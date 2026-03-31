class_name RegionModifier
extends RefCounted

## Applies region-specific gameplay modifications to combat.
## Standalone system: injected into combat, called at specific points.
## Each region has exactly one modifier from a fixed set of 13.

# --- Constants ---

const REFLEX_FIRST_WORD_MULT: float = 1.3
const FIGHT_OFFENSE_MULT: float = 1.25
const FIGHT_DEFENSE_MULT: float = 1.25
const CONSOLIDATION_REPLAY_BONUS: int = 1
const EXPRESSIVE_INDUCTION_MULT: float = 1.5
const VALENCE_HEAL_SHIELD_MULT: float = 2.0
const VALENCE_BURN_DRAIN_MULT: float = 2.0
const TRANSCRIPTION_SWAP_MULT: float = 1.3
const ERROR_SIGNAL_COMPLETE_BONUS: int = 1
const ERROR_SIGNAL_EMPTY_PENALTY: int = 1

# --- Public Variables ---

var modifier_id: String = ""

# --- Private Variables ---

var _word_history: Dictionary = {}
var _fight_choice: String = ""
var _transcribed_morphemes: Array = []
var _cascade_active_mod: String = ""
var _cascade_pool: Array[String] = []
var _lateral_assignments: Dictionary = {}
var _lateral_next_side: String = "left"
var _original_pos_order: Array = []
var _executive_choice: String = ""
var _conduction_carry: MorphemeData = null
var _words_this_turn: int = 0


# --- Static Factory ---

static func create(id: String) -> RegionModifier:
	var mod := RegionModifier.new()
	mod.modifier_id = id
	return mod


# --- Combat Start ---

## Called once at combat start. ui_callback signature: (action: String, data: Dictionary) -> Variant
func apply_start_of_combat(state: CombatState, ui_callback: Callable) -> void:
	match modifier_id:
		"fight_or_flight":
			# Request player choice: offense or defense
			_fight_choice = ui_callback.call("choose_fight_mode", {
				"options": ["offense", "defense"],
				"offense_desc": "+25% induction",
				"defense_desc": "+25% insulation",
			}) as String
			if _fight_choice == "":
				_fight_choice = "offense"

		"executive_control":
			_executive_choice = ui_callback.call("choose_executive", {
				"options": ["draw", "insulate", "burn"],
				"draw_desc": "Draw 2 extra",
				"insulate_desc": "+2 insulation",
				"burn_desc": "2 BURN to all enemies",
			}) as String
			if _executive_choice == "":
				_executive_choice = "draw"
			_apply_executive_choice(state)

		"transcription":
			_apply_transcription_swap(state)

		"lateralization":
			_assign_lateral_sides(state)

		"receptive_aphasia":
			ui_callback.call("hide_all_pos_labels", {})

		"spatial_mapping":
			# Capture the initial slot POS order so _rotate_pos_slots has something to rotate.
			var initial_order: Variant = ui_callback.call("get_slot_pos_order", {})
			if initial_order is Array:
				_original_pos_order = initial_order as Array

		"cascade":
			# Cascade needs a pool of other region modifiers to draw from
			_cascade_pool = _get_non_cascade_modifiers()


# --- Turn Start ---

## Called each turn start, after CombatState.begin_turn().
func apply_turn_start(state: CombatState, turn: int) -> void:
	_words_this_turn = 0

	match modifier_id:
		"spatial_mapping":
			if turn > 1:  # Don't rotate on first turn
				_rotate_pos_slots(state, turn)

		"valence_shift":
			pass  # Handled in modify_effect_power based on turn parity

		"conduction":
			if _conduction_carry != null:
				state.hand.append(_conduction_carry.duplicate())
				_conduction_carry = null

		"cascade":
			if turn > 1 and turn % 2 == 0 and not _cascade_pool.is_empty():
				_cascade_active_mod = _cascade_pool[randi() % _cascade_pool.size()]
			else:
				_cascade_active_mod = ""

		"executive_control":
			_apply_executive_choice(state)


# --- Induction Modification ---

