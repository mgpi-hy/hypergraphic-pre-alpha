extends Node

## Combat
signal turn_started(turn_number: int)
signal turn_ended
signal damage_dealt(amount: int, source: Node, target: Node)
signal card_played(card: MorphemeData)
signal word_submitted(word: String, induction: int)
signal enemy_defeated(enemy: EnemyData)
signal combat_won
signal combat_lost

## Progression
signal map_node_selected(node_type: String, column: int)
signal region_entered(region: RegionData)
signal region_choices_available(regions: Array)  ## Array[RegionData]
signal run_started(character: CharacterData)
signal run_ended(won: bool)

## Economy
signal semant_changed(new_value: int)
signal cogency_changed(new_value: int)
signal grapheme_acquired(grapheme: GraphemeData)
signal morpheme_added(morpheme: MorphemeData)
signal morpheme_removed(morpheme: MorphemeData)

## Effects/Items
signal insulation_changed(new_value: int)
signal phoneme_used(phoneme: PhonemeData)
signal grapheme_effect_triggered(grapheme: GraphemeData, effect: Effect)
signal affix_attached(morpheme: MorphemeData, affix: MorphemeData)
signal multiplier_applied(multiplier_value: int)

## UI
signal screen_transition_requested(scene_path: String)
signal tooltip_requested(text: String, position: Vector2)
signal tooltip_dismissed
