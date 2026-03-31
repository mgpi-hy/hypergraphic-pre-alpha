# game_manager.gd — Autoload: run state, meta-progression, screen routing
extends Node

## Owns the current run, meta-progression currency/unlocks, and the
## scene-based screen FSM. No combat logic, no UI.

# --- Constants ---

const SCENE_TITLE: String = "res://scenes/screens/title_screen.tscn"
const SCENE_CHARACTER_SELECT: String = "res://scenes/screens/character_select.tscn"
const SCENE_MAP: String = "res://scenes/screens/map_screen.tscn"
const SCENE_COMBAT: String = "res://scenes/combat/combat_screen.tscn"
const SCENE_SHOP: String = "res://scenes/screens/shop_screen.tscn"
const SCENE_REST: String = "res://scenes/screens/rest_screen.tscn"
const SCENE_EVENT: String = "res://scenes/screens/event_screen.tscn"
const SCENE_REWARD: String = "res://scenes/screens/reward_screen.tscn"
const SCENE_RUN_SUMMARY: String = "res://scenes/screens/run_summary.tscn"
const SCENE_DECK_VIEWER: String = "res://scenes/screens/deck_viewer.tscn"
const SCENE_ROOT_UNLOCK: String = "res://scenes/screens/root_unlock_screen.tscn"
const SCENE_REGION_SELECT: String = "res://scenes/screens/region_select.tscn"

const MORPHEME_DATA_DIR: String = "res://data/morphemes/"
const REGION_DATA_DIR: String = "res://data/regions/"

## Act 1 region IDs. One is chosen at random to start a run.
const ACT_1_REGIONS: Array[String] = ["brainstem"]

# --- Public Variables ---

## Current run data. Null when not in a run.
var run: RunData = null

## Meta-currency earned across runs, spent on character/content unlocks.
var meta_pragmant: int = 0

## Morpheme root forms the player has permanently unlocked.
var unlocked_roots: Array[String] = []

## Grapheme effect IDs the player has permanently unlocked.
var unlocked_graphemes: Array[String] = []

## Persistent user settings (audio, display, gameplay).
var settings: SettingsData = SettingsData.new()

## Current ascension level for the next run.
var current_ascension: int = 0

# --- Private Variables ---

## Currently active screen node (ScreenState subclass).
var _current_screen: ScreenState = null

## List of unlocked character IDs. "english" is always present.
var _unlocked_characters: Array[String] = ["english"]

## Previous screen name for enter() context.
var _previous_screen_name: String = ""


# --- Virtual Methods ---

func _ready() -> void:
	SaveManager.load_meta()
	# Adopt the main scene (title screen) into the screen FSM.
	# The main scene is loaded by Godot before autoloads run _ready(),
	# so we defer to let the scene tree finish setup.
	call_deferred("_adopt_main_scene")


## Grab the main scene and wire it into the screen FSM so its
## finished signal actually routes somewhere.
func _adopt_main_scene() -> void:
	var main_scene: Node = get_tree().current_scene
	if main_scene is ScreenState:
		_current_screen = main_scene as ScreenState
		_current_screen.finished.connect(_on_screen_finished)
	else:
		# Main scene isn't a ScreenState; load title screen through FSM
		_transition_to(SCENE_TITLE)


# --- Public Methods: Run Lifecycle ---

## Start a new run with the given character. Creates RunData,
## loads starter deck, transitions to map.
func start_run(character: CharacterData) -> void:
	run = RunData.new()
	run.character = character
	run.ascension_level = current_ascension
	run.cogency = character.starter_cogency
	run.max_cogency = character.starter_cogency

	run.deck = get_starter_deck(character)

	# Load starting region and generate map
	var region: RegionData = _load_starting_region()
	if region == null:
		push_error("GameManager.start_run: no starting region found")
		_transition_to(SCENE_TITLE)
		return

	run.current_region_id = region.id
	run.current_region_index = 0
	run.traversed_regions.append(region.id)

	var map: MapData = MapData.generate(region)

	EventBus.run_started.emit(character)
	_transition_to(SCENE_MAP, {"map": map})


## End the current run. Record stats, award pragmant, go to summary.
func end_run(is_victory: bool) -> void:
	if run == null:
		_transition_to(SCENE_TITLE)
		return

	# Award pragmant based on progress
	var pragmant_earned: int = _calculate_pragmant(is_victory)
	meta_pragmant += pragmant_earned

	# Record stats
	var enemies: int = run.get_stat("enemies_defeated")
	var words: int = run.get_stat("words_submitted")
	SaveManager.total_words_submitted += words
	SaveManager.record_run_end(run.current_region_index, enemies, is_victory)
	SaveManager.record_run({
		"regions_cleared": run.current_region_index,
		"character_name": run.character.display_name if run.character else "???",
		"victory": is_victory,
		"enemies_defeated": enemies,
		"words_submitted": words,
		"timestamp": Time.get_datetime_string_from_system(),
	})
	SaveManager.save_meta()

	# Stash summary for the run summary screen
	_stash_run_summary(is_victory, pragmant_earned)

	EventBus.run_ended.emit(is_victory)

	run = null
	_transition_to(SCENE_RUN_SUMMARY)


