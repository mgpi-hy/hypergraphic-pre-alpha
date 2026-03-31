class_name RareJinGoldenEffect
extends Effect

## Jin (金): Golden Yield. +1 semant per multiplier activated
## on submission.

func execute(context: EffectContext) -> void:
	var mult_count: int = context.combat_state.get_multiplier_count()
	if mult_count <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.GAIN_SEMANT
	action.amount = mult_count
	action.source = context.source
	context.action_queue.enqueue(action)
