class_name MapScreen
extends ScreenState

## Map screen: renders the 17-column DAG for the current region.
## Nodes are clickable buttons with type abbreviations, color-coded,
## connected by Line2D paths. Available nodes pulse; visited nodes dim.

# --- Constants ---

const NODE_COLORS: Dictionary = {
	MapData.NodeType.SYNAPSE: Color("#FF1E40"),
	MapData.NodeType.LESION: Color("#E040FB"),
	MapData.NodeType.GANGLION: Color("#FFD54F"),
	MapData.NodeType.MYELIN: Color("#00F090"),
	MapData.NodeType.APHASIA: ThemeManager.COLOR_INSULATION,
	MapData.NodeType.BOSS: Color("#FF1E40"),
}

const NODE_TOOLTIPS: Dictionary = {
	MapData.NodeType.SYNAPSE: "SYNAPSE: Standard combat. Defeat enemies for semant and morphemes.",
	MapData.NodeType.LESION: "LESION: Elite combat. Harder enemies, better rewards.",
	MapData.NodeType.GANGLION: "GANGLION: Shop. Buy morphemes, phonemes, or remove cards.",
	MapData.NodeType.MYELIN: "MYELIN: Rest stop. Heal, upgrade a morpheme, or train.",
	MapData.NodeType.APHASIA: "APHASIA: Random event. Choices with risk and reward.",
	MapData.NodeType.BOSS: "BOSS: Region guardian. Must defeat to advance.",
}

const NODE_WIDTH: int = 44
const NODE_HEIGHT: int = 40
const COLUMN_SPACING: int = 95
const ROW_SPACING: int = 80
const MAP_OFFSET_X: int = 60
const MAP_OFFSET_Y: int = 20

# --- Private Variables ---

var _map: MapData = null
var _pulse_time: float = 0.0
var _node_pressed: bool = false

var _header_label: Label = null
var _region_label: Label = null
var _scroll_container: ScrollContainer = null
var _map_content: Control = null
var _line_container: Node2D = null
var _cogency_label: Label = null
var _semant_label: Label = null
var _deck_label: Label = null
var _floor_label: Label = null
var _bottom_bar: HBoxContainer = null
var _node_buttons: Array[Button] = []
var _node_id_map: Dictionary = {}  # Button -> int (node id)
var _cached_enemies: Array[EnemyData] = []


# --- Virtual Methods ---

func enter(previous: String, data: Dictionary = {}) -> void:
	super.enter(previous, data)
	_map = data.get("map", null) as MapData
	if _map == null:
		push_error("MapScreen.enter: no MapData in data dict")
		finished.emit("res://scenes/screens/title_screen.tscn", {})
		return
	_load_enemy_pool()
	_build_ui()
	_populate_map()
	if GameManager.run != null:
		_update_bottom_bar_from_run(GameManager.run)
	# Deferred so layout has computed sizes before we read _scroll_container.size.x
	call_deferred("_auto_scroll_to_available")


func exit() -> void:
	super.exit()


func _process(delta: float) -> void:
	if _map == null:
		return
	_pulse_time += delta
	_animate_pulses()


# --- Private Methods: UI Construction ---

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = ThemeManager.COLOR_VOID
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Region grid background
	var region_name: String = _get_region_display_name()
	ThemeManager.build_unicode_grid(self, region_name, 5, 0.05)

	# Header
	_header_label = Label.new()
	var current_col: int = _map.get_furthest_visited_column() + 1
	_header_label.text = "%s  |  COLUMN %d / %d" % [
		region_name.to_upper(), maxi(current_col, 1), MapData.COLUMNS,
	]
	_header_label.position = Vector2(40, 20)
	ThemeManager.apply_mono_font(_header_label, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(_header_label, ThemeManager.COLOR_TEXT_MAIN)
	add_child(_header_label)

	# Region subtitle
	_region_label = Label.new()
	var subtitle: String = region_name
	if _map.region != null and _map.region.modifier_name != "":
		subtitle += "  [%s]" % _map.region.modifier_name
	_region_label.text = subtitle
	_region_label.position = Vector2(40, 48)
	ThemeManager.apply_mono_font(_region_label, ThemeManager.FONT_BODY)
	var region_color: Color = _get_region_color()
	ThemeManager.apply_glow_text(_region_label, region_color)
	add_child(_region_label)

	# Scroll container for the map
	_scroll_container = ScrollContainer.new()
	_scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll_container.offset_top = 80
	_scroll_container.offset_bottom = -60
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll_container)

	# Map content inside scroll
	_map_content = Control.new()
	_scroll_container.add_child(_map_content)

	# Line container (behind nodes)
	_line_container = Node2D.new()
	_map_content.add_child(_line_container)

	# Bottom bar
	_build_bottom_bar()


