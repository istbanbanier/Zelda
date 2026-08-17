## Bâtisseur des 64 CHUNKS de terrain V2 — collision V2.1, peau V2.2.
##
## Chaque chunk échantillonne la fonction commune (`WorldV2Heightmap`) aux
## coordonnées ENTIÈRES du monde : deux chunks voisins partagent leurs 65
## échantillons de frontière — la continuité est un fait de construction.
## Collision : UNE `HeightMapShape3D` 65×65 au pas de 1 m par chunk (le pas
## natif de la forme — jamais de `scale` sur une CollisionShape3D), soit 64
## formes pour tout le monde. GELÉE depuis V2.1 : la phase paysagère ne
## touche que la PEAU.
##
## Visuel V2.2 : un `ArrayMesh` par chunk portant, par SOMMET, les données
## que le matériau de paysage interprète — teinte peinte de région à
## transitions LARGES (grille floutée §10-11 de la directive), masque de
## route adouci, humidité des berges, cendres de la Marche — plus la teinte
## de diagnostic V2.1 conservée en CUSTOM1, cachée par défaut. Toutes les
## données sont échantillonnées en espace MONDE : aucune couture de chunk
## possible, par construction.
##
## Tout se construit UNE fois au chargement — jamais par frame.
class_name WorldV2TerrainBuilder
extends RefCounted

const SAMPLES: int = WorldV2Heightmap.CHUNK_SIZE_M + 1
const ROUTE_PAINT_HALF_W: float = 2.0
## Masque de route ADOUCI : plein jusqu'à 1,4 m, éteint à 2,6 m — le shader
## mord ensuite ce bord au bruit (§14 : intégrée, jamais plaquée).
const ROUTE_SOFT_NEAR: float = 1.4
const ROUTE_SOFT_FAR: float = 2.6

## Grille de peinture pré-calculée puis FLOUTÉE : les transitions de région
## font ~10-16 m au lieu d'un pas de 1 m — « jamais la couleur seule », et
## jamais une frontière de rectangle visible au sol.
const PAINT_GRID_STEP_M: float = 4.0
const PAINT_BLUR_RADIUS_CELLS: int = 2

## Teintes PEINTES par région, en espace ALBÉDO (leçon scripts/CLAUDE.md :
## la lumière a un gain ≈ 1,4-1,8 non linéaire — viser la valeur RENDUE de
## §1.5, mesurée en capture, jamais la couleur cible en albédo).
## Identités §4 du masterplan : crête luxuriante, prairie ouverte, val
## frais, falaises sèches, camp usé, bois profond, hauteurs ocres, steppe
## pâle, ruines poussiéreuses, marche éteinte, anneau minéral.
## Calibrées à la CAPTURE (llvmpipe, cam01) : la première passe à ~/1,65 de
## la palette rendait l'herbe à 19-25 %% de luma (bande §1.5 : 35-65) — le
## gain de CE monde (filmic + soleil 23°) est bien plus faible que celui du
## lab V1. Relevées de ×1,45, puis re-mesurées.
## Troisième passe mesurée : ×1,45 remettait les VALEURS dans la bande §1.5
## mais rendait l'image ACIDE — le canal bleu des albédos valait la moitié de
## la palette cible et le soleil miel aggravait le glissement jaune. Le bleu
## remonte, la dominante verte se calme : l'olive de §1.4, pas le néon.
const REGION_PAINT: Dictionary = {
	&"r01_crete_de_l_aube": Color(0.36, 0.47, 0.27),
	&"r02_prairie_mille_fleurs": Color(0.35, 0.44, 0.27),
	&"r03_val_de_neris": Color(0.31, 0.43, 0.29),
	&"r04_falaises_du_couchant": Color(0.40, 0.37, 0.26),
	&"r05_terrasse_du_camp": Color(0.38, 0.41, 0.27),
	&"r06_bois_du_levant": Color(0.23, 0.36, 0.22),
	&"r07_hauteurs_de_l_orient": Color(0.39, 0.35, 0.23),
	&"r08_steppe_du_nord": Color(0.39, 0.40, 0.27),
	&"r09_ruines_du_coeur": Color(0.38, 0.40, 0.30),
	&"r10_marche_de_l_orage": Color(0.32, 0.33, 0.31),
	&"r11_anneau_frontalier": Color(0.33, 0.30, 0.27),
}
const PAINT_FALLBACK: Color = Color(0.35, 0.43, 0.27)
## Cendres : identité de la Marche de l'Orage (herbe qui cède aux cendres),
## poussière minérale légère sur l'anneau. Floutées par la même grille.
const REGION_ASH: Dictionary = {
	&"r10_marche_de_l_orage": 0.75,
	&"r11_anneau_frontalier": 0.30,
}

