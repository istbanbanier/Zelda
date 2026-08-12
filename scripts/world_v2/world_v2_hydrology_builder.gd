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

const WATER_STEP_M: float = 8.0
const MAIN_HALF_W: float = 4.2
const TRIB_HALF_W: float = 2.6
const MAIN_DRAFT: float = 0.9
const TRIB_DRAFT: float = 0.6

var _heightmap: WorldV2Heightmap = null
var _layout: Dictionary = {}
var _material: StandardMaterial3D = null


func _init(heightmap: WorldV2Heightmap, layout: Dictionary) -> void:
	_heightmap = heightmap
	_layout = layout
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = Color(0.25, 0.5, 0.75, 0.62)
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED


func build(water_parent: Node3D, landmarks_parent: Node3D) -> void:
	water_parent.add_child(_ribbon("MainCourseWater",
		_heightmap.river_main_polyline(), MAIN_HALF_W, MAIN_DRAFT))
	water_parent.add_child(_ribbon("TributaryWater",
		_heightmap.river_trib_polyline(), TRIB_HALF_W, TRIB_DRAFT))
	water_parent.add_child(_lake())
	_build_ford_markers(landmarks_parent)
	landmarks_parent.add_child(_whitebox_bridge_deck())


## Ruban d'eau : surface au-dessus du LIT réel (jamais une bande plane —
## le profil descend avec la rivière).
func _ribbon(ribbon_name: String, line: PackedVector2Array, half_w: float,
		draft: float) -> MeshInstance3D:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous_left: Vector3 = Vector3.ZERO
	var previous_right: Vector3 = Vector3.ZERO
	var has_previous: bool = false
	for i: int in range(line.size() - 1):
		var a: Vector2 = line[i]
		var b: Vector2 = line[i + 1]
		var seg_len: float = a.distance_to(b)
		var steps: int = maxi(1, int(ceilf(seg_len / WATER_STEP_M)))
		for s: int in range(steps + 1):
			var t: float = float(s) / float(steps)
			var p: Vector2 = a.lerp(b, t)
			var direction: Vector2 = (b - a).normalized()
			var side: Vector2 = Vector2(-direction.y, direction.x) * half_w
			# Le lit LOCAL fixe la surface : profil + tirant d'eau.
			var bed: float = _heightmap.height_at(p.x, p.y)
			var surface: float = minf(bed + draft,
				maxf(_heightmap.water_surface_at(p.x, p.y), bed + 0.15))
			var left: Vector3 = Vector3(p.x + side.x, surface, p.y + side.y)
			var right: Vector3 = Vector3(p.x - side.x, surface, p.y - side.y)
			if has_previous:
				st.add_vertex(previous_left)
				st.add_vertex(right)
				st.add_vertex(previous_right)
				st.add_vertex(previous_left)
				st.add_vertex(left)
				st.add_vertex(right)
			previous_left = left
			previous_right = right
			has_previous = true
	var mesh: ArrayMesh = st.commit()
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, _material)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = ribbon_name
	instance.mesh = mesh
	instance.add_to_group(&"world_v2_water")
	return instance


func _lake() -> MeshInstance3D:
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = _heightmap.lake_radius() + WorldV2Heightmap.LAKE_SHORE_W * 0.5
	disc.bottom_radius = disc.top_radius
	disc.height = 0.1
	disc.material = _material
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = "StormLakeWater"
	instance.mesh = disc
	instance.add_to_group(&"world_v2_water")
	var center: Vector2 = _heightmap.lake_center()
	instance.position = Vector3(center.x, -0.5, center.y)
	return instance


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
	# enjambe le bras nord (centre ≈ 13 m à l'est de l'abutment).
	deck.position = abutment + Vector3(13.0, 0.35, 0.0)
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(28.0, 0.5, 4.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.42, 0.28)
	mesh.material = material
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = "DeckMesh"
	visual.mesh = mesh
	visual.add_to_group(&"world_v2_navsource")
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
