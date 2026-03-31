class_name PhonemePharyngealCopyEffect
extends Effect

## Pharyngeal (ħ): Pharyngeal Copy. Duplicate last placed word.
## If the copy is a novel word, x1.5 bonus.

@export var novel_multiplier: float = 1.5


func execute(context: EffectContext) -> void:
	context.combat_state.duplicate_last_placed_word(novel_multiplier)
