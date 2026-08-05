## `HeroShotLab` — micro-scène North Star 80×80 m (bible §29 passe V2,
## P2 §11.1). C'est ici que la recette visuelle se règle AVANT toute
## propagation : héros de dos, pente d'herbe et de fleurs, chemin, rivière
## en S, camp simplifié, pylône, proxy de citadelle, falaises
## d'encadrement, ciel, nuage d'orage local et caméra North Star.
##
## Les éléments lointains sont AUTORÉS EN CONTRAT D'ÉCRAN : `_world_at`
## inverse la projection de `VistaCamera_Hero01` — un anchor placé à
## (63,5 %, 61 %, 90 m) TOMBE à 63,5 %/61 % du cadre, par construction.
## `test_hero_shot_lab.gd` revérifie ces fenêtres par la projection
## directe, indépendamment. Corrections adversariales #3 (rivière en S)
## et #4 (camp dans le cadre, pylône 75-79 % X) intégrées comme contrats.
##
## Environnement : la capture llvmpipe sert la RÉGRESSION visuelle ; le
## score WOW réel attend la machine utilisateur (CLAUDE.md, limites).
class_name HeroShotLab
extends Node3D

## Caméra North Star (bible §3.1) : FOV VERTICAL 44° = 71,4° horizontal
## en 16:9 (KEEP_HEIGHT — entrer 68 en vertical est LE piège nommé §3.1).
const CAM_FOV: float = 44.0
const CAM_PITCH_DEG: float = -2.0
## Position relative aux pieds du héros (origine du lab) : 4,5 m
## derrière, objectif à 1,70 m, décalé pour poser le héros à ~41 % X.
const CAM_POSITION: Vector3 = Vector3(0.55, 1.70, 4.5)
const HERO_HEIGHT: float = 1.78

const COL_GRASS: Color = Color(0.365, 0.561, 0.239)      # #5D8F3D
const COL_GRASS_LIT: Color = Color(0.698, 0.784, 0.353)  # #B2C85A
const COL_EARTH: Color = Color(0.541, 0.353, 0.212)      # terre #8A5A36
const COL_ROCK: Color = Color(0.608, 0.408, 0.259)       # ocre #9B6842
const COL_WATER: Color = Color(0.310, 0.686, 0.698)      # turquoise #4FAFB2
const COL_CANVAS: Color = Color(0.72, 0.42, 0.30)        # toile de camp
const COL_STONE_COLD: Color = Color(0.298, 0.357, 0.459) # ombre froide
const COL_COPPER: Color = Color(0.43, 0.46, 0.37)        # cuivre patiné
const COL_IVORY: Color = Color(0.847, 0.784, 0.631)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)

## Tracé de la rivière en CONTRAT D'ÉCRAN : (X %, Y %, distance m).
## Deux changements de direction horizontale = le S (correction #3).
## PHYSIQUE (leçons v0/v1) : un plateau à bord franc OCCULTE tout ce qui
## descend derrière lui (seuls les fanions du camp émergeaient de la
## ligne de visée). Le héros se tient donc sur une PENTE CONTINUE de 8°,
## toujours visible, dont la ligne de fuite apparente est à ~63 %
## (pitch −2° : horizon vrai à 54,3 %). Un ruban posé sur cette pente
## vit dans la bande 63-66 % : le S se lit en X (34 → 50 %), la
## profondeur par la convergence et l'amincissement.
## L'amorce entre par le BAS-GAUCHE, devant le héros (leçon v1 : à 40 %
## X elle passait derrière lui), puis le S remonte vers le centre.
const RIVER_SCREEN: Array[Vector3] = [
	Vector3(34.0, 69.5, 20.0),
	Vector3(31.0, 67.0, 30.0),
	Vector3(34.0, 65.3, 44.0),
	Vector3(40.0, 64.3, 66.0),
	Vector3(48.0, 63.9, 100.0),
	Vector3(50.0, 63.7, 145.0),
	Vector3(49.0, 63.5, 205.0),
]
## Pente continue du premier plan : 8° (tan ≈ 0,1405).
const SLOPE_TAN: float = 0.1405

