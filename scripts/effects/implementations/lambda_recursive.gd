class_name LambdaRecursiveDescentEffect
extends Effect

## Lambda (L): Branch completion bonus applies to partial branches.
## 2 of 3 filled = x1.5. Full 4+ slot branches get x3.0 instead of x2.5.
## This is a PASSIVE that modifies branch multiplier calculations.

@export var partial_multiplier: float = 1.5
@export var large_branch_multiplier: float = 3.0


func modify_value(base_value: int, context: EffectContext) -> int:
	# Delegates to CombatState's branch scoring with lambda flag
	context.combat_state.set_lambda_active(true)
	return base_value
