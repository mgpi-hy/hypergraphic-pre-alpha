class_name POSColors
extends RefCounted

## POS syntax highlighting palette. Maps part-of-speech tags to terminal colors.

# --- Constants ---
const COLORS: Dictionary = {
	"noun": Color("#FF5252"),
	"verb": Color("#69F0AE"),
	"adjective": Color("#80D8FF"),
	"adj": Color("#80D8FF"),
	"adverb": Color("#448AFF"),
	"adv": Color("#448AFF"),
	"determiner": Color("#757575"),
	"det": Color("#757575"),
	"preposition": Color("#757575"),
	"prep": Color("#757575"),
	"conjunction": Color("#757575"),
	"conj": Color("#757575"),
	"prefix": Color("#AAAAAA"),
	"suffix": Color("#AAAAAA"),
	"root": Color("#CCCCCC"),
	"default": Color("#AAAAAA"),
}

const SLOT_EMPTY_BORDER := Color("#37474F")
const SLOT_VALID_HOVER := Color("#00E676")
const SLOT_INVALID_HOVER := Color("#FF1744")
const TREE_BRANCH := Color("#546E7A")
const SHIELD_COLOR := Color("#40C4FF")
const DAMAGE_COLOR := Color("#FFEB3B")
const SEMANT_COLOR := Color("#CE93D8")
const BG_BRAINSTEM := Color("#0A0A0A")
const TEXT_BRAINSTEM := Color("#33FF33")

# --- Public Methods ---

static func get_color(pos_or_type: String) -> Color:
	if COLORS.has(pos_or_type):
		return COLORS[pos_or_type]
	return COLORS["default"]
