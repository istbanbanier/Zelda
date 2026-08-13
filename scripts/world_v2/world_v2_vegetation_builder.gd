## Bâtisseur de VÉGÉTATION cellulaire V2.2-C — le sol prend vie, par cellules.
##
## Architecture contractuelle (tests/world_v2/test_world_v2_landscape_contract.gd) :
## chaque cellule est un `MultiMeshInstance3D` de 32 m (emprise monde ≤ 48 m),
## groupe `world_v2_vegetation` ; les troncs d'arbres et gros rochers portent
## des collisions SIMPLES dans `world_v2_vegetation_colliders` — les seules
## collisions nouvelles que la directive V2.2 §7 autorise (avec re-bake nav).
##
## Déterminisme : une graine par (cellule, couche) dérivée d'une graine
## GLOBALE fixe — deux montages produisent le même paysage, c'est testé.
##
## Anti-scatter-uniforme (§7.17 : « un scatter uniforme est un échec ») :
## les arbres du Bois poussent en BOSQUETS de 3 à 7, les fleurs en phrases
## de 5 à 12, les roseaux suivent les berges, et chaque région du masterplan
## §4 garde son identité — la crête reste vierge d'arbres, la steppe fait du
## vide une identité, la Marche ne porte que des morts.
##
## Exclusions PLUS STRICTES que le contrat testé (routes 2,3 m > 2,0 ;
## gués 5,5 > 5,0 ; checkpoints 4,5 > 4,0 ; objectifs 6,0 > 4,0 pour ce qui
## bloque un cadre) — l'herbe de premier plan près des caméras est VOULUE
## (North Star §1.1) et n'est pas exclue.
##
## Tout se construit UNE fois au chargement — jamais par frame.
class_name WorldV2VegetationBuilder
extends RefCounted

const GLOBAL_SEED: int = 20260813
const CELL_M: int = 32
const PLAYABLE_LIMIT_M: float = 233.0

const ROUTE_CLEAR_M: float = 2.3
const FORD_CLEAR_M: float = 5.5
const CHECKPOINT_CLEAR_M: float = 4.5
const CAMERA_BLOCKER_CLEAR_M: float = 6.0

const GRASS_MAX_SLOPE_DEG: float = 38.0
const TREE_MAX_SLOPE_DEG: float = 26.0
const BOULDER_MAX_SLOPE_DEG: float = 44.0

const TRUNK_RADIUS_M: float = 0.34
const TRUNK_HEIGHT_M: float = 3.0
## En dessous de ce rayon d'emprise, un rocher n'a pas de collision : on
## marche dessus par la HeightMap, pas contre lui.
const BOULDER_COLLIDER_MIN_RADIUS_M: float = 0.55

## Profils par région — densités en éléments par m² de cellule. Le VIDE des
## régions sèches est une identité (masterplan §4 R08), pas un oubli.
const PROFILES: Dictionary = {
	&"r01_crete_de_l_aube": {
		"grass": 0.42, "tall": true, "flowers": 0.010, "trees": 0.0,
		"boulders": 0.0030,
	},
	&"r02_prairie_mille_fleurs": {
		"grass": 0.30, "tall": false, "flowers": 0.008, "trees": 0.0016,
		"boulders": 0.0030,
	},
	&"r03_val_de_neris": {
		"grass": 0.24, "tall": false, "flowers": 0.002, "trees": 0.0035,
		"boulders": 0.0060, "reeds": true,
	},
	&"r04_falaises_du_couchant": {
		"grass": 0.05, "tall": false, "flowers": 0.0, "trees": 0.0,
		"boulders": 0.0100,
	},
	&"r05_terrasse_du_camp": {
		"grass": 0.20, "tall": false, "flowers": 0.002, "trees": 0.0010,
		"boulders": 0.0030,
	},
	&"r06_bois_du_levant": {
		"grass": 0.16, "tall": false, "flowers": 0.001, "trees": 0.0100,
		"boulders": 0.0040, "clusters": true,
	},
	&"r07_hauteurs_de_l_orient": {
		"grass": 0.05, "tall": false, "flowers": 0.0, "trees": 0.0014,
		"boulders": 0.0100,
	},
	&"r08_steppe_du_nord": {
		"grass": 0.045, "tall": false, "flowers": 0.0, "trees": 0.0008,
		"boulders": 0.0080,
	},
	&"r09_ruines_du_coeur": {
		"grass": 0.09, "tall": false, "flowers": 0.0, "trees": 0.0010,
		"boulders": 0.0080,
	},
	&"r10_marche_de_l_orage": {
		"grass": 0.010, "tall": false, "flowers": 0.0, "trees": 0.0010,
		"boulders": 0.0060, "dead": true,
	},
}

