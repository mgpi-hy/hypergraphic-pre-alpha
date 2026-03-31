class_name SyntaxTree
extends Control

## Hierarchical syntax tree with branches (NP, VP, PP), each containing
## typed SyntaxSlots. Manages branch completion multipliers and visual layout.

# --- Signals ---

signal slot_morpheme_dropped(morpheme: MorphemeData, slot: SyntaxSlot)
signal slot_morpheme_cleared(slot: SyntaxSlot)

# --- Constants ---

const SYNTAX_SLOT_SCENE: PackedScene = preload("res://scenes/combat/syntax_slot.tscn")

const BRANCH_MULT: float = 2.0
const FULL_TREE_MULT: float = 2.0

## Branch label colors: maps branch prefix to POS color key.
const BRANCH_COLORS: Dictionary = {
	"NP": "noun",
	"VP": "verb",
	"PP": "preposition",
}

## Named tree configs for bosses and backwards compatibility.
const NAMED_CONFIGS: Dictionary = {
	"default": [
		{"pos": Enums.POSType.NOUN, "branch": "NP", "optional": false},
		{"pos": Enums.POSType.VERB, "branch": "VP", "optional": false},
	],
	"boss_broca": [
		{"pos": Enums.POSType.DETERMINER, "branch": "NP", "optional": true},
		{"pos": Enums.POSType.ADJECTIVE, "branch": "NP", "optional": false},
		{"pos": Enums.POSType.NOUN, "branch": "NP", "optional": false},
		{"pos": Enums.POSType.VERB, "branch": "VP", "optional": false},
		{"pos": Enums.POSType.ADVERB, "branch": "VP", "optional": true},
		{"pos": Enums.POSType.PREPOSITION, "branch": "PP", "optional": false},
		{"pos": Enums.POSType.DETERMINER, "branch": "PP", "optional": true},
		{"pos": Enums.POSType.NOUN, "branch": "PP", "optional": false},
	],
	"boss_wernicke": [
		{"pos": Enums.POSType.DETERMINER, "branch": "NP", "optional": true},
		{"pos": Enums.POSType.NOUN, "branch": "NP", "optional": false},
		{"pos": Enums.POSType.VERB, "branch": "VP", "optional": false},
		{"pos": Enums.POSType.ADVERB, "branch": "VP", "optional": true},
		{"pos": Enums.POSType.DETERMINER, "branch": "NP2", "optional": true},
		{"pos": Enums.POSType.ADJECTIVE, "branch": "NP2", "optional": true},
		{"pos": Enums.POSType.NOUN, "branch": "NP2", "optional": false},
	],
	"boss_seizure": [
		{"pos": Enums.POSType.DETERMINER, "branch": "NP", "optional": true},
		{"pos": Enums.POSType.ADJECTIVE, "branch": "NP", "optional": false},
		{"pos": Enums.POSType.NOUN, "branch": "NP", "optional": false},
		{"pos": Enums.POSType.VERB, "branch": "VP", "optional": false},
		{"pos": Enums.POSType.ADVERB, "branch": "VP", "optional": true},
		{"pos": Enums.POSType.ADVERB, "branch": "VP", "optional": true},
		{"pos": Enums.POSType.PREPOSITION, "branch": "PP", "optional": false},
		{"pos": Enums.POSType.DETERMINER, "branch": "PP", "optional": true},
		{"pos": Enums.POSType.NOUN, "branch": "PP", "optional": false},
	],
}

## Tier boundaries: floor_number -> tier index (1-based)
const TIER_FLOOR_RANGES: Array = [
	{"min": 1, "max": 4},    # Tier 1: Intransitive
	{"min": 5, "max": 8},    # Tier 2: Transitive
	{"min": 9, "max": 12},   # Tier 3: Prepositional
	{"min": 13, "max": 17},  # Tier 4: Boss/Complex
]

## Max optional modifier slots per branch at each tier.
## Tier 1: 0-1 modifiers, Tier 2: 0-1, Tier 3: 0-2, Tier 4: 0-2
const TIER_MAX_MODS: Array[int] = [1, 1, 2, 2]


