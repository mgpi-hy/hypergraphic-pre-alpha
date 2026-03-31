class_name ThurisazEffect
extends Effect

## Thurisaz (ᚦ): Thorn Wall. When insulation absorbs damage, deal 2 back.

@export var reflect_damage: int = 2


func can_trigger(context: EffectContext) -> bool:
	return context.damage_amount > 0 and context.combat_state.player_insulation > 0


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = reflect_damage
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
