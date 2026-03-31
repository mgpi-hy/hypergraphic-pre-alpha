class_name CombatScreen
extends ScreenState

## Top-level combat controller. Owns all combat subsystems and runs the phase FSM.
## This is controller logic only: no UI code, no node creation, no rendering.
## CombatUI connects to the signals declared here and calls the public API.

# --- Signals ---

signal phase_changed(phase: Phase)
signal hand_updated(hand: Array[MorphemeData])
signal enemy_intents_updated(intents: Array[Dictionary])
signal damage_resolved(result: Dictionary)
signal enemy_turn_completed(results: Array[Dictionary])
signal combat_ended(is_victory: bool)
signal morpheme_placed(morpheme: MorphemeData, slot_index: int)
signal morpheme_removed(slot_index: int)
signal word_validated(result: Dictionary)

# --- Enums ---

enum Phase { DRAW, PLACE, AFFIX, SUBMIT, RESOLVE, ENEMY_TURN }

# --- Constants ---

const REWARD_SCREEN_PATH: String = "res://scenes/screens/reward_screen.tscn"
const DEATH_SCREEN_PATH: String = "res://scenes/screens/title_screen.tscn"
const DRAW_PER_TURN: int = 3
const HOLD_BONUS_DRAW: int = 5
const HOLD_MULTIPLIER: float = 2.0

## Maps boss enemy IDs to their specific tree types.
const BOSS_TREE_MAP: Dictionary = {
	"brocas_aphasia": "boss_broca",
	"wernickes_aphasia": "boss_wernicke",
	"seizure_disorder": "boss_seizure",
}

# --- Private Variables ---

var _phase: Phase = Phase.DRAW:
	set(value):
		if _phase == value:
			return
		_exit_phase(_phase)
		_phase = value
		_enter_phase(_phase)

var _combat_state: CombatState
var _damage_resolver: DamageResolver
var _word_validator: WordValidator
var _enemy_controller: EnemyController
var _effect_manager: EffectManager

var _run_data: RunData
var _floor_number: int = 1
var _tree_type: String = ""  ## Named config for bosses, or "" for procedural
var _generated_config: Array = []  ## Procedurally generated tree config
var _placed_morphemes: Array[MorphemeData] = []
var _placed_slots: Dictionary = {}  # slot_index -> MorphemeData
var _active_effects: Array[Effect] = []  # tracked for cleanup
var _is_combat_active: bool = false
var _hold_bonus_active: bool = false  ## true if player held last turn (draw 5 + x2)


# --- Virtual Methods ---

func _ready() -> void:
	_combat_state = CombatState.new()
	_damage_resolver = DamageResolver.new()
	_word_validator = WordValidator.new()
	_enemy_controller = EnemyController.new()

	# Use the EffectManager child placed in the .tscn scene
	_effect_manager = $EffectManager as EffectManager
	if not _effect_manager:
		# Fallback: create one if the scene node is missing
		_effect_manager = EffectManager.new()
		_effect_manager.name = "EffectManager"
		add_child(_effect_manager)


## Called by ScreenState FSM. Receives data dict with run_data, enemies, floor_number.
func enter(_previous: String, data: Dictionary = {}) -> void:
	super.enter(_previous, data)
	print("[COMBAT] enter() called. data keys: ", data.keys())

	_run_data = data.get("run_data") as RunData
	if not _run_data and GameManager.run != null:
		_run_data = GameManager.run
	if not _run_data:
		push_error("CombatScreen.enter: missing run_data and GameManager.run is null")
		return
	print("[COMBAT] RunData OK. deck size: ", _run_data.deck.size())

	var enemy_list: Array[EnemyData] = []
	var raw_enemies: Array = data.get("enemies", [])
	print("[COMBAT] raw_enemies count: ", raw_enemies.size())
	for enemy: Variant in raw_enemies:
		var enemy_data: EnemyData = enemy as EnemyData
		if enemy_data:
			enemy_list.append(enemy_data)
		else:
			print("[COMBAT] WARNING: enemy cast failed for: ", enemy)
	if enemy_list.is_empty():
		push_error("CombatScreen.enter: no enemies provided")
		return
	print("[COMBAT] enemy_list count: ", enemy_list.size())

	_floor_number = data.get("floor_number", 1) as int

	# Select tree type from data or derive from enemy tier
	_tree_type = _select_tree_type(data, enemy_list)
	_generated_config = []
	if _tree_type == "":
		# Procedural generation based on floor number
		_generated_config = SyntaxTree.generate_tree_config(_floor_number)
		print("[COMBAT] tree: procedural (floor %d, %d slots)" % [_floor_number, _generated_config.size()])
	else:
		print("[COMBAT] tree_type: ", _tree_type)

	# 1. Initialize CombatState from RunData
	_combat_state.init_from_run(_run_data)

	# 2. Initialize EnemyController with enemy list + floor
	_enemy_controller.init_enemies(enemy_list, _floor_number)
	_combat_state.set_enemies(_enemy_controller.get_all_enemies())

	# 3. Register character passive effects
	_register_character_passives()

	# 4. Register grapheme effects for all acquired graphemes
	_register_grapheme_effects()

	# 5. Create RegionModifier from current region
	var region_id: String = _run_data.current_region_id
	var region_data: RegionData = data.get("region_data") as RegionData
	var mod_id: String = ""
	if region_data:
		mod_id = region_data.modifier_id
	if mod_id != "":
		_combat_state.region_modifier = RegionModifier.create(mod_id)
		print("[COMBAT] region modifier: ", mod_id)
	else:
		_combat_state.region_modifier = null
		print("[COMBAT] no region modifier for region: ", region_id)

	# 6. Fire ON_COMBAT_START trigger
	_is_combat_active = true
	var ctx: EffectContext = _build_context()
	_effect_manager.trigger(Enums.EffectTrigger.ON_COMBAT_START, ctx)
	_resolve_queue(ctx)

	# 7. Tell CombatUI to build initial display (enemies, tree, stats)
	var ui: CombatUI = _get_combat_ui()
	print("[COMBAT] CombatUI found: ", ui != null)
	if ui:
		print("[COMBAT] calling initialize_combat_display()")
		ui.initialize_combat_display()
	else:
		push_error("CombatScreen: CombatUI child not found!")

	# 8. Apply region modifier start-of-combat (UI now exists, can show choice prompts)
	if _combat_state.region_modifier:
		_combat_state.region_modifier.apply_start_of_combat(
			_combat_state, _region_modifier_ui_callback
		)

	# 9. Initial full hand draw (hand_size cards, not DRAW_PER_TURN)
	var initial_draw: int = _combat_state.deck.max_hand_size
	_combat_state.draw_morphemes(initial_draw)
	hand_updated.emit(_combat_state.hand)
	print("[COMBAT] initial draw: %d cards" % _combat_state.hand.size())

	# 10. Start first turn (draws DRAW_PER_TURN additional cards)
	print("[COMBAT] starting first turn")
	_start_turn()


