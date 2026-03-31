class_name LatinDDalethBulwarkEffect
extends Effect

## D - Daleth's Bulwark (Declan Starter): At end of turn, if insulation > 0,
## gain +2 insulation. Rewards maintaining your wall.

@export var insulation_bonus: int = 2


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.player_insulation > 0


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.GAIN_INSULATION
	action.amount = insulation_bonus
	action.source = context.source
	context.action_queue.enqueue(action)
