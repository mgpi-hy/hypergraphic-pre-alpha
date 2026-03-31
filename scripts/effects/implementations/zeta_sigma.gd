class_name ZetaCompoundForceEffect
extends Effect

## Zeta (Z): Words with 3+ morphemes get +3 induction.

@export var morpheme_threshold: int = 3
@export var bonus: int = 3


func can_trigger(context: EffectContext) -> bool:
	return context.morphemes.size() >= morpheme_threshold


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = bonus
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
