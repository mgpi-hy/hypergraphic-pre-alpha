class_name RunData
extends RefCounted

## Transient run state for a single roguelite run.
## Not a Resource because it's never saved to disk as .tres;
## it lives in memory and is serialized by SaveManager.

# --- Constants ---

const MAX_GRAPHEMES: int = 10
const MAX_PHONEMES: int = 5

# --- Character ---

## The character selected for this run
var character: CharacterData = null

# --- Player Vitals ---

## Current cogency (health)
var cogency: int = 50

## Maximum cogency (caps healing)
var max_cogency: int = 50

## Current semant (currency for shops/events)
var semant: int = 0

# --- Deck & Inventory ---

## The player's current morpheme deck
var deck: Array[MorphemeData] = []

## Acquired graphemes (passive relics, persist for the run)
var acquired_graphemes: Array[GraphemeData] = []

## Acquired phonemes (consumables)
var acquired_phonemes: Array[PhonemeData] = []

# --- Map Progress ---

## Current region index within the run (0-3)
var current_region_index: int = 0

## Current column within the region's 17-column DAG (0-16)
var current_column: int = 0

## ID of the current region (string reference to RegionData.id)
var current_region_id: String = ""

## Region IDs traversed so far this run
var traversed_regions: Array[String] = []

# --- Combat Stats (accumulated across the run) ---

## Lifetime stats for this run, keyed by stat name.
## Keys: "words_submitted", "turns_survived", "enemies_defeated",
##        "damage_dealt", "novel_words", "rooms_cleared"
var combat_stats: Dictionary = {}

# --- Roots ---

## Root texts the player has used to form words this run (for novel word tracking)
var unlocked_roots: Array[String] = []

## All complete word forms submitted this run, used for cross-combat novel word detection.
var words_used_this_run: Array[String] = []

# --- Next-Combat Bonuses (from events/rest) ---

## Extra insulation granted at next combat start
var next_combat_extra_insulation: int = 0

## Extra morphemes drawn at next combat start
var next_combat_extra_draw: int = 0

# --- Run Metadata ---

## Skipped morpheme IDs (for run summary "Fragments Lost")
var skipped_morphemes: Array[String] = []

## Name of the enemy that killed the player (for death screen)
var last_enemy_name: String = ""

## Current ascension level
var ascension_level: int = 0


# --- Public Methods ---

## Maps region/column position to an equivalent floor (1-20) for enemy scaling.
func get_equivalent_floor() -> int:
	var difficulty: float = float(current_region_index * 17 + current_column)
	return clampi(1 + roundi(difficulty * 19.0 / 67.0), 1, 20)


## Heal cogency, capped at max.
func heal(amount: int) -> void:
	cogency = mini(cogency + amount, max_cogency)


## Take cogency damage, floored at 0.
func take_damage(amount: int) -> void:
	cogency = maxi(cogency - amount, 0)


## Returns true if player cogency has reached 0.
func is_dead() -> bool:
	return cogency <= 0


## Add semant.
func add_semant(amount: int) -> void:
	semant += amount


## Spend semant if affordable. Returns true on success.
func spend_semant(amount: int) -> bool:
	if semant < amount:
		return false
	semant -= amount
	return true


## Add a morpheme to the deck.
func add_to_deck(morpheme: MorphemeData) -> void:
	deck.append(morpheme)


## Remove a morpheme from the deck by index.
func remove_from_deck(index: int) -> void:
	if index >= 0 and index < deck.size():
		deck.remove_at(index)


## Returns true if the grapheme inventory has room.
func can_add_grapheme() -> bool:
	return acquired_graphemes.size() < MAX_GRAPHEMES


## Returns true if the phoneme inventory has room.
func can_add_phoneme() -> bool:
	return acquired_phonemes.size() < MAX_PHONEMES


## Increment a combat stat by the given amount.
func increment_stat(stat_name: String, amount: int = 1) -> void:
	if not combat_stats.has(stat_name):
		combat_stats[stat_name] = 0
	combat_stats[stat_name] += amount


## Get a combat stat value (0 if not tracked yet).
func get_stat(stat_name: String) -> int:
	return combat_stats.get(stat_name, 0)