## Bandes d'humidité des berges (au-delà de la demi-largeur du lit).
## V2.2R.1 (famille F, diagnostic magenta) : les bandes larges lisaient
## comme des RUBANS D'EAU — leurs fins et occlusions passaient pour des
## rubans cassés (rejet du lead, region_r03). Resserrées : la peinture
## humide borde l'eau, elle ne la remplace pas.
const WET_MAIN_NEAR: float = 2.2
const WET_MAIN_FAR: float = 4.6
const WET_TRIB_NEAR: float = 1.2
const WET_TRIB_FAR: float = 3.2
const WET_LAKE_BAND: float = 3.0
const WATER_SEGMENT_MARGIN: float = 8.0

## Teintes de diagnostic par région (V2.1) — conservées en CUSTOM1, cachées
## par défaut (directive V2.2 §11).
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
var _material: ShaderMaterial = null
## [a: Vector2, b: Vector2, wet_near: float, wet_far: float]
var _water_segments: Array[Array] = []
var _paint_grid: PackedColorArray = PackedColorArray()
var _paint_cols: int = 0


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

	_material = WorldV2GroundMaterial.create()
	_collect_water_segments()
	_build_paint_grid()


## Segments d'eau (cours principal + affluent) avec leur bande d'humidité —
## même filtrage par chunk que les routes.
func _collect_water_segments() -> void:
	var main_line: PackedVector2Array = _heightmap.river_main_polyline()
	for i: int in range(main_line.size() - 1):
		_water_segments.append([main_line[i], main_line[i + 1],
			WET_MAIN_NEAR, WET_MAIN_FAR])
	var trib_line: PackedVector2Array = _heightmap.river_trib_polyline()
	for i: int in range(trib_line.size() - 1):
		_water_segments.append([trib_line[i], trib_line[i + 1],
			WET_TRIB_NEAR, WET_TRIB_FAR])


## Grille de peinture : teinte de région (rgb) + cendres (a) au pas de 4 m,
## puis flou séparable — les transitions de région deviennent des dégradés
## de ~10-16 m qu'aucun échantillonnage par sommet ne pourrait offrir seul.
func _build_paint_grid() -> void:
	_paint_cols = int(float(WorldV2Heightmap.CHUNK_SIZE_M * WorldV2Heightmap.GRID_COLS)
		/ PAINT_GRID_STEP_M) + 1
	_paint_grid.resize(_paint_cols * _paint_cols)
	for gz: int in range(_paint_cols):
		for gx: int in range(_paint_cols):
			var x: float = WorldV2Heightmap.ORIGIN_XZ + float(gx) * PAINT_GRID_STEP_M
			var z: float = WorldV2Heightmap.ORIGIN_XZ + float(gz) * PAINT_GRID_STEP_M
			var region: StringName = region_id_at(x, z)
			var paint: Color = REGION_PAINT.get(region, PAINT_FALLBACK) as Color
			paint.a = float(REGION_ASH.get(region, 0.0))
			_paint_grid[gz * _paint_cols + gx] = paint
	for axis: int in range(2):
		var blurred: PackedColorArray = PackedColorArray()
		blurred.resize(_paint_grid.size())
		for gz: int in range(_paint_cols):
			for gx: int in range(_paint_cols):
				var sum: Color = Color(0, 0, 0, 0)
				var taps: int = 0
				for offset: int in range(-PAINT_BLUR_RADIUS_CELLS,
						PAINT_BLUR_RADIUS_CELLS + 1):
					var sx: int = gx + (offset if axis == 0 else 0)
					var sz: int = gz + (offset if axis == 1 else 0)
					if sx < 0 or sx >= _paint_cols or sz < 0 or sz >= _paint_cols:
						continue
					sum += _paint_grid[sz * _paint_cols + sx]
					taps += 1
				blurred[gz * _paint_cols + gx] = sum / float(maxi(taps, 1))
		_paint_grid = blurred


