## Détection de coup (MASTER_SPEC §10.1) — en physique réelle, pas en maquette.
##
## Le critère central du Gate C s'appelle « une touche par swing ». Ces tests
## construisent une hitbox et des hurtbox réellement en chevauchement dans
## l'espace physique, activent une fenêtre, et COMPTENT : §10.1 interdit « des
## dégâts à chaque frame d'overlap », et le chevauchement dure ici des dizaines
## de frames — c'est précisément ce que le set des cibles touchées doit absorber.
extends GateTestCase

var _world: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _setup() -> void:
	_world = Node3D.new()
	_tree().root.add_child(_world)


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null


func _make_hitbox(team: StringName, at: Vector3) -> HitboxComponent:
	var hitbox: HitboxComponent = HitboxComponent.new()
	hitbox.team = team
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.6
	shape.shape = sphere
	hitbox.add_child(shape)
	_world.add_child(hitbox)
	hitbox.global_position = at
	return hitbox


## Une victime = santé + hurtbox câblées comme dans une vraie scène (§6.3),
## NodePath compris — le câblage fait partie de ce qu'on teste.
func _make_victim(team: StringName, at: Vector3, max_health: float = 100.0,
		weak_point: float = 1.0) -> HurtboxComponent:
	var root: Node3D = Node3D.new()
	var health: HealthComponent = HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = max_health
	root.add_child(health)

	var hurtbox: HurtboxComponent = HurtboxComponent.new()
	hurtbox.name = "Hurtbox"
	hurtbox.team = team
	hurtbox.weak_point_multiplier = weak_point
	hurtbox.health_path = NodePath("../HealthComponent")
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.5
	shape.shape = sphere
	hurtbox.add_child(shape)
	root.add_child(hurtbox)

	_world.add_child(root)
	root.global_position = at
	return hurtbox


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func test_an_overlapping_swing_hits_exactly_once() -> void:
	## §10.1, la phrase clé : le chevauchement dure 30 frames, la victime encaisse
	## UN coup.
	_setup()
	var hitbox: HitboxComponent = _make_hitbox(&"player", Vector3.ZERO)
	var victim: HurtboxComponent = _make_victim(&"enemies", Vector3(0.5, 0, 0))
	var hits: Array[int] = [0]
	victim.hit_received.connect(func(_e: DamageEvent) -> void: hits[0] += 1)
	await _settle(3)

	hitbox.activate(10.0)
	await _settle(30)
	hitbox.deactivate()

	check_equal(hits[0], 1, "coups reçus pendant 30 frames de chevauchement")
	check_approx(victim.health().current(), 90.0, 0.001, "santé après un seul coup de 10")
	_teardown()


func test_a_second_swing_hits_again() -> void:
	## Le set meurt avec le swing : deux activations, deux coups — pas un, pas
	## trois. Vérifie aussi que les attack ID diffèrent (§10.3).
	_setup()
	var hitbox: HitboxComponent = _make_hitbox(&"player", Vector3.ZERO)
	var victim: HurtboxComponent = _make_victim(&"enemies", Vector3(0.5, 0, 0))
	var ids: Array[int] = []
	victim.hit_received.connect(func(e: DamageEvent) -> void: ids.append(e.attack_id))
	await _settle(3)

	var first: int = hitbox.activate(10.0)
	await _settle(10)
	hitbox.deactivate()
	var second: int = hitbox.activate(10.0)
	await _settle(10)
	hitbox.deactivate()

	check_equal(ids.size(), 2, "deux swings, deux coups")
	check(first != second, "deux swings ne partagent jamais un attack ID")
	if ids.size() == 2:
		check(ids[0] != ids[1], "les événements portent bien les deux ID distincts")
	check_approx(victim.health().current(), 80.0, 0.001, "santé après deux coups de 10")
	_teardown()


func test_one_swing_hits_every_target_in_range_once() -> void:
	## §21.4 « frapper plusieurs ennemis avec un swing » — la part automatisable :
	## chaque victime du même swing est touchée une fois, avec le même attack ID.
	_setup()
	var hitbox: HitboxComponent = _make_hitbox(&"player", Vector3.ZERO)
	var a: HurtboxComponent = _make_victim(&"enemies", Vector3(0.5, 0, 0))
	var b: HurtboxComponent = _make_victim(&"enemies", Vector3(-0.5, 0, 0))
	var ids: Array[int] = []
	a.hit_received.connect(func(e: DamageEvent) -> void: ids.append(e.attack_id))
	b.hit_received.connect(func(e: DamageEvent) -> void: ids.append(e.attack_id))
	await _settle(3)

	hitbox.activate(10.0)
	await _settle(20)
	hitbox.deactivate()

	check_equal(ids.size(), 2, "deux victimes, un coup chacune")
	if ids.size() == 2:
		check_equal(ids[0], ids[1], "même swing, même attack ID")
	check_approx(a.health().current(), 90.0, 0.001, "victime A touchée une fois")
	check_approx(b.health().current(), 90.0, 0.001, "victime B touchée une fois")
	_teardown()


