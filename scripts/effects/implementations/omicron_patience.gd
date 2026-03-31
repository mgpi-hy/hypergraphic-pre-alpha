class_name OmicronPatienceShieldEffect
extends Effect

## Omicron (O): Complete a turn without filling all POS slots = +3 insulation.

@export var insulation_bonus: int = 3


func can_trigger(context: EffectContext) -> bool:
	return not context.combat_state.all_pos_slots_filled()


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.GAIN_INSULATION
	action.amount = insulation_bonus
	action.source = context.source
	context.action_queue.enqueue(action)
