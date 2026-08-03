## Salle centrale et antichambre (MASTER_SPEC §15.9, §15.10, §19.5).
##
## Le point dur de §15.9 est l'INDÉPENDANCE des trois circuits : un
## premier circuit résolu ne doit rien allumer d'autre que son propre
## anneau. C'est ce que teste `test_one_circuit_lights_only_its_own_ring`,
## et c'est exactement le défaut qu'une porte à nœud commun aurait créé.
extends GateTestCase

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
	await _settle(2)


func _erase_save() -> void:
	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	if save_system == null:
		return
	var path: String = String(save_system.call("slot_path", "slot0"))
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


## Écrit une sauvegarde où les salles listées sont résolues.
func _write_solved_rooms(rooms: Array[String]) -> void:
	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	var dungeon: Dictionary = {}
	for room_id: String in rooms:
		dungeon[room_id] = {"solved": true}
	save_system.call("save_slot", "slot0", {
		"schema": 2, "checkpoint": "test", "dungeon": dungeon,
	})


func test_the_hall_starts_with_three_dead_circuits() -> void:
	## §15.9 : trois récepteurs INDÉPENDANTS. Aucun n'est allumé tant
	## qu'aucune salle n'est résolue, et la porte du boss compte bien
	## trois conditions.
	await _erase_save()
	var hall: CentralHall = await _open(HALL) as CentralHall
	check_equal(hall.receivers().size(), 3, "trois récepteurs")
	check_equal(hall.powered_circuits(), 0, "aucun circuit alimenté")
	check_equal(hall.boss_door().required_count(), 3,
		"la porte du boss a trois conditions")
	check(not hall.boss_door().is_latched(), "…et elle est fermée")
	for receiver: ElectricNode in hall.receivers():
		var ring: ReceiverRing = receiver.get_node("Ring") as ReceiverRing
		check_equal(ring.lit_segments(), 0,
			"l'anneau de %s est ouvert" % receiver.name)
	await _close(hall)


func test_one_circuit_lights_only_its_own_ring() -> void:
	## LE test de §15.9. Les trois branches sont électriquement séparées :
	## résoudre la salle 3 n'allume QUE l'anneau nord. Si les branches
	## partageaient un nœud (la porte, par exemple), le courant remonterait
	## et les trois anneaux se fermeraient d'un coup.
	await _erase_save()
	await _write_solved_rooms(["dungeon.room.relays.03"])
	var hall: CentralHall = await _open(HALL) as CentralHall
	check_equal(hall.powered_circuits(), 1, "un seul circuit alimenté")
	var west: ElectricNode = hall.get_node("ReceiverWest") as ElectricNode
	var north: ElectricNode = hall.get_node("ReceiverNorth") as ElectricNode
	var east: ElectricNode = hall.get_node("ReceiverEast") as ElectricNode
	check(north.is_powered(), "le récepteur NORD s'allume (salle 3)")
	check(not west.is_powered(), "…l'ouest reste éteint")
	check(not east.is_powered(), "…l'est aussi")
	check(not hall.boss_door().is_latched(),
		"…et la porte du boss ne bouge pas")
	check_equal(hall.boss_door().satisfied_conditions(), 1,
		"une condition sur trois")
	await _close(hall)
	await _erase_save()


func test_each_circuit_comes_from_its_documented_room() -> void:
	## §15.9 exige de documenter « quelle salle fournit quel récepteur ».
	## Le tableau de l'en-tête de `central_hall.gd` est ici VÉRIFIÉ, salle
	## par salle, sur le vrai chemin (la sauvegarde commune).
	var mapping: Array[Array] = [
		["dungeon.room.vertical.02", "ReceiverWest"],
		["dungeon.room.relays.03", "ReceiverNorth"],
		["dungeon.room.battery.04", "ReceiverEast"],
	]
	for entry: Array in mapping:
		await _erase_save()
		await _write_solved_rooms([String(entry[0])])
		var hall: CentralHall = await _open(HALL) as CentralHall
		var lit: ElectricNode = hall.get_node(String(entry[1])) as ElectricNode
		check(lit.is_powered(), "%s alimente %s" % [entry[0], entry[1]])
		check_equal(hall.powered_circuits(), 1, "…et lui seul")
		await _close(hall)
	await _erase_save()


