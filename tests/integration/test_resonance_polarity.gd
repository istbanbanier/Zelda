## P2-2 — Polarité (P2 §3.4) : attirer/repousser un objet MÉTALLIQUE CHARGÉ
## sous plafond de masse, par impulsions bornées compatibles Jolt — jamais un
## téléport, jamais un acteur vivant (RigidBody3D uniquement, structurel).
##
## Fail-first : écrit avant l'implémentation. Contrats : mouvement réel vers/
## loin de l'ancrage ; vitesse plafonnée ; continuité de position (aucun saut
## > vitesse max × dt) ; refus explicables (pas métal, pas chargé, trop lourd,
## hors portée) ; l'engagement se termine seul (durée max) et casse à la
## décharge de la cible.
extends GateTestCase

var _root: Node3D = null
var _body: CharacterBody3D = null
var _resonance: ResonanceController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	_body = null
	_resonance = null


func _setup() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var floor_shape: CollisionShape3D = CollisionShape3D.new()
	var floor_box: BoxShape3D = BoxShape3D.new()
	floor_box.size = Vector3(80.0, 1.0, 80.0)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	_root.add_child(floor_body)
	_body = CharacterBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = CapsuleShape3D.new()
	_body.add_child(shape)
	_root.add_child(_body)
	_body.global_position = Vector3(0.0, 1.0, 0.0)
	_resonance = ResonanceController.new()
	_root.add_child(_resonance)


func _metal_block(at: Vector3, block_mass: float, charged: bool = true,
		metal: bool = true) -> RigidBody3D:
	var block: RigidBody3D = RigidBody3D.new()
	block.mass = block_mass
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.8, 0.8, 0.8)
	shape.shape = box
	block.add_child(shape)
	var profile: MaterialProfile = MaterialProfile.new()
	profile.id = &"metal" if metal else &"bois"
	profile.conductivity = 0.9 if metal else 0.05
	profile.charge_capacity = 10.0 if metal else 0.0
	profile.logical_mass = block_mass
	var tags: Array[StringName] = []
	tags.append(&"metal" if metal else &"wood")
	profile.tags = tags
	var state: MaterialStateComponent = MaterialStateComponent.new()
	state.profile = profile
	block.add_child(state)
	_root.add_child(block)
	block.global_position = at
	if charged and metal:
		state.add_charge(5.0)
	return block


func _state_of(block: RigidBody3D) -> MaterialStateComponent:
	for child: Node in block.get_children():
		if child is MaterialStateComponent:
			return child as MaterialStateComponent
	return null


func test_attract_pulls_the_block_without_teleport_and_under_speed_cap() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var block: RigidBody3D = _metal_block(Vector3(6.0, 0.6, 0.0), 40.0)
	for i: int in range(10):
		await tree.physics_frame
	var start_gap: float = block.global_position.distance_to(_body.global_position)
	var verdict: StringName = _resonance.try_polarity(_body, block, &"attirer")
	check(verdict == &"engaged", "verdict : engaged (obtenu %s)" % verdict)
	var max_speed: float = 0.0
	var max_step: float = 0.0
	var previous: Vector3 = block.global_position
	var dt: float = 1.0 / float(Engine.physics_ticks_per_second)
	for i: int in range(70):
		await tree.physics_frame
		max_speed = maxf(max_speed, block.linear_velocity.length())
		max_step = maxf(max_step, block.global_position.distance_to(previous))
		previous = block.global_position
	var end_gap: float = block.global_position.distance_to(_body.global_position)
	check(end_gap < start_gap - 1.0,
		"le bloc s'est rapproché (%.2f → %.2f m)" % [start_gap, end_gap])
	check(max_speed <= ResonanceController.POLARITY_SPEED + 1.0,
		"vitesse plafonnée (max %.2f m/s)" % max_speed)
	check(max_step <= (ResonanceController.POLARITY_SPEED + 2.0) * dt * 2.0,
		"continuité : aucun saut de position (max %.3f m/tick)" % max_step)
	_teardown()


func test_repel_pushes_the_block_away() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var block: RigidBody3D = _metal_block(Vector3(3.0, 0.6, 0.0), 40.0)
	for i: int in range(10):
		await tree.physics_frame
	var start_gap: float = block.global_position.distance_to(_body.global_position)
	check(_resonance.try_polarity(_body, block, &"repousser") == &"engaged", "engagé")
	for i: int in range(70):
		await tree.physics_frame
	var end_gap: float = block.global_position.distance_to(_body.global_position)
	check(end_gap > start_gap + 1.0,
		"le bloc s'est éloigné (%.2f → %.2f m)" % [start_gap, end_gap])
	_teardown()


func test_refusals_are_explained() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var wood: RigidBody3D = _metal_block(Vector3(4.0, 0.6, 0.0), 40.0, false, false)
	var uncharged: RigidBody3D = _metal_block(Vector3(0.0, 0.6, 4.0), 40.0, false, true)
	var heavy: RigidBody3D = _metal_block(Vector3(0.0, 0.6, -4.0), 200.0)
	var far: RigidBody3D = _metal_block(Vector3(30.0, 0.6, 0.0), 40.0)
	for i: int in range(10):
		await tree.physics_frame
	check(_resonance.try_polarity(_body, wood, &"attirer") == &"pas_metal",
		"bois : pas_metal")
	check(_resonance.try_polarity(_body, uncharged, &"attirer") == &"pas_charge",
		"métal non chargé : pas_charge (la Polarité exige la charge, P2 §3.4)")
	check(_resonance.try_polarity(_body, heavy, &"attirer") == &"trop_lourd",
		"200 kg : trop_lourd")
	check(_resonance.try_polarity(_body, far, &"attirer") == &"hors_portee",
		"30 m : hors_portee")
	check(not _resonance.polarity_engaged(), "aucun engagement retenu")
	_teardown()


func test_the_engagement_ends_on_its_own_after_the_time_budget() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var block: RigidBody3D = _metal_block(Vector3(6.0, 0.6, 0.0), 40.0)
	for i: int in range(10):
		await tree.physics_frame
	check(_resonance.try_polarity(_body, block, &"attirer") == &"engaged", "engagé")
	check(_resonance.polarity_engaged(), "engagement actif")
	# Budget 2,5 s = 150 ticks ; marge.
	for i: int in range(170):
		await tree.physics_frame
	check(not _resonance.polarity_engaged(),
		"l'engagement s'éteint seul au budget de durée (P2 §3.4 : durée bornée)")
	_teardown()


func test_discharging_the_target_breaks_the_engagement() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var block: RigidBody3D = _metal_block(Vector3(6.0, 0.6, 0.0), 40.0)
	for i: int in range(10):
		await tree.physics_frame
	check(_resonance.try_polarity(_body, block, &"attirer") == &"engaged", "engagé")
	for i: int in range(5):
		await tree.physics_frame
	_state_of(block).ground()
	await tree.physics_frame
	await tree.physics_frame
	check(not _resonance.polarity_engaged(),
		"cible déchargée → engagement rompu (la Polarité manipule une CHARGE)")
	_teardown()
