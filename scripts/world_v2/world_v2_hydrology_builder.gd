## Bâtisseur de l'EAU de diagnostic V2.1 — surfaces simples, aucun VFX.
##
## L'eau whitebox dit une seule chose : « ici, la surface est à cette
## altitude ». Rubans de quads le long des cours (surface = profil du lit
## + tirant d'eau), disque du lac, matériau bleu translucide non éclairé.
## Aucune collision — le sol du lit porte le joueur, les berges escaladables
## garantissent qu'il n'est jamais piégé (D-019).
##
## S'y ajoute le TABLIER WHITEBOX du pont magnétique : une passerelle
## statique marchable au-dessus du bras nord. Le MÉCANISME (Polarité) reste
## une phase ultérieure — ici, seule la structure spatiale existe, et son
## nom le crie.
class_name WorldV2HydrologyBuilder
extends RefCounted

## 4 m (V2.2R.1) : à 8 m, une descente raide produisait une MARCHE de
## surface de 2,71 m entre deux arêtes — un mur d'eau (mesuré par le filet
## des raccords).
const WATER_STEP_M: float = 4.0
const MAIN_HALF_W: float = 4.2
const TRIB_HALF_W: float = 2.6
const MAIN_DRAFT: float = 0.9
const TRIB_DRAFT: float = 0.6

var _heightmap: WorldV2Heightmap = null
var _layout: Dictionary = {}
var _material: ShaderMaterial = null

## Facteur de profondeur plein à partir de cette hauteur d'eau (m).
const DEPTH_FULL_M: float = 2.5


func _init(heightmap: WorldV2Heightmap, layout: Dictionary) -> void:
	_heightmap = heightmap
	_layout = layout
	# Eau V2.2 : couleur par profondeur, courant, mousse de rive — les
	# données vivent dans les COULEURS DE SOMMET (r profondeur, gb courant).
	_material = ShaderMaterial.new()
	_material.shader = load("res://shaders/world_v2/SH_WorldV2Water.gdshader") as Shader
	_material.set_shader_parameter(&"wave_noise",
		WorldV2GroundMaterial.grain_texture())


func build(water_parent: Node3D, landmarks_parent: Node3D) -> void:
	# V2.2R.1 : sources ENFOUIES sous le terrain, embouchure sous le plan du
	# lac. V2.2R.2 : la confluence affluent→cours principal est une VRAIE
	# jonction topologique — le ruban de l'affluent s'arrête avant l'emprise
	# du cours principal et une PIÈCE DE CONFLUENCE triangulée relie son
	# arête terminale aux sommets de bord EXACTS du cours principal (soudure
	# par positions identiques, aucune T-junction : la bouche couvre des
	# arêtes de bord ENTIÈRES). Filets : F (extrémités) et F2 (confluence),
	# tous deux écrits rouges d'abord.
	var main_profile: Dictionary = _course_profile(
		_heightmap.river_main_polyline(), MAIN_HALF_W, MAIN_DRAFT,
		true, PackedVector2Array(), 0.0)
	var trib_profile: Dictionary = _course_profile(
		_heightmap.river_trib_polyline(), TRIB_HALF_W, TRIB_DRAFT,
		true, _heightmap.river_main_polyline(), MAIN_HALF_W + 3.5)
	water_parent.add_child(_strip_mesh("MainCourseWater", main_profile))
	water_parent.add_child(_strip_mesh("TributaryWater", trib_profile))
	water_parent.add_child(_confluence_patch(trib_profile, main_profile))
	water_parent.add_child(_lake())
	water_parent.add_child(_deep_water_obstruction())
	_build_ford_markers(landmarks_parent)
	landmarks_parent.add_child(_whitebox_bridge_deck())


