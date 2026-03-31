class_name SyntaxSlot
extends PanelContainer

## A drop target in the syntax tree. Accepts morpheme blocks via drag-and-drop.
## Displays POS type label with color coding, box-drawing border, filled/empty state.

# --- Signals ---

signal morpheme_dropped(morpheme: MorphemeData, slot: SyntaxSlot)
signal morpheme_cleared(slot: SyntaxSlot)

# --- Constants ---

const POS_LABELS: Dictionary = {
	Enums.POSType.NOUN: "NOUN",
	Enums.POSType.VERB: "VERB",
	Enums.POSType.ADJECTIVE: "ADJ",
	Enums.POSType.ADVERB: "ADV",
	Enums.POSType.DETERMINER: "DET",
	Enums.POSType.PREPOSITION: "PREP",
}

# --- Exports ---

@export var pos_type: Enums.POSType = Enums.POSType.NOUN
@export var is_optional: bool = false
@export var is_required: bool = true

# --- Public Variables ---

# TODO: Phil's Compounding passive requires multi-root slot support.
# Currently 1 morpheme per slot. Multi-root requires morpheme_parts: Array[MorphemeData]
# and insertion ordering (prefix -> root -> suffix). Tracked as a future feature.
var placed_morpheme: MorphemeData = null
var current_word: WordBlock = null
var branch_id: String = ""
var is_locked: bool = false
var is_pos_hidden: bool = false

# --- Private Variables ---

var _pos_label: Label
var _content_label: Label
var _stats_label: Label
var _tag_label: Label
var _optional_marker: Label


# --- Virtual Methods ---

func _ready() -> void:
	_build_display()
	_apply_empty_style()
	custom_minimum_size = Vector2(100.0, 70.0)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is MorphemeData and placed_morpheme == null


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is MorphemeData:
		return
	placed_morpheme = data as MorphemeData
	_rebuild_word()
	_apply_filled_style()
	morpheme_dropped.emit(placed_morpheme, self)


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT and placed_morpheme:
		clear_slot()


# --- Public Methods ---

## Remove the placed morpheme and reset to empty state.
func clear_slot() -> void:
	placed_morpheme = null
	current_word = null
	_apply_empty_style()
	morpheme_cleared.emit(self)


## Returns true if this slot has a morpheme whose POS matches the slot POS.
func is_pos_matched() -> bool:
	if not placed_morpheme:
		return false
	return placed_morpheme.pos_type == pos_type


## Refresh the slot's visual state based on current data (locked, pos_hidden, filled).
func update_display() -> void:
	if placed_morpheme != null:
		_apply_filled_style()
	else:
		_apply_empty_style()
	# Show/hide POS label based on is_pos_hidden flag
	if _pos_label:
		_pos_label.visible = not is_pos_hidden
	# Dim the slot if locked
	if is_locked:
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		modulate = Color.WHITE


## Place a morpheme into this slot and update display. Does NOT emit morpheme_dropped.
func place(morpheme: MorphemeData) -> void:
	placed_morpheme = morpheme
	_rebuild_word()
	_apply_filled_style()
	if _pos_label:
		_pos_label.visible = not is_pos_hidden


## Remove the placed morpheme and update display. Does NOT emit morpheme_cleared.
func clear_morpheme() -> void:
	placed_morpheme = null
	current_word = null
	_apply_empty_style()


## Compatibility alias: place a morpheme without emitting signals. Used by force-place mechanics.
func set_morpheme(morpheme: MorphemeData) -> void:
	place(morpheme)


# --- Private Methods ---

func _build_display() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	_pos_label = Label.new()
	var pos_name: String = POS_LABELS.get(pos_type, "?")
	if is_optional:
		_pos_label.text = pos_name + "?"
	else:
		_pos_label.text = pos_name
	_pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_pos_label, ThemeManager.FONT_BODY)
	vbox.add_child(_pos_label)

	_content_label = Label.new()
	_content_label.text = "---"
	_content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_content_label, ThemeManager.FONT_BODY)
	vbox.add_child(_content_label)

	_stats_label = Label.new()
	_stats_label.text = ""
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_stats_label, ThemeManager.FONT_MICRO)
	_stats_label.visible = false
	vbox.add_child(_stats_label)

	_tag_label = Label.new()
	_tag_label.text = ""
	_tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_tag_label, ThemeManager.FONT_MICRO)
	_tag_label.visible = false
	vbox.add_child(_tag_label)

	if is_optional:
		_optional_marker = Label.new()
		_optional_marker.text = "(opt)"
		_optional_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeManager.apply_mono_font(_optional_marker, ThemeManager.FONT_MICRO)
		ThemeManager.apply_glow_text(_optional_marker, ThemeManager.COLOR_TEXT_DIM)
		vbox.add_child(_optional_marker)


