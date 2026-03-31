class_name RestScreen
extends ScreenState

## The Myelin Sheath: rest site between combats.
## Three options: heal cogency, upgrade a morpheme (+2 induction), or remove a morpheme.

# --- Constants ---
const SCENE_MAP: String = "res://scenes/screens/map_screen.tscn"
const HEAL_PERCENT: float = 0.3

const FLAVOR_TEXTS: PackedStringArray = [
	"The myelin sheath thickens...",
	"Neural pathways consolidate...",
	"Synaptic pruning optimizes connections...",
	"Dendrites reach toward silence...",
	"The axon hums, dormant but ready...",
	"Resting potential holds steady...",
	"Neurotransmitters replenish in the cleft...",
	"Calcium channels close. The signal quiets...",
	"Glial cells tend to the damage...",
	"Long-term potentiation strengthens the trace...",
]

# --- Private Variables ---
var _choice_made: bool = false
var _main_content: VBoxContainer = null
var _stats_label: Label = null
var _choice_container: HBoxContainer = null
var _result_container: VBoxContainer = null
var _overlay: Control = null
var _current_cogency: int = 50
var _max_cogency: int = 50
var _deck: Array[MorphemeData] = []
var _map: Variant = null


# --- Virtual Methods ---

func enter(previous: String, data: Dictionary = {}) -> void:
	super.enter(previous, data)
	_map = data.get("map", null)
	# Pull cogency and deck from RunData (map_screen doesn't pass them)
	if GameManager.run != null:
		_current_cogency = GameManager.run.cogency
		_max_cogency = GameManager.run.max_cogency
		_deck.clear()
		for m: MorphemeData in GameManager.run.deck:
			_deck.append(m)
	else:
		_current_cogency = data.get("cogency", 50) as int
		_max_cogency = data.get("max_cogency", 50) as int
		_deck.clear()
		var raw_deck: Array = data.get("deck", [])
		for m: Variant in raw_deck:
			if m is MorphemeData:
				_deck.append(m)
	_build_ui()
	_update_stats()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _overlay:
			_close_overlay()
		get_viewport().set_input_as_handled()


