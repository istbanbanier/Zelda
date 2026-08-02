## Salle 3 du donjon — relais rotatifs (MASTER_SPEC §15.7, §15.3, §15.11).
##
## Le test le plus important est le SOLVEUR exigé par §15.7 : il énumère
## les 256 configurations possibles et prouve qu'au moins une referme le
## circuit — et que celle du départ n'en est pas une. Une énigme dont on
## n'a pas prouvé qu'elle a une solution n'est pas une énigme.
extends GateTestCase

const ROOM: String = "res://scenes/dungeon/rooms/Room3Relays.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open_room() -> Room3Relays:
	var room: Room3Relays = (load(ROOM) as PackedScene).instantiate() \
		as Room3Relays
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


func test_the_room_starts_unsolved_with_a_partial_path() -> void:
	## §15.7 : « feedback distinct si chemin partiel ». Le courant part
	## bien de la source et meurt À la première colonne mal tournée : la
	## ligne allumée DIT jusqu'où il passe.
	await _erase_save()
	var room: Room3Relays = await _open_room()
	check(room.source().is_powered(), "la source débite")
	check(not room.receiver().is_powered(), "le récepteur reste éteint")
	check(not room.door().is_latched(), "la porte est fermée")
	var wire_in: ElectricNode = room.get_node("WireIn01") as ElectricNode
	check(wire_in.is_powered(),
		"le premier segment EST allumé : le courant arrive à la colonne")
	var wire_out: ElectricNode = room.get_node("WireOut01") as ElectricNode
	check(not wire_out.is_powered(),
		"…et le dernier ne l'est pas : le chemin s'arrête en route")
	check_equal(room.relays().size(), 4, "quatre colonnes (§15.7)")
	await _close(room)


func test_the_solver_proves_a_solution_exists() -> void:
	## §15.7 : « solveur/test automatique vérifie au moins une
	## configuration solution ». 4 colonnes × 4 orientations = 256 essais,
	## joués sur le VRAI graphe, pas sur un modèle de papier.
	await _erase_save()
	var room: Room3Relays = await _open_room()
	var relays: Array[ElectricRelay] = room.relays()
	var start: Array[int] = []
	for relay: ElectricRelay in relays:
		start.append(relay.step_index())
	var solutions: Array[Array] = []
	for a: int in range(4):
		for b: int in range(4):
			for c: int in range(4):
				for d: int in range(4):
					relays[0].set_step_index(a)
					relays[1].set_step_index(b)
					relays[2].set_step_index(c)
					relays[3].set_step_index(d)
					room.graph().recompute()
					if room.receiver().is_powered():
						solutions.append([a, b, c, d])
	check(solutions.size() >= 1,
		"au moins une configuration résout (%d trouvée(s) : %s)"
		% [solutions.size(), str(solutions)])
	check(not solutions.has(start),
		"…et la configuration de DÉPART %s n'en est pas une" % str(start))
	# Une énigme à 256 solutions n'en serait pas une non plus.
	check(solutions.size() <= 4,
		"…la solution reste rare (%d sur 256)" % solutions.size())
	await _close(room)


func test_a_column_turns_by_discrete_steps_and_its_ports_follow() -> void:
	## §15.7 (« rotations discrètes ») et §15.3 (« dépendre de
	## l'orientation des ports »). Les bras visibles et les ports logiques
	## sont au MÊME endroit : ce que le joueur voit est ce qui est calculé.
	await _erase_save()
	var room: Room3Relays = await _open_room()
	var relay: ElectricRelay = room.relays()[0]
	var before: int = relay.step_index()
	check(relay.is_in_group("interactable"), "la colonne est interactable")
	check(relay.interact(room.player()), "l'interaction lance la rotation")
	check(relay.is_turning(), "…la rotation dure (elle n'est pas instantanée)")
	check(not relay.interact(room.player()),
		"…et une deuxième demande pendant la rotation est refusée")
	for i: int in range(120):
		await _tree().physics_frame
		if not relay.is_turning():
			break
	check_equal(relay.step_index(), (before + 1) % 4,
		"un quart de tour exactement")
	var node: ElectricNode = relay.node()
	var ports: Array[Dictionary] = node.world_ports()
	check_equal(ports.size(), 2, "deux ports")
	var arm0: Node3D = relay.get_node("Pivot/Arm0") as Node3D
	var arm1: Node3D = relay.get_node("Pivot/Arm1") as Node3D
	var port_a: Vector3 = ports[0]["position"] as Vector3
	var port_b: Vector3 = ports[1]["position"] as Vector3
	check(arm0.global_position.distance_to(port_a) < 0.45,
		"le bras 0 est bien SUR son port (%.2f m)"
		% arm0.global_position.distance_to(port_a))
	check(arm1.global_position.distance_to(port_b) < 0.45,
		"le bras 1 est bien SUR son port (%.2f m)"
		% arm1.global_position.distance_to(port_b))
	await _close(room)


