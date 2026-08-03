## Salle 1 du donjon — initiation (MASTER_SPEC §15.5, §14.3, §15.11).
##
## Chaque exigence de §15.5 a ici son test, et le plus important d'entre
## eux ne triche pas : le bloc est poussé PAR LE JOUEUR, à la marche,
## sans téléportation ni écriture de transform. C'est la seule preuve qui
## dise quelque chose sur une salle jouable.
extends GateTestCase

const ROOM: String = "res://scenes/dungeon/rooms/Room1Initiation.tscn"
## Le bloc est en contact quand son centre est à moins de 0,84 m du plan
## des plaques — géométrie mesurée dans `room1_initiation.gd`.
const CONTACT_Z: float = -4.0


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open_room() -> Room1Initiation:
	var room: Room1Initiation = (load(ROOM) as PackedScene).instantiate() \
		as Room1Initiation
	_tree().root.add_child(room)
	await _settle(6)
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


## Pose le bloc au contact SANS le pousser — pour les tests qui mesurent
## ce qui vient APRÈS le contact (délai de porte, anneau, sauvegarde).
func _bridge(room: Room1Initiation) -> void:
	var block: PushableBlock = room.block()
	block.place_at(Transform3D(Basis.IDENTITY,
		Vector3(0, block.global_position.y, CONTACT_Z)))
	room.graph().mark_dirty()
	await _settle(3)


func test_the_room_starts_dark_shut_and_solvable() -> void:
	## État initial : le vide entre les plaques est un VRAI vide (aucun
	## courant ne le franchit), le récepteur est éteint, la porte fermée.
	await _erase_save()
	var room: Room1Initiation = await _open_room()
	check(room.source() != null and room.source().is_powered(),
		"la source est allumée dès le départ (§15.4 : pulsation lente)")
	check(not room.receiver().is_powered(),
		"le récepteur est ÉTEINT : le vide court n'est pas franchi")
	check(not room.door().is_latched(), "la porte est fermée")
	check_approx(room.door().open_ratio(), 0.0, 0.001,
		"…et son panneau n'a pas bougé")
	var west: ElectricNode = room.get_node("PlateWest") as ElectricNode
	var east: ElectricNode = room.get_node("PlateEast") as ElectricNode
	check(west.is_powered(), "la plaque ouest EST alimentée (câble visible)")
	check(not east.is_powered(),
		"…la plaque est ne l'est pas : la cause du blocage est lisible")
	var gap: float = west.global_position.distance_to(east.global_position)
	check(gap > west.port_reach + east.port_reach,
		"le vide mesure %.2f m pour %.2f m de portée cumulée" %
		[gap, west.port_reach + east.port_reach])
	check(room.block() != null, "le bloc métallique mobile est là")
	check(room.reset_button() != null, "le bouton de reset est là")
	await _close(room)


func test_the_player_pushes_the_block_and_opens_the_door() -> void:
	## LE test de la salle. Aucune téléportation, aucun transform écrit :
	## le joueur marche vers le nord, pousse le bloc de 40 kg jusqu'à la
	## butée, le courant traverse, la porte s'ouvre.
	await _erase_save()
	var room: Room1Initiation = await _open_room()
	var player: PlayerController = room.player()
	check_not_null(player, "le joueur est dans la salle")
	if player == null:
		await _close(room)
		return
	var block: PushableBlock = room.block()
	var start_z: float = block.global_position.z
	var intent: InputIntent = InputIntent.new()
	player.set_intent_source(intent)
	var opened: bool = false
	var ticks: int = 0
	for i: int in range(900):
		ticks += 1
		# §8.2 : le déplacement est RELATIF À LA CAMÉRA. Le pilote projette
		# la direction monde (-Z) dans le repère du lacet, comme le ferait
		# un joueur qui pousse le stick vers l'avant.
		var yaw: Basis = (player.get_node("CameraRig/YawPivot") as Node3D) \
			.global_transform.basis
		var forward: Vector3 = -yaw.z
		forward.y = 0.0
		var right: Vector3 = yaw.x
		right.y = 0.0
		var wish: Vector3 = Vector3(0, 0, -1)
		intent.move = Vector2(wish.dot(right.normalized()),
			wish.dot(forward.normalized())).normalized()
		await _tree().physics_frame
		if room.door().is_open():
			opened = true
			break
	intent.move = Vector2.ZERO
	check(block.global_position.z < start_z - 5.0,
		"le bloc a été POUSSÉ de %.2f m vers le nord" %
		(start_z - block.global_position.z))
	check(absf(block.global_position.z - CONTACT_Z) < 0.85,
		"…et il s'est arrêté au contact (z = %.2f)" % block.global_position.z)
	check(room.receiver().is_powered(),
		"le récepteur s'allume : le bloc a fermé le circuit")
	check(opened, "la porte s'est ouverte en %d ticks de marche" % ticks)
	check(room.is_solved(), "la salle est marquée résolue")
	await _close(room)


