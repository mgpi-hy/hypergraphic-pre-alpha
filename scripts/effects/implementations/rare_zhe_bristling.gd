class_name RareZheBristlingEffect
extends Effect

## Zhe (Ж): Bristling. Facing 2+ enemies = +3 induction to all words.
## +5 if no insulation.

@export var base_bonus: int = 3
@export var no_insulation_bonus: int = 5


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.alive_enemy_count() >= 2


func execute(context: EffectContext) -> void:
	var bonus: int = base_bonus
	if context.combat_state.player_insulation <= 0:
		bonus = no_insulation_bonus
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = bonus
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
