## Escalade (§9.2) et franchissement (§9.3) — mesurés dans le bac à sable réel.
##
## Le bac à sable aligne quatre parois en `z = -30`, chacune isolant **un** cas :
## paroi de 4 m dégagée, paroi identique marquée `unclimbable`, rebord bas, rebord
## bas surmonté d'un plafond. Une paroi unique « générique » ne permettrait pas de
## distinguer « surface interdite » de « sonde dans le vide » quand un test rougit.
##
## Comme partout en Phase B, le contrôleur est piloté par `InputIntent` injectée :
## aucune touche simulée (D-013).
extends GateTestCase

const SANDBOX: String = "res://scenes/tests/TraversalSandbox.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"
const TICK: float = 1.0 / 60.0

## Abscisses des parois du bac à sable, toutes en z = -30.
const X_CLIMB_WALL: float = -5.0
const X_UNCLIMBABLE: float = -25.0
const X_LOW_LEDGE: float = 12.0
const X_CAPPED_LEDGE: float = 28.0
const X_OVERHANG: float = -15.0
## Face avant des parois (elles occupent z de -30,5 à -29,5).
const WALL_FACE_Z: float = -29.5

var _world: Node = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _setup(spawn: Vector3) -> bool:
	var tree: SceneTree = _tree()
	if tree == null:
		check(false, "SceneTree indisponible")
		return false
	var world_scene: PackedScene = load(SANDBOX) as PackedScene
	var player_scene: PackedScene = load(PLAYER) as PackedScene
	if world_scene == null or player_scene == null:
		check(false, "scènes de test introuvables")
		return false

	_world = world_scene.instantiate()
	tree.root.add_child(_world)
	_player = player_scene.instantiate() as PlayerController
	_world.add_child(_player)
	_player.global_position = spawn
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	await _settle(30)
	return true


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	_intent = null


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


## Pousse vers `-Z` — la face avant des parois — jusqu'à l'accroche ou l'échéance.
## Retourne le nombre de ticks écoulés, `-1` si l'accroche n'a pas eu lieu.
func _push_into_wall(max_ticks: int) -> int:
	_intent.move = Vector2(0.0, 1.0)
	for i: int in range(max_ticks):
		await _tree().physics_frame
		if _player.is_climbing():
			return i + 1
	return -1


func test_pushing_into_a_wall_grabs_it() -> void:
	## §9.2 ne fixe aucune touche d'escalade : pousser vers une paroi saisissable
	## suffit (D-017).
	if not await _setup(Vector3(X_CLIMB_WALL, 1.0, -28.0)):
		return
	var normals: Array[Vector3] = []
	_player.grabbed_wall.connect(func(n: Vector3) -> void: normals.append(n))

	var ticks: int = await _push_into_wall(120)
	check(ticks > 0, "pousser vers la paroi doit accrocher")
	check(_player.is_climbing(), "le mode doit être CLIMBING")
	check_equal(normals.size(), 1, "nombre d'accroches signalées")
	if normals.size() == 1:
		# La paroi fait face à +Z : sa normale doit pointer vers le joueur.
		check(normals[0].z > 0.9,
			"la normale retenue doit être celle de la face avant : %v" % normals[0])
	_teardown()


func test_an_unclimbable_surface_is_refused() -> void:
	## §9.2 : le groupe `unclimbable` interdit l'accroche. Géométrie identique à la
	## paroi précédente — seul le groupe change, donc seul le groupe peut expliquer
	## la différence de résultat.
	if not await _setup(Vector3(X_UNCLIMBABLE, 1.0, -28.0)):
		return
	var ticks: int = await _push_into_wall(180)
	check(ticks < 0, "une paroi `unclimbable` ne doit jamais être saisie")
	check(not _player.is_climbing(), "le mode doit rester LOCOMOTION")
	# Contrôle de cohérence : le joueur a bien atteint la paroi, il ne s'est pas
	# arrêté trois mètres avant — sans quoi le refus ne prouverait rien.
	check(_player.global_position.z < -28.5,
		"le joueur doit avoir atteint la paroi (z = %.2f)" % _player.global_position.z)
	_teardown()


