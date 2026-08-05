## P2-2 — ResonanceLab (P2 §14.2) : la scène-vitrine des cinq opérations.
##
## Fail-first : écrit avant la scène. Test STRUCTUREL : le lab charge sans
## erreur et contient tout ce qu'il faut pour exercer chaque opération à la
## main — les contrats des opérations elles-mêmes ont leurs propres suites.
extends GateTestCase

const LAB: String = "res://scenes/tests/ResonanceLab.tscn"

var _lab: Node = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _lab != null and is_instance_valid(_lab):
		_lab.get_parent().remove_child(_lab)
		_lab.queue_free()
	_lab = null


func test_the_lab_loads_and_offers_every_operation() -> void:
	var tree: SceneTree = _tree()
	var scene: PackedScene = load(LAB) as PackedScene
	check(scene != null, "la scène du lab existe")
	if scene == null:
		return
	_lab = scene.instantiate()
	tree.root.add_child(_lab)
	for i: int in range(30):
		await tree.physics_frame

	var player: PlayerController = \
		tree.get_first_node_in_group(&"player") as PlayerController
	check(player != null, "un joueur jouable est présent")
	if player != null:
		check(player.get_node_or_null("Components/ResonanceController") != null,
			"le joueur porte le Bracelet")

	var targets: Array[Node] = tree.get_nodes_in_group(&"resonance_targets")
	var kinds: Dictionary = {}
	for node: Node in targets:
		var target: ResonanceTargetComponent = node as ResonanceTargetComponent
		if target != null:
			kinds[target.kind] = int(kinds.get(target.kind, 0)) + 1
	check(int(kinds.get(&"material", 0)) + int(kinds.get(&"arc_anchor", 0)) \
			+ int(kinds.get(&"port", 0)) + int(kinds.get(&"polarity", 0)) >= 6,
		"au moins six cibles de Résonance au total")
	check(int(kinds.get(&"port", 0)) >= 2, "au moins deux ports pour l'Arc Link")
	check(int(kinds.get(&"arc_anchor", 0)) >= 1, "au moins un ancrage Arc Step")
	check(int(kinds.get(&"polarity", 0)) >= 1, "au moins un bloc de Polarité")

	var graphs: Array[Node] = tree.get_nodes_in_group(&"electric_graphs")
	check(not graphs.is_empty(), "un graphe électrique arbitre la zone Link")

	var states: Array[Node] = tree.get_nodes_in_group(&"material_states")
	var charged: int = 0
	for node: Node in states:
		var state: MaterialStateComponent = node as MaterialStateComponent
		if state != null and state.is_charged():
			charged += 1
	check(charged >= 2, "au moins deux objets chargés (Polarité + Ground)")
	_teardown()
