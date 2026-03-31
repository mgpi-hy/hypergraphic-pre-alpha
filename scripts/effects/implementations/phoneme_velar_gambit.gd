class_name PhonemeVelarGambitEffect
extends Effect

## Velar Fricative (ɣ): Velar Gambit. Submit current tree immediately,
## even incomplete. Unfilled slots deal their induction as self-damage.

func execute(context: EffectContext) -> void:
	context.combat_state.force_submit_tree()