func test_an_inactive_hitbox_never_hits() -> void:
	## La fenêtre active de §10.1 : hors d'elle, le chevauchement est inoffensif.
	_setup()
	var hitbox: HitboxComponent = _make_hitbox(&"player", Vector3.ZERO)
	var victim: HurtboxComponent = _make_victim(&"enemies", Vector3(0.5, 0, 0))
	var hits: Array[int] = [0]
	victim.hit_received.connect(func(_e: DamageEvent) -> void: hits[0] += 1)

	await _settle(20)
	check_equal(hits[0], 0, "aucun coup sans activation")

	hitbox.activate(10.0)
	await _settle(5)
	hitbox.deactivate()
	await _settle(20)
	check_equal(hits[0], 1, "un coup pendant la fenêtre, plus rien après")
	_teardown()


func test_friendly_fire_is_refused_by_team() -> void:
	## §10.3 : l'événement transporte l'équipe ; §5.7 : les couches séparent déjà
	## les camps, mais une erreur de couche ne doit pas suffire à blesser un allié.
	_setup()
	var hitbox: HitboxComponent = _make_hitbox(&"player", Vector3.ZERO)
	var ally: HurtboxComponent = _make_victim(&"player", Vector3(0.5, 0, 0))
	var enemy: HurtboxComponent = _make_victim(&"enemies", Vector3(-0.5, 0, 0))
	await _settle(3)

	hitbox.activate(10.0)
	await _settle(10)
	hitbox.deactivate()

	check_approx(ally.health().current(), 100.0, 0.001, "l'allié n'est jamais touché")
	check_approx(enemy.health().current(), 90.0, 0.001, "l'ennemi l'est")
	_teardown()


func test_weak_point_multiplier_is_applied_by_the_formula() -> void:
	## §10.3 : le point faible est un attribut de la hurtbox, appliqué par la
	## formule au contact — le dos du colosse sera une hurtbox à ×2, pas un cas
	## particulier dans le code de l'attaquant.
	_setup()
	var hitbox: HitboxComponent = _make_hitbox(&"player", Vector3.ZERO)
	var victim: HurtboxComponent = _make_victim(&"enemies", Vector3(0.5, 0, 0), 100.0, 2.0)
	var amounts: Array[float] = []
	victim.hit_received.connect(func(e: DamageEvent) -> void: amounts.append(e.amount))
	await _settle(3)

	hitbox.activate(10.0)
	await _settle(10)
	hitbox.deactivate()

	check_equal(amounts.size(), 1, "un coup")
	if amounts.size() == 1:
		check_approx(amounts[0], 20.0, 0.001, "10 × 2 au point faible")
	check_approx(victim.health().current(), 80.0, 0.001, "santé après le coup amplifié")
	_teardown()


func test_the_event_carries_what_the_spec_demands() -> void:
	## §10.3 énumère le contenu de l'événement. On vérifie qu'il arrive complet —
	## les couches de présentation (C.1+) s'y abonneront sans rien redemander.
	_setup()
	var hitbox: HitboxComponent = _make_hitbox(&"player", Vector3.ZERO)
	var victim: HurtboxComponent = _make_victim(&"enemies", Vector3(0.5, 0, 0))
	var events: Array[DamageEvent] = []
	victim.hit_received.connect(func(e: DamageEvent) -> void: events.append(e))
	await _settle(3)

	hitbox.activate(12.0, 4.0, 2.5, &"melee", &"electric")
	await _settle(10)
	hitbox.deactivate()

	check_equal(events.size(), 1, "un événement")
	if events.size() != 1:
		_teardown()
		return
	var e: DamageEvent = events[0]
	check_equal(e.team, &"player", "équipe")
	check_equal(e.damage_type, &"melee", "type")
	check_approx(e.amount, 12.0, 0.001, "quantité finale")
	check_approx(e.poise_damage, 4.0, 0.001, "poise")
	check_approx(e.knockback, 2.5, 0.001, "recul")
	check_equal(e.element, &"electric", "élément")
	check(e.attack_id > 0, "attack ID renseigné")
	check(e.direction.length() > 0.9, "direction normalisée renseignée")
	_teardown()
