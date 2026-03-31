class_name CombatUI
extends Control

## Combat UI: 3-column layout (log | tree+hand | enemies), animations, input.
## No game logic. Connects to CombatScreen signals.

# --- Signals ---

signal submit_pressed
signal hold_pressed
signal morpheme_placed(morpheme: MorphemeData, slot: SyntaxSlot)
signal phoneme_used(phoneme: PhonemeData)

# --- Constants ---

const MORPHEME_BLOCK_SCENE: PackedScene = preload("res://scenes/combat/morpheme_block.tscn")
const SYNTAX_SLOT_SCENE: PackedScene = preload("res://scenes/combat/syntax_slot.tscn")
const ENEMY_PANEL_SCENE: PackedScene = preload("res://scenes/combat/enemy_panel.tscn")

const CASCADE_COLORS: Array[String] = ["#FFB300", "#FF8C00", "#FFD700", "#FFFFFF"]
const SHAKE_DURATION: float = 0.15
const FLOAT_DURATION: float = 0.8
const FLOAT_RISE: float = 40.0

const LEFT_PANEL_WIDTH: float = 160.0
const RIGHT_PANEL_WIDTH: float = 220.0
const CARD_SIZE := Vector2(120.0, 80.0)
const CARD_SPACING: int = 8
const MARGIN_SIZE: int = 16
const MAIN_SEPARATION: int = 4
const BOARD_SEPARATION: int = 16
const CENTER_SEPARATION: int = 20
const CASCADE_SLOT_FLASH: float = 0.06
const CASCADE_STEP_DELAY: float = 0.08
const CASCADE_EVENT_PAUSE: float = 0.2

# --- Variables ---

var combat_screen: Node = null
var _enemy_container: VBoxContainer
var _syntax_tree: SyntaxTree
var _hand_container: HBoxContainer
var _submit_button: Button
var _hold_button: Button
var _cogency_bar: ProgressBar
var _cogency_label: Label
var _insulation_label: Label
var _semant_label: Label
var _turn_label: Label
var _floor_label: Label
var _multiplier_label: Label
var _induction_preview: Label
var _combo_label: Label
var _phoneme_row: HBoxContainer
var _grapheme_row: HBoxContainer
var _combat_log: CombatLog
var _sentence_label: Label
var _enemy_panels: Array[EnemyPanel] = []
var _syntax_slots: Array[SyntaxSlot] = []
var _floor_number: int = 1
var _used_phoneme_ids: Dictionary = {}  ## tracks consumed phonemes this combat
var _cascade_running: bool = false
var _draw_pile_label: Label

func _ready() -> void:
	_build_layout()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match (event as InputEventKey).keycode:
		KEY_ENTER, KEY_KP_ENTER:
			if _submit_button and not _submit_button.disabled:
				submit_pressed.emit()
				get_viewport().set_input_as_handled()
		KEY_SPACE:
			if _hold_button and not _hold_button.disabled:
				hold_pressed.emit()
				get_viewport().set_input_as_handled()
		KEY_D:
			var cs: CombatScreen = combat_screen as CombatScreen
			if cs:
				cs.open_deck_viewer()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			var cs2: CombatScreen = combat_screen as CombatScreen
			if cs2:
				cs2.forfeit_combat()
			get_viewport().set_input_as_handled()


# --- Public Methods ---
func update_hand(hand: Array[MorphemeData]) -> void:
	for child: Node in _hand_container.get_children():
		child.queue_free()

	for morpheme: MorphemeData in hand:
		var block: MorphemeBlock = MORPHEME_BLOCK_SCENE.instantiate() as MorphemeBlock
		block.morpheme = morpheme
		block.custom_minimum_size = CARD_SIZE
		_hand_container.add_child(block)


func update_enemy_display(enemies: Array) -> void:
	for panel: EnemyPanel in _enemy_panels:
		panel.queue_free()
	_enemy_panels.clear()

	for enemy_data: Variant in enemies:
		if not enemy_data is EnemyData:
			continue
		var panel: EnemyPanel = ENEMY_PANEL_SCENE.instantiate() as EnemyPanel
		panel.enemy_data = enemy_data as EnemyData
		panel.custom_minimum_size.x = RIGHT_PANEL_WIDTH
		_enemy_container.add_child(panel)
		_enemy_panels.append(panel)


func build_syntax_tree(tree_type: String) -> void:
	_syntax_tree.build_tree(tree_type)
	_syntax_slots = _syntax_tree.get_all_slots()


func build_syntax_tree_from_config(config: Array) -> void:
	_syntax_tree.build_tree_from_config(config)
	_syntax_slots = _syntax_tree.get_all_slots()


