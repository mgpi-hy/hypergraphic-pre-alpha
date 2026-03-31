class_name PhiRootLatticeEffect
extends Effect

## Phi (F): STARTER (Phil). Each root beyond the first in a single word
## grants +2 induction to that word.

@export var bonus_per_extra_root: int = 2


func execute(context: EffectContext) -> void:
	var root_count: int = 0
	for m: MorphemeData in context.morphemes:
		if m.type == "root":
			root_count += 1
	if root_count <= 1:
		return
	var extra_roots: int = root_count - 1
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = extra_roots * bonus_per_extra_root
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
