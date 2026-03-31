class_name LatinTHRemnantScriptEffect
extends Effect

## TH (Thorn) - Remnant Script: Germanic morphemes grant +3 induction.
## Triggers ON_WORD_FORMED per word. Counts Germanic morphemes in the word.

@export var bonus_per_germanic: int = 3


func execute(context: EffectContext) -> void:
	var germanic_count: int = 0
	for m: MorphemeData in context.morphemes:
		if m.family == "germanic":
			germanic_count += 1
	if germanic_count <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = germanic_count * bonus_per_germanic
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
