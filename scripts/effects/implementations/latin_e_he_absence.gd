class_name LatinEHeAbsenceEffect
extends Effect

## E - He's Absence (Ellie Starter): Each unfilled optional slot at submit
## grants +2 insulation. Rewards minimalist play.

@export var insulation_per_empty: int = 2


func execute(context: EffectContext) -> void:
	var empty_optionals: int = context.combat_state.count_empty_optional_slots()
	if empty_optionals <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.GAIN_INSULATION
	action.amount = empty_optionals * insulation_per_empty
	action.source = context.source
	context.action_queue.enqueue(action)
