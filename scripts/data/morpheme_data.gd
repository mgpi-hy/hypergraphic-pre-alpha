class_name MorphemeData
extends Resource

## A single morpheme block: root, prefix, suffix, or infix.
## The atomic unit of the player's deck. Placed in syntax tree slots during combat.

# --- Enums ---

enum MorphemeType { ROOT, PREFIX, SUFFIX, INFIX }

enum CombatRole { CONTENT, FUNCTIONAL, HYBRID }

enum Charge { CHARGED, NEUTRAL, NULL }

enum Rarity { COMMON, UNCOMMON, RARE, MYTHIC, LEGENDARY }

# --- Exports: Identity ---

## Unique string identifier for this morpheme (e.g. "rupt", "pre", "un")
@export var id: String = ""

## Human-readable name shown in UI
@export var display_name: String = ""

## The morpheme text placed in the syntax tree (e.g. "rupt", "pre")
@export var root_text: String = ""

## IPA transcription of the morpheme
@export var ipa: String = ""

## Etymological family this morpheme belongs to
@export var family: Enums.MorphemeFamily = Enums.MorphemeFamily.GERMANIC

# --- Exports: Morphological Properties ---

## Part of speech this morpheme fills
@export var pos_type: Enums.POSType = Enums.POSType.NOUN

## Root, prefix, suffix, or infix
@export var type: MorphemeType = MorphemeType.ROOT

## True if this morpheme is an affix (prefix/suffix/infix), false for roots
@export var is_affix: bool = false

## Number of affix slots this root provides (0 for affixes themselves)
@export_range(0, 5) var affix_slots: int = 0

## Which morpheme types may precede this one in a word
@export var allowed_preceding: Array[String] = []

## Which morpheme types may follow this one in a word
@export var allowed_following: Array[String] = []

# --- Exports: Combat Stats ---

## Base induction value (damage contribution). Mapped from old semantic_weight.
@export_range(1, 20) var base_induction: int = 5

## Combat function: content word, functional word, or hybrid
@export var combat_role: CombatRole = CombatRole.CONTENT

## Charge state for special interactions
@export var charge: Charge = Charge.NULL

# --- Exports: Economy ---

## Rarity tier affecting drop rates and shop pricing
@export var rarity: Rarity = Rarity.COMMON

## Number of syllables (affects stress rules and some effects)
@export var syllable_count: int = 1

# --- Exports: Effects ---

## Effect resources triggered by this morpheme (affix effects, on-play, etc.)
@export var effects: Array[Effect] = []

# --- Exports: Metadata ---

## Known real words this morpheme can form (for novel word detection)
@export var known_words: Array[String] = []

## Default stress pattern (array of syllable indices)
@export var default_stress: Array[int] = [0]

## Stress rule applied when this morpheme is part of a word
@export var stress_rule: String = "none"

## Description text shown in tooltips
@export_multiline var description: String = ""
