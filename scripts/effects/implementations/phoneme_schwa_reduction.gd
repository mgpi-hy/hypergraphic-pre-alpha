class_name PhonemeSchwaReductionEffect
extends Effect

## Schwa (ə): Reduction. Draw 3 morphemes, but exile the
## highest-weight one drawn.

@export var draw_count: int = 3


func execute(context: EffectContext) -> void:
	# Draw morphemes
	var draw_action := GameAction.new()
	draw_action.type = Enums.ActionType.DRAW_MORPHEME
	draw_action.amount = draw_count
	draw_action.source = context.source
	context.action_queue.enqueue(draw_action)
	# Exile heaviest is handled by CombatState after draw resolves
	context.combat_state.set_exile_heaviest_drawn(true)
