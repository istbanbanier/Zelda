## V2.2R.2 — CONTRÔLE F2 : la confluence est une VRAIE jonction topologique.
##
## Le lead a rejeté la confluence de `gros_plan_jonction_eau.png` (V2.2R.1,
## code a37ec16) : deux nappes superposées, pli sombre, rupture de hauteur
## et de normale, pointes triangulaires. Le filet F (extrémités) ne voit
## pas ce défaut : il accepte un cap RENTRÉ SOUS l'autre ruban — précisément
## le recouvrement rejeté. F2 mesure la ZONE de confluence elle-même, sur
## les maillages montés (complète F, ne remplace ni F ni le contrôle E).
##
## Écrit ROUGE d'abord sur la géométrie de a37ec16 :
##   - normales ABSENTES des deux rubans (mesuré : ARRAY_NORMAL vide) ;
##   - recouvrement en projection XZ (le prolongement glissait SOUS le
##     cours principal) ;
##   - bord intérieur LIBRE dans l'emprise du cours principal (le bout du
##     prolongement flottait sous la nappe).
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
## Rayon de la zone de confluence autour du point C.
const ZONE_R: float = 9.0
const MAIN_HALF_W: float = 4.2
## Continuité de hauteur exigée au raccord.
const MAX_SEAM_GAP_M: float = 0.05
## Angle maximal entre normales de la zone (surface d'eau quasi plane).
const MAX_NORMAL_SPREAD_DEG: float = 25.0

var _world: Node3D = null
var _junction: Vector2 = Vector2.ZERO
var _main_fil: PackedVector2Array = PackedVector2Array()