func _apply_empty_style() -> void:
	var style: StyleBoxFlat = ThemeManager.make_empty_slot_style()
	add_theme_stylebox_override("panel", style)

	var pos_name: String = _get_pos_string()
	var pos_color: Color = POSColors.get_color(pos_name)
	ThemeManager.apply_glow_text(_pos_label, pos_color.darkened(0.3))
	ThemeManager.apply_glow_text(_content_label, ThemeManager.COLOR_TEXT_DIM)
	_content_label.text = "---"

	# Update POS label text for empty state
	var label_text: String = POS_LABELS.get(pos_type, "?")
	if is_optional:
		_pos_label.text = label_text + "?"
	else:
		_pos_label.text = label_text

	_stats_label.visible = false
	_tag_label.visible = false

	if _optional_marker:
		_optional_marker.visible = true


func _rebuild_word() -> void:
	if not placed_morpheme:
		current_word = null
		return
	var morpheme_parts: Array[MorphemeData] = [placed_morpheme]
	current_word = WordBlock.from_morphemes(morpheme_parts, pos_type)


func _apply_filled_style() -> void:
	if not placed_morpheme:
		return
	var pos_name: String = _get_pos_string()
	var pos_color: Color = POSColors.get_color(pos_name)

	# Border: POS-colored if matched, red with "!!" if mismatched
	var is_matched: bool = is_pos_matched()
	var border_color: Color = pos_color if is_matched else ThemeManager.COLOR_ALERT
	var style: StyleBoxFlat = ThemeManager.make_filled_slot_style(border_color)
	add_theme_stylebox_override("panel", style)

	ThemeManager.apply_glow_text(_pos_label, pos_color)

	# Form text (with mismatch warning)
	if current_word:
		_content_label.text = current_word.form.to_upper()
		if not is_matched:
			_content_label.text += " !!"
			ThemeManager.apply_glow_text(_content_label, ThemeManager.COLOR_ALERT)
		else:
			ThemeManager.apply_glow_text(_content_label, ThemeManager.get_text_main())

		# Stats line: [induction] (insulation) in gold/purple
		var stat_parts: PackedStringArray = []
		if current_word.induction > 0:
			stat_parts.append("[%d]" % current_word.induction)
		if current_word.insulation > 0:
			stat_parts.append("(%d)" % current_word.insulation)
		if stat_parts.size() > 0:
			_stats_label.text = " ".join(stat_parts)
			# Color by dominant stat; gold for induction, purple for insulation
			if current_word.induction >= current_word.insulation:
				ThemeManager.apply_glow_text(_stats_label, ThemeManager.COLOR_WARNING)
			else:
				ThemeManager.apply_glow_text(_stats_label, ThemeManager.COLOR_INSULATION)
			_stats_label.visible = true
		else:
			_stats_label.visible = false

		# Tags: NEW, MIX/MIX+
		var tags: PackedStringArray = []
		if current_word.is_novel:
			tags.append("NEW")
		if current_word.has_mixed_families:
			if current_word.family_set.size() > 2:
				tags.append("MIX+")
			else:
				tags.append("MIX")
		if tags.size() > 0:
			_tag_label.text = " ".join(tags)
			ThemeManager.apply_glow_text(_tag_label, ThemeManager.COLOR_TEXT_DIM)
			_tag_label.visible = true
		else:
			_tag_label.visible = false
	else:
		_content_label.text = placed_morpheme.root_text.to_upper()
		ThemeManager.apply_glow_text(_content_label, ThemeManager.get_text_main())
		_stats_label.visible = false
		_tag_label.visible = false

	if _optional_marker:
		_optional_marker.visible = false


func _get_pos_string() -> String:
	match pos_type:
		Enums.POSType.NOUN:
			return "noun"
		Enums.POSType.VERB:
			return "verb"
		Enums.POSType.ADJECTIVE:
			return "adjective"
		Enums.POSType.ADVERB:
			return "adverb"
		Enums.POSType.DETERMINER:
			return "determiner"
		Enums.POSType.PREPOSITION:
			return "preposition"
		_:
			return "default"
