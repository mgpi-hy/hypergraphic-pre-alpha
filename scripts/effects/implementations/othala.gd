class_name OthalaEffect
extends Effect

## Othala (ᛟ): Native Mastery. Words entirely from character's native family
## get x1.25 multiplier (Frankie gets x1.1 instead).

@export var native_multiplier: float = 1.25
@export var polyglot_multiplier: float = 1.1


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.is_word_all_native(context.word)


func execute(context: EffectContext) -> void:
	var mult: float = polyglot_multiplier if context.combat_state.is_polyglot_character() else native_multiplier
	context.combat_state.add_word_multiplier(mult)