## Generate a tree config array procedurally based on floor number.
## Every call produces a unique, grammatically valid English phrase structure.
## Higher tiers unlock more branches and modifier slots.
## rng: optional RandomNumberGenerator for deterministic generation.
static func generate_tree_config(floor_number: int, rng: RandomNumberGenerator = null) -> Array:
	var tier: int = _get_tier_for_floor(floor_number)

	# Progress within the tier (0.0 to 1.0), biases optional slots toward appearing
	var tier_range: Dictionary = TIER_FLOOR_RANGES[tier - 1]
	var tier_min: int = tier_range["min"]
	var tier_max: int = tier_range["max"]
	var progress: float = 0.0
	if tier_max > tier_min:
		progress = float(floor_number - tier_min) / float(tier_max - tier_min)

	var config: Array = []
	var max_mods: int = TIER_MAX_MODS[tier - 1]

	# --- NP (subject): always present ---
	# Required: N. Optional: Det, Adj (based on tier + randomness)
	var np_mods: int = _roll_modifier_count(max_mods, progress, rng)
	if np_mods >= 1 and _roll_chance(0.3 + progress * 0.4, rng):
		config.append({"pos": Enums.POSType.DETERMINER, "branch": "NP", "optional": true})
	if np_mods >= 1 and tier >= 2 and _roll_chance(0.2 + progress * 0.3, rng):
		config.append({"pos": Enums.POSType.ADJECTIVE, "branch": "NP", "optional": true})
	config.append({"pos": Enums.POSType.NOUN, "branch": "NP", "optional": false})

	# --- VP (predicate): always present ---
	# Required: V. Optional: Adv (1 slot tier 1-2, up to 2 at tier 4)
	config.append({"pos": Enums.POSType.VERB, "branch": "VP", "optional": false})
	var vp_adv_max: int = 1 if tier < 4 else 2
	var vp_adv_count: int = _roll_modifier_count(mini(max_mods, vp_adv_max), progress * 0.7, rng)
	for i: int in range(vp_adv_count):
		if _roll_chance(0.25 + progress * 0.35, rng):
			config.append({"pos": Enums.POSType.ADVERB, "branch": "VP", "optional": true})

	# --- NP2 (object): tier 2+ with 50% base chance, increasing with progress ---
	var has_np2: bool = false
	if tier >= 2 and _roll_chance(0.5 + progress * 0.2, rng):
		has_np2 = true
		var np2_mods: int = _roll_modifier_count(max_mods, progress, rng)
		if np2_mods >= 1 and _roll_chance(0.3 + progress * 0.3, rng):
			config.append({"pos": Enums.POSType.DETERMINER, "branch": "NP2", "optional": true})
		if np2_mods >= 2 and tier >= 3 and _roll_chance(0.2 + progress * 0.3, rng):
			config.append({"pos": Enums.POSType.ADJECTIVE, "branch": "NP2", "optional": true})
		config.append({"pos": Enums.POSType.NOUN, "branch": "NP2", "optional": false})

	# --- PP (prepositional phrase): tier 3+ with 50% base chance ---
	if tier >= 3 and _roll_chance(0.5 + progress * 0.3, rng):
		config.append({"pos": Enums.POSType.PREPOSITION, "branch": "PP", "optional": false})
		if _roll_chance(0.4 + progress * 0.3, rng):
			config.append({"pos": Enums.POSType.DETERMINER, "branch": "PP", "optional": true})
		config.append({"pos": Enums.POSType.NOUN, "branch": "PP", "optional": false})

	# --- Minimum: guarantee at least 3 slots for all tiers ---
	# All optional rolls can fail at any tier, leaving a trivially small tree.
	# A 2-slot tree gives degenerate x4 multipliers; always require at least 3.
	if config.size() < 3:
		# DET in NP is the most natural English expansion
		config.insert(0, {"pos": Enums.POSType.DETERMINER, "branch": "NP", "optional": true})

	# --- Tier 4 fallback: guarantee at least 3 branches ---
	# If tier 4 rolled only NP+VP, force either NP2 or PP
	if tier >= 4 and not has_np2 and config.size() < 5:
		# Force a PP at minimum
		config.append({"pos": Enums.POSType.PREPOSITION, "branch": "PP", "optional": false})
		if _roll_chance(0.5, rng):
			config.append({"pos": Enums.POSType.DETERMINER, "branch": "PP", "optional": true})
		config.append({"pos": Enums.POSType.NOUN, "branch": "PP", "optional": false})

	return config


