## HAMEAUX DE LA VALLÉE — les deux petits établissements de travail.
##
## Ordre d'extension §2 : après « un village habité et identifiable de loin »
## viennent les hameaux. Deux, ici, et surtout PAS deux copies du village de la
## rivière. Chacun a son métier, son architecture et son ambiance ; on doit
## pouvoir dire ce qu'on y fabrique avant d'y être entré.
##
##   - `HameauDesBucherons`, à la lisière EST de la forêt claire : pans de bois,
##     écrans de planches, toitures de rondins et de bardeaux, troncs empilés,
##     scierie ouverte, établi, hache et charrette. On y travaille le bois.
##   - `PosteMinier`, au pied de la falaise d'apprentissage : brique inégale,
##     toit-terrasse plat à parapet, galerie condamnée par une grille, caisses
##     de minerai, pioches, séchoir et palissade. On y travaille la pierre.
##
## Le village de la rivière, lui, est de plâtre clair sous tuiles rondes. Les
## trois lieux se distinguent donc en silhouette : toiture pentue de tuiles,
## toiture de bois, toit plat de brique.
##
## §1 reste la règle dure : une porte visible ouvre sur un VRAI intérieur, ou
## elle est visiblement condamnée. La cabane et le corps de garde sont donc
## réellement creux — quatre murs, un plancher, une baie franchissable. La
## galerie de mine, elle, est barrée d'une grille, et cette grille porte une
## COLLISION, pas seulement un maillage : la façade ne ment pas.
##
## Chaque hameau se déclare au `DiscoveryLog` par son propre `PointOfInterest`,
## avec un identifiant §19.3 distinct.
class_name Hamlets
extends Node3D

## Même règle qu'au village : le kit modulaire est réparti sur deux dossiers
## (les murs sont arrivés avec le lot « donjon », toitures et escaliers avec la
## promotion « monde ouvert »). Une pièce se résout par RECHERCHE, pas par
## chemin figé — sinon déplacer un asset casserait les hameaux en silence.
const KIT_DIRS: Array[String] = [
	"res://assets/environment/village/%s.gltf",
	"res://assets/environment/dungeon/%s.gltf",
]
const PROPS: String = "res://assets/environment/props/%s.gltf"
const FOLIAGE: String = "res://assets/environment/foliage/%s.gltf"
const ROCKS: String = "res://assets/environment/rocks/%s.gltf"

## Pas du kit, mesuré sur les modules du bourg : murs et sols de 2 m.
const MODULE: float = 2.0
## Hauteur d'un mur du kit (3,12 m).
const WALL_H: float = 3.12
## Largeur laissée libre dans une baie de porte : le joueur passe.
const DOOR_GAP: float = 1.30

## LISIÈRE EST de la forêt claire (troncs jusqu'à x ≈ 95, plaine sud à y = 2).
## Loin du camp ennemi (45, 6, 65) et du gué est (95, 10) : on n'empile pas
## deux lieux au même endroit.
const SITE_LOGGING: Vector3 = Vector3(110.0, 2.0, 40.0)
## PIED DE LA FALAISE d'apprentissage (face est du plateau, x = −80), au nord
## du village de la rivière (−70, 2, 36) qu'il ne doit pas chevaucher.
const SITE_MINING: Vector3 = Vector3(-68.0, 2.0, 86.0)

## §19.3 : `zone.category.name.index`.
const LOGGING_POI_ID: StringName = &"valley.poi.logging_hamlet.01"
const MINING_POI_ID: StringName = &"valley.poi.mining_post.01"

## ANCRAGES de récompense (contrat `RewardAnchor`). Positions éprouvées par
## `tools/godot/probe_reward_anchors.gd` dans la vallée montée, puis figées.
const ANCHORS: Dictionary = {
	LOGGING_POI_ID: {
		"at": Vector3(2.0, 0.0, 4.0), "approach": Vector3(5.0, 0.0, 4.0),
		"kind": RewardAnchor.Kind.WEAPON,
	},
	MINING_POI_ID: {
		"at": Vector3(1.0, 0.0, 1.0), "approach": Vector3(-1.77, 0.0, 2.15),
		"kind": RewardAnchor.Kind.CHEST,
	},
}

## Quartiers exposés pour que les tests puissent les interroger sans deviner
## un chemin de nœud.
var logging_camp: Node3D = null
var mining_post: Node3D = null
var logging_poi: PointOfInterest = null
var mining_poi: PointOfInterest = null

## Hauteur du plancher des deux pièces CLOSES — ce que le test « on s'y tient
## debout » compare pour vérifier qu'on n'est pas tombé au fond du monde.
var cabin_floor_y: float = 0.0
var guardhouse_floor_y: float = 0.0

var _built: int = 0
var _logging_built: int = 0
var _mining_built: int = 0


