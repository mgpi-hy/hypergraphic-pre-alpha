class_name GammaInflectionEffect
extends Effect

## Gamma (G): When cogency drops below 50%, all induction +30% for rest of combat.
## Triggers once per combat. Uses PASSIVE to modify outgoing damage.

@export var induction_bonus: float = 0.3

var _triggered: bool = false


func activate(_context: EffectContext) -> void:
	_triggered = false


func can_trigger(context: EffectContext) -> bool:
	if _triggered:
		return false
	var threshold: float = float(context.combat_state.max_cogency) * 0.5
	return float(context.combat_state.player_cogency) < threshold


func execute(context: EffectContext) -> void:
	_triggered = true
	context.combat_state.set_persistent_induction_bonus(induction_bonus)