## Get a named config by key. Used for boss overrides and backwards compatibility.
static func get_config_by_name(config_name: String) -> Array:
	if NAMED_CONFIGS.has(config_name):
		return NAMED_CONFIGS[config_name].duplicate(true)
	return NAMED_CONFIGS["default"].duplicate(true)


## Determine tier (1-4) from floor number.
static func _get_tier_for_floor(floor_number: int) -> int:
	for i: int in range(TIER_FLOOR_RANGES.size()):
		var r: Dictionary = TIER_FLOOR_RANGES[i]
		if floor_number >= r["min"] and floor_number <= r["max"]:
			return i + 1
	# Past tier 4: use tier 4
	if floor_number > 17:
		return 4
	return 1


## Roll how many optional modifier slots to attempt for a branch.
## Returns 0 to max_count, biased upward by progress.
static func _roll_modifier_count(max_count: int, progress: float, rng: RandomNumberGenerator = null) -> int:
	if max_count <= 0:
		return 0
	# Each slot has an independent chance to appear, scaling with progress
	var count: int = 0
	for i: int in range(max_count):
		var chance: float = 0.3 + progress * 0.4
		if _roll_chance(chance, rng):
			count += 1
	return count


## Roll a boolean with the given probability (0.0 to 1.0).
static func _roll_chance(probability: float, rng: RandomNumberGenerator = null) -> bool:
	var roll: float = rng.randf() if rng else randf()
	return roll < probability

# --- Private Variables ---

var _sentence_node_label: Label = null  # "S" node at top of tree
var _branches: Dictionary = {}  # branch_id -> {label, mult_label, slots, container}
var _tree_type: String = ""
var _root_container: HBoxContainer
var _branch_order: Array[String] = []  # preserves insertion order
var _syntax_slots: Array[SyntaxSlot] = []  # flat list of all slots across branches


# --- Virtual Methods ---

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _draw() -> void:
	if _branches.is_empty() or not _sentence_node_label:
		return

	# S-node center at top: convert global position to local draw space
	var my_origin: Vector2 = global_position
	var s_global: Vector2 = _sentence_node_label.global_position
	var s_local: Vector2 = s_global - my_origin
	var s_center_x: float = s_local.x + _sentence_node_label.size.x / 2.0
	var s_bottom_y: float = s_local.y + _sentence_node_label.size.y

	var line_color: Color = ThemeManager.COLOR_TEXT_DIM.darkened(0.2)
	var line_width: float = 1.5

	for branch_id: String in _branch_order:
		var branch_data: Dictionary = _branches[branch_id]
		var branch_label: Label = branch_data["label"] as Label
		if not branch_label:
			continue

		# Branch label top-center in local space
		var bl_global: Vector2 = branch_label.global_position
		var bl_local: Vector2 = bl_global - my_origin
		var bl_top_center: Vector2 = Vector2(
			bl_local.x + branch_label.size.x / 2.0,
			bl_local.y
		)
		var bl_bottom_center: Vector2 = Vector2(
			bl_local.x + branch_label.size.x / 2.0,
			bl_local.y + branch_label.size.y
		)

		# Line: S bottom -> branch label top
		draw_line(
			Vector2(s_center_x, s_bottom_y),
			bl_top_center,
			line_color,
			line_width,
			true
		)

		# Lines: branch label bottom -> each slot top-center
		var slot_line_color: Color = line_color.darkened(0.15)
		var slots: Array = branch_data.get("slots", [])
		for slot_variant: Variant in slots:
			if not slot_variant is Control:
				continue
			var slot_ctrl: Control = slot_variant as Control
			var sl_global: Vector2 = slot_ctrl.global_position
			var sl_local: Vector2 = sl_global - my_origin
			var sl_top_center: Vector2 = Vector2(
				sl_local.x + slot_ctrl.size.x / 2.0,
				sl_local.y
			)
			draw_line(
				bl_bottom_center,
				sl_top_center,
				slot_line_color,
				1.0,
				true
			)


# --- Public Methods ---

