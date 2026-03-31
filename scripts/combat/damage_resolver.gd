class_name DamageResolver
extends RefCounted

## Calculates the multiplier chain for word submissions and resolves damage.
## Pure math; no Node dependencies. Takes combat state and returns breakdowns
## for the cascade display. See game-spec.md for the multiplier table.

# --- Constants ---

const POS_MATCH_MULT: float = 1.5
const BRANCH_COMPLETE_MULT: float = 2.0
const FULL_TREE_MULT: float = 2.0
const NOVEL_WORD_MULT: float = 1.5
const OPTIONAL_FILLED_MULT: float = 1.5
const FUNCTIONAL_BONUS_MULT: float = 1.25
const FAMILY_MIX_PENALTY: float = 0.75
const FAMILY_MIX_BONUS: float = 1.25  # Frankie's lingua_franca passive
const EMPTY_SLOT_PENALTY: int = 2  # induction reduction per unfilled required slot

# --- Character Passive Constants ---
const ELLIE_ELISION_MULT: float = 1.25        # x1.25 per empty optional slot
const DECLAN_INSULATION_MULT: float = 1.5     # x1.5 insulation multiplier
const PHIL_COMPOUND_ROOT_MULT: float = 1.1    # x1.1 per root (stacking)
const PHIL_INSULATION_DIV: float = 2.0        # halved insulation

# --- Synergy Constants ---
const FAMILY_UNITY_MULT: float = 1.3          # all roots same family, 2+ words
const FULL_AFFIX_MULT: float = 1.2            # word has both prefix and suffix
const SEMANTIC_MASS_HIGH_MULT: float = 1.3    # total morpheme weight > 35
const SEMANTIC_MASS_LOW_MULT: float = 1.15    # total morpheme weight > 20
const SEMANTIC_MASS_HIGH_THRESHOLD: int = 35
const SEMANTIC_MASS_LOW_THRESHOLD: int = 20

# --- Insulation Bonus Constants ---
const INSULATION_FULL_TREE_BONUS: float = 1.5    # +50% insulation for full tree
const INSULATION_ALL_POS_BONUS: float = 1.25     # +25% insulation for all POS matched

# --- Private Variables ---

var _word_validator: WordValidator


# --- Virtual Methods ---

func _init() -> void:
	_word_validator = WordValidator.new()


# --- Public Methods ---

