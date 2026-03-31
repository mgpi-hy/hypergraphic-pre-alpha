class_name LatinHHeWindowEffect
extends Effect

## H - He's Window: Once per turn, placing a root on an occupied slot
## swaps it (old root returns to hand). Tier 2: sets a flag on CombatState
## at turn start enabling the swap mechanic.


func execute(context: EffectContext) -> void:
	context.combat_state.set_he_window_available(true)
