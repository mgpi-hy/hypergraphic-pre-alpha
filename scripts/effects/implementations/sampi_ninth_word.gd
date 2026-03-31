class_name SampiNinthWordEffect
extends Effect

## Sampi (archaic): Every 9th word submitted in the run, triple induction.

@export var word_interval: int = 9
@export var induction_multiplier: float = 3.0

var _words_counted: int = 0


func activate(_context: EffectContext) -> void:
	_words_counted = 0


func execute(context: EffectContext) -> void:
	_words_counted += 1
	if _words_counted % word_interval == 0:
		context.combat_state.set_next_word_multiplier(induction_multiplier)
