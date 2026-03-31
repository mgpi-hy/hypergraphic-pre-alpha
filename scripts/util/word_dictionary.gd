class_name WordDictionary
extends RefCounted

## Dictionary of real English words formable from the morpheme pool.
## Used to detect "novel" (non-real) words for the novelty multiplier.
## Words are grouped by etymological family: Germanic, Latinate, Greek,
## cross-family combos, and functional words.

# --- Constants ---
const TIER_COMMON: String = "common"
const TIER_UNCOMMON: String = "uncommon"
const TIER_RARE: String = "rare"

const KNOWN_WORDS: PackedStringArray = [
	# =======================================================================
	# GERMANIC ROOT WORDS (standalone or with affixes)
	# =======================================================================

	# --- break ---
	"break", "breaker", "breaking", "breakable", "unbreakable",
	"outbreak", "outbreaker",

	# --- hold ---
	"hold", "holder", "holding", "holdless", "uphold",
	"overhold", "withhold", "withholder", "beholding", "beholder", "behold",

	# --- stand ---
	"stand", "standing", "standish", "withstand",
	"outstanding", "misstand",

	# --- fall ---
	"fall", "falling", "fallout", "outfall", "downfall",
	"befalling",

	# --- bind ---
	"bind", "binder", "binding", "unbind", "unbinding",
	"unbindable",

	# --- speak ---
	"speak", "speaker", "speaking", "unspeakable", "outspoken",
	"outspeak", "misspeaking", "forespeaker", "bespeak",

	# --- think ---
	"think", "thinker", "thinking", "unthinkable", "rethink",
	"forethink", "forethinker", "overthink", "overthinker",
	"misthink",

	# --- work ---
	"work", "worker", "working", "workable", "rework",
	"craftwork", "overwork", "workless", "outwork",
	"reworkable", "workish", "workward",

	# --- word ---
	"word", "wordless", "wordly", "wording", "wordish",
	"foreword", "misword",

	# --- spell ---
	"spell", "spellbound", "spelling", "misspell", "misspelling",
	"speller", "bespell",

	# --- craft ---
	"craft", "crafter", "crafty", "craftless", "craftdom",
	"craftsman",

	# --- name ---
	"name", "namer", "nameless", "unnamed", "rename", "misname",
	"naming", "forename",

	# --- tale ---
	"tale", "taledom", "teller",

	# --- might ---
	"might", "mighty", "mightless", "mightful",
	"mightily", "overmight",

	# --- blight ---
	"blight", "blighter", "blightful", "blighting",
	"unblighted",

	# --- dread ---
	"dread", "dreadful", "dreadless", "dreadness",
	"dreading", "undreaded",

	# --- writ ---
	"writ", "writing", "writer", "overwriting",
	"miswriting",

	# --- OE roots (standalone, kenning combos, with OE/common suffixes) ---
	"wyrd", "wyrdful", "wyrdless",
	"wer", "werdom",
	"dom", "doomful",
	"lof", "lofless",
	"mod", "modless", "modful",
	"sar", "sarful",
	"ead", "eadless",
	"bana", "baneful",
	"holm", "holmward",
	"hild", "hildful",
	"wyn", "wynful", "wynless",
	"bealu", "bealuful",
	"gar", "garward",
	"helm", "helmless", "helmward",

	# --- Germanic prefix + root combos ---
	"forework", "beforehand",
	"miscraft", "overcraft",
	"mishold", "outhold",
	"forewrit", "overwrit",
	"unworthy", "bework",
	"bedread", "bemight",

	# =======================================================================
	# LATINATE ROOT WORDS
	# =======================================================================

	# --- struct ---
	"structure", "structural", "destruction", "restructure",
	"construct", "construction", "constructive", "instructor",
	"obstruction", "unstructured", "destructive", "destructible",
	"constructible", "restructuring", "deconstructive",
	"infrastructural", "substructure", "superstructure",

	# --- form ---
	"form", "formation", "formal", "formable", "reform",
	"reformation", "reformable", "deform", "deformation",
	"inform", "informant", "conform", "transform",
	"transformation", "conformable", "transformable",
	"deformable", "reformist", "formless", "preform",
	"informative", "formative", "conformist",
	"transformative", "informal", "misinform",
	"unformable", "misformation",

	# --- scrib ---
	"inscription", "description", "prescribe", "subscribe",
	"transcription", "descriptive", "inscriptive",
	"subscriber", "prescriptive", "conscription",
	"indescribable", "transcriber", "describer",
	"proscription", "subscription",

	# --- dict ---
	"diction", "dictation", "prediction", "edict",
	"contradiction", "dictive", "predictable",
	"unpredictable", "dictator", "predictor",
	"interdict", "interdiction", "verdict",
	"benediction", "malediction",

	# --- rupt ---
	"rupture", "disruption", "disruptive", "eruptive",
	"corruption", "interruption", "abruptness",
	"erupt", "disrupt", "interrupt", "corrupt",
	"abrupt", "incorruptible", "disruptable",
	"interruptible", "corruptible",

	# --- ject ---
	"ejection", "rejection", "injection", "projection",
	"subjection", "dejection", "projective", "subjective",
	"reject", "inject", "project", "subject",
	"eject", "deject", "projector", "injector",
	"ejectable", "injectable", "projectable",
	"rejectionist", "objectify",

	# --- cept ---
	"reception", "deception", "conception", "inception",
	"receptive", "deceptive", "perceptive", "perceptible",
	"concept", "precept", "intercept", "receptionist",
	"conceptive", "interceptor", "imperceptible",
	"inconceivable", "preconception",

	# --- duct ---
	"reduction", "deduction", "induction", "conductor",
	"conduction", "conductive", "reductive", "productive",
	"production", "reproduce", "introduction", "deductible",
	"inductive", "reducible", "conductible",
	"productivity", "reproductible", "seduction",
	"transduction",

	# --- plic ---
	"implication", "complication", "replication", "duplicity",
	"implicit", "explicit", "complicate", "implicate",
	"replicate", "duplicate", "applicable", "inexplicable",
	"complicity", "simplicity",

	# --- voc ---
	"invocation", "revocation", "evocation", "provocative",
	"vocal", "vocation", "vocalize", "evocative",
	"revocable", "irrevocable", "provocation",
	"convocation", "invocable", "vocalist",

	# --- port ---
	"transport", "deportation", "exportable", "importable",
	"portable", "portment", "import", "export", "deport",
	"report", "reporter", "supportive", "transportable",
	"portage", "purport", "portability",

	# --- tang ---
	"intangible", "tangible", "tangent",
	"tangential",

	# --- fract ---
	"fraction", "fracture", "infraction", "refractive",
	"refraction", "fractious", "diffraction",
	"fracturable",

	# --- vers ---
	"versatile", "version", "reversion", "conversion",
	"subversive", "reversible", "diversify",
	"reverse", "converse", "diverse", "inverse",
	"traverse", "averse", "adversity",
	"conversant", "irreversible", "diversity",
	"inversion", "subversion", "perverse",
	"transverse", "diversion",

	# --- clar ---
	"clarify", "clarity", "clarion", "declaration",
	"declare", "clarifier",

	# --- cogn ---
	"cognition", "recognition", "cognizable", "precognition",
	"incognito", "recognize", "cognizant",
	"recognizable", "cognitive", "cognizance",

	# --- lum ---
	"luminous", "luminary", "illuminate",
	"luminance", "luminosity",

	# --- jug (judge) ---
	"judge", "judgment", "judgmental", "prejudge",
	"prejudgment", "misjudge", "misjudgment",

	# --- chanc ---
	"chance", "chancery", "mischance",

	# --- plais (pleasure) ---
	"pleasure", "pleasurable", "displeasure",
	"pleasant", "unpleasant",

	# --- grace ---
	"grace", "graceful", "graceless", "gracious", "disgrace",
	"disgraceful", "ungraceful", "gracefulness",
	"ingrace",

	# --- roial (royal) ---
	"royal", "royalty", "royalist",

	# --- surg ---
	"surge", "surgeon", "resurgent", "resurgence", "insurgent",
	"insurgence", "surgical",

	# --- langu ---
	"language", "languish", "languishment",
	"languishable",

	# --- prov ---
	"prove", "provable", "disprove", "improvable",
	"provision", "improvise", "provenance",
	"surveillance", "reprove", "approval",
	"disprovable", "unprovable",

	# --- verb ---
	"verbal", "verbalize", "verbose", "verbosity",
	"verbalism", "nonverbal", "preverbal",

	# --- cord (cor/cordis, heart) ---
	"cordial", "concordance", "discord", "discordant",
	"accord", "accordance", "recordable",

	# =======================================================================
	# GREEK ROOT WORDS
	# =======================================================================

	# --- graph ---
	"graphic", "graphism", "graphist",
	"graphite", "graphoid",
	"hypergraphic", "neographic",
	"monographic", "polygraphic", "monograph",
	"polygraph", "autograph",

	# --- morph ---
	"morphism", "morphic", "polymorphism", "morphology",
	"polymorphic", "neomorphic", "amorphous",
	"morphist", "morphoid",
	"isomorphism", "isomorphic",
	"monomorphic",

	# --- lex ---
	"lexicon", "lexical",
	"lexicology",

	# --- log ---
	"logic", "logical", "monologue", "neologism",
	"logist", "logism",
	"monologic", "antilogic",
	"analogous", "epilogue", "prologue",
	"dialogue", "apologize", "apologist",

	# --- phon ---
	"phonics", "phonic", "phonism", "polyphonic",
	"phonology", "phonist", "phonoid",
	"hyperphonic", "antiphonic",
	"monophonic", "euphonic",

	# --- path ---
	"pathology", "pathic", "psychopath", "neuropathology",
	"pathologist", "apathic", "apathy",
	"antipathy", "sympathy", "empathy",
	"pathoid", "neuropathic", "psychopathic",
	"telepathy", "telepathic",

	# --- chron ---
	"chronic", "chronism", "chronist", "chronology",
	"chronological", "antichronic",
	"chronoid", "synchronize", "synchronism",
	"anachronism", "anachronistic",

	# --- crypt ---
	"cryptic", "cryptology",
	"cryptoid", "cryptist",
	"hypercryptic", "encrypt",

	# --- nom ---
	"nominal", "autonomy",
	"antinominal", "nomism",
	"nomist", "nomination",
	"anomaly", "anomalous",
	"taxonomy", "astronomical",

	# --- trop ---
	"tropic", "tropism",
	"tropical", "neotropic",
	"psychotropic", "neurotropic",
	"heliotropism",

	# --- glyph ---
	"glyphic", "glyphoid",
	"hieroglyph", "hieroglyphic",
	"monoglyph",

	# --- soph ---
	"sophist", "sophism", "philosophy",
	"philosopher", "philosophical",
	"sophistic", "sophomore",
	"sophisticated",

	# --- phil ---
	"philic", "philism", "philia",
	"philology", "philologist",
	"autophilia", "euphilia",

	# --- aesth ---
	"aesthetic", "aesthetics", "aesthetism",
	"aesthetist", "anaesthetic",

	# --- cosm ---
	"cosmic", "cosmism", "cosmology",
	"cosmologist", "cosmoid",
	"microcosmic",

	# --- dem ---
	"democracy", "democrat", "democratic",
	"demography", "demographic",

	# --- techn ---
	"technic", "technics", "technology",
	"technologist", "technoid",
	"polytechnic",

	# --- crat ---
	"autocrat", "autocratic", "autocracy",
	"plutocracy", "theocracy",

	# --- scop ---
	"scopic", "scopism",
	"microscopic",

	# --- typ ---
	"typic", "typical", "typist",
	"typography", "typology",
	"typoid", "atypical",

	# --- astr ---
	"astral", "astronomer", "astronomy",
	"astrophysic", "astroid", "astrologic",

	# --- therm ---
	"thermic", "thermology",
	"thermoid", "thermist",
	"hyperthermic", "hypothermic",
	"exothermic", "geothermal",

	# --- psych ---
	"psychic", "psychology", "psychosis",
	"psychoid", "psychist",
	"psychopath", "psychotropic",
	"antipsychotic",

	# --- gen ---
	"genetic", "genesis", "neurogenesis",
	"genism", "genist",
	"neogenesis", "polygenism",
	"pathogenesis", "pathogenic",
	"psychogenesis", "agenesis",
	"eugenics",

	# --- syn ---
	"synthesis", "synthetic",
	"synod", "syndrome", "synonym",
	"synchronize", "synergism",

	# --- neur ---
	"neurosis", "neurotic", "neurology",
	"neurologist", "neuropathology",
	"neurogenic", "neurotropic",
	"neuropathic",

	# --- bio ---
	"biotic", "biology", "biologist",
	"biogenesis", "biomorphic",
	"antibiotic", "neobiotic",
	"abiotic", "symbiosis",

	# --- chrom ---
	"chromatic", "polychromatic",
	"monochromatic", "achromatic",
	"chromosome", "chromism",

	# --- dyn ---
	"dynamic", "dynamism", "dynasty",
	"dynamist", "aerodynamic",
	"hydrodynamic", "thermodynamic",

	# --- arch ---
	"archaic", "archaism", "archist",
	"anarchy", "anarchism", "anarchist",
	"monarchy", "oligarchy",

	# --- tele ---
	"teleology", "telescopic",
	"telepath", "telepathic",
	"telegram", "telegraph",

	# --- feed/back combos ---
	"feedback", "feedward",

	# --- thought (think combos) ---
	"thoughtful", "thoughtless",

	# --- bold ---
	"bold", "boldness", "boldly",
	"overbold", "unbold",

	# --- stark ---
	"stark", "starkness", "starkly",

	# --- heart ---
	"heart", "heartful", "heartless", "heartily",

	# --- star ---
	"star", "starless", "stardom",

	# =======================================================================
	# CROSS-FAMILY COMBOS (assembled from mixed morpheme families)
	# =======================================================================

	# Germanic prefix + Latinate root
	"overstructure", "subprocess", "preworker",
	"unportable", "outform", "misform",
	"unformable", "unbindable", "unspeakable",
	"reworkable",
	"unbreakable", "untangible",
	"misformation",

	# Greek prefix + non-Greek root
	"hyperstructure", "antistructure",
	"neoformation", "monoform",
	"hypervocal",

	# Mixed root + Greek/Latin suffix
	"workism", "wordism", "spellcraft",
	"breakage", "holdable", "speakable",
	"thinkable", "workable", "nameable",
	"bindable", "writable",
	"craftiness",

	# New root cross-family
	"biography", "biographic", "autographic",
	"cosmographic", "demographic", "technologic",

	# Deeper cross-family
	"psycholinguistic", "neurolinguistic",
	"morphophonemic", "lexicographic",
	"cryptographic", "chronographic",
	"graphological", "pathographic",

	# =======================================================================
	# FUNCTIONAL WORDS
	# =======================================================================
	"the", "a", "this", "that", "each",
	"not", "well", "so", "yet",
	"with", "from", "through",
]

