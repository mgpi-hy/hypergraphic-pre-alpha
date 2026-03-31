class_name PassivePhilCompoundRootsEffect
extends Effect

## Phil (Compounding): Up to 4 roots x1.1 each. Words with multiple
## roots get multiplicative scaling.
## PASSIVE: modifies induction based on root count in the word.

@export var multiplier_per_root: float = 1.1
@export var max_roots: int = 4


func modify_value(base_value: int, context: EffectContext) -> int:
	var root_count: int = 0
	for m: MorphemeData in context.morphemes:
		if m.type == "root":
			root_count += 1
	root_count = mini(root_count, max_roots)
	if root_count <= 1:
		return base_value
	var result: float = float(base_value)
	for i: int in range(root_count):
		result *= multiplier_per_root
	return roundi(result)
