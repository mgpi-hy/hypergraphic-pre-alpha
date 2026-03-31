class_name Effect
extends Resource

## Base class for all effects in Hypergraphic.
##
## Every grapheme, phoneme, affix, and character passive extends this.
## Override virtual methods to implement behavior. Never edit combat code
## to add content; create a new Effect subclass + .tres file instead.

# --- Exports ---

## Human-readable name shown in UI
@export var display_name: String = ""

## Description text (supports {placeholder} substitution)
@export var description: String = ""

## When this effect triggers
@export var trigger: Enums.EffectTrigger = Enums.EffectTrigger.ON_PLAY

## Effect priority (lower = resolves first). Use multiples of 10 for spacing.
@export var priority: int = 100


# --- Public Methods ---

## Override in subclass. Enqueue actions on the context's action queue.
func execute(context: EffectContext) -> void:
	push_warning("Effect.execute() not overridden in %s" % display_name)


## Override for interceptor effects that modify actions before resolution.
func modify_action(action: GameAction, _context: EffectContext) -> GameAction:
	return action


## Override for PASSIVE effects that modify damage/insulation values.
func modify_value(base_value: int, _context: EffectContext) -> int:
	return base_value


## Override to check if this effect can trigger right now.
func can_trigger(_context: EffectContext) -> bool:
	return true


## Called when effect is registered (combat start, grapheme acquired).
## Override for setup: connect EventBus signals, initialize state.
func activate(context: EffectContext) -> void:
	pass


## Called when effect is unregistered (combat end, grapheme removed).
## MUST disconnect any EventBus signals connected in activate().
func deactivate() -> void:
	pass