## Espèces par usage — modèles Quaternius CC0 déjà attribués (ART-Q0/Q8/Q9).
const TREES_MEADOW: Array[StringName] = [&"CommonTree_1", &"CommonTree_3", &"CommonTree_5"]
const TREES_RIVERSIDE: Array[StringName] = [&"CommonTree_2", &"CommonTree_4"]
const TREES_WOOD: Array[StringName] = [&"CommonTree_1", &"CommonTree_2",
	&"CommonTree_4", &"Pine_1", &"Pine_3"]
const TREES_DRY: Array[StringName] = [&"TwistedTree_1", &"TwistedTree_2", &"Pine_4"]
const TREES_DEAD: Array[StringName] = [&"DeadTree_1", &"DeadTree_2", &"TwistedTree_3"]
const FLOWER_MODELS: Array[StringName] = [&"Flower_3_Group", &"Flower_4_Group"]
const BOULDER_MODELS: Array[StringName] = [&"Rock_Medium_1", &"Rock_Medium_2", &"Rock_Medium_3"]
const PEBBLE_MODELS: Array[StringName] = [&"Pebble_Round_2", &"Pebble_Round_4", &"Pebble_Square_1"]

const FOLIAGE_SHADER: String = "res://shaders/foliage/foliage_wind.gdshader"

var _heightmap: WorldV2Heightmap = null
var _terrain: WorldV2TerrainBuilder = null
var _route_segments: Array[Array] = []
var _water_segments: Array[Array] = []
var _fords: Array[Vector2] = []
var _checkpoints: Array[Vector2] = []
var _camera_eyes: Array[Vector2] = []
var _mesh_cache: Dictionary = {}
var _grass_short: ArrayMesh = null
var _grass_tall: ArrayMesh = null
var _reed_mesh: ArrayMesh = null


func _init(heightmap: WorldV2Heightmap, terrain: WorldV2TerrainBuilder,
		layout: Dictionary) -> void:
	_heightmap = heightmap
	_terrain = terrain
	var routes: Dictionary = layout.get("routes", {}) as Dictionary
	for route_name: String in ["main_path", "river_route", "heights_route", "ruins_route"]:
		var waypoints: Array = (routes.get(route_name, {}) as Dictionary) \
			.get("waypoints_xz", []) as Array
		for i: int in range(waypoints.size() - 1):
			var a: Array = waypoints[i] as Array
			var b: Array = waypoints[i + 1] as Array
			_route_segments.append([Vector2(float(a[0]), float(a[1])),
				Vector2(float(b[0]), float(b[1]))])
	var main_line: PackedVector2Array = heightmap.river_main_polyline()
	for i: int in range(main_line.size() - 1):
		_water_segments.append([main_line[i], main_line[i + 1]])
	var trib_line: PackedVector2Array = heightmap.river_trib_polyline()
	for i: int in range(trib_line.size() - 1):
		_water_segments.append([trib_line[i], trib_line[i + 1]])
	_fords = heightmap.fords().duplicate()
	for entry: Variant in layout.get("checkpoints", []) as Array:
		var pos: Variant = (entry as Dictionary).get("pos")
		if pos is Array and (pos as Array).size() == 3:
			_checkpoints.append(Vector2(float((pos as Array)[0]),
				float((pos as Array)[2])))
	for window: Array in WorldV2CamerasBuilder.WINDOWS:
		_camera_eyes.append(Vector2(float(window[1]), float(window[2])))
	_grass_short = _make_tuft_mesh(0.32, 6)
	_grass_tall = _make_tuft_mesh(0.72, 7)
	_reed_mesh = _make_tuft_mesh(1.05, 5)


