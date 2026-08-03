## GROTTES DE LA VALLÉE — les espaces souterrains de l'ordre d'extension §2.
##
## La règle centrale de l'ordre est sans ambiguïté : « les grottes doivent être
## de véritables espaces explorables, pas de simples trous décoratifs ». Une
## bouche noire plaquée sur une falaise passerait n'importe quel comptage ; on
## construit donc, pour chacune des trois grottes :
##
##   1. une ENTRÉE franchissable — un seuil de 2,2 m de haut au minimum et de
##      plus de 1,6 m de large, la capsule du joueur (rayon 0,35, hauteur 1,7)
##      passe réellement ;
##   2. un VOLUME intérieur — sol porteur, parois fermées, plafond au-dessus de
##      la tête, où l'on tient debout ;
##   3. une RAISON d'y aller — coffre, filon, ingrédient, indice.
##
## Le dépôt n'a pas de kit de caverne. Les volumes sont donc bâtis en boîtes
## (BoxMesh + StaticBody3D/BoxShape3D, comme les colliders du village), puis
## HABILLÉS par les rochers du kit et, pour les parties maçonnées — mine étayée,
## crypte —, par les murs de brique. Les modèles du kit sont purement visuels :
## toute la collision vient des boîtes, ce qui permet de LAISSER un trou dans le
## seuil au lieu de murer la grotte de l'intérieur.
##
## Les trois grottes sont posées à l'écart des lieux déjà bâtis : village de la
## rivière (−70, 2, 36), camp ennemi (45, 6, 65), pylône (115, 18, −25), donjon
## (0, 34, −210), falaise d'apprentissage (x −140…−80, z 40…90), ruines
## centrales (z −65…−25). Chacune se DÉCLARE au journal des découvertes par un
## `PointOfInterest` d'identifiant §19.3.
class_name ValleyCaves
extends Node3D

## Le kit est réparti sur cinq dossiers (rochers, donjon, village, props,
## feuillage). Une pièce se résout par recherche, pas par chemin figé : déplacer
## un asset ne doit pas casser une grotte en silence.
const KIT_DIRS: Array[String] = [
	"res://assets/environment/rocks/%s.gltf",
	"res://assets/environment/dungeon/%s.gltf",
	"res://assets/environment/village/%s.gltf",
	"res://assets/environment/props/%s.gltf",
	"res://assets/environment/foliage/%s.gltf",
]

## Pas du kit Quaternius : murs et sols de 2 m, murs hauts de 3,12 m.
const MODULE: float = 2.0
const WALL_H: float = 3.12

## Gabarit du joueur, repris de la capsule du contrôleur. Aucune ouverture de ce
## fichier ne descend en dessous — c'est la définition même de « franchissable ».
const PLAYER_RADIUS: float = 0.35
const PLAYER_HEIGHT: float = 1.7
## Marges de sécurité de l'ordre : 1,6 m de large, 2,2 m de haut au minimum.
const MIN_GAP: float = 1.6
const MIN_CLEARANCE: float = 2.2

## Clés internes des trois grottes.
const CAVE_WATERFALL: StringName = &"cascade"
const CAVE_MINE: StringName = &"mine"
const CAVE_CRYPT: StringName = &"crypte"

## Implantations, en coordonnées de la vallée (plaines à y = 2).
## Cascade : plaine sud-ouest, au pied de la falaise d'apprentissage mais en
## dehors de son emprise (z 40…90) et de celle du village (x −93…−47).
const SITE_WATERFALL: Vector3 = Vector3(-118.0, 2.0, 26.0)
## Mine : plaine nord, à l'est de la terrasse du pylône (x 87…143, z −50…0).
const SITE_MINE: Vector3 = Vector3(160.0, 2.0, -70.0)
## Crypte : plaine nord, à l'ouest des ruines centrales (x −20…15, z −65…−25).
const SITE_CRYPT: Vector3 = Vector3(-60.0, 2.0, -90.0)

## Teintes graybox, dans la bande ocre/pierre de §3.4.
const COL_ROCK: Color = Color(0.42, 0.33, 0.26)
const COL_ROCK_DARK: Color = Color(0.27, 0.22, 0.19)
const COL_STONE: Color = Color(0.45, 0.44, 0.47)
const COL_EARTH: Color = Color(0.34, 0.30, 0.21)
const COL_WATER: Color = Color(0.35, 0.72, 0.78, 0.55)
const COL_ORE: Color = Color(0.13, 0.85, 0.93)
const COL_COPPER: Color = Color(0.55, 0.36, 0.22)


