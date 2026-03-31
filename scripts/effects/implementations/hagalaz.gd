class_name HagalazEffect
extends Effect

## Hagalaz (ᚺ): Hailstrike. Once per combat, negate excess damage above 10
## from a single hit.

@export var damage_cap: int = 10

var _triggered: bool = false


func activate(_context: EffectContext) -> void:
	_triggered = false


func modify_action(action: GameAction, _context: EffectContext) -> GameAction:
	if _triggered:
		return action
	if action.type != Enums.ActionType.DEAL_DAMAGE:
		return action
	if action.amount <= damage_cap:
		return action
	_triggered = true
	action.amount = damage_cap
	return action
