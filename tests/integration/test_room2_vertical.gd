## Salle 2 du donjon — circuit vertical (MASTER_SPEC §15.6, §9.1-§9.3,
## §13.5, §15.11).
##
## Le test central fait GRIMPER le joueur : il pousse vers la paroi,
## s'élève, se hisse sur la corniche. Aucune téléportation sur le trajet
## prouvé, aucun transform écrit pendant la montée.
extends GateTestCase

const ROOM: String = "res://scenes/dungeon/rooms/Room2Vertical.tscn"
## Vitesse d'escalade de §9.2 (1,9-2,2 m/s) : sert à vérifier que la
## fenêtre calme d'une électrode suffit à franchir sa zone.
const CLIMB_SPEED: float = 1.9


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open_room() -> Room2Vertical:
	var room: Room2Vertical = (load(ROOM) as PackedScene).instantiate() \
		as Room2Vertical
	_tree().root.add_child(room)
	await _settle(8)
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


## Pousse le joueur dans une direction MONDE, en projetant dans le repère
## de la caméra comme le ferait une main sur le stick (§8.2).
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


func test_the_shaft_starts_with_live_electrodes_and_a_dead_elevator() -> void:
	## §15.6 : « ascenseur non alimenté » au départ, et le courant part
	## dans la branche DANGER — c'est ce qui donne son énigme à la salle.
	await _erase_save()
	var room: Room2Vertical = await _open_room()
	check(room.source().is_powered(), "la source débite")
	check_equal(room.hazards().size(), 3, "trois électrodes")
	for hazard: ElectricHazard in room.hazards():
		check(hazard.node().is_powered(),
			"%s est sous tension au départ" % hazard.name)
	check(not room.receiver().is_powered(),
		"le récepteur de l'ascenseur est MORT : l'aiguillage le coupe")
	check(not room.elevator().is_running(), "l'ascenseur ne bouge pas")
	check(not room.door().is_latched(), "la porte du haut est fermée")
	check(not room.reroute_switch().is_flipped(), "le levier est au repos")
	await _close(room)


func test_the_electrodes_beat_with_an_observable_rhythm() -> void:
	## §15.6 : « électrodes intermittentes avec rythme observable ». On
	## MESURE la décharge et le calme, et on vérifie que la fenêtre calme
	## suffit à franchir la zone à la vitesse d'escalade de §9.2.
	await _erase_save()
	var room: Room2Vertical = await _open_room()
	var hazard: ElectricHazard = room.hazards()[0]
	var step: float = 1.0 / float(Engine.physics_ticks_per_second)
	# Se caler sur un VRAI front montant : d'abord attendre la fin de la
	# décharge en cours, sinon on mesure un cycle tronqué.
	for i: int in range(400):
		if not hazard.is_discharging():
			break
		await _tree().physics_frame
	for i: int in range(400):
		if hazard.is_discharging():
			break
		await _tree().physics_frame
	check(hazard.is_discharging(), "la décharge démarre")
	var on_seen: float = 0.0
	for i: int in range(400):
		if not hazard.is_discharging():
			break
		on_seen += step
		await _tree().physics_frame
	var off_seen: float = 0.0
	for i: int in range(400):
		if hazard.is_discharging():
			break
		off_seen += step
		await _tree().physics_frame
	check(absf(on_seen - hazard.on_time) < 0.1,
		"décharge mesurée %.2f s pour %.2f s annoncées" % [on_seen,
		hazard.on_time])
	check(absf(off_seen - hazard.off_time) < 0.1,
		"calme mesuré %.2f s pour %.2f s annoncées" % [off_seen,
		hazard.off_time])
	var crossing: float = hazard.area_size.y / CLIMB_SPEED
	check(off_seen > crossing,
		"la fenêtre calme (%.2f s) dépasse la traversée (%.2f s à %.1f m/s)"
		% [off_seen, crossing, CLIMB_SPEED])
	var phases: Array[float] = []
	for other: ElectricHazard in room.hazards():
		phases.append(other.phase_offset)
	check(phases[0] != phases[1] and phases[1] != phases[2],
		"les trois électrodes ne battent pas ensemble : %s" % str(phases))
	await _close(room)


