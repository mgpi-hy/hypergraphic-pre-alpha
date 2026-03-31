class_name WunjoEffect
extends Effect

## Wunjo (ᚹ): Joy of Victory. Heal 3 cogency after defeating any enemy.

@export var heal_amount: int = 3


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.HEAL_COGENCY
	action.amount = heal_amount
	action.source = context.source
	context.action_queue.enqueue(action)