func test_the_door_waits_between_06_and_12_seconds() -> void:
	## §15.5 : « porte s'ouvre avec délai 0,6-1,2 s ». Mesuré, pas déclaré.
	await _erase_save()
	var room: Room1Initiation = await _open_room()
	await _bridge(room)
	check(room.receiver().is_powered(), "contact établi")
	var delay: float = 0.0
	var step: float = 1.0 / float(Engine.physics_ticks_per_second)
	for i: int in range(200):
		if room.door().open_ratio() > 0.0:
			break
		delay += step
		await _tree().physics_frame
	check(delay >= ElectricDoor.DELAY_MIN - 0.05,
		"le mécanisme attend au moins %.2f s (mesuré %.2f s)" %
		[ElectricDoor.DELAY_MIN, delay])
	check(delay <= ElectricDoor.DELAY_MAX + 0.05,
		"…et pas plus de %.2f s (mesuré %.2f s)" %
		[ElectricDoor.DELAY_MAX, delay])
	await _close(room)


func test_the_light_travels_along_the_circuit() -> void:
	## §15.5 : « propagation lumineuse visible ». La logique bascule d'un
	## coup ; la LUMIÈRE, elle, part de la source et arrive au récepteur —
	## donc à un instant donné, le début du circuit est plus allumé que la
	## fin. Un allumage simultané échouerait ici.
	await _erase_save()
	var room: Room1Initiation = await _open_room()
	await _bridge(room)
	var near: ElectricVisual = room.get_node("WireEast01/Visual") \
		as ElectricVisual
	var far: ElectricVisual = room.get_node("WireDoorSpur02/Visual") \
		as ElectricVisual
	check_not_null(near, "segment proche de la source")
	check_not_null(far, "segment proche de la porte")
	var seen_ahead: bool = false
	for i: int in range(120):
		if near.fill_ratio() > far.fill_ratio() + 0.15:
			seen_ahead = true
			break
		await _tree().process_frame
	check(seen_ahead,
		"le cyan atteint le début du circuit AVANT sa fin (propagation)")
	for i: int in range(200):
		if far.fill_ratio() >= 0.99:
			break
		await _tree().process_frame
	check_approx(far.fill_ratio(), 1.0, 0.02,
		"…et il finit par atteindre la porte")
	var ring: ReceiverRing = room.receiver().get_node("Ring") as ReceiverRing
	for i: int in range(200):
		if ring.closed_ratio() >= 0.99:
			break
		await _tree().process_frame
	check_equal(ring.lit_segments(), ReceiverRing.SEGMENTS,
		"l'anneau du récepteur s'est FERMÉ (§15.4)")
	await _close(room)


func test_the_reset_button_replays_the_puzzle_without_taking_anything_back()\
		-> void:
	## §15.5 « bouton reset » et §15.11 anti-softlock : le reset ramène le
	## bloc à son départ, MAIS ne referme pas une porte déjà ouverte.
	await _erase_save()
	var room: Room1Initiation = await _open_room()
	await _bridge(room)
	for i: int in range(150):
		if room.door().is_open():
			break
		await _tree().physics_frame
	check(room.door().is_open(), "porte ouverte avant le reset")
	var button: ResetButton = room.reset_button()
	check(button.is_in_group("interactable"),
		"le bouton est un interactable (§14.2)")
	check(button.interact(room.player()), "l'interaction est acceptée")
	await _settle(4)
	check_approx(room.block().global_position.z, 3.0, 0.2,
		"le bloc est revenu à son départ")
	check(not room.receiver().is_powered(), "le circuit est rouvert")
	check(room.door().is_open(),
		"…et la porte reste OUVERTE : un reset ne retire jamais un acquis")
	check_equal(button.press_count(), 1, "une pression comptée")
	await _close(room)


