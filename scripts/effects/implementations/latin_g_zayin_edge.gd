class_name LatinGZayinEdgeEffect
extends Effect

## G - Zayin's Edge: Fill all required slots without filling any optionals
## = x1.75 multiplier. Tier 2: sets a multiplier flag on CombatState.

@export var multiplier: float = 1.75


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.all_required_filled() and not context.combat_state.any_optional_filled()


func execute(context: EffectContext) -> void:
	context.combat_state.add_submit_multiplier(multiplier)
