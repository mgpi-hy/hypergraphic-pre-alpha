class_name LatinOAyinGazeEffect
extends Effect

## O - Ayin's Gaze: Once per turn at draw, exile the lowest-weight
## morpheme from hand and draw 2 replacements. Tier 2: sets the exile
## flag on CombatState so the draw phase can execute the swap.

var _used_this_turn: bool = false


func activate(_context: EffectContext) -> void:
	_used_this_turn = false


func execute(context: EffectContext) -> void:
	if context.trigger == Enums.EffectTrigger.ON_TURN_START:
		_used_this_turn = false
		context.combat_state.set_ayin_gaze_available(true)
	elif context.trigger == Enums.EffectTrigger.ON_DRAW and not _used_this_turn:
		_used_this_turn = true
		context.combat_state.set_ayin_gaze_available(false)
		# Exile lowest + draw 2 handled by CombatState/screen
		context.combat_state.trigger_ayin_gaze_exile()
