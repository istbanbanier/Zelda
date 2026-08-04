## SOUTERRAINS DE LA VALLÉE — deux espaces sous la roche, complémentaires des
## trois grottes de `ValleyCaves`.
##
## La règle centrale de l'ordre vaut ici mot pour mot : « les grottes doivent
## être de véritables espaces explorables, pas de simples trous décoratifs ».
## Une bouche noire plaquée sur un talus passerait n'importe quel comptage de
## nœuds. On construit donc, pour chacun des deux lieux :
##
##   1. une ENTRÉE franchissable — au moins 1,6 m de large et 2,2 m de haut,
##      la capsule du joueur (rayon 0,35, hauteur 1,7) passe réellement ;
##   2. un VOLUME intérieur — sol porteur, parois fermées, plafond au-dessus
##      de la tête, où l'on tient debout ;
##   3. une RAISON d'y aller — raccourci, coffre, minerai, ingrédient, indice.
##
## Les deux lieux :
##
##   - le **Passage dérobé de l'Éperon** : une entrée discrète au pied d'un
##     éperon rocheux, une galerie inclinée de 22 m qui MONTE de 9 m, et une
##     sortie au sommet. C'est un raccourci VRAI : l'éperon est un massif plein
##     de 23 m de large sur 44 m de long — le contourner puis le gravir coûte
##     bien davantage que les trente mètres du boyau. Les deux extrémités sont
##     franchissables dans les deux sens : on monte et on redescend ;
##   - la **Cavité de cristal** : une salle minérale de 13 × 13 m sous une
##     butte, hérissée de formations pâles et ambrées. Le cyan reste RARE et
##     réservé à l'énergie de Résonance (§3.4) : ces cristaux sont de l'ivoire
##     et de l'ambre, faiblement émissifs, jamais du néon.
##
## Le dépôt n'a pas de kit de caverne. Les volumes sont donc bâtis en boîtes
## (BoxMesh + StaticBody3D/BoxShape3D) puis HABILLÉS par les rochers du kit et,
## pour les parties étayées, par `Prop_Support` et les murs de brique. Les
## modèles du kit sont purement visuels : toute la collision vient des boîtes,
## ce qui permet de LAISSER un trou dans le seuil au lieu de murer le lieu de
## l'intérieur.
##
## Implantations choisies à l'écart de tout ce qui est déjà bâti — village
## (−70, 2, 36), bûcherons (110, 2, 40), poste minier (−68, 2, 86), camp
## (45, 6, 65), pylône (115, 18, −25), donjon (0, 34, −210), crête (0, 24, 170),
## ruine de guet (−128, 14, 82), arbre ancien (−96, 2, −62), caravane
## (−38, 2, −120) — et des trois grottes de `ValleyCaves` : cascade
## (−118, 2, 26), mine (160, 2, −70), crypte (−60, 2, −90). L'éperon reste au
## nord de l'emprise de la falaise d'apprentissage (x −140…−80, z 40…90) : la
## roche du terrain et la nôtre ne se recouvrent jamais.
class_name ValleyUndergrounds
extends Node3D

## Le kit est réparti sur cinq dossiers (rochers, donjon, village, props,
## feuillage). Une pièce se résout par recherche, pas par chemin figé :
## déplacer un asset ne doit pas casser un souterrain en silence.
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

## Gabarit du joueur, repris de la capsule du contrôleur. Aucune ouverture de
## ce fichier ne descend en dessous — c'est la définition de « franchissable ».
const PLAYER_RADIUS: float = 0.35
const PLAYER_HEIGHT: float = 1.7
## Marges de sécurité de l'ordre : 1,6 m de large, 2,2 m de haut au minimum.
const MIN_GAP: float = 1.6
const MIN_CLEARANCE: float = 2.2

## Clés internes des deux lieux.
const UNDER_PASSAGE: StringName = &"passage"
const UNDER_CRYSTAL: StringName = &"cristal"

## ANCRAGES de récompense (contrat `RewardAnchor`). Positions éprouvées par
## `tools/godot/probe_reward_anchors.gd` dans la vallée montée, puis figées.
const ANCHORS: Dictionary = {
	&"valley.poi.hidden_passage.01": {
		"at": Vector3(0.0, 0.0, 2.0), "approach": Vector3(-2.12, 0.0, -0.12),
		"kind": RewardAnchor.Kind.CHEST,
	},
	&"valley.poi.crystal_hollow.01": {
		"at": Vector3(0.0, 0.0, -2.0), "approach": Vector3(0.52, 0.0, 0.95),
		"kind": RewardAnchor.Kind.PUZZLE,
	},
}

## Dénivelé et allonge de la galerie inclinée. 9 m gagnés sur 22 m de course :
## une pente de 22,2°, franchement sous les 45° que `CharacterBody3D` accepte
## comme sol. Une pente plus raide raccourcirait le boyau mais rendrait la
## montée hasardeuse — ce serait un raccourci qui ne marche qu'en théorie.
const RISE: float = 9.0
const RUN: float = 22.0

## Éperon : plaine sud (y = 2, z de 16 à 256), au NORD de la falaise
## d'apprentissage dont l'emprise s'arrête à z = 90. Le massif s'étend d'ici
## vers le sud (lacet 180°), donc de z = 115 à z = 165 : aucun recouvrement.
const SITE_PASSAGE: Vector3 = Vector3(-134.0, 2.0, 122.0)
## Cavité : plaine nord (y = 2, z de −256 à −4), à l'ouest de tout ce qui est
## bâti — la crypte de `ValleyCaves` est à 100 m, l'arbre ancien à 98 m.
const SITE_CRYSTAL: Vector3 = Vector3(-140.0, 2.0, -150.0)