## Resolves word damage from placed morphemes against a syntax tree.
##
## combat_state: current CombatState (for words_used, character, etc.)
## effect_manager: EffectManager for passive polling
## placed_morphemes: flat array of all morphemes placed across the tree
## syntax_tree_data: describes tree structure, expects:
##   "slots": Array[Dictionary] each with:
##     "pos": Enums.POSType, "is_optional": bool, "is_filled": bool,
##     "branch_id": String, "morphemes": Array[MorphemeData]
##
## Returns Dictionary with:
##   base_induction: int, multipliers: Array[Dictionary], final_induction: int,
##   is_novel_word: bool
func resolve_word(
	combat_state: CombatState,
	effect_manager: EffectManager,
	placed_morphemes: Array,
	syntax_tree_data: Dictionary,
	action_queue: ActionQueue = null,
) -> Dictionary:
	var result: Dictionary = {
		"base_induction": 0,
		"multipliers": [],
		"final_induction": 0,
		"insulation_gained": 0,
		"is_novel_word": false,
	}

	if placed_morphemes.is_empty():
		return result

	# --- Step 1: Sum base induction ---
	var base_induction: int = _sum_base_induction(placed_morphemes)
	result["base_induction"] = base_induction

	# --- Step 2: Evaluate multiplier conditions ---
	# Cascade order: per-word -> per-branch -> full tree -> empty slot penalty
	var slots: Array = syntax_tree_data.get("slots", [])
	var multipliers: Array[Dictionary] = []
	var cumulative: float = 1.0

	# --- Per-word multipliers ---

	# 1. POS match: per-slot, each matching slot contributes
	var pos_match_count: int = _count_pos_matches(slots)
	if pos_match_count > 0:
		for i: int in range(pos_match_count):
			multipliers.append({"name": "POS_MATCH", "value": POS_MATCH_MULT})
			cumulative *= POS_MATCH_MULT

	# 2. Optional slot filled
	var optional_filled_count: int = _count_optional_filled(slots)
	if optional_filled_count > 0:
		for i: int in range(optional_filled_count):
			multipliers.append({"name": "OPTIONAL_FILLED", "value": OPTIONAL_FILLED_MULT})
			cumulative *= OPTIONAL_FILLED_MULT

	# 2b. Ellie (Elision) passive: x1.25 per empty optional slot
	var character: CharacterData = combat_state.character
	if character != null and character.id == "french":
		var empty_optional_count: int = _count_empty_optional(slots)
		for i: int in range(empty_optional_count):
			multipliers.append({
				"name": "ELISION",
				"value": ELLIE_ELISION_MULT,
				"color": "#CE93D8",
			})
			cumulative *= ELLIE_ELISION_MULT

	# 3. Novel word detection
	var assembled_word: String = _assemble_full_word(slots)
	var words_used: Array[String] = combat_state.words_used_this_run
	var is_novel: bool = _word_validator.is_novel_word(assembled_word, words_used)
	if is_novel:
		multipliers.append({"name": "NOVEL_WORD", "value": NOVEL_WORD_MULT})
		cumulative *= NOVEL_WORD_MULT
		result["is_novel_word"] = true

	# 4. Family mix (penalty or Frankie bonus); xi code-switcher can cancel penalty
	var family_mult: float = _get_family_mix_multiplier(placed_morphemes, combat_state)
	if combat_state.skip_family_mix_penalty and family_mult < 1.0:
		family_mult = 1.0
		combat_state.skip_family_mix_penalty = false
	if family_mult != 1.0:
		var mix_name: String = "FAMILY_MIX_BONUS" if family_mult > 1.0 else "FAMILY_MIX_PENALTY"
		multipliers.append({"name": mix_name, "value": family_mult})
		cumulative *= family_mult

	# --- Per-branch multipliers ---

	# 5. Branch completion
	var branch_complete: bool = _check_branches_complete(slots)
	if branch_complete:
		multipliers.append({"name": "BRANCH_COMPLETE", "value": BRANCH_COMPLETE_MULT})
		cumulative *= BRANCH_COMPLETE_MULT

	# 6. Functional bonus: any FUNCTIONAL morpheme in the submission
	var has_functional: bool = _has_functional_morpheme(placed_morphemes)
	if has_functional:
		multipliers.append({"name": "FUNCTIONAL_BONUS", "value": FUNCTIONAL_BONUS_MULT})
		cumulative *= FUNCTIONAL_BONUS_MULT

	# --- Full tree ---

	# 7. Full tree bonus
	# Requires all slots filled AND all filled slots POS-matched, consistent
	# with SyntaxTree.is_tree_complete() which checks both conditions.
	var all_slots_arr: Array = slots
	var all_filled: Array = []
	for slot: Dictionary in all_slots_arr:
		all_filled.append(slot.get("is_filled", false))
	var all_pos_match: bool = true
	for slot: Dictionary in all_slots_arr:
		if slot.get("is_filled", false) and not slot.get("is_pos_matched", true):
			all_pos_match = false
			break
	var tree_complete: bool = _word_validator.check_tree_complete(all_slots_arr, all_filled) and all_pos_match
	if tree_complete:
		multipliers.append({"name": "FULL_TREE", "value": FULL_TREE_MULT})
		cumulative *= FULL_TREE_MULT

	# --- Character passives (multiplier phase) ---

	# Phil (Compounding) passive: x1.1 per root, starting at 2 roots (capped at 4)
	if character != null and character.id == "greek":
		var root_count: int = _count_roots(placed_morphemes)
		if root_count >= 2:
			var capped_count: int = mini(root_count, 4)
			var phil_mult: float = pow(PHIL_COMPOUND_ROOT_MULT, capped_count)
			multipliers.append({
				"name": "COMPOUND",
				"value": phil_mult,
				"color": "#00F090",
			})
			cumulative *= phil_mult

	# --- Synergy multipliers ---

	# Family Unity: all roots in the word share the same family AND 2+ words this turn
	var all_roots_same_family: bool = _check_all_roots_same_family(placed_morphemes)
	if all_roots_same_family and combat_state.words_submitted_this_turn >= 1:
		multipliers.append({
			"name": "UNITY",
			"value": FAMILY_UNITY_MULT,
			"color": "#FFD54F",
		})
		cumulative *= FAMILY_UNITY_MULT

	# Full Affix: this word has both a prefix AND a suffix
	if _has_prefix_and_suffix(placed_morphemes):
		multipliers.append({
			"name": "FULL_AFFIX",
			"value": FULL_AFFIX_MULT,
			"color": "#80D8FF",
		})
		cumulative *= FULL_AFFIX_MULT

	# Semantic Mass: total base_induction across all placed morphemes
	var total_weight: int = _sum_base_induction(placed_morphemes)
	if total_weight > SEMANTIC_MASS_HIGH_THRESHOLD:
		multipliers.append({
			"name": "MASS",
			"value": SEMANTIC_MASS_HIGH_MULT,
			"color": "#FF8A65",
		})
		cumulative *= SEMANTIC_MASS_HIGH_MULT
	elif total_weight > SEMANTIC_MASS_LOW_THRESHOLD:
		multipliers.append({
			"name": "MASS",
			"value": SEMANTIC_MASS_LOW_MULT,
			"color": "#FF8A65",
		})
		cumulative *= SEMANTIC_MASS_LOW_MULT

	result["multipliers"] = multipliers

	# --- Empty slot penalty (reduces induction, not cogency) ---
	var empty_required_count: int = _count_empty_required(slots)
	var empty_penalty_per_slot: int = EMPTY_SLOT_PENALTY

	# Region modifier: adjust per-slot empty penalty
	var region_mod: RegionModifier = combat_state.region_modifier
	if region_mod:
		empty_penalty_per_slot = region_mod.modify_empty_penalty(empty_penalty_per_slot)

	var empty_penalty: int = empty_required_count * empty_penalty_per_slot
	if empty_penalty > 0:
		multipliers.append({
			"label": "EMPTY",
			"value": -empty_penalty,
			"is_flat": true,
			"color": "#FF1E40",
		})

	# --- Step 3: Apply empty slot penalty to induction (flat subtraction) ---
	var pre_penalty: int = roundi(float(base_induction) * cumulative)
	var final_after_penalty: int = maxi(pre_penalty - empty_penalty, 0)

	# --- Step 3b: Region modifier induction adjustment ---
	if region_mod:
		var word_index: int = combat_state.words_submitted_this_turn
		final_after_penalty = region_mod.modify_induction(
			final_after_penalty, word_index, assembled_word
		)

	# --- Step 4: Let passives modify the value ---
	var context: EffectContext = EffectContext.from_combat(combat_state, action_queue, null)
	context.damage_amount = final_after_penalty
	context.word = assembled_word
	context.is_novel_word = is_novel
	var final_induction: int = effect_manager.apply_passives(final_after_penalty, context)
	result["final_induction"] = final_induction

	# --- Ken (Kenning) passive: steal cogency = induction / 2 if 2+ NOUN roots ---
	if character != null and character.id == "old_english":
		var noun_root_count: int = _count_noun_roots(placed_morphemes)
		if noun_root_count >= 2:
			result["kenning_heal"] = final_induction / 2

	# --- Step 5: Calculate insulation from functional/hybrid morphemes ---
	var base_insulation: int = calculate_insulation(placed_morphemes, character)

	# Insulation bonus: full tree completion = +50%
	if tree_complete:
		base_insulation = roundi(base_insulation * INSULATION_FULL_TREE_BONUS)

	# Insulation bonus: all POS matched = +25%
	if all_pos_match:
		base_insulation = roundi(base_insulation * INSULATION_ALL_POS_BONUS)

	# Region modifier: adjust insulation
	if region_mod:
		var branch_info: Dictionary = {
			"slots": slots,
			"complete": branch_complete,
		}
		base_insulation = region_mod.modify_insulation(base_insulation, branch_info)

	result["insulation_gained"] = base_insulation

	return result


