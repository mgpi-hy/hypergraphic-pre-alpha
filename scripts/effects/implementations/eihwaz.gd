class_name EihwazEffect
extends Effect

## Eihwaz (ᛇ): Insulation Floor. Insulation cannot degrade below 1.
## Intercepts insulation-loss actions to enforce the floor.

@export var insulation_floor: int = 1


func modify_action(action: GameAction, context: EffectContext) -> GameAction:
	if action.type != Enums.ActionType.GAIN_INSULATION:
		return action
	if action.amount >= 0:
		return action
	# Prevent insulation from dropping below floor
	var current: int = context.combat_state.player_insulation
	var result: int = current + action.amount
	if result < insulation_floor and current >= insulation_floor:
		action.amount = -(current - insulation_floor)
	return action