var _anchors: Dictionary[StringName, Node3D] = {}
var _river_local: Array[Vector3] = []
var _grass_cells: int = 0


func _ready() -> void:
	_build_camera()
	_build_hero()
	_build_terrain()
	_build_river()
	_build_camp()
	_build_pylon()
	_build_citadel_proxy()
	_build_storm()
	_build_light()


## Inverse de la projection de la caméra North Star : un point d'écran
## (X %, Y % — origine haut-gauche) à `distance` mètres devient un point
## LOCAL du lab. Autorer ici = tomber dans la fenêtre, par construction.
func _world_at(x_pct: float, y_pct: float, distance: float) -> Vector3:
	var tan_v: float = tan(deg_to_rad(CAM_FOV) * 0.5)
	var tan_h: float = tan_v * 16.0 / 9.0
	var x_ndc: float = (x_pct / 100.0 - 0.5) * 2.0
	var y_ndc: float = (0.5 - y_pct / 100.0) * 2.0
	var local: Vector3 = Vector3(x_ndc * tan_h * distance,
		y_ndc * tan_v * distance, -distance)
	var rot: Basis = Basis(Vector3.RIGHT, deg_to_rad(CAM_PITCH_DEG))
	return CAM_POSITION + rot * local


func anchor(anchor_name: StringName) -> Node3D:
	return _anchors.get(anchor_name, null)


func vista_camera() -> Camera3D:
	return get_node_or_null("VistaCamera_Hero01") as Camera3D


func river_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for local: Vector3 in _river_local:
		points.append(to_global(local))
	return points


func grass_cell_count() -> int:
	return _grass_cells


## État de capture (`--call=capture_north_star`, outil §21.5) : active la
## caméra North Star et TIENT l'éclair majeur (§3.2 : « un éclair majeur
## simultané dans la vue d'ouverture » — `hold_flash` est fait pour ça,
## le jeu garde sa cadence irrégulière).
func capture_north_star() -> void:
	var camera: Camera3D = vista_camera()
	if camera != null:
		camera.current = true
	var storm: StormCell = get_node_or_null("Storm") as StormCell
	if storm != null:
		storm.hold_flash()


func _mark(anchor_name: StringName, at: Vector3) -> Node3D:
	var marker: Marker3D = Marker3D.new()
	marker.name = String(anchor_name).to_pascal_case()
	marker.position = at
	add_child(marker)
	_anchors[anchor_name] = marker
	return marker


func _build_camera() -> void:
	var camera: Camera3D = Camera3D.new()
	camera.name = "VistaCamera_Hero01"
	camera.position = CAM_POSITION
	camera.rotation_degrees = Vector3(CAM_PITCH_DEG, 0.0, 0.0)
	camera.fov = CAM_FOV
	camera.current = false
	add_child(camera)


func _build_hero() -> void:
	_mark(&"hero_feet", Vector3.ZERO)
	_mark(&"hero_head", Vector3(0.0, HERO_HEIGHT, 0.0))
	# Le hero asset de la Phase H, DE DOS (il regarde la vallée, -Z).
	var scene: PackedScene = load(
		"res://assets/characters/hero/Male_Ranger.gltf") as PackedScene
	if scene != null:
		var hero: Node3D = scene.instantiate() as Node3D
		hero.name = "Hero"
		hero.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		add_child(hero)
		# Le glTF n'embarque AUCUNE animation (sondé) : sortir de la
		# T-pose se fait à l'os — bras posés le long du corps.
		var skeleton: Skeleton3D = null
		for node: Node in hero.find_children("*", "Skeleton3D", true, false):
			skeleton = node as Skeleton3D
		if skeleton != null:
			_lower_arm(skeleton, "upperarm_l", -70.0)
			_lower_arm(skeleton, "upperarm_r", 70.0)
	else:
		var proxy: MeshInstance3D = MeshInstance3D.new()
		proxy.name = "Hero"
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.height = HERO_HEIGHT
		capsule.radius = 0.3
		proxy.mesh = capsule
		proxy.position = Vector3(0.0, HERO_HEIGHT * 0.5, 0.0)
		add_child(proxy)


