## Relief macro de la Vallée de Néris — blockout D.1 (MASTER_SPEC §3.3, §7.4).
##
## Un blockout DÉCLARATIF : dalles (plateaux, terrasses, lit de rivière) et
## rampes en prismes convexes pleins — la leçon de B.1 (une boîte pivotée offre
## un dessous en surplomb ; un prisme convexe n'en a pas). Tout est déterministe,
## sans bruit ni aléa : les tests raisonnent sur des cotes exactes.
##
## La relation de §3.3 est portée par les masses : crête de départ (0, 24, 170),
## descente en S vers la terrasse du camp (45, 6, 65), lit de rivière autour de
## Z = 10 avec deux gués (les « deux routes » de §4.1), falaise d'apprentissage
## à l'ouest avec corniches de repos (§9.3), terrasse du pylône (115, 18, −25),
## forêt claire au sud-est, ruines centrales sur la route du donjon, et plateau
## monumental (0, 34, −210) portant le proxy de citadelle. Le pylône et la
## citadelle sont des PROXYS graybox : des masses à la bonne place, pas de l'art.
class_name ValleyTerrain
extends Node3D

## Épaisseur : toutes les dalles descendent jusqu'à cette profondeur — aucun
## interstice entre volumes voisins, donc aucune chute « dans » le relief.
const BASE_Y: float = -8.0

## Palette §3.4, en aplats graybox.
const COL_GRASS: Color = Color(0.365, 0.561, 0.239)
const COL_GRASS_DARK: Color = Color(0.30, 0.46, 0.21)
const COL_ROCK: Color = Color(0.608, 0.408, 0.259)
const COL_STONE: Color = Color(0.45, 0.44, 0.47)
const COL_WOOD: Color = Color(0.408, 0.251, 0.157)
const COL_COPPER: Color = Color(0.55, 0.36, 0.22)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)
const COL_RIVERBED: Color = Color(0.35, 0.42, 0.45)


func _ready() -> void:
	_build_border_mountains()
	_build_plains_and_river()
	_build_spawn_ridge_and_descent()
	_build_camp_terrace()
	_build_learning_cliff()
	_build_pylon_terrace_and_proxy()
	_build_forest()
	_build_central_ruins()
	_build_dungeon_plateau_and_citadel()


## ---------------------------------------------------------------------------
## Zones
## ---------------------------------------------------------------------------

## Limites du monde (D.1R.4, PT-D1-09) : une chaîne montagneuse continue,
## PHYSIQUE, remplace l'absence de bords — pas un mur invisible. Faces internes
## à ±250, 70 m de haut, marquées `unclimbable` (§9.2 : le groupe de refus
## existe depuis B.3) — l'endurance n'y suffirait de toute façon pas.
const BORDER_INNER: float = 250.0
const BORDER_OUTER: float = 292.0
const BORDER_TOP: float = 70.0
const COL_MOUNTAIN: Color = Color(0.42, 0.38, 0.4)


func _build_border_mountains() -> void:
	var mid: float = (BORDER_INNER + BORDER_OUTER) * 0.5
	var depth: float = BORDER_OUTER - BORDER_INNER
	var span: float = BORDER_OUTER * 2.0
	var walls: Array[Array] = [
		["BorderNorth", Vector2(0, -mid), Vector2(span, depth)],
		["BorderSouth", Vector2(0, mid), Vector2(span, depth)],
		["BorderWest", Vector2(-mid, 0), Vector2(depth, span)],
		["BorderEast", Vector2(mid, 0), Vector2(depth, span)],
	]
	for wall: Array in walls:
		_slab(wall[0], wall[1], wall[2], BORDER_TOP, COL_MOUNTAIN)
		var body: StaticBody3D = get_node_or_null(NodePath(String(wall[0]))) as StaticBody3D
		if body != null:
			body.add_to_group("unclimbable")

