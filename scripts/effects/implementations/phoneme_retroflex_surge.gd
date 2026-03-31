class_name PhonemeRetroflexSurgeEffect
extends Effect

## Retroflex Approximant (ɻ): Retroflex Surge. Gain 5 insulation
## and draw 2 extra morphemes.

@export var insulation_bonus: int = 5
@export var draw_bonus: int = 2


func execute(context: EffectContext) -> void:
	var shield_action := GameAction.new()
	shield_action.type = Enums.ActionType.GAIN_INSULATION
	shield_action.amount = insulation_bonus
	shield_action.source = context.source
	context.action_queue.enqueue(shield_action)

	var draw_action := GameAction.new()
	draw_action.type = Enums.ActionType.DRAW_MORPHEME
	draw_action.amount = draw_bonus
	draw_action.source = context.source
	context.action_queue.enqueue(draw_action)