func _ready() -> void:
	# Les deux hameaux portent leurs coordonnées absolues : ce nœud reste à
	# l'origine, sinon un décalage du parent déplacerait les deux lieux.
	position = Vector3.ZERO
	_build_logging_hamlet()
	_build_mining_post()


func piece_count() -> int:
	return _built


func logging_piece_count() -> int:
	return _logging_built


func mining_piece_count() -> int:
	return _mining_built


## Les deux lieux, pour un appelant qui veut les lier en une fois. `ValleyWorld`
## n'en a pas besoin (il parcourt les `PointOfInterest` descendants), mais un
## test ou un outil de contrôle, si.
func pois() -> Array[PointOfInterest]:
	var found: Array[PointOfInterest] = []
	if logging_poi != null:
		found.append(logging_poi)
	if mining_poi != null:
		found.append(mining_poi)
	return found


# --- Briques ----------------------------------------------------------------

## Instancie une pièce du kit. Renvoie `null` si l'asset manque, sans lever :
## un hameau amputé d'un modèle doit rester chargeable et le DIRE.
##
## `tilt_deg` permet de coucher une pièce (un poteau devient un tronc empilé,
## une dalle de plancher devient un écran de planches) sans multiplier les
## assets — le kit n'en contient pas d'autre.
func _piece(asset: String, at: Vector3, yaw_deg: float = 0.0,
		parent: Node3D = null, path: String = "",
		tilt_deg: Vector3 = Vector3.ZERO) -> Node3D:
	var packed: PackedScene = null
	# Construit explicitement : un ternaire renvoie ici un `Array` non typé,
	# que GDScript refuse d'affecter à un `Array[String]`.
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
		push_warning("[hameaux] pièce absente du kit : %s" % asset)
		return null
	var node: Node3D = packed.instantiate() as Node3D
	# Nom unique, comme `ValleyRelics._spawn` : deux pièces homonymes sous le
	# même parent sont rebaptisées `@Node3D@366` par le moteur, et plus aucun
	# test ne peut alors les désigner — la géométrie devient invisible aux
	# tests, ce qui a laissé passer un toit flottant dans le village.
	node.name = "%s_%03d" % [asset, _built]
	node.position = at
	# §3 : le kit végétal est importé sans normalisation d'échelle ; la
	# correction mesurée vit dans `KitScale`, en un seul point.
	var corrected: float = KitScale.factor(asset)
	if not is_equal_approx(corrected, 1.0):
		node.scale = Vector3.ONE * corrected
	node.rotation_degrees = Vector3(tilt_deg.x, yaw_deg + tilt_deg.y, tilt_deg.z)
	(parent if parent != null else self).add_child(node)
	_built += 1
	return node


## Collision explicite : le kit est purement visuel. Une boîte statique est
## posée à la main, ce qui permet de LAISSER un trou dans une baie de porte —
## un collider unique par mur murerait la cabane de l'intérieur.
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


## Mur plein : visuel + collision pleine. Même géométrie qu'au village
## (`scripts/world/riverside_village.gd`) : elle y est éprouvée.
func _wall(parent: Node3D, at: Vector3, yaw: float, kind: String) -> void:
	_piece(kind, at, yaw, parent)
	var along: Vector3 = Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
	var thick: Vector3 = Vector3(absf(along.z), 0, absf(along.x)) * 0.4
	var span: Vector3 = along.abs() * MODULE
	_wall_collider(parent, at + Vector3(0, WALL_H * 0.5, 0),
		Vector3(maxf(span.x, thick.x), WALL_H, maxf(span.z, thick.z)))


## Mur À BAIE : deux jambages et un linteau, le passage reste libre. C'est ce
## qui distingue un intérieur réel d'une façade décorative.
func _door_wall(parent: Node3D, at: Vector3, yaw: float, kind: String) -> void:
	_piece(kind, at, yaw, parent)
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


## Une clôture posée pièce par pièce, chaque segment avec sa collision : une
## palissade qu'on traverse n'enclôt rien. `gap_at` laisse le portail ouvert.
func _fence_row(parent: Node3D, kind: String, start: Vector3, step: Vector3,
		count: int, yaw: float, gap_at: Array[int]) -> void:
	var along: Vector3 = step.normalized()
	for i: int in range(count):
		if gap_at.has(i):
			continue
		var at: Vector3 = start + step * float(i)
		_piece(kind, at, yaw, parent)
		var size: Vector3 = along.abs() * MODULE \
			+ Vector3(absf(along.z), 0.0, absf(along.x)) * 0.35
		_wall_collider(parent, at + Vector3(0, 0.85, 0),
			Vector3(maxf(size.x, 0.35), 1.7, maxf(size.z, 0.35)))


# --- Hameau des bûcherons ---------------------------------------------------

