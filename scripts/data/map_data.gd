class_name MapData
extends RefCounted

## Procedural region map generator (StS-style DAG).
## 17-column branching path per region with weighted node type distribution,
## minimum guarantees, and mark/visit progression logic.

# --- Enums ---

enum NodeType { SYNAPSE, LESION, GANGLION, MYELIN, APHASIA, BOSS }

# --- Constants ---

const COLUMNS: int = 17

const NODE_TYPE_NAMES: Dictionary = {
	NodeType.SYNAPSE: "SYNAPSE",
	NodeType.LESION: "LESION",
	NodeType.GANGLION: "GANGLION",
	NodeType.MYELIN: "MYELIN",
	NodeType.APHASIA: "APHASIA",
	NodeType.BOSS: "BOSS",
}

const NODE_TYPE_ABBREVS: Dictionary = {
	NodeType.SYNAPSE: "SYN",
	NodeType.LESION: "LES",
	NodeType.GANGLION: "GAN",
	NodeType.MYELIN: "MYE",
	NodeType.APHASIA: "APH",
	NodeType.BOSS: "BOS",
}

# Column-depth type pools (weighted by repetition)
const _POOL_EARLY: Array[NodeType] = [
	NodeType.SYNAPSE, NodeType.SYNAPSE, NodeType.SYNAPSE, NodeType.SYNAPSE,
	NodeType.APHASIA, NodeType.APHASIA,
	NodeType.GANGLION,
]

const _POOL_MID_EARLY: Array[NodeType] = [
	NodeType.SYNAPSE, NodeType.SYNAPSE, NodeType.SYNAPSE,
	NodeType.LESION,
	NodeType.GANGLION,
	NodeType.MYELIN,
	NodeType.APHASIA,
]

const _POOL_MID: Array[NodeType] = [
	NodeType.SYNAPSE, NodeType.SYNAPSE, NodeType.SYNAPSE,
	NodeType.LESION, NodeType.LESION,
	NodeType.GANGLION,
	NodeType.APHASIA,
]

const _POOL_MID_LATE: Array[NodeType] = [
	NodeType.SYNAPSE, NodeType.SYNAPSE,
	NodeType.LESION, NodeType.LESION, NodeType.LESION,
	NodeType.MYELIN,
	NodeType.APHASIA,
]

const _POOL_LATE: Array[NodeType] = [
	NodeType.SYNAPSE, NodeType.SYNAPSE, NodeType.SYNAPSE,
	NodeType.LESION, NodeType.LESION, NodeType.LESION,
	NodeType.MYELIN,
]

# --- Public Variables ---

var nodes: Array[Dictionary] = []
var region: RegionData = null

# --- Private Variables ---

var _node_lookup: Dictionary = {}  # id -> node Dictionary


# --- Static Factory ---

static func generate(p_region: RegionData) -> MapData:
	var map := MapData.new()
	map.region = p_region
	map._generate_dag()

	# Mark first column as available
	for node: Dictionary in map.nodes:
		if node["column"] == 0:
			node["is_available"] = true

	return map


# --- Public Methods ---

func get_node_by_id(id: int) -> Dictionary:
	if _node_lookup.has(id):
		return _node_lookup[id]
	return {}


func mark_visited(id: int) -> void:
	var node: Dictionary = get_node_by_id(id)
	if node.is_empty():
		return

	node["is_visited"] = true
	node["is_available"] = false

	# Unlock connected nodes
	var connections: Array = node["connections"]
	for conn_id: Variant in connections:
		var conn: Dictionary = get_node_by_id(int(conn_id))
		if conn.is_empty():
			continue
		if not conn["is_visited"]:
			conn["is_available"] = true

	# Lock all other unvisited nodes at or before this column
	var visited_col: int = node["column"]
	for other: Dictionary in nodes:
		if other["id"] == id:
			continue
		if other["is_visited"]:
			continue
		var is_connected: bool = other["id"] in connections
		if not is_connected and other["column"] <= visited_col:
			other["is_available"] = false


func get_available_nodes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node: Dictionary in nodes:
		if node["is_available"] and not node["is_visited"]:
			result.append(node)
	return result


