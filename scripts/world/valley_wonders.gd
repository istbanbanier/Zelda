## SECONDE VAGUE de lieux naturels mémorables de la Vallée de Néris.
##
## `ValleyLandmarks` a posé la première vague (arbre doyen, source, champ de
## fleurs, arche de pierre, belvédère). Ce fichier en pose cinq autres, choisis
## pour occuper des registres que la première vague ne couvrait PAS :
##
##   1. `ChuteDuVoile`      — une CHUTE D'EAU et son bassin : la seule masse en
##                            mouvement permanent du monde, lisible à 150 m ;
##   2. `CercleDesVeilleurs`— un monument ANCIEN : des pierres dressées dont la
##                            disposition est manifestement voulue ;
##   3. `GorgeDuVent`       — un PASSAGE, pas un objet : deux parois, un couloir
##                            franchissable, un raccourci sur la route du nord ;
##   4. `BoisCourbe`        — un bosquet MARQUÉ par l'orage, sur le chemin de la
##                            citadelle : arbres penchés, bois mort, sol rasé ;
##   5. `ArbreFoudroye`     — un arbre FRAPPÉ : bois noirci, fente pâle, et des
##                            repousses au pied qui disent que la vie revient.
##
## Les cinq sites sont à plus de 30 m de tout lieu déjà implanté (village,
## hameaux, ruines, grottes, première vague, camp, pylône, donjon, crête) : le
## monde gagne cinq destinations, il n'en empile pas deux au même endroit.
##
## Chaque lieu offre au moins un élément de la liste de l'ordre d'extension —
## ingrédients récoltables, panorama, raccourci, indice environnemental ou
## fragment d'histoire raconté par la composition — et se DÉCLARE au
## `DiscoveryLog` par un `PointOfInterest` d'identifiant §19.3.
##
## RÈGLE DE PALETTE tenue ici (§3.4 : le cyan est RARE, réservé à l'énergie de
## Résonance) : la cascade est de l'EAU — bleu-vert désaturé, transparente,
## AUCUNE émission ; son écume est un blanc cassé, pas un cœur électrique.
## L'arbre foudroyé montre du charbon et du bois nu, pas une lueur. Le bosquet
## orageux se lit par ses formes — troncs couchés, branches brisées, sol rasé —
## et par rien d'autre.
class_name ValleyWonders
extends Node3D

## Le kit d'environnement est réparti sur plusieurs dossiers. Une pièce se
## résout donc par RECHERCHE, jamais par chemin figé — sinon déplacer un asset
## casserait un lieu en silence.
const ASSET_DIRS: Array[String] = [
	"res://assets/environment/foliage/%s.gltf",
	"res://assets/environment/rocks/%s.gltf",
	"res://assets/environment/props/%s.gltf",
	"res://assets/environment/village/%s.gltf",
	"res://assets/environment/dungeon/%s.gltf",
]

## Shader de vent partagé (§7.5 : « aucun recalcul CPU de toute la prairie »).
const FOLIAGE_SHADER: String = "res://shaders/foliage/foliage_wind.gdshader"

# --- Implantation -----------------------------------------------------------
#
# Repères du terrain : plaine sud y = 2 pour z de 16 à 256 ; plaine nord y = 2
# pour z de −256 à −4 ; lit de rivière autour de z = 10 ; camp (45, 6, 65) ;
# pylône (115, 18, −25) ; donjon (0, 34, −210) ; crête de départ (0, 24, 170) ;
# village (−70, 2, 36) ; hameau des bûcherons (110, 2, 40) ; poste minier
# (−68, 2, 86). Première vague : (−96, 2, −62), (−72, 2, 78), (−34, 2, 112),
# (−14, 0, 10), (168, 0, 40). Ruines : (−128, 14, 82), (−12, 2, 10),
# (−16, 2, 78), (−38, 2, −120). Grottes : (−118, 2, 26), (160, 2, −70),
# (−60, 2, −90).
#
# Tous les sites sont donnés à y = 2, l'altitude des deux plaines : le Y LOCAL
# d'un lieu est donc sa hauteur au-dessus du sol, ce qui rend chaque cote
# lisible sans conversion mentale.

## Plaine sud-est, à 80 m au nord du belvédère : le seul relief de ce quadrant
## après lui, et la raison d'y revenir.
const SITE_FALLS: Vector3 = Vector3(150.0, 2.0, 118.0)
## Plaine nord-ouest, en terrain nu : un cercle de pierres a besoin de VIDE
## autour de lui pour se lire comme un monument et non comme un éboulis.
const SITE_CIRCLE: Vector3 = Vector3(-132.0, 2.0, -28.0)
## Plaine nord-est, sur la route qui monte du gué est vers le pylône.
const SITE_GORGE: Vector3 = Vector3(68.0, 2.0, -96.0)
## Chemin du donjon (0, 34, −210) : le dernier bosquet avant la citadelle.
const SITE_GROVE: Vector3 = Vector3(-8.0, 2.0, -152.0)
## Plaine sud-ouest, en vue de la crête de départ : l'orage frappe DÉJÀ ici,
## et c'est la première fois que le joueur en voit la preuve au sol.
const SITE_STRUCK: Vector3 = Vector3(-92.0, 2.0, 148.0)

## §19.3 : `zone.category.name.index`. Aucun de ces cinq identifiants n'est
## utilisé ailleurs dans le monde.
const POI_FALLS: StringName = &"valley.poi.veil_falls.01"
const POI_CIRCLE: StringName = &"valley.poi.watchers_circle.01"
const POI_GORGE: StringName = &"valley.poi.wind_gorge.01"
const POI_GROVE: StringName = &"valley.poi.storm_grove.01"
const POI_STRUCK: StringName = &"valley.poi.thunderstruck_tree.01"

# --- Cotes de la chute ------------------------------------------------------

## Lèvre de la chute et plateau panoramique (local, donc au-dessus du sol).
const FALLS_TOP_Y: float = 20.0
## Centre de l'abri creusé derrière le rideau d'eau. On y entre en TRAVERSANT
## la chute : le rideau n'a pas de collision, la roche en a une.
const FALLS_SHELTER: Vector3 = Vector3(0.0, 0.0, -12.0)

# --- Cotes du cercle --------------------------------------------------------

const CIRCLE_RADIUS: float = 11.0
## Douze positions régulières, dont une laissée VIDE : c'est l'entrée, et son
## absence est ce qui prouve une intention. Le trilithe l'encadre.
const CIRCLE_SLOTS: int = 12
## Hauteur du dessus de l'autel central — la dalle sur laquelle on monte.
const CIRCLE_ALTAR_TOP: float = 0.7

# --- Cotes de la gorge ------------------------------------------------------

## La gorge n'est pas alignée sur la grille du monde : une faille orthogonale
## se lirait comme un couloir de donjon. Le lacet reste modeste (≈ 14°).
const GORGE_YAW: float = 0.24
## Longueur des parois, et demi-largeur du passage LIBRE au sol.
const GORGE_LENGTH: float = 44.0
const GORGE_HALF_WIDTH: float = 2.2
## Entrée sud et sortie nord, en coordonnées LOCALES de la gorge.
const GORGE_MOUTH_SOUTH: Vector3 = Vector3(0.0, 0.0, 23.0)
const GORGE_MOUTH_NORTH: Vector3 = Vector3(0.0, 0.0, -23.0)

# --- Cotes du bosquet -------------------------------------------------------

## Inclinaison des arbres vivants. Le vent descend de la citadelle (−Z), les
## troncs fuient donc vers +Z : une rotation POSITIVE autour de X couche la
## cime vers le sud. C'est l'indice environnemental du lieu — le bosquet
## désigne la source de l'orage sans une ligne de texte.
const GROVE_LEAN: float = 0.30
## Rayon de la clairière rasée, au centre.
const GROVE_CLEARING: float = 5.4

# --- Cotes de l'arbre foudroyé ----------------------------------------------

const STRUCK_TRUNK_H: float = 9.0
## Largeur de la fente ouverte par la foudre, entre les deux demi-troncs.
const STRUCK_SPLIT: float = 0.42

# --- Palette (VISUAL_ASSET_BIBLE §1.4) --------------------------------------