## Teintes graybox, dans la bande ocre/pierre de §3.4. Les cristaux sont
## IVOIRE (`#D8C8A1`) et ambrés : le cyan appartient à la Résonance seule.
const COL_ROCK: Color = Color(0.42, 0.33, 0.26)
const COL_ROCK_DARK: Color = Color(0.27, 0.22, 0.19)
const COL_STONE: Color = Color(0.45, 0.44, 0.47)
const COL_EARTH: Color = Color(0.34, 0.30, 0.21)
const COL_CRYSTAL_PALE: Color = Color(0.85, 0.80, 0.66)
const COL_CRYSTAL_IVORY: Color = Color(0.92, 0.88, 0.76)
const COL_CRYSTAL_AMBER: Color = Color(0.84, 0.63, 0.30)
const COL_MARK: Color = Color(0.78, 0.62, 0.36)


## Fiche d'un souterrain : ce que les autres systèmes — et les tests — ont
## besoin de savoir sans fouiller l'arbre de scène.
class UndergroundRecord extends RefCounted:
	var key: StringName = &""
	var root: Node3D = null
	var poi: PointOfInterest = null
	## Point d'approche, DEHORS, devant la bouche principale.
	var entrance: Vector3 = Vector3.ZERO
	## Normale sortante de la bouche principale : on entre vers `-entrance_normal`.
	var entrance_normal: Vector3 = Vector3.BACK
	## Point d'approche, DEHORS, devant la SECONDE bouche. Pour un lieu à une
	## seule bouche, c'est le même point que `entrance` — dire le contraire
	## laisserait croire à une sortie qui n'existe pas.
	var exit: Vector3 = Vector3.ZERO
	var exit_normal: Vector3 = Vector3.FORWARD
	## Point de station, DEDANS, au-dessus du sol porteur.
	var interior: Vector3 = Vector3.ZERO
	## Point de station de la SECONDE salle.
	var second_room: Vector3 = Vector3.ZERO
	## Cotes des deux sols, dans le repère de `ValleyUndergrounds`.
	var floor_y: float = 0.0
	var exit_floor_y: float = 0.0
	## Vrai seulement si le lieu TRAVERSE : deux bouches distinctes reliées.
	var through: bool = false


var _sites: Dictionary = {}
var _materials: Dictionary = {}
var _built: int = 0


func _ready() -> void:
	_build_hidden_passage()
	_build_crystal_hollow()


# --- Contrat public ---------------------------------------------------------

## Nombre de volumes et de modèles réellement posés.
func piece_count() -> int:
	return _built


## Clés des souterrains, dans l'ordre de construction.
func site_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for key: StringName in _sites:
		keys.append(key)
	return keys


func has_site(key: StringName) -> bool:
	return _sites.has(key)


func site_root(key: StringName) -> Node3D:
	var record: UndergroundRecord = _record(key)
	if record == null:
		return null
	return record.root


func site_poi(key: StringName) -> PointOfInterest:
	var record: UndergroundRecord = _record(key)
	if record == null:
		return null
	return record.poi


## Point d'ENTRÉE, en repère global : devant la bouche principale, dehors.
func entrance_point(key: StringName) -> Vector3:
	var record: UndergroundRecord = _record(key)
	if record == null:
		return Vector3.ZERO
	return to_global(record.entrance)


## Direction sortante de la bouche principale. On entre vers l'opposé.
func door_normal(key: StringName) -> Vector3:
	var record: UndergroundRecord = _record(key)
	if record == null:
		return Vector3.BACK
	return (global_transform.basis * record.entrance_normal).normalized()


## Point de SORTIE, en repère global : devant la seconde bouche, dehors.
func exit_point(key: StringName) -> Vector3:
	var record: UndergroundRecord = _record(key)
	if record == null:
		return Vector3.ZERO
	return to_global(record.exit)


## Direction sortante de la seconde bouche. On y entre vers l'opposé.
func exit_normal(key: StringName) -> Vector3:
	var record: UndergroundRecord = _record(key)
	if record == null:
		return Vector3.FORWARD
	return (global_transform.basis * record.exit_normal).normalized()


## Point INTÉRIEUR de la salle principale : là où l'on doit tenir debout.
func interior_point(key: StringName) -> Vector3:
	var record: UndergroundRecord = _record(key)
	if record == null:
		return Vector3.ZERO
	return to_global(record.interior)


## Point INTÉRIEUR de la seconde salle — chambre haute du passage, galerie
## d'entrée de la cavité.
func second_room_point(key: StringName) -> Vector3:
	var record: UndergroundRecord = _record(key)
	if record == null:
		return Vector3.ZERO
	return to_global(record.second_room)


## Cote du sol de la salle principale, en repère global.
func floor_level(key: StringName) -> float:
	var record: UndergroundRecord = _record(key)
	if record == null:
		return 0.0
	return to_global(Vector3(0.0, record.floor_y, 0.0)).y


## Cote du sol devant la seconde bouche, en repère global.
func exit_floor_level(key: StringName) -> float:
	var record: UndergroundRecord = _record(key)
	if record == null:
		return 0.0
	return to_global(Vector3(0.0, record.exit_floor_y, 0.0)).y


## Vrai si le lieu TRAVERSE réellement : deux bouches distinctes reliées par
## un boyau continu. Un raccourci qui ne débouche pas n'est pas un raccourci.
func is_through_passage(key: StringName) -> bool:
	var record: UndergroundRecord = _record(key)
	if record == null:
		return false
	return record.through


## Dénivelé gagné entre les deux bouches, en mètres.
func elevation_gain(key: StringName) -> float:
	var record: UndergroundRecord = _record(key)
	if record == null:
		return 0.0
	return absf(record.exit_floor_y - record.floor_y)


## Déclare les deux lieux au journal des découvertes. L'injection reste
## explicite : un souterrain ne sait pas s'il a déjà été vu, il le DEMANDE.
func bind_all(discovery_log: DiscoveryLog) -> void:
	for key: StringName in _sites:
		var record: UndergroundRecord = _record(key)
		if record != null and record.poi != null:
			record.poi.bind(discovery_log)


