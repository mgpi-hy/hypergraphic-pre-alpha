class_name PhonemeLateralDriftEffect
extends Effect

## Lateral Approximant (ɬ): Lateral Drift. All morphemes in hand
## temporarily match any POS for 1 turn.

func execute(context: EffectContext) -> void:
	context.combat_state.set_lateral_drift_active(true)