const COL_ROCK: Color = Color(0.61, 0.41, 0.26)          # roche ocre
const COL_ROCK_SHADE: Color = Color(0.44, 0.34, 0.26)    # creux, sous-face
const COL_STONE: Color = Color(0.47, 0.45, 0.43)         # granite du monument
const COL_STONE_SHADE: Color = Color(0.34, 0.33, 0.32)
const COL_WATER: Color = Color(0.09, 0.55, 0.60, 0.82)   # même eau que la rivière
const COL_WATER_BED: Color = Color(0.20, 0.30, 0.30)     # fond du bassin
## Rideau de la chute : de l'eau en CHUTE, donc pâle et laiteuse. Très
## désaturée — ce n'est pas du cyan, et elle n'émet rien.
const COL_FALL: Color = Color(0.74, 0.86, 0.87, 0.62)
const COL_FOAM: Color = Color(0.92, 0.95, 0.94, 0.55)
const COL_MIST: Color = Color(0.86, 0.90, 0.91, 0.15)
const COL_CHARRED: Color = Color(0.13, 0.12, 0.12)       # bois brûlé
const COL_SPLIT: Color = Color(0.84, 0.78, 0.64)         # bois nu mis à vif
const COL_SCORCH: Color = Color(0.25, 0.22, 0.19)        # sol calciné
const COL_LEAF: Color = Color(0.36, 0.52, 0.24)          # verdure
const COL_LEAF_DRY: Color = Color(0.53, 0.51, 0.29)      # herbe battue

## Points d'intérêt portés par les cinq lieux, dans l'ordre de construction.
var pois: Array[PointOfInterest] = []

var _built: int = 0
var _cover: int = 0
var _materials: Dictionary = {}


func _ready() -> void:
	_build_veil_falls()
	_build_watchers_circle()
	_build_wind_gorge()
	_build_storm_grove()
	_build_thunderstruck_tree()


## Nombre de modèles réellement instanciés (un asset manquant ne compte pas).
func piece_count() -> int:
	return _built


## Nombre total de touffes écrites dans les MultiMesh de couvre-sol.
func cover_count() -> int:
	return _cover


func poi_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for poi: PointOfInterest in pois:
		ids.append(poi.poi_id)
	return ids


# ---------------------------------------------------------------------------
# Briques communes
# ---------------------------------------------------------------------------

## Instancie un modèle du kit. Renvoie `null` si l'asset manque, sans lever :
## un lieu amputé d'un modèle doit rester chargeable et le DIRE.
##
## `tilt` porte le roulis et le tangage en radians (x = tangage, y = roulis) :
## c'est ce qui permet de coucher un tronc ou de pencher un arbre sous le vent
## sans dupliquer un second modèle.
func _piece(asset: String, at: Vector3, yaw: float, parent: Node3D,
		factor: float = 1.0, tilt: Vector2 = Vector2.ZERO) -> Node3D:
	var packed: PackedScene = null
	for pattern: String in ASSET_DIRS:
		var full: String = pattern % asset
		if ResourceLoader.exists(full):
			packed = load(full) as PackedScene
			if packed != null:
				break
	if packed == null:
		push_warning("[merveilles] modèle absent du kit : %s" % asset)
		return null
	var node: Node3D = packed.instantiate() as Node3D
	if node == null:
		push_warning("[merveilles] modèle illisible : %s" % asset)
		return null
	# Nom unique par construction : Godot renommerait sinon en « @…@ », et un
	# nœud renommé n'est plus retrouvable par un test.
	node.name = "%s_%d" % [asset, _built]
	node.position = at
	node.rotation = Vector3(tilt.x, yaw, tilt.y)
	if not is_equal_approx(factor, 1.0):
		node.scale = Vector3.ONE * factor
	parent.add_child(node)
	_built += 1
	return node


## Matériau mis en cache : les lieux réutilisent une poignée de teintes, et
## dupliquer un `StandardMaterial3D` par bloc coûterait autant de pipelines.
func _material(colour: Color, rough: float = 0.92,
		transparent: bool = false) -> StandardMaterial3D:
	var key: String = "%s|%.2f|%s" % [colour, rough, transparent]
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = rough
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.metallic = 0.1
	_materials[key] = material
	return material


## Masse PLEINE : visuel et collision d'un seul bloc. `centre` est le centre
## géométrique, `size` la boîte complète, `yaw` son orientation.
func _solid(parent: Node3D, node_name: String, centre: Vector3, size: Vector3,
		colour: Color = COL_ROCK, yaw: float = 0.0) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "%sMesh" % node_name
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = _material(colour)
	body.add_child(mesh)
	# Transform AVANT `add_child` : un corps physique repositionné après son
	# entrée dans l'arbre se téléporte d'une frame.
	body.transform = Transform3D(Basis(Vector3.UP, yaw), centre)
	parent.add_child(body)
	return body


## Fût vertical plein — une capsule de collision carrée sur un tronc rond se
## sentirait immédiatement.
func _solid_trunk(parent: Node3D, node_name: String, foot: Vector3,
		radius: float, height: float) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	shape.position = Vector3(0, height * 0.5, 0)
	body.add_child(shape)
	body.position = foot
	parent.add_child(body)
	return body


## RAMPE praticable : une boîte inclinée dont la FACE SUPÉRIEURE passe
## exactement par `from` et `to` (tous deux exprimés en surface, pas en
## centre). Un raccord approximatif laisserait une marche invisible.
func _ramp_solid(parent: Node3D, node_name: String, from: Vector3, to: Vector3,
		width: float, thickness: float, colour: Color = COL_ROCK) -> StaticBody3D:
	var flat: Vector2 = Vector2(to.x - from.x, to.z - from.z)
	var run: float = flat.length()
	var rise: float = to.y - from.y
	var length: float = sqrt(run * run + rise * rise)
	var yaw: float = atan2(flat.x, flat.y)
	var pitch: float = -atan2(rise, run)
	var basis: Basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(width, thickness, length)
	shape.shape = box
	body.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "%sMesh" % node_name
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = box.size
	mesh.mesh = box_mesh
	mesh.material_override = _material(colour)
	body.add_child(mesh)
	var centre: Vector3 = (from + to) * 0.5 - (basis * Vector3.UP) * thickness * 0.5
	body.transform = Transform3D(basis, centre)
	parent.add_child(body)
	return body


## Panneau purement VISUEL : pas de collision. C'est ce qui permet de traverser
## le rideau d'eau à pied et d'entrer dans l'abri.
func _panel(parent: Node3D, node_name: String, centre: Vector3, size: Vector3,
		colour: Color, rough: float = 0.9, transparent: bool = false,
		yaw: float = 0.0) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = node_name
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = _material(colour, rough, transparent)
	mesh.transform = Transform3D(Basis(Vector3.UP, yaw), centre)
	parent.add_child(mesh)
	return mesh


## Disque plat visuel : nappe d'eau, écume, embrun, cerne de brûlé.
func _disc(parent: Node3D, node_name: String, centre: Vector3, radius: float,
		height: float, colour: Color, rough: float = 0.9,
		transparent: bool = false) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = node_name
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	mesh.mesh = cylinder
	mesh.material_override = _material(colour, rough, transparent)
	mesh.position = centre
	parent.add_child(mesh)
	return mesh


## Noircit un modèle importé : le kit ne livre pas d'arbre calciné, et un
## `material_override` posé sur chaque `MeshInstance3D` du sous-arbre coûte
## moins qu'un asset dédié tout en disant la même chose.
func _charred(node: Node3D, colour: Color) -> void:
	if node == null:
		return
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		var mesh: MeshInstance3D = current as MeshInstance3D
		if mesh != null:
			mesh.material_override = _material(colour, 0.95)
		for child: Node in current.get_children():
			stack.append(child)


## Volume d'approche du lieu. Il ne porte AUCUN gameplay : la découverte est
## arbitrée par le `DiscoveryLog`, jamais par le lieu lui-même.
func _declare(parent: Node3D, poi_id: StringName, display_name: String,
		region: StringName, extent: Vector3, offset: Vector3) -> PointOfInterest:
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "PointDInteret"
	poi.poi_id = poi_id
	poi.display_name = display_name
	poi.region = region
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = extent
	shape.shape = box
	poi.add_child(shape)
	poi.position = offset
	parent.add_child(poi)
	pois.append(poi)
	return poi


