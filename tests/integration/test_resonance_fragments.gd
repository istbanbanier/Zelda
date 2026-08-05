## P2-4e — Fragments de Résonance (bible §5) : trois propriétés FACULTATIVES,
## une par style, boss solvable sans. Fail-first : écrit avant l'implémentation.
##
## Contrats : trois identifiants connus seulement (l'inconnu est refusé), pas
## de doublon ; FLUX rembourse de l'endurance sur une mise à la terre d'une
## charge significative, avec cooldown ; ÉLAN conserve une portion BORNÉE de
## l'élan d'Arc Step à l'arrivée ; ÉCHO fait pointer le Pulse vers la dernière
## source sonore perçue — jamais vers son propre Pulse, jamais sans bruit.
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
	box.size = Vector3(80.0, 1.0, 80.0)
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
	state.charge_decay_enabled = false
	holder.add_child(state)
	state.add_charge(charge)
	return state


func _stamina() -> StaminaComponent:
	return _player.get_node("Components/StaminaComponent") as StaminaComponent


func test_only_the_three_known_fragments_are_grantable_once() -> void:
	if not _setup():
		check(false, "mise en scène impossible")
		return
	check(not _resonance.has_fragment(&"flux"), "rien au départ")
	check(_resonance.grant_fragment(&"flux"), "Flux accordé")
	check(_resonance.has_fragment(&"flux"), "…et détenu")
	check(not _resonance.grant_fragment(&"flux"), "jamais deux fois")
	check(not _resonance.grant_fragment(&"triche"), "l'inconnu est refusé")
	check(_resonance.grant_fragment(&"echo") and _resonance.grant_fragment(&"elan"),
		"les trois connus s'accordent")
	_teardown()


func test_flux_refunds_stamina_on_a_significant_grounding_with_cooldown() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var block_a: MaterialStateComponent = _charged_block(Vector3(0.0, 0.5, -2.0))
	var block_b: MaterialStateComponent = _charged_block(Vector3(0.0, 0.5, 2.0))
	for i: int in range(30):
		await tree.physics_frame
	# SANS le fragment : la terre ne rembourse rien.
	var pool: StaminaComponent = _stamina()
	pool.try_spend(50.0)
	var before: float = pool.current()
	check(_resonance.try_ground(_player, block_a) == &"grounding", "terre engagée")
	for i: int in range(30):
		await tree.physics_frame
	check(pool.current() <= before + 1.0,
		"sans Flux : aucun remboursement (%.0f → %.0f)" % [before, pool.current()])
	# AVEC : remboursement borné, puis cooldown.
	_resonance.grant_fragment(&"flux")
	before = pool.current()
	check(_resonance.try_ground(_player, block_b) == &"grounding", "seconde terre")
	for i: int in range(30):
		await tree.physics_frame
	check(pool.current() >= before + 10.0,
		"avec Flux : l'endurance revient (%.0f → %.0f)" % [before, pool.current()])
	# Cooldown : une troisième terre immédiate ne rembourse pas.
	var block_c: MaterialStateComponent = _charged_block(Vector3(2.0, 0.5, 0.0))
	await tree.physics_frame
	pool.try_spend(20.0)
	before = pool.current()
	check(_resonance.try_ground(_player, block_c) == &"grounding", "troisième terre")
	for i: int in range(30):
		await tree.physics_frame
	check(pool.current() <= before + 1.0,
		"cooldown : pas de second remboursement immédiat")
	_teardown()


func test_elan_keeps_a_bounded_part_of_the_dash_momentum() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var holder: Node3D = Node3D.new()
	_root.add_child(holder)
	holder.global_position = Vector3(0.0, 1.0, -8.0)
	var anchor: ResonanceTargetComponent = ResonanceTargetComponent.new()
	anchor.kind = &"arc_anchor"
	holder.add_child(anchor)
	for i: int in range(20):
		await tree.physics_frame
	# SANS : l'arrivée s'arrête net.
	check(_resonance.try_arc_step(_player, anchor) == &"step", "premier step")
	for i: int in range(60):
		await tree.physics_frame
	var speed_without: float = Vector2(_player.velocity.x, _player.velocity.z).length()
	check(speed_without < 1.0,
		"sans Élan : arrêt net à l'arrivée (%.2f m/s)" % speed_without)
	# AVEC : une portion BORNÉE survit à l'arrivée.
	_resonance.grant_fragment(&"elan")
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	var second: ResonanceTargetComponent = ResonanceTargetComponent.new()
	second.kind = &"arc_anchor"
	var second_holder: Node3D = Node3D.new()
	_root.add_child(second_holder)
	second_holder.global_position = Vector3(8.0, 1.0, 0.0)
	second_holder.add_child(second)
	for i: int in range(40):
		await tree.physics_frame
	check(_resonance.try_arc_step(_player, second) == &"step", "second step")
	var peak_after_arrival: float = 0.0
	var was_dashing: bool = false
	var arrived: bool = false
	for i: int in range(70):
		await tree.physics_frame
		var planar: float = Vector2(_player.velocity.x, _player.velocity.z).length()
		if planar > 12.0:
			was_dashing = true
		elif was_dashing and not arrived:
			arrived = true
		if arrived:
			peak_after_arrival = maxf(peak_after_arrival, planar)
	check(peak_after_arrival >= 2.0,
		"avec Élan : l'élan survit (%.2f m/s ≥ 2)" % peak_after_arrival)
	check(peak_after_arrival <= 10.0,
		"…mais BORNÉ (%.2f ≤ 10 — jamais l'élan complet du dash)" % peak_after_arrival)
	_teardown()


func test_echo_points_the_pulse_at_the_last_heard_noise_never_at_itself() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	_resonance.grant_fragment(&"echo")
	var traces: Array[Vector3] = []
	_resonance.echo_trace.connect(func(direction: Vector3) -> void:
		traces.append(direction))
	for i: int in range(20):
		await tree.physics_frame
	# Sans bruit récent : le Pulse ne trace rien (surtout pas son PROPRE bruit).
	check(_resonance.try_pulse(_player) == &"fired", "premier Pulse")
	await tree.physics_frame
	check(traces.is_empty(), "aucun bruit perçu : aucune trace — et jamais soi-même")
	# Un bruit au nord-est, puis Pulse : la trace pointe vers lui.
	NoiseEvents.emit(tree, Vector3(8.0, 1.0, -8.0), 30.0, &"impact")
	for i: int in range(100):
		await tree.physics_frame
	check(_resonance.try_pulse(_player) == &"fired", "second Pulse")
	await tree.physics_frame
	check(traces.size() == 1, "une trace émise")
	if traces.size() == 1:
		var expected: Vector3 = (Vector3(8.0, 1.0, -8.0)
			- _player.global_position).normalized()
		check(traces[0].dot(expected) > 0.95,
			"…qui pointe vers la source (dot %.2f)" % traces[0].dot(expected))
	_teardown()
