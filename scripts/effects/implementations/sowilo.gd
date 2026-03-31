class_name SowiloEffect
extends Effect

## Sowilo (ᛊ): Solar Flare. Full tree submit = deal 5 damage to ALL enemies.

@export var aoe_damage: int = 5


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.is_full_tree


func execute(context: EffectContext) -> void:
	var enemies: Array[Node] = context.combat_state.get_alive_enemies()
	for enemy: Node in enemies:
		var action := GameAction.new()
		action.type = Enums.ActionType.DEAL_DAMAGE
		action.amount = aoe_damage
		action.source = context.source
		action.target = enemy
		context.action_queue.enqueue(action)
