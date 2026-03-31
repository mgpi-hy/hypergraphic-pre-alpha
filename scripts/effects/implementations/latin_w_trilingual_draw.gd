class_name LatinWTrilingualDrawEffect
extends Effect

## W - Trilingual Draw: Hand has 3+ families at turn start = draw 1 extra.
## Triggers ON_TURN_START. Checks family diversity in current hand.

@export var family_threshold: int = 3
@export var extra_draw: int = 1


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.hand_family_count() >= family_threshold


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.DRAW_MORPHEME
	action.amount = extra_draw
	action.source = context.source
	context.action_queue.enqueue(action)