func exit() -> void:
	_effect_manager.clear_all()
	_active_effects.clear()
	_placed_morphemes.clear()
	_placed_slots.clear()
	_is_combat_active = false
	super.exit()


# --- Public API (for CombatUI to call) ---

## Place a morpheme into a syntax tree slot. Returns true on success.
func place_morpheme(morpheme: MorphemeData, slot_index: int) -> bool:
	if _phase != Phase.PLACE:
		return false
	if _placed_slots.has(slot_index):
		return false

	# Region modifier placement check
	if _combat_state.region_modifier:
		var total_slots: int = _get_total_slot_count()
		if not _combat_state.region_modifier.can_place_morpheme(morpheme, slot_index, total_slots):
			return false

	_placed_slots[slot_index] = morpheme
	_placed_morphemes.append(morpheme)

	# Remove from hand
	var hand_idx: int = _combat_state.hand.find(morpheme)
	if hand_idx >= 0:
		_combat_state.hand.remove_at(hand_idx)

	morpheme_placed.emit(morpheme, slot_index)
	hand_updated.emit(_combat_state.hand)

	# Check POS match and fire trigger only if morpheme POS matches the slot's required POS
	var ctx: EffectContext = _build_context()
	ctx.morphemes = [morpheme]
	var _pos_matched: bool = false
	var _ui: CombatUI = _get_combat_ui()
	if _ui:
		var _tree: SyntaxTree = _ui.get_syntax_tree()
		if _tree:
			var _all_slots: Array[SyntaxSlot] = _tree.get_all_slots()
			if slot_index >= 0 and slot_index < _all_slots.size():
				_pos_matched = _all_slots[slot_index].is_pos_matched()
	if _pos_matched:
		_effect_manager.trigger(Enums.EffectTrigger.ON_POS_MATCH, ctx)
		_resolve_queue(ctx)

	return true


## Remove a morpheme from a syntax tree slot and return it to hand.
func remove_morpheme(slot_index: int) -> void:
	if _phase != Phase.PLACE and _phase != Phase.AFFIX:
		return
	if not _placed_slots.has(slot_index):
		return

	# Region modifier removal check (reflex blocks removal)
	if _combat_state.region_modifier:
		if not _combat_state.region_modifier.can_remove_morpheme():
			return

	var morpheme: MorphemeData = _placed_slots[slot_index] as MorphemeData
	_placed_slots.erase(slot_index)
	_placed_morphemes.erase(morpheme)

	# Return to hand
	_combat_state.hand.append(morpheme)

	morpheme_removed.emit(slot_index)
	hand_updated.emit(_combat_state.hand)


## Attach an affix morpheme to a root in a given slot. Returns true on success.
func attach_affix(root_slot: int, affix: MorphemeData) -> bool:
	if _phase != Phase.AFFIX and _phase != Phase.PLACE:
		return false
	if not _placed_slots.has(root_slot):
		return false
	if not affix.is_affix:
		return false

	_placed_morphemes.append(affix)

	# Remove from hand
	var hand_idx: int = _combat_state.hand.find(affix)
	if hand_idx >= 0:
		_combat_state.hand.remove_at(hand_idx)

	var ctx: EffectContext = _build_context()
	ctx.morphemes = [_placed_slots[root_slot] as MorphemeData, affix]
	_effect_manager.trigger(Enums.EffectTrigger.ON_AFFIX_ATTACHED, ctx)
	_resolve_queue(ctx)

	morpheme_placed.emit(affix, root_slot)
	hand_updated.emit(_combat_state.hand)
	return true


