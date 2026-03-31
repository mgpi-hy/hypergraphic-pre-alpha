class_name EpsilonEscalationEffect
extends Effect

## Epsilon (E): If the second word scores higher than the first, the third word
## gets +2 induction. Rewards escalating word quality within a turn.

@export var bonus: int = 2


func can_trigger(context: EffectContext) -> bool:
	if context.combat_state.words_submitted_this_turn < 3:
		return false
	var scores: Array[int] = context.combat_state.word_scores_this_turn
	return scores.size() >= 2 and scores[1] > scores[0]


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = bonus
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
