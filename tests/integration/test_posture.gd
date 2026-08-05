## P2-3 — Posture : la jauge TACTIQUE des porteurs de garde (P2 §7.4, bible
## §7.2). Fail-first : écrit avant `PostureComponent` et la migration du
## Briseur.
##
## Contrats : la jauge encaisse, casse UNE fois (signal unique), se recharge
## après une accalmie et ne re-casse pas tant qu'elle est à zéro ; un coup à
## fort `posture_damage` la brise même si ses dégâts de santé sont faibles ;
## la déviation parfaite du joueur nourrit la POSTURE quand la cible en porte
## une, et la POISE sinon (règle de dispatch de la bible §7.2).
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null


func _setup() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)


func test_the_gauge_breaks_once_and_recovers_after_a_lull() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var posture: PostureComponent = PostureComponent.new()
	posture.max_posture = 12.0
	posture.regen_delay = 0.4
	posture.regen_rate = 30.0
	_root.add_child(posture)
	var broken: Array[int] = [0]
	posture.posture_broken.connect(func() -> void: broken[0] += 1)
	check(not posture.take_posture_damage(5.0), "5/12 : pas de rupture")
	check(not posture.is_broken(), "la jauge tient")
	check(posture.take_posture_damage(8.0), "13/12 : rupture — et l'appel le dit")
	check(posture.is_broken(), "état brisé")
	check(broken[0] == 1, "signal émis UNE fois")
	# À zéro, frapper encore ne ré-émet pas (idempotence).
	check(not posture.take_posture_damage(5.0), "frapper une jauge brisée ne re-casse pas")
	check(broken[0] == 1, "toujours un seul signal")
	# Accalmie : la jauge se recharge et peut re-casser ensuite.
	for i: int in range(40):
		await tree.physics_frame
	check(not posture.is_broken(), "après l'accalmie, la jauge est revenue")
	check(posture.current() > 0.0, "recharge réelle (%.1f)" % posture.current())
	_teardown()


func test_a_posture_heavy_blow_breaks_the_black_guard_in_one_hit() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, 40.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	_root.add_child(floor_body)
	var player_scene: PackedScene = load(PLAYER) as PackedScene
	var player: PlayerController = player_scene.instantiate() as PlayerController
	_root.add_child(player)
	# Loin d'abord : le Briseur ne doit pas avoir le temps d'ENGAGER (la
	# garde tombe pendant ses propres coups) — schéma du test historique.
	player.global_position = Vector3(0.0, 0.1, -40.0)
	var black_scene: PackedScene = load("res://scenes/enemies/RaiderBlack.tscn") as PackedScene
	var black: RaiderBlack = black_scene.instantiate() as RaiderBlack
	_root.add_child(black)
	black.global_position = Vector3(0.0, 0.1, 0.0)
	for i: int in range(20):
		await tree.physics_frame
	player.global_position = Vector3(0.0, 0.1, -1.5)
	(black.get_node("Pivot") as Node3D).rotation.y = PI
	for i: int in range(10):
		await tree.physics_frame
	if not black.is_guarding():
		check(false, "préalable : garde levée face au joueur")
		_teardown()
		return
	# Un coup FAIBLE en santé mais LOURD en posture : la garde casse net.
	var blow: DamageEvent = DamageEvent.new()
	blow.amount = 2.0
	blow.posture_damage = 12.0
	blow.direction = Vector3(0.0, 0.0, -1.0)
	blow.attack_id = HitboxComponent.next_attack_id()
	(black.get_node("Hurtbox") as HurtboxComponent).receive_hit(blow)
	await tree.physics_frame
	await tree.physics_frame
	check(black.guard_gauge() <= 0.1,
		"posture_damage 12 vide la jauge en un coup (%.1f)" % black.guard_gauge())
	check(black.state_name() == &"staggered",
		"la rupture ouvre : STAGGERED (§12.3)")
	_teardown()


func test_a_perfect_deflect_feeds_posture_when_carried_else_poise() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, 40.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	_root.add_child(floor_body)
	var player_scene: PackedScene = load(PLAYER) as PackedScene
	var player: PlayerController = player_scene.instantiate() as PlayerController
	_root.add_child(player)
	player.global_position = Vector3(0.0, 1.0, 0.0)
	var intent: InputIntent = InputIntent.new()
	player.set_intent_source(intent)
	# Attaquant factice PORTEUR des deux jauges : le dispatch doit choisir
	# la posture et laisser la poise intacte.
	var attacker: Node3D = Node3D.new()
	_root.add_child(attacker)
	attacker.global_position = Vector3(0.0, 1.0, 4.0)
	var poise: PoiseComponent = PoiseComponent.new()
	poise.name = "PoiseComponent"
	poise.max_poise = 100.0
	attacker.add_child(poise)
	var poise_hits: Array[int] = [0]
	poise.poise_changed.connect(func(_c: float, _m: float) -> void: poise_hits[0] += 1)
	var posture: PostureComponent = PostureComponent.new()
	posture.name = "PostureComponent"
	posture.max_posture = 12.0
	attacker.add_child(posture)
	for i: int in range(20):
		await tree.physics_frame
	# Parade parfaite : garde levée un tick avant l'impact frontal.
	intent.aim_held = true
	await tree.physics_frame
	var blow: DamageEvent = DamageEvent.new()
	blow.amount = 15.0
	blow.direction = Vector3(0.0, 0.0, -1.0)
	blow.instigator = attacker
	blow.attack_id = HitboxComponent.next_attack_id()
	(player.get_node("Hurtbox") as HurtboxComponent).receive_hit(blow)
	await tree.physics_frame
	check(posture.current() < posture.max_posture,
		"la POSTURE de l'attaquant a payé (%.1f/12)" % posture.current())
	check(not poise.is_broken() and poise_hits[0] == 0,
		"…et sa POISE est intacte : le dispatch a choisi (bible §7.2)")
	intent.aim_held = false
	_teardown()