## Calculate insulation value from placed morphemes.
## Insulation = sum of base_induction for all FUNCTIONAL and HYBRID morphemes.
## Character passives applied here: Ken = 0 always, Declan = x1.5, Phil = /2.
func calculate_insulation(placed_morphemes: Array, character: CharacterData = null) -> int:
	# Ken (Kenning): no insulation -- he steals cogency instead
	if character != null and character.id == "old_english":
		return 0

	var total: int = 0
	for m: MorphemeData in placed_morphemes:
		if m.combat_role == MorphemeData.CombatRole.FUNCTIONAL or m.combat_role == MorphemeData.CombatRole.HYBRID:
			total += m.base_induction

	# Declan (Declension): x1.5 insulation
	if character != null and character.id == "latin":
		total = roundi(float(total) * DECLAN_INSULATION_MULT)

	# Phil (Compounding): halved insulation
	if character != null and character.id == "greek":
		total = roundi(float(total) / PHIL_INSULATION_DIV)

	return total


## Resolves enemy damage against the player, applying insulation absorption.
## Returns the cogency damage taken after insulation absorbs what it can.
func resolve_enemy_damage(base_damage: int, combat_state: CombatState) -> int:
	if base_damage <= 0:
		return 0

	var insulation: int = combat_state.player_insulation
	if insulation >= base_damage:
		# Insulation absorbs all damage
		combat_state.player_insulation -= base_damage
		return 0

	# Insulation absorbs partial damage; remainder hits cogency
	var remaining: int = base_damage - insulation
	combat_state.player_insulation = 0
	return remaining


