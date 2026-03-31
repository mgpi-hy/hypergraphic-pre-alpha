class_name PassiveDeclanPersistenceEffect
extends Effect

## Declan (Declension): Insulation persists between turns at x1.5.
## Intercepts the system insulation-reset at turn start.
## Insulation caps at 25 to prevent snowball.

@export var persistence_multiplier: float = 1.5
@export var insulation_cap: int = 25


func modify_action(action: GameAction, context: EffectContext) -> GameAction:
	# Cancel the automatic insulation reset at turn start
	if action.type == Enums.ActionType.GAIN_INSULATION and action.amount < 0:
		if action.source == null:  # system-generated reset
			# Keep insulation but reduce it
			var current: int = context.combat_state.player_insulation
			var kept: int = mini(roundi(current / persistence_multiplier), insulation_cap)
			action.amount = -(current - kept)
	# Cap insulation gains
	if action.type == Enums.ActionType.GAIN_INSULATION and action.amount > 0:
		var projected: int = context.combat_state.player_insulation + action.amount
		if projected > insulation_cap:
			action.amount = maxi(insulation_cap - context.combat_state.player_insulation, 0)
	return action