func get_nodes_in_column(col: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node: Dictionary in nodes:
		if node["column"] == col:
			result.append(node)
	return result


func is_region_complete() -> bool:
	for node: Dictionary in nodes:
		if node["column"] == COLUMNS - 1 and node["is_visited"]:
			return true
	return false


func get_furthest_visited_column() -> int:
	var furthest: int = -1
	for node: Dictionary in nodes:
		if node["is_visited"] and node["column"] > furthest:
			furthest = node["column"]
	return furthest


# --- Private Methods ---

func _generate_dag() -> void:
	var next_id: int = 0
	var column_ids: Array[Array] = []

	for col: int in range(COLUMNS):
		var col_ids: Array[int] = []
		var num_rows: int = 0

		if col == 0:
			# Entry: 2-3 synapse nodes
			num_rows = randi_range(2, 3)
			for row: int in range(num_rows):
				_add_node(next_id, NodeType.SYNAPSE, col, row)
				col_ids.append(next_id)
				next_id += 1

		elif col <= 14:
			# Middle columns: type from depth pool
			num_rows = randi_range(2, 3) if col <= 5 else randi_range(2, 4)
			var pool: Array[NodeType] = _get_pool_for_column(col)
			for row: int in range(num_rows):
				var node_type: NodeType = pool[randi() % pool.size()]
				_add_node(next_id, node_type, col, row)
				col_ids.append(next_id)
				next_id += 1

		elif col == 15:
			# Pre-boss funnel: 2 synapse nodes
			num_rows = 2
			for row: int in range(num_rows):
				_add_node(next_id, NodeType.SYNAPSE, col, row)
				col_ids.append(next_id)
				next_id += 1

		elif col == 16:
			# Boss: single node
			_add_node(next_id, NodeType.BOSS, col, 0)
			col_ids.append(next_id)
			next_id += 1

		column_ids.append(col_ids)

	_wire_connections(column_ids)
	_enforce_minimums()


func _add_node(id: int, type: NodeType, col: int, row: int) -> void:
	var node: Dictionary = {
		"id": id,
		"type": type,
		"column": col,
		"row": row,
		"connections": [],
		"is_visited": false,
		"is_available": false,
	}
	nodes.append(node)
	_node_lookup[id] = node


func _wire_connections(column_ids: Array[Array]) -> void:
	for col: int in range(COLUMNS - 1):
		var cur_ids: Array = column_ids[col]
		var next_ids: Array = column_ids[col + 1]
		var targeted: Dictionary = {}

		for node_id: Variant in cur_ids:
			var node: Dictionary = get_node_by_id(int(node_id))
			var node_row: int = node["row"]
			var num_connections: int = randi_range(1, mini(2, next_ids.size()))

			# Build preference-sorted targets: same row, adjacent, then rest
			var sorted_targets: Array[int] = []
			var same_row: Array[int] = []
			var adjacent: Array[int] = []
			var other: Array[int] = []

			for tid: Variant in next_ids:
				var tnode: Dictionary = get_node_by_id(int(tid))
				var trow: int = tnode["row"]
				if trow == node_row:
					same_row.append(int(tid))
				elif absi(trow - node_row) == 1:
					adjacent.append(int(tid))
				else:
					other.append(int(tid))

			same_row.shuffle()
			adjacent.shuffle()
			other.shuffle()
			sorted_targets.append_array(same_row)
			sorted_targets.append_array(adjacent)
			sorted_targets.append_array(other)

			var connected: int = 0
			for tid: int in sorted_targets:
				if connected >= num_connections:
					break
				if tid not in node["connections"]:
					node["connections"].append(tid)
					targeted[tid] = true
					connected += 1

		# Ensure every next-column node has at least one incoming connection
		for tid: Variant in next_ids:
			if not targeted.has(int(tid)):
				var source_id: int = cur_ids[randi() % cur_ids.size()]
				var source_node: Dictionary = get_node_by_id(int(source_id))
				if int(tid) not in source_node["connections"]:
					source_node["connections"].append(int(tid))


func _get_pool_for_column(col: int) -> Array[NodeType]:
	if col <= 3:
		return _POOL_EARLY
	if col <= 6:
		return _POOL_MID_EARLY
	if col <= 9:
		return _POOL_MID
	if col <= 12:
		return _POOL_MID_LATE
	return _POOL_LATE


func _enforce_minimums() -> void:
	var ganglion_count: int = 0
	var myelin_count: int = 0
	var lesion_count: int = 0

	for node: Dictionary in nodes:
		var col: int = node["column"]
		if col < 1 or col > 14:
			continue
		var t: NodeType = node["type"]
		if t == NodeType.GANGLION:
			ganglion_count += 1
		elif t == NodeType.MYELIN:
			myelin_count += 1
		elif t == NodeType.LESION:
			lesion_count += 1

	var needed_ganglion: int = maxi(0, 3 - ganglion_count)
	if needed_ganglion > 0:
		_inject_type(NodeType.GANGLION, needed_ganglion, 2, 13)

	var needed_myelin: int = maxi(0, 3 - myelin_count)
	if needed_myelin > 0:
		_inject_type(NodeType.MYELIN, needed_myelin, 3, 14)

	var needed_lesion: int = maxi(0, 4 - lesion_count)
	if needed_lesion > 0:
		_inject_type(NodeType.LESION, needed_lesion, 1, 14)


func _inject_type(target_type: NodeType, count: int, min_col: int, max_col: int) -> void:
	var candidates: Array[Dictionary] = []
	for node: Dictionary in nodes:
		var col: int = node["column"]
		if col >= min_col and col <= max_col and node["type"] == NodeType.SYNAPSE:
			candidates.append(node)

	candidates.shuffle()

	# First pass: spread across different columns
	var used_columns: Dictionary = {}
	var injected: int = 0

	for node: Dictionary in candidates:
		if injected >= count:
			break
		if not used_columns.has(node["column"]):
			node["type"] = target_type
			used_columns[node["column"]] = true
			injected += 1

	# Second pass: fill remaining from any synapse candidate
	if injected < count:
		for node: Dictionary in candidates:
			if injected >= count:
				break
			if node["type"] == NodeType.SYNAPSE:
				node["type"] = target_type
				injected += 1
