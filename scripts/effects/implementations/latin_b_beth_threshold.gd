class_name LatinBBethThresholdEffect
extends Effect

## B - Beth's Threshold: Start of combat, choose 1 of 3 morphemes
## for opening hand.
## This is a UI-interactive effect. execute() sets the flag on CombatState
## so the combat screen can present the choice modal.

var _triggered: bool = false


func activate(_context: EffectContext) -> void:
	_triggered = false


func can_trigger(_context: EffectContext) -> bool:
	return not _triggered


func execute(context: EffectContext) -> void:
	_triggered = true
	context.combat_state.set_beth_threshold_pending(true)
