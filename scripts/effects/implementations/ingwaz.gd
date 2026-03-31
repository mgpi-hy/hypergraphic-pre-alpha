class_name IngwazEffect
extends Effect

## Ingwaz (ᛜ): Branch Heal. Complete a branch = heal 2 cogency.

@export var heal_amount: int = 2


func execute(context: EffectContext) -> void:
	var completed: int = context.combat_state.get_completed_branches_count()
	if completed <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.HEAL_COGENCY
	action.amount = heal_amount * completed
	action.source = context.source
	context.action_queue.enqueue(action)
