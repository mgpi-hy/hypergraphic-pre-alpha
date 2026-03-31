class_name ChiMorphemeSwapEffect
extends Effect

## Chi (C): Start of turn, swap 1 hand morpheme with 1 from draw pile.
## Player sees both and chooses. Once per turn.

var _used_this_turn: bool = false


func activate(_context: EffectContext) -> void:
	_used_this_turn = false


func can_trigger(context: EffectContext) -> bool:
	return not _used_this_turn \
		and context.combat_state.hand_size() > 0 \
		and context.combat_state.draw_pile_size() > 0


func execute(context: EffectContext) -> void:
	_used_this_turn = true
	context.combat_state.request_morpheme_swap()
