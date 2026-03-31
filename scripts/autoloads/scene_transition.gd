extends CanvasLayer

## Terminal-style scanline wipe transition effect.
## Fills the screen with sparse glitch characters during scene changes.

# --- Constants ---
const FADE_DURATION: float = 0.3
const GLITCH_HOLD: float = 0.08

const GLITCH_CHARS: PackedStringArray = [
	"█", "▓", "▒", "░", "▄", "▀", "▐", "▌",
	"╔", "╗", "╚", "╝", "═", "║", "┃", "┳",
	"0", "1", "x", "F", "A", "E", "C", "D",
	"$", "@", "#", "%", "&", "!", "?", ">",
]

const GLITCH_COLORS: PackedStringArray = [
	"00F090", "00D0FF", "FFB300", "FF1E40",
	"4A4A55", "1A1A20", "00F090", "00F090",
]

const GLITCH_DENSITY: float = 0.3
const GLITCH_CHAR_WIDTH: float = 8.0
const GLITCH_CHAR_HEIGHT: float = 14.0

# --- Private Variables ---
var _overlay: ColorRect = null
var _glitch_label: RichTextLabel = null
var _is_transitioning: bool = false
var _active_tween: Tween = null


# --- Virtual Methods ---

func _ready() -> void:
	layer = 100
	_build_overlay()


# --- Public Methods ---

func transition_to(scene_path: String) -> void:
	if _is_transitioning:
		push_warning("SceneTransition: ignoring duplicate transition to %s" % scene_path)
		return
	_is_transitioning = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# Fade out: current scene vanishes behind overlay
	_fill_glitch_text()
	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.tween_property(_overlay, "modulate:a", 1.0, FADE_DURATION)
	_active_tween.tween_property(_glitch_label, "modulate:a", 0.6, FADE_DURATION * 0.8)
	await _active_tween.finished

	# Brief hold with glitch visible
	await get_tree().create_timer(GLITCH_HOLD).timeout

	# Load new scene
	get_tree().change_scene_to_file(scene_path)

	# Wait for the new scene to initialize
	await get_tree().process_frame
	await get_tree().process_frame

	# Fade in: reveal new scene
	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.tween_property(_glitch_label, "modulate:a", 0.0, FADE_DURATION * 0.5)
	_active_tween.tween_property(_overlay, "modulate:a", 0.0, FADE_DURATION)
	await _active_tween.finished

	_active_tween = null
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glitch_label.clear()
	_is_transitioning = false


func transition_to_packed(scene: PackedScene) -> void:
	if _is_transitioning:
		push_warning("SceneTransition: already transitioning, forcing reset for packed scene")
		force_reset()
	_is_transitioning = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	_fill_glitch_text()
	var tween_out: Tween = create_tween()
	tween_out.set_parallel(true)
	tween_out.tween_property(_overlay, "modulate:a", 1.0, FADE_DURATION)
	tween_out.tween_property(_glitch_label, "modulate:a", 0.6, FADE_DURATION * 0.8)
	await tween_out.finished

	await get_tree().create_timer(GLITCH_HOLD).timeout

	get_tree().change_scene_to_packed(scene)

	await get_tree().process_frame
	await get_tree().process_frame

	var tween_in: Tween = create_tween()
	tween_in.set_parallel(true)
	tween_in.tween_property(_glitch_label, "modulate:a", 0.0, FADE_DURATION * 0.5)
	tween_in.tween_property(_overlay, "modulate:a", 0.0, FADE_DURATION)
	await tween_in.finished

	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glitch_label.clear()
	_is_transitioning = false


func force_reset() -> void:
	_is_transitioning = false
	_overlay.modulate.a = 0.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glitch_label.modulate.a = 0.0
	_glitch_label.clear()


# --- Private Methods ---

func _build_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.color = ThemeManager.COLOR_VOID
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.modulate.a = 0.0
	add_child(_overlay)

	_glitch_label = RichTextLabel.new()
	_glitch_label.bbcode_enabled = true
	_glitch_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glitch_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glitch_label.scroll_active = false
	_glitch_label.modulate.a = 0.0
	ThemeManager.apply_mono_font_rtl(_glitch_label, ThemeManager.FONT_MICRO)
	_glitch_label.add_theme_color_override(
		"default_color", ThemeManager.COLOR_SUCCESS
	)
	_overlay.add_child(_glitch_label)


func _fill_glitch_text() -> void:
	_glitch_label.clear()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var cols: int = int(viewport_size.x / GLITCH_CHAR_WIDTH)
	var rows: int = int(viewport_size.y / GLITCH_CHAR_HEIGHT)
	var text: String = ""

	for r: int in range(rows):
		var line: String = ""
		for c: int in range(cols):
			if randf() < GLITCH_DENSITY:
				var idx: int = randi() % GLITCH_CHARS.size()
				line += "[color=#%s]%s[/color]" % [
					_random_glitch_color(),
					GLITCH_CHARS[idx],
				]
			else:
				line += " "
		text += line + "\n"

	_glitch_label.append_text(text)


func _random_glitch_color() -> String:
	return GLITCH_COLORS[randi() % GLITCH_COLORS.size()]