func test_a_live_electrode_refuses_the_grip_and_shocks_the_player() -> void:
	## Deux effets, pas un : la paroi sous tension n'est plus accrochable
	## (§9.2, groupe `electrified`) ET la décharge blesse (§15.6).
	await _erase_save()
	var room: Room2Vertical = await _open_room()
	var player: PlayerController = room.player()
	var hazard: ElectricHazard = room.hazards()[0]
	var block: StaticBody3D = room.get_node("ClimbBlockA") as StaticBody3D
	var climbing: ClimbingComponent = player.find_children("*",
		"ClimbingComponent", true, false)[0] as ClimbingComponent
	# Le joueur se place dans la zone de l'électrode A.
	player.global_position = Vector3(-6.2, 2.6, 3.6)
	var health: float = player.health().current()
	var shocked: bool = false
	var refused_while_live: bool = false
	for i: int in range(400):
		await _tree().physics_frame
		if hazard.is_discharging():
			if not climbing.is_surface_climbable(block):
				refused_while_live = true
			if player.health().current() < health:
				shocked = true
		if shocked and refused_while_live:
			break
	check(refused_while_live,
		"sous tension, le bloc n'est plus accrochable (§9.2)")
	check(shocked, "…et la décharge blesse (%.1f → %.1f PV)"
		% [health, player.health().current()])
	# Une fois le cycle passé, la prise redevient possible : le rythme est
	# une porte, pas un mur.
	var reopened: bool = false
	for i: int in range(400):
		await _tree().physics_frame
		if not hazard.is_discharging() and climbing.is_surface_climbable(block):
			reopened = true
			break
	check(reopened, "au repos, la voie se rouvre")
	await _close(room)


func test_electric_resistance_softens_the_shock() -> void:
	## §13.5 : « Résistance électrique : -60 % de dégâts électriques ».
	## Premier usage réel du plat de baies — sans ce test, le buff resterait
	## une ligne de tableau.
	await _erase_save()
	var room: Room2Vertical = await _open_room()
	var player: PlayerController = room.player()
	var hazard: ElectricHazard = room.hazards()[0]
	var status: StatusEffectComponent = player.status()
	check_not_null(status, "le joueur porte un StatusEffectComponent")
	player.global_position = Vector3(-6.2, 2.6, 3.6)
	var bare: float = await _measure_shock(room, hazard, player)
	check(bare > 0.0, "sans buff, la décharge coûte %.1f PV" % bare)
	player.health().revive()
	status.apply_buff(&"elec_resist", 1.0, 120.0)
	await _settle(2)
	var buffed: float = await _measure_shock(room, hazard, player)
	check(buffed < bare * 0.75,
		"avec la résistance, elle ne coûte plus que %.1f PV (contre %.1f)"
		% [buffed, bare])
	await _close(room)


func _measure_shock(room: Room2Vertical, hazard: ElectricHazard,
		player: PlayerController) -> float:
	var before: float = player.health().current()
	for i: int in range(600):
		await _tree().physics_frame
		if player.health().current() < before:
			break
	return before - player.health().current()


func test_the_upper_switch_reroutes_the_current() -> void:
	## §15.6 : « interrupteur supérieur redirige le courant ». Un seul
	## geste : la branche danger MEURT, la branche ascenseur VIT.
	await _erase_save()
	var room: Room2Vertical = await _open_room()
	var lever: ElectricSwitch = room.reroute_switch()
	check(lever.is_in_group("interactable"), "le levier est un interactable")
	check(lever.interact(room.player()), "l'interaction est acceptée")
	await _settle(6)
	for hazard: ElectricHazard in room.hazards():
		check(not hazard.node().is_powered(),
			"%s est coupée" % hazard.name)
		check(not hazard.is_discharging(), "…et ne décharge plus")
	check(room.receiver().is_powered(), "le récepteur de l'ascenseur s'allume")
	check(room.elevator().is_running(), "l'ascenseur se met en route")
	check(room.is_rerouted(), "la salle sait que le courant est redirigé")
	var opened: bool = false
	for i: int in range(300):
		await _tree().physics_frame
		if room.door().is_open():
			opened = true
			break
	check(opened, "la porte du haut s'ouvre")
	await _close(room)


