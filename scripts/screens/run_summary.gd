class_name RunSummaryScreen
extends ScreenState

## Victory/defeat stats screen shown at the end of a run.
## Terminal aesthetic with box-drawing stat table and typewriter effect.

# --- Constants ---

const SCENE_TITLE: String = "res://scenes/screens/title_screen.tscn"

const LINE_DELAY: float = 0.04
const ACCENT_HEX: String = "#00F090"
const ALERT_HEX: String = "#FF1E40"
const DIM_HEX: String = "#4A4A55"
const SHIELD_HEX: String = "#00D0FF"
const WARNING_HEX: String = "#FFB300"

# --- Private Variables ---

var _is_victory: bool = false
var _summary: Dictionary = {}
var _bg: ColorRect = null
var _scroll: ScrollContainer = null
var _content: RichTextLabel = null
var _continue_btn: Button = null
var _lines: PackedStringArray = []
var _current_line: int = 0


# --- Virtual Methods ---

func enter(previous: String, data: Dictionary = {}) -> void:
	super.enter(previous, data)
	# Read stashed summary from GameManager meta (data dict may be empty)
	if data.is_empty() and GameManager.has_meta("run_summary"):
		_summary = GameManager.get_meta("run_summary") as Dictionary
	else:
		_summary = data
	_is_victory = _summary.get("is_victory", false) as bool
	_build_ui()
	_build_lines()
	# Fade in then start typewriter
	_bg.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_bg, "modulate:a", 1.0, 0.4)
	await tween.finished
	_current_line = 0
	_type_next_line()


