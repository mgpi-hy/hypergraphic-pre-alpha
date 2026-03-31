class_name PhonemeData
extends Resource

## A phoneme: single-use combat consumable represented by an IPA symbol.
## Powerful effects with meaningful tradeoffs. 18 total.

# --- Enums ---

enum Rarity { COMMON, UNCOMMON, RARE }

# --- Exports: Identity ---

## Unique string identifier (e.g. "schwa", "velar_gambit")
@export var id: String = ""

## Human-readable name shown in UI (e.g. "Reduction", "Velar Gambit")
@export var display_name: String = ""

## IPA symbol displayed (e.g. unicode schwa, theta)
@export var ipa_symbol: String = ""

## Description text explaining what this phoneme does
@export_multiline var description: String = ""

# --- Exports: Classification ---

## Rarity tier affecting drop rates and shop pricing
@export var rarity: Rarity = Rarity.COMMON

## Whether this phoneme is consumed on use (most are; false for persistent ones)
@export var is_consumable: bool = true

# --- Exports: Economy ---

## Semant cost to purchase in shop
@export_range(0, 100) var semant_cost: int = 5

# --- Exports: Effects ---

## Effect resources triggered when this phoneme is activated
@export var effects: Array[Effect] = []
