class_name AlphaFirstPrincipleEffect
extends Effect

## Alpha (A): First word each turn gets x1.25 induction.
## Applies as a flat bonus equal to 25% of the word's base induction.

@export var multiplier_bonus: float = 0.25


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.words_submitted_this_turn == 0


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
