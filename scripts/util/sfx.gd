class_name SFX
extends RefCounted

## Procedural audio synthesis system. Generates all sound effects at runtime
## from sine waves, sweeps, chords, and noise bursts.

# --- Constants ---
const SAMPLE_RATE: int = 44100

# --- Public Methods ---

static func play(node: Node, stream: AudioStreamWAV) -> void:
	## Play a sound on a given node (creates a temporary AudioStreamPlayer).
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -6.0
	node.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


static func play_slot_fill(node: Node) -> void:
	## Bright click-tone with slight pitch variation to prevent habituation.
	var jitter: float = randf_range(0.95, 1.05)
	play(node, _make_tone(880.0 * jitter, 0.08, 0.2))


static func play_slot_clear(node: Node) -> void:
	## Softer lower tone for removing.
	play(node, _make_tone(440.0, 0.06, 0.15))


static func play_submit(node: Node) -> void:
	## Ascending sweep with body.
	play(node, _make_sweep(440.0, 880.0, 0.15, 0.25))


static func play_enemy_attack(node: Node) -> void:
	## Descending hit with weight + sub-bass layer.
	play(node, _make_sweep(600.0, 150.0, 0.14, 0.3))
	play(node, _make_tone(80.0, 0.05, 0.35, true))


static func play_invalid(node: Node) -> void:
	## Flat buzz (dissonant).
	play(node, _make_sweep(300.0, 150.0, 0.1, 0.2))


static func play_victory(node: Node) -> void:
	## Major chord sweep upward.
	play(node, _make_chord(440.0, 660.0, 0.4, 0.3))


static func play_defeat(node: Node) -> void:
	## Minor descent.
	play(node, _make_sweep(660.0, 110.0, 0.5, 0.3))


static func play_cascade_tick(node: Node, pitch_index: int) -> void:
	## C major pentatonic cascade; each step ascends, consonant, never clashes.
	var pentatonic: Array[float] = [523.0, 587.0, 659.0, 784.0, 880.0, 1047.0]
	var idx: int = clampi(pitch_index, 0, pentatonic.size() - 1)
	var base_freq: float = pentatonic[idx]
	var vol: float = 0.15 + float(idx) * 0.01
	if idx <= 1:
		play(node, _make_tone(base_freq, 0.08, vol))
	else:
		play(node, _make_chord(base_freq, base_freq * 1.5, 0.1, vol))


static func play_cascade_mult(node: Node) -> void:
	## Major triad chord (C5-E5-G5) for satisfying resolution.
	play(node, _make_triad(523.0, 659.0, 784.0, 0.2, 0.25))


static func play_cascade_branch(node: Node) -> void:
	## Chord sweep for branch completion.
	play(node, _make_chord(660.0, 990.0, 0.18, 0.25))


static func play_cascade_full_tree(node: Node) -> void:
	## Big ascending sweep with harmonics.
	play(node, _make_sweep(440.0, 1760.0, 0.3, 0.3))


static func play_impact(node: Node) -> void:
	## Heavy thud on enemy hit + sub-bass.
	play(node, _make_sweep(200.0, 60.0, 0.15, 0.35))
	play(node, _make_tone(60.0, 0.06, 0.3, true))


static func play_reward(node: Node) -> void:
	## Bright major chord with pentatonic pitch variation.
	var pentatonic_roots: Array[float] = [523.0, 587.0, 659.0, 784.0, 880.0]
	var root: float = pentatonic_roots[randi() % pentatonic_roots.size()]
	play(node, _make_chord(root, root * 1.5, 0.25, 0.25))


static func play_heal(node: Node) -> void:
	## Gentle ascending fifth.
	play(node, _make_chord(330.0, 495.0, 0.3, 0.2))


static func play_burn(node: Node) -> void:
	## Harsh noise-toned descending.
	play(node, _make_sweep(1200.0, 400.0, 0.1, 0.25))


static func play_shield(node: Node) -> void:
	## Solid mid-tone ping.
	play(node, _make_tone(660.0, 0.12, 0.2))