## Semis de modèles récoltables ou décoratifs autour d'un centre — disposition
## DÉTERMINISTE (angle et rayon dérivés de l'index), pour qu'une capture de
## référence reste rejouable.
func _scatter(parent: Node3D, assets: Array[String], centre: Vector3,
		radius_min: float, radius_max: float, count: int, factor: float,
		seed_offset: float = 0.0) -> void:
	if assets.is_empty():
		return
	for i: int in range(count):
		var angle: float = TAU * float(i) * 0.618034 + seed_offset
		var span: float = float(i % 5) / 4.0
		var radius: float = radius_min + (radius_max - radius_min) * span
		var at: Vector3 = centre + Vector3(cos(angle) * radius, 0.0,
			sin(angle) * radius)
		var wobble: float = 1.0 + 0.14 * float(i % 3) - 0.07
		_piece(assets[i % assets.size()], at, angle * 1.7, parent, factor * wobble)


# --- Couvre-sol en MultiMesh PARTITIONNÉ (§7.5) -----------------------------

## Un `MultiMeshInstance3D` par cellule : la bible interdit un tampon unique
## couvrant toute la vallée, et une cellule reste cullable d'un bloc.
##
## Le semis est en GRAPPES avec de vrais vides (§7.17 : un semis uniforme est
## un échec, même à un million d'instances), déterministe par graine, et il
## respecte deux exclusions — un rayon dégagé au centre, et un plan `min_z`
## derrière lequel se trouve la roche.
func _cover_cells(parent: Node3D, prefix: String, centre: Vector3, cells: int,
		cell_size: float, density: float, blade_height: float,
		low: Color, high: Color, seed_value: int,
		clear_centre: Vector3, clear_radius: float, min_z: float) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var mesh: ArrayMesh = _tuft_mesh(blade_height)
	# Albédo blanc : le shader fait `ALBEDO = albedo * COLOR`, donc la teinte
	# d'instance passe telle quelle.
	var material: Material = _foliage_material(Color(1, 1, 1), blade_height)
	var half: float = cell_size * 0.5
	var offset: float = (float(cells) - 1.0) * 0.5
	var target: int = int(cell_size * cell_size * density)
	for ix: int in range(cells):
		for iz: int in range(cells):
			var cell_centre: Vector3 = centre + Vector3(
				(float(ix) - offset) * cell_size, 0.0,
				(float(iz) - offset) * cell_size)
			var spots: PackedVector3Array = PackedVector3Array()
			var attempts: int = 0
			while spots.size() < target and attempts < target * 5:
				attempts += 1
				var cluster: Vector3 = cell_centre + Vector3(
					rng.randf_range(-half, half), 0.0,
					rng.randf_range(-half, half))
				if not _cover_allows(cluster, clear_centre, clear_radius, min_z):
					continue
				var grouped: int = rng.randi_range(4, 9)
				for j: int in range(grouped):
					if spots.size() >= target:
						break
					var spot: Vector3 = cluster + Vector3(
						rng.randf_range(-1.05, 1.05), 0.0,
						rng.randf_range(-1.05, 1.05))
					if _cover_allows(spot, clear_centre, clear_radius, min_z):
						spots.append(spot)
			if spots.is_empty():
				continue

			var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
			node.name = "%sCellule%d%d" % [prefix, ix, iz]
			node.material_override = material
			var multimesh: MultiMesh = MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.use_colors = true
			multimesh.mesh = mesh
			multimesh.instance_count = spots.size()
			node.multimesh = multimesh
			# Le RenderingServer sans fenêtre ne restitue pas les tampons
			# d'instance (`get_instance_transform` rend l'identité, mesuré sur
			# la prairie de crête). Les origines et teintes sont donc AUSSI
			# consignées en métadonnées, par la même boucle : le test lit ce
			# qui a été écrit, pas ce que le serveur veut bien rendre.
			var origins: PackedVector3Array = PackedVector3Array()
			var tints: PackedColorArray = PackedColorArray()
			for i: int in range(spots.size()):
				var spot: Vector3 = spots[i]
				var basis: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)) \
					.scaled(Vector3.ONE * rng.randf_range(0.72, 1.34))
				var tint: Color = low.lerp(high, rng.randf())
				multimesh.set_instance_transform(i, Transform3D(basis, spot))
				multimesh.set_instance_color(i, tint)
				origins.append(spot)
				tints.append(tint)
			node.set_meta(&"origins", origins)
			node.set_meta(&"tints", tints)
			parent.add_child(node)
			_cover += spots.size()


func _cover_allows(spot: Vector3, clear_centre: Vector3, clear_radius: float,
		min_z: float) -> bool:
	if spot.z < min_z:
		return false
	return spot.distance_to(clear_centre) >= clear_radius


## Matériau de végétation : shader de vent partagé, repli `StandardMaterial3D`
## si le shader n'est pas livré. Un couvre-sol sans vent reste un couvre-sol ;
## un couvre-sol qui échoue à charger est une erreur bloquante.
func _foliage_material(albedo: Color, height: float) -> Material:
	if ResourceLoader.exists(FOLIAGE_SHADER):
		var shader: Shader = load(FOLIAGE_SHADER) as Shader
		if shader != null:
			var material: ShaderMaterial = ShaderMaterial.new()
			material.shader = shader
			material.set_shader_parameter(&"albedo", albedo)
			material.set_shader_parameter(&"blade_height", height)
			material.set_shader_parameter(&"sway_amplitude", 0.05)
			return material
	push_warning("[merveilles] shader de vent absent — repli sans balancement")
	var fallback: StandardMaterial3D = StandardMaterial3D.new()
	fallback.albedo_color = albedo
	fallback.vertex_color_use_as_albedo = true
	fallback.roughness = 0.9
	fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
	return fallback


## Touffe : cinq brins en éventail, origine AU SOL (le shader normalise
## `VERTEX.y` par `blade_height`). Normales redressées vers le ciel, sinon un
## brin reçoit une lumière horizontale et se découpe en carton noir.
func _tuft_mesh(height: float) -> ArrayMesh:
	const BLADES: int = 5
	const SKY_BIAS: float = 0.72
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in range(BLADES):
		var yaw: float = TAU * float(k) / float(BLADES) + 0.27 * float(k % 3)
		var basis: Basis = Basis(Vector3.UP, yaw)
		# Chaque brin s'écarte du centre et se COUCHE vers sa pointe : c'est ce
		# ploiement qui donne la silhouette d'une touffe au repos.
		var lean: float = 0.09 + 0.05 * float(k % 4)
		var tall: float = height * (0.70 + 0.10 * float(k % 4))
		var root: Vector3 = basis * Vector3(0.0, 0.0, 0.022 * float(k % 3))
		var tip: Vector3 = root + basis * Vector3(lean, tall, 0.0)
		var side: Vector3 = basis * Vector3(0.0, 0.0, 0.017)
		var face: Vector3 = basis * Vector3(1.0, 0.0, 0.0)
		var normal: Vector3 = face.lerp(Vector3.UP, SKY_BIAS).normalized()
		var quad: Array[Vector3] = [
			root - side, root + side, tip + side * 0.35,
			root - side, tip + side * 0.35, tip - side * 0.35,
		]
		for vertex: Vector3 in quad:
			st.set_normal(normal)
			st.add_vertex(vertex)
	return st.commit()


