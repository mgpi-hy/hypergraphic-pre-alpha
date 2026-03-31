class_name PassiveKenNoInsulationEffect
extends Effect

## Ken (Kenning): NO insulation. Intercepts all insulation-gain
## actions and cancels them.

func modify_action(action: GameAction, _context: EffectContext) -> GameAction:
	if action.type == Enums.ActionType.GAIN_INSULATION:
		action.amount = 0
	return action
