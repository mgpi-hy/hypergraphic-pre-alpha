class_name EventScreen
extends ScreenState

## Aphasia Event: random linguistic encounters between combats.
## Presents a narrative event with 2-3 choices that modify run state.
## Outcomes are encoded in the choice data as {cogency, semant, insulation, draw}
## deltas, resolved generically without per-event match branches.

# --- Constants ---

const SCENE_MAP: String = "res://scenes/screens/map_screen.tscn"

# --- Private Variables ---

var _event_index: int = -1
var _choice_made: bool = false
var _main_content: VBoxContainer = null
var _choice_container: VBoxContainer = null
var _result_container: VBoxContainer = null
var _map: Variant = null

# --- Event Data ---
# Each choice has: text, color, result_text, and optional stat deltas:
#   cog (cogency), sem (semant), ins (next combat insulation), drw (next combat draw)

static func _events() -> Array[Dictionary]:
	return [
		{"name": "SEMANTIC DRIFT", "color": ThemeManager.COLOR_INSULATION, "min_region": 0,
			"flavor": "A word in your cortex shifts meaning. The signifier detaches from its signified, drifting through associative space.",
			"choices": [
				{"text": "Accept the drift (+5 semant)", "color": ThemeManager.COLOR_SUCCESS, "result": "The meaning shifts. New connections form.", "sem": 5},
				{"text": "Reject the mutation (no change)", "color": ThemeManager.COLOR_TEXT_DIM, "result": "Stability preserved."},
				{"text": "Prune the dead branch (+8 semant, -3 COG)", "color": ThemeManager.COLOR_ALERT, "result": "Pruned. +8 semant, -3 COG.", "sem": 8, "cog": -3},
		]},
		{"name": "LOAN WORD", "color": ThemeManager.COLOR_GOLD, "min_region": 0,
			"flavor": "A foreign morpheme surfaces from deep substrate. It carries the grammar of another language family, loan-shifted through centuries of neural drift.",
			"choices": [
				{"text": "Accept the loan word (-3 COG, +10 semant)", "color": ThemeManager.COLOR_SUCCESS, "result": "The foreign root takes hold. -3 COG, +10 semant.", "cog": -3, "sem": 10},
				{"text": "Decline (purity has its costs)", "color": ThemeManager.COLOR_TEXT_DIM, "result": "Purity maintained. The loan word fades."},
		]},
		{"name": "PHONOLOGICAL SHIFT", "color": ThemeManager.COLOR_WARNING, "min_region": 0,
			"flavor": "The Great Vowel Shift echoes through your synapses. Sound changes cascade, breaking old patterns.",
			"choices": [
				{"text": "Embrace the shift (-5 COG, +12 semant)", "color": ThemeManager.COLOR_WARNING, "result": "Sound changes cascade. -5 COG, +12 semant.", "cog": -5, "sem": 12},
				{"text": "Resist (keep cogency, gain nothing)", "color": ThemeManager.COLOR_TEXT_DIM, "result": "You resist. The vowels hold their positions."},
		]},
		{"name": "LEXICAL GAP", "color": ThemeManager.COLOR_ALERT, "min_region": 0,
			"flavor": "A hole opens in your lexicon. Something crystallizes in the gap: precise and consumable.",
			"choices": [
				{"text": "Let it go (-4 COG, +8 semant)", "color": ThemeManager.COLOR_ALERT, "result": "A gap opens. Something fills it. -4 COG, +8 semant.", "cog": -4, "sem": 8},
				{"text": "Hold on (keep your deck intact)", "color": ThemeManager.COLOR_TEXT_DIM, "result": "You hold on. The gap remains unfilled."},
		]},
		{"name": "ETYMOLOGICAL DISCOVERY", "color": ThemeManager.COLOR_SUCCESS, "min_region": 0,
			"flavor": "You trace a root back through Proto-Indo-European, through branch points and Grimm's Law.",
			"choices": [
				{"text": "Study the etymology (+5 semant, +2 COG)", "color": ThemeManager.COLOR_SUCCESS, "result": "The roots reveal their history. +5 semant, +2 COG.", "sem": 5, "cog": 2},
				{"text": "Move on (no time for scholarship)", "color": ThemeManager.COLOR_TEXT_DIM, "result": "No time for etymology. You press on."},
		]},
		{"name": "MEMORY FRAGMENT", "color": ThemeManager.COLOR_GOLD, "min_region": 0,
			"flavor": "A shard of language surfaces from deep storage, pre-semantic, half-dissolved.",
			"choices": [
				{"text": "Retrieve the fragment (+3 COG)", "color": ThemeManager.COLOR_SUCCESS, "result": "A fragment surfaces from deep storage. +3 COG.", "cog": 3},
				{"text": "Let it dissolve (+18 semant)", "color": ThemeManager.COLOR_GOLD, "result": "The fragment dissolves into currency. +18 semant.", "sem": 18},
		]},
		{"name": "NEURAL FORK", "color": ThemeManager.COLOR_WARNING, "min_region": 0,
			"flavor": "The pathway bifurcates. Left: myelinated, safe. Right: raw axon, more bandwidth. Always more bandwidth.",
			"choices": [
				{"text": "Safe route: myelinated pathway (+8 COG)", "color": ThemeManager.COLOR_SUCCESS, "result": "The myelinated pathway. Safe. +8 COG.", "cog": 8},
				{"text": "Risky route: raw axon (-5 COG, +20 semant)", "color": ThemeManager.COLOR_ALERT, "result": "Raw axon. Signal degrades but bandwidth surges. -5 COG, +20 semant.", "cog": -5, "sem": 20},
		]},
		{"name": "PHANTOM LIMB", "color": ThemeManager.COLOR_INSULATION, "min_region": 0,
			"flavor": "You feel a word that isn't there. The phantom morpheme aches, a lexical limb severed long ago.",
			"choices": [
				{"text": "Embrace the phantom (+3 insulation next combat)", "color": ThemeManager.COLOR_SHIELD, "result": "The phantom solidifies. +3 insulation next combat.", "ins": 3},
				{"text": "Ignore it (phantoms are distractions)", "color": ThemeManager.COLOR_TEXT_DIM, "result": "You ignore the phantom. It fades."},
		]},
		{"name": "HYPERGRAPHIC EPISODE", "color": ThemeManager.COLOR_SUCCESS, "min_region": 0,
			"flavor": "The pressure builds behind your eyes. Words demanding to be written. If not released it will build up.",
			"choices": [
				{"text": "Write it out (-3 COG, +15 semant, +1 draw)", "color": ThemeManager.COLOR_SUCCESS, "result": "The words pour out. -3 COG, +15 semant, +1 draw.", "cog": -3, "sem": 15, "drw": 1},
				{"text": "Suppress it (the pressure remains)", "color": ThemeManager.COLOR_TEXT_DIM, "result": "You swallow the words. The pressure builds."},
		]},
		{"name": "GRIMM'S LAW", "color": ThemeManager.COLOR_WARNING, "min_region": 0,
			"flavor": "The consonants shift. p becomes f, t becomes th, k becomes h. A systematic transformation.",
			"choices": [
				{"text": "Apply the law (+10 semant)", "color": ThemeManager.COLOR_WARNING, "result": "The consonants shift. +10 semant.", "sem": 10},
				{"text": "Resist the shift (maintain stability)", "color": ThemeManager.COLOR_TEXT_DIM, "result": "The consonants hold. Stability over transformation."},
		]},
		{"name": "BROCA'S WHISPER", "color": ThemeManager.COLOR_SHIELD, "min_region": 1,
			"flavor": "The speech production center hums. Words form without volition, syntax assembles itself.",
			"choices": [
				{"text": "Listen closely (+5 COG, +5 semant)", "color": ThemeManager.COLOR_SHIELD, "result": "The whisper resolves into clarity. +5 COG, +5 semant.", "cog": 5, "sem": 5},
				{"text": "Shut it out (silence is also language)", "color": ThemeManager.COLOR_TEXT_DIM, "result": "Silence. The whisper dies unheard."},
		]},
		{"name": "DEAD LANGUAGE", "color": ThemeManager.COLOR_ALERT, "min_region": 1,
			"flavor": "A root from a dead language surfaces. No living speaker. Just raw morphological potential.",
			"choices": [
				{"text": "Excavate the root (-5 COG, +3 draw)", "color": ThemeManager.COLOR_SUCCESS, "result": "The dead root stirs. -5 COG, +3 draw next combat.", "cog": -5, "drw": 3},
				{"text": "Let the dead stay dead", "color": ThemeManager.COLOR_TEXT_DIM, "result": "The dead stay buried."},
				{"text": "Sell the artifact (+25 semant)", "color": ThemeManager.COLOR_GOLD, "result": "The artifact fetches a good price. +25 semant.", "sem": 25},
		]},
		{"name": "APHASIC EPISODE", "color": ThemeManager.COLOR_ALERT, "min_region": 1,
			"flavor": "Language collapses. Words scatter. For a moment, every morpheme is a stranger.",
			"choices": [
				{"text": "Ride it out (-8 COG, +20 semant)", "color": ThemeManager.COLOR_ALERT, "result": "Language breaks. You survive the silence. -8 COG, +20 semant.", "cog": -8, "sem": 20},
				{"text": "Fight it (no effect)", "color": ThemeManager.COLOR_TEXT_DIM, "result": "You fight through. Language holds, barely."},
		]},
		{"name": "WERNICKE'S ECHO", "color": ThemeManager.COLOR_INSULATION, "min_region": 1,
			"flavor": "Words come easily but mean nothing. Fluent, grammatical, empty.",
			"choices": [
				{"text": "Find meaning in the noise (+10 semant)", "color": ThemeManager.COLOR_INSULATION, "result": "Signal in the noise. +10 semant.", "sem": 10},
				{"text": "Stop talking (+3 COG)", "color": ThemeManager.COLOR_TEXT_DIM, "result": "Silence restores. +3 COG.", "cog": 3},
		]},
		{"name": "SYNAPTIC SURPLUS", "color": ThemeManager.COLOR_SUCCESS, "min_region": 0,
			"flavor": "An unexpected neural windfall. Extra bandwidth, extra capacity.",
			"choices": [
				{"text": "Invest in offense (+2 draw next combat)", "color": ThemeManager.COLOR_WARNING, "result": "Bandwidth allocated to offense. +2 draw.", "drw": 2},
				{"text": "Invest in defense (+5 insulation next combat)", "color": ThemeManager.COLOR_SHIELD, "result": "Bandwidth allocated to defense. +5 insulation.", "ins": 5},
				{"text": "Cash out (+15 semant)", "color": ThemeManager.COLOR_GOLD, "result": "Surplus liquidated. +15 semant.", "sem": 15},
		]},
		{"name": "CORPUS CALLOSUM BRIDGE", "color": ThemeManager.COLOR_SHIELD, "min_region": 2,
			"flavor": "The bridge between hemispheres widens. Cross-domain synthesis becomes trivially easy.",
			"choices": [
				{"text": "Cross the bridge (+8 COG, +8 semant)", "color": ThemeManager.COLOR_SHIELD, "result": "The bridge holds. +8 COG, +8 semant.", "cog": 8, "sem": 8},
				{"text": "Stay on your side (the familiar is safer)", "color": ThemeManager.COLOR_TEXT_DIM, "result": "You stay on your side. Safe, if limited."},
		]},
		{"name": "ECSTATIC AURA", "color": ThemeManager.COLOR_GOLD, "min_region": 2,
			"flavor": "The pre-ictal aura washes over you. Every word glows. Every syllable hums. It feels good. It feels too good.",
			"choices": [
				{"text": "Surrender to it (-10 COG, +30 semant, +3 draw)", "color": ThemeManager.COLOR_GOLD, "result": "The aura crests. Everything glows. -10 COG, +30 semant, +3 draw.", "cog": -10, "sem": 30, "drw": 3},
				{"text": "Ground yourself (+5 COG)", "color": ThemeManager.COLOR_TEXT_DIM, "result": "You ground yourself. The moment passes. +5 COG.", "cog": 5},
		]},
	]


