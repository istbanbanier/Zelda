## P2-4d — Placement du bassin conducteur (route de la rivière).
## Fail-first : écrit avant l'implantation. Site (16, 2, 28) sondé plat
## (`probe_bridge_site.gd`, campagne du bassin) ; lieu déclaré §19.3 avec
## ancrage PUZZLE — un lieu sans récompense est interdit (§3).
extends GateTestCase

const SITE: Vector3 = Vector3(16.0, 2.0, 28.0)

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null


func test_the_basin_stands_on_the_river_route_as_a_declared_place() -> void:
	var tree: SceneTree = _tree()
	_root = Node3D.new()
	tree.root.add_child(_root)
	var relics: Node3D = ValleyRelics.new()
	_root.add_child(relics)
	await tree.physics_frame
	var site: Node3D = relics.get_node_or_null("BassinConducteur") as Node3D
	check(site != null, "le site du bassin existe")
	if site == null:
		_teardown()
		return
	check(site.position.distance_to(SITE) < 0.1, "posé au site sondé (16, 2, 28)")
	var basin: ConductiveBasin = null
	for child: Node in site.get_children():
		if child is ConductiveBasin:
			basin = child as ConductiveBasin
	check(basin != null, "le diorama ConductiveBasin est monté")
	if basin == null:
		_teardown()
		return
	check(not basin.receiver().is_powered(), "à découvrir : le circuit attend")
	var poi_found: bool = false
	for poi: PointOfInterest in relics.pois:
		if poi.poi_id == &"valley.poi.conductive_basin.01":
			poi_found = true
	check(poi_found, "POI valley.poi.conductive_basin.01 déclaré")
	check(site.find_children("*", "RewardAnchor", true, false).size() >= 1,
		"un ancrage de récompense est posé")
	_teardown()