func _build_plains_and_river() -> void:
	# Plaine sud (côté spawn/camp) et plaine nord (côté donjon/pylône), séparées
	# par le lit de rivière en bande autour de Z = 10 (§3.3 : « rivière en S
	# autour de Z = 10 » — le S visuel viendra avec l'eau ; le LIT est la bande).
	_slab("PlainSouth", Vector2(0, 136), Vector2(512, 240), 2.0, COL_GRASS)
	_slab("PlainNorth", Vector2(0, -126), Vector2(512, 260), 2.0, COL_GRASS)
	_slab("Riverbed", Vector2(0, 10), Vector2(512, 12), -1.5, COL_RIVERBED)
	# Deux gués : la route du donjon (ouest) et la route du pylône (est).
	_slab("FordWest", Vector2(20, 10), Vector2(12, 12), 2.0, COL_GRASS_DARK)
	_slab("FordEast", Vector2(95, 10), Vector2(12, 12), 2.0, COL_GRASS_DARK)


func _build_spawn_ridge_and_descent() -> void:
	# Crête de départ : le héros domine la vallée (§3.2, spawn §3.3 (0, 24, 170)).
	_slab("SpawnRidge", Vector2(0, 176), Vector2(100, 64), 24.0, COL_GRASS)
	# Descente en S : trois rampes douces alternant la direction, deux paliers.
	_ramp("DescentA", Vector3(20, 24, 146), Vector3(34, 16, 118), 10.0, COL_GRASS_DARK)
	_slab("DescentLanding1", Vector2(36, 110), Vector2(14, 16), 16.0, COL_GRASS)
	_ramp("DescentB", Vector3(34, 16, 104), Vector3(20, 8, 84), 10.0, COL_GRASS_DARK)
	_slab("DescentLanding2", Vector2(18, 78), Vector2(14, 12), 8.0, COL_GRASS)
	_ramp("DescentC", Vector3(20, 8, 74), Vector3(34, 6, 66), 8.0, COL_GRASS_DARK)


func _build_camp_terrace() -> void:
	# Terrasse du camp (§3.3 : (45, 6, 65)) et sa sortie vers la plaine sud.
	_slab("CampTerrace", Vector2(45, 65), Vector2(44, 40), 6.0, COL_GRASS)
	_ramp("CampExit", Vector3(40, 6, 47), Vector3(40, 2, 30), 10.0, COL_GRASS_DARK)


func _build_learning_cliff() -> void:
	# Falaise d'apprentissage (§3.3 : ouest). Mur est du plateau : 12 m depuis la
	# plaine (y 2 → 14) — deux corniches de repos (§9.3) jalonnent la montée,
	# et le plateau récompense d'un panorama.
	_slab("LearningCliff", Vector2(-110, 65), Vector2(60, 50), 14.0, COL_ROCK)
	_slab("CliffLedgeLow", Vector2(-79.5, 58), Vector2(1.0, 6), 6.0, COL_ROCK)
	_slab("CliffLedgeHigh", Vector2(-79.5, 72), Vector2(1.0, 6), 10.5, COL_ROCK)


func _build_pylon_terrace_and_proxy() -> void:
	# Terrasse du pylône (§3.3 : (115, 18, −25)) et sa rampe d'accès nord.
	_slab("PylonTerrace", Vector2(115, -25), Vector2(56, 50), 18.0, COL_ROCK)
	# La rampe atterrit AU RAS du bord ouest (x = 87) : une arrivée à l'intérieur
	# de l'emprise laisserait un mur en travers de la pente — mesuré à la sonde
	# (y = 18 rencontré à mi-rampe avant correction).
	_ramp("PylonRamp", Vector3(64, 2, 2), Vector3(87, 18, -14), 10.0, COL_ROCK)
	# Proxy du pylône : fût de cuivre + tête cyan émissive — le point d'intérêt
	# du tiers droit de la vue d'ouverture (§3.2).
	_cylinder("PylonShaft", Vector3(115, 18, -25), 2.5, 22.0, COL_COPPER, true)
	_orb("PylonHead", Vector3(115, 41.5, -25), 3.0, COL_CYAN)


