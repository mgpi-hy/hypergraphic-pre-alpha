class_name CombatState
extends RefCounted

## Central data object for all transient combat state.
## Holds player vitals, deck (via DeckManager), enemy refs, turn tracking,
## modifier flags, word tracking, and combat stats. Pure data + methods.
## No Node dependencies, no signals, no UI.

# --- Constants ---

const DEFAULT_MAX_COGENCY: int = 50

# --- Player Vitals ---

var player_cogency: int = DEFAULT_MAX_COGENCY
var max_cogency: int = DEFAULT_MAX_COGENCY
var player_insulation: int = 0
var semant: int = 0

# --- Deck Management (delegated to DeckManager) ---

var deck: DeckManager = DeckManager.new()

# --- Enemy State ---

var enemies: Array = []
var active_enemy_index: int = 0

# --- Region Modifier ---

var region_modifier: RegionModifier = null

# --- Turn Tracking ---

var current_turn: int = 1
var is_player_turn: bool = true
var words_submitted_this_turn: int = 0
var word_scores_this_turn: Array[int] = []
var word_forms_this_turn: Array[String] = []

# --- Modifier Flags (Tier 2: set by effects, consumed by resolvers) ---

var next_word_multiplier: float = 1.0
var next_affix_multiplier: float = 1.0
var bonus_draw: int = 0
var bonus_induction_next_submit: int = 0
var persistent_induction_bonus: int = 0
var multiplier_bonus: float = 0.0
var submit_multiplier: float = 1.0
var optional_slot_multiplier: float = 0.0
var mem_tide_bonus: int = 0
var shop_discount: int = 0

# --- Boolean Flags (Tier 2) ---

var force_pos_match: bool = false          ## berkano: first root POS-matched
var frozen_syntax: bool = false            ## isa: tree layout persists
var reveal_thresholds: bool = false        ## kenaz: enemy HP thresholds visible
var lambda_active: bool = false            ## lambda: recursive resubmit
var round_up: bool = false                 ## pi: round multiplied values up
var wild_draw_replacement: bool = false    ## perthro: random draw replacement
var auto_slot_enabled: bool = false        ## laguz: auto-slot to best POS
var induction_preview_visible: bool = false ## ayn: real-time preview
var word_swap_available: bool = false      ## ehwaz: swap word positions
var he_window_available: bool = false      ## he window: swap root from hand
var kaph_retain: bool = false              ## kaph: retain hand between turns
var beth_threshold_pending: bool = false   ## beth: opening hand choice
var pe_echo_pending: bool = false          ## pe: repeat last word at half
var tav_mark_reward: bool = false          ## tav: extra reward on first kill
var null_submit_available: bool = false    ## latin Y: submit empty tree
var ayin_gaze_available: bool = false      ## ayin: exile + draw this turn
var lateral_drift_active: bool = false     ## phoneme: all morph match any POS
var exile_heaviest_drawn: bool = false     ## schwa: exile heaviest drawn
var sibilant_germanic_mult: float = 0.0   ## sibilant burst: germanic mult
var sibilant_fallback_mult: float = 0.0   ## sibilant burst: fallback mult
var is_full_tree: bool = false             ## all syntax tree slots filled
var skip_family_mix_penalty: bool = false   ## xi: cancel family mix penalty this word

# --- Run Context (copied from RunData at init) ---

var character: CharacterData = null    ## the run's character (for family checks)
var floors_cleared: int = 0
var grapheme_count_cache: int = 0
var _grapheme_id_set: Dictionary = {}      ## cached grapheme IDs for has_grapheme()

# --- Novel Word Tracking ---

var words_used_this_run: Array[String] = []
var words_used_this_combat: Array[String] = []

# --- Combat Stats ---

var total_induction_dealt: int = 0
var total_insulation_gained: int = 0
var enemies_defeated: int = 0
var words_submitted: int = 0
var novel_words_found: int = 0

# --- Highlight Stats (juice: best moments for post-combat display) ---

var best_word_form: String = ""
var best_word_induction: int = 0
var peak_multiplier: float = 1.0

# --- Combo ---

var combo_count: int = 0  # Consecutive submits without holding

# --- Private: Syntax Tree Cache ---

