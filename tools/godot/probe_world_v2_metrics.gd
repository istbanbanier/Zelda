## Sonde de MÉTRIQUES World V2 (V2.1) — manifeste JSON pour `evidence/`.
##
## Usage :
##   godot --headless --path . --script tools/godot/probe_world_v2_metrics.gd \
##     > evidence/world_v2/v2_1/metrics_world_v2.json
##
## Tout vient du monde MONTÉ et de la fonction de hauteur réelle — aucune
## valeur recopiée à la main. La sonde ne modifie rien ; elle imprime un seul
## document JSON sur stdout (les diagnostics du montage partent sur stderr
## via print_rich? non : ils restent des print — d'où le marqueur BEGIN/END
## pour l'extraction).
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"
const ANCHORS: Dictionary = {
	"spawn": Vector3(0, 24, 170),
	"camp": Vector3(45, 6, 65),
	"pylone": Vector3(115, 18, -25),
	"porte_du_donjon": Vector3(0, 34, -210),
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var build_start: int = Time.get_ticks_msec()
	var world: Node3D = (load(WORLD) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	await process_frame
	await physics_frame
	var build_ms: int = Time.get_ticks_msec() - build_start
	var heightmap: RefCounted = world.call("heightmap")
	var layout: Dictionary = world.call("layout")

	var doc: Dictionary = {}
	doc["monde"] = String(world.get("WORLD_ID"))
	doc["montage_ms"] = build_ms

	# --- Terrain.
	var flat: int = 0
	var total: int = 0
	for z: int in range(-230, 231, 6):
		for x: int in range(-230, 231, 6):
			if Vector2(float(x), float(z)).length() >= 235.0:
				continue
			total += 1
			if float(heightmap.call("slope_deg_at", float(x), float(z))) < 1.0:
				flat += 1
	doc["terrain"] = {
		"chunks": get_nodes_in_group(&"world_v2_terrain").size(),
		"plat_sous_1_deg_pct": snappedf(100.0 * float(flat) / float(maxi(total, 1)), 0.1),
		"echantillons": total,
	}

	# --- Ancres §3.3 : hauteur réelle, pente, sol physique.
	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var anchors_doc: Dictionary = {}
	for anchor_name: String in ANCHORS:
		var wanted: Vector3 = ANCHORS[anchor_name] as Vector3
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			Vector3(wanted.x, 200.0, wanted.z), Vector3(wanted.x, -60.0, wanted.z), 1)
		var hit: Dictionary = space.intersect_ray(query)
		anchors_doc[anchor_name] = {
			"contractuel": [wanted.x, wanted.y, wanted.z],
			"hauteur_fonction": snappedf(
				float(heightmap.call("height_at", wanted.x, wanted.z)), 0.001),
			"pente_deg": snappedf(
				float(heightmap.call("slope_deg_at", wanted.x, wanted.z)), 0.1),
			"sol_physique_y": snappedf((hit["position"] as Vector3).y, 0.001) \
				if not hit.is_empty() else null,
			"collider": String((hit["collider"] as Node).name) \
				if not hit.is_empty() else null,
		}
	doc["ancres"] = anchors_doc

	# --- Routes : longueur et pire marche analytique au mètre.
	var routes_doc: Dictionary = {}
	for node: Node in get_nodes_in_group(&"world_v2_routes"):
		var waypoints: Array = node.get_meta(&"waypoints_xz", []) as Array
		var length: float = 0.0
		var worst: float = 0.0
		var worst_at: Vector2 = Vector2.ZERO
		for i: int in range(waypoints.size() - 1):
			var a: Vector2 = Vector2(float((waypoints[i] as Array)[0]),
				float((waypoints[i] as Array)[1]))
			var b: Vector2 = Vector2(float((waypoints[i + 1] as Array)[0]),
				float((waypoints[i + 1] as Array)[1]))
			length += a.distance_to(b)
			var steps: int = maxi(2, int(a.distance_to(b)))
			var previous: float = float(heightmap.call("height_at", a.x, a.y))
			for s: int in range(1, steps + 1):
				var p: Vector2 = a.lerp(b, float(s) / float(steps))
				var h: float = float(heightmap.call("height_at", p.x, p.y))
				if absf(h - previous) > worst:
					worst = absf(h - previous)
					worst_at = p
				previous = h
		routes_doc[String(node.name)] = {
			"jalons": waypoints.size(),
			"longueur_m": snappedf(length, 0.1),
			"pire_marche_m_par_m": snappedf(worst, 0.01),
			"pire_marche_en": [worst_at.x, worst_at.y],
		}
	doc["routes"] = routes_doc

	# --- Gués : profondeur de marche au cœur.
	var fords_doc: Array = []
	for ford: Vector2 in (heightmap.call("fords") as Array):
		fords_doc.append({
			"xz": [ford.x, ford.y],
			"profondeur_m": snappedf(
				float(heightmap.call("water_surface_at", ford.x, ford.y))
				- float(heightmap.call("height_at", ford.x, ford.y)), 0.01),
		})
	doc["gues"] = fords_doc

	# --- Navigation : quadrants + chemins d'ancres sur la carte réelle.
	var map: RID = world.get_world_3d().navigation_map
	NavigationServer3D.map_force_update(map)
	await physics_frame
	var nav_doc: Dictionary = {"quadrants": {}}
	for quadrant: int in range(4):
		var path: String = "res://resources/world_v2/nav/world_v2_navmesh_q%d.tres" % quadrant
		var mesh: NavigationMesh = load(path) as NavigationMesh
		(nav_doc["quadrants"] as Dictionary)["q%d" % quadrant] = \
			mesh.get_polygon_count() if mesh != null else 0
	var legs_doc: Dictionary = {}
	var leg_names: Array[String] = ["spawn_camp", "camp_pylone", "pylone_porte",
		"spawn_porte"]
	var legs: Array[Array] = [
		[ANCHORS["spawn"], ANCHORS["camp"]],
		[ANCHORS["camp"], ANCHORS["pylone"]],
		[ANCHORS["pylone"], ANCHORS["porte_du_donjon"]],
		[ANCHORS["spawn"], ANCHORS["porte_du_donjon"]],
	]
	for i: int in range(legs.size()):
		var path_points: PackedVector3Array = NavigationServer3D.map_get_path(
			map, legs[i][0] as Vector3, legs[i][1] as Vector3, true)
		var length: float = 0.0
		for j: int in range(path_points.size() - 1):
			length += path_points[j].distance_to(path_points[j + 1])
		var arrival: float = -1.0
		if path_points.size() >= 2:
			var last: Vector3 = path_points[path_points.size() - 1]
			var target: Vector3 = legs[i][1] as Vector3
			arrival = Vector2(last.x, last.z).distance_to(Vector2(target.x, target.z))
		legs_doc[leg_names[i]] = {
			"points": path_points.size(),
			"longueur_m": snappedf(length, 0.1),
			"ecart_arrivee_m": snappedf(arrival, 0.01),
		}
	nav_doc["chemins_ancres"] = legs_doc
	doc["navigation"] = nav_doc

	# --- Manifeste des lieux : identifiant persistant exact + position réelle.
	var places: Array = []
	for marker: Node in get_nodes_in_group(&"world_v2_poi_markers"):
		var node3d: Node3D = marker as Node3D
		places.append({
			"id": String(marker.get_meta(&"place_id", marker.name)),
			"xyz": [snappedf(node3d.global_position.x, 0.01),
				snappedf(node3d.global_position.y, 0.01),
				snappedf(node3d.global_position.z, 0.01)],
		})
	doc["lieux"] = {
		"pois": places.size(),
		"sites_systemiques": get_nodes_in_group(&"world_v2_site_markers").size(),
		"grottes": get_nodes_in_group(&"world_v2_cave_markers").size(),
		"checkpoints": get_nodes_in_group(&"world_v2_checkpoints").size(),
		"gardes_frontiere": get_nodes_in_group(&"world_v2_border_guards").size(),
		"cameras": get_nodes_in_group(&"world_v2_capture_cameras").size(),
		"manifeste_pois": places,
	}
	doc["carte_valide"] = (WorldV2Layout.validate(layout) as Array).is_empty()

	print("=== METRICS_BEGIN ===")
	print(JSON.stringify(doc, "  "))
	print("=== METRICS_END ===")
	quit(0)