func test_turning_every_column_right_opens_the_door() -> void:
	## Le parcours du joueur : il tourne les colonnes une à une, par le
	## VRAI chemin d'interaction, jusqu'à ce que la ligne se referme.
	await _erase_save()
	var room: Room3Relays = await _open_room()
	var solution: Array[int] = [2, 0, 1, 3]
	var turns: int = 0
	for i: int in range(room.relays().size()):
		var relay: ElectricRelay = room.relays()[i]
		for guard: int in range(8):
			if relay.step_index() == solution[i]:
				break
			check(relay.interact(room.player()), "rotation acceptée")
			turns += 1
			for tick: int in range(120):
				await _tree().physics_frame
				if not relay.is_turning():
					break
	check(turns > 0, "%d quarts de tour ont été nécessaires" % turns)
	await _settle(4)
	check(room.receiver().is_powered(), "le circuit est refermé")
	check(room.is_solved(), "la salle se sait résolue")
	var opened: bool = false
	for i: int in range(300):
		await _tree().physics_frame
		if room.door().is_open():
			opened = true
			break
	check(opened, "la porte s'ouvre")
	await _close(room)


func test_a_wrong_configuration_costs_nothing_but_a_quarter_turn() -> void:
	## §15.7 : « aucune erreur ne tue immédiatement ». Cette salle ne
	## contient aucun danger : se tromper ne coûte que du temps.
	await _erase_save()
	var room: Room3Relays = await _open_room()
	var player: PlayerController = room.player()
	var health: float = player.health().current()
	var hazards: Array[Node] = room.find_children("*", "ElectricHazard",
		true, false)
	check(hazards.is_empty(), "aucun danger dans la salle des relais")
	for relay: ElectricRelay in room.relays():
		relay.interact(player)
	await _settle(60)
	check_equal(player.health().current(), health,
		"quatre erreurs plus tard, le joueur est intact")
	check(not room.receiver().is_powered(),
		"…et le circuit est simplement resté ouvert")
	await _close(room)


func test_the_reset_restores_the_initial_configuration() -> void:
	## §15.7 : « bouton reset remet la configuration initiale ».
	await _erase_save()
	var room: Room3Relays = await _open_room()
	var start: Array[int] = []
	for relay: ElectricRelay in room.relays():
		start.append(relay.step_index())
	for relay: ElectricRelay in room.relays():
		relay.set_step_index(relay.step_index() + 1)
	await _settle(2)
	check(room.reset_button().interact(room.player()), "le bouton répond")
	await _settle(4)
	var after: Array[int] = []
	for relay: ElectricRelay in room.relays():
		after.append(relay.step_index())
	check_equal(str(after), str(start),
		"les quatre colonnes ont retrouvé leur départ")
	await _close(room)


func test_the_solved_room_reopens_solved() -> void:
	## §15.11 : état sauvegardé, y compris l'orientation des colonnes.
	await _erase_save()
	var room: Room3Relays = await _open_room()
	room.capture_state_solved()
	await _settle(6)
	check(room.receiver().is_powered(), "circuit refermé")
	for i: int in range(300):
		await _tree().physics_frame
		if room.door().is_open():
			break
	check(room.save_room_state(), "état écrit")
	var steps: Array[int] = []
	for relay: ElectricRelay in room.relays():
		steps.append(relay.step_index())
	await _close(room)

	var reloaded: Room3Relays = await _open_room()
	var restored: Array[int] = []
	for relay: ElectricRelay in reloaded.relays():
		restored.append(relay.step_index())
	check_equal(str(restored), str(steps),
		"les colonnes ont retrouvé leur orientation")
	check(reloaded.receiver().is_powered(), "…le circuit est toujours fermé")
	check(reloaded.door().is_open(), "…et la porte est ouverte d'emblée")
	await _close(reloaded)
	await _erase_save()


func test_the_ids_are_unique_and_the_exit_exists() -> void:
	await _erase_save()
	var room: Room3Relays = await _open_room()
	var problems: Array[String] = room.graph().validate_ids()
	check(problems.is_empty(), "aucun ID vide ni dupliqué : %s" % str(problems))
	var doors: Array[Node] = room.find_children("*", "SceneDoor", true, false)
	check_equal(doors.size(), 1, "une porte de retour")
	if not doors.is_empty():
		check_equal(String((doors[0] as SceneDoor).target_scene),
			"res://scenes/dungeon/rooms/Room2Vertical.tscn",
			"…qui pointe sur la salle 2")
	await _close(room)
