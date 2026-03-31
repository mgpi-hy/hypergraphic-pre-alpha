class_name LatinFWawBridgeEffect
extends Effect

## F - Waw's Bridge (Frankie Starter): 2+ families on tree, each family
## beyond the first grants +3 induction to all words.
## Triggers ON_PLAY. Counts distinct morpheme families across all placed
## morphemes and enqueues bonus damage.

@export var induction_per_extra_family: int = 3


func execute(context: EffectContext) -> void:
	var families: Dictionary = {}
	for m: MorphemeData in context.morphemes:
		families[m.family] = true
	var extra: int = maxi(families.size() - 1, 0)
	if extra <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = extra * induction_per_extra_family
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