# --- Private Methods ---

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = ThemeManager.COLOR_VOID
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	ThemeManager.build_unicode_grid(self, "limbic system", 4, 0.02)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 60)
	for side: String in ["margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 40)
	add_child(margin)

	_main_content = VBoxContainer.new()
	_main_content.add_theme_constant_override("separation", 24)
	_main_content.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(_main_content)

	var header := Label.new()
	header.text = "\u2550\u2550\u2550 MYELIN SHEATH \u2550\u2550\u2550"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(header, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(header, ThemeManager.COLOR_SUCCESS)
	_main_content.add_child(header)

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_stats_label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(_stats_label, ThemeManager.COLOR_TEXT_MAIN)
	_main_content.add_child(_stats_label)

	var flavor := Label.new()
	flavor.text = FLAVOR_TEXTS[randi() % FLAVOR_TEXTS.size()]
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(flavor, ThemeManager.FONT_MICRO)
	flavor.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	_main_content.add_child(flavor)

	_choice_container = HBoxContainer.new()
	_choice_container.add_theme_constant_override("separation", 40)
	_choice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_content.add_child(_choice_container)

	var heal_amt: int = int(float(_max_cogency) * HEAL_PERCENT)
	_add_choice("REST", "Restore 30%% cogency\n(+%d COG)" % heal_amt, "[ RESTORE ]", ThemeManager.COLOR_SUCCESS, _on_heal)
	_add_choice("UPGRADE", "Upgrade a morpheme\n(+2 induction)", "[ SELECT ]", ThemeManager.COLOR_GOLD, _on_upgrade)
	_add_choice("REMOVE", "Remove a morpheme\nfrom your deck", "[ SELECT ]", ThemeManager.COLOR_ALERT, _on_remove)

	_result_container = VBoxContainer.new()
	_result_container.add_theme_constant_override("separation", 16)
	_result_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_result_container.visible = false
	_main_content.add_child(_result_container)


func _add_choice(title: String, desc: String, btn_text: String, color: Color, cb: Callable) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 180)
	ThemeManager.apply_panel_style(panel, ThemeManager.COLOR_PANEL, color, 2)
	_choice_container.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(t, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(t, color)
	vbox.add_child(t)

	var d := Label.new()
	d.text = desc
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeManager.apply_mono_font(d, ThemeManager.FONT_BODY)
	d.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_MAIN)
	vbox.add_child(d)

	var b := Button.new()
	b.text = btn_text
	b.custom_minimum_size = Vector2(180, 40)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ThemeManager.apply_mono_font(b, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(b, color)
	b.pressed.connect(cb)
	vbox.add_child(b)


func _on_heal() -> void:
	if _choice_made:
		return
	_choice_made = true
	_choice_container.visible = false
	var heal_amount: int = int(float(_max_cogency) * HEAL_PERCENT)
	var old: int = _current_cogency
	_current_cogency = mini(_current_cogency + heal_amount, _max_cogency)
	if GameManager.run != null:
		GameManager.run.cogency = _current_cogency
	_update_stats()
	_show_result("Cogency restored (+%d). The signal strengthens." % (_current_cogency - old))


func _on_upgrade() -> void:
	if _choice_made:
		return
	_choice_made = true
	_show_deck_overlay("SELECT MORPHEME TO UPGRADE", ThemeManager.COLOR_GOLD, true)


func _on_remove() -> void:
	if _choice_made:
		return
	_choice_made = true
	_show_deck_overlay("SELECT MORPHEME TO REMOVE", ThemeManager.COLOR_ALERT, false)


func _show_deck_overlay(title: String, color: Color, is_upgrade: bool) -> void:
	_close_overlay()
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.03, 0.92)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s: String in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(s, 60)
	for s: String in ["margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(s, 40)
	_overlay.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var t := Label.new()
	t.text = "\u2550\u2550\u2550 %s \u2550\u2550\u2550" % title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(t, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(t, color)
	vbox.add_child(t)

	if _deck.is_empty():
		var empty := Label.new()
		empty.text = "No morphemes available."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeManager.apply_mono_font(empty, ThemeManager.FONT_BODY)
		empty.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
		vbox.add_child(empty)
	else:
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		vbox.add_child(grid)
		for i: int in _deck.size():
			var m: MorphemeData = _deck[i]
			var btn := Button.new()
			if is_upgrade:
				btn.text = "%s\n[%d] \u2192 [%d]" % [m.root_text, m.base_induction, m.base_induction + 2]
			else:
				btn.text = "%s\n[%d]" % [m.root_text, m.base_induction]
			btn.custom_minimum_size = Vector2(120, 60)
			ThemeManager.apply_mono_font(btn, ThemeManager.FONT_MICRO)
			ThemeManager.apply_button_style(btn, color)
			if is_upgrade:
				btn.pressed.connect(_do_upgrade.bind(i))
			else:
				btn.pressed.connect(_do_remove.bind(i))
			grid.add_child(btn)

	var cancel := Button.new()
	cancel.text = "[ CANCEL ]"
	cancel.custom_minimum_size = Vector2(200, 40)
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ThemeManager.apply_mono_font(cancel, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(cancel, ThemeManager.COLOR_TEXT_DIM)
	cancel.pressed.connect(_close_overlay)
	vbox.add_child(cancel)


func _do_upgrade(idx: int) -> void:
	if idx >= _deck.size():
		return
	var m: MorphemeData = _deck[idx]
	m.base_induction += 2
	_close_overlay()
	_choice_container.visible = false
	_show_result("%s upgraded to [%d] induction." % [m.root_text, m.base_induction])


func _do_remove(idx: int) -> void:
	if idx >= _deck.size():
		return
	var removed: MorphemeData = _deck[idx]
	_deck.remove_at(idx)
	if GameManager.run != null:
		var run_idx: int = GameManager.run.deck.find(removed)
		if run_idx >= 0:
			GameManager.run.deck.remove_at(run_idx)
	_close_overlay()
	_choice_container.visible = false
	_show_result("%s removed from deck." % removed.root_text)


func _close_overlay() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null
	_choice_made = false


func _show_result(text: String) -> void:
	_result_container.visible = true
	for c: Node in _result_container.get_children():
		c.queue_free()
	var r := Label.new()
	r.text = text
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(r, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(r, ThemeManager.COLOR_TEXT_MAIN)
	_result_container.add_child(r)
	var btn := Button.new()
	btn.text = "[ CONTINUE ]"
	btn.custom_minimum_size = Vector2(200, 40)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ThemeManager.apply_mono_font(btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(btn, ThemeManager.COLOR_SUCCESS)
	btn.pressed.connect(func() -> void:
		var data: Dictionary = {}
		if _map != null:
			data["map"] = _map
		finished.emit(SCENE_MAP, data)
	)
	_result_container.add_child(btn)


func _update_stats() -> void:
	_stats_label.text = "COG: %d/%d    DECK: %d" % [_current_cogency, _max_cogency, _deck.size()]
