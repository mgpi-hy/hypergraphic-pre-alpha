class_name EffectManager
extends Node

## Manages effect registration, triggering, and lifecycle for a combat encounter.
## Child node of CombatScreen. Combat subsystems access via @export injection, not autoload.

# --- Private Variables ---
var _action_queue: ActionQueue
var _registry: Dictionary = {}  # Enums.EffectTrigger -> Array[Effect]


# --- Virtual Methods ---

func _init() -> void:
	_action_queue = ActionQueue.new()


# --- Public Methods ---

func get_action_queue() -> ActionQueue:
	return _action_queue


## Register an effect. Stateful effects are duplicated to avoid shared-instance bugs.
func register(effect: Effect, context: EffectContext) -> Effect:
	# Duplicate so runtime state doesn't pollute the .tres on disk
	var instance: Effect = effect.duplicate()
	if not _registry.has(instance.trigger):
		_registry[instance.trigger] = []
	_registry[instance.trigger].append(instance)
	_registry[instance.trigger].sort_custom(func(a: Effect, b: Effect) -> bool:
		return a.priority < b.priority
	)
	if instance.trigger == Enums.EffectTrigger.INTERCEPTOR:
		_action_queue.register_interceptor(instance)
	instance.activate(context)
	return instance


## Unregister an effect. Calls deactivate() for cleanup.
func unregister(effect: Effect) -> void:
	effect.deactivate()
	if _registry.has(effect.trigger):
		_registry[effect.trigger].erase(effect)
	if effect.trigger == Enums.EffectTrigger.INTERCEPTOR:
		_action_queue.unregister_interceptor(effect)


## Fire all effects for a trigger type.
func trigger(trigger_type: Enums.EffectTrigger, context: EffectContext) -> void:
	if not _registry.has(trigger_type):
		return
	for effect: Effect in _registry[trigger_type]:
		if effect.can_trigger(context):
			effect.execute(context)


## Poll PASSIVE effects during damage resolution.
## Returns the modified value after all passives have had a chance to modify it.
func apply_passives(base_value: int, context: EffectContext) -> int:
	var value: int = base_value
	if not _registry.has(Enums.EffectTrigger.PASSIVE):
		return value
	for effect: Effect in _registry[Enums.EffectTrigger.PASSIVE]:
		if effect.can_trigger(context):
			value = effect.modify_value(value, context)
	return value


## Unregister all effects. Called at combat end.
func clear_all() -> void:
	for trigger_type: Enums.EffectTrigger in _registry:
		for effect: Effect in _registry[trigger_type]:
			effect.deactivate()
	_registry.clear()
	_action_queue = ActionQueue.new()
