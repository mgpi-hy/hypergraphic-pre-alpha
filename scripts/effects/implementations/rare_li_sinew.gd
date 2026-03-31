class_name RareLiSinewEffect
extends Effect

## Li (力): Sinew Force. +1 induction per word submitted this turn
## (1st = +1, 2nd = +2, 3rd = +3). Resets each turn.

var _words_this_turn: int = 0


func activate(_context: EffectContext) -> void:
	_words_this_turn = 0


func execute(context: EffectContext) -> void:
	_words_this_turn += 1
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = _words_this_turn
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
