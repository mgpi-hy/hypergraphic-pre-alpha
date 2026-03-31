class_name XiCodeSwitcherEffect
extends Effect

## Xi (X): Words with 2+ families get +4 induction and ignore the family mix penalty.

@export var bonus: int = 4


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.is_current_word_family_mixed()


func execute(context: EffectContext) -> void:
	# Cancel the mix penalty
	context.combat_state.cancel_family_mix_penalty()
	# Add flat bonus
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = bonus
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
