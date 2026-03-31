class_name RareAlephSilentOriginEffect
extends Effect

## Aleph (א): Silent Origin. Bare roots (no affixes) x1.3 induction.
## Tier 2: modifier flag on word-formed context.

@export var bare_root_multiplier: float = 1.3


func can_trigger(context: EffectContext) -> bool:
	if context.morphemes.is_empty():
		return false
	# Only roots, no affixes
	for m: MorphemeData in context.morphemes:
		if m.type == "prefix" or m.type == "suffix":
			return false
	return true


func execute(context: EffectContext) -> void:
	context.combat_state.set_next_word_multiplier(bare_root_multiplier)
