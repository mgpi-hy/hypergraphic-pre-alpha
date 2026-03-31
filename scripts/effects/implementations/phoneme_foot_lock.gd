class_name PhonemeFootLockEffect
extends Effect

## Horseshoe (ʊ): Foot Lock. Reroll all enemy intents.

func execute(context: EffectContext) -> void:
	context.combat_state.reroll_all_enemy_intents()