## Build the visual tree from a config type string (named configs only).
func build_tree(tree_type: String) -> void:
	_tree_type = tree_type
	_clear_tree()

	var config: Array = get_config_by_name(tree_type)
	_build_from_config(config)


## Build the visual tree from a raw config array (procedurally generated).
func build_tree_from_config(config: Array, label: String = "generated") -> void:
	_tree_type = label
	_clear_tree()
	_build_from_config(config)


## Internal: build visual nodes from a config array.
func _build_from_config(config: Array) -> void:

	# Wrapper VBox: holds the S label above the branches. Shrinks to content
	# and centers horizontally so it doesn't eat space from the hand/log/enemies.
	var tree_vbox := VBoxContainer.new()
	tree_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tree_vbox.add_theme_constant_override("separation", 8)
	tree_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tree_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(tree_vbox)

	# Sentence node label at the top
	_sentence_node_label = Label.new()
	_sentence_node_label.text = "═══ S ═══"
	_sentence_node_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_sentence_node_label, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(_sentence_node_label, ThemeManager.COLOR_TEXT_DIM)
	tree_vbox.add_child(_sentence_node_label)

	# Spacer so connection lines have vertical room between S and branch labels
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	tree_vbox.add_child(spacer)

	# Root branches container
	_root_container = HBoxContainer.new()
	_root_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_root_container.add_theme_constant_override("separation", 24)
	_root_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_root_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tree_vbox.add_child(_root_container)

	# Build branch structure from config entries
	for entry: Dictionary in config:
		var branch_id: String = entry.get("branch", "default")
		var pos: Enums.POSType = entry.get("pos", Enums.POSType.NOUN) as Enums.POSType
		var is_opt: bool = entry.get("optional", false)

		if not _branches.has(branch_id):
			_create_branch(branch_id)

		_add_slot_to_branch(branch_id, pos, is_opt)

	# Trigger line drawing after layout
	queue_redraw()


func get_tree_type() -> String:
	return _tree_type


func get_all_slots() -> Array[SyntaxSlot]:
	var result: Array[SyntaxSlot] = []
	for branch_id: String in _branch_order:
		var branch: Dictionary = _branches[branch_id]
		var slots: Array = branch.get("slots", [])
		for slot: Variant in slots:
			result.append(slot as SyntaxSlot)
	return result


func get_branch_ids() -> Array[String]:
	return _branch_order.duplicate()


func get_slots_in_branch(branch_id: String) -> Array[SyntaxSlot]:
	if not _branches.has(branch_id):
		return []
	var branch: Dictionary = _branches[branch_id]
	var result: Array[SyntaxSlot] = []
	var slots: Array = branch.get("slots", [])
	for slot: Variant in slots:
		result.append(slot as SyntaxSlot)
	return result


## All required (non-optional, non-locked) slots in this branch are filled.
func is_branch_complete(branch_id: String) -> bool:
	if not _branches.has(branch_id):
		return false
	var branch: Dictionary = _branches[branch_id]
	var slots: Array = branch.get("slots", [])
	for slot_variant: Variant in slots:
		var slot: SyntaxSlot = slot_variant as SyntaxSlot
		if slot.is_required and slot.placed_morpheme == null:
			return false
	return true


## All fillable slots filled AND every filled slot has POS match.
func is_tree_complete() -> bool:
	for branch_id: String in _branch_order:
		var branch: Dictionary = _branches[branch_id]
		var slots: Array = branch.get("slots", [])
		for slot_variant: Variant in slots:
			var slot: SyntaxSlot = slot_variant as SyntaxSlot
			if slot.placed_morpheme == null:
				return false
			if not slot.is_pos_matched():
				return false
	return true


## Per-branch completion info for cache updates.
func get_branch_completion() -> Dictionary:
	var result: Dictionary = {}
	for branch_id: String in _branch_order:
		var branch: Dictionary = _branches[branch_id]
		var slots: Array = branch.get("slots", [])
		var filled: int = 0
		var required: int = 0
		for slot_variant: Variant in slots:
			var slot: SyntaxSlot = slot_variant as SyntaxSlot
			if slot.is_required:
				required += 1
			if slot.placed_morpheme != null:
				filled += 1
		result[branch_id] = {
			"filled": filled,
			"required": required,
			"is_complete": is_branch_complete(branch_id),
		}
	return result


