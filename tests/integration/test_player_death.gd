## Mort du joueur (§8.1 Dead, §16.2 généralisé) — régression du constat D1 de la
## revue contradictoire du Gate C : avant correction, le cadavre courait à
## 6 m/s, attaquait, esquivait, et le pillard le frappait indéfiniment. Ces
## tests rejouent la sonde de la revue et doivent rougir si l'état Dead
## disparaît. Le retour au checkpoint est Phase E (consigné dans STATUS).
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const RAIDER: String = "res://scenes/enemies/RaiderRed.tscn"

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


## Coup ennemi artificiel, comme dans test_heavy_and_hurt.
func _strike(damage: float) -> void:
	var hitbox: HitboxComponent = HitboxComponent.new()
	hitbox.team = &"enemies"
	hitbox.collision_mask = 32
	var cs: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 1.5
	cs.shape = sphere
	hitbox.add_child(cs)
	_world.add_child(hitbox)
	hitbox.global_position = _player.global_position + Vector3(0, 1, -0.8)
	await _settle(3)
	hitbox.activate(damage, 0.0, 3.0)
	await _settle(3)
	hitbox.deactivate()
	hitbox.queue_free()


func test_a_fatal_blow_leaves_a_still_and_deaf_corpse() -> void:
	## La sonde de la revue, en assertions : le coup fatal ne laisse ni recul en
	## course, ni attaque, ni esquive, ni verrouillage — un mort est immobile et
	## sourd aux intentions.
	await _setup()
	var health: HealthComponent = _player.health()
	health.revive(5.0)
	await _settle(2)

	await _strike(8.0)

	check(health.is_dead(), "le coup fatal tue (5 − 8)")
	check_equal(_player.mode(), PlayerController.Mode.DEAD,
		"la mort ÉCRASE la réaction HURT posée par le même coup")
	await _settle(5)
	check(_player.horizontal_speed() < 0.1,
		"le recul du coup fatal est annulé — le cadavre ne court pas (%.2f m/s)"
		% _player.horizontal_speed())

	var start: Vector3 = _player.global_position
	_intent.move = Vector2(0, 1)
	_intent.attack_pressed = true
	await _settle(20)
	_intent.dodge_pressed = true
	_intent.lock_pressed = true
	await _settle(20)
	_intent.move = Vector2.ZERO

	check(not _player.is_attacking(), "un mort n'attaque pas")
	check_equal(_player.mode(), PlayerController.Mode.DEAD, "un mort n'esquive pas")
	check(_player.lock_target() == null, "un mort ne verrouille pas")
	check((_player.global_position - start).length() < 0.05,
		"un mort ne se déplace pas (%.3f m)" % (_player.global_position - start).length())
	_teardown()


func test_the_raider_disengages_from_a_corpse() -> void:
	## Deuxième moitié de D1 : le pillard frappait le cadavre indéfiniment —
	## `_target_valid()` et la perception ignoraient la mort. Ici : joueur tué en
	## pleine poursuite → le pillard retourne à l'IDLE et n'y revient pas.
	await _setup()
	var raider: RaiderRed = (load(RAIDER) as PackedScene).instantiate() as RaiderRed
	_world.add_child(raider)
	raider.global_position = Vector3(0, 0, 6.0)
	await _settle(2)

	# Révéler l'attaquant (un impact est un événement sonore, §12.7) : le pillard
	# poursuit un joueur bien vivant.
	var poke: DamageEvent = DamageEvent.new()
	poke.instigator = _player
	poke.team = &"player"
	poke.amount = 1.0
	poke.attack_id = HitboxComponent.next_attack_id()
	(raider.get_node("Hurtbox") as HurtboxComponent).receive_hit(poke)
	await _settle(10)
	check_equal(raider.state(), RaiderRed.State.CHASE, "préalable : il poursuit")

	_player.health().revive(3.0)
	await _strike(8.0)
	check(_player.health().is_dead(), "préalable : le joueur meurt")

	# Compter les coups portés au cadavre à partir de MAINTENANT.
	var post_mortem_hits: Array[int] = [0]
	(_player.get_node("Hurtbox") as HurtboxComponent).hit_received.connect(
		func(_event: DamageEvent) -> void: post_mortem_hits[0] += 1)

	# 5 s : de quoi couvrir plusieurs cadences de perception et d'attaque.
	await _settle(300)

	check_equal(raider.state(), RaiderRed.State.IDLE,
		"le pillard a lâché le cadavre et n'y revient pas")
	check_equal(post_mortem_hits[0], 0, "aucun coup porté au cadavre")
	_teardown()