## Profil COMPLET d'un cours : points échantillonnés (coudes arrondis par
## Chaikin, source enfouie), surfaces lissées, et ARÊTES 3D gauche/droite
## mitrées par point — la bande ET la pièce de confluence lisent les MÊMES
## sommets, c'est ce qui rend la soudure exacte (V2.2R.2).
func _course_profile(line: PackedVector2Array, half_w: float, draft: float,
		buried_start: bool, trim_fil: PackedVector2Array,
		trim_dist: float) -> Dictionary:
	line = _chaikin(line, 2)
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(line.size() - 1):
		var a: Vector2 = line[i]
		var b: Vector2 = line[i + 1]
		var steps: int = maxi(1, int(ceilf(a.distance_to(b) / WATER_STEP_M)))
		for s: int in range(steps):
			points.append(a.lerp(b, float(s) / float(steps)))
	points.append(line[line.size() - 1])
	# Fin SOUDÉE (affluent) : le ruban s'arrête AVANT l'emprise du cours
	# principal — la pièce de confluence prend le relais jusqu'au bord.
	if not trim_fil.is_empty():
		while points.size() > 2 and _dist_to_line(
				points[points.size() - 1], trim_fil) < trim_dist:
			points.remove_at(points.size() - 1)
	var overrides: PackedFloat32Array = PackedFloat32Array()
	overrides.resize(points.size())
	overrides.fill(-1e9)
	if buried_start:
		var head: Array = _buried_extension(points[0],
			(points[0] - points[1]).normalized(), draft)
		var new_points: PackedVector2Array = PackedVector2Array()
		var new_overrides: PackedFloat32Array = PackedFloat32Array()
		for entry: Array in head:
			new_points.append(entry[0] as Vector2)
			new_overrides.append(float(entry[1]))
		new_points.append_array(points)
		new_overrides.append_array(overrides)
		points = new_points
		overrides = new_overrides

	# Surfaces : naturelles puis LISSÉES (les imposées ne bougent pas).
	var surfaces: PackedFloat32Array = PackedFloat32Array()
	surfaces.resize(points.size())
	for k: int in range(points.size()):
		if overrides[k] > -1e8:
			surfaces[k] = overrides[k]
			continue
		var bed: float = _heightmap.height_at(points[k].x, points[k].y)
		surfaces[k] = minf(bed + draft,
			maxf(_heightmap.water_surface_at(points[k].x, points[k].y), bed + 0.15))
	for k: int in range(1, points.size() - 1):
		if overrides[k] > -1e8:
			continue
		var smoothed: float = (surfaces[k - 1] + surfaces[k] * 2.0
			+ surfaces[k + 1]) * 0.25
		var bed: float = _heightmap.height_at(points[k].x, points[k].y)
		surfaces[k] = maxf(smoothed, bed + 0.10)

	# Arêtes 3D mitrées et données de sommet par point.
	var lefts: PackedVector3Array = PackedVector3Array()
	var rights: PackedVector3Array = PackedVector3Array()
	var datas: PackedColorArray = PackedColorArray()
	for k: int in range(points.size()):
		var p: Vector2 = points[k]
		var into: Vector2 = (p - points[k - 1]).normalized() if k > 0 else Vector2.ZERO
		var out_of: Vector2 = (points[k + 1] - p).normalized() \
			if k < points.size() - 1 else Vector2.ZERO
		var direction: Vector2 = (into + out_of).normalized() \
			if (into + out_of).length() > 0.001 \
			else (into if into != Vector2.ZERO else out_of)
		var side: Vector2 = Vector2(-direction.y, direction.x) * half_w
		var bed: float = _heightmap.height_at(p.x, p.y)
		lefts.append(Vector3(p.x + side.x, surfaces[k], p.y + side.y))
		rights.append(Vector3(p.x - side.x, surfaces[k], p.y - side.y))
		datas.append(Color(clampf((surfaces[k] - bed) / DEPTH_FULL_M, 0.0, 1.0),
			direction.x * 0.5 + 0.5, direction.y * 0.5 + 0.5, 1.0))
	return {"points": points, "surfaces": surfaces, "lefts": lefts,
		"rights": rights, "datas": datas, "half_w": half_w}


