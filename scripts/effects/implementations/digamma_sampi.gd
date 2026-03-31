class_name DigammaSixthWordEffect
extends Effect

## Digamma (archaic): Every 6th word submitted in the run, draw 3 extra next turn.

@export var word_interval: int = 6
@export var extra_draw: int = 3

var _words_counted: int = 0
var _pending_draw: int = 0


func activate(_context: EffectContext) -> void:
	_words_counted = 0
	_pending_draw = 0


func execute(context: EffectContext) -> void:
	# ON_WORD_FORMED: count words
	_words_counted += 1
	if _words_counted % word_interval == 0:
		_pending_draw = extra_draw
		context.combat_state.add_extra_draw_next_turn(_pending_draw)
