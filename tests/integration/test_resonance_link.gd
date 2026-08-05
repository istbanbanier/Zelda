## P2-2 — Arc Link (P2 §3.3) : un lien temporaire entre deux ports, injecté
## comme nœud CABLE dans le graphe électrique EXISTANT — la propagation, les
## cycles et l'idempotence sont ceux du Gate F, pas une seconde logique.
##
## Fail-first : écrit avant `ResonanceLinkNode` et `try_link`. Contrats :
## le lien TRANSPORTE (source active → récepteur alimenté), il ne CRÉE jamais
## d'énergie (source coupée → rien) ; un seul lien actif (le nouveau remplace
## l'ancien) ; port détruit → dissolution sûre au tick suivant ; refus
## explicables (hors portée joueur, ports trop écartés, pas de ligne de vue).
extends GateTestCase

var _root: Node3D = null
var _graph: ElectricGraph = null
var _body: CharacterBody3D = null
var _resonance: ResonanceController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	_graph = null
	_body = null
	_resonance = null


func _setup() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	_graph = ElectricGraph.new()
	_root.add_child(_graph)
	_body = CharacterBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = CapsuleShape3D.new()
	_body.add_child(shape)
	_root.add_child(_body)
	_body.global_position = Vector3(3.0, 1.0, 0.0)
	_resonance = ResonanceController.new()
	_root.add_child(_resonance)


func _node(kind: ElectricNode.Kind, id: StringName, at: Vector3,
		active: bool = true) -> ElectricNode:
	var node: ElectricNode = ElectricNode.new()
	node.kind = kind
	node.node_id = id
	node.enabled = active
	_root.add_child(node)
	node.global_position = at
	return node


func test_a_link_bridges_a_gap_and_powers_the_receiver() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var source: ElectricNode = _node(ElectricNode.Kind.SOURCE, &"lab.link.source.01", Vector3.ZERO)
	var receiver: ElectricNode = _node(ElectricNode.Kind.RECEIVER, &"lab.link.receiver.01",
		Vector3(6.0, 0.0, 0.0))
	await tree.physics_frame
	await tree.physics_frame
	check(not receiver.is_powered(), "préalable : 6 m sans lien = récepteur éteint")
	var verdict: StringName = _resonance.try_link(_body, source, receiver)
	check(verdict == &"linked", "verdict : linked (obtenu %s)" % verdict)
	await tree.physics_frame
	await tree.physics_frame
	check(receiver.is_powered(), "le lien transporte : récepteur alimenté")
	_teardown()


func test_a_link_never_creates_energy() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var source: ElectricNode = _node(ElectricNode.Kind.SOURCE, &"lab.link.source.02",
		Vector3.ZERO, false)
	var receiver: ElectricNode = _node(ElectricNode.Kind.RECEIVER, &"lab.link.receiver.02",
		Vector3(6.0, 0.0, 0.0))
	await tree.physics_frame
	await tree.physics_frame
	var verdict: StringName = _resonance.try_link(_body, source, receiver)
	check(verdict == &"linked", "le lien se pose aussi sur une source éteinte")
	await tree.physics_frame
	await tree.physics_frame
	check(not receiver.is_powered(),
		"source coupée + lien = récepteur ÉTEINT (le lien transporte, il ne crée pas)")
	_teardown()


func test_only_one_link_the_new_one_replaces_the_old() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var source: ElectricNode = _node(ElectricNode.Kind.SOURCE, &"lab.link.source.03", Vector3.ZERO)
	var receiver_a: ElectricNode = _node(ElectricNode.Kind.RECEIVER, &"lab.link.receiver.03a",
		Vector3(6.0, 0.0, 0.0))
	var receiver_b: ElectricNode = _node(ElectricNode.Kind.RECEIVER, &"lab.link.receiver.03b",
		Vector3(0.0, 0.0, 6.0))
	await tree.physics_frame
	await tree.physics_frame
	check(_resonance.try_link(_body, source, receiver_a) == &"linked", "premier lien posé")
	await tree.physics_frame
	await tree.physics_frame
	check(receiver_a.is_powered(), "récepteur A alimenté")
	check(_resonance.try_link(_body, source, receiver_b) == &"linked", "second lien posé")
	await tree.physics_frame
	await tree.physics_frame
	check(not receiver_a.is_powered(), "l'ancien lien est dissous : A éteint")
	check(receiver_b.is_powered(), "le nouveau transporte : B alimenté")
	check(tree.get_nodes_in_group(&"resonance_links").size() == 1,
		"UN seul lien actif dans l'arbre (P2 §3.3)")
	_teardown()


func test_a_destroyed_port_dissolves_the_link_safely() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var source: ElectricNode = _node(ElectricNode.Kind.SOURCE, &"lab.link.source.04", Vector3.ZERO)
	var receiver: ElectricNode = _node(ElectricNode.Kind.RECEIVER, &"lab.link.receiver.04",
		Vector3(6.0, 0.0, 0.0))
	await tree.physics_frame
	await tree.physics_frame
	check(_resonance.try_link(_body, source, receiver) == &"linked", "lien posé")
	await tree.physics_frame
	receiver.get_parent().remove_child(receiver)
	receiver.free()
	await tree.physics_frame
	await tree.physics_frame
	check(tree.get_nodes_in_group(&"resonance_links").is_empty(),
		"port détruit → lien dissous, sans crash (P2 §3.3 : annulation sûre)")
	check(_resonance.active_link() == null, "le contrôleur a lâché sa référence")
	_teardown()


func test_refusals_are_explained() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var source: ElectricNode = _node(ElectricNode.Kind.SOURCE, &"lab.link.source.05", Vector3.ZERO)
	var receiver_far: ElectricNode = _node(ElectricNode.Kind.RECEIVER, &"lab.link.receiver.05",
		Vector3(20.0, 0.0, 0.0))
	await tree.physics_frame
	# Ports écartés de 20 m > portée du lien.
	_body.global_position = Vector3(10.0, 1.0, 0.0)
	check(_resonance.try_link(_body, source, receiver_far) == &"trop_loin",
		"ports trop écartés : trop_loin")
	# Joueur trop loin des ports.
	_body.global_position = Vector3(60.0, 1.0, 0.0)
	check(_resonance.try_link(_body, source, receiver_far) == &"hors_portee",
		"joueur hors de portée de sélection : hors_portee")
	check(tree.get_nodes_in_group(&"resonance_links").is_empty(), "aucun lien posé")
	_teardown()


func test_a_wall_between_ports_refuses_the_link() -> void:
	var tree: SceneTree = _tree()
	_setup()
	var source: ElectricNode = _node(ElectricNode.Kind.SOURCE, &"lab.link.source.06", Vector3.ZERO)
	var receiver: ElectricNode = _node(ElectricNode.Kind.RECEIVER, &"lab.link.receiver.06",
		Vector3(6.0, 0.0, 0.0))
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.4, 6.0, 8.0)
	shape.shape = box
	wall.add_child(shape)
	_root.add_child(wall)
	wall.global_position = Vector3(3.0, 0.0, 0.0)
	_body.global_position = Vector3(3.0, 1.0, 5.0)
	await tree.physics_frame
	check(_resonance.try_link(_body, source, receiver) == &"pas_de_vue",
		"mur entre les ports : pas_de_vue (P2 §3.3 — ligne de vue obligatoire)")
	check(tree.get_nodes_in_group(&"resonance_links").is_empty(), "aucun lien posé")
	_teardown()