func _lower_arm(skeleton: Skeleton3D, bone: String, degrees: float) -> void:
	var index: int = skeleton.find_bone(bone)
	if index < 0:
		return
	var rest: Quaternion = skeleton.get_bone_rest(index).basis \
		.get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(index,
		rest * Quaternion(Vector3(0, 0, 1), deg_to_rad(degrees)))


func _material(colour: Color, rough: float = 0.9) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = rough
	return material


func _slab(slab_name: String, centre: Vector3, size: Vector3,
		colour: Color) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = slab_name
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(colour)
	mesh.position = centre
	add_child(mesh)


## Hauteur de la pente continue en un z donné (surface passant par les
## pieds du héros à l'origine, descendant vers −z).
func _slope_height(z: float) -> float:
	return z * SLOPE_TAN


func _build_terrain() -> void:
	# UNE pente continue de 8° (leçon v1 : un bord de plateau occulte la
	# vallée entière depuis une caméra presque horizontale). Le héros se
	# tient dessus à l'origine ; la surface passe par (0, 0).
	var slope: MeshInstance3D = MeshInstance3D.new()
	slope.name = "ValleySlope"
	var slope_box: BoxMesh = BoxMesh.new()
	slope_box.size = Vector3(130, 2, 168)
	slope.mesh = slope_box
	slope.material_override = _material(COL_GRASS)
	slope.position = Vector3(4, _slope_height(-68.0) - 1.0, -68)
	slope.rotation_degrees = Vector3(-8.0, 0, 0)
	add_child(slope)
	# Fond de vallée PLAT (~−21 m) : la pente s'y adoucit, la queue de la
	# rivière et le socle de la citadelle s'y posent.
	_slab("ValleyFloor", Vector3(4, -22.0, -245), Vector3(240, 2, 210),
		COL_GRASS)
	# Chemin de terre : il ÉPOUSE la pente (leçon v1).
	var path: MeshInstance3D = MeshInstance3D.new()
	path.name = "PathCrest"
	var path_box: BoxMesh = BoxMesh.new()
	path_box.size = Vector3(1.6, 0.06, 34)
	path.mesh = path_box
	path.material_override = _material(COL_EARTH)
	path.position = Vector3(2.2, _slope_height(-9.0) + 0.05, -9)
	path.rotation_degrees = Vector3(-8.0, 0, 0)
	add_child(path)
	# Falaises d'encadrement (§1.1), enracinées dans la pente — strates
	# décalées, tons rabattus (le mur plat orange est un échec nommé v0).
	_slab("CliffLeftNear", Vector3(-26, _slope_height(-30.0) + 5.0, -30),
		Vector3(14, 10, 40), COL_ROCK.lerp(COL_STONE_COLD, 0.25))
	_slab("CliffLeftLip", Vector3(-22.5, _slope_height(-34.0) + 10.6, -34),
		Vector3(9, 3.2, 34), COL_ROCK.lerp(COL_GRASS, 0.3))
	_slab("CliffLeftFar", Vector3(-36, _slope_height(-95.0) + 6.0, -95),
		Vector3(20, 16, 70), COL_ROCK.lerp(COL_STONE_COLD, 0.45))
	# Décalée à droite (leçon v0 : à x 46 elle avalait le pylône).
	_slab("CliffRightFar", Vector3(62, _slope_height(-120.0) + 4.0, -120),
		Vector3(18, 13, 50), COL_ROCK.lerp(COL_STONE_COLD, 0.4))
	_build_mountains()
	_grass_foreground()