# ---------------------------------------------------------------------------
# 1. LA CHUTE DU VOILE — plaine sud-est
# ---------------------------------------------------------------------------
#
# Une paroi de 20 m ouverte en son milieu, un rideau d'eau qui tombe de la
# lèvre, un bassin en bas. C'est la seule masse EN MOUVEMENT du monde : à
# 150 m, ce qui identifie le lieu n'est ni sa forme ni sa couleur, c'est le
# fait que quelque chose y bouge en permanence.
#
# Trois raisons d'y aller :
#   - l'ABRI derrière le rideau — on traverse l'eau (le rideau n'a pas de
#     collision) et on entre dans une niche sèche de 10 × 8 m où pousse la
#     récolte d'ombre ;
#   - le PANORAMA — un couloir de roche à l'est monte à la lèvre par une rampe
#     de 35°, d'où l'on domine toute la plaine ;
#   - le ruisseau de sortie, qui file vers le sud et dit d'où vient l'eau.
#
# Le turquoise est une EAU (même teinte que la rivière), le blanc est de
# l'ÉCUME. Ni l'un ni l'autre n'émet : le cyan reste à la Résonance (§3.4).
func _build_veil_falls() -> void:
	var place: Node3D = Node3D.new()
	place.name = "ChuteDuVoile"
	add_child(place)
	place.position = SITE_FALLS

	# --- La paroi -----------------------------------------------------------
	var cliff: Node3D = Node3D.new()
	cliff.name = "Falaise"
	place.add_child(cliff)
	# Deux jambages, un linteau et un fond : la niche est le VIDE qu'ils
	# laissent, x de −5 à 5, z de −16 à −8, sur 8 m de haut.
	_solid(cliff, "ParoiGauche", Vector3(-12.5, 10.0, -14.0), Vector3(15, 20, 12))
	_solid(cliff, "ParoiDroite", Vector3(12.5, 10.0, -14.0), Vector3(15, 20, 12))
	_solid(cliff, "LinteauDeNiche", Vector3(0.0, 14.0, -14.0), Vector3(10, 12, 12))
	_solid(cliff, "FondDeNiche", Vector3(0.0, 4.0, -18.0), Vector3(10, 8, 4),
		COL_ROCK_SHADE)
	# Épaules : elles portent la silhouette au-delà de la lèvre (26 m) et
	# encadrent la chute sans la boucher.
	_solid(cliff, "EpauleGauche", Vector3(-30.0, 13.0, -16.0), Vector3(14, 26, 14),
		COL_ROCK_SHADE)
	_solid(cliff, "EpauleDroite", Vector3(34.0, 13.0, -16.0), Vector3(14, 26, 14),
		COL_ROCK_SHADE)
	# Habillage : des blocs cassent les arêtes de boîte au pied de la paroi.
	for i: int in range(9):
		var along: float = -18.0 + float(i) * 4.6
		if absf(along) < 6.0:
			continue   # devant la niche : on n'obstrue pas l'entrée
		_piece("Rock_Medium_%d" % (1 + i % 3), Vector3(along, 0.0, -8.6),
			float(i) * 1.3, cliff, 1.5 + 0.3 * float(i % 2))

	# --- La montée à la lèvre ----------------------------------------------
	# Couloir de 7 m entre la paroi (x ≤ 20) et l'épaule droite (x ≥ 27) : la
	# rampe y monte 20 m sur 28 m de course, soit 35,5°, sous les 46°
	# franchissables de §8.2.
	_ramp_solid(cliff, "RampeDeLaLevre", Vector3(23.5, 0.0, 16.0),
		Vector3(23.5, FALLS_TOP_Y, -12.0), 5.0, 1.4, COL_ROCK)
	# Palier de raccord : sa face supérieure affleure EXACTEMENT la lèvre.
	_solid(cliff, "PalierDeLevre", Vector3(21.5, FALLS_TOP_Y - 0.5, -14.0),
		Vector3(5, 1, 10), COL_ROCK)

	# --- Le rideau ----------------------------------------------------------
	var fall: Node3D = Node3D.new()
	fall.name = "Chute"
	place.add_child(fall)
	# Aucune collision sur ces trois volumes : on TRAVERSE la chute.
	_panel(fall, "RideauDEau", Vector3(0.0, 10.0, -7.7), Vector3(9.6, 20.0, 0.35),
		COL_FALL, 0.16, true)
	# La veine centrale est de l'écume, pas un cœur d'énergie : blanc cassé,
	# opacité modérée, aucune émission.
	_panel(fall, "VeineDEcume", Vector3(0.0, 10.0, -7.42), Vector3(4.0, 20.0, 0.5),
		COL_FOAM, 0.22, true)
	_disc(fall, "Embrun", Vector3(0.0, 1.2, -6.0), 6.2, 2.6, COL_MIST, 0.5, true)

	# --- Le bassin ----------------------------------------------------------
	var basin: Node3D = Node3D.new()
	basin.name = "Bassin"
	place.add_child(basin)
	_disc(basin, "FondDuBassin", Vector3(0.0, 0.08, -0.5), 8.0, 0.16,
		COL_WATER_BED, 0.95)
	_disc(basin, "NappeDEau", Vector3(0.0, 0.36, -0.5), 7.5, 0.5, COL_WATER,
		0.15, true)
	_disc(basin, "EcumeDImpact", Vector3(0.0, 0.66, -6.4), 3.4, 0.14, COL_FOAM,
		0.3, true)
	# Margelle : on s'assoit dessus, on en fait le tour, on ne traverse pas le
	# bassin par erreur. Les positions trop proches de la paroi sont écartées.
	for i: int in range(12):
		var angle: float = TAU * float(i) / 12.0 + 0.26
		var at: Vector3 = Vector3(cos(angle) * 8.6, 0.0, sin(angle) * 8.6 - 0.5)
		if at.z < -5.5:
			continue
		_solid(basin, "Margelle%d" % i, at + Vector3(0, 0.45, 0),
			Vector3(2.0, 0.9, 2.0), COL_ROCK_SHADE, angle)
		_piece("Rock_Medium_%d" % (1 + i % 3), at, angle, basin,
			0.65 + 0.12 * float(i % 3))
	# L'exutoire : dix galets et trois plantes d'eau qui filent vers le sud.
	for i: int in range(10):
		var run: float = float(i)
		_piece("Pebble_Round_%d" % (1 + i % 5),
			Vector3(1.4 + sin(run * 0.9) * 1.8, 0.05, 8.0 + run * 2.1),
			run * 0.8, basin, 1.4)
	var water_plants: Array[String] = ["Plant_7_Big", "Plant_1", "Fern_1"]
	_scatter(basin, water_plants, Vector3(2.2, 0.0, 14.0), 1.2, 3.6, 4, 0.6, 0.4)

	# --- L'abri derrière l'eau ---------------------------------------------
	var shelter: Node3D = Node3D.new()
	shelter.name = "Abri"
	place.add_child(shelter)
	# Sol PORTEUR explicite : l'abri ne dépend pas du terrain pour exister, et
	# c'est ce qui permet d'y tenir debout dans une scène isolée.
	_solid(shelter, "SolDeLAbri", Vector3(0.0, -0.25, -12.0),
		Vector3(10.4, 0.5, 8.4), COL_ROCK_SHADE)
	var shade_crop: Array[String] = ["Mushroom_Common", "Mushroom_Laetiporus"]
	_scatter(shelter, shade_crop, FALLS_SHELTER, 1.2, 3.4, 6, 1.0, 1.1)
	var shade_ferns: Array[String] = ["Fern_1", "Plant_7"]
	_scatter(shelter, shade_ferns, FALLS_SHELTER + Vector3(0, 0, -1.5), 1.4, 3.2,
		5, 0.3, 2.3)
	# Fragment d'histoire : quelqu'un a dormi ici, à l'abri de l'eau et des
	# regards. Foyer froid, corde, seau, caisse — aucun texte.
	_piece("Crate_Wooden", FALLS_SHELTER + Vector3(-3.2, 0.0, -1.9), 0.6, shelter)
	_piece("Bucket_Wooden_1", FALLS_SHELTER + Vector3(-2.2, 0.0, -2.6), 1.8,
		shelter)
	_piece("Rope_1", FALLS_SHELTER + Vector3(2.8, 0.0, -2.4), 2.4, shelter)
	_piece("Bag", FALLS_SHELTER + Vector3(3.3, 0.0, -1.4), 0.9, shelter)
	for i: int in range(7):
		var angle: float = TAU * float(i) / 7.0 + 0.4
		_piece("Pebble_Round_%d" % (1 + i % 5),
			FALLS_SHELTER + Vector3(cos(angle) * 0.8 + 2.4, 0.0,
				sin(angle) * 0.8 - 3.0), angle * 2.1, shelter, 1.2)
	# Vignes ruisselantes sur la lèvre de la niche : elles disent « naturel »
	# là où la géométrie dit « boîte ».
	for i: int in range(4):
		var vine: String = "Prop_Vine1" if i % 2 == 0 else "Prop_Vine2"
		_piece(vine, Vector3(-3.6 + float(i) * 2.4, 7.6, -8.2), float(i) * 0.7,
			shelter, 1.3)

	# --- La lèvre et son panorama ------------------------------------------
	var summit: Node3D = Node3D.new()
	summit.name = "Sommet"
	place.add_child(summit)
	# Bordure de la lèvre : on voit le vide sans qu'un mur cache la plaine.
	for i: int in range(8):
		var along: float = -16.0 + float(i) * 4.6
		_piece("Rock_Medium_%d" % (1 + i % 3),
			Vector3(along, FALLS_TOP_Y - 0.3, -8.8), float(i) * 1.1, summit, 0.7)
	_piece("DeadTree_2", Vector3(-13.0, FALLS_TOP_Y, -15.5), 1.2, summit, 0.8)
	_piece("TwistedTree_3", Vector3(14.0, FALLS_TOP_Y, -16.5), 2.4, summit, 0.55)
	_piece("Torch_Metal", Vector3(-9.0, FALLS_TOP_Y, -13.0), 0.4, summit)
	_piece("Prop_WoodenFence_Single", Vector3(-7.6, FALLS_TOP_Y, -12.2), 0.3,
		summit)
	var summit_grass: Array[String] = ["Grass_Wispy_Short", "Grass_Common_Short",
		"Clover_2"]
	_scatter(summit, summit_grass, Vector3(-4.0, FALLS_TOP_Y, -14.0), 2.0, 6.0,
		9, 0.65, 1.6)

	# --- Rive et récolte ----------------------------------------------------
	var bushes: Array[String] = ["Bush_Common_Flowers", "Bush_Common"]
	_scatter(place, bushes, Vector3(-7.0, 0.0, 5.0), 2.4, 6.0, 5, 0.85, 1.2)
	var bank: Array[String] = ["Clover_1", "Clover_2", "Fern_1"]
	_scatter(place, bank, Vector3(0.0, 0.0, 0.0), 9.5, 13.0, 8, 0.8, 3.1)
	_piece("CommonTree_4", Vector3(-14.0, 0.0, 6.5), 1.1, place, 0.85)
	_piece("CommonTree_2", Vector3(15.0, 0.0, 8.0), 2.3, place, 0.75)
	# Herbe humide autour du bassin, en cellules (§7.5). L'exclusion évite la
	# nappe d'eau et tout ce qui est derrière la ligne de la paroi.
	_cover_cells(place, "HerbeHumide", Vector3(0.0, 0.0, 4.0), 2, 16.0, 0.55,
		0.34, COL_LEAF, Color(0.55, 0.68, 0.32), 20260803,
		Vector3(0.0, 0.0, -0.5), 8.8, -6.0)

	_declare(place, POI_FALLS, "La Chute du Voile", &"cascade",
		Vector3(46, 30, 46), Vector3(0, 10, 0))


