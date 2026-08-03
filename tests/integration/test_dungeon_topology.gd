## Topologie du donjon assemblé (F.6, MASTER_SPEC §6.1, §15.11).
##
## Une salle testable seule ne fait pas un donjon. Ici on vérifie
## l'ASSEMBLAGE : chaque seuil mène à une scène qui existe, chaque
## traversée dépose le joueur DEVANT la porte par laquelle il pourrait
## revenir (§6.1), et aucune porte ne mène nulle part.
extends GateTestCase

const VESTIBULE: String = "res://scenes/world/citadel/CitadelVestibule.tscn"
const ROOM1: String = "res://scenes/dungeon/rooms/Room1Initiation.tscn"
const ROOM2: String = "res://scenes/dungeon/rooms/Room2Vertical.tscn"
const ROOM3: String = "res://scenes/dungeon/rooms/Room3Relays.tscn"
const ROOM4: String = "res://scenes/dungeon/rooms/Room4Battery.tscn"
const HALL: String = "res://scenes/dungeon/rooms/CentralHall.tscn"
const ANTE: String = "res://scenes/dungeon/rooms/Antechamber.tscn"

const DUNGEON_SCENES: Array[String] = [ROOM1, ROOM2, ROOM3, ROOM4, HALL, ANTE]


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open(path: String) -> Node3D:
	var scene: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(scene)
	await _settle(6)
	return scene


func _close(scene: Node) -> void:
	scene.get_parent().remove_child(scene)
	scene.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


func _erase_save() -> void:
	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	if save_system == null:
		return
	var path: String = String(save_system.call("slot_path", "slot0"))
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func test_every_dungeon_door_points_at_a_real_scene() -> void:
	## Une porte qui mène à une scène inexistante est un crash différé.
	await _erase_save()
	var checked: int = 0
	for path: String in DUNGEON_SCENES:
		var scene: Node3D = await _open(path)
		var doors: Array[Node] = scene.find_children("*", "SceneDoor", true,
			false)
		check(not doors.is_empty(), "%s a au moins un seuil" % path.get_file())
		for door: Node in doors:
			var target: String = String((door as SceneDoor).target_scene)
			check(ResourceLoader.exists(target),
				"%s → %s existe" % [door.name, target.get_file()])
			check((door as SceneDoor).spawn_tag != &"",
				"…et porte un tag d'apparition")
			checked += 1
		await _close(scene)
	check(checked >= 10, "%d seuils vérifiés dans le donjon" % checked)


func test_the_vestibule_now_opens_into_the_dungeon() -> void:
	## D.1R.4 avait promis « le donjon est plus loin » avec un seuil scellé.
	## F.6 tient la promesse : le seuil du fond est une vraie porte.
	await _erase_save()
	var vestibule: Node3D = await _open(VESTIBULE)
	var door: SceneDoor = vestibule.get_node_or_null("DungeonDoor") as SceneDoor
	check_not_null(door, "le seuil du fond est une SceneDoor")
	if door != null:
		check_equal(String(door.target_scene), ROOM1,
			"…qui mène à la salle 1 du donjon")
		check(door.is_in_group("interactable"), "…et qui est interactable")
	check(vestibule.get_node_or_null("SealedDoor") == null,
		"le mur scellé a disparu : plus de fausse promesse")
	await _close(vestibule)


## Chaque traversée : (origine, destination, tag posé par la porte).
func _transitions() -> Array[Array]:
	return [
		[VESTIBULE, ROOM1, &"room1_from_vestibule"],
		[ROOM1, HALL, &"hall_from_room1"],
		[HALL, ROOM1, &"room1_from_hall"],
		[HALL, ROOM2, &"room2_from_hall"],
		[ROOM2, HALL, &"hall_from_room2"],
		[HALL, ROOM3, &"room3_from_hall"],
		[ROOM3, HALL, &"hall_from_room3"],
		[HALL, ROOM4, &"room4_from_hall"],
		[ROOM4, HALL, &"hall_from_room4"],
		[HALL, ANTE, &"antechamber_from_hall"],
		[ANTE, HALL, &"hall_from_antechamber"],
	]


