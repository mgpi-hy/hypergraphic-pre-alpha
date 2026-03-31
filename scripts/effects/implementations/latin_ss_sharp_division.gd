class_name LatinSSSharpDivisionEffect
extends Effect

## SS (Eszett) - Sharp Division: Enemy below 10 cogency = your induction
## is doubled this submit. Triggers ON_PLAY as an interceptor that checks
## enemy HP before damage resolves.

@export var hp_threshold: int = 10


func can_trigger(context: EffectContext) -> bool:
	if context.target == null:
		return false
	return context.combat_state.get_target_cogency(context.target) < hp_threshold


func execute(context: EffectContext) -> void:
	context.combat_state.set_next_word_multiplier(2.0)