## Bois dominant : écrans de planches, poteaux d'angle en bois, toitures de
## bardeaux et rondins, planchers clairs. Aucune tuile ronde — c'est la
## signature du village de la rivière, pas celle-ci.
func _build_logging_hamlet() -> void:
	var before: int = _built
	logging_camp = Node3D.new()
	logging_camp.name = "HameauDesBucherons"
	add_child(logging_camp)
	logging_camp.position = SITE_LOGGING
	_build_logging_cabin(logging_camp)
	_build_sawmill(logging_camp)
	_build_log_stacks(logging_camp)
	_build_cart_yard(logging_camp)
	_dress_logging_edge(logging_camp)
	logging_poi = _make_poi(logging_camp, LOGGING_POI_ID,
		"Hameau des bûcherons", &"foret", Vector3(2, 4, 4),
		Vector3(44, 12, 44))
	_logging_built = _built - before


## CABANE : 6 × 6 m, réellement creuse, porte à l'OUEST — elle regarde la
## forêt et la scierie, là où l'on travaille.
func _build_logging_cabin(parent: Node3D) -> void:
	var cabin: Node3D = Node3D.new()
	cabin.name = "CabaneDesBucherons"
	parent.add_child(cabin)
	cabin.position = Vector3.ZERO
	var half: float = MODULE   # 3 modules de côté -> demi-emprise de 2 m

	# Plancher : c'est lui qui prouve qu'on entre dans un VOLUME.
	for ix: int in range(-1, 2):
		for iz: int in range(-1, 2):
			_piece("Floor_WoodLight",
				Vector3(ix * MODULE, 0.02, iz * MODULE), 0.0, cabin)
	cabin_floor_y = SITE_LOGGING.y + 0.02
	# Sol porteur sous le plancher : le joueur ne tombe pas au travers.
	_wall_collider(cabin, Vector3(0, -0.25, 0), Vector3(6.4, 0.5, 6.4))

	# Quatre faces. La façade OUEST porte la baie ; les autres alternent murs
	# pleins et fenêtres pour que la cabane ne soit pas aveugle.
	for iz: int in range(-1, 2):
		var z: float = iz * MODULE
		if iz == 0:
			_door_wall(cabin, Vector3(-half - MODULE * 0.5, 0, z), 90.0,
				"Wall_Plaster_Door_Round")
		else:
			_wall(cabin, Vector3(-half - MODULE * 0.5, 0, z), 90.0,
				"Wall_Plaster_Straight")
		_wall(cabin, Vector3(half + MODULE * 0.5, 0, z), 270.0,
			"Wall_Plaster_Window_Wide_Round" if iz == 0
			else "Wall_Plaster_Straight")
	for ix: int in range(-1, 2):
		var x: float = ix * MODULE
		_wall(cabin, Vector3(x, 0, half + MODULE * 0.5), 0.0,
			"Wall_Plaster_Window_Wide_Round" if ix == 0
			else "Wall_Plaster_Straight")
		_wall(cabin, Vector3(x, 0, -half - MODULE * 0.5), 180.0,
			"Wall_Plaster_Straight")

	# Pans de bois : poteaux d'angle apparents — le remplissage clair est pris
	# dans une ossature, comme un colombage. C'est ce qui éloigne la cabane du
	# plâtre lisse du bourg.
	for corner: Vector3 in [Vector3(-3, 0, -3), Vector3(3, 0, -3),
			Vector3(-3, 0, 3), Vector3(3, 0, 3)]:
		_piece("Corner_Exterior_Wood", corner, 0.0, cabin)
	# Toiture de BARDEAUX, pentue, avec un rondin de faîtage : ni tuile ronde
	# (le village), ni terrasse plate (le poste minier).
	for iz: int in range(-1, 2):
		var z: float = iz * MODULE
		_piece("Roof_Wooden_2x1_L", Vector3(-MODULE, WALL_H, z), 0.0, cabin)
		_piece("Roof_Wooden_2x1_Center", Vector3(0, WALL_H, z), 0.0, cabin)
		_piece("Roof_Wooden_2x1_R", Vector3(MODULE, WALL_H, z), 0.0, cabin)
	_piece("Roof_Log", Vector3(0, WALL_H + 0.9, 0), 0.0, cabin)
	_piece("Prop_Chimney", Vector3(1.6, WALL_H + 0.6, -1.4), 0.0, cabin)
	_piece("Roof_FrontSupports", Vector3(0, WALL_H - 0.2, 3.1), 0.0, cabin)

	# Mobilier : on VIT ici, ce n'est pas une pièce vide sous un toit.
	_piece("Table_Large", Vector3(-1.2, 0.05, -0.9), 0.0, cabin, PROPS)
	_piece("Stool", Vector3(-2.0, 0.05, -0.9), 0.0, cabin, PROPS)
	_piece("Chair_1", Vector3(-0.4, 0.05, -1.7), 200.0, cabin, PROPS)
	_piece("Bed_Twin1", Vector3(1.8, 0.05, -1.6), 90.0, cabin, PROPS)
	_piece("Chest_Wood", Vector3(2.1, 0.05, 1.7), 0.0, cabin, PROPS)
	_piece("Shelf_Simple", Vector3(-2.5, 0.05, 1.4), 90.0, cabin, PROPS)
	_piece("Pot_1", Vector3(-2.4, 0.95, 1.4), 0.0, cabin, PROPS)
	_piece("Candle_1", Vector3(-1.1, 0.82, -1.2), 0.0, cabin, PROPS)
	_piece("Bucket_Wooden_1", Vector3(0.9, 0.05, 2.1), 25.0, cabin, PROPS)
	_piece("Lantern_Wall", Vector3(-2.85, 1.9, -1.0), 90.0, cabin, PROPS)


