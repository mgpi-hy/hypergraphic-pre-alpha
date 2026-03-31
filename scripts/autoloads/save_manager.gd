# save_manager.gd — Autoload: meta-progression persistence
# No run saves. Roguelite means you earn your wins.
extends Node

## Handles saving and loading meta-progression data to user://.
## Atomic writes via temp file + rename. Tracks lifetime stats,
## unlocks, and settings across runs.

# --- Constants ---

const SAVE_PATH: String = "user://save_data.json"

# --- Public Variables ---

var total_runs: int = 0
var best_region: int = 0
var total_enemies_defeated: int = 0
var total_victories: int = 0
var total_words_submitted: int = 0
var best_single_induction: int = 0
var longest_win_streak: int = 0
var current_win_streak: int = 0
var tutorial_shown: bool = false
var ascension_unlocked: int = 0
var run_history: Array[Dictionary] = []


# --- Public Methods ---

## Save all meta-progression state to disk. Atomic write.
func save_meta() -> void:
	var data: Dictionary = {
		"meta_pragmant": GameManager.meta_pragmant,
		"unlocked_characters": GameManager.get_unlocked_character_ids(),
		"unlocked_roots": GameManager.unlocked_roots.duplicate(),
		"unlocked_graphemes": GameManager.unlocked_graphemes.duplicate(),
		"total_runs": total_runs,
		"best_region": best_region,
		"total_enemies_defeated": total_enemies_defeated,
		"total_victories": total_victories,
		"total_words_submitted": total_words_submitted,
		"best_single_induction": best_single_induction,
		"longest_win_streak": longest_win_streak,
		"current_win_streak": current_win_streak,
		"tutorial_shown": tutorial_shown,
		"ascension_unlocked": ascension_unlocked,
		"run_history": run_history.duplicate(),
		"settings": GameManager.settings.to_dict(),
	}

	var json_string: String = JSON.stringify(data, "\t")
	_atomic_write(json_string)


## Load meta-progression state from disk. Called by GameManager._ready().
func load_meta() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: could not open save file for reading")
		return

	var json_string: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result: int = json.parse(json_string)
	if parse_result != OK:
		push_warning("SaveManager: failed to parse save file")
		return

	if not json.data is Dictionary:
		push_warning("SaveManager: save data is not a Dictionary")
		return

	var data: Dictionary = json.data
	_apply_loaded_data(data)


## Returns true if a save file exists on disk.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Delete save file and reset all state to defaults.
func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

	GameManager.meta_pragmant = 0
	GameManager.reset_unlocks()
	GameManager.settings = SettingsData.new()

	total_runs = 0
	best_region = 0
	total_enemies_defeated = 0
	total_victories = 0
	total_words_submitted = 0
	best_single_induction = 0
	longest_win_streak = 0
	current_win_streak = 0
	tutorial_shown = false
	ascension_unlocked = 0
	run_history.clear()

	_apply_settings()


## Record a run summary dict into run_history (last 10 kept).
func record_run(data: Dictionary) -> void:
	run_history.insert(0, data)
	if run_history.size() > 10:
		run_history.resize(10)


## Update lifetime stats at run end.
func record_run_end(region_index: int, enemies: int, is_victory: bool = false) -> void:
	total_runs += 1

	if region_index > best_region:
		best_region = region_index

	total_enemies_defeated += enemies

	if is_victory:
		total_victories += 1
		current_win_streak += 1
		if current_win_streak > longest_win_streak:
			longest_win_streak = current_win_streak
	else:
		current_win_streak = 0


# --- Private Methods ---

## Atomic write: write to temp file, then rename over real file.
func _atomic_write(json_string: String) -> void:
	var temp_path: String = SAVE_PATH + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: could not open temp file for writing")
		return

	file.store_string(json_string)
	file.close()

	var err: Error = DirAccess.rename_absolute(temp_path, SAVE_PATH)
	if err != OK:
		push_warning("SaveManager: rename failed (error %d), save may be stale" % err)


## Apply loaded data to GameManager and local stats.
func _apply_loaded_data(data: Dictionary) -> void:
	GameManager.meta_pragmant = data.get("meta_pragmant", 0)

	# Stats
	total_runs = data.get("total_runs", 0)
	best_region = data.get("best_region", 0)
	total_enemies_defeated = data.get("total_enemies_defeated", 0)
	total_victories = data.get("total_victories", 0)
	total_words_submitted = data.get("total_words_submitted", 0)
	best_single_induction = data.get("best_single_induction", 0)
	longest_win_streak = data.get("longest_win_streak", 0)
	current_win_streak = data.get("current_win_streak", 0)
	tutorial_shown = data.get("tutorial_shown", false)
	ascension_unlocked = data.get("ascension_unlocked", 0)

	# Run history
	run_history.clear()
	var loaded_history: Array = data.get("run_history", [])
	for entry in loaded_history:
		if entry is Dictionary:
			run_history.append(entry)

	# Unlocked roots
	GameManager.unlocked_roots.clear()
	var loaded_roots: Array = data.get("unlocked_roots", [])
	for r in loaded_roots:
		if r is String:
			GameManager.unlocked_roots.append(r)

	# Unlocked graphemes
	GameManager.unlocked_graphemes.clear()
	var loaded_graphemes: Array = data.get("unlocked_graphemes", [])
	for g in loaded_graphemes:
		if g is String:
			GameManager.unlocked_graphemes.append(g)

	# Unlocked characters
	var loaded_chars: Array = data.get("unlocked_characters", ["english"])
	if not loaded_chars is Array or loaded_chars.is_empty():
		loaded_chars = ["english"]
	if not "english" in loaded_chars:
		loaded_chars.append("english")
	GameManager.set_unlocked_characters(loaded_chars)

	# Settings
	if data.has("settings"):
		GameManager.settings.from_dict(data["settings"])

	_apply_settings()


## Apply current settings to engine (audio buses, display mode).
func _apply_settings() -> void:
	var s: SettingsData = GameManager.settings

	# Audio buses: Master = 0, SFX = 1, Music = 2 (if they exist)
	if AudioServer.bus_count > 0:
		AudioServer.set_bus_volume_db(0, linear_to_db(s.master_volume))
	if AudioServer.bus_count > 1:
		AudioServer.set_bus_volume_db(1, linear_to_db(s.sfx_volume))
	if AudioServer.bus_count > 2:
		AudioServer.set_bus_volume_db(2, linear_to_db(s.music_volume))

	# Fullscreen
	if s.is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
