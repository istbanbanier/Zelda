## Arc et flèches (MASTER_SPEC §10.4, §11.1).
##
## Le contrat de §10.4, pièce par pièce : la visée tire là où la caméra regarde,
## la flèche tombe (« gravité modérée »), elle s'arrête au premier contact — mur
## comme chair —, le tir près d'un mur n'atteint jamais ce qui est derrière, et
## le pool n'instancie rien en rafale (§20.6). L'enveloppe épingle les nombres
## de §10.4 (vitesse 42–58) et §11.1 (arc simple, 9).
##
## Géométrie : la caméra regarde vers -Z (lacet 0), légèrement plongeante
## (tangage -0,15 rad) — les cibles de tir vivent à -Z, à moins de 6 m pour que
## la ligne descendante reste dans la capsule de hurtbox (0–1,7 m).
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
	_world.add_child(floor_body)
	floor_body.global_position = Vector3(0, -0.5, 0)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_world.add_child(_player)
	_player.global_position = Vector3(0, 0.1, 0)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	await _settle(2)
	for i: int in range(120):
		if _player.is_on_floor():
			break
		await _tree().physics_frame
	check(_player.is_on_floor(), "préalable de setup : joueur atterri")


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


func _dummy_at(position: Vector3) -> CombatDummy:
	var dummy: CombatDummy = (load(DUMMY) as PackedScene).instantiate() as CombatDummy
	_world.add_child(dummy)
	dummy.global_position = position
	return dummy


func _wall_at(position: Vector3, size: Vector3) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	cs.shape = box
	wall.add_child(cs)
	_world.add_child(wall)
	wall.global_position = position


func _bow() -> BowComponent:
	return _player.get_node("Components/BowComponent") as BowComponent


func test_an_aimed_shot_wounds_a_dummy_at_distance() -> void:
	## §10.4 + §11.1 : visée tenue, tir, 9 de dégâts là où la caméra regarde —
	## bien au-delà de toute portée de mêlée (§11.1 : 1,6–2,7 m).
	await _setup()
	var dummy: CombatDummy = _dummy_at(Vector3(0, 0, -4.0))
	await _settle(3)

	_intent.aim_held = true
	_intent.shoot_pressed = true
	await _settle(15)   # 4 m à 48 m/s : 5 ticks — marge comprise

	check_approx(dummy.health().current(), 45.0 - 9.0, 0.001,
		"l'arc simple fait 9 (§11.1) à distance")
	_teardown()


func test_shooting_requires_the_aim_to_be_held() -> void:
	## §8.5 : « viser/tirer » — le tir est un geste de visée, pas un bouton libre.
	## Sans visée, l'appui ne part pas.
	await _setup()
	var dummy: CombatDummy = _dummy_at(Vector3(0, 0, -4.0))
	await _settle(3)

	_intent.shoot_pressed = true   # aim_held reste faux
	await _settle(15)

	check_approx(dummy.health().current(), 45.0, 0.001,
		"aucune flèche ne part sans visée")
	check_equal(_bow().active_arrows().size(), 0, "aucune flèche en vol")
	_teardown()


func test_the_arrow_falls_under_gravity() -> void:
	## §10.4 « gravité modérée » : tirée À PLAT, la flèche tombe — vitesse
	## verticale négative croissante et position sous l'origine. Composant nu :
	## la balistique se mesure sans caméra.
	await _setup()
	var bow: BowComponent = BowComponent.new()
	bow.tuning = load("res://resources/combat/bow_default.tres") as BowTuning
	_world.add_child(bow)
	var exclude: Array[RID] = []
	check(bow.try_fire(Vector3(0, 2.0, 0), Vector3(0, 0, -1), &"player", _player, exclude),
		"le tir horizontal part")
	var arrow: ArrowProjectile = bow.active_arrows()[0]

	await _settle(20)   # 1/3 s de vol

	check(arrow.velocity().y < -3.5,
		"la vitesse verticale s'accumule (vy = %.2f, attendu ≈ -4)" % arrow.velocity().y)
	check(arrow.global_position.y < 1.7,
		"la flèche est tombée sous son origine (y = %.2f < 2,0)" % arrow.global_position.y)
	check(arrow.global_position.z < -12.0,
		"la portée horizontale est conservée (z = %.1f)" % arrow.global_position.z)
	_teardown()


