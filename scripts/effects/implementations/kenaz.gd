class_name KenazEffect
extends Effect

## Kenaz (ᚲ): Torchlight. Reveal enemy cogency thresholds (phase-change HP).

func execute(context: EffectContext) -> void:
	context.combat_state.set_reveal_thresholds(true)
