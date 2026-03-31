class_name UruzEffect
extends Effect

## Uruz (ᚢ): Wild Strength. Ken's starter.
## First word each turn gets +3 flat induction (+5 if no insulation).

@export var base_bonus: int = 3
@export var no_insulation_bonus: int = 5

var _first_word_played: bool = false


func activate(_context: EffectContext) -> void:
	_first_word_played = false


func can_trigger(context: EffectContext) -> bool:
	return not _first_word_played


func execute(context: EffectContext) -> void:
	_first_word_played = true
	var bonus: int = no_insulation_bonus if context.combat_state.player_insulation == 0 else base_bonus
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = bonus
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
