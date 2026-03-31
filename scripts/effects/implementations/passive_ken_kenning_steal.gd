class_name PassiveKenKenningStealEffect
extends Effect

## Ken (Kenning): Words with 2+ noun roots (kennings) steal cogency
## equal to half the word's induction.

@export var min_noun_roots: int = 2


func can_trigger(context: EffectContext) -> bool:
	var noun_roots: int = 0
	for m: MorphemeData in context.morphemes:
		if m.type == "root" and m.has_pos_tag("noun"):
			noun_roots += 1
	return noun_roots >= min_noun_roots


func execute(context: EffectContext) -> void:
	var steal_amount: int = maxi(context.damage_amount / 2, 1)
	var action := GameAction.new()
	action.type = Enums.ActionType.HEAL_COGENCY
	action.amount = steal_amount
	action.source = context.source
	context.action_queue.enqueue(action)
