class_name KappaInitialEchoEffect
extends Effect

## Kappa (K): If a morpheme shares its first letter with the previously placed
## morpheme, gain +1 induction.

@export var bonus: int = 1


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.words_submitted_this_turn >= 2


func execute(context: EffectContext) -> void:
	var scores: Array[String] = context.combat_state.word_forms_this_turn
	if scores.size() < 2:
		return
	var current: String = scores[scores.size() - 1]
	var previous: String = scores[scores.size() - 2]
	if current.length() == 0 or previous.length() == 0:
		return
	if current[0] != previous[0]:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = bonus
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