## Fiche d'une grotte : ce que les autres systèmes — et les tests — ont besoin
## de savoir sans fouiller l'arbre de scène.
class CaveRecord extends RefCounted:
	var key: StringName = &""
	var root: Node3D = null
	var poi: PointOfInterest = null
	## Point d'approche, DEHORS, devant le seuil (repère `ValleyCaves`).
	var entrance: Vector3 = Vector3.ZERO
	## Point de station, DEDANS, au-dessus du sol porteur (repère `ValleyCaves`).
	var interior: Vector3 = Vector3.ZERO
	## Normale sortante du seuil : on entre en allant vers `-door_normal`.
	var door_normal: Vector3 = Vector3.BACK
	## Cote du sol intérieur.
	var floor_y: float = 0.0


var _caves: Dictionary = {}
var _materials: Dictionary = {}
var _built: int = 0


func _ready() -> void:
	_build_waterfall_cave()
	_build_abandoned_mine()
	_build_forgotten_crypt()


# --- Contrat public ---------------------------------------------------------

## Nombre de volumes et de modèles réellement posés.
func piece_count() -> int:
	return _built


## Clés des grottes, dans l'ordre de construction.
func cave_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for key: StringName in _caves:
		keys.append(key)
	return keys


func has_cave(key: StringName) -> bool:
	return _caves.has(key)


func cave_root(key: StringName) -> Node3D:
	var record: CaveRecord = _record(key)
	if record == null:
		return null
	return record.root


func cave_poi(key: StringName) -> PointOfInterest:
	var record: CaveRecord = _record(key)
	if record == null:
		return null
	return record.poi


## Point d'ENTRÉE, en repère global : devant le seuil, dehors.
func entrance_point(key: StringName) -> Vector3:
	var record: CaveRecord = _record(key)
	if record == null:
		return Vector3.ZERO
	return to_global(record.entrance)


## Point INTÉRIEUR, en repère global : là où l'on doit tenir debout.
func interior_point(key: StringName) -> Vector3:
	var record: CaveRecord = _record(key)
	if record == null:
		return Vector3.ZERO
	return to_global(record.interior)


## Direction sortante du seuil, en repère global. On entre vers l'opposé.
func door_normal(key: StringName) -> Vector3:
	var record: CaveRecord = _record(key)
	if record == null:
		return Vector3.BACK
	return (global_transform.basis * record.door_normal).normalized()


## Cote du sol intérieur, en repère global.
func floor_level(key: StringName) -> float:
	var record: CaveRecord = _record(key)
	if record == null:
		return 0.0
	return to_global(Vector3(0.0, record.floor_y, 0.0)).y


## Déclare les trois grottes au journal des découvertes. L'injection reste
## explicite : une grotte ne sait pas si elle a déjà été vue, elle le DEMANDE.
func bind_all(discovery_log: DiscoveryLog) -> void:
	for key: StringName in _caves:
		var record: CaveRecord = _record(key)
		if record != null and record.poi != null:
			record.poi.bind(discovery_log)


func _record(key: StringName) -> CaveRecord:
	if not _caves.has(key):
		return null
	var record: CaveRecord = _caves[key]
	return record


# --- Briques ----------------------------------------------------------------

## Matériaux mis en cache par teinte : deux cents boîtes graybox ne doivent pas
## créer deux cents ressources. Le cache est PARTAGÉ — ne jamais muter un
## matériau rendu ici, le dupliquer d'abord.
func _material(colour: Color, translucent: bool = false,
		emission: float = 0.0) -> StandardMaterial3D:
	var key: String = "%s|%s|%.2f" % [colour.to_html(true), translucent, emission]
	if _materials.has(key):
		var cached: StandardMaterial3D = _materials[key]
		return cached
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.92
	if translucent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.roughness = 0.18
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = colour
		material.emission_energy_multiplier = emission
	_materials[key] = material
	return material


## Masse PLEINE : maillage + collision de même taille. C'est la roche.
func _solid(parent: Node3D, label: String, centre: Vector3, size: Vector3,
		colour: Color) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "%s%03d" % [label, _built]
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "Masse"
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = _material(colour)
	body.add_child(mesh)
	body.position = centre   # position AVANT add_child
	parent.add_child(body)
	_built += 1
	return body


## Volume DÉCORATIF, sans collision : rideau d'eau, filon, fresque. Rien ici ne
## doit bloquer le joueur — sinon la grotte se referme sur une illusion.
func _decor_box(parent: Node3D, label: String, centre: Vector3, size: Vector3,
		colour: Color, emission: float = 0.0,
		translucent: bool = false) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "%s%03d" % [label, _built]
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(colour, translucent, emission)
	mesh.position = centre
	parent.add_child(mesh)
	_built += 1
	return mesh


