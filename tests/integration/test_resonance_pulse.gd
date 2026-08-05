## P2-2 — Pulse, première opération du Bracelet (P2 §3.2).
##
## Fail-first : écrit avant `ResonanceController`/`ResonanceTargetComponent`.
## Contrats testés : révélation dans le rayon AVEC ligne de vue, jamais à
## travers un mur, jamais au-delà du rayon ; cooldown qui refuse puis rend la
## main ; révélation qui expire ; onde sonore que les ennemis entendent
## (« certains ennemis peuvent l'entendre » — le Pulse a un coût de bruit).
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"

var _root: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	_player = null
	_intent = null


func _setup() -> bool:
	var tree: SceneTree = _tree()
	if tree == null:
		return false
	_root = Node3D.new()
	tree.root.add_child(_root)
	_root.add_child(_static_box(Vector3(0.0, -0.5, 0.0), Vector3(80.0, 1.0, 80.0)))
	var player_scene: PackedScene = load(PLAYER) as PackedScene
	if player_scene == null:
		return false
	_player = player_scene.instantiate() as PlayerController
	_root.add_child(_player)
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	return true


func _static_box(at: Vector3, size: Vector3) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = at
	return body


func _target_at(at: Vector3) -> ResonanceTargetComponent:
	var holder: Node3D = Node3D.new()
	_root.add_child(holder)
	holder.global_position = at
	var component: ResonanceTargetComponent = ResonanceTargetComponent.new()
	holder.add_child(component)
	return component


func _press_pulse() -> void:
	_intent.pulse_pressed = true


func _release_pulse() -> void:
	_intent.pulse_pressed = false


func test_pulse_reveals_in_radius_with_los_and_not_beyond() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var near: ResonanceTargetComponent = _target_at(Vector3(0.0, 1.0, -4.0))
	var far: ResonanceTargetComponent = _target_at(Vector3(0.0, 1.0, -25.0))
	for i: int in range(10):
		await tree.physics_frame
	_press_pulse()
	await tree.physics_frame
	_release_pulse()
	await tree.physics_frame
	check(near.is_revealed(), "cible à 4 m avec LOS : révélée")
	check(not far.is_revealed(), "cible à 25 m (> rayon) : jamais révélée")
	_teardown()


func test_pulse_never_reveals_through_a_wall() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	# Mur plein entre le joueur et la cible — de la base au-dessus des têtes.
	_root.add_child(_static_box(Vector3(0.0, 2.0, -3.0), Vector3(8.0, 4.0, 0.4)))
	var hidden: ResonanceTargetComponent = _target_at(Vector3(0.0, 1.0, -6.0))
	for i: int in range(10):
		await tree.physics_frame
	_press_pulse()
	await tree.physics_frame
	_release_pulse()
	await tree.physics_frame
	check(not hidden.is_revealed(),
		"cible derrière un mur : jamais révélée (P2 §3.2 — pas de vision à travers)")
	_teardown()


func test_pulse_cooldown_refuses_then_recovers() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var target: ResonanceTargetComponent = _target_at(Vector3(0.0, 1.0, -4.0))
	var fired: Array[int] = [0]
	var resonance: ResonanceController = \
		_player.get_node("Components/ResonanceController") as ResonanceController
	resonance.pulse_fired.connect(func(_count: int) -> void: fired[0] += 1)
	for i: int in range(10):
		await tree.physics_frame
	_press_pulse()
	await tree.physics_frame
	_release_pulse()
	await tree.physics_frame
	check(fired[0] == 1, "premier Pulse : parti")
	# Ré-appui immédiat : refusé par le cooldown.
	_press_pulse()
	await tree.physics_frame
	_release_pulse()
	await tree.physics_frame
	check(fired[0] == 1, "ré-appui sous cooldown : refusé")
	# Après le cooldown (1,5 s = 90 ticks, marge incluse) : repart.
	for i: int in range(100):
		await tree.physics_frame
	_press_pulse()
	await tree.physics_frame
	_release_pulse()
	await tree.physics_frame
	check(fired[0] == 2, "après cooldown : le Pulse repart")
	check(target.is_revealed(), "et il révèle à nouveau")
	_teardown()


func test_a_reveal_expires_on_its_own() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var target: ResonanceTargetComponent = _target_at(Vector3(0.0, 1.0, -4.0))
	var ended: Array[int] = [0]
	target.reveal_ended.connect(func() -> void: ended[0] += 1)
	for i: int in range(10):
		await tree.physics_frame
	_press_pulse()
	await tree.physics_frame
	_release_pulse()
	check(true, "préambule joué")
	# Durée de révélation 3 s = 180 ticks ; marge.
	for i: int in range(200):
		await tree.physics_frame
	check(not target.is_revealed(), "la révélation expire d'elle-même")
	check(ended[0] == 1, "reveal_ended émis une fois")
	_teardown()


func test_pulse_emits_a_noise_enemies_can_hear() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var ear: Node3D = Node3D.new()
	ear.set_script(load("res://tests/support/noise_ear.gd"))
	_root.add_child(ear)
	ear.add_to_group("enemies")
	for i: int in range(10):
		await tree.physics_frame
	_press_pulse()
	await tree.physics_frame
	_release_pulse()
	await tree.physics_frame
	var heard: Array = ear.get("heard") as Array
	check(heard.size() == 1, "le Pulse a produit UN bruit")
	if heard.size() == 1:
		var event: Dictionary = heard[0] as Dictionary
		check(StringName(event["kind"]) == &"pulse", "nature du bruit : pulse")
	_teardown()
