## Verrouille la fondation de la Phase A : autoloads présents, contrats de base
## respectés (MASTER_SPEC §5.6, §18.1, §19.2).
##
## Ces tests s'exécutent en headless. Ils vérifient des comportements, pas des
## intentions : un autoload déclaré mais désactivé, ou un bus audio absent, doit
## faire rougir la suite.
extends GateTestCase

const EXPECTED_AUTOLOADS: Array[String] = [
	"GameState", "EventBus", "SaveSystem", "AudioManager", "SceneFlow",
]


func _autoload(autoload_name: String) -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(autoload_name))


func test_all_autoloads_are_registered_and_active() -> void:
	## Le préfixe « * » dans project.godot active le singleton. Sans lui l'autoload
	## est déclaré mais absent de l'arbre — erreur invisible jusqu'à l'exécution.
	for autoload_name: String in EXPECTED_AUTOLOADS:
		var setting: String = String(ProjectSettings.get_setting("autoload/%s" % autoload_name, ""))
		check(setting != "", "autoload non déclaré dans project.godot : %s" % autoload_name)
		check(setting.begins_with("*"),
			"autoload « %s » déclaré mais désactivé (préfixe « * » manquant) : %s"
			% [autoload_name, setting])


func test_autoloads_are_present_in_the_tree() -> void:
	for autoload_name: String in EXPECTED_AUTOLOADS:
		check_not_null(_autoload(autoload_name), "autoload absent de l'arbre : %s" % autoload_name)


func test_game_state_flow_transitions_are_idempotent() -> void:
	var state: Node = _autoload("GameState")
	check_not_null(state, "GameState")
	if state == null:
		return
	var initial: int = int(state.call("get_flow"))
	# Re-poser le même état ne doit rien émettre ni rien changer.
	state.call("set_flow", initial)
	check_equal(int(state.call("get_flow")), initial, "set_flow(même valeur) ne change rien")


func test_game_state_holds_no_scene_reference() -> void:
	## §5.6 : un autoload ne conserve aucune référence fragile au joueur ou aux
	## ennemis. Un autoload survit aux changements de scène ; une telle référence
	## devient invalide sans prévenir.
	var state: Node = _autoload("GameState")
	check_not_null(state, "GameState")
	if state == null:
		return
	var offenders: Array[String] = []
	for property: Dictionary in state.get_property_list():
		if int(property.get("type", 0)) != TYPE_OBJECT:
			continue
		var property_name: String = String(property.get("name", ""))
		if property_name.begins_with("_") or property_name == "script":
			var value: Variant = state.get(property_name)
			if value is Node:
				offenders.append(property_name)
	check(offenders.is_empty(),
		"GameState conserve une référence de nœud : %s" % str(offenders))


func test_event_bus_carries_exactly_the_admitted_signals() -> void:
	## §5.6 : l'EventBus ne porte que des événements réellement globaux. Le
	## registre ci-dessous EST la décision visible : tout signal absent de cette
	## liste fait échouer le test — l'ajout se justifie dans docs/DECISIONS.md
	## et se déclare ici dans le même changement. Admis : gameplay_notification
	## (D.1R.3, D-026 — coffres/armes/contrôleur → HUD, aucun propriétaire).
	var bus: Node = _autoload("EventBus")
	check_not_null(bus, "EventBus")
	if bus == null:
		return
	var admitted: Array[String] = ["gameplay_notification"]
	var declared: Array[String] = []
	for entry: Dictionary in bus.get_script().get_script_signal_list():
		declared.append(String(entry.get("name", "")))
	declared.sort()
	admitted.sort()
	check(declared == admitted,
		"signaux de l'EventBus hors registre : déclarés %s, admis %s"
		% [str(declared), str(admitted)])


func test_audio_buses_exist() -> void:
	## §18.1. Créés au runtime plutôt que via un .tres binaire : lisible en diff
	## et vérifiable ici.
	var audio: Node = _autoload("AudioManager")
	check_not_null(audio, "AudioManager")
	if audio == null:
		return
	for bus_name: String in ["Master", "Music", "Ambience", "SFX", "UI", "Voice"]:
		check(bool(audio.call("has_bus", bus_name)), "bus audio absent : %s" % bus_name)


