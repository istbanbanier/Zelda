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
	node.position = at
	# §3 : le kit végétal est importé sans normalisation d'échelle ; la
	# correction mesurée vit dans `KitScale`, en un seul point.
	var corrected: float = KitScale.factor(asset)
	if not is_equal_approx(corrected, 1.0):
		node.scale = Vector3.ONE * corrected
	node.rotation_degrees = Vector3(tilt_deg.x, yaw_deg + tilt_deg.y, tilt_deg.z)
	# « Rien ne flotte » : une partie du kit a son origine SOUS sa
	# géométrie (Prop_Support commence à +1,21 m). Sans cette
	# correction, l'objet est suspendu en l'air. Voir KitPlacement.
	KitPlacement.seat(node, node.scene_file_path)
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


## TOITURE DE BARDEAUX à deux pans, montée par RANGS CHAÎNÉS.
##
## CE QUI ÉTAIT FAUX. La cabane et la scierie posaient leurs rangs au pas de
## 2 m (`MODULE`) et TOUS À LA MÊME HAUTEUR. Or le module de bardeaux ne fait
## pas 2 m de profondeur. Mesuré par `tools/gltf_inspect.py` sur
## `Roof_Wooden_2x1_Center.gltf` : bbox z [0 ; 1,499], y [-0,1453 ; 1,0622] —
## soit 1,499 m de PROFONDEUR pour 1,2075 m de MONTÉE. Conséquences :
##   - il manquait un tiers de la couverture (une bande de 1 m au-dessus du
##     mur bas, et deux fentes de 0,50 m entre les rangs) : on voyait le ciel
##     depuis l'intérieur ;
##   - chaque rang redescendait à la hauteur du précédent, donc ce n'était pas
##     une pente mais trois appentis en escalier séparés de 1,20 m.
##
## CE QUI EST POSÉ ICI. Deux pans qui se rejoignent au faîte, chacun monté par
## deux rangs chaînés : pas de 1,47 m en z (1,499 m moins 3 cm de
## recouvrement, pour ne laisser aucune fente) et +1,20 m en y, exactement la
## montée mesurée du module. Le pan sud est tourné à yaw 180 ; à cette
## rotation le débord latéral de `_L` bascule côté intérieur, il faut donc
## INTERVERTIR `_L` et `_R` — sinon les deux débords tombent du même côté.
##
## `eave_y` est la hauteur de l'égout (bord bas), `eave_z` la demi-profondeur
## couverte. Le faîte se retrouve en x, à `eave_y + 2 × 1,2075`.
func _shingle_gable_roof(parent: Node3D, eave_y: float, eave_z: float) -> void:
	for pan: int in [-1, 1]:
		var yaw: float = 0.0 if pan < 0 else 180.0
		var west: String = "Roof_Wooden_2x1_L" if pan < 0 else "Roof_Wooden_2x1_R"
		var east: String = "Roof_Wooden_2x1_R" if pan < 0 else "Roof_Wooden_2x1_L"
		for course: int in range(2):
			var z0: float = float(pan) * (eave_z - float(course) * 1.47)
			var y0: float = eave_y + float(course) * 1.20
			_piece(west, Vector3(-MODULE, y0, z0), yaw, parent)
			_piece("Roof_Wooden_2x1_Center", Vector3(0.0, y0, z0), yaw, parent)
			_piece(east, Vector3(MODULE, y0, z0), yaw, parent)


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
	# (le village), ni terrasse plate (le poste minier). Emprise à couvrir :
	# murs à z = ±3 -> deux pans de 2,95 m depuis l'égout, faîte à z ≈ 0.
	# Voir `_shingle_gable_roof` pour le détail de la mesure.
	_shingle_gable_roof(cabin, WALL_H, 2.95)
	# LIMITE ASSUMÉE, à ne pas masquer : les deux bouts du toit (faces x = ±3,
	# 6,00 m de base et 2,26 m de flèche) restent des triangles OUVERTS. Le kit
	# ne contient AUCUN pignon de la famille bardeaux : les seules pièces de
	# fermeture sont `Roof_Front_Brick4/6/8`, taillées pour la pente des tuiles
	# rondes (mesuré : `Roof_Front_Brick6` monte de 4,38 m sur 6,69 m de base,
	# contre 2,26 m sur 6,00 m ici, soit presque le double). Poser l'une d'elles
	# serait un faux pignon, visiblement décalé. C'est un trou du KIT, pas du
	# code ; on ne bricole pas, on le signale.
	#
	# Le faîte est désormais en X, à y = 5,38 (2,975 + 2 × 1,2075). `Roof_Log`
	# était posé yaw 0, donc EN TRAVERS de la pente, et à 4,02 m il ne touchait
	# rien : mesuré 10,696 m de long dans son axe Z local (bbox z ±5,348), il
	# dépassait de 2,35 m au-delà de chaque mur, dans le vide, à 4–5,4 m de
	# haut. À yaw 90 il devient une vraie faîtière, à cheval sur le sommet des
	# deux pans (son dessous, bbox y min 3,849 après assise, tombe à 5,20).
	# Le débord de 2,35 m subsiste mais passe du mauvais axe au bon : le kit
	# n'a pas de rondin plus court.
	_piece("Roof_Log", Vector3(0, 5.20, 0), 90.0, cabin)
	# La souche démarrait à WALL_H + 0,6 = 3,72 m, soit 26 cm AU-DESSUS du
	# rampant, et culminait 2,7 m au-dessus du faîte : la valeur venait du
	# village, dont le toit est deux fois plus haut. `Prop_Chimney` mesure
	# 3,178 m et son origine est à sa base (bbox y min = 0, aucune assise à
	# corriger) : posée à 2,52 m elle traverse la couverture et ne dépasse
	# plus que de 0,32 m au-dessus du faîte.
	_piece("Prop_Chimney", Vector3(1.6, WALL_H - 0.60, -1.4), 0.0, cabin)
	# `Roof_FrontSupports` est une POUTRE DE RIVE horizontale (mesurée
	# 5,486 × 0,231 × 0,655), pas un pignon. Posée à (0 ; 2,92 ; 3,1) elle
	# occupait z ∈ [3,07 ; 3,73] et y ∈ [2,80 ; 3,03] : hors du toit ET hors du
	# mur, elle ne touchait rien. Recalée sous l'égout sud : son dessus
	# (pos.y + 0,113 = 2,973) affleure le dessous des bardeaux (2,975) et son
	# emprise z ∈ [2,29 ; 2,95] reste sous la couverture.
	_piece("Roof_FrontSupports", Vector3(0, 2.86, 2.32), 0.0, cabin)

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

	# Écran de planches au nord. `Floor_WoodDark` mesure 2 × 2 m ; couché par
	# le tilt Rx(90) chaque rang couvre 2 m de HAUT. Les deux rangs montaient
	# à 4,00 m, alors que l'égout de la couverture corrigée est à 2,86 : le
	# haut de l'écran dépassait le toit de plus d'un mètre. Le rang haut passe
	# donc de y = 3,0 à y = 2,0, l'écran s'arrête à 3,00 m, au ras de la rive.
	# Le mètre de recouvrement entre les deux rangs est décalé de 2 cm en z
	# (−3,02 au lieu de −3,00) : deux planches coplanaires se battraient en
	# profondeur ; à 2 cm d'écart elles se lisent comme un clin.
	for ix: int in range(-1, 2):
		var x: float = ix * MODULE
		_piece("Floor_WoodDark", Vector3(x, 1.0, -3.0), 0.0, mill, "",
			Vector3(90, 0, 0))
		_piece("Floor_WoodDark", Vector3(x, 2.0, -3.02), 0.0, mill, "",
			Vector3(90, 0, 0))
	# Collision alignée sur le visible (3,00 m et non plus 4,00 m).
	_wall_collider(mill, Vector3(0, 1.5, -3.01), Vector3(6.4, 3.0, 0.42))

	# Quatre poteaux porteurs. `Prop_Support` N'EST PAS un poteau : mesuré
	# bbox x ±0,099, y [1,2114 ; 2,920], z [-0,118 ; 1,918], c'est une JAMBE
	# DE FORCE diagonale de 1,709 m de haut et 0,20 m d'épaisseur une fois
	# assise. La couverture était à 3,90 m : 2,05 m de vide au-dessus du
	# sommet réel des « poteaux ». Et les colliders déclaraient 3,60 m, soit
	# 2,1× la hauteur du maillage — on se cognait dans l'air.
	# `Corner_Exterior_Wood` est le seul montant pleine hauteur du kit à
	# origine correcte : mesuré 0,210 × 3,000 × 0,240, bbox y min = 0.
	for corner: Vector3 in [Vector3(-3, 0, -2.8), Vector3(3, 0, -2.8),
			Vector3(-3, 0, 2.8), Vector3(3, 0, 2.8)]:
		_piece("Corner_Exterior_Wood", corner, 0.0, mill)
		_wall_collider(mill, corner + Vector3(0, 1.5, 0),
			Vector3(0.3, 3.0, 0.3))
	# Couverture de bardeaux, calée sur la tête des nouveaux poteaux (3,00 m).
	# Elle posait ses rangs au pas de 2 m et tous à plat, comme la cabane :
	# même correction, deux pans chaînés. Emprise : de l'écran (z = −3) au
	# poteau sud (z = +2,8), couverte de −2,90 à +2,90.
	_shingle_gable_roof(mill, 3.00, 2.90)

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
	# Deux billes en attente de refente. Couchée par le tilt Rz(90), la pièce
	# n'est plus assise par `KitPlacement` (la composante Y de la correction
	# devient nulle sous cette rotation) : son décalage interne subsiste, et
	# le modèle se retrouve entièrement À CÔTÉ du point demandé — monde
	# x ∈ [pos.x − 2,920 ; pos.x − 1,211], z ∈ [pos.z − 0,118 ; pos.z + 1,918].
	# On compense donc +2,065 en x et −0,900 en z pour recentrer la géométrie
	# sur le point voulu. Les deux billes étaient en outre posées à 0,70 m
	# l'une de l'autre alors qu'elles mesurent 2,036 m dans l'axe z : elles se
	# traversaient et la seconde débordait de 1,52 m hors du plancher. Elles
	# sont désormais EMPILÉES (l'épaisseur réelle est de 0,199 m), au même
	# endroit, entièrement sur le plancher (z ∈ [0,88 ; 2,92]).
	_piece("Prop_Support", Vector3(2.265, 0.30, 1.00), 0.0, mill, "",
		Vector3(0, 0, 90))
	_piece("Prop_Support", Vector3(2.265, 0.50, 1.00), 0.0, mill, "",
		Vector3(0, 0, 90))