var _cached_empty_optional_slots: int = 0
var _cached_all_required_filled: bool = false
var _cached_any_optional_filled: bool = false
var _cached_placed_word_count: int = 0
var _cached_highest_word_induction: int = 0
var _cached_any_words_share_family: bool = false
var _cached_all_roots_family: String = ""
var _cached_word_family_mixed: bool = false
var _cached_native_words: Array[String] = []
var _cached_is_polyglot: bool = false
var _cached_completed_branches: int = 0
var _cached_empty_affix_slots: int = 0
var _cached_multiplier_count: int = 0

# --- Enemy Mechanic Pending Flags (set by EnemyController, consumed by CombatScreen) ---

var pending_scramble: int = 0          ## swap slot POS types
var pending_silence: int = 0           ## lock syntax slots
var pending_lock: int = 0              ## lock player actions
var pending_grow_branch: int = 0       ## add extra syntax slots
var pending_hide_pos: bool = false     ## hide POS labels
var pending_shift_tree: int = 0        ## shift tree layout
var pending_force_place: int = 0       ## force morpheme placement
var pending_shrink_hand: int = 0       ## reduce hand size temporarily
var pending_halve_hand: bool = false   ## discard half the hand
var pending_cancel_novel: bool = false ## suppress novel word bonus
var pending_steal_morpheme: int = 0    ## steal a placed morpheme
var cancel_novel_bonus: bool = false   ## set true when novel bonus is suppressed this turn

# --- Private: Pending UI Operations ---

var _pending_morpheme_swap: bool = false
var _pending_morphemic_drift: bool = false
var _pending_ayin_gaze: bool = false
var _pending_spite_spawn: bool = false
var _pending_force_submit: bool = false
var _pending_wildcard_slot: bool = false
var _pending_wildcard_draw: int = 0
var _pending_optional_slot: bool = false
var _pending_burn_slot: bool = false
var _pending_hand_discard_swap: bool = false
var _pending_swap_pos_bonus: float = 0.0
var _pending_double_attack: bool = false
var _pending_duplicate_word: bool = false
var _pending_duplicate_mult: float = 0.0
var _pending_reroll_slots: bool = false
var _pending_clear_words: bool = false


# --- Initialization ---

## Populate combat state from run data at combat start.
func init_from_run(run_data: RunData) -> void:
	player_cogency = run_data.cogency
	max_cogency = run_data.max_cogency
	semant = run_data.semant
	character = run_data.character
	var starter_size: int = DeckManager.DEFAULT_HAND_SIZE
	if run_data.character:
		starter_size = run_data.character.starter_hand_size
	deck.init_from_deck(run_data.deck, starter_size)
	# unlocked_roots are permanently unlocked morpheme forms, not words used this run.
	# Novel word detection compares against this list, so seeding it with unlocked_roots
	# would suppress every unlocked root as "already seen." Start empty each combat.
	if run_data.get("words_used_this_run") != null:
		words_used_this_run = run_data.words_used_this_run.duplicate()
	else:
		words_used_this_run = []
	floors_cleared = run_data.current_region_index * 17 + run_data.current_column
	grapheme_count_cache = run_data.acquired_graphemes.size()
	_grapheme_id_set.clear()
	for grapheme: GraphemeData in run_data.acquired_graphemes:
		_grapheme_id_set[grapheme.id] = true
	if run_data.next_combat_extra_insulation > 0:
		player_insulation = run_data.next_combat_extra_insulation
	if run_data.next_combat_extra_draw > 0:
		bonus_draw = run_data.next_combat_extra_draw
	_reset_combat_stats()


## Write combat results back to run data at combat end.
func apply_to_run(run_data: RunData) -> void:
	run_data.cogency = player_cogency
	run_data.semant = semant
	# Persist novel word history so the next combat knows what words are no longer novel.
	run_data.words_used_this_run = words_used_this_run.duplicate()
	run_data.increment_stat("damage_dealt", total_induction_dealt)
	run_data.increment_stat("words_submitted", words_submitted)
	run_data.increment_stat("novel_words", novel_words_found)
	run_data.increment_stat("enemies_defeated", enemies_defeated)
	run_data.next_combat_extra_insulation = 0
	run_data.next_combat_extra_draw = 0
	# Track best-ever highlight stats across the run
	var prev_best: int = run_data.get_stat("best_word_induction")
	if best_word_induction > prev_best:
		run_data.combat_stats["best_word_induction"] = best_word_induction
		run_data.combat_stats["best_word_form"] = best_word_form
	var prev_peak: float = run_data.combat_stats.get("peak_multiplier", 1.0)
	if peak_multiplier > prev_peak:
		run_data.combat_stats["peak_multiplier"] = peak_multiplier