# ---------------------------------------------------------------------------
# 2. LE CERCLE DES VEILLEURS — plaine nord-ouest
# ---------------------------------------------------------------------------
#
# Douze positions régulières sur un cercle de 11 m. Onze portent une pierre ;
# la douzième est VIDE, et c'est elle qui prouve l'intention — un éboulis n'a
# pas de porte. Le trilithe qui l'encadre pointe le nord, c'est-à-dire la
# citadelle : le monument regarde la tempête depuis bien avant le joueur.
#
# Trois pierres sont couchées, une est fendue : le temps a passé, personne
# n'entretient plus rien. L'autel central est une dalle basse sur laquelle on
# MONTE — le seul endroit du cercle d'où l'on voit par-dessus les pierres.
#
# Fragment d'histoire (offrandes au pied de la pierre nord-est) et récolte au
# pied des monolithes : le lieu paie le détour de deux façons.
func _build_watchers_circle() -> void:
	var place: Node3D = Node3D.new()
	place.name = "CercleDesVeilleurs"
	add_child(place)
	place.position = SITE_CIRCLE

	var stones: Node3D = Node3D.new()
	stones.name = "Menhirs"
	place.add_child(stones)

	# Les onze dressées. Le repère angulaire est choisi pour que l'angle 0
	# regarde le NORD (−Z) : la position vide, donc l'entrée, y tombe.
	for slot: int in range(1, CIRCLE_SLOTS):
		var angle: float = TAU * float(slot) / float(CIRCLE_SLOTS)
		var at: Vector3 = Vector3(sin(angle) * CIRCLE_RADIUS, 0.0,
			-cos(angle) * CIRCLE_RADIUS)
		# Trois pierres COUCHÉES : le monument n'est pas entretenu.
		var fallen: bool = slot == 4 or slot == 7 or slot == 10
		if fallen:
			# Une pierre à terre garde sa longueur, mais à l'horizontale : la
			# boîte tourne de 90° dans le plan vertical, ce qui revient à
			# échanger sa hauteur et sa profondeur.
			_solid(stones, "Menhir%02d" % slot, at + Vector3(0, 0.6, 0),
				Vector3(1.7, 1.2, 5.6), COL_STONE_SHADE, -angle)
			_piece("Rock_Medium_%d" % (1 + slot % 3), at + Vector3(0.9, 0.0, 0.9),
				angle, stones, 0.9)
			continue
		var tall: float = 5.2 + 0.28 * float(slot % 5)
		# `yaw = -angle` place la grande face TANGENTE au cercle et tourne la
		# tranche vers le centre : les onze pierres se regardent.
		_solid(stones, "Menhir%02d" % slot, at + Vector3(0, tall * 0.5, 0),
			Vector3(1.7, tall, 1.2), COL_STONE, -angle)
		# Un caillou appuyé au pied casse l'arête de la boîte.
		if slot % 2 == 0:
			_piece("Rock_Medium_%d" % (1 + slot % 3),
				at + Vector3(sin(angle) * 1.5, 0.0, -cos(angle) * 1.5),
				angle * 1.3, stones, 0.7)

	# --- La porte -----------------------------------------------------------
	var gate: Node3D = Node3D.new()
	gate.name = "Porte"
	place.add_child(gate)
	# Deux montants de 8 m et un linteau : le passage libre fait 4,2 m de large
	# et 8 m sous le linteau. C'est la silhouette qu'on voit de la plaine.
	for side: float in [-1.0, 1.0]:
		var tag: String = "Ouest" if side < 0.0 else "Est"
		_solid(gate, "Montant%s" % tag,
			Vector3(side * 2.9, 4.0, -CIRCLE_RADIUS), Vector3(1.6, 8.0, 1.4),
			COL_STONE)
	_solid(gate, "Linteau", Vector3(0.0, 8.5, -CIRCLE_RADIUS),
		Vector3(8.0, 1.0, 1.6), COL_STONE)

	# --- L'autel ------------------------------------------------------------
	# Dalle basse, au centre exact : on y monte, et de là seulement on voit
	# par-dessus les pierres couchées jusqu'à la plaine.
	_solid(place, "Autel", Vector3(0.0, CIRCLE_ALTAR_TOP * 0.5, 0.0),
		Vector3(3.4, CIRCLE_ALTAR_TOP, 3.4), COL_STONE_SHADE, 0.22)
	_piece("RockPath_Round_Wide", Vector3(0.0, CIRCLE_ALTAR_TOP + 0.02, 0.0),
		0.22, place, 1.5)

	# --- Le cercle extérieur ------------------------------------------------
	# Seize petites pierres à 15,5 m : elles doublent le cercle et disent que
	# l'ouvrage était plus vaste que ce qu'il en reste.
	for i: int in range(16):
		var angle: float = TAU * float(i) / 16.0 + 0.13
		_piece("Rock_Medium_%d" % (1 + i % 3),
			Vector3(sin(angle) * 15.5, 0.0, -cos(angle) * 15.5), angle,
			place, 0.55 + 0.1 * float(i % 3))

	# --- L'allée d'accès ----------------------------------------------------
	# Huit dalles venant du sud, c'est-à-dire de la vallée. Elles s'arrêtent au
	# cercle extérieur : on entre par le sud, on traverse le monument, et c'est
	# en ressortant par la porte du nord qu'on se retrouve face à la citadelle.
	# C'est la seule ligne droite du lieu, et elle sert cette lecture.
	for i: int in range(8):
		_piece("RockPath_Square_Wide",
			Vector3(sin(float(i) * 0.7) * 0.6, 0.04, 26.0 - float(i) * 1.9),
			float(i) * 0.35, place, 1.3)

	# --- Les offrandes ------------------------------------------------------
	var offerings: Node3D = Node3D.new()
	offerings.name = "Offrandes"
	place.add_child(offerings)
	offerings.position = Vector3(7.2, 0.0, 7.2)
	_piece("Pot_1", Vector3(0.0, 0.0, 0.0), 0.5, offerings)
	_piece("Pot_1_Lid", Vector3(0.55, 0.0, 0.35), 1.9, offerings)
	_piece("Bottle_1", Vector3(-0.6, 0.0, 0.4), 2.7, offerings)
	_piece("Scroll_1", Vector3(0.2, 0.0, -0.7), 1.2, offerings)
	_piece("Banner_2", Vector3(-1.6, 0.0, -0.9), 0.3, offerings, 0.85)
	_piece("Chain_Coil", Vector3(1.3, 0.0, -0.5), 2.2, offerings)
	# Spirale de galets vers l'autel : le seul « texte » du lieu.
	for i: int in range(9):
		var t: float = float(i) / 8.0
		var angle: float = t * 3.4
		var radius: float = 1.4 + t * 4.6
		_piece("Pebble_Round_%d" % (1 + i % 5),
			Vector3(-cos(angle) * radius, 0.0, -sin(angle) * radius),
			angle, offerings, 1.25)

	# --- La récolte ---------------------------------------------------------
	var herbs: Array[String] = ["Clover_1", "Clover_2", "Fern_1", "Plant_7"]
	_scatter(place, herbs, Vector3.ZERO, 9.0, 13.5, 12, 0.45, 0.8)
	var caps: Array[String] = ["Mushroom_Common"]
	_scatter(place, caps, Vector3(-8.0, 0.0, 4.0), 1.6, 4.2, 5, 1.0, 2.6)
	var blooms: Array[String] = ["Flower_3_Group", "Flower_4_Group",
		"Bush_Common_Flowers"]
	_scatter(place, blooms, Vector3.ZERO, 12.5, 17.0, 9, 0.6, 1.9)

	_declare(place, POI_CIRCLE, "Le Cercle des Veilleurs", &"plaine_nord",
		Vector3(40, 16, 40), Vector3(0, 6, 0))


