class_name PhonemeDentalShieldEffect
extends Effect

## Theta (θ): Dental Shield. Gain 15 insulation. If already
## above 10, gain 5 instead.

@export var full_bonus: int = 15
@export var reduced_bonus: int = 5
@export var threshold: int = 10


func execute(context: EffectContext) -> void:
	var amount: int = full_bonus
	if context.combat_state.player_insulation > threshold:
		amount = reduced_bonus
	var action := GameAction.new()
	action.type = Enums.ActionType.GAIN_INSULATION
	action.amount = amount
	action.source = context.source
	context.action_queue.enqueue(action)