## SCIERIE : appentis OUVERT sur trois côtés — on voit le travail depuis la
## lisière. L'écran du fond est fait de dalles de plancher redressées : le kit
## n'a pas de mur de planches, mais il a des planches.
func _build_sawmill(parent: Node3D) -> void:
	var mill: Node3D = Node3D.new()
	mill.name = "Scierie"
	parent.add_child(mill)
	mill.position = Vector3(12.0, 0, 1.0)

	# Écran de planches au nord (deux rangs de 2 m -> 4 m de haut).
	for ix: int in range(-1, 2):
		var x: float = ix * MODULE
		_piece("Floor_WoodDark", Vector3(x, 1.0, -3.0), 0.0, mill, "",
			Vector3(90, 0, 0))
		_piece("Floor_WoodDark", Vector3(x, 3.0, -3.0), 0.0, mill, "",
			Vector3(90, 0, 0))
	_wall_collider(mill, Vector3(0, 2.0, -3.0), Vector3(6.4, 4.0, 0.4))

	# Quatre poteaux porteurs : ils tiennent la couverture et se heurtent.
	for corner: Vector3 in [Vector3(-3, 0, -2.8), Vector3(3, 0, -2.8),
			Vector3(-3, 0, 2.8), Vector3(3, 0, 2.8)]:
		_piece("Prop_Support", corner, 0.0, mill)
		_wall_collider(mill, corner + Vector3(0, 1.8, 0),
			Vector3(0.45, 3.6, 0.45))
	# Couverture de bardeaux sur toute la travée.
	for iz: int in range(-1, 2):
		var z: float = iz * MODULE
		_piece("Roof_Wooden_2x1_L", Vector3(-MODULE, 3.9, z), 0.0, mill)
		_piece("Roof_Wooden_2x1_Center", Vector3(0, 3.9, z), 0.0, mill)
		_piece("Roof_Wooden_2x1_R", Vector3(MODULE, 3.9, z), 0.0, mill)

	# Sol de travail : plancher de planches sombres, copeaux compris.
	for ix: int in range(-1, 2):
		for iz: int in range(-1, 2):
			_piece("Floor_WoodDark", Vector3(ix * MODULE, 0.02, iz * MODULE),
				0.0, mill)

	# L'ÉTABLI et la HACHE : la fonction du lieu, lisible d'un coup d'œil.
	_piece("Workbench", Vector3(-1.4, 0.05, -1.9), 0.0, mill, PROPS)
	_piece("Axe_Bronze", Vector3(-1.2, 0.95, -1.9), 15.0, mill, PROPS)
	_piece("Whetstone", Vector3(0.6, 0.05, -2.1), 0.0, mill, PROPS)
	_piece("Crate_Wooden", Vector3(2.2, 0.05, -1.6), 12.0, mill, PROPS)
	_piece("Barrel", Vector3(2.4, 0.05, 1.2), 0.0, mill, PROPS)
	_piece("Bucket_Wooden_1", Vector3(1.4, 0.05, 2.2), 40.0, mill, PROPS)
	_piece("Rope_1", Vector3(-2.2, 0.05, 1.6), 0.0, mill, PROPS)
	_piece("Chain_Coil", Vector3(-2.4, 0.05, 0.4), 0.0, mill, PROPS)
	# Deux billes en attente de refente, couchées près de l'établi.
	_piece("Prop_Support", Vector3(0.2, 0.3, 1.9), 0.0, mill, "",
		Vector3(0, 0, 90))
	_piece("Prop_Support", Vector3(0.2, 0.3, 2.6), 0.0, mill, "",
		Vector3(0, 0, 90))


