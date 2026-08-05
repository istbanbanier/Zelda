## P2-2 — Ground (P2 §3.6) : mise à la terre volontaire d'un objet chargé.
##
## Fail-first : écrit avant l'implémentation. Contrats : startup visible
## (0,35 s) pendant lequel le héros est IMMOBILE ; support valide exigé (au
## sol) ; drainage réel à l'issue (charge à zéro, état grounded) ; refus
## explicables (pas de charge, hors portée, en l'air) ; annulation propre si
## la cible s'éloigne pendant le startup — jamais d'effet à moitié appliqué.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"

var _root: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null
var _resonance: ResonanceController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	_player = null
	_intent = null
	_resonance = null


func _setup() -> bool:
	var tree: SceneTree = _tree()
	if tree == null:
		return false
	_root = Node3D.new()
	tree.root.add_child(_root)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(60.0, 1.0, 60.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	_root.add_child(floor_body)
	var player_scene: PackedScene = load(PLAYER) as PackedScene
	if player_scene == null:
		return false
	_player = player_scene.instantiate() as PlayerController
	_root.add_child(_player)
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	_resonance = _player.get_node("Components/ResonanceController") as ResonanceController
	return true


func _charged_block(at: Vector3, charge: float = 5.0) -> MaterialStateComponent:
	var holder: Node3D = Node3D.new()
	_root.add_child(holder)
	holder.global_position = at
	var profile: MaterialProfile = MaterialProfile.new()
	profile.id = &"metal"
	profile.conductivity = 0.9
	profile.charge_capacity = 10.0
	var tags: Array[StringName] = [&"metal"]
	profile.tags = tags
	var state: MaterialStateComponent = MaterialStateComponent.new()
	state.profile = profile
	holder.add_child(state)
	if charge > 0.0:
		state.add_charge(charge)
	return state


func test_grounding_drains_the_target_after_a_visible_startup() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var block: MaterialStateComponent = _charged_block(Vector3(0.0, 0.5, -2.0))
	var completed: Array[int] = [0]
	_resonance.ground_completed.connect(func(_t: Node) -> void: completed[0] += 1)
	for i: int in range(20):
		await tree.physics_frame
	var verdict: StringName = _resonance.try_ground(_player, block)
	check(verdict == &"grounding", "verdict : grounding (obtenu %s)" % verdict)
	# Pendant le startup, la charge est toujours là — rien à moitié.
	await tree.physics_frame
	check(block.is_charged(), "startup en cours : la charge n'a pas encore bougé")
	# Le héros est immobilisé : pousser le stick ne le déplace pas.
	var at_start: Vector3 = _player.global_position
	_intent.move = Vector2(1.0, 0.0)
	for i: int in range(12):
		await tree.physics_frame
	_intent.move = Vector2.ZERO
	check(_player.global_position.distance_to(at_start) < 0.25,
		"immobilité pendant le startup (P2 §3.6 — vulnérabilité assumée)")
	for i: int in range(20):
		await tree.physics_frame
	check(not block.is_charged(), "charge drainée à zéro à l'issue")
	check(block.is_grounded(), "état grounded actif sur la cible")
	check(completed[0] == 1, "ground_completed émis une fois")
	_teardown()


func test_refusals_are_explained() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var uncharged: MaterialStateComponent = _charged_block(Vector3(0.0, 0.5, -2.0), 0.0)
	var far_block: MaterialStateComponent = _charged_block(Vector3(0.0, 0.5, -12.0))
	for i: int in range(20):
		await tree.physics_frame
	check(_resonance.try_ground(_player, uncharged) == &"pas_de_charge",
		"cible sans charge : pas_de_charge")
	check(_resonance.try_ground(_player, far_block) == &"hors_portee",
		"12 m : hors_portee")
	# En l'air : pas de support valide — DANS la portée (2 m), mais décollé.
	var near: MaterialStateComponent = _charged_block(Vector3(0.0, 0.5, 2.0))
	_player.global_position = Vector3(0.0, 2.5, 2.0)
	await tree.physics_frame
	await tree.physics_frame
	check(_resonance.try_ground(_player, near) == &"pas_au_sol",
		"héros en l'air : pas_au_sol (support de terre exigé, P2 §3.6)")
	_teardown()


func test_the_direct_key_grounds_the_nearest_charged_object() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	# Deux blocs chargés : le plus PROCHE doit être choisi.
	var near_block: MaterialStateComponent = _charged_block(Vector3(0.0, 0.5, -1.5))
	var far_block: MaterialStateComponent = _charged_block(Vector3(0.0, 0.5, 2.8))
	for i: int in range(20):
		await tree.physics_frame
	_intent.ground_pressed = true
	await tree.physics_frame
	_intent.ground_pressed = false
	# Startup 0,35 s puis drainage.
	for i: int in range(30):
		await tree.physics_frame
	check(not near_block.is_charged(), "le bloc le plus proche est drainé")
	check(far_block.is_charged(), "l'autre n'est pas touché")
	_teardown()


func test_a_target_leaving_range_cancels_cleanly() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var block: MaterialStateComponent = _charged_block(Vector3(0.0, 0.5, -2.0))
	var cancelled: Array[int] = [0]
	_resonance.ground_cancelled.connect(func(_reason: StringName) -> void: cancelled[0] += 1)
	for i: int in range(20):
		await tree.physics_frame
	check(_resonance.try_ground(_player, block) == &"grounding", "démarré")
	await tree.physics_frame
	# La cible s'échappe pendant le startup.
	(block.get_parent() as Node3D).global_position = Vector3(0.0, 0.5, -30.0)
	for i: int in range(30):
		await tree.physics_frame
	check(cancelled[0] == 1, "annulation émise une fois")
	check(block.is_charged(), "AUCUN drainage : rien à moitié appliqué")
	check(not block.is_grounded(), "aucun état grounded posé")
	_teardown()
