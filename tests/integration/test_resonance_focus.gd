## P2-2 — Focus/sélection du Bracelet (P2 §3.1/§3.8) : le maillon qui rend
## Arc Link, Polarité et Arc Step JOUABLES. Fail-first : écrit avant
## l'implémentation.
##
## Contrats : la sélection suit l'axe de visée (le plus proche de l'axe
## gagne), le cycle déplace la sélection, une cible occluse n'est jamais
## candidate ; la confirmation DISPATCHE selon la nature de la cible
## (ancrage → Arc Step, port → lien en deux temps, métal chargé → Polarité) ;
## sortir du focus oublie le port A en attente ; et pendant le focus, le clic
## de confirmation ne déclenche JAMAIS un coup d'épée.
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
	_root.add_child(_static_box(Vector3(0.0, -0.5, 0.0), Vector3(80.0, 1.0, 80.0)))
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


func _target_at(at: Vector3, kind: StringName) -> ResonanceTargetComponent:
	var holder: Node3D = Node3D.new()
	_root.add_child(holder)
	holder.global_position = at
	var component: ResonanceTargetComponent = ResonanceTargetComponent.new()
	component.kind = kind
	holder.add_child(component)
	return component


func _port_at(at: Vector3, id: StringName,
		kind: ElectricNode.Kind) -> ResonanceTargetComponent:
	var node: ElectricNode = ElectricNode.new()
	node.kind = kind
	node.node_id = id
	_root.add_child(node)
	node.global_position = at
	var component: ResonanceTargetComponent = ResonanceTargetComponent.new()
	component.kind = &"port"
	node.add_child(component)
	return component


func _aim(direction: Vector3) -> void:
	_resonance.focus_update(_player,
		_player.global_position + Vector3.UP * 1.4, direction.normalized())


func test_selection_follows_the_aim_axis_and_cycles() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var ahead: ResonanceTargetComponent = _target_at(Vector3(0.0, 1.0, -6.0), &"arc_anchor")
	var side: ResonanceTargetComponent = _target_at(Vector3(5.0, 1.0, -5.0), &"arc_anchor")
	for i: int in range(10):
		await tree.physics_frame
	_aim(Vector3.FORWARD)
	check(_resonance.focus_selected() == ahead,
		"l'axe de visée choisit la cible devant")
	_resonance.focus_cycle(1)
	check(_resonance.focus_selected() == side, "le cycle passe à la suivante")
	# La sélection au cycle SURVIT à la mise à jour suivante (hystérésis).
	_aim(Vector3.FORWARD)
	check(_resonance.focus_selected() == side,
		"hystérésis : la sélection choisie ne saute pas au premier update")
	_teardown()


func test_an_occluded_target_is_never_a_candidate() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	_root.add_child(_static_box(Vector3(0.0, 2.0, -3.0), Vector3(8.0, 4.0, 0.4)))
	var hidden: ResonanceTargetComponent = _target_at(Vector3(0.0, 1.0, -6.0), &"arc_anchor")
	for i: int in range(10):
		await tree.physics_frame
	_aim(Vector3.FORWARD)
	check(_resonance.focus_selected() == null,
		"cible derrière un mur : aucune sélection (jamais à travers, P2 §3.2)")
	_teardown()


func test_confirm_dispatches_arc_step_on_an_anchor() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var anchor: ResonanceTargetComponent = _target_at(Vector3(0.0, 1.0, -7.0), &"arc_anchor")
	for i: int in range(15):
		await tree.physics_frame
	_aim(Vector3.FORWARD)
	var verdict: StringName = _resonance.focus_confirm(_player, false)
	check(verdict == &"step", "confirmation sur ancrage → Arc Step (obtenu %s)" % verdict)
	for i: int in range(50):
		await tree.physics_frame
	check(_player.global_position.z < -4.0, "le dash a réellement eu lieu")
	_teardown()


