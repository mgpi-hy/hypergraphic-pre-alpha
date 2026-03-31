class_name LatinTTavMarkEffect
extends Effect

## T - Tav's Mark: First enemy killed each combat drops extra reward
## morpheme. Triggers ON_ENEMY_DEFEATED. Sets a flag for the reward
## screen once, then disables.

var _fired: bool = false


func activate(_context: EffectContext) -> void:
	_fired = false


func can_trigger(_context: EffectContext) -> bool:
	return not _fired


func execute(context: EffectContext) -> void:
	_fired = true
	context.combat_state.set_tav_mark_reward(true)
