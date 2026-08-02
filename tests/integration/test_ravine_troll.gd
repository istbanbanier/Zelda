## Colosse des ravins (MASTER_SPEC §12.4, D-EN.4) — la QUATRIÈME famille :
## ~420 PV, 3,8 m de haut (capsule r=1,1 : sa taille EST sa navigation —
## une porte étroite le refuse), onde de choc au sol ÉVITABLE par saut,
## lancer de rocher balistique, point faible DORSAL ×2, token lourd.
## Tout mesuré en physique réelle sur la vraie scène.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const TROLL: String = "res://scenes/enemies/RavineTroll.tscn"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _setup(player_at: Vector3, troll_at: Vector3) -> RavineTroll:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(160, 1, 160)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = player_at
	_world.add_child(_player)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	var troll: RavineTroll = (load(TROLL) as PackedScene).instantiate() as RavineTroll
	troll.position = troll_at
	_world.add_child(troll)
	var to_player: Vector3 = player_at - troll_at
	(troll.get_node("Pivot") as Node3D).rotation.y = atan2(to_player.x, to_player.z)
	await _settle(2)
	for i: int in range(120):
		if _player.is_on_floor():
			break
		await _tree().physics_frame
	return troll


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	await _settle(1)


func test_troll_tuning_and_scale_match_the_spec() -> void:
	## §12.4 / §12.6 : ~420 PV, 3,5-4,5 m de haut, vision 35 m / 115°,
	## audition 30 m, poursuite 4,8 m/s, virage LENT, portée 3,2 m.
	var troll: RavineTroll = await _setup(Vector3(0, 0.1, -40), Vector3(0, 0.1, 0))
	check_equal(troll.tuning.max_health, 420.0, "420 PV (§12.4)")
	check_equal(troll.tuning.vision_range, 35.0, "vision 35 m (§12.6)")
	check_equal(troll.tuning.vision_half_angle_deg, 57.5, "cône 115°")
	check_equal(troll.tuning.hearing_range, 30.0, "audition 30 m")
	check_equal(troll.tuning.pursuit_speed, 4.8, "poursuite 4,8 m/s")
	check(troll.tuning.turn_speed < 5.0,
		"virage LENT (%.1f) — la masse ne pivote pas comme un pillard"
		% troll.tuning.turn_speed)
	var capsule: CapsuleShape3D = (troll.get_node("CollisionShape3D")
		as CollisionShape3D).shape as CapsuleShape3D
	check(capsule.height >= 3.5 and capsule.height <= 4.5,
		"hauteur 3,5-4,5 m (%.1f)" % capsule.height)
	check(capsule.radius >= 1.0,
		"corpulence réelle (rayon %.1f m)" % capsule.radius)
	check_equal(troll.health().max_health, 420.0, "la santé réelle suit")
	await _teardown()


func test_the_back_is_a_real_weak_point() -> void:
	## §12.4 / §10.3 : « point faible visible dos ou tête » — la hurtbox
	## dorsale porte ×2, et les deux volumes ne se chevauchent PAS.
	var troll: RavineTroll = await _setup(Vector3(0, 0.1, -40), Vector3(0, 0.1, 0))
	var front: HurtboxComponent = troll.get_node("Pivot/Hurtbox") \
		as HurtboxComponent
	var back: HurtboxComponent = troll.get_node("Pivot/BackHurtbox") \
		as HurtboxComponent
	check_equal(front.weak_point_multiplier, 1.0, "l'avant est ordinaire")
	check_equal(back.weak_point_multiplier, 2.0, "le DOS vaut double (§12.4)")
	check(back.position.z < front.position.z,
		"le volume dorsal est bien derrière (%.2f < %.2f)"
		% [back.position.z, front.position.z])
	var front_box: BoxShape3D = (front.get_node("CollisionShape3D")
		as CollisionShape3D).shape as BoxShape3D
	check(absf(back.position.z - front.position.z) >= front_box.size.z - 0.01,
		"…et les deux volumes ne se chevauchent pas")
	await _teardown()


