class_name RareAnaphoraAlliterationEffect
extends Effect

## Anaphora: When 2+ placed words start with the same letter, x1.3 multiplier.
## Checks word_forms_this_turn for shared initial letters at word submit time.

@export var alliteration_multiplier: float = 1.3


func can_trigger(context: EffectContext) -> bool:
	var forms: Array[String] = context.combat_state.word_forms_this_turn
	if forms.size() < 2:
		return false
	var initials: Dictionary = {}
	for form: String in forms:
		if form.is_empty():
			continue
		var first: String = form[0].to_lower()
		initials[first] = initials.get(first, 0) + 1
	for count: Variant in initials.values():
		if (count as int) >= 2:
			return true
	return false


func execute(context: EffectContext) -> void:
	context.combat_state.multiplier_bonus += alliteration_multiplier - 1.0
