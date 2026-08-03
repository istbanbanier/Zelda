## Salle 4 du donjon — batterie transportable (MASTER_SPEC §15.8, §15.3,
## §14.3, §15.11).
##
## Les deux solutions de §15.8 sont testées séparément : couper le courant,
## ou poser la planche isolante. Une énigme qui n'aurait qu'un chemin
## officiel et un chemin cassé ne vaudrait pas mieux qu'un couloir.
extends GateTestCase

const ROOM: String = "res://scenes/dungeon/rooms/Room4Battery.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open_room() -> Room4Battery:
	var room: Room4Battery = (load(ROOM) as PackedScene).instantiate() \
		as Room4Battery
	_tree().root.add_child(room)
	await _settle(10)
	return room


func _close(room: Node) -> void:
	room.get_parent().remove_child(room)
	room.queue_free()
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


func test_the_water_is_live_and_the_far_side_is_dead() -> void:
	## État initial de §15.8 : la source alimente la nappe, et le côté
	## EST n'a aucun courant — aucun câble ne traverse le canal.
	await _erase_save()
	var room: Room4Battery = await _open_room()
	check(room.source().is_powered(), "la source débite")
	check(room.water().node().is_powered(), "la nappe est sous tension")
	check(room.water().is_discharging(),
		"…et elle décharge en continu (ce n'est pas un piège rythmé)")
	check(not room.receiver().is_powered(),
		"le récepteur de la porte est mort : rien ne traverse le canal")
	check(not room.door().is_latched(), "la porte est fermée")
	check(not room.battery().is_charged(), "la batterie est vide")
	await _close(room)


func test_the_battery_charges_only_in_its_socket() -> void:
	## §15.3 : « distinguer charge stockée, SOCKET et décharge ». Posée
	## n'importe où, la batterie ne se remplit pas.
	await _erase_save()
	var room: Room4Battery = await _open_room()
	var battery: PortableBattery = room.battery()
	battery.place_at(Transform3D(Basis.IDENTITY, Vector3(-10.0, 0.6, 4.0)))
	await _settle(120)
	check(not battery.is_charged(),
		"posée à l'écart, elle reste vide (%.0f %%)"
		% (battery.charge_ratio() * 100.0))
	battery.place_at(Transform3D(Basis.IDENTITY, Vector3(-8.0, 1.2, 0.5)))
	await _settle(120)
	check(room.charge_socket().is_loaded(), "le berceau l'a calée")
	check(battery.is_charged(), "…et elle se remplit (%.0f %%)"
		% (battery.charge_ratio() * 100.0))
	await _close(room)


func test_cutting_the_current_makes_the_channel_safe() -> void:
	## Première solution de §15.8 : « couper le courant ». La nappe
	## s'éteint, et le berceau de charge s'éteint avec elle — c'est le prix
	## à payer, et c'est ce qui rend l'ordre des gestes intéressant.
	await _erase_save()
	var room: Room4Battery = await _open_room()
	check(room.main_switch().interact(room.player()), "le levier répond")
	await _settle(6)
	check(not room.water().node().is_powered(), "la nappe est morte")
	check(not room.water().is_discharging(), "…elle ne décharge plus")
	var contact: ElectricNode = room.get_node("ChargeContact") as ElectricNode
	check(not contact.is_powered(), "…et le berceau de charge aussi")
	# Rebasculable : §15.8 exige que le retour reste possible, donc que la
	# recharge reste possible.
	check(room.main_switch().interact(room.player()), "le levier se rebascule")
	await _settle(6)
	check(room.water().node().is_powered(), "la nappe revient")
	await _close(room)


func test_the_carried_battery_powers_the_far_door() -> void:
	## Deuxième mécanisme de §15.8 : la batterie chargée APPORTE le courant
	## là où aucun câble ne va.
	await _erase_save()
	var room: Room4Battery = await _open_room()
	var battery: PortableBattery = room.battery()
	battery.set_charge_seconds(battery.capacity)
	await _settle(4)
	battery.place_at(Transform3D(Basis.IDENTITY, Vector3(7.0, 1.2, -2.0)))
	await _settle(30)
	check(room.door_socket().is_loaded(), "le berceau de la porte l'a calée")
	check(room.receiver().is_powered(),
		"le récepteur s'allume — le courant a traversé DANS la batterie")
	check(room.is_solved(), "la salle se sait résolue")
	var opened: bool = false
	for i: int in range(300):
		await _tree().physics_frame
		if room.door().is_open():
			opened = true
			break
	check(opened, "la porte s'ouvre")
	await _close(room)


func test_the_player_picks_up_carries_and_drops_the_battery() -> void:
	## §14.2 : ramasser, transporter, poser — par le VRAI chemin
	## d'interaction, pas par un `place_at` de test.
	await _erase_save()
	var room: Room4Battery = await _open_room()
	var player: PlayerController = room.player()
	var battery: PortableBattery = room.battery()
	player.global_position = battery.global_position + Vector3(0, 0, 1.4)
	await _settle(10)
	check(battery.is_in_group("interactable"), "la batterie est interactable")
	check(battery.interact(player), "elle est prise")
	check(battery.is_carried(), "…elle est portée")
	await _settle(10)
	check(battery.global_position.distance_to(player.global_position) < 2.0,
		"…elle suit le porteur (%.2f m)"
		% battery.global_position.distance_to(player.global_position))
	# Le porteur se déplace : la batterie suit.
	player.global_position += Vector3(0, 0, -3.0)
	await _settle(10)
	check(battery.global_position.distance_to(player.global_position) < 2.0,
		"…toujours sur lui après trois mètres")
	check(battery.interact(player), "elle est reposée")
	check(not battery.is_carried(), "…elle n'est plus portée")
	await _settle(30)
	check(battery.global_position.y > -1.0, "…et elle repose sur le sol")
	await _close(room)


