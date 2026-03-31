class_name DagazEffect
extends Effect

## Dagaz (ᛞ): Death Save. First lethal hit per combat: survive at 1 cogency
## and gain +5 induction on next submit.

@export var induction_bonus: int = 5

var _triggered: bool = false


func activate(_context: EffectContext) -> void:
	_triggered = false


func can_trigger(context: EffectContext) -> bool:
	return not _triggered and context.combat_state.player_cogency <= 0


func execute(context: EffectContext) -> void:
	_triggered = true
	# Tier 1: heal back to 1 cogency
	var action := GameAction.new()
	action.type = Enums.ActionType.HEAL_COGENCY
	action.amount = 1
	action.source = context.source
	context.action_queue.enqueue(action)
	# Tier 2: bonus induction on next submit
	context.combat_state.set_bonus_induction_next_submit(induction_bonus)