func test_the_boss_door_opens_only_on_the_third_circuit() -> void:
	## §15.9 : « trois récepteurs alimentent la porte SIMULTANÉMENT ».
	await _erase_save()
	await _write_solved_rooms(["dungeon.room.vertical.02",
		"dungeon.room.relays.03"])
	var hall: CentralHall = await _open(HALL) as CentralHall
	check_equal(hall.powered_circuits(), 2, "deux circuits sur trois")
	check(not hall.boss_door().is_latched(),
		"la porte reste fermée à deux circuits")
	# Le troisième circuit tombe : le mécanisme part.
	hall.capture_state_all_circuits()
	await _settle(6)
	check_equal(hall.powered_circuits(), 3, "trois circuits")
	check(hall.boss_door().is_latched(), "la porte s'engage")
	var opened: bool = false
	for i: int in range(600):
		await _tree().physics_frame
		if hall.boss_door().is_open():
			opened = true
			break
	check(opened, "…et elle s'ouvre pour de bon")
	await _close(hall)
	await _erase_save()


func test_the_hall_is_a_real_hub_on_two_levels() -> void:
	## L'architecture multi-niveaux : quatre salles au sol, la porte du
	## boss six mètres plus haut, et deux rampes PRATICABLES (§8.2 : une
	## pente jusqu'à 46° se monte en marchant).
	await _erase_save()
	var hall: CentralHall = await _open(HALL) as CentralHall
	var doors: Array[Node] = hall.find_children("*", "SceneDoor", true, false)
	check_equal(doors.size(), 5,
		"cinq seuils : quatre salles et l'antichambre")
	var targets: Array[String] = []
	for door: Node in doors:
		targets.append(String((door as SceneDoor).target_scene))
	for expected: String in [CentralHall.ROOM1, CentralHall.ROOM2,
			CentralHall.ROOM3, CentralHall.ROOM4, CentralHall.ANTECHAMBER]:
		check(targets.has(expected), "un seuil mène à %s" % expected)
	var gallery: Node3D = hall.get_node("Gallery") as Node3D
	check_approx(gallery.global_position.y, CentralHall.GALLERY_Y - 0.25, 0.01,
		"la galerie est à six mètres")
	for side: String in ["RampW", "RampE"]:
		var ramp: Node3D = hall.get_node(side) as Node3D
		var slope: float = rad_to_deg(absf(ramp.rotation.x))
		check(slope < 46.0,
			"%s monte à %.1f° — praticable à pied (§8.2)" % [side, slope])
	await _close(hall)


func test_the_player_walks_up_the_ramp_to_the_boss_door() -> void:
	## La preuve qui compte : le joueur MONTE. Sans téléportation, il part
	## du sol, prend la rampe et arrive sur la galerie.
	await _erase_save()
	var hall: CentralHall = await _open(HALL) as CentralHall
	var player: PlayerController = hall.player()
	player.global_position = Vector3(12.5, 0.4, 0.0)
	await _settle(20)
	var intent: InputIntent = InputIntent.new()
	player.set_intent_source(intent)
	var start_y: float = player.global_position.y
	for i: int in range(600):
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
		if player.global_position.y > CentralHall.GALLERY_Y - 0.5:
			break
	intent.move = Vector2.ZERO
	check(player.global_position.y > start_y + 4.0,
		"le joueur est monté de %.2f m en marchant"
		% (player.global_position.y - start_y))
	await _close(hall)


func test_the_wall_map_has_one_line_per_circuit() -> void:
	## §15.9 : « carte murale et lignes continues », pas un compteur.
	await _erase_save()
	await _write_solved_rooms(["dungeon.room.battery.04"])
	var hall: CentralHall = await _open(HALL) as CentralHall
	var lines: Array[Node] = hall.find_children("MapLine*", "MeshInstance3D",
		true, false)
	check_equal(lines.size(), 3, "trois lignes sur la carte")
	# La ligne du circuit EST est branchée sur SON récepteur : elle
	# s'allume, les deux autres non.
	var visuals: Array[Node] = hall.find_children("MapVisual*",
		"ElectricVisual", true, false)
	check_equal(visuals.size(), 3, "chaque ligne a sa présentation")
	var lit: int = 0
	for i: int in range(240):
		await _tree().process_frame
		lit = 0
		for visual: Node in visuals:
			if (visual as ElectricVisual).fill_ratio() > 0.9:
				lit += 1
		if lit >= 1:
			break
	check_equal(lit, 1, "une seule ligne allumée pour un seul circuit")
	await _close(hall)
	await _erase_save()


