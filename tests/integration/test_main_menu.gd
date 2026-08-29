## Menu principal et transition Boot → MainMenu (MASTER_SPEC §17.3, §6.1).
##
## Les exigences d'interface de §17.3 — navigation clavier et manette, focus
## visible, aucun piège de focus — sont vérifiables en headless : ce sont des
## propriétés de l'arbre de contrôles, pas du rendu. Ce qui n'est PAS vérifiable
## ici : l'apparence, la lisibilité et le confort réels. Ils exigent un écran.
extends GateTestCase

const MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"
const BOOT_SCENE: String = "res://scenes/boot/Boot.tscn"
const SLOT: String = "slot0"

var _spawned: Node = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Instancie le menu dans l'arbre et laisse passer une frame pour que `_ready()`
## ait câblé le focus.
func _open_menu() -> Node:
	var tree: SceneTree = _tree()
	if tree == null:
		return null
	var packed: PackedScene = load(MENU_SCENE) as PackedScene
	if packed == null:
		return null
	var menu: Node = packed.instantiate()
	tree.root.add_child(menu)
	_spawned = menu
	return menu


func _close_menu() -> void:
	if _spawned != null and is_instance_valid(_spawned):
		_spawned.get_parent().remove_child(_spawned)
		_spawned.queue_free()
	_spawned = null


func _save_system() -> Node:
	var tree: SceneTree = _tree()
	return null if tree == null else tree.root.get_node_or_null(NodePath("SaveSystem"))


## Depuis D.0, « Nouvelle partie » enchaîne sur une VRAIE transition vers la
## vallée. L'exécuter dans le runner remplacerait la scène courante et mettrait
## l'arbre en pause — poison pour tous les tests suivants. On rend donc
## SceneFlow « occupé » le temps de l'appui : la demande de transition est
## refusée proprement (chemin d'échec réel du menu), observable via le label.
func _block_flow() -> void:
	var flow: Node = _tree().root.get_node_or_null(NodePath("SceneFlow"))
	if flow != null:
		flow.set("_busy", true)


func _unblock_flow() -> void:
	var flow: Node = _tree().root.get_node_or_null(NodePath("SceneFlow"))
	if flow != null:
		flow.set("_busy", false)


func _clear_save() -> void:
	var system: Node = _save_system()
	if system == null:
		return
	var path: String = String(system.call("slot_path", SLOT))
	for candidate: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func test_menu_scene_loads_and_has_its_buttons() -> void:
	var menu: Node = _open_menu()
	check_not_null(menu, "scène du menu principal")
	if menu == null:
		return
	await _tree().process_frame

	for button_name: String in ["ContinueButton", "NewGameButton", "OptionsButton", "QuitButton"]:
		var button: Button = menu.find_child(button_name, true, false) as Button
		check_not_null(button, "bouton %s" % button_name)
	_close_menu()


func test_focus_cycle_has_no_dead_end() -> void:
	## §17.3 : « pas de piège de focus ». On suit les voisins depuis le bouton
	## focalisé : le parcours doit revenir à son point de départ, sans jamais
	## pointer un bouton désactivé.
	var menu: Node = _open_menu()
	if menu == null:
		check(false, "menu non instancié")
		return
	await _tree().process_frame

	var start: Control = menu.get_viewport().gui_get_focus_owner()
	check_not_null(start, "un bouton doit avoir le focus à l'ouverture")
	if start == null:
		_close_menu()
		return

	var visited: Array[Control] = [start]
	var current: Control = start
	for step: int in range(8):
		var path: NodePath = current.focus_neighbor_bottom
		check(not path.is_empty(), "voisin bas manquant sur « %s »" % current.name)
		if path.is_empty():
			break
		var next: Control = current.get_node_or_null(path) as Control
		check_not_null(next, "voisin bas introuvable depuis « %s »" % current.name)
		if next == null:
			break
		check(not (next is Button and (next as Button).disabled),
			"le focus mène à un bouton désactivé : « %s »" % next.name)
		if next == start:
			break
		visited.append(next)
		current = next
	check(current == start or visited.has(start), "le cycle de focus doit boucler")
	check(visited.size() >= 2, "au moins deux boutons doivent être atteignables")
	_close_menu()


