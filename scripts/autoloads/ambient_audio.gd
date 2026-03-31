extends Node

## Procedural ambient sound system. Three simultaneous sine-wave layers
## (drone, pulse, texture) crossfade between six modes. Neural/electronic
## atmosphere generated at runtime; no audio files required.

# --- Enums ---
enum Mode { MENU, MAP, COMBAT, SHOP, REST, EVENT }

# --- Constants ---
const SAMPLE_RATE: int = 44100
const CROSSFADE_DURATION: float = 0.8

const MODE_NAMES: Dictionary = {
	"menu": Mode.MENU,
	"map": Mode.MAP,
	"combat": Mode.COMBAT,
	"shop": Mode.SHOP,
	"rest": Mode.REST,
	"event": Mode.EVENT,
}

## Region-specific drone root frequencies (neural oscillation bands).
const REGION_FREQS: Dictionary = {
	"brainstem": 45.0,
	"amygdala": 55.0,
	"hippocampus": 62.0,
	"thalamus": 70.0,
	"hypothalamus": 58.0,
	"wernickes": 82.0,
	"brocas": 78.0,
	"cerebellum": 65.0,
	"corpus_callosum": 73.0,
	"temporal_lobe": 85.0,
	"parietal_lobe": 75.0,
	"occipital_lobe": 90.0,
	"frontal_lobe": 80.0,
}

# --- Private Variables ---
var _drone_player: AudioStreamPlayer = null
var _pulse_player: AudioStreamPlayer = null
var _texture_player: AudioStreamPlayer = null

var _current_mode: Mode = Mode.MENU
var _master_volume: float = 0.5

## Per-mode layer flags and parameters.
var _drone_enabled: bool = false
var _pulse_enabled: bool = false
var _texture_enabled: bool = false
var _drone_freq: float = 70.0
var _drone_volume_db: float = -20.0
var _pulse_volume_db: float = -25.0
var _pulse_interval: float = 0.85
var _texture_volume_db: float = -30.0
var _texture_freq_min: float = 800.0
var _texture_freq_max: float = 2000.0
var _texture_interval: float = 2.0

## Timers for pulse/texture fire scheduling.
var _pulse_timer: float = 0.0
var _texture_timer: float = 0.0

## Brownian noise state for drone generation.
var _noise_state: float = 0.0

var _rng: RandomNumberGenerator = null
var _crossfade_tween: Tween = null


# --- Virtual Methods ---

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

	_drone_player = _make_player()
	_pulse_player = _make_player()
	_texture_player = _make_player()

	_connect_signals()
	set_mode("menu")


func _process(delta: float) -> void:
	if not _drone_enabled and not _pulse_enabled and not _texture_enabled:
		return

	if _pulse_enabled:
		_pulse_timer += delta
		if _pulse_timer >= _pulse_interval:
			_pulse_timer = 0.0
			_play_pulse()

	if _texture_enabled:
		_texture_timer += delta
		if _texture_timer >= _texture_interval:
			_texture_timer = 0.0
			_texture_interval = _rng.randf_range(1.0, 3.0)
			_play_texture()


# --- Public Methods ---

func set_mode(mode: String) -> void:
	## Crossfade to a new ambient mode. Accepts lowercase mode names:
	## "menu", "map", "combat", "shop", "rest", "event".
	if not MODE_NAMES.has(mode):
		push_warning("AmbientAudio: unknown mode '%s'" % mode)
		return

	var new_mode: Mode = MODE_NAMES[mode] as Mode
	if new_mode == _current_mode and _drone_player.playing:
		return
	_current_mode = new_mode

	# Kill any in-progress crossfade
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	# Fade out current layers, apply new config, fade in
	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.tween_property(
		_drone_player, "volume_db", -60.0, CROSSFADE_DURATION * 0.5
	)
	_crossfade_tween.tween_property(
		_pulse_player, "volume_db", -60.0, CROSSFADE_DURATION * 0.5
	)
	_crossfade_tween.tween_property(
		_texture_player, "volume_db", -60.0, CROSSFADE_DURATION * 0.5
	)
	_crossfade_tween.chain().tween_callback(_apply_mode_config)