func test_the_plank_bridges_the_live_channel() -> void:
	## Seconde solution de §15.8 : « créer une passerelle isolante ». La
	## planche est du BOIS : elle ne conduit rien, elle porte. Debout
	## dessus, au-dessus d'une nappe SOUS TENSION, on ne prend rien.
	await _erase_save()
	var room: Room4Battery = await _open_room()
	var plank: CarryableObject = room.plank()
	check(plank.is_in_group("insulated"), "la planche est isolante (§14.4)")
	check(room.water().is_discharging(), "la nappe est bien sous tension")
	var socket: ObjectSocket = room.get_node("PlankSocketWest") as ObjectSocket
	plank.place_at(Transform3D(Basis.IDENTITY,
		socket.global_position + socket.seat_offset + Vector3(0, 0.4, 0)))
	await _settle(40)
	check(socket.is_loaded(), "le berceau ouest a calé la planche")
	var player: PlayerController = room.player()
	var health: float = player.health().current()
	player.global_position = socket.global_position + socket.seat_offset \
		+ Vector3(0, 1.2, 0)
	await _settle(150)
	check_equal(player.health().current(), health,
		"debout sur la planche, au-dessus de l'eau vive, aucun dégât")
	await _close(room)


func test_wading_into_a_live_channel_hurts_without_ending_the_run() -> void:
	## La nappe doit être un DANGER lisible, pas une exécution : §15.8 veut
	## qu'on puisse toujours revenir.
	await _erase_save()
	var room: Room4Battery = await _open_room()
	var player: PlayerController = room.player()
	var health: float = player.health().current()
	player.global_position = Vector3(0, -0.8, 5.0)   # dans le canal
	await _settle(150)
	check(player.health().current() < health,
		"patauger coûte (%.0f → %.0f PV)"
		% [health, player.health().current()])
	check(not player.health().is_dead(),
		"…mais deux secondes et demie dans l'eau ne tuent pas")
	await _close(room)


func test_a_battery_lost_in_the_channel_returns_to_the_charge_bank() -> void:
	## §14.3 et §15.8 : « batterie hors limites réapparaît », et jamais du
	## mauvais côté — elle revient TOUJOURS près de son berceau de charge.
	await _erase_save()
	var room: Room4Battery = await _open_room()
	var battery: PortableBattery = room.battery()
	battery.place_at(Transform3D(Basis.IDENTITY, Vector3(0, -1.2, 6.0)))
	var recovered: bool = false
	for i: int in range(240):
		await _tree().physics_frame
		if battery.global_position.y > 0.0:
			recovered = true
			break
	check(recovered, "la batterie revient")
	check(battery.global_position.x < -3.0,
		"…du côté de la charge (x = %.1f)" % battery.global_position.x)
	check(battery.global_position.distance_to(
		room.charge_socket().global_position) < 6.0,
		"…à portée de son berceau")
	await _close(room)


func test_no_door_stands_between_the_battery_and_its_charger() -> void:
	## §15.8 : « aucune porte ne verrouille la batterie du mauvais côté ».
	## On le VÉRIFIE au lieu de l'affirmer : la seule porte de la salle est
	## à l'est, au-delà du récepteur ; le berceau de charge et le point de
	## secours de la batterie sont tous deux à l'ouest.
	await _erase_save()
	var room: Room4Battery = await _open_room()
	var doors: Array[Node] = room.find_children("*", "ElectricDoor", true, false)
	check_equal(doors.size(), 1, "une seule porte à ouvrir")
	var door: ElectricDoor = doors[0] as ElectricDoor
	check(door.global_position.x > 5.0, "elle est à l'est")
	check(room.battery().rescue_transform().origin.x < -3.0,
		"le point de secours de la batterie est à l'ouest")
	check(room.charge_socket().global_position.x < -3.0,
		"…comme son berceau de charge")
	check(room.plank().rescue_transform().origin.x < -3.0,
		"…et comme celui de la planche")
	await _close(room)


func test_the_solved_room_reopens_solved() -> void:
	await _erase_save()
	var room: Room4Battery = await _open_room()
	room.capture_state_solved()
	await _settle(10)
	check(room.receiver().is_powered(), "circuit fermé par la batterie")
	for i: int in range(300):
		await _tree().physics_frame
		if room.door().is_open():
			break
	check(room.save_room_state(), "état écrit")
	await _close(room)

	var reloaded: Room4Battery = await _open_room()
	check(reloaded.door().is_open(), "la porte rouvre ouverte")
	check(reloaded.battery().is_charged(),
		"…et la batterie a gardé sa charge (%.0f %%)"
		% (reloaded.battery().charge_ratio() * 100.0))
	await _close(reloaded)
	await _erase_save()


func test_the_ids_are_unique_and_the_exit_exists() -> void:
	await _erase_save()
	var room: Room4Battery = await _open_room()
	var problems: Array[String] = room.graph().validate_ids()
	check(problems.is_empty(), "aucun ID vide ni dupliqué : %s" % str(problems))
	var doors: Array[Node] = room.find_children("*", "SceneDoor", true, false)
	check(not doors.is_empty(), "des seuils de sortie existent")
	check_equal(doors.size(), 2, "…deux seuils vers la salle centrale")
	for door: Node in doors:
		check_equal(String((door as SceneDoor).target_scene),
			"res://scenes/dungeon/rooms/CentralHall.tscn",
			"…qui pointe sur la salle centrale")
	await _close(room)
