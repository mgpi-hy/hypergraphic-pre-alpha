class_name LatinRReshCrownEffect
extends Effect

## R - Resh's Crown: Highest-induction word each submit gets +25%.
## Triggers ON_PLAY. Only fires when 2+ words are placed (otherwise
## there's no "highest" to distinguish).

@export var bonus_pct: float = 0.25


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.placed_word_count() > 1


func execute(context: EffectContext) -> void:
	var best_induction: int = context.combat_state.highest_word_induction()
	var bonus: int = int(best_induction * bonus_pct)
	if bonus <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = bonus
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