func _record(key: StringName) -> UndergroundRecord:
	if not _sites.has(key):
		return null
	var record: UndergroundRecord = _sites[key]
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
		material.roughness = 0.24
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


## Volume DÉCORATIF, sans collision : veine, marque gravée, éclat de cristal
## fin. Rien ici ne doit bloquer le joueur — sinon le lieu se referme sur sa
## propre mise en scène.
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


## ÉCLAT de cristal : une boîte fine et PENCHÉE. Une formation minérale ne
## pousse jamais parfaitement verticale ; l'inclinaison est ce qui distingue
## une cavité cristalline d'un alignement de barreaux.
func _shard(parent: Node3D, label: String, centre: Vector3, size: Vector3,
		tilt_deg: float, yaw_deg: float, colour: Color,
		emission: float) -> MeshInstance3D:
	var mesh: MeshInstance3D = _decor_box(parent, label, centre, size, colour,
		emission)
	mesh.rotation_degrees = Vector3(tilt_deg, yaw_deg, 0.0)
	return mesh


## Instancie une pièce du kit. Renvoie `null` si l'asset manque, sans lever :
## un souterrain amputé d'un modèle doit rester chargeable et le dire.
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
		push_warning("[souterrains] pièce absente du kit : %s" % asset)
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
		# §3 : correction d'échelle du kit végétal, point unique (`KitScale`).
		var corrected: float = factor * KitScale.factor(asset)
		if node != null and not is_equal_approx(corrected, 1.0):
			node.scale = Vector3.ONE * corrected


## COQUE d'une salle réellement creuse : sol porteur, plafond, quatre parois —
## celles listées dans `doors` étant PERCÉES d'un seuil franchissable.
##
## `doors` contient des normales de face parmi `RIGHT`, `LEFT`, `BACK` (+Z) et
## `FORWARD` (−Z), exprimées dans le repère de `parent`.
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


## SEUIL : deux jambages et un linteau. Le trou du milieu est le souterrain —
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
	# Linteau : on ne franchit pas le seuil par-dessus la porte.
	var lintel: float = maxf(height - head, 0.2)
	var lintel_at: Vector3 = centre + Vector3(0, height - lintel * 0.5, 0)
	var lintel_size: Vector3 = Vector3(thickness, lintel, opening)
	if along_x:
		lintel_size = Vector3(opening, lintel, thickness)
	_solid(parent, label + "Linteau", lintel_at, lintel_size, colour)


## TABLIER d'entrée : le sol devant le seuil, de plain-pied avec l'intérieur.
## Sans lui, le boyau s'ouvrirait sur le vide dès que le terrain bouge.
func _apron(parent: Node3D, centre: Vector3, size: Vector3,
		colour: Color) -> void:
	_solid(parent, "Tablier", centre, size, colour)


## GALERIE INCLINÉE : sol, plafond et deux parois, sans aucun bouchon d'about.
## Les deux extrémités sont donc ouvertes PAR CONSTRUCTION, et viennent
## s'aboucher aux seuils des salles qu'elles relient. Toute la géométrie est
## bâtie dans un pivot penché : la coque suit la pente au lieu de l'escalader
## par des marches, qu'un `CharacterBody3D` ne gravit pas tout seul.
##
## Renvoie le pivot, pour que l'habillage suive lui aussi l'inclinaison.
func _incline_tunnel(parent: Node3D, node_name: String, start: Vector3,
		rise: float, run: float, width: float, height: float,
		thickness: float, colour: Color) -> Node3D:
	var pivot: Node3D = Node3D.new()
	pivot.name = node_name
	pivot.position = start
	# Rotation +X : la direction locale −Z part vers le haut. Vérifié à la
	# main sur la matrice — une erreur de signe enterrerait la galerie.
	pivot.rotation_degrees = Vector3(rad_to_deg(atan2(rise, run)), 0.0, 0.0)
	parent.add_child(pivot)
	var length: float = sqrt(rise * rise + run * run)
	var half: float = length * 0.5
	var outer_w: float = width + thickness * 2.0
	_solid(pivot, node_name + "Sol", Vector3(0, -thickness * 0.5, -half),
		Vector3(outer_w, thickness, length), colour)
	_solid(pivot, node_name + "Plafond",
		Vector3(0, height + thickness * 0.5, -half),
		Vector3(outer_w, thickness, length), colour)
	for side: float in [-1.0, 1.0]:
		_solid(pivot, node_name + "Paroi",
			Vector3(side * (width + thickness) * 0.5, height * 0.5, -half),
			Vector3(thickness, height, length), colour)
	return pivot


## Racine d'un souterrain, orientée : le lacet fait ouvrir la bouche vers le
## monde, et toute la coque tourne avec lui.
func _site_root(node_name: String, site: Vector3, yaw_deg: float) -> Node3D:
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
	RewardAnchor.attach_from_table(root, poi_id, ANCHORS, "souterrains")
	return poi


## Enregistre la fiche : points et normales sont ramenés dans le repère de
## `ValleyUndergrounds` par la transformée de la racine.
func _register(key: StringName, root: Node3D, poi: PointOfInterest,
		entrance_local: Vector3, exit_local: Vector3, interior_local: Vector3,
		second_local: Vector3, exit_floor_local: float,
		through: bool) -> void:
	var record: UndergroundRecord = UndergroundRecord.new()
	record.key = key
	record.root = root
	record.poi = poi
	record.entrance = root.transform * entrance_local
	record.exit = root.transform * exit_local
	record.interior = root.transform * interior_local
	record.second_room = root.transform * second_local
	record.entrance_normal = (root.basis * Vector3.BACK).normalized()
	# Un lieu à bouche unique n'a pas de « seconde normale » : lui en inventer
	# une opposée ferait croire à un second débouché. Sa sortie est son entrée.
	if through:
		record.exit_normal = (root.basis * Vector3.FORWARD).normalized()
	else:
		record.exit_normal = record.entrance_normal
	record.floor_y = root.position.y
	record.exit_floor_y = root.position.y + exit_floor_local
	record.through = through
	_sites[key] = record


