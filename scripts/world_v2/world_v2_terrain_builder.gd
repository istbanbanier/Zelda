## Bâtisseur des 64 CHUNKS de terrain V2.1 — whitebox de diagnostic.
##
## Chaque chunk échantillonne la fonction commune (`WorldV2Heightmap`) aux
## coordonnées ENTIÈRES du monde : deux chunks voisins partagent leurs 65
## échantillons de frontière — la continuité est un fait de construction.
## Collision : UNE `HeightMapShape3D` 65×65 au pas de 1 m par chunk (le pas
## natif de la forme — jamais de `scale` sur une CollisionShape3D), soit 64
## formes pour tout le monde. Visuel : un `ArrayMesh` par chunk, teinté par
## SOMMET : une famille de teinte par région, lit d'eau sombre, bande de
## route ocre APPARTENANT au terrain, anneau frontalier assombri. Aucun
## matériau artistique — c'est un whitebox et il le dit.
##
## Tout se construit UNE fois au chargement — jamais par frame.
class_name WorldV2TerrainBuilder
extends RefCounted

const SAMPLES: int = WorldV2Heightmap.CHUNK_SIZE_M + 1
const ROUTE_PAINT_HALF_W: float = 2.0

## Teintes de diagnostic par région (mates, distinctes — prompt V2.1 §4).
const REGION_TINTS: Dictionary = {
	&"r01_crete_de_l_aube": Color(0.55, 0.62, 0.38),
	&"r02_prairie_mille_fleurs": Color(0.45, 0.60, 0.35),
	&"r03_val_de_neris": Color(0.35, 0.55, 0.45),
	&"r04_falaises_du_couchant": Color(0.55, 0.45, 0.32),
	&"r05_terrasse_du_camp": Color(0.60, 0.52, 0.35),
	&"r06_bois_du_levant": Color(0.35, 0.50, 0.30),
	&"r07_hauteurs_de_l_orient": Color(0.50, 0.44, 0.36),
	&"r08_steppe_du_nord": Color(0.52, 0.52, 0.36),
	&"r09_ruines_du_coeur": Color(0.50, 0.48, 0.44),
	&"r10_marche_de_l_orage": Color(0.44, 0.40, 0.46),
	&"r11_anneau_frontalier": Color(0.34, 0.33, 0.35),
}
const TINT_FALLBACK: Color = Color(0.46, 0.46, 0.42)
const TINT_RIVERBED: Color = Color(0.25, 0.30, 0.38)
const TINT_ROUTE: Color = Color(0.72, 0.58, 0.30)
const TINT_FORBIDDEN: Color = Color(0.40, 0.30, 0.30)
const FORBIDDEN_RADIUS: float = 238.0

var _heightmap: WorldV2Heightmap = null
var _regions: Array[Dictionary] = []
var _route_segments: Array[Array] = []
var _material: StandardMaterial3D = null


func _init(heightmap: WorldV2Heightmap, layout: Dictionary) -> void:
	_heightmap = heightmap
	for entry: Variant in layout.get("regions", []) as Array:
		var region: Dictionary = entry as Dictionary
		var rects: Array[Rect2] = []
		for bound: Variant in region.get("bounds", []) as Array:
			var b: Dictionary = bound as Dictionary
			if b.has("x") and b.has("z"):
				var bx: Array = b["x"] as Array
				var bz: Array = b["z"] as Array
				rects.append(Rect2(float(bx[0]), float(bz[0]),
					float(bx[1]) - float(bx[0]), float(bz[1]) - float(bz[0])))
		if rects.is_empty():
			continue
		var area: float = 0.0
		for rect: Rect2 in rects:
			area += rect.size.x * rect.size.y
		_regions.append({
			"id": StringName(String(region.get("id", ""))),
			"rects": rects,
			"area": area,
		})
	# La plus PETITE région gagne (les Ruines du Cœur sont découpées dans la
	# steppe : sans ce tri, la steppe les recouvrirait).
	_regions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["area"]) < float(b["area"]))

	for route_name: String in ["main_path", "river_route", "heights_route", "ruins_route"]:
		var route: Dictionary = (layout.get("routes", {}) as Dictionary) \
			.get(route_name, {}) as Dictionary
		var waypoints: Array = route.get("waypoints_xz", []) as Array
		for i: int in range(waypoints.size() - 1):
			var a: Array = waypoints[i] as Array
			var b: Array = waypoints[i + 1] as Array
			_route_segments.append([
				Vector2(float(a[0]), float(a[1])), Vector2(float(b[0]), float(b[1]))])

	_material = StandardMaterial3D.new()
	_material.vertex_color_use_as_albedo = true
	_material.roughness = 1.0


func build(parent: Node3D) -> void:
	for row: int in range(WorldV2Heightmap.GRID_ROWS):
		for col: int in range(WorldV2Heightmap.GRID_COLS):
			parent.add_child(_build_chunk(col, row))


