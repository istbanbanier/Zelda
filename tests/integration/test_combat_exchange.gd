## Premier échange (MASTER_SPEC §10.1, §10.2) — joueur réel contre mannequin réel.
##
## Les tests unitaires prouvent le timing ; celui-ci prouve la CHAÎNE : intention
## → mode d'attaque → fenêtre active → hitbox orientée par le regard → hurtbox →
## formule → santé. Comme partout, `InputIntent` injectée — aucune touche simulée
## (D-013).
extends GateTestCase

const LAB: String = "res://scenes/tests/CombatLab.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"
const DUMMY: String = "res://scenes/tests/CombatDummy.tscn"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Monte un sol nu, le joueur, et un mannequin à `dummy_position`. Le joueur
## apparaît orienté vers +Z (le nez de la silhouette) : le mannequin posé devant
## est dans le volume de frappe sans qu'aucun déplacement soit nécessaire.
func _setup(dummy_position: Vector3) -> CombatDummy:
	_world = Node3D.new()
	_tree().root.add_child(_world)

	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var floor_shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(30, 1, 30)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)

	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = Vector3(0, 0.1, 0)
	_world.add_child(_player)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)

	var dummy: CombatDummy = (load(DUMMY) as PackedScene).instantiate() as CombatDummy
	dummy.position = dummy_position
	_world.add_child(dummy)

	# PIÈGE MESURÉ : le monde du test précédent, en `queue_free`, survit encore une
	# frame — le joueur peut apparaître posé sur sa géométrie fantôme (mesuré :
	# y = 0,87 au lieu de 0,1), puis chuter quand elle disparaît. Un appui envoyé
	# « après 10 ticks » arrivait en plein vol et le portail `is_on_floor()` le
	# consommait sans agir. On attend donc l'ÉTAT — deux frames pour laisser mourir
	# les fantômes, puis l'atterrissage réel — jamais un nombre de ticks fixe.
	await _settle(2)
	for i: int in range(120):
		if _player.is_on_floor():
			break
		await _tree().physics_frame
	check(_player.is_on_floor(), "préalable de setup : le joueur doit avoir atterri")
	return dummy


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


func test_a_single_press_lands_a_single_blow() -> void:
	## L'échange minimal : un appui, un coup, 12 dégâts (épée usée, §11.1),
	## malgré une fenêtre active qui chevauche le mannequin plusieurs frames.
	var dummy: CombatDummy = await _setup(Vector3(0, 0, 1.3))
	var amounts: Array[float] = []
	(dummy.get_node("Hurtbox") as HurtboxComponent).hit_received.connect(
		func(e: DamageEvent) -> void: amounts.append(e.amount))
	await _settle(10)

	_intent.attack_pressed = true
	await _settle(60)   # l'attaque entière (0,52 s) tient dans une seconde

	check_equal(amounts.size(), 1, "un appui, un coup")
	if amounts.size() == 1:
		check_approx(amounts[0], 12.0, 0.001, "dégâts du premier coup (12 × 1,0)")
	check_approx(dummy.health().current(), 33.0, 0.001, "santé du mannequin (45 − 12)")
	check(not _player.is_attacking(), "le joueur a rendu la main")
	_teardown()


func test_attack_engages_at_the_next_tick() -> void:
	## §10.6 et §23.1, appliqués à l'attaque : l'état s'engage au tick suivant
	## l'intention — le startup est de l'anticipation VOULUE, pas de la latence.
	var _dummy: CombatDummy = await _setup(Vector3(0, 0, 8.0))
	await _settle(10)
	check(not _player.is_attacking(), "au repos")
	_intent.attack_pressed = true
	await _settle(1)
	check(_player.is_attacking(), "l'attaque doit être engagée au tick suivant")
	_teardown()


