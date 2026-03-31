class_name EhwazEffect
extends Effect

## Ehwaz (ᛖ): Word Swap. Once per turn, swap positions of 2 placed words
## in the syntax tree.

var _used_this_turn: bool = false


func activate(_context: EffectContext) -> void:
	_used_this_turn = false


func can_trigger(_context: EffectContext) -> bool:
	return not _used_this_turn


func execute(context: EffectContext) -> void:
	_used_this_turn = true
	context.combat_state.set_word_swap_available(true)
