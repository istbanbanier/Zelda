## Vérifie que l'outil de validation manuelle reste utilisable.
##
## La sonde d'entrée est le seul moyen d'exécuter les étapes 2 et 3 de
## `docs/MANUAL_VALIDATION.md` : sans joueur ni monde, aucune touche ne produit
## d'effet visible. Si elle se désynchronise de l'InputMap — une action ajoutée
## ailleurs et pas ici — la validation manuelle testerait un sous-ensemble sans
## que personne ne s'en aperçoive.
##
## Ces tests portent sur la structure, pas sur l'affichage : l'apparence relève
## précisément de la validation humaine.
extends GateTestCase

const PROBE_SCENE: String = "res://scenes/tests/InputProbe.tscn"
const PROBE_SCRIPT: String = "res://scripts/tools/input_probe.gd"

## Doit rester identique à `EXPECTED_ACTIONS` de `test_input_map.gd`.
const EXPECTED_ACTIONS: Array[String] = [
	"move_forward", "move_left", "move_back", "move_right",
	"jump", "sprint", "interact",
	"attack_light", "attack_heavy", "aim", "shoot", "dodge",
	"lock_on", "target_prev", "target_next",
	"inventory", "quick_meal", "pause",
]


func test_probe_scene_exists_and_loads() -> void:
	check(ResourceLoader.exists(PROBE_SCENE), "la scène de sonde doit exister")
	var packed: PackedScene = load(PROBE_SCENE) as PackedScene
	check_not_null(packed, "la scène de sonde doit se charger")


func test_probe_watches_every_input_action() -> void:
	## Le point sensible : une action ajoutée à l'InputMap mais absente de la
	## sonde ne serait jamais testée à la main.
	var script: Script = load(PROBE_SCRIPT) as Script
	check_not_null(script, "script de la sonde")
	if script == null:
		return
	var watched: Array = script.get_script_constant_map().get("WATCHED_ACTIONS", [])
	for action: String in EXPECTED_ACTIONS:
		check(watched.has(action),
			"action absente de la sonde, donc non testable à la main : %s" % action)
	check_equal(watched.size(), EXPECTED_ACTIONS.size(),
		"la sonde surveille un nombre d'actions différent de l'InputMap")


func test_probe_left_key_matches_the_input_map() -> void:
	## La sonde annonce à l'opérateur quelle position physique porte « gauche ».
	## Si cette constante divergeait de l'InputMap réel, le bandeau afficherait un
	## verdict AZERTY faux — le pire cas possible pour ce protocole.
	var script: Script = load(PROBE_SCRIPT) as Script
	if script == null:
		check(false, "script de la sonde")
		return
	var declared: int = int(script.get_script_constant_map().get("LEFT_PHYSICAL_KEY", -1))

	var bound: Array[int] = []
	for event: InputEvent in InputMap.action_get_events("move_left"):
		if event is InputEventKey:
			bound.append((event as InputEventKey).physical_keycode)
	check(bound.has(declared),
		"la sonde annonce la position physique %d pour « gauche », "
		% declared + "mais l'InputMap lie %s" % str(bound))


func test_probe_is_not_reachable_from_the_game() -> void:
	## Outil de développement : il ne doit pas être la scène principale.
	check(String(ProjectSettings.get_setting("application/run/main_scene", "")) != PROBE_SCENE,
		"la sonde ne doit jamais être la scène principale du projet")
