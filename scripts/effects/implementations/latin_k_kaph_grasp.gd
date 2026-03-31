class_name LatinKKaphGraspEffect
extends Effect

## K - Kaph's Grasp: Retain 1 unplaced morpheme between turns.
## Tier 2: sets the retain flag on CombatState so the discard phase
## skips one morpheme.


func execute(context: EffectContext) -> void:
	context.combat_state.set_kaph_retain(true)
