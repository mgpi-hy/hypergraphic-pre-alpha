class_name EnemyData
extends Resource

## An enemy (pathology) definition. Stats, intent patterns, mechanics,
## phase transitions, and visual properties.

# --- Enums ---

enum Tier { SYNAPSE, LESION, BOSS }

enum IntentType { ATTACK, DEFEND, BUFF, DRAIN, SCRAMBLE, SILENCE, LOCK }

# --- Exports: Identity ---

## Unique string identifier (e.g. "solecism", "brocas_aphasia")
@export var id: String = ""

## Human-readable name shown in UI (e.g. "SOLECISM", "BROCA'S APHASIA")
@export var display_name: String = ""

## Enemy tier: synapse (basic), lesion (elite), boss
@export var tier: Tier = Tier.SYNAPSE

# --- Exports: Combat Stats ---

## Enemy health (reduce to 0 to defeat)
@export_range(1, 999) var cogency: int = 75

## Base damage per attack intent
@export_range(0, 50) var base_damage: int = 6

## Damage scaling factor per floor beyond first appearance
@export_range(0, 10) var scaling_factor: int = 2

## Floor number where this enemy first appears (for scaling)
@export var first_floor: int = 1

# --- Exports: Intent ---

## Pool of intents this enemy cycles through.
## Each entry: {"type": IntentType, "value": int}
@export var intent_pool: Array[Dictionary] = []

# --- Exports: Mechanic ---

## Special mechanic ID (e.g. "swap_pos", "lock_slot", "grow_branch")
@export var mechanic: String = ""

## Turns between mechanic triggers
@export_range(1, 10) var mechanic_interval: int = 3

# --- Exports: Phase Transitions ---

## HP ratio threshold to trigger single phase change (0.0 to disable)
@export_range(0.0, 1.0, 0.05) var phase_threshold: float = 0.5

## Mechanic activated at phase threshold
@export var phase_mechanic: String = ""

## Flavor text shown on phase change
@export var phase_text: String = ""

## Multi-phase support: HP ratio thresholds (overrides single-phase if non-empty)
@export var phase_thresholds: Array[float] = []

## Multi-phase support: mechanics per phase (parallel with phase_thresholds)
@export var phase_mechanics: Array[String] = []

## Multi-phase support: flavor texts per phase (parallel with phase_thresholds)
@export var phase_texts: Array[String] = []

# --- Exports: Immunities ---

## Effect name this enemy is immune to (empty = none)
@export var effect_immunity: String = ""

## Effect name this enemy reflects back at player (empty = none)
@export var effect_reflect: String = ""

# --- Exports: Visual ---

## Enemy color for UI and glitch art
@export var color: Color = Color("#FF1E40")

## Density of glitch characters in ASCII art (0.0 to 1.0)
@export_range(0.0, 1.0, 0.05) var glitch_density: float = 0.3


# --- Public Methods ---

## Scale cogency and base_damage for floor progression.
## Increases by ~12% per floor beyond first appearance.
func scale_for_floor(floor_num: int) -> void:
	var floors_beyond: int = maxi(floor_num - first_floor, 0)
	if floors_beyond <= 0:
		return
	var scale: float = 1.0 + 0.12 * floors_beyond
	cogency = roundi(cogency * scale)
	base_damage = roundi(base_damage * scale)