func build(parent: Node3D) -> void:
	var cells_per_side: int = int(float(WorldV2Heightmap.CHUNK_SIZE_M
		* WorldV2Heightmap.GRID_COLS) / float(CELL_M))
	for cz: int in range(cells_per_side):
		for cx: int in range(cells_per_side):
			var origin_x: float = WorldV2Heightmap.ORIGIN_XZ + float(cx * CELL_M)
			var origin_z: float = WorldV2Heightmap.ORIGIN_XZ + float(cz * CELL_M)
			# Cellule entièrement hors zone jouable : rien à semer.
			var corner_min: float = Vector2(origin_x, origin_z).length()
			var center: Vector2 = Vector2(origin_x + CELL_M * 0.5, origin_z + CELL_M * 0.5)
			if center.length() - float(CELL_M) > PLAYABLE_LIMIT_M and corner_min > PLAYABLE_LIMIT_M:
				continue
			_build_cell(parent, cx, cz, origin_x, origin_z)


## -- construction d'une cellule ----------------------------------------------

func _build_cell(parent: Node3D, cx: int, cz: int,
		origin_x: float, origin_z: float) -> void:
	var grass: Array[Transform3D] = []
	var grass_tints: Array[Color] = []
	var tall: Array[Transform3D] = []
	var tall_tints: Array[Color] = []
	var reeds: Array[Transform3D] = []
	var flowers: Array[Transform3D] = []
	var trees: Dictionary = {}
	var boulders: Dictionary = {}
	var blockers: Array[Array] = []

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([GLOBAL_SEED, cx, cz])
	var area: float = float(CELL_M * CELL_M)
	# Contexte PRÉ-FILTRÉ par cellule : tester 85 000 candidats contre les
	# ~60 segments GLOBAUX de routes ferait des millions d'opérations pour
	# rien — même leçon que `_segments_near_chunk` du bâtisseur de terrain.
	var ctx: Dictionary = _cell_context(origin_x, origin_z)

	# 1. Herbe : tolérante, dense — l'identité de teinte suit la peinture du sol.
	var attempts: int = int(area * 0.5)
	for i: int in range(attempts):
		var p: Vector2 = Vector2(origin_x + rng.randf() * CELL_M,
			origin_z + rng.randf() * CELL_M)
		var profile: Dictionary = _profile_at(p)
		var density: float = float(profile.get("grass", 0.0))
		if density <= 0.0 or rng.randf() > density * 2.0:
			continue
		if not _spot_allows(p, GRASS_MAX_SLOPE_DEG, false, ctx):
			continue
		var t: Transform3D = _ground_transform(p, rng, 0.85, 1.30, -0.05)
		var tint: Color = _grass_tint(p, rng)
		if bool(profile.get("tall", false)) and rng.randf() < 0.6:
			tall.append(t)
			tall_tints.append(tint)
		else:
			grass.append(t)
			grass_tints.append(tint)

	# 2. Roseaux : uniquement la bande humide des berges (1,5-4,5 m du fil).
	if _cell_touches_water(origin_x, origin_z):
		for i: int in range(int(area * 0.03)):
			var p: Vector2 = Vector2(origin_x + rng.randf() * CELL_M,
				origin_z + rng.randf() * CELL_M)
			if not bool(_profile_at(p).get("reeds", false)):
				continue
			var d: float = _water_distance(p, ctx)
			if d < 1.5 or d > 4.5:
				continue
			if not _spot_allows(p, GRASS_MAX_SLOPE_DEG, false, ctx):
				continue
			reeds.append(_ground_transform(p, rng, 0.9, 1.25, -0.06))

	# 3. Fleurs : en PHRASES de 5-12 autour d'un centre (bible §7.4).
	var flower_profile: Dictionary = _profile_at(Vector2(origin_x + CELL_M * 0.5,
		origin_z + CELL_M * 0.5))
	var cluster_count: int = _stochastic_count(
		float(flower_profile.get("flowers", 0.0)) * area, rng)
	for c: int in range(cluster_count):
		var center: Vector2 = Vector2(origin_x + rng.randf() * CELL_M,
			origin_z + rng.randf() * CELL_M)
		if float(_profile_at(center).get("flowers", 0.0)) <= 0.0:
			continue
		if not _spot_allows(center, GRASS_MAX_SLOPE_DEG, false, ctx):
			continue
		for f: int in range(rng.randi_range(5, 12)):
			var p: Vector2 = center + Vector2(rng.randf_range(-1.6, 1.6),
				rng.randf_range(-1.6, 1.6))
			if _spot_allows(p, GRASS_MAX_SLOPE_DEG, false, ctx):
				flowers.append(_ground_transform(p, rng, 0.8, 1.15, -0.03))

	# 4. Arbres : bosquets dans le Bois, isolés ailleurs, morts dans la Marche.
	var tree_profile: Dictionary = _profile_at(Vector2(origin_x + CELL_M * 0.5,
		origin_z + CELL_M * 0.5))
	var tree_budget: int = _stochastic_count(
		float(tree_profile.get("trees", 0.0)) * area, rng)
	if bool(tree_profile.get("clusters", false)):
		var cluster_total: int = maxi(1, tree_budget / 4) if tree_budget > 0 else 0
		for c: int in range(cluster_total):
			var center: Vector2 = Vector2(origin_x + rng.randf() * CELL_M,
				origin_z + rng.randf() * CELL_M)
			for k: int in range(rng.randi_range(3, 7)):
				var p: Vector2 = center + Vector2(rng.randf_range(-7.0, 7.0),
					rng.randf_range(-7.0, 7.0))
				_try_tree(p, rng, trees, blockers, ctx)
	else:
		for i: int in range(tree_budget):
			var p: Vector2 = Vector2(origin_x + rng.randf() * CELL_M,
				origin_z + rng.randf() * CELL_M)
			_try_tree(p, rng, trees, blockers, ctx)

	# 5. Rochers posés : gros (collision) et cailloux (aucune).
	var boulder_budget: int = _stochastic_count(
		float(tree_profile.get("boulders", 0.0)) * area, rng)
	for i: int in range(boulder_budget):
		var p: Vector2 = Vector2(origin_x + rng.randf() * CELL_M,
			origin_z + rng.randf() * CELL_M)
		var profile: Dictionary = _profile_at(p)
		if float(profile.get("boulders", 0.0)) <= 0.0:
			continue
		if not _spot_allows(p, BOULDER_MAX_SLOPE_DEG, true, ctx):
			continue
		var big: bool = rng.randf() < 0.35
		var model: StringName = (BOULDER_MODELS if big else PEBBLE_MODELS)[
			rng.randi_range(0, 2)]
		var scale: float = rng.randf_range(0.9, 1.7) if big else rng.randf_range(0.8, 1.4)
		var t: Transform3D = _ground_transform(p, rng, scale, scale, -0.12)
		_append_model(boulders, model, t)
		if big:
			var radius: float = _mesh_radius(model) * scale
			if radius >= BOULDER_COLLIDER_MIN_RADIUS_M:
				blockers.append([t.origin, radius, "boulder"])

	# 6. Matérialiser la cellule.
	var cell_root: Node3D = Node3D.new()
	cell_root.name = "veg_c%dr%d" % [cx, cz]
	cell_root.position = Vector3(origin_x + CELL_M * 0.5, 0.0, origin_z + CELL_M * 0.5)
	var made: bool = false
	made = _emit_cells(cell_root, "grass", _grass_short, grass, grass_tints,
		_grass_material(0.32)) or made
	made = _emit_cells(cell_root, "tall", _grass_tall, tall, tall_tints,
		_grass_material(0.72)) or made
	made = _emit_cells(cell_root, "reeds", _reed_mesh, reeds, [],
		_reed_material()) or made
	if not flowers.is_empty():
		var model: StringName = FLOWER_MODELS[absi(hash([cx, cz])) % FLOWER_MODELS.size()]
		made = _emit_model_cells(cell_root, "flowers", model, flowers) or made
	for model: StringName in trees.keys():
		made = _emit_model_cells(cell_root, "tree_" + String(model), model,
			trees[model] as Array[Transform3D]) or made
	for model: StringName in boulders.keys():
		made = _emit_model_cells(cell_root, "rock_" + String(model), model,
			boulders[model] as Array[Transform3D]) or made
	if not made:
		cell_root.free()
		return
	for blocker: Array in blockers:
		cell_root.add_child(_make_blocker(blocker[0] as Vector3,
			float(blocker[1]), String(blocker[2]), cell_root.position))
	parent.add_child(cell_root)


