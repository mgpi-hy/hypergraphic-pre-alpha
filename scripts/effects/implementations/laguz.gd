class_name LaguzEffect
extends Effect

## Laguz (ᛚ): Auto-Slot. After submitting a word, if the next slot in that
## branch is empty, auto-slot the first valid morpheme from hand.

func execute(context: EffectContext) -> void:
	context.combat_state.set_auto_slot_enabled(true)
