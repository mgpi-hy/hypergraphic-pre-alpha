class_name OmegaFinalWordEffect
extends Effect

## Omega (W): Last word each turn gets x1.5 induction.
## Applied after all words are scored; adds 50% of the last word's induction.

@export var multiplier_bonus: float = 0.5


func execute(context: EffectContext) -> void:
	var bonus: int = int(context.damage_amount * multiplier_bonus)
	if bonus <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = bonus
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
