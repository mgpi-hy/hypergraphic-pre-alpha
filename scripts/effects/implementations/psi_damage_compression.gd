class_name PsiDamageCompressionEffect
extends Effect

## Psi (Y): Enemies dealing >8 deal exactly 8; enemies dealing <=3 deal 0.
## Interceptor that modifies incoming damage actions.

@export var upper_cap: int = 8
@export var lower_threshold: int = 3


func modify_action(action: GameAction, _context: EffectContext) -> GameAction:
	if action.type != Enums.ActionType.DEAL_DAMAGE:
		return action
	# Only intercept enemy-to-player damage
	if action.target == null:
		return action
	if action.amount > upper_cap:
		action.amount = upper_cap
	elif action.amount <= lower_threshold:
		action.amount = 0
	return action