func test_audio_volume_roundtrip_and_clamp() -> void:
	var audio: Node = _autoload("AudioManager")
	if audio == null:
		check(false, "AudioManager absent")
		return
	var previous: float = float(audio.call("get_volume", "Music"))
	audio.call("set_volume", "Music", 0.5)
	check_approx(float(audio.call("get_volume", "Music")), 0.5, 0.02, "volume Music à 0,5")
	audio.call("set_volume", "Music", 2.0)
	check_approx(float(audio.call("get_volume", "Music")), 1.0, 0.02, "volume borné à 1,0")
	audio.call("set_volume", "Music", 0.0)
	check_approx(float(audio.call("get_volume", "Music")), 0.0, 0.001, "volume 0 = muet")
	audio.call("set_volume", "Music", previous)


func test_scene_flow_owns_its_fade_layer() -> void:
	## D-007 : le voile de fondu appartient à l'autoload, pas à Boot.tscn — sinon
	## il serait libéré au premier changement de scène, quand il sert.
	var flow: Node = _autoload("SceneFlow")
	check_not_null(flow, "SceneFlow")
	if flow == null:
		return
	var layer: Node = flow.get_node_or_null(NodePath("FadeLayer"))
	check_not_null(layer, "SceneFlow doit détenir son propre FadeLayer")
	if layer != null:
		check_not_null(layer.get_node_or_null(NodePath("FadeRect")),
			"FadeLayer doit contenir un FadeRect")


func test_scene_flow_shows_a_loading_screen_that_survives_the_pause() -> void:
	## Le chargement de la vallée dure 25 à 65 s en rendu logiciel. Tant qu'il
	## était SYNCHRONE, aucune image ne pouvait être dessinée : deux playtests en
	## boîte noire ont pris cet écran noir muet pour un plantage et sont partis
	## chercher des journaux d'erreur.
	##
	## L'écran de chargement doit donc exister ET tourner en pause : `go_to()`
	## met l'arbre en pause avant de charger, et un Control laissé en `INHERIT`
	## serait gelé au moment précis où il doit informer.
	var flow: Node = _autoload("SceneFlow")
	check_not_null(flow, "SceneFlow")
	if flow == null:
		return
	var layer: Node = flow.get_node_or_null(NodePath("FadeLayer"))
	check_not_null(layer, "FadeLayer")
	if layer == null:
		return
	var loading: Node = layer.get_node_or_null(NodePath("LoadingUI"))
	check_not_null(loading, "SceneFlow doit détenir un écran de chargement")
	if loading == null:
		return
	check_equal(loading.process_mode, Node.PROCESS_MODE_ALWAYS,
		"l'écran de chargement doit tourner alors que l'arbre est en pause")
	var control: Control = loading as Control
	check_not_null(control, "LoadingUI doit être un Control")
	if control != null:
		check(not control.visible,
			"l'écran de chargement reste caché hors transition")
	check_not_null(loading.get_node_or_null(NodePath("LoadingLabel")),
		"il doit porter un libellé lisible")
	check_not_null(loading.get_node_or_null(NodePath("Track/Bar")),
		"il doit porter une barre de progression")


func test_scene_flow_refuses_a_missing_scene() -> void:
	var flow: Node = _autoload("SceneFlow")
	if flow == null:
		check(false, "SceneFlow absent")
		return
	check(not bool(flow.call("is_busy")), "SceneFlow ne doit pas être occupé au repos")
	# `can_go_to()` porte la décision ; `go_to()` y ajoute l'exécution et la
	# journalisation d'erreur. On teste la règle sans polluer le journal avec un
	# `ERROR:` que le niveau 2b compterait — à juste titre — comme un échec.
	check(not bool(flow.call("can_go_to", "res://scenes/inexistante_zqx.tscn")),
		"une scène introuvable doit être refusée")
	check(bool(flow.call("can_go_to", "res://scenes/boot/Boot.tscn")),
		"une scène existante doit être acceptée au repos")