## Bande continue d'un profil, quads mitrés, NORMALES verticales explicites
## (V2.2R.2 — mesuré par F2 : les rubans n'avaient AUCUNE normale, la
## continuité d'éclairage au raccord était indéfinissable).
func _strip_mesh(strip_name: String, profile: Dictionary) -> MeshInstance3D:
	var lefts: PackedVector3Array = profile["lefts"]
	var rights: PackedVector3Array = profile["rights"]
	var datas: PackedColorArray = profile["datas"]
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in range(1, lefts.size()):
		st.set_normal(Vector3.UP)
		st.set_color(datas[k - 1])
		st.add_vertex(lefts[k - 1])
		st.set_normal(Vector3.UP)
		st.set_color(datas[k])
		st.add_vertex(rights[k])
		st.set_normal(Vector3.UP)
		st.set_color(datas[k - 1])
		st.add_vertex(rights[k - 1])
		st.set_normal(Vector3.UP)
		st.set_color(datas[k - 1])
		st.add_vertex(lefts[k - 1])
		st.set_normal(Vector3.UP)
		st.set_color(datas[k])
		st.add_vertex(lefts[k])
		st.set_normal(Vector3.UP)
		st.set_color(datas[k])
		st.add_vertex(rights[k])
	var mesh: ArrayMesh = st.commit()
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, _material)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = strip_name
	instance.mesh = mesh
	instance.add_to_group(&"world_v2_water")
	return instance


## PIÈCE DE CONFLUENCE (V2.2R.2) : surface commune triangulée entre l'arête
## terminale de l'affluent et le BORD du cours principal.
##
## Soudure RÉELLE : la rangée côté affluent réutilise les sommets EXACTS de
## sa dernière arête ; la rangée côté cours principal réutilise des sommets
## de bord ENTIERS du maillage principal (trois sommets consécutifs — aucun
## sommet posé au milieu d'une arête, donc aucune T-junction). Une rangée
## intermédiaire ÉVASÉE arrondit les deux pointes (rejet du lead). Les UV
## sont en espace monde dans le shader : continuité automatique ; le
## courant se fond de la direction de l'affluent vers celle du principal.
func _confluence_patch(trib: Dictionary, main: Dictionary) -> MeshInstance3D:
	var trib_lefts: PackedVector3Array = trib["lefts"]
	var trib_rights: PackedVector3Array = trib["rights"]
	var trib_datas: PackedColorArray = trib["datas"]
	var last: int = trib_lefts.size() - 1
	var mouth_left: Vector3 = trib_lefts[last]
	var mouth_right: Vector3 = trib_rights[last]
	var mouth_mid: Vector3 = (mouth_left + mouth_right) * 0.5
	# Index du point principal le plus proche de la bouche.
	var main_points: PackedVector2Array = main["points"]
	var nearest: int = 1
	var best: float = 1e9
	for k: int in range(main_points.size()):
		var d: float = main_points[k].distance_to(Vector2(mouth_mid.x, mouth_mid.z))
		if d < best:
			best = d
			nearest = k
	nearest = clampi(nearest, 2, main_points.size() - 3)
	# Côté du cours principal qui FAIT FACE à l'affluent.
	var main_lefts: PackedVector3Array = main["lefts"]
	var main_rights: PackedVector3Array = main["rights"]
	var left_d: float = main_lefts[nearest].distance_to(mouth_mid)
	var right_d: float = main_rights[nearest].distance_to(mouth_mid)
	var edge: PackedVector3Array = main_lefts if left_d < right_d else main_rights
	var main_datas: PackedColorArray = main["datas"]
	# CINQ sommets de bord CONSÉCUTIFS (arêtes entières, zéro T-junction).
	# Trois ne suffisaient pas : la sonde a mesuré un coin en biseau de
	# ~0,1 m entre le flanc de la pièce et le bord principal, 0,16 m AU-DELÀ
	# du premier sommet soudé (trou F2 en (-22.2, 6.9)). Élargir la fenêtre
	# d'un sommet de chaque côté englobe les deux coins.
	var weld: PackedVector3Array = PackedVector3Array([
		edge[nearest - 2], edge[nearest - 1], edge[nearest],
		edge[nearest + 1], edge[nearest + 2]])
	# Orientation : le premier sommet soudé du côté de la gauche de la bouche.
	if mouth_left.distance_to(weld[0]) > mouth_left.distance_to(weld[4]):
		weld.reverse()
	# Rangée intermédiaire ÉVASÉE : trois points entre la bouche (élargie de
	# 30 %) et le bord — les pointes deviennent obtuses, la largeur et la
	# hauteur évoluent continûment (écart par rangée mesuré ≤ 5 cm par F2).
	var flare_left: Vector3 = mouth_mid + (mouth_left - mouth_mid) * 1.3
	var flare_right: Vector3 = mouth_mid + (mouth_right - mouth_mid) * 1.3
	var m0: Vector3 = flare_left.lerp(weld[0], 0.5)
	var m1: Vector3 = mouth_mid.lerp(weld[2], 0.5)
	var m2: Vector3 = flare_right.lerp(weld[4], 0.5)
	var trib_data: Color = trib_datas[last]
	var main_data: Color = main_datas[nearest]
	var mid_data: Color = Color(
		(trib_data.r + main_data.r) * 0.5, (trib_data.g + main_data.g) * 0.5,
		(trib_data.b + main_data.b) * 0.5, 1.0)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var weld_row: Array = []
	for w: Vector3 in weld:
		weld_row.append([w, main_data])
	var rows: Array = [
		[[mouth_left, trib_data], [mouth_right, trib_data]],
		[[m0, mid_data], [m1, mid_data], [m2, mid_data]],
		weld_row,
	]
	_stitch_rows(st, rows[0] as Array, rows[1] as Array)
	_stitch_rows(st, rows[1] as Array, rows[2] as Array)
	st.index()
	var mesh: ArrayMesh = st.commit()
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, _material)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = "ConfluenceWater"
	instance.mesh = mesh
	instance.add_to_group(&"world_v2_water")
	return instance


