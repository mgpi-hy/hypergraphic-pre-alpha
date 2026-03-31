class_name GeboEffect
extends Effect

## Gebo (ᚷ): Gift Exchange. Discard hand without submitting = gain 3 insulation.

@export var insulation_bonus: int = 3


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.GAIN_INSULATION
	action.amount = insulation_bonus
	action.source = context.source
	context.action_queue.enqueue(action)
