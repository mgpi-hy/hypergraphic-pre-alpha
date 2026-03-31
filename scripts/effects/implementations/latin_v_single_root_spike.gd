class_name LatinVSingleRootSpikeEffect
extends Effect

## V - Single Root Spike: Single-morpheme words (bare root) deal
## +5 induction. Triggers ON_WORD_FORMED for each word.

@export var bonus_induction: int = 5


func can_trigger(context: EffectContext) -> bool:
	return context.morphemes.size() == 1


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = bonus_induction
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
