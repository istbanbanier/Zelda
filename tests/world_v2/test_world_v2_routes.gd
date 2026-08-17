## V2.1 — les ROUTES sont un sol physique continu, pas des lignes sur la carte.
##
## Le trajet est sondé AU SOL PHYSIQUE (rayons, masque 1) mètre par mètre :
## le tablier du pont magnétique compte comme sol — la fonction de hauteur
## seule dirait que la route de la rivière tombe dans le bras nord (contrôle
## négatif B : retirer la collision du tablier doit rougir ICI en nommant la
## route et l'endroit).
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
## Même littéral que le test du terrain : aucune marche verticale artificielle.
const MAX_STEP_PER_METRE: float = 1.3
const ROUTE_NAMES: Array[String] = ["main_path", "river_route", "heights_route",
	"ruins_route"]

var _world: Node3D = null


func test_chaque_route_a_un_sol_physique_continu() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame
	var space: PhysicsDirectSpaceState3D = _world.get_world_3d().direct_space_state

	# Les waypoints sont lus sur les NŒUDS INSPECTABLES (métadonnées), pas
	# rechargés du JSON : le test juge ce que le monde monté porte vraiment.
	var routes: Dictionary = {}
	for node: Node in loop.get_nodes_in_group(&"world_v2_routes"):
		routes[String(node.name)] = node.get_meta(&"waypoints_xz", []) as Array
	var faults: Array[String] = []
	for route_name: String in ROUTE_NAMES:
		if not routes.has(route_name):
			faults.append("route absente : %s" % route_name)
			continue
		var waypoints: Array = routes[route_name] as Array
		if waypoints.size() < 4:
			faults.append("%s n'a que %d waypoints" % [route_name, waypoints.size()])
			continue
		var worst_step: float = 0.0
		var worst_at: Vector2 = Vector2.ZERO
		for i: int in range(waypoints.size() - 1):
			var a: Vector2 = Vector2(float((waypoints[i] as Array)[0]),
				float((waypoints[i] as Array)[1]))
			var b: Vector2 = Vector2(float((waypoints[i + 1] as Array)[0]),
				float((waypoints[i + 1] as Array)[1]))
			var steps: int = maxi(2, int(a.distance_to(b)))
			var previous: float = _floor_y(space, a)
			if previous <= -100.0:
				faults.append("%s : aucun sol au waypoint (%.0f, %.0f)"
					% [route_name, a.x, a.y])
				continue
			for s: int in range(1, steps + 1):
				var p: Vector2 = a.lerp(b, float(s) / float(steps))
				var floor_y: float = _floor_y(space, p)
				if floor_y <= -100.0:
					faults.append("%s : trou de sol en (%.0f, %.0f)"
						% [route_name, p.x, p.y])
					break
				if absf(floor_y - previous) > worst_step:
					worst_step = absf(floor_y - previous)
					worst_at = p
				previous = floor_y
		if worst_step > MAX_STEP_PER_METRE:
			faults.append("%s : marche de %.2f m/m en (%.0f, %.0f)"
				% [route_name, worst_step, worst_at.x, worst_at.y])
	check(faults.is_empty(),
		"chaque route est un sol continu praticable — %s" % " ; ".join(faults))

	# Les quatre raccourcis annoncés existent et disent ce qu'ils relient.
	var shortcuts: Array[Node] = loop.get_nodes_in_group(&"world_v2_shortcuts")
	check_equal(shortcuts.size(), 4, "quatre raccourcis inspectables")
	for shortcut: Node in shortcuts:
		var links: Array = shortcut.get_meta(&"links", []) as Array
		check(links.size() == 2, "%s relie deux lieux" % shortcut.name)

	var clean: bool = await restore_root()
	check(clean, "démontage propre — %s" % restore_root_reason())
	restore_saves()


## Premier sol PHYSIQUE (masque 1) sous (x, z) — -1000 si aucun.
func _floor_y(space: PhysicsDirectSpaceState3D, p: Vector2) -> float:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(p.x, 200.0, p.y), Vector3(p.x, -60.0, p.y), 1)
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return -1000.0
	return (hit["position"] as Vector3).y