# ---------------------------------------------------------------------------
# 3. LA GORGE DU VENT — plaine nord-est
# ---------------------------------------------------------------------------
#
# Un lieu qui n'est pas un objet mais un PASSAGE : deux parois de 18 m
# séparées par 4,4 m de couloir, sur 44 m de long. Le contournement par la
# plaine coûte plusieurs centaines de mètres ; la gorge est donc un vrai
# raccourci sur la route du nord (§2).
#
# Elle est réellement franchissable : le sol est dégagé d'un bout à l'autre.
# Ce qui la resserre est EN HAUTEUR — deux surplombs et un rocher coincé entre
# les parois. La menace se voit, elle ne bloque pas.
#
# Une alcôve s'ouvre à mi-parcours sur le flanc ouest : 5 × 5 m de dégagement
# où l'on sort du couloir, où quelqu'un a campé, et où pousse la récolte
# d'ombre. Elle est la respiration du lieu et sa récompense.
func _build_wind_gorge() -> void:
	var place: Node3D = Node3D.new()
	place.name = "GorgeDuVent"
	add_child(place)
	place.position = SITE_GORGE
	# Une faille alignée sur la grille du monde se lirait comme un couloir de
	# donjon. Le lacet reste faible pour que la lecture du passage demeure
	# immédiate depuis les deux entrées.
	place.rotation.y = GORGE_YAW

	var walls: Node3D = Node3D.new()
	walls.name = "Parois"
	place.add_child(walls)

	# Sol PORTEUR explicite : la gorge se traverse même hors du terrain de la
	# vallée, et c'est ce qui rend la traversée testable en scène isolée.
	_solid(place, "SolDeLaGorge", Vector3(0.0, -0.3, 0.0), Vector3(6.0, 0.6, 54.0),
		COL_ROCK_SHADE)

	var half_length: float = GORGE_LENGTH * 0.5
	var wall_offset: float = GORGE_HALF_WIDTH + 5.5
	# Flanc EST : d'une seule masse.
	_solid(walls, "ParoiEst", Vector3(wall_offset, 9.0, 0.0),
		Vector3(11, 18, GORGE_LENGTH))
	# Flanc OUEST : deux masses séparées par l'alcôve, dont le fond est reculé.
	_solid(walls, "ParoiOuestSud", Vector3(-wall_offset, 9.0, 11.5),
		Vector3(11, 18, 21))
	_solid(walls, "ParoiOuestNord", Vector3(-wall_offset, 9.0, -13.5),
		Vector3(11, 18, 17))
	_solid(walls, "FondDeLAlcove", Vector3(-wall_offset - 2.5, 9.0, -2.0),
		Vector3(6, 18, 6), COL_ROCK_SHADE)

	# Ce qui referme la gorge est EN HAUT : dégagement de 7,5 m au minimum,
	# soit quatre fois la taille du héros. On passe toujours.
	_solid(walls, "SurplombSud", Vector3(0.0, 10.5, 9.0), Vector3(5.6, 6.0, 4.6),
		COL_ROCK_SHADE)
	_solid(walls, "SurplombNord", Vector3(0.0, 11.5, -10.0),
		Vector3(5.6, 5.0, 3.8), COL_ROCK_SHADE)
	_solid(walls, "RocherCoince", Vector3(0.0, 15.5, -1.0),
		Vector3(4.2, 4.2, 4.2), COL_ROCK)

	# Couronne des parois : la ligne de crête, vue d'en bas.
	for i: int in range(10):
		var along: float = -half_length + 2.0 + float(i) * 4.4
		var edge: float = wall_offset - 4.0 if i % 2 == 0 else -wall_offset + 4.0
		_piece("Rock_Medium_%d" % (1 + i % 3), Vector3(edge, 18.0, along),
			float(i) * 1.4, walls, 1.7 + 0.3 * float(i % 2))
	# Vignes suspendues : elles marquent l'humidité du fond et cassent la
	# verticale des boîtes.
	for i: int in range(5):
		var vine: String = "Prop_Vine1" if i % 2 == 0 else "Prop_Vine2"
		_piece(vine, Vector3(GORGE_HALF_WIDTH - 0.2, 11.0 + float(i % 2) * 2.0,
			-14.0 + float(i) * 7.0), PI, walls, 1.4)

	# Évasement des deux bouches : sans lui, la gorge s'ouvre comme une porte.
	for i: int in range(8):
		var side: float = 1.0 if i % 2 == 0 else -1.0
		var end: float = 1.0 if i < 4 else -1.0
		var spread: float = 4.0 + float(i % 4) * 2.6
		_piece("Rock_Medium_%d" % (1 + i % 3),
			Vector3(side * spread, 0.0, end * (half_length + 1.5 + float(i % 4))),
			float(i) * 1.1, walls, 1.4 + 0.3 * float(i % 3))

	# --- L'alcôve -----------------------------------------------------------
	var alcove: Node3D = Node3D.new()
	alcove.name = "Alcove"
	place.add_child(alcove)
	alcove.position = Vector3(-4.6, 0.0, -2.0)
	# Fragment d'histoire : un campement, un foyer froid, du matériel laissé.
	_piece("Crate_Wooden", Vector3(-1.4, 0.0, -1.5), 0.6, alcove)
	_piece("Barrel", Vector3(-1.8, 0.0, 0.4), 1.4, alcove)
	_piece("Rope_1", Vector3(0.4, 0.0, -1.8), 2.1, alcove)
	_piece("Bucket_Wooden_1", Vector3(1.1, 0.0, 0.9), 0.8, alcove)
	_piece("Shelf_Simple", Vector3(-2.0, 0.0, 1.6), 0.1, alcove)
	for i: int in range(8):
		var angle: float = TAU * float(i) / 8.0 + 0.25
		_piece("Pebble_Round_%d" % (1 + i % 5),
			Vector3(cos(angle) * 0.85, 0.0, sin(angle) * 0.85), angle * 2.2,
			alcove, 1.25)
	# Récolte d'ombre : l'alcôve est le seul endroit humide et abrité du lieu.
	var alcove_crop: Array[String] = ["Mushroom_Common", "Mushroom_Laetiporus"]
	_scatter(alcove, alcove_crop, Vector3(0.4, 0.0, 0.6), 0.9, 2.2, 5, 1.0, 1.4)
	var alcove_ferns: Array[String] = ["Fern_1", "Plant_7"]
	_scatter(alcove, alcove_ferns, Vector3(-0.4, 0.0, -0.4), 1.0, 2.0, 4, 0.3, 2.9)

	# Végétation rase au fond de la faille : peu de lumière, donc peu de chose.
	var floor_plants: Array[String] = ["Clover_2", "Fern_1"]
	_scatter(place, floor_plants, Vector3(0.0, 0.0, 6.0), 1.2, 2.0, 4, 0.35, 0.7)
	_scatter(place, floor_plants, Vector3(0.0, 0.0, -16.0), 1.2, 2.0, 4, 0.35, 2.1)

	_declare(place, POI_GORGE, "La Gorge du Vent", &"gorges",
		Vector3(30, 22, 52), Vector3(0, 8, 0))


