class_name LatinUFullDiscountEffect
extends Effect

## U - Full Sentence Discount: Full tree submit = reduce next shop
## purchase by 3 semant (stacks to -9). Tier 2: sets a discount flag
## on RunState.

@export var discount_per_full_tree: int = 3
@export var max_discount: int = 9

var _accumulated: int = 0


func activate(_context: EffectContext) -> void:
	_accumulated = 0


func can_trigger(context: EffectContext) -> bool:
	return context.combat_state.is_full_tree and _accumulated < max_discount


func execute(context: EffectContext) -> void:
	_accumulated = mini(_accumulated + discount_per_full_tree, max_discount)
	context.combat_state.set_shop_discount(_accumulated)