## Triangule deux rangées de sommets [position, data] en éventail régulier,
## enroulement corrigé pour que la face regarde le ciel.
func _stitch_rows(st: SurfaceTool, near_row: Array, far_row: Array) -> void:
	var i: int = 0
	var j: int = 0
	while i < near_row.size() - 1 or j < far_row.size() - 1:
		var advance_far: bool = false
		if i >= near_row.size() - 1:
			advance_far = true
		elif j < far_row.size() - 1:
			var na: Vector3 = (near_row[i + 1] as Array)[0] as Vector3
			var fa: Vector3 = (far_row[j] as Array)[0] as Vector3
			var nb: Vector3 = (near_row[i] as Array)[0] as Vector3
			var fb: Vector3 = (far_row[j + 1] as Array)[0] as Vector3
			advance_far = nb.distance_to(fb) < na.distance_to(fa)
		if advance_far:
			_patch_triangle(st, near_row[i] as Array, far_row[j] as Array,
				far_row[j + 1] as Array)
			j += 1
		else:
			_patch_triangle(st, near_row[i] as Array, far_row[j] as Array,
				near_row[i + 1] as Array)
			i += 1


func _patch_triangle(st: SurfaceTool, a: Array, b: Array, c: Array) -> void:
	var pa: Vector3 = a[0] as Vector3
	var pb: Vector3 = b[0] as Vector3
	var pc: Vector3 = c[0] as Vector3
	var ordered: Array = [a, b, c]
	if (pb - pa).cross(pc - pa).y < 0.0:
		ordered = [a, c, b]
	for entry: Variant in ordered:
		st.set_normal(Vector3.UP)
		st.set_color((entry as Array)[1] as Color)
		st.add_vertex((entry as Array)[0] as Vector3)


func _dist_to_line(p: Vector2, line: PackedVector2Array) -> float:
	var best: float = 1e9
	for i: int in range(line.size() - 1):
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(
			p, line[i], line[i + 1])))
	return best


