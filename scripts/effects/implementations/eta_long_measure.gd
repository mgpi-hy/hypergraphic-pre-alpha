class_name EtaLongMeasureEffect
extends Effect

## Eta (H): +1 max hand size permanently. Applied at combat start.

@export var hand_size_bonus: int = 1


func execute(context: EffectContext) -> void:
	context.combat_state.increase_hand_size(hand_size_bonus)