# --- Private Methods ---

## Sums base_induction from all placed morphemes.
func _sum_base_induction(morphemes: Array) -> int:
	var total: int = 0
	for m: MorphemeData in morphemes:
		total += m.base_induction
	return total


## Counts slots where morpheme POS matches slot POS.
func _count_pos_matches(slots: Array) -> int:
	var count: int = 0
	for slot: Dictionary in slots:
		if not slot.get("is_filled", false):
			continue
		var slot_pos: int = slot.get("pos", -1)
		var morphemes: Array = slot.get("morphemes", [])
		for m: MorphemeData in morphemes:
			if m.type == MorphemeData.MorphemeType.ROOT and m.pos_type == slot_pos:
				count += 1
				break
	return count


## Counts optional slots that have been filled.
func _count_optional_filled(slots: Array) -> int:
	var count: int = 0
	for slot: Dictionary in slots:
		if slot.get("is_optional", false) and slot.get("is_filled", false):
			count += 1
	return count


## Assembles the full word string from all filled slots.
func _assemble_full_word(slots: Array) -> String:
	var all_morphemes: Array[MorphemeData] = []
	for slot: Dictionary in slots:
		if not slot.get("is_filled", false):
			continue
		var morphemes: Array = slot.get("morphemes", [])
		for m: MorphemeData in morphemes:
			all_morphemes.append(m)
	return _word_validator.assemble_word(all_morphemes)


## Checks whether all branches in the tree are complete.
func _check_branches_complete(slots: Array) -> bool:
	var branches: Dictionary = {}  # branch_id -> {"slots": [], "filled": []}
	for slot: Dictionary in slots:
		var branch_id: String = slot.get("branch_id", "default")
		if not branches.has(branch_id):
			branches[branch_id] = {"slots": [], "filled": []}
		branches[branch_id]["slots"].append(slot)
		branches[branch_id]["filled"].append(slot.get("is_filled", false))

	if branches.is_empty():
		return false

	for branch_id: String in branches:
		var branch: Dictionary = branches[branch_id]
		if not _word_validator.check_branch_complete(branch["slots"], branch["filled"]):
			return false
	return true


