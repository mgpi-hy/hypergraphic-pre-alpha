class_name SettingsData
extends Resource

## Persistent user settings. Saved to user:// between sessions.
## Simple value store; no game logic.

# --- Exports: Audio ---

## Master volume multiplier (0.0 to 1.0)
@export_range(0.0, 1.0, 0.05) var master_volume: float = 1.0

## Sound effects volume multiplier (0.0 to 1.0)
@export_range(0.0, 1.0, 0.05) var sfx_volume: float = 1.0

## Music volume multiplier (0.0 to 1.0)
@export_range(0.0, 1.0, 0.05) var music_volume: float = 0.5

# --- Exports: Display ---

## Whether the game runs in fullscreen mode
@export var is_fullscreen: bool = false

## High contrast mode for accessibility
@export var is_high_contrast: bool = false

# --- Exports: Gameplay ---

## Whether screen shake is enabled
@export var is_screen_shake_enabled: bool = true


# --- Public Methods ---

## Serialize settings to a Dictionary for saving.
func to_dict() -> Dictionary:
	return {
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
		"is_fullscreen": is_fullscreen,
		"is_high_contrast": is_high_contrast,
		"is_screen_shake_enabled": is_screen_shake_enabled,
	}


## Restore settings from a Dictionary.
func from_dict(data: Dictionary) -> void:
	master_volume = data.get("master_volume", 1.0)
	sfx_volume = data.get("sfx_volume", 1.0)
	music_volume = data.get("music_volume", 0.5)
	is_fullscreen = data.get("is_fullscreen", false)
	is_high_contrast = data.get("is_high_contrast", false)
	is_screen_shake_enabled = data.get("is_screen_shake_enabled", true)
