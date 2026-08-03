## F.8 — le donjon RÉSOLU de bout en bout, depuis une sauvegarde vierge
## (MASTER_SPEC §22 Gate F : « quatre salles solvables depuis sauvegarde
## vierge et intermédiaire »).
##
## Ce que ce test fait vraiment, et ce qu'il ne fait pas :
##   - chaque énigme est résolue par SON GESTE RÉEL — le bloc est poussé
##     par le joueur qui marche, le levier est basculé par `interact()`,
##     les colonnes sont tournées une par une, la batterie est PRISE,
##     PORTÉE et POSÉE. Aucun `capture_state_*`, aucun état forcé ;
##   - entre deux gestes, le joueur est REPOSITIONNÉ dans la salle plutôt
##     que promené : la marche est prouvée ailleurs (poussée du bloc,
##     escalade du puits, rampe du hall) et la refaire ici coûterait des
##     minutes de simulation sans rien démontrer de neuf. C'est dit
##     franchement plutôt que caché ;
##   - l'état passe d'une salle à l'autre par la VRAIE sauvegarde commune,
##     comme en jeu.
extends GateTestCase

const ROOM1: String = "res://scenes/dungeon/rooms/Room1Initiation.tscn"
const ROOM2: String = "res://scenes/dungeon/rooms/Room2Vertical.tscn"
const ROOM3: String = "res://scenes/dungeon/rooms/Room3Relays.tscn"
const ROOM4: String = "res://scenes/dungeon/rooms/Room4Battery.tscn"
const HALL: String = "res://scenes/dungeon/rooms/CentralHall.tscn"
const ANTE: String = "res://scenes/dungeon/rooms/Antechamber.tscn"


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


func _drive(player: PlayerController, intent: InputIntent, world_dir: Vector3,
		ticks: int) -> void:
	for i: int in range(ticks):
		var yaw: Basis = (player.get_node("CameraRig/YawPivot") as Node3D) \
			.global_transform.basis
		var forward: Vector3 = -yaw.z
		forward.y = 0.0
		var right: Vector3 = yaw.x
		right.y = 0.0
		intent.move = Vector2(world_dir.dot(right.normalized()),
			world_dir.dot(forward.normalized())).normalized()
		await _tree().physics_frame
	intent.move = Vector2.ZERO


func _wait_for_door(door: ElectricDoor, ticks: int) -> bool:
	for i: int in range(ticks):
		await _tree().physics_frame
		if door.is_open():
			return true
	return false


## Salle 1 : le joueur POUSSE le bloc jusqu'au contact.
func _solve_room1() -> bool:
	var room: Room1Initiation = await _open(ROOM1) as Room1Initiation
	var player: PlayerController = room.player()
	var intent: InputIntent = InputIntent.new()
	player.set_intent_source(intent)
	await _drive(player, intent, Vector3(0, 0, -1), 900)
	var opened: bool = await _wait_for_door(room.door(), 200)
	check(room.is_solved(), "salle 1 : le bloc a fermé le circuit")
	check(opened, "salle 1 : la porte est ouverte")
	var saved: bool = room.save_room_state()
	check(saved, "salle 1 : état écrit dans la sauvegarde commune")
	await _close(room)
	return opened and saved


## Salle 2 : le joueur BASCULE le levier de la mezzanine.
func _solve_room2() -> bool:
	var room: Room2Vertical = await _open(ROOM2) as Room2Vertical
	var lever: ElectricSwitch = room.reroute_switch()
	check(lever.interact(room.player()), "salle 2 : le levier répond")
	await _settle(8)
	var opened: bool = await _wait_for_door(room.door(), 400)
	check(room.is_rerouted(), "salle 2 : le courant est redirigé")
	check(opened, "salle 2 : la porte du haut est ouverte")
	for hazard: ElectricHazard in room.hazards():
		check(not hazard.node().is_powered(),
			"salle 2 : %s est éteinte" % hazard.name)
	var saved: bool = room.save_room_state()
	check(saved, "salle 2 : état écrit")
	await _close(room)
	return opened and saved


## Salle 3 : le joueur TOURNE les quatre colonnes, un quart de tour à la
## fois, jusqu'à la seule configuration qui referme la ligne.
func _solve_room3() -> bool:
	var room: Room3Relays = await _open(ROOM3) as Room3Relays
	var solution: Array[int] = [2, 0, 1, 3]
	var turns: int = 0
	for i: int in range(room.relays().size()):
		var relay: ElectricRelay = room.relays()[i]
		for guard: int in range(8):
			if relay.step_index() == solution[i]:
				break
			relay.interact(room.player())
			turns += 1
			for tick: int in range(120):
				await _tree().physics_frame
				if not relay.is_turning():
					break
	await _settle(6)
	var opened: bool = await _wait_for_door(room.door(), 400)
	check(turns > 0, "salle 3 : %d quarts de tour joués" % turns)
	check(room.is_solved(), "salle 3 : le circuit est refermé")
	check(opened, "salle 3 : la porte est ouverte")
	var saved: bool = room.save_room_state()
	check(saved, "salle 3 : état écrit")
	await _close(room)
	return opened and saved