func test_hammering_delivers_the_full_combo_then_resets() -> void:
	## §10.2 : trois légères à 1,0 / 1,05 / 1,3 — soit 12 ; 12,6 ; 15,6, total
	## 40,2. Le mannequin (45 PV, pillard braise §12.1) SURVIT au combo complet :
	## c'est le quatrième coup — première légère d'un NOUVEAU combo, donc 12 tout
	## rond — qui le couche. Le même martèlement prouve ainsi l'échelle des
	## multiplicateurs, la remise à zéro du combo, et la mort.
	var dummy: CombatDummy = await _setup(Vector3(0, 0, 1.3))
	var amounts: Array[float] = []
	(dummy.get_node("Hurtbox") as HurtboxComponent).hit_received.connect(
		func(e: DamageEvent) -> void: amounts.append(e.amount))
	var deaths: Array[int] = [0]
	dummy.dummy_died.connect(func() -> void: deaths[0] += 1)
	await _settle(10)

	# Marteler : l'appui est posé à chaque tick, le buffer et la fenêtre font le
	# reste. 240 ticks = 4 s — trois coups enchaînés (~1,6 s) plus le suivant.
	for i: int in range(240):
		_intent.attack_pressed = true
		await _tree().physics_frame

	check_equal(amounts.size(), 4, "quatre coups reçus, puis plus rien (cadavre)")
	if amounts.size() == 4:
		check_approx(amounts[0], 12.0, 0.001, "coup 1 : 12 × 1,0")
		check_approx(amounts[1], 12.6, 0.001, "coup 2 : 12 × 1,05")
		check_approx(amounts[2], 15.6, 0.001, "coup 3 : 12 × 1,3")
		check_approx(amounts[3], 12.0, 0.001, "coup 4 : nouveau combo, 12 × 1,0 — la remise à zéro est prouvée par le montant")
	check_equal(deaths[0], 1, "le mannequin meurt une fois")
	check(dummy.health().is_dead(), "le mannequin est mort")
	_teardown()


func test_movement_is_locked_during_the_attack() -> void:
	## §10.6 : pendant l'attaque, le corps est engagé — la vitesse s'éteint même
	## si le joueur maintient une direction.
	var _dummy: CombatDummy = await _setup(Vector3(0, 0, 8.0))
	await _settle(10)
	_intent.move = Vector2(1.0, 0.0)
	await _settle(60)
	check(_player.horizontal_speed() > 4.0, "préalable : le joueur court")

	_intent.attack_pressed = true
	await _settle(20)
	check(_player.is_attacking(), "préalable : attaque engagée")
	check(_player.horizontal_speed() < 0.5,
		"la course doit s'être éteinte pendant l'attaque (%.2f m/s)"
		% _player.horizontal_speed())
	_teardown()


func test_a_dead_dummy_takes_no_further_hits() -> void:
	## §12.10 : un cadavre coupe sa hurtbox. Après la mort, marteler encore ne
	## produit plus aucun événement de coup.
	var dummy: CombatDummy = await _setup(Vector3(0, 0, 1.3))
	var hits: Array[int] = [0]
	(dummy.get_node("Hurtbox") as HurtboxComponent).hit_received.connect(
		func(_e: DamageEvent) -> void: hits[0] += 1)
	await _settle(10)

	for i: int in range(240):
		_intent.attack_pressed = true
		await _tree().physics_frame
	check(dummy.health().is_dead(), "préalable : le mannequin est mort (4 coups)")
	var hits_at_death: int = hits[0]

	for i: int in range(120):
		_intent.attack_pressed = true
		await _tree().physics_frame
	check_equal(hits[0], hits_at_death, "aucun coup supplémentaire sur un cadavre")
	_teardown()


func test_two_dummies_side_by_side_each_take_one_hit_per_swing() -> void:
	## §21.4 « frapper plusieurs ennemis avec un swing » — cette fois via le VRAI
	## volume d'épée du joueur, pas une hitbox de test.
	var a: CombatDummy = await _setup(Vector3(-0.45, 0, 1.3))
	var b: CombatDummy = (load(DUMMY) as PackedScene).instantiate() as CombatDummy
	b.position = Vector3(0.45, 0, 1.3)
	_world.add_child(b)
	await _settle(10)

	_intent.attack_pressed = true
	await _settle(60)

	check_approx(a.health().current(), 33.0, 0.001, "mannequin gauche touché une fois")
	check_approx(b.health().current(), 33.0, 0.001, "mannequin droit touché une fois")
	_teardown()