## All morphemes currently placed in any slot.
func get_filled_morphemes() -> Array:
	var result: Array = []
	for branch_id: String in _branch_order:
		var branch: Dictionary = _branches[branch_id]
		var slots: Array = branch.get("slots", [])
		for slot_variant: Variant in slots:
			var slot: SyntaxSlot = slot_variant as SyntaxSlot
			if slot.placed_morpheme != null:
				result.append(slot.placed_morpheme)
	return result


## Fire animation: sequentially lights filled slots left-to-right, then flashes white.
## The syntax tree is a dendrite; submitting fires the neural impulse.
func play_fire_animation() -> void:
	var all: Array[SyntaxSlot] = get_all_slots()
	var filled_count: int = 0
	for slot: SyntaxSlot in all:
		if slot.placed_morpheme != null:
			filled_count += 1
	if filled_count == 0:
		return
	# Sequential fire: left to right
	var pitch: int = 0
	for slot: SyntaxSlot in all:
		if slot.placed_morpheme == null:
			continue
		slot.modulate = Color(2.0, 2.0, 2.0)  # bright white flash
		SFX.play_cascade_tick(self, pitch)
		pitch = mini(pitch + 1, 5)
		await get_tree().create_timer(0.04).timeout
		slot.modulate = Color.WHITE
	# Final flash: whole tree white, then fade
	modulate = Color(1.5, 1.5, 1.5)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	await tween.finished


func clear_all_slots() -> void:
	for branch_id: String in _branch_order:
		var branch: Dictionary = _branches[branch_id]
		var slots: Array = branch.get("slots", [])
		for slot_variant: Variant in slots:
			var slot: SyntaxSlot = slot_variant as SyntaxSlot
			slot.clear_slot()
	update_branch_multipliers()


## Update multiplier labels based on current branch completion.
func update_branch_multipliers() -> void:
	for branch_id: String in _branch_order:
		var branch: Dictionary = _branches[branch_id]
		var mult_label: Label = branch.get("mult_label") as Label
		var label: Label = branch.get("label") as Label
		if not mult_label or not label:
			continue

		var is_complete: bool = is_branch_complete(branch_id)
		if is_complete:
			mult_label.text = "x%.1f" % BRANCH_MULT
			ThemeManager.apply_glow_text(mult_label, ThemeManager.COLOR_WARNING)
			# Brighten branch label
			var color_key: String = _get_branch_color_key(branch_id)
			var col: Color = POSColors.get_color(color_key)
			ThemeManager.apply_glow_text(label, col)
		else:
			mult_label.text = "x1.0"
			ThemeManager.apply_glow_text(mult_label, ThemeManager.COLOR_TEXT_DIM)
			var color_key: String = _get_branch_color_key(branch_id)
			var col: Color = POSColors.get_color(color_key).darkened(0.3)
			ThemeManager.apply_glow_text(label, col)


## Count completed branches.
func get_completed_branch_count() -> int:
	var count: int = 0
	for branch_id: String in _branch_order:
		if is_branch_complete(branch_id):
			count += 1
	return count


## Count empty optional slots.
func count_empty_optional_slots() -> int:
	var count: int = 0
	for branch_id: String in _branch_order:
		var branch: Dictionary = _branches[branch_id]
		var slots: Array = branch.get("slots", [])
		for slot_variant: Variant in slots:
			var slot: SyntaxSlot = slot_variant as SyntaxSlot
			if slot.is_optional and slot.placed_morpheme == null:
				count += 1
	return count


## Count optional slots that have been filled.
func count_optional_filled() -> int:
	var count: int = 0
	for branch_id: String in _branch_order:
		var branch: Dictionary = _branches[branch_id]
		var slots: Array = branch.get("slots", [])
		for slot_variant: Variant in slots:
			var slot: SyntaxSlot = slot_variant as SyntaxSlot
			if slot.is_optional and slot.placed_morpheme != null:
				count += 1
	return count


## Check if all required slots are filled (across all branches).
func all_required_filled() -> bool:
	for branch_id: String in _branch_order:
		var branch: Dictionary = _branches[branch_id]
		var slots: Array = branch.get("slots", [])
		for slot_variant: Variant in slots:
			var slot: SyntaxSlot = slot_variant as SyntaxSlot
			if slot.is_required and slot.placed_morpheme == null:
				return false
	return true


