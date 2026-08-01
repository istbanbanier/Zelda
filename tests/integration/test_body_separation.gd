## Séparation physique des corps — régressions du playtest n° 1 (PT-D1-02).
##
## Avant D.1R.2 : joueur masque 1, pillard masque 1 — personne ne collisionnait
## qu'avec le décor, les capsules se traversaient. Ces tests mesurent des
## DISTANCES entre vrais `CharacterBody3D` après plusieurs ticks : ils
## rougissent si les masques reviennent à 1, ou si la séparation locale
## disparaît (file indienne).
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const RAIDER: String = "res://scenes/enemies/RaiderRed.tscn"

## Rayons de capsule : joueur 0,35 + pillard 0,4 = contact à 0,75.
const PLAYER_RAIDER_CONTACT: float = 0.75
const RAIDER_RAIDER_CONTACT: float = 0.8

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


func _spawn_raider(at: Vector3) -> RaiderRed:
	var raider: RaiderRed = (load(RAIDER) as PackedScene).instantiate() as RaiderRed
	raider.position = at
	_world.add_child(raider)
	return raider


func _flat_distance(a: Node3D, b: Node3D) -> float:
	var gap: Vector3 = a.global_position - b.global_position
	gap.y = 0.0
	return gap.length()


func _poke(raider: RaiderRed) -> void:
	var event: DamageEvent = DamageEvent.new()
	event.instigator = _player
	event.team = &"player"
	event.amount = 1.0
	event.attack_id = HitboxComponent.next_attack_id()
	(raider.get_node("Hurtbox") as HurtboxComponent).receive_hit(event)


func test_a_raider_can_never_share_the_player_volume() -> void:
	## Les deux corps sont posés au MÊME point : la dépénétration + les masques
	## corrigés les écartent. Avec les masques d'avant (1/1), ils resteraient
	## exactement superposés — le test rougit.
	await _setup()
	var raider: RaiderRed = _spawn_raider(_player.global_position)
	await _settle(30)

	var gap: float = _flat_distance(_player, raider)
	check(gap >= PLAYER_RAIDER_CONTACT * 0.75,
		"deux corps ne partagent jamais un volume (écart %.2f m, contact à %.2f)"
		% [gap, PLAYER_RAIDER_CONTACT])
	_teardown()


func test_three_chasing_raiders_never_stack_and_all_reach_the_player() -> void:
	## PT-D1-02, seconde moitié : la collision seule laisse trois poursuivants en
	## file indienne (le troisième à ~3 m). La séparation locale les déploie :
	## TOUS approchent à portée de menace, et aucun couple ne se chevauche —
	## mesuré sur 8 s de poursuite réelle.
	await _setup()
	var raiders: Array[RaiderRed] = [
		_spawn_raider(Vector3(0, 0.1, 8)),
		_spawn_raider(Vector3(0.3, 0.1, 8.6)),
		_spawn_raider(Vector3(-0.3, 0.1, 9.2)),
	]
	await _settle(5)
	for raider: RaiderRed in raiders:
		_poke(raider)

	var min_pairwise: float = 100.0
	for i: int in range(480):
		await _tree().physics_frame
		if i < 60:
			continue  # laisser la dépénétration initiale se faire
		for a: int in range(raiders.size()):
			for b: int in range(a + 1, raiders.size()):
				min_pairwise = minf(min_pairwise,
					_flat_distance(raiders[a], raiders[b]))

	check(min_pairwise >= RAIDER_RAIDER_CONTACT * 0.7,
		"aucun chevauchement de pillards pendant la poursuite (min %.2f m)" % min_pairwise)
	var worst: float = 0.0
	for raider: RaiderRed in raiders:
		worst = maxf(worst, _flat_distance(_player, raider))
	check(worst <= 2.8,
		"les TROIS approchent à portée de menace — pas de file indienne (max %.2f m)" % worst)
	_teardown()


func test_a_pushing_raider_never_forces_the_player_through_a_wall() -> void:
	## PT-D1-02 : le joueur est adossé à un mur, un pillard le presse de face
	## pendant 5 s — le joueur ne traverse JAMAIS le plan du mur.
	await _setup()
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(8, 4, 0.4)
	cs.shape = box
	wall.add_child(cs)
	wall.position = Vector3(0, 2, -1.0)   # face nord du mur à z = -0.8
	_world.add_child(wall)
	# Joueur collé au mur, pillard devant lui qui pousse vers -Z.
	_player.global_position = Vector3(0, 0.1, -0.4)
	_player.reset_physics_interpolation()
	var raider: RaiderRed = _spawn_raider(Vector3(0, 0.1, 1.2))
	await _settle(5)
	_poke(raider)

	var deepest: float = 100.0
	for i: int in range(300):
		await _tree().physics_frame
		deepest = minf(deepest, _player.global_position.z)

	check(deepest > -0.8 + 0.3,
		"le joueur reste du bon côté du mur (z min %.2f, plan à -0.8)" % deepest)
	check(_player.health().current() >= 0.0, "les dégâts de mêlée, eux, restent légitimes")
	_teardown()


func test_combat_still_works_with_the_new_masks() -> void:
	## Garde-fou : la séparation physique n'a pas volé le combat — le duel
	## complet de C.2 reste gagnable avec les nouveaux masques.
	await _setup()
	var raider: RaiderRed = _spawn_raider(Vector3(0, 0.1, 3))
	await _settle(5)
	_poke(raider)
	var dead: Array[bool] = [false]
	raider.died.connect(func() -> void: dead[0] = true)

	for i: int in range(600):
		_intent.attack_pressed = true
		await _tree().physics_frame
		if dead[0]:
			break

	check(dead[0], "le pillard meurt sous le martèlement — hitbox/hurtbox intactes")
	check(not _player.health().is_dead(), "le joueur survit")
	_teardown()