func _build_bottom_bar() -> void:
	_bottom_bar = HBoxContainer.new()
	_bottom_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_bar.offset_top = -50
	_bottom_bar.offset_left = 40
	_bottom_bar.offset_right = -40
	_bottom_bar.add_theme_constant_override("separation", 40)
	add_child(_bottom_bar)

	_cogency_label = _make_stat_label(ThemeManager.COLOR_SUCCESS)
	_bottom_bar.add_child(_cogency_label)

	_semant_label = _make_stat_label(ThemeManager.COLOR_INSULATION)
	_bottom_bar.add_child(_semant_label)

	_deck_label = _make_stat_label(ThemeManager.COLOR_TEXT_DIM)
	_bottom_bar.add_child(_deck_label)

	_floor_label = _make_stat_label(ThemeManager.COLOR_TEXT_DIM)
	_bottom_bar.add_child(_floor_label)

	_update_bottom_bar()


func _make_stat_label(color: Color) -> Label:
	var label := Label.new()
	ThemeManager.apply_mono_font(label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(label, color)
	return label


func _update_bottom_bar() -> void:
	_cogency_label.text = "COG: --/--"
	_semant_label.text = "\u00A7--"
	_deck_label.text = "DECK: --"
	_floor_label.text = ""


func _update_bottom_bar_from_run(run: RunData) -> void:
	_cogency_label.text = "COG: %d/%d" % [run.cogency, run.max_cogency]
	_semant_label.text = "\u00A7%d" % run.semant
	_deck_label.text = "DECK: %d" % run.deck.size()
	_floor_label.text = "Region %d/4  |  Floor %d" % [
		run.current_region_index + 1, run.get_equivalent_floor(),
	]


# --- Private Methods: Map Rendering ---

func _populate_map() -> void:
	# Size map content to fit all columns
	var content_width: float = MAP_OFFSET_X * 2.0 + MapData.COLUMNS * COLUMN_SPACING
	var content_height: float = _scroll_container.size.y
	if content_height <= 0.0:
		content_height = 500.0
	_map_content.custom_minimum_size = Vector2(content_width, content_height)

	# Draw connection lines first (behind nodes)
	for node: Dictionary in _map.nodes:
		var from_pos: Vector2 = _get_node_center(node["column"], node["row"])
		var connections: Array = node["connections"]
		for conn_id: Variant in connections:
			var conn: Dictionary = _map.get_node_by_id(int(conn_id))
			if conn.is_empty():
				continue
			var to_pos: Vector2 = _get_node_center(conn["column"], conn["row"])
			_draw_connection_line(from_pos, to_pos, node["is_visited"])

	# Draw node buttons
	for node: Dictionary in _map.nodes:
		_create_node_button(node)


func _draw_connection_line(from: Vector2, to: Vector2, is_visited: bool) -> void:
	var line := Line2D.new()
	line.points = [from, to]
	line.width = 2.0
	line.antialiased = true
	var color: Color = ThemeManager.COLOR_TEXT_DIM
	if is_visited:
		color = color.darkened(0.5)
	line.default_color = color
	_line_container.add_child(line)


func _create_node_button(node: Dictionary) -> void:
	var node_type: MapData.NodeType = node["type"] as MapData.NodeType
	var color: Color = NODE_COLORS.get(node_type, ThemeManager.COLOR_TEXT_DIM)
	var abbrev: String = MapData.NODE_TYPE_ABBREVS.get(node_type, "???")
	var is_visited: bool = node["is_visited"]
	var is_available: bool = node["is_available"]
	var pos: Vector2 = _get_node_position(node["column"], node["row"])
	var furthest_col: int = _map.get_furthest_visited_column()
	var is_current: bool = is_visited and node["column"] == furthest_col

	var btn := Button.new()
	btn.position = pos
	btn.text = abbrev
	btn.clip_text = false
	ThemeManager.apply_mono_font(btn, ThemeManager.FONT_MICRO)

	# Size (boss nodes slightly larger)
	var btn_width: int = NODE_WIDTH + 20 if node_type == MapData.NodeType.BOSS else NODE_WIDTH
	var btn_height: int = NODE_HEIGHT + 10 if node_type == MapData.NodeType.BOSS else NODE_HEIGHT
	btn.custom_minimum_size = Vector2(btn_width, btn_height)
	btn.size = Vector2(btn_width, btn_height)

	# Styling
	var normal := StyleBoxFlat.new()
	normal.set_corner_radius_all(0)
	normal.content_margin_left = 2
	normal.content_margin_right = 2
	normal.content_margin_top = 2
	normal.content_margin_bottom = 2

	if is_current:
		normal.bg_color = ThemeManager.COLOR_PANEL.lightened(0.05)
		normal.border_color = ThemeManager.COLOR_SUCCESS
		normal.set_border_width_all(3)
		btn.add_theme_color_override("font_color", ThemeManager.COLOR_SUCCESS)
		btn.disabled = true
	elif is_visited:
		normal.bg_color = ThemeManager.COLOR_PANEL.darkened(0.3)
		normal.border_color = color.darkened(0.6)
		normal.set_border_width_all(1)
		btn.add_theme_color_override("font_color", color.darkened(0.5))
		btn.disabled = true
	elif is_available:
		normal.bg_color = ThemeManager.COLOR_PANEL
		normal.border_color = color
		normal.set_border_width_all(2)
		btn.add_theme_color_override("font_color", color)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		normal.bg_color = ThemeManager.COLOR_PANEL.darkened(0.2)
		normal.border_color = ThemeManager.COLOR_TEXT_DIM.darkened(0.3)
		normal.set_border_width_all(1)
		btn.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM.darkened(0.3))
		btn.disabled = true

	btn.add_theme_stylebox_override("normal", normal)

	# Hover/pressed for available nodes
	if is_available and not is_visited:
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = ThemeManager.COLOR_PANEL.lightened(0.08)
		hover.border_color = color.lightened(0.3)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_color_override("font_hover_color", color.lightened(0.3))

		var pressed := normal.duplicate() as StyleBoxFlat
		pressed.bg_color = color.darkened(0.7)
		btn.add_theme_stylebox_override("pressed", pressed)

	# Disabled style preserves font color
	var disabled_style := normal.duplicate() as StyleBoxFlat
	btn.add_theme_stylebox_override("disabled", disabled_style)
	btn.add_theme_color_override("font_disabled_color", btn.get_theme_color("font_color"))

	# Tooltip
	btn.tooltip_text = NODE_TOOLTIPS.get(node_type, "")

	# "YOU ARE HERE" marker
	if is_current:
		var marker := Label.new()
		marker.text = "\u25C6"
		ThemeManager.apply_mono_font(marker, ThemeManager.FONT_BODY)
		ThemeManager.apply_glow_text(marker, ThemeManager.COLOR_SUCCESS)
		marker.position = Vector2(
			pos.x + float(btn_width) + 4.0,
			pos.y + (float(btn_height) - 20.0) / 2.0,
		)
		_map_content.add_child(marker)

	_map_content.add_child(btn)
	_node_buttons.append(btn)
	_node_id_map[btn] = node["id"]

	if is_available and not is_visited:
		btn.pressed.connect(_on_node_pressed.bind(node["id"]))


