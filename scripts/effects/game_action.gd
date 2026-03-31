class_name GameAction
extends RefCounted

## A discrete state change that flows through the ActionQueue.
##
## Uses match dispatch on ActionType. This is the one place where
## match-on-type is acceptable: actions are a closed set of primitive
## state changes, not extensible content.

# --- Public Variables ---

var type: Enums.ActionType
var amount: int = 0
var source: Node
var target: Node


# --- Public Methods ---

## Execute this action against combat state and emit EventBus signals.
func execute(context: EffectContext) -> void:
	match type:
		Enums.ActionType.DEAL_DAMAGE:
			context.combat_state.deal_damage(amount, target)
			EventBus.damage_dealt.emit(amount, source, target)
		Enums.ActionType.GAIN_INSULATION:
			context.combat_state.add_insulation(amount)
			EventBus.insulation_changed.emit(context.combat_state.player_insulation)
		Enums.ActionType.DRAW_MORPHEME:
			context.combat_state.draw_morphemes(amount)
		Enums.ActionType.DISCARD_MORPHEME:
			context.combat_state.discard_morphemes(amount)
		Enums.ActionType.GAIN_SEMANT:
			context.combat_state.add_semant(amount)
			EventBus.semant_changed.emit(context.combat_state.semant)
		Enums.ActionType.LOSE_COGENCY:
			context.combat_state.lose_cogency(amount)
			EventBus.cogency_changed.emit(context.combat_state.player_cogency)
		Enums.ActionType.HEAL_COGENCY:
			context.combat_state.heal_cogency(amount)
			EventBus.cogency_changed.emit(context.combat_state.player_cogency)
		Enums.ActionType.ADD_MULTIPLIER:
			context.combat_state.add_multiplier(amount)
			EventBus.multiplier_applied.emit(amount)
