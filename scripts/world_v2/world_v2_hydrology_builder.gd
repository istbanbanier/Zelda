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
	# V2.2R.1 (famille F) : chaque extrémité de ruban est TRAITÉE — source
	# ENFOUIE sous le terrain (l'eau émerge du sol), confluence RENTRÉE sous
	# le cours principal, embouchure déjà sous le plan du lac. Le filet
	# `test_world_v2_water_junctions.gd` mesure les quatre caps (rouge avant).
	water_parent.add_child(_ribbon("MainCourseWater",
		_heightmap.river_main_polyline(), MAIN_HALF_W, MAIN_DRAFT,
		"buried", "free", PackedVector2Array()))
	water_parent.add_child(_ribbon("TributaryWater",
		_heightmap.river_trib_polyline(), TRIB_HALF_W, TRIB_DRAFT,
		"buried", "join", _heightmap.river_main_polyline()))
	water_parent.add_child(_lake())
	water_parent.add_child(_deep_water_obstruction())
	_build_ford_markers(landmarks_parent)
	landmarks_parent.add_child(_whitebox_bridge_deck())


## Ruban d'eau : surface au-dessus du LIT réel (jamais une bande plane —
## le profil descend avec la rivière), en bande CONTINUE à joints MITRÉS.
##
## V2.2R : le fil est échantillonné d'un bloc et chaque point porte UNE
## arête, orientée par la direction MOYENNÉE de ses deux segments (mitre).
## Filet : `test_world_v2_water_mesh.gd` (rouge avant).
##
## V2.2R.1 (rejet visuel du lead, region_r03 — « rubans terminés
## brutalement, raccords incomplets ») : chaque extrémité reçoit un
## TRAITEMENT explicite :
##   - `buried`  : le ruban se prolonge en amont et PLONGE sous le terrain
##                 (la source émerge du sol, aucun cap plat en l'air) ;
##   - `join`    : le ruban se prolonge jusqu'au fil de `join_line` et se
##                 RENTRE sous sa surface locale (confluence sans trou) ;
##   - `free`    : rien (l'embouchure passe déjà sous le plan du lac).
## La surface NATURELLE est lissée longitudinalement (une passe) : à 8 m
## d'échantillonnage une descente raide faisait une marche de 2,71 m.
## Filet : `test_world_v2_water_junctions.gd` (rouge avant, 4 écarts).
func _ribbon(ribbon_name: String, line: PackedVector2Array, half_w: float,
		draft: float, start_mode: String, end_mode: String,
		join_line: PackedVector2Array) -> MeshInstance3D:
	# 1. Échantillonner LE FIL ENTIER, puis prolonger les extrémités.
	# ARRONDIR d'abord les coudes (Chaikin ×2, extrémités conservées) : au
	# coude vif, l'arête mitrée pivotait d'un coup et le ruban se PINÇAIT en
	# pointe — lisible comme un « ruban terminé brutalement » (mesuré au
	# zoom r03, V2.2R.1). Le fil PHYSIQUE (carve, gués, hydrologie) reste
	# le fil gelé — seul le maillage visuel épouse la courbe.
	line = _chaikin(line, 2)
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(line.size() - 1):
		var a: Vector2 = line[i]
		var b: Vector2 = line[i + 1]
		var steps: int = maxi(1, int(ceilf(a.distance_to(b) / WATER_STEP_M)))
		for s: int in range(steps):
			points.append(a.lerp(b, float(s) / float(steps)))
	points.append(line[line.size() - 1])
	# `override[k]` >= -1e8 : surface IMPOSÉE ; `alphas[k]` : opacité de
	# sommet (le prolongement de confluence s'efface, jamais un empilement
	# d'alphas à bord lisible — rejet V2.2R.1, zoom de jonction).
	var overrides: PackedFloat32Array = PackedFloat32Array()
	overrides.resize(points.size())
	overrides.fill(-1e9)
	var alphas: PackedFloat32Array = PackedFloat32Array()
	alphas.resize(points.size())
	alphas.fill(1.0)
	if start_mode == "buried":
		var head: Array = _buried_extension(points[0],
			(points[0] - points[1]).normalized(), draft)
		var new_points: PackedVector2Array = PackedVector2Array()
		var new_overrides: PackedFloat32Array = PackedFloat32Array()
		var new_alphas: PackedFloat32Array = PackedFloat32Array()
		for entry: Array in head:
			new_points.append(entry[0] as Vector2)
			new_overrides.append(float(entry[1]))
			new_alphas.append(1.0)
		new_points.append_array(points)
		new_overrides.append_array(overrides)
		new_alphas.append_array(alphas)
		points = new_points
		overrides = new_overrides
		alphas = new_alphas
	if end_mode == "buried":
		var tail: Array = _buried_extension(points[points.size() - 1],
			(points[points.size() - 1] - points[points.size() - 2]).normalized(),
			draft)
		for i: int in range(tail.size() - 1, -1, -1):
			points.append((tail[i] as Array)[0] as Vector2)
			overrides.append(float((tail[i] as Array)[1]))
			alphas.append(1.0)
	elif end_mode == "join":
		for entry: Array in _join_extension(points[points.size() - 1], join_line):
			points.append(entry[0] as Vector2)
			overrides.append(float(entry[1]))
			alphas.append(float(entry[2]))

	# 2. Surfaces : naturelles puis LISSÉES (les imposées ne bougent pas).
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

	# 3. Émettre la bande continue.
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous_left: Vector3 = Vector3.ZERO
	var previous_right: Vector3 = Vector3.ZERO
	var previous_data: Color = Color.WHITE
	for k: int in range(points.size()):
		var p: Vector2 = points[k]
		var into: Vector2 = (p - points[k - 1]).normalized() if k > 0 else Vector2.ZERO
		var out_of: Vector2 = (points[k + 1] - p).normalized() 			if k < points.size() - 1 else Vector2.ZERO
		var direction: Vector2 = (into + out_of).normalized() 			if (into + out_of).length() > 0.001 else (into if into != Vector2.ZERO else out_of)
		var side: Vector2 = Vector2(-direction.y, direction.x) * half_w
		var bed: float = _heightmap.height_at(p.x, p.y)
		var surface: float = surfaces[k]
		var left: Vector3 = Vector3(p.x + side.x, surface, p.y + side.y)
		var right: Vector3 = Vector3(p.x - side.x, surface, p.y - side.y)
		# r = profondeur (bornée), gb = courant, a = opacité — lus par le shader.
		var vertex_data: Color = Color(
			clampf((surface - bed) / DEPTH_FULL_M, 0.0, 1.0),
			direction.x * 0.5 + 0.5, direction.y * 0.5 + 0.5, alphas[k])
		if k > 0:
			st.set_color(previous_data)
			st.add_vertex(previous_left)
			st.set_color(vertex_data)
			st.add_vertex(right)
			st.set_color(previous_data)
			st.add_vertex(previous_right)
			st.set_color(previous_data)
			st.add_vertex(previous_left)
			st.set_color(vertex_data)
			st.add_vertex(left)
			st.set_color(vertex_data)
			st.add_vertex(right)
		previous_left = left
		previous_right = right
		previous_data = vertex_data
	var mesh: ArrayMesh = st.commit()
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, _material)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = ribbon_name
	instance.mesh = mesh
	instance.add_to_group(&"world_v2_water")
	return instance


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


