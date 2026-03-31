class_name LatinSShinTeethEffect
extends Effect

## S - Shin's Teeth: When hit by an enemy attack, gain a temporary
## "spite" root morpheme in hand (any-POS, +3 induction). Spite roots
## expire at next turn start. Triggers ON_DAMAGE_TAKEN.


func can_trigger(context: EffectContext) -> bool:
	return context.damage_amount > 0


func execute(context: EffectContext) -> void:
	context.combat_state.spawn_spite_morpheme()
