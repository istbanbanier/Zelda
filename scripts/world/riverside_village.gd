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

## Assise de la vitre `Window_Wide_Round1`, MESURÉE sur le .gltf :
## sa géométrie commence à y = +1,016 (bbox y 1,016 → 2,742). `KitPlacement.seat()`
## rabaisse tout modèle dont le bas est au-dessus de son ancrage : demander
## exactement 1,016 annule donc la correction et laisse la vitre pile dans la
## baie percée du mur (trou mesuré : x ±0,60, y 1,04 → 2,61).
const GLASS_SILL_Y: float = 1.016

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
	# §3 : le kit végétal est importé sans normalisation d'échelle ; la
	# correction mesurée vit dans `KitScale`, en un seul point.
	var corrected: float = KitScale.factor(asset)
	if not is_equal_approx(corrected, 1.0):
		node.scale = Vector3.ONE * corrected
	node.rotation_degrees = Vector3(0, yaw_deg, 0)
	# « Rien ne flotte » : une partie du kit a son origine SOUS sa
	# géométrie (Prop_Support commence à +1,21 m). Sans cette
	# correction, l'objet est suspendu en l'air. Voir KitPlacement.
	KitPlacement.seat(node, node.scene_file_path)
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


## VITRE d'une baie de fenêtre. Purement visuelle : aucune collision n'est
## ajoutée, le mur porteur pose déjà la sienne — une fenêtre ne se traverse pas
## pour autant, le collider du mur est plein sur toute sa largeur.
##
## `at` est la position du MUR : la vitre reprend son plan, son yaw et son
## niveau ; seule l'assise dans le mur s'y ajoute (GLASS_SILL_Y).
func _glass(parent: Node3D, at: Vector3, yaw: float) -> void:
	_piece("Window_Wide_Round1",
		Vector3(at.x, at.y + GLASS_SILL_Y, at.z), yaw, parent)


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
			# DÉFAUT CORRIGÉ : la baie du mur est un TROU réel (1,20 × 1,57 m
			# mesurés dans le maillage) et la vitre du kit n'était posée nulle
			# part — on voyait à travers la maison. Voir GLASS_SILL_Y.
			_glass(inn, Vector3(x, 0, half + MODULE * 0.5), 0.0)
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
		if iz == 0:
			_glass(inn, Vector3(-half - MODULE * 0.5, 0, z), 90.0)
			_glass(inn, Vector3(half + MODULE * 0.5, 0, z), 270.0)

	# DÉFAUT CORRIGÉ : aucun poteau d'angle. L'épaisseur du mur n'est pas
	# centrée sur son plan (bbox z −0,314 → +0,092) : à chaque angle, les deux
	# murs se croisaient en laissant une fente ouverte sur toute la hauteur
	# (3,12 m). Même geste qu'à hamlets.gd:296 pour la cabane, même trame 6 × 6.
	for corner: Vector3 in [Vector3(-3, 0, -3), Vector3(3, 0, -3),
			Vector3(-3, 0, 3), Vector3(3, 0, 3)]:
		_piece("Corner_Exterior_Wood", corner, 0.0, inn)

	_gabled_roof(inn, 6, Vector3(0, WALL_H, 0))
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

	# DÉFAUT CORRIGÉ : l'atelier n'avait pas de sol, l'enclume était posée dans
	# l'herbe. Six dalles de 2 × 2 m couvrent exactement l'emprise des deux
	# murs : x −2 → +2 et z −3 → +3.
	for fx: int in [-1, 1]:
		for fz: int in [-1, 0, 1]:
			_piece("Floor_UnevenBrick",
				Vector3(fx * MODULE * 0.5, 0.02, fz * MODULE), 0.0, forge)

	# DÉFAUT CORRIGÉ : la couverture était UNE planche `Roof_Wooden_2x1_Center`
	# de 2,00 × 1,50 m (3 m² mesurés), suspendue au-dessus d'un abri de 4 × 6 m
	# (24 m²) sans toucher aucun mur — 12 % de couverture, et rien dessous.
	# `Roof_RoundTiles_4x6` est taillé pour cette emprise exactement : bbox
	# x ±2,757 (4 m de portée + 0,76 d'égout) et z ±3,786 (6 m + 0,79). Sa
	# faîtière court sur Z, comme tous les toits du kit : les triangles ouverts
	# sont donc aux deux BOUTS, en z = ±3, et c'est là que va le pignon.
	_piece("Roof_RoundTiles_4x6", Vector3(0, WALL_H, 0), 0.0, forge)
	# Pignon nord : posé sur le mur (mur z −3,092 → −2,686, pignon −3,794 → −2,665).
	_piece("Roof_Front_Brick4", Vector3(0, WALL_H, -MODULE * 1.5), 180.0, forge)
	# Pignon sud : ferme le triangle au-dessus de la façade OUVERTE. Il occupe
	# y 2,99 → 6,06, très au-dessus de l'arase (3,12) : le passage reste libre,
	# l'appentis garde sa façade ouverte (par design, §ligne 195).
	_piece("Roof_Front_Brick4", Vector3(0, WALL_H, MODULE * 1.5), 0.0, forge)
	# Poutre de rive sous l'égout est, le côté ouvert sur la place : 5,49 m de
	# long, elle court sur la travée. Même emploi qu'à hamlets.gd:306.
	_piece("Roof_FrontSupports", Vector3(MODULE, WALL_H - 0.2, 0.0), 90.0, forge)
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
	# DÉFAUT CORRIGÉ : la tour était bâtie 4 m × 2 m — faces avant/arrière au
	# plan z = ±1 et UNE seule pièce de 2 m par face latérale, pour un côté de
	# 4 m. Le chapeau `Roof_Tower_RoundTiles` (bbox x ±2,825, z ±2,714) est
	# taillé pour une tour de 4 × 4 : il débordait de 1,71 m dans le vide au
	# nord et au sud, et on voyait l'intérieur creux par-dessus l'arase.
	# Reprise de la trame des habitations : plans à ±MODULE, deux pièces par
	# face, 8 modules par niveau — emprise 4 × 4 m.
	for level: int in range(2):
		var y: float = float(level) * WALL_H
		for ix: int in [-1, 1]:
			_wall(mill, Vector3(ix * MODULE * 0.5, y, MODULE), 0.0,
				"Wall_UnevenBrick_Straight")
			_wall(mill, Vector3(ix * MODULE * 0.5, y, -MODULE), 180.0,
				"Wall_UnevenBrick_Straight")
			for iz: int in [-1, 1]:
				_wall(mill, Vector3(ix * MODULE, y, iz * MODULE * 0.5),
					90.0 if ix < 0 else 270.0, "Wall_UnevenBrick_Straight")
		# Poteaux d'angle : même fente de 9 cm qu'à l'auberge, sur deux niveaux.
		for cx: int in [-1, 1]:
			for cz: int in [-1, 1]:
				_piece("Corner_Exterior_Wood",
					Vector3(cx * MODULE, y, cz * MODULE), 0.0, mill)
	# Le chapeau ne bouge pas : sa jupe (bbox min y −0,572) descend à 5,668 et
	# recouvre de 0,57 m l'arase du 2e niveau (6,243) sur les QUATRE faces,
	# avec 0,80 m d'égout régulier.
	_piece("Roof_Tower_RoundTiles", Vector3(0, WALL_H * 2.0, 0), 0.0, mill)