# --- Virtual Methods ---

func enter(previous: String, data: Dictionary = {}) -> void:
	super.enter(previous, data)
	_map = data.get("map", null)
	_select_event()
	_build_ui()


# --- Private Methods ---

func _select_event() -> void:
	var events: Array[Dictionary] = _events()
	var region_index: int = 0
	if GameManager.run != null:
		region_index = GameManager.run.current_region_index
	var eligible: Array[int] = []
	for i: int in events.size():
		if (events[i].get("min_region", 0) as int) <= region_index:
			eligible.append(i)
	if eligible.is_empty():
		_event_index = 0
		return
	eligible.shuffle()
	_event_index = eligible[0]


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.color = ThemeManager.COLOR_VOID
	add_child(bg)
	ThemeManager.build_unicode_grid(self, "wernicke's area", 4, 0.02)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	_main_content = VBoxContainer.new()
	_main_content.add_theme_constant_override("separation", 20)
	_main_content.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(_main_content)

	var event: Dictionary = _events()[_event_index]

	var header := Label.new()
	header.text = "═══ %s ═══" % event["name"]
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(header, ThemeManager.FONT_H1)
	ThemeManager.apply_glow_text(header, event.get("color", ThemeManager.COLOR_INSULATION) as Color)
	_main_content.add_child(header)

	var flavor := Label.new()
	flavor.text = event["flavor"] as String
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeManager.apply_mono_font(flavor, ThemeManager.FONT_BODY)
	flavor.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	_main_content.add_child(flavor)

	var sep := Label.new()
	sep.text = "────────────────────────────────────────"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeManager.apply_mono_font(sep, ThemeManager.FONT_MICRO)
	sep.add_theme_color_override("font_color", ThemeManager.COLOR_TEXT_DIM)
	_main_content.add_child(sep)

	_choice_container = VBoxContainer.new()
	_choice_container.add_theme_constant_override("separation", 12)
	_choice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_content.add_child(_choice_container)

	var choices: Array = event["choices"] as Array
	for i: int in choices.size():
		var choice: Dictionary = choices[i] as Dictionary
		var btn := Button.new()
		btn.text = choice["text"] as String
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.custom_minimum_size = Vector2(500, 40)
		ThemeManager.apply_mono_font(btn, ThemeManager.FONT_BODY)
		ThemeManager.apply_button_style(btn, choice.get("color", ThemeManager.COLOR_TEXT_MAIN) as Color)
		btn.pressed.connect(_on_choice.bind(i))
		_choice_container.add_child(btn)

	_result_container = VBoxContainer.new()
	_result_container.add_theme_constant_override("separation", 16)
	_result_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_result_container.visible = false
	_main_content.add_child(_result_container)