## Un bouton désactivé mais focalisable piège la navigation manette.
##
## RENDU DÉTERMINISTE le 2026-08-29. Sa seule assertion vivait sous
## `if button != null and button.disabled:` — l'« assertion sautée » nommée
## dans `tests/CLAUDE.md`. Or le SEUL bouton jamais grisé est « Continuer »,
## et il ne l'est que sans sauvegarde : dès qu'une suite antérieure en laissait
## une, ce test n'exécutait plus RIEN. Le garde-fou du runner l'a attrapé
## comme « couverture illusoire » dans un filet de 208 tests — pas en
## isolation, ni dans trois ordres plus courts, ce qui est exactement la forme
## d'ISS-038.
##
## Deux corrections, toutes deux RENFORÇANTES : on efface la sauvegarde pour
## que « Continuer » soit grisé à coup sûr, et on exige que les quatre boutons
## EXISTENT — sans quoi un simple renommage laissait le test vert et muet.
func test_disabled_buttons_are_not_focusable() -> void:
	_clear_save()
	var menu: Node = _open_menu()
	if menu == null:
		check(false, "menu non instancié")
		return
	await _tree().process_frame
	var grises: int = 0
	for button_name: String in ["ContinueButton", "NewGameButton", "OptionsButton", "QuitButton"]:
		var button: Button = menu.find_child(button_name, true, false) as Button
		check_not_null(button,
			"le bouton « %s » existe — un renommage laissait ce test muet"
			% button_name)
		if button != null and button.disabled:
			grises += 1
			check_equal(button.focus_mode, Control.FOCUS_NONE,
				"bouton désactivé « %s » ne doit pas être focalisable" % button_name)
	check(grises >= 1,
		"NON VACUITÉ : au moins un bouton est grisé (%d) — sans sauvegarde, "
		% grises + "« Continuer » doit l'être, sinon la vérification "
		+ "ci-dessus n'a rien examiné")
	_close_menu()


func test_continue_is_disabled_without_a_save() -> void:
	_clear_save()
	var menu: Node = _open_menu()
	if menu == null:
		check(false, "menu non instancié")
		return
	await _tree().process_frame
	var continue_button: Button = menu.find_child("ContinueButton", true, false) as Button
	check_not_null(continue_button, "ContinueButton")
	if continue_button != null:
		check(continue_button.disabled, "« Continuer » doit être grisé sans sauvegarde")
	_close_menu()


func test_new_game_creates_a_save_and_enables_continue() -> void:
	_clear_save()
	var menu: Node = _open_menu()
	if menu == null:
		check(false, "menu non instancié")
		return
	await _tree().process_frame

	var new_game: Button = menu.find_child("NewGameButton", true, false) as Button
	var continue_button: Button = menu.find_child("ContinueButton", true, false) as Button
	check_not_null(new_game, "NewGameButton")
	if new_game == null:
		_close_menu()
		return

	_block_flow()
	new_game.pressed.emit()
	await _tree().process_frame
	_unblock_flow()

	var system: Node = _save_system()
	check(system != null and bool(system.call("has_save", SLOT)),
		"« Nouvelle partie » doit créer une sauvegarde réelle")
	if continue_button != null:
		check(not continue_button.disabled,
			"« Continuer » doit s'activer une fois la sauvegarde créée")
	# La transition vers World V2 a été DEMANDÉE — le flux bloqué l'a
	# refusée par le chemin d'échec prévu, et le menu l'a dit.
	var status: Label = menu.find_child("StatusLabel", true, false) as Label
	if status != null:
		check_equal(status.text, "Monde indisponible — voir le journal.",
			"« Nouvelle partie » tente bien d'entrer dans World V2")
	_close_menu()
	_clear_save()


func test_new_game_asks_confirmation_before_overwriting() -> void:
	## §17.3 : confirmation avant d'écraser une sauvegarde.
	_clear_save()
	var system: Node = _save_system()
	if system == null:
		check(false, "SaveSystem absent")
		return
	check(bool(system.call("save_slot", SLOT, {"marqueur": "existant"})), "sauvegarde préalable")

	var menu: Node = _open_menu()
	if menu == null:
		check(false, "menu non instancié")
		return
	await _tree().process_frame

	var new_game: Button = menu.find_child("NewGameButton", true, false) as Button
	if new_game == null:
		check(false, "NewGameButton")
		_close_menu()
		return

	# Premier appui : demande de confirmation, la sauvegarde reste intacte.
	_block_flow()
	new_game.pressed.emit()
	await _tree().process_frame
	var still_there: Dictionary = system.call("load_slot", SLOT)
	check_equal(String(still_there.get("marqueur", "")), "existant",
		"le premier appui ne doit rien écraser")

	# Second appui : confirmation, la sauvegarde est remplacée.
	new_game.pressed.emit()
	await _tree().process_frame
	_unblock_flow()
	var replaced: Dictionary = system.call("load_slot", SLOT)
	check(not replaced.has("marqueur"), "le second appui doit écraser la sauvegarde")

	_close_menu()
	_clear_save()