func test_a_shot_against_a_wall_never_reaches_what_is_behind() -> void:
	## §10.4 : « raycast proche anti-tir à travers mur ». Le balayage part de la
	## POITRINE — un mur à 80 cm arrête la flèche, le mannequin derrière ne sent
	## rien. C'est la géométrie que le contrôle Z3 (origine avancée de 1,5 m)
	## doit faire échouer.
	await _setup()
	_wall_at(Vector3(0, 1.5, -0.8), Vector3(4, 3, 0.2))
	var dummy: CombatDummy = _dummy_at(Vector3(0, 0, -4.0))
	await _settle(3)

	_intent.aim_held = true
	_intent.shoot_pressed = true
	await _settle(15)

	check_approx(dummy.health().current(), 45.0, 0.001,
		"le mannequin derrière le mur est intact")
	check_equal(_bow().active_arrows().size(), 0,
		"la flèche s'est arrêtée au mur (désactivée)")
	_teardown()


func test_the_arrow_stops_at_its_first_victim() -> void:
	## §10.1 par construction : la flèche meurt au premier contact. Deux mannequins
	## alignés — le premier prend 9, le second rien.
	await _setup()
	var front: CombatDummy = _dummy_at(Vector3(0, 0, -3.5))
	var back: CombatDummy = _dummy_at(Vector3(0, 0, -5.5))
	await _settle(3)

	_intent.aim_held = true
	_intent.shoot_pressed = true
	await _settle(15)

	check_approx(front.health().current(), 45.0 - 9.0, 0.001,
		"la première victime prend 9")
	check_approx(back.health().current(), 45.0, 0.001,
		"la flèche ne traverse jamais sa première victime")
	_teardown()


func test_the_pool_never_grows_past_its_size() -> void:
	## §20.6 : « pools pour flèches » — jamais d'instanciation en rafale. Réglage
	## de mécanisme (pool 3, cadence nulle) : le 4e tir est refusé, le pool reste
	## à 3. La cadence, elle, refuse un second tir immédiat au réglage livré.
	await _setup()
	var mechanism: BowTuning = BowTuning.new()
	mechanism.pool_size = 3
	mechanism.shot_cooldown = 0.0
	mechanism.lifetime = 60.0
	var bow: BowComponent = BowComponent.new()
	bow.tuning = mechanism
	_world.add_child(bow)
	await _settle(1)
	var exclude: Array[RID] = []
	for i: int in range(3):
		check(bow.try_fire(Vector3(0, 30, 0), Vector3(0, 0, -1), &"player", _player, exclude),
			"tir %d accepté dans la taille du pool" % (i + 1))
	check(not bow.try_fire(Vector3(0, 30, 0), Vector3(0, 0, -1), &"player", _player, exclude),
		"le 4e tir est refusé, pas instancié")
	check_equal(bow.pool_count(), 3, "le pool n'a jamais dépassé sa taille")

	var paced: BowComponent = BowComponent.new()
	paced.tuning = load("res://resources/combat/bow_default.tres") as BowTuning
	_world.add_child(paced)
	await _settle(1)
	check(paced.try_fire(Vector3(0, 30, 0), Vector3(0, 0, -1), &"player", _player, exclude),
		"premier tir cadencé accepté")
	check(not paced.try_fire(Vector3(0, 30, 0), Vector3(0, 0, -1), &"player", _player, exclude),
		"le second tir immédiat est refusé par la cadence")
	_teardown()


func test_bow_tuning_matches_the_spec() -> void:
	## Enveloppe : §10.4 vitesse 42–58 m/s, gravité modérée (< 24, la gravité du
	## monde) ; §11.1 arc simple à 9. Une mutation du .tres livré doit rougir ici.
	var tuning: BowTuning = load("res://resources/combat/bow_default.tres") as BowTuning
	check_not_null(tuning, "bow_default.tres")
	if tuning == null:
		return
	check(tuning.arrow_speed >= 42.0 and tuning.arrow_speed <= 58.0,
		"vitesse hors §10.4 : %.1f" % tuning.arrow_speed)
	check_approx(tuning.base_damage, 9.0, 0.001, "arc simple : 9 (§11.1)")
	check(tuning.arrow_gravity > 0.0 and tuning.arrow_gravity < 24.0,
		"gravité modérée : %.1f (monde : 24)" % tuning.arrow_gravity)
	check(tuning.pool_size >= 1, "pool utilisable")
	check(tuning.shot_cooldown > 0.0, "cadence non nulle")
	check(tuning.lifetime > 0.0, "durée de vie non nulle")
