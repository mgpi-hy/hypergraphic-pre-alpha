class_name RareEfFamilyToleranceEffect
extends Effect

## Ef (Ф): Family Tolerance. Family mixing penalty reduced
## from x0.75 to x0.85.
## PASSIVE: modifies the family mix penalty value.

@export var reduced_penalty: float = 0.85


func modify_value(base_value: int, _context: EffectContext) -> int:
	# Modifies the family-mix penalty when polled by DamageResolver.
	# base_value is the penalty as int (75 = 0.75). Return 85 = 0.85.
	return roundi(reduced_penalty * 100.0)
