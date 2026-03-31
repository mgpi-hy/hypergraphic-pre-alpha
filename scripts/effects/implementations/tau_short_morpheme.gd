class_name TauShortMorphemeEffect
extends Effect

## Tau (T): Morphemes with exactly 3 letters get +1 induction.

@export var target_length: int = 3
@export var bonus: int = 1


func execute(context: EffectContext) -> void:
	var count: int = 0
	for m: MorphemeData in context.morphemes:
		if m.form.length() == target_length:
			count += 1
	if count <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = count * bonus
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
