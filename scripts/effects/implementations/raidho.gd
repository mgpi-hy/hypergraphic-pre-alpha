class_name RaidhoEffect
extends Effect

## Raidho (ᚱ): Journey Rune. +1 induction per floor cleared (caps +10).

@export var bonus_per_floor: int = 1
@export var max_bonus: int = 10


func modify_value(base_value: int, context: EffectContext) -> int:
	var floors_cleared: int = context.combat_state.floors_cleared
	var bonus: int = mini(floors_cleared * bonus_per_floor, max_bonus)
	return base_value + bonus