## Horizon montagneux (§1.1 : Y 24-43 %, contraste faible ; §3.3 :
## montagnes non jouables à 550-1 200 m). Il remplit aussi la bande
## 40-54 % : la part de ciel redescend vers les 38-48 % demandés —
## l'arbitrage v2 se fait par le DÉCOR, pas en cassant le cadrage héros.
func _build_mountains() -> void:
	var mountains: Array[Array] = [
		["MesaA", Vector3(-210, 12, -560), Vector3(200, 68, 60)],
		["MesaB", Vector3(-60, 20, -640), Vector3(180, 88, 70)],
		["MesaC", Vector3(120, 8, -600), Vector3(160, 62, 60)],
		["MesaD", Vector3(280, 16, -680), Vector3(220, 76, 70)],
		["MesaE", Vector3(30, 30, -760), Vector3(260, 104, 80)],
	]
	var pale: Color = COL_STONE_COLD.lerp(Color(0.66, 0.73, 0.80), 0.55)
	for mesa: Array in mountains:
		_slab(mesa[0] as String, mesa[1] as Vector3, mesa[2] as Vector3,
			pale)


## L'herbe du premier plan : cellules MultiMesh (§26.3 — jamais une seule
## nappe), organisées en « PHRASES » (§7.4) : grande touffe + moyennes +
## fleurs + VIDE, répétition irrégulière — un scatter uniforme est un
## échec nommé, même dense (leçon v1).
func _grass_foreground() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260805
	var blade: ArrayMesh = _blade_mesh()
	for cell_x: int in range(-2, 2):
		for cell_z: int in range(2):
			var origin: Vector3 = Vector3(float(cell_x) * 10.0 + 5.0, 0.0,
				-float(cell_z) * 10.0 - 2.0)
			# 5-7 touffes par cellule, tailles inégales — et le reste en
			# vide : la respiration fait la phrase.
			var clumps: Array[Vector3] = []
			var clump_scale: Array[float] = []
			for c: int in range(rng.randi_range(5, 7)):
				clumps.append(origin + Vector3(rng.randf_range(-4.2, 4.2),
					0.0, rng.randf_range(-4.2, 4.2)))
				clump_scale.append(rng.randf_range(0.8, 1.6))
			var cell: MultiMeshInstance3D = MultiMeshInstance3D.new()
			cell.name = "Grass_%d_%d" % [cell_x + 2, cell_z]
			var multimesh: MultiMesh = MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = blade
			multimesh.instance_count = 240
			for i: int in range(multimesh.instance_count):
				var pick: int = rng.randi_range(0, clumps.size() - 1)
				# Densité qui retombe du cœur vers le bord de la touffe.
				var radius: float = rng.randf_range(0.0, 2.4) * rng.randf()
				var angle: float = rng.randf_range(0.0, TAU)
				var spot: Vector3 = clumps[pick] + Vector3(
					cos(angle) * radius, 0.0, sin(angle) * radius)
				spot.y = minf(_slope_height(spot.z), 0.0)
				var closeness: float = 1.0 - radius / 2.4
				var basis: Basis = Basis(Vector3.UP,
					rng.randf_range(0.0, TAU))
				basis = basis.scaled(Vector3.ONE * clump_scale[pick]
					* rng.randf_range(0.55, 0.85 + 0.7 * closeness))
				multimesh.set_instance_transform(i,
					Transform3D(basis, spot))
			cell.multimesh = multimesh
			var material: StandardMaterial3D = _material(
				COL_GRASS.lerp(COL_GRASS_LIT, rng.randf_range(0.2, 0.6)))
			cell.material_override = material
			add_child(cell)
			_grass_cells += 1
			_flower_patch(rng, cell_x, cell_z, clumps)


