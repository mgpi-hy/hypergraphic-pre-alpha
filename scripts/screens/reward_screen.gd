class_name RewardScreen
extends ScreenState

## Post-combat reward screen. Offers morpheme, grapheme, and semant rewards.
## Player picks a category or skips, then proceeds to the map.

# --- Constants ---

const SCENE_MAP: String = "res://scenes/screens/map_screen.tscn"
const ACCENT_COLOR := ThemeManager.COLOR_WARNING
const GRAPHEME_COLOR := ThemeManager.COLOR_SUCCESS
const MORPH_COLOR := ThemeManager.COLOR_INSULATION
const DIM_COLOR := ThemeManager.COLOR_TEXT_DIM
const SEMANT_REWARD_BASE: int = 3

# --- Private Variables ---

var _reward_data: Dictionary = {}
var _claimed: Dictionary = {}
var _map: Variant = null
var _is_boss_victory: bool = false
var _reward_list: VBoxContainer = null
var _morpheme_choices: Array[MorphemeData] = []
var _morpheme_sub_panel: Control = null
var _morpheme_row: PanelContainer = null
var _grapheme_row: PanelContainer = null


# --- Virtual Methods ---

func enter(previous: String, data: Dictionary = {}) -> void:
	super.enter(previous, data)
	_reward_data = data
	_map = data.get("map", null)
	_is_boss_victory = data.get("is_boss_victory", false) as bool
	_build_ui()


