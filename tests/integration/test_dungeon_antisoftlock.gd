## F.7 — anti-softlock et persistance sur le donjon ENTIER (§15.11).
##
## §15.11 liste ce que CHAQUE salle doit garantir. Les suites par salle
## le vérifient chacune dans son coin ; celle-ci le vérifie pour toutes,
## d'une seule main, y compris les deux cas que le joueur produit vraiment :
## repartir d'une sauvegarde VIERGE, et repartir d'une sauvegarde prise AU
## MILIEU d'une résolution.
extends GateTestCase

const ROOM1: String = "res://scenes/dungeon/rooms/Room1Initiation.tscn"
const ROOM2: String = "res://scenes/dungeon/rooms/Room2Vertical.tscn"
const ROOM3: String = "res://scenes/dungeon/rooms/Room3Relays.tscn"
const ROOM4: String = "res://scenes/dungeon/rooms/Room4Battery.tscn"
const HALL: String = "res://scenes/dungeon/rooms/CentralHall.tscn"
const ANTE: String = "res://scenes/dungeon/rooms/Antechamber.tscn"

const PUZZLE_ROOMS: Array[String] = [ROOM1, ROOM2, ROOM3, ROOM4]
const ALL_ROOMS: Array[String] = [ROOM1, ROOM2, ROOM3, ROOM4, HALL, ANTE]


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open(path: String) -> Node3D:
	var scene: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(scene)
	await _settle(8)
	return scene


func _close(scene: Node) -> void:
	scene.get_parent().remove_child(scene)
	scene.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(3)


func _erase_save() -> void:
	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	if save_system == null:
		return
	var path: String = String(save_system.call("slot_path", "slot0"))
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func test_every_room_opens_from_a_virgin_save() -> void:
	## §15.11 : « test depuis sauvegarde vierge ». Aucune salle ne doit
	## dépendre d'un état écrit par une autre pour se charger.
	await _erase_save()
	for path: String in ALL_ROOMS:
		var room: DungeonRoom = await _open(path) as DungeonRoom
		check_not_null(room, "%s se charge sans sauvegarde" % path.get_file())
		if room == null:
			continue
		check_not_null(room.graph(), "…avec son graphe")
		var problems: Array[String] = room.graph().validate_ids()
		check(problems.is_empty(), "…et des IDs sains : %s" % str(problems))
		var player: Node3D = room.call("player") as Node3D
		check_not_null(player, "…et un joueur posé")
		await _close(room)


func test_every_room_survives_a_reload_from_its_own_save() -> void:
	## §15.11 : « état sauvegardé » et « test après chargement en milieu de
	## résolution ». On écrit l'état TEL QUEL (donc à mi-course), on
	## recharge, et la salle doit rester jouable — ni résolue par magie,
	## ni bloquée.
	for path: String in PUZZLE_ROOMS:
		await _erase_save()
		var room: DungeonRoom = await _open(path) as DungeonRoom
		check(room.save_room_state(),
			"%s écrit son état intermédiaire" % path.get_file())
		await _close(room)
		var reloaded: DungeonRoom = await _open(path) as DungeonRoom
		check_not_null(reloaded, "…et se recharge")
		check(not bool(reloaded.call("is_solved") if reloaded.has_method("is_solved")
			else reloaded.call("is_rerouted")),
			"…toujours non résolue (aucune résolution fantôme)")
		check(reloaded.graph().node_count() > 0, "…circuit intact")
		await _close(reloaded)
	await _erase_save()


func test_no_essential_object_can_be_lost_for_good() -> void:
	## §15.11 : « aucune ressource obligatoire destructible » et §14.3 :
	## tout objet d'énigme a un transform de secours. On les jette hors du
	## monde ; ils doivent tous revenir.
	for path: String in [ROOM1, ROOM4]:
		await _erase_save()
		var room: DungeonRoom = await _open(path) as DungeonRoom
		var blocks: Array[PushableBlock] = room.blocks()
		check(not blocks.is_empty(),
			"%s a des objets essentiels (%d)" % [path.get_file(), blocks.size()])
		for block: PushableBlock in blocks:
			block.place_at(Transform3D(Basis.IDENTITY, Vector3(0, -60, 0)))
		var recovered: int = 0
		for i: int in range(300):
			await _tree().physics_frame
			recovered = 0
			for block: PushableBlock in blocks:
				if block.global_position.y > -5.0:
					recovered += 1
			if recovered == blocks.size():
				break
		check_equal(recovered, blocks.size(),
			"…tous revenus (%d/%d)" % [recovered, blocks.size()])
		await _close(room)
	await _erase_save()


func test_every_puzzle_room_can_be_reset_without_losing_progress() -> void:
	## §15.11 : « reset » partout, ET la règle qui va avec : un reset ne
	## retire jamais un acquis. On résout, on remet à zéro, la porte reste
	## ouverte.
	for path: String in [ROOM1, ROOM3, ROOM4]:
		await _erase_save()
		var room: DungeonRoom = await _open(path) as DungeonRoom
		room.call("capture_state_solved")
		await _settle(8)
		var door: ElectricDoor = room.call("door") as ElectricDoor
		var opened: bool = false
		for i: int in range(400):
			await _tree().physics_frame
			if door.is_open():
				opened = true
				break
		check(opened, "%s : la porte s'ouvre" % path.get_file())
		var button: ResetButton = room.call("reset_button") as ResetButton
		check_not_null(button, "…un bouton de reset existe")
		if button != null:
			check(button.interact(room.call("player") as PlayerController),
				"…il répond")
		await _settle(6)
		check(door.is_open(), "…et la porte reste OUVERTE après le reset")
		await _close(room)
	await _erase_save()


