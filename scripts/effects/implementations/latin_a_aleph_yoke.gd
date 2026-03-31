class_name LatinAAlephYokeEffect
extends Effect

## A - Aleph's Yoke: +1 induction per root placed this submit.
## Triggers ON_WORD_FORMED for each word; counts roots in the word
## and enqueues bonus damage.

@export var bonus_per_root: int = 1


func execute(context: EffectContext) -> void:
	var root_count: int = 0
	for m: MorphemeData in context.morphemes:
		if m.type == "root":
			root_count += 1
	if root_count <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = root_count * bonus_per_root
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