func _build_forest() -> void:
	# Forêt claire au sud-est du centre (§3.3) : troncs à collision, couronnes
	# visuelles. Positions déterministes, espacées — des obstacles francs pour
	# la preuve de navigation.
	var trunks: Array[Vector2] = [
		Vector2(58, 24), Vector2(66, 33), Vector2(75, 22), Vector2(84, 30),
		Vector2(93, 24), Vector2(62, 44), Vector2(72, 40), Vector2(82, 46),
		Vector2(91, 38), Vector2(69, 52), Vector2(79, 56), Vector2(88, 52),
	]
	var forest: Node3D = Node3D.new()
	forest.name = "Forest"
	add_child(forest)
	for i: int in range(trunks.size()):
		var at: Vector2 = trunks[i]
		_cylinder_in("Trunk%02d" % i, forest, Vector3(at.x, 2.0, at.y),
			0.5, 7.0, COL_WOOD, true)
		_orb_in("Canopy%02d" % i, forest, Vector3(at.x, 9.5, at.y), 2.6, COL_GRASS_DARK)


func _build_central_ruins() -> void:
	# Ruines centrales, sur la route plaine nord → donjon : fragments de murs
	# avec de vrais passages — le détour que la navigation devra prouver.
	var ruins: Node3D = Node3D.new()
	ruins.name = "Ruins"
	add_child(ruins)
	var walls: Array[Array] = [
		# [centre xz, taille xz, hauteur]
		[Vector2(-6, -30), Vector2(12, 1.2), 3.0],
		[Vector2(8, -38), Vector2(1.2, 10), 2.4],
		[Vector2(4, -52), Vector2(14, 1.2), 3.2],
		[Vector2(-4, -62), Vector2(1.2, 12), 2.6],
		[Vector2(14, -60), Vector2(8, 1.2), 1.8],
		# Salle éventrée en U, ouverte au sud : trois murs. C'est le piège de la
		# preuve de navigation — un pilotage direct s'y coince, un chemin la
		# contourne par l'ouverture.
		[Vector2(-14, -44), Vector2(10, 1.2), 2.0],
		[Vector2(-18, -54), Vector2(1.2, 20), 2.2],
		[Vector2(-10, -54), Vector2(1.2, 20), 2.2],
	]
	for i: int in range(walls.size()):
		var wall: Array = walls[i]
		var center: Vector2 = wall[0]
		var size: Vector2 = wall[1]
		var height: float = wall[2]
		_box_in("RuinWall%02d" % i, ruins,
			Vector3(center.x, 2.0 + height * 0.5, center.y),
			Vector3(size.x, height, size.y), COL_STONE, true)