## Build the starter deck for a character based on their allowed families.
## Loads MorphemeData resources from data/morphemes/.
func get_starter_deck(character: CharacterData) -> Array[MorphemeData]:
	var all_morphemes: Array[MorphemeData] = _load_all_morphemes()
	var deck: Array[MorphemeData] = []

	for m in all_morphemes:
		if not _is_starter_morpheme(m):
			continue
		if not character.is_morpheme_allowed(m):
			continue
		deck.append(m)

	return deck


# --- Public Methods: Character Unlocks ---

## Unlock a character by ID. Saves immediately.
func unlock_character(id: String) -> void:
	if id in _unlocked_characters:
		return
	_unlocked_characters.append(id)
	SaveManager.save_meta()


## Returns true if the character is unlocked.
func is_character_unlocked(id: String) -> bool:
	return id in _unlocked_characters


## Returns a copy of the unlocked character ID list (for SaveManager).
func get_unlocked_character_ids() -> Array[String]:
	return _unlocked_characters.duplicate()


## Replace the unlocked characters list (called by SaveManager on load).
func set_unlocked_characters(ids: Array) -> void:
	_unlocked_characters.clear()
	for id in ids:
		if id is String:
			_unlocked_characters.append(id)
	if not "english" in _unlocked_characters:
		_unlocked_characters.append("english")


## Reset unlocks to defaults (called by SaveManager.clear_save()).
func reset_unlocks() -> void:
	_unlocked_characters.clear()
	_unlocked_characters.append("english")
	unlocked_roots.clear()
	unlocked_graphemes.clear()


# --- Public Methods: Root Unlocks ---

## Unlock a morpheme root form permanently.
func unlock_root(form: String) -> void:
	if form in unlocked_roots:
		return
	unlocked_roots.append(form)
	SaveManager.save_meta()


## Returns true if the root form is unlocked.
func is_root_unlocked(form: String) -> bool:
	return form in unlocked_roots


# --- Public Methods: Grapheme Unlocks ---

## Unlock a grapheme by effect ID permanently.
func unlock_grapheme(effect_id: String) -> void:
	if effect_id in unlocked_graphemes:
		return
	unlocked_graphemes.append(effect_id)
	SaveManager.save_meta()


## Returns true if the grapheme effect ID is unlocked.
func is_grapheme_unlocked(effect_id: String) -> bool:
	return effect_id in unlocked_graphemes


# --- Public Methods: Region Progression ---

## Advance to the next region after beating a boss.
## Loads region choices from current region's leads_to, transitions to
## region select screen (if choices exist) or forces the next region.
func advance_region() -> void:
	if run == null:
		push_error("GameManager.advance_region: no active run")
		return

	var current_region: RegionData = _load_region(run.current_region_id)
	if current_region == null:
		push_error("GameManager.advance_region: current region not found")
		return

	var next_ids: Array[String] = current_region.leads_to
	if next_ids.is_empty():
		# No more regions (temporal lobe beaten); run is won
		end_run(true)
		return

	# Load candidate regions
	var choices: Array[RegionData] = []
	for region_id: String in next_ids:
		var region: RegionData = _load_region(region_id)
		if region:
			choices.append(region)

	if choices.is_empty():
		push_error("GameManager.advance_region: failed to load any next regions")
		end_run(false)
		return

	if choices.size() == 1:
		# Only one option, skip selection screen
		set_region(choices[0])
		return

	# Multiple choices: show region select screen
	EventBus.region_choices_available.emit(choices)
	_transition_to(SCENE_REGION_SELECT, {"choices": choices})


## Set the next region and transition to its map.
## Called by region select screen or advance_region() when forced.
func set_region(region: RegionData) -> void:
	if run == null:
		push_error("GameManager.set_region: no active run")
		return

	run.current_region_index += 1
	run.current_region_id = region.id
	run.current_column = 0
	run.traversed_regions.append(region.id)

	EventBus.region_entered.emit(region)

	var map: MapData = MapData.generate(region)
	_transition_to(SCENE_MAP, {"map": map})


## Convert region_index + column to a 1-20 equivalent floor for scaling.
## 4 regions x 17 columns = 68 positions mapped to 1-20.
static func get_equivalent_floor(region_index: int, column: int) -> int:
	var position: float = float(region_index * 17 + column)
	return clampi(1 + roundi(position * 19.0 / 67.0), 1, 20)


# --- Public Methods: Navigation ---

## Navigate to combat with enemy and floor context.
func navigate_to_combat(enemies: Array, floor_number: int) -> void:
	var data: Dictionary = {
		"enemies": enemies,
		"floor_number": floor_number,
	}
	_transition_to(SCENE_COMBAT, data)


## Navigate to the shop screen with context data.
func navigate_to_shop(data: Dictionary = {}) -> void:
	_transition_to(SCENE_SHOP, data)


## Navigate to the rest screen with context data.
func navigate_to_rest(data: Dictionary = {}) -> void:
	_transition_to(SCENE_REST, data)


