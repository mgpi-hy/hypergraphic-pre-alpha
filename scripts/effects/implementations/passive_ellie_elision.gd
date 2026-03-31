class_name PassiveEllieElisionEffect
extends Effect

## Ellie (Elision): x1.25 per empty optional slot at submission.
## PASSIVE: modifies the final multiplier based on empty optionals.

@export var multiplier_per_slot: float = 1.25


func modify_value(base_value: int, context: EffectContext) -> int:
	var empty_optionals: int = context.combat_state.count_empty_optional_slots()
	if empty_optionals <= 0:
		return base_value
	# Apply multiplicative bonus: each empty optional multiplies by 1.25
	var result: float = float(base_value)
	for i: int in range(empty_optionals):
		result *= multiplier_per_slot
	return roundi(result)