## Fleurs en groupes AU BORD des touffes (§7.1 : blanches/jaunes, bleues
## rares), jamais un semis uniforme.
func _flower_patch(rng: RandomNumberGenerator, cell_x: int, cell_z: int,
		clumps: Array[Vector3]) -> void:
	var palette: Array[Color] = [Color(0.94, 0.89, 0.75),
		Color(1.0, 0.84, 0.54), Color(0.42, 0.51, 0.72)]
	var weights: Array[int] = [0, 0, 0, 1, 1, 2]   # le bleu reste rare
	var flowers: MultiMeshInstance3D = MultiMeshInstance3D.new()
	flowers.name = "Flowers_%d_%d" % [cell_x + 2, cell_z]
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var head: BoxMesh = BoxMesh.new()
	head.size = Vector3(0.09, 0.09, 0.09)
	multimesh.mesh = head
	multimesh.instance_count = 14
	for i: int in range(multimesh.instance_count):
		var clump: Vector3 = clumps[rng.randi_range(0, clumps.size() - 1)]
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = rng.randf_range(1.6, 2.8)
		var spot: Vector3 = clump + Vector3(cos(angle) * radius, 0.0,
			sin(angle) * radius)
		spot.y = minf(_slope_height(spot.z), 0.0) \
			+ rng.randf_range(0.18, 0.4)
		multimesh.set_instance_transform(i,
			Transform3D(Basis.IDENTITY, spot))
	flowers.multimesh = multimesh
	flowers.material_override = _material(
		palette[weights[rng.randi_range(0, weights.size() - 1)]], 0.7)
	add_child(flowers)


func _blade_mesh() -> ArrayMesh:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.add_vertex(Vector3(-0.03, 0.0, 0.0))
	surface.add_vertex(Vector3(0.03, 0.0, 0.0))
	surface.add_vertex(Vector3(0.0, 0.55, 0.04))
	surface.generate_normals()
	return surface.commit()


## Correction #3 : le ruban turquoise en S, autoré en contrat d'écran.
func _build_river() -> void:
	_river_local.clear()
	for spec: Vector3 in RIVER_SCREEN:
		_river_local.append(_world_at(spec.x, spec.y, spec.z))
	var river: Node3D = Node3D.new()
	river.name = "River"
	add_child(river)
	for i: int in range(_river_local.size() - 1):
		var from_point: Vector3 = _river_local[i]
		var to_point: Vector3 = _river_local[i + 1]
		var segment: MeshInstance3D = MeshInstance3D.new()
		segment.name = "Segment%d" % i
		var box: BoxMesh = BoxMesh.new()
		var length: float = from_point.distance_to(to_point)
		# Large et légèrement SURÉLEVÉ (leçon v1 : un ruban affleurant
		# disparaît sous les brins d'herbe et le bord de pente).
		box.size = Vector3(7.0 + float(i) * 1.5, 0.3, length + 3.0)
		segment.mesh = box
		var material: StandardMaterial3D = _material(COL_WATER, 0.25)
		material.emission_enabled = true
		material.emission = COL_WATER * 0.35
		segment.material_override = material
		segment.position = (from_point + to_point) * 0.5 \
			+ Vector3(0.0, 0.3, 0.0)
		var flat: Vector3 = to_point - from_point
		segment.rotation.y = atan2(-flat.x, -flat.z)
		river.add_child(segment)