# --- Deck Delegation (forwarding to DeckManager) ---

func draw_morphemes(count: int) -> void: deck.draw_morphemes(count)
func discard_morpheme(morpheme: MorphemeData) -> void: deck.discard_morpheme(morpheme)
func discard_morphemes(count: int) -> void: deck.discard_morphemes(count)
func shuffle_discard_into_draw() -> void: deck.shuffle_discard_into_draw()
func shuffle_draw_pile() -> void: deck.shuffle_draw_pile()
func exhaust_morpheme(morpheme: MorphemeData) -> void: deck.exhaust_morpheme(morpheme)
func recall_all_discards() -> void: deck.recall_all_discards()
func duplicate_random_discard_to_hand() -> void: deck.duplicate_random_discard_to_hand()
func hand_size() -> int: return deck.hand_size()
func draw_pile_size() -> int: return deck.draw_pile_size()
func discard_pile_size() -> int: return deck.discard_pile_size()
func hand_family_count() -> int: return deck.hand_family_count()
func increase_hand_size(bonus: int) -> void: deck.increase_hand_size(bonus)

# --- Compatibility Properties ---
## Forwarding properties so existing code that reads combat_state.hand,
## .draw_pile, etc. keeps working without changes.

var draw_pile: Array[MorphemeData]:
	get: return deck.draw_pile
	set(value): deck.draw_pile = value

var hand: Array[MorphemeData]:
	get: return deck.hand
	set(value): deck.hand = value

var discard_pile: Array[MorphemeData]:
	get: return deck.discard_pile
	set(value): deck.discard_pile = value

var exhaust_pile: Array[MorphemeData]:
	get: return deck.exhaust_pile
	set(value): deck.exhaust_pile = value

var max_hand_size: int:
	get: return deck.max_hand_size
	set(value): deck.max_hand_size = value


# --- Player Vitals ---

func deal_damage(amount: int, target: Node) -> void:
	if amount <= 0:
		return
	total_induction_dealt += amount
	if target and target.has_method("take_damage"):
		target.take_damage(amount)


func add_insulation(amount: int) -> void:
	player_insulation = maxi(player_insulation + amount, 0)
	if amount > 0:
		total_insulation_gained += amount


func lose_cogency(amount: int) -> void:
	if amount <= 0:
		return
	player_cogency = maxi(player_cogency - amount, 0)


func heal_cogency(amount: int) -> void:
	if amount <= 0:
		return
	player_cogency = mini(player_cogency + amount, max_cogency)


func add_semant(amount: int) -> void:
	semant = maxi(semant + amount, 0)


func add_multiplier(amount: int) -> void:
	multiplier_bonus += float(amount)


# --- Modifier Setters (Tier 2) ---

func set_next_word_multiplier(mult: float) -> void: next_word_multiplier = mult
func set_next_affix_multiplier(mult: float) -> void: next_affix_multiplier = mult
func set_bonus_draw_next_turn(draws: int) -> void: bonus_draw += draws
func add_extra_draw_next_turn(draws: int) -> void: bonus_draw += draws
func set_bonus_induction_next_submit(amount: int) -> void: bonus_induction_next_submit += amount
func set_persistent_induction_bonus(amount: int) -> void: persistent_induction_bonus = amount
func add_multiplier_bonus(amount: float) -> void: multiplier_bonus += amount
func add_submit_multiplier(mult: float) -> void: submit_multiplier *= mult
func set_optional_slot_multiplier(mult: float) -> void: optional_slot_multiplier = mult
func set_mem_tide_bonus(amount: int) -> void: mem_tide_bonus = amount
func set_shop_discount(amount: int) -> void: shop_discount = amount
func set_force_pos_match(value: bool) -> void: force_pos_match = value
func set_frozen_syntax(value: bool) -> void: frozen_syntax = value
func set_reveal_thresholds(value: bool) -> void: reveal_thresholds = value
func set_lambda_active(value: bool) -> void: lambda_active = value
func set_round_up(value: bool) -> void: round_up = value
func set_wild_draw_replacement(value: bool) -> void: wild_draw_replacement = value
func set_auto_slot_enabled(value: bool) -> void: auto_slot_enabled = value
func set_induction_preview_visible(value: bool) -> void: induction_preview_visible = value
func set_word_swap_available(value: bool) -> void: word_swap_available = value
func set_he_window_available(value: bool) -> void: he_window_available = value
func set_kaph_retain(value: bool) -> void: kaph_retain = value
func set_beth_threshold_pending(value: bool) -> void: beth_threshold_pending = value
func set_pe_echo_pending(value: bool) -> void: pe_echo_pending = value
func set_tav_mark_reward(value: bool) -> void: tav_mark_reward = value
func set_null_submit_available(value: bool) -> void: null_submit_available = value
func set_ayin_gaze_available(value: bool) -> void: ayin_gaze_available = value
func set_lateral_drift_active(value: bool) -> void: lateral_drift_active = value
func set_exile_heaviest_drawn(value: bool) -> void: exile_heaviest_drawn = value

