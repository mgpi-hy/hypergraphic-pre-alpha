class_name DeckViewerScreen
extends ScreenState

## Full-screen overlay to view all morphemes in the current deck.
## Grid layout, color-coded by POS, sortable by family/POS/induction.

# --- Constants ---

const DIM_COLOR := ThemeManager.COLOR_TEXT_DIM

# --- Enums ---

enum SortMode { FAMILY, POS, INDUCTION }

# --- Private Variables ---

var _previous_screen: String = ""
var _return_data: Dictionary = {}
var _sort_mode: SortMode = SortMode.POS
var _card_container: GridContainer = null
var _count_label: Label = null
var _sort_buttons: Array[Button] = []


# --- Virtual Methods ---

func enter(previous: String, data: Dictionary = {}) -> void:
	super.enter(previous, data)
	_previous_screen = data.get("return_to", previous) as String
	_return_data = data.duplicate()
	_return_data.erase("return_to")
	_build_ui()
	_populate_cards()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed:
		return
	if event.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()


# --- Private Methods ---

func _build_ui() -> void:
	# Full screen overlay
	mouse_filter = Control.MOUSE_FILTER_STOP

	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.02, 0.03, 0.92)
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	ThemeManager.build_unicode_grid(self, "parietal lobe", 4, 0.015)

	# Main panel
	var panel := PanelContainer.new()
	panel.anchor_left = 0.05
	panel.anchor_right = 0.95
	panel.anchor_top = 0.03
	panel.anchor_bottom = 0.97
	panel.offset_left = 0.0
	panel.offset_right = 0.0
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	ThemeManager.apply_panel_style(panel, ThemeManager.COLOR_PANEL, DIM_COLOR, 1)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Header
	var header := Label.new()
	header.text = "═══ MORPHEME DECK ═══"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(header, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(header, ThemeManager.COLOR_TEXT_MAIN)
	vbox.add_child(header)

	# Count
	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_count_label, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(_count_label, DIM_COLOR)
	vbox.add_child(_count_label)

	# Sort row
	var sort_row := HBoxContainer.new()
	sort_row.add_theme_constant_override("separation", 6)
	sort_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(sort_row)

	var sort_label := Label.new()
	sort_label.text = "SORT:"
	ThemeManager.apply_mono_font(sort_label, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(sort_label, DIM_COLOR)
	sort_row.add_child(sort_label)

	var sort_names: Array[String] = ["BY POS", "BY FAMILY", "BY INDUCTION"]
	var sort_modes: Array[SortMode] = [SortMode.POS, SortMode.FAMILY, SortMode.INDUCTION]
	for i: int in sort_names.size():
		var btn := _make_sort_button(sort_names[i])
		btn.pressed.connect(_on_sort_change.bind(sort_modes[i]))
		sort_row.add_child(btn)
		_sort_buttons.append(btn)

	# Scrollable card area
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_card_container = GridContainer.new()
	_card_container.columns = 5
	_card_container.add_theme_constant_override("h_separation", 8)
	_card_container.add_theme_constant_override("v_separation", 8)
	_card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_card_container)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "[ CLOSE  ESC ]"
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ThemeManager.apply_mono_font(close_btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(close_btn, DIM_COLOR)
	close_btn.pressed.connect(_close)
	vbox.add_child(close_btn)

	_update_sort_styles()


func _populate_cards() -> void:
	for child: Node in _card_container.get_children():
		child.queue_free()

	var deck: Array[MorphemeData] = _get_deck()
	var sorted: Array[MorphemeData] = _sort_deck(deck)

	_count_label.text = "%d MORPHEMES" % sorted.size()

	for morph: MorphemeData in sorted:
		var card := _make_card(morph)
		_card_container.add_child(card)


func _make_card(morph: MorphemeData) -> PanelContainer:
	var pos_color: Color = _get_pos_color(morph.pos_type)
	var family_color: Color = _get_family_color(morph.family)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 100)

	var style := StyleBoxFlat.new()
	style.bg_color = ThemeManager.COLOR_PANEL.lightened(0.03)
	style.set_corner_radius_all(0)
	style.set_border_width_all(1)
	style.border_color = pos_color.darkened(0.4)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	# Root text
	var root_label := Label.new()
	root_label.text = morph.root_text.to_upper()
	ThemeManager.apply_mono_font(root_label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(root_label, pos_color)
	vbox.add_child(root_label)

	# POS
	var pos_label := Label.new()
	pos_label.text = Enums.POSType.keys()[morph.pos_type]
	ThemeManager.apply_mono_font(pos_label, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(pos_label, pos_color.darkened(0.2))
	vbox.add_child(pos_label)

	# Family
	var fam_label := Label.new()
	fam_label.text = Enums.MorphemeFamily.keys()[morph.family]
	ThemeManager.apply_mono_font(fam_label, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(fam_label, family_color)
	vbox.add_child(fam_label)

	# Induction
	var ind_label := Label.new()
	ind_label.text = "[%d]" % morph.base_induction
	ThemeManager.apply_mono_font(ind_label, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(ind_label, ThemeManager.COLOR_WARNING)
	vbox.add_child(ind_label)

	return card


func _sort_deck(deck: Array[MorphemeData]) -> Array[MorphemeData]:
	var result: Array[MorphemeData] = deck.duplicate()
	match _sort_mode:
		SortMode.FAMILY:
			result.sort_custom(func(a: MorphemeData, b: MorphemeData) -> bool:
				if a.family != b.family:
					return a.family < b.family
				return a.root_text < b.root_text
			)
		SortMode.POS:
			result.sort_custom(func(a: MorphemeData, b: MorphemeData) -> bool:
				if a.pos_type != b.pos_type:
					return a.pos_type < b.pos_type
				return a.root_text < b.root_text
			)
		SortMode.INDUCTION:
			result.sort_custom(func(a: MorphemeData, b: MorphemeData) -> bool:
				if a.base_induction != b.base_induction:
					return a.base_induction > b.base_induction
				return a.root_text < b.root_text
			)
	return result


func _on_sort_change(mode: SortMode) -> void:
	_sort_mode = mode
	_update_sort_styles()
	_populate_cards()


func _update_sort_styles() -> void:
	var mode_names: Array[String] = ["BY POS", "BY FAMILY", "BY INDUCTION"]
	for i: int in _sort_buttons.size():
		var is_active: bool = i == int(_sort_mode)
		if is_active:
			_sort_buttons[i].add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_MAIN)
		else:
			_sort_buttons[i].add_theme_color_override("font_color", DIM_COLOR)


func _make_sort_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	ThemeManager.apply_mono_font(btn, ThemeManager.FONT_MICRO)
	btn.add_theme_color_override("font_color", DIM_COLOR)
	btn.add_theme_color_override("font_hover_color", ThemeManager.COLOR_TEXT_MAIN)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_corner_radius_all(0)
	btn.add_theme_stylebox_override("normal", style)
	var hover := StyleBoxFlat.new()
	hover.bg_color = ThemeManager.COLOR_PANEL.lightened(0.05)
	hover.set_corner_radius_all(0)
	btn.add_theme_stylebox_override("hover", hover)
	return btn


func _get_deck() -> Array[MorphemeData]:
	if GameManager.run != null:
		return GameManager.run.deck
	return []


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


func _get_family_color(family: Enums.MorphemeFamily) -> Color:
	match family:
		Enums.MorphemeFamily.GERMANIC:
			return Color("#8BC34A")
		Enums.MorphemeFamily.LATINATE:
			return ThemeManager.COLOR_INSULATION
		Enums.MorphemeFamily.GREEK:
			return Color("#00BCD4")
		Enums.MorphemeFamily.FUNCTIONAL:
			return DIM_COLOR
		_:
			return DIM_COLOR


func _close() -> void:
	finished.emit(_previous_screen, _return_data)