const _UNCOMMON_WORDS: PackedStringArray = [
	# Germanic uncommon
	"standish", "taledom", "craftdom", "forethink", "forethinker",
	"withhold", "withholder", "beholding", "beholder", "behold",
	"outspeak", "outbreaker", "bespeak", "bespell",
	"overthink", "overthinker", "misthink",
	"overwork", "outwork", "forework", "forewrit",
	"overwrit", "bework", "bedread", "bemight",
	"foreword", "misword", "wordish",
	"workward", "holdless", "workless",
	"miscraft", "overcraft", "mishold", "outhold",
	"heartward", "heartish", "stardust", "starward",
	"wyrd", "wyrdful", "wyrdless", "werdom",
	"holmward", "helmward", "garward",
	"modful", "modless", "sarful",
	"eadless", "lofless", "hildful",
	"wynful", "wynless", "bealuful", "baneful",
	# Latinate uncommon
	"constructible", "deconstructive", "infrastructural",
	"substructure", "superstructure",
	"prescriptive", "conscription", "proscription",
	"interdiction", "interdict", "benediction", "malediction",
	"incorruptible", "interruptible", "corruptible",
	"ejectable", "rejectionist",
	"conceptive", "interceptor", "imperceptible",
	"preconception", "reproductible", "transduction",
	"inexplicable", "complicity",
	"irrevocable", "convocation", "invocable",
	"portage", "purport", "portability",
	"fractious", "diffraction", "fracturable",
	"verbalize", "verbosity", "concordant", "discordance",
	"conversant", "irreversible", "transverse", "diversion",
	"clarifier", "cognizant", "cognizance",
	"luminance", "luminosity", "illuminate",
	"mischance", "surgicalness",
	"languishment", "reprove",
	"prejudgment", "misjudgment",
	"insurgence",
	# Greek uncommon
	"graphoid", "morphoid", "phonoid", "pathoid",
	"chronoid", "cryptoid", "thermoid", "psychoid",
	"monographic", "polygraphic", "monograph", "polygraph",
	"isomorphism", "isomorphic", "monomorphic",
	"lexicology", "monologic",
	"hyperphonic", "antiphonic", "monophonic", "euphonic",
	"antichronic", "synchronism", "anachronism", "anachronistic",
	"hypercryptic", "antinominal", "nomism", "nomist",
	"neotropic", "neurotropic",
	"monoglyph", "sophistic",
	"hyperthermic", "hypothermic", "exothermic",
	"antipsychotic", "polygenism", "agenesis",
	"synergism",
	# New Greek uncommon
	"philology", "philologist", "autophilia", "euphilia",
	"aesthetism", "aesthetist", "anaesthetic",
	"cosmoid", "microcosmic",
	"demography", "demographic",
	"technoid", "polytechnic",
	"astrism", "astrologist", "astroid",
	"autocracy", "plutocracy", "theocracy",
	"scopism", "microscopic",
	"typoid", "typology",
	# Cross-family uncommon
	"overstructure", "subprocess", "preworker",
	"hyperstructure", "antistructure", "neoformation",
	"psycholinguistic", "neurolinguistic",
	"morphophonemic", "lexicographic",
	"cryptographic", "chronographic",
	"graphological", "pathographic",
	"hypervocal",
]

