class_name PerthroEffect
extends Effect

## Perthro (ᛈ): Wild Draw. Start of turn, 1 random hand morpheme is replaced
## by a random morpheme from outside the deck (any family).

func execute(context: EffectContext) -> void:
	context.combat_state.set_wild_draw_replacement(true)
