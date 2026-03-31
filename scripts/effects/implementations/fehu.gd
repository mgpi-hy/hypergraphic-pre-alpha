class_name FehuEffect
extends Effect

## Fehu (ᚠ): Cattle Price. +2 semant from every combat victory.

@export var semant_bonus: int = 2


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.GAIN_SEMANT
	action.amount = semant_bonus
	action.source = context.source
	context.action_queue.enqueue(action)