## Teinte peinte + cendres au point (x, z) — bilinéaire sur la grille floutée.
func _paint_at(x: float, z: float) -> Color:
	var fx: float = clampf((x - WorldV2Heightmap.ORIGIN_XZ) / PAINT_GRID_STEP_M,
		0.0, float(_paint_cols - 1))
	var fz: float = clampf((z - WorldV2Heightmap.ORIGIN_XZ) / PAINT_GRID_STEP_M,
		0.0, float(_paint_cols - 1))
	var x0: int = int(fx)
	var z0: int = int(fz)
	var x1: int = mini(x0 + 1, _paint_cols - 1)
	var z1: int = mini(z0 + 1, _paint_cols - 1)
	var tx: float = fx - float(x0)
	var tz: float = fz - float(z0)
	var top: Color = _paint_grid[z0 * _paint_cols + x0].lerp(
		_paint_grid[z0 * _paint_cols + x1], tx)
	var bottom: Color = _paint_grid[z1 * _paint_cols + x0].lerp(
		_paint_grid[z1 * _paint_cols + x1], tx)
	return top.lerp(bottom, tz)


func build(parent: Node3D) -> void:
	for row: int in range(WorldV2Heightmap.GRID_ROWS):
		for col: int in range(WorldV2Heightmap.GRID_COLS):
			parent.add_child(_build_chunk(col, row))


func _build_chunk(col: int, row: int) -> StaticBody3D:
	var origin_x: float = WorldV2Heightmap.ORIGIN_XZ + float(col * WorldV2Heightmap.CHUNK_SIZE_M)
	var origin_z: float = WorldV2Heightmap.ORIGIN_XZ + float(row * WorldV2Heightmap.CHUNK_SIZE_M)
	var center_x: float = origin_x + float(WorldV2Heightmap.CHUNK_SIZE_M) * 0.5
	var center_z: float = origin_z + float(WorldV2Heightmap.CHUNK_SIZE_M) * 0.5

	# Une seule passe d'échantillonnage : hauteurs ET données de peinture.
	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(SAMPLES * SAMPLES)
	var paints: PackedColorArray = PackedColorArray()
	paints.resize(SAMPLES * SAMPLES)
	var masks: PackedColorArray = PackedColorArray()
	masks.resize(SAMPLES * SAMPLES)
	var diags: PackedColorArray = PackedColorArray()
	diags.resize(SAMPLES * SAMPLES)
	var local_routes: Array[Array] = _segments_near_chunk(origin_x, origin_z)
	var local_water: Array[Array] = _water_near_chunk(origin_x, origin_z)
	for sz: int in range(SAMPLES):
		for sx: int in range(SAMPLES):
			var wx: float = origin_x + float(sx)
			var wz: float = origin_z + float(sz)
			var index: int = sz * SAMPLES + sx
			var h: float = _heightmap.height_at(wx, wz)
			heights[index] = h
			var paint: Color = _paint_at(wx, wz)
			var route_mask: float = _route_mask(wx, wz, local_routes)
			paints[index] = Color(paint.r, paint.g, paint.b, route_mask)
			masks[index] = Color(_wetness(wx, wz, local_water), paint.a, 0.0, 0.0)
			diags[index] = _tint(wx, wz, h, local_routes)

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
	mesh_instance.mesh = _build_mesh(heights, paints, masks, diags)
	body.add_child(mesh_instance)
	return body


## Segments d'eau qui touchent l'emprise du chunk (bande humide comprise).
func _water_near_chunk(origin_x: float, origin_z: float) -> Array[Array]:
	var near: Array[Array] = []
	var chunk_rect: Rect2 = Rect2(
		origin_x - WATER_SEGMENT_MARGIN, origin_z - WATER_SEGMENT_MARGIN,
		float(WorldV2Heightmap.CHUNK_SIZE_M) + 2.0 * WATER_SEGMENT_MARGIN,
		float(WorldV2Heightmap.CHUNK_SIZE_M) + 2.0 * WATER_SEGMENT_MARGIN)
	for segment: Array in _water_segments:
		var a: Vector2 = segment[0] as Vector2
		var b: Vector2 = segment[1] as Vector2
		var seg_rect: Rect2 = Rect2(minf(a.x, b.x), minf(a.y, b.y),
			absf(b.x - a.x), absf(b.y - a.y))
		if chunk_rect.intersects(seg_rect.grow(0.1)):
			near.append(segment)
	return near


