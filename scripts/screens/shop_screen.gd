class_name ShopScreen
extends ScreenState

## The Ganglion: spend semant on graphemes, phonemes, or deck removal.
## Displays available items with costs. Terminal aesthetic, box-drawing.

# --- Constants ---
const SCENE_MAP: String = "res://scenes/screens/map_screen.tscn"
const GRAPHEME_DIR: String = "res://data/graphemes/"
const PHONEME_DIR: String = "res://data/phonemes/"

const GRAPHEME_COUNT: int = 3
const PHONEME_COUNT: int = 2
const COLOR_GOLD := Color("#FFD54F")
const COLOR_SOLD := Color("#333340")
const COLOR_GRAPHEME := Color("#00F090")

# --- Private Variables ---
var _shop_graphemes: Array[GraphemeData] = []
var _shop_phonemes: Array[PhonemeData] = []
var _grapheme_sold: Array[bool] = []
var _phoneme_sold: Array[bool] = []
var _grapheme_panels: Array[PanelContainer] = []
var _phoneme_panels: Array[PanelContainer] = []
var _stats_label: Label = null
var _main_content: VBoxContainer = null
var _info_line: Label = null
var _run_semant: int = 0
var _map: Variant = null


# --- Virtual Methods ---

func enter(previous: String, data: Dictionary = {}) -> void:
	super.enter(previous, data)
	_map = data.get("map", null)
	if GameManager.run != null:
		_run_semant = GameManager.run.semant
	else:
		_run_semant = data.get("semant", 50) as int
	_build_ui()
	_generate_stock(data)
	_populate_graphemes()
	_populate_phonemes()
	_update_stats()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_leave()
		get_viewport().set_input_as_handled()


# --- Private Methods ---

func _generate_stock(data: Dictionary) -> void:
	# Load available graphemes from directory
	var all_graphemes: Array[GraphemeData] = []
	var raw_graphemes: Array = _load_resources_from(GRAPHEME_DIR)
	for r: Variant in raw_graphemes:
		if r is GraphemeData:
			all_graphemes.append(r)
	all_graphemes.shuffle()

	# Filter out already-owned graphemes
	var owned_ids: Array = []
	if GameManager.run != null:
		for g: GraphemeData in GameManager.run.acquired_graphemes:
			owned_ids.append(g.id)
	else:
		owned_ids = data.get("owned_grapheme_ids", [])
	var available: Array[GraphemeData] = []
	for g: GraphemeData in all_graphemes:
		if g.id not in owned_ids:
			available.append(g)

	for i: int in GRAPHEME_COUNT:
		if i < available.size():
			_shop_graphemes.append(available[i])
		_grapheme_sold.append(i >= available.size())

	# Load available phonemes
	var all_phonemes: Array[PhonemeData] = []
	var raw_phonemes: Array = _load_resources_from(PHONEME_DIR)
	for r: Variant in raw_phonemes:
		if r is PhonemeData:
			all_phonemes.append(r)
	all_phonemes.shuffle()

	for i: int in PHONEME_COUNT:
		if i < all_phonemes.size():
			_shop_phonemes.append(all_phonemes[i])
		_phoneme_sold.append(i >= all_phonemes.size())


