class_name MorphemeBlock
extends PanelContainer

## A draggable morpheme card in the player's hand.
## Displays root text, POS type (color-coded), family indicator, base induction.
## Supports drag-and-drop onto SyntaxSlot targets.

# --- Constants ---

const POS_NAMES: Dictionary = {
	Enums.POSType.NOUN: "N",
	Enums.POSType.VERB: "V",
	Enums.POSType.ADJECTIVE: "ADJ",
	Enums.POSType.ADVERB: "ADV",
}

const FAMILY_GLYPHS: Dictionary = {
	Enums.MorphemeFamily.GERMANIC: "G",
	Enums.MorphemeFamily.LATINATE: "L",
	Enums.MorphemeFamily.GREEK: "K",
	Enums.MorphemeFamily.FUNCTIONAL: "F",
}

# --- Exports ---

@export var morpheme: MorphemeData

# --- Private Variables ---

var _root_label: Label
var _pos_label: Label
var _family_label: Label
var _induction_label: Label
var _insulation_label: Label


# --- Virtual Methods ---

func _ready() -> void:
	_build_display()
	_apply_style()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not morpheme:
		return null
	set_drag_preview(_make_drag_preview())
	return morpheme


# --- Private Methods ---

func _build_display() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	_root_label = Label.new()
	_root_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_root_label, ThemeManager.FONT_BODY)
	vbox.add_child(_root_label)

	var info_row := HBoxContainer.new()
	info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info_row.add_theme_constant_override("separation", 4)
	vbox.add_child(info_row)

	_pos_label = Label.new()
	ThemeManager.apply_mono_font(_pos_label, ThemeManager.FONT_MICRO)
	info_row.add_child(_pos_label)

	_family_label = Label.new()
	ThemeManager.apply_mono_font(_family_label, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(_family_label, ThemeManager.COLOR_TEXT_DIM)
	info_row.add_child(_family_label)

	_induction_label = Label.new()
	ThemeManager.apply_mono_font(_induction_label, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(_induction_label, ThemeManager.COLOR_WARNING)
	info_row.add_child(_induction_label)

	_insulation_label = Label.new()
	ThemeManager.apply_mono_font(_insulation_label, ThemeManager.FONT_MICRO)
	ThemeManager.apply_glow_text(_insulation_label, ThemeManager.COLOR_INSULATION)
	info_row.add_child(_insulation_label)

	if morpheme:
		_root_label.text = morpheme.root_text.to_upper()
		var pos_key: String = POS_NAMES.get(morpheme.pos_type, "?")
		_pos_label.text = "[%s]" % pos_key
		_family_label.text = FAMILY_GLYPHS.get(morpheme.family, "?")

		# Show induction for CONTENT/HYBRID, insulation for FUNCTIONAL/HYBRID
		var role: MorphemeData.CombatRole = morpheme.combat_role
		if role == MorphemeData.CombatRole.CONTENT or role == MorphemeData.CombatRole.HYBRID:
			_induction_label.text = "[%d]" % morpheme.base_induction
			_induction_label.visible = true
		else:
			_induction_label.visible = false

		if role == MorphemeData.CombatRole.FUNCTIONAL or role == MorphemeData.CombatRole.HYBRID:
			_insulation_label.text = "(%d)" % morpheme.base_induction
			_insulation_label.visible = true
		else:
			_insulation_label.visible = false


func _apply_style() -> void:
	if not morpheme:
		ThemeManager.apply_panel_style(self, ThemeManager.COLOR_PANEL, ThemeManager.COLOR_TEXT_DIM)
		return

	var pos_name: String = _get_pos_string(morpheme.pos_type)
	var pos_color: Color = POSColors.get_color(pos_name)
	var rarity_str: String = _get_rarity_string(morpheme.rarity)
	var style: StyleBoxFlat = ThemeManager.make_morpheme_card_style(pos_color, rarity_str)
	add_theme_stylebox_override("panel", style)
	ThemeManager.apply_glow_text(_root_label, ThemeManager.get_text_main())
	ThemeManager.apply_glow_text(_pos_label, pos_color)

	custom_minimum_size = Vector2(80.0, 60.0)


func _make_drag_preview() -> Control:
	var preview := PanelContainer.new()
	var pos_name: String = _get_pos_string(morpheme.pos_type)
	var pos_color: Color = POSColors.get_color(pos_name)
	ThemeManager.apply_panel_style(preview, ThemeManager.COLOR_PANEL, pos_color, 2)
	preview.modulate.a = 0.8

	var label := Label.new()
	label.text = morpheme.root_text.to_upper()
	ThemeManager.apply_mono_font(label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(label, pos_color)
	preview.add_child(label)

	return preview


func _get_pos_string(pos: Enums.POSType) -> String:
	match pos:
		Enums.POSType.NOUN:
			return "noun"
		Enums.POSType.VERB:
			return "verb"
		Enums.POSType.ADJECTIVE:
			return "adjective"
		Enums.POSType.ADVERB:
			return "adverb"
		_:
			return "default"


func _get_rarity_string(rarity: MorphemeData.Rarity) -> String:
	match rarity:
		MorphemeData.Rarity.UNCOMMON:
			return "uncommon"
		MorphemeData.Rarity.RARE:
			return "rare"
		MorphemeData.Rarity.MYTHIC:
			return "mythic"
		MorphemeData.Rarity.LEGENDARY:
			return "legendary"
		_:
			return "common"
