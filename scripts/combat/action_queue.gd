class_name ActionQueue
extends RefCounted

## Queues and resolves GameActions, running interceptors before execution.
## All discrete state changes go through this queue so interceptors can modify them.

# --- Constants ---
const MAX_RESOLVE_DEPTH: int = 100  # prevent infinite loops

# --- Private Variables ---
var _queue: Array[GameAction] = []
var _interceptors: Array[Effect] = []
var _resolve_depth: int = 0


# --- Public Methods ---

func enqueue(action: GameAction) -> void:
	_queue.append(action)


func register_interceptor(effect: Effect) -> void:
	_interceptors.append(effect)
	_interceptors.sort_custom(func(a: Effect, b: Effect) -> bool:
		return a.priority < b.priority
	)


func unregister_interceptor(effect: Effect) -> void:
	_interceptors.erase(effect)


func resolve_all(context: EffectContext) -> void:
	_resolve_depth += 1
	if _resolve_depth > MAX_RESOLVE_DEPTH:
		push_error("ActionQueue: resolve depth exceeded %d, breaking potential loop" % MAX_RESOLVE_DEPTH)
		_queue.clear()
		_resolve_depth -= 1
		return
	while not _queue.is_empty():
		var action: GameAction = _queue.pop_front()
		for interceptor: Effect in _interceptors:
			if interceptor.can_trigger(context):
				action = interceptor.modify_action(action, context)
				if action == null:
					break  # interceptor cancelled the action
		if action != null:
			action.execute(context)
	_resolve_depth -= 1
