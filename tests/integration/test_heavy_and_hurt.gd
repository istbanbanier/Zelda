## Attaque lourde (§10.2, §9.1) et réaction de dégât (§8.1 Hurt, §10.5).
##
## Les deux moitiés de l'item 12 de §22 qui manquaient : la lourde — chère,
## refusée à jauge vide, brisant la poise d'un coup — et le joueur qui RÉAGIT
## enfin à un coup, sans pour autant pouvoir être verrouillé par une cadence.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const RAIDER: String = "res://scenes/enemies/RaiderRed.tscn"
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
	box.size = Vector3(60, 1, 60)
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


func _spawn_dummy(at: Vector3) -> CombatDummy:
	var dummy: CombatDummy = (load(DUMMY) as PackedScene).instantiate() as CombatDummy
	_world.add_child(dummy)
	dummy.global_position = at
	return dummy


func test_heavy_attack_deals_scaled_damage_and_costs_stamina() -> void:
	## 12 × 1,8 = 21,6 de dégâts, 20 d'endurance (§9.1) — les deux mesurés sur le
	## même coup.
	await _setup()
	var dummy: CombatDummy = _spawn_dummy(Vector3(0, 0, 1.3))
	var stamina: StaminaComponent = _player.stamina()
	var stamina_before: float = stamina.current()
	await _settle(3)

	_intent.heavy_pressed = true
	# Le coût est prélevé à l'AMORCE (§9.1 : une action refusée ne consomme rien,
	# donc une action lancée consomme tout de suite). Mesurer immédiatement, avant
	# que la régénération (délai 1 s) ne rende des points pendant le recovery.
	await _settle(5)
	check_approx(stamina_before - stamina.current(), 20.0, 0.001,
		"coût d'endurance de la lourde (§9.1)")
	await _settle(65)   # startup 0,35 + actif 0,12 + recovery

	check_approx(dummy.health().current(), 45.0 - 21.6, 0.001,
		"dégâts de la lourde (12 × 1,8)")
	_teardown()


func test_heavy_attack_is_refused_when_stamina_is_low() -> void:
	## §9.1 : « lourde refusée » à jauge insuffisante. Rien ne part, rien n'est
	## prélevé, le mannequin ne sent rien.
	await _setup()
	var dummy: CombatDummy = _spawn_dummy(Vector3(0, 0, 1.3))
	var stamina: StaminaComponent = _player.stamina()
	stamina.set_current(10.0)   # sous le coût de 20
	await _settle(3)

	_intent.heavy_pressed = true
	await _settle(70)

	check(not _player.is_attacking(), "la lourde refusée ne part pas")
	check_approx(dummy.health().current(), 45.0, 0.001, "le mannequin est intact")
	check(stamina.current() >= 9.9, "rien n'est prélevé (%.1f)" % stamina.current())
	_teardown()


func test_one_heavy_blow_breaks_the_raider_poise() -> void:
	## Poise de la lourde : 25 ≥ 20 — un seul coup étourdit le pillard, là où il
	## en fallait deux légers. C'est l'« ouverture claire » de §12.3, version
	## pillard.
	await _setup()
	var raider: RaiderRed = (load(RAIDER) as PackedScene).instantiate() as RaiderRed
	_world.add_child(raider)
	raider.global_position = Vector3(0, 0, 1.3)
	var staggered: Array[int] = [0]
	raider.state_changed.connect(func(state: StringName) -> void:
		if state == &"staggered":
			staggered[0] += 1)
	await _settle(3)

	_intent.heavy_pressed = true
	await _settle(70)

	check_equal(staggered[0], 1, "une lourde suffit à briser la poise (25 ≥ 20)")
	check(not raider.health().is_dead(), "étourdi, pas mort (21,6 < 45)")
	_teardown()