## Submit the current word/tree for damage resolution.
func submit_word() -> void:
	if _phase != Phase.SUBMIT and _phase != Phase.PLACE and _phase != Phase.AFFIX:
		return
	_on_submit()


## Skip submission, discard hand, proceed to enemy turn.
func hold_turn() -> void:
	if _phase != Phase.SUBMIT and _phase != Phase.PLACE and _phase != Phase.AFFIX:
		return
	_on_hold()


## Activate a phoneme consumable during combat.
## Phonemes are one-shot: execute each effect once and discard. Do NOT register
## them with EffectManager — registration causes them to fire again on ON_PLAY,
## producing a double-fire for any effect with a matching trigger.
func use_phoneme(phoneme: PhonemeData) -> void:
	if not _is_combat_active:
		return

	var ctx: EffectContext = _build_context()
	for effect: Effect in phoneme.effects:
		var instance: Effect = effect.duplicate()
		instance.execute(ctx)
	_resolve_queue(ctx)

	# Consume if single-use
	if phoneme.is_consumable:
		_run_data.acquired_phonemes.erase(phoneme)
	EventBus.phoneme_used.emit(phoneme)


## Advance from RESOLVE phase to ENEMY_TURN. Called by CombatUI after animations.
func advance_to_enemy_turn() -> void:
	if _phase != Phase.RESOLVE:
		return
	_phase = Phase.ENEMY_TURN


## Read-only access to combat state for UI queries.
func get_combat_state() -> CombatState:
	return _combat_state


## Read-only access to enemy controller for UI queries.
func get_enemy_controller() -> EnemyController:
	return _enemy_controller


## Get the tree type for this combat encounter (empty string for procedural).
func get_tree_type() -> String:
	return _tree_type


## Get the procedurally generated config (empty if using a named config).
func get_generated_config() -> Array:
	return _generated_config


## Open the deck viewer overlay.
func open_deck_viewer() -> void:
	# TODO: open deck viewer overlay
	pass


## Forfeit the current combat (counts as a defeat).
func forfeit_combat() -> void:
	_end_combat(false)


# --- Turn Flow ---

## Begin a new player turn: increment turn, draw morphemes, select intents.
func _start_turn() -> void:
	_combat_state.begin_turn()

	# Apply region modifier turn start
	if _combat_state.region_modifier:
		_combat_state.region_modifier.apply_turn_start(
			_combat_state, _combat_state.current_turn
		)
		# spatial_mapping: apply rotated POS order to syntax tree slots
		if _combat_state.region_modifier.modifier_id == "spatial_mapping":
			var rotated: Array = _combat_state.region_modifier.get_rotated_pos_order()
			if not rotated.is_empty():
				var ui: CombatUI = _get_combat_ui()
				if ui:
					var tree: SyntaxTree = ui.get_syntax_tree()
					if tree:
						var all_slots: Array[SyntaxSlot] = tree.get_all_slots()
						for i: int in range(mini(rotated.size(), all_slots.size())):
							all_slots[i].pos_type = rotated[i] as Enums.POSType

	# Fire ON_TURN_START
	var ctx: EffectContext = _build_context()
	_effect_manager.trigger(Enums.EffectTrigger.ON_TURN_START, ctx)
	_resolve_queue(ctx)

	# Reset insulation (unless character passive overrides via interceptor)
	if not _combat_state.kaph_retain:
		_combat_state.player_insulation = 0

	# Draw morphemes: persistent hand + DRAW_PER_TURN (or HOLD_BONUS_DRAW if held)
	var base_draw: int = DRAW_PER_TURN
	if _hold_bonus_active:
		base_draw = HOLD_BONUS_DRAW
		_combat_state.submit_multiplier *= HOLD_MULTIPLIER
		_hold_bonus_active = false
	var draw_count: int = base_draw + _combat_state.consume_bonus_draw()
	_combat_state.draw_morphemes(draw_count)

	# Fire ON_DRAW for drawn morphemes
	var draw_ctx: EffectContext = _build_context()
	draw_ctx.morphemes = _combat_state.hand.duplicate()
	_effect_manager.trigger(Enums.EffectTrigger.ON_DRAW, draw_ctx)
	_resolve_queue(draw_ctx)

	# Select enemy intents
	_enemy_controller.select_intents()

	# Clear placed state for new turn
	_placed_morphemes.clear()
	_placed_slots.clear()

	# Emit signals for UI
	hand_updated.emit(_combat_state.hand)
	enemy_intents_updated.emit(_enemy_controller.get_enemy_intents())

	# Transition to PLACE phase
	_phase = Phase.PLACE


