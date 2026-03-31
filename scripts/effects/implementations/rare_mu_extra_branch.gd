class_name RareMuExtraBranchEffect
extends Effect

## Mu (木): Extra Branch. Syntax tree gains 1 additional optional
## slot on longest branch.
## Tier 2: sets flag on CombatState at combat start.

func execute(context: EffectContext) -> void:
	context.combat_state.add_optional_slot_to_longest_branch()
