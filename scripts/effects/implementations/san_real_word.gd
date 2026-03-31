class_name SanRealWordBonusEffect
extends Effect

## San (archaic): Real English words (dictionary matches, not novel) grant +1 semant.

@export var semant_per_word: int = 1


func execute(context: EffectContext) -> void:
	if context.word.is_empty():
		return
	if context.is_novel_word:
		return
	# Real dictionary word (not novel) = economy bonus
	var action := GameAction.new()
	action.type = Enums.ActionType.GAIN_SEMANT
	action.amount = semant_per_word
	action.source = context.source
	context.action_queue.enqueue(action)