func test_a_shallow_slope_is_never_grabbed() -> void:
	## §8.2 fait gravir une pente à 40° en marchant ; l'escalader en plus serait un
	## doublon incohérent.
	##
	## Constat mesuré, noté parce qu'il n'est pas intuitif : le refus n'est pas
	## `too_shallow` mais `no_wall`. Un rayon horizontal parti de la hauteur du
	## torse ne rencontre une pente d'angle θ qu'à la distance 1,10 / tan θ ; sous
	## environ 57°, cette distance dépasse la portée d'accroche de 0,70 m et la
	## sonde passe simplement au-dessus. Le filtre d'angle sert donc aux parois
	## irrégulières rencontrées **en cours d'escalade**, pas à l'approche au sol —
	## c'est ce que vérifie le test suivant.
	if not await _setup(Vector3(-20.0, 1.5, 3.3)):
		return
	var climbing: ClimbingComponent = _player.get_node("Components/ClimbingComponent")
	check_not_null(climbing, "ClimbingComponent")
	if climbing == null:
		_teardown()
		return
	var space: PhysicsDirectSpaceState3D = _player.get_world_3d().direct_space_state
	var probe: ClimbingComponent.WallProbe = climbing.probe_wall(
		space, _player.global_position, Vector3(0, 0, -1), [_player.get_rid()])
	check(not probe.grabbable,
		"une pente à 40° ne doit pas être saisissable (refus : %s)" % probe.refusal)
	_teardown()


func test_an_overhang_is_refused() -> void:
	## §9.2 : « refuser vides/concavités ». Des pieds dans le vide sous un torse en
	## contact décrivent un surplomb ; s'y accrocher ferait pendre le personnage
	## sans appui.
	##
	## Cette branche n'était couverte par aucun test avant que le contrôle négatif
	## P2 ne le montre — en retirant l'exigence de contact aux pieds sans faire
	## rougir quoi que ce soit. La paroi flottante du bac à sable existe pour ça.
	if not await _setup(Vector3(X_OVERHANG, 1.0, -28.0)):
		return
	var climbing: ClimbingComponent = _player.get_node("Components/ClimbingComponent")
	if climbing == null:
		check(false, "ClimbingComponent")
		_teardown()
		return

	var ticks: int = await _push_into_wall(120)
	check(ticks < 0, "un surplomb ne doit jamais être saisi")

	var space: PhysicsDirectSpaceState3D = _player.get_world_3d().direct_space_state
	var probe: ClimbingComponent.WallProbe = climbing.probe_wall(
		space, _player.global_position, Vector3(0, 0, -1), [_player.get_rid()])
	check(probe.chest_hit, "préalable : le torse doit toucher la paroi flottante")
	check(not probe.foot_hit, "préalable : les pieds doivent être dans le vide")
	check(not probe.grabbable, "un surplomb ne doit pas être saisissable")
	check_equal(probe.refusal, &"overhang", "raison du refus")
	_teardown()


