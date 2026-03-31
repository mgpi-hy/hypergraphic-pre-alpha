class_name RareTavCovenantEffect
extends Effect

## Tav (ת): Covenant Mark. Track unique words submitted this run;
## after 10, permanently +2 induction to all words.

@export var threshold: int = 10
@export var induction_bonus: int = 2

var _unique_words: Array[String] = []
var _threshold_reached: bool = false


func activate(_context: EffectContext) -> void:
	_unique_words.clear()
	_threshold_reached = false


func can_trigger(context: EffectContext) -> bool:
	return context.word != ""


func execute(context: EffectContext) -> void:
	if not _threshold_reached:
		if not _unique_words.has(context.word):
			_unique_words.append(context.word)
			if _unique_words.size() >= threshold:
				_threshold_reached = true
	if _threshold_reached:
		var action := GameAction.new()
		action.type = Enums.ActionType.DEAL_DAMAGE
		action.amount = induction_bonus
		action.source = context.source
		action.target = context.target
		context.action_queue.enqueue(action)
