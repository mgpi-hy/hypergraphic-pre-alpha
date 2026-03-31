class_name PhonemeSibilantBurstEffect
extends Effect

## Esh (ʃ): Sibilant Burst. Double next word's induction if it
## contains a Germanic root. Otherwise x1.5.

@export var germanic_multiplier: float = 2.0
@export var fallback_multiplier: float = 1.5


func execute(context: EffectContext) -> void:
	context.combat_state.set_sibilant_burst(germanic_multiplier, fallback_multiplier)