## Camp simplifié au plan moyen (61-66 % X — correction #4) : terrasse,
## feu, deux auvents, fumée fine. Lisible à 90 m (§10.1 de la bible).
func _build_camp() -> void:
	# Y 64,6 % : là où l'ancre TOMBE SUR la pente continue à 90 m — le
	# camp se pose au sol, pas dessous (leçons v0/v1).
	var centre: Vector3 = _world_at(63.5, 64.6, 90.0)
	_mark(&"camp_center", centre)
	_slab("CampTerrace", centre + Vector3(0, -0.8, 0), Vector3(24, 1.6, 20),
		COL_EARTH)
	_slab("CampFirePit", centre + Vector3(0, 0.2, 0), Vector3(1.4, 0.4, 1.4),
		COL_STONE_COLD)
	var flame: MeshInstance3D = MeshInstance3D.new()
	flame.name = "CampFlame"
	var flame_box: BoxMesh = BoxMesh.new()
	flame_box.size = Vector3(0.8, 1.2, 0.8)
	flame.mesh = flame_box
	var flame_material: StandardMaterial3D = _material(
		Color(1.0, 0.604, 0.239))
	flame_material.emission_enabled = true
	flame_material.emission = Color(1.0, 0.604, 0.239)
	flame_material.emission_energy_multiplier = 4.0
	flame.material_override = flame_material
	flame.position = centre + Vector3(0, 1.0, 0)
	add_child(flame)
	# Bible §10.1 : le camp se lit à 70-110 m par flamme, FUMÉE fine et
	# DEUX bannières — pas par ses petits props (leçon v1 : des tentes de
	# 28 px sans signal vertical n'existent pas à l'image).
	var smoke: MeshInstance3D = MeshInstance3D.new()
	smoke.name = "CampSmoke"
	var smoke_box: BoxMesh = BoxMesh.new()
	smoke_box.size = Vector3(1.1, 9.0, 1.1)
	smoke.mesh = smoke_box
	smoke.material_override = _material(Color(0.78, 0.80, 0.82), 1.0)
	smoke.position = centre + Vector3(0.4, 6.0, 0)
	add_child(smoke)
	for side: int in [-1, 1]:
		var tent: MeshInstance3D = MeshInstance3D.new()
		tent.name = "CampTent%s" % ("W" if side < 0 else "E")
		var prism: PrismMesh = PrismMesh.new()
		prism.size = Vector3(4.8, 3.6, 3.6)
		tent.mesh = prism
		tent.material_override = _material(COL_CANVAS)
		tent.position = centre + Vector3(6.5 * float(side), 1.8,
			-2.0 * float(side))
		tent.rotation_degrees = Vector3(0, 24.0 * float(side), 0)
		add_child(tent)
		var pole: MeshInstance3D = MeshInstance3D.new()
		pole.name = "CampBannerPole%s" % ("W" if side < 0 else "E")
		var pole_box: BoxMesh = BoxMesh.new()
		pole_box.size = Vector3(0.3, 6.5, 0.3)
		pole.mesh = pole_box
		pole.material_override = _material(Color(0.408, 0.251, 0.157))
		pole.position = centre + Vector3(3.2 * float(side), 3.25, 2.5)
		add_child(pole)
		var flag: MeshInstance3D = MeshInstance3D.new()
		flag.name = "CampBanner%s" % ("W" if side < 0 else "E")
		var flag_box: BoxMesh = BoxMesh.new()
		flag_box.size = Vector3(2.1, 1.3, 0.12)
		flag.mesh = flag_box
		flag.material_override = _material(Color(0.78, 0.30, 0.22))
		flag.position = centre + Vector3(3.2 * float(side) + 1.1, 5.6, 2.5)
		add_child(flag)


## Pylône au tiers droit (75-79 % X — correction #4). ~105 m : là où un
## asset de 34 m (§3 : 28-36 m) REMPLIT sa fenêtre verticale 17 → 57 %.
## À 140-190 m il faudrait 52 m — les fenêtres du cadre priment.
func _build_pylon() -> void:
	# Y 60 % : le pied émerge de la pente sur son éperon (~3,5 m) ; le
	# sommet (base + 34 m) retombe à ~19,6 % — les deux fenêtres tenues.
	var base: Vector3 = _world_at(77.0, 60.0, 105.0)
	_mark(&"pylon_base", base)
	_mark(&"pylon_top", base + Vector3(0, 34.0, 0))
	# Éperon rocheux (§6.1) sous le pylône.
	_slab("PylonSpur", base + Vector3(0, -4.0, 0), Vector3(16, 8, 16),
		COL_ROCK)
	var pylon: Node3D = Node3D.new()
	pylon.name = "Pylon"
	pylon.position = base
	add_child(pylon)
	# Fût effilé en trois segments, cuivre patiné + céramique.
	var heights: Array[float] = [10.0, 12.0, 8.0]
	var widths: Array[float] = [3.4, 2.5, 1.7]
	var y: float = 0.0
	for i: int in range(3):
		var segment: MeshInstance3D = MeshInstance3D.new()
		segment.name = "Shaft%d" % i
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(widths[i], heights[i], widths[i])
		segment.mesh = box
		segment.material_override = _material(
			COL_COPPER if i % 2 == 0 else COL_IVORY, 0.6)
		segment.position = Vector3(0, y + heights[i] * 0.5, 0)
		pylon.add_child(segment)
		y += heights[i]
	# Anneau incomplet et fourche terminale (§11.2), cœur cyan discret.
	var crown: MeshInstance3D = MeshInstance3D.new()
	crown.name = "Crown"
	var crown_box: BoxMesh = BoxMesh.new()
	crown_box.size = Vector3(4.6, 3.6, 1.2)
	crown.mesh = crown_box
	var crown_material: StandardMaterial3D = _material(COL_COPPER, 0.5)
	crown_material.emission_enabled = true
	crown_material.emission = COL_CYAN
	crown_material.emission_energy_multiplier = 0.6
	crown.material_override = crown_material
	crown.position = Vector3(0, y + 1.6, 0)
	pylon.add_child(crown)


