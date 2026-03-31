class_name PassivePhilHalvedInsulationEffect
extends Effect

## Phil (Compounding): Halved insulation. Intercepts insulation
## gain actions and cuts them in half.

@export var insulation_fraction: float = 0.5


func modify_action(action: GameAction, _context: EffectContext) -> GameAction:
	if action.type == Enums.ActionType.GAIN_INSULATION and action.amount > 0:
		action.amount = maxi(roundi(action.amount * insulation_fraction), 1)
	return action
