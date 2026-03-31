class_name EnemyPanel
extends PanelContainer

## Displays one enemy during combat. Name, cogency bar, intent icon,
## ASCII glitch art. No game logic; purely visual.

# --- Constants ---

const GLITCH_CHARS: Array[String] = [
	"#", "@", "%", "&", "!", "?", "*",
	"$", "~", "^", "+", "=", "|",
]

const INTENT_GLYPHS: Dictionary = {
	EnemyData.IntentType.ATTACK: "[ATK]",
	EnemyData.IntentType.DEFEND: "[DEF]",
	EnemyData.IntentType.BUFF: "[BUF]",
	EnemyData.IntentType.DRAIN: "[DRN]",
	EnemyData.IntentType.SCRAMBLE: "[SCR]",
	EnemyData.IntentType.SILENCE: "[SIL]",
	EnemyData.IntentType.LOCK: "[LCK]",
}

const INTENT_COLORS: Dictionary = {
	EnemyData.IntentType.ATTACK: Color("#FFB300"),
	EnemyData.IntentType.DEFEND: Color("#CE93D8"),
	EnemyData.IntentType.BUFF: Color("#00F090"),
	EnemyData.IntentType.DRAIN: Color("#E040FB"),
	EnemyData.IntentType.SCRAMBLE: Color("#00E5FF"),
	EnemyData.IntentType.SILENCE: Color("#B388FF"),
	EnemyData.IntentType.LOCK: Color("#757575"),
}

# --- Exports ---

@export var enemy_data: EnemyData

# --- Private Variables ---

var _name_label: Label
var _cogency_bar: ProgressBar
var _cogency_text: Label
var _intent_label: Label
var _glitch_label: Label
var _max_cogency: int = 1
var _glitch_timer: float = 0.0


# --- Virtual Methods ---

func _ready() -> void:
	_build_display()
	if enemy_data:
		_max_cogency = enemy_data.cogency
		_name_label.text = enemy_data.display_name
		_cogency_bar.max_value = _max_cogency
		_cogency_bar.value = _max_cogency
		_cogency_text.text = "%d/%d" % [_max_cogency, _max_cogency]
		_generate_glitch_art()
		_apply_enemy_color()


func _process(delta: float) -> void:
	if not enemy_data:
		return
	_glitch_timer += delta
	if _glitch_timer >= 0.15:
		_glitch_timer = 0.0
		_generate_glitch_art()


# --- Public Methods ---

## Update the panel with current cogency and intent.
func update_display(cogency: int, max_cogency: int, intent: Dictionary) -> void:
	_max_cogency = max_cogency
	_cogency_bar.max_value = max_cogency
	_cogency_bar.value = cogency
	_cogency_text.text = "%d/%d" % [cogency, max_cogency]
	update_intent(intent)


## Update the intent display with color-coded type and value.
func update_intent(intent: Dictionary) -> void:
	var intent_type: int = intent.get("type", EnemyData.IntentType.ATTACK)
	var intent_value: int = intent.get("value", 0)
	var glyph: String = INTENT_GLYPHS.get(intent_type, "[???]")
	var color: Color = INTENT_COLORS.get(intent_type, ThemeManager.COLOR_WARNING)
	_intent_label.text = "%s %d" % [glyph, intent_value]
	ThemeManager.apply_glow_text(_intent_label, color)


## Flash red and shake on damage.
func play_damage_animation(amount: int) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.3, 0.3), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

	# Shake
	var original_pos: Vector2 = position
	var intensity: float = clampf(float(amount) * 0.5, 2.0, 8.0)
	for i: int in range(3):
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity),
		)
		tween.tween_property(self, "position", original_pos + offset, 0.03)
	tween.tween_property(self, "position", original_pos, 0.03)


## Shatter the panel on defeat: glitch corrupts, scale pop, flash, dissolve.
func play_defeat_animation() -> void:
	# Override glitch density to full corruption
	if enemy_data:
		enemy_data.glitch_density = 1.0
	_generate_glitch_art()
	SFX.play_impact(self)

	var tween := create_tween()
	# Scale up slightly (pressure before break)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUAD)
	# White flash
	tween.tween_property(self, "modulate", Color(3.0, 3.0, 3.0), 0.05)
	# Shatter: shrink + fade simultaneously
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_QUAD)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


# --- Private Methods ---

func _build_display() -> void:
	custom_minimum_size = Vector2(200.0, 80.0)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	add_child(hbox)

	# Left side: glitch art
	_glitch_label = Label.new()
	_glitch_label.custom_minimum_size = Vector2(50.0, 0.0)
	ThemeManager.apply_mono_font(_glitch_label, ThemeManager.FONT_MICRO)
	hbox.add_child(_glitch_label)

	# Right side: info
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	_name_label = Label.new()
	_name_label.text = "UNKNOWN"
	ThemeManager.apply_mono_font(_name_label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(_name_label, ThemeManager.COLOR_ALERT)
	info_vbox.add_child(_name_label)

	_cogency_bar = ProgressBar.new()
	_cogency_bar.custom_minimum_size = Vector2(0.0, 8.0)
	_cogency_bar.show_percentage = false
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = ThemeManager.COLOR_ALERT
	fill_style.set_corner_radius_all(0)
	_cogency_bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = ThemeManager.COLOR_PANEL
	bg_style.set_corner_radius_all(0)
	bg_style.set_border_width_all(1)
	bg_style.border_color = ThemeManager.COLOR_TEXT_DIM
	_cogency_bar.add_theme_stylebox_override("background", bg_style)
	info_vbox.add_child(_cogency_bar)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 8)
	info_vbox.add_child(stats_row)

	_cogency_text = Label.new()
	_cogency_text.text = "0/0"
	ThemeManager.apply_mono_font(_cogency_text, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(_cogency_text, ThemeManager.get_text_main())
	stats_row.add_child(_cogency_text)

	_intent_label = Label.new()
	_intent_label.text = "[ATK] 0"
	ThemeManager.apply_mono_font(_intent_label, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(_intent_label, ThemeManager.COLOR_WARNING)
	stats_row.add_child(_intent_label)


func _generate_glitch_art() -> void:
	if not enemy_data:
		return
	var density: float = enemy_data.glitch_density
	var lines: String = ""
	for row: int in range(4):
		for col: int in range(6):
			if randf() < density:
				lines += GLITCH_CHARS[randi() % GLITCH_CHARS.size()]
			else:
				lines += " "
		if row < 3:
			lines += "\n"
	_glitch_label.text = lines


func _apply_enemy_color() -> void:
	if not enemy_data:
		return
	ThemeManager.apply_panel_style(
		self, ThemeManager.COLOR_PANEL,
		enemy_data.color, ThemeManager.get_border_width(),
	)
	ThemeManager.apply_glow_text(_name_label, enemy_data.color)
	ThemeManager.apply_glow_text(_glitch_label, enemy_data.color.darkened(0.3))
