class_name LatinJYodCrownEffect
extends Effect

## J - Yod's Crown: Random POS slot becomes wild each turn.
## Words placed in the wild slot get x2.0. Tier 2: sets the wild slot
## index on CombatState at turn start.

@export var wild_multiplier: float = 2.0


func execute(context: EffectContext) -> void:
	context.combat_state.set_yod_crown_wild_slot(wild_multiplier)
