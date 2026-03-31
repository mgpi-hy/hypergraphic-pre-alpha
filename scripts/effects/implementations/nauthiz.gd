class_name NauthizEffect
extends Effect

## Nauthiz (ᚾ): Necessity's Spur. 3 or fewer root morphemes in hand = all
## multipliers +0.5.

@export var multiplier_bonus: float = 0.5
@export var root_threshold: int = 3


func can_trigger(context: EffectContext) -> bool:
	var root_count: int = 0
	for m: MorphemeData in context.morphemes:
		if m.type == "root":
			root_count += 1
	return root_count <= root_threshold


func execute(context: EffectContext) -> void:
	context.combat_state.add_multiplier_bonus(multiplier_bonus)
