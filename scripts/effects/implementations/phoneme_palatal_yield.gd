class_name PhonemePalatalYieldEffect
extends Effect

## Palatal Nasal (ɲ): Palatal Yield. Gain 5 semant. Discard 1
## random morpheme from hand.

@export var semant_gain: int = 5
@export var discard_count: int = 1


func execute(context: EffectContext) -> void:
	var semant_action := GameAction.new()
	semant_action.type = Enums.ActionType.GAIN_SEMANT
	semant_action.amount = semant_gain
	semant_action.source = context.source
	context.action_queue.enqueue(semant_action)

	var discard_action := GameAction.new()
	discard_action.type = Enums.ActionType.DISCARD_MORPHEME
	discard_action.amount = discard_count
	discard_action.source = context.source
	context.action_queue.enqueue(discard_action)