## Salle 4 : PRENDRE la batterie, la POSER dans le berceau de charge,
## couper le courant, la reprendre, la poser dans le berceau de la porte.
func _solve_room4() -> bool:
	var room: Room4Battery = await _open(ROOM4) as Room4Battery
	var player: PlayerController = room.player()
	var battery: PortableBattery = room.battery()

	player.global_position = battery.global_position + Vector3(0, 0, 1.4)
	await _settle(6)
	check(battery.interact(player), "salle 4 : la batterie est PRISE")
	# Le porteur va au berceau de charge et repose la batterie dedans.
	player.global_position = room.charge_socket().global_position \
		+ Vector3(0, 0.3, 1.6)
	await _settle(6)
	check(battery.interact(player), "salle 4 : elle est POSÉE au berceau")
	var charged: bool = false
	for i: int in range(600):
		await _tree().physics_frame
		if battery.charge_ratio() > 0.5:
			charged = true
			break
	check(charged, "salle 4 : elle se charge (%.0f %%)"
		% (battery.charge_ratio() * 100.0))
	# Geste du joueur, dans l'ordre qui a un sens : on REPREND d'abord la
	# batterie — tant qu'elle est dans son berceau, elle continue d'alimenter
	# le circuit, donc l'eau (comportement systémique voulu, testé à part) —
	# PUIS on coupe la source (§15.8, première solution).
	check(battery.interact(player), "salle 4 : la batterie est reprise")
	await _settle(8)
	check(room.main_switch().interact(player), "salle 4 : le courant est coupé")
	await _settle(10)
	check(not room.water().is_discharging(), "salle 4 : la nappe est morte")
	player.global_position = room.door_socket().global_position \
		+ Vector3(0, 0.3, 1.6)
	await _settle(6)
	check(battery.interact(player), "salle 4 : elle est posée au berceau de la porte")
	await _settle(30)
	var opened: bool = await _wait_for_door(room.door(), 400)
	check(room.is_solved(), "salle 4 : le courant a traversé DANS la batterie")
	check(opened, "salle 4 : la porte est ouverte")
	var saved: bool = room.save_room_state()
	check(saved, "salle 4 : état écrit")
	await _close(room)
	return opened and saved


func test_the_four_rooms_are_solvable_from_a_virgin_save() -> void:
	## Gate F, critère principal. Sauvegarde effacée : rien n'est acquis.
	await _erase_save()
	var one: bool = await _solve_room1()
	var two: bool = await _solve_room2()
	var three: bool = await _solve_room3()
	var four: bool = await _solve_room4()
	check(one and two and three and four,
		"les quatre salles ont été résolues d'affilée, depuis rien")

	# La salle centrale lit la sauvegarde commune : trois circuits vivants.
	var hall: CentralHall = await _open(HALL) as CentralHall
	check_equal(hall.powered_circuits(), 3,
		"les trois circuits permanents débitent (§15.9)")
	var boss_opened: bool = await _wait_for_door(hall.boss_door(), 900)
	check(boss_opened, "la porte du boss s'ouvre pour de bon")
	await _close(hall)

	# Et l'antichambre est atteignable, avec son checkpoint.
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	game_state.call("set_pending_spawn", &"antechamber_from_hall")
	var ante: Antechamber = await _open(ANTE) as Antechamber
	check(ante.checkpoint_written(), "l'antichambre pose le checkpoint (§19.5)")
	check_not_null(ante.chest(), "…et tient son coffre garanti")
	await _close(ante)
	await _erase_save()


func test_the_dungeon_resumes_from_an_intermediate_save() -> void:
	## Gate F, second critère : « solvable depuis une sauvegarde
	## INTERMÉDIAIRE ». On coupe le run en deux — deux salles faites, la
	## sauvegarde relue depuis le disque, puis les deux autres.
	await _erase_save()
	var one: bool = await _solve_room1()
	var two: bool = await _solve_room2()
	check(one and two, "deux salles faites")

	# Relecture RÉELLE du fichier : c'est l'état qui traverse, pas un objet
	# gardé en mémoire.
	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	var data: Dictionary = save_system.call("load_slot", "slot0") as Dictionary
	var rooms: Dictionary = data.get("dungeon", {}) as Dictionary
	check(rooms.has("dungeon.room.initiation.01"),
		"la sauvegarde intermédiaire connaît la salle 1")
	check(rooms.has("dungeon.room.vertical.02"), "…et la salle 2")

	var hall_mid: CentralHall = await _open(HALL) as CentralHall
	check_equal(hall_mid.powered_circuits(), 1,
		"un seul circuit debout à mi-parcours (la salle 1 n'en alimente aucun)")
	check(not hall_mid.boss_door().is_latched(),
		"…et la porte du boss reste fermée")
	await _close(hall_mid)

	var three: bool = await _solve_room3()
	var four: bool = await _solve_room4()
	check(three and four, "les deux dernières salles se résolvent APRÈS reprise")

	var hall_end: CentralHall = await _open(HALL) as CentralHall
	check_equal(hall_end.powered_circuits(), 3, "les trois circuits y sont")
	check(await _wait_for_door(hall_end.boss_door(), 900),
		"la porte du boss s'ouvre depuis une reprise")
	await _close(hall_end)
	await _erase_save()