## TRONCS EMPILÉS : deux piles pyramidales, franches et solides. Elles font
## obstacle — un tas de bois qu'on traverse n'est qu'une image.
func _build_log_stacks(parent: Node3D) -> void:
	var stacks: Node3D = Node3D.new()
	stacks.name = "PileDeTroncs"
	parent.add_child(stacks)
	stacks.position = Vector3(5.0, 0, 9.0)
	var bases: Array[Vector3] = [Vector3.ZERO, Vector3(0, 0, 4.4)]
	for base: Vector3 in bases:
		for z: float in [-1.0, 0.0, 1.0]:
			_piece("Prop_Support", base + Vector3(0, 0.35, z), 0.0, stacks, "",
				Vector3(0, 0, 90))
		for z: float in [-0.5, 0.5]:
			_piece("Prop_Support", base + Vector3(0, 1.0, z), 0.0, stacks, "",
				Vector3(0, 0, 90))
		_piece("Prop_Support", base + Vector3(0, 1.65, 0), 0.0, stacks, "",
			Vector3(0, 0, 90))
		_wall_collider(stacks, base + Vector3(0, 1.0, 0),
			Vector3(4.2, 2.0, 2.8))
	# Le bois débité, mis à part, et de quoi le lier.
	_piece("Crate_Wooden", Vector3(2.6, 0.05, 2.2), 30.0, stacks, PROPS)
	_piece("Rope_1", Vector3(2.0, 0.05, 3.4), 0.0, stacks, PROPS)


## CHARRETTERIE : la charrette, ce qui s'y charge, et l'enclos bas qui tient
## l'attelage. Portail laissé ouvert au sud, côté chemin.
func _build_cart_yard(parent: Node3D) -> void:
	var yard: Node3D = Node3D.new()
	yard.name = "Charretterie"
	parent.add_child(yard)
	yard.position = Vector3(-9.0, 0, 8.0)
	_piece("Prop_Wagon", Vector3(0, 0.05, 0), 25.0, yard)
	_piece("FarmCrate_Empty", Vector3(2.2, 0.05, -1.1), 10.0, yard, PROPS)
	_piece("Crate_Wooden", Vector3(2.6, 0.05, 0.4), 40.0, yard, PROPS)
	_piece("Barrel", Vector3(-2.4, 0.05, 1.0), 0.0, yard, PROPS)
	_piece("Barrel_Holder", Vector3(-2.4, 0.05, 2.2), 0.0, yard, PROPS)
	_piece("Bag", Vector3(1.4, 0.05, 1.9), 60.0, yard, PROPS)
	_piece("Torch_Metal", Vector3(3.4, 0, -2.6), 0.0, yard, PROPS)
	# Enclos bas : deux côtés seulement, le hameau reste traversable.
	var no_gap: Array[int] = []
	_fence_row(yard, "Prop_WoodenFence_Extension2", Vector3(-4.0, 0, 3.4),
		Vector3(MODULE, 0, 0), 5, 0.0, no_gap)
	_fence_row(yard, "Prop_WoodenFence_Extension1", Vector3(-4.6, 0, -3.0),
		Vector3(0, 0, MODULE), 4, 90.0, no_gap)


## Lisière : quelques souches, pins et broussailles qui raccordent le hameau à
## la forêt au lieu de le poser sur une pelouse nue.
func _dress_logging_edge(parent: Node3D) -> void:
	var edge: Node3D = Node3D.new()
	edge.name = "Lisiere"
	parent.add_child(edge)
	var greens: Array[Vector3] = [
		Vector3(-13.5, 0, -3.0), Vector3(-12.0, 0, 4.5),
		Vector3(-11.0, 0, -8.0), Vector3(6.0, 0, -7.5),
	]
	for i: int in range(greens.size()):
		var kind: String = "Pine_2" if i % 2 == 0 else "CommonTree_3"
		_piece(kind, greens[i], float(i) * 47.0, edge, FOLIAGE)
	_piece("Bush_Common", Vector3(-6.5, 0, 12.0), 20.0, edge, FOLIAGE)
	_piece("Fern_1", Vector3(-4.0, 0, -5.5), 130.0, edge, FOLIAGE)
	_piece("Mushroom_Common", Vector3(9.5, 0, 7.5), 0.0, edge, FOLIAGE)
	_piece("Rock_Medium_2", Vector3(14.0, 0, 9.0), 60.0, edge, ROCKS)


# --- Poste minier de la falaise ---------------------------------------------

## Pierre dominante : brique inégale, plancher de brique, toit-TERRASSE plat à
## parapet. Pas un rondin de charpente apparente — c'est l'autre métier.
func _build_mining_post() -> void:
	var before: int = _built
	mining_post = Node3D.new()
	mining_post.name = "PosteMinier"
	add_child(mining_post)
	mining_post.position = SITE_MINING
	_build_guardhouse(mining_post)
	_build_mine_gallery(mining_post)
	_build_drying_shed(mining_post)
	_build_ore_yard(mining_post)
	_build_palisade(mining_post)
	mining_poi = _make_poi(mining_post, MINING_POI_ID,
		"Poste minier de la falaise", &"falaise", Vector3(1, 4, 1),
		Vector3(40, 12, 40))
	_mining_built = _built - before