## Submit the assembled word for damage resolution.
func _on_submit() -> void:
	if _placed_morphemes.is_empty():
		return

	# Validate word
	var slot_pos: Enums.POSType = Enums.POSType.NOUN  # default; overridden by tree
	var validation: Dictionary = _word_validator.validate_word(
		_placed_morphemes, slot_pos, _combat_state.words_used_this_run
	)

	word_validated.emit(validation)

	if not validation.get("is_valid", false):
		return

	var assembled_word: String = validation.get("word", "")
	var is_novel: bool = validation.get("has_novel", false)

	# Build syntax tree data from SyntaxTree component if available
	var syntax_tree_data: Dictionary = _build_syntax_tree_data()

	# Resolve damage
	var result: Dictionary = _damage_resolver.resolve_word(
		_combat_state, _effect_manager, _placed_morphemes, syntax_tree_data,
		_effect_manager.get_action_queue()
	)

	var final_induction: int = result.get("final_induction", 0)

	# Grant insulation from functional/hybrid morphemes
	var insulation_gained: int = result.get("insulation_gained", 0)
	if insulation_gained > 0:
		_combat_state.add_insulation(insulation_gained)

	# Fire ON_WORD_FORMED
	var ctx: EffectContext = _build_context()
	ctx.word = assembled_word
	ctx.morphemes = _placed_morphemes.duplicate()
	ctx.is_novel_word = is_novel
	_effect_manager.trigger(Enums.EffectTrigger.ON_WORD_FORMED, ctx)

	# Fire ON_NOVEL_WORD if applicable
	if is_novel:
		_effect_manager.trigger(Enums.EffectTrigger.ON_NOVEL_WORD, ctx)

	# Fire ON_PLAY
	_effect_manager.trigger(Enums.EffectTrigger.ON_PLAY, ctx)
	_resolve_queue(ctx)

	# Record submission
	_combat_state.record_word_submitted(assembled_word, final_induction)

	# Notify region modifier of submission
	if _combat_state.region_modifier:
		_combat_state.region_modifier.on_post_submit([assembled_word])

	# Apply damage to targeted enemy
	var target_idx: int = _combat_state.active_enemy_index
	var defeat_info: Dictionary = _enemy_controller.apply_damage_to_enemy(target_idx, final_induction)

	# Fire ON_DAMAGE_DEALT
	var dmg_ctx: EffectContext = _build_context()
	dmg_ctx.damage_amount = final_induction
	_effect_manager.trigger(Enums.EffectTrigger.ON_DAMAGE_DEALT, dmg_ctx)
	_resolve_queue(dmg_ctx)

	# Check for enemy defeat
	if defeat_info.get("defeated", false):
		_combat_state.record_enemy_defeated()
		# Track kills by enemy tier for pragmant calculation
		var defeated_inst: EnemyController.EnemyInstance = (
			_enemy_controller.get_all_enemies()[target_idx] as EnemyController.EnemyInstance
			if target_idx < _enemy_controller.get_all_enemies().size() else null
		)
		if defeated_inst and defeated_inst.data and _run_data:
			match defeated_inst.data.tier:
				EnemyData.Tier.SYNAPSE:
					_run_data.increment_stat("synapses_killed")
				EnemyData.Tier.LESION:
					_run_data.increment_stat("lesions_killed")
				EnemyData.Tier.BOSS:
					_run_data.increment_stat("bosses_killed")
		var defeat_ctx: EffectContext = _build_context()
		_effect_manager.trigger(Enums.EffectTrigger.ON_ENEMY_DEFEATED, defeat_ctx)
		_resolve_queue(defeat_ctx)
		# Advance target to next surviving enemy (if any remain)
		_combat_state.advance_to_next_alive_enemy()

	# Resolve any remaining queued actions
	_resolve_queue(_build_context())

	# Track combo: consecutive submits without holding
	_combat_state.increment_combo()

	# Emit result for UI cascade display
	result["defeat_info"] = defeat_info
	result["word"] = assembled_word
	result["is_novel"] = is_novel
	result["combo"] = _combat_state.get_combo()
	damage_resolved.emit(result)

	# Discard placed morphemes after submission (persistent hand; only placed cards discard)
	for m: MorphemeData in _placed_morphemes:
		_combat_state.discard_pile.append(m)
	_placed_morphemes.clear()
	_placed_slots.clear()

	# Check victory
	if _enemy_controller.is_all_defeated():
		_end_combat(true)
		return

	# Move to RESOLVE phase (brief pause for animations, then enemy turn)
	_phase = Phase.RESOLVE


## Hold turn: return placed morphemes to hand, grant hold bonus next turn,
## then proceed to enemy turn. Hand is persistent (not discarded).
func _on_hold() -> void:
	# Move placed morphemes back to hand
	for slot_idx: int in _placed_slots:
		var m: MorphemeData = _placed_slots[slot_idx] as MorphemeData
		_combat_state.hand.append(m)
	_placed_morphemes.clear()
	_placed_slots.clear()

	# Reset combo on hold
	_combat_state.reset_combo()

	# Holding grants bonus draw (5) and x2 multiplier next turn
	_hold_bonus_active = true

	hand_updated.emit(_combat_state.hand)
	_phase = Phase.ENEMY_TURN