# --- Private Methods: Interaction ---

func _on_node_pressed(node_id: int) -> void:
	if _node_pressed:
		return
	var node: Dictionary = _map.get_node_by_id(node_id)
	if node.is_empty():
		return
	_node_pressed = true

	_map.mark_visited(node_id)

	# Track column for floor display and enemy scaling
	if GameManager.run:
		GameManager.run.current_column = node.get("column", 0)

	var node_type: MapData.NodeType = node["type"] as MapData.NodeType
	var next_screen: String = _get_screen_for_type(node_type)
	var data: Dictionary = _build_transition_data(node)
	finished.emit(next_screen, data)


func _get_screen_for_type(node_type: MapData.NodeType) -> String:
	match node_type:
		MapData.NodeType.SYNAPSE:
			return "res://scenes/combat/combat_screen.tscn"
		MapData.NodeType.LESION:
			return "res://scenes/combat/combat_screen.tscn"
		MapData.NodeType.GANGLION:
			return "res://scenes/screens/shop_screen.tscn"
		MapData.NodeType.MYELIN:
			return "res://scenes/screens/rest_screen.tscn"
		MapData.NodeType.APHASIA:
			return "res://scenes/screens/event_screen.tscn"
		MapData.NodeType.BOSS:
			return "res://scenes/combat/combat_screen.tscn"
		_:
			push_error("MapScreen: unknown node type %s" % node_type)
			return "res://scenes/screens/map_screen.tscn"


func _build_transition_data(node: Dictionary) -> Dictionary:
	var node_type: MapData.NodeType = node["type"] as MapData.NodeType
	var data: Dictionary = {
		"map": _map,
		"node_type": node_type,
		"column": node["column"],
	}

	match node_type:
		MapData.NodeType.SYNAPSE, MapData.NodeType.LESION, MapData.NodeType.BOSS:
			data["is_elite"] = node_type == MapData.NodeType.LESION
			data["is_boss"] = node_type == MapData.NodeType.BOSS
			data["floor"] = node["column"]
			data["floor_number"] = node["column"]
			data["enemies"] = _generate_enemies_for_node(node_type, node["column"])
			data["region_data"] = _map.region
		MapData.NodeType.GANGLION:
			data["context"] = "shop"
		MapData.NodeType.MYELIN:
			data["context"] = "rest"
		MapData.NodeType.APHASIA:
			data["context"] = "event"

	return data


