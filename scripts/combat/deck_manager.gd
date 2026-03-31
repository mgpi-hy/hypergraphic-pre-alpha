class_name DeckManager
extends RefCounted

## Manages the StS-style deck cycle: draw pile, hand, discard pile, exhaust pile.
## Pure data + methods. No Node dependencies, no signals, no UI.

# --- Constants ---

const DEFAULT_HAND_SIZE: int = 7

# --- Public Variables ---

var draw_pile: Array[MorphemeData] = []
var hand: Array[MorphemeData] = []
var discard_pile: Array[MorphemeData] = []
var exhaust_pile: Array[MorphemeData] = []
var max_hand_size: int = DEFAULT_HAND_SIZE


# --- Initialization ---

## Populate deck from a morpheme array (duplicates each entry).
func init_from_deck(deck: Array[MorphemeData], starter_hand_size: int) -> void:
	max_hand_size = starter_hand_size
	draw_pile.clear()
	for morpheme: MorphemeData in deck:
		draw_pile.append(morpheme.duplicate())
	shuffle_draw_pile()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()


# --- Draw / Discard / Exhaust ---

## Draw morphemes from draw pile into hand, reshuffling if needed.
## Capped at max_hand_size so the hand can never overflow.
func draw_morphemes(count: int) -> void:
	var space: int = maxi(max_hand_size - hand.size(), 0)
	var actual_count: int = mini(count, space)
	for i: int in range(actual_count):
		if draw_pile.is_empty():
			shuffle_discard_into_draw()
		if draw_pile.is_empty():
			return
		hand.append(draw_pile.pop_back())


## Discard a specific morpheme from hand.
func discard_morpheme(morpheme: MorphemeData) -> void:
	var idx: int = hand.find(morpheme)
	if idx < 0:
		return
	hand.remove_at(idx)
	discard_pile.append(morpheme)


## Discard morphemes from the end of hand.
func discard_morphemes(count: int) -> void:
	for i: int in range(mini(count, hand.size())):
		if hand.is_empty():
			return
		discard_pile.append(hand.pop_back())


## Shuffle discard pile into draw pile.
func shuffle_discard_into_draw() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	shuffle_draw_pile()


## Shuffle draw pile in place.
func shuffle_draw_pile() -> void:
	draw_pile.shuffle()


## Permanently remove a morpheme from hand.
func exhaust_morpheme(morpheme: MorphemeData) -> void:
	var idx: int = hand.find(morpheme)
	if idx < 0:
		return
	hand.remove_at(idx)
	exhaust_pile.append(morpheme)


## Move all discards back into hand (wynn lost letter).
func recall_all_discards() -> void:
	hand.append_array(discard_pile)
	discard_pile.clear()


## Duplicate a random discard into hand (mu morpheme echo).
func duplicate_random_discard_to_hand() -> void:
	if discard_pile.is_empty():
		return
	hand.append(discard_pile[randi() % discard_pile.size()].duplicate())


# --- Pile Queries ---

func hand_size() -> int:
	return hand.size()


func draw_pile_size() -> int:
	return draw_pile.size()


func discard_pile_size() -> int:
	return discard_pile.size()


## Count distinct morpheme families in hand.
func hand_family_count() -> int:
	var families: Dictionary = {}
	for m: MorphemeData in hand:
		families[m.family] = true
	return families.size()


## Increase max hand size (eta long measure).
func increase_hand_size(bonus: int) -> void:
	max_hand_size += bonus
