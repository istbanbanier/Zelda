## Pillard braise (MASTER_SPEC §12.1, §12.7) — le premier duel, en physique réelle.
##
## Le raider est piloté par sa propre IA ; le joueur par `InputIntent` injectée.
## Le cas central est celui que §12.1 impose au tutoriel vivant : le joueur
## esquive le coup télégraphié — i-frames réelles, chronométrées sur le startup
## du gourdin — et le pillard **recule**.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const RAIDER: String = "res://scenes/enemies/RaiderRed.tscn"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## `wall_size` non nul : un mur est posé AVANT le pillard — sa perception tourne
## dès son entrée en scène, un obstacle ajouté après coup arriverait trop tard.
func _setup(player_at: Vector3, raider_at: Vector3,
		wall_at: Vector3 = Vector3.ZERO, wall_size: Vector3 = Vector3.ZERO) -> RaiderRed:
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
	_player.position = player_at
	_world.add_child(_player)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)

	if wall_size != Vector3.ZERO:
		_wall_at(wall_at, wall_size)

	var raider: RaiderRed = (load(RAIDER) as PackedScene).instantiate() as RaiderRed
	raider.position = raider_at
	_world.add_child(raider)

	await _settle(2)
	for i: int in range(120):
		if _player.is_on_floor():
			break
		await _tree().physics_frame
	check(_player.is_on_floor(), "préalable de setup : joueur atterri")
	return raider


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


func test_raider_sees_and_chases_the_player_in_its_cone() -> void:
	## §12.6 : vision 22 m / 95°. Le pillard regarde +Z (pivot au repos) ; le
	## joueur est posé devant lui, à 10 m : poursuite attendue.
	var raider: RaiderRed = await _setup(Vector3(0, 0.1, 10), Vector3.ZERO)
	var start_distance: float = raider.global_position.distance_to(_player.global_position)
	await _settle(90)
	var end_distance: float = raider.global_position.distance_to(_player.global_position)
	check(raider.state() != RaiderRed.State.IDLE, "le pillard doit avoir aggro")
	check(end_distance < start_distance - 2.0,
		"il doit s'être rapproché (%.1f -> %.1f m)" % [start_distance, end_distance])
	_teardown()


func test_raider_ignores_the_player_behind_it() -> void:
	## Le cône de §12.6 est réel : dans le dos (joueur en -Z), pas d'aggro.
	## L'audition de §12.6 attendrait un ÉVÉNEMENT sonore (§12.7) — il n'en
	## existe pas encore, et rester immobile n'en produit pas.
	var raider: RaiderRed = await _setup(Vector3(0, 0.1, -8), Vector3.ZERO)
	await _settle(90)
	check_equal(raider.state(), RaiderRed.State.IDLE,
		"aucune aggro dans le dos, sans bruit")
	_teardown()


func test_raider_never_sees_through_a_wall() -> void:
	## §12.7 : « aucune vision à travers mur ». Même distance, même cône que le
	## premier test — seul le mur change.
	var raider: RaiderRed = await _setup(Vector3(0, 0.1, 10), Vector3.ZERO,
		Vector3(0, 2, 5), Vector3(8, 4, 0.4))
	await _settle(90)
	check_equal(raider.state(), RaiderRed.State.IDLE, "le mur bloque la vision")
	_teardown()


func test_raider_telegraphs_then_lands_its_blow() -> void:
	## §12.1 : télégraphe 0,65–0,95 s — le startup du gourdin (0,8 s, épinglé plus
	## bas). Le joueur immobile encaisse 8 (gourdin bois, §11.1) après le
	## télégraphe, jamais avant.
	# À 6 m : le pillard doit d'abord approcher (~1 s), les connexions de signaux
	# ci-dessous précèdent donc TOUTE annonce — à 2 m, la première attaque partait
	# pendant le _setup et le chronomètre la manquait.
	var raider: RaiderRed = await _setup(Vector3(0, 0.1, 6.0), Vector3.ZERO)
	var health: HealthComponent = _player.get_node("Components/HealthComponent")
	var full: float = health.current()

	var strike_seen: Array[float] = []
	var telegraph_start: Array[float] = [-1.0]
	var clock: Array[float] = [0.0]
	var attack: AttackControllerComponent = raider.get_node("AttackController")
	attack.attack_started.connect(func(_d: AttackDefinition, _i: int) -> void:
		telegraph_start[0] = clock[0])
	health.damaged.connect(func(_e: DamageEvent) -> void: strike_seen.append(clock[0]))

	for i: int in range(360):
		await _tree().physics_frame
		clock[0] += 1.0 / 60.0
		if not strike_seen.is_empty():
			break

	check(telegraph_start[0] >= 0.0, "l'attaque doit avoir été annoncée")
	check(not strike_seen.is_empty(), "le coup doit avoir porté sur un joueur immobile")
	if not strike_seen.is_empty():
		var telegraph: float = strike_seen[0] - telegraph_start[0]
		check(telegraph >= 0.65,
			"le coup ne porte jamais avant le télégraphe de §12.1 (%.2f s)" % telegraph)
		check_approx(health.current(), full - 8.0, 0.001,
			"dégâts du gourdin bois (§11.1 : 8)")
	_teardown()


