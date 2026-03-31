class_name LatinXSamekhScaffoldEffect
extends Effect

## X - Samekh's Scaffold: Optional slots generate x1.75 instead of x1.5
## when filled. Tier 2: sets the upgraded optional multiplier on CombatState.

@export var upgraded_optional_mult: float = 1.75


func execute(context: EffectContext) -> void:
	context.combat_state.set_optional_slot_multiplier(upgraded_optional_mult)
