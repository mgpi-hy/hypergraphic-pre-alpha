class_name PhonemeAshPulseEffect
extends Effect

## Ash (æ): Ash Pulse. If insulation is 0, gain 20. If above 0,
## double it but lose 5 cogency.

@export var zero_bonus: int = 20
@export var cogency_cost: int = 5


func execute(context: EffectContext) -> void:
	if context.combat_state.player_insulation <= 0:
		var action := GameAction.new()
		action.type = Enums.ActionType.GAIN_INSULATION
		action.amount = zero_bonus
		action.source = context.source
		context.action_queue.enqueue(action)
	else:
		# Double current insulation
		var current: int = context.combat_state.player_insulation
		var gain_action := GameAction.new()
		gain_action.type = Enums.ActionType.GAIN_INSULATION
		gain_action.amount = current
		gain_action.source = context.source
		context.action_queue.enqueue(gain_action)
		# Lose cogency
		var cost_action := GameAction.new()
		cost_action.type = Enums.ActionType.LOSE_COGENCY
		cost_action.amount = cogency_cost
		cost_action.source = context.source
		context.action_queue.enqueue(cost_action)
