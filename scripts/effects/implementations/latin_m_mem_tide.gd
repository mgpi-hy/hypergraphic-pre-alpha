class_name LatinMMemTideEffect
extends Effect

## M - Mem's Tide: Full tree submit = +3 induction to all words next turn.
## Triggers ON_PLAY. If tree was full, sets a bonus flag on CombatState
## that applies next turn.

@export var induction_bonus: int = 3


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.is_full_tree


func execute(context: EffectContext) -> void:
	context.combat_state.set_mem_tide_bonus(induction_bonus)