func test_a_block_thrown_out_of_the_world_comes_back() -> void:
	## §14.3 : « s'il tombe, réapparaître après 1-2 s ». Sans ce filet, la
	## salle serait perdable — ce que §15.5 interdit explicitement.
	await _erase_save()
	var room: Room1Initiation = await _open_room()
	var block: PushableBlock = room.block()
	block.place_at(Transform3D(Basis.IDENTITY, Vector3(0, -40, 0)))
	await _settle(2)
	check(block.is_lost(), "le bloc est reconnu hors du monde")
	var recovered: bool = false
	var elapsed: float = 0.0
	var step: float = 1.0 / float(Engine.physics_ticks_per_second)
	for i: int in range(200):
		elapsed += step
		await _tree().physics_frame
		if block.global_position.y > 0.0:
			recovered = true
			break
	check(recovered, "il réapparaît (%.2f s)" % elapsed)
	check(elapsed >= 1.0 and elapsed <= 2.2,
		"…dans la fenêtre 1-2 s de §14.3 (mesuré %.2f s)" % elapsed)
	check_approx(block.global_position.z, 3.0, 0.2,
		"…à son transform de secours")
	await _close(room)


func test_the_solution_cannot_be_overshot() -> void:
	## « Solution impossible à perdre » : même lancé au-delà de la zone de
	## contact, le bloc est arrêté par la butée et RESTE au contact.
	await _erase_save()
	var room: Room1Initiation = await _open_room()
	var block: PushableBlock = room.block()
	block.place_at(Transform3D(Basis.IDENTITY,
		Vector3(0, block.global_position.y, 0.0)))
	await _settle(2)
	# 40 m/s : cent fois ce que la poussée du joueur peut produire (elle
	# est plafonnée à 2,2 m/s). Si un jour une explosion ou un défaut de
	# solveur lance le bloc, la butée doit tenir quand même.
	block.apply_central_impulse(Vector3(0, 0, -1) * block.mass * 40.0)
	for i: int in range(200):
		await _tree().physics_frame
	check(block.global_position.z > CONTACT_Z - 0.85,
		"la butée arrête le bloc au contact malgré 40 m/s (z = %.2f)" %
		block.global_position.z)
	check(absf(block.global_position.x) < 0.5 and block.global_position.y > 0.5,
		"…sans le faire sauter hors du couloir")
	check(room.receiver().is_powered(),
		"…et le circuit est fermé, jamais dépassé")
	await _close(room)


func test_the_room_carries_no_explanatory_text() -> void:
	## §15.5 : « objectif compréhensible sans texte ». Ce test prouve
	## l'ABSENCE de texte, pas la compréhension — celle-ci demande un œil
	## humain et reste NON VÉRIFIÉE (docs/MANUAL_VALIDATION.md).
	await _erase_save()
	var room: Room1Initiation = await _open_room()
	var labels: Array[Node] = room.find_children("*", "Label3D", true, false)
	check(labels.is_empty(), "aucun panneau de texte dans la salle")
	check(not room.find_children("Chevron*", "MeshInstance3D", true, false)
		.is_empty(), "…mais des chevrons au sol montrent la direction")
	check(room.get_node_or_null("ChannelStop") != null,
		"…et une butée matérialise la destination du bloc")
	await _close(room)