## Prolongement de CONFLUENCE : le fil continue jusqu'à 2 m À L'INTÉRIEUR
## du bord du ruban récepteur, surface glissée juste sous la sienne, et
## OPACITÉ qui s'efface dès le franchissement du bord — mesuré au zoom de
## jonction : un simple recouvrement empilait deux alphas et le bord de la
## nappe rentrée restait LISIBLE à travers le cours principal.
## Retourne [[point, surface_imposée, opacité], …] dans l'ordre d'ajout.
func _join_extension(origin: Vector2, receiver_line: PackedVector2Array) -> Array:
	var best: float = 1e9
	var closest: Vector2 = origin
	for i: int in range(receiver_line.size() - 1):
		var candidate: Vector2 = Geometry2D.get_closest_point_to_segment(
			origin, receiver_line[i], receiver_line[i + 1])
		var d: float = origin.distance_to(candidate)
		if d < best:
			best = d
			closest = candidate
	var receiver_bed: float = _heightmap.height_at(closest.x, closest.y)
	var receiver_surface: float = minf(receiver_bed + MAIN_DRAFT,
		maxf(_heightmap.water_surface_at(closest.x, closest.y),
			receiver_bed + 0.15))
	var toward: Vector2 = (closest - origin)
	if toward.length() < 0.001:
		return []
	var direction: Vector2 = toward.normalized()
	# S'arrêter 2 m PASSÉ le bord du récepteur (jamais jusqu'à son fil : le
	# filet exige < demi-largeur − 0,5 ; 2,2 m du fil le satisfait).
	var total: float = maxf(toward.length() - MAIN_HALF_W + 2.0, 2.0)
	var edge_at: float = maxf(toward.length() - MAIN_HALF_W, 0.5)
	var entries: Array = []
	var steps: int = maxi(3, int(ceilf(total / 1.5)))
	for s: int in range(1, steps + 1):
		var t: float = float(s) / float(steps)
		var traveled: float = total * t
		var p: Vector2 = origin + direction * traveled
		# Sous la surface du récepteur, opacité pleine jusqu'à son bord puis
		# effacement progressif — la confluence fond, elle ne se découpe pas.
		var past_edge: float = clampf((traveled - edge_at)
			/ maxf(total - edge_at, 0.001), 0.0, 1.0)
		entries.append([p, receiver_surface - 0.03 - 0.06 * t,
			1.0 - past_edge])
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