func set_sibilant_burst(germanic_mult: float, fallback_mult: float) -> void:
	sibilant_germanic_mult = germanic_mult
	sibilant_fallback_mult = fallback_mult

func set_yod_crown_wild_slot(_mult: float) -> void: pass
func increase_relic_cap(_amount: int) -> void: pass


# --- Syntax Tree Queries ---

func count_empty_optional_slots() -> int: return _cached_empty_optional_slots
func all_required_filled() -> bool: return _cached_all_required_filled
func any_optional_filled() -> bool: return _cached_any_optional_filled
func all_pos_slots_filled() -> bool: return is_full_tree
func placed_word_count() -> int: return _cached_placed_word_count
func highest_word_induction() -> int: return _cached_highest_word_induction
func any_words_share_family() -> bool: return _cached_any_words_share_family
func all_roots_are_family(family_name: String) -> bool: return _cached_all_roots_family == family_name
func is_current_word_family_mixed() -> bool: return _cached_word_family_mixed
func is_word_all_native(word: String) -> bool: return word in _cached_native_words
func is_polyglot_character() -> bool: return _cached_is_polyglot
func get_completed_branches_count() -> int: return _cached_completed_branches
func calc_lamed_goad_bonus(per_empty: int) -> int: return _cached_empty_affix_slots * per_empty
func get_multiplier_count() -> int: return _cached_multiplier_count
func grapheme_count() -> int: return grapheme_count_cache
func has_grapheme(gid: String) -> bool: return _grapheme_id_set.has(gid)
func cancel_family_mix_penalty() -> void: skip_family_mix_penalty = true


# --- Enemy Setup ---

## Populate the enemies array from EnemyController instances.
func set_enemies(enemy_list: Array) -> void:
	enemies = enemy_list


# --- Enemy Queries ---

func alive_enemy_count() -> int:
	var count: int = 0
	for enemy: Variant in enemies:
		if enemy and enemy.has_method("is_alive") and enemy.is_alive():
			count += 1
	return count


func get_target_cogency(target: Node) -> int:
	if target and target.has_method("get_cogency"):
		return target.get_cogency()
	return 0


func get_overkill_amount(target: Node) -> int:
	if target and target.has_method("get_cogency"):
		return maxi(-target.get_cogency(), 0)
	return 0


func get_next_alive_enemy(after: Node) -> Node:
	var found: bool = false
	for enemy: Variant in enemies:
		if enemy == after:
			found = true
			continue
		if found and enemy and enemy.has_method("is_alive") and enemy.is_alive():
			return enemy as Node
	return null


func get_alive_enemies() -> Array:
	var result: Array = []
	for enemy: Variant in enemies:
		if enemy and enemy.has_method("is_alive") and enemy.is_alive():
			result.append(enemy)
	return result


# --- Enemy Operations ---

## After an enemy is defeated, advance active_enemy_index to the next living enemy.
func advance_to_next_alive_enemy() -> void:
	for i: int in range(enemies.size()):
		var idx: int = (active_enemy_index + 1 + i) % enemies.size()
		if idx < enemies.size():
			var enemy: Variant = enemies[idx]
			if enemy and not enemy.is_defeated:
				active_enemy_index = idx
				return


func deal_damage_to_all_enemies(amount: int, _source: Node) -> void:
	for enemy: Variant in enemies:
		if enemy and enemy.has_method("is_alive") and enemy.is_alive():
			deal_damage(amount, enemy as Node)