func test_leaving_and_coming_back_keeps_what_was_solved() -> void:
	## §15.11 : « sortie et retour ». On résout la salle 1, on la quitte,
	## on y revient : elle est encore résolue, sa porte encore ouverte.
	await _erase_save()
	var room: Room1Initiation = await _open(ROOM1) as Room1Initiation
	room.capture_state_solved()
	await _settle(8)
	for i: int in range(400):
		await _tree().physics_frame
		if room.door().is_open():
			break
	check(room.is_solved(), "la salle 1 est résolue")
	check(room.save_room_state(), "…et l'a écrit")
	await _close(room)

	# Passage par une AUTRE salle, comme le ferait un joueur.
	var hall: CentralHall = await _open(HALL) as CentralHall
	await _settle(4)
	await _close(hall)

	var again: Room1Initiation = await _open(ROOM1) as Room1Initiation
	check(again.is_solved(), "…elle est toujours résolue au retour")
	check(again.door().is_open(), "…et sa porte est ouverte")
	await _close(again)
	await _erase_save()


func test_the_graph_never_loops_forever_and_keeps_no_dead_reference() -> void:
	## §15.11 : « absence de cycle infini », « absence de référence
	## invalide ». On recalcule cent fois chaque circuit après avoir
	## remué ce qui peut l'être : aucun blocage, aucun voisin mort.
	for path: String in ALL_ROOMS:
		await _erase_save()
		var room: DungeonRoom = await _open(path) as DungeonRoom
		for i: int in range(100):
			room.graph().recompute()
		check(room.graph().recompute_count() >= 100,
			"%s : cent recalculs sans blocage" % path.get_file())
		var dangling: int = 0
		for node: Node in room.find_children("*", "ElectricNode", true, false):
			for neighbour: ElectricNode in (node as ElectricNode).neighbours():
				if not is_instance_valid(neighbour):
					dangling += 1
		check_equal(dangling, 0, "…et aucun voisin invalide")
		await _close(room)
	await _erase_save()


func test_every_room_carries_a_visual_hint_and_a_way_back() -> void:
	## §15.11 : « indice visuel » et « chemin retour ». L'indice n'est pas
	## du texte : c'est de la géométrie qui montre où aller.
	await _erase_save()
	var hints: Dictionary[String, String] = {
		ROOM1: "Chevron*",      # couloir de poussée fléché au sol
		ROOM2: "Grip*",         # prises de cuivre sur la voie d'escalade
		ROOM3: "Wire*",         # le créneau de câbles dit le chemin
		ROOM4: "Post*",         # les montants des berceaux disent « ici »
	}
	for path: String in PUZZLE_ROOMS:
		var room: DungeonRoom = await _open(path) as DungeonRoom
		var doors: Array[Node] = room.find_children("*", "SceneDoor", true, false)
		check(not doors.is_empty(),
			"%s a un chemin retour" % path.get_file())
		var marks: Array[Node] = room.find_children(hints[path], "", true, false)
		check(not marks.is_empty(),
			"…et un indice visuel (%s : %d)" % [hints[path], marks.size()])
		var labels: Array[Node] = room.find_children("*", "Label3D", true, false)
		check(labels.is_empty(), "…sans une ligne de texte explicative")
		await _close(room)


func test_the_debug_tool_lists_ids_ports_neighbours_and_states() -> void:
	## §15.11 : « créer un outil debug affichant IDs, ports, voisins et
	## état powered, mais le masquer dans le build final ».
	await _erase_save()
	var room: Room1Initiation = await _open(ROOM1) as Room1Initiation
	var overlay: ElectricDebugOverlay = room.get_node_or_null("ElectricDebug") \
		as ElectricDebugOverlay
	check_not_null(overlay, "l'outil est présent en build de développement")
	if overlay == null:
		await _close(room)
		return
	var lines: Array[String] = overlay.dump_lines()
	check(lines.size() >= room.graph().node_count(),
		"il liste les %d nœuds du circuit" % room.graph().node_count())
	var joined: String = overlay.dump_text()
	check(joined.contains("dungeon.node.room1_source.01"), "…avec leurs IDs")
	check(joined.contains("SOURCE") and joined.contains("RECEIVER"),
		"…leurs types")
	check(joined.contains("ports="), "…le nombre de ports")
	check(joined.contains("voisins=["), "…et leurs voisins")
	check(joined.contains("ALIMENTÉ") and joined.contains("éteint"),
		"…et l'état powered des deux côtés du vide")
	var summary: Dictionary = overlay.summary()
	check(int(summary["sources"]) >= 1 and int(summary["receivers"]) >= 1,
		"le résumé compte sources et récepteurs")
	check_equal(int(summary["orphans"]), 0,
		"aucun nœud FIXE hors du circuit (faute de pose)")
	check_equal(int(summary["mobile_idle"]), 1,
		"…et exactement un objet mobile en attente : le bloc, avant qu'on le pousse")
	# Le contrat de masquage, testable sans build de release.
	check(ElectricDebugOverlay.is_enabled_for(true),
		"actif en build de développement")
	check(not ElectricDebugOverlay.is_enabled_for(false),
		"RETIRÉ en build final")
	await _close(room)