# ---------------------------------------------------------------------------
# 4. LE BOIS COURBÉ — sur le chemin du donjon
# ---------------------------------------------------------------------------
#
# Le dernier bosquet avant la citadelle, et le premier endroit où l'orage se
# lit dans la VÉGÉTATION plutôt que dans le ciel. Trois règles de composition,
# aucune lumière :
#
#   - tous les arbres vivants penchent dans le MÊME sens, vers le sud, parce
#     que le vent descend de la citadelle. C'est l'indice environnemental :
#     le bosquet désigne la source de l'orage ;
#   - la lisière NORD, exposée, ne porte que du bois mort ; la lisière sud,
#     à l'abri, reste verte. La frontière entre les deux est la mesure du
#     dégât ;
#   - au centre, une clairière rasée où rien ne repousse, et quatre troncs
#     abattus couchés en éventail depuis elle.
#
# Le couvre-sol est court, sec et dense (MultiMesh partitionné, §7.5) : une
# herbe battue, pas une prairie. Récolte de bois mort au pied des troncs.
func _build_storm_grove() -> void:
	var place: Node3D = Node3D.new()
	place.name = "BoisCourbe"
	add_child(place)
	place.position = SITE_GROVE

	# --- La clairière rasée -------------------------------------------------
	var clearing: Node3D = Node3D.new()
	clearing.name = "Clairiere"
	place.add_child(clearing)
	_disc(clearing, "SolCalcine", Vector3(0.0, 0.03, 0.0), GROVE_CLEARING, 0.06,
		COL_SCORCH, 0.98)
	# Six saignées rayonnantes : la terre a éclaté depuis le centre.
	for i: int in range(6):
		var angle: float = TAU * float(i) / 6.0 + 0.31
		var reach: float = GROVE_CLEARING + 1.4 + float(i % 3) * 0.9
		_panel(clearing, "Saignee%d" % i,
			Vector3(cos(angle) * reach * 0.6, 0.05, sin(angle) * reach * 0.6),
			Vector3(0.34, 0.05, reach), COL_SCORCH, 0.98, false, -angle + PI * 0.5)
	for i: int in range(6):
		var angle: float = TAU * float(i) / 6.0 + 0.9
		_piece("Rock_Medium_%d" % (1 + i % 3),
			Vector3(cos(angle) * (GROVE_CLEARING - 0.8), 0.0,
				sin(angle) * (GROVE_CLEARING - 0.8)), angle, clearing, 0.6)

	# --- Les arbres vivants, penchés ---------------------------------------
	var leaning: Node3D = Node3D.new()
	leaning.name = "ArbresPenches"
	place.add_child(leaning)
	# Rotation POSITIVE autour de X : la cime part vers +Z, donc vers le sud,
	# donc à l'opposé de la citadelle. Les onze arbres partagent ce signe —
	# c'est cette unanimité qui se lit comme du vent, pas comme du hasard.
	var live: Array[Array] = [
		["CommonTree_1", Vector3(-13.0, 0.0, 7.5), 0.85],
		["CommonTree_3", Vector3(-7.5, 0.0, 13.0), 0.95],
		["CommonTree_5", Vector3(2.0, 0.0, 11.5), 0.90],
		["CommonTree_2", Vector3(9.5, 0.0, 8.0), 0.80],
		["CommonTree_4", Vector3(14.5, 0.0, 13.5), 0.88],
		["Pine_2", Vector3(-16.0, 0.0, 1.5), 0.75],
		["Pine_4", Vector3(13.0, 0.0, 1.0), 0.70],
		["Pine_1", Vector3(-11.0, 0.0, 17.5), 0.82],
		["Pine_5", Vector3(6.5, 0.0, 17.0), 0.78],
		["TwistedTree_2", Vector3(17.0, 0.0, 5.5), 0.60],
		["TwistedTree_1", Vector3(-18.5, 0.0, 10.0), 0.55],
	]
	for i: int in range(live.size()):
		var entry: Array = live[i]
		var at: Vector3 = entry[1] as Vector3
		var lean: float = GROVE_LEAN - 0.06 + 0.035 * float(i % 4)
		_piece(entry[0] as String, at, at.x * 0.19, leaning, float(entry[2]),
			Vector2(lean, 0.0))
		_solid_trunk(leaning, "Tronc%d" % i, at, 0.55, 3.6)

	# --- Le bois mort, sur la lisière exposée ------------------------------
	var deadwood: Node3D = Node3D.new()
	deadwood.name = "BoisMort"
	place.add_child(deadwood)
	var dead: Array[Array] = [
		["DeadTree_1", Vector3(-9.0, 0.0, -11.0), 1.05],
		["DeadTree_2", Vector3(-1.5, 0.0, -15.0), 0.95],
		["DeadTree_1", Vector3(7.0, 0.0, -12.5), 1.15],
		["DeadTree_2", Vector3(14.0, 0.0, -8.0), 0.85],
		["TwistedTree_3", Vector3(-15.5, 0.0, -6.5), 0.55],
	]
	for i: int in range(dead.size()):
		var entry: Array = dead[i]
		var at: Vector3 = entry[1] as Vector3
		# Le bois mort penche PLUS fort : il n'a plus rien pour se redresser.
		var lean: float = GROVE_LEAN + 0.12 + 0.05 * float(i % 3)
		_piece(entry[0] as String, at, at.z * 0.23, deadwood, float(entry[2]),
			Vector2(lean, 0.0))
		_solid_trunk(deadwood, "Souche%d" % i, at, 0.45, 2.8)

	# --- Les troncs abattus -------------------------------------------------
	var fallen: Node3D = Node3D.new()
	fallen.name = "TroncsAbattus"
	place.add_child(fallen)
	# Quatre troncs couchés en éventail depuis la clairière : le souffle est
	# parti de là. Chacun porte une collision — on monte dessus.
	var logs: Array[Array] = [
		[Vector3(-8.0, 0.0, 4.0), 0.55],
		[Vector3(6.0, 0.0, 4.8), -0.42],
		[Vector3(-6.5, 0.0, -5.0), 2.35],
		[Vector3(8.5, 0.0, -4.2), -2.20],
	]
	for i: int in range(logs.size()):
		var entry: Array = logs[i]
		var at: Vector3 = entry[0] as Vector3
		var yaw: float = float(entry[1])
		# Un arbre couché : presque un quart de tour de tangage, ce qui pose la
		# cime au sol sans faire disparaître le pied sous le terrain.
		_piece("DeadTree_1" if i % 2 == 0 else "DeadTree_2",
			at + Vector3(0.0, 0.5, 0.0), yaw, fallen, 0.9,
			Vector2(PI * 0.46, 0.0))
		_solid(fallen, "TroncAbattu%d" % i, at + Vector3(0.0, 0.5, 0.0),
			Vector3(1.0, 1.0, 7.4), COL_ROCK_SHADE, yaw)
		# Le bois mort porte des polypores : la récolte du lieu.
		_piece("Mushroom_Laetiporus", at + Vector3(0.6, 1.0, 1.2), yaw * 1.7,
			fallen, 0.9)
		_piece("Mushroom_Laetiporus", at + Vector3(-0.5, 0.9, -1.6), yaw * 2.3,
			fallen, 0.75)

	# --- La récolte et le sol ----------------------------------------------
	var lee_crop: Array[String] = ["Mushroom_Common", "Fern_1", "Plant_7"]
	_scatter(place, lee_crop, Vector3(-4.0, 0.0, 8.0), 2.0, 6.5, 8, 0.65, 1.7)
	var dry_scrub: Array[String] = ["Grass_Wispy_Tall", "Grass_Common_Short",
		"Bush_Common"]
	_scatter(place, dry_scrub, Vector3(0.0, 0.0, -6.0), 6.0, 13.0, 9, 0.6, 2.8)
	# Cairn de bord de route : le chemin du donjon passe ici, et quelqu'un l'a
	# balisé avant que le bois ne se couche.
	_solid(place, "CairnDeRoute", Vector3(-19.0, 0.55, -2.0),
		Vector3(1.2, 1.1, 1.2), COL_ROCK_SHADE, 0.4)
	for i: int in range(3):
		_piece("Rock_Medium_%d" % (1 + i), Vector3(-19.0, 0.35 * float(i), -2.0),
			float(i) * 1.6, place, 0.5 - 0.1 * float(i))

	# Herbe battue : courte, sèche, dense, en cellules (§7.5).
	_cover_cells(place, "HerbeBattue", Vector3.ZERO, 2, 20.0, 0.70, 0.24,
		COL_LEAF_DRY, Color(0.40, 0.44, 0.26), 20260804, Vector3.ZERO,
		GROVE_CLEARING, -20.0)

	_declare(place, POI_GROVE, "Le Bois Courbé", &"orage",
		Vector3(46, 18, 46), Vector3(0, 7, 0))


