class_name PhonemeStrutGuardEffect
extends Effect

## Wedge (ʌ): Strut Guard. Halve enemy base damage for 2 turns.

@export var weaken_turns: int = 2


func execute(context: EffectContext) -> void:
	context.combat_state.weaken_target_enemy(weaken_turns)