func test_confirm_links_two_ports_in_two_steps_and_focus_end_forgets() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var source_port: ResonanceTargetComponent = _port_at(Vector3(-3.0, 1.0, -5.0),
		&"lab.focus.source.01", ElectricNode.Kind.SOURCE)
	var receiver_port: ResonanceTargetComponent = _port_at(Vector3(3.0, 1.0, -5.0),
		&"lab.focus.receiver.01", ElectricNode.Kind.RECEIVER)
	var graph: ElectricGraph = ElectricGraph.new()
	_root.add_child(graph)
	for i: int in range(10):
		await tree.physics_frame
	# Premier temps : viser le port source, confirmer.
	_aim(Vector3(-3.0, 0.0, -5.0))
	check(_resonance.focus_selected() == source_port, "port source visé")
	check(_resonance.focus_confirm(_player, false) == &"port_a",
		"premier port retenu comme extrémité A")
	# Sortir du focus OUBLIE l'extrémité A (P2 §3.8 : annulation lisible).
	_resonance.focus_end()
	_aim(Vector3(3.0, 0.0, -5.0))
	check(_resonance.focus_confirm(_player, false) == &"port_a",
		"après focus_end, tout recommence : ce port est un nouveau A")
	# Repartir de zéro pour la pose complète — l'A précédent est volontairement
	# oublié, sinon la confirmation suivante lierait immédiatement.
	_resonance.focus_end()
	# Deux temps complets : A puis B → lien réel, récepteur alimenté.
	_aim(Vector3(-3.0, 0.0, -5.0))
	if _resonance.focus_selected() != source_port:
		_resonance.focus_cycle(1)
	check(_resonance.focus_selected() == source_port, "re-viser la source")
	check(_resonance.focus_confirm(_player, false) == &"port_a", "A retenu")
	_aim(Vector3(3.0, 0.0, -5.0))
	if _resonance.focus_selected() != receiver_port:
		_resonance.focus_cycle(1)
	check(_resonance.focus_selected() == receiver_port, "viser le récepteur")
	check(_resonance.focus_confirm(_player, false) == &"linked", "B → lien posé")
	await tree.physics_frame
	await tree.physics_frame
	check((receiver_port.anchor() as ElectricNode).is_powered(),
		"le courant passe par le lien posé au focus")
	_teardown()


func test_confirm_engages_polarity_on_charged_metal() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var block: RigidBody3D = RigidBody3D.new()
	block.mass = 40.0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.8, 0.8, 0.8)
	shape.shape = box
	block.add_child(shape)
	var profile: MaterialProfile = MaterialProfile.new()
	profile.id = &"metal"
	profile.conductivity = 0.9
	profile.charge_capacity = 10.0
	var tags: Array[StringName] = [&"metal"]
	profile.tags = tags
	var state: MaterialStateComponent = MaterialStateComponent.new()
	state.profile = profile
	block.add_child(state)
	var marker: ResonanceTargetComponent = ResonanceTargetComponent.new()
	marker.kind = &"polarity"
	block.add_child(marker)
	_root.add_child(block)
	block.global_position = Vector3(0.0, 0.6, -6.0)
	state.add_charge(5.0)
	for i: int in range(10):
		await tree.physics_frame
	_aim(Vector3.FORWARD)
	check(_resonance.focus_selected() == marker, "bloc chargé visé")
	var verdict: StringName = _resonance.focus_confirm(_player, false)
	check(verdict == &"engaged", "confirmation → Polarité engagée (obtenu %s)" % verdict)
	check(_resonance.polarity_engaged(), "engagement actif")
	_teardown()


func test_while_focusing_the_confirm_click_never_swings_the_sword() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var anchor: ResonanceTargetComponent = _target_at(Vector3(0.0, 1.0, -7.0), &"arc_anchor")
	for i: int in range(15):
		await tree.physics_frame
	# Chaîne d'INTENT réelle : focus tenu + clic d'attaque.
	_intent.focus_held = true
	_intent.attack_pressed = true
	await tree.physics_frame
	await tree.physics_frame
	_intent.attack_pressed = false
	_intent.focus_held = false
	check(_player.mode() != PlayerController.Mode.ATTACKING,
		"le clic en focus CONFIRME, il ne frappe pas (aucun coup d'épée)")
	_teardown()
