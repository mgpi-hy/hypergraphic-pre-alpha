class_name SettingsScreen
extends ScreenState

## Settings menu accessible from title screen or in-game pause.
## Adjusts audio, display, and accessibility. Persists via SaveManager.

# --- Private Variables ---

var _master_slider: HSlider = null
var _sfx_slider: HSlider = null
var _music_slider: HSlider = null
var _fullscreen_toggle: CheckButton = null
var _high_contrast_toggle: CheckButton = null
var _shake_toggle: CheckButton = null
var _content: VBoxContainer = null
var _previous_screen: String = ""


# --- Virtual Methods ---

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


# --- Public Methods ---

func enter(previous: String, data: Dictionary = {}) -> void:
	super.enter(previous, data)
	_previous_screen = data.get("return_to", previous)
	_build_ui()
	_load_current_values()


# --- Private Methods: UI Construction ---

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Dark overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.02, 0.03, 0.92)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)

	ThemeManager.build_unicode_grid(self, "limbic system", 4, 0.015)

	# Scroll container
	var scroll := ScrollContainer.new()
	scroll.anchor_left = 0.5
	scroll.anchor_right = 0.5
	scroll.anchor_top = 0.05
	scroll.anchor_bottom = 0.95
	scroll.offset_left = -320
	scroll.offset_right = 320
	add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 16)
	scroll.add_child(_content)

	# Header
	var header := Label.new()
	header.text = "\u2550\u2550\u2550 SETTINGS \u2550\u2550\u2550"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(header, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(header, ThemeManager.COLOR_SUCCESS)
	_content.add_child(header)

	_add_separator()

	# Audio
	_add_section_label("AUDIO")
	_master_slider = _add_slider("Master Volume")
	_sfx_slider = _add_slider("SFX Volume")
	_music_slider = _add_slider("Music Volume")

	_master_slider.value_changed.connect(_on_master_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_music_slider.value_changed.connect(_on_music_changed)

	_add_separator()

	# Display
	_add_section_label("DISPLAY")
	_fullscreen_toggle = _add_toggle("Fullscreen")
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)

	_add_separator()

	# Accessibility
	_add_section_label("ACCESSIBILITY")
	_high_contrast_toggle = _add_toggle("High Contrast")
	_shake_toggle = _add_toggle("Screen Shake")

	_high_contrast_toggle.toggled.connect(_on_high_contrast_toggled)
	_shake_toggle.toggled.connect(_on_shake_toggled)

	_add_separator()

	# Back button
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_child(btn_row)

	var back_btn := Button.new()
	back_btn.text = "[ BACK ]"
	back_btn.custom_minimum_size = Vector2(200, 40)
	ThemeManager.apply_mono_font(back_btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(back_btn, ThemeManager.COLOR_SUCCESS)
	back_btn.pressed.connect(_on_back_pressed)
	btn_row.add_child(back_btn)


func _load_current_values() -> void:
	var s: SettingsData = GameManager.settings
	_master_slider.value = s.master_volume
	_sfx_slider.value = s.sfx_volume
	_music_slider.value = s.music_volume
	_fullscreen_toggle.button_pressed = s.is_fullscreen
	_high_contrast_toggle.button_pressed = s.is_high_contrast
	_shake_toggle.button_pressed = s.is_screen_shake_enabled


func _add_section_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	ThemeManager.apply_mono_font(label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(label, ThemeManager.COLOR_TEXT_MAIN)
	_content.add_child(label)


func _add_separator() -> void:
	var sep := Label.new()
	sep.text = "\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
	ThemeManager.apply_mono_font(sep, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(sep, ThemeManager.COLOR_TEXT_DIM)
	_content.add_child(sep)


func _add_slider(label_text: String) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_content.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(200, 0)
	ThemeManager.apply_mono_font(label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(label, ThemeManager.COLOR_TEXT_DIM)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(300, 24)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var track_style := StyleBoxFlat.new()
	track_style.bg_color = ThemeManager.COLOR_PANEL
	track_style.border_color = ThemeManager.COLOR_TEXT_DIM
	track_style.set_border_width_all(1)
	track_style.set_corner_radius_all(0)
	track_style.content_margin_top = 4
	track_style.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", track_style)

	var grabber_style := StyleBoxFlat.new()
	grabber_style.bg_color = ThemeManager.COLOR_SUCCESS
	grabber_style.set_corner_radius_all(0)
	slider.add_theme_stylebox_override("grabber_area", grabber_style)
	slider.add_theme_stylebox_override("grabber_area_highlight", grabber_style)

	row.add_child(slider)

	var val_label := Label.new()
	val_label.text = "100%"
	val_label.custom_minimum_size = Vector2(50, 0)
	ThemeManager.apply_mono_font(val_label, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(val_label, ThemeManager.COLOR_TEXT_MAIN)
	row.add_child(val_label)

	slider.value_changed.connect(func(val: float) -> void:
		val_label.text = "%d%%" % int(val * 100)
	)

	return slider


func _add_toggle(label_text: String) -> CheckButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_content.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(200, 0)
	ThemeManager.apply_mono_font(label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(label, ThemeManager.COLOR_TEXT_DIM)
	row.add_child(label)

	var toggle := CheckButton.new()
	ThemeManager.apply_mono_font(toggle, ThemeManager.FONT_BODY)
	toggle.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_MAIN)
	row.add_child(toggle)

	return toggle


# --- Private Methods: Signal Handlers ---

func _on_master_changed(value: float) -> void:
	GameManager.settings.master_volume = value
	if AudioServer.bus_count > 0:
		AudioServer.set_bus_volume_db(0, linear_to_db(value))
	SaveManager.save_meta()


func _on_sfx_changed(value: float) -> void:
	GameManager.settings.sfx_volume = value
	if AudioServer.bus_count > 1:
		AudioServer.set_bus_volume_db(1, linear_to_db(value))
	SaveManager.save_meta()


func _on_music_changed(value: float) -> void:
	GameManager.settings.music_volume = value
	if AudioServer.bus_count > 2:
		AudioServer.set_bus_volume_db(2, linear_to_db(value))
	SaveManager.save_meta()


func _on_fullscreen_toggled(pressed: bool) -> void:
	GameManager.settings.is_fullscreen = pressed
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	SaveManager.save_meta()


func _on_high_contrast_toggled(pressed: bool) -> void:
	GameManager.settings.is_high_contrast = pressed
	ThemeManager.set_high_contrast(pressed)
	SaveManager.save_meta()


func _on_shake_toggled(pressed: bool) -> void:
	GameManager.settings.is_screen_shake_enabled = pressed
	SaveManager.save_meta()


func _on_back_pressed() -> void:
	finished.emit(_previous_screen, {})