## Navigate to an event screen with context data.
func navigate_to_event(data: Dictionary = {}) -> void:
	_transition_to(SCENE_EVENT, data)


# --- Private Methods: Screen FSM ---

## Transition to a new screen. Tears down the current screen,
## instantiates the next, wires the finished signal.
func _transition_to(screen_path: String, data: Dictionary = {}) -> void:
	if _current_screen:
		_previous_screen_name = _current_screen.name
		if _current_screen.finished.is_connected(_on_screen_finished):
			_current_screen.finished.disconnect(_on_screen_finished)
		_current_screen.exit()
		_current_screen.queue_free()
		_current_screen = null

	var next_scene: PackedScene = load(screen_path) as PackedScene
	if not next_scene:
		push_error("GameManager: failed to load screen: %s" % screen_path)
		return

	var next_node: Node = next_scene.instantiate()
	_current_screen = next_node as ScreenState
	if not _current_screen:
		push_error("GameManager: screen root is not ScreenState: %s" % screen_path)
		next_node.queue_free()
		return

	# Add to scene tree root (not to self) so it renders as main content
	get_tree().root.add_child(_current_screen)
	_current_screen.finished.connect(_on_screen_finished)
	_current_screen.enter(_previous_screen_name, data)


## Called when the current screen emits finished. Routes to next screen.
func _on_screen_finished(next_screen: String, data: Dictionary) -> void:
	_transition_to(next_screen, data)


# --- Private Methods: Region Loading ---

## Load a random act 1 region as the starting region for a new run.
func _load_starting_region() -> RegionData:
	var region_id: String = ACT_1_REGIONS[randi() % ACT_1_REGIONS.size()]
	var path: String = REGION_DATA_DIR + region_id + ".tres"
	var region: RegionData = load(path) as RegionData
	if region == null:
		push_error("GameManager: failed to load region: %s" % path)
	return region


## Load a region by ID string.
func _load_region(region_id: String) -> RegionData:
	var path: String = REGION_DATA_DIR + region_id + ".tres"
	var region: RegionData = load(path) as RegionData
	if region == null:
		push_error("GameManager: failed to load region: %s" % path)
	return region


# --- Private Methods: Deck Building ---

## Load all MorphemeData resources from the morphemes directory.
func _load_all_morphemes() -> Array[MorphemeData]:
	var morphemes: Array[MorphemeData] = []
	var dir := DirAccess.open(MORPHEME_DATA_DIR)
	if not dir:
		push_warning("GameManager: could not open morpheme directory: %s" % MORPHEME_DATA_DIR)
		return morphemes

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path: String = MORPHEME_DATA_DIR + file_name
			var res: MorphemeData = load(path) as MorphemeData
			if res:
				morphemes.append(res)
			else:
				push_warning("GameManager: failed to load morpheme: %s" % path)
		file_name = dir.get_next()
	dir.list_dir_end()

	return morphemes


## Returns true if a morpheme should be in a starter deck.
## Starter morphemes are common-rarity roots and functional affixes.
func _is_starter_morpheme(m: MorphemeData) -> bool:
	if m.rarity != MorphemeData.Rarity.COMMON:
		return false
	if m.is_affix and m.combat_role != MorphemeData.CombatRole.FUNCTIONAL:
		return false
	return true


# --- Private Methods: Progression ---

## Calculate pragmant earned from a run based on progress and outcome.
func _calculate_pragmant(is_victory: bool) -> int:
	if run == null:
		return 0
	if is_victory:
		return (run.current_region_index + 1) * 15
	return (run.current_region_index + 1) * 8


## Stash a run summary dictionary as node meta for the summary screen.
func _stash_run_summary(is_victory: bool, pragmant_earned: int) -> void:
	if run == null:
		return

	var deck_forms: Array[String] = []
	for m in run.deck:
		deck_forms.append(m.root_text)

	var summary: Dictionary = {
		"regions_cleared": run.current_region_index,
		"rooms_cleared": run.get_stat("rooms_cleared"),
		"enemies_defeated": run.get_stat("enemies_defeated"),
		"words_submitted": run.get_stat("words_submitted"),
		"turns_survived": run.get_stat("turns_survived"),
		"pragmant_earned": pragmant_earned,
		"total_pragmant": meta_pragmant,
		"is_victory": is_victory,
		"character_name": run.character.display_name if run.character else "???",
		"character_art": run.character.ascii_art if run.character else "",
		"character_color": run.character.color if run.character else Color.WHITE,
		"deck_forms": deck_forms,
		"skipped_morphemes": run.skipped_morphemes,
		"deck_size": run.deck.size(),
		"grapheme_count": run.acquired_graphemes.size(),
		"last_enemy_name": run.last_enemy_name,
		"death_region_id": run.current_region_id,
		"death_column": run.current_column,
		"novel_words": run.get_stat("novel_words"),
		"best_word_form": run.combat_stats.get("best_word_form", ""),
		"best_word_induction": run.combat_stats.get("best_word_induction", 0),
		"peak_multiplier": run.combat_stats.get("peak_multiplier", 1.0),
	}
	set_meta("run_summary", summary)