## Instancie une pièce du kit. Renvoie `null` si l'asset manque, sans lever :
## une grotte amputée d'un modèle doit rester chargeable et le dire.
func _piece(asset: String, at: Vector3, yaw_deg: float = 0.0,
		parent: Node3D = null) -> Node3D:
	var packed: PackedScene = null
	for pattern: String in KIT_DIRS:
		var full: String = pattern % asset
		if ResourceLoader.exists(full):
			packed = load(full) as PackedScene
			if packed != null:
				break
	if packed == null:
		push_warning("[grottes] pièce absente du kit : %s" % asset)
		return null
	var node: Node3D = packed.instantiate() as Node3D
	node.name = "%s_%03d" % [asset, _built]
	node.position = at
	node.rotation_degrees = Vector3(0, yaw_deg, 0)
	var holder: Node3D = self
	if parent != null:
		holder = parent
	holder.add_child(node)
	_built += 1
	return node


## Série de modèles décoratifs : `[nom, position, lacet, échelle facultative]`.
func _dress(parent: Node3D, placements: Array[Array]) -> void:
	for entry: Array in placements:
		var asset: String = entry[0]
		var at: Vector3 = entry[1]
		var yaw: float = entry[2]
		var factor: float = 1.0
		if entry.size() > 3:
			factor = entry[3]
		var node: Node3D = _piece(asset, at, yaw, parent)
		if node != null and not is_equal_approx(factor, 1.0):
			node.scale = Vector3.ONE * factor


## COQUE d'une salle réellement creuse : sol porteur, plafond, quatre parois —
## celles listées dans `doors` étant PERCÉES d'un seuil franchissable.
##
## `doors` contient des normales de face parmi `RIGHT`, `LEFT`, `BACK`
## (+Z) et `FORWARD` (−Z), exprimées dans le repère de `parent`.
func _shell(parent: Node3D, label: String, origin: Vector3, inner: Vector3,
		thickness: float, doors: Array[Vector3], gap: float,
		clearance: float, colour: Color) -> void:
	var half_x: float = inner.x * 0.5
	var half_z: float = inner.z * 0.5
	var outer_x: float = inner.x + thickness * 2.0
	var outer_z: float = inner.z + thickness * 2.0
	# Sol porteur : sans lui, « l'intérieur » est un trou et le joueur tombe.
	_solid(parent, label + "Sol", origin + Vector3(0, -thickness * 0.5, 0),
		Vector3(outer_x, thickness, outer_z), colour)
	# Plafond : on est SOUS quelque chose, pas dans un enclos à ciel ouvert.
	_solid(parent, label + "Plafond",
		origin + Vector3(0, inner.y + thickness * 0.5, 0),
		Vector3(outer_x, thickness, outer_z), colour)
	var faces: Array[Vector3] = [
		Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD,
	]
	for face: Vector3 in faces:
		# Une paroi nord/sud s'étend en X ; une paroi est/ouest s'étend en Z et
		# couvre les angles.
		var along_x: bool = absf(face.z) > 0.5
		var span: float = inner.z + thickness * 2.0
		if along_x:
			span = inner.x
		var centre: Vector3 = origin + Vector3(
			face.x * (half_x + thickness * 0.5), 0.0,
			face.z * (half_z + thickness * 0.5))
		if doors.has(face):
			_threshold(parent, label, centre, span, inner.y, thickness,
				along_x, gap, clearance, colour)
			continue
		var size: Vector3 = Vector3(thickness, inner.y, span)
		if along_x:
			size = Vector3(span, inner.y, thickness)
		_solid(parent, label + "Paroi", centre + Vector3(0, inner.y * 0.5, 0),
			size, colour)


## SEUIL : deux jambages et un linteau. Le trou du milieu est la grotte —
## c'est lui qui distingue un espace explorable d'un décor de façade.
func _threshold(parent: Node3D, label: String, centre: Vector3, span: float,
		height: float, thickness: float, along_x: bool, gap: float,
		clearance: float, colour: Color) -> void:
	var opening: float = maxf(gap, MIN_GAP)
	var head: float = maxf(clearance, MIN_CLEARANCE)
	var jamb: float = maxf((span - opening) * 0.5, 0.25)
	for side: float in [-1.0, 1.0]:
		var offset: float = side * (opening + jamb) * 0.5
		var at: Vector3 = centre + Vector3(0, height * 0.5, 0)
		var size: Vector3 = Vector3(thickness, height, jamb)
		if along_x:
			at.x += offset
			size = Vector3(jamb, height, thickness)
		else:
			at.z += offset
		_solid(parent, label + "Jambage", at, size, colour)
	# Linteau : on ne franchit pas la grotte par-dessus la porte.
	var lintel: float = maxf(height - head, 0.2)
	var lintel_at: Vector3 = centre + Vector3(0, height - lintel * 0.5, 0)
	var lintel_size: Vector3 = Vector3(thickness, lintel, opening)
	if along_x:
		lintel_size = Vector3(opening, lintel, thickness)
	_solid(parent, label + "Linteau", lintel_at, lintel_size, colour)


