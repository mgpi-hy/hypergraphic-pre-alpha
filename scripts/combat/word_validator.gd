class_name WordValidator
extends RefCounted

## Validates words assembled in the syntax tree during combat.
## Checks POS matching, branch/tree completion, novel word detection,
## and word assembly from placed morphemes. Pure logic; no Node dependencies.


# --- Public Methods ---

## Returns true if the morpheme's POS type matches the slot's required POS.
func validate_placement(morpheme: MorphemeData, slot_pos: Enums.POSType) -> bool:
	return morpheme.pos_type == slot_pos


## Validates a complete word assembled from placed morphemes.
## Returns a breakdown dictionary for use by DamageResolver and UI.
func validate_word(placed_morphemes: Array[MorphemeData], slot_pos: Enums.POSType, words_used: Array[String]) -> Dictionary:
	var result: Dictionary = {
		"is_valid": false,
		"word": "",
		"pos_matches": [],
		"has_novel": false,
		"error": "",
	}

	if placed_morphemes.is_empty():
		result["error"] = "No morphemes placed"
		return result

	# Must have at least one root
	var has_root: bool = false
	for m: MorphemeData in placed_morphemes:
		if m.type == MorphemeData.MorphemeType.ROOT:
			has_root = true
			break

	if not has_root:
		result["error"] = "No root morpheme found"
		return result

	var word: String = assemble_word(placed_morphemes)
	if word.is_empty():
		result["error"] = "Assembled word is empty"
		return result

	# Check POS match for each morpheme
	var pos_matches: Array[bool] = []
	for m: MorphemeData in placed_morphemes:
		pos_matches.append(m.pos_type == slot_pos)

	var is_novel: bool = is_novel_word(word, words_used)

	result["is_valid"] = true
	result["word"] = word
	result["pos_matches"] = pos_matches
	result["has_novel"] = is_novel
	return result


## Concatenates root texts to form the assembled word string.
## Affixes modify meaning but roots form the base word for display and lookup.
func assemble_word(placed_morphemes: Array[MorphemeData]) -> String:
	var parts: PackedStringArray = []
	for m: MorphemeData in placed_morphemes:
		if m.root_text.is_empty():
			continue
		parts.append(m.root_text)
	return "".join(parts).to_lower()


## Returns true if the word has not been used this run.
func is_novel_word(word: String, words_used: Array[String]) -> bool:
	if word.is_empty():
		return false
	var lower: String = word.to_lower()
	return not words_used.has(lower)


## Returns true if all required (non-optional) slots in a branch are filled.
## slots: array of slot dictionaries with "is_optional" and "is_filled" keys.
func check_branch_complete(slots: Array, filled: Array) -> bool:
	if slots.is_empty():
		return false
	if slots.size() != filled.size():
		push_warning("WordValidator.check_branch_complete: slots/filled size mismatch")
		return false
	for i: int in range(slots.size()):
		var slot: Dictionary = slots[i]
		var is_filled: bool = filled[i]
		# Required slots must be filled for branch completion
		if not slot.get("is_optional", false) and not is_filled:
			return false
	return true


## Returns true if every slot in the tree (required + optional) is filled.
func check_tree_complete(all_slots: Array, all_filled: Array) -> bool:
	if all_slots.is_empty():
		return false
	if all_slots.size() != all_filled.size():
		push_warning("WordValidator.check_tree_complete: slots/filled size mismatch")
		return false
	for i: int in range(all_slots.size()):
		if not all_filled[i]:
			return false
	return true


## Returns the family mix info for a set of morphemes.
## Returns a dictionary with "is_mixed" and "family_count" keys.
func get_family_mix_info(morphemes: Array[MorphemeData]) -> Dictionary:
	var families: Dictionary = {}
	for m: MorphemeData in morphemes:
		# Functional morphemes don't count toward family mixing
		if m.combat_role == MorphemeData.CombatRole.FUNCTIONAL:
			continue
		if not families.has(m.family):
			families[m.family] = 0
		families[m.family] += 1

	return {
		"is_mixed": families.size() > 1,
		"family_count": families.size(),
		"families": families,
	}