# ---------------------------------------------------------------------------
# 5. L'ARBRE FOUDROYÉ — plaine sud-ouest
# ---------------------------------------------------------------------------
#
# Un seul arbre, en terrain plat, en vue de la crête de départ : la première
# preuve au SOL que l'orage de la citadelle porte jusqu'ici. Trois choses le
# décrivent, et pas une n'est lumineuse (§3.4) :
#
#   - le TRONC est noir. Le kit ne livre pas d'arbre calciné : le modèle mort
#     reçoit un `material_override` charbon, et deux demi-troncs pleins
#     portent sa collision ;
#   - une FENTE PÂLE court du pied à la cime, entre les deux moitiés — le
#     bois nu mis à vif par la décharge. C'est le seul clair de la
#     composition, et c'est du bois, pas une lueur ;
#   - au pied, des REPOUSSES : cinq jeunes arbres à un sixième de taille, des
#     buissons, une couronne d'herbe fraîche. La vie revient, et c'est ce
#     contraste qui fait tenir l'image.
#
# Récolte de polypores sur le bois mort, et un jalon de berger à côté : on se
# repérait déjà sur cet arbre avant qu'il ne brûle.
func _build_thunderstruck_tree() -> void:
	var place: Node3D = Node3D.new()
	place.name = "ArbreFoudroye"
	add_child(place)
	place.position = SITE_STRUCK

	var trunk: Node3D = Node3D.new()
	trunk.name = "Tronc"
	place.add_child(trunk)

	# Le modèle mort donne la silhouette éclatée ; il est noirci en place.
	var crown: Node3D = _piece("DeadTree_1", Vector3.ZERO, 0.35, trunk, 1.8)
	_charred(crown, COL_CHARRED)
	var stump: Node3D = _piece("DeadTree_2", Vector3(3.4, 0.0, -2.2), 2.1, trunk,
		0.7)
	_charred(stump, COL_CHARRED)

	# Les deux demi-troncs : ils portent la collision, et l'écart entre eux EST
	# la fente. `yaw` commun pour que la fente regarde la crête de départ.
	var split_yaw: float = 0.35
	for side: float in [-1.0, 1.0]:
		var tag: String = "Ouest" if side < 0.0 else "Est"
		_solid(trunk, "DemiTronc%s" % tag,
			Vector3(side * (STRUCK_SPLIT * 0.5 + 0.75), STRUCK_TRUNK_H * 0.5, 0.0),
			Vector3(1.5, STRUCK_TRUNK_H, 2.3), COL_CHARRED, split_yaw)
	# Le bois nu : plus clair que tout le reste de la composition, et mat.
	_panel(trunk, "FenteClaire", Vector3(0.0, STRUCK_TRUNK_H * 0.46, 0.0),
		Vector3(STRUCK_SPLIT, STRUCK_TRUNK_H * 0.92, 2.4), COL_SPLIT, 0.86,
		false, split_yaw)
	# Éclats projetés au pied : le bois est parti en échardes.
	for i: int in range(5):
		var angle: float = TAU * float(i) / 5.0 + 0.6
		_panel(trunk, "Echarde%d" % i,
			Vector3(cos(angle) * 2.2, 0.7, sin(angle) * 2.2),
			Vector3(0.22, 2.4, 0.5), COL_CHARRED, 0.95, false, -angle)

	# --- Le cerne de brûlé --------------------------------------------------
	_disc(place, "CerneCalcine", Vector3(0.0, 0.03, 0.0), 6.4, 0.06, COL_SCORCH,
		0.98)
	for i: int in range(8):
		var angle: float = TAU * float(i) / 8.0 + 0.22
		var reach: float = 6.4 + 1.6 + float(i % 3) * 1.1
		_panel(place, "Fissure%d" % i,
			Vector3(cos(angle) * reach * 0.6, 0.05, sin(angle) * reach * 0.6),
			Vector3(0.28, 0.05, reach), COL_SCORCH, 0.98, false,
			-angle + PI * 0.5)
	for i: int in range(8):
		var angle: float = TAU * float(i) / 8.0 + 1.1
		_piece("Pebble_Square_%d" % (1 + i % 2),
			Vector3(cos(angle) * (7.5 + float(i % 3)), 0.0,
				sin(angle) * (7.5 + float(i % 3))), angle * 1.9, place, 1.5)

	# --- Les repousses ------------------------------------------------------
	var regrowth: Node3D = Node3D.new()
	regrowth.name = "Repousses"
	place.add_child(regrowth)
	# Cinq jeunes arbres à un sixième de la taille adulte : à côté du géant
	# noir, c'est leur PETITESSE qui raconte le temps écoulé.
	var saplings: Array[Array] = [
		["CommonTree_2", Vector3(3.9, 0.0, 2.6), 0.20],
		["CommonTree_3", Vector3(-3.2, 0.0, 3.6), 0.17],
		["CommonTree_5", Vector3(-4.3, 0.0, -2.4), 0.19],
		["CommonTree_1", Vector3(2.4, 0.0, -4.1), 0.16],
		["Pine_3", Vector3(5.1, 0.0, -1.2), 0.22],
	]
	for i: int in range(saplings.size()):
		var entry: Array = saplings[i]
		var at: Vector3 = entry[1] as Vector3
		_piece(entry[0] as String, at, at.z * 0.8, regrowth, float(entry[2]))
	var young: Array[String] = ["Bush_Common", "Bush_Common_Flowers", "Plant_1",
		"Plant_1_Big"]
	_scatter(regrowth, young, Vector3.ZERO, 2.6, 5.4, 8, 0.55, 1.3)
	var herbs: Array[String] = ["Clover_1", "Clover_2", "Flower_4_Group"]
	_scatter(regrowth, herbs, Vector3.ZERO, 5.6, 8.4, 9, 0.6, 2.5)
	# Couronne d'herbe fraîche : le vert le plus franc de la scène, posé juste
	# au bord du noir. Elle s'arrête au cerne calciné (6,4 m) — le sol brûlé
	# reste NU, et c'est ce vide qui fait lire les repousses qui s'y risquent.
	_cover_cells(regrowth, "HerbeNeuve", Vector3.ZERO, 2, 14.0, 0.62, 0.30,
		COL_LEAF, Color(0.58, 0.72, 0.31), 20260805, Vector3.ZERO, 6.6, -14.0)

	# --- La récolte sur le bois mort ---------------------------------------
	_piece("Mushroom_Laetiporus", Vector3(1.35, 1.5, 0.6), 1.2, trunk, 0.95)
	_piece("Mushroom_Laetiporus", Vector3(-1.4, 2.7, -0.5), 2.7, trunk, 0.8)
	_piece("Mushroom_Laetiporus", Vector3(1.1, 3.6, -0.8), 0.5, trunk, 0.65)
	var base_crop: Array[String] = ["Mushroom_Common", "Fern_1"]
	_scatter(place, base_crop, Vector3(-2.0, 0.0, 1.6), 1.8, 3.4, 5, 0.9, 0.9)

	# --- Le jalon de berger -------------------------------------------------
	var marker: Node3D = Node3D.new()
	marker.name = "Marque"
	place.add_child(marker)
	marker.position = Vector3(-7.6, 0.0, 5.2)
	_solid(marker, "Borne", Vector3(0.0, 0.65, 0.0), Vector3(0.9, 1.3, 0.9),
		COL_ROCK_SHADE, 0.5)
	for i: int in range(3):
		_piece("Rock_Medium_%d" % (1 + i), Vector3(0.0, 0.42 * float(i), 0.0),
			float(i) * 1.7, marker, 0.42 - 0.08 * float(i))
	_piece("Bucket_Wooden_1", Vector3(1.3, 0.0, 0.7), 1.1, marker)
	_piece("Rope_1", Vector3(-1.1, 0.0, 0.9), 2.5, marker)
	_piece("Prop_WoodenFence_Single", Vector3(-1.9, 0.0, -1.2), 0.4, marker)

	_declare(place, POI_STRUCK, "L'Arbre foudroyé", &"plaine_sud",
		Vector3(32, 18, 32), Vector3(0, 7, 0))
