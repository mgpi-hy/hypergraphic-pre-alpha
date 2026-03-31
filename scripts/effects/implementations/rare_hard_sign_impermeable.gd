class_name RareHardSignImpermeableEffect
extends Effect

## Hard Sign (Ъ): Impermeable. Once per combat, completely block
## one enemy attack (reduce to 0). INTERCEPTOR.

var _triggered: bool = false


func activate(_context: EffectContext) -> void:
	_triggered = false


func modify_action(action: GameAction, _context: EffectContext) -> GameAction:
	if _triggered:
		return action
	if action.type == Enums.ActionType.LOSE_COGENCY and action.amount > 0:
		_triggered = true
		action.amount = 0
	return action
