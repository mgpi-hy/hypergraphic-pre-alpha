class_name RegionSelect
extends ScreenState

## Region selection screen shown between acts.
## Displays 2-3 region choices with modifier info. Player clicks to advance.

# --- Constants ---

const BOX_H: String = "\u2500"  # ─
const BOX_V: String = "\u2502"  # │
const BOX_TL: String = "\u250c"  # ┌
const BOX_TR: String = "\u2510"  # ┐
const BOX_BL: String = "\u2514"  # └
const BOX_BR: String = "\u2518"  # ┘

const COMPLEXITY_LABEL: Dictionary = {
	"simple": "SIMPLE",
	"complex": "COMPLEX",
}

# --- Private Variables ---

var _choices: Array = []  ## Array[RegionData]
var _choice_buttons: Array[Button] = []
var _header_label: Label
var _container: HBoxContainer


# --- Virtual Methods ---

func enter(_previous: String, data: Dictionary = {}) -> void:
	super.enter(_previous, data)
	_choices = data.get("choices", [])
	if _choices.is_empty():
		push_error("RegionSelect.enter: no choices provided")
		return
	_build_ui()


func exit() -> void:
	super.exit()


# --- Private Methods ---

func _build_ui() -> void:
	# Full-screen dark background
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ThemeManager.apply_panel_style(bg, ThemeManager.COLOR_VOID, ThemeManager.COLOR_VOID, 0)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)

	# Header
	_header_label = Label.new()
	_header_label.text = "CHOOSE NEXT REGION"
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_header_label, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(_header_label, ThemeManager.COLOR_TEXT_MAIN)
	vbox.add_child(_header_label)

	# Subheader: act indicator
	var act_num: int = 2
	if not _choices.is_empty():
		act_num = (_choices[0] as RegionData).act
	var sub_label := Label.new()
	sub_label.text = "ACT %d" % act_num
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(sub_label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(sub_label, ThemeManager.COLOR_TEXT_DIM)
	vbox.add_child(sub_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer)

	# Choice cards in a horizontal row
	_container = HBoxContainer.new()
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.add_theme_constant_override("separation", 24)
	vbox.add_child(_container)

	for i: int in range(_choices.size()):
		var region: RegionData = _choices[i] as RegionData
		if region:
			_create_region_card(region, i)


func _create_region_card(region: RegionData, index: int) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 320)
	ThemeManager.apply_panel_style(card, ThemeManager.COLOR_PANEL, region.color, 2)
	_container.add_child(card)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 16)
	card_margin.add_theme_constant_override("margin_right", 16)
	card_margin.add_theme_constant_override("margin_top", 16)
	card_margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(card_margin)

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 8)
	card_margin.add_child(card_vbox)

	# Region name
	var name_label := Label.new()
	name_label.text = region.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeManager.apply_mono_font(name_label, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(name_label, region.color)
	card_vbox.add_child(name_label)

	# Complexity tag
	var complexity_text: String = COMPLEXITY_LABEL.get(region.complexity, "SIMPLE")
	var complexity_label := Label.new()
	complexity_label.text = "[%s]" % complexity_text
	complexity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(complexity_label, ThemeManager.FONT_MICRO)
	var complexity_color: Color = ThemeManager.COLOR_WARNING if region.complexity == "complex" else ThemeManager.COLOR_TEXT_DIM
	ThemeManager.apply_glow_text(complexity_label, complexity_color)
	card_vbox.add_child(complexity_label)

	# Separator
	var sep := Label.new()
	sep.text = BOX_H.repeat(24)
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(sep, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(sep, region.color.darkened(0.5))
	card_vbox.add_child(sep)

	# Modifier name
	var mod_name := Label.new()
	mod_name.text = region.modifier_name
	mod_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(mod_name, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(mod_name, ThemeManager.COLOR_TEXT_MAIN)
	card_vbox.add_child(mod_name)

	# Modifier description
	var mod_desc := Label.new()
	mod_desc.text = region.modifier_description
	mod_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mod_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mod_desc.custom_minimum_size = Vector2(240, 0)
	ThemeManager.apply_mono_font(mod_desc, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(mod_desc, ThemeManager.COLOR_TEXT_DIM)
	card_vbox.add_child(mod_desc)

	# Spacer to push boss info and button to bottom
	var card_spacer := Control.new()
	card_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_vbox.add_child(card_spacer)

	# Boss type
	var boss_label := Label.new()
	var boss_text: String = region.boss_id.replace("_", " ").to_upper()
	boss_label.text = "BOSS: %s" % boss_text
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(boss_label, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(boss_label, ThemeManager.COLOR_ALERT)
	card_vbox.add_child(boss_label)

	# Separator
	var sep2 := Label.new()
	sep2.text = BOX_H.repeat(24)
	sep2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(sep2, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(sep2, region.color.darkened(0.5))
	card_vbox.add_child(sep2)

	# Select button
	var btn := Button.new()
	btn.text = ">> ENTER <<"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeManager.apply_mono_font(btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(btn, region.color)
	btn.pressed.connect(_on_region_chosen.bind(index))
	card_vbox.add_child(btn)
	_choice_buttons.append(btn)


func _on_region_chosen(index: int) -> void:
	if index < 0 or index >= _choices.size():
		return

	# Disable all buttons to prevent double-click
	for btn: Button in _choice_buttons:
		btn.disabled = true

	var region: RegionData = _choices[index] as RegionData
	if region:
		GameManager.set_region(region)