## Execute the enemy turn: all enemies act, then start next player turn or end combat.
func _start_enemy_turn() -> void:
	var results: Array[Dictionary] = _enemy_controller.execute_enemy_turn(
		_combat_state, _effect_manager
	)

	# Apply any pending mechanics queued by enemy actions
	_apply_pending_mechanics()

	# Fire ON_DAMAGE_TAKEN for each attack that dealt damage
	for result: Dictionary in results:
		var dmg: int = result.get("damage_dealt", 0)
		if dmg > 0:
			var ctx: EffectContext = _build_context()
			ctx.damage_amount = dmg
			_effect_manager.trigger(Enums.EffectTrigger.ON_DAMAGE_TAKEN, ctx)
			_resolve_queue(ctx)

	# Resolve any remaining queued actions
	_resolve_queue(_build_context())

	enemy_turn_completed.emit(results)

	# Check player death
	if _combat_state.player_cogency <= 0:
		_end_combat(false)
		return

	# Fire ON_TURN_END
	var end_ctx: EffectContext = _build_context()
	_effect_manager.trigger(Enums.EffectTrigger.ON_TURN_END, end_ctx)
	_resolve_queue(end_ctx)

	# Hand is persistent: morphemes stay between turns.
	# Placed morphemes were already discarded during submit or returned during hold.

	# Start next turn
	_start_turn()


## End combat: fire triggers, write results, emit signals.
func _end_combat(is_victory: bool) -> void:
	_is_combat_active = false

	# Fire ON_COMBAT_END
	var ctx: EffectContext = _build_context()
	_effect_manager.trigger(Enums.EffectTrigger.ON_COMBAT_END, ctx)
	_resolve_queue(ctx)

	# Unregister all effects
	_effect_manager.clear_all()
	_active_effects.clear()

	# Apply combat results to RunData
	_combat_state.apply_to_run(_run_data)

	combat_ended.emit(is_victory)

	# Route to next screen
	if is_victory:
		var reward_data: Dictionary = {"run_data": _run_data}
		# Check if defeated enemy was a boss; reward screen routes differently
		if _is_boss_encounter():
			reward_data["is_boss_victory"] = true
		reward_data["highlights"] = {
			"best_word": _combat_state.best_word_form,
			"best_induction": _combat_state.best_word_induction,
			"peak_multiplier": _combat_state.peak_multiplier,
			"total_damage": _combat_state.total_induction_dealt,
			"turns": _combat_state.current_turn,
		}
		finished.emit(REWARD_SCREEN_PATH, reward_data)
	else:
		_run_data.last_enemy_name = _get_last_enemy_name()
		GameManager.end_run(false)


# --- Phase FSM ---

func _enter_phase(phase: Phase) -> void:
	phase_changed.emit(phase)
	match phase:
		Phase.DRAW:
			pass  # handled by _start_turn
		Phase.PLACE:
			pass  # UI enables drag-drop
		Phase.AFFIX:
			pass  # UI enables affix snapping
		Phase.SUBMIT:
			pass  # UI enables submit/hold buttons
		Phase.RESOLVE:
			pass  # brief pause for damage animations; CombatUI calls advance_to_enemy_turn()
		Phase.ENEMY_TURN:
			_start_enemy_turn()


func _exit_phase(_exiting: Phase) -> void:
	# Reserved for phase-specific teardown (e.g., disabling input modes).
	# Currently no exit logic needed; phases are entered, not exited.
	pass


# --- Effect Registration ---

## Register character passive effects on the EffectManager.
func _register_character_passives() -> void:
	if not _run_data.character:
		return
	var ctx: EffectContext = _build_context()
	for effect: Effect in _run_data.character.passive_effects:
		var instance: Effect = _effect_manager.register(effect, ctx)
		_active_effects.append(instance)


## Register all grapheme effects for acquired graphemes.
func _register_grapheme_effects() -> void:
	var ctx: EffectContext = _build_context()
	for grapheme: GraphemeData in _run_data.acquired_graphemes:
		for effect: Effect in grapheme.effects:
			var instance: Effect = _effect_manager.register(effect, ctx)
			_active_effects.append(instance)


# --- Context Building ---

## Build an EffectContext with current combat state.
func _build_context() -> EffectContext:
	return EffectContext.from_combat(
		_combat_state,
		_effect_manager.get_action_queue(),
		self
	)


## Resolve all pending actions in the queue.
func _resolve_queue(ctx: EffectContext) -> void:
	_effect_manager.get_action_queue().resolve_all(ctx)


# --- Helper Methods ---

## Select tree type based on encounter data and enemy composition.
## Returns a named config string for bosses, or "" for procedural generation.
func _select_tree_type(data: Dictionary, enemy_list: Array[EnemyData]) -> String:
	# Explicit tree_type from map/encounter data takes priority (boss overrides)
	var explicit_type: String = data.get("tree_type", "") as String
	if explicit_type != "" and SyntaxTree.NAMED_CONFIGS.has(explicit_type):
		return explicit_type

	# Check for boss-specific tree
	if not enemy_list.is_empty():
		var first_enemy: EnemyData = enemy_list[0]
		if first_enemy.tier == EnemyData.Tier.BOSS and BOSS_TREE_MAP.has(first_enemy.id):
			return BOSS_TREE_MAP[first_enemy.id]

	# Non-boss encounters use procedural generation (return empty to signal this)
	return ""


