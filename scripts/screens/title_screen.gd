extends ScreenState

## Title screen. Terminal aesthetic, box-drawing borders, monospace everything.

# --- Constants ---
const TITLE_TEXT: String = "HYPERGRAPHIC"
const SUBTITLE_TEXT: String = "a linguistics roguelite deckbuilder"
const TITLE_FONT_SIZE: int = 48
const SUBTITLE_FONT_SIZE: int = 16
const BUTTON_FONT_SIZE: int = 16
const BUTTON_MIN_WIDTH: float = 220.0

const BORDER_TOP: String = "╔══════════════════════════════════════╗"
const BORDER_BOT: String = "╚══════════════════════════════════════╝"
const BORDER_MID: String = "╠══════════════════════════════════════╣"

# --- Private Variables ---
var _start_button: Button = null
var _settings_button: Button = null
var _quit_button: Button = null


# --- Virtual Methods ---

func _ready() -> void:
	_build_ui()


# --- Private Methods ---

func _build_ui() -> void:
	# Full-screen void background
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_rect := ColorRect.new()
	bg_rect.color = ThemeManager.COLOR_VOID
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)

	# Root container: center everything vertically and horizontally
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 0)
	center.add_child(vbox)

	# Top border
	_add_border_label(vbox, BORDER_TOP)
	_add_spacer(vbox, 16.0)

	# Title
	var title := Label.new()
	title.text = TITLE_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(title, TITLE_FONT_SIZE)
	ThemeManager.apply_glow_text(title, ThemeManager.COLOR_SUCCESS)
	vbox.add_child(title)

	_add_spacer(vbox, 8.0)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = SUBTITLE_TEXT
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(subtitle, SUBTITLE_FONT_SIZE)
	subtitle.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	vbox.add_child(subtitle)

	_add_spacer(vbox, 8.0)

	# Mid border
	_add_border_label(vbox, BORDER_MID)
	_add_spacer(vbox, 24.0)

	# Button container
	var btn_box := VBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_box)

	# START
	_start_button = _make_button("[ START ]", ThemeManager.COLOR_SUCCESS)
	_start_button.pressed.connect(_on_start_pressed)
	btn_box.add_child(_start_button)

	# SETTINGS (disabled)
	_settings_button = _make_button("[ SETTINGS ]", ThemeManager.COLOR_TEXT_DIM)
	_settings_button.disabled = true
	btn_box.add_child(_settings_button)

	# QUIT
	_quit_button = _make_button("[ QUIT ]", ThemeManager.COLOR_ALERT)
	_quit_button.pressed.connect(_on_quit_pressed)
	btn_box.add_child(_quit_button)

	_add_spacer(vbox, 24.0)

	# Bottom border
	_add_border_label(vbox, BORDER_BOT)

	_add_spacer(vbox, 16.0)

	# Version / cursor blink line
	var version := Label.new()
	version.text = "> v0.1.0_"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(version, ThemeManager.FONT_MICRO)
	version.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	vbox.add_child(version)


func _add_border_label(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(label, ThemeManager.FONT_BODY)
	label.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	parent.add_child(label)


func _add_spacer(parent: VBoxContainer, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	parent.add_child(spacer)


func _make_button(text: String, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(BUTTON_MIN_WIDTH, 0.0)
	ThemeManager.apply_mono_font(btn, BUTTON_FONT_SIZE)
	ThemeManager.apply_button_style(btn, accent)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return btn


func _on_start_pressed() -> void:
	finished.emit("res://scenes/screens/character_select.tscn", {})


func _on_quit_pressed() -> void:
	get_tree().quit()
