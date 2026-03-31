class_name CharacterData
extends Resource

## A playable character (language persona). Each has a unique passive,
## family restrictions, and starting stats. 5 total.

# --- Exports: Identity ---

## Unique string identifier (e.g. "english", "french", "old_english")
@export var id: String = ""

## Human-readable name shown in UI (e.g. "Frankie", "Ellie")
@export var display_name: String = ""

## Language this character represents (e.g. "English", "French")
@export var language: String = ""

# --- Exports: Passive ---

## Name of this character's passive ability (e.g. "Lingua Franca")
@export var passive_name: String = ""

## Human-readable description of the passive
@export_multiline var passive_description: String = ""

## Effect resources implementing the passive (registered at combat start)
@export var passive_effects: Array[Effect] = []

# --- Exports: Family Restrictions ---

## This character's primary morpheme family
@export var primary_family: Enums.MorphemeFamily = Enums.MorphemeFamily.GERMANIC

## Families this character may use without penalty. Empty = all allowed.
@export var allowed_families: Array[Enums.MorphemeFamily] = []

# --- Exports: Starting Stats ---

## Starting and max cogency (health) for a run
@export_range(1, 200) var starter_cogency: int = 50

## Number of morphemes drawn at turn start
@export_range(1, 15) var starter_hand_size: int = 7

# --- Exports: Visual ---

## Character color used for UI accents
@export var color: Color = Color.WHITE

## ASCII art representation on character select screen
@export_multiline var ascii_art: String = ""

# --- Exports: Unlock ---

## Condition string for unlocking (e.g. "starter", "region_1", "victory")
@export var unlock_condition: String = "starter"

## Human-readable unlock requirement text (e.g. "CLEAR ACT 1")
@export var unlock_description: String = ""


# --- Public Methods ---

## Returns true if the given family is allowed for this character.
func is_family_allowed(morph_family: Enums.MorphemeFamily) -> bool:
	if allowed_families.is_empty():
		return true
	return morph_family in allowed_families


## Returns true if the given morpheme can be used by this character.
## Functional morphemes bypass family restrictions.
func is_morpheme_allowed(m: MorphemeData) -> bool:
	if m.combat_role == MorphemeData.CombatRole.FUNCTIONAL:
		return true
	return is_family_allowed(m.family)