func _append_model(bucket: Dictionary, model: StringName, t: Transform3D) -> void:
	if not bucket.has(model):
		var empty: Array[Transform3D] = []
		bucket[model] = empty
	(bucket[model] as Array[Transform3D]).append(t)


## -- règles de placement ------------------------------------------------------

func _profile_at(p: Vector2) -> Dictionary:
	return PROFILES.get(_terrain.region_id_at(p.x, p.y), {}) as Dictionary


## Contexte par cellule : seulement les couloirs qui la TOUCHENT.
func _cell_context(origin_x: float, origin_z: float) -> Dictionary:
	var rect: Rect2 = Rect2(origin_x, origin_z, float(CELL_M), float(CELL_M))
	var routes: Array[Array] = []
	var route_rect: Rect2 = rect.grow(ROUTE_CLEAR_M + 1.0)
	for segment: Array in _route_segments:
		var a: Vector2 = segment[0] as Vector2
		var b: Vector2 = segment[1] as Vector2
		if route_rect.intersects(Rect2(minf(a.x, b.x), minf(a.y, b.y),
				absf(b.x - a.x), absf(b.y - a.y)).grow(0.1)):
			routes.append(segment)
	var water: Array[Array] = []
	var water_rect: Rect2 = rect.grow(12.0)
	for segment: Array in _water_segments:
		var a: Vector2 = segment[0] as Vector2
		var b: Vector2 = segment[1] as Vector2
		if water_rect.intersects(Rect2(minf(a.x, b.x), minf(a.y, b.y),
				absf(b.x - a.x), absf(b.y - a.y)).grow(0.1)):
			water.append(segment)
	var fords: Array[Vector2] = []
	for ford: Vector2 in _fords:
		if rect.grow(FORD_CLEAR_M + 1.0).has_point(ford):
			fords.append(ford)
	var checkpoints: Array[Vector2] = []
	for checkpoint: Vector2 in _checkpoints:
		if rect.grow(CHECKPOINT_CLEAR_M + 1.0).has_point(checkpoint):
			checkpoints.append(checkpoint)
	var eyes: Array[Vector2] = []
	for eye: Vector2 in _camera_eyes:
		if rect.grow(CAMERA_BLOCKER_CLEAR_M + 1.0).has_point(eye):
			eyes.append(eye)
	return {"rect": rect, "routes": routes, "water": water, "fords": fords,
		"checkpoints": checkpoints, "eyes": eyes}