## Toit à deux pans FERMÉ. Un toit sans pignons laisse un triangle ouvert à
## chaque bout : le joueur voit sous les tuiles, et la maison n'est plus une
## maison. Le kit fournit `Roof_Front_Brick4/6/8` pour cela ; ils n'étaient
## posés nulle part. On les pose donc AVEC le toit, jamais séparément — un
## seul appel, impossible à oublier.
##
## `span` est le côté couvert en mètres (4, 6 ou 8).
##
## AXE MESURÉ, PAS SUPPOSÉ : tous les `Roof_RoundTiles_*` du kit ont leur
## faîtière parallèle à Z — hauteur constante le long de z, profil triangulaire
## le long de x. Les triangles ouverts sont donc en z = ±span/2, et le pignon
## s'y pose à yaw 0 et 180. Une première version les avait mis sur l'axe X :
## les vrais triangles restaient ouverts ET deux panneaux de brique
## transperçaient les versants. Vérifié au relevé de sommets du .gltf.
func _gabled_roof(parent: Node3D, span: int, at: Vector3,
		gable_on_z: bool = true) -> void:
	_piece("Roof_RoundTiles_%dx%d" % [span, span], at, 0.0, parent)
	var front: String = "Roof_Front_Brick%d" % span
	var half: float = float(span) * 0.5
	for side: int in [-1, 1]:
		var offset: Vector3 = Vector3(0, 0, half * float(side)) if gable_on_z \
			else Vector3(half * float(side), 0, 0)
		var yaw: float = 0.0
		if gable_on_z:
			yaw = 0.0 if side > 0 else 180.0
		else:
			yaw = 270.0 if side > 0 else 90.0
		_piece(front, at + offset, yaw, parent)