func _on_choice(choice_index: int) -> void:
	if _choice_made:
		return
	_choice_made = true
	_choice_container.visible = false

	var event: Dictionary = _events()[_event_index]
	var choices: Array = event["choices"] as Array
	if choice_index >= choices.size():
		_show_result("Nothing happens.")
		return

	var choice: Dictionary = choices[choice_index] as Dictionary
	var run: RunData = GameManager.run if GameManager.run != null else null

	# Apply stat deltas from choice data
	if run != null:
		var cog_delta: int = choice.get("cog", 0) as int
		if cog_delta > 0:
			run.heal(cog_delta)
		elif cog_delta < 0:
			run.take_damage(-cog_delta)

		var sem_delta: int = choice.get("sem", 0) as int
		if sem_delta > 0:
			run.add_semant(sem_delta)

		var ins_delta: int = choice.get("ins", 0) as int
		if ins_delta > 0:
			run.next_combat_extra_insulation += ins_delta

		var drw_delta: int = choice.get("drw", 0) as int
		if drw_delta > 0:
			run.next_combat_extra_draw += drw_delta

	_show_result(choice.get("result", "Done.") as String)


func _show_result(text: String) -> void:
	_result_container.visible = true

	var result_label := Label.new()
	result_label.text = text
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeManager.apply_mono_font(result_label, ThemeManager.FONT_BODY)
	ThemeManager.apply_glow_text(result_label, ThemeManager.COLOR_TEXT_MAIN)
	_result_container.add_child(result_label)

	var continue_btn := Button.new()
	continue_btn.text = "[ CONTINUE ]"
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ThemeManager.apply_mono_font(continue_btn, ThemeManager.FONT_BODY)
	ThemeManager.apply_button_style(continue_btn, ThemeManager.COLOR_SUCCESS)
	continue_btn.pressed.connect(_on_continue)
	_result_container.add_child(continue_btn)


func _on_continue() -> void:
	var data: Dictionary = {}
	if _map != null:
		data["map"] = _map
	finished.emit(SCENE_MAP, data)
