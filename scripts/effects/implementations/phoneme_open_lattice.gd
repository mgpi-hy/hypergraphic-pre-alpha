class_name PhonemeOpenLatticeEffect
extends Effect

## Epsilon (ɛ): Open Lattice. Add a wildcard slot. If filled
## with a Greek root, draw 2.

@export var greek_bonus_draw: int = 2


func execute(context: EffectContext) -> void:
	context.combat_state.add_wildcard_slot(greek_bonus_draw)