## SANCTUAIRE : petit, ouvert, sur la hauteur du village.
func _build_shrine() -> void:
	var shrine: Node3D = Node3D.new()
	shrine.name = "Sanctuaire"
	add_child(shrine)
	shrine.position = Vector3(-14.0, 0, 8.0)
	# DÉFAUT CORRIGÉ : l'unique mur était au plan z = −1, hors trame. Le toit
	# 4x4 posé au centre couvre z −2,740 → +2,822 : le mur était donc 1,74 m en
	# retrait de son propre égout, et le pignon arrière (z = −2) flottait un
	# mètre derrière lui. Au plan z = −MODULE, le mur (z −2,092 → −1,686) passe
	# exactement SOUS le pignon (z −2,794 → −1,665), comme partout ailleurs.
	for ix: int in [-1, 1]:
		_wall(shrine, Vector3(ix * MODULE * 0.5, 0, -MODULE), 180.0,
			"Wall_Plaster_Straight")
	_gabled_roof(shrine, 4, Vector3(0, WALL_H, 0))
	# L'édicule est OUVERT sur trois côtés par design — mais un toit ouvert
	# repose sur des appuis visibles. Poutre de rive de 5,49 m sous l'égout de
	# la façade libre (z = +2), même emploi qu'à hamlets.gd:306.
	_piece("Roof_FrontSupports", Vector3(0, WALL_H - 0.2, MODULE), 0.0, shrine)
	# Les deux props suivent le mur d'un mètre : ils étaient posés contre lui.
	_piece("CandleStick", Vector3(0, 0.05, -1.6), 0.0, shrine, PROPS)
	_piece("Banner_1", Vector3(-1.4, 0.05, -1.8), 0.0, shrine, PROPS)


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
			# DÉFAUT CORRIGÉ : baies jamais vitrées — deux trous de 1,20 ×
			# 1,57 m par maison, par lesquels on voyait l'herbe du terrain à
			# l'intérieur et l'envers des tuiles au-dessus.
			_glass(house, Vector3(ix * MODULE * 0.5, 0, MODULE), 0.0)
			_wall(house, Vector3(ix * MODULE * 0.5, 0, -MODULE), 180.0,
				"Wall_Plaster_Straight")
			# DÉFAUT CORRIGÉ : une seule pièce de 2 m ne fermait que le
			# milieu d'un côté de 4 m — la maison restait ouverte d'un mètre
			# à chaque bout, et on voyait au travers.
			for iz: int in [-1, 1]:
				_wall(house, Vector3(ix * MODULE, 0, iz * MODULE * 0.5),
					90.0 if ix < 0 else 270.0, "Wall_Plaster_Straight")
			# Poteaux d'angle : sans eux, une fente ouverte de haut en bas
			# aux quatre angles — l'épaisseur du mur n'est pas centrée sur
			# son plan (bbox z −0,314 → +0,092).
			for cz: int in [-1, 1]:
				_piece("Corner_Exterior_Wood",
					Vector3(ix * MODULE, 0, cz * MODULE), 0.0, house)
			# DÉFAUT CORRIGÉ : la maison n'avait aucun sol — par la baie on
			# voyait l'herbe du terrain à l'intérieur. Quatre dalles de
			# 2 × 2 m couvrent exactement x −2 → +2 et z −2 → +2.
			for fz: int in [-1, 1]:
				_piece("Floor_WoodDark",
					Vector3(ix * MODULE * 0.5, 0.02, fz * MODULE * 0.5),
					0.0, house)
		_gabled_roof(house, 4, Vector3(0, WALL_H, 0))
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
	# DÉFAUT CORRIGÉ, deux fautes dans la même ligne. (1) Le module descend vers
	# son +z LOCAL : relevé des sommets, la marche haute est en z = −1 (y =
	# 1,000) et la basse en z = +1 (y = 0,000). Posé à yaw 0 il grimpait donc
	# vers la rivière alors que l'ensemble descendait — trois volées retournées.
	# (2) Il rachète 1,00 m par volée, pas 1,2 : au joint, 1,00 contre −1,20
	# laissait 2,20 m de vide sec, deux fois de suite. Chaînage vérifié à
	# yaw 180 : (z −20 ; y +1,00) → (z −22 ; y 0,00) → (z −24 ; y −1,00) →
	# (z −26 ; y −2,00), continu, et z = −26 tombe sur le lit de rivière.
	for i: int in range(3):
		_piece("Stairs_Exterior_Straight_L",
			Vector3(-2.0, -float(i) * 1.0, -21.0 - float(i) * 2.0), 180.0,
			square)


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