## Le point respecte les couloirs du contrat et le terrain.
func _spot_allows(p: Vector2, max_slope_deg: float, is_blocker: bool,
		ctx: Dictionary) -> bool:
	if p.length() > PLAYABLE_LIMIT_M:
		return false
	if _heightmap.is_in_water(p.x, p.y):
		return false
	if _heightmap.slope_deg_at(p.x, p.y) > max_slope_deg:
		return false
	for segment: Array in ctx["routes"] as Array[Array]:
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(
			p, segment[0] as Vector2, segment[1] as Vector2)
		if p.distance_to(closest) < ROUTE_CLEAR_M:
			return false
	for ford: Vector2 in ctx["fords"] as Array[Vector2]:
		if p.distance_to(ford) < FORD_CLEAR_M:
			return false
	for checkpoint: Vector2 in ctx["checkpoints"] as Array[Vector2]:
		if p.distance_to(checkpoint) < CHECKPOINT_CLEAR_M:
			return false
	if is_blocker:
		for eye: Vector2 in ctx["eyes"] as Array[Vector2]:
			if p.distance_to(eye) < CAMERA_BLOCKER_CLEAR_M:
				return false
	return true


func _try_tree(p: Vector2, rng: RandomNumberGenerator, trees: Dictionary,
		blockers: Array[Array], ctx: Dictionary) -> void:
	# Un arbre reste DANS sa cellule : un bosquet qui déborde gonflerait
	# l'emprise au-delà du plafond contractuel de 48 m.
	if not (ctx["rect"] as Rect2).has_point(p):
		return
	var profile: Dictionary = _profile_at(p)
	if float(profile.get("trees", 0.0)) <= 0.0:
		return
	if not _spot_allows(p, TREE_MAX_SLOPE_DEG, true, ctx):
		return
	# L'espèce suit l'identité : morts dans la Marche, rivière au Val,
	# bosquets mêlés au Bois, tordus sur les Hauteurs, isolés en prairie.
	var species: Array[StringName] = TREES_MEADOW
	if bool(profile.get("dead", false)):
		species = TREES_DEAD
	elif bool(profile.get("reeds", false)):
		species = TREES_RIVERSIDE
	elif bool(profile.get("clusters", false)):
		species = TREES_WOOD
	elif _water_distance(p, ctx) < 9.0:
		species = TREES_RIVERSIDE
	elif float(profile.get("grass", 1.0)) < 0.06:
		species = TREES_DRY
	var model: StringName = species[rng.randi_range(0, species.size() - 1)]
	var scale: float = rng.randf_range(0.85, 1.35)
	var t: Transform3D = _ground_transform(p, rng, scale, scale, -0.10)
	_append_model(trees, model, t)
	blockers.append([t.origin, TRUNK_RADIUS_M * scale, "trunk"])


