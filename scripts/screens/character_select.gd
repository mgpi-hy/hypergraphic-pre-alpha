class_name CharacterSelectScreen
extends ScreenState

## Character selection screen. Displays all 5 characters with lock/unlock state,
## passive abilities, starter stats, and ASCII art. Terminal aesthetic.
## Hover to inspect, click to select and start a run.

# --- Constants ---
const SCENE_MAP: String = "res://scenes/screens/map_screen.tscn"
const CHARACTER_DIR: String = "res://data/characters/"

const FLAVOR_QUOTES: Dictionary = {
	"english": "\"All tongues are mine.\"",
	"french": "\"L'absence est tout.\"",
	"old_english": "\"By whale-road and bone-house.\"",
	"latin": "\"Decline, and be stronger.\"",
	"greek": "\"One root is never enough.\"",
}

const FAMILY_LABELS: Dictionary = {
	Enums.MorphemeFamily.GERMANIC: "GERMANIC",
	Enums.MorphemeFamily.LATINATE: "LATINATE",
	Enums.MorphemeFamily.GREEK: "GREEK",
	Enums.MorphemeFamily.FUNCTIONAL: "ALL FAMILIES",
}

# --- Private Variables ---
var _characters: Array[CharacterData] = []
var _panels: Array[PanelContainer] = []
var _selected_index: int = -1
var _hovered_index: int = -1
var _preview_panel: PanelContainer = null
var _preview_content: VBoxContainer = null


# --- Virtual Methods ---

func enter(previous: String, data: Dictionary = {}) -> void:
	super.enter(previous, data)
	_load_characters()
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back()
		get_viewport().set_input_as_handled()


# --- Private Methods ---