func _load_resources_from(dir_path: String) -> Array:
	var results: Array = []
	var dir := DirAccess.open(dir_path)
	if not dir:
		return results
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res: Resource = load(dir_path + file_name)
			if res:
				results.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	return results


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = ThemeManager.COLOR_VOID
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	ThemeManager.build_unicode_grid(self, "temporal lobe", 4, 0.02)

	# Main layout
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	_main_content = VBoxContainer.new()
	_main_content.add_theme_constant_override("separation", 16)
	margin.add_child(_main_content)

	# Header
	var header := Label.new()
	header.text = "\u2550\u2550\u2550 GANGLION \u2550\u2550\u2550"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(header, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(header, COLOR_GOLD)
	_main_content.add_child(header)

	# Stats
	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_stats_label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(_stats_label, ThemeManager.COLOR_TEXT_MAIN)
	_main_content.add_child(_stats_label)

	# Separator
	_add_separator(ThemeManager.COLOR_TEXT_DIM)

	# Two columns: graphemes + phonemes
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_content.add_child(columns)

	# Column 1: GRAPHEMES
	var graph_col := _make_section("GRAPHEMES", COLOR_GRAPHEME)
	graph_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(graph_col)
	for i: int in GRAPHEME_COUNT:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		graph_col.add_child(panel)
		_grapheme_panels.append(panel)

	# Column 2: PHONEMES
	var phone_col := _make_section("PHONEMES", ThemeManager.COLOR_SHIELD)
	phone_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(phone_col)
	for i: int in PHONEME_COUNT:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		phone_col.add_child(panel)
		_phoneme_panels.append(panel)

	# Info line
	_add_separator(ThemeManager.COLOR_TEXT_DIM)
	_info_line = Label.new()
	_info_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_line.custom_minimum_size = Vector2(0, 20)
	_info_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeManager.apply_mono_font(_info_line, ThemeManager.FONT_MICRO)
	_info_line.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	_main_content.add_child(_info_line)

	# Bottom: leave button
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_content.add_child(bottom)

	var leave_btn := Button.new()
	leave_btn.text = "[ LEAVE SHOP ]"
	leave_btn.custom_minimum_size = Vector2(220, 44)
	leave_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ThemeManager.apply_mono_font(leave_btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(leave_btn, ThemeManager.COLOR_TEXT_DIM)
	leave_btn.pressed.connect(_on_leave)
	bottom.add_child(leave_btn)


func _make_section(title_text: String, color: Color) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = "\u250c %s \u2510" % title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(title, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(title, color)
	vbox.add_child(title)
	return vbox


func _populate_graphemes() -> void:
	for i: int in GRAPHEME_COUNT:
		_render_grapheme_panel(i)


func _render_grapheme_panel(idx: int) -> void:
	if idx >= _grapheme_panels.size():
		return
	var panel: PanelContainer = _grapheme_panels[idx]
	for c: Node in panel.get_children():
		c.queue_free()

	var is_sold: bool = _grapheme_sold[idx]
	var has_data: bool = idx < _shop_graphemes.size()
	var border_color: Color = COLOR_GRAPHEME if not is_sold and has_data else COLOR_SOLD
	ThemeManager.apply_panel_style(panel, ThemeManager.COLOR_PANEL, border_color)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	if is_sold or not has_data:
		var sold_label := Label.new()
		sold_label.text = "[ SOLD ]" if is_sold and has_data else "[ EMPTY ]"
		sold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeManager.apply_mono_font(sold_label, ThemeManager.FONT_BODY)
		sold_label.add_theme_color_override("font_color", COLOR_SOLD)
		vbox.add_child(sold_label)
		return

	var g: GraphemeData = _shop_graphemes[idx]

	# Symbol
	var sym := Label.new()
	sym.text = g.symbol
	sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(sym, 24)
	ThemeManager.apply_glow_text(sym, COLOR_GRAPHEME)
	vbox.add_child(sym)

	# Name
	var name_label := Label.new()
	name_label.text = g.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(name_label, ThemeManager.FONT_BODY)
	name_label.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_MAIN)
	vbox.add_child(name_label)

	# Description
	var desc := Label.new()
	desc.text = g.description
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeManager.apply_mono_font(desc, ThemeManager.FONT_MICRO)
	desc.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	vbox.add_child(desc)

	# Buy button
	var buy_btn := Button.new()
	var can_afford: bool = _run_semant >= g.semant_cost
	buy_btn.text = "BUY \u00a7%d" % g.semant_cost
	buy_btn.disabled = not can_afford
	buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ThemeManager.apply_mono_font(buy_btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(buy_btn, COLOR_GRAPHEME)
	buy_btn.pressed.connect(_on_buy_grapheme.bind(idx))
	vbox.add_child(buy_btn)

	# Hover
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if not panel.mouse_entered.is_connected(_on_grapheme_hover.bind(idx)):
		panel.mouse_entered.connect(_on_grapheme_hover.bind(idx))
		panel.mouse_exited.connect(_clear_info)


func _populate_phonemes() -> void:
	for i: int in PHONEME_COUNT:
		_render_phoneme_panel(i)


func _render_phoneme_panel(idx: int) -> void:
	if idx >= _phoneme_panels.size():
		return
	var panel: PanelContainer = _phoneme_panels[idx]
	for c: Node in panel.get_children():
		c.queue_free()

	var is_sold: bool = _phoneme_sold[idx]
	var has_data: bool = idx < _shop_phonemes.size()
	var border_color: Color = ThemeManager.COLOR_SHIELD if not is_sold and has_data else COLOR_SOLD
	ThemeManager.apply_panel_style(panel, ThemeManager.COLOR_PANEL, border_color)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	if is_sold or not has_data:
		var sold_label := Label.new()
		sold_label.text = "[ SOLD ]" if is_sold and has_data else "[ EMPTY ]"
		sold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeManager.apply_mono_font(sold_label, ThemeManager.FONT_BODY)
		sold_label.add_theme_color_override("font_color", COLOR_SOLD)
		vbox.add_child(sold_label)
		return

	var p: PhonemeData = _shop_phonemes[idx]

	# IPA symbol
	var sym := Label.new()
	sym.text = p.ipa_symbol
	sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(sym, 24)
	ThemeManager.apply_glow_text(sym, ThemeManager.COLOR_SHIELD)
	vbox.add_child(sym)

	# Name
	var name_label := Label.new()
	name_label.text = p.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(name_label, ThemeManager.FONT_BODY)
	name_label.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_MAIN)
	vbox.add_child(name_label)

	# Description
	var desc := Label.new()
	desc.text = p.description
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeManager.apply_mono_font(desc, ThemeManager.FONT_MICRO)
	desc.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	vbox.add_child(desc)

	# Buy button
	var buy_btn := Button.new()
	var can_afford: bool = _run_semant >= p.semant_cost
	buy_btn.text = "BUY \u00a7%d" % p.semant_cost
	buy_btn.disabled = not can_afford
	buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ThemeManager.apply_mono_font(buy_btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(buy_btn, ThemeManager.COLOR_SHIELD)
	buy_btn.pressed.connect(_on_buy_phoneme.bind(idx))
	vbox.add_child(buy_btn)

	# Hover
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if not panel.mouse_entered.is_connected(_on_phoneme_hover.bind(idx)):
		panel.mouse_entered.connect(_on_phoneme_hover.bind(idx))
		panel.mouse_exited.connect(_clear_info)


func _on_buy_grapheme(idx: int) -> void:
	if idx >= _shop_graphemes.size() or _grapheme_sold[idx]:
		return
	var g: GraphemeData = _shop_graphemes[idx]
	if _run_semant < g.semant_cost:
		return
	_run_semant -= g.semant_cost
	_grapheme_sold[idx] = true
	if GameManager.run != null:
		GameManager.run.semant = _run_semant
		GameManager.run.acquired_graphemes.append(g)
	_refresh_all()
	_update_stats()


func _on_buy_phoneme(idx: int) -> void:
	if idx >= _shop_phonemes.size() or _phoneme_sold[idx]:
		return
	var p: PhonemeData = _shop_phonemes[idx]
	if _run_semant < p.semant_cost:
		return
	_run_semant -= p.semant_cost
	_phoneme_sold[idx] = true
	if GameManager.run != null:
		GameManager.run.semant = _run_semant
		GameManager.run.acquired_phonemes.append(p)
	_refresh_all()
	_update_stats()


func _refresh_all() -> void:
	for i: int in GRAPHEME_COUNT:
		_render_grapheme_panel(i)
	for i: int in PHONEME_COUNT:
		_render_phoneme_panel(i)


func _update_stats() -> void:
	_stats_label.text = "\u00a7%d SEMANT" % _run_semant


func _add_separator(color: Color) -> void:
	var sep := Label.new()
	sep.text = "\u2500".repeat(60)
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(sep, ThemeManager.FONT_MICRO)
	sep.add_theme_color_override("font_color", color)
	_main_content.add_child(sep)


func _on_grapheme_hover(idx: int) -> void:
	if _grapheme_sold[idx] or idx >= _shop_graphemes.size():
		_clear_info()
		return
	var g: GraphemeData = _shop_graphemes[idx]
	_info_line.text = "%s  |  %s  |  %s" % [g.symbol, g.display_name, g.description]


func _on_phoneme_hover(idx: int) -> void:
	if _phoneme_sold[idx] or idx >= _shop_phonemes.size():
		_clear_info()
		return
	var p: PhonemeData = _shop_phonemes[idx]
	_info_line.text = "%s  |  %s  |  %s" % [p.ipa_symbol, p.display_name, p.description]


func _clear_info() -> void:
	if _info_line:
		_info_line.text = ""


func _on_leave() -> void:
	var data: Dictionary = {}
	if _map != null:
		data["map"] = _map
	finished.emit(SCENE_MAP, data)