# --- 1. PASSAGE DÉROBÉ DE L'ÉPERON ------------------------------------------

## RACCOURCI vertical. Trois volumes en enfilade :
##
##   vestibule (y = 0) → galerie inclinée (+9 m sur 22 m) → chambre haute.
##
## La bouche basse s'ouvre au pied de l'éperon, à demi masquée par des blocs
## et un rideau de lierre — « dérobée » veut dire discrète, jamais murée : la
## collision reste celle des jambages, et les modèles du kit ne bloquent rien.
##
## La bouche haute débouche sur la terrasse du sommet, 9 m plus haut. Le gain
## est réel : l'éperon est un massif PLEIN de 23 m de large sur 44 m de long
## dont les flancs montent d'un seul tenant. Sans le boyau, il faut faire le
## tour et trouver une montée ; avec lui, trente mètres suffisent.
func _build_hidden_passage() -> void:
	# Lacet 180° : la bouche basse regarde le NORD (vers la falaise
	# d'apprentissage), et le massif se développe vers le sud — hors de
	# l'emprise du terrain, qui s'arrête à z = 90.
	var root: Node3D = _site_root("PassageDerobe", SITE_PASSAGE, 180.0)
	var thickness: float = 1.2
	var vestibule: Vector3 = Vector3(6.0, 3.0, 6.0)
	var chamber: Vector3 = Vector3(7.0, 3.2, 7.0)
	var tunnel_w: float = 3.0
	var tunnel_h: float = 3.2
	var tunnel_t: float = 1.0
	# Face extérieure du vestibule côté galerie : la galerie démarre là, de
	# sorte que le seuil reste de PLAIN-PIED. La faire commencer plus tôt
	# ferait monter le sol sous le linteau et mangerait le dégagement.
	var mouth_z: float = vestibule.z * 0.5 + thickness            # 4,2 m
	var tunnel_start: Vector3 = Vector3(0, 0, -mouth_z)
	var tunnel_end_z: float = -mouth_z - RUN                      # −26,2 m
	# La chambre haute est placée pour que sa face AVANT (+Z) touche l'about
	# de la galerie : origine = about − demi-emprise − épaisseur.
	var chamber_z: float = tunnel_end_z - chamber.z * 0.5 - thickness  # −30,9 m
	var chamber_back_z: float = chamber_z - chamber.z * 0.5 - thickness

	# Vestibule : percé dehors (+Z) ET vers la galerie (−Z). Liste TYPÉE — un
	# littéral non typé se refuse à un `Array[Vector3]`, et le passage se
	# murerait en silence.
	var vestibule_doors: Array[Vector3] = [Vector3.BACK, Vector3.FORWARD]
	_shell(root, "Vestibule", Vector3.ZERO, vestibule, thickness,
		vestibule_doors, 2.4, 2.4, COL_ROCK)
	# Galerie : ouverte aux deux bouts par construction.
	var gallery: Node3D = _incline_tunnel(root, "GalerieInclinee", tunnel_start,
		RISE, RUN, tunnel_w, tunnel_h, tunnel_t, COL_ROCK)
	# Chambre haute : percée vers la galerie (+Z) et vers la terrasse (−Z).
	var chamber_doors: Array[Vector3] = [Vector3.BACK, Vector3.FORWARD]
	_shell(root, "ChambreHaute", Vector3(0, RISE, chamber_z), chamber,
		thickness, chamber_doors, 2.4, 2.4, COL_ROCK)

	# Tablier bas devant la bouche discrète.
	_apron(root, Vector3(0, -thickness * 0.5, mouth_z + 3.2),
		Vector3(9.4, thickness, 6.4), COL_ROCK)
	# Terrasse du sommet : un massif plein dont le DESSUS est de plain-pied
	# avec la chambre haute. C'est le débouché : on sort à 9 m au-dessus de la
	# plaine, pas sur une corniche flottante.
	_solid(root, "TerrasseSommet",
		Vector3(0, RISE * 0.5, chamber_back_z - 3.5),
		Vector3(11.0, RISE, 7.0), COL_ROCK)

	# Flancs de l'éperon : deux masses pleines qui font du lieu un OBSTACLE.
	# Elles démarrent à x = ±4,5, juste au-delà de l'emprise intérieure des
	# salles — elles épaississent la roche, elles n'entrent jamais dedans.
	for side: float in [-1.0, 1.0]:
		_solid(root, "Flanc", Vector3(side * 8.0, RISE * 0.5, -15.0),
			Vector3(7.0, RISE, 44.0), COL_ROCK_DARK)
	# Crête : la masse au-dessus de la galerie suit sa montée, par paliers.
	# Sans elle, le boyau serait un tube posé sur l'herbe.
	var slope: float = RISE / RUN
	var lift: float = (tunnel_h + tunnel_t) / cos(atan2(RISE, RUN))
	var steps: int = 4
	var seg: float = RUN / float(steps)
	for index: int in range(steps):
		var near: float = seg * float(index)
		var far: float = seg * float(index + 1)
		var bottom: float = near * slope + lift
		var top: float = far * slope + lift + 0.8
		_solid(root, "Crete",
			Vector3(0, (bottom + top) * 0.5, -mouth_z - (near + far) * 0.5),
			Vector3(9.0, top - bottom, seg), COL_ROCK)
	# Sommet du vestibule : la roche au-dessus de la bouche basse.
	_solid(root, "Coiffe", Vector3(0, 6.2, 0), Vector3(9.0, 4.0, 8.4),
		COL_ROCK)

	# Habillage extérieur BAS : la bouche est à demi dissimulée par des blocs
	# et de la végétation. Les modèles n'ont pas de collision — le seuil reste
	# libre, seule la lecture change.
	_dress(root, [
		["Rock_Medium_1", Vector3(-3.6, 0.0, 5.2), 28.0, 1.5],
		["Rock_Medium_2", Vector3(3.4, 0.0, 5.6), -42.0, 1.4],
		["Rock_Medium_3", Vector3(-2.4, 0.0, 8.2), 105.0, 1.2],
		["Rock_Medium_1", Vector3(2.8, 0.0, 9.0), 160.0, 1.1],
		["Pebble_Round_1", Vector3(-1.2, 0.02, 7.4), 20.0, 1.4],
		["Pebble_Round_3", Vector3(1.6, 0.02, 8.4), 210.0, 1.2],
		["Pebble_Square_2", Vector3(0.4, 0.02, 6.2), 60.0, 1.3],
		["RockPath_Round_Thin", Vector3(0.0, 0.03, 10.2), 0.0, 1.0],
		["Bush_Common", Vector3(-4.8, 0.0, 7.0), 40.0, 1.2],
		["Bush_Common_Flowers", Vector3(4.6, 0.0, 8.2), 130.0, 1.0],
		["Fern_1", Vector3(-2.0, 0.0, 4.6), 200.0, 1.1],
		["Fern_1", Vector3(2.2, 0.0, 4.4), 20.0, 1.0],
		["Grass_Wispy_Tall", Vector3(-1.0, 0.0, 9.6), 0.0, 1.0],
		["TwistedTree_1", Vector3(-6.2, 0.0, 10.6), 25.0, 1.0],
		["Prop_Vine1", Vector3(-1.6, 2.4, mouth_z + 0.05), 0.0, 1.0],
		["Prop_Vine2", Vector3(1.6, 2.4, mouth_z + 0.05), 0.0, 1.0],
	])
	# Vestibule : la halte du bas. Un coffre, une corde, une lanterne — et la
	# MARQUE gravée qui signale que le boyau mène quelque part.
	_dress(root, [
		["Chest_Wood", Vector3(-2.0, 0.05, 1.8), 22.0, 1.0],
		["Crate_Wooden", Vector3(2.1, 0.05, 1.4), 15.0, 1.0],
		["Rope_1", Vector3(1.4, 0.05, -1.6), 80.0, 1.0],
		["Bucket_Wooden_1", Vector3(-2.3, 0.05, -1.2), 0.0, 1.0],
		["Lantern_Wall", Vector3(-2.9, 1.9, -0.4), 90.0, 1.0],
		["Mushroom_Common", Vector3(2.6, 0.02, -2.2), 0.0, 1.2],
		["Mushroom_Common", Vector3(2.2, 0.02, -2.7), 140.0, 1.0],
		["Pebble_Round_4", Vector3(-1.0, 0.02, -2.4), 60.0, 1.1],
	])
	# MARQUE de chemin : trois chevrons montants gravés près du seuil de la
	# galerie. L'indice se lit sans texte — il désigne la direction du haut.
	var mark: Node3D = Node3D.new()
	mark.name = "MarqueDeChemin"
	root.add_child(mark)
	for index: int in range(3):
		var y: float = 1.3 + float(index) * 0.4
		for side: float in [-1.0, 1.0]:
			_decor_box(mark, "Chevron",
				Vector3(side * 0.22, y, -2.94), Vector3(0.06, 0.44, 0.05),
				COL_MARK, 0.9)

	# Boisage de la galerie : les étais suivent la pente, dans le repère du
	# pivot. Ils tiennent dans les 3,2 m de hauteur libre.
	for index: int in range(6):
		var along: float = -2.4 - float(index) * 3.6
		for side: float in [-1.0, 1.0]:
			_piece("Prop_Support", Vector3(side * 1.42, 0.0, along), 0.0,
				gallery)
	# Dallage usé le long de la montée : on voit que le boyau a servi.
	for step: int in range(5):
		_piece("Floor_UnevenBrick", Vector3(0.0, 0.02,
			-3.6 - float(step) * 4.4), 0.0, gallery)

	# Chambre haute : la sortie. Coffre garanti, outillage, et une ouverture
	# maçonnée qui se repère depuis la terrasse.
	_dress(root, [
		["Chest_Wood", Vector3(1.9, RISE + 0.05, chamber_z - 2.2), 200.0, 1.0],
		["Crate_Metal", Vector3(-2.3, RISE + 0.05, chamber_z - 1.6), 40.0, 1.0],
		["Barrel", Vector3(-2.6, RISE + 0.05, chamber_z + 1.0), 0.0, 1.0],
		["Torch_Metal", Vector3(2.9, RISE + 1.7, chamber_z + 0.4), 270.0, 1.0],
		["Rope_1", Vector3(0.6, RISE + 0.05, chamber_z + 2.0), 120.0, 1.0],
		["Prop_Support", Vector3(-2.4, RISE, chamber_z - 2.8), 0.0, 1.0],
		["Prop_Support", Vector3(2.4, RISE, chamber_z - 2.8), 0.0, 1.0],
		["Wall_UnevenBrick_Straight",
			Vector3(-2.2, RISE, chamber_back_z - 0.4), 180.0, 1.0],
		["Wall_UnevenBrick_Straight",
			Vector3(2.2, RISE, chamber_back_z - 0.4), 180.0, 1.0],
		["Pebble_Square_1", Vector3(-1.4, RISE + 0.02, chamber_back_z - 2.6),
			35.0, 1.3],
		["Rock_Medium_2", Vector3(-4.6, RISE, chamber_back_z - 3.4), 60.0, 1.2],
		["Rock_Medium_3", Vector3(4.4, RISE, chamber_back_z - 3.0), -50.0, 1.1],
		["Grass_Common_Tall", Vector3(2.0, RISE, chamber_back_z - 4.6), 0.0, 1.0],
		["Pine_2", Vector3(-4.8, RISE, chamber_back_z - 5.8), 0.0, 1.0],
	])

	# Lueurs : ni l'un ni l'autre bout n'est un trou noir, et la galerie garde
	# un point de repère à mi-pente.
	var low_glow: OmniLight3D = OmniLight3D.new()
	low_glow.name = "LueurVestibule"
	low_glow.light_color = Color(1.0, 0.78, 0.46)
	low_glow.light_energy = 1.0
	low_glow.omni_range = 10.0
	low_glow.position = Vector3(0, 2.1, 0.6)
	root.add_child(low_glow)
	var mid_glow: OmniLight3D = OmniLight3D.new()
	mid_glow.name = "LueurGalerie"
	mid_glow.light_color = Color(0.96, 0.82, 0.58)
	mid_glow.light_energy = 0.8
	mid_glow.omni_range = 12.0
	mid_glow.position = Vector3(0, RISE * 0.5 + 1.8, -mouth_z - RUN * 0.5)
	root.add_child(mid_glow)
	var high_glow: OmniLight3D = OmniLight3D.new()
	high_glow.name = "LueurChambreHaute"
	high_glow.light_color = Color(0.86, 0.90, 0.96)
	high_glow.light_energy = 1.1
	high_glow.omni_range = 11.0
	high_glow.position = Vector3(0, RISE + 2.2, chamber_z - 1.0)
	root.add_child(high_glow)

	var poi: PointOfInterest = _declare(root,
		&"valley.poi.hidden_passage.01", "Passage dérobé de l'Éperon",
		&"hauteurs", Vector3(20, 12, 24), Vector3(0, 3, 2))
	_register(UNDER_PASSAGE, root, poi,
		Vector3(0, 1.0, mouth_z + 2.2),                 # devant la bouche basse
		Vector3(0, RISE + 1.0, chamber_back_z - 2.4),   # sur la terrasse haute
		Vector3(0, 1.2, 0.0),                           # station : vestibule
		Vector3(0, RISE + 1.2, chamber_z),              # station : chambre haute
		RISE, true)