## Coupe de coins de Chaikin : chaque segment est remplacé par ses points
## à 25 % et 75 % — les coudes s'arrondissent, les EXTRÉMITÉS ne bougent
## pas (les traitements d'extrémité s'y accrochent).
func _chaikin(line: PackedVector2Array, passes: int) -> PackedVector2Array:
	var current: PackedVector2Array = line
	for p: int in range(passes):
		var smoothed: PackedVector2Array = PackedVector2Array()
		smoothed.append(current[0])
		for i: int in range(current.size() - 1):
			smoothed.append(current[i].lerp(current[i + 1], 0.25))
			smoothed.append(current[i].lerp(current[i + 1], 0.75))
		smoothed.append(current[current.size() - 1])
		current = smoothed
	return current


## Prolongement ENFOUI d'une source : trois points continuant le fil vers
## l'amont, surface imposée qui plonge sous le terrain — le ruban émerge du
## sol au lieu de flotter en l'air (cap mesuré à 0,90 m au-dessus du sol).
## Retourne [[point, surface_imposée], …] du plus LOINTAIN au plus proche.
func _buried_extension(origin: Vector2, away: Vector2, draft: float) -> Array:
	var entries: Array = []
	var origin_bed: float = _heightmap.height_at(origin.x, origin.y)
	var natural: float = minf(origin_bed + draft,
		maxf(_heightmap.water_surface_at(origin.x, origin.y), origin_bed + 0.15))
	for distance_and_sink: Array in [[8.0, 1.2], [4.5, 0.8], [2.0, 0.35]]:
		var p: Vector2 = origin + away * float(distance_and_sink[0])
		var ground: float = _heightmap.height_at(p.x, p.y)
		# Sous le sol LOCAL et jamais plus haut que la surface naturelle du
		# départ : le prolongement descend, il ne fait pas un dôme.
		entries.append([p, minf(ground - float(distance_and_sink[1]),
			natural - 0.10)])
	return entries


## Disque du lac en ÉVENTAIL avec profondeur par sommet : pétrole au
## centre du bol, turquoise à la rive — le miroir sombre du masterplan R10,
## sans re-toucher ni le niveau ni le bol (gelés V2.1).
func _lake() -> MeshInstance3D:
	var center: Vector2 = _heightmap.lake_center()
	var radius: float = _heightmap.lake_radius() + WorldV2Heightmap.LAKE_SHORE_W * 0.5
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments: int = 40
	var center_depth: Color = Color(1.0, 0.5, 0.5)
	for i: int in range(segments):
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float(i + 1) / float(segments)
		var p0: Vector2 = Vector2(cos(a0), sin(a0)) * radius
		var p1: Vector2 = Vector2(cos(a1), sin(a1)) * radius
		var d0: Color = _lake_rim_data(center + p0)
		var d1: Color = _lake_rim_data(center + p1)
		st.set_color(center_depth)
		st.add_vertex(Vector3.ZERO)
		st.set_color(d1)
		st.add_vertex(Vector3(p1.x, 0.0, p1.y))
		st.set_color(d0)
		st.add_vertex(Vector3(p0.x, 0.0, p0.y))
	var mesh: ArrayMesh = st.commit()
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, _material)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = "StormLakeWater"
	instance.mesh = mesh
	instance.add_to_group(&"world_v2_water")
	instance.position = Vector3(center.x, -0.5, center.y)
	return instance


func _lake_rim_data(world_xz: Vector2) -> Color:
	var depth: float = clampf(
		(-0.5 - _heightmap.height_at(world_xz.x, world_xz.y)) / DEPTH_FULL_M,
		0.0, 1.0)
	return Color(depth, 0.5, 0.5)