## Swap POS types on N random non-locked slots.
func scramble_random_slots(count: int) -> void:
	var eligible: Array[SyntaxSlot] = []
	for slot: SyntaxSlot in get_all_slots():
		if not slot.is_locked:
			eligible.append(slot)
	if eligible.size() < 2:
		return
	for i: int in range(mini(count, eligible.size() / 2)):
		var a: int = randi() % eligible.size()
		var b: int = (a + 1 + randi() % (eligible.size() - 1)) % eligible.size()
		var temp_pos: Enums.POSType = eligible[a].pos_type
		eligible[a].pos_type = eligible[b].pos_type
		eligible[b].pos_type = temp_pos
		eligible[a].update_display()
		eligible[b].update_display()


## Lock N random empty, non-locked slots (enemy can't place morphemes there).
func lock_random_slots(count: int) -> void:
	var eligible: Array[SyntaxSlot] = []
	for slot: SyntaxSlot in get_all_slots():
		if not slot.is_locked and slot.placed_morpheme == null:
			eligible.append(slot)
	eligible.shuffle()
	for i: int in range(mini(count, eligible.size())):
		eligible[i].is_locked = true
		eligible[i].update_display()


## Add N optional slots, one per call to add_random_optional_slot.
func add_optional_slots(count: int) -> void:
	for i: int in range(count):
		add_random_optional_slot()


## Add an optional slot to the longest branch.
func add_random_optional_slot() -> void:
	var longest_branch: String = ""
	var max_count: int = 0
	for branch_id: String in _branches.keys():
		var slots: Array[SyntaxSlot] = get_slots_in_branch(branch_id)
		if slots.size() > max_count:
			max_count = slots.size()
			longest_branch = branch_id
	if longest_branch.is_empty():
		return
	var new_slot: SyntaxSlot = SYNTAX_SLOT_SCENE.instantiate() as SyntaxSlot
	new_slot.pos_type = Enums.POSType.ADJECTIVE  # Default optional type
	new_slot.is_optional = true
	new_slot.is_required = false
	new_slot.branch_id = longest_branch
	new_slot.morpheme_dropped.connect(_on_slot_dropped)
	new_slot.morpheme_cleared.connect(_on_slot_cleared)
	var branch_data: Dictionary = _branches[longest_branch]
	var container: HBoxContainer = branch_data["container"]
	container.add_child(new_slot)
	branch_data["slots"].append(new_slot)


## Hide POS labels on N random slots.
func hide_random_slot_pos(count: int) -> void:
	var eligible: Array[SyntaxSlot] = []
	for slot: SyntaxSlot in get_all_slots():
		if not slot.is_pos_hidden:
			eligible.append(slot)
	eligible.shuffle()
	for i: int in range(mini(count, eligible.size())):
		eligible[i].is_pos_hidden = true
		eligible[i].update_display()


## Shift all placed morphemes one slot to the right (last wraps to first).
## count parameter is accepted for API compatibility but shift is always by 1.
func shift_slot_layout(_count: int = 1) -> void:
	shift_morphemes_right()


## Shift all placed morphemes one slot to the right (last wraps to first).
func shift_morphemes_right() -> void:
	var all: Array[SyntaxSlot] = get_all_slots()
	if all.size() < 2:
		return
	# Collect placed morphemes in order
	var morphemes: Array = []
	for slot: SyntaxSlot in all:
		morphemes.append(slot.placed_morpheme)  # null if empty
	# Rotate right: last element goes to front
	var last: Variant = morphemes.pop_back()
	morphemes.push_front(last)
	# Reassign
	for i: int in range(all.size()):
		if morphemes[i] != null:
			all[i].place(morphemes[i])
		else:
			all[i].clear_morpheme()


## Get all empty (unfilled, unlocked) slots.
func get_empty_slots() -> Array[SyntaxSlot]:
	var result: Array[SyntaxSlot] = []
	for slot: SyntaxSlot in get_all_slots():
		if slot.placed_morpheme == null and not slot.is_locked:
			result.append(slot)
	return result


