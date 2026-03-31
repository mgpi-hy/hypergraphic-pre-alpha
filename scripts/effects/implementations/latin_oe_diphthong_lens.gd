class_name LatinOEDiphthongLensEffect
extends Effect

## OE (Ethel) - Diphthong Lens: Words with both a prefix AND suffix
## get +4 induction. Triggers ON_WORD_FORMED per word.

@export var bonus_induction: int = 4


func can_trigger(context: EffectContext) -> bool:
	var has_prefix: bool = false
	var has_suffix: bool = false
	for m: MorphemeData in context.morphemes:
		if m.type == "prefix":
			has_prefix = true
		elif m.type == "suffix":
			has_suffix = true
	return has_prefix and has_suffix


func execute(context: EffectContext) -> void:
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = bonus_induction
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
