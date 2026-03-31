class_name AnsuzEffect
extends Effect

## Ansuz (ᚨ): God's Mouth. Full tree submit = draw 2 extra next turn.

@export var extra_draw: int = 2


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.is_full_tree


func execute(context: EffectContext) -> void:
	context.combat_state.set_bonus_draw_next_turn(extra_draw)