func test_the_reroute_cannot_be_undone() -> void:
	## Anti-softlock (§15.11) : rebasculer réarmerait les électrodes sous
	## les pieds d'un joueur déjà en haut. Le levier ne revient pas.
	await _erase_save()
	var room: Room2Vertical = await _open_room()
	var lever: ElectricSwitch = room.reroute_switch()
	check(lever.interact(room.player()), "premier basculement accepté")
	await _settle(4)
	check(not lever.interact(room.player()), "le second est REFUSÉ")
	check(lever.is_flipped(), "le levier reste en position")
	check(room.receiver().is_powered(), "…et le courant reste sur l'ascenseur")
	await _close(room)


func test_the_elevator_stops_rather_than_crushing_the_player() -> void:
	## §15.6 : « l'ascenseur ne peut écraser ou coincer le joueur ». On
	## raccourcit la course (paramètre exporté) pour observer la descente
	## sans attendre neuf secondes : la garde ne dépend pas de la hauteur.
	await _erase_save()
	var room: Room2Vertical = await _open_room()
	var lift: ElevatorPlatform = room.elevator()
	lift.top_y = 4.0
	check(room.reroute_switch().interact(room.player()), "courant redirigé")
	await _settle(4)
	# Laisser la plateforme monter puis redescendre.
	var reached_top: bool = false
	for i: int in range(600):
		await _tree().physics_frame
		if lift.position.y >= 3.99:
			reached_top = true
			break
	check(reached_top, "la plateforme monte jusqu'en haut de sa course")
	# Le joueur se met SOUS elle, sur le sol.
	var player: PlayerController = room.player()
	player.global_position = Vector3(1.0, 0.2, 1.0)
	var lowest: float = lift.position.y
	for i: int in range(900):
		await _tree().physics_frame
		lowest = minf(lowest, lift.position.y)
		if lift.is_blocked():
			break
	check(lift.is_blocked(), "la plateforme s'arrête sur le corps détecté")
	check(lowest > player.global_position.y + 1.0,
		"…bien au-dessus du joueur (%.2f m contre %.2f m)"
		% [lowest, player.global_position.y])
	check(not player.health().is_dead(), "le joueur est vivant")
	await _close(room)


func test_the_elevator_carries_the_player_upward() -> void:
	## Une plateforme qui ne porte personne n'est pas un ascenseur : le
	## joueur posé dessus doit MONTER avec elle (§14.1, sync_to_physics).
	await _erase_save()
	var room: Room2Vertical = await _open_room()
	var lift: ElevatorPlatform = room.elevator()
	var player: PlayerController = room.player()
	check(room.reroute_switch().interact(room.player()), "courant redirigé")
	await _settle(4)
	player.global_position = Vector3(1.0, 1.3, 1.0)
	var start: float = player.global_position.y
	for i: int in range(600):
		await _tree().physics_frame
		if player.global_position.y > start + 3.0:
			break
	check(player.global_position.y > start + 3.0,
		"le joueur s'est élevé de %.2f m avec la plateforme"
		% (player.global_position.y - start))
	check(absf(player.global_position.y - lift.position.y) < 1.6,
		"…en restant posé dessus")
	await _close(room)