## Masque de route ADOUCI (0-1) — le shader mord ce bord au bruit.
func _route_mask(x: float, z: float, local_routes: Array[Array]) -> float:
	if local_routes.is_empty():
		return 0.0
	var p: Vector2 = Vector2(x, z)
	var best: float = INF
	for segment: Array in local_routes:
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(
			p, segment[0] as Vector2, segment[1] as Vector2)
		best = minf(best, p.distance_to(closest))
	return 1.0 - smoothstep(ROUTE_SOFT_NEAR, ROUTE_SOFT_FAR, best)


## Humidité (0-1) : pleine dans le lit, dégradée sur la berge, autour du lac.
##
## V2.2R.1 (famille F — DIAGNOSTIC MAGENTA sur le cadrage r03) : les
## « rubans terminés brutalement, raccords incomplets, morceau séparé »
## rejetés par le lead n'étaient PAS les maillages d'eau — c'était CETTE
## peinture, purement horizontale, qui grimpait les berges et les terrasses
## des gorges en nappes anguleuses et s'arrêtait en ligne dure à la limite
## de sa bande. L'humidité s'ATTÉNUE désormais avec la HAUTEUR au-dessus de
## la ligne d'eau locale : elle épouse la rive, jamais les parois.
func _wetness(x: float, z: float, local_water: Array[Array]) -> float:
	var p: Vector2 = Vector2(x, z)
	var wet: float = 0.0
	# Niveau d'eau de RÉFÉRENCE de la contribution gagnante : le lit au
	# point le plus proche du fil + tirant moyen (`water_surface_at` rend
	# -INF hors du couloir étroit du lit — inutilisable pour la berge).
	var level: float = -1e9
	for segment: Array in local_water:
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(
			p, segment[0] as Vector2, segment[1] as Vector2)
		var d: float = p.distance_to(closest)
		var contribution: float = 1.0 - smoothstep(float(segment[2]),
			float(segment[3]), d)
		if contribution > wet:
			wet = contribution
			level = _heightmap.height_at(closest.x, closest.y) + 0.75
	var lake_d: float = p.distance_to(_heightmap.lake_center())
	var lake_contribution: float = 1.0 - smoothstep(_heightmap.lake_radius(),
		_heightmap.lake_radius() + WET_LAKE_BAND, lake_d)
	if lake_contribution > wet:
		wet = lake_contribution
		level = -0.5
	if wet <= 0.001:
		return 0.0
	var above: float = _heightmap.height_at(x, z) - level
	return wet * (1.0 - smoothstep(0.8, 2.4, above))


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


func _build_mesh(heights: PackedFloat32Array, paints: PackedColorArray,
		masks: PackedColorArray, diags: PackedColorArray) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# CUSTOM0 = humidité/cendres ; CUSTOM1 = teinte de diagnostic V2.1
	# (cachée par défaut — directive §11). Les canaux custom vivent dans le
	# Vertex de SurfaceTool : ils survivent à generate_normals (source 4.7.1).
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA8_UNORM)
	st.set_custom_format(1, SurfaceTool.CUSTOM_RGBA8_UNORM)
	var half: float = float(WorldV2Heightmap.CHUNK_SIZE_M) * 0.5
	for sz: int in range(SAMPLES - 1):
		for sx: int in range(SAMPLES - 1):
			var i00: int = sz * SAMPLES + sx
			var i10: int = i00 + 1
			var i01: int = i00 + SAMPLES
			var i11: int = i01 + 1
			# Enroulement MESURÉ À LA CAPTURE (inspection réelle, phase V2.1) :
			# l'ordre p00→p11→p10 ne rendait que le DESSOUS du terrain — le
			# monde disparaissait de presque tous les angles de jeu. La note
			# ISS-018 d'origine affirmait l'inverse sans capture : c'est
			# précisément le mensonge silencieux qu'une inspection d'image
			# attrape et qu'aucun test de collision ne peut voir.
			for index: int in [i00, i10, i11, i00, i11, i01]:
				st.set_color(paints[index])
				st.set_custom(0, masks[index])
				st.set_custom(1, diags[index])
				var col: int = index % SAMPLES
				var row: int = index / SAMPLES
				st.add_vertex(Vector3(float(col) - half, heights[index],
					float(row) - half))
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
