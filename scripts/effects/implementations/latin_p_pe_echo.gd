class_name LatinPPeEchoEffect
extends Effect

## P - Pe's Echo: Buy morpheme at shop = gain copy of random same-family
## morpheme (1x per shop visit). Shop-only acquisition.
## This effect triggers outside combat; sets a flag on RunState.


func execute(context: EffectContext) -> void:
	context.combat_state.set_pe_echo_pending(true)
