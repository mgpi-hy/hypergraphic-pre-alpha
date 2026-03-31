class_name CombatLog
extends RichTextLabel

## Left-panel combat log. BBCode-formatted scrolling text feed for scoring
## breakdowns, damage events, enemy attacks, and status changes.

# --- Constants ---

const COLOR_DIM := "#3A3A45"
const COLOR_WARNING := "#FFB300"
const COLOR_GOLD := "#FFD700"
const COLOR_WHITE := "#E2E2E8"
const COLOR_ALERT := "#FF1E40"
const COLOR_SUCCESS := "#00F090"
const COLOR_SHIELD := "#00D0FF"
const COLOR_INSULATION := "#CE93D8"

# --- Private Variables ---

var _current_turn: int = 1


# --- Virtual Methods ---

func _ready() -> void:
	bbcode_enabled = true
	scroll_following = true
	fit_content = false
	scroll_active = true
	selection_enabled = false
	custom_minimum_size = Vector2(160.0, 0.0)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_FILL
	ThemeManager.apply_mono_font(self, ThemeManager.FONT_MICRO)
	add_theme_color_override("default_color", ThemeManager.COLOR_TEXT_DIM)


# --- Public Methods ---

## Set the current turn number for log prefixes.
func set_turn(turn: int) -> void:
	_current_turn = turn


## Append a plain BBCode line with turn prefix.
func log_text(text_content: String) -> void:
	_append_line("[color=%s][T%d][/color] %s" % [COLOR_DIM, _current_turn, text_content])


## Format and log a full scoring breakdown.
## multipliers: Array of {"label": String, "value": float}
func log_scoring(word_form: String, base: int, multipliers: Array[Dictionary]) -> void:
	_append_line(
		"[color=%s][T%d][/color] [color=%s]%s[/color]"
		% [COLOR_DIM, _current_turn, COLOR_WHITE, word_form]
	)
	_append_line(
		"[color=%s][T%d][/color] [color=%s]Base induction: %d[/color]"
		% [COLOR_DIM, _current_turn, COLOR_WARNING, base]
	)
	var running: int = base
	for mult: Dictionary in multipliers:
		var label: String = mult.get("label", "")
		var value: float = mult.get("value", 1.0)
		running = maxi(int(float(running) * value), 1)
		var color: String = COLOR_GOLD if value >= 2.0 else COLOR_WARNING
		_append_line(
			"[color=%s][T%d][/color] [color=%s]  [x%.1f %s] -> %d[/color]"
			% [COLOR_DIM, _current_turn, color, value, label, running]
		)
	_append_line(
		"[color=%s][T%d][/color] [color=%s]  == TOTAL INDUCTION %d ==[/color]"
		% [COLOR_DIM, _current_turn, COLOR_WHITE, running]
	)


## Log damage dealt to a target.
func log_damage(target: String, amount: int) -> void:
	_append_line(
		"[color=%s][T%d][/color] [color=%s]%s takes %d damage[/color]"
		% [COLOR_DIM, _current_turn, COLOR_ALERT, target, amount]
	)


## Log enemy attack with optional absorbed amount.
func log_enemy_attack(enemy: String, damage: int, absorbed: int) -> void:
	if absorbed > 0:
		_append_line(
			"[color=%s][T%d][/color] [color=%s]%s attacks: %d dmg (%d absorbed)[/color]"
			% [COLOR_DIM, _current_turn, COLOR_ALERT, enemy, damage, absorbed]
		)
	else:
		_append_line(
			"[color=%s][T%d][/color] [color=%s]%s attacks: %d dmg[/color]"
			% [COLOR_DIM, _current_turn, COLOR_ALERT, enemy, damage]
		)


## Log insulation gain/loss.
func log_insulation(amount: int) -> void:
	_append_line(
		"[color=%s][T%d][/color] [color=%s]Insulation +%d[/color]"
		% [COLOR_DIM, _current_turn, COLOR_INSULATION, amount]
	)


## Log enemy defeat.
func log_defeat(enemy: String) -> void:
	_append_line(
		"[color=%s][T%d][/color] [color=%s]%s defeated[/color]"
		% [COLOR_DIM, _current_turn, COLOR_SUCCESS, enemy]
	)


## Clear all log contents.
func clear_log() -> void:
	clear()


# --- Private Methods ---

func _append_line(bbcode: String) -> void:
	append_text(bbcode + "\n")
