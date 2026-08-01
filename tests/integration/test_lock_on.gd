## Verrouillage de cible (MASTER_SPEC §8.4) — acquisition, suivi, libérations.
##
## « Jamais à travers mur » est testé avec un vrai mur ; la convergence caméra est
## mesurée en angle ; chaque libération (mort, distance, mur) a son cas.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const DUMMY: String = "res://scenes/tests/CombatDummy.tscn"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _setup() -> void:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = Vector3(0, 0.1, 0)
	_world.add_child(_player)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	await _settle(2)
	for i: int in range(120):
		if _player.is_on_floor():
			break
		await _tree().physics_frame
	check(_player.is_on_floor(), "préalable de setup : joueur atterri")


func _dummy_at(position: Vector3) -> CombatDummy:
	var dummy: CombatDummy = (load(DUMMY) as PackedScene).instantiate() as CombatDummy
	dummy.position = position
	_world.add_child(dummy)
	return dummy


func _wall_at(position: Vector3, size: Vector3) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	cs.shape = box
	wall.add_child(cs)
	wall.position = position
	_world.add_child(wall)


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


func test_lock_acquires_the_target_in_front() -> void:
	## La caméra au repos regarde -Z (elle est derrière le joueur) : la cible
	## devant la caméra est verrouillable, celle dans le dos ne l'est pas.
	await _setup()
	var front: CombatDummy = _dummy_at(Vector3(0, 0, -8))
	var _behind: CombatDummy = _dummy_at(Vector3(0, 0, 12))
	await _settle(3)

	_intent.lock_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), front, "la cible dans le cône caméra est retenue")
	_teardown()


func test_lock_never_acquires_through_a_wall() -> void:
	## §8.4 : « jamais à travers mur ». Même position, même cône — seul le mur
	## sépare les deux cas.
	await _setup()
	var _hidden: CombatDummy = _dummy_at(Vector3(0, 0, -8))
	_wall_at(Vector3(0, 1.5, -4), Vector3(6, 3, 0.4))
	await _settle(3)

	_intent.lock_pressed = true
	await _settle(2)
	check(_player.lock_target() == null, "aucune cible à travers un mur")
	_teardown()


func test_camera_converges_toward_the_locked_target() -> void:
	## §8.4 : conserver la cible dans le cadre. La cible est posée sur le côté ;
	## une fois verrouillée — après rotation manuelle de la caméra vers elle pour
	## l'acquisition — on déplace la CIBLE et le lacet doit suivre sans entrée.
	await _setup()
	var dummy: CombatDummy = _dummy_at(Vector3(0, 0, -8))
	await _settle(3)
	_intent.lock_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), dummy, "préalable : cible verrouillée")

	var rig: CameraRig = _player.get_node("CameraRig") as CameraRig
	dummy.global_position = Vector3(6, 0, -6)
	await _settle(45)
	# La cible est en (6, -6) : lacet attendu atan2(-6, 6) ≈ -0,785 rad.
	var expected: float = atan2(-6.0, 6.0)
	check_approx(rig.get_yaw(), expected, 0.15,
		"le lacet converge vers la cible déplacée sans aucune entrée de regard")
	_teardown()


func test_lock_releases_when_the_target_dies() -> void:
	await _setup()
	var dummy: CombatDummy = _dummy_at(Vector3(0, 0, -8))
	await _settle(3)
	_intent.lock_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), dummy, "préalable : verrouillé")

	var kill: DamageEvent = DamageEvent.new()
	kill.amount = 999.0
	dummy.health().take_damage(kill)
	await _settle(2)
	check(_player.lock_target() == null, "la mort de la cible libère le verrou")
	_teardown()


func test_lock_releases_beyond_range_and_toggles_off() -> void:
	await _setup()
	var dummy: CombatDummy = _dummy_at(Vector3(0, 0, -8))
	await _settle(3)
	_intent.lock_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), dummy, "préalable : verrouillé")

	dummy.global_position = Vector3(0, 0, -35)   # au-delà des 26 m de libération
	await _settle(3)
	check(_player.lock_target() == null, "la distance libère le verrou")

	# Bascule volontaire : verrouiller puis re-presser décroche.
	dummy.global_position = Vector3(0, 0, -8)
	await _settle(3)
	_intent.lock_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), dummy, "re-verrouillé")
	_intent.lock_pressed = true
	await _settle(2)
	check(_player.lock_target() == null, "l'appui décroche")
	_teardown()


func test_locked_player_faces_the_target_while_strafing() -> void:
	## §8.4 : strafe — le personnage fait face à la menace pendant qu'il se
	## déplace latéralement.
	await _setup()
	var dummy: CombatDummy = _dummy_at(Vector3(0, 0, -8))
	await _settle(3)
	_intent.lock_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), dummy, "préalable : verrouillé")

	_intent.move = Vector2(1.0, 0.0)
	await _settle(30)
	var visual: Node3D = _player.get_node("VisualRoot") as Node3D
	# La cible est vers -Z : lacet visuel attendu ≈ atan2(0, -8) = π (face à -Z).
	var facing: Vector3 = visual.global_transform.basis.z
	check(facing.z < -0.8,
		"le personnage doit faire face à la cible en strafe (face z = %.2f)" % facing.z)
	check(_player.horizontal_speed() > 3.0, "tout en se déplaçant")
	_teardown()


func test_lock_ranges_match_the_spec() -> void:
	## §8.4 : acquisition 18–24 m. La libération doit être plus large que
	## l'acquisition, sinon la cible clignote à la frontière.
	var player_scene: PackedScene = load(PLAYER)
	var player: PlayerController = player_scene.instantiate() as PlayerController
	var lock: LockOnComponent = player.get_node("Components/LockOnComponent")
	check(lock.acquire_range >= 18.0 and lock.acquire_range <= 24.0,
		"portée d'acquisition hors §8.4 (18–24 m) : %.1f" % lock.acquire_range)
	check(lock.release_range > lock.acquire_range,
		"la libération doit dépasser l'acquisition (hystérésis)")
	player.free()


func test_target_switch_steps_sideways_and_never_wraps() -> void:
	## §8.4 : « cible préc./suiv. » directionnel. Trois cibles : gauche, droite,
	## et une troisième derrière un mur — le pas suivant va vers la droite de la
	## caméra, ne boucle jamais au bord (§10.8 : pas de « target switch
	## absurde »), et ne traverse jamais un mur.
	##
	## Géométrie comptée depuis la CAMÉRA (épaule x +0,32, recul z ≈ +4,5) : la
	## gauche à x -1 est mieux alignée que la droite à x +3 ; le mur s'étend
	## jusqu'à x 3 pour couper la ligne caméra → troisième cible (qui croise
	## z = -4 vers x ≈ 4,2), sans masquer la cible de droite (croisement x ≈ 2,1).
	await _setup()
	var left: CombatDummy = _dummy_at(Vector3(-1, 0, -8))
	var right: CombatDummy = _dummy_at(Vector3(3, 0, -8))
	var _walled: CombatDummy = _dummy_at(Vector3(6, 0, -8))
	_wall_at(Vector3(5.5, 1.5, -4), Vector3(5, 3, 0.4))
	await _settle(3)

	_intent.lock_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), left, "acquisition : la cible la plus alignée")

	_intent.target_next_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), right, "suivant : un pas vers la droite caméra")

	_intent.target_next_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), right,
		"au bord : pas de boucle, pas de cible à travers le mur")

	_intent.target_prev_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), left, "précédent : retour vers la gauche")

	_intent.target_prev_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), left, "au bord gauche : pas de boucle non plus")
	_teardown()