static func play_phase_change(node: Node) -> void:
	## Dissonant minor 2nd (E3 + F3) for ominous phase transition.
	play(node, _make_chord(165.0, 175.0, 0.3, 0.2))


static func play_novel_word(node: Node) -> void:
	## Pure bright chime at C6 with harmonic shimmer.
	play(node, _make_tone(1047.0, 0.12, 0.18))


# --- Private Methods ---

static func _make_tone(
	freq: float,
	duration: float,
	volume: float = 0.3,
	fade_out: bool = true,
) -> AudioStreamWAV:
	## Generate a sine tone with optional harmonics for richer timbre.
	var num_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i: int in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		var envelope: float = volume
		if fade_out:
			var progress: float = float(i) / num_samples
			envelope = volume * (1.0 - progress * progress)

		var wave: float = sin(t * freq * TAU) * 0.75
		wave += sin(t * freq * 2.0 * TAU) * 0.15
		wave += sin(t * freq * 3.0 * TAU) * 0.07
		var sample_val: float = wave * envelope
		var sample_int: int = clampi(int(sample_val * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


static func _make_sweep(
	freq_start: float,
	freq_end: float,
	duration: float,
	volume: float = 0.3,
) -> AudioStreamWAV:
	## Generate a frequency sweep with harmonics.
	var num_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i: int in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / num_samples
		var freq: float = lerpf(freq_start, freq_end, progress)
		var envelope: float = volume * (1.0 - progress * progress)

		var wave: float = sin(t * freq * TAU) * 0.7
		wave += sin(t * freq * 2.0 * TAU) * 0.18
		wave += sin(t * freq * 3.0 * TAU) * 0.06
		var sample_val: float = wave * envelope
		var sample_int: int = clampi(int(sample_val * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


static func _make_click(
	duration: float = 0.03,
	volume: float = 0.2,
) -> AudioStreamWAV:
	## Noise burst with tonal attack transient.
	var num_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	for i: int in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / num_samples
		var envelope: float = volume * exp(-progress * 8.0)
		var noise: float = rng.randf_range(-1.0, 1.0)
		var tone: float = sin(t * 1200.0 * TAU)
		var sample_val: float = (noise * 0.6 + tone * 0.4) * envelope
		var sample_int: int = clampi(int(sample_val * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


static func _make_chord(
	freq1: float,
	freq2: float,
	duration: float,
	volume: float = 0.25,
) -> AudioStreamWAV:
	## Two-tone chord (for rewards, upgrades).
	var num_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i: int in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / num_samples
		var attack: float = minf(progress / 0.05, 1.0)
		var decay: float = 1.0 - (progress * progress)
		var envelope: float = volume * attack * decay
		var wave: float = sin(t * freq1 * TAU) * 0.45
		wave += sin(t * freq2 * TAU) * 0.35
		wave += sin(t * freq1 * 2.0 * TAU) * 0.1
		wave += sin(t * freq2 * 2.0 * TAU) * 0.08
		var sample_val: float = wave * envelope
		var sample_int: int = clampi(int(sample_val * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


static func _make_triad(
	freq1: float,
	freq2: float,
	freq3: float,
	duration: float,
	volume: float = 0.25,
) -> AudioStreamWAV:
	## Three-tone triad chord (for major payoffs).
	var num_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i: int in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / num_samples
		var attack: float = minf(progress / 0.03, 1.0)
		var decay: float = 1.0 - (progress * progress)
		var envelope: float = volume * attack * decay
		var wave: float = sin(t * freq1 * TAU) * 0.35
		wave += sin(t * freq2 * TAU) * 0.30
		wave += sin(t * freq3 * TAU) * 0.25
		wave += sin(t * freq1 * 2.0 * TAU) * 0.06
		wave += sin(t * freq3 * 2.0 * TAU) * 0.04
		var sample_val: float = wave * envelope
		var sample_int: int = clampi(int(sample_val * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream
