## V2.2R.1 — FILET des RACCORDEMENTS d'eau : aucune extrémité de ruban nue.
##
## Rejet visuel du lead sur 274f539 (region_r03) : « rubans se terminant
## brutalement, raccords incomplets, morceau séparé au premier plan ». Le
## filet des quads dégénérés ne prouve pas la continuité : il regarde
## l'intérieur du ruban, jamais ses BOUTS. Celui-ci mesure, sur le MAILLAGE
## réel monté, ce que chaque extrémité fait :
##
##   - ENFOUIE : le cap plonge sous le terrain (source qui émerge du sol) ;
##   - SOUS UNE AUTRE EAU : dans l'emprise de l'autre ruban ET sous sa
##     surface locale (confluence rentrée), ou dans le lac ET sous son plan ;
##   - sinon : cap plat visible → ÉCHEC nommé.
##
## Mesuré ROUGE d'abord sur 274f539 : départ du cours principal 0,90 m
## AU-DESSUS du sol à la source, départ de l'affluent 0,60 m au-dessus,
## fin de l'affluent 0,27 m HORS de l'emprise du cours principal (le trou
## de jonction vu par le lead). Seule l'embouchure du lac était rentrée.
##
## S'y ajoute la continuité de HAUTEUR le long du fil : aucune marche de
## surface > 2,5 m entre deux arêtes consécutives (une déchirure verticale
## se lit comme un mur d'eau).
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
## Marge d'enfouissement : le cap doit être au moins à 10 cm SOUS le sol.
const BURIED_MARGIN_M: float = 0.10
## Marge de rentrée sous une autre surface d'eau.
const TUCK_MARGIN_M: float = 0.05
## Demi-largeurs contractuelles des rubans (bâtisseur d'hydrologie).
const MAIN_HALF_W: float = 4.2
const TRIB_HALF_W: float = 2.6
const MAIN_DRAFT: float = 0.9
## Marche de surface maximale entre deux arêtes consécutives.
const MAX_SURFACE_STEP_M: float = 2.5

var _world: Node3D = null
var _heightmap: RefCounted = null