func test_la_confluence_est_une_jonction_topologique() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame
	var heightmap: RefCounted = _world.get("_heightmap") as RefCounted
	_main_fil = heightmap.call("river_main_polyline")
	var trib_line: PackedVector2Array = heightmap.call("river_trib_polyline")
	var trib_end: Vector2 = trib_line[trib_line.size() - 1]
	_junction = _closest_on_fil(trib_end)

	var faults: Array[String] = []
	var main_tris: Array[PackedVector3Array] = _zone_triangles("MainCourseWater")
	var trib_tris: Array[PackedVector3Array] = _zone_triangles("TributaryWater")
	var patch_tris: Array[PackedVector3Array] = _zone_triangles("ConfluenceWater")
	var side_tris: Array[PackedVector3Array] = trib_tris + patch_tris
	if main_tris.is_empty() or side_tris.is_empty():
		faults.append("zone de confluence sans triangles (main %d, affluent %d)"
			% [main_tris.size(), side_tris.size()])

	# 1. Normales PRÉSENTES sur les trois maillages, et cohérentes (une
	# surface d'eau quasi plane : toutes proches de la verticale).
	for entry: Array in [["MainCourseWater", true], ["TributaryWater", true],
			["ConfluenceWater", false]]:
		var verdict: String = _normals_verdict(entry[0] as String,
			bool(entry[1]))
		if verdict != "":
			faults.append(verdict)

	# 2. Aucun RECOUVREMENT en projection XZ entre le côté affluent
	# (ruban + pièce de confluence) et le cours principal.
	var overlapping: int = 0
	var covered_gaps: int = 0
	var step: float = 0.5
	var sample_z: float = _junction.y - ZONE_R
	while sample_z <= _junction.y + ZONE_R:
		var sample_x: float = _junction.x - ZONE_R
		while sample_x <= _junction.x + ZONE_R:
			var p: Vector2 = Vector2(sample_x, sample_z)
			if p.distance_to(_junction) <= ZONE_R:
				if _covers(side_tris, p, true) and _covers(main_tris, p, true):
					overlapping += 1
			sample_x += step
		sample_z += step
	if overlapping > 0:
		faults.append("%d point(s) couverts par les DEUX nappes (recouvrement)"
			% overlapping)

	# 3. COUVERTURE COMPLÈTE entre l'affluent et le cours principal : aucun
	# trou d'eau le long du trajet EAU RÉELLE de l'affluent → fil principal
	# (le bout du maillage, pas le jalon brut : le ruban s'arrête désormais
	# avant l'emprise et la pièce de confluence prend le relais).
	var walk_start: Vector2 = trib_end
	var tributary: MeshInstance3D = _world.get_node_or_null(
		"Water/TributaryWater") as MeshInstance3D
	if tributary != null and tributary.mesh != null \
			and tributary.mesh.get_surface_count() > 0:
		var trib_vertices: PackedVector3Array = \
			tributary.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var n: int = trib_vertices.size()
		if n >= 2:
			var cap: Vector3 = (trib_vertices[n - 2] + trib_vertices[n - 1]) * 0.5
			walk_start = Vector2(cap.x, cap.z)
	var walk: float = 0.0
	var gap_spots: Array[String] = []
	var total: float = walk_start.distance_to(_junction)
	while walk <= total:
		var p: Vector2 = walk_start + (_junction - walk_start).normalized() * walk
		if not (_covers(side_tris, p, false) or _covers(main_tris, p, false)):
			covered_gaps += 1
			gap_spots.append("(%.1f, %.1f)" % [p.x, p.y])
		walk += 0.25
	if covered_gaps > 0:
		faults.append("%d trou(s) de couverture entre affluent et cours principal — %s"
			% [covered_gaps, " ; ".join(gap_spots.slice(0, 5))])

	# 4. Aucun BORD INTÉRIEUR LIBRE : une arête de bord du côté affluent
	# dont les deux sommets sont NETTEMENT dans l'emprise du cours principal
	# est une nappe qui flotte sous/sur l'autre.
	var free_inside: int = 0
	var free_spots: Array[String] = []
	for edge: Array in _boundary_edges(side_tris):
		var a: Vector3 = edge[0] as Vector3
		var b: Vector3 = edge[1] as Vector3
		# « Dans l'emprise » se mesure contre la nappe RÉELLE (couverture du
		# maillage principal), pas contre le fil brut : le fil arrondi
		# s'écarte du fil brut aux coudes.
		if _covers(main_tris, Vector2(a.x, a.z), true) \
				and _covers(main_tris, Vector2(b.x, b.z), true):
			free_inside += 1
			free_spots.append("(%.1f, %.1f)-(%.1f, %.1f)" % [a.x, a.z, b.x, b.z])
	if free_inside > 0:
		faults.append("%d arête(s) de bord libre DANS l'emprise du cours principal — %s"
			% [free_inside, " ; ".join(free_spots.slice(0, 3))])

	# 5. CONTINUITÉ DE HAUTEUR au raccord : tout sommet de bord du côté
	# affluent posé dans la bande du bord du cours principal doit toucher
	# la surface du cours principal à 5 cm près.
	var seam_gaps: Array[String] = []
	for edge: Array in _boundary_edges(side_tris):
		for v: Variant in edge:
			var vertex: Vector3 = v as Vector3
			var fil_d: float = _dist_to_fil(Vector2(vertex.x, vertex.z))
			if absf(fil_d - MAIN_HALF_W) > 1.0:
				continue
			var gap: float = _dist_to_mesh(main_tris, vertex)
			if gap > MAX_SEAM_GAP_M:
				seam_gaps.append("(%.1f, %.1f) : %.3f m" % [vertex.x, vertex.z, gap])
	if not seam_gaps.is_empty():
		faults.append("%d sommet(s) de raccord à plus de %.2f m de la nappe "
			% [seam_gaps.size(), MAX_SEAM_GAP_M]
			+ "principale — %s" % " ; ".join(seam_gaps.slice(0, 3)))

	var shown: Array[String] = faults.slice(0, 6)
	if faults.size() > 6:
		shown.append("… et %d autres" % (faults.size() - 6))
	check(faults.is_empty(),
		"la confluence est une jonction topologique (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(shown)])

	var clean: bool = await restore_root()
	check(clean, "démontage propre (confluence) — %s" % restore_root_reason())
	restore_saves()


## -- lecture des maillages ----------------------------------------------------

## Triangles (monde) d'un nœud d'eau dont AU MOINS un sommet est dans la zone.
func _zone_triangles(node_name: String) -> Array[PackedVector3Array]:
	var out: Array[PackedVector3Array] = []
	var instance: MeshInstance3D = _world.get_node_or_null(
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
	var offset: Vector3 = instance.global_position
	for t: int in range(order.size() / 3):
		var tri: PackedVector3Array = PackedVector3Array()
		var near: bool = false
		for c: int in range(3):
			var v: Vector3 = vertices[order[t * 3 + c]] + offset
			tri.append(v)
			if Vector2(v.x, v.z).distance_to(_junction) < ZONE_R + 4.0:
				near = true
		if near:
			out.append(tri)
	return out


func _normals_verdict(node_name: String, required: bool) -> String:
	var instance: MeshInstance3D = _world.get_node_or_null(
		"Water/" + node_name) as MeshInstance3D
	if instance == null or instance.mesh == null \
			or instance.mesh.get_surface_count() == 0:
		return "%s : maillage absent" % node_name if required else ""
	var arrays: Array = instance.mesh.surface_get_arrays(0)
	var normals: Variant = arrays[Mesh.ARRAY_NORMAL]
	if not (normals is PackedVector3Array) \
			or (normals as PackedVector3Array).is_empty():
		return "%s : normales ABSENTES" % node_name
	for n: Vector3 in normals as PackedVector3Array:
		if n.length() > 0.5 \
				and rad_to_deg(n.normalized().angle_to(Vector3.UP)) \
					> MAX_NORMAL_SPREAD_DEG:
			return "%s : normale à %.0f° de la verticale (surface d'eau)" \
				% [node_name, rad_to_deg(n.normalized().angle_to(Vector3.UP))]
	return ""


## Arêtes apparaissant UNE seule fois (bord) dans un ensemble de triangles.
func _boundary_edges(tris: Array[PackedVector3Array]) -> Array[Array]:
	var seen: Dictionary = {}
	for tri: PackedVector3Array in tris:
		for c: int in range(3):
			var a: Vector3 = tri[c]
			var b: Vector3 = tri[(c + 1) % 3]
			var ka: String = "%.3f,%.3f,%.3f" % [a.x, a.y, a.z]
			var kb: String = "%.3f,%.3f,%.3f" % [b.x, b.y, b.z]
			var key: String = ka + "|" + kb if ka < kb else kb + "|" + ka
			if seen.has(key):
				seen[key] = []
			else:
				seen[key] = [a, b]
	var out: Array[Array] = []
	for key: String in seen.keys():
		if not (seen[key] as Array).is_empty():
			out.append(seen[key] as Array)
	return out


## Le point XZ est-il couvert par un triangle ? `strict` exclut les bords
## (bande morte 1e-4 en barycentrique) : un point SUR la soudure appartient
## aux deux nappes sans être un recouvrement.
func _covers(tris: Array[PackedVector3Array], p: Vector2, strict: bool) -> bool:
	for tri: PackedVector3Array in tris:
		var a: Vector2 = Vector2(tri[0].x, tri[0].z)
		var b: Vector2 = Vector2(tri[1].x, tri[1].z)
		var c: Vector2 = Vector2(tri[2].x, tri[2].z)
		var denominator: float = (b.y - c.y) * (a.x - c.x) \
			+ (c.x - b.x) * (a.y - c.y)
		if absf(denominator) < 1e-9:
			continue
		var u: float = ((b.y - c.y) * (p.x - c.x) + (c.x - b.x) * (p.y - c.y)) \
			/ denominator
		var v: float = ((c.y - a.y) * (p.x - c.x) + (a.x - c.x) * (p.y - c.y)) \
			/ denominator
		var w: float = 1.0 - u - v
		var margin: float = 0.02 if strict else -0.0001
		if u > margin and v > margin and w > margin:
			return true
	return false


func _dist_to_mesh(tris: Array[PackedVector3Array], p: Vector3) -> float:
	var best: float = 1e9
	for tri: PackedVector3Array in tris:
		var q: Vector3 = _closest_on_triangle(p, tri[0], tri[1], tri[2])
		best = minf(best, p.distance_to(q))
	return best


func _closest_on_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	# Projection sur le plan puis rabattement sur les arêtes si hors triangle.
	var normal: Vector3 = (b - a).cross(c - a)
	if normal.length() < 1e-9:
		return a
	normal = normal.normalized()
	var projected: Vector3 = p - normal * (p - a).dot(normal)
	if _covers([PackedVector3Array([a, b, c])],
			Vector2(projected.x, projected.z), false):
		return projected
	var best: Vector3 = a
	var best_d: float = p.distance_to(a)
	for edge: Array in [[a, b], [b, c], [c, a]]:
		var e0: Vector3 = edge[0] as Vector3
		var e1: Vector3 = edge[1] as Vector3
		var t: float = clampf((p - e0).dot(e1 - e0) / maxf((e1 - e0).length_squared(), 1e-9), 0.0, 1.0)
		var q: Vector3 = e0 + (e1 - e0) * t
		if p.distance_to(q) < best_d:
			best_d = p.distance_to(q)
			best = q
	return best


func _closest_on_fil(p: Vector2) -> Vector2:
	var best: float = 1e9
	var closest: Vector2 = p
	for i: int in range(_main_fil.size() - 1):
		var candidate: Vector2 = Geometry2D.get_closest_point_to_segment(
			p, _main_fil[i], _main_fil[i + 1])
		if p.distance_to(candidate) < best:
			best = p.distance_to(candidate)
			closest = candidate
	return closest


func _dist_to_fil(p: Vector2) -> float:
	var best: float = 1e9
	for i: int in range(_main_fil.size() - 1):
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(
			p, _main_fil[i], _main_fil[i + 1])))
	return best