## TABLIER d'entrée : le sol devant le seuil, de plain-pied avec l'intérieur.
## Sans lui, la grotte s'ouvrirait sur le vide dès que le terrain bouge.
func _apron(parent: Node3D, centre: Vector3, size: Vector3,
		colour: Color) -> void:
	_solid(parent, "Tablier", centre, size, colour)


## Racine d'une grotte, orientée : le lacet fait ouvrir le seuil vers le monde,
## et toute la coque tourne avec lui.
func _cave_root(node_name: String, site: Vector3, yaw_deg: float) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = node_name
	root.position = site
	root.rotation_degrees = Vector3(0, yaw_deg, 0)
	add_child(root)
	return root


## Déclaration au monde : identifiant §19.3, nom affiché, région.
func _declare(root: Node3D, poi_id: StringName, display_name: String,
		region: StringName, volume: Vector3, at: Vector3) -> PointOfInterest:
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "PointDInteret"
	poi.poi_id = poi_id
	poi.display_name = display_name
	poi.region = region
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = volume
	shape.shape = box
	poi.add_child(shape)
	poi.position = at
	root.add_child(poi)
	return poi


## Enregistre la fiche : les points d'entrée et de station sont ramenés dans le
## repère de `ValleyCaves` par la transformée de la racine.
func _register(key: StringName, root: Node3D, poi: PointOfInterest,
		entrance_local: Vector3, interior_local: Vector3) -> void:
	var record: CaveRecord = CaveRecord.new()
	record.key = key
	record.root = root
	record.poi = poi
	record.entrance = root.transform * entrance_local
	record.interior = root.transform * interior_local
	record.door_normal = (root.basis * Vector3.BACK).normalized()
	record.floor_y = root.position.y
	_caves[key] = record


# --- 1. GROTTE DE LA CASCADE ------------------------------------------------

