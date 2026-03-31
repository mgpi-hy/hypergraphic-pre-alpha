class_name EnemyController
extends RefCounted

## Manages enemy AI during combat: intent selection, intent cycling, phase transitions,
## periodic mechanics, and enemy turn execution. Does NOT handle rendering (that's CombatUI).


# --- Constants ---

const INTENT_TYPE := EnemyData.IntentType


# --- Inner Classes ---

## Runtime state for a single active enemy in combat.
class EnemyInstance extends RefCounted:
	var id: String = ""
	var data: EnemyData
	var current_cogency: int = 0
	var max_cogency: int = 0
	var current_intent: Dictionary = {}  # {type: IntentType, value: int}
	var intent_index: int = 0
	var turns_alive: int = 0
	var is_phased: bool = false
	var phase_index: int = 0  # tracks which phase thresholds have been crossed
	var mechanic_cooldown: int = 0
	var insulation: int = 0
	var base_damage: int = 0
	var is_defeated: bool = false
	var bonus_attacks: int = 0


	func _init() -> void:
		pass


	## True if this enemy is still in the fight.
	func is_alive() -> bool:
		return not is_defeated and current_cogency > 0


	## Check if the periodic mechanic should fire this turn.
	func should_trigger_mechanic() -> bool:
		return mechanic_cooldown <= 0 and not data.mechanic.is_empty()


# --- Private Variables ---

var _enemies: Array[EnemyInstance] = []


# --- Public Methods ---

## Initialize enemy instances from data, scaled for the current floor.
## Duplicates EnemyData so runtime mutations (scaling) don't pollute .tres on disk.
func init_enemies(enemy_list: Array[EnemyData], floor_number: int) -> void:
	_enemies.clear()
	for i: int in range(enemy_list.size()):
		var source: EnemyData = enemy_list[i]
		if not source:
			push_error("EnemyController: null EnemyData at index %d" % i)
			continue
		var scaled: EnemyData = source.duplicate() as EnemyData
		if not scaled:
			push_error("EnemyController: failed to duplicate EnemyData '%s'" % source.id)
			continue
		scaled.scale_for_floor(floor_number)

		var inst := EnemyInstance.new()
		inst.id = scaled.id if scaled.id != "" else "enemy_%d" % i
		inst.data = scaled
		inst.current_cogency = scaled.cogency
		inst.max_cogency = scaled.cogency
		inst.base_damage = scaled.base_damage
		inst.intent_index = 0
		inst.turns_alive = 0
		inst.is_phased = false
		inst.phase_index = 0
		inst.mechanic_cooldown = scaled.mechanic_interval
		inst.insulation = 0
		inst.is_defeated = false
		inst.current_intent = {}
		_enemies.append(inst)


## For each alive enemy, pick the next intent from their intent_pool (cycling).
## Also checks for phase transitions when cogency drops below thresholds.
func select_intents() -> void:
	for enemy: EnemyInstance in _enemies:
		if not enemy.is_alive():
			continue
		_check_phase_transition(enemy)
		_cycle_intent(enemy)


## Execute all enemy intents in order. Returns action results for UI to animate.
## Each result: {enemy_id, intent_type, value, mechanic, absorbed, damage_dealt}
func execute_enemy_turn(combat_state: CombatState, effect_manager: EffectManager) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for enemy: EnemyInstance in _enemies:
		if not enemy.is_alive():
			continue
		var result: Dictionary = _execute_intent(enemy, combat_state, effect_manager)
		results.append(result)
		# Bonus attacks from effects (e.g. Retroflex Scatter)
		for _ba: int in range(enemy.bonus_attacks):
			var bonus_result: Dictionary = _execute_intent(enemy, combat_state, effect_manager)
			results.append(bonus_result)
		enemy.bonus_attacks = 0

		# Tick mechanic cooldown and fire periodic mechanic
		if enemy.data.mechanic.is_empty():
			pass  # No mechanic defined, skip
		elif enemy.data.mechanic_interval <= 0:
			pass  # Interval 0 means no auto-trigger (manual only)
		else:
			enemy.mechanic_cooldown -= 1
			if enemy.should_trigger_mechanic():
				var mech_result: Dictionary = _apply_mechanic(enemy, combat_state)
				if not mech_result.is_empty():
					results.append(mech_result)
				enemy.mechanic_cooldown = enemy.data.mechanic_interval

		enemy.turns_alive += 1

		# Increment base damage by scaling factor each turn
		enemy.base_damage += enemy.data.scaling_factor
	return results