# --- Private Methods ---

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = ThemeManager.COLOR_VOID
	_bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_bg)

	ThemeManager.build_unicode_grid(self, "temporal lobe", 4, 0.02)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	_bg.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 0)
	margin.add_child(vbox)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_scroll)

	_content = RichTextLabel.new()
	_content.bbcode_enabled = true
	_content.fit_content = true
	_content.scroll_active = false
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.selection_enabled = false
	_content.add_theme_color_override("default_color", ThemeManager.COLOR_TEXT_MAIN)
	ThemeManager.apply_mono_font_rtl(_content, ThemeManager.FONT_BODY)
	_scroll.add_child(_content)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer)

	_continue_btn = Button.new()
	_continue_btn.text = "[ TRY AGAIN ]" if not _is_victory else "[ CONTINUE ]"
	_continue_btn.visible = false
	_continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ThemeManager.apply_mono_font(_continue_btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(_continue_btn, ThemeManager.COLOR_SUCCESS)
	_continue_btn.pressed.connect(_on_continue)
	vbox.add_child(_continue_btn)


func _build_lines() -> void:
	var header_color: String = ACCENT_HEX if _is_victory else ALERT_HEX
	var header_text: String = "RUN COMPLETE" if _is_victory else "FLATLINE"

	_lines = PackedStringArray()
	_lines.append("")
	_lines.append("[color=%s]╔══════════════════════════════════════╗[/color]" % header_color)
	_lines.append("[color=%s]║                                      ║[/color]" % header_color)
	_lines.append("[color=%s]║     ═══ %s ═══     ║[/color]" % [header_color, header_text.rpad(14)])
	_lines.append("[color=%s]║                                      ║[/color]" % header_color)
	_lines.append("[color=%s]╚══════════════════════════════════════╝[/color]" % header_color)
	_lines.append("")

	# Character
	var char_name: String = _summary.get("character_name", "???") as String
	if char_name != "":
		_lines.append("[color=%s]  CHARACTER: %s[/color]" % [DIM_HEX, char_name])
		_lines.append("")

	# Cause of death
	if not _is_victory:
		var enemy: String = _summary.get("last_enemy_name", "") as String
		if enemy != "":
			_lines.append("[color=%s]  KILLED BY: %s[/color]" % [ALERT_HEX, enemy])
		var region: String = _summary.get("death_region", "") as String
		var column: int = _summary.get("death_column", 0) as int
		if region != "":
			_lines.append("[color=%s]  LOCATION:  %s COL %d[/color]" % [DIM_HEX, region, column])
		_lines.append("")

	# Stats table
	var regions: int = _summary.get("regions_cleared", 0) as int
	var enemies: int = _summary.get("enemies_defeated", 0) as int
	var words: int = _summary.get("words_submitted", 0) as int
	var novel: int = _summary.get("novel_words", 0) as int
	var deck_size: int = _summary.get("deck_size", 0) as int
	var pragmant: int = _summary.get("pragmant_earned", 0) as int

	_lines.append("[color=%s]┌─── RUN STATS ────────────────────────┐[/color]" % DIM_HEX)
	_lines.append("[color=%s]│[/color]  REGION REACHED:     [color=%s]%s[/color]" % [DIM_HEX, ACCENT_HEX, str(regions)])
	_lines.append("[color=%s]│[/color]  ENEMIES DEFEATED:   [color=%s]%s[/color]" % [DIM_HEX, SHIELD_HEX, str(enemies).lpad(4)])
	_lines.append("[color=%s]│[/color]  WORDS SUBMITTED:    [color=%s]%s[/color]" % [DIM_HEX, WARNING_HEX, str(words).lpad(4)])
	_lines.append("[color=%s]│[/color]  NOVEL WORDS:        [color=%s]%s[/color]" % [DIM_HEX, WARNING_HEX, str(novel).lpad(4)])
	_lines.append("[color=%s]│[/color]  FINAL DECK:         [color=%s]%s morphemes[/color]" % [DIM_HEX, SHIELD_HEX, str(deck_size)])
	_lines.append("[color=%s]└──────────────────────────────────────┘[/color]" % DIM_HEX)
	_lines.append("")

	# Highlight reel
	var best_word: String = _summary.get("best_word_form", "") as String
	var best_ind: int = _summary.get("best_word_induction", 0) as int
	var peak_mult: float = _summary.get("peak_multiplier", 1.0)
	var novel_count: int = _summary.get("novel_words", 0) as int

	if best_word != "" or enemies > 0:
		_lines.append("[color=%s]┌─── HIGHLIGHT REEL ───────────────────┐[/color]" % DIM_HEX)
		if best_word != "":
			_lines.append("[color=%s]│[/color]  BEST WORD:     [color=%s]%s[/color] for [color=%s]%d[/color] induction" % [DIM_HEX, WARNING_HEX, best_word.to_upper(), WARNING_HEX, best_ind])
		if peak_mult > 1.0:
			_lines.append("[color=%s]│[/color]  PEAK MULT:     [color=%s]x%.1f[/color]" % [DIM_HEX, WARNING_HEX, peak_mult])
		if novel_count > 0:
			_lines.append("[color=%s]│[/color]  NOVEL WORDS:   [color=%s]%d[/color]" % [DIM_HEX, ACCENT_HEX, novel_count])
		_lines.append("[color=%s]└──────────────────────────────────────┘[/color]" % DIM_HEX)
		_lines.append("")

	# Victory/defeat banner
	if _is_victory:
		_lines.append("[color=%s][b]       YOU CLIMBED THE TOWER[/b][/color]" % ACCENT_HEX)
		_lines.append("")
	elif not _is_victory and regions > 0:
		var death_region: String = _summary.get("death_region_id", "") as String
		var death_col: int = _summary.get("death_column", 0) as int
		if death_region != "":
			_lines.append("[color=%s]  FELL AT %s, FLOOR %d/17[/color]" % [DIM_HEX, death_region.to_upper(), death_col + 1])
			_lines.append("")

	# Pragmant
	_lines.append("[color=%s]┌─── REWARDS ──────────────────────────┐[/color]" % DIM_HEX)
	_lines.append("[color=%s]│[/color]  [color=%s]%d PRAGMANT EARNED[/color]" % [DIM_HEX, ACCENT_HEX, pragmant])
	_lines.append("[color=%s]└──────────────────────────────────────┘[/color]" % DIM_HEX)
	_lines.append("")


func _type_next_line() -> void:
	if _current_line >= _lines.size():
		_continue_btn.visible = true
		_continue_btn.grab_focus()
		return

	_content.append_text(_lines[_current_line] + "\n")
	_current_line += 1

	# Auto-scroll
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)

	var timer: SceneTreeTimer = get_tree().create_timer(LINE_DELAY)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(self) and is_inside_tree():
			_type_next_line()
	)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed:
		return
	if _continue_btn.visible:
		return
	_skip_typewriter()
	get_viewport().set_input_as_handled()


func _skip_typewriter() -> void:
	while _current_line < _lines.size():
		_content.append_text(_lines[_current_line] + "\n")
		_current_line += 1
	_continue_btn.visible = true
	_continue_btn.grab_focus()


func _on_continue() -> void:
	finished.emit(SCENE_TITLE, {})
