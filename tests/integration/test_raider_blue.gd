## Pillard azur (MASTER_SPEC §12.2, D-EN.1) — la DEUXIÈME famille réelle :
## stats et arme propres (85 PV, lance longue), contournement mesuré,
## maintien de distance entre deux piques, esquive d'une lourde
## télégraphiée avec cooldown, alerte des alliés par défaut. Tout en
## physique réelle sur la vraie scène.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const BLUE: String = "res://scenes/enemies/RaiderBlue.tscn"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _setup(player_at: Vector3, blue_at: Vector3) -> RaiderBlue:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = player_at
	_world.add_child(_player)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	var blue: RaiderBlue = (load(BLUE) as PackedScene).instantiate() as RaiderBlue
	blue.position = blue_at
	_world.add_child(blue)
	await _settle(2)
	for i: int in range(120):
		if _player.is_on_floor():
			break
		await _tree().physics_frame
	return blue


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	await _settle(1)


func test_blue_tuning_matches_the_spec() -> void:
	## §12.2 / §12.6 : 85 PV, lance, vision 30 m / 105°, audition 20 m,
	## poursuite 5,8 m/s, alerte par défaut — des NOMBRES propres, pas une
	## recoloration du braise.
	var blue: RaiderBlue = await _setup(Vector3(0, 0.1, -40), Vector3(0, 0.1, 0))
	check_equal(blue.tuning.max_health, 85.0, "85 PV (§12.2)")
	check_equal(blue.tuning.vision_range, 30.0, "vision 30 m (§12.6)")
	check_equal(blue.tuning.vision_half_angle_deg, 52.5, "cône 105°")
	check_equal(blue.tuning.hearing_range, 20.0, "audition 20 m")
	check_equal(blue.tuning.pursuit_speed, 5.8, "poursuite 5,8 m/s")
	check(blue.tuning.attack_reach > 2.0,
		"portée de LANCE (%.1f m) — pas celle du gourdin (1,6)"
		% blue.tuning.attack_reach)
	check(blue.tuning.alert_radius > 0.0, "il ALERTE par défaut (§12.2)")
	check_equal(blue.health().max_health, 85.0, "la santé réelle suit")
	await _teardown()


func test_blue_thrusts_from_spear_range_and_telegraphs() -> void:
	## La pique part d'une distance où le gourdin ne toucherait PAS
	## (2,2 m > 1,6 m de portée braise) : l'arme fait la famille.
	var blue: RaiderBlue = await _setup(Vector3(0, 0.1, 2.2), Vector3(0, 0.1, 0))
	var health: HealthComponent = _player.health()
	var start: float = health.current()
	var telegraphed: bool = false
	var struck: bool = false
	for i: int in range(240):
		await _tree().physics_frame
		if blue.state() == RaiderBlue.State.ATTACK:
			telegraphed = true
		if health.current() < start:
			struck = true
			break
	check(telegraphed, "l'attaque est passée par son état (annonce §10.5)")
	check(struck, "la pique TOUCHE à distance de lance")
	await _teardown()


func test_blue_sidesteps_a_telegraphed_heavy_once_per_cooldown() -> void:
	## §12.2 : esquive d'une lourde TRÈS télégraphiée, cooldown 6-10 s —
	## le pas latéral part pendant le startup ; une deuxième lourde
	## immédiate n'est PAS esquivée (cooldown mesuré).
	# Le joueur démarre HORS de vue : l'azur ne doit pas avoir le temps
	# d'attaquer pendant l'attente d'atterrissage du setup.
	var blue: RaiderBlue = await _setup(Vector3(0, 0.1, -40), Vector3(0, 0.1, 0))
	_player.global_position = Vector3(0, 0.1, 3.2)
	await _settle(10)
	check_equal(blue.state(), RaiderBlue.State.CHASE, "préalable : en chasse")
	_intent.heavy_pressed = true
	await _settle(3)
	_intent.heavy_pressed = false
	var stepped: bool = false
	for i: int in range(30):
		await _tree().physics_frame
		if blue.is_sidestepping():
			stepped = true
			break
	check(stepped, "la lourde télégraphiée déclenche le pas latéral")
	check(blue.dodge_cooldown_left() > 5.0,
		"…et arme un cooldown de 6-10 s (%.1f s)" % blue.dodge_cooldown_left())
	# Attendre la fin de la lourde, puis relancer : PAS de deuxième esquive.
	await _settle(150)
	_intent.heavy_pressed = true
	await _settle(3)
	_intent.heavy_pressed = false
	var second_step: bool = false
	for i: int in range(30):
		await _tree().physics_frame
		if blue.is_sidestepping():
			second_step = true
			break
	check(not second_step, "aucun spam : la 2e lourde n'est pas esquivée")
	await _teardown()


func test_blue_reopens_distance_while_its_attack_cools_down() -> void:
	## §12.2 : « alterne maintien de distance et attaque » — après sa
	## pique, pendant le cooldown, il ROUVRE l'écart au lieu de coller.
	var blue: RaiderBlue = await _setup(Vector3(0, 0.1, 2.2), Vector3(0, 0.1, 0))
	# Laisser la première pique partir et se terminer.
	var attacked: bool = false
	for i: int in range(240):
		await _tree().physics_frame
		if blue.state() == RaiderBlue.State.ATTACK:
			attacked = true
		if attacked and blue.state() == RaiderBlue.State.CHASE:
			break
	check(attacked, "préalable : une pique a eu lieu")
	var gap_after_attack: float = blue.global_position.distance_to(
		_player.global_position)
	await _settle(35)
	var gap_later: float = blue.global_position.distance_to(
		_player.global_position)
	check(gap_later > gap_after_attack + 0.3,
		"l'écart se rouvre pendant le cooldown (%.2f -> %.2f m)"
		% [gap_after_attack, gap_later])
	await _teardown()


func test_blue_flanks_instead_of_walking_straight_in() -> void:
	## §12.2 : « contourne le joueur » — à mi-distance, l'approche porte
	## une composante LATÉRALE mesurable ; le braise, lui, fonce droit.
	var blue: RaiderBlue = await _setup(Vector3(0, 0.1, -40), Vector3(0, 0.1, 0))
	_player.global_position = Vector3(0, 0.1, 6.5)
	await _settle(10)
	check_equal(blue.state(), RaiderBlue.State.CHASE, "préalable : en chasse")
	var lateral_accumulated: float = 0.0
	for i: int in range(45):
		await _tree().physics_frame
		var to_player: Vector3 = _player.global_position - blue.global_position
		to_player.y = 0.0
		if to_player.length() < 2.6:
			break
		if to_player.length_squared() > 0.0001:
			var lateral: Vector3 = to_player.normalized().cross(Vector3.UP)
			lateral_accumulated += absf(blue.velocity.dot(lateral)) \
				* (1.0 / 60.0)
	check(lateral_accumulated > 0.4,
		"déplacement latéral réel pendant l'approche (%.2f m)"
		% lateral_accumulated)
	await _teardown()
