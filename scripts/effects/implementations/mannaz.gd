class_name MannazEffect
extends Effect

## Mannaz (ᛗ): Novel Induction. Novel words grant +3 flat induction in
## addition to the standard novel word multiplier.

@export var novel_bonus: int = 3


func can_trigger(context: EffectContext) -> bool:
	return context.is_novel_word


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = novel_bonus
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
