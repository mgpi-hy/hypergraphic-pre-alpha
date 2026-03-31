class_name RareLongDragonCostEffect
extends Effect

## Long (龍): Dragon Scale combat start cost. Lose 3 cogency at
## start of each combat.

@export var cogency_cost: int = 3


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.LOSE_COGENCY
	action.amount = cogency_cost
	action.source = context.source
	context.action_queue.enqueue(action)