## CORPS DE GARDE : 6 × 6 m, réellement creux, porte à l'EST — elle regarde la
## cour, le portail et la plaine par où l'on arrive.
func _build_guardhouse(parent: Node3D) -> void:
	var house: Node3D = Node3D.new()
	house.name = "CorpsDeGarde"
	parent.add_child(house)
	house.position = Vector3.ZERO
	var half: float = MODULE

	for ix: int in range(-1, 2):
		for iz: int in range(-1, 2):
			_piece("Floor_Brick",
				Vector3(ix * MODULE, 0.02, iz * MODULE), 0.0, house)
	guardhouse_floor_y = SITE_MINING.y + 0.02
	_wall_collider(house, Vector3(0, -0.25, 0), Vector3(6.4, 0.5, 6.4))

	for iz: int in range(-1, 2):
		var z: float = iz * MODULE
		if iz == 0:
			_door_wall(house, Vector3(half + MODULE * 0.5, 0, z), 270.0,
				"Wall_UnevenBrick_Door_Round")
		else:
			_wall(house, Vector3(half + MODULE * 0.5, 0, z), 270.0,
				"Wall_UnevenBrick_Straight")
		_wall(house, Vector3(-half - MODULE * 0.5, 0, z), 90.0,
			"Wall_UnevenBrick_Window_Thin_Round" if iz == 0
			else "Wall_UnevenBrick_Straight")
	for ix: int in range(-1, 2):
		var x: float = ix * MODULE
		_wall(house, Vector3(x, 0, half + MODULE * 0.5), 0.0,
			"Wall_UnevenBrick_Window_Wide_Round" if ix == 0
			else "Wall_UnevenBrick_Straight")
		_wall(house, Vector3(x, 0, -half - MODULE * 0.5), 180.0,
			"Wall_UnevenBrick_Window_Thin_Round" if ix == 0
			else "Wall_UnevenBrick_Straight")
	for corner: Vector3 in [Vector3(-3, 0, -3), Vector3(3, 0, -3),
			Vector3(-3, 0, 3), Vector3(3, 0, 3)]:
		_piece("Corner_Exterior_Brick", corner, 0.0, house)

	# TOIT-TERRASSE : des dalles de brique posées à plat, ceinturées d'un
	# parapet. Silhouette horizontale — l'inverse exact des toitures pentues
	# du bourg et de la cabane des bûcherons.
	for ix: int in range(-1, 2):
		for iz: int in range(-1, 2):
			_piece("Floor_Brick",
				Vector3(ix * MODULE, WALL_H, iz * MODULE), 0.0, house)
	for ix: int in range(-1, 2):
		var px: float = ix * MODULE
		_piece("Prop_ExteriorBorder_Straight1",
			Vector3(px, WALL_H + 0.1, 3.0), 0.0, house)
		_piece("Prop_ExteriorBorder_Straight1",
			Vector3(px, WALL_H + 0.1, -3.0), 180.0, house)
	for iz: int in range(-1, 2):
		var pz: float = iz * MODULE
		_piece("Prop_ExteriorBorder_Straight1",
			Vector3(3.0, WALL_H + 0.1, pz), 270.0, house)
		_piece("Prop_ExteriorBorder_Straight1",
			Vector3(-3.0, WALL_H + 0.1, pz), 90.0, house)

	# Mobilier : on y dort, on y compte, on y range les outils.
	_piece("Bed_Twin1", Vector3(-1.8, 0.05, -1.6), 90.0, house, PROPS)
	_piece("Bed_Twin1", Vector3(-1.8, 0.05, 1.6), 90.0, house, PROPS)
	_piece("Table_Large", Vector3(1.4, 0.05, -1.0), 90.0, house, PROPS)
	_piece("Bench", Vector3(0.4, 0.05, -1.0), 90.0, house, PROPS)
	_piece("Book_Stack_1", Vector3(1.4, 0.85, -1.2), 0.0, house, PROPS)
	_piece("Mug", Vector3(1.5, 0.85, -0.5), 0.0, house, PROPS)
	_piece("Chest_Wood", Vector3(1.9, 0.05, 2.1), 180.0, house, PROPS)
	_piece("Pickaxe_Bronze", Vector3(-2.6, 0.05, 0.2), 10.0, house, PROPS)
	_piece("Bucket_Metal", Vector3(0.2, 0.05, 2.3), 0.0, house, PROPS)
	_piece("Lantern_Wall", Vector3(2.85, 1.9, 1.2), 270.0, house, PROPS)
	_piece("Torch_Metal", Vector3(3.6, 0, 0.9), 0.0, house, PROPS)


