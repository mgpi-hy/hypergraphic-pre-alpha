class_name RegionData
extends Resource

## A brain region that forms one act of the run.
## Each region is a 17-column StS-style DAG with a boss at column 16.
## 13 total regions, 4 selected per run via branching tree.

# --- Exports: Identity ---

## Unique string identifier (e.g. "brainstem", "temporal_lobe")
@export var id: String = ""

## Human-readable name shown in UI (e.g. "BRAINSTEM", "TEMPORAL LOBE")
@export var display_name: String = ""

## Flavor description of this region
@export_multiline var description: String = ""

# --- Exports: Structure ---

## Boss enemy ID for this region (string reference to EnemyData.id)
@export var boss_id: String = ""

## Region IDs this region can lead to (branching paths)
@export var leads_to: Array[String] = []

## Which act this region belongs to (1-4)
@export_range(1, 4) var act: int = 1

# --- Exports: Modifier ---

## Name of the region modifier (e.g. "Reflex", "Fight or Flight")
@export var modifier_name: String = ""

## Unique ID for the modifier effect
@export var modifier_id: String = ""

## Human-readable modifier description
@export_multiline var modifier_description: String = ""

# --- Exports: Map Generation ---

## Ambient audio mode for this region
@export var ambient_mode: String = ""

## Node type weights for map generation (e.g. {"combat": 0.5, "shop": 0.1})
@export var node_type_weights: Dictionary = {}

# --- Exports: Visual ---

## Region color for UI theming
@export var color: Color = Color.WHITE

## Complexity flag for UI hints ("simple" or "complex")
@export var complexity: String = "simple"