func _load_enemy_pool() -> void:
	if not _cached_enemies.is_empty():
		return
	var dir := DirAccess.open("res://data/enemies/")
	if not dir:
		push_warning("MapScreen: could not open enemy directory: res://data/enemies/")
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var enemy: EnemyData = load("res://data/enemies/" + file_name) as EnemyData
			if enemy:
				_cached_enemies.append(enemy)
		file_name = dir.get_next()
	dir.list_dir_end()


func _generate_enemies_for_node(node_type: MapData.NodeType, floor_num: int) -> Array:
	## Select enemies appropriate for the combat node type from the cached pool.
	var all_enemies: Array[EnemyData] = _cached_enemies

	if all_enemies.is_empty():
		push_warning("MapScreen: enemy pool is empty")
		return []

	# Filter by tier
	var target_tier: EnemyData.Tier = EnemyData.Tier.SYNAPSE
	match node_type:
		MapData.NodeType.LESION:
			target_tier = EnemyData.Tier.LESION
		MapData.NodeType.BOSS:
			target_tier = EnemyData.Tier.BOSS

	var pool: Array[EnemyData] = []
	for e: EnemyData in all_enemies:
		if e.tier == target_tier:
			pool.append(e)

	if pool.is_empty():
		# Fallback: use any enemy
		pool = all_enemies

	if pool.is_empty():
		return []

	pool.shuffle()

	# Select enemies: 1 for boss, 1-2 for lesion, 1-3 for synapse
	var count: int = 1
	match node_type:
		MapData.NodeType.SYNAPSE:
			count = randi_range(1, mini(3, pool.size()))
		MapData.NodeType.LESION:
			count = randi_range(1, mini(2, pool.size()))
		MapData.NodeType.BOSS:
			count = 1

	var result: Array = []
	for i: int in count:
		var enemy: EnemyData = pool[i % pool.size()].duplicate()
		result.append(enemy)

	return result


# --- Private Methods: Animation ---

func _animate_pulses() -> void:
	for btn: Button in _node_buttons:
		var node_id: int = _node_id_map.get(btn, -1)
		if node_id < 0:
			continue
		var node: Dictionary = _map.get_node_by_id(node_id)
		if node.is_empty():
			continue

		var furthest_col: int = _map.get_furthest_visited_column()
		var is_current: bool = node["is_visited"] and node["column"] == furthest_col

		if is_current:
			var pulse: float = 0.8 + 0.2 * sin(_pulse_time * 2.0)
			btn.modulate.a = pulse
		elif node["is_available"] and not node["is_visited"]:
			var pulse: float = 0.7 + 0.3 * sin(_pulse_time * 3.0)
			btn.modulate.a = pulse


# --- Private Methods: Layout Helpers ---

func _get_node_position(col: int, row: int) -> Vector2:
	var col_nodes: Array[Dictionary] = _map.get_nodes_in_column(col)
	var total_height: float = float(maxi(col_nodes.size(), 1) - 1) * ROW_SPACING
	var available_height: float = _scroll_container.size.y
	if available_height <= 0.0:
		available_height = 500.0
	var start_y: float = MAP_OFFSET_Y + (available_height - total_height - NODE_HEIGHT) / 2.0

	return Vector2(
		MAP_OFFSET_X + col * COLUMN_SPACING,
		start_y + row * ROW_SPACING,
	)


func _get_node_center(col: int, row: int) -> Vector2:
	var pos: Vector2 = _get_node_position(col, row)
	return pos + Vector2(NODE_WIDTH / 2.0, NODE_HEIGHT / 2.0)


func _auto_scroll_to_available() -> void:
	if _scroll_container == null:
		return
	var available: Array[Dictionary] = _map.get_available_nodes()
	var target_col: int = _map.get_furthest_visited_column()
	for node: Dictionary in available:
		if node["column"] < target_col or target_col < 0:
			target_col = node["column"]
	if target_col < 0:
		target_col = 0

	var target_x: float = MAP_OFFSET_X + target_col * COLUMN_SPACING
	var viewport_w: float = _scroll_container.size.x
	var scroll_x: float = maxf(0.0, target_x - viewport_w / 2.0)
	_scroll_container.scroll_horizontal = int(scroll_x)


# --- Private Methods: Region Info ---

func _get_region_display_name() -> String:
	if _map.region != null and _map.region.display_name != "":
		return _map.region.display_name
	return "UNKNOWN REGION"


func _get_region_color() -> Color:
	if _map.region != null:
		return _map.region.color
	return ThemeManager.COLOR_TEXT_DIM
