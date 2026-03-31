class_name IsaEffect
extends Effect

## Isa (ᛁ): Frozen Syntax. Syntax tree keeps POS layout between turns
## (doesn't regenerate).

func execute(context: EffectContext) -> void:
	context.combat_state.set_frozen_syntax(true)
