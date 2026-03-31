class_name LatinLLamedGoadEffect
extends Effect

## L - Lamed's Goad: Incomplete branches with at least one filled slot
## grant +4 induction per empty required slot in that branch, but those
## branches forfeit their branch-complete multiplier.
## Triggers ON_PLAY. Queries CombatState for branch fill data.

@export var bonus_per_empty: int = 4


func execute(context: EffectContext) -> void:
	var bonus: int = context.combat_state.calc_lamed_goad_bonus(bonus_per_empty)
	if bonus <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = bonus
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