func _build_dungeon_plateau_and_citadel() -> void:
	# Plateau monumental (§3.3 : donjon (0, 34, −210)) et sa rampe processionnelle.
	_slab("DungeonPlateau", Vector2(0, -210), Vector2(130, 90), 34.0, COL_ROCK)
	# Même règle que la rampe du pylône : arrivée au ras du bord nord (z = -165).
	_ramp("DungeonRamp", Vector3(0, 2, -110), Vector3(0, 34, -165), 16.0, COL_ROCK)
	# Proxy de citadelle : masse centrale, quatre tours, cœur cyan — la
	# silhouette du fond de la vue d'ouverture (§3.2 : 300–420 m du spawn).
	var citadel: Node3D = Node3D.new()
	citadel.name = "CitadelProxy"
	add_child(citadel)
	_box_in("Keep", citadel, Vector3(0, 34 + 23, -210), Vector3(24, 46, 24), COL_STONE, true)
	for i: int in range(4):
		var dx: float = -14.0 if i % 2 == 0 else 14.0
		var dz: float = -14.0 if i < 2 else 14.0
		_box_in("Tower%d" % i, citadel, Vector3(dx, 34 + 28, -210 + dz),
			Vector3(8, 56, 8), COL_STONE, true)
	_box_in("EnergyCore", citadel, Vector3(0, 34 + 32, -210 + 12.2),
		Vector3(3, 10, 0.6), COL_CYAN, false, true)
	# Entrée de la citadelle (D.1R.4, PT-D1-10) : ouverture sombre encadrée de
	# cyan sur la face avant du donjon, et une VRAIE porte qui charge le
	# vestibule — la promesse vue depuis la crête n'est plus fausse.
	_box_in("DoorFrameLeft", citadel, Vector3(-2.2, 34 + 3, -197.8),
		Vector3(0.8, 6.0, 0.6), COL_CYAN, false, true)
	_box_in("DoorFrameRight", citadel, Vector3(2.2, 34 + 3, -197.8),
		Vector3(0.8, 6.0, 0.6), COL_CYAN, false, true)
	_box_in("DoorFrameTop", citadel, Vector3(0, 34 + 6.2, -197.8),
		Vector3(5.2, 0.8, 0.6), COL_CYAN, false, true)
	var door: SceneDoor = SceneDoor.new()
	door.name = "CitadelDoor"
	door.verb = "Entrer"
	door.target_scene = "res://scenes/world/citadel/CitadelVestibule.tscn"
	door.spawn_tag = &"from_valley"
	door.collision_layer = 1
	door.collision_mask = 0
	var door_shape: CollisionShape3D = CollisionShape3D.new()
	var door_box: BoxShape3D = BoxShape3D.new()
	door_box.size = Vector3(3.6, 6.0, 0.5)
	door_shape.shape = door_box
	door.add_child(door_shape)
	var door_mesh: MeshInstance3D = MeshInstance3D.new()
	var door_mesh_box: BoxMesh = BoxMesh.new()
	door_mesh_box.size = Vector3(3.6, 6.0, 0.5)
	door_mesh.mesh = door_mesh_box
	var door_material: StandardMaterial3D = StandardMaterial3D.new()
	door_material.albedo_color = Color(0.08, 0.09, 0.12)
	door_mesh.material_override = door_material
	door.add_child(door_mesh)
	door.position = Vector3(0, 34 + 3, -197.9)   # AVANT add_child (règle D.0)
	citadel.add_child(door)


## ---------------------------------------------------------------------------
## Briques de construction
## ---------------------------------------------------------------------------

## Dalle pleine : sommet à `top`, fond commun à BASE_Y.
func _slab(slab_name: String, center_xz: Vector2, size_xz: Vector2, top: float,
		color: Color) -> void:
	var height: float = top - BASE_Y
	_box_in(slab_name, self,
		Vector3(center_xz.x, BASE_Y + height * 0.5, center_xz.y),
		Vector3(size_xz.x, height, size_xz.y), color, true)


## Boîte avec collision optionnelle et émission optionnelle.
func _box_in(box_name: String, parent: Node3D, center: Vector3, size: Vector3,
		color: Color, with_collision: bool, emissive: bool = false) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = box_name + "Mesh"
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color, emissive)
	if with_collision:
		var body: StaticBody3D = StaticBody3D.new()
		body.name = box_name
		body.collision_layer = 1
		body.collision_mask = 0
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box_shape: BoxShape3D = BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		body.add_child(mesh)
		# Position AVANT add_child — règle D.0 : un corps ajouté à l'origine puis
		# déplacé y passe un tick physique. Mesuré ici même : les montagnes
		# périmétrales à l'origine enveloppaient le spawn et catapultaient le
		# joueur de 4,6 m au premier tick (sonde BorderWest).
		body.position = center
		parent.add_child(body)
	else:
		mesh.name = box_name
		mesh.position = center
		parent.add_child(mesh)