func set_input_enabled(enabled: bool) -> void:
	_submit_button.disabled = not enabled
	_hold_button.disabled = not enabled
	for child: Node in _hand_container.get_children():
		if child is MorphemeBlock:
			(child as MorphemeBlock).set_process_input(enabled)


func update_player_stats(
	cogency: int,
	max_cogency: int,
	insulation: int,
	semant: int,
	turn: int,
) -> void:
	_cogency_bar.max_value = max_cogency
	_cogency_bar.value = cogency
	_cogency_label.text = "COG %d/%d" % [cogency, max_cogency]
	_insulation_label.text = "INS (%d)" % insulation
	_semant_label.text = "SEM %d" % semant
	_turn_label.text = "T%d" % turn
	_combat_log.set_turn(turn)


func update_multiplier_display(multiplier: float, induction: int) -> void:
	_multiplier_label.text = "x%.1f" % multiplier
	var color: Color = ThemeManager.COLOR_WARNING if multiplier > 1.0 else ThemeManager.COLOR_TEXT_DIM
	_multiplier_label.add_theme_color_override("font_color", color)
	_induction_preview.text = "INDUCTION: [%d]" % induction


func play_multiplier_cascade(steps: Array[Dictionary]) -> void:
	var running_mult: float = 1.0
	var running_induction: int = 0

	# Feature 3: combo escalation -- get current combo to scale speed and pitch
	var combo: int = 0
	var cs: CombatScreen = combat_screen as CombatScreen
	if cs:
		combo = cs.get_combat_state().get_combo()
	# cascade speeds up at higher combos (combo 3 = ~69% normal duration, combo 5 = ~57%)
	var speed_mult: float = 1.0 / (1.0 + float(combo) * 0.15)
	var pitch_bonus: int = mini(combo, 5)

	# Dim all slots first
	for slot: SyntaxSlot in _syntax_slots:
		slot.modulate = Color(0.3, 0.3, 0.3)

	for i: int in range(steps.size()):
		var step: Dictionary = steps[i]
		var slot_idx: int = step.get("slot_index", 0)
		var word_induction: int = step.get("induction", 0)
		var mults: Array = step.get("mults", [])
		var is_branch_complete: bool = step.get("branch_complete", false)
		var is_full_tree: bool = step.get("full_tree", false)

		# 1. Flash the slot white (0.06s) + pentatonic tick
		if slot_idx >= 0 and slot_idx < _syntax_slots.size():
			var slot: SyntaxSlot = _syntax_slots[slot_idx]
			var slot_tween := create_tween()
			slot_tween.tween_property(slot, "modulate", Color.WHITE, CASCADE_SLOT_FLASH)

		SFX.play_cascade_tick(self, i + pitch_bonus)
		await get_tree().create_timer(CASCADE_STEP_DELAY * speed_mult).timeout

		# 2. Flash each multiplier with floating tag + label pop
		for m_entry: Dictionary in mults:
			var mult_value: float = m_entry.get("value", 1.0)
			running_mult *= mult_value
			var tag_text: String = m_entry.get("label", "")

			# Floating tag label (rises 30px, fades over 0.5s)
			if tag_text != "" and slot_idx >= 0 and slot_idx < _syntax_slots.size():
				_spawn_floating_tag(
					tag_text,
					_syntax_slots[slot_idx].global_position + Vector2(0.0, -10.0),
				)

			# Pop the multiplier_label (scale 1.0 -> 1.35 -> 1.0 over 0.16s)
			var m_tween := create_tween()
			m_tween.tween_property(
				_multiplier_label, "scale",
				Vector2(1.35, 1.35), 0.06,
			).set_trans(Tween.TRANS_BACK)
			m_tween.tween_property(
				_multiplier_label, "scale",
				Vector2(1.0, 1.0), 0.1,
			)

			if tag_text == "NOVEL":
				SFX.play_novel_word(self)
			else:
				SFX.play_cascade_mult(self)
			await get_tree().create_timer(CASCADE_STEP_DELAY * speed_mult).timeout

		running_induction += word_induction
		var live_total: int = maxi(int(float(running_induction) * running_mult), 1)
		update_multiplier_display(running_mult, live_total)

		# 3. Branch complete: bigger pop + SFX
		if is_branch_complete:
			SFX.play_cascade_branch(self)
			var branch_tween := create_tween()
			branch_tween.tween_property(
				_multiplier_label, "scale",
				Vector2(1.5, 1.5), 0.08,
			).set_trans(Tween.TRANS_BACK)
			branch_tween.tween_property(
				_multiplier_label, "scale",
				Vector2(1.0, 1.0), 0.12,
			)
			await get_tree().create_timer(CASCADE_EVENT_PAUSE * speed_mult).timeout

		# 4. Full tree: screen flash + biggest pop + SFX
		if is_full_tree:
			SFX.play_cascade_full_tree(self)
			_flash_screen_cascade()
			var tree_tween := create_tween()
			tree_tween.tween_property(
				_multiplier_label, "scale",
				Vector2(2.0, 2.0), 0.1,
			).set_trans(Tween.TRANS_BACK)
			tree_tween.tween_property(
				_multiplier_label, "scale",
				Vector2(1.0, 1.0), 0.15,
			)
			await get_tree().create_timer(0.25 * speed_mult).timeout

	# Critical hit threshold: x8.0+ triggers special feedback
	if running_mult >= 8.0:
		_flash_screen_gold()
		SFX.play_cascade_full_tree(self)
		var crit_tween := create_tween()
		crit_tween.tween_property(
			_multiplier_label, "scale",
			Vector2(2.5, 2.5), 0.1,
		).set_trans(Tween.TRANS_BACK)
		crit_tween.tween_property(
			_multiplier_label, "scale",
			Vector2(1.0, 1.0), 0.15,
		)
		_combat_log.log_text("[color=#FFD54F][b]>> CRITICAL INDUCTION <<[/b][/color]")
		await get_tree().create_timer(0.3).timeout

	# Track peak multiplier for highlights
	var state: CombatState = cs.get_combat_state() if cs else null
	if state and running_mult > state.peak_multiplier:
		state.peak_multiplier = running_mult

	# Restore all slot modulation
	for slot: SyntaxSlot in _syntax_slots:
		slot.modulate = Color.WHITE

	# Feature 2: dramatic pause then final induction number slam
	var final_induction: int = maxi(int(float(running_induction) * running_mult), 1)
	await get_tree().create_timer(0.3).timeout
	_induction_preview.text = "INDUCTION: [%d]" % final_induction
	var final_tween: Tween = create_tween()
	final_tween.tween_property(
		_induction_preview, "scale", Vector2(1.5, 1.5), 0.08,
	).set_trans(Tween.TRANS_BACK)
	final_tween.tween_property(_induction_preview, "scale", Vector2(1.0, 1.0), 0.12)
	SFX.play_impact(self)
	_combat_log.log_text("[color=#FFFFFF][b]  == TOTAL INDUCTION: %d ==[/b][/color]" % final_induction)