func modify_induction(base: int, word_index: int, word_form: String) -> int:
	var result: int = base

	match modifier_id:
		"reflex":
			if word_index == 0:
				result = roundi(float(result) * REFLEX_FIRST_WORD_MULT)

		"fight_or_flight":
			if _fight_choice == "offense":
				result = roundi(float(result) * FIGHT_OFFENSE_MULT)

		"consolidation":
			if _word_history.has(word_form):
				result += _word_history[word_form] * CONSOLIDATION_REPLAY_BONUS

		"expressive_aphasia":
			result = roundi(float(result) * EXPRESSIVE_INDUCTION_MULT)

		"transcription":
			# Check if any placed morphemes were transcribed (swapped family)
			# Caller passes word_form; we check if it was built with transcribed morphemes
			# Bonus handled in _has_transcribed_morphemes check at resolve time
			pass

		"cascade":
			if _cascade_active_mod != "":
				result = _cascade_modify_induction(result, word_index, word_form)

	return result


# --- Insulation Modification ---

func modify_insulation(base: int, branch_data: Dictionary) -> int:
	var result: int = base

	match modifier_id:
		"fight_or_flight":
			if _fight_choice == "defense":
				result = roundi(float(result) * FIGHT_DEFENSE_MULT)

		"error_signal":
			var slots: Array = branch_data.get("slots", [])
			var is_complete: bool = branch_data.get("complete", false)
			if is_complete:
				result += slots.size() * ERROR_SIGNAL_COMPLETE_BONUS

		"cascade":
			if _cascade_active_mod != "":
				result = _cascade_modify_insulation(result, branch_data)

	return result


# --- Empty Penalty Modification ---

func modify_empty_penalty(base: int) -> int:
	var result: int = base

	match modifier_id:
		"error_signal":
			result += ERROR_SIGNAL_EMPTY_PENALTY

		"cascade":
			if _cascade_active_mod != "":
				result = _cascade_modify_empty_penalty(result)

	return result


# --- Effect Power Modification ---

## Modifies effect power for specific effect types. Used by EffectManager.
func modify_effect_power(power: int, effect_type: String, turn: int) -> int:
	var result: int = power

	match modifier_id:
		"valence_shift":
			var is_odd_turn: bool = turn % 2 == 1
			if is_odd_turn and (effect_type == "HEAL" or effect_type == "SHIELD"):
				result = roundi(float(result) * VALENCE_HEAL_SHIELD_MULT)
			elif not is_odd_turn and (effect_type == "BURN" or effect_type == "DRAIN"):
				result = roundi(float(result) * VALENCE_BURN_DRAIN_MULT)

		"cascade":
			if _cascade_active_mod == "valence_shift":
				var is_odd: bool = turn % 2 == 1
				if is_odd and (effect_type == "HEAL" or effect_type == "SHIELD"):
					result = roundi(float(result) * VALENCE_HEAL_SHIELD_MULT)
				elif not is_odd and (effect_type == "BURN" or effect_type == "DRAIN"):
					result = roundi(float(result) * VALENCE_BURN_DRAIN_MULT)

	return result


# --- Post-Submit ---

## Called after word submission. Updates internal tracking.
func on_post_submit(word_forms: Array[String]) -> void:
	_words_this_turn += word_forms.size()

	match modifier_id:
		"consolidation":
			for word: String in word_forms:
				if _word_history.has(word):
					_word_history[word] += 1
				else:
					_word_history[word] = 1

		"conduction":
			pass  # Caller sets carry via set_conduction_carry()


# --- Placement Checks ---

func can_place_morpheme(morpheme: MorphemeData, slot_index: int, total_slots: int) -> bool:
	match modifier_id:
		"expressive_aphasia":
			# One word per turn: block placement if already submitted this turn
			if _words_this_turn >= 1:
				return false

		"lateralization":
			var side: String = _get_lateral_side(morpheme)
			var midpoint: int = total_slots / 2
			if side == "left" and slot_index >= midpoint:
				return false
			if side == "right" and slot_index < midpoint:
				return false

		"cascade":
			if _cascade_active_mod == "expressive_aphasia":
				if _words_this_turn >= 1:
					return false
			elif _cascade_active_mod == "lateralization":
				var side: String = _get_lateral_side(morpheme)
				var midpoint: int = total_slots / 2
				if side == "left" and slot_index >= midpoint:
					return false
				if side == "right" and slot_index < midpoint:
					return false

	return true


func can_remove_morpheme() -> bool:
	if modifier_id == "reflex":
		return false
	if modifier_id == "cascade" and _cascade_active_mod == "reflex":
		return false
	return true


func is_transcribed(morpheme: MorphemeData) -> bool:
	return morpheme in _transcribed_morphemes


func set_conduction_carry(morpheme: MorphemeData) -> void:
	_conduction_carry = morpheme


func get_cascade_active() -> String:
	return _cascade_active_mod


func get_original_pos_order() -> Array:
	return _original_pos_order