## Deal damage to a specific enemy. Returns defeat info.
func apply_damage_to_enemy(enemy_index: int, amount: int) -> Dictionary:
	if enemy_index < 0 or enemy_index >= _enemies.size():
		push_error("EnemyController: invalid enemy_index %d" % enemy_index)
		return {"defeated": false, "remaining": 0, "enemy_id": ""}

	var enemy: EnemyInstance = _enemies[enemy_index]
	# Guard: if already defeated, don't fire defeat triggers or count the kill again.
	if enemy.is_defeated:
		return {"defeated": false, "already_dead": true, "damage_dealt": 0, "enemy_id": enemy.id}

	# Insulation absorbs first
	var absorbed: int = mini(enemy.insulation, amount)
	enemy.insulation -= absorbed
	var remaining_damage: int = amount - absorbed

	enemy.current_cogency = maxi(enemy.current_cogency - remaining_damage, 0)
	var is_dead: bool = enemy.current_cogency <= 0
	if is_dead:
		enemy.is_defeated = true

	return {
		"defeated": is_dead,
		"remaining": enemy.current_cogency,
		"enemy_id": enemy.id,
		"absorbed": absorbed,
		"damage_applied": remaining_damage,
	}


## Get all alive enemy instances.
func get_alive_enemies() -> Array[EnemyInstance]:
	var alive: Array[EnemyInstance] = []
	for enemy: EnemyInstance in _enemies:
		if enemy.is_alive():
			alive.append(enemy)
	return alive


## Get all enemy instances (alive or dead), for UI display.
func get_all_enemies() -> Array[EnemyInstance]:
	return _enemies


## Get current intents for all alive enemies. For CombatUI telegraph display.
func get_enemy_intents() -> Array[Dictionary]:
	var intents: Array[Dictionary] = []
	for enemy: EnemyInstance in _enemies:
		if not enemy.is_alive():
			continue
		intents.append({
			"enemy_id": enemy.id,
			"intent": enemy.current_intent.duplicate(),
			"display_name": enemy.data.display_name,
		})
	return intents


## True if every enemy in the encounter is defeated.
func is_all_defeated() -> bool:
	for enemy: EnemyInstance in _enemies:
		if enemy.is_alive():
			return false
	return true


## Get a specific enemy by index.
func get_enemy(index: int) -> EnemyInstance:
	if index < 0 or index >= _enemies.size():
		return null
	return _enemies[index]


## Get a specific enemy by ID.
func get_enemy_by_id(enemy_id: String) -> EnemyInstance:
	for enemy: EnemyInstance in _enemies:
		if enemy.id == enemy_id:
			return enemy
	return null


# --- Private Methods ---

## Cycle to the next intent in the pool. Wraps around when exhausted.
func _cycle_intent(enemy: EnemyInstance) -> void:
	if enemy.data.intent_pool.is_empty():
		# Fallback: basic attack
		enemy.current_intent = {
			"type": INTENT_TYPE.ATTACK,
			"value": enemy.base_damage,
		}
		return

	var pool: Array[Dictionary] = enemy.data.intent_pool
	var raw_intent: Dictionary = pool[enemy.intent_index % pool.size()]
	enemy.intent_index += 1

	# Resolve the actual value: attacks use current base_damage, others use pool value
	var intent_type: int = raw_intent.get("type", INTENT_TYPE.ATTACK)
	var pool_value: int = raw_intent.get("value", 0)

	var resolved_value: int = pool_value
	if intent_type == INTENT_TYPE.ATTACK:
		resolved_value = enemy.base_damage + pool_value

	enemy.current_intent = {
		"type": intent_type,
		"value": resolved_value,
	}


## Check if the enemy should transition to a new phase based on cogency ratio.
func _check_phase_transition(enemy: EnemyInstance) -> void:
	var ratio: float = float(enemy.current_cogency) / float(enemy.max_cogency)

	# Multi-phase: check each threshold in order
	if not enemy.data.phase_thresholds.is_empty():
		while enemy.phase_index < enemy.data.phase_thresholds.size():
			var threshold: float = enemy.data.phase_thresholds[enemy.phase_index]
			if ratio > threshold:
				break
			enemy.is_phased = true
			enemy.phase_index += 1
		return

	# Single-phase fallback
	if enemy.is_phased:
		return
	if enemy.data.phase_threshold <= 0.0:
		return
	if ratio <= enemy.data.phase_threshold:
		enemy.is_phased = true
		enemy.phase_index = 1