func test_the_angle_filter_rejects_a_surface_below_the_threshold() -> void:
	## Le filtre d'angle vérifié là où il agit réellement : la pente à 60° du bac à
	## sable, assez raide pour se présenter devant le torse. Avec le réglage réel
	## (46°) elle est saisissable ; avec un seuil porté à 70°, la même sonde au même
	## endroit doit la refuser pour `too_shallow`. Deux mesures, une seule variable.
	if not await _setup(Vector3(0.0, 1.0, 0.0)):
		return
	var climbing: ClimbingComponent = _player.get_node("Components/ClimbingComponent")
	if climbing == null:
		check(false, "ClimbingComponent")
		_teardown()
		return
	# L'origine de sonde est un paramètre : inutile que le joueur se tienne là — il
	# glisserait d'ailleurs sur une pente à 60°. La pente raide du bac à sable est
	# en x = -30, son pied en z = 3.
	var space: PhysicsDirectSpaceState3D = _player.get_world_3d().direct_space_state
	var origin: Vector3 = Vector3(-30.0, 0.0, 2.9)
	var forward: Vector3 = Vector3(0, 0, -1)

	var accepted: ClimbingComponent.WallProbe = climbing.probe_wall(
		space, origin, forward, [_player.get_rid()])
	check(accepted.grabbable,
		"une pente à 60° doit être saisissable au seuil réel (refus : %s)"
		% accepted.refusal)

	var raised: ClimbTuning = climbing.tuning.duplicate()
	raised.min_wall_angle_deg = 70.0
	climbing.tuning = raised
	var refused: ClimbingComponent.WallProbe = climbing.probe_wall(
		space, origin, forward, [_player.get_rid()])
	check(not refused.grabbable, "un seuil à 70° doit refuser une pente à 60°")
	check_equal(refused.refusal, &"too_shallow", "raison du refus")
	_teardown()


func test_no_angle_is_both_unwalkable_and_unclimbable() -> void:
	## Invariant entre deux ressources qui s'ignorent. Si le seuil de paroi passait
	## au-dessus de l'angle de sol praticable, il resterait une bande d'angles où le
	## joueur glisse sans pouvoir s'accrocher — un piège que rien ne signalerait.
	## C'était le cas au premier jet de B.3 : paroi ≥ 50°, sol ≤ 46°, quatre degrés
	## de vide.
	var climb: ClimbTuning = load("res://resources/tuning/climb_default.tres")
	var locomotion: LocomotionTuning = load("res://resources/tuning/locomotion_default.tres")
	check_not_null(climb, "climb_default.tres")
	check_not_null(locomotion, "locomotion_default.tres")
	if climb == null or locomotion == null:
		return
	check(climb.min_wall_angle_deg <= locomotion.max_floor_angle_deg,
		"seuil de paroi (%.1f°) au-dessus de l'angle de sol praticable (%.1f°) : "
		% [climb.min_wall_angle_deg, locomotion.max_floor_angle_deg]
		+ "une bande d'angles deviendrait infranchissable")


func test_climbing_rises_at_the_declared_speed() -> void:
	## §9.2 : 2,0 m/s vers le haut.
	if not await _setup(Vector3(X_CLIMB_WALL, 1.0, -28.0)):
		return
	check(await _push_into_wall(120) > 0, "préalable : accroche")
	var start_y: float = _player.global_position.y
	_intent.move = Vector2(0.0, 1.0)
	await _settle(60)
	var climbed: float = _player.global_position.y - start_y
	var tuning: ClimbTuning = load("res://resources/tuning/climb_default.tres")
	check_approx(climbed, tuning.climb_speed_up, 0.4,
		"hauteur gagnée en 1 s d'escalade")
	_teardown()


func test_climbing_drains_stamina() -> void:
	## §9.1 : 18/s en escalade — le coût était déclaré depuis B.2, il est enfin
	## consommé.
	if not await _setup(Vector3(X_CLIMB_WALL, 1.0, -28.0)):
		return
	check(await _push_into_wall(120) > 0, "préalable : accroche")
	var stamina: StaminaComponent = _player.stamina()
	var before: float = stamina.current()
	_intent.move = Vector2(0.0, 1.0)
	await _settle(60)
	var spent: float = before - stamina.current()
	check_approx(spent, stamina.tuning.climb_drain, 2.0,
		"endurance consommée par 1 s d'escalade")
	check(stamina.tuning.climb_drain > stamina.tuning.sprint_drain,
		"préalable de lecture : grimper coûte plus cher que sprinter (§9.1)")
	_teardown()