func reroll_all_enemy_intents() -> void:
	for enemy: Variant in enemies:
		if enemy and enemy.has_method("reroll_intent"):
			enemy.reroll_intent()


func shuffle_enemy_order() -> void:
	enemies.shuffle()


func weaken_target_enemy(turns: int) -> void:
	if active_enemy_index < 0 or active_enemy_index >= enemies.size():
		return
	var enemy: Variant = enemies[active_enemy_index]
	if enemy and enemy.has_method("apply_weaken"):
		enemy.apply_weaken(turns)


# --- UI-Driven Operations (set flags for CombatScreen to consume) ---

func request_morpheme_swap() -> void:
	_pending_morpheme_swap = true

func request_morphemic_drift() -> void:
	_pending_morphemic_drift = true

func trigger_ayin_gaze_exile() -> void:
	_pending_ayin_gaze = true

func spawn_spite_morpheme() -> void:
	_pending_spite_spawn = true

func force_submit_tree() -> void:
	_pending_force_submit = true

func add_wildcard_slot(greek_bonus_draw: int) -> void:
	_pending_wildcard_slot = true
	_pending_wildcard_draw = greek_bonus_draw

func add_optional_slot_to_longest_branch() -> void:
	_pending_optional_slot = true

func set_burn_slot_from_highest_word() -> void:
	_pending_burn_slot = true

func swap_hand_discard_roots(pos_bonus: float) -> void:
	_pending_hand_discard_swap = true
	_pending_swap_pos_bonus = pos_bonus

func set_random_enemy_double_attack() -> void:
	_pending_double_attack = true

func duplicate_last_placed_word(novel_mult: float) -> void:
	_pending_duplicate_word = true
	_pending_duplicate_mult = novel_mult

func reroll_empty_slot_pos() -> int:
	_pending_reroll_slots = true
	return 0

func clear_all_placed_words() -> int:
	_pending_clear_words = true
	return _cached_placed_word_count

func add_word_multiplier(mult: float) -> void:
	submit_multiplier *= mult


# --- Pending Operation Consumers (CombatScreen polls these) ---

func consume_pending_morpheme_swap() -> bool:
	var v: bool = _pending_morpheme_swap
	_pending_morpheme_swap = false
	return v

func consume_pending_morphemic_drift() -> bool:
	var v: bool = _pending_morphemic_drift
	_pending_morphemic_drift = false
	return v

func consume_pending_ayin_gaze() -> bool:
	var v: bool = _pending_ayin_gaze
	_pending_ayin_gaze = false
	return v

func consume_pending_spite_spawn() -> bool:
	var v: bool = _pending_spite_spawn
	_pending_spite_spawn = false
	return v

func consume_pending_force_submit() -> bool:
	var v: bool = _pending_force_submit
	_pending_force_submit = false
	return v

func consume_pending_wildcard_slot() -> Dictionary:
	if not _pending_wildcard_slot:
		return {}
	_pending_wildcard_slot = false
	var d: Dictionary = {"draw": _pending_wildcard_draw}
	_pending_wildcard_draw = 0
	return d

func consume_pending_optional_slot() -> bool:
	var v: bool = _pending_optional_slot
	_pending_optional_slot = false
	return v

func consume_pending_burn_slot() -> bool:
	var v: bool = _pending_burn_slot
	_pending_burn_slot = false
	return v

func consume_pending_hand_discard_swap() -> Dictionary:
	if not _pending_hand_discard_swap:
		return {}
	_pending_hand_discard_swap = false
	var d: Dictionary = {"pos_bonus": _pending_swap_pos_bonus}
	_pending_swap_pos_bonus = 0.0
	return d

func consume_pending_double_attack() -> bool:
	var v: bool = _pending_double_attack
	_pending_double_attack = false
	return v

func consume_pending_duplicate_word() -> Dictionary:
	if not _pending_duplicate_word:
		return {}
	_pending_duplicate_word = false
	var d: Dictionary = {"mult": _pending_duplicate_mult}
	_pending_duplicate_mult = 0.0
	return d

func consume_pending_reroll_slots() -> bool:
	var v: bool = _pending_reroll_slots
	_pending_reroll_slots = false
	return v

func consume_pending_clear_words() -> bool:
	var v: bool = _pending_clear_words
	_pending_clear_words = false
	return v


# --- Turn Lifecycle ---

