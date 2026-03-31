class_name LatinQQophExpansionEffect
extends Effect

## Q - Qoph's Expansion: Relic cap +1 (10 to 11). Can't drop below
## 2 relics. Tier 2: modifier on RunState applied at acquisition.

@export var cap_increase: int = 1


func activate(context: EffectContext) -> void:
	context.combat_state.increase_relic_cap(cap_increase)


func deactivate() -> void:
	pass
