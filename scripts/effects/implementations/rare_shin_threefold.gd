class_name RareShinThreefoldEffect
extends Effect

## Shin (ש): Threefold Fire. Words with exactly 3 morphemes
## (prefix + root + suffix) get +5 induction.

@export var induction_bonus: int = 5


func can_trigger(context: EffectContext) -> bool:
	if context.morphemes.size() != 3:
		return false
	var has_prefix: bool = false
	var has_root: bool = false
	var has_suffix: bool = false
	for m: MorphemeData in context.morphemes:
		if m.type == "prefix":
			has_prefix = true
		elif m.type == "root":
			has_root = true
		elif m.type == "suffix":
			has_suffix = true
	return has_prefix and has_root and has_suffix


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = induction_bonus
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