func _load_characters() -> void:
	var dir := DirAccess.open(CHARACTER_DIR)
	if not dir:
		push_warning("No character directory found at %s" % CHARACTER_DIR)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path: String = CHARACTER_DIR + file_name
			var data: CharacterData = load(path) as CharacterData
			if data:
				_characters.append(data)
		file_name = dir.get_next()
	dir.list_dir_end()
	# Sort by id for consistent ordering
	_characters.sort_custom(func(a: CharacterData, b: CharacterData) -> bool:
		return a.id < b.id
	)


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Background
	var bg := ColorRect.new()
	bg.color = ThemeManager.COLOR_VOID
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Neural grid background
	ThemeManager.build_unicode_grid(self, "broca's area", 4, 0.02)

	# Main vertical layout
	var outer := VBoxContainer.new()
	outer.anchor_left = 0.02
	outer.anchor_right = 0.98
	outer.anchor_top = 0.03
	outer.anchor_bottom = 0.97
	outer.offset_left = 0
	outer.offset_right = 0
	outer.offset_top = 0
	outer.offset_bottom = 0
	outer.add_theme_constant_override("separation", 16)
	add_child(outer)

	# Header
	var header := Label.new()
	header.text = "\u2550\u2550\u2550 SELECT OPERATOR \u2550\u2550\u2550"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(header, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(header, ThemeManager.COLOR_SUCCESS)
	outer.add_child(header)

	# Main content: left panels + right preview
	var main_hbox := HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 16)
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(main_hbox)

	# Character panel row in a scroll container
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_hbox.add_child(scroll)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)

	for i: int in range(_characters.size()):
		var panel: PanelContainer = _build_character_panel(_characters[i], i)
		row.add_child(panel)
		_panels.append(panel)

	# Right side: preview panel (hidden by default, shown on hover)
	_preview_panel = PanelContainer.new()
	_preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_panel.size_flags_stretch_ratio = 1.5
	_preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_panel.custom_minimum_size = Vector2(260, 0)
	_preview_panel.visible = false
	ThemeManager.apply_panel_style(
		_preview_panel, ThemeManager.COLOR_PANEL, ThemeManager.COLOR_TEXT_DIM
	)
	main_hbox.add_child(_preview_panel)

	_preview_content = VBoxContainer.new()
	_preview_content.add_theme_constant_override("separation", 10)
	_preview_panel.add_child(_preview_content)

	_show_preview_empty()

	# Bottom row: back button
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(bottom)

	var back_btn := Button.new()
	back_btn.text = "[ BACK ]"
	back_btn.custom_minimum_size = Vector2(200, 44)
	ThemeManager.apply_mono_font(back_btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(back_btn, ThemeManager.COLOR_TEXT_DIM)
	back_btn.pressed.connect(_on_back)
	bottom.add_child(back_btn)


func _build_character_panel(character: CharacterData, index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var is_locked: bool = not GameManager.is_character_unlocked(character.id)

	# Panel style
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeManager.COLOR_PANEL
	style.border_color = character.color.darkened(0.4) if is_locked else character.color.darkened(0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)

	# Content
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	# ASCII art
	var art_label := Label.new()
	art_label.text = character.ascii_art
	art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(art_label, ThemeManager.FONT_MICRO)
	if is_locked:
		art_label.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	else:
		art_label.add_theme_color_override("font_color", character.color)
	content.add_child(art_label)

	# Separator
	_add_separator_to(content, character.color.darkened(0.3))

	# Name
	var name_label := Label.new()
	name_label.text = character.display_name.to_upper()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(name_label, ThemeManager.FONT_H1)
	if is_locked:
		name_label.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	else:
		ThemeManager.apply_glow_text(name_label, character.color)
	content.add_child(name_label)

	# Language
	var lang_label := Label.new()
	lang_label.text = character.language
	lang_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(lang_label, ThemeManager.FONT_MICRO)
	lang_label.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	content.add_child(lang_label)

	# Lock overlay or passive name
	if is_locked:
		var lock_label := Label.new()
		lock_label.text = "[LOCKED]"
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeManager.apply_mono_font(lock_label, ThemeManager.FONT_BODY)
		lock_label.add_theme_color_override("font_color", ThemeManager.COLOR_ALERT)
		content.add_child(lock_label)

		var cond_label := Label.new()
		cond_label.text = character.unlock_description
		cond_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeManager.apply_mono_font(cond_label, ThemeManager.FONT_MICRO)
		cond_label.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
		content.add_child(cond_label)
	else:
		var passive_label := Label.new()
		passive_label.text = "[ %s ]" % character.passive_name
		passive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeManager.apply_mono_font(passive_label, ThemeManager.FONT_MICRO)
		passive_label.add_theme_color_override("font_color", character.color.darkened(0.15))
		content.add_child(passive_label)

	# Interactive
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_panel_input.bind(index))
	panel.mouse_entered.connect(_on_panel_hover.bind(index, true))
	panel.mouse_exited.connect(_on_panel_hover.bind(index, false))

	return panel


func _show_preview_empty() -> void:
	_clear_preview()
	var hint := Label.new()
	hint.text = "< HOVER TO INSPECT >"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ThemeManager.apply_mono_font(hint, ThemeManager.FONT_BODY)
	hint.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	_preview_content.add_child(hint)


func _show_preview_for(index: int) -> void:
	_clear_preview()
	var character: CharacterData = _characters[index]
	var is_locked: bool = not GameManager.is_character_unlocked(character.id)
	var text_color: Color = ThemeManager.COLOR_TEXT_DIM if is_locked else ThemeManager.COLOR_TEXT_MAIN
	var accent: Color = ThemeManager.COLOR_TEXT_DIM if is_locked else character.color

	# Update preview border
	ThemeManager.apply_panel_style(_preview_panel, ThemeManager.COLOR_PANEL, accent.darkened(0.2), 2)

	# Character name
	var name_label := Label.new()
	name_label.text = character.display_name.to_upper()
	ThemeManager.apply_mono_font(name_label, 24)
	if is_locked:
		name_label.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	else:
		ThemeManager.apply_glow_text(name_label, character.color)
	_preview_content.add_child(name_label)

	# Language
	var origin := Label.new()
	origin.text = character.language
	ThemeManager.apply_mono_font(origin, ThemeManager.FONT_H1)
	origin.add_theme_color_override("font_color", accent.darkened(0.1))
	_preview_content.add_child(origin)

	# Locked banner
	if is_locked:
		var lock_banner := Label.new()
		lock_banner.text = ">>> [LOCKED] <<<"
		ThemeManager.apply_mono_font(lock_banner, ThemeManager.FONT_H1)
		lock_banner.add_theme_color_override("font_color", ThemeManager.COLOR_ALERT)
		_preview_content.add_child(lock_banner)

		var cond := Label.new()
		cond.text = character.unlock_description
		ThemeManager.apply_mono_font(cond, ThemeManager.FONT_BODY)
		cond.add_theme_color_override("font_color", ThemeManager.COLOR_WARNING)
		_preview_content.add_child(cond)

	_add_separator_to(_preview_content, accent)

	# Passive ability
	var passive_header := Label.new()
	passive_header.text = "[ %s ]" % character.passive_name
	ThemeManager.apply_mono_font(passive_header, ThemeManager.FONT_H1)
	passive_header.add_theme_color_override("font_color", accent)
	_preview_content.add_child(passive_header)

	var passive_desc := Label.new()
	passive_desc.text = character.passive_description
	passive_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeManager.apply_mono_font(passive_desc, ThemeManager.FONT_BODY)
	passive_desc.add_theme_color_override("font_color", text_color)
	_preview_content.add_child(passive_desc)

	# Stats
	var stats := Label.new()
	stats.text = "COG: %d    HAND: %d" % [character.starter_cogency, character.starter_hand_size]
	ThemeManager.apply_mono_font(stats, ThemeManager.FONT_BODY)
	stats.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	_preview_content.add_child(stats)

	_add_separator_to(_preview_content, accent)

	# Family
	var family_display: String = FAMILY_LABELS.get(character.primary_family, "UNKNOWN")
	if character.allowed_families.is_empty():
		family_display = "ALL FAMILIES"
	var family_label := Label.new()
	family_label.text = "DECK: %s" % family_display
	ThemeManager.apply_mono_font(family_label, ThemeManager.FONT_BODY)
	family_label.add_theme_color_override("font_color", text_color)
	_preview_content.add_child(family_label)

	# Flavor quote
	var quote_text: String = FLAVOR_QUOTES.get(character.id, "")
	if quote_text != "":
		var quote := Label.new()
		quote.text = quote_text
		quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ThemeManager.apply_mono_font(quote, ThemeManager.FONT_MICRO)
		quote.add_theme_color_override("font_color", accent.darkened(0.2))
		_preview_content.add_child(quote)

	_add_separator_to(_preview_content, accent)

	# Start run button (only for unlocked characters)
	if not is_locked:
		var start_btn := Button.new()
		start_btn.text = "[ START RUN ]"
		start_btn.custom_minimum_size = Vector2(200, 40)
		start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ThemeManager.apply_mono_font(start_btn, ThemeManager.FONT_BODY)
		ThemeManager.apply_button_style(start_btn, character.color)
		start_btn.pressed.connect(_on_start_run.bind(index))
		_preview_content.add_child(start_btn)


func _clear_preview() -> void:
	for child: Node in _preview_content.get_children():
		child.queue_free()


func _add_separator_to(parent: VBoxContainer, color: Color) -> void:
	var sep := Label.new()
	sep.text = "\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
	ThemeManager.apply_mono_font(sep, ThemeManager.FONT_MICRO)
	sep.add_theme_color_override("font_color", color.darkened(0.5))
	parent.add_child(sep)


func _on_panel_hover(index: int, entered: bool) -> void:
	var character: CharacterData = _characters[index]
	var panel: PanelContainer = _panels[index]
	var is_locked: bool = not GameManager.is_character_unlocked(character.id)

	var style := StyleBoxFlat.new()
	style.bg_color = ThemeManager.COLOR_PANEL
	style.set_corner_radius_all(0)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0

	if entered and not is_locked:
		style.border_color = character.color
		style.set_border_width_all(3)
		style.bg_color = ThemeManager.COLOR_PANEL.lightened(0.03)
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	elif entered and is_locked:
		style.border_color = ThemeManager.COLOR_ALERT.darkened(0.3)
		style.set_border_width_all(2)
		panel.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	else:
		style.border_color = character.color.darkened(0.4) if is_locked else character.color.darkened(0.2)
		style.set_border_width_all(2)
		panel.mouse_default_cursor_shape = Control.CURSOR_ARROW

	panel.add_theme_stylebox_override("panel", style)

	if entered:
		_hovered_index = index
		_show_preview_for(index)
	else:
		_hovered_index = -1
		_show_preview_empty()


func _on_panel_input(event: InputEvent, index: int) -> void:
	if event is not InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return

	var character: CharacterData = _characters[index]
	if not GameManager.is_character_unlocked(character.id):
		_show_locked_feedback(index)
		return

	_on_start_run(index)


func _on_start_run(index: int) -> void:
	var character: CharacterData = _characters[index]
	GameManager.start_run(character)


func _show_locked_feedback(index: int) -> void:
	var panel: PanelContainer = _panels[index]
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeManager.COLOR_PANEL
	style.border_color = ThemeManager.COLOR_ALERT
	style.set_border_width_all(3)
	style.set_corner_radius_all(0)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)

	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(func() -> void:
		var revert := style.duplicate() as StyleBoxFlat
		revert.border_color = ThemeManager.COLOR_ALERT.darkened(0.5)
		revert.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", revert)
	)


func _on_back() -> void:
	finished.emit("res://scenes/screens/title_screen.tscn", {})