## Proxy de citadelle (bible §2.4) : socle très large, terrasses, deux
## épaules, spire — moins de vingt grandes formes, lisibles à 300 m.
func _build_citadel_proxy() -> void:
	var centre: Vector3 = _world_at(50.5, 43.0, 320.0)
	_mark(&"citadel_center", centre)
	var citadel: Node3D = Node3D.new()
	citadel.name = "CitadelProxy"
	citadel.position = centre
	add_child(citadel)
	var masses: Array[Array] = [
		["Socle", Vector3(0, -18, 0), Vector3(190, 26, 90)],
		["TerraceA", Vector3(-12, -2, 4), Vector3(130, 18, 66)],
		["TerraceB", Vector3(8, 12, 0), Vector3(90, 16, 50)],
		["ShoulderW", Vector3(-46, 16, -4), Vector3(34, 30, 38)],
		["ShoulderE", Vector3(38, 10, 2), Vector3(30, 24, 34)],
		["Keep", Vector3(0, 28, -2), Vector3(48, 26, 36)],
	]
	for mass: Array in masses:
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = mass[0] as String
		var box: BoxMesh = BoxMesh.new()
		box.size = mass[2] as Vector3
		mesh.mesh = box
		mesh.material_override = _material(COL_STONE_COLD, 0.85)
		mesh.position = mass[1] as Vector3
		citadel.add_child(mesh)
	# La spire : elle capte l'orage (ancre au sommet).
	var spire: MeshInstance3D = MeshInstance3D.new()
	spire.name = "Spire"
	var spire_box: BoxMesh = BoxMesh.new()
	spire_box.size = Vector3(12, 46, 12)
	spire.mesh = spire_box
	spire.material_override = _material(COL_STONE_COLD, 0.8)
	spire.position = Vector3(0, 62, -2)
	citadel.add_child(spire)
	_mark(&"citadel_spire", centre + Vector3(0, 85, -2))


## Le nuage d'orage LOCAL au-dessus de la citadelle — la StormCell de la
## vallée, réutilisée telle quelle (éclair déterministe, localité testée).
func _build_storm() -> void:
	var storm: StormCell = StormCell.new()
	storm.name = "Storm"
	var spire: Node3D = _anchors.get(&"citadel_spire", null)
	if spire != null:
		storm.position = spire.position + Vector3(0, 26, 0)
	add_child(storm)


func _build_light() -> void:
	# Fin d'après-midi (§22.1) : soleil ouest/haut-gauche, miel.
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color(1.0, 0.839, 0.541)
	sun.light_energy = 1.45
	sun.rotation_degrees = Vector3(-23.0, 52.0, 0.0)
	add_child(sun)
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky: Sky = Sky.new()
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.514, 0.663, 0.804)
	sky_material.sky_horizon_color = Color(0.843, 0.867, 0.902)
	sky_material.ground_bottom_color = Color(0.361, 0.443, 0.322)
	sky_material.ground_horizon_color = Color(0.749, 0.780, 0.702)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.55
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.686, 0.784, 0.827)
	# 0,0045 + perspective aérienne (leçon v0 : à 0,0016 la citadelle
	# COLLAIT au premier plan — §1.3 exige l'étagement atmosphérique).
	environment.fog_density = 0.0045
	environment.fog_aerial_perspective = 0.5
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "LabEnvironment"
	world_environment.environment = environment
	add_child(world_environment)
