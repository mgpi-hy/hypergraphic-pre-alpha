class_name GraphemeData
extends Resource

## A grapheme: passive permanent item that persists for the entire run.
## Acquired between combats. Each has 1-3 effects that trigger on conditions.
## 100 total across 4 script families (Latin, Runic, Greek, CJK).

# --- Enums ---

enum Rarity { COMMON, UNCOMMON, RARE, MYTHIC, LEGENDARY }

enum AcquisitionType { STANDARD, SHOP_ONLY, BOSS_ONLY, STARTER }

# --- Exports: Identity ---

## Unique string identifier (e.g. "algiz", "latin_a")
@export var id: String = ""

## Human-readable name shown in UI
@export var display_name: String = ""

## The glyph displayed (e.g. "A", unicode rune)
@export var symbol: String = ""

## Description text explaining what this grapheme does
@export_multiline var description: String = ""

# --- Exports: Classification ---

## Which script family this grapheme belongs to
@export var family: Enums.GraphemeFamily = Enums.GraphemeFamily.LATIN

## Rarity tier affecting drop rates and shop pricing
@export var rarity: Rarity = Rarity.COMMON

## How this grapheme can be acquired
@export var acquisition: AcquisitionType = AcquisitionType.STANDARD

# --- Exports: Economy ---

## Semant cost to purchase in shop
@export_range(0, 100) var semant_cost: int = 15

# --- Exports: Effects ---

## Effect resources triggered by this grapheme (registered on acquisition)
@export var effects: Array[Effect] = []

# --- Exports: Visual ---

## Icon texture for UI display (optional; falls back to symbol text)
@export var icon: Texture2D
