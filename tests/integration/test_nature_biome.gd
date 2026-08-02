## ART-Q4 — biome nature composé : la forêt porte les VRAIS arbres sur les
## collisions de tronc INCHANGÉES (la preuve de navigation ne bouge pas),
## et les « phrases » végétales (§7.17) posent buissons/galets/rochers en
## groupes délibérés — jamais une dispersion uniforme, jamais une boîte à
## la place d'un asset manquant.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"

var _valley: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _load_valley() -> void:
	_valley = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_valley)
	await _settle(5)


func _unload_valley() -> void:
	_valley.get_parent().remove_child(_valley)
	_valley.queue_free()
	_valley = null
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


func test_the_forest_mounts_real_trees_on_the_same_trunk_collisions() -> void:
	## Douze arbres de production, maillages réels, variation de lacet et
	## d'échelle — et DOUZE collisions de tronc toujours en place : le
	## navmesh n'a aucune raison de bouger.
	await _load_valley()
	var forest: Node3D = _valley.find_children("Forest", "Node3D", true,
		false)[0] as Node3D
	var trees: Array[Node] = []
	var collisions: int = 0
	for child: Node in forest.get_children():
		if String(child.name).begins_with("Tree"):
			trees.append(child)
		if child is StaticBody3D:
			collisions += 1
	check_equal(trees.size(), 12, "douze arbres de production")
	check_equal(collisions, 12, "douze collisions de tronc INTACTES")
	var yaws: Dictionary = {}
	var scales: Dictionary = {}
	for tree: Node in trees:
		var node: Node3D = tree as Node3D
		var has_mesh: bool = false
		for mesh: Node in node.find_children("*", "MeshInstance3D", true, false):
			if (mesh as MeshInstance3D).mesh != null:
				has_mesh = true
		check(has_mesh, "%s : maillage réel" % tree.name)
		yaws[snappedf(node.rotation.y, 0.001)] = true
		scales[snappedf(node.scale.x, 0.001)] = true
	check(yaws.size() >= 10, "lacets variés (%d distincts)" % yaws.size())
	check(scales.size() >= 8, "échelles variées (%d distinctes)" % scales.size())
	for i: int in range(12):
		var canopy: Node = forest.get_node_or_null("Canopy%02d" % i)
		check(canopy == null, "plus aucune couronne graybox (%02d)" % i)
	await _unload_valley()


func test_the_nature_phrases_are_grouped_not_uniform() -> void:
	## Les phrases végétales existent (buissons, galets, rochers réels), les
	## rochers bloquent, et les placements forment des GROUPES : la distance
	## au plus proche voisin varie fortement — signature d'une composition,
	## pas d'une grille.
	await _load_valley()
	var phrases: Node3D = _valley.find_children("NaturePhrases", "Node3D",
		true, false)[0] as Node3D
	var props: Array[Node3D] = []
	for child: Node in phrases.get_children():
		props.append(child as Node3D)
	check_equal(props.size(), 12, "les douze éléments de phrase sont livrés")
	var rocks_with_collision: int = 0
	for prop: Node3D in props:
		var has_mesh: bool = false
		for mesh: Node in prop.find_children("*", "MeshInstance3D", true, false):
			if (mesh as MeshInstance3D).mesh != null:
				has_mesh = true
		check(has_mesh, "%s : maillage réel" % prop.name)
		if String(prop.name).contains("rock") \
				and not prop.find_children("*", "CollisionShape3D", true,
					false).is_empty():
			rocks_with_collision += 1
	check_equal(rocks_with_collision, 2, "les deux rochers sont des obstacles")
	# Composition : voisin le plus proche entre 1 m (grappe) et > 15 m
	# (vide entre groupes) — une grille uniforme n'a pas cette variance.
	var nearest: Array[float] = []
	for a: Node3D in props:
		var best: float = INF
		for b: Node3D in props:
			if a != b:
				best = minf(best, a.position.distance_to(b.position))
		nearest.append(best)
	nearest.sort()
	check(nearest[0] < 3.0, "des éléments SERRÉS existent (%.1f m)" % nearest[0])
	check(nearest[nearest.size() - 1] > 15.0,
		"de vrais VIDES séparent les groupes (%.1f m)" % nearest[nearest.size() - 1])
	await _unload_valley()
