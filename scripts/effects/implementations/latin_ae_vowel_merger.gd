class_name LatinAEVowelMergerEffect
extends Effect

## AE (Ash) - Vowel Merger: 2+ words share a morpheme family = all get
## +2 induction. Triggers ON_PLAY. Checks placed words for family overlap.

@export var bonus_induction: int = 2


func execute(context: EffectContext) -> void:
	var word_count: int = context.combat_state.placed_word_count()
	if word_count < 2:
		return
	var shared: bool = context.combat_state.any_words_share_family()
	if not shared:
		return
	# Bonus applies to all words
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = bonus_induction * word_count
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
