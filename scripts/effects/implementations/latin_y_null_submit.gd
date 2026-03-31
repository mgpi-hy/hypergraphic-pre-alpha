class_name LatinYNullSubmitEffect
extends Effect

## Y - Null Submit: When you submit 0 words in a turn, shuffle hand into
## draw pile instead of discarding. Tier 2: sets a flag on CombatState
## that the submit phase checks.


func execute(context: EffectContext) -> void:
	context.combat_state.set_null_submit_available(true)