## TRONCS EMPILÉS : deux piles pyramidales, franches et solides. Elles font
## obstacle — un tas de bois qu'on traverse n'est qu'une image.
func _build_log_stacks(parent: Node3D) -> void:
	var stacks: Node3D = Node3D.new()
	stacks.name = "PileDeTroncs"
	parent.add_child(stacks)
	stacks.position = Vector3(5.0, 0, 9.0)
	var bases: Array[Vector3] = [Vector3.ZERO, Vector3(0, 0, 4.4)]
	# CE QUI ÉTAIT FAUX, mesuré pièce par pièce sur `Prop_Support` couché par
	# le tilt Rz(90) — qui envoie le local (x, y, z) sur le monde (−y, x, z) :
	#  (a) `KitPlacement.seat` ne s'applique plus sous cette rotation, donc le
	#      décalage interne du modèle subsiste : chaque « tronc » occupait
	#      monde x ∈ [pos.x − 2,920 ; pos.x − 1,211], entièrement à CÔTÉ du
	#      point demandé -> +2,065 en x recentre la géométrie ;
	#  (b) en z la pièce s'étend de −0,118 à +1,918 autour du point -> −0,900
	#      la recentre aussi ;
	#  (c) les trois pièces d'un lit étaient à z = −1 / 0 / +1 alors que
	#      chacune mesure 2,036 m en z : 1,00 m d'interpénétration entre
	#      voisines -> deux pièces par lit, écartées de 2,04 m, bout à bout ;
	#  (d) couchée, la pièce ne fait que 0,199 m d'épaisseur, or les lits
	#      étaient espacés de 0,65 m : 0,45 m d'air entre chaque lit -> pas de
	#      0,20 m, l'épaisseur réelle, les lits se touchent.
	# ÉCART ASSUMÉ avec le relevé : il proposait le lit du milieu à z = ±0,51,
	# ce qui rouvre 1,02 m d'interpénétration (le défaut (c) qu'il corrige par
	# ailleurs). Les deux lits bas sont donc au même pas bout à bout, et c'est
	# le lit du haut, seul et centré, qui donne la silhouette pyramidale.
	for base: Vector3 in bases:
		for z: float in [-1.02, 1.02]:
			_piece("Prop_Support", base + Vector3(2.065, 0.30, z - 0.90), 0.0,
				stacks, "", Vector3(0, 0, 90))
		for z: float in [-1.02, 1.02]:
			_piece("Prop_Support", base + Vector3(2.065, 0.50, z - 0.90), 0.0,
				stacks, "", Vector3(0, 0, 90))
		_piece("Prop_Support", base + Vector3(2.065, 0.70, -0.90), 0.0, stacks,
			"", Vector3(0, 0, 90))
		# Collision recalée sur le bois réellement présent : x ∈ [−0,86 ; 0,85],
		# y ∈ [0,20 ; 0,80], z ∈ [−2,04 ; 2,04]. L'ancienne boîte 4,2 × 2,0 × 2,8
		# avait sa moitié +X dans le vide et laissait 0,82 m de bois hors
		# collision en −X.
		_wall_collider(stacks, base + Vector3(0, 0.40, 0),
			Vector3(1.80, 0.80, 4.20))
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
	# `Corner_Exterior_Brick` est une pièce EN L, pas un poteau symétrique :
	# mesuré bbox x [-0,3529 ; 0,1777], z [-0,1991 ; 0,3767], ses deux branches
	# filent l'une vers −x, l'autre vers +z. Elle n'habille donc correctement
	# que l'angle où un mur part en −x et l'autre en +z, c'est-à-dire (+3, −3).
	# Les quatre exemplaires étaient posés à yaw 0 : TROIS ANGLES SUR QUATRE
	# recevaient la pièce retournée, branches dans le vide et épaisseur rentrée
	# dans la pièce au lieu de couvrir l'arête. Chaque angle reçoit désormais
	# son yaw ; à yaw 90 les branches deviennent (+z, +x), à 180 (+x, −z), à
	# 270 (−z, −x). (La cabane des bûcherons n'est pas concernée :
	# `Corner_Exterior_Wood` est symétrique, mesuré x ±0,105, z ±0,120.)
	var brick_corners: Array[Array] = [
		[Vector3(3, 0, -3), 0.0], [Vector3(-3, 0, -3), 90.0],
		[Vector3(-3, 0, 3), 180.0], [Vector3(3, 0, 3), 270.0],
	]
	for entry: Array in brick_corners:
		_piece("Corner_Exterior_Brick", entry[0] as Vector3, entry[1] as float,
			house)

	# TOIT-TERRASSE : des dalles de brique posées à plat, ceinturées d'un
	# parapet. Silhouette horizontale — l'inverse exact des toitures pentues
	# du bourg et de la cabane des bûcherons.
	for ix: int in range(-1, 2):
		for iz: int in range(-1, 2):
			_piece("Floor_Brick",
				Vector3(ix * MODULE, WALL_H, iz * MODULE), 0.0, house)
	# `Prop_ExteriorBorder_Straight1` est ASYMÉTRIQUE en z : mesuré bbox
	# x ±1,0, y [0 ; 0,134], z [0 ; 0,700] — toute la pièce est du côté +z de
	# son origine. Posées à z = ±3,0, les six bordures nord et sud tombaient
	# donc ENTIÈREMENT hors de la dalle (qui s'arrête à z = ±3), en
	# porte-à-faux de 0,70 m sur le vide. On les rentre à z = ±2,30 : elles
	# couvrent alors z ∈ [2,30 ; 3,00] et [−3,00 ; −2,30], sur la dalle.
	# Les bords est/ouest, eux, tombaient déjà bien (yaw 270/90 renvoient le
	# +z local vers −x/+x) ; seule leur hauteur change.
	# Hauteur : WALL_H + 0,1 = 3,22 laissait 9 cm d'air au-dessus du dessus de
	# la dalle (3,13). WALL_H + 0,01 les y pose.
	for ix: int in range(-1, 2):
		var px: float = ix * MODULE
		_piece("Prop_ExteriorBorder_Straight1",
			Vector3(px, WALL_H + 0.01, 2.30), 0.0, house)
		_piece("Prop_ExteriorBorder_Straight1",
			Vector3(px, WALL_H + 0.01, -2.30), 180.0, house)
	for iz: int in range(-1, 2):
		var pz: float = iz * MODULE
		_piece("Prop_ExteriorBorder_Straight1",
			Vector3(3.0, WALL_H + 0.01, pz), 270.0, house)
		_piece("Prop_ExteriorBorder_Straight1",
			Vector3(-3.0, WALL_H + 0.01, pz), 90.0, house)

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
	# `Wall_Arch` ne mesure que 2,000 × 3,000 × 0,064 m : la façade tenait
	# entière dans un panneau de 6,4 cm large de 2 m, alors que la collision
	# posée plus bas couvre z ∈ [−3,2 ; +3,2], soit 6,4 m. Il y avait donc
	# 4,4 m de mur INVISIBLE de part et d'autre de l'arche. Deux piédroits
	# viennent donner corps à ce qu'on heurte : `Wall_UnevenBrick_Straight`
	# mesure 2,00 × 3,12 × 0,407 m, et à yaw 90 chacun couvre exactement
	# z ∈ [1,0 ; 3,0] et [−3,0 ; −1,0], bord à bord avec l'arche.
	for side: float in [-1.0, 1.0]:
		_piece("Wall_UnevenBrick_Straight", Vector3(0.0, 0, side * 2.0), 90.0,
			gallery)
		# Bandeau de couronnement, posé sur la tête des piédroits (3,1227 m).
		_piece("Prop_ExteriorBorder_Straight1", Vector3(0.0, 3.12, side * 2.0),
			90.0, gallery)
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
	# Mêmes deux erreurs qu'à la scierie. (1) `Prop_Support` ne fait que
	# 1,709 m de haut une fois assis, alors que les colliders déclaraient
	# 3,20 m et que la couverture était posée à 3,20 : 1,49 m de vide au-dessus
	# des « poteaux ». On passe au seul montant pleine hauteur du kit,
	# `Corner_Exterior_Wood` (mesuré 3,000 m, origine à sa base).
	for corner: Vector3 in [Vector3(-2.2, 0, -1.6), Vector3(2.2, 0, -1.6),
			Vector3(-2.2, 0, 1.6), Vector3(2.2, 0, 1.6)]:
		_piece("Corner_Exterior_Wood", corner, 0.0, shed)
		_wall_collider(shed, corner + Vector3(0, 1.5, 0),
			Vector3(0.3, 3.0, 0.3))
	# (2) `Overhang_RoofIncline_UnevenBricks` est une plaque PLATE suspendue
	# SOUS son origine : mesuré bbox x ±1,0, y [−0,3244 ; −0,0586],
	# z [−1,0216 ; +0,4079], soit 2,00 × 1,43 m seulement. Les deux
	# exemplaires posés en z = 0 ne couvraient que 4,00 × 1,43 m d'une emprise
	# de 4,4 × 3,2 m : 55 % du séchoir restait à ciel ouvert. Trois rangs au
	# pas de 1,43 m (la profondeur exacte de la plaque) couvrent désormais
	# z ∈ [−2,45 ; +1,84]. Posée à 3,32, la plaque a son dessous à 3,00 —
	# pile sur la tête des nouveaux poteaux.
	for ix: int in [-1, 1]:
		for pz: float in [-1.43, 0.0, 1.43]:
			_piece("Overhang_RoofIncline_UnevenBricks",
				Vector3(float(ix) * MODULE * 0.5, 3.32, pz), 0.0, shed)
	# `Overhang_UnevenBrick_Long` n'est pas une couverture : mesuré
	# 2,00 × 3,03 × 2,20 m avec bbox y min = 0, c'est un module
	# d'encorbellement PLEINE HAUTEUR. Posé à y = 3,20 il formait un pan de
	# brique de 3 m suspendu en l'air, jusqu'à 6,23 m, visible de toute la
	# cour. Reposé au sol côté nord, il devient le mur de fond du séchoir
	# (y ∈ [0 ; 3,03], z ∈ [−2,80 ; −0,60]) et reçoit sa collision.
	_piece("Overhang_UnevenBrick_Long", Vector3(0, 0.0, -2.6), 0.0, shed)
	_wall_collider(shed, Vector3(0, 1.5, -2.7), Vector3(2.0, 3.0, 0.4))
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
	# Est : le retour vers le nord. Il ne « ferme pas les deux angles » comme
	# l'affirmait le commentaire précédent : au sud-est il tombe dans
	# l'ouverture du portail, et au nord-est c'est le rang nord qui vient le
	# rejoindre (voir plus bas).
	_fence_row(fence, "Prop_WoodenFence_Extension1", Vector3(12.0, 0, -10.0),
		Vector3(0, 0, MODULE), 12, 90.0, no_gap)
	# Nord : le fond de la cour. Le rang comptait 12 modules (x = −12 à +10) ;
	# `Prop_WoodenFence_Extension2` mesurant 2,027 m de large, le dernier
	# s'arrêtait à x = 11,03. Le module d'angle du rang est, lui, occupe
	# x ∈ [11,95 ; 12,06] : il restait 0,92 m SANS PIÈCE NI COLLIDER à l'angle
	# nord-est — une fente par laquelle on voyait et on sortait de l'enceinte
	# (`_fence_row` pose la collision module par module, un module absent est
	# donc aussi un trou de collision). Un 13ᵉ module, à x = +12, couvre
	# x ∈ [11,01 ; 13,03] et croise le rang est en T.
	_fence_row(fence, "Prop_WoodenFence_Extension2", Vector3(-12.0, 0, 12.0),
		Vector3(MODULE, 0, 0), 13, 0.0, no_gap)
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