## L'EAU PROFONDE du lac n'est pas marchable : obstruction de navigation
## DÉCLARÉE, creusée dans le bake (`affect/carve_navigation_mesh`). Ce n'est
## pas un artifice : c'est la règle « on ne patrouille pas sous 5 m d'eau »
## exprimée là où le bake la lit — sans elle, le lit du bras nord (28°)
## descendait tranquillement dans le bol et « l'île » était un mensonge
## (mesuré : un chemin atteignait le centre du lac à 1,8 m près).
func _deep_water_obstruction() -> NavigationObstacle3D:
	var obstruction: NavigationObstacle3D = NavigationObstacle3D.new()
	obstruction.name = "DeepWaterObstruction"
	obstruction.affect_navigation_mesh = true
	obstruction.carve_navigation_mesh = true
	# Emprise : le disque immergé (h < surface -0,5) a le rayon du lac —
	# marge de 1 m pour couvrir la ligne d'eau. Le contour est en Vector3
	# (plan XZ) — source 4.7.1 : `Vector<Vector3> vertices`.
	var radius: float = _heightmap.lake_radius() + 1.0
	var outline: PackedVector3Array = PackedVector3Array()
	for i: int in range(16):
		var azimuth: float = TAU * float(i) / 16.0
		outline.append(Vector3(cos(azimuth) * radius, 0.0, sin(azimuth) * radius))
	obstruction.vertices = outline
	obstruction.height = 7.5
	var center: Vector2 = _heightmap.lake_center()
	obstruction.position = Vector3(center.x, -8.0, center.y)
	return obstruction


func _build_ford_markers(parent: Node3D) -> void:
	for entry: Variant in (_layout.get("river", {}) as Dictionary).get("fords", []) as Array:
		var ford: Dictionary = entry as Dictionary
		var pos: Array = ford.get("pos_xz", []) as Array
		if pos.size() != 2:
			continue
		var marker: Node3D = Node3D.new()
		marker.name = String(ford.get("id", "ford"))
		marker.add_to_group(&"world_v2_ford_markers")
		var x: float = float(pos[0])
		var z: float = float(pos[1])
		marker.position = Vector3(x, _heightmap.height_at(x, z), z)
		marker.set_meta(&"links", ford.get("links", []))
		parent.add_child(marker)


## Tablier STATIQUE du pont magnétique — structure spatiale seulement, le
## mécanisme de Polarité appartient à une phase ultérieure.
func _whitebox_bridge_deck() -> StaticBody3D:
	var abutment: Vector3 = _site_of(&"valley.poi.magnetic_bridge.01")
	var deck: StaticBody3D = StaticBody3D.new()
	deck.name = "WHITEBOX_MagneticBridgeDeck"
	deck.collision_layer = 1
	deck.collision_mask = 0
	deck.add_to_group(&"world_v2_whitebox")
	# Du côté ouest (l'abutment du layout) vers la berge est : le tablier
	# enjambe le bras nord (centre ≈ 13 m à l'est de l'abutment). LARGE de
	# 7 m : à 4 m, le parcours réel tombait du bord sud dans la gorge de
	# berge (56°, escaladable mais infranchissable à la marche) — mesuré par
	# le pilote de la route de la rivière, arrêté en (-26, 0.1, -61).
	deck.position = abutment + Vector3(13.0, 0.35, 0.0)
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(28.0, 0.5, 7.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	# Bois sombre : le tablier reste un PROXY (le vrai pont appartient à une
	# phase ultérieure) mais il ne crie plus orange dans les captures.
	material.albedo_color = Color(0.30, 0.22, 0.14)
	material.roughness = 0.95
	mesh.material = material
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = "DeckMesh"
	visual.mesh = mesh
	deck.add_child(visual)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = mesh.size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "DeckCollision"
	collision.shape = shape
	deck.add_child(collision)
	return deck


func _site_of(place_id: StringName) -> Vector3:
	for entry: Variant in _layout.get("systemic_sites", []) as Array:
		var site_entry: Dictionary = entry as Dictionary
		if StringName(String(site_entry.get("id", ""))) == place_id:
			var site: Array = site_entry.get("v2_site", []) as Array
			if site.size() == 3:
				return Vector3(float(site[0]), float(site[1]), float(site[2]))
	return Vector3.ZERO