func _ground_transform(p: Vector2, rng: RandomNumberGenerator,
		scale_min: float, scale_max: float, sink: float) -> Transform3D:
	var scale: float = rng.randf_range(scale_min, scale_max)
	var basis: Basis = Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale)
	return Transform3D(basis,
		Vector3(p.x, _heightmap.height_at(p.x, p.y) + sink, p.y))


func _grass_tint(p: Vector2, rng: RandomNumberGenerator) -> Color:
	var paint: Color = WorldV2TerrainBuilder.REGION_PAINT.get(
		_terrain.region_id_at(p.x, p.y),
		WorldV2TerrainBuilder.PAINT_FALLBACK) as Color
	var luma: float = rng.randf_range(0.9, 1.35)
	return Color(paint.r * luma * 1.35, paint.g * luma * 1.35,
		paint.b * luma * 1.20)


func _water_distance(p: Vector2, ctx: Dictionary) -> float:
	var best: float = p.distance_to(_heightmap.lake_center()) - _heightmap.lake_radius()
	for segment: Array in ctx["water"] as Array[Array]:
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(
			p, segment[0] as Vector2, segment[1] as Vector2)
		best = minf(best, p.distance_to(closest))
	return best


func _cell_touches_water(origin_x: float, origin_z: float) -> bool:
	var rect: Rect2 = Rect2(origin_x - 6.0, origin_z - 6.0,
		float(CELL_M) + 12.0, float(CELL_M) + 12.0)
	for segment: Array in _water_segments:
		var a: Vector2 = segment[0] as Vector2
		var b: Vector2 = segment[1] as Vector2
		if rect.intersects(Rect2(minf(a.x, b.x), minf(a.y, b.y),
				absf(b.x - a.x), absf(b.y - a.y)).grow(0.1)):
			return true
	return rect.grow(_heightmap.lake_radius()).has_point(_heightmap.lake_center())


## Densité fractionnaire → compte entier SANS biais (0,3/cellule = 30 % de
## chances d'en avoir un), déterministe par la graine de cellule.
func _stochastic_count(expected: float, rng: RandomNumberGenerator) -> int:
	var base: int = int(expected)
	if rng.randf() < expected - float(base):
		base += 1
	return base


## -- matérialisation ----------------------------------------------------------