## GALERIE : la bouche de mine, plaquée contre la falaise. §1 interdit une
## porte qui ment : celle-ci est VISIBLEMENT condamnée par une grille, et la
## grille porte une collision pleine. On voit où l'on ne va pas.
func _build_mine_gallery(parent: Node3D) -> void:
	var gallery: Node3D = Node3D.new()
	gallery.name = "GalerieDeMine"
	parent.add_child(gallery)
	# Face est de la falaise à x = −80 en repère monde : la bouche s'ouvre
	# vers l'est, à un mètre du rocher.
	gallery.position = Vector3(-11.0, 0, -2.0)

	_piece("Wall_Arch", Vector3(0, 0, 0), 90.0, gallery)
	_piece("DoorFrame_Round_Brick", Vector3(0.15, 0, 0), 90.0, gallery)
	for side: float in [-1.0, 1.0]:
		_piece("Prop_Support", Vector3(0.35, 0, side * 1.25), 0.0, gallery)
	# La GRILLE, et sa collision : la galerie est fermée pour de bon.
	_piece("Prop_MetalFence_Simple", Vector3(0.35, 0, 0), 90.0, gallery)
	_wall_collider(gallery, Vector3(0.2, WALL_H * 0.5, 0),
		Vector3(0.7, WALL_H, 3.0))
	# Le rocher derrière : rien ne passe non plus par les côtés.
	for side: float in [-1.0, 1.0]:
		_wall_collider(gallery, Vector3(-0.4, WALL_H * 0.5, side * 2.4),
			Vector3(1.6, WALL_H, 1.6))

	# Le convoi : berline, rail de pierre, déblais, outils au pied.
	_piece("RockPath_Square_Wide", Vector3(2.2, 0.02, 0), 0.0, gallery, ROCKS)
	_piece("RockPath_Square_Small_1", Vector3(4.0, 0.02, 0.2), 0.0, gallery,
		ROCKS)
	_piece("Prop_Wagon", Vector3(3.2, 0.05, 0.1), 90.0, gallery)
	_piece("Pickaxe_Bronze", Vector3(1.5, 0.05, -1.9), 70.0, gallery, PROPS)
	_piece("Prop_Brick1", Vector3(1.9, 0.05, 2.3), 20.0, gallery)
	_piece("Rock_Medium_1", Vector3(2.6, 0, -3.2), 40.0, gallery, ROCKS)
	_piece("Pebble_Square_1", Vector3(1.2, 0.02, 1.4), 0.0, gallery, ROCKS)
	_piece("Pebble_Square_2", Vector3(4.6, 0.02, -1.2), 0.0, gallery, ROCKS)
	_piece("Torch_Metal", Vector3(0.9, 0, -2.2), 0.0, gallery, PROPS)


## SÉCHOIR : abri ouvert où sèchent sacs et toiles avant descente à la vallée.
## Couverture de brique inclinée sur poteaux — pas un bardeau.
func _build_drying_shed(parent: Node3D) -> void:
	var shed: Node3D = Node3D.new()
	shed.name = "Sechoir"
	parent.add_child(shed)
	shed.position = Vector3(6.5, 0, 8.0)
	for corner: Vector3 in [Vector3(-2.2, 0, -1.6), Vector3(2.2, 0, -1.6),
			Vector3(-2.2, 0, 1.6), Vector3(2.2, 0, 1.6)]:
		_piece("Prop_Support", corner, 0.0, shed)
		_wall_collider(shed, corner + Vector3(0, 1.6, 0),
			Vector3(0.45, 3.2, 0.45))
	for ix: int in [-1, 1]:
		_piece("Overhang_RoofIncline_UnevenBricks",
			Vector3(float(ix) * MODULE * 0.5, 3.2, 0), 0.0, shed)
	_piece("Overhang_UnevenBrick_Long", Vector3(0, 3.2, -1.7), 0.0, shed)
	# Les claies : cordes tendues, toiles et sacs suspendus.
	_piece("Rope_1", Vector3(0, 2.2, -0.9), 0.0, shed, PROPS)
	_piece("Rope_1", Vector3(0, 2.2, 0.9), 0.0, shed, PROPS)
	_piece("Banner_1_Cloth", Vector3(-1.2, 2.1, -0.9), 0.0, shed, PROPS)
	_piece("Banner_2_Cloth", Vector3(1.1, 2.1, 0.9), 0.0, shed, PROPS)
	_piece("Bag", Vector3(-1.6, 0.05, 0.6), 30.0, shed, PROPS)
	_piece("Pouch_Large", Vector3(1.5, 0.05, -0.8), 200.0, shed, PROPS)
	_piece("FarmCrate_Empty", Vector3(0.2, 0.05, 1.3), 15.0, shed, PROPS)