## Rampe : prisme convexe PLEIN entre deux extrémités de surface (centres des
## arêtes haute et basse). Huit sommets, aucun dessous en surplomb (leçon B.1).
func _ramp(ramp_name: String, from: Vector3, to: Vector3, width: float,
		color: Color) -> void:
	var along: Vector3 = to - from
	var flat: Vector3 = Vector3(along.x, 0.0, along.z)
	if flat.length_squared() < 0.0001:
		push_error("[terrain] rampe dégénérée : %s" % ramp_name)
		return
	var side: Vector3 = flat.normalized().cross(Vector3.UP) * (width * 0.5)
	var points: PackedVector3Array = PackedVector3Array([
		from + side, from - side,                                # arête haute, sommet
		to + side, to - side,                                    # arête basse, sommet
		Vector3(from.x + side.x, BASE_Y, from.z + side.z),        # fonds
		Vector3(from.x - side.x, BASE_Y, from.z - side.z),
		Vector3(to.x + side.x, BASE_Y, to.z + side.z),
		Vector3(to.x - side.x, BASE_Y, to.z - side.z),
	])
	var body: StaticBody3D = StaticBody3D.new()
	body.name = ramp_name
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var hull: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	hull.points = points
	shape.shape = hull
	body.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = ramp_name + "Mesh"
	mesh.mesh = _hull_mesh(points)
	mesh.material_override = _material(color, false)
	body.add_child(mesh)
	add_child(body)


## Maillage du prisme : les six faces du coin, en quads triangulés.
func _hull_mesh(p: PackedVector3Array) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var quads: Array[Array] = [
		[0, 1, 3, 2],   # dessus (la pente)
		[4, 6, 7, 5],   # dessous
		[0, 2, 6, 4],   # flanc +side
		[1, 5, 7, 3],   # flanc -side
		[0, 4, 5, 1],   # face haute
		[2, 3, 7, 6],   # face basse
	]
	for quad: Array in quads:
		st.add_vertex(p[quad[0]]); st.add_vertex(p[quad[1]]); st.add_vertex(p[quad[2]])
		st.add_vertex(p[quad[0]]); st.add_vertex(p[quad[2]]); st.add_vertex(p[quad[3]])
	st.generate_normals()
	return st.commit()


func _cylinder(cyl_name: String, base: Vector3, radius: float, height: float,
		color: Color, with_collision: bool) -> void:
	_cylinder_in(cyl_name, self, base, radius, height, color, with_collision)


## Cylindre posé sur `base` (pied au sol, §7.15 : bas de l'objet au sol).
func _cylinder_in(cyl_name: String, parent: Node3D, base: Vector3, radius: float,
		height: float, color: Color, with_collision: bool) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = cyl_name + "Mesh"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	mesh.mesh = cyl
	mesh.material_override = _material(color, false)
	var center: Vector3 = base + Vector3(0, height * 0.5, 0)
	if with_collision:
		var body: StaticBody3D = StaticBody3D.new()
		body.name = cyl_name
		body.collision_layer = 1
		body.collision_mask = 0
		var shape: CollisionShape3D = CollisionShape3D.new()
		var cyl_shape: CylinderShape3D = CylinderShape3D.new()
		cyl_shape.radius = radius
		cyl_shape.height = height
		shape.shape = cyl_shape
		body.add_child(shape)
		body.add_child(mesh)
		body.position = center   # AVANT add_child (règle D.0)
		parent.add_child(body)
	else:
		mesh.name = cyl_name
		mesh.position = center
		parent.add_child(mesh)


func _orb(orb_name: String, center: Vector3, radius: float, color: Color) -> void:
	_orb_in(orb_name, self, center, radius, color)


## Sphère visuelle sans collision (têtes de pylône, couronnes d'arbres).
func _orb_in(orb_name: String, parent: Node3D, center: Vector3, radius: float,
		color: Color) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = orb_name
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh.mesh = sphere
	var emissive: bool = color == COL_CYAN
	mesh.material_override = _material(color, emissive)
	mesh.position = center
	parent.add_child(mesh)


func _material(color: Color, emissive: bool) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if emissive:
		# Cœur blanc, halo cyan (§7.9) — version proxy : émission simple.
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0
	return mat