func test_a_timed_dodge_avoids_the_blow_and_makes_the_raider_retreat() -> void:
	## LE cas de §12.1 : « recule après une esquive réussie du joueur ». L'esquive
	## est réelle et chronométrée sur le télégraphe : déclenchée 0,65 s après
	## l'annonce, ses i-frames (0,02–0,27) couvrent la fenêtre active du gourdin
	## (0,80–0,95).
	var raider: RaiderRed = await _setup(Vector3(0, 0.1, 6.0), Vector3.ZERO)
	var health: HealthComponent = _player.get_node("Components/HealthComponent")
	var full: float = health.current()

	var announced: Array[bool] = [false]
	var attack: AttackControllerComponent = raider.get_node("AttackController")
	attack.attack_started.connect(func(_d: AttackDefinition, _i: int) -> void:
		announced[0] = true)

	# Attendre l'annonce, puis esquiver 0,65 s plus tard (39 ticks).
	var waited: int = 0
	while not announced[0] and waited < 300:
		await _tree().physics_frame
		waited += 1
	check(announced[0], "préalable : le pillard doit attaquer")
	await _settle(39)
	_intent.dodge_pressed = true
	await _settle(60)

	check_approx(health.current(), full, 0.001,
		"l'esquive chronométrée doit annuler le coup (santé %.1f)" % health.current())
	var retreated: bool = raider.state() == RaiderRed.State.RETREAT \
		or raider.state() == RaiderRed.State.CHASE
	check(retreated, "après l'esquive, le pillard a reculé (état : %s)" % raider.state_name())
	# La preuve du recul est la distance : à portée de gourdin au moment du coup,
	# nettement plus loin après le repli.
	var distance: float = raider.global_position.distance_to(_player.global_position)
	check(distance > 2.2,
		"le repli doit se lire dans la distance (%.2f m)" % distance)
	_teardown()


func test_two_sword_hits_stagger_the_raider() -> void:
	## Poise 20, coups d'épée à 10 de poise : le deuxième casse la jauge, le
	## stagger interrompt tout et la fenêtre d'ouverture existe (§12.3 généralisé
	## au pillard : ouverture claire après la garde brisée).
	# Le pillard est DEVANT le joueur : l'épée frappe vers +Z. Posé derrière, le
	# combo battait l'air — défaut du premier jet de ce test.
	var raider: RaiderRed = await _setup(Vector3(0, 0.1, 0), Vector3(0, 0, 1.3))
	var staggered: Array[int] = [0]
	raider.state_changed.connect(func(s: StringName) -> void:
		if s == &"staggered":
			staggered[0] += 1)

	# Deux combos d'un coup chacun : marteler ferait trois touches et tuerait.
	_intent.attack_pressed = true
	await _settle(45)
	_intent.attack_pressed = true
	await _settle(45)

	check_equal(staggered[0], 1, "le deuxième coup (poise 10+10 ≥ 20) étourdit une fois")
	check(not raider.health().is_dead(), "étourdi n'est pas mort")
	await _settle(60)   # stagger_duration 0,8 s
	check(raider.state() != RaiderRed.State.STAGGERED,
		"l'étourdissement se dissipe (état : %s)" % raider.state_name())
	_teardown()


func test_the_duel_can_be_won() -> void:
	## Gate C : « combat gagnable ». Le joueur martèle, encaisse peut-être un
	## coup, et le pillard meurt — puis reste inerte (§12.10).
	var raider: RaiderRed = await _setup(Vector3(0, 0.1, 0), Vector3(0, 0, 1.5))
	var deaths: Array[int] = [0]
	raider.died.connect(func() -> void: deaths[0] += 1)

	for i: int in range(480):
		_intent.attack_pressed = true
		await _tree().physics_frame
		if raider.health().is_dead():
			break

	check(raider.health().is_dead(), "le duel doit être gagnable en martelant")
	check_equal(deaths[0], 1, "une seule mort")
	check_equal(raider.state(), RaiderRed.State.DEAD, "état final : dead")

	var player_health: HealthComponent = _player.get_node("Components/HealthComponent")
	check(player_health.current() > 0.0,
		"le joueur survit au tutoriel vivant (%.0f PV)" % player_health.current())
	_teardown()


func test_raider_tuning_matches_the_spec() -> void:
	## §12.1 et §12.6 épinglés, ainsi que le télégraphe du gourdin — jamais
	## seulement comparés au tuning qui les porte (revue B).
	var tuning: EnemyTuning = load("res://resources/enemies/raider_red_default.tres")
	check_not_null(tuning, "raider_red_default.tres")
	if tuning != null:
		check_approx(tuning.max_health, 45.0, 0.001, "45 PV (§12.1)")
		check_approx(tuning.vision_range, 22.0, 0.001, "vision 22 m (§12.6)")
		check_approx(tuning.vision_half_angle_deg, 47.5, 0.001, "cône 95° (§12.6)")
		check_approx(tuning.pursuit_speed, 5.2, 0.001, "poursuite 5,2 m/s (§12.6)")
	var club: AttackDefinition = load("res://resources/combat/raider/club_1.tres")
	check_not_null(club, "club_1.tres")
	if club != null:
		check(club.startup >= 0.65 and club.startup <= 0.95,
			"télégraphe hors §12.1 (0,65–0,95 s) : %.2f" % club.startup)