func test_a_blow_knocks_the_player_back_with_brief_control_loss() -> void:
	## §8.1 Hurt : le `knockback` transporté depuis C.0 est enfin consommé — le
	## joueur est déplacé dans la direction du coup et perd brièvement la main.
	await _setup()
	var hitbox: HitboxComponent = HitboxComponent.new()
	hitbox.team = &"enemies"
	hitbox.collision_mask = 32
	var cs: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 1.0
	cs.shape = sphere
	hitbox.add_child(cs)
	_world.add_child(hitbox)
	# La hitbox est DERRIÈRE le joueur (-Z) : la direction du coup — attaquant →
	# victime — pousse vers +Z.
	hitbox.global_position = _player.global_position + Vector3(0, 1, -0.8)
	await _settle(3)

	var start: Vector3 = _player.global_position
	hitbox.activate(8.0, 0.0, 3.0)
	await _settle(3)
	hitbox.deactivate()

	check_equal(_player.mode(), PlayerController.Mode.HURT,
		"le coup reprend brièvement le contrôle")
	await _settle(20)
	check(_player.global_position.z - start.z > 0.15,
		"le recul pousse dans la direction du coup (dz = %.2f)"
		% (_player.global_position.z - start.z))
	check_equal(_player.mode(), PlayerController.Mode.LOCOMOTION,
		"le contrôle revient après la réaction (0,25 s)")
	_teardown()


func test_stunlock_grace_blocks_the_reaction_but_never_the_damage() -> void:
	## §10.5, au mot près : la protection anti-stunlock rend le CONTRÔLE, jamais
	## les points de vie. Deux coups en cadence : les deux blessent, seul le
	## premier renverse.
	await _setup()
	var hitbox: HitboxComponent = HitboxComponent.new()
	hitbox.team = &"enemies"
	hitbox.collision_mask = 32
	var cs: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 2.0
	cs.shape = sphere
	hitbox.add_child(cs)
	_world.add_child(hitbox)
	hitbox.global_position = _player.global_position + Vector3(0, 1, -0.8)
	await _settle(3)

	var health: HealthComponent = _player.get_node("Components/HealthComponent")
	var full: float = health.current()

	hitbox.activate(8.0, 0.0, 3.0)
	await _settle(3)
	hitbox.deactivate()
	check_equal(_player.mode(), PlayerController.Mode.HURT, "premier coup : réaction")

	# Attendre la fin de la réaction (0,25 s) mais rester DANS la grâce (0,85 s).
	await _settle(20)
	check_equal(_player.mode(), PlayerController.Mode.LOCOMOTION, "contrôle rendu")
	hitbox.activate(8.0, 0.0, 3.0)
	await _settle(3)
	hitbox.deactivate()

	check_approx(health.current(), full - 16.0, 0.001,
		"les DEUX coups blessent — la grâce ne protège jamais les PV")
	check_equal(_player.mode(), PlayerController.Mode.LOCOMOTION,
		"le second coup, dans la grâce, ne reprend pas le contrôle")

	# La grâce expire : un troisième coup renverse à nouveau.
	await _settle(40)   # au-delà des 0,85 s depuis le premier
	hitbox.activate(8.0, 0.0, 3.0)
	await _settle(3)
	hitbox.deactivate()
	check_equal(_player.mode(), PlayerController.Mode.HURT,
		"la grâce expirée, la réaction revient")
	_teardown()


func test_heavy_definition_matches_the_spec() -> void:
	## §10.2 : hit-stop lourd 0,070–0,095 s ; §9.1 : coût 20 épinglé côté stamina.
	var heavy: AttackDefinition = load("res://resources/combat/sword/heavy_1.tres")
	check_not_null(heavy, "heavy_1.tres")
	if heavy != null:
		check(heavy.hit_stop >= 0.070 and heavy.hit_stop <= 0.095,
			"hit-stop lourd hors §10.2 : %.3f" % heavy.hit_stop)
		check(heavy.damage_multiplier > 1.5, "la lourde doit frapper nettement plus fort")
		check(heavy.startup > 0.25, "la lourde s'annonce (startup %.2f)" % heavy.startup)
	var stamina: StaminaTuning = load("res://resources/tuning/stamina_default.tres")
	if stamina != null:
		check_approx(stamina.heavy_attack_cost, 20.0, 0.001, "coût de la lourde (§9.1)")