func test_the_shockwave_spares_a_jumping_player() -> void:
	## §12.4 : « onde de choc au sol évitable par saut » — la MÊME onde,
	## au même rayon : au sol elle touche, en l'air elle épargne.
	var troll: RavineTroll = await _setup(Vector3(0, 0.1, 3.0), Vector3(0, 0.1, 0))
	var health: HealthComponent = _player.health()
	# 1. Au sol : l'anneau passe sur le joueur et frappe.
	var ring: ShockwaveRing = ShockwaveRing.new()
	_world.add_child(ring)
	ring.global_position = Vector3(0, 0.05, 0)
	var grounded_start: float = health.current()
	for i: int in range(90):
		await _tree().physics_frame
		if health.current() < grounded_start:
			break
	check(health.current() < grounded_start,
		"au SOL : l'onde frappe (%.0f -> %.0f)"
		% [grounded_start, health.current()])
	# 2. En l'air : le joueur saute, une nouvelle onde passe — épargné.
	await _settle(30)
	_intent.jump_pressed = true
	await _settle(2)
	_intent.jump_pressed = false
	await _settle(6)
	check(not _player.is_on_floor(), "préalable : le joueur a décollé")
	var airborne_start: float = health.current()
	var ring2: ShockwaveRing = ShockwaveRing.new()
	_world.add_child(ring2)
	ring2.global_position = Vector3(0, 0.05, 0)
	for i: int in range(24):
		await _tree().physics_frame
		if not _player.is_on_floor():
			continue
	check_equal(health.current(), airborne_start,
		"en L'AIR : l'onde passe DESSOUS, aucun dégât")
	check(troll.tuning.max_health > 0.0, "le colosse est resté cohérent")
	await _teardown()


func test_the_troll_winds_up_and_throws_a_rock_at_mid_range() -> void:
	## §12.4 : « peut ramasser/lancer un rocher » — à mi-distance (6-16 m)
	## il ANNONCE (immobile, orienté) puis LANCE un vrai projectile
	## balistique ; le rocher vole réellement.
	var troll: RavineTroll = await _setup(Vector3(0, 0.1, 10.0), Vector3(0, 0.1, 0))
	var rock: ArrowProjectile = troll.get_node("RockProjectile") as ArrowProjectile
	var wound_up: bool = false
	var flew: bool = false
	var launch_position: Vector3 = Vector3.ZERO
	for i: int in range(300):
		await _tree().physics_frame
		if troll.is_winding_throw():
			wound_up = true
		if rock.visible and not flew:
			flew = true
			launch_position = rock.global_position
			break
	check(wound_up, "l'annonce du lancer a eu lieu (immobile, orienté)")
	check(flew, "le rocher est parti")
	await _settle(10)
	check(rock.global_position.distance_to(launch_position) > 1.0,
		"…et il VOLE réellement (%.1f m parcourus)"
		% rock.global_position.distance_to(launch_position))
	await _teardown()


func test_the_troll_cannot_squeeze_through_a_narrow_door() -> void:
	## §12.4 : « aucun passage dans des portes étroites » — la capsule de
	## 2,2 m de large ne franchit PAS une ouverture de 1,6 m ; un pillard
	## (0,76 m) la franchit. La taille EST la navigation.
	var troll: RavineTroll = await _setup(Vector3(0, 0.1, 8.0), Vector3(0, 0.1, 0))
	# Mur percé d'une porte de 1,6 m, entre le colosse et le joueur.
	for side: float in [-1.0, 1.0]:
		var wall: StaticBody3D = StaticBody3D.new()
		wall.collision_layer = 1
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(10.0, 6.0, 0.6)
		shape.shape = box
		wall.add_child(shape)
		wall.position = Vector3(side * 5.8, 3.0, 4.0)
		_world.add_child(wall)
	await _settle(6)
	var start_z: float = troll.global_position.z
	for i: int in range(240):
		await _tree().physics_frame
	check(troll.global_position.z < 4.0,
		"le colosse reste du MAUVAIS côté du mur (z = %.2f)"
		% troll.global_position.z)
	check(troll.global_position.z > start_z - 0.5,
		"…il a bien tenté d'avancer, il est BLOQUÉ par sa carrure")
	await _teardown()
