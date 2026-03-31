class_name NuNegationShieldEffect
extends Effect

## Nu (N): Negation affixes (un-, in-, im-, dis-, -less) each grant +3 insulation.

@export var insulation_per_affix: int = 3

var _negation_forms: Array[String] = ["un", "in", "im", "dis", "less"]


func execute(context: EffectContext) -> void:
	var neg_count: int = 0
	for m: MorphemeData in context.morphemes:
		if m.form in _negation_forms:
			neg_count += 1
	if neg_count <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.GAIN_INSULATION
	action.amount = neg_count * insulation_per_affix
	action.source = context.source
	context.action_queue.enqueue(action)
