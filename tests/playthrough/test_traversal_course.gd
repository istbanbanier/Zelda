## Parcours de traversal enchaîné — critère de sortie du Gate B (§22).
##
## §22 exige « parcours test complet sans blocage ni caméra cassée ». Les autres
## suites vérifient chaque capacité **isolément** ; celle-ci vérifie qu'elles
## s'enchaînent, ce qu'aucun test unitaire ne peut dire. Un franchissement qui
## laisse le personnage dans un état incohérent — accroche au sol non rétablie,
## mode figé, endurance bloquée — ne se manifeste qu'au segment suivant.
##
## Le pilote est **scripté et sans triche** : il tient « avant » et saute au bord
## du vide. Il ne téléporte rien, ne force aucun état, n'appelle aucune méthode de
## debug. C'est la contrainte de §0.8 sur la démo, appliquée ici.
extends GateTestCase

const COURSE: String = "res://scenes/tests/TraversalCourse.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"

## Budget de temps du parcours. Large : on cherche un blocage, pas un record.
const MAX_TICKS: int = 60 * 40

## Altitudes des segments, telles que définies dans `TraversalCourse.tscn`.
const Y_GROUND: float = 0.0
const Y_STEP: float = 0.32
const Y_PLATEAU: float = 2.837
const Y_TOWER: float = 6.837

## Bord du vide, et abscisse à partir de laquelle le pilote saute.
const GAP_START_X: float = 22.0
const JUMP_TRIGGER_X: float = 21.2

var _world: Node = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	_intent = null


func test_the_full_traversal_course_is_completed_without_a_softlock() -> void:
	var tree: SceneTree = _tree()
	if tree == null:
		check(false, "SceneTree indisponible")
		return
	var course_scene: PackedScene = load(COURSE) as PackedScene
	var player_scene: PackedScene = load(PLAYER) as PackedScene
	if course_scene == null or player_scene == null:
		check(false, "scènes du parcours introuvables")
		return

	_world = course_scene.instantiate()
	tree.root.add_child(_world)
	_player = player_scene.instantiate() as PlayerController
	_world.add_child(_player)
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)

	var stepped: Array[int] = [0]
	var grabbed: Array[int] = [0]
	var mantled: Array[int] = [0]
	_player.stepped_up.connect(func(_h: float) -> void: stepped[0] += 1)
	_player.grabbed_wall.connect(func(_n: Vector3) -> void: grabbed[0] += 1)
	_player.mantle_finished.connect(func() -> void: mantled[0] += 1)

	for i: int in range(30):
		await tree.physics_frame

	# Jalons franchis, dans l'ordre. Un parcours qui atteint la fin sans les avoir
	# tous vus aurait emprunté un raccourci que la géométrie n'autorise pas.
	var reached_step: bool = false
	var reached_ramp_top: bool = false
	var crossed_gap: bool = false
	var reached_tower_top: bool = false
	var fell: bool = false

	var camera: Camera3D = (_player.get_node("CameraRig") as CameraRig).get_camera()
	var camera_clipped: int = 0
	var camera_probe: SphereShape3D = SphereShape3D.new()
	camera_probe.radius = 0.12

	# Le parcours n'est pas achevé quand l'altitude du sommet est atteinte — elle
	# l'est **pendant** le franchissement — mais quand le joueur s'y tient, rendu à
	# la locomotion. Confondre les deux ferait conclure au succès une image avant la
	# fin, et laisserait passer un état final incohérent.
	var completed: bool = false
	var ticks: int = 0
	while ticks < MAX_TICKS and not completed:
		ticks += 1
		var x: float = _player.global_position.x
		var y: float = _player.global_position.y

		# --- Pilote : avancer, et sauter au bord du vide -----------------------
		_intent.move = Vector2(0.0, 0.0)
		if _player.is_climbing():
			_intent.move = Vector2(0.0, 1.0)   # sur paroi, « avant » signifie monter
		else:
			_intent.move = Vector2(1.0, 0.0)   # +X, la caméra est au repos
		if not _player.is_climbing() and not _player.is_mantling() \
				and x >= JUMP_TRIGGER_X and x < GAP_START_X and _player.is_on_floor():
			_intent.jump_pressed = true

		await tree.physics_frame

		# --- Relevé -------------------------------------------------------------
		x = _player.global_position.x
		y = _player.global_position.y
		if x > 11.0 and y > Y_STEP - 0.1:
			reached_step = true
		if x > 18.0 and y > Y_PLATEAU - 0.15:
			reached_ramp_top = true
		if x > 24.5 and y > Y_PLATEAU - 0.15:
			crossed_gap = true
		if y > Y_TOWER - 0.2 and x > 30.0:
			reached_tower_top = true
		completed = reached_tower_top and _player.is_on_floor() \
			and not _player.is_climbing() and not _player.is_mantling()
		# Tomber dans le vide est un échec observable grâce au filet : sans lui, la
		# chute serait infinie et se lirait comme « toujours en mouvement ».
		if y < -1.0:
			fell = true
			break

		# --- Caméra : ne traverse-t-elle jamais la géométrie ? (§23.1) ----------
		# Une sphère au point de vue, à chaque tick du parcours. C'est la mesure la
		# plus directe de « la caméra ne traverse pas les murs » : non pas que le
		# bras se raccourcisse, mais que l'œil ne soit jamais dans la roche.
		var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		query.shape = camera_probe
		query.transform = Transform3D(Basis.IDENTITY, camera.global_position)
		query.collision_mask = 1
		query.exclude = [_player.get_rid()]
		if not _player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			camera_clipped += 1

	check(not fell,
		"le joueur ne doit pas tomber dans le vide (y = %.2f à x = %.2f)"
		% [_player.global_position.y, _player.global_position.x])
	check(reached_step, "segment 1 : la marche de 0,32 m doit être franchie")
	check(reached_ramp_top, "segment 2 : le haut de la rampe à 40° doit être atteint")
	check(crossed_gap, "segment 3 : le vide doit être franchi d'un saut")
	check(reached_tower_top,
		"segment 4 : le sommet de la tour doit être atteint (x = %.2f, y = %.2f)"
		% [_player.global_position.x, _player.global_position.y])
	check(ticks < MAX_TICKS,
		"le parcours doit s'achever dans le budget (%d ticks écoulés)" % ticks)

	# Chaque capacité a réellement servi : sans ces compteurs, un parcours réussi
	# par un chemin imprévu passerait pour une validation du traversal.
	check(stepped[0] >= 1, "le franchissement de marche doit avoir servi")
	check(grabbed[0] >= 1, "l'escalade doit avoir servi")
	check(mantled[0] >= 1, "le franchissement de rebord doit avoir servi")

	check_equal(camera_clipped, 0,
		"images où la caméra était dans la géométrie (§23.1 : aucune traversée)")

	# État final cohérent : le personnage rend la main prêt à rejouer.
	check(not _player.is_climbing(), "le joueur ne doit pas rester accroché")
	check(not _player.is_mantling(), "le joueur ne doit pas rester en franchissement")
	check_approx(_player.floor_snap_length, _player.tuning.floor_snap_length, 0.001,
		"accroche au sol rétablie à l'arrivée")
	_teardown()