## Build syntax tree data dictionary for DamageResolver.
## Uses the SyntaxTree component if available, falls back to placed_slots.
func _build_syntax_tree_data() -> Dictionary:
	var ui: CombatUI = _get_combat_ui()
	if ui:
		var tree: SyntaxTree = ui.get_syntax_tree()
		if tree:
			return tree.build_resolver_data()

	# Fallback: build from placed_slots (legacy flat layout)
	var slots: Array[Dictionary] = []
	for slot_idx: int in _placed_slots:
		var morpheme: MorphemeData = _placed_slots[slot_idx] as MorphemeData
		slots.append({
			"pos": morpheme.pos_type,
			"is_optional": false,
			"is_filled": true,
			"branch_id": "default",
			"morphemes": [morpheme],
		})
	return {"slots": slots}


## Find the CombatUI child node.
func _get_combat_ui() -> CombatUI:
	for child: Node in get_children():
		if child is CombatUI:
			return child as CombatUI
	return null


## Returns total syntax tree slot count for region modifier placement checks.
func _get_total_slot_count() -> int:
	var tree_data: Dictionary = _build_syntax_tree_data()
	var slots: Array = tree_data.get("slots", [])
	return slots.size()


## UI callback for region modifiers. Routes UI requests to CombatUI.
## Returns a Variant (usually String) depending on the action.
func _region_modifier_ui_callback(action: String, data: Dictionary) -> Variant:
	var ui: CombatUI = _get_combat_ui()
	if not ui:
		push_warning("RegionModifier UI callback: no CombatUI found for action: %s" % action)
		return ""

	match action:
		"choose_fight_mode":
			# Default to offense if UI can't prompt yet
			if ui.has_method("prompt_fight_mode_choice"):
				return ui.prompt_fight_mode_choice(data)
			return "offense"
		"choose_executive":
			if ui.has_method("prompt_executive_choice"):
				return ui.prompt_executive_choice(data)
			return "draw"
		"hide_all_pos_labels":
			if ui.has_method("hide_all_pos_labels"):
				ui.hide_all_pos_labels()
		"reveal_adjacent_pos":
			if ui.has_method("reveal_adjacent_pos"):
				ui.reveal_adjacent_pos(data)
		"get_slot_pos_order":
			# Return the current POS type for each slot in order, for spatial_mapping.
			var tree: SyntaxTree = ui.get_syntax_tree()
			if tree:
				var pos_order: Array = []
				for slot: SyntaxSlot in tree.get_all_slots():
					pos_order.append(slot.pos_type)
				return pos_order
			return []
		_:
			push_warning("RegionModifier: unknown UI action: %s" % action)

	return ""


## Returns true if any enemy in this encounter is a boss.
func _is_boss_encounter() -> bool:
	var all_enemies: Array = _enemy_controller.get_all_enemies()
	for enemy_inst: Variant in all_enemies:
		var inst: EnemyController.EnemyInstance = enemy_inst as EnemyController.EnemyInstance
		if inst and inst.data and inst.data.tier == EnemyData.Tier.BOSS:
			return true
	return false