## Grotte NATURELLE, derrière un rideau d'eau : un surplomb de roche avance
## au-dessus du seuil, l'eau tombe de sa lèvre, et l'on passe dessous à sec.
## Le rideau est purement visuel — il ne bloque rien, sinon la grotte serait
## murée par sa propre mise en scène.
func _build_waterfall_cave() -> void:
	var root: Node3D = _cave_root("GrotteCascade", SITE_WATERFALL, 0.0)
	var inner: Vector3 = Vector3(9.0, 3.2, 7.0)
	var thickness: float = 1.2
	var face_z: float = inner.z * 0.5 + thickness      # 4,7 m
	var half_x: float = inner.x * 0.5 + thickness      # 5,7 m

	# Le seuil est déclaré par une liste TYPÉE : un littéral non typé se refuse
	# à un `Array[Vector3]`, et la grotte se murerait en silence.
	var doors: Array[Vector3] = [Vector3.BACK]
	_shell(root, "Cascade", Vector3.ZERO, inner, thickness,
		doors, 2.6, 2.4, COL_ROCK)
	# Tablier sous le surplomb, de plain-pied avec la salle.
	_apron(root, Vector3(0, -thickness * 0.5, face_z + 3.0),
		Vector3(inner.x + thickness * 2.0, thickness, 6.0), COL_ROCK)
	# Surplomb : la lèvre d'où l'eau tombe, à 4,4 m au-dessus du tablier.
	_solid(root, "Surplomb", Vector3(0, inner.y + thickness + 0.8, face_z + 2.0),
		Vector3(inner.x + thickness * 2.0, 1.6, 4.0), COL_ROCK)
	# Contreforts : le massif se lit comme un éperon rocheux, pas comme un cube.
	for side: float in [-1.0, 1.0]:
		_solid(root, "Contrefort", Vector3(side * (half_x + 0.9), 2.5, 0.0),
			Vector3(1.8, 5.0, inner.z + thickness * 2.0), COL_ROCK_DARK)

	# Rideau d'eau et vasque : décor pur, aucune collision.
	var fall: Node3D = Node3D.new()
	fall.name = "Cascade"
	root.add_child(fall)
	_decor_box(fall, "RideauEau", Vector3(0, 3.1, face_z + 3.9),
		Vector3(inner.x + 1.0, 6.2, 0.25), COL_WATER, 0.0, true)
	_decor_box(fall, "Vasque", Vector3(0, 0.12, face_z + 5.2),
		Vector3(inner.x + 2.0, 0.24, 2.6), COL_WATER, 0.0, true)

	# Habillage extérieur : blocs et galets autour de la bouche.
	_dress(root, [
		["Rock_Medium_1", Vector3(-7.4, 0.0, 5.6), 24.0, 1.4],
		["Rock_Medium_2", Vector3(7.2, 0.0, 6.4), -35.0, 1.3],
		["Rock_Medium_3", Vector3(-6.2, 0.0, 9.4), 70.0, 1.1],
		["Rock_Medium_1", Vector3(6.4, 0.0, 10.2), 130.0, 1.0],
		["Pebble_Round_1", Vector3(-2.6, 0.02, 9.6), 15.0, 1.6],
		["Pebble_Round_2", Vector3(2.2, 0.02, 10.1), 200.0, 1.4],
		["Pebble_Round_3", Vector3(0.8, 0.02, 8.6), 95.0, 1.2],
		["Pebble_Square_1", Vector3(-1.4, 0.02, 7.4), 45.0, 1.3],
		["RockPath_Round_Wide", Vector3(0.0, 0.03, 11.4), 0.0, 1.0],
		["RockPath_Round_Thin", Vector3(-2.0, 0.03, 12.6), 20.0, 1.0],
		["Fern_1", Vector3(-4.4, 0.0, 6.2), 30.0, 1.2],
		["Fern_1", Vector3(4.2, 0.0, 7.0), -20.0, 1.0],
		["Grass_Wispy_Tall", Vector3(3.2, 0.0, 9.8), 0.0, 1.0],
		["Bush_Common", Vector3(-5.6, 0.0, 11.0), 60.0, 1.0],
		["Prop_Vine2", Vector3(-1.9, 4.2, face_z + 0.1), 0.0, 1.0],
		["Prop_Vine1", Vector3(2.1, 4.2, face_z + 0.1), 0.0, 1.0],
	])
	# Intérieur : la RAISON d'entrer — un coffre à l'abri, des champignons
	# d'ombre humide (ingrédients de §13.1) et de quoi voir où l'on met les pieds.
	_dress(root, [
		["Chest_Wood", Vector3(-2.8, 0.05, -2.4), 18.0, 1.0],
		["Mushroom_Common", Vector3(2.6, 0.02, -2.2), 0.0, 1.3],
		["Mushroom_Common", Vector3(3.2, 0.02, -1.4), 120.0, 1.1],
		["Mushroom_Laetiporus", Vector3(3.6, 0.02, 0.6), 40.0, 1.0],
		["Fern_1", Vector3(-3.4, 0.02, 1.2), 200.0, 0.9],
		["Pebble_Round_4", Vector3(1.2, 0.02, 1.8), 130.0, 1.2],
		["Pebble_Round_5", Vector3(-1.6, 0.02, 2.4), 260.0, 1.0],
		["Bucket_Wooden_1", Vector3(-3.6, 0.05, -0.4), 25.0, 1.0],
		["Bag", Vector3(-2.0, 0.05, -3.0), 60.0, 1.0],
		["Torch_Metal", Vector3(3.9, 1.6, -3.0), 270.0, 1.0],
	])
	# Filet de lumière filtrant par le rideau : la salle n'est jamais un trou noir.
	var glow: OmniLight3D = OmniLight3D.new()
	glow.name = "LueurCascade"
	glow.light_color = Color(0.68, 0.86, 0.92)
	glow.light_energy = 1.1
	glow.omni_range = 12.0
	glow.position = Vector3(0, 2.2, 1.6)
	root.add_child(glow)

	var poi: PointOfInterest = _declare(root,
		&"valley.poi.waterfall_cave.01", "Grotte de la cascade", &"riviere",
		Vector3(24, 12, 26), Vector3(0, 3, 2))
	_register(CAVE_WATERFALL, root, poi,
		Vector3(0, 1.0, face_z + 1.7), Vector3(0, 1.2, -0.5))


# --- 2. MINE ABANDONNÉE -----------------------------------------------------

