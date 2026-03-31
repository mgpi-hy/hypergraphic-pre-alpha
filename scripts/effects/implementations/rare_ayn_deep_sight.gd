class_name RareAynDeepSightEffect
extends Effect

## Ayn (ع): Deep Sight. See exact induction values before submitting.
## Tier 2: sets a visibility flag on CombatState.

func execute(context: EffectContext) -> void:
	context.combat_state.set_induction_preview_visible(true)
