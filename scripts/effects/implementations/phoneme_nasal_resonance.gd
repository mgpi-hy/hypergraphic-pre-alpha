class_name PhonemeNasalResonanceEffect
extends Effect

## Eng (ŋ): Nasal Resonance. Heal cogency equal to morphemes
## in hand x2.

@export var heal_multiplier: int = 2


func execute(context: EffectContext) -> void:
	var hand_size: int = context.combat_state.hand_size()
	var heal_amount: int = hand_size * heal_multiplier
	if heal_amount <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.HEAL_COGENCY
	action.amount = heal_amount
	action.source = context.source
	context.action_queue.enqueue(action)
