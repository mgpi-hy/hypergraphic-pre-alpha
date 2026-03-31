class_name RareYanSpeechActEffect
extends Effect

## Yan (言): Speech Act. Words with 4+ morphemes echo: deal 50% again.

@export var echo_percent: float = 0.5
@export var morpheme_threshold: int = 4


func can_trigger(context: EffectContext) -> bool:
	return context.morphemes.size() >= morpheme_threshold


func execute(context: EffectContext) -> void:
	var echo_amount: int = maxi(context.damage_amount / 2, 1)
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = echo_amount
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
