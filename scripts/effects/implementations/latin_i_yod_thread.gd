class_name LatinIYodThreadEffect
extends Effect

## I - Yod's Thread: 3+ affixes this submit = +2 induction per affix
## beyond the 2nd. Triggers ON_PLAY, counts total affixes across all
## placed words.

@export var threshold: int = 3
@export var bonus_per_extra: int = 2


func execute(context: EffectContext) -> void:
	var affix_count: int = 0
	for m: MorphemeData in context.morphemes:
		if m.type == "prefix" or m.type == "suffix":
			affix_count += 1
	if affix_count < threshold:
		return
	var bonus: int = (affix_count - (threshold - 1)) * bonus_per_extra
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = bonus
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
