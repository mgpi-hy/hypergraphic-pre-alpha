class_name LatinZOverkillCarryEffect
extends Effect

## Z - Overkill Carry: Overkill damage carries to another enemy; if none,
## heal excess as cogency. Triggers ON_ENEMY_DEFEATED.


func execute(context: EffectContext) -> void:
	var overkill: int = context.combat_state.get_overkill_amount(context.target)
	if overkill <= 0:
		return
	# Try to carry to next enemy
	var next_enemy: Node = context.combat_state.get_next_alive_enemy(context.target)
	if next_enemy != null:
		var action := GameAction.new()
		action.type = Enums.ActionType.DEAL_DAMAGE
		action.amount = overkill
		action.source = context.source
		action.target = next_enemy
		context.action_queue.enqueue(action)
	else:
		# No enemies left; heal cogency
		var heal := GameAction.new()
		heal.type = Enums.ActionType.HEAL_COGENCY
		heal.amount = overkill
		heal.source = context.source
		context.action_queue.enqueue(heal)