func show_floating_number(value: int, pos: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = str(value)
	label.position = pos
	label.z_index = 100
	ThemeManager.apply_mono_font(label, ThemeManager.FONT_H1)
	label.add_theme_color_override("font_color", color)
	label.pivot_offset = label.size * 0.5
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - FLOAT_RISE, FLOAT_DURATION)
	tween.tween_property(label, "modulate:a", 0.0, FLOAT_DURATION)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


func shake_node(node: Control, intensity: float) -> void:
	var original_pos: Vector2 = node.position
	var tween := create_tween()
	for j: int in range(4):
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity),
		)
		tween.tween_property(node, "position", original_pos + offset, SHAKE_DURATION / 4.0)
	tween.tween_property(node, "position", original_pos, SHAKE_DURATION / 4.0)


func animate_enemy_attacks(results: Array) -> void:
	for result: Dictionary in results:
		var idx: int = result.get("panel_index", 0)
		var damage: int = result.get("damage", 0)
		var absorbed: int = result.get("absorbed", 0)
		if idx >= 0 and idx < _enemy_panels.size():
			var enemy_name: String = _enemy_panels[idx].enemy_data.display_name if _enemy_panels[idx].enemy_data else "enemy"
			SFX.play_enemy_attack(self)
			shake_node(_cogency_bar, 4.0)
			show_floating_number(
				damage,
				_cogency_bar.global_position + Vector2(0.0, -20.0),
				ThemeManager.COLOR_ALERT,
			)
			_combat_log.log_enemy_attack(enemy_name, damage, absorbed)
			await get_tree().create_timer(0.3).timeout


func update_enemy_panel(
	index: int,
	cogency: int,
	max_cogency: int,
	intent: Dictionary,
) -> void:
	if index < 0 or index >= _enemy_panels.size():
		return
	_enemy_panels[index].update_display(cogency, max_cogency, intent)


func play_enemy_defeat(index: int) -> void:
	if index < 0 or index >= _enemy_panels.size():
		return
	_enemy_panels[index].play_defeat_animation()


func get_syntax_slots() -> Array[SyntaxSlot]:
	return _syntax_slots


func get_syntax_tree() -> SyntaxTree:
	return _syntax_tree


func get_combat_log() -> CombatLog:
	return _combat_log


