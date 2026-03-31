class_name LatinNNunSpineEffect
extends Effect

## N - Nun's Spine: 0 insulation at end of turn = gain 3 insulation
## next turn. Triggers ON_TURN_END; checks insulation and sets a flag
## for next turn's start.

@export var insulation_bonus: int = 3

var _primed: bool = false


func activate(_context: EffectContext) -> void:
	_primed = false


func execute(context: EffectContext) -> void:
	if context.trigger == Enums.EffectTrigger.ON_TURN_END:
		_primed = context.combat_state.player_insulation == 0
	elif context.trigger == Enums.EffectTrigger.ON_TURN_START and _primed:
		_primed = false
		var action := GameAction.new()
		action.type = Enums.ActionType.GAIN_INSULATION
		action.amount = insulation_bonus
		action.source = context.source
		context.action_queue.enqueue(action)