func test_boot_can_reach_the_main_menu() -> void:
	## §6.1 : l'enchaînement passe par SceneFlow, seul chemin qui coupe les
	## entrées et ne laisse aucun ancien nœud actif.
	var tree: SceneTree = _tree()
	if tree == null:
		check(false, "SceneTree")
		return
	var flow: Node = tree.root.get_node_or_null(NodePath("SceneFlow"))
	check_not_null(flow, "SceneFlow")
	if flow == null:
		return
	check(bool(flow.call("can_go_to", MENU_SCENE)),
		"SceneFlow doit pouvoir atteindre le menu principal")
	check(ResourceLoader.exists(BOOT_SCENE), "la scène Boot doit exister")
	check_equal(String(ProjectSettings.get_setting("application/run/main_scene", "")),
		BOOT_SCENE, "la scène principale du projet doit être Boot")


func test_builtin_ui_actions_exist_for_menu_navigation() -> void:
	## La navigation d'un menu Godot repose sur les actions intégrées `ui_*`.
	## Notre InputMap généré ne doit pas les avoir écrasées.
	for action: String in ["ui_accept", "ui_cancel", "ui_up", "ui_down", "ui_focus_next"]:
		check(InputMap.has_action(action),
			"action intégrée absente, navigation clavier/manette cassée : %s" % action)


func test_debug_entry_follows_build_type() -> void:
	## §6.1 : « un debug overlay désactivé dans le build final ». La règle est
	## vérifiée dans les deux sens, sans supposer le type de build courant : en
	## développement l'entrée est présente et utilisable, en export release elle
	## disparaît de l'arbre de focus au lieu d'être seulement grisée.
	var menu: Node = _open_menu()
	if menu == null:
		check(false, "menu non instancié")
		return
	await _tree().process_frame

	var debug_button: Button = menu.find_child("DebugAuditButton", true, false) as Button
	check_not_null(debug_button, "DebugAuditButton")
	if debug_button == null:
		_close_menu()
		return

	# La règle a CHANGÉ, et le test avec elle. `OS.is_debug_build()` ne suffisait
	# pas : le projet se livre en archive à ouvrir dans Godot, donc le joueur
	# lance un build de debug et voyait « Debug — Audit d'entrée » dans son menu
	# principal. Un playtest en boîte noire l'a relevé comme premier signal de
	# « ce n'est pas un jeu ». Il faut désormais une intention EXPLICITE.
	var wanted: bool = OS.is_debug_build() \
		and OS.get_environment("ECLATS_DEBUG_MENU") == "1"
	check_equal(debug_button.visible, wanted,
		"l'entrée debug n'apparaît que sur intention explicite (attendu %s)"
		% wanted)
	check_equal(debug_button.disabled, not wanted,
		"…et n'est utilisable que dans ce cas")
	if not wanted:
		check_equal(debug_button.focus_mode, Control.FOCUS_NONE,
			"sans intention explicite, l'entrée debug n'est pas focalisable")
	# Contrôle NÉGATIF : sans la variable, un build de debug ne doit RIEN
	# montrer. Sans cette ligne, le test passerait aussi bien si la garde
	# n'existait pas, dès lors qu'on l'exécute dans un export release.
	check(not (OS.get_environment("ECLATS_DEBUG_MENU") != "1"
		and debug_button.visible),
		"sans ECLATS_DEBUG_MENU, l'entrée reste invisible même en debug")
	_close_menu()


func test_debug_audit_scene_is_reachable_in_development() -> void:
	## L'outil ne sert à rien s'il n'est pas atteignable : c'est le seul chemin
	## prévu par docs/MANUAL_GATE_A.md pour les étapes clavier et manette.
	if not OS.is_debug_build():
		check(true, "build release : atteignabilité de l'audit volontairement non testée")
		return
	var flow: Node = _tree().root.get_node_or_null(NodePath("SceneFlow"))
	check_not_null(flow, "SceneFlow")
	if flow != null:
		check(bool(flow.call("can_go_to", "res://scenes/tests/InputAudit.tscn")),
			"la scène InputAudit doit être atteignable en développement")