## Get all filled slots.
func get_filled_slots() -> Array[SyntaxSlot]:
	var result: Array[SyntaxSlot] = []
	for slot: SyntaxSlot in get_all_slots():
		if slot.placed_morpheme != null:
			result.append(slot)
	return result


## Get the index of a slot in the flat slots array.
func get_slot_index(slot: SyntaxSlot) -> int:
	var all: Array[SyntaxSlot] = get_all_slots()
	return all.find(slot)


## Build the syntax_tree_data Dictionary expected by DamageResolver.
func build_resolver_data() -> Dictionary:
	var slots: Array[Dictionary] = []
	for branch_id: String in _branch_order:
		var branch: Dictionary = _branches[branch_id]
		var branch_slots: Array = branch.get("slots", [])
		for slot_variant: Variant in branch_slots:
			var slot: SyntaxSlot = slot_variant as SyntaxSlot
			var morphemes: Array = []
			if slot.placed_morpheme != null:
				morphemes.append(slot.placed_morpheme)
			slots.append({
				"pos": slot.pos_type,
				"is_optional": slot.is_optional,
				"is_filled": slot.placed_morpheme != null,
				"is_pos_matched": slot.is_pos_matched() if slot.placed_morpheme != null else true,
				"branch_id": slot.branch_id,
				"morphemes": morphemes,
			})
	return {"slots": slots}


# --- Private Methods ---

func _clear_tree() -> void:
	_branches.clear()
	_branch_order.clear()
	_sentence_node_label = null
	for child: Node in get_children():
		child.queue_free()


func _create_branch(branch_id: String) -> void:
	var branch_vbox := VBoxContainer.new()
	branch_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	branch_vbox.add_theme_constant_override("separation", 4)
	_root_container.add_child(branch_vbox)

	# Multiplier label
	var mult_label := Label.new()
	mult_label.text = "x1.0"
	mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(mult_label, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(mult_label, ThemeManager.COLOR_TEXT_DIM)
	branch_vbox.add_child(mult_label)

	# Branch name label (e.g., "[NP]")
	var branch_label := Label.new()
	branch_label.text = "[%s]" % branch_id
	branch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(branch_label, ThemeManager.FONT_BODY)
	var color_key: String = _get_branch_color_key(branch_id)
	var branch_color: Color = POSColors.get_color(color_key)
	ThemeManager.apply_glow_text(branch_label, branch_color.darkened(0.3))
	branch_vbox.add_child(branch_label)

	# Slot container (horizontal row within branch)
	var slot_hbox := HBoxContainer.new()
	slot_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_hbox.add_theme_constant_override("separation", 4)
	branch_vbox.add_child(slot_hbox)

	_branches[branch_id] = {
		"label": branch_label,
		"mult_label": mult_label,
		"slots": [],
		"container": slot_hbox,
		"vbox": branch_vbox,
	}
	_branch_order.append(branch_id)


func _add_slot_to_branch(
	branch_id: String,
	pos: Enums.POSType,
	is_opt: bool,
) -> void:
	var branch: Dictionary = _branches[branch_id]
	var container: HBoxContainer = branch["container"] as HBoxContainer

	var slot: SyntaxSlot = SYNTAX_SLOT_SCENE.instantiate() as SyntaxSlot
	slot.pos_type = pos
	slot.is_optional = is_opt
	slot.is_required = not is_opt
	slot.branch_id = branch_id

	slot.morpheme_dropped.connect(_on_slot_dropped)
	slot.morpheme_cleared.connect(_on_slot_cleared)

	container.add_child(slot)
	branch["slots"].append(slot)


func _get_branch_color_key(branch_id: String) -> String:
	# Strip numeric suffix: "NP2" -> "NP"
	var base: String = branch_id.rstrip("0123456789")
	if BRANCH_COLORS.has(base):
		return BRANCH_COLORS[base]
	return "default"


func _on_slot_dropped(morpheme: MorphemeData, slot: SyntaxSlot) -> void:
	update_branch_multipliers()
	queue_redraw()
	slot_morpheme_dropped.emit(morpheme, slot)


func _on_slot_cleared(slot: SyntaxSlot) -> void:
	update_branch_multipliers()
	queue_redraw()
	slot_morpheme_cleared.emit(slot)