## Mine ÉTAYÉE : une galerie droite de 12 m, boisée d'étais, débouchant sur une
## chambre d'abattage. Deux coques dont les seuils sont alignés — la galerie est
## percée à ses deux bouts, la chambre du côté de la galerie —, ce qui donne un
## passage continu de l'extérieur jusqu'au filon.
func _build_abandoned_mine() -> void:
	# Lacet 270° : le seuil s'ouvre vers l'ouest, face à la route du pylône.
	var root: Node3D = _cave_root("MineAbandonnee", SITE_MINE, 270.0)
	var thickness: float = 1.2
	var gallery: Vector3 = Vector3(3.2, 3.2, 12.0)
	var chamber: Vector3 = Vector3(8.0, 3.4, 8.0)
	var mouth_z: float = gallery.z * 0.5 + thickness            # 7,2 m
	var chamber_z: float = -(mouth_z + thickness + chamber.z * 0.5)  # −12,4 m

	# Galerie : percée dehors (+Z) ET vers la chambre (−Z).
	var gallery_doors: Array[Vector3] = [Vector3.BACK, Vector3.FORWARD]
	_shell(root, "Galerie", Vector3.ZERO, gallery, thickness,
		gallery_doors, 2.4, 2.4, COL_ROCK)
	# Chambre d'abattage : percée du seul côté de la galerie. Les deux seuils
	# sont alignés — le passage est continu de l'extérieur jusqu'au filon.
	var chamber_doors: Array[Vector3] = [Vector3.BACK]
	_shell(root, "Chambre", Vector3(0, 0, chamber_z), chamber, thickness,
		chamber_doors, 2.4, 2.4, COL_ROCK)
	_apron(root, Vector3(0, -thickness * 0.5, mouth_z + 3.0),
		Vector3(6.0, thickness, 6.0), COL_ROCK)
	# Halde : les déblais forment le talus caractéristique d'une mine.
	for side: float in [-1.0, 1.0]:
		_solid(root, "Halde", Vector3(side * 4.4, 0.5, mouth_z + 2.4),
			Vector3(3.0, 1.0, 5.0), COL_EARTH)

	# Boisage : étais le long de la galerie. Ils tiennent dans les 3,2 m de
	# hauteur libre — un étai qui traverserait le plafond trahirait la coque.
	for index: int in range(4):
		var z: float = 4.4 - float(index) * 3.0
		for side: float in [-1.0, 1.0]:
			_piece("Prop_Support", Vector3(side * 1.45, 0.0, z), 0.0, root)
	# Sol de galerie : dalles usées sur la grille de 2 m du kit.
	for step: int in range(6):
		var z: float = -5.0 + float(step) * 2.0
		for side: float in [-1.0, 1.0]:
			_piece("Floor_UnevenBrick", Vector3(side * 0.9, 0.02, z), 0.0, root)

	# Carreau de mine : le seuil est MAÇONNÉ, on le repère de loin.
	_dress(root, [
		["Wall_UnevenBrick_Straight", Vector3(-2.2, 0.0, mouth_z + 0.4), 0.0],
		["Wall_UnevenBrick_Straight", Vector3(2.2, 0.0, mouth_z + 0.4), 0.0],
		["Prop_Support", Vector3(-1.5, 0.0, mouth_z - 0.2), 0.0],
		["Prop_Support", Vector3(1.5, 0.0, mouth_z - 0.2), 0.0],
		["Prop_Wagon", Vector3(2.6, 0.05, mouth_z + 3.2), 78.0],
		["Rock_Medium_2", Vector3(-5.2, 0.0, mouth_z + 5.4), 40.0, 1.3],
		["Rock_Medium_3", Vector3(5.6, 0.0, mouth_z + 5.0), -60.0, 1.2],
		["Pebble_Square_2", Vector3(-2.4, 0.02, mouth_z + 4.6), 15.0, 1.4],
		["Pebble_Round_1", Vector3(1.2, 0.02, mouth_z + 5.6), 190.0, 1.2],
		["DeadTree_1", Vector3(-6.6, 0.0, mouth_z + 8.0), 25.0, 1.0],
		["Crate_Wooden", Vector3(-2.6, 0.05, mouth_z + 2.0), 20.0],
		["Barrel", Vector3(-3.2, 0.05, mouth_z + 3.4), 0.0],
	])
	# Chambre d'abattage : outillage laissé sur place, et le FILON — la raison
	# de descendre jusqu'ici.
	_dress(root, [
		["Pickaxe_Bronze", Vector3(-1.8, 0.05, chamber_z + 2.0), 110.0],
		["Crate_Metal", Vector3(2.6, 0.05, chamber_z + 1.4), 35.0],
		["Crate_Wooden", Vector3(3.1, 0.05, chamber_z + 2.6), 12.0],
		["Bucket_Metal", Vector3(-2.9, 0.05, chamber_z - 0.6), 0.0],
		["Chain_Coil", Vector3(1.4, 0.05, chamber_z - 2.4), 60.0],
		["Rope_1", Vector3(-1.2, 0.05, chamber_z - 2.8), 200.0],
		["Chest_Wood", Vector3(0.2, 0.05, chamber_z - 3.0), 180.0],
		["Lantern_Wall", Vector3(0.0, 1.9, chamber_z - 3.7), 180.0],
		["Prop_Support", Vector3(-3.3, 0.0, chamber_z - 1.0), 0.0],
		["Prop_Support", Vector3(3.3, 0.0, chamber_z - 1.0), 0.0],
	])
	# Filons affleurants sur les parois de la chambre : décor pur, émissif.
	var vein: Node3D = Node3D.new()
	vein.name = "Filon"
	root.add_child(vein)
	var veins: Array[Array] = [
		[Vector3(-3.95, 1.7, chamber_z + 1.2), Vector3(0.12, 0.7, 1.8), COL_ORE],
		[Vector3(-3.95, 2.4, chamber_z - 1.6), Vector3(0.12, 0.4, 1.2), COL_ORE],
		[Vector3(3.95, 1.4, chamber_z - 0.4), Vector3(0.12, 0.9, 2.2), COL_COPPER],
		[Vector3(0.0, 3.3, chamber_z - 1.0), Vector3(2.4, 0.12, 0.6), COL_ORE],
	]
	for entry: Array in veins:
		var at: Vector3 = entry[0]
		var size: Vector3 = entry[1]
		var tint: Color = entry[2]
		_decor_box(vein, "Veine", at, size, tint, 1.8)
	var lamp: OmniLight3D = OmniLight3D.new()
	lamp.name = "LueurFilon"
	lamp.light_color = Color(0.42, 0.88, 0.95)
	lamp.light_energy = 1.3
	lamp.omni_range = 11.0
	lamp.position = Vector3(0, 2.0, chamber_z)
	root.add_child(lamp)
	var lantern: OmniLight3D = OmniLight3D.new()
	lantern.name = "LueurGalerie"
	lantern.light_color = Color(1.0, 0.72, 0.38)
	lantern.light_energy = 0.9
	lantern.omni_range = 9.0
	lantern.position = Vector3(0, 2.2, 2.0)
	root.add_child(lantern)

	var poi: PointOfInterest = _declare(root,
		&"valley.poi.abandoned_mine.01", "Mine abandonnée", &"hauteurs",
		Vector3(20, 12, 44), Vector3(0, 3, -3))
	_register(CAVE_MINE, root, poi,
		Vector3(0, 1.0, mouth_z + 2.0), Vector3(0, 1.2, chamber_z))


