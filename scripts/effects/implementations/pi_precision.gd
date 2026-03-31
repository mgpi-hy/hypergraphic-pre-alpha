class_name PiIrrationalPrecisionEffect
extends Effect

## Pi (P): All induction calculations round up instead of down.
## Sets a flag on CombatState that the damage resolver checks.


func execute(context: EffectContext) -> void:
	context.combat_state.set_round_up(true)