## TROUVAILLE D'INGÉNIERIE (mesurée, source 4.7.1) : le renderer DUMMY du
## mode headless `--script` jette les données d'instance de MultiMesh —
## `_multimesh_instance_set_transform` est un no-op et le `get` rend
## l'identité (servers/rendering/dummy/storage/mesh_storage.h:191,202).
## Un test headless qui lirait le MultiMesh testerait le renderer factice,
## pas le monde. Le bâtisseur écrit donc son PLAN DE PLANTATION en méta du
## nœud — depuis les MÊMES valeurs, dans la MÊME boucle que l'écriture
## moteur : le headless prouve le plan, la capture (llvmpipe, vrai
## renderer) prouve le rendu.
func _emit_cells(cell_root: Node3D, layer: String, mesh: Mesh,
		transforms: Array[Transform3D], tints: Array[Color],
		material: Material) -> bool:
	if transforms.is_empty():
		return false
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not tints.is_empty()
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	var origins: PackedVector3Array = PackedVector3Array()
	var scales: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(transforms.size()):
		var t: Transform3D = transforms[i]
		t.origin -= cell_root.position
		mm.set_instance_transform(i, t)
		if mm.use_colors:
			mm.set_instance_color(i, tints[i])
		origins.append(transforms[i].origin)
		scales.append(t.basis.get_scale().x)
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = "%s_%s" % [cell_root.name, layer]
	instance.multimesh = mm
	instance.material_override = material
	instance.set_meta(&"instance_origins", origins)
	instance.set_meta(&"instance_scales", scales)
	instance.add_to_group(&"world_v2_vegetation")
	cell_root.add_child(instance)
	return true


func _emit_model_cells(cell_root: Node3D, layer: String, model: StringName,
		transforms: Array[Transform3D]) -> bool:
	if transforms.is_empty():
		return false
	var mesh: Mesh = _model_mesh(model, _category_tone(layer))
	if mesh == null:
		push_warning("[world_v2] modèle végétal introuvable : %s" % model)
		return false
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	var origins: PackedVector3Array = PackedVector3Array()
	var scales: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(transforms.size()):
		var t: Transform3D = transforms[i]
		t.origin -= cell_root.position
		mm.set_instance_transform(i, t)
		origins.append(transforms[i].origin)
		scales.append(t.basis.get_scale().x)
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = "%s_%s" % [cell_root.name, layer]
	instance.multimesh = mm
	instance.set_meta(&"instance_origins", origins)
	instance.set_meta(&"instance_scales", scales)
	instance.add_to_group(&"world_v2_vegetation")
	cell_root.add_child(instance)
	return true


func _make_blocker(world_pos: Vector3, radius: float, kind: String,
		cell_origin: Vector3) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "%s_%d_%d" % [kind, int(world_pos.x), int(world_pos.z)]
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group(&"world_v2_vegetation_colliders")
	body.position = world_pos - cell_origin
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Shape"
	if kind == "trunk":
		var cylinder: CylinderShape3D = CylinderShape3D.new()
		cylinder.radius = radius
		cylinder.height = TRUNK_HEIGHT_M
		shape.shape = cylinder
		shape.position = Vector3(0.0, TRUNK_HEIGHT_M * 0.5, 0.0)
	else:
		var sphere: SphereShape3D = SphereShape3D.new()
		sphere.radius = radius
		shape.shape = sphere
		shape.position = Vector3(0.0, radius * 0.5, 0.0)
	body.add_child(shape)
	return body


## -- ressources partagées -----------------------------------------------------

## Touffe d'herbe générée (AD-001 : rien de téléchargé pour l'herbe) : un
## éventail de lames croisées, base au sol, compatible `foliage_wind`.
func _make_tuft_mesh(height: float, blades: int) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([GLOBAL_SEED, "tuft", height, blades])
	for b: int in range(blades):
		var yaw: float = TAU * float(b) / float(blades) + rng.randf_range(-0.3, 0.3)
		var direction: Vector3 = Vector3(cos(yaw), 0.0, sin(yaw))
		var base: Vector3 = direction * rng.randf_range(0.02, 0.10)
		var lean: Vector3 = direction * rng.randf_range(0.08, 0.22)
		var blade_h: float = height * rng.randf_range(0.75, 1.15)
		var half_w: Vector3 = Vector3(-direction.z, 0.0, direction.x) \
			* rng.randf_range(0.025, 0.05)
		var tip: Vector3 = base + lean + Vector3(0.0, blade_h, 0.0)
		st.add_vertex(base - half_w)
		st.add_vertex(base + half_w)
		st.add_vertex(tip + half_w * 0.25)
		st.add_vertex(base - half_w)
		st.add_vertex(tip + half_w * 0.25)
		st.add_vertex(tip - half_w * 0.25)
	st.generate_normals()
	return st.commit()


