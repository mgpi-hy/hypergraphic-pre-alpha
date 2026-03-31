class_name PhonemeVoicedEdgeEffect
extends Effect

## Ezh (ʒ): Voiced Edge. Deal 15 damage to all enemies.

@export var damage: int = 15


func execute(context: EffectContext) -> void:
	context.combat_state.deal_damage_to_all_enemies(damage, context.source)
