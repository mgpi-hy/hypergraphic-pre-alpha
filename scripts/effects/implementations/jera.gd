class_name JeraEffect
extends Effect

## Jera (ᛃ): Harvest Cycle. Every 3rd turn, gain +5 insulation.

@export var trigger_interval: int = 3
@export var insulation_bonus: int = 5

var _turns_counted: int = 0


func activate(_context: EffectContext) -> void:
	_turns_counted = 0


func execute(context: EffectContext) -> void:
	_turns_counted += 1
	if _turns_counted >= trigger_interval:
		_turns_counted = 0
		var action := GameAction.new()
		action.type = Enums.ActionType.GAIN_INSULATION
		action.amount = insulation_bonus
		action.source = context.source
		context.action_queue.enqueue(action)