func test_the_solved_room_reopens_solved() -> void:
	## §15.11 : « état sauvegardé » et §19.4 : l'état s'APPLIQUE. Une
	## salle résolue, rechargée depuis le disque, démarre porte ouverte —
	## sans rejouer l'animation ni redemander le puzzle.
	await _erase_save()
	var room: Room1Initiation = await _open_room()
	await _bridge(room)
	for i: int in range(150):
		if room.door().is_open():
			break
		await _tree().physics_frame
	check(room.is_solved(), "salle résolue")
	check(room.save_room_state(), "état écrit dans le slot commun")
	await _close(room)

	var reloaded: Room1Initiation = await _open_room()
	check(reloaded.is_solved(), "…la salle rechargée se sait résolue")
	check(reloaded.door().is_open(),
		"…et sa porte est ouverte dès la première image")
	check_approx(reloaded.block().global_position.z, CONTACT_Z, 0.9,
		"…le bloc est là où le joueur l'avait laissé")
	await _close(reloaded)
	await _erase_save()


func test_reloading_mid_resolution_never_locks_the_room() -> void:
	## §15.11 : « test après chargement en milieu de résolution ». Le bloc
	## est sauvegardé À MI-CHEMIN : au rechargement la salle n'est ni
	## résolue ni bloquée, et le puzzle reste jouable.
	await _erase_save()
	var room: Room1Initiation = await _open_room()
	var block: PushableBlock = room.block()
	block.place_at(Transform3D(Basis.IDENTITY,
		Vector3(0, block.global_position.y, -0.5)))
	await _settle(3)
	check(not room.is_solved(), "salle non résolue au moment de la sauvegarde")
	check(room.save_room_state(), "état intermédiaire écrit")
	await _close(room)

	var reloaded: Room1Initiation = await _open_room()
	check(not reloaded.is_solved(), "…elle redémarre non résolue")
	check(not reloaded.door().is_latched(), "…porte toujours fermée")
	check_approx(reloaded.block().global_position.z, -0.5, 0.4,
		"…le bloc a repris sa place à mi-chemin")
	# Et le puzzle reste soluble depuis cet état.
	await _bridge(reloaded)
	check(reloaded.receiver().is_powered(),
		"…le circuit se ferme encore : aucun softlock")
	await _close(reloaded)
	await _erase_save()


func test_the_block_can_be_placed_in_its_very_first_frame() -> void:
	## Un chargement replace le bloc depuis `_ready()` (§19.4) : le
	## placement doit donc tenir dans la frame même où le corps naît,
	## avant que le solveur ait fait un pas avec lui.
	await _erase_save()
	var room: Room1Initiation = (load(ROOM) as PackedScene).instantiate() \
		as Room1Initiation
	_tree().root.add_child(room)
	# AUCUNE frame ici : on est dans la fenêtre exacte du blocage.
	room.capture_state_solved()
	check_approx(room.block().global_position.z, CONTACT_Z, 0.01,
		"le bloc est posé au contact dès l'appel")
	await _settle(30)
	check_approx(room.block().global_position.z, CONTACT_Z, 0.3,
		"…il y est encore après 30 ticks (le moteur a continué de tourner)")
	check(room.receiver().is_powered(), "…et le circuit s'est fermé")
	await _close(room)


func test_the_room_ids_are_unique_and_the_exit_exists() -> void:
	## §19.3 : ID vide ou dupliqué = faute de conception. §15.11 : « chemin
	## retour » — la salle a une sortie vers le vestibule.
	await _erase_save()
	var room: Room1Initiation = await _open_room()
	var problems: Array[String] = room.graph().validate_ids()
	check(problems.is_empty(), "aucun ID vide ni dupliqué : %s" % str(problems))
	check(room.graph().node_count() >= 25,
		"le circuit compte %d nœuds réels" % room.graph().node_count())
	var doors: Array[Node] = room.find_children("*", "SceneDoor", true, false)
	check_equal(doors.size(), 2,
		"deux seuils : le vestibule au sud, la salle centrale au nord")
	var targets: Array[String] = []
	for door: Node in doors:
		targets.append(String((door as SceneDoor).target_scene))
	check(targets.has("res://scenes/world/citadel/CitadelVestibule.tscn"),
		"…l'un revient au vestibule")
	check(targets.has("res://scenes/dungeon/rooms/CentralHall.tscn"),
		"…l'autre mène à la salle centrale (F.6 : la porte du puzzle SERT)")
	await _close(room)