## Process all pending flags set by EnemyController AND player effects.
## Enemy mechanic flags (pending_scramble, etc.) manipulate the syntax tree.
## Player effect flags (_pending_morpheme_swap, etc.) manipulate hand/slots.
func _apply_pending_mechanics() -> void:
	var ui: CombatUI = _get_combat_ui()
	var tree: SyntaxTree = null
	if ui:
		tree = ui.get_syntax_tree()

	if _combat_state.pending_scramble > 0:
		if tree and tree.has_method("scramble_random_slots"):
			tree.scramble_random_slots(_combat_state.pending_scramble)
		_combat_state.pending_scramble = 0

	if _combat_state.pending_silence > 0:
		if tree and tree.has_method("lock_random_slots"):
			tree.lock_random_slots(_combat_state.pending_silence)
		_combat_state.pending_silence = 0

	if _combat_state.pending_lock > 0:
		# Lock player actions: disable input for pending_lock turns via UI
		if ui and ui.has_method("set_input_enabled"):
			ui.set_input_enabled(false)
		_combat_state.pending_lock = 0

	if _combat_state.pending_grow_branch > 0:
		if tree and tree.has_method("add_optional_slots"):
			tree.add_optional_slots(_combat_state.pending_grow_branch)
		_combat_state.pending_grow_branch = 0

	if _combat_state.pending_hide_pos:
		if ui and ui.has_method("hide_all_pos_labels"):
			ui.hide_all_pos_labels()
		_combat_state.pending_hide_pos = false

	if _combat_state.pending_shift_tree > 0:
		if tree and tree.has_method("shift_slot_layout"):
			tree.shift_slot_layout(_combat_state.pending_shift_tree)
		_combat_state.pending_shift_tree = 0

	if _combat_state.pending_force_place > 0:
		# Force random morphemes from hand into slots
		var placed: int = 0
		var all_slots: Array[SyntaxSlot] = []
		if tree:
			all_slots = tree.get_all_slots()
		for slot: SyntaxSlot in all_slots:
			if placed >= _combat_state.pending_force_place:
				break
			if slot.placed_morpheme != null:
				continue
			if _combat_state.hand.is_empty():
				break
			var morpheme: MorphemeData = _combat_state.hand[0]
			_combat_state.hand.remove_at(0)
			slot.set_morpheme(morpheme)
			placed += 1
		_combat_state.pending_force_place = 0

	if _combat_state.pending_shrink_hand > 0:
		var discard_count: int = mini(_combat_state.pending_shrink_hand, _combat_state.hand.size())
		for i: int in range(discard_count):
			if _combat_state.hand.is_empty():
				break
			var m: MorphemeData = _combat_state.hand.pick_random()
			_combat_state.hand.erase(m)
			_combat_state.discard_pile.append(m)
		_combat_state.pending_shrink_hand = 0

	if _combat_state.pending_halve_hand:
		var discard_count: int = _combat_state.hand.size() / 2
		for i: int in range(discard_count):
			if _combat_state.hand.is_empty():
				break
			var m: MorphemeData = _combat_state.hand.pick_random()
			_combat_state.hand.erase(m)
			_combat_state.discard_pile.append(m)
		_combat_state.pending_halve_hand = false

	if _combat_state.pending_cancel_novel:
		_combat_state.cancel_novel_bonus = true
		_combat_state.pending_cancel_novel = false

	if _combat_state.pending_steal_morpheme > 0:
		# Remove morphemes from hand (stolen by enemy)
		var steal_count: int = mini(_combat_state.pending_steal_morpheme, _combat_state.hand.size())
		for i: int in range(steal_count):
			if _combat_state.hand.is_empty():
				break
			var m: MorphemeData = _combat_state.hand.pick_random()
			_combat_state.hand.erase(m)
		_combat_state.pending_steal_morpheme = 0

	# --- Player Effect Pending Flags ---

	if _combat_state.consume_pending_morpheme_swap():
		# Chi: swap a random hand morpheme with a random draw pile morpheme
		if not _combat_state.hand.is_empty() and not _combat_state.draw_pile.is_empty():
			var hand_idx: int = randi() % _combat_state.hand.size()
			var draw_idx: int = randi() % _combat_state.draw_pile.size()
			var from_hand: MorphemeData = _combat_state.hand[hand_idx]
			var from_draw: MorphemeData = _combat_state.draw_pile[draw_idx]
			_combat_state.hand[hand_idx] = from_draw
			_combat_state.draw_pile[draw_idx] = from_hand
			hand_updated.emit(_combat_state.hand)

	if _combat_state.consume_pending_morphemic_drift():
		# Delta: transform a random placed root to a random root of a different family
		var roots_in_slots: Array[int] = []
		for slot_idx: int in _placed_slots:
			var morph: MorphemeData = _placed_slots[slot_idx] as MorphemeData
			if morph and morph.type == MorphemeData.MorphemeType.ROOT:
				roots_in_slots.append(slot_idx)
		if not roots_in_slots.is_empty():
			var target_slot: int = roots_in_slots.pick_random()
			var old_morph: MorphemeData = _placed_slots[target_slot] as MorphemeData
			# Find a root of a different family from the deck's morpheme pool
			var candidates: Array[MorphemeData] = []
			for m: MorphemeData in _combat_state.draw_pile:
				if m.type == MorphemeData.MorphemeType.ROOT and m.family != old_morph.family:
					candidates.append(m)
			if not candidates.is_empty():
				var replacement: MorphemeData = candidates.pick_random()
				_placed_slots[target_slot] = replacement
				# Update the placed morphemes list
				var old_idx: int = _placed_morphemes.find(old_morph)
				if old_idx >= 0:
					_placed_morphemes[old_idx] = replacement

	if _combat_state.consume_pending_ayin_gaze():
		# Ayin: exile lowest-weight morpheme from hand, draw 2
		if not _combat_state.hand.is_empty():
			var lowest: MorphemeData = _combat_state.hand[0]
			for m: MorphemeData in _combat_state.hand:
				if m.base_induction < lowest.base_induction:
					lowest = m
			_combat_state.exhaust_morpheme(lowest)
			_combat_state.draw_morphemes(2)
			hand_updated.emit(_combat_state.hand)

	if _combat_state.consume_pending_spite_spawn():
		# Shin: add a temporary +3 any-POS morpheme to hand
		var spite: MorphemeData = MorphemeData.new()
		spite.root_text = "SPITE"
		spite.display_name = "Spite"
		spite.base_induction = 3
		spite.type = MorphemeData.MorphemeType.ROOT
		spite.pos_type = Enums.POSType.NOUN
		spite.combat_role = MorphemeData.CombatRole.CONTENT
		spite.rarity = MorphemeData.Rarity.COMMON
		_combat_state.hand.append(spite)
		hand_updated.emit(_combat_state.hand)

	if _combat_state.consume_pending_force_submit():
		# Velar Gambit: force submit tree now, damage for unfilled required slots
		if tree:
			var empty_required: int = 0
			for slot: SyntaxSlot in tree.get_all_slots():
				if slot.placed_morpheme == null and slot.is_required:
					empty_required += 1
			# Self-damage for empty required slots
			_combat_state.player_cogency -= empty_required * 3
		_on_submit()

	var wildcard_data: Dictionary = _combat_state.consume_pending_wildcard_slot()
	if not wildcard_data.is_empty():
		# Open Lattice: add a wildcard POS slot
		if tree:
			tree.add_random_optional_slot()

	if _combat_state.consume_pending_optional_slot():
		# Mu: add optional slot to longest branch
		if tree:
			tree.add_random_optional_slot()

	if _combat_state.consume_pending_burn_slot():
		# Huo: highest-induction word's slot becomes wildcard (any POS fits)
		if tree:
			var best_slot: SyntaxSlot = null
			var best_induction: int = -1
			for slot: SyntaxSlot in tree.get_all_slots():
				if slot.placed_morpheme != null:
					if slot.placed_morpheme.base_induction > best_induction:
						best_induction = slot.placed_morpheme.base_induction
						best_slot = slot
			if best_slot:
				best_slot.is_required = false
				best_slot.is_optional = true

	var swap_data: Dictionary = _combat_state.consume_pending_hand_discard_swap()
	if not swap_data.is_empty():
		# Click Swap: swap a random root between hand and discard
		var hand_roots: Array[int] = []
		for i: int in range(_combat_state.hand.size()):
			if _combat_state.hand[i].type == MorphemeData.MorphemeType.ROOT:
				hand_roots.append(i)
		var disc_roots: Array[int] = []
		for i: int in range(_combat_state.discard_pile.size()):
			if _combat_state.discard_pile[i].type == MorphemeData.MorphemeType.ROOT:
				disc_roots.append(i)
		if not hand_roots.is_empty() and not disc_roots.is_empty():
			var hi: int = hand_roots.pick_random()
			var di: int = disc_roots.pick_random()
			var from_hand: MorphemeData = _combat_state.hand[hi]
			var from_disc: MorphemeData = _combat_state.discard_pile[di]
			_combat_state.hand[hi] = from_disc
			_combat_state.discard_pile[di] = from_hand
			hand_updated.emit(_combat_state.hand)

	if _combat_state.consume_pending_double_attack():
		# Retroflex Scatter: mark a random alive enemy to attack twice
		var alive_enemies: Array[EnemyController.EnemyInstance] = _enemy_controller.get_alive_enemies()
		if not alive_enemies.is_empty():
			var target: EnemyController.EnemyInstance = alive_enemies.pick_random()
			if target:
				target.bonus_attacks += 1

	var dup_data: Dictionary = _combat_state.consume_pending_duplicate_word()
	if not dup_data.is_empty():
		# Pharyngeal Copy: duplicate last placed word's induction as bonus
		var dup_mult: float = dup_data.get("mult", 1.0)
		if _combat_state.best_word_induction > 0:
			var bonus: int = int(_combat_state.best_word_induction * dup_mult)
			_combat_state.bonus_induction_next_submit += bonus

	if _combat_state.consume_pending_reroll_slots():
		# Rhotic Shift: randomize all empty slot POS types
		if tree:
			var pos_options: Array[Enums.POSType] = [
				Enums.POSType.NOUN, Enums.POSType.VERB, Enums.POSType.ADJECTIVE,
				Enums.POSType.ADVERB, Enums.POSType.DETERMINER, Enums.POSType.PREPOSITION,
			]
			var match_count: int = 0
			for slot: SyntaxSlot in tree.get_all_slots():
				if slot.placed_morpheme == null and not slot.is_locked:
					slot.pos_type = pos_options.pick_random()
					slot.update_display()
					# Check if any hand morpheme matches the new POS
					for m: MorphemeData in _combat_state.hand:
						if m.pos_type == slot.pos_type:
							match_count += 1
							break
			if match_count >= 2:
				_combat_state.draw_morphemes(1)
				hand_updated.emit(_combat_state.hand)

	if _combat_state.consume_pending_clear_words():
		# Glottal Catch: clear all placed words, draw 2 per word cleared
		if tree:
			var words_cleared: int = 0
			for slot: SyntaxSlot in tree.get_all_slots():
				if slot.placed_morpheme != null:
					var m: MorphemeData = slot.placed_morpheme
					_combat_state.hand.append(m)
					slot.clear_slot()
					words_cleared += 1
			_placed_morphemes.clear()
			_placed_slots.clear()
			if words_cleared > 0:
				_combat_state.draw_morphemes(words_cleared * 2)
				hand_updated.emit(_combat_state.hand)


## Get the display name of the last alive (or most recent) enemy.
func _get_last_enemy_name() -> String:
	var all_enemies: Array = _enemy_controller.get_all_enemies()
	if all_enemies.is_empty():
		return "Unknown"
	var last: EnemyController.EnemyInstance = all_enemies.back() as EnemyController.EnemyInstance
	if last and last.data:
		return last.data.display_name
	return "Unknown"
