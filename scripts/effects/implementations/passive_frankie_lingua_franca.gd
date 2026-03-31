class_name PassiveFrankieLinguaFrancaEffect
extends Effect

## Frankie (Lingua Franca): x1.25 bonus for mixing morpheme families
## in a single word, instead of the normal x0.75 penalty.
## PASSIVE: modifies the family-mix multiplier value.

@export var mix_bonus: float = 1.25


func modify_value(base_value: int, context: EffectContext) -> int:
	# When DamageResolver polls for the family-mix multiplier,
	# this converts the penalty into a bonus.
	# base_value represents the penalty as int percentage (75 = x0.75).
	# Return 125 = x1.25 if the word has mixed families.
	if context.combat_state.is_current_word_family_mixed():
		return roundi(mix_bonus * 100.0)
	return base_value