## COUR À MINERAI : les caisses ferrées, les pioches, le brut trié. C'est ce
## quartier qui dit le métier depuis le portail.
func _build_ore_yard(parent: Node3D) -> void:
	var yard: Node3D = Node3D.new()
	yard.name = "CourDeMinerai"
	parent.add_child(yard)
	yard.position = Vector3(3.0, 0, -7.0)
	_piece("Crate_Metal", Vector3(0, 0.05, 0), 0.0, yard, PROPS)
	_piece("Crate_Metal", Vector3(1.4, 0.05, 0.5), 20.0, yard, PROPS)
	_piece("Crate_Metal", Vector3(0.4, 0.05, 1.7), 340.0, yard, PROPS)
	_piece("Crate_Wooden", Vector3(2.6, 0.05, -0.6), 12.0, yard, PROPS)
	_piece("Barrel", Vector3(-1.6, 0.05, 1.2), 0.0, yard, PROPS)
	_piece("Bucket_Metal", Vector3(-1.2, 0.05, -0.4), 0.0, yard, PROPS)
	_piece("Pickaxe_Bronze", Vector3(-2.2, 0.05, 0.2), 300.0, yard, PROPS)
	_piece("Pickaxe_Bronze", Vector3(-2.0, 0.05, -1.1), 20.0, yard, PROPS)
	_piece("Chain_Coil", Vector3(2.2, 0.05, 1.6), 0.0, yard, PROPS)
	_piece("Anvil_Log", Vector3(3.4, 0.05, 1.4), 45.0, yard, PROPS)
	_piece("Prop_Brick1", Vector3(-2.8, 0.05, 2.4), 25.0, yard)
	_piece("Rock_Medium_3", Vector3(-3.6, 0, -2.0), 15.0, yard, ROCKS)
	_piece("Pebble_Square_2", Vector3(1.0, 0.02, -1.8), 0.0, yard, ROCKS)


## PALISSADE : elle ferme la cour au sud, à l'est et au nord ; à l'ouest, la
## falaise elle-même fait mur (les rangs viennent buter contre le rocher, à
## x = −80 en repère monde). Portail ouvert au SUD-EST, côté vallée : on
## entre, et surtout on ressort (§15.11 — jamais de clôture qui enferme).
func _build_palisade(parent: Node3D) -> void:
	var fence: Node3D = Node3D.new()
	fence.name = "Palissade"
	parent.add_child(fence)
	# Portail : deux modules retirés, soit 4 m de passage franc. Les rangs
	# partent de x = −12 par pas de 2 m, donc les modules 10 et 11 couvrent
	# x = 7 à 11 — l'axe du chemin qui monte de la vallée.
	var gate: Array[int] = [10, 11]
	var no_gap: Array[int] = []
	_fence_row(fence, "Prop_WoodenFence_Extension1", Vector3(-12.0, 0, -10.0),
		Vector3(MODULE, 0, 0), 12, 0.0, gate)
	# Est : le retour vers le nord — c'est ce rang qui ferme les deux angles.
	_fence_row(fence, "Prop_WoodenFence_Extension1", Vector3(12.0, 0, -10.0),
		Vector3(0, 0, MODULE), 12, 90.0, no_gap)
	# Nord : le fond de la cour.
	_fence_row(fence, "Prop_WoodenFence_Extension2", Vector3(-12.0, 0, 12.0),
		Vector3(MODULE, 0, 0), 12, 0.0, no_gap)
	# Deux jalons de portail, pour qu'il se voie de loin.
	for side: float in [-1.0, 1.0]:
		_piece("Prop_WoodenFence_Single",
			Vector3(9.0 + side * 2.0, 0, -10.0), 0.0, fence)
		_wall_collider(fence, Vector3(9.0 + side * 2.0, 0.85, -10.0),
			Vector3(0.6, 1.7, 0.5))
	_piece("Banner_2", Vector3(11.6, 0, -10.4), 0.0, fence, PROPS)


# --- Déclaration au journal des découvertes ---------------------------------

## Chaque hameau se DÉCLARE : identifiant stable §19.3, nom affiché, région.
## Le volume d'approche est large (le lieu se découvre en y arrivant, pas en
## marchant sur un point précis) mais reste borné à l'emprise du hameau.
func _make_poi(parent: Node3D, poi_id: StringName, label: String,
		region: StringName, centre: Vector3, size: Vector3) -> PointOfInterest:
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "PointDInteret"
	poi.poi_id = poi_id
	poi.display_name = label
	poi.region = region
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	poi.add_child(shape)
	poi.position = centre
	parent.add_child(poi)
	RewardAnchor.attach_from_table(parent, poi_id, ANCHORS, "hameaux")
	return poi