func test_every_crossing_lands_in_front_of_the_way_back() -> void:
	## §6.1 : « ressortir replace le joueur DEVANT la porte, jamais au
	## spawn ». On pose le tag comme le ferait la porte, on charge la
	## destination, et on vérifie que le joueur atterrit à portée d'un
	## seuil qui ramène d'où il vient.
	await _erase_save()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	for entry: Array in _transitions():
		var origin: String = String(entry[0])
		var destination: String = String(entry[1])
		var tag: StringName = entry[2] as StringName
		game_state.call("set_pending_spawn", tag)
		var scene: Node3D = await _open(destination)
		var player: Node3D = scene.call("player") as Node3D
		check_not_null(player, "%s a un joueur" % destination.get_file())
		var best: float = 1e9
		for door: Node in scene.find_children("*", "SceneDoor", true, false):
			if String((door as SceneDoor).target_scene) != origin:
				continue
			best = minf(best,
				player.global_position.distance_to((door as Node3D).global_position))
		check(best < 6.0,
			"%s → %s : on arrive à %.1f m du seuil de retour"
			% [origin.get_file(), destination.get_file(), best])
		await _close(scene)
	await _erase_save()


func test_the_dungeon_graph_of_rooms_is_fully_connected() -> void:
	## Depuis le vestibule, toutes les salles doivent être atteignables en
	## suivant les portes — et toutes doivent ramener en arrière. Un donjon
	## dont une salle serait sans retour violerait §15.11.
	await _erase_save()
	var links: Dictionary[String, Array] = {}
	for path: String in DUNGEON_SCENES + [VESTIBULE]:
		var scene: Node3D = await _open(path)
		var targets: Array[String] = []
		for door: Node in scene.find_children("*", "SceneDoor", true, false):
			var target: String = String((door as SceneDoor).target_scene)
			if not targets.has(target):
				targets.append(target)
		links[path] = targets
		await _close(scene)
	# Parcours depuis le vestibule.
	var seen: Array[String] = [VESTIBULE]
	var queue: Array[String] = [VESTIBULE]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		for target: Variant in links.get(current, []):
			var next: String = String(target)
			if links.has(next) and not seen.has(next):
				seen.append(next)
				queue.append(next)
	for path: String in DUNGEON_SCENES:
		check(seen.has(path),
			"%s est atteignable depuis le vestibule" % path.get_file())
	# Et le retour : chaque salle a un seuil vers la salle centrale ou le
	# vestibule.
	for path: String in [ROOM1, ROOM2, ROOM3, ROOM4, ANTE]:
		var targets: Array = links[path] as Array
		check(targets.has(HALL) or targets.has(VESTIBULE),
			"%s a un chemin retour" % path.get_file())
	await _erase_save()


func test_the_hall_reflects_the_rooms_actually_solved() -> void:
	## Bout en bout : trois salles résolues dans la sauvegarde commune, et
	## la salle centrale ouvre la porte du boss — sans qu'aucun code de
	## salle ne touche à un compteur.
	await _erase_save()
	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	save_system.call("save_slot", "slot0", {
		"schema": 2,
		"checkpoint": "test",
		"dungeon": {
			"dungeon.room.vertical.02": {"rerouted": true},
			"dungeon.room.relays.03": {"solved": true},
			"dungeon.room.battery.04": {"solved": true},
		},
	})
	var hall: CentralHall = await _open(HALL) as CentralHall
	check_equal(hall.powered_circuits(), 3, "les trois circuits débitent")
	check(hall.boss_door().is_latched(), "la porte du boss s'engage")
	var opened: bool = false
	for i: int in range(600):
		await _tree().physics_frame
		if hall.boss_door().is_open():
			opened = true
			break
	check(opened, "…et s'ouvre en entier")
	await _close(hall)
	await _erase_save()
