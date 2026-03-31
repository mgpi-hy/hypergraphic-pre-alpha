class_name LatinWynnLostLetterEffect
extends Effect

## Wynn - Lost Letter: Once per combat, recall all discarded morphemes
## to draw pile. Triggers ON_TURN_START when discard pile > 3.

@export var discard_threshold: int = 3

var _triggered: bool = false


func activate(_context: EffectContext) -> void:
	_triggered = false


func can_trigger(context: EffectContext) -> bool:
	return not _triggered and context.combat_state.discard_pile_size() > discard_threshold


func execute(context: EffectContext) -> void:
	_triggered = true
	context.combat_state.recall_all_discards()