## Build phoneme consumable buttons from RunData.
func build_phoneme_buttons(phonemes: Array[PhonemeData]) -> void:
	for child: Node in _phoneme_row.get_children():
		child.queue_free()
	_used_phoneme_ids.clear()

	for phoneme: PhonemeData in phonemes:
		var btn := Button.new()
		btn.text = phoneme.ipa_symbol
		btn.custom_minimum_size = Vector2(40.0, 40.0)
		btn.tooltip_text = "%s: %s" % [phoneme.display_name, phoneme.description]
		ThemeManager.apply_mono_font(btn, ThemeManager.FONT_BODY)
		ThemeManager.apply_button_style(btn, ThemeManager.COLOR_WARNING)
		btn.pressed.connect(_on_phoneme_button_pressed.bind(phoneme, btn))
		_phoneme_row.add_child(btn)


## Build grapheme display icons from RunData.
func build_grapheme_display(graphemes: Array[GraphemeData]) -> void:
	for child: Node in _grapheme_row.get_children():
		child.queue_free()

	for grapheme: GraphemeData in graphemes:
		var lbl := Label.new()
		lbl.text = grapheme.symbol
		lbl.custom_minimum_size = Vector2(24.0, 24.0)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.tooltip_text = "%s: %s" % [grapheme.display_name, grapheme.description]
		ThemeManager.apply_mono_font(lbl, ThemeManager.FONT_MICRO)
		ThemeManager.apply_glow_text(lbl, ThemeManager.COLOR_TEXT_DIM)
		_grapheme_row.add_child(lbl)


## Flash a grapheme label when its effect triggers.
func flash_grapheme(grapheme_id: String) -> void:
	var cs: CombatScreen = combat_screen as CombatScreen
	if not cs:
		return
	var run: RunData = GameManager.run
	if not run:
		return
	for i: int in range(run.acquired_graphemes.size()):
		if run.acquired_graphemes[i].id == grapheme_id:
			if i < _grapheme_row.get_child_count():
				var lbl: Label = _grapheme_row.get_child(i) as Label
				if lbl:
					var tween := create_tween()
					ThemeManager.apply_glow_text(lbl, ThemeManager.COLOR_WARNING)
					tween.tween_interval(0.3)
					tween.tween_callback(func() -> void:
						ThemeManager.apply_glow_text(lbl, ThemeManager.COLOR_TEXT_DIM)
					)
			return


## Update the floor label with column/total format.
func update_floor_display(column: int, total: int) -> void:
	_floor_label.text = "FLOOR %d/%d" % [column, total]


## Show or hide the combo counter. Only visible when combo > 1.
func update_combo_display(combo: int) -> void:
	if combo > 1:
		_combo_label.text = "x%d COMBO" % combo
		_combo_label.visible = true
	else:
		_combo_label.visible = false


# --- Private Methods ---