func set_volume(volume: float) -> void:
	## Set master volume (0.0 to 1.0). Applies immediately to active layers.
	_master_volume = clampf(volume, 0.0, 1.0)
	_apply_volumes()


func stop_all() -> void:
	## Silence everything and reset state.
	_drone_enabled = false
	_pulse_enabled = false
	_texture_enabled = false
	_drone_player.stop()
	_pulse_player.stop()
	_texture_player.stop()


# --- Private Methods ---

func _make_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = "Master"
	player.volume_db = -60.0
	add_child(player)
	return player


func _connect_signals() -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if not bus:
		push_warning("AmbientAudio: EventBus not found, signal routing disabled")
		return

	bus.combat_won.connect(func() -> void: set_mode("map"))
	bus.combat_lost.connect(func() -> void: set_mode("map"))
	bus.run_started.connect(func(_c: CharacterData) -> void: set_mode("map"))
	bus.run_ended.connect(func(_won: bool) -> void: set_mode("menu"))
	bus.map_node_selected.connect(_on_map_node_selected)


func _on_map_node_selected(node_type: String, _column: int) -> void:
	match node_type:
		"combat":
			set_mode("combat")
		"elite":
			set_mode("combat")
		"shop":
			set_mode("shop")
		"rest":
			set_mode("rest")
		"event":
			set_mode("event")
		_:
			set_mode("map")


func _apply_mode_config() -> void:
	## Configure layer flags/params for the current mode, then start layers.
	_pulse_timer = 0.0
	_texture_timer = 0.0

	match _current_mode:
		Mode.MENU:
			_drone_enabled = true
			_pulse_enabled = false
			_texture_enabled = false
			_drone_freq = 70.0
			_drone_volume_db = -22.0
		Mode.MAP:
			_drone_enabled = true
			_pulse_enabled = true
			_texture_enabled = false
			_drone_freq = 70.0
			_pulse_interval = 0.85
			_drone_volume_db = -20.0
			_pulse_volume_db = -25.0
		Mode.COMBAT:
			_drone_enabled = true
			_pulse_enabled = true
			_texture_enabled = true
			_drone_freq = 75.0
			_pulse_interval = 0.75
			_drone_volume_db = -18.0
			_pulse_volume_db = -23.0
			_texture_volume_db = -28.0
			_texture_freq_min = 800.0
			_texture_freq_max = 2000.0
		Mode.SHOP:
			_drone_enabled = true
			_pulse_enabled = false
			_texture_enabled = true
			_drone_freq = 65.0
			_drone_volume_db = -22.0
			_texture_volume_db = -30.0
			_texture_freq_min = 600.0
			_texture_freq_max = 1200.0
			_texture_interval = 2.5
		Mode.REST:
			_drone_enabled = true
			_pulse_enabled = false
			_texture_enabled = false
			_drone_freq = 60.0
			_drone_volume_db = -24.0
		Mode.EVENT:
			_drone_enabled = true
			_pulse_enabled = true
			_texture_enabled = true
			_drone_freq = 80.0
			_pulse_interval = 0.5
			_drone_volume_db = -14.0
			_pulse_volume_db = -20.0
			_texture_volume_db = -24.0
			_texture_freq_min = 1000.0
			_texture_freq_max = 2500.0
			_texture_interval = 1.0

	_apply_region_tuning()

	if _drone_enabled:
		_start_drone()
	else:
		_drone_player.stop()

	if not _pulse_enabled:
		_pulse_player.stop()
	if not _texture_enabled:
		_texture_player.stop()


func _get_volume_scale() -> float:
	var music_vol: float = _master_volume
	if GameManager != null and GameManager.settings != null:
		music_vol = GameManager.settings.music_volume
	return clampf(music_vol, 0.001, 1.0)


func _apply_volumes() -> void:
	var scale_db: float = linear_to_db(_get_volume_scale())
	if _drone_player.playing:
		_drone_player.volume_db = _drone_volume_db + scale_db
	if _pulse_player.playing:
		_pulse_player.volume_db = _pulse_volume_db + scale_db
	if _texture_player.playing:
		_texture_player.volume_db = _texture_volume_db + scale_db


