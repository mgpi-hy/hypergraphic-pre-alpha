class_name RareHuoBurningEffect
extends Effect

## Huo (火): Burning Lexicon. After submitting, highest-induction word
## burns its POS slot (any POS fits next turn).
## Tier 2: sets burn-slot flag on CombatState.

func execute(context: EffectContext) -> void:
	context.combat_state.set_burn_slot_from_highest_word()
