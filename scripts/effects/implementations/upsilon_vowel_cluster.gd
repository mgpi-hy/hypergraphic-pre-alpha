class_name UpsilonVowelClusterEffect
extends Effect

## Upsilon (U): Each vowel-cluster grapheme owned grants +1 induction to all words.
## Vowel-cluster set: Alpha, Epsilon, Eta, Iota, Omicron, Upsilon, Omega.

var _vowel_cluster_ids: Array[String] = [
	"greek_alpha_first_principle",
	"greek_epsilon_escalation",
	"greek_eta_long_measure",
	"greek_iota_small_form",
	"greek_omicron_patience_shield",
	"greek_upsilon_vowel_cluster",
	"greek_omega_final_word",
]


func execute(context: EffectContext) -> void:
	var count: int = 0
	for gid: String in _vowel_cluster_ids:
		if context.combat_state.has_grapheme(gid):
			count += 1
	if count <= 0:
		return
	var action := GameAction.new()
	action.type = Enums.ActionType.DEAL_DAMAGE
	action.amount = count
	action.source = context.source
	action.target = context.target
	context.action_queue.enqueue(action)
