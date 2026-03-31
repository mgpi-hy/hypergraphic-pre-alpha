class_name DeltaMorphemicDriftEffect
extends Effect

## Delta (D): Once per combat, transform a root to a random root of a different family.

var _used: bool = false


func activate(_context: EffectContext) -> void:
	_used = false


func can_trigger(_context: EffectContext) -> bool:
	return not _used


func execute(context: EffectContext) -> void:
	_used = true
	context.combat_state.request_morphemic_drift()
