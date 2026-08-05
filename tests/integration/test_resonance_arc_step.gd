## P2-2 — Arc Step (P2 §3.5) : dash physique court vers un ancrage valide.
##
## Fail-first : écrit avant l'implémentation. Interdits durs testés : jamais à
## travers un mur (sweep de capsule sur TOUT le trajet), jamais d'arrivée sans
## sol, coût d'endurance payé à l'exécution seulement (un refus ne coûte rien),
## cooldown, ancrage détruit refusé. Le dash est un MOUVEMENT (vitesse +
## move_and_slide), pas un téléport : la position progresse continûment.
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


func _setup(floor_size: Vector3 = Vector3(80.0, 1.0, 80.0),
		floor_at: Vector3 = Vector3(0.0, -0.5, 0.0)) -> bool:
	var tree: SceneTree = _tree()
	if tree == null:
		return false
	_root = Node3D.new()
	tree.root.add_child(_root)
	_root.add_child(_static_box(floor_at, floor_size))
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


func _anchor_at(at: Vector3) -> ResonanceTargetComponent:
	var holder: Node3D = Node3D.new()
	_root.add_child(holder)
	holder.global_position = at
	var component: ResonanceTargetComponent = ResonanceTargetComponent.new()
	component.kind = &"arc_anchor"
	holder.add_child(component)
	return component


func _stamina() -> StaminaComponent:
	return _player.get_node("Components/StaminaComponent") as StaminaComponent


func test_the_dash_reaches_the_anchor_pays_stamina_and_never_jumps() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var anchor: ResonanceTargetComponent = _anchor_at(Vector3(0.0, 1.0, -8.0))
	for i: int in range(20):
		await tree.physics_frame
	var stamina_before: float = _stamina().current()
	var verdict: StringName = _resonance.try_arc_step(_player, anchor)
	check(verdict == &"step", "verdict : step (obtenu %s)" % verdict)
	var previous: Vector3 = _player.global_position
	var max_step: float = 0.0
	for i: int in range(60):
		await tree.physics_frame
		max_step = maxf(max_step, _player.global_position.distance_to(previous))
		previous = _player.global_position
	var gap: float = Vector2(_player.global_position.x - 0.0,
		_player.global_position.z - (-8.0)).length()
	check(gap < 1.6, "arrivé près de l'ancrage (reste %.2f m)" % gap)
	var dt: float = 1.0 / float(Engine.physics_ticks_per_second)
	check(max_step <= (ResonanceController.ARC_STEP_SPEED + 4.0) * dt,
		"mouvement continu, jamais un saut (max %.3f m/tick)" % max_step)
	check(_stamina().current() <= stamina_before - 19.0,
		"coût d'endurance payé (%.0f → %.0f)" % [stamina_before, _stamina().current()])
	_teardown()


func test_a_wall_on_the_path_refuses_without_cost() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	_root.add_child(_static_box(Vector3(0.0, 2.0, -4.0), Vector3(10.0, 4.0, 0.5)))
	var anchor: ResonanceTargetComponent = _anchor_at(Vector3(0.0, 1.0, -8.0))
	for i: int in range(20):
		await tree.physics_frame
	var stamina_before: float = _stamina().current()
	var at_before: Vector3 = _player.global_position
	check(_resonance.try_arc_step(_player, anchor) == &"obstacle",
		"mur sur le trajet : obstacle (P2 §3.5 — jamais à travers)")
	for i: int in range(10):
		await tree.physics_frame
	check(_player.global_position.distance_to(at_before) < 0.5, "pas de dash")
	check(absf(_stamina().current() - stamina_before) < 1.0,
		"un refus ne coûte RIEN (P2 §3.5)")
	_teardown()


func test_range_stamina_cooldown_and_destroyed_anchor_are_refused() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var near_anchor: ResonanceTargetComponent = _anchor_at(Vector3(0.0, 1.0, -6.0))
	var far_anchor: ResonanceTargetComponent = _anchor_at(Vector3(0.0, 1.0, -30.0))
	for i: int in range(20):
		await tree.physics_frame
	check(_resonance.try_arc_step(_player, far_anchor) == &"hors_portee",
		"30 m : hors_portee")
	# Ancrage retiré du monde (détruit) — détaché de l'arbre, PAS libéré :
	# un objet libéré ne peut même pas franchir un paramètre typé, et le vrai
	# flux ne garde jamais de référence morte (sélection par appel).
	var dead: ResonanceTargetComponent = _anchor_at(Vector3(3.0, 1.0, 0.0))
	var dead_holder: Node3D = dead.anchor()
	dead_holder.get_parent().remove_child(dead_holder)
	check(_resonance.try_arc_step(_player, dead) == &"invalide",
		"ancrage hors du monde : invalide")
	dead_holder.queue_free()
	# Endurance insuffisante : vider la jauge par l'API normale.
	var pool: StaminaComponent = _stamina()
	pool.try_spend(pool.current())
	check(_resonance.try_arc_step(_player, near_anchor) == &"endurance",
		"jauge vide : endurance")
	_teardown()


func test_cooldown_refuses_then_recovers() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var anchor_a: ResonanceTargetComponent = _anchor_at(Vector3(0.0, 1.0, -7.0))
	for i: int in range(20):
		await tree.physics_frame
	check(_resonance.try_arc_step(_player, anchor_a) == &"step", "premier step")
	await tree.physics_frame
	var anchor_b: ResonanceTargetComponent = _anchor_at(Vector3(4.0, 1.0, -7.0))
	check(_resonance.try_arc_step(_player, anchor_b) == &"cooldown",
		"ré-appui immédiat : cooldown")
	# Fin du dash + cooldown (0,35 s) largement passés.
	for i: int in range(120):
		await tree.physics_frame
	check(_resonance.try_arc_step(_player, anchor_b) == &"step",
		"après cooldown : repart")
	_teardown()


func test_an_anchor_over_a_void_is_refused_no_landing_ground() -> void:
	var tree: SceneTree = _tree()
	# Sol court : le vide commence à z = -5.
	if not _setup(Vector3(20.0, 1.0, 10.0), Vector3(0.0, -0.5, 0.0)):
		check(false, "mise en scène impossible")
		return
	var over_void: ResonanceTargetComponent = _anchor_at(Vector3(0.0, 1.0, -9.0))
	for i: int in range(20):
		await tree.physics_frame
	check(_resonance.try_arc_step(_player, over_void) == &"pas_de_sol",
		"ancrage au-dessus du vide : pas_de_sol (P2 §3.5 — validation d'arrivée)")
	_teardown()