func test_chaque_extremite_de_ruban_est_raccordee() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame
	_heightmap = _world.get("_heightmap") as RefCounted

	var main_line: PackedVector2Array = _heightmap.call("river_main_polyline")
	var trib_line: PackedVector2Array = _heightmap.call("river_trib_polyline")
	var faults: Array[String] = []

	# 1. Les quatre extrémités : chacune enfouie, rentrée sous l'autre eau,
	# ou dans le lac — jamais un cap plat nu.
	var main_ends: Array[Vector3] = _ribbon_ends("MainCourseWater", faults)
	var trib_ends: Array[Vector3] = _ribbon_ends("TributaryWater", faults)
	for entry: Array in [
		["MainCourseWater/départ", main_ends[0] if main_ends.size() > 0 else Vector3.INF, trib_line, TRIB_HALF_W],
		["MainCourseWater/fin", main_ends[1] if main_ends.size() > 1 else Vector3.INF, trib_line, TRIB_HALF_W],
		["TributaryWater/départ", trib_ends[0] if trib_ends.size() > 0 else Vector3.INF, main_line, MAIN_HALF_W],
		["TributaryWater/fin", trib_ends[1] if trib_ends.size() > 1 else Vector3.INF, main_line, MAIN_HALF_W],
	]:
		var label: String = entry[0] as String
		var cap: Vector3 = entry[1] as Vector3
		if cap == Vector3.INF:
			continue
		var verdict: String = _end_verdict(cap, entry[2] as PackedVector2Array,
			float(entry[3]))
		if verdict != "":
			faults.append("%s : %s" % [label, verdict])

	# 2. Continuité de hauteur le long de chaque fil.
	for ribbon_name: String in ["MainCourseWater", "TributaryWater"]:
		var vertices: PackedVector3Array = _ribbon_vertices(ribbon_name)
		if vertices.is_empty():
			continue
		var quad_count: int = vertices.size() / 6
		for q: int in range(quad_count):
			var base: int = q * 6
			var previous_y: float = (vertices[base].y + vertices[base + 2].y) * 0.5
			var current_y: float = (vertices[base + 4].y + vertices[base + 5].y) * 0.5
			if absf(current_y - previous_y) > MAX_SURFACE_STEP_M:
				faults.append("%s : marche de surface de %.2f m au quad %d"
					% [ribbon_name, absf(current_y - previous_y), q])

	var shown: Array[String] = faults.slice(0, 6)
	if faults.size() > 6:
		shown.append("… et %d autres" % (faults.size() - 6))
	check(faults.is_empty(),
		"chaque extrémité d'eau est raccordée, aucune marche (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(shown)])

	var clean: bool = await restore_root()
	check(clean, "démontage propre (raccords d'eau) — %s" % restore_root_reason())
	restore_saves()


## Verdict d'une extrémité : "" si raccordée, sinon la raison.
func _end_verdict(cap: Vector3, other_line: PackedVector2Array,
		other_half_w: float) -> String:
	var ground: float = float(_heightmap.call("height_at", cap.x, cap.z))
	# a. Enfouie sous le terrain.
	if cap.y <= ground - BURIED_MARGIN_M:
		return ""
	# a2. SOUDÉE à la pièce de confluence (V2.2R.2) : l'arête terminale de
	# l'affluent est reprise sommet pour sommet par `ConfluenceWater`. Le cap
	# est le MILIEU de cette arête — jamais un sommet de la pièce — donc on
	# vérifie qu'il repose SUR une corde entre deux sommets de la pièce
	# (l'arête de bouche), à 5 cm près.
	var patch: MeshInstance3D = _world.get_node_or_null(
		"Water/ConfluenceWater") as MeshInstance3D
	if patch != null and patch.mesh != null and patch.mesh.get_surface_count() > 0:
		var arrays: Array = patch.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i: int in range(vertices.size()):
			for j: int in range(i + 1, vertices.size()):
				var on_segment: Vector3 = Geometry3D.get_closest_point_to_segment(
					cap, vertices[i], vertices[j])
				if on_segment.distance_to(cap) <= 0.05:
					return ""
	# b. Dans le lac, sous son plan (-0,5).
	var lake_center: Vector2 = _heightmap.call("lake_center")
	var lake_radius: float = _heightmap.call("lake_radius")
	var cap_xz: Vector2 = Vector2(cap.x, cap.z)
	if cap_xz.distance_to(lake_center) < lake_radius - 1.0 \
			and cap.y <= -0.5 - TUCK_MARGIN_M:
		return ""
	# c. Dans l'emprise de l'AUTRE ruban, sous sa surface locale.
	var best: float = 1e9
	var closest: Vector2 = cap_xz
	for i: int in range(other_line.size() - 1):
		var candidate: Vector2 = Geometry2D.get_closest_point_to_segment(
			cap_xz, other_line[i], other_line[i + 1])
		var d: float = cap_xz.distance_to(candidate)
		if d < best:
			best = d
			closest = candidate
	if best < other_half_w - 0.5:
		var other_bed: float = float(_heightmap.call("height_at", closest.x, closest.y))
		var other_surface: float = minf(other_bed + MAIN_DRAFT,
			maxf(float(_heightmap.call("water_surface_at", closest.x, closest.y)),
				other_bed + 0.15))
		if cap.y <= other_surface - TUCK_MARGIN_M:
			return ""
		return "dans l'emprise voisine mais %.2f m au-dessus de sa surface" \
			% (cap.y - other_surface)
	return "cap nu : %.2f m au-dessus du sol, à %.2f m du fil voisin" \
		% [cap.y - ground, best]


## Les deux arêtes d'extrémité (milieux) d'un ruban, [début, fin].
func _ribbon_ends(ribbon_name: String, faults: Array[String]) -> Array[Vector3]:
	var vertices: PackedVector3Array = _ribbon_vertices(ribbon_name)
	if vertices.size() < 6:
		faults.append("%s : maillage absent ou vide" % ribbon_name)
		return []
	var n: int = vertices.size()
	# Disposition du quad (bâtisseur) : [prev_g, droite, prev_d, prev_g, gauche, droite].
	var first_mid: Vector3 = (vertices[0] + vertices[2]) * 0.5
	var last_mid: Vector3 = (vertices[n - 2] + vertices[n - 1]) * 0.5
	return [first_mid, last_mid]


func _ribbon_vertices(ribbon_name: String) -> PackedVector3Array:
	var instance: MeshInstance3D = _world.get_node_or_null(
		"Water/" + ribbon_name) as MeshInstance3D
	if instance == null or instance.mesh == null \
			or instance.mesh.get_surface_count() == 0:
		return PackedVector3Array()
	return instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