## Execute a single enemy's current intent against the player.
func _execute_intent(enemy: EnemyInstance, combat_state: CombatState, _effect_manager: EffectManager) -> Dictionary:
	var intent: Dictionary = enemy.current_intent
	var intent_type: int = intent.get("type", INTENT_TYPE.ATTACK)
	var value: int = intent.get("value", 0)

	var result: Dictionary = {
		"enemy_id": enemy.id,
		"intent_type": intent_type,
		"value": value,
		"mechanic": "",
		"display_name": enemy.data.display_name,
	}

	match intent_type:
		INTENT_TYPE.ATTACK:
			var attack_value: int = value
			# Insulation on the player absorbs damage
			var absorbed: int = mini(combat_state.player_insulation, attack_value)
			combat_state.player_insulation -= absorbed
			var final_damage: int = attack_value - absorbed
			combat_state.player_cogency = maxi(combat_state.player_cogency - final_damage, 0)
			result["absorbed"] = absorbed
			result["damage_dealt"] = final_damage

		INTENT_TYPE.DEFEND:
			enemy.insulation += value
			result["insulation_gained"] = value

		INTENT_TYPE.BUFF:
			enemy.base_damage += value
			result["buff_amount"] = value

		INTENT_TYPE.DRAIN:
			# Steal semant from the player
			var drained: int = mini(combat_state.semant, value)
			combat_state.semant -= drained
			result["semant_drained"] = drained

		INTENT_TYPE.SCRAMBLE:
			# Flag combat state; CombatUI/CombatScreen resolves the actual slot swap
			combat_state.pending_scramble += value
			result["scramble_count"] = value

		INTENT_TYPE.SILENCE:
			# Flag combat state; CombatScreen resolves the slot lock
			combat_state.pending_silence += value
			result["silence_count"] = value

		INTENT_TYPE.LOCK:
			# Flag combat state; CombatScreen resolves the action lock
			combat_state.pending_lock += value
			result["lock_count"] = value

		_:
			push_warning("EnemyController: unknown intent type %d for '%s'" % [intent_type, enemy.id])

	return result


## Apply the enemy's periodic mechanic. Returns a result dict (or empty if no mechanic).
func _apply_mechanic(enemy: EnemyInstance, combat_state: CombatState) -> Dictionary:
	if enemy.data.mechanic == "":
		return {}

	var result: Dictionary = {
		"enemy_id": enemy.id,
		"intent_type": -1,
		"value": 0,
		"mechanic": enemy.data.mechanic,
		"display_name": enemy.data.display_name,
	}

	# Mechanics that modify combat_state flags (resolved by CombatScreen/CombatUI)
	match enemy.data.mechanic:
		"swap_pos":
			combat_state.pending_scramble += 1
			result["value"] = 1
		"lock_slot":
			combat_state.pending_silence += 1
			result["value"] = 1
		"grow_branch":
			combat_state.pending_grow_branch += 1
			result["value"] = 1
		"hide_pos":
			combat_state.pending_hide_pos = true
			result["value"] = 1
		"shift_tree":
			combat_state.pending_shift_tree += 1
			result["value"] = 1
		"heal_self":
			var heal: int = 10
			var old: int = enemy.current_cogency
			enemy.current_cogency = mini(enemy.current_cogency + heal, enemy.max_cogency)
			result["value"] = enemy.current_cogency - old
		"force_place":
			combat_state.pending_force_place += 1
			result["value"] = 1
		"shrink_hand":
			combat_state.pending_shrink_hand += 1
			result["value"] = 1
		"flood_tree":
			combat_state.pending_grow_branch += 2
			result["value"] = 2
		"halve_hand":
			combat_state.pending_halve_hand = true
			result["value"] = 1
		"cancel_novel":
			combat_state.pending_cancel_novel = true
			result["value"] = 1
		"scramble":
			combat_state.pending_scramble += 1
			result["value"] = 1
		"steal_morpheme":
			combat_state.pending_steal_morpheme += 1
			result["value"] = 1
		_:
			push_warning("EnemyController: unknown mechanic '%s' for '%s'" % [enemy.data.mechanic, enemy.id])
			return {}

	return result