func test_the_player_really_climbs_the_shaft() -> void:
	## LE test de la salle : le joueur pousse vers la paroi et MONTE. Sans
	## téléportation ; seule la mise en place initiale place le corps au
	## pied du premier bloc.
	await _erase_save()
	var room: Room2Vertical = await _open_room()
	var player: PlayerController = room.player()
	# Courant redirigé : ce test isole « la voie est-elle grimpable »,
	# le danger a son propre test.
	check(room.reroute_switch().interact(player), "courant redirigé")
	await _settle(4)
	player.global_position = Vector3(-6.2, 0.3, 4.2)
	await _settle(20)
	var intent: InputIntent = InputIntent.new()
	player.set_intent_source(intent)
	var start_y: float = player.global_position.y
	await _drive(player, intent, Vector3(0, 0, -1), 240)
	intent.move = Vector2.ZERO
	var climbed: float = player.global_position.y - start_y
	check(climbed > 5.0, "le joueur a gravi %.2f m" % climbed)
	check(player.global_position.y > 5.4,
		"…il a dépassé le toit du premier bloc (y = %.2f)"
		% player.global_position.y)
	await _close(room)


func test_a_fall_lands_on_the_ledge_below() -> void:
	## §15.6 : « chute renvoie à un palier proche ». Les blocs étant
	## décalés, lâcher la paroi du troisième segment fait tomber sur le
	## toit du deuxième — 2 à 3 m, sous le seuil de dégâts de §8.2.
	await _erase_save()
	var room: Room2Vertical = await _open_room()
	var player: PlayerController = room.player()
	check(room.reroute_switch().interact(player), "courant redirigé")
	await _settle(4)
	var health_before: float = player.health().current()
	player.global_position = Vector3(-5.2, 13.5, -2.4)
	var landed: bool = false
	for i: int in range(300):
		await _tree().physics_frame
		if player.is_on_floor():
			landed = true
			break
	check(landed, "le joueur retombe sur quelque chose")
	check(player.global_position.y > 10.5,
		"…sur le palier du dessous, à %.2f m (pas 13 m plus bas)"
		% player.global_position.y)
	check_equal(player.health().current(), health_before,
		"…sans dégâts de chute")
	await _close(room)


func test_the_rerouted_room_reopens_rerouted() -> void:
	## §15.11 : « état sauvegardé ». L'aiguillage vit dans le graphe : au
	## rechargement, les électrodes restent mortes et la porte ouverte.
	await _erase_save()
	var room: Room2Vertical = await _open_room()
	check(room.reroute_switch().interact(room.player()), "courant redirigé")
	await _settle(6)
	for i: int in range(300):
		await _tree().physics_frame
		if room.door().is_open():
			break
	check(room.save_room_state(), "état écrit dans le slot commun")
	await _close(room)

	var reloaded: Room2Vertical = await _open_room()
	check(reloaded.is_rerouted(), "la salle rechargée se sait redirigée")
	check(reloaded.reroute_switch().is_flipped(),
		"…le levier est resté basculé")
	check(reloaded.receiver().is_powered(), "…l'ascenseur est vivant")
	for hazard: ElectricHazard in reloaded.hazards():
		check(not hazard.node().is_powered(),
			"…%s est restée morte" % hazard.name)
	check(reloaded.door().is_open(), "…et la porte est ouverte d'emblée")
	await _close(reloaded)
	await _erase_save()


func test_the_ids_are_unique_and_the_exit_exists() -> void:
	## §19.3 et §15.11 : identifiants stables, chemin retour réel.
	await _erase_save()
	var room: Room2Vertical = await _open_room()
	var problems: Array[String] = room.graph().validate_ids()
	check(problems.is_empty(), "aucun ID vide ni dupliqué : %s" % str(problems))
	check(room.graph().node_count() >= 50,
		"le circuit compte %d nœuds réels" % room.graph().node_count())
	var doors: Array[Node] = room.find_children("*", "SceneDoor", true, false)
	check(not doors.is_empty(), "des seuils de sortie existent")
	# F.6 : la salle est une branche du hall — on y entre et on en ressort
	# par la salle centrale, et le puzzle ouvre un second passage vers elle.
	check_equal(doors.size(), 2, "…deux seuils vers la salle centrale")
	for door: Node in doors:
		check_equal(String((door as SceneDoor).target_scene),
			"res://scenes/dungeon/rooms/CentralHall.tscn",
			"…qui pointe sur la salle centrale")
	check(room.get_node("WallWest").is_in_group("unclimbable"),
		"le mur ouest est inaccrochable : la voie passe par les blocs")
	await _close(room)
