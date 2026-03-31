class_name BetaNeuralCoatEffect
extends Effect

## Beta (B): Start of turn, gain insulation equal to morphemes in hand.


func execute(context: EffectContext) -> void:
	var hand_count: int = context.combat_state.hand_size()
	if hand_count <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.GAIN_INSULATION
	action.amount = hand_count
	action.source = context.source
	context.action_queue.enqueue(action)
