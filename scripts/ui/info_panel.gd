class_name InfoPanel
extends PanelContainer

## Popup panel that shows detailed info about a grapheme, morpheme, or phoneme.
## Close on click outside or Escape. Terminal aesthetic with box-drawing border.

# --- Signals ---

signal closed

# --- Private Variables ---

var _title_label: Label = null
var _body_label: RichTextLabel = null
var _overlay: ColorRect = null


# --- Virtual Methods ---

func _ready() -> void:
	_build_ui()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


# --- Public Methods ---

## Display a GraphemeData resource in the panel.
func show_grapheme(data: GraphemeData) -> void:
	if not data:
		return
	var rarity_name: String = GraphemeData.Rarity.keys()[data.rarity]
	var family_name: String = Enums.GraphemeFamily.keys()[data.family]
	_title_label.text = "%s  %s" % [data.symbol, data.display_name]

	var bbcode: String = ""
	bbcode += "[color=#%s]%s[/color]  |  " % [ThemeManager.COLOR_TEXT_DIM.to_html(false), family_name]
	bbcode += "[color=#%s]%s[/color]\n\n" % [ThemeManager.COLOR_WARNING.to_html(false), rarity_name]
	bbcode += data.description
	if data.effects.size() > 0:
		bbcode += "\n\n[color=#%s]EFFECTS:[/color]\n" % ThemeManager.COLOR_SUCCESS.to_html(false)
		for effect: Effect in data.effects:
			if effect:
				bbcode += "  %s\n" % effect.get_description() if effect.has_method("get_description") else "  (effect)\n"
	bbcode += "\n[color=#%s]Shop cost: %d semant[/color]" % [ThemeManager.COLOR_GOLD.to_html(false), data.semant_cost]

	_body_label.clear()
	_body_label.append_text(bbcode)
	_show_panel()


## Display a MorphemeData resource in the panel.
func show_morpheme(data: MorphemeData) -> void:
	if not data:
		return
	var pos_name: String = Enums.POSType.keys()[data.pos_type]
	var family_name: String = Enums.MorphemeFamily.keys()[data.family]
	var type_name: String = MorphemeData.MorphemeType.keys()[data.type]
	_title_label.text = data.root_text if data.root_text != "" else data.display_name

	var bbcode: String = ""
	bbcode += "[color=#%s]%s[/color]  |  " % [ThemeManager.COLOR_TEXT_DIM.to_html(false), type_name]
	bbcode += "[color=#%s]%s[/color]  |  " % [ThemeManager.COLOR_WARNING.to_html(false), pos_name]
	bbcode += "[color=#%s]%s[/color]\n\n" % [ThemeManager.COLOR_GOLD.to_html(false), family_name]
	bbcode += "Base induction: [color=#%s]%d[/color]\n" % [ThemeManager.COLOR_WARNING.to_html(false), data.base_induction]
	bbcode += "Affix slots: [color=#%s]%d[/color]\n" % [ThemeManager.COLOR_SHIELD.to_html(false), data.affix_slots]
	if data.description != "":
		bbcode += "\n%s" % data.description

	_body_label.clear()
	_body_label.append_text(bbcode)
	_show_panel()


## Display a PhonemeData resource in the panel.
func show_phoneme(data: PhonemeData) -> void:
	if not data:
		return
	var rarity_name: String = PhonemeData.Rarity.keys()[data.rarity]
	_title_label.text = "%s  %s" % [data.ipa_symbol, data.display_name]

	var bbcode: String = ""
	bbcode += "[color=#%s]%s[/color]  |  " % [ThemeManager.COLOR_TEXT_DIM.to_html(false), rarity_name]
	if data.is_consumable:
		bbcode += "[color=#%s]CONSUMABLE[/color]\n\n" % ThemeManager.COLOR_ALERT.to_html(false)
	else:
		bbcode += "[color=#%s]PERSISTENT[/color]\n\n" % ThemeManager.COLOR_SUCCESS.to_html(false)
	bbcode += data.description
	bbcode += "\n\n[color=#%s]Shop cost: %d semant[/color]" % [ThemeManager.COLOR_GOLD.to_html(false), data.semant_cost]

	_body_label.clear()
	_body_label.append_text(bbcode)
	_show_panel()


# --- Private Methods ---

func _build_ui() -> void:
	custom_minimum_size = Vector2(400, 250)
	mouse_filter = Control.MOUSE_FILTER_STOP

	ThemeManager.apply_panel_style(self, ThemeManager.COLOR_PANEL, ThemeManager.COLOR_TEXT_DIM, 2)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Box-drawing top border
	var top_border := Label.new()
	top_border.text = "\u250c\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2510"
	ThemeManager.apply_mono_font(top_border, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(top_border, ThemeManager.COLOR_TEXT_DIM)
	vbox.add_child(top_border)

	# Title
	_title_label = Label.new()
	_title_label.text = ""
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_title_label, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(_title_label, ThemeManager.COLOR_TEXT_MAIN)
	vbox.add_child(_title_label)

	# Separator
	var sep := Label.new()
	sep.text = "\u2502\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2502"
	ThemeManager.apply_mono_font(sep, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(sep, ThemeManager.COLOR_TEXT_DIM)
	vbox.add_child(sep)

	# Body (rich text for colored details)
	_body_label = RichTextLabel.new()
	_body_label.bbcode_enabled = true
	_body_label.fit_content = true
	_body_label.scroll_active = false
	_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ThemeManager.apply_mono_font_rtl(_body_label, ThemeManager.FONT_MICRO)
	vbox.add_child(_body_label)

	# Box-drawing bottom border
	var bottom_border := Label.new()
	bottom_border.text = "\u2514\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2518"
	ThemeManager.apply_mono_font(bottom_border, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(bottom_border, ThemeManager.COLOR_TEXT_DIM)
	vbox.add_child(bottom_border)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "[ CLOSE ]"
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ThemeManager.apply_mono_font(close_btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(close_btn, ThemeManager.COLOR_TEXT_DIM)
	close_btn.pressed.connect(_close)
	vbox.add_child(close_btn)

	hide()


func _show_panel() -> void:
	show()
	# Center on screen
	var viewport_size: Vector2 = get_viewport_rect().size
	position = (viewport_size - size) * 0.5


func _close() -> void:
	hide()
	closed.emit()