const _RARE_WORDS: PackedStringArray = [
	# OE archaic forms and kenning-style compounds
	"dom", "wer", "lof", "mod", "sar", "ead",
	"bana", "holm", "hild", "wyn", "bealu",
	"gar", "helm", "mægen", "helmless",
	# Deep Latinate
	"incognito", "duplicity", "portment",
	"abruptness", "luminous", "luminary",
	"seduction", "simplicity",
	"objectify",
	# Deep Greek
	"autograph", "hieroglyph", "hieroglyphic",
	"heliotropism", "anachronistic",
	"geothermal", "eugenics",
	"neuropathology", "psychogenesis",
	"pathogenesis", "pathogenic",
	"neurogenesis", "neurogenic",
	"telepathy", "telepathic",
	"sophomore", "sophisticated",
	"anomaly", "anomalous",
	"taxonomy", "astronomical",
	"epilogue", "prologue", "dialogue",
	"apologize", "apologist",
	"analogous",
	# Hyper-specialized cross-family
	"neographic", "hypergraphic",
	"psychotropic", "neuropathic",
	"psychopathic",
]


# --- Public Methods ---

static func is_known(word_form: String) -> bool:
	var lower: String = word_form.to_lower()
	return KNOWN_WORDS.has(lower)


## Returns the tier of a known word: "common", "uncommon", or "rare".
## Unknown words (not in KNOWN_WORDS) return "common" as a safe default.
static func get_word_tier(word: String) -> String:
	var lower: String = word.to_lower()
	if _RARE_WORDS.has(lower):
		return TIER_RARE
	if _UNCOMMON_WORDS.has(lower):
		return TIER_UNCOMMON
	return TIER_COMMON