# --- 3. CRYPTE OUBLIÉE ------------------------------------------------------

## Petite CRYPTE : une salle maçonnée sous un tertre. La coque de pierre porte
## la collision ; les murs de brique du kit l'habillent de l'intérieur, sans
## jamais fermer le seuil.
func _build_forgotten_crypt() -> void:
	# Lacet 180° : le porche regarde le nord, vers les ruines centrales.
	var root: Node3D = _cave_root("CrypteOubliee", SITE_CRYPT, 180.0)
	var inner: Vector3 = Vector3(9.0, 3.3, 9.0)
	var thickness: float = 1.0
	var face_z: float = inner.z * 0.5 + thickness   # 5,5 m

	var doors: Array[Vector3] = [Vector3.BACK]
	_shell(root, "Crypte", Vector3.ZERO, inner, thickness,
		doors, 2.2, 2.4, COL_STONE)
	_apron(root, Vector3(0, -thickness * 0.5, face_z + 3.0),
		Vector3(inner.x + thickness * 2.0, thickness, 6.0), COL_STONE)
	# Tertre : la crypte est ENTERRÉE, la butte de terre la signale de loin.
	_solid(root, "Tertre", Vector3(0, inner.y + thickness + 0.6, 0),
		Vector3(13.0, 1.2, 13.0), COL_EARTH)

	# Porche : deux jouées de brique de part et d'autre du seuil. Elles laissent
	# les 2,2 m d'ouverture libres — la collision reste celle des jambages.
	_dress(root, [
		["Wall_UnevenBrick_Straight", Vector3(-2.1, 0.0, face_z + 0.4), 0.0],
		["Wall_UnevenBrick_Straight", Vector3(2.1, 0.0, face_z + 0.4), 0.0],
		["DoorFrame_Round_Brick", Vector3(0.0, 0.0, face_z + 0.15), 0.0],
		["Prop_Brick1", Vector3(-3.2, 0.05, face_z + 1.6), 30.0],
		["Prop_Brick1", Vector3(3.4, 0.05, face_z + 2.2), 200.0],
		["Prop_Vine1", Vector3(-1.7, 2.4, face_z + 0.05), 0.0],
		["Prop_Vine2", Vector3(1.7, 2.4, face_z + 0.05), 0.0],
		["Rock_Medium_1", Vector3(-6.4, 0.0, face_z + 3.4), 55.0, 1.2],
		["Rock_Medium_3", Vector3(6.2, 0.0, face_z + 3.0), -40.0, 1.1],
		["Pebble_Square_1", Vector3(-1.2, 0.02, face_z + 4.2), 25.0, 1.3],
		["RockPath_Square_Wide", Vector3(0.0, 0.03, face_z + 5.0), 0.0],
		["TwistedTree_1", Vector3(-7.6, 0.0, face_z + 6.4), 15.0, 1.0],
		["Bush_Common", Vector3(6.8, 0.0, face_z + 6.0), 80.0, 1.0],
		["Clover_1", Vector3(3.0, 0.0, face_z + 4.8), 0.0, 1.0],
	])
	# Dallage : la grille de 2 m du kit couvre les 9 m de la salle.
	for ix: int in range(-2, 2):
		for iz: int in range(-2, 2):
			_piece("Floor_Brick",
				Vector3(float(ix) * MODULE + 1.0, 0.02,
					float(iz) * MODULE + 1.0), 0.0, root)
	# Parement intérieur : brique sur les trois parois pleines. Les pièces font
	# 3,12 m de haut, la salle 3,3 m — rien ne traverse le plafond.
	for ix: int in range(-2, 2):
		var x: float = float(ix) * MODULE + 1.0
		_piece("Wall_UnevenBrick_Straight", Vector3(x, 0.0, -4.35), 180.0, root)
	for iz: int in range(-2, 2):
		var z: float = float(iz) * MODULE + 1.0
		_piece("Wall_UnevenBrick_Straight", Vector3(-4.35, 0.0, z), 90.0, root)
		_piece("Wall_UnevenBrick_Straight", Vector3(4.35, 0.0, z), 270.0, root)

	# Sarcophage central et niches : le mobilier funéraire donne l'échelle et
	# empêche la salle d'être une boîte vide.
	_solid(root, "Sarcophage", Vector3(0, 0.45, -1.2), Vector3(2.4, 0.9, 1.2),
		COL_STONE)
	_decor_box(root, "Couvercle", Vector3(0, 0.98, -1.2),
		Vector3(2.6, 0.16, 1.4), Color(0.52, 0.50, 0.53))
	# FRESQUE : l'indice. Motif du « courant fendu » en graybox — une ligne
	# verticale ouverte autour d'un vide, réunie plus bas.
	var fresco: Node3D = Node3D.new()
	fresco.name = "Fresque"
	root.add_child(fresco)
	_decor_box(fresco, "Panneau", Vector3(0, 1.9, -4.3), Vector3(2.8, 2.0, 0.1),
		Color(0.38, 0.35, 0.31))
	_decor_box(fresco, "Trait", Vector3(0, 2.7, -4.24), Vector3(0.12, 0.8, 0.06),
		COL_ORE, 1.4)
	_decor_box(fresco, "Trait", Vector3(0, 1.1, -4.24), Vector3(0.12, 0.8, 0.06),
		COL_ORE, 1.4)
	for side: float in [-1.0, 1.0]:
		_decor_box(fresco, "Branche", Vector3(side * 0.35, 1.9, -4.24),
			Vector3(0.1, 0.9, 0.06), COL_ORE, 1.4)

	_dress(root, [
		["CandleStick", Vector3(-1.6, 0.05, -1.2), 0.0],
		["CandleStick", Vector3(1.6, 0.05, -1.2), 0.0],
		["Candle_1", Vector3(0.0, 1.08, -1.2), 0.0],
		["Book_Stack_1", Vector3(-3.4, 0.05, -2.6), 40.0],
		["Bookcase_2", Vector3(-3.6, 0.05, 1.2), 90.0],
		["Shelf_Arch", Vector3(3.6, 0.05, 0.6), 270.0],
		["Scroll_1", Vector3(3.3, 0.05, -1.8), 120.0],
		["Pot_1", Vector3(3.2, 0.05, 2.6), 0.0],
		["Chest_Wood", Vector3(-3.2, 0.05, -3.4), 20.0],
		["Banner_1", Vector3(-4.2, 0.05, 3.2), 90.0],
		["Banner_1", Vector3(4.2, 0.05, 3.2), 270.0],
		["Torch_Metal", Vector3(-4.2, 1.7, -0.6), 90.0],
		["Torch_Metal", Vector3(4.2, 1.7, -0.6), 270.0],
		["Bottle_1", Vector3(-3.3, 0.05, 3.4), 60.0],
		["Bench", Vector3(2.4, 0.05, 3.2), 0.0],
	])
	var candle: OmniLight3D = OmniLight3D.new()
	candle.name = "LueurCrypte"
	candle.light_color = Color(1.0, 0.78, 0.45)
	candle.light_energy = 1.0
	candle.omni_range = 10.0
	candle.position = Vector3(0, 2.0, -0.4)
	root.add_child(candle)

	var poi: PointOfInterest = _declare(root,
		&"valley.poi.hollow_crypt.01", "Crypte oubliée", &"ruines",
		Vector3(26, 12, 28), Vector3(0, 3, 2))
	# Le point de station est pris DEVANT le sarcophage, dans le dégagement de
	# la salle : on doit tenir debout sur le dallage, pas sur le tombeau.
	_register(CAVE_CRYPT, root, poi,
		Vector3(0, 1.0, face_z + 1.7), Vector3(0, 1.2, 2.0))
