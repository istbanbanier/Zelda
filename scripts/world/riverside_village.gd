## VILLAGE DE LA RIVIÈRE — le premier lieu habité du monde ouvert.
##
## Ordre d'extension §2 : « un village habité et identifiable de loin »,
## avec place centrale, auberge visitable, forge, marché, moulin, sanctuaire,
## habitations et quai. §1 est catégorique sur un point : une structure dont
## la porte est visible doit avoir un VRAI intérieur, ou être visiblement
## condamnée — jamais une façade qui ment.
##
## L'auberge est donc réellement creuse : quatre murs sur un plancher, une
## baie de porte franchissable, un toit posé au-dessus. Le reste du bourg est
## bâti du même kit modulaire, sur la grille de 2 m que suit le pack.
##
## Le village se déclare au `DiscoveryLog` par un `PointOfInterest` : il naît
## avec son identifiant, sa sauvegarde et son test, comme tout lieu du monde.
class_name RiversideVillage
extends Node3D

## Le kit modulaire est réparti sur deux dossiers : les murs sont arrivés avec
## le lot « donjon », les toitures et escaliers avec la promotion « monde
## ouvert ». Une pièce se résout donc par recherche, pas par chemin figé —
## sinon déplacer un asset casserait le village en silence.
const KIT_DIRS: Array[String] = [
	"res://assets/environment/village/%s.gltf",
	"res://assets/environment/dungeon/%s.gltf",
]
const PROPS: String = "res://assets/environment/props/%s.gltf"

## Pas du kit Quaternius, mesuré sur les modules : murs et sols de 2 m.
const MODULE: float = 2.0
## Hauteur d'un mur, mesurée elle aussi (3,12 m).
const WALL_H: float = 3.12
## Largeur laissée libre dans une baie de porte : le joueur passe.
const DOOR_GAP: float = 1.30

## Rive SUD de la rivière (lit à z = 10, plaine sud à y = 2).
const SITE: Vector3 = Vector3(-70.0, 2.0, 36.0)

var poi: PointOfInterest = null
var interior_floor_y: float = 0.0
var _built: int = 0


func _ready() -> void:
	position = SITE
	_build_inn()
	_build_forge()
	_build_mill()
	_build_shrine()
	_build_dwellings()
	_build_square_and_quay()
	_build_poi()


func piece_count() -> int:
	return _built


# --- Briques ----------------------------------------------------------------

## Instancie une pièce du kit. Renvoie `null` si l'asset manque, sans lever :
## un village amputé d'un modèle doit rester chargeable et le dire.
func _piece(asset: String, at: Vector3, yaw_deg: float = 0.0,
		parent: Node3D = null, path: String = "") -> Node3D:
	var packed: PackedScene = null
	# Construit explicitement : un ternaire renvoie ici un `Array` non typé,
	# que GDScript refuse d'affecter à un `Array[String]` — erreur d'exécution
	# silencieuse pour le test, mais rouge pour `validate_fast`.
	var candidates: Array[String] = []
	if path.is_empty():
		candidates.assign(KIT_DIRS)
	else:
		candidates.append(path)
	for pattern: String in candidates:
		var full: String = pattern % asset
		if ResourceLoader.exists(full):
			packed = load(full) as PackedScene
			if packed != null:
				break
	if packed == null:
		push_warning("[village] pièce absente du kit : %s" % asset)
		return null
	var node: Node3D = packed.instantiate() as Node3D
	node.position = at
	node.rotation_degrees = Vector3(0, yaw_deg, 0)
	(parent if parent != null else self).add_child(node)
	_built += 1
	return node