func _build_chunk(col: int, row: int) -> StaticBody3D:
	var origin_x: float = WorldV2Heightmap.ORIGIN_XZ + float(col * WorldV2Heightmap.CHUNK_SIZE_M)
	var origin_z: float = WorldV2Heightmap.ORIGIN_XZ + float(row * WorldV2Heightmap.CHUNK_SIZE_M)
	var center_x: float = origin_x + float(WorldV2Heightmap.CHUNK_SIZE_M) * 0.5
	var center_z: float = origin_z + float(WorldV2Heightmap.CHUNK_SIZE_M) * 0.5

	# Une seule passe d'échantillonnage : hauteurs ET couleurs par sommet.
	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(SAMPLES * SAMPLES)
	var colors: PackedColorArray = PackedColorArray()
	colors.resize(SAMPLES * SAMPLES)
	var local_routes: Array[Array] = _segments_near_chunk(origin_x, origin_z)
	for sz: int in range(SAMPLES):
		for sx: int in range(SAMPLES):
			var wx: float = origin_x + float(sx)
			var wz: float = origin_z + float(sz)
			var index: int = sz * SAMPLES + sx
			var h: float = _heightmap.height_at(wx, wz)
			heights[index] = h
			colors[index] = _tint(wx, wz, h, local_routes)

	var body: StaticBody3D = StaticBody3D.new()
	body.name = "c%dr%d" % [col, row]
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group(&"world_v2_terrain")
	body.position = Vector3(center_x, 0.0, center_z)

	var shape: HeightMapShape3D = HeightMapShape3D.new()
	shape.map_width = SAMPLES
	shape.map_depth = SAMPLES
	shape.map_data = heights
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "GroundCollision"
	collision.shape = shape
	body.add_child(collision)

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = "GroundMesh"
	mesh_instance.mesh = _build_mesh(heights, colors)
	mesh_instance.add_to_group(&"world_v2_navsource")
	body.add_child(mesh_instance)
	return body


## Segments de route qui touchent l'emprise du chunk (marge de peinture) —
## le premier jet testait TOUS les segments à chaque sommet : des dizaines
## de millions d'opérations pour rien.
func _segments_near_chunk(origin_x: float, origin_z: float) -> Array[Array]:
	var near: Array[Array] = []
	var chunk_rect: Rect2 = Rect2(
		origin_x - ROUTE_PAINT_HALF_W, origin_z - ROUTE_PAINT_HALF_W,
		float(WorldV2Heightmap.CHUNK_SIZE_M) + 2.0 * ROUTE_PAINT_HALF_W,
		float(WorldV2Heightmap.CHUNK_SIZE_M) + 2.0 * ROUTE_PAINT_HALF_W)
	for segment: Array in _route_segments:
		var a: Vector2 = segment[0] as Vector2
		var b: Vector2 = segment[1] as Vector2
		var seg_rect: Rect2 = Rect2(minf(a.x, b.x), minf(a.y, b.y),
			absf(b.x - a.x), absf(b.y - a.y))
		if chunk_rect.intersects(seg_rect.grow(0.1)):
			near.append(segment)
	return near


func _build_mesh(heights: PackedFloat32Array, colors: PackedColorArray) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: float = float(WorldV2Heightmap.CHUNK_SIZE_M) * 0.5
	for sz: int in range(SAMPLES - 1):
		for sx: int in range(SAMPLES - 1):
			var i00: int = sz * SAMPLES + sx
			var i10: int = i00 + 1
			var i01: int = i00 + SAMPLES
			var i11: int = i01 + 1
			var p00: Vector3 = Vector3(float(sx) - half, heights[i00], float(sz) - half)
			var p10: Vector3 = Vector3(float(sx + 1) - half, heights[i10], float(sz) - half)
			var p01: Vector3 = Vector3(float(sx) - half, heights[i01], float(sz + 1) - half)
			var p11: Vector3 = Vector3(float(sx + 1) - half, heights[i11], float(sz + 1) - half)
			# Enroulement vu de DESSUS — l'inverse rend le sol invisible
			# (leçon ISS-018, attrapée deux fois sur la V1).
			st.set_color(colors[i00])
			st.add_vertex(p00)
			st.set_color(colors[i11])
			st.add_vertex(p11)
			st.set_color(colors[i10])
			st.add_vertex(p10)
			st.set_color(colors[i00])
			st.add_vertex(p00)
			st.set_color(colors[i01])
			st.add_vertex(p01)
			st.set_color(colors[i11])
			st.add_vertex(p11)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, _material)
	return mesh


func _tint(x: float, z: float, h: float, local_routes: Array[Array]) -> Color:
	var surface: float = _heightmap.water_surface_at(x, z)
	if surface > -INF and h < surface + 0.25:
		return TINT_RIVERBED
	var p: Vector2 = Vector2(x, z)
	for segment: Array in local_routes:
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(
			p, segment[0] as Vector2, segment[1] as Vector2)
		if p.distance_to(closest) <= ROUTE_PAINT_HALF_W:
			return TINT_ROUTE
	if p.length() >= FORBIDDEN_RADIUS:
		return TINT_FORBIDDEN
	return region_tint(region_id_at(x, z))


func region_id_at(x: float, z: float) -> StringName:
	var p: Vector2 = Vector2(x, z)
	for region: Dictionary in _regions:
		for rect: Rect2 in region["rects"] as Array[Rect2]:
			if rect.has_point(p):
				return region["id"] as StringName
	if p.length() >= WorldV2Heightmap.PLAYABLE_RADIUS_M:
		return &"r11_anneau_frontalier"
	return &""


func region_tint(region_id: StringName) -> Color:
	return REGION_TINTS.get(region_id, TINT_FALLBACK) as Color
