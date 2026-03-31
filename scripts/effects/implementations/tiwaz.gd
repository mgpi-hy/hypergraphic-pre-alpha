class_name TiwazEffect
extends Effect

## Tiwaz (ᛏ): Tyr's Sacrifice. Once per turn, sacrifice 5 cogency to double
## one word's induction.

@export var cogency_cost: int = 5
@export var induction_multiplier: float = 2.0

var _used_this_turn: bool = false


func activate(_context: EffectContext) -> void:
	_used_this_turn = false


func can_trigger(context: EffectContext) -> bool:
	return not _used_this_turn and context.combat_state.player_cogency > cogency_cost


func execute(context: EffectContext) -> void:
	_used_this_turn = true
	# Tier 1: pay the cogency cost
	var action := GameAction.new()
	action.type = Enums.ActionType.LOSE_COGENCY
	action.amount = cogency_cost
	action.source = context.source
	context.action_queue.enqueue(action)
	# Tier 2: double the word's induction
	context.combat_state.set_next_word_multiplier(induction_multiplier)
