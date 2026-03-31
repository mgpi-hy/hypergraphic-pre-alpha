class_name RootUnlockScreen
extends ScreenState

## Spend semant to unlock new morpheme roots for future runs.
## Tiered unlock tree (tiers 0-5, increasing cost).
## Port from old root_unlock_screen.gd adapted to new architecture.

# --- Constants ---

const COLOR_LOCKED_DIM := Color("#1A1A22")
const COLOR_OWNED := Color("#2A2A35")

const TIER_COSTS: Array[int] = [0, 15, 30, 50, 80, 120]
const TIER_SPACING: int = 110
const NODE_WIDTH: int = 130
const NODE_HEIGHT: int = 80

# --- Private Variables ---

var _pragmant_label: Label = null
var _tree_section: VBoxContainer = null
var _info_line: RichTextLabel = null
var _main_content: VBoxContainer = null
var _map: Variant = null
var _return_screen: String = ""


# --- Virtual Methods ---

func enter(previous: String, data: Dictionary = {}) -> void:
	super.enter(previous, data)
	_map = data.get("map", null)
	_return_screen = data.get("return_to", GameManager.SCENE_MAP) as String
	_build_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_done()
		get_viewport().set_input_as_handled()


# --- Private Methods: UI Construction ---

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Background
	var bg := ColorRect.new()
	bg.color = ThemeManager.COLOR_VOID
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	ThemeManager.build_unicode_grid(self, "brainstem", 4, 0.02)

	# Scroll wrapper
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	scroll.add_child(margin)

	_main_content = VBoxContainer.new()
	_main_content.add_theme_constant_override("separation", 16)
	_main_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_main_content)

	# Header
	var header := Label.new()
	header.text = "\u2550\u2550\u2550 MORPHEME VAULT \u2550\u2550\u2550"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(header, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(header, ThemeManager.COLOR_GOLD)
	_main_content.add_child(header)

	# Pragmant balance
	_pragmant_label = Label.new()
	_pragmant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(_pragmant_label, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(_pragmant_label, ThemeManager.COLOR_GOLD)
	_main_content.add_child(_pragmant_label)
	_update_pragmant_display()

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Spend pragmant to permanently unlock root morphemes for future runs."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(subtitle, ThemeManager.FONT_MICRO)
	subtitle.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	_main_content.add_child(subtitle)

	_add_separator()

	# Tree section (holds tier rows)
	_tree_section = VBoxContainer.new()
	_tree_section.add_theme_constant_override("separation", 24)
	_tree_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_content.add_child(_tree_section)

	_rebuild_tree()

	_add_separator()

	# Info line
	_info_line = RichTextLabel.new()
	_info_line.bbcode_enabled = true
	_info_line.fit_content = true
	_info_line.scroll_active = false
	_info_line.custom_minimum_size = Vector2(0, 20)
	_info_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeManager.apply_mono_font_rtl(_info_line, ThemeManager.FONT_MICRO)
	_info_line.text = ""
	_main_content.add_child(_info_line)

	# Done button
	var bottom_row := HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_content.add_child(bottom_row)

	var done_btn := Button.new()
	done_btn.text = "[ DONE ]"
	done_btn.custom_minimum_size = Vector2(200, 44)
	done_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ThemeManager.apply_mono_font(done_btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(done_btn, ThemeManager.COLOR_TEXT_DIM)
	done_btn.pressed.connect(_on_done)
	bottom_row.add_child(done_btn)


# --- Private Methods: Tree ---

func _rebuild_tree() -> void:
	for child: Node in _tree_section.get_children():
		child.queue_free()

	# Build a flat list of unlockable roots grouped by tier.
	# For now, load all morpheme roots and assign tiers by rarity.
	var all_morphemes: Array[MorphemeData] = _load_unlockable_roots()
	if all_morphemes.is_empty():
		var empty_label := Label.new()
		empty_label.text = "(no roots available for unlock)"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeManager.apply_mono_font(empty_label, ThemeManager.FONT_MICRO)
		empty_label.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
		_tree_section.add_child(empty_label)
		return

	# Group by tier (rarity ordinal maps to tier)
	var tiers: Dictionary = {}
	for m: MorphemeData in all_morphemes:
		var tier: int = clampi(m.rarity, 0, TIER_COSTS.size() - 1)
		if not tiers.has(tier):
			tiers[tier] = []
		tiers[tier].append(m)

	for tier_num: int in range(TIER_COSTS.size()):
		if not tiers.has(tier_num):
			continue

		var tier_morphemes: Array = tiers[tier_num]
		var cost: int = TIER_COSTS[tier_num]

		# Tier header
		var tier_header := Label.new()
		if tier_num == 0:
			tier_header.text = "\u2502 TIER %d (STARTER)" % tier_num
		else:
			tier_header.text = "\u2502 TIER %d  \u2014  \u20b1%d per root" % [tier_num, cost]
		ThemeManager.apply_mono_font(tier_header, ThemeManager.FONT_BODY)
		ThemeManager.apply_glow_text(tier_header, ThemeManager.COLOR_GOLD)
		_tree_section.add_child(tier_header)

		# Grid of root cards
		var grid := GridContainer.new()
		grid.columns = 6
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_tree_section.add_child(grid)

		for m: MorphemeData in tier_morphemes:
			var card: PanelContainer = _build_root_card(m, tier_num, cost)
			grid.add_child(card)


func _build_root_card(m: MorphemeData, tier: int, cost: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(NODE_WIDTH, NODE_HEIGHT)

	var is_unlocked: bool = tier == 0 or GameManager.is_root_unlocked(m.root_text)
	var can_afford: bool = GameManager.meta_pragmant >= cost
	var can_buy: bool = not is_unlocked and cost > 0 and can_afford

	# Colors
	var pos_name: String = Enums.POSType.keys()[m.pos_type]
	var border_color: Color = ThemeManager.COLOR_TEXT_DIM
	var bg_color: Color = ThemeManager.COLOR_PANEL

	if is_unlocked:
		border_color = ThemeManager.COLOR_SUCCESS
		bg_color = COLOR_OWNED
	elif can_buy:
		border_color = ThemeManager.COLOR_WARNING
	else:
		border_color = COLOR_LOCKED_DIM

	ThemeManager.apply_panel_style(panel, bg_color, border_color, 2)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	# Root text
	var form_label := Label.new()
	form_label.text = m.root_text if m.root_text != "" else m.id
	form_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(form_label, ThemeManager.FONT_H1)
	if is_unlocked:
		ThemeManager.apply_glow_text(form_label, ThemeManager.COLOR_SUCCESS)
	elif can_buy:
		form_label.add_theme_color_override("font_color", ThemeManager.COLOR_WARNING)
	else:
		form_label.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	vbox.add_child(form_label)

	# POS label
	var type_label := Label.new()
	type_label.text = pos_name
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(type_label, ThemeManager.FONT_MICRO)
	type_label.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	vbox.add_child(type_label)

	# Status line
	if is_unlocked:
		var owned_label := Label.new()
		owned_label.text = "OWNED"
		owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeManager.apply_mono_font(owned_label, ThemeManager.FONT_MICRO)
		owned_label.add_theme_color_override("font_color", ThemeManager.COLOR_SUCCESS)
		vbox.add_child(owned_label)
	elif cost > 0:
		var buy_btn := Button.new()
		buy_btn.text = "\u20b1%d" % cost
		buy_btn.disabled = not can_afford
		buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		ThemeManager.apply_mono_font(buy_btn, ThemeManager.FONT_MICRO)
		if can_afford:
			ThemeManager.apply_button_style(buy_btn, ThemeManager.COLOR_GOLD)
		else:
			ThemeManager.apply_button_style(buy_btn, ThemeManager.COLOR_ALERT)
			buy_btn.add_theme_color_override("font_color", ThemeManager.COLOR_ALERT.darkened(0.3))
		buy_btn.pressed.connect(_on_buy_root.bind(m.root_text, cost))
		vbox.add_child(buy_btn)

	# Hover info
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_entered.connect(_on_card_hover.bind(m, tier))
	panel.mouse_exited.connect(_clear_info_line)

	return panel


# --- Private Methods: Data ---

func _load_unlockable_roots() -> Array[MorphemeData]:
	## Load all root morphemes from the morpheme data directory.
	var morphemes: Array[MorphemeData] = []
	var dir := DirAccess.open(GameManager.MORPHEME_DATA_DIR)
	if not dir:
		return morphemes

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path: String = GameManager.MORPHEME_DATA_DIR + file_name
			var res: MorphemeData = load(path) as MorphemeData
			if res and res.type == MorphemeData.MorphemeType.ROOT:
				morphemes.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()

	return morphemes


# --- Private Methods: Actions ---

func _on_buy_root(form: String, cost: int) -> void:
	if GameManager.meta_pragmant < cost:
		return
	if GameManager.is_root_unlocked(form):
		return

	GameManager.meta_pragmant -= cost
	GameManager.unlock_root(form)
	SaveManager.save_meta()
	_update_pragmant_display()
	_rebuild_tree()


func _on_done() -> void:
	var data: Dictionary = {}
	if _map != null:
		data["map"] = _map
	finished.emit(_return_screen, data)


# --- Private Methods: Display Helpers ---

func _update_pragmant_display() -> void:
	if _pragmant_label != null:
		_pragmant_label.text = "\u20b1%d" % GameManager.meta_pragmant


func _on_card_hover(m: MorphemeData, tier: int) -> void:
	if _info_line == null:
		return
	var pos_name: String = Enums.POSType.keys()[m.pos_type]
	var family_name: String = Enums.MorphemeFamily.keys()[m.family]
	var rarity_name: String = MorphemeData.Rarity.keys()[m.rarity]
	var info: String = "[center]%s  |  POS: [color=#%s]%s[/color]  |  family: [color=#%s]%s[/color]  |  rarity: [color=#%s]%s[/color]  |  induction: [color=#%s]%d[/color]  |  tier: [color=#%s]%d[/color][/center]" % [
		m.root_text,
		ThemeManager.COLOR_WARNING.to_html(false), pos_name,
		ThemeManager.COLOR_GOLD.to_html(false), family_name,
		ThemeManager.COLOR_SHIELD.to_html(false), rarity_name,
		ThemeManager.COLOR_WARNING.to_html(false), m.base_induction,
		ThemeManager.COLOR_GOLD.to_html(false), tier,
	]
	_info_line.clear()
	_info_line.append_text(info)


func _clear_info_line() -> void:
	if _info_line != null:
		_info_line.clear()
		_info_line.text = ""


func _add_separator() -> void:
	var sep := Label.new()
	sep.text = "\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(sep, ThemeManager.FONT_MICRO)
	sep.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	_main_content.add_child(sep)
