class_name PhonemeGlottalCatchEffect
extends Effect

## Glottal Stop (ʔ): Glottal Catch. Clear all placed words.
## For each word cleared, draw 2 morphemes.

@export var draw_per_word: int = 2


func execute(context: EffectContext) -> void:
	var words_cleared: int = context.combat_state.clear_all_placed_words()
	if words_cleared <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.DRAW_MORPHEME
	action.amount = words_cleared * draw_per_word
	action.source = context.source
	context.action_queue.enqueue(action)
