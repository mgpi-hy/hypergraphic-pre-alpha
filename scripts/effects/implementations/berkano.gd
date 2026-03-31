class_name BerkanoEffect
extends Effect

## Berkano (ᛒ): Foundation Root. First root placed each turn counts as
## POS-matched regardless of slot.

var _used_this_turn: bool = false


func activate(_context: EffectContext) -> void:
	_used_this_turn = false


func can_trigger(_context: EffectContext) -> bool:
	return not _used_this_turn


func execute(context: EffectContext) -> void:
	_used_this_turn = true
	context.combat_state.set_force_pos_match(true)
