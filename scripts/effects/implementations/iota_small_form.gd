class_name IotaSmallFormEffect
extends Effect

## Iota (I): When you play a morpheme with 3 or fewer letters, draw 1 morpheme.

@export var max_letters: int = 3
@export var draw_count: int = 1


func can_trigger(context: EffectContext) -> bool:
	for m: MorphemeData in context.morphemes:
		if m.form.length() <= max_letters:
			return true
	return false


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.DRAW_MORPHEME
	action.amount = draw_count
	action.source = context.source
	context.action_queue.enqueue(action)
