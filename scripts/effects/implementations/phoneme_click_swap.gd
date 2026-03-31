class_name PhonemeClickSwapEffect
extends Effect

## Bilabial Click (ʘ): Click Swap. Swap roots between hand and
## discard. Swapped-in roots matching tree POS gain +3 induction.

@export var pos_match_bonus: int = 3


func execute(context: EffectContext) -> void:
	context.combat_state.swap_hand_discard_roots(pos_match_bonus)