# --- Private Methods ---

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.03, 0.95)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	ThemeManager.build_unicode_grid(self, "limbic system", 4, 0.015)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 200)
	margin.add_theme_constant_override("margin_right", 200)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(main_vbox)

	# Header
	var header := Label.new()
	header.text = "═══ SPOILS ═══"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(header, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(header, ACCENT_COLOR)
	main_vbox.add_child(header)

	# Highlights box (post-combat stats)
	var highlights: Dictionary = _reward_data.get("highlights", {})
	if not highlights.is_empty():
		var hl := RichTextLabel.new()
		hl.bbcode_enabled = true
		hl.fit_content = true
		hl.scroll_active = false
		hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hl.selection_enabled = false
		ThemeManager.apply_mono_font_rtl(hl, ThemeManager.FONT_MICRO)
		var best_w: String = highlights.get("best_word", "")
		var best_i: int = highlights.get("best_induction", 0)
		var peak_m: float = highlights.get("peak_multiplier", 1.0)
		var total_d: int = highlights.get("total_damage", 0)
		var turns: int = highlights.get("turns", 0)
		var gold: String = "#FFD700"
		var dim: String = "#4A4A55"
		var lines: String = "[color=%s]" % dim
		lines += "  Best word: [color=%s]%s [%d][/color]\n" % [gold, best_w.to_upper(), best_i]
		lines += "  Peak mult: [color=%s]x%.1f[/color]\n" % [gold, peak_m]
		lines += "  Total dmg: [color=%s]%d[/color]  " % [gold, total_d]
		lines += "Turns: [color=%s]%d[/color]" % [gold, turns]
		lines += "[/color]"
		hl.text = lines
		main_vbox.add_child(hl)

	# Semant earned: 3 + floor/2 base, range +3 (random)
	var semant_earned: int = _reward_data.get("semant", -1) as int
	if semant_earned < 0:
		var floor_num: int = GameManager.run.get_equivalent_floor() if GameManager.run != null else 1
		var base_semant: int = SEMANT_REWARD_BASE + floor_num / 2
		var bonus: int = randi() % 4  # 0-3 range
		semant_earned = base_semant + bonus
	if semant_earned > 0 and GameManager.run != null:
		GameManager.run.add_semant(semant_earned)
		var semant_label := Label.new()
		semant_label.text = "+%d semant" % semant_earned
		semant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeManager.apply_mono_font(semant_label, ThemeManager.FONT_BODY)
		ThemeManager.apply_glow_text(semant_label, ACCENT_COLOR)
		main_vbox.add_child(semant_label)

	_reward_list = VBoxContainer.new()
	_reward_list.add_theme_constant_override("separation", 8)
	main_vbox.add_child(_reward_list)

	_morpheme_row = _make_reward_row("ADD MORPHEME", "Choose a morpheme for your deck", MORPH_COLOR, "morpheme")
	_reward_list.add_child(_morpheme_row)

	var enemy_tier: String = _reward_data.get("enemy_tier", "synapse") as String
	if enemy_tier == "lesion" or enemy_tier == "boss":
		_grapheme_row = _make_reward_row("ADD GRAPHEME", "Choose a passive relic", GRAPHEME_COLOR, "grapheme")
		_reward_list.add_child(_grapheme_row)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(spacer)

	var proceed_btn := Button.new()
	proceed_btn.text = "[ PROCEED ]"
	proceed_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ThemeManager.apply_mono_font(proceed_btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(proceed_btn, ACCENT_COLOR)
	proceed_btn.pressed.connect(_on_proceed)
	main_vbox.add_child(proceed_btn)


func _make_reward_row(title: String, desc: String, accent: Color, reward_type: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 60)
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeManager.COLOR_PANEL.lightened(0.03)
	style.border_color = accent.darkened(0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	var title_label := Label.new()
	title_label.text = title
	ThemeManager.apply_mono_font(title_label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(title_label, accent)
	hbox.add_child(title_label)

	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ThemeManager.apply_mono_font(desc_label, ThemeManager.FONT_MICRO)
	desc_label.add_theme_color_override("font_color", DIM_COLOR)
	hbox.add_child(desc_label)

	var click_btn := Button.new()
	click_btn.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var clear := StyleBoxFlat.new()
	clear.bg_color = Color.TRANSPARENT
	click_btn.add_theme_stylebox_override("normal", clear)
	var hover := StyleBoxFlat.new()
	hover.bg_color = accent.darkened(0.85)
	click_btn.add_theme_stylebox_override("hover", hover)
	click_btn.add_theme_color_override("font_color", Color.TRANSPARENT)
	click_btn.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	click_btn.pressed.connect(_on_row_clicked.bind(reward_type, panel, accent))
	panel.add_child(click_btn)
	return panel


func _on_row_clicked(reward_type: String, _panel: PanelContainer, _accent: Color) -> void:
	if _claimed.has(reward_type):
		return
	match reward_type:
		"morpheme":
			_show_morpheme_choices()
		"grapheme":
			_claimed["grapheme"] = true
			if _grapheme_row != null:
				_mark_row_claimed(_grapheme_row, GRAPHEME_COLOR, "CLAIMED")


func _show_morpheme_choices() -> void:
	if _morpheme_sub_panel != null:
		_morpheme_sub_panel.queue_free()
		_morpheme_sub_panel = null
		return
	if _morpheme_choices.is_empty():
		_morpheme_choices = _generate_morpheme_choices(3)

	_morpheme_sub_panel = VBoxContainer.new()
	_morpheme_sub_panel.add_theme_constant_override("separation", 6)
	var choice_row := HBoxContainer.new()
	choice_row.add_theme_constant_override("separation", 12)
	choice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_morpheme_sub_panel.add_child(choice_row)

	for i: int in _morpheme_choices.size():
		var card := _make_morpheme_card(_morpheme_choices[i], i)
		choice_row.add_child(card)

	var skip := Button.new()
	skip.text = "[ SKIP ]"
	skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ThemeManager.apply_mono_font(skip, ThemeManager.FONT_MICRO)
	ThemeManager.apply_button_style(skip, DIM_COLOR)
	skip.pressed.connect(_on_skip_morpheme)
	_morpheme_sub_panel.add_child(skip)

	var idx: int = _morpheme_row.get_index() + 1
	_reward_list.add_child(_morpheme_sub_panel)
	_reward_list.move_child(_morpheme_sub_panel, idx)


func _make_morpheme_card(m: MorphemeData, idx: int) -> PanelContainer:
	var pos_color: Color = _get_pos_color(m.pos_type)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 120)
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeManager.COLOR_PANEL.lightened(0.03)
	style.border_color = pos_color.darkened(0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var root_label := Label.new()
	root_label.text = m.root_text.to_upper()
	root_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(root_label, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(root_label, pos_color)
	vbox.add_child(root_label)

	var info_label := Label.new()
	info_label.text = "%s  %s" % [Enums.POSType.keys()[m.pos_type], Enums.MorphemeFamily.keys()[m.family]]
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(info_label, ThemeManager.FONT_MICRO)
	info_label.add_theme_color_override("font_color", DIM_COLOR)
	vbox.add_child(info_label)

	var ind_label := Label.new()
	ind_label.text = "[%d]" % m.base_induction
	ind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(ind_label, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(ind_label, ThemeManager.COLOR_WARNING)
	vbox.add_child(ind_label)

	var click_btn := Button.new()
	click_btn.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var clear := StyleBoxFlat.new()
	clear.bg_color = Color.TRANSPARENT
	click_btn.add_theme_stylebox_override("normal", clear)
	var hover := StyleBoxFlat.new()
	hover.bg_color = pos_color.darkened(0.85)
	click_btn.add_theme_stylebox_override("hover", hover)
	click_btn.add_theme_color_override("font_color", Color.TRANSPARENT)
	click_btn.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	click_btn.pressed.connect(_on_morpheme_chosen.bind(idx))
	card.add_child(click_btn)
	return card


func _on_morpheme_chosen(idx: int) -> void:
	if _claimed.has("morpheme"):
		return
	_claimed["morpheme"] = true
	if GameManager.run != null and idx < _morpheme_choices.size():
		GameManager.run.add_to_deck(_morpheme_choices[idx])
	_mark_row_claimed(_morpheme_row, MORPH_COLOR, "CLAIMED")
	if _morpheme_sub_panel != null:
		_morpheme_sub_panel.queue_free()
		_morpheme_sub_panel = null


func _on_skip_morpheme() -> void:
	_claimed["morpheme"] = true
	_mark_row_claimed(_morpheme_row, DIM_COLOR, "SKIPPED")
	if _morpheme_sub_panel != null:
		_morpheme_sub_panel.queue_free()
		_morpheme_sub_panel = null


func _mark_row_claimed(panel: PanelContainer, accent: Color, status_text: String) -> void:
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style != null:
		style.bg_color = accent.darkened(0.85)
		style.border_color = accent.darkened(0.3)
		panel.add_theme_stylebox_override("panel", style)
	for child: Node in panel.get_children():
		if child is HBoxContainer:
			var status := Label.new()
			status.text = "[%s]" % status_text
			ThemeManager.apply_mono_font(status, ThemeManager.FONT_MICRO)
			ThemeManager.apply_glow_text(status, accent)
			child.add_child(status)
			break
	for child: Node in panel.get_children():
		if child is Button:
			child.queue_free()


func _on_proceed() -> void:
	if _is_boss_victory:
		# Boss defeated: advance to next region instead of returning to map
		GameManager.advance_region()
		return
	var data: Dictionary = {}
	if _map != null:
		data["map"] = _map
	finished.emit(SCENE_MAP, data)


func _generate_morpheme_choices(count: int) -> Array[MorphemeData]:
	var result: Array[MorphemeData] = []
	var dir_path: String = "res://data/morphemes/"
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	var pool: Array[MorphemeData] = []
	while file_name != "":
		if file_name.ends_with(".tres"):
			var morph: MorphemeData = load(dir_path + file_name) as MorphemeData
			if morph != null:
				pool.append(morph)
		file_name = dir.get_next()
	dir.list_dir_end()
	pool.shuffle()
	for i: int in mini(count, pool.size()):
		result.append(pool[i])
	return result


func _get_pos_color(pos: Enums.POSType) -> Color:
	match pos:
		Enums.POSType.NOUN:
			return ThemeManager.COLOR_SHIELD
		Enums.POSType.VERB:
			return ThemeManager.COLOR_ALERT
		Enums.POSType.ADJECTIVE:
			return ThemeManager.COLOR_WARNING
		Enums.POSType.ADVERB:
			return ThemeManager.COLOR_INSULATION
		_:
			return DIM_COLOR