## Reset per-turn state at player turn start.
func begin_turn() -> void:
	current_turn += 1
	is_player_turn = true
	words_submitted_this_turn = 0
	word_scores_this_turn.clear()
	word_forms_this_turn.clear()
	force_pos_match = false
	word_swap_available = false
	he_window_available = false
	ayin_gaze_available = false
	lateral_drift_active = false
	exile_heaviest_drawn = false
	sibilant_germanic_mult = 0.0
	sibilant_fallback_mult = 0.0
	submit_multiplier = 1.0
	skip_family_mix_penalty = false
	bonus_induction_next_submit += mem_tide_bonus
	mem_tide_bonus = 0
	_clear_pending_flags()


func record_word_submitted(word: String, score: int) -> void:
	words_submitted += 1
	words_submitted_this_turn += 1
	word_scores_this_turn.append(score)
	word_forms_this_turn.append(word)
	words_used_this_combat.append(word)
	if word not in words_used_this_run:
		words_used_this_run.append(word)
		novel_words_found += 1
	if score > best_word_induction:
		best_word_induction = score
		best_word_form = word


func consume_next_word_multiplier() -> float:
	var m: float = next_word_multiplier
	next_word_multiplier = 1.0
	return m


func consume_next_affix_multiplier() -> float:
	var m: float = next_affix_multiplier
	next_affix_multiplier = 1.0
	return m


func consume_bonus_induction() -> int:
	var b: int = bonus_induction_next_submit
	bonus_induction_next_submit = 0
	return b


func consume_bonus_draw() -> int:
	var d: int = bonus_draw
	bonus_draw = 0
	return d


func record_enemy_defeated() -> void:
	enemies_defeated += 1


# --- Combo ---

func increment_combo() -> void:
	combo_count += 1


func reset_combo() -> void:
	combo_count = 0


func get_combo() -> int:
	return combo_count


# --- Syntax Tree Cache Update ---

func update_tree_cache(
	empty_optional: int,
	all_required: bool,
	any_optional: bool,
	placed_words: int,
	highest_induction: int,
	share_family: bool,
	all_roots_family: String,
	word_mixed: bool,
	native_words: Array[String],
	is_polyglot: bool,
	completed_branches: int,
	empty_affix: int,
	mult_count: int,
	full_tree: bool,
) -> void:
	_cached_empty_optional_slots = empty_optional
	_cached_all_required_filled = all_required
	_cached_any_optional_filled = any_optional
	_cached_placed_word_count = placed_words
	_cached_highest_word_induction = highest_induction
	_cached_any_words_share_family = share_family
	_cached_all_roots_family = all_roots_family
	_cached_word_family_mixed = word_mixed
	_cached_native_words = native_words
	_cached_is_polyglot = is_polyglot
	_cached_completed_branches = completed_branches
	_cached_empty_affix_slots = empty_affix
	_cached_multiplier_count = mult_count
	is_full_tree = full_tree


# --- Private ---

func _reset_combat_stats() -> void:
	total_induction_dealt = 0
	total_insulation_gained = 0
	enemies_defeated = 0
	words_submitted = 0
	novel_words_found = 0
	combo_count = 0
	best_word_form = ""
	best_word_induction = 0
	peak_multiplier = 1.0
	words_used_this_combat.clear()
	current_turn = 0
	words_submitted_this_turn = 0
	word_scores_this_turn.clear()
	word_forms_this_turn.clear()


func _clear_pending_flags() -> void:
	_pending_morpheme_swap = false
	_pending_morphemic_drift = false
	_pending_ayin_gaze = false
	_pending_spite_spawn = false
	_pending_force_submit = false
	_pending_wildcard_slot = false
	_pending_wildcard_draw = 0
	_pending_optional_slot = false
	_pending_burn_slot = false
	_pending_hand_discard_swap = false
	_pending_swap_pos_bonus = 0.0
	_pending_double_attack = false
	_pending_duplicate_word = false
	_pending_duplicate_mult = 0.0
	_pending_reroll_slots = false
	_pending_clear_words = false
	# Enemy mechanic flags
	pending_scramble = 0
	pending_silence = 0
	pending_lock = 0
	pending_grow_branch = 0
	pending_hide_pos = false
	pending_shift_tree = 0
	pending_force_place = 0
	pending_shrink_hand = 0
	pending_halve_hand = false
	pending_cancel_novel = false
	pending_steal_morpheme = 0
	cancel_novel_bonus = false
