## Fait respecter les quatre contraintes d'architecture d'entrée (D-012, D-013).
##
## Elles ne sont pas des recommandations : ce sont les conditions pour que la
## dette `CONTROLLER-001` reste payable sans réécriture. La Phase B se développe
## au clavier ; sans ce garde-fou, du code finirait par supposer un clavier et
## l'essai manette exigerait de tout reprendre.
##
## Ce test lit le **code source**. Il ne prouve donc pas que la manette
## fonctionne — rien d'automatisé ne le pourra jamais (voir CONTROLLER-001). Il
## prouve seulement que rien n'empêche structurellement qu'elle fonctionne.
extends GateTestCase

## Seuls fichiers autorisés à consulter un périphérique ou une constante de touche.
const INPUT_LAYER: Array[String] = [
	"res://scripts/components/player_input_reader.gd",
]

## Outillage de développement, hors du jeu : l'audit d'entrée doit évidemment
## parler de touches, c'est son objet. Le générateur de projet aussi.
const TOOLING: Array[String] = [
	"res://scripts/tools/input_audit.gd",
	"res://tools/godot/setup_project.gd",
	# Le mode développement lit F3/F4/F5 en touches BRUTES, et c'est
	# délibéré : passer par l'InputMap ajouterait trois actions au jeu livré
	# et entrerait en conflit avec le remappage du joueur. Il ne pilote AUCUN
	# gameplay — il enregistre. La règle D-013 protège le gameplay des
	# périphériques ; elle n'a pas à interdire à un outil de debug d'avoir
	# des touches. Voir docs/MODE_DEV.md.
	"res://scripts/tools/dev_mode.gd",
]

## Motifs qui trahissent une dépendance au clavier hors de la couche d'entrée.
const FORBIDDEN: Array[String] = [
	"Input.is_key_pressed",
	"Input.is_physical_key_pressed",
	"InputEventKey",
	"KEY_",
	"OS.get_keycode_string",
]

## Répertoires de gameplay soumis à la règle.
const GAMEPLAY_ROOTS: Array[String] = [
	"res://scripts",
]


func _collect_scripts(dir_path: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_collect_scripts(full, out)
		elif entry.ends_with(".gd"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()


func test_no_gameplay_script_reads_the_keyboard() -> void:
	## Contrainte 2 : « aucune logique dépendante du clavier ».
	## Contrainte 4 : « aucun raccourci clavier codé en dur ».
	var scripts: Array[String] = []
	for root: String in GAMEPLAY_ROOTS:
		_collect_scripts(root, scripts)
	check(scripts.size() > 0, "aucun script de gameplay trouvé — le test se croirait vert à vide")

	for path: String in scripts:
		if INPUT_LAYER.has(path) or TOOLING.has(path):
			continue
		var source: String = FileAccess.get_file_as_string(path)
		for pattern: String in FORBIDDEN:
			check(not source.contains(pattern),
				"%s contient « %s » : le gameplay ne doit connaître que des actions, " % [path, pattern]
				+ "jamais des touches (D-013). Passer par InputIntent.")


func test_only_the_reader_queries_the_input_map() -> void:
	## Contrainte 1 : « InputMap séparé de la logique gameplay ». Le gameplay ne
	## doit pas interroger `Input` directement, même par action : sinon la zone
	## morte, le remapping et la détection de périphérique se dispersent.
	var scripts: Array[String] = []
	for root: String in GAMEPLAY_ROOTS:
		_collect_scripts(root, scripts)

	for path: String in scripts:
		if INPUT_LAYER.has(path) or TOOLING.has(path):
			continue
		# `scripts/ui/` est exempté : un menu réagit à `ui_accept`/`ui_cancel` via
		# le système de focus de Godot, pas via la couche d'intention du joueur.
		if path.begins_with("res://scripts/ui/"):
			continue
		var source: String = FileAccess.get_file_as_string(path)
		for pattern: String in ["Input.get_vector", "Input.is_action_pressed", "Input.get_axis"]:
			check(not source.contains(pattern),
				"%s interroge Input directement (« %s ») : passer par InputIntent (D-013)"
				% [path, pattern])


func test_every_action_still_has_a_gamepad_binding() -> void:
	## Contrainte 3 : « toutes les actions possèdent déjà leurs liaisons manette ».
	## Vérifié pour TOUTES les actions du projet, y compris celles ajoutées après
	## coup — c'est le point qui se perd le plus facilement.
	var checked: int = 0
	for setting: Dictionary in ProjectSettings.get_property_list():
		var key: String = String(setting.get("name", ""))
		if not key.begins_with("input/"):
			continue
		var action: String = key.trim_prefix("input/")
		if action.begins_with("ui_"):
			continue  # actions intégrées de Godot, hors de notre contrôle
		checked += 1
		var has_pad: bool = false
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				has_pad = true
				break
		check(has_pad, "action sans liaison manette : %s — interdit tant que "
			% action + "CONTROLLER-001 n'est pas levée")
	check(checked > 0, "aucune action de projet inspectée")


func test_intent_carries_no_device_information() -> void:
	## L'intention doit rester ignorante du périphérique : si elle exposait un
	## « is_gamepad », le gameplay finirait par s'en servir pour se ramifier.
	var source: String = FileAccess.get_file_as_string("res://scripts/components/input_intent.gd")
	check(source != "", "InputIntent introuvable")
	for pattern: String in ["Input.", "InputMap", "InputEvent", "joy", "keyboard", "gamepad"]:
		check(not source.contains(pattern),
			"InputIntent mentionne « %s » : elle doit ignorer d'où vient l'ordre" % pattern)


func test_intent_consumes_edges_but_keeps_held_states() -> void:
	## Un front consommé deux fois provoquerait un double saut ; un état maintenu
	## effacé couperait le sprint à chaque tick.
	var intent: InputIntent = InputIntent.new()
	intent.jump_pressed = true
	intent.sprint_held = true
	intent.move = Vector2(1.0, 0.0)

	intent.consume_edges()
	check(not intent.jump_pressed, "un front doit être consommé")
	check(intent.sprint_held, "un état maintenu ne doit PAS être effacé par consume_edges()")
	check(intent.has_move(), "le vecteur de déplacement doit survivre à consume_edges()")

	intent.clear()
	check(not intent.sprint_held, "clear() doit tout remettre à zéro")
	check(not intent.has_move(), "clear() doit annuler le déplacement")