func _build_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Void background
	var bg := ColorRect.new()
	bg.color = ThemeManager.COLOR_VOID
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Root margin container (16px all sides)
	var main_margin := MarginContainer.new()
	main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_margin.add_theme_constant_override("margin_left", MARGIN_SIZE)
	main_margin.add_theme_constant_override("margin_right", MARGIN_SIZE)
	main_margin.add_theme_constant_override("margin_top", MARGIN_SIZE)
	main_margin.add_theme_constant_override("margin_bottom", MARGIN_SIZE)
	add_child(main_margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", MAIN_SEPARATION)
	main_margin.add_child(main_vbox)

	# ========== TOP BAR ==========
	_build_top_bar(main_vbox)

	# --- Separator ---
	var sep1 := HSeparator.new()
	sep1.add_theme_stylebox_override("separator", _make_separator_style())
	main_vbox.add_child(sep1)

	# ========== BOARD AREA (3-column) ==========
	var board := HBoxContainer.new()
	board.add_theme_constant_override("separation", BOARD_SEPARATION)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(board)

	# --- Left Panel: Combat Log ---
	_build_left_panel(board)

	# --- Center Panel: Syntax Tree + Hand ---
	_build_center_panel(board)

	# --- Right Panel: Enemies ---
	_build_right_panel(board)

	# --- Separator ---
	var sep2 := HSeparator.new()
	sep2.add_theme_stylebox_override("separator", _make_separator_style())
	main_vbox.add_child(sep2)

	# ========== BOTTOM BAR ==========
	_build_bottom_bar(main_vbox)


func _build_top_bar(parent: VBoxContainer) -> void:
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	parent.add_child(top_bar)

	_turn_label = _make_stat_label("T1", ThemeManager.COLOR_TEXT_DIM)
	top_bar.add_child(_turn_label)
	_floor_label = _make_stat_label("FLOOR 1/17", ThemeManager.COLOR_TEXT_DIM)
	top_bar.add_child(_floor_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	_semant_label = _make_stat_label("SEM 0", ThemeManager.COLOR_GOLD)
	top_bar.add_child(_semant_label)


func _build_left_panel(parent: HBoxContainer) -> void:
	var left_panel := VBoxContainer.new()
	left_panel.custom_minimum_size.x = LEFT_PANEL_WIDTH
	left_panel.size_flags_horizontal = Control.SIZE_FILL
	parent.add_child(left_panel)

	_combat_log = CombatLog.new()
	left_panel.add_child(_combat_log)


func _build_center_panel(parent: HBoxContainer) -> void:
	var center_panel := VBoxContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_panel.add_theme_constant_override("separation", CENTER_SEPARATION)
	center_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(center_panel)

	# Sentence label (shows the constructed word/sentence)
	_sentence_label = Label.new()
	_sentence_label.text = ""
	_sentence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_sentence_label, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(_sentence_label, ThemeManager.COLOR_TEXT_MAIN)
	center_panel.add_child(_sentence_label)

	# SyntaxTree component — shrinks to content, centered in panel
	_syntax_tree = SyntaxTree.new()
	_syntax_tree.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_syntax_tree.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_syntax_tree.slot_morpheme_dropped.connect(_on_slot_morpheme_dropped)
	_syntax_tree.slot_morpheme_cleared.connect(_on_slot_morpheme_cleared)
	center_panel.add_child(_syntax_tree)

	# Multiplier + induction preview row
	var mult_row := HBoxContainer.new()
	mult_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mult_row.add_theme_constant_override("separation", 16)
	center_panel.add_child(mult_row)

	_multiplier_label = Label.new()
	_multiplier_label.text = "x1.0"
	_multiplier_label.pivot_offset = Vector2(30.0, 10.0)
	ThemeManager.apply_mono_font(_multiplier_label, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(_multiplier_label, ThemeManager.COLOR_TEXT_DIM)
	mult_row.add_child(_multiplier_label)

	_induction_preview = Label.new()
	_induction_preview.text = "INDUCTION: [0]"
	_induction_preview.pivot_offset = Vector2(60.0, 10.0)
	ThemeManager.apply_mono_font(_induction_preview, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(_induction_preview, ThemeManager.COLOR_WARNING)
	mult_row.add_child(_induction_preview)

	_combo_label = Label.new()
	_combo_label.text = ""
	_combo_label.visible = false
	ThemeManager.apply_mono_font(_combo_label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(_combo_label, ThemeManager.COLOR_SUCCESS)
	mult_row.add_child(_combo_label)

	# Hand container (morpheme cards, below syntax tree)
	_hand_container = HBoxContainer.new()
	_hand_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_hand_container.add_theme_constant_override("separation", CARD_SPACING)
	_hand_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.add_child(_hand_container)

	# Draw/discard pile counter (feature 4: deck visibility)
	_draw_pile_label = Label.new()
	_draw_pile_label.text = "DRAW: 0 | DISC: 0"
	_draw_pile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_draw_pile_label, ThemeManager.FONT_MICRO)
	_draw_pile_label.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	center_panel.add_child(_draw_pile_label)


func _build_right_panel(parent: HBoxContainer) -> void:
	var right_panel := VBoxContainer.new()
	right_panel.custom_minimum_size.x = RIGHT_PANEL_WIDTH
	right_panel.size_flags_horizontal = Control.SIZE_FILL
	right_panel.add_theme_constant_override("separation", 4)
	parent.add_child(right_panel)

	_enemy_container = right_panel


func _build_bottom_bar(parent: VBoxContainer) -> void:
	var bottom_bar := HBoxContainer.new()
	bottom_bar.add_theme_constant_override("separation", 12)
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(bottom_bar)

	_cogency_label = _make_stat_label("COG 50/50", ThemeManager.COLOR_SUCCESS)
	bottom_bar.add_child(_cogency_label)

	_cogency_bar = _make_cogency_bar()
	bottom_bar.add_child(_cogency_bar)

	_insulation_label = _make_stat_label("INS (0)", ThemeManager.COLOR_INSULATION)
	bottom_bar.add_child(_insulation_label)

	_submit_button = _make_action_button("SUBMIT", ThemeManager.COLOR_SUCCESS, _on_submit_pressed)
	bottom_bar.add_child(_submit_button)
	_hold_button = _make_action_button("HOLD", ThemeManager.COLOR_TEXT_DIM, _on_hold_pressed)
	bottom_bar.add_child(_hold_button)

	_grapheme_row = HBoxContainer.new()
	_grapheme_row.add_theme_constant_override("separation", 2)
	bottom_bar.add_child(_grapheme_row)

	_phoneme_row = HBoxContainer.new()
	_phoneme_row.add_theme_constant_override("separation", 4)
	bottom_bar.add_child(_phoneme_row)


func _make_stat_label(text_content: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text_content
	ThemeManager.apply_mono_font(lbl, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(lbl, color)
	return lbl


func _make_cogency_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(120.0, 12.0)
	bar.max_value = 50
	bar.value = 50
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = ThemeManager.COLOR_SUCCESS
	fill.set_corner_radius_all(0)
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = ThemeManager.COLOR_PANEL
	bg.set_corner_radius_all(0)
	bg.set_border_width_all(1)
	bg.border_color = ThemeManager.COLOR_TEXT_DIM
	bar.add_theme_stylebox_override("background", bg)
	return bar


func _make_action_button(text_content: String, color: Color, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text_content
	ThemeManager.apply_mono_font(btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(btn, color)
	btn.pressed.connect(callback)
	return btn


func _make_separator_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeManager.COLOR_TEXT_DIM
	style.content_margin_top = 1.0
	style.content_margin_bottom = 0.0
	return style


func _refresh_player_stats() -> void:
	var cs: CombatScreen = combat_screen as CombatScreen
	if not cs:
		return
	var state: CombatState = cs.get_combat_state()
	update_player_stats(
		state.player_cogency, state.max_cogency,
		state.player_insulation, state.semant, state.current_turn,
	)


## Show near-miss log lines for branches that were partially filled but incomplete (feature 1).
func _show_near_misses(branch_ids: Array[String], completion: Dictionary) -> void:
	for branch_id: String in branch_ids:
		var branch: Dictionary = completion.get(branch_id, {})
		var filled: int = branch.get("filled", 0)
		var required: int = branch.get("required", 0)
		var is_complete: bool = branch.get("is_complete", false)
		if not is_complete and filled > 0 and required > 0:
			var miss_text: String = "[%s] %d/%d → x2.0 IF COMPLETE" % [branch_id, filled, required]
			_combat_log.log_text("[color=#4A4A55]  %s[/color]" % miss_text)


func _refresh_draw_count() -> void:
	var cs: CombatScreen = combat_screen as CombatScreen
	if not cs:
		return
	var state: CombatState = cs.get_combat_state()
	_draw_pile_label.text = "DRAW: %d | DISC: %d" % [
		state.draw_pile.size(),
		state.discard_pile.size(),
	]


func _refresh_enemy_panels() -> void:
	var cs: CombatScreen = combat_screen as CombatScreen
	if not cs:
		return
	var ec: EnemyController = cs.get_enemy_controller()
	var all_enemies: Array = ec.get_all_enemies()
	for i: int in range(mini(all_enemies.size(), _enemy_panels.size())):
		var inst: EnemyController.EnemyInstance = all_enemies[i] as EnemyController.EnemyInstance
		if inst and inst.is_alive():
			_enemy_panels[i].update_display(
				inst.current_cogency, inst.max_cogency, inst.current_intent,
			)


func _flash_screen() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.3)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 200
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.15)
	tween.tween_callback(flash.queue_free)


## Gold screen flash for critical induction threshold (x8.0+).
func _flash_screen_gold() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.84, 0.0, 0.25)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 200
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.4)
	tween.tween_callback(flash.queue_free)


## Screen flash for cascade full tree (white overlay 0.35 alpha -> 0 over 0.25s).
func _flash_screen_cascade() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.35)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 200
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.25)
	tween.tween_callback(flash.queue_free)


## Spawn a floating tag label that rises 30px and fades over 0.5s.
func _spawn_floating_tag(tag_text: String, pos: Vector2) -> void:
	var tag := Label.new()
	tag.text = tag_text
	tag.position = pos
	tag.z_index = 100
	ThemeManager.apply_mono_font(tag, ThemeManager.FONT_MICRO)
	tag.add_theme_color_override("font_color", ThemeManager.COLOR_WARNING)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(tag, "position:y", pos.y - 30.0, 0.5)
	tween.tween_property(tag, "modulate:a", 0.0, 0.5)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		if is_instance_valid(tag):
			tag.queue_free()
	)


func _set_input_enabled(enabled: bool) -> void:
	set_input_enabled(enabled)


func _advance_after_cascade() -> void:
	var cs: CombatScreen = combat_screen as CombatScreen
	if cs:
		cs.advance_to_enemy_turn()


func _connect_signals() -> void:
	var cs: CombatScreen = combat_screen as CombatScreen
	if not cs:
		push_warning("CombatUI._connect_signals: combat_screen is null or not CombatScreen")
		return
	cs.phase_changed.connect(_on_phase_changed)
	cs.hand_updated.connect(_on_hand_updated)
	cs.enemy_intents_updated.connect(_on_enemy_intents_updated)
	cs.damage_resolved.connect(_on_damage_resolved)
	cs.enemy_turn_completed.connect(_on_enemy_turn_completed)
	cs.combat_ended.connect(_on_combat_ended)
	cs.morpheme_placed.connect(_on_morpheme_placed_signal)
	cs.morpheme_removed.connect(_on_morpheme_removed_signal)
	cs.word_validated.connect(_on_word_validated)

	# --- CombatUI -> CombatScreen button wiring ---
	submit_pressed.connect(cs.submit_word)
	hold_pressed.connect(cs.hold_turn)
	phoneme_used.connect(cs.use_phoneme)


func initialize_combat_display() -> void:
	combat_screen = get_parent()
	_connect_signals()
	var cs: CombatScreen = combat_screen as CombatScreen
	if not cs:
		push_warning("CombatUI: combat_screen is not CombatScreen")
		return

	# Store floor number for display
	_floor_number = cs._floor_number
	_floor_label.text = "F%d" % _floor_number

	# Build enemy panels from EnemyController data
	var ec: EnemyController = cs.get_enemy_controller()
	var all_enemies: Array = ec.get_all_enemies()
	for panel: EnemyPanel in _enemy_panels:
		panel.queue_free()
	_enemy_panels.clear()
	for enemy_inst: Variant in all_enemies:
		var inst: EnemyController.EnemyInstance = enemy_inst as EnemyController.EnemyInstance
		if not inst or not inst.data:
			continue
		var panel: EnemyPanel = ENEMY_PANEL_SCENE.instantiate() as EnemyPanel
		panel.enemy_data = inst.data
		panel.custom_minimum_size.x = RIGHT_PANEL_WIDTH
		_enemy_container.add_child(panel)
		_enemy_panels.append(panel)

	# Build syntax tree: procedural config or named type
	var tree_type: String = cs.get_tree_type()
	var generated: Array = cs.get_generated_config()
	if not generated.is_empty():
		build_syntax_tree_from_config(generated)
	else:
		build_syntax_tree(tree_type)

	# Build phoneme buttons from RunData
	if GameManager.run:
		build_phoneme_buttons(GameManager.run.acquired_phonemes)
		build_grapheme_display(GameManager.run.acquired_graphemes)
		# Floor display: column/17 within the current region
		var col: int = GameManager.run.current_column + 1
		update_floor_display(col, 17)

	# Initial stats and hand update
	_refresh_player_stats()
	var state: CombatState = cs.get_combat_state()
	if not state.hand.is_empty():
		update_hand(state.hand)

	_combat_log.log_text("[color=%s]Combat begins[/color]" % CombatLog.COLOR_WHITE)


# --- Signal Handlers (CombatScreen -> CombatUI) ---

func _on_phase_changed(phase: CombatScreen.Phase) -> void:
	match phase:
		CombatScreen.Phase.PLACE, CombatScreen.Phase.AFFIX:
			set_input_enabled(true)
		CombatScreen.Phase.RESOLVE:
			_set_input_enabled(false)
		CombatScreen.Phase.ENEMY_TURN:
			# Combo resets on hold; reflect in UI
			set_input_enabled(false)
			var cs: CombatScreen = combat_screen as CombatScreen
			if cs:
				update_combo_display(cs.get_combat_state().get_combo())
		_:
			set_input_enabled(false)


func _on_hand_updated(hand: Array[MorphemeData]) -> void:
	update_hand(hand)
	_refresh_player_stats()
	_refresh_draw_count()


func _on_enemy_intents_updated(_intents: Array[Dictionary]) -> void:
	_refresh_enemy_panels()


func _on_damage_resolved(result: Dictionary) -> void:
	if _cascade_running:
		push_warning("CombatUI: cascade already running, ignoring duplicate damage_resolved")
		return
	var cs: CombatScreen = combat_screen as CombatScreen
	if not cs:
		return

	# Log scoring breakdown if present
	var word_form: String = result.get("word", result.get("word_form", ""))
	var base_induction: int = result.get("base_induction", 0)
	var mults: Array[Dictionary] = []
	var raw_mults: Array = result.get("multipliers", [])
	for m: Variant in raw_mults:
		if m is Dictionary:
			mults.append(m as Dictionary)
	var total_induction: int = result.get("total_induction", 0)

	if word_form != "":
		_combat_log.log_scoring(word_form, base_induction, mults)

	# Log damage dealt to each target
	var targets_hit: Array = result.get("targets_hit", [])
	for target_info: Variant in targets_hit:
		if target_info is Dictionary:
			var t: Dictionary = target_info as Dictionary
			var t_name: String = t.get("name", "enemy")
			var t_dmg: int = t.get("damage", total_induction)
			_combat_log.log_damage(t_name, t_dmg)

	_refresh_player_stats()

	# Refresh enemy panels + detect defeats
	var ec: EnemyController = cs.get_enemy_controller()
	var all_enemies: Array = ec.get_all_enemies()
	for i: int in range(mini(all_enemies.size(), _enemy_panels.size())):
		var inst: EnemyController.EnemyInstance = all_enemies[i] as EnemyController.EnemyInstance
		if not inst:
			continue
		_enemy_panels[i].update_display(
			inst.current_cogency, inst.max_cogency, inst.current_intent,
		)
		if inst.is_defeated:
			_enemy_panels[i].play_defeat_animation()
			_combat_log.log_defeat(inst.data.display_name if inst.data else "enemy")

	# Capture branch completion before clearing (feature 1: near-miss feedback)
	var branch_completion_snapshot: Dictionary = _syntax_tree.get_branch_completion()
	var branch_ids_snapshot: Array[String] = _syntax_tree.get_branch_ids()

	# Neural firing animation: the dendrite discharges before clearing
	if _syntax_tree:
		await _syntax_tree.play_fire_animation()
	_syntax_tree.clear_all_slots()

	# Update combo display
	var combo: int = result.get("combo", 0)
	update_combo_display(combo)

	# Run cascade animation before advancing; blocks enemy turn until complete
	var cascade_steps: Array = result.get("cascade_steps", [])
	_cascade_running = true
	await play_multiplier_cascade(cascade_steps)
	_cascade_running = false

	# Near-miss feedback: show incomplete branches that had at least one fill (feature 1)
	_show_near_misses(branch_ids_snapshot, branch_completion_snapshot)

	_advance_after_cascade()


func _on_enemy_turn_completed(results: Array[Dictionary]) -> void:
	await animate_enemy_attacks(results)
	_refresh_player_stats()
	# Insulation absorption feedback (feature 5)
	for result: Dictionary in results:
		var absorbed: int = result.get("absorbed", 0)
		var damage: int = result.get("damage", 0)
		if absorbed > 0:
			_combat_log.log_text("[color=#CE93D8]  INSULATION absorbs %d[/color]" % absorbed)
		if damage > 0:
			_combat_log.log_text("[color=#FF1E40]  -%d COGENCY[/color]" % damage)


func _on_combat_ended(is_victory: bool) -> void:
	set_input_enabled(false)
	if is_victory:
		_multiplier_label.text = "VICTORY"
		_combat_log.log_text("[color=%s]Victory![/color]" % CombatLog.COLOR_SUCCESS)
	else:
		_multiplier_label.text = "DEFEAT"
		_combat_log.log_text("[color=%s]Defeated.[/color]" % CombatLog.COLOR_ALERT)


func _on_morpheme_placed_signal(_morpheme: MorphemeData, _slot_index: int) -> void:
	pass  # Visual feedback handled by SyntaxSlot._drop_data

func _on_morpheme_removed_signal(_slot_index: int) -> void:
	pass  # Visual feedback handled by SyntaxSlot.clear_slot

func _on_word_validated(result: Dictionary) -> void:
	if not result.get("is_valid", false):
		_induction_preview.text = result.get("reason", "INVALID") if result.get("reason", "") != "" else "INVALID"

func _on_submit_pressed() -> void:
	submit_pressed.emit()

func _on_hold_pressed() -> void:
	# Hold feedback: flash hand gold + floating text + charging sound
	SFX.play_shield(self)
	for child: Node in _hand_container.get_children():
		if child is Control:
			var card: Control = child as Control
			var tween := create_tween()
			tween.tween_property(card, "modulate", Color(1.0, 0.84, 0.0), 0.05)
			tween.tween_property(card, "modulate", Color.WHITE, 0.1)
	_spawn_floating_tag("x2 NEXT TURN", _hand_container.global_position + Vector2(40.0, -10.0))
	hold_pressed.emit()


func _on_slot_morpheme_dropped(morpheme: MorphemeData, slot: SyntaxSlot) -> void:
	SFX.play_slot_fill(self)
	morpheme_placed.emit(morpheme, slot)

	var cs: CombatScreen = combat_screen as CombatScreen
	if cs:
		var slot_index: int = _syntax_slots.find(slot)
		if slot_index >= 0:
			cs.place_morpheme(morpheme, slot_index)


func _on_slot_morpheme_cleared(slot: SyntaxSlot) -> void:
	SFX.play_slot_clear(self)

	var cs: CombatScreen = combat_screen as CombatScreen
	if cs:
		var slot_index: int = _syntax_slots.find(slot)
		if slot_index >= 0:
			cs.remove_morpheme(slot_index)


func _on_phoneme_button_pressed(phoneme: PhonemeData, btn: Button) -> void:
	if _used_phoneme_ids.has(phoneme.id):
		return
	_used_phoneme_ids[phoneme.id] = true
	btn.disabled = true
	btn.modulate = Color(0.4, 0.4, 0.4)
	phoneme_used.emit(phoneme)
