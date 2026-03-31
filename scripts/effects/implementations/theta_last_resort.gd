class_name ThetaLastResortEffect
extends Effect

## Theta (Q): When cogency drops below 25%, next word deals double induction.
## Once per combat.

var _triggered: bool = false


func activate(_context: EffectContext) -> void:
	_triggered = false


func can_trigger(context: EffectContext) -> bool:
	if _triggered:
		return false
	var threshold: float = float(context.combat_state.max_cogency) * 0.25
	return float(context.combat_state.player_cogency) < threshold and context.combat_state.player_cogency > 0


func execute(context: EffectContext) -> void:
	_triggered = true
	context.combat_state.set_next_word_multiplier(2.0)