func _apply_region_tuning() -> void:
	if GameManager == null or GameManager.run == null:
		return
	var region_id: String = GameManager.run.current_region_id
	if region_id == "" or not REGION_FREQS.has(region_id):
		return
	_drone_freq = REGION_FREQS[region_id]
	var ratio: float = _drone_freq / 70.0
	_texture_freq_min *= ratio
	_texture_freq_max *= ratio


func _start_drone() -> void:
	var stream: AudioStreamWAV = _generate_drone(_drone_freq, 3.0)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	_drone_player.stream = stream
	_drone_player.volume_db = _drone_volume_db + linear_to_db(_get_volume_scale())
	_drone_player.play()


func _play_pulse() -> void:
	var freq: float = _rng.randf_range(100.0, 200.0)
	var stream: AudioStreamWAV = _generate_click(freq, 0.05)
	_pulse_player.stream = stream
	_pulse_player.volume_db = _pulse_volume_db + linear_to_db(_get_volume_scale())
	_pulse_player.play()


func _play_texture() -> void:
	var freq: float = _rng.randf_range(_texture_freq_min, _texture_freq_max)
	var duration: float = _rng.randf_range(0.2, 0.5)
	var stream: AudioStreamWAV = _generate_texture(freq, duration)
	_texture_player.stream = stream
	_texture_player.volume_db = _texture_volume_db + linear_to_db(_get_volume_scale())
	_texture_player.play()


# --- Wave Generation ---

func _filtered_noise() -> float:
	## Brownian noise: random walk, clamped, with DC-drift correction.
	_noise_state += _rng.randf_range(-0.1, 0.1)
	_noise_state = clampf(_noise_state, -1.0, 1.0)
	_noise_state *= 0.998
	return _noise_state


func _generate_drone(freq: float, duration: float) -> AudioStreamWAV:
	## Rich drone: fundamental + harmonics + filtered noise + slow modulation.
	var num_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	var mod_freq: float = 0.25
	var drift_freq: float = 0.07
	_noise_state = 0.0

	for i: int in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		var pitch: float = freq + 1.5 * sin(t * drift_freq * TAU)
		var wave: float = sin(t * pitch * TAU) * 0.55
		wave += sin(t * pitch * 2.0 * TAU) * 0.18
		wave += sin(t * pitch * 3.0 * TAU) * 0.10
		wave += sin(t * pitch * 5.0 * TAU) * 0.04
		wave += _filtered_noise() * 0.06
		var envelope: float = 0.14 * (0.65 + 0.35 * sin(t * mod_freq * TAU))
		var sample_val: float = wave * envelope
		var sample_int: int = clampi(
			int(sample_val * 32767.0), -32768, 32767
		)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _generate_click(freq: float, duration: float) -> AudioStreamWAV:
	## Neural firing click: noise transient + tonal body + inharmonic partial.
	var num_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i: int in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / num_samples
		var envelope: float = 0.22 * exp(-progress * 5.0)
		var transient: float = 0.0
		if progress < 0.1:
			transient = _rng.randf_range(-1.0, 1.0) * (1.0 - progress / 0.1) * 0.4
		var wave: float = sin(t * freq * TAU) * 0.6
		wave += sin(t * freq * 1.5 * TAU) * 0.25
		wave += sin(t * freq * 2.5 * TAU) * 0.08
		var sample_val: float = (wave * envelope) + (transient * envelope * 2.0)
		var sample_int: int = clampi(
			int(sample_val * 32767.0), -32768, 32767
		)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _generate_texture(freq: float, duration: float) -> AudioStreamWAV:
	## Glass bell tone: fundamental + detuned partial + harmonics, fade in/out.
	var num_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i: int in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / num_samples
		var envelope: float = 0.11
		if progress < 0.2:
			envelope *= progress / 0.2
		elif progress > 0.5:
			var fade: float = 1.0 - (progress - 0.5) / 0.5
			envelope *= fade * fade
		var wave: float = sin(t * freq * TAU) * 0.6
		wave += sin(t * (freq * 1.002) * TAU) * 0.25
		wave += sin(t * freq * 2.0 * TAU) * 0.12
		wave += sin(t * freq * 3.0 * TAU) * 0.04
		var sample_val: float = wave * envelope
		var sample_int: int = clampi(
			int(sample_val * 32767.0), -32768, 32767
		)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream
