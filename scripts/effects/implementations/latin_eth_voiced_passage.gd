class_name LatinEthVoicedPassageEffect
extends Effect

## Eth (DH) - Voiced Passage: Draw pile reshuffles after every submit.
## Triggers ON_PLAY. Tells CombatState to shuffle the draw pile.


func execute(context: EffectContext) -> void:
	context.combat_state.shuffle_draw_pile()
