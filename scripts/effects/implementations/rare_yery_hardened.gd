class_name RareYeryHardenedEffect
extends Effect

## Yery (Ы): Hardened Vowel. Insulation doesn't degrade on hits <= 3.
## INTERCEPTOR: modifies insulation-loss actions from small attacks.

@export var damage_threshold: int = 3


func modify_action(action: GameAction, context: EffectContext) -> GameAction:
	# Intercept insulation degradation from small hits
	if action.type == Enums.ActionType.GAIN_INSULATION and action.amount < 0:
		if context.damage_amount > 0 and context.damage_amount <= damage_threshold:
			action.amount = 0
	return action
