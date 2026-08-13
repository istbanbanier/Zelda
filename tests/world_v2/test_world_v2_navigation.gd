## V2.1 — la NAVIGATION est cuite, versionnée, bornée par quadrant, et RELIE
## réellement les ancres du monde.
##
## Ce que chaque garde empêche :
##   - un quadrant vide ou presque vide = le bug exact du premier bake (le
##     parse des maillages visuels rendait 2 polygones en headless) ;
##   - un quadrant qui déborde son emprise = un `filter_baking_aabb` ignoré,
##     et la promesse « par région » devient un seul bloc sous un autre nom ;
##   - un chemin spawn → porte impossible = un monde dont les régions ne se
##     raccordent pas à leurs frontières ;
##   - un lac « accessible » = le bol n'est plus une île de navigation.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const NAV_PATTERN: String = "res://resources/world_v2/nav/world_v2_navmesh_q%d.tres"
## Un quadrant réel porte des CENTAINES de polygones ; un bake réduit aux
## seules crêtes des gardes en porterait ~20. Le plancher tranche entre les
## deux sans épingler un compte exact fragile.
const MIN_POLYGONS_PER_QUADRANT: int = 50
const QUADRANT_EXTENT: float = 256.0
const AABB_MARGIN_M: float = 2.0
## Un chemin réel serpente (gués, rampe) ; au-delà de ce multiple du vol
## d'oiseau, la connexion passe par un détour absurde.
const MAX_PATH_STRETCH: float = 3.0

var _world: Node3D = null


func test_les_quatre_quadrants_sont_cuits_et_bornes() -> void:
	var faults: Array[String] = []
	for quadrant: int in range(4):
		var path: String = NAV_PATTERN % quadrant
		if not ResourceLoader.exists(path):
			faults.append("quadrant %d ABSENT (%s)" % [quadrant, path])
			continue
		var mesh: NavigationMesh = load(path) as NavigationMesh
		if mesh == null:
			faults.append("quadrant %d illisible" % quadrant)
			continue
		if mesh.get_polygon_count() < MIN_POLYGONS_PER_QUADRANT:
			faults.append("quadrant %d quasi vide : %d polygone(s)"
				% [quadrant, mesh.get_polygon_count()])
		# Emprise : chaque sommet reste dans SON quadrant (le découpage par
		# région est réel, pas décoratif).
		var min_x: float = -QUADRANT_EXTENT + QUADRANT_EXTENT * float(quadrant % 2)
		var min_z: float = -QUADRANT_EXTENT + QUADRANT_EXTENT * float(quadrant / 2)
		for vertex: Vector3 in mesh.get_vertices():
			if vertex.x < min_x - AABB_MARGIN_M \
					or vertex.x > min_x + QUADRANT_EXTENT + AABB_MARGIN_M \
					or vertex.z < min_z - AABB_MARGIN_M \
					or vertex.z > min_z + QUADRANT_EXTENT + AABB_MARGIN_M:
				faults.append("quadrant %d déborde en (%.0f, %.0f)"
					% [quadrant, vertex.x, vertex.z])
				break
	check(faults.is_empty(), "quatre quadrants cuits et bornés — %s"
		% " ; ".join(faults))


func test_la_navigation_relie_les_ancres_mais_pas_le_lac() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame

	var regions: Array[Node] = (_world.get_node("Navigation") as Node3D).get_children()
	check_equal(regions.size(), 4, "quatre régions de navigation montées")

	var map: RID = _world.get_world_3d().navigation_map
	# La carte se synchronise au rythme physique — on force l'itération pour
	# ne pas dépendre d'un nombre de frames deviné.
	NavigationServer3D.map_force_update(map)
	await loop.physics_frame

	var faults: Array[String] = []
	var legs: Array[Array] = [
		["spawn → camp", Vector3(0, 24, 170), Vector3(45, 6, 65)],
		["camp → pylône", Vector3(45, 6, 65), Vector3(115, 18, -25)],
		["pylône → porte", Vector3(115, 18, -25), Vector3(0, 34, -210)],
		["spawn → porte", Vector3(0, 24, 170), Vector3(0, 34, -210)],
	]
	for leg: Array in legs:
		var label: String = String(leg[0])
		var from: Vector3 = leg[1] as Vector3
		var to: Vector3 = leg[2] as Vector3
		var path: PackedVector3Array = NavigationServer3D.map_get_path(
			map, from, to, true)
		if path.size() < 2:
			faults.append("%s : aucun chemin" % label)
			continue
		var arrival: float = Vector2(path[path.size() - 1].x, path[path.size() - 1].z) \
			.distance_to(Vector2(to.x, to.z))
		if arrival > 4.0:
			faults.append("%s : le chemin s'arrête à %.1f m du but" % [label, arrival])
		var length: float = 0.0
		for i: int in range(path.size() - 1):
			length += path[i].distance_to(path[i + 1])
		var crow: float = Vector2(from.x, from.z).distance_to(Vector2(to.x, to.z))
		if length > crow * MAX_PATH_STRETCH + 40.0:
			faults.append("%s : détour absurde (%.0f m pour %.0f m à vol d'oiseau)"
				% [label, length, crow])
	check(faults.is_empty(), "les ancres sont reliées par la navigation — %s"
		% " ; ".join(faults))

	# Le bol du lac est une ÎLE de navigation voulue : un chemin qui vise son
	# centre doit s'arrêter à la rive, jamais descendre dans le bol.
	var heightmap: WorldV2Heightmap = _world.call("heightmap") as WorldV2Heightmap
	var lake: Vector2 = heightmap.lake_center()
	var lake_path: PackedVector3Array = NavigationServer3D.map_get_path(
		map, Vector3(0, 24, 170), Vector3(lake.x, -5.0, lake.y), true)
	check(lake_path.size() >= 2, "un chemin part bien vers le lac")
	if lake_path.size() >= 2:
		var stop: Vector3 = lake_path[lake_path.size() - 1]
		check(Vector2(stop.x, stop.z).distance_to(lake) > 5.0,
			"…et s'arrête à la rive (%.1f m du centre), le bol reste une île"
				% Vector2(stop.x, stop.z).distance_to(lake))

	var clean: bool = await restore_root()
	check(clean, "démontage propre — %s" % restore_root_reason())
	restore_saves()
