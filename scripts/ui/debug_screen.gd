class_name DebugScreen
extends Control

## Debug overlay toggled with F12 or backtick.
## Shows run state and provides cheat buttons.
## Only visible in debug builds (OS.is_debug_build()).

# --- Constants ---

const COLOR_ACCENT := Color("#FF6B6B")
const COLOR_DEBUG_SUCCESS := Color("#00F090")
const COLOR_DEBUG_GOLD := Color("#FFD54F")

# --- Private Variables ---

var _stats_label: Label = null
var _content: VBoxContainer = null
var _is_open: bool = false


# --- Virtual Methods ---

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	_build_ui()
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed:
		return
	if event.keycode == KEY_F12 or event.keycode == KEY_QUOTELEFT:
		_toggle()
		get_viewport().set_input_as_handled()


# --- Private Methods: UI ---

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Semi-transparent overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.02, 0.03, 0.85)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	margin.add_child(_content)

	# Header
	var header := Label.new()
	header.text = "\u2550\u2550\u2550 DEBUG \u2550\u2550\u2550"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(header, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(header, COLOR_ACCENT)
	_content.add_child(header)

	# Stats display
	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeManager.apply_mono_font(_stats_label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(_stats_label, ThemeManager.COLOR_TEXT_MAIN)
	_content.add_child(_stats_label)

	# Separator
	var sep := Label.new()
	sep.text = "\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(sep, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(sep, ThemeManager.COLOR_TEXT_DIM)
	_content.add_child(sep)

	# Cheat buttons
	var btn_grid := GridContainer.new()
	btn_grid.columns = 3
	btn_grid.add_theme_constant_override("h_separation", 12)
	btn_grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(btn_grid)

	_add_debug_btn(btn_grid, "Give 100 Semant", COLOR_DEBUG_GOLD, _on_give_semant)
	_add_debug_btn(btn_grid, "Heal Full", COLOR_DEBUG_SUCCESS, _on_heal_full)
	_add_debug_btn(btn_grid, "Skip to Boss", COLOR_ACCENT, _on_skip_to_boss)
	_add_debug_btn(btn_grid, "Win Combat", COLOR_DEBUG_SUCCESS, _on_win_combat)
	_add_debug_btn(btn_grid, "Unlock All Chars", COLOR_DEBUG_GOLD, _on_unlock_all_characters)
	_add_debug_btn(btn_grid, "Give 500 Pragmant", COLOR_DEBUG_GOLD, _on_give_pragmant)

	# Close hint
	var hint := Label.new()
	hint.text = "F12 / ` to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(hint, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(hint, ThemeManager.COLOR_TEXT_DIM)
	_content.add_child(hint)


func _add_debug_btn(
	parent: Control,
	text: String,
	color: Color,
	callback: Callable,
) -> void:
	var btn := Button.new()
	btn.text = "[ %s ]" % text
	btn.custom_minimum_size = Vector2(200, 36)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ThemeManager.apply_mono_font(btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(btn, color)
	btn.pressed.connect(callback)
	parent.add_child(btn)


# --- Private Methods: Toggle ---

func _toggle() -> void:
	_is_open = not _is_open
	visible = _is_open
	if _is_open:
		_update_stats()


func _update_stats() -> void:
	if _stats_label == null:
		return
	var run: RunData = GameManager.run
	if run == null:
		_stats_label.text = "No active run  |  Pragmant: %d" % GameManager.meta_pragmant
		return

	var region_name: String = run.current_region_id if run.current_region_id != "" else "???"
	_stats_label.text = "Region: %s  |  Col: %d  |  COG: %d/%d  |  Semant: %d  |  Deck: %d" % [
		region_name,
		run.current_column,
		run.cogency,
		run.max_cogency,
		run.semant,
		run.deck.size(),
	]


# --- Private Methods: Cheat Callbacks ---

func _on_give_semant() -> void:
	if GameManager.run != null:
		GameManager.run.semant += 100
	_update_stats()


func _on_heal_full() -> void:
	if GameManager.run != null:
		GameManager.run.cogency = GameManager.run.max_cogency
	_update_stats()


func _on_skip_to_boss() -> void:
	if GameManager.run != null:
		GameManager.run.current_column = 15
	_update_stats()


func _on_win_combat() -> void:
	EventBus.combat_won.emit()


func _on_unlock_all_characters() -> void:
	for id: String in ["english", "latin", "greek", "germanic", "frankie"]:
		GameManager.unlock_character(id)
	SaveManager.save_meta()
	_update_stats()


func _on_give_pragmant() -> void:
	GameManager.meta_pragmant += 500
	SaveManager.save_meta()
	_update_stats()
