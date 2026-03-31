class_name RhoDeepDrawEffect
extends Effect

## Rho (R): Start of combat, draw 1 extra. Max hand size +1 permanently this run.

@export var extra_draw: int = 1
@export var hand_size_bonus: int = 1


func execute(context: EffectContext) -> void:
	context.combat_state.increase_hand_size(hand_size_bonus)
	var action := GameAction.new()
	action.type = Enums.ActionType.DRAW_MORPHEME
	action.amount = extra_draw
	action.source = context.source
	context.action_queue.enqueue(action)
