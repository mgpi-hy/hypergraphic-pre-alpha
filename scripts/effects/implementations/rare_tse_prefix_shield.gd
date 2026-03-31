class_name RareTsePrefixShieldEffect
extends Effect

## Tse (Ц): Prefix Shield. First prefix placed each turn grants
## +1 insulation.

@export var insulation_bonus: int = 1

var _used_this_turn: bool = false


func activate(_context: EffectContext) -> void:
	_used_this_turn = false


func can_trigger(_context: EffectContext) -> bool:
	return not _used_this_turn


func execute(context: EffectContext) -> void:
	# Check if any morpheme in context is a prefix
	var has_prefix: bool = false
	for m: MorphemeData in context.morphemes:
		if m.type == "prefix":
			has_prefix = true
			break
	if not has_prefix:
		return
	_used_this_turn = true
	var action := GameAction.new()
	action.type = Enums.ActionType.GAIN_INSULATION
	action.amount = insulation_bonus
	action.source = context.source
	context.action_queue.enqueue(action)
