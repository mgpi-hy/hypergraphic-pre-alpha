class_name AlgizEffect
extends Effect

## Algiz (ᛉ): Elk Sedge. +3 insulation at the start of each combat.

@export var insulation_bonus: int = 3


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.GAIN_INSULATION
	action.amount = insulation_bonus
	action.source = context.source
	context.action_queue.enqueue(action)