func test_exhaustion_releases_the_wall() -> void:
	## §9.1 : « à zéro : lâcher du mur ». Le comportement observable est la chute.
	if not await _setup(Vector3(X_CLIMB_WALL, 1.0, -28.0)):
		return
	check(await _push_into_wall(120) > 0, "préalable : accroche")
	var reasons: Array[StringName] = []
	_player.released_wall.connect(func(r: StringName) -> void: reasons.append(r))

	# Réserve amorcée basse : vider 100 à 18/s prendrait 5,5 s et ferait franchir
	# le haut de la paroi, ce qui mesurerait un mantle et non un épuisement.
	_player.stamina().set_current(4.0)
	_intent.move = Vector2(0.0, 1.0)
	await _settle(60)

	check(not _player.is_climbing(), "épuisé, le joueur doit avoir lâché la paroi")
	check(reasons.size() >= 1, "un lâcher doit être signalé")
	if reasons.size() >= 1:
		check_equal(reasons[0], &"exhausted", "raison du lâcher")
	_teardown()


func test_climb_jump_costs_stamina_and_pushes_off() -> void:
	## §9.2 : saut d'escalade de 0,75–1,0 m ; §9.1 : 20 d'endurance.
	if not await _setup(Vector3(X_CLIMB_WALL, 1.0, -28.0)):
		return
	check(await _push_into_wall(120) > 0, "préalable : accroche")
	var stamina: StaminaComponent = _player.stamina()
	var before: float = stamina.current()

	_intent.move = Vector2.ZERO
	_intent.jump_pressed = true
	await _settle(2)

	check(not _player.is_climbing(), "le saut d'escalade doit détacher de la paroi")
	check_approx(before - stamina.current(), stamina.tuning.climb_jump_cost, 0.5,
		"endurance consommée par le saut d'escalade")
	check(_player.velocity.y > 3.0,
		"le saut doit projeter vers le haut (vy = %.2f)" % _player.velocity.y)
	check(_player.velocity.z > 0.1,
		"le saut doit écarter de la paroi (vz = %.2f)" % _player.velocity.z)
	_teardown()


func test_reaching_a_ledge_mantles_onto_it() -> void:
	## §9.3, le cas nominal : rebord bas de 1,20 m, dessus dégagé.
	if not await _setup(Vector3(X_LOW_LEDGE, 1.0, -28.0)):
		return
	var started: Array[Vector3] = []
	var finished: Array[int] = [0]
	_player.mantle_started.connect(func(t: Vector3) -> void: started.append(t))
	_player.mantle_finished.connect(func() -> void: finished[0] += 1)

	# On relâche dès la fin du franchissement. Maintenir la poussée trois secondes
	# de plus ferait traverser le rebord — profond d'un mètre — puis quarante
	# mètres de sol, et la mesure porterait sur une chute hors du bac à sable.
	_intent.move = Vector2(0.0, 1.0)
	for i: int in range(240):
		await _tree().physics_frame
		if finished[0] >= 1:
			break
	_intent.move = Vector2.ZERO
	await _settle(20)

	check(finished[0] >= 1, "le franchissement doit s'achever")
	check(started.size() >= 1, "le franchissement doit avoir été annoncé")
	check(not _player.is_mantling(), "le mode doit être revenu à LOCOMOTION")
	check_approx(_player.global_position.y, 1.2, 0.15,
		"le joueur doit se tenir sur le dessus du rebord")
	check(_player.global_position.z < WALL_FACE_Z,
		"le joueur doit avoir franchi le rebord (z = %.2f)" % _player.global_position.z)
	check(_player.is_on_floor(), "le joueur doit reposer sur le dessus, pas flotter")
	_teardown()


