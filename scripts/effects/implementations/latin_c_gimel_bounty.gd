class_name LatinCGimelBountyEffect
extends Effect

## C - Gimel's Bounty: Each unique POS type submitted grants +1 semant.
## Triggers ON_PLAY after submission. Counts distinct POS types among
## placed words and enqueues semant gain.

@export var semant_per_pos: int = 1


func execute(context: EffectContext) -> void:
	var pos_types: Array[String] = []
	for m: MorphemeData in context.morphemes:
		if m.type == "root":
			for tag: String in m.pos_tags:
				if not pos_types.has(tag):
					pos_types.append(tag)
	if pos_types.is_empty():
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.GAIN_SEMANT
	action.amount = pos_types.size() * semant_per_pos
	action.source = context.source
	context.action_queue.enqueue(action)