# --- Private Methods ---

func _apply_executive_choice(state: CombatState) -> void:
	match _executive_choice:
		"draw":
			state.bonus_draw += 2
		"insulate":
			state.add_insulation(2)
		"burn":
			# Set a flag; CombatScreen applies BURN to all enemies
			state.bonus_induction_next_submit += 2


func _apply_transcription_swap(state: CombatState) -> void:
	_transcribed_morphemes.clear()
	if state.hand.size() < 2:
		return

	var families: Array = [
		Enums.MorphemeFamily.GERMANIC,
		Enums.MorphemeFamily.LATINATE,
		Enums.MorphemeFamily.GREEK,
	]

	# Pick 2 random hand morphemes and swap their families
	var indices: Array[int] = []
	var available: Array[int] = []
	for i: int in range(state.hand.size()):
		if state.hand[i].family != Enums.MorphemeFamily.FUNCTIONAL:
			available.append(i)

	for _j: int in range(mini(2, available.size())):
		if available.is_empty():
			break
		var pick: int = randi() % available.size()
		indices.append(available[pick])
		available.remove_at(pick)

	for idx: int in indices:
		var m: MorphemeData = state.hand[idx]
		var other_families: Array = families.filter(
			func(f: Enums.MorphemeFamily) -> bool: return f != m.family
		)
		if not other_families.is_empty():
			m.family = other_families[randi() % other_families.size()]
			_transcribed_morphemes.append(m)


func _assign_lateral_sides(state: CombatState) -> void:
	_lateral_assignments.clear()
	for i: int in range(state.hand.size()):
		var side: String = "left" if i < state.hand.size() / 2 else "right"
		_lateral_assignments[state.hand[i].id] = side


func _get_lateral_side(morpheme: MorphemeData) -> String:
	if _lateral_assignments.has(morpheme.id):
		return _lateral_assignments[morpheme.id]
	# New morphemes drawn mid-combat: alternate sides to avoid deterministic clustering
	if _lateral_next_side == "left":
		_lateral_assignments[morpheme.id] = "left"
		_lateral_next_side = "right"
	else:
		_lateral_assignments[morpheme.id] = "right"
		_lateral_next_side = "left"
	return _lateral_assignments[morpheme.id]


func _rotate_pos_slots(_state: CombatState, _turn: int) -> void:
	if _original_pos_order.is_empty():
		return
	# Rotate: last element moves to front, others shift right.
	# CombatScreen reads the updated order via get_rotated_pos_order() and
	# applies it to SyntaxSlot POS assignments at turn start.
	var last: int = _original_pos_order.pop_back()
	_original_pos_order.push_front(last)


## Returns the current (possibly rotated) POS order for CombatScreen to apply.
func get_rotated_pos_order() -> Array:
	return _original_pos_order


func _get_non_cascade_modifiers() -> Array[String]:
	return [
		"reflex", "fight_or_flight", "consolidation", "receptive_aphasia",
		"expressive_aphasia", "valence_shift", "transcription", "conduction",
		"error_signal", "executive_control", "spatial_mapping", "lateralization",
	]


# --- Cascade Delegation ---

func _cascade_modify_induction(base: int, word_index: int, word_form: String) -> int:
	var result: int = base
	match _cascade_active_mod:
		"reflex":
			if word_index == 0:
				result = roundi(float(result) * REFLEX_FIRST_WORD_MULT)
		"fight_or_flight":
			if _fight_choice == "offense":
				result = roundi(float(result) * FIGHT_OFFENSE_MULT)
		"consolidation":
			if _word_history.has(word_form):
				result += _word_history[word_form] * CONSOLIDATION_REPLAY_BONUS
		"expressive_aphasia":
			result = roundi(float(result) * EXPRESSIVE_INDUCTION_MULT)
	return result


func _cascade_modify_insulation(base: int, branch_data: Dictionary) -> int:
	var result: int = base
	match _cascade_active_mod:
		"fight_or_flight":
			if _fight_choice == "defense":
				result = roundi(float(result) * FIGHT_DEFENSE_MULT)
		"error_signal":
			var slots: Array = branch_data.get("slots", [])
			var is_complete: bool = branch_data.get("complete", false)
			if is_complete:
				result += slots.size() * ERROR_SIGNAL_COMPLETE_BONUS
	return result


func _cascade_modify_empty_penalty(base: int) -> int:
	if _cascade_active_mod == "error_signal":
		return base + ERROR_SIGNAL_EMPTY_PENALTY
	return base