func test_climbing_a_tall_wall_ends_in_a_mantle() -> void:
	## Le parcours complet de B.3, en un seul geste : accroche, quatre mètres
	## d'ascension, franchissement du sommet. Les tests précédents isolent chaque
	## étape ; celui-ci vérifie qu'elles s'enchaînent — c'est la question à laquelle
	## un test unitaire ne répond jamais.
	if not await _setup(Vector3(X_CLIMB_WALL, 1.0, -28.0)):
		return
	var finished: Array[int] = [0]
	var released: Array[StringName] = []
	_player.mantle_finished.connect(func() -> void: finished[0] += 1)
	_player.released_wall.connect(func(r: StringName) -> void: released.append(r))

	_intent.move = Vector2(0.0, 1.0)
	for i: int in range(600):
		await _tree().physics_frame
		if finished[0] >= 1:
			break
	_intent.move = Vector2.ZERO
	await _settle(20)

	check(finished[0] >= 1,
		"l'ascension doit se conclure par un franchissement (lâchers : %s)" % [released])
	check_approx(_player.global_position.y, 4.0, 0.2,
		"le joueur doit se tenir sur le sommet de la paroi de 4 m")
	check(_player.is_on_floor(), "le joueur doit reposer sur le sommet")
	# L'endurance a été consommée par l'ascension : sans cela, l'escalade serait
	# gratuite et §9.1 ne serait pas tenu sur le chemin le plus exigeant.
	check(_player.stamina().current() < _player.stamina().maximum(),
		"l'ascension doit avoir coûté de l'endurance (%.1f)" % _player.stamina().current())
	_teardown()


func test_a_ledge_under_a_ceiling_refuses_the_mantle() -> void:
	## §21.4 : « tenter mantle sous plafond ». Le dessus est marchable, mais la
	## capsule n'y tient pas : §9.3 exige d'annuler proprement plutôt que de
	## franchir dans la géométrie.
	if not await _setup(Vector3(X_CAPPED_LEDGE, 1.0, -28.0)):
		return
	var refusals: Array[StringName] = []
	_player.mantle_refused.connect(func(r: StringName) -> void: refusals.append(r))
	var finished: Array[int] = [0]
	_player.mantle_finished.connect(func() -> void: finished[0] += 1)

	_intent.move = Vector2(0.0, 1.0)
	await _settle(180)

	check(refusals.size() >= 1, "le franchissement doit être refusé explicitement")
	if refusals.size() >= 1:
		check_equal(refusals[0], &"blocked", "raison du refus")
	check_equal(finished[0], 0, "aucun franchissement ne doit s'achever")
	# Anti-softlock : le joueur ne doit pas finir encastré dans le plafond
	# (qui occupe y de 2,4 à 2,8).
	check(_player.global_position.y < 2.4,
		"le joueur ne doit pas se retrouver dans le plafond (y = %.2f)"
		% _player.global_position.y)
	_teardown()


func test_the_body_never_rotates_while_climbing() -> void:
	## Même invariant qu'en locomotion : le corps porte le `CameraRig`. S'il
	## s'orientait sur la paroi, la caméra basculerait avec lui.
	if not await _setup(Vector3(X_CLIMB_WALL, 1.0, -28.0)):
		return
	check(await _push_into_wall(120) > 0, "préalable : accroche")
	_intent.move = Vector2(0.3, 1.0)
	await _settle(30)
	check_approx(_player.rotation.y, 0.0, 0.001, "lacet du corps pendant l'escalade")
	check_approx(_player.rotation.x, 0.0, 0.001, "tangage du corps pendant l'escalade")
	_teardown()


func test_releasing_the_wall_restores_ground_settings() -> void:
	## L'accroche au sol est coupée pendant l'escalade, sinon `floor_snap_length`
	## rabattrait le personnage vers le sol dès qu'il décolle. Elle doit être
	## rétablie au lâcher : sans cela le joueur redescendrait au sol sans accroche,
	## et décollerait sur chaque bosse pour le reste de la partie.
	if not await _setup(Vector3(X_CLIMB_WALL, 1.0, -28.0)):
		return
	var tuning: LocomotionTuning = _player.tuning
	check(await _push_into_wall(120) > 0, "préalable : accroche")
	check_approx(_player.floor_snap_length, 0.0, 0.001,
		"accroche au sol coupée pendant l'escalade")

	_intent.move = Vector2.ZERO
	_intent.jump_pressed = true
	await _settle(5)
	check_approx(_player.floor_snap_length, tuning.floor_snap_length, 0.001,
		"accroche au sol rétablie après le lâcher")
	_teardown()