func test_the_antechamber_holds_everything_15_10_asks_for() -> void:
	## §15.10, item par item.
	await _erase_save()
	var ante: Antechamber = await _open(ANTE) as Antechamber
	check(ante.checkpoint_written(), "le checkpoint est ÉCRIT en entrant")
	check_not_null(ante.chest(), "coffre garanti")
	check_equal(String(ante.chest().weapon_loot.id), "conductive_blade",
		"…qui contient une arme conductrice")
	check(ante.chest().arrows_loot >= 10, "…et des flèches")
	check_not_null(ante.campfire(), "station de cuisine")
	check_equal(ante.berries().size(), 4, "quatre baies électriques")
	for berry: IngredientPickup in ante.berries():
		check_equal(String(berry.definition.id), "storm_berry",
			"…de la bonne famille (résistance électrique, §13.5)")
	# Deux seuils depuis G.1 : le RETOUR vers la salle centrale (§15.10 :
	# « possibilité de revenir ») et l'entrée dans l'arène. On les nomme
	# tous les deux plutôt que d'en compter un — un compte se casse au
	# prochain ajout sans rien dire de ce qui manque.
	var doors: Array[Node] = ante.find_children("*", "SceneDoor", true, false)
	var targets: Array[String] = []
	for door: Node in doors:
		targets.append((door as SceneDoor).target_scene)
	check(targets.has(HALL), "un seuil de RETOUR vers la salle centrale")
	check(targets.has("res://scenes/boss/BossArena.tscn"),
		"…et le seuil qui mène à l'arène du boss")
	check_equal(doors.size(), 2, "et rien d'autre : deux seuils, pas plus")
	check_equal(String((doors[0] as SceneDoor).target_scene), Antechamber.HALL,
		"…qui pointe vraiment sur elle")
	check(not ante.find_children("ArenaPylon*", "StaticBody3D", true, false)
		.is_empty(), "l'arène s'aperçoit derrière la baie (quatre pylônes)")
	await _close(ante)
	await _erase_save()


func test_the_fresco_teaches_wood_against_metal() -> void:
	## §15.10 : « fresque montrant bois isolant / métal conducteur ». Ce
	## n'est pas une image : ce sont deux vraies lignes du graphe, et
	## seule celle du métal arrive au bout (§14.4).
	await _erase_save()
	var ante: Antechamber = await _open(ANTE) as Antechamber
	var metal: ElectricNode = ante.get_node("FrescoMetalEnd") as ElectricNode
	var wood: ElectricNode = ante.get_node("FrescoWoodEnd") as ElectricNode
	var bar: ElectricNode = ante.get_node("FrescoWoodBar") as ElectricNode
	check(metal.is_powered(), "la voie du MÉTAL arrive au bout")
	check(not wood.is_powered(), "la voie du BOIS s'arrête au barreau")
	check_approx(bar.conductivity, 0.0, 0.001,
		"…parce que le bois ne conduit pas (§14.4)")
	check(bar.is_in_group("insulated"), "…et qu'il est marqué isolant")
	await _close(ante)
	await _erase_save()


func test_the_antechamber_chest_arms_the_player_for_the_boss() -> void:
	## §16.7 : le coffre de l'antichambre fait partie du butin GARANTI
	## avant le boss. Ouvert par le vrai chemin, il remplit l'inventaire.
	await _erase_save()
	var ante: Antechamber = await _open(ANTE) as Antechamber
	var player: PlayerController = ante.player()
	var before: int = player.inventory().weapons().size()
	var arrows: int = player.inventory().arrows()
	check(ante.chest().interact(player), "le coffre s'ouvre")
	await _settle(4)
	check_equal(player.inventory().weapons().size(), before + 1,
		"une arme de plus")
	check(player.inventory().arrows() > arrows,
		"…et des flèches en plus (%d → %d)"
		% [arrows, player.inventory().arrows()])
	check(not ante.chest().interact(player),
		"…et il ne se re-ouvre pas (§11.4 : jamais de second loot)")
	await _close(ante)
	await _erase_save()