static var _grass_materials: Dictionary = {}


func _grass_material(blade_height: float) -> ShaderMaterial:
	var key: String = "h%.2f" % blade_height
	if _grass_materials.has(key):
		return _grass_materials[key] as ShaderMaterial
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load(FOLIAGE_SHADER) as Shader
	# Blanc : la teinte vient ENTIÈREMENT de l'instance (peinture de région).
	material.set_shader_parameter(&"albedo", Vector3(1.0, 1.0, 1.0))
	material.set_shader_parameter(&"blade_height", blade_height)
	material.set_shader_parameter(&"sway_amplitude", 0.05 + blade_height * 0.05)
	_grass_materials[key] = material
	return material


func _reed_material() -> ShaderMaterial:
	if _grass_materials.has("reed"):
		return _grass_materials["reed"] as ShaderMaterial
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load(FOLIAGE_SHADER) as Shader
	material.set_shader_parameter(&"albedo", Vector3(0.30, 0.42, 0.28))
	material.set_shader_parameter(&"blade_height", 1.05)
	material.set_shader_parameter(&"sway_amplitude", 0.10)
	_grass_materials["reed"] = material
	return material


## Ton par catégorie : les feuillages Quaternius bruts sont NÉON sous le
## soleil miel (mesuré cam01 : les canopées sortaient de la palette pendant
## que le sol calibré restait olive). On assagit vers l'olive de §1.4 ; les
## fleurs restent des accents vifs ; les rochers glissent vers l'ocre.
func _category_tone(layer: String) -> Color:
	if layer.begins_with("tree_"):
		return Color(0.72, 0.74, 0.58)
	if layer.begins_with("rock_"):
		return Color(0.95, 0.88, 0.78)
	return Color(1.0, 1.0, 1.0)


## Maillage d'un modèle CC0, DUPLIQUÉ puis assagi — on ne mute jamais la
## ressource partagée du dépôt, et le painterly est MAT (§7.1 : pas de
## hotspot plastique).
func _model_mesh(model: StringName, tone: Color = Color(1, 1, 1)) -> Mesh:
	var key: String = "%s|%s" % [model, tone.to_html(false)]
	if _mesh_cache.has(key):
		return _mesh_cache[key] as Mesh
	var packed: PackedScene = AssetRegistry.model(model)
	if packed == null:
		return null
	var node: Node = packed.instantiate()
	var source: Mesh = _find_mesh(node)
	var mesh: Mesh = null
	if source != null:
		mesh = source.duplicate() as Mesh
		for s: int in range(mesh.get_surface_count()):
			var material: Material = mesh.surface_get_material(s)
			if material is StandardMaterial3D:
				var copy: StandardMaterial3D = \
					(material as StandardMaterial3D).duplicate() as StandardMaterial3D
				copy.vertex_color_use_as_albedo = false
				copy.albedo_color = Color(copy.albedo_color.r * tone.r,
					copy.albedo_color.g * tone.g, copy.albedo_color.b * tone.b,
					copy.albedo_color.a)
				copy.roughness = maxf(copy.roughness, 0.95)
				copy.metallic_specular = 0.1
				mesh.surface_set_material(s, copy)
	node.free()
	_mesh_cache[key] = mesh
	return mesh


func _mesh_radius(model: StringName) -> float:
	var mesh: Mesh = _model_mesh(model)
	if mesh == null:
		return 0.0
	var size: Vector3 = mesh.get_aabb().size
	return maxf(size.x, size.z) * 0.5


func _find_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return (node as MeshInstance3D).mesh
	for child: Node in node.get_children():
		var found: Mesh = _find_mesh(child)
		if found != null:
			return found
	return null
