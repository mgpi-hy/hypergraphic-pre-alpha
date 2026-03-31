class_name PhonemeRetroflexScatterEffect
extends Effect

## Retroflex D (ɖ): Retroflex Scatter. Randomize all enemy intents
## and shuffle order. 30% chance one enemy attacks twice next turn.

@export var double_attack_chance: float = 0.3


func execute(context: EffectContext) -> void:
	context.combat_state.reroll_all_enemy_intents()
	context.combat_state.shuffle_enemy_order()
	if randf() < double_attack_chance:
		context.combat_state.set_random_enemy_double_attack()
