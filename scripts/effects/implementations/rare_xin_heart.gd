class_name RareXinHeartEffect
extends Effect

## Xin (心): Heart Radical. Heal 1 cogency per morpheme placed.

func execute(context: EffectContext) -> void:
	var morph_count: int = context.morphemes.size()
	if morph_count <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.HEAL_COGENCY
	action.amount = morph_count
	action.source = context.source
	context.action_queue.enqueue(action)
