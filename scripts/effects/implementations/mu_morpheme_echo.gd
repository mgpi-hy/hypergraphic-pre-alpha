class_name MuMorphemeEchoEffect
extends Effect

## Mu (M): Submit exactly 2 words = duplicate a random discard morpheme into hand.

@export var required_word_count: int = 2


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.words_submitted_this_turn == required_word_count \
		and context.combat_state.discard_pile_size() > 0


func execute(context: EffectContext) -> void:
	context.combat_state.duplicate_random_discard_to_hand()
