class_name SigmaSummationEffect
extends Effect

## Sigma (S): +1 induction per morpheme placed this submit (all words combined).


func execute(context: EffectContext) -> void:
	var morph_count: int = context.morphemes.size()
	if morph_count <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = morph_count
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
