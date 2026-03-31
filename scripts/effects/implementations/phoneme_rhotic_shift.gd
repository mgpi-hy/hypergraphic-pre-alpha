class_name PhonemeRhoticShiftEffect
extends Effect

## Turned R (ɹ): Rhotic Shift. Reroll all empty slot POS types.
## If 2+ now match your hand, draw 1.

@export var match_threshold: int = 2
@export var bonus_draw: int = 1


func execute(context: EffectContext) -> void:
	var matches: int = context.combat_state.reroll_empty_slot_pos()
	if matches >= match_threshold:
		var action := GameAction.new()
		action.type = Enums.ActionType.DRAW_MORPHEME
		action.amount = bonus_draw
		action.source = context.source
		context.action_queue.enqueue(action)