## Returns the family mix multiplier for a set of placed morphemes.
## Frankie gets a bonus for mixing; everyone else gets a penalty per off-family morpheme.
func _get_family_mix_multiplier(morphemes: Array, combat_state: CombatState) -> float:
	var mix_info: Dictionary = _word_validator.get_family_mix_info(morphemes)
	if not mix_info["is_mixed"]:
		return 1.0

	# Frankie's passive: bonus for mixing families
	var character: CharacterData = combat_state.character
	if character != null and character.id == "english":
		return FAMILY_MIX_BONUS

	# Everyone else: penalty for off-family morphemes
	# Count off-family morphemes for stacking penalty
	var off_family_count: int = 0
	if character != null:
		for m: MorphemeData in morphemes:
			if m.combat_role == MorphemeData.CombatRole.FUNCTIONAL:
				continue
			if not character.is_family_allowed(m.family):
				off_family_count += 1

	if off_family_count == 0:
		return 1.0

	# x0.75 per off-family morpheme, stacking multiplicatively
	var penalty: float = 1.0
	for i: int in range(off_family_count):
		penalty *= FAMILY_MIX_PENALTY
	return penalty


## Returns true if any morpheme has a FUNCTIONAL combat role.
func _has_functional_morpheme(morphemes: Array) -> bool:
	for m: MorphemeData in morphemes:
		if m.combat_role == MorphemeData.CombatRole.FUNCTIONAL:
			return true
	return false


## Counts unfilled required (non-optional) slots.
func _count_empty_required(slots: Array) -> int:
	var count: int = 0
	for slot: Dictionary in slots:
		if not slot.get("is_optional", false) and not slot.get("is_filled", false):
			count += 1
	return count


## Counts empty (unfilled) optional slots.
func _count_empty_optional(slots: Array) -> int:
	var count: int = 0
	for slot: Dictionary in slots:
		if slot.get("is_optional", false) and not slot.get("is_filled", false):
			count += 1
	return count


## Counts ROOT morphemes in the placed set.
func _count_roots(morphemes: Array) -> int:
	var count: int = 0
	for m: MorphemeData in morphemes:
		if m.type == MorphemeData.MorphemeType.ROOT:
			count += 1
	return count


## Counts ROOT morphemes whose pos_type is NOUN.
func _count_noun_roots(morphemes: Array) -> int:
	var count: int = 0
	for m: MorphemeData in morphemes:
		if m.type == MorphemeData.MorphemeType.ROOT and m.pos_type == Enums.POSType.NOUN:
			count += 1
	return count


## Returns true if all non-FUNCTIONAL roots share the same family.
## Returns false if there are no roots (nothing to unify).
func _check_all_roots_same_family(morphemes: Array) -> bool:
	var first_family: int = -1
	for m: MorphemeData in morphemes:
		if m.type != MorphemeData.MorphemeType.ROOT:
			continue
		if m.combat_role == MorphemeData.CombatRole.FUNCTIONAL:
			continue
		if first_family == -1:
			first_family = m.family
		elif m.family != first_family:
			return false
	return first_family != -1


## Returns true if the placed morphemes include at least one PREFIX and one SUFFIX.
func _has_prefix_and_suffix(morphemes: Array) -> bool:
	var has_prefix: bool = false
	var has_suffix: bool = false
	for m: MorphemeData in morphemes:
		if m.type == MorphemeData.MorphemeType.PREFIX:
			has_prefix = true
		elif m.type == MorphemeData.MorphemeType.SUFFIX:
			has_suffix = true
		if has_prefix and has_suffix:
			return true
	return false
