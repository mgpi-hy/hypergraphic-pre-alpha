class_name RareLongDragonEffect
extends Effect

## Long (龍): Dragon Scale. 3+ relics: all additive relic bonuses +1.
## Also: lose 3 cogency at start of each combat (cost).
## PASSIVE: modifies additive bonus values.

@export var bonus_per_relic: int = 1
@export var combat_start_cost: int = 3
@export var min_relic_count: int = 3


func modify_value(base_value: int, context: EffectContext) -> int:
	if context.combat_state.grapheme_count() >= min_relic_count:
		return base_value + bonus_per_relic
	return base_value
