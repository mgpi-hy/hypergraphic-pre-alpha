class_name WordBlock
extends RefCounted

## A word assembled from morphemes placed in a syntax slot.
## Result of combining prefix + root + suffix. Pure data, no Node dependencies.

# --- Fields ---

var form: String = ""
var parts: Array[MorphemeData] = []
var output_pos: Enums.POSType = Enums.POSType.NOUN
var induction: int = 0
var insulation: int = 0
var is_novel: bool = false
var is_pos_matched: bool = false
var has_mixed_families: bool = false
var family_set: Array[Enums.MorphemeFamily] = []


# --- Static Factory ---

static func from_morphemes(morpheme_parts: Array[MorphemeData], required_pos: Enums.POSType) -> WordBlock:
	var wb := WordBlock.new()
	wb.parts = morpheme_parts

	if morpheme_parts.is_empty():
		return wb

	# Form: concatenate root_text, stripping leading/trailing hyphens
	var form_pieces: PackedStringArray = []
	for m: MorphemeData in morpheme_parts:
		if m.root_text.is_empty():
			continue
		var cleaned: String = m.root_text.strip_edges()
		cleaned = cleaned.trim_prefix("-").trim_suffix("-")
		form_pieces.append(cleaned)
	wb.form = "".join(form_pieces)

	# Induction: sum base_induction for CONTENT and HYBRID
	# Insulation: sum base_induction for FUNCTIONAL and HYBRID
	for m: MorphemeData in morpheme_parts:
		var role: MorphemeData.CombatRole = m.combat_role
		if role == MorphemeData.CombatRole.CONTENT or role == MorphemeData.CombatRole.HYBRID:
			wb.induction += m.base_induction
		if role == MorphemeData.CombatRole.FUNCTIONAL or role == MorphemeData.CombatRole.HYBRID:
			wb.insulation += m.base_induction

	# Output POS: rightmost morpheme's pos_type (suffixes determine POS)
	for m: MorphemeData in morpheme_parts:
		wb.output_pos = m.pos_type

	# Novel: not in the known word dictionary
	wb.is_novel = not WordDictionary.is_known(wb.form)

	# POS match: output POS matches the required slot POS
	wb.is_pos_matched = (wb.output_pos == required_pos)

	# Family analysis: unique non-FUNCTIONAL families
	var seen: Dictionary = {}
	for m: MorphemeData in morpheme_parts:
		if m.combat_role == MorphemeData.CombatRole.FUNCTIONAL:
			continue
		if not seen.has(m.family):
			seen[m.family] = true
			wb.family_set.append(m.family)
	wb.has_mixed_families = wb.family_set.size() > 1

	return wb
