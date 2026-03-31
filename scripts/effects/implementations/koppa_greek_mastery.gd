class_name KoppaGreekMasteryEffect
extends Effect

## Koppa (archaic): Greek-family morphemes get +2 induction.
## If ALL placed roots are Greek, bonus is +4 instead.

@export var base_bonus: int = 2
@export var full_greek_bonus: int = 4


func execute(context: EffectContext) -> void:
	var all_roots_greek: bool = context.combat_state.all_roots_are_family("greek")
	var bonus_per: int = full_greek_bonus if all_roots_greek else base_bonus
	var greek_count: int = 0
	for m: MorphemeData in context.morphemes:
		if m.family == "greek":
			greek_count += 1
	if greek_count <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = greek_count * bonus_per
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