# --- 2. CAVITÉ DE CRISTAL ---------------------------------------------------

## Cavité MINÉRALE sous une butte : une courte galerie d'entrée mène à une
## salle de 13 × 13 m hérissée de formations. Les cristaux sont PÂLES — ivoire
## et ambre, faiblement émissifs. §3.4 réserve le cyan à l'énergie de
## Résonance : un néon cyan ferait passer un gisement minéral pour un
## mécanisme, et brûlerait l'accent le plus rare de la palette.
##
## Les plus gros amas portent une collision : on les CONTOURNE. Une salle dont
## tout le décor se traverse n'est pas un espace, c'est une image.
func _build_crystal_hollow() -> void:
	# Lacet 35° : la bouche s'ouvre au sud-est, du côté par lequel on arrive.
	var root: Node3D = _site_root("CaviteCristalline", SITE_CRYSTAL, 35.0)
	var thickness: float = 1.2
	var entry: Vector3 = Vector3(3.4, 3.0, 6.0)
	var hall: Vector3 = Vector3(13.0, 4.4, 13.0)
	var mouth_z: float = entry.z * 0.5 + thickness              # 4,2 m
	# La salle est placée pour que sa face AVANT touche celle de la galerie.
	var hall_z: float = -mouth_z - hall.z * 0.5 - thickness     # −11,9 m
	var hall_back_z: float = hall_z - hall.z * 0.5 - thickness

	var entry_doors: Array[Vector3] = [Vector3.BACK, Vector3.FORWARD]
	_shell(root, "GalerieEntree", Vector3.ZERO, entry, thickness,
		entry_doors, 2.4, 2.4, COL_ROCK)
	var hall_doors: Array[Vector3] = [Vector3.BACK]
	_shell(root, "SalleCristal", Vector3(0, 0, hall_z), hall, thickness,
		hall_doors, 2.6, 2.6, COL_STONE)
	_apron(root, Vector3(0, -thickness * 0.5, mouth_z + 3.0),
		Vector3(5.8, thickness, 6.0), COL_ROCK)

	# Butte : la cavité est ENTERRÉE. Le chapeau de terre repose sur le plafond
	# de la salle, les talus habillent les flancs et le fond.
	_solid(root, "Butte", Vector3(0, hall.y + thickness + 1.0, hall_z),
		Vector3(17.0, 2.0, 17.0), COL_EARTH)
	for side: float in [-1.0, 1.0]:
		_solid(root, "Talus", Vector3(side * 9.0, 2.8, hall_z),
			Vector3(3.0, 5.6, 19.0), COL_EARTH)
	_solid(root, "TalusFond", Vector3(0, 2.8, hall_back_z - 1.5),
		Vector3(19.0, 5.6, 3.0), COL_EARTH)
	# Épaulements de roche encadrant la bouche : la butte se lit comme un
	# affleurement, pas comme un tas de terre percé d'un tuyau.
	for side: float in [-1.0, 1.0]:
		_solid(root, "Epaulement", Vector3(side * 3.6, 1.6, mouth_z),
			Vector3(3.0, 3.2, 2.6), COL_ROCK)

	# Habillage extérieur.
	_dress(root, [
		["Rock_Medium_2", Vector3(-4.2, 0.0, mouth_z + 2.6), 35.0, 1.4],
		["Rock_Medium_3", Vector3(4.0, 0.0, mouth_z + 3.0), -55.0, 1.3],
		["Rock_Medium_1", Vector3(-2.6, 0.0, mouth_z + 5.4), 120.0, 1.1],
		["Pebble_Round_2", Vector3(1.4, 0.02, mouth_z + 4.2), 180.0, 1.3],
		["Pebble_Square_1", Vector3(-1.0, 0.02, mouth_z + 5.0), 40.0, 1.2],
		["RockPath_Square_Wide", Vector3(0.0, 0.03, mouth_z + 6.2), 0.0, 1.0],
		["DeadTree_2", Vector3(-6.0, 0.0, mouth_z + 7.4), 20.0, 1.0],
		["Bush_Common", Vector3(5.4, 0.0, mouth_z + 6.6), 70.0, 1.0],
		["Grass_Wispy_Short", Vector3(2.4, 0.0, mouth_z + 2.0), 0.0, 1.0],
		["Prop_Vine2", Vector3(-1.5, 2.3, mouth_z + 0.05), 0.0, 1.0],
	])
	# Galerie d'entrée : le matériel du prospecteur qui a trouvé le gisement.
	_dress(root, [
		["Prop_Support", Vector3(-1.35, 0.0, 1.6), 0.0, 1.0],
		["Prop_Support", Vector3(1.35, 0.0, 1.6), 0.0, 1.0],
		["Prop_Support", Vector3(-1.35, 0.0, -1.8), 0.0, 1.0],
		["Prop_Support", Vector3(1.35, 0.0, -1.8), 0.0, 1.0],
		["Floor_UnevenBrick", Vector3(0.0, 0.02, 0.0), 0.0, 1.0],
		["Floor_UnevenBrick", Vector3(0.0, 0.02, -2.4), 0.0, 1.0],
		["Lantern_Wall", Vector3(-1.6, 1.9, 0.2), 90.0, 1.0],
		["Bag", Vector3(1.1, 0.05, 2.2), 45.0, 1.0],
	])

	# AMAS de cristal PORTEURS : trois massifs à contourner. Ils sont placés
	# hors du point de station (0, −11,9) — un amas au milieu de la salle
	# ferait échouer la preuve de sol pour de mauvaises raisons.
	_solid(root, "AmasCristal", Vector3(-4.4, 1.5, hall_z + 2.6),
		Vector3(2.0, 3.0, 2.0), COL_CRYSTAL_PALE)
	_solid(root, "AmasCristal", Vector3(4.8, 1.2, hall_z - 2.4),
		Vector3(1.8, 2.4, 1.8), COL_CRYSTAL_AMBER)
	_solid(root, "AmasCristal", Vector3(-3.4, 1.0, hall_z - 4.4),
		Vector3(1.5, 2.0, 1.5), COL_CRYSTAL_PALE)
	_solid(root, "AmasCristal", Vector3(5.2, 0.9, hall_z + 4.2),
		Vector3(1.4, 1.8, 1.4), COL_CRYSTAL_PALE)

	# ÉCLATS décoratifs : penchés, de tailles et d'orientations dispersées.
	# Émission FAIBLE (0,45 à 0,8) — la cavité luit doucement, elle ne
	# clignote pas. `[position, taille, inclinaison, lacet, teinte, émission]`.
	var crystals: Node3D = Node3D.new()
	crystals.name = "Cristaux"
	root.add_child(crystals)
	var shards: Array[Array] = [
		[Vector3(-5.4, 1.1, hall_z + 4.8), Vector3(0.28, 2.2, 0.28), 14.0,
			25.0, COL_CRYSTAL_IVORY, 0.7],
		[Vector3(-4.9, 0.8, hall_z + 5.6), Vector3(0.22, 1.6, 0.22), -11.0,
			70.0, COL_CRYSTAL_PALE, 0.55],
		[Vector3(-5.9, 0.7, hall_z + 3.6), Vector3(0.20, 1.4, 0.20), 19.0,
			110.0, COL_CRYSTAL_AMBER, 0.6],
		[Vector3(5.6, 1.0, hall_z + 1.2), Vector3(0.26, 2.0, 0.26), -16.0,
			200.0, COL_CRYSTAL_IVORY, 0.75],
		[Vector3(5.1, 0.7, hall_z + 0.2), Vector3(0.20, 1.4, 0.20), 12.0,
			260.0, COL_CRYSTAL_PALE, 0.5],
		[Vector3(6.0, 0.9, hall_z - 0.9), Vector3(0.24, 1.8, 0.24), 8.0,
			320.0, COL_CRYSTAL_AMBER, 0.65],
		[Vector3(-2.2, 0.6, hall_z - 5.6), Vector3(0.18, 1.2, 0.18), -14.0,
			15.0, COL_CRYSTAL_PALE, 0.5],
		[Vector3(-1.2, 0.8, hall_z - 5.9), Vector3(0.22, 1.6, 0.22), 10.0,
			95.0, COL_CRYSTAL_IVORY, 0.7],
		[Vector3(0.9, 0.7, hall_z - 5.7), Vector3(0.20, 1.4, 0.20), 17.0,
			145.0, COL_CRYSTAL_AMBER, 0.6],
		[Vector3(2.6, 0.9, hall_z - 5.4), Vector3(0.24, 1.8, 0.24), -9.0,
			230.0, COL_CRYSTAL_PALE, 0.55],
		[Vector3(-4.6, 3.4, hall_z + 1.4), Vector3(0.22, 1.7, 0.22), 168.0,
			40.0, COL_CRYSTAL_IVORY, 0.8],
		[Vector3(3.8, 3.6, hall_z + 3.2), Vector3(0.18, 1.3, 0.18), 194.0,
			120.0, COL_CRYSTAL_PALE, 0.6],
		[Vector3(1.6, 3.5, hall_z - 3.6), Vector3(0.20, 1.5, 0.20), 176.0,
			280.0, COL_CRYSTAL_AMBER, 0.7],
		[Vector3(-2.8, 3.7, hall_z - 1.8), Vector3(0.16, 1.1, 0.16), 186.0,
			330.0, COL_CRYSTAL_IVORY, 0.55],
		[Vector3(-4.4, 3.1, hall_z + 2.6), Vector3(0.9, 0.5, 0.9), 0.0,
			30.0, COL_CRYSTAL_PALE, 0.45],
		[Vector3(4.8, 2.5, hall_z - 2.4), Vector3(0.8, 0.45, 0.8), 0.0,
			70.0, COL_CRYSTAL_AMBER, 0.45],
		[Vector3(-6.2, 0.35, hall_z - 2.0), Vector3(0.7, 0.7, 0.7), 22.0,
			55.0, COL_CRYSTAL_PALE, 0.4],
		[Vector3(6.1, 0.35, hall_z + 3.4), Vector3(0.6, 0.6, 0.6), -18.0,
			210.0, COL_CRYSTAL_IVORY, 0.4],
		[Vector3(0.2, 0.3, hall_z + 5.4), Vector3(0.5, 0.5, 0.5), 12.0,
			160.0, COL_CRYSTAL_AMBER, 0.4],
		[Vector3(-1.8, 0.3, hall_z + 4.4), Vector3(0.45, 0.45, 0.45), -8.0,
			300.0, COL_CRYSTAL_PALE, 0.4],
	]
	for entry_data: Array in shards:
		var at: Vector3 = entry_data[0]
		var size: Vector3 = entry_data[1]
		var tilt: float = entry_data[2]
		var yaw: float = entry_data[3]
		var tint: Color = entry_data[4]
		var glow: float = entry_data[5]
		_shard(crystals, "Eclat", at, size, tilt, yaw, tint, glow)
	# Veines minérales affleurant les parois : le gisement continue dans la
	# roche. Décor pur, aucune collision.
	for index: int in range(4):
		var z: float = hall_z + 4.0 - float(index) * 2.8
		_decor_box(crystals, "Veine", Vector3(-6.45, 2.2, z),
			Vector3(0.10, 0.5, 1.6), COL_CRYSTAL_AMBER, 0.5)
		_decor_box(crystals, "Veine", Vector3(6.45, 1.7, z),
			Vector3(0.10, 0.4, 1.4), COL_CRYSTAL_IVORY, 0.5)

	# La RAISON d'entrer : un coffre au fond, un chantier d'extraction
	# interrompu, et des champignons d'ombre humide (ingrédients de §13.1).
	_dress(root, [
		["Chest_Wood", Vector3(0.4, 0.05, hall_back_z + 1.8), 180.0, 1.0],
		["Pickaxe_Bronze", Vector3(-2.6, 0.05, hall_z + 3.4), 100.0, 1.0],
		["Crate_Wooden", Vector3(-1.8, 0.05, hall_z + 4.6), 25.0, 1.0],
		["Crate_Metal", Vector3(2.8, 0.05, hall_z + 4.2), 55.0, 1.0],
		["Bucket_Metal", Vector3(3.4, 0.05, hall_z + 2.8), 0.0, 1.0],
		["Barrel", Vector3(-3.0, 0.05, hall_z + 5.0), 0.0, 1.0],
		["Chain_Coil", Vector3(2.2, 0.05, hall_z - 4.6), 70.0, 1.0],
		["Rope_1", Vector3(-2.0, 0.05, hall_z - 3.2), 210.0, 1.0],
		["Mushroom_Common", Vector3(-5.0, 0.02, hall_z - 5.0), 0.0, 1.3],
		["Mushroom_Common", Vector3(-4.4, 0.02, hall_z - 5.6), 130.0, 1.1],
		["Mushroom_Laetiporus", Vector3(4.6, 0.02, hall_z - 5.2), 45.0, 1.0],
		["Fern_1", Vector3(3.6, 0.02, hall_z - 5.8), 190.0, 0.9],
		["Torch_Metal", Vector3(-6.2, 1.7, hall_z + 0.6), 90.0, 1.0],
		["Torch_Metal", Vector3(6.2, 1.7, hall_z + 0.6), 270.0, 1.0],
		["Bench", Vector3(-4.0, 0.05, hall_z - 1.4), 90.0, 1.0],
		["Book_Stack_1", Vector3(-4.0, 0.55, hall_z - 1.4), 30.0, 1.0],
	])

	# Lueur : chaude à l'entrée, plus pâle et minérale au fond. Rien de cyan.
	var entry_glow: OmniLight3D = OmniLight3D.new()
	entry_glow.name = "LueurEntree"
	entry_glow.light_color = Color(1.0, 0.80, 0.50)
	entry_glow.light_energy = 0.9
	entry_glow.omni_range = 9.0
	entry_glow.position = Vector3(0, 2.1, -0.6)
	root.add_child(entry_glow)
	var hall_glow: OmniLight3D = OmniLight3D.new()
	hall_glow.name = "LueurCristal"
	hall_glow.light_color = Color(0.98, 0.94, 0.80)
	hall_glow.light_energy = 1.2
	hall_glow.omni_range = 15.0
	hall_glow.position = Vector3(0, 2.6, hall_z)
	root.add_child(hall_glow)
	var amber_glow: OmniLight3D = OmniLight3D.new()
	amber_glow.name = "LueurAmbre"
	amber_glow.light_color = Color(0.96, 0.74, 0.42)
	amber_glow.light_energy = 0.8
	amber_glow.omni_range = 10.0
	amber_glow.position = Vector3(4.4, 1.8, hall_z - 2.0)
	root.add_child(amber_glow)

	var poi: PointOfInterest = _declare(root,
		&"valley.poi.crystal_hollow.01", "Cavité de cristal", &"ruines",
		Vector3(22, 12, 26), Vector3(0, 3, -2))
	# Une seule bouche : sortie et entrée sont le MÊME point. Le dire
	# autrement laisserait croire à un second débouché qui n'existe pas.
	_register(UNDER_CRYSTAL, root, poi,
		Vector3(0, 1.0, mouth_z + 2.0),      # devant la bouche
		Vector3(0, 1.0, mouth_z + 2.0),      # …et c'est la seule
		Vector3(0, 1.2, hall_z),             # station : salle de cristal
		Vector3(0, 1.2, 0.0),                # station : galerie d'entrée
		0.0, false)