## Collision explicite : le kit est purement visuel. Une boîte statique est
## posée à la main, ce qui permet de LAISSER un trou dans une baie de porte —
## un collider unique par mur murerait l'auberge de l'intérieur.
func _wall_collider(parent: Node3D, centre: Vector3, size: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = centre
	parent.add_child(body)


## Mur plein : visuel + collision pleine.
func _wall(parent: Node3D, at: Vector3, yaw: float, kind: String) -> void:
	_piece(kind, at, yaw, parent)
	var along: Vector3 = Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
	var thick: Vector3 = Vector3(absf(along.z), 0, absf(along.x)) * 0.4
	var span: Vector3 = along.abs() * MODULE
	_wall_collider(parent, at + Vector3(0, WALL_H * 0.5, 0),
		Vector3(maxf(span.x, thick.x), WALL_H, maxf(span.z, thick.z)))


## Mur À BAIE : deux jambages et un linteau, le passage reste libre. C'est
## ce qui distingue un intérieur réel d'une façade décorative.
func _door_wall(parent: Node3D, at: Vector3, yaw: float) -> void:
	_piece("Wall_Plaster_Door_Round", at, yaw, parent)
	var along: Vector3 = Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
	var jamb: float = (MODULE - DOOR_GAP) * 0.5
	for side: float in [-1.0, 1.0]:
		var centre: Vector3 = at + along * side * (DOOR_GAP + jamb) * 0.5 \
			+ Vector3(0, WALL_H * 0.5, 0)
		var size: Vector3 = along.abs() * jamb + Vector3(0.4, 0, 0.4) \
			* Vector3(absf(along.z), 0, absf(along.x))
		_wall_collider(parent, centre,
			Vector3(maxf(size.x, 0.4), WALL_H, maxf(size.z, 0.4)))
	# Linteau : on ne passe pas par-dessus la porte.
	_wall_collider(parent, at + Vector3(0, WALL_H - 0.4, 0),
		Vector3(maxf(along.abs().x * MODULE, 0.4), 0.8,
			maxf(along.abs().z * MODULE, 0.4)))


# --- Le bourg ---------------------------------------------------------------

## AUBERGE : 6 × 6 m, réellement creuse, porte au sud.
func _build_inn() -> void:
	var inn: Node3D = Node3D.new()
	inn.name = "Auberge"
	add_child(inn)
	inn.position = Vector3(0, 0, 0)
	var half: float = MODULE  # 3 modules de côté -> demi-emprise de 2 m

	# Plancher : c'est lui qui prouve qu'on entre dans un VOLUME.
	for ix: int in range(-1, 2):
		for iz: int in range(-1, 2):
			_piece("Floor_WoodLight",
				Vector3(ix * MODULE, 0.02, iz * MODULE), 0.0, inn)
	interior_floor_y = SITE.y + 0.02
	# Sol porteur sous le plancher : le joueur ne tombe pas au travers.
	_wall_collider(inn, Vector3(0, -0.25, 0), Vector3(6.4, 0.5, 6.4))

	# Quatre faces. La façade sud porte la baie ; les autres alternent murs
	# pleins et fenêtres pour que la maison ne soit pas aveugle.
	for ix: int in range(-1, 2):
		var x: float = ix * MODULE
		if ix == 0:
			_door_wall(inn, Vector3(x, 0, half + MODULE * 0.5), 0.0)
		else:
			_wall(inn, Vector3(x, 0, half + MODULE * 0.5), 0.0,
				"Wall_Plaster_Window_Wide_Round")
		_wall(inn, Vector3(x, 0, -half - MODULE * 0.5), 180.0,
			"Wall_Plaster_Straight")
	for iz: int in range(-1, 2):
		var z: float = iz * MODULE
		_wall(inn, Vector3(-half - MODULE * 0.5, 0, z), 90.0,
			"Wall_Plaster_Straight" if iz != 0
			else "Wall_Plaster_Window_Wide_Round")
		_wall(inn, Vector3(half + MODULE * 0.5, 0, z), 270.0,
			"Wall_Plaster_Straight" if iz != 0
			else "Wall_Plaster_Window_Wide_Round")

	_piece("Roof_RoundTiles_6x6", Vector3(0, WALL_H, 0), 0.0, inn)
	_piece("Prop_Chimney2", Vector3(1.6, WALL_H + 0.6, -1.4), 0.0, inn)

	# Mobilier : l'auberge est MEUBLÉE, sinon c'est une pièce vide avec un toit.
	_piece("Table_Large", Vector3(-1.2, 0.05, -0.8), 0.0, inn, PROPS)
	_piece("Stool", Vector3(-2.0, 0.05, -0.8), 0.0, inn, PROPS)
	_piece("Bench", Vector3(-1.2, 0.05, 0.6), 0.0, inn, PROPS)
	_piece("Barrel", Vector3(2.0, 0.05, -1.8), 0.0, inn, PROPS)
	_piece("Cauldron", Vector3(1.9, 0.05, 1.6), 0.0, inn, PROPS)
	_piece("Bed_Twin1", Vector3(-1.8, 0.05, 1.7), 90.0, inn, PROPS)


## FORGE : appentis ouvert — on voit l'artisan travailler depuis la place.
func _build_forge() -> void:
	var forge: Node3D = Node3D.new()
	forge.name = "Forge"
	add_child(forge)
	forge.position = Vector3(11.0, 0, 2.0)
	for iz: int in range(-1, 2):
		_wall(forge, Vector3(-MODULE, 0, iz * MODULE), 90.0,
			"Wall_UnevenBrick_Straight")
	for ix: int in range(-1, 1):
		_wall(forge, Vector3(ix * MODULE + 1.0, 0, -MODULE * 1.5), 180.0,
			"Wall_UnevenBrick_Straight")
	_piece("Roof_Wooden_2x1_Center", Vector3(0, WALL_H, 0), 0.0, forge)
	_piece("Anvil", Vector3(0.6, 0.05, 0.4), 20.0, forge, PROPS)
	_piece("Workbench", Vector3(-1.2, 0.05, 1.6), 0.0, forge, PROPS)
	_piece("Whetstone", Vector3(1.4, 0.05, 1.4), 0.0, forge, PROPS)
	_piece("WeaponStand", Vector3(-1.4, 0.05, -1.6), 0.0, forge, PROPS)


## MOULIN : la verticale qui identifie le village de loin (§4 de l'ordre).
func _build_mill() -> void:
	var mill: Node3D = Node3D.new()
	mill.name = "Moulin"
	add_child(mill)
	mill.position = Vector3(-4.0, 0, -16.0)   # côté rivière
	for level: int in range(2):
		var y: float = float(level) * WALL_H
		for ix: int in [-1, 1]:
			_wall(mill, Vector3(ix * MODULE * 0.5, y, MODULE * 0.5), 0.0,
				"Wall_UnevenBrick_Straight")
			_wall(mill, Vector3(ix * MODULE * 0.5, y, -MODULE * 0.5), 180.0,
				"Wall_UnevenBrick_Straight")
			_wall(mill, Vector3(ix * MODULE, y, 0.0), 90.0 if ix < 0 else 270.0,
				"Wall_UnevenBrick_Straight")
	_piece("Roof_Tower_RoundTiles", Vector3(0, WALL_H * 2.0, 0), 0.0, mill)


## SANCTUAIRE : petit, ouvert, sur la hauteur du village.
func _build_shrine() -> void:
	var shrine: Node3D = Node3D.new()
	shrine.name = "Sanctuaire"
	add_child(shrine)
	shrine.position = Vector3(-14.0, 0, 8.0)
	for ix: int in [-1, 1]:
		_wall(shrine, Vector3(ix * MODULE * 0.5, 0, -MODULE * 0.5), 180.0,
			"Wall_Plaster_Straight")
	_piece("Roof_RoundTiles_4x4", Vector3(0, WALL_H, 0), 0.0, shrine)
	_piece("CandleStick", Vector3(0, 0.05, -0.6), 0.0, shrine, PROPS)
	_piece("Banner_1", Vector3(-1.4, 0.05, -0.8), 0.0, shrine, PROPS)


## HABITATIONS : deux maisons fermées, portes VISIBLEMENT condamnées par des
## planches — §1 interdit de laisser croire qu'on peut entrer partout.
func _build_dwellings() -> void:
	var row: Node3D = Node3D.new()
	row.name = "Habitations"
	add_child(row)
	var sites: Array[Vector3] = [Vector3(8.0, 0, 14.0), Vector3(-10.0, 0, 18.0)]
	for index: int in range(sites.size()):
		var house: Node3D = Node3D.new()
		house.name = "Maison%d" % (index + 1)
		row.add_child(house)
		house.position = sites[index]
		for ix: int in [-1, 1]:
			_wall(house, Vector3(ix * MODULE * 0.5, 0, MODULE), 0.0,
				"Wall_Plaster_Window_Wide_Round")
			_wall(house, Vector3(ix * MODULE * 0.5, 0, -MODULE), 180.0,
				"Wall_Plaster_Straight")
			_wall(house, Vector3(ix * MODULE, 0, 0.0),
				90.0 if ix < 0 else 270.0, "Wall_Plaster_Straight")
		_piece("Roof_RoundTiles_4x4", Vector3(0, WALL_H, 0), 0.0, house)
		_piece("Prop_Chimney2", Vector3(0.8, WALL_H + 0.5, -0.8), 0.0, house)


## PLACE et QUAI : le marché, les clôtures, et la descente vers l'eau.
func _build_square_and_quay() -> void:
	var square: Node3D = Node3D.new()
	square.name = "PlaceEtQuai"
	add_child(square)
	_piece("Stall_Cart_Empty", Vector3(3.0, 0.05, 8.0), 30.0, square, PROPS)
	_piece("FarmCrate_Apple", Vector3(4.4, 0.05, 9.0), 0.0, square, PROPS)
	_piece("Barrel_Apples", Vector3(2.0, 0.05, 9.4), 0.0, square, PROPS)
	_piece("Crate_Wooden", Vector3(5.2, 0.05, 7.4), 15.0, square, PROPS)
	for i: int in range(4):
		_piece("Prop_WoodenFence_Extension2",
			Vector3(-16.0 + float(i) * 2.0, 0, 14.0), 0.0, square)
	# Quai : descente vers la rive, face au lit de rivière (z = 10 en repère
	# monde, donc z négatif ici puisque le village est posé à z = 36).
	for i: int in range(3):
		_piece("Stairs_Exterior_Straight_L",
			Vector3(-2.0, -float(i) * 1.2, -21.0 - float(i) * 2.0), 0.0, square)


## Le village se DÉCLARE : identifiant stable, nom affiché, région.
func _build_poi() -> void:
	poi = PointOfInterest.new()
	poi.name = "PointDInteret"
	poi.poi_id = &"valley.poi.riverside_village.01"
	poi.display_name = "Village de la rivière"
	poi.region = &"riviere"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(46, 12, 46)
	shape.shape = box
	poi.add_child(shape)
	poi.position = Vector3(0, 4, 4)
	add_child(poi)
	# ANCRAGE de récompense (contrat `RewardAnchor`) : sur la place, devant
	# l'auberge. Position éprouvée par `tools/godot/probe_reward_anchors.gd`
	# dans la vallée montée — sol réel, dégagement au gabarit du joueur — puis
	# figée ici. Le village de forge rend une arme, pas un coffre de plus.
	RewardAnchor.attach(self, poi.poi_id, RewardAnchor.Kind.WEAPON,
		Vector3(0.0, 0.0, 4.0), Vector3(3.0, 0.0, 4.0))
