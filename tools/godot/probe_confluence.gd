## Sonde de la confluence affluent→cours principal (V2.2R.2) — diagnostic seul.
##
## Usage :
##   godot --headless --path . --script tools/godot/probe_confluence.gd
##
## Le filet F2 (`test_world_v2_water_confluence.gd`) nomme un trou de
## couverture par ses coordonnées ; cette sonde répond à la question qui
## tranche : QUELS triangles bordent ce point, et où passe la pièce
## `ConfluenceWater` par rapport au bord du cours principal. Elle imprime :
##   - l'arête terminale réelle du ruban d'affluent ;
##   - chaque triangle de la pièce de confluence ;
##   - les sommets du cours principal proches de la jonction ;
##   - pour un point donné (arg --spot=x,z), la distance XZ à chaque nappe.
extends SceneTree

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"


func _initialize() -> void:
	var world: Node3D = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i: int in range(12):
		await process_frame

	var heightmap: RefCounted = world.get("_heightmap") as RefCounted
	var main_fil: PackedVector2Array = heightmap.call("river_main_polyline")
	var trib_fil: PackedVector2Array = heightmap.call("river_trib_polyline")
	var trib_end: Vector2 = trib_fil[trib_fil.size() - 1]
	var junction: Vector2 = _closest_on_fil(trib_end, main_fil)
	print("[confluence] jalon brut affluent : (%.2f, %.2f)" % [trib_end.x, trib_end.y])
	print("[confluence] jonction C (fil brut) : (%.2f, %.2f)" % [junction.x, junction.y])

	var spot: Vector2 = Vector2(-22.2, 6.9)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--spot="):
			var parts: PackedStringArray = argument.substr(7).split(",")
			spot = Vector2(parts[0].to_float(), parts[1].to_float())

	# 1. Arête terminale de l'affluent.
	var trib_vertices: PackedVector3Array = _vertices(world, "TributaryWater")
	var n: int = trib_vertices.size()
	print("")
	print("[affluent] %d sommets ; arête terminale :" % n)
	print("  gauche (n-2) : (%.3f, %.3f, %.3f)"
		% [trib_vertices[n - 2].x, trib_vertices[n - 2].y, trib_vertices[n - 2].z])
	print("  droite (n-1) : (%.3f, %.3f, %.3f)"
		% [trib_vertices[n - 1].x, trib_vertices[n - 1].y, trib_vertices[n - 1].z])

	# 2. Triangles de la pièce de confluence.
	var patch: MeshInstance3D = world.get_node_or_null(
		"Water/ConfluenceWater") as MeshInstance3D
	if patch == null or patch.mesh == null:
		print("[pièce] ABSENTE")
	else:
		var arrays: Array = patch.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		print("")
		print("[pièce] %d sommets, %d triangles :" % [vertices.size(), indices.size() / 3])
		for vi: int in range(vertices.size()):
			print("  s%d : (%.3f, %.3f, %.3f)"
				% [vi, vertices[vi].x, vertices[vi].y, vertices[vi].z])
		for t: int in range(indices.size() / 3):
			print("  t%d : s%d s%d s%d" % [t, indices[t * 3],
				indices[t * 3 + 1], indices[t * 3 + 2]])

	# 3. Sommets du cours principal proches de la jonction (rayon 10 m).
	var main_vertices: PackedVector3Array = _vertices(world, "MainCourseWater")
	print("")
	print("[principal] sommets à moins de 10 m de C :")
	for vi: int in range(main_vertices.size()):
		var v: Vector3 = main_vertices[vi]
		if Vector2(v.x, v.z).distance_to(junction) < 10.0:
			print("  i%d : (%.3f, %.3f, %.3f)" % [vi, v.x, v.y, v.z])

	# 4. Le point litigieux : distance XZ au triangle le plus proche de chaque
	# nappe (0 = couvert).
	print("")
	print("[point] (%.2f, %.2f) :" % [spot.x, spot.y])
	for node_name: String in ["TributaryWater", "ConfluenceWater", "MainCourseWater"]:
		var tris: Array[PackedVector3Array] = _triangles(world, node_name)
		var best: float = 1e9
		for tri: PackedVector3Array in tris:
			best = minf(best, _dist_xz_to_triangle(spot, tri))
		print("  %s : %.3f m" % [node_name, best])
	quit(0)


func _vertices(world: Node3D, node_name: String) -> PackedVector3Array:
	var instance: MeshInstance3D = world.get_node_or_null(
		"Water/" + node_name) as MeshInstance3D
	if instance == null or instance.mesh == null \
			or instance.mesh.get_surface_count() == 0:
		return PackedVector3Array()
	return instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]


func _triangles(world: Node3D, node_name: String) -> Array[PackedVector3Array]:
	var out: Array[PackedVector3Array] = []
	var instance: MeshInstance3D = world.get_node_or_null(
		"Water/" + node_name) as MeshInstance3D
	if instance == null or instance.mesh == null \
			or instance.mesh.get_surface_count() == 0:
		return out
	var arrays: Array = instance.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: Variant = arrays[Mesh.ARRAY_INDEX]
	var order: PackedInt32Array = PackedInt32Array()
	if indices is PackedInt32Array and (indices as PackedInt32Array).size() > 0:
		order = indices
	else:
		for i: int in range(vertices.size()):
			order.append(i)
	for t: int in range(order.size() / 3):
		out.append(PackedVector3Array([vertices[order[t * 3]],
			vertices[order[t * 3 + 1]], vertices[order[t * 3 + 2]]]))
	return out


func _dist_xz_to_triangle(p: Vector2, tri: PackedVector3Array) -> float:
	var a: Vector2 = Vector2(tri[0].x, tri[0].z)
	var b: Vector2 = Vector2(tri[1].x, tri[1].z)
	var c: Vector2 = Vector2(tri[2].x, tri[2].z)
	var denominator: float = (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
	if absf(denominator) >= 1e-9:
		var u: float = ((b.y - c.y) * (p.x - c.x) + (c.x - b.x) * (p.y - c.y)) \
			/ denominator
		var v: float = ((c.y - a.y) * (p.x - c.x) + (a.x - c.x) * (p.y - c.y)) \
			/ denominator
		if u >= 0.0 and v >= 0.0 and 1.0 - u - v >= 0.0:
			return 0.0
	var best: float = 1e9
	for edge: Array in [[a, b], [b, c], [c, a]]:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(
			p, edge[0] as Vector2, edge[1] as Vector2)))
	return best


func _closest_on_fil(p: Vector2, fil: PackedVector2Array) -> Vector2:
	var best: float = 1e9
	var closest: Vector2 = p
	for i: int in range(fil.size() - 1):
		var candidate: Vector2 = Geometry2D.get_closest_point_to_segment(
			p, fil[i], fil[i + 1])
		if p.distance_to(candidate) < best:
			best = p.distance_to(candidate)
			closest = candidate
	return closest
