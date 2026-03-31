class_name EffectContext
extends RefCounted

## Carries all combat state to effects so they never reach into globals.
##
## Not all fields are populated for every trigger. Check the context field
## availability table in effect-system.md before accessing fields.

# --- Public Variables ---

var combat_state: CombatState
var action_queue: ActionQueue
var source: Node               ## Who triggered this effect
var target: Node               ## Who it targets (if applicable)
var damage_amount: int = 0     ## For damage-related triggers
var word: String = ""          ## For word-related triggers
var morphemes: Array[MorphemeData] = []
var turn_number: int = 0
var is_novel_word: bool = false


# --- Static Methods ---

## Factory method for combat effects.
static func from_combat(state: CombatState, queue: ActionQueue, src: Node, tgt: Node = null) -> EffectContext:
	var ctx := EffectContext.new()
	ctx.combat_state = state
	ctx.action_queue = queue
	ctx.source = src
	ctx.target = tgt
	ctx.turn_number = state.current_turn
	return ctx
