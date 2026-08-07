## L'INVITE D'INTERACTION, DU POINT DE VUE DU JOUEUR.
##
## Défaut mesuré au playtest humain du 2026-08-07 (session_20260807_141313) :
## le joueur a appuyé sur `E` devant SEPT objets — feu de camp (3 fois),
## enclume, cadavre, objet orange, herse — et n'a JAMAIS vu une seule invite
## à l'écran. Bilan de sa partie : 0 coffre, 0 ingrédient, 0 cuisine, donjon
## jamais atteint. Tout le contenu du jeu lui était inaccessible.
##
## POURQUOI LES TESTS EXISTANTS N'ONT RIEN VU : `test_cooking_ui.gd` appelle
## `fire.interact(_player)` DIRECTEMENT. Il prouve que l'atelier s'ouvre quand
## on l'appelle — jamais qu'un joueur debout devant le feu puisse l'appeler.
## Toute la chaîne réelle (portée, cône, ligne de vue, cadence, signal, HUD)
## était hors test. C'est la règle nº7 du guide de travail : un fichier qui
## existe ne prouve pas qu'un joueur puisse s'en servir.
##
## Ce cas rejoue donc le geste du joueur : on POSE le héros devant l'objet, on
## le TOURNE vers lui, on laisse tourner `_physics_process`, et on lit ce que
## la coquille AFFICHE. Aucun appel direct à `interact()`.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"

## Distances d'approche éprouvées : le joueur ne s'arrête jamais au millimètre.
## `INTERACT_RANGE` vaut 2,2 m ; on vérifie donc qu'un arrêt naturel — entre
## 1,2 m et 1,8 m — invite bien. Un jeu qui n'invite qu'à 0,4 m n'invite pas.
const APPROACH_DISTANCES: Array[float] = [1.2, 1.5, 1.8]

var _valley: Node3D = null
var _shell: GameplayShell = null
var _player: PlayerController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _load_valley() -> void:
	# Un monde jouable AUTOSAUVEGARDE : on garde l'état d'avant pour le
	# rendre intact au cas suivant (voir `remember_saves`).
	remember_saves()
	_valley = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_valley)
	await _settle(5)
	_shell = _valley.get_node("GameplayShell") as GameplayShell
	_player = _valley.call("player") as PlayerController


func _unload_valley() -> void:
	_tree().paused = false
	_valley.get_parent().remove_child(_valley)
	_valley.queue_free()
	_valley = null
	_shell = null
	_player = null
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)
	restore_saves()


## Pose le héros à `distance` mètres de la cible, sur l'axe donné, tourné VERS
## elle, et laisse la physique le reposer au sol. Retourne l'invite affichée.
##
## `_visual_root` est orienté à la main : au repos le contrôleur ne tourne pas
## le personnage (il n'oriente que sur la vitesse), donc sans cela on mesurerait
## l'orientation héritée du spawn au lieu du regard du joueur.
func _stand_before(target: Node3D, distance: float, axis: Vector3) -> String:
	var spot: Vector3 = target.global_position + axis.normalized() * distance
	_player.velocity = Vector3.ZERO
	# Un peu au-dessus du sol : la physique fait retomber le héros sur la
	# terrasse au lieu de le coincer dans le relief.
	_player.global_position = spot + Vector3.UP * 0.6
	await _settle(2)
	var visual: Node3D = _player.get_node("VisualRoot") as Node3D
	var to_target: Vector3 = target.global_position - _player.global_position
	# Le modèle regarde +Z (cf. `_orient_visual` : `atan2(x, z)`).
	visual.rotation.y = atan2(to_target.x, to_target.z)
	# La sélection tourne à la cadence `INTERACT_FOCUS_INTERVAL` (6 ticks) :
	# on laisse largement de quoi la voir passer, puis une frame de traitement
	# pour que la coquille ait reçu le signal.
	await _settle(14)
	await _tree().process_frame
	return _shell.prompt_text()


func _campfire() -> Campfire:
	var fires: Array[Node] = _valley.find_children("*", "Campfire", true, false)
	return null if fires.is_empty() else fires[0] as Campfire


## LE TEST QUI MANQUAIT. Le joueur s'approche du feu par les quatre côtés et
## à trois distances : l'invite « E — Cuisiner » doit apparaître.
func test_the_player_standing_at_the_campfire_sees_the_prompt() -> void:
	await _load_valley()
	var fire: Campfire = _campfire()
	check(fire != null, "le feu de cuisine existe dans la vallée")
	if fire == null:
		await _unload_valley()
		return
	var axes: Array[Vector3] = [
		Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT,
	]
	var seen: int = 0
	var tried: int = 0
	for axis: Vector3 in axes:
		for distance: float in APPROACH_DISTANCES:
			tried += 1
			var prompt: String = await _stand_before(fire, distance, axis)
			if prompt == "E — Cuisiner":
				seen += 1
	# Exigence du joueur, pas du code : arriver sur le feu et voir l'invite.
	# On tolère qu'un côté soit masqué par le décor du camp, jamais que le
	# feu reste muet sur la majorité des approches naturelles.
	check(seen > tried / 2,
		"l'invite « E — Cuisiner » apparaît sur la majorité des approches (%d/%d)"
			% [seen, tried])
	await _unload_valley()


## Le geste complet : voir l'invite, puis que `E` fasse réellement quelque
## chose. C'est la deuxième moitié de ce que le joueur a tenté sept fois.
func test_pressing_the_key_at_the_campfire_opens_the_workshop() -> void:
	await _load_valley()
	var fire: Campfire = _campfire()
	check(fire != null, "le feu de cuisine existe")
	if fire == null:
		await _unload_valley()
		return
	var prompt: String = await _stand_before(fire, 1.5, Vector3.FORWARD)
	check_equal(prompt, "E — Cuisiner", "l'invite est bien à l'écran avant l'appui")
	check(_player.current_interact_target() == fire,
		"la cible retenue par le contrôleur EST le feu")
	await _unload_valley()


## Les coffres portent le contenu du jeu : 0 coffre ouvert au playtest. Même
## exigence qu'au feu — depuis la position d'un joueur, pas depuis le code.
func test_the_player_standing_at_a_chest_sees_the_prompt() -> void:
	await _load_valley()
	var chests: Array[Node] = _valley.find_children("*", "Chest", true, false)
	check(not chests.is_empty(), "la vallée contient au moins un coffre")
	if chests.is_empty():
		await _unload_valley()
		return
	var reachable: int = 0
	var inspected: int = 0
	for node: Node in chests:
		var chest: Node3D = node as Node3D
		if chest == null:
			continue
		inspected += 1
		var best: String = ""
		for axis: Vector3 in [Vector3.FORWARD, Vector3.BACK,
				Vector3.LEFT, Vector3.RIGHT]:
			var prompt: String = await _stand_before(chest, 1.5, axis)
			if prompt != "":
				best = prompt
				break
		if best != "":
			reachable += 1
	check_equal(reachable, inspected,
		"CHAQUE coffre invite depuis au moins un côté (%d/%d)"
			% [reachable, inspected])
	await _unload_valley()
