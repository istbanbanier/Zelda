## LIEUX NATURELS MÉMORABLES de la Vallée de Néris.
##
## Ordre d'extension §2 : « des lieux naturels mémorables ». §4 en donne le
## critère dur : « plusieurs destinations doivent être perceptibles depuis
## chaque point élevé ». Un lieu n'est donc pas un objet posé sur une plaine —
## c'est une SILHOUETTE qui se voit de loin, ou une composition qui récompense
## le détour. Les cinq lieux retenus jouent chacun sur un registre différent :
##
##   1. `ArbreDoyen`           — masse végétale isolée, visible à 200 m ;
##   2. `SourceAuxReflets`     — bassin turquoise au pied de la falaise ;
##   3. `ChampDeFleurs`        — tache de couleur lue DEPUIS la crête ;
##   4. `ArcheDePierre`        — pont naturel : on passe dessus ET dessous ;
##   5. `BelvedereDuGuetteur`  — sommet panoramique, le point élevé de §4.
##
## Ils sont répartis dans cinq régions distinctes (nord-ouest, pied de falaise,
## sud-ouest, rivière, est) pour que l'exploration garde un rythme : jamais
## deux repères dans le même regard, jamais 200 m de plaine sans rien.
##
## Chaque lieu offre au moins un élément de la liste de §2 — ingrédients
## récoltables, panorama, raccourci, indice environnemental ou fragment
## d'histoire raconté par la composition — et se DÉCLARE au `DiscoveryLog`
## par un `PointOfInterest` d'identifiant §19.3.
##
## RÈGLE DE PALETTE respectée ici : le cyan est RARE (§3.4, réservé à l'énergie
## de Résonance). Le bassin turquoise est une EAU — teinte de la bande
## « ciel/brume/eau », transparente, non émissive. Aucun lieu n'allume de néon.
class_name ValleyLandmarks
extends Node3D

## Le kit d'environnement est réparti sur plusieurs dossiers (le lot « monde
## ouvert » a livré la végétation et les roches, le lot « donjon » les vignes
## et les clôtures). Une pièce se résout donc par RECHERCHE, jamais par chemin
## figé — sinon déplacer un asset casserait un lieu en silence.
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
# pour z de −256 à −4 ; lit de rivière (y = −1,5) entre z = 4 et z = 16 ;
# camp (45, 6, 65) ; pylône (115, 18, −25) ; donjon (0, 34, −210) ; crête de
# départ (0, 24, 170) ; village de la rivière (−70, 2, 36), emprise ±23 m.
#
# Les deux derniers sites sont donnés à y = 0 : leurs constructions portent
# leur propre altitude (tablier du pont, gradins du belvédère), et travailler
# en Y monde évite une double conversion à chaque bloc.

## Plaine nord-ouest, à l'écart des ruines centrales (x de −20 à 18).
const SITE_ANCIENT_TREE: Vector3 = Vector3(-96.0, 2.0, -62.0)
## Pied EST de la falaise d'apprentissage (x de −140 à −80, sommet y = 14),
## au nord de l'emprise du village (qui s'arrête à z = 63).
const SITE_SPRING: Vector3 = Vector3(-72.0, 2.0, 78.0)
## Plaine sud-ouest, sous la crête de départ : le champ se lit d'en haut.
const SITE_FLOWER_FIELD: Vector3 = Vector3(-34.0, 2.0, 112.0)
## Travée de rivière libre : les gués sont à x = 20 et x = 95.
const SITE_STONE_BRIDGE: Vector3 = Vector3(-14.0, 0.0, 10.0)
## Plaine est, seul relief de ce quadrant — la raison d'aller à l'est.
const SITE_OVERLOOK: Vector3 = Vector3(168.0, 0.0, 40.0)

## Hauteur de la surface franchissable du pont naturel.
const BRIDGE_DECK_Y: float = 5.2
## Épaisseur du tablier : le dessous reste à 3,9 m, soit 4,4 m au-dessus de
## l'eau — on passe dessous debout.
const BRIDGE_DECK_THICKNESS: float = 1.3
## Plateforme sommitale du belvédère.
const OVERLOOK_SUMMIT_Y: float = 22.0

## ANCRAGES de récompense (contrat `RewardAnchor`).
##
## Ces positions ne sont pas choisies à l'œil. Elles viennent de
## `tools/godot/probe_reward_anchors.gd`, qui monte la vallée réelle et éprouve
## physiquement, autour de chaque lieu, le sol et le dégagement au gabarit du
## joueur. Les figer ici les rend relisibles, versionnées et vérifiables :
## `RewardAnchorAudit` refait le trajet à chaque suite de tests.
##
## Le belvédère est le seul lieu à GRAVIR : son ancrage est au sommet, son
## pied de traversée sur la plaine, et l'audit exige qu'un corps monte
## réellement l'échine au lieu de croire un navmesh.
const ANCHORS: Dictionary = {
	POI_ANCIENT_TREE: {
		"at": Vector3(2.0, 0.0, 0.0), "approach": Vector3(5.0, 0.0, 0.0),
		"kind": RewardAnchor.Kind.INGREDIENT,
	},
	POI_SPRING: {
		"at": Vector3(-2.49, 0.0, 6.01), "approach": Vector3(-3.64, 0.0, 8.78),
		"kind": RewardAnchor.Kind.INGREDIENT,
	},
	POI_FLOWER_FIELD: {
		"at": Vector3(0.0, 0.0, 0.0), "approach": Vector3(3.0, 0.0, 0.0),
		"kind": RewardAnchor.Kind.INGREDIENT,
	},
	POI_STONE_BRIDGE: {
		"at": Vector3(-1.15, -1.50, 2.77), "approach": Vector3(-2.30, -1.50, 5.54),
		"kind": RewardAnchor.Kind.STORY,
	},
	POI_OVERLOOK: {
		"at": Vector3(0.0, OVERLOOK_SUMMIT_Y, -10.0),
		"approach": Vector3(0.0, OVERLOOK_SUMMIT_Y, -7.0),
		"kind": RewardAnchor.Kind.WEAPON,
		"traversal": true, "base": Vector3(0.0, 2.5, 32.0),
	},
}

## §19.3 : `zone.category.name.index`.
const POI_ANCIENT_TREE: StringName = &"valley.poi.ancient_tree.01"
const POI_SPRING: StringName = &"valley.poi.turquoise_spring.01"
const POI_FLOWER_FIELD: StringName = &"valley.poi.flower_field.01"
const POI_STONE_BRIDGE: StringName = &"valley.poi.stone_bridge.01"
const POI_OVERLOOK: StringName = &"valley.poi.overlook_summit.01"

# --- Champ de fleurs (§7.5 : MultiMesh PARTITIONNÉ) -------------------------

## Quatre cellules de 24 m — la bible interdit un MultiMesh unique couvrant
## toute la vallée, et une cellule reste cullable d'un bloc.
const FIELD_CELLS: int = 2          # 2 × 2 cellules
const FIELD_CELL_SIZE: float = 24.0
## Densité en corolles par m². 0,78 donne ~450 fleurs par cellule : une MASSE
## de couleur lisible depuis la crête, pas une poignée de brins isolés.
const FIELD_DENSITY: float = 0.78
## Rayon d'exclusion autour de l'arbre focal, et demi-largeur du sentier.
const FIELD_TREE_CLEAR: float = 6.0
const FIELD_PATH_HALF: float = 2.4
## Position locale de l'arbre isolé qui donne sa silhouette au champ.
const FIELD_TREE_LOCAL: Vector3 = Vector3(0.0, 0.0, -9.0)

# --- Palette (VISUAL_ASSET_BIBLE §1.4) --------------------------------------

const COL_ROCK: Color = Color(0.61, 0.41, 0.26)          # roche ocre
const COL_ROCK_SHADE: Color = Color(0.44, 0.34, 0.26)    # creux, sous-face
const COL_WATER: Color = Color(0.09, 0.55, 0.60, 0.82)   # même eau que la rivière
const COL_WATER_BED: Color = Color(0.20, 0.30, 0.30)     # fond du bassin
const COL_LEAF: Color = Color(0.36, 0.52, 0.24)          # tiges
## Fleurs blanches / jaunes / bleues (§7.5). Le bleu reste SOMBRE : il ne doit
## pas être confondu avec le cyan de la Résonance.
const COL_PETALS: Array[Color] = [
	Color(0.95, 0.95, 0.91),
	Color(0.91, 0.79, 0.30),
	Color(0.42, 0.56, 0.83),
]

## Points d'intérêt portés par les cinq lieux, dans l'ordre de construction.
var pois: Array[PointOfInterest] = []

var _built: int = 0
var _blooms: int = 0
var _materials: Dictionary = {}


func _ready() -> void:
	_build_ancient_tree()
	_build_spring()
	_build_flower_field()
	_build_stone_bridge()
	_build_overlook()


## Nombre de modèles réellement instanciés (un asset manquant ne compte pas).
func piece_count() -> int:
	return _built


## Nombre total de corolles écrites dans les MultiMesh du champ de fleurs.
func bloom_count() -> int:
	return _blooms


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
func _piece(asset: String, at: Vector3, yaw: float, parent: Node3D,
		factor: float = 1.0) -> Node3D:
	var packed: PackedScene = null
	for pattern: String in ASSET_DIRS:
		var full: String = pattern % asset
		if ResourceLoader.exists(full):
			packed = load(full) as PackedScene
			if packed != null:
				break
	if packed == null:
		push_warning("[lieux] modèle absent du kit : %s" % asset)
		return null
	var node: Node3D = packed.instantiate() as Node3D
	if node == null:
		push_warning("[lieux] modèle illisible : %s" % asset)
		return null
	# Nom unique par construction : Godot renommerait sinon en « @…@ », et un
	# nœud renommé n'est plus retrouvable par un test.
	node.name = "%s_%d" % [asset, _built]
	node.position = at
	node.rotation.y = yaw
	# §3 : correction d'échelle du kit végétal, point unique (`KitScale`).
	var corrected: float = factor * KitScale.factor(asset)
	if not is_equal_approx(corrected, 1.0):
		node.scale = Vector3.ONE * corrected
	# « Rien ne flotte » : une partie du kit a son origine SOUS sa
	# géométrie (Prop_Support commence à +1,21 m). Sans cette
	# correction, l'objet est suspendu en l'air. Voir KitPlacement.
	KitPlacement.seat(node, node.scene_file_path)
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


## Masse de pierre PLEINE : visuel et collision d'un seul bloc. `centre` est le
## centre géométrique, `size` la boîte complète.
func _solid(parent: Node3D, node_name: String, centre: Vector3, size: Vector3,
		colour: Color = COL_ROCK) -> StaticBody3D:
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
	# Position AVANT `add_child` : un corps physique repositionné après son
	# entrée dans l'arbre se téléporte d'une frame.
	body.position = centre
	parent.add_child(body)
	return body


## Fût vertical plein — le tronc de l'arbre doyen : une capsule de collision
## carrée sur un tronc rond se sentirait immédiatement.
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
## centre). C'est ce qui permet de raccorder une pente à un gradin au
## millimètre — un raccord approximatif laisse une marche invisible.
##
## La pente reste sous les 46° franchissables de §8.2 ; l'appelant la choisit.
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
	# Le centre descend d'une demi-épaisseur SOUS la face supérieure, le long
	# de la normale de la pente.
	var centre: Vector3 = (from + to) * 0.5 - (basis * Vector3.UP) * thickness * 0.5
	body.transform = Transform3D(basis, centre)
	parent.add_child(body)
	return body


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
	# L'ancrage naît avec le lieu, pas après coup : un lieu déclaré sans point
	# de récompense est exactement le défaut que ce contrat corrige.
	RewardAnchor.attach_from_table(parent, poi_id, ANCHORS, "repères")
	return poi


## Petit semis de modèles récoltables ou décoratifs autour d'un centre —
## disposition DÉTERMINISTE (angle et rayon dérivés de l'index), pour qu'une
## capture de référence soit rejouable.
func _scatter(parent: Node3D, assets: Array[String], centre: Vector3,
		radius_min: float, radius_max: float, count: int, factor: float,
		seed_offset: float = 0.0) -> void:
	for i: int in range(count):
		var angle: float = TAU * float(i) * 0.618034 + seed_offset
		var span: float = float(i % 5) / 4.0
		var radius: float = radius_min + (radius_max - radius_min) * span
		var at: Vector3 = centre + Vector3(cos(angle) * radius, 0.0,
			sin(angle) * radius)
		var wobble: float = 1.0 + 0.14 * float(i % 3) - 0.07
		_piece(assets[i % assets.size()], at, angle * 1.7, parent,
			factor * wobble)


# ---------------------------------------------------------------------------
# 1. L'ARBRE DOYEN — plaine nord-ouest
# ---------------------------------------------------------------------------
#
# Un seul arbre, très au-dessus de la taille des autres, sur une plaine vide :
# c'est la silhouette la plus économique qui existe pour marquer une distance.
# Le contraste d'échelle fait le travail — cinq arbres ordinaires de 6 à 7 m
# l'entourent, et c'est leur petitesse qui rend le doyen monumental.
#
# Le doyen dépasse la bande « spécimens héros 14-17 m » de la bible : à 21 m il
# reste lisible à 200 m depuis la crête de départ. L'écart est ASSUMÉ ici et
# nulle part ailleurs — c'est un repère, pas un arbre de forêt.
#
# Fragment d'histoire (§2) : un campement abandonné sous la couronne — foyer
# de galets froid, clôture cassée, seau, corde, caisse renversée. Personne ne
# l'explique ; la composition suffit.
# Récolte : champignons à l'ombre, polypores sur le tronc, fougères, trèfles.
func _build_ancient_tree() -> void:
	var place: Node3D = Node3D.new()
	place.name = "ArbreDoyen"
	add_child(place)
	place.position = SITE_ANCIENT_TREE

	# Le doyen (TwistedTree_1 mesure 13,5 × 16,7 m ; à 1,3 il monte à ~21 m).
	_piece("TwistedTree_1", Vector3.ZERO, 0.4, place, 1.3)
	# Tronc PHYSIQUE : on s'y appuie, on s'y abrite, l'IA le contourne.
	_solid_trunk(place, "TroncDoyen", Vector3.ZERO, 1.9, 9.0)

	# Cortège d'arbres ordinaires : ce sont eux qui donnent l'échelle.
	var court: Array[Array] = [
		["CommonTree_2", Vector3(14.0, 0, 6.0), 0.9],
		["CommonTree_3", Vector3(-11.0, 0, 12.0), 0.85],
		["CommonTree_5", Vector3(-15.0, 0, -7.0), 0.95],
		["TwistedTree_3", Vector3(9.0, 0, -14.0), 0.5],
		["CommonTree_1", Vector3(17.0, 0, -4.0), 0.8],
	]
	for entry: Array in court:
		var at: Vector3 = entry[1] as Vector3
		_piece(entry[0] as String, at, at.x * 0.21, place, float(entry[2]))

	# Racines affleurantes : quatre blocs à collision au pied du géant. On y
	# monte au MANTLE (§9.3), pas au pas — voir la mesure ci-dessous.
	var roots: Array[Vector3] = [
		Vector3(5.6, 0, 3.4), Vector3(-4.8, 0, 5.2),
		Vector3(-5.4, 0, -4.6), Vector3(4.2, 0, -5.8),
	]
	# La collision était une boîte unique de 3,40 × 1,10 × 2,80 pour TOUS les
	# blocs, alors que les rochers posés dessus montent bien plus haut. Cotes
	# gltf_inspect × échelle (1,15 / 1,35 / 1,15 / 1,35) : sommets réels à
	# 2,29 / 2,49 / 2,30 / 2,68 m, soit 1,19 à 1,58 m de pierre AU-DESSUS du
	# dessus de la collision — le joueur s'arrêtait à 1,10 m, torse et tête
	# dans le bloc. Les emprises au sol débordaient aussi (jusqu'à 4,35 m pour
	# une boîte de 3,40). Boîtes remesurées une par une, hauteur calée sur le
	# sommet réel et emprise horizontale à ~0,85 × la boîte englobante : la
	# collision ne dépasse jamais la pierre visible. (Les rochers étant tournés
	# et leur maillage n'étant pas centré sur son origine, une lèvre de pierre
	# peut dépasser la boîte d'environ 0,3 m d'un côté ; c'est le sens sûr.)
	var root_box: Array[Vector3] = [
		Vector3(3.2, 2.29, 2.9), Vector3(3.5, 2.49, 2.9),
		Vector3(3.3, 2.30, 3.4), Vector3(3.7, 2.68, 3.4),
	]
	for i: int in range(roots.size()):
		var at: Vector3 = roots[i]
		var box: Vector3 = root_box[i]
		_solid(place, "Racine%d" % i, at + Vector3(0, box.y * 0.5, 0), box,
			COL_ROCK_SHADE)
		_piece("Rock_Medium_%d" % (1 + i % 3), at, float(i) * 1.31, place,
			1.15 + 0.2 * float(i % 2))

	# Récolte à l'ombre (§2 : « ingrédients récoltables »). Les listes passent
	# par des variables TYPÉES : un littéral confié à un paramètre
	# `Array[String]` se convertit mal et échoue à l'exécution, pas au parse.
	var shade: Array[String] = ["Mushroom_Common", "Mushroom_Common",
		"Mushroom_Laetiporus"]
	_scatter(place, shade, Vector3(-2.0, 0, 2.5), 1.8, 6.5, 6, 1.0, 0.6)
	var undergrowth: Array[String] = ["Fern_1", "Plant_7", "Clover_1", "Clover_2"]
	_scatter(place, undergrowth, Vector3.ZERO, 3.5, 9.0, 7, 0.3, 1.9)
	# Polypores accrochés au tronc — la même récolte, mais qu'il faut LEVER
	# les yeux pour voir.
	_piece("Mushroom_Laetiporus", Vector3(1.5, 1.4, 0.2), 1.1, place, 0.9)
	_piece("Mushroom_Laetiporus", Vector3(-1.3, 2.1, 0.9), 2.6, place, 0.7)

	# Le campement abandonné.
	var story: Node3D = Node3D.new()
	story.name = "CampementAbandonne"
	place.add_child(story)
	story.position = Vector3(7.5, 0, 8.5)
	_piece("Crate_Wooden", Vector3(0.0, 0.0, 0.0), 0.7, story, 1.0)
	_piece("Bucket_Wooden_1", Vector3(1.3, 0.0, 0.6), 2.2, story, 1.0)
	_piece("Rope_1", Vector3(0.4, 0.0, 1.5), 1.0, story, 1.0)
	_piece("Prop_WoodenFence_Single", Vector3(-2.4, 0.0, 1.9), 0.35, story, 1.0)
	_piece("Banner_1", Vector3(-3.1, 0.0, -0.8), 0.2, story, 0.9)
	# Foyer froid : huit galets en anneau. Aucune braise, aucune lumière —
	# le feu est mort depuis longtemps, et c'est tout le récit.
	for i: int in range(8):
		var angle: float = TAU * float(i) / 8.0 + 0.2
		_piece("Pebble_Round_%d" % (1 + i % 5),
			Vector3(cos(angle) * 0.85, 0.0, sin(angle) * 0.85) + Vector3(2.2, 0, -1.6),
			angle * 2.3, story, 1.3)

	_declare(place, POI_ANCIENT_TREE, "L'Arbre doyen", &"plaine_nord",
		Vector3(30, 14, 30), Vector3(0, 5, 0))


# ---------------------------------------------------------------------------
# 2. LA SOURCE AUX REFLETS — pied de la falaise d'apprentissage
# ---------------------------------------------------------------------------
#
# Un bassin d'eau claire au pied du mur d'escalade (x = −80, sommet y = 14).
# Deux raisons d'y venir : la récolte humide (fougères, plantes, champignons,
# baies de buisson) et l'INDICE — le ruisseau qui en sort file vers la
# rivière, et les dalles qui montent vers l'ouest désignent la paroi. Le lieu
# dit « on grimpe ici » sans une ligne de texte.
#
# Le turquoise est une EAU, pas un néon : même teinte que le ruban de rivière,
# transparente, rugosité basse, AUCUNE émission. Le cyan reste réservé à la
# Résonance (§3.4 : « moins de 5 % de cyan saturé à l'écran »).
func _build_spring() -> void:
	var place: Node3D = Node3D.new()
	place.name = "SourceAuxReflets"
	add_child(place)
	place.position = SITE_SPRING

	# Fond sombre puis nappe d'eau : deux disques, l'eau LÉGÈREMENT plus
	# petite pour qu'on voie la pierre mouillée de la rive.
	var bed: MeshInstance3D = MeshInstance3D.new()
	bed.name = "FondDuBassin"
	var bed_mesh: CylinderMesh = CylinderMesh.new()
	bed_mesh.top_radius = 5.2
	bed_mesh.bottom_radius = 5.2
	bed_mesh.height = 0.16
	bed.mesh = bed_mesh
	bed.material_override = _material(COL_WATER_BED, 0.95)
	bed.position = Vector3(0, 0.08, 0)
	place.add_child(bed)

	var water: MeshInstance3D = MeshInstance3D.new()
	water.name = "NappeDEau"
	var water_mesh: CylinderMesh = CylinderMesh.new()
	water_mesh.top_radius = 4.8
	water_mesh.bottom_radius = 4.8
	water_mesh.height = 0.44
	water.mesh = water_mesh
	water.material_override = _material(COL_WATER, 0.15, true)
	water.position = Vector3(0, 0.34, 0)
	place.add_child(water)

	# Margelle : dix roches en anneau, chacune à collision — on s'assoit dessus
	# et on en fait le tour. L'anneau est un POINTILLÉ, pas une clôture : les
	# boîtes de `_solid` ne sont pas tournées, et l'écart AABB mesuré entre
	# voisines vaut 0,66 / 1,15 / 1,15 / 0,64 / 1,32 m (× 2 par symétrie) —
	# on peut donc entrer dans le bassin à pied. C'est ASSUMÉ : la revue
	# proposait 14 blocs de 2,8 m, qui referment tout (écart 0,00 partout),
	# mais le calcul montre que cet anneau plein enterrerait l'ancrage de
	# récompense du lieu — ANCHORS[POI_SPRING] = (−2,49 ; 0 ; 6,01) tombe dans
	# la boîte centrée (−2,90 ; 4,91) de demi-côté 1,4, ce qui ferait échouer
	# `RewardAnchorAudit` — plus deux fougères sur quatre, un trèfle et deux
	# des quatre champignons d'ombre. Le bassin ne fait que 0,44 m d'eau
	# décorative : y entrer n'est ni un piège ni une chute. On garde donc
	# l'anneau ouvert et on décrit la géométrie telle qu'elle est.
	for i: int in range(10):
		var angle: float = TAU * float(i) / 10.0 + 0.31
		var at: Vector3 = Vector3(cos(angle) * 5.7, 0.0, sin(angle) * 5.7)
		_solid(place, "Margelle%d" % i, at + Vector3(0, 0.45, 0),
			Vector3(2.2, 0.9, 2.2), COL_ROCK_SHADE)
		_piece("Rock_Medium_%d" % (1 + i % 3), at, angle, place,
			0.6 + 0.12 * float(i % 3))

	# La venue d'eau : trois dalles qui montent vers la paroi ouest. Elles ne
	# mènent pas AU sommet — elles le DÉSIGNENT (§2 : indice environnemental).
	# Deux fautes mesurées et corrigées ensemble :
	#  - l'escalier s'enfonçait dans la falaise. La face est de `LearningCliff`
	#    (valley_terrain.gd:549, dalle pleine x −140..−80, z 40..90) tombe à
	#    x local = −8. Les centres étaient étagés en X (−7,0 / −8,9 / −10,8) :
	#    17 %, 80 % puis 100 % de la pierre disparaissait dans le mur, et il ne
	#    restait qu'une dalle et demie de l'indice environnemental.
	#  - la première marche flottait : centre y 0,85 pour 0,50 m d'épaisseur,
	#    donc 0,60 m d'air sous une dalle de 3,00 × 2,60 m.
	# On étage donc en Z, tous les blocs restant à x = −7,0 : chacun mord
	# 0,50 m dans la paroi — adossé, jamais avalé. Épaisseur portée de 0,50 à
	# 0,75 m pour que les marches s'empilent VRAIMENT (0,00..0,75 / 0,75..1,50 /
	# 1,50..2,25) : à 0,50 m il restait 0,25 m de vide entre chaque marche.
	# La première repose sur la plaine (dessous à y local 0 = monde 2,0).
	for i: int in range(3):
		var step: float = float(i)
		_solid(place, "Vasque%d" % i,
			Vector3(-7.0, 0.375 + step * 0.75, 2.4 - step * 1.8),
			Vector3(3.0, 0.75, 2.6), COL_ROCK)
		_piece("RockPath_Round_Wide",
			Vector3(-7.0, 0.77 + step * 0.75, 2.4 - step * 1.8),
			step * 0.8, place, 1.2)

	# L'exutoire : neuf galets et trois plantes d'eau qui filent vers le nord,
	# c'est-à-dire vers le lit de rivière (z = 10). Le ruisseau est suggéré,
	# pas simulé — mais il pointe dans la bonne direction.
	for i: int in range(9):
		var run: float = float(i)
		_piece("Pebble_Round_%d" % (1 + i % 5),
			Vector3(1.2 + run * 0.55, 0.05, -6.0 - run * 2.4), run * 0.9,
			place, 1.4)
	var water_plants: Array[String] = ["Plant_7_Big", "Plant_1"]
	_scatter(place, water_plants, Vector3(2.6, 0, -12.0), 1.0, 3.4, 3, 0.8, 0.4)

	# Récolte de rive (§2). Les buissons fleuris et les fougères marquent
	# l'humidité ; les champignons se cachent côté ombre, à l'ouest.
	var bushes: Array[String] = ["Bush_Common_Flowers", "Bush_Common"]
	_scatter(place, bushes, Vector3(3.0, 0, 4.0), 3.0, 6.0, 3, 0.85, 1.2)
	var ferns: Array[String] = ["Fern_1"]
	_scatter(place, ferns, Vector3(-2.0, 0, 5.5), 2.0, 5.0, 4, 0.28, 2.4)
	var tall_plants: Array[String] = ["Plant_1_Big"]
	_scatter(place, tall_plants, Vector3(-4.5, 0, -3.0), 1.5, 3.5, 2, 0.7, 0.9)
	var clovers: Array[String] = ["Clover_1", "Clover_2"]
	_scatter(place, clovers, Vector3(0.0, 0, 0.0), 6.8, 9.5, 5, 0.9, 3.1)
	var caps: Array[String] = ["Mushroom_Common"]
	# Le semis était centré à x local −8,5, soit 0,5 m DERRIÈRE la face de la
	# falaise (x = −8) : deux champignons sur quatre étaient dans la roche,
	# sous 12 m de pierre, et la récolte annoncée n'en montrait que deux.
	# Centre ramené à −5,4 ; mêmes rayons et même `seed_offset`, donc mêmes
	# positions relatives. Vérifié : x monde −77,55 / −76,03 / −79,80 / −75,27,
	# les quatre à l'est de la paroi, le plus profond à 0,20 m de la face —
	# toujours « côté ombre », et aucun ne tombe dans une margelle ni sur une
	# vasque (le plus proche passe à 0,20 m du bord de Vasque0).
	_scatter(place, caps, Vector3(-5.4, 0, 4.0), 1.2, 3.6, 4, 1.0, 1.7)
	# Deux arbres penchés au-dessus de l'eau : ils cadrent le bassin et le
	# rendent visible d'en haut, depuis la falaise.
	_piece("TwistedTree_2", Vector3(-6.5, 0, 7.5), 2.2, place, 0.45)
	_piece("CommonTree_4", Vector3(6.8, 0, -2.5), 1.1, place, 0.8)

	_declare(place, POI_SPRING, "La Source aux reflets", &"falaise",
		Vector3(22, 10, 22), Vector3(0, 3, 0))


# ---------------------------------------------------------------------------
# 3. LE CHAMP DES MILLE FLEURS — plaine sud-ouest
# ---------------------------------------------------------------------------
#
# Le seul lieu qui se lit d'abord PAR LA COULEUR : depuis la crête de départ
# (0, 24, 170), à 60 m au sud-ouest, une tache blanche et jaune sur le vert de
# la plaine. Un arbre isolé lui donne sa silhouette, un sentier de dalles le
# traverse — le champ est une DESTINATION, pas une texture.
#
# §7.5 impose le MultiMesh partitionné : quatre cellules de 24 m, tiges et
# corolles séparées (une corolle blanche sur une tige verte demande deux
# teintes, donc deux tampons), scatter déterministe en grappes avec de vrais
# vides, vent par `SH_FoliageWind`. Aucun recalcul CPU.
func _build_flower_field() -> void:
	var place: Node3D = Node3D.new()
	place.name = "ChampDeFleurs"
	add_child(place)
	place.position = SITE_FLOWER_FIELD

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260803
	var stem_mesh: ArrayMesh = _stem_mesh()
	var bloom_mesh: ArrayMesh = _bloom_mesh()
	var stem_material: Material = _foliage_material(COL_LEAF, 0.42)
	# Albédo blanc : le shader fait `ALBEDO = albedo * COLOR`, donc la teinte
	# d'instance passe telle quelle. Une corolle jaune reste jaune.
	var bloom_material: Material = _foliage_material(Color(1, 1, 1), 0.10)

	var half: float = FIELD_CELL_SIZE * 0.5
	var target: int = int(FIELD_CELL_SIZE * FIELD_CELL_SIZE * FIELD_DENSITY)
	for ix: int in range(FIELD_CELLS):
		for iz: int in range(FIELD_CELLS):
			var cell_centre: Vector3 = Vector3(
				(float(ix) - 0.5) * FIELD_CELL_SIZE, 0.0,
				(float(iz) - 0.5) * FIELD_CELL_SIZE)
			# Grappes de 4 à 9 corolles autour d'un centre, avec des VIDES
			# entre elles (§7.17 : un semis uniforme est un échec, même à un
			# million d'instances).
			var spots: PackedVector3Array = PackedVector3Array()
			var attempts: int = 0
			while spots.size() < target and attempts < target * 4:
				attempts += 1
				var cluster: Vector3 = cell_centre + Vector3(
					rng.randf_range(-half, half), 0.0,
					rng.randf_range(-half, half))
				if not _field_allows(cluster):
					continue
				var grouped: int = rng.randi_range(4, 9)
				for j: int in range(grouped):
					if spots.size() >= target:
						break
					var spot: Vector3 = cluster + Vector3(
						rng.randf_range(-1.15, 1.15), 0.0,
						rng.randf_range(-1.15, 1.15))
					if _field_allows(spot):
						spots.append(spot)

			var suffix: String = "%d%d" % [ix, iz]
			var stems: MultiMeshInstance3D = _multimesh_cell(
				"Tiges%s" % suffix, stem_mesh, stem_material, spots.size())
			var blooms: MultiMeshInstance3D = _multimesh_cell(
				"Corolles%s" % suffix, bloom_mesh, bloom_material, spots.size())
			# Le RenderingServer sans fenêtre ne restitue pas les tampons
			# d'instance (`get_instance_transform` rend l'identité, mesuré sur
			# la prairie de crête). Les origines et teintes sont donc AUSSI
			# consignées en métadonnées, par la même boucle : le test lit ce
			# qui a été écrit, pas ce que le serveur veut bien rendre.
			var origins: PackedVector3Array = PackedVector3Array()
			var tints: PackedColorArray = PackedColorArray()
			for i: int in range(spots.size()):
				var spot: Vector3 = spots[i]
				var height: float = rng.randf_range(0.30, 0.46)
				var yaw: float = rng.randf_range(0.0, TAU)
				var lean: float = rng.randf_range(0.85, 1.25)
				var stem_basis: Basis = Basis(Vector3.UP, yaw) \
					.scaled(Vector3(lean, height / 0.42, lean))
				stems.multimesh.set_instance_transform(i,
					Transform3D(stem_basis, spot))
				stems.multimesh.set_instance_color(i,
					COL_LEAF.lerp(Color(0.62, 0.72, 0.34), rng.randf()))
				var tint: Color = COL_PETALS[i % COL_PETALS.size()]
				var bloom_basis: Basis = Basis(Vector3.UP, yaw + 0.7) \
					.scaled(Vector3.ONE * rng.randf_range(0.8, 1.3))
				blooms.multimesh.set_instance_transform(i,
					Transform3D(bloom_basis, spot + Vector3(0, height, 0)))
				blooms.multimesh.set_instance_color(i, tint)
				origins.append(spot)
				tints.append(tint)
			blooms.set_meta(&"origins", origins)
			blooms.set_meta(&"tints", tints)
			place.add_child(stems)
			place.add_child(blooms)
			_blooms += spots.size()

	# L'arbre isolé : la silhouette sans laquelle le champ n'est qu'un aplat.
	_piece("CommonTree_2", FIELD_TREE_LOCAL, 0.6, place, 1.15)
	_solid_trunk(place, "TroncSolitaire", FIELD_TREE_LOCAL, 0.7, 4.0)
	for i: int in range(3):
		var angle: float = TAU * float(i) / 3.0 + 0.9
		_piece("Rock_Medium_%d" % (1 + i), FIELD_TREE_LOCAL
			+ Vector3(cos(angle) * 3.4, 0.0, sin(angle) * 3.4), angle, place, 0.8)

	# Sentier est-ouest : sept dalles, la lecture du passage à travers la
	# masse. Le semis les évite déjà (`_field_allows`).
	for i: int in range(7):
		_piece("RockPath_Square_Wide",
			Vector3(-18.0 + float(i) * 6.0, 0.04, sin(float(i) * 0.8) * 0.9),
			float(i) * 0.4, place, 1.25)

	# Bordures « en phrases » (§7.4) : de vraies touffes fleuries en périphérie,
	# là où le joueur passe à 2 m et où le MultiMesh ne suffirait plus.
	var borders: Array[String] = ["Flower_3_Group", "Flower_4_Group",
		"Bush_Common_Flowers"]
	_scatter(place, borders, Vector3(0, 0, 0), 17.0, 23.0, 12, 0.55, 0.5)
	var grasses: Array[String] = ["Grass_Wispy_Tall", "Grass_Common_Tall"]
	_scatter(place, grasses, Vector3(0, 0, 0), 12.0, 21.0, 6, 0.7, 2.7)

	_declare(place, POI_FLOWER_FIELD, "Le Champ des mille fleurs",
		&"plaine_sud", Vector3(52, 12, 52), Vector3(0, 4, 0))


## Le semis évite l'arbre focal et le sentier : deux vides VOULUS, qui font
## lire la masse au lieu de la noyer.
func _field_allows(spot: Vector3) -> bool:
	if spot.distance_to(FIELD_TREE_LOCAL) < FIELD_TREE_CLEAR:
		return false
	return absf(spot.z) > FIELD_PATH_HALF


## Cellule de MultiMesh prête à remplir.
func _multimesh_cell(node_name: String, mesh: Mesh, material: Material,
		count: int) -> MultiMeshInstance3D:
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = node_name
	node.material_override = material
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = count
	node.multimesh = multimesh
	return node


## Matériau de végétation : shader de vent partagé, repli `StandardMaterial3D`
## si le shader n'est pas livré. Un champ sans vent reste un champ ; un champ
## qui échoue à charger est une erreur bloquante.
func _foliage_material(albedo: Color, height: float) -> Material:
	if ResourceLoader.exists(FOLIAGE_SHADER):
		var shader: Shader = load(FOLIAGE_SHADER) as Shader
		if shader != null:
			var material: ShaderMaterial = ShaderMaterial.new()
			material.shader = shader
			material.set_shader_parameter(&"albedo", albedo)
			material.set_shader_parameter(&"blade_height", height)
			material.set_shader_parameter(&"sway_amplitude", 0.045)
			return material
	push_warning("[lieux] shader de vent absent — repli sans balancement")
	var fallback: StandardMaterial3D = StandardMaterial3D.new()
	fallback.albedo_color = albedo
	fallback.vertex_color_use_as_albedo = true
	fallback.roughness = 0.9
	fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
	return fallback


## Tige : deux quads croisés de 1,1 cm de large, origine AU SOL (le shader
## normalise `VERTEX.y` par `blade_height`). Normales redressées vers le ciel,
## sinon la tige reçoit une lumière horizontale et se découpe en carton noir.
func _stem_mesh() -> ArrayMesh:
	const HEIGHT: float = 0.42
	const HALF: float = 0.011
	const SKY_BIAS: float = 0.7
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in range(2):
		var basis: Basis = Basis(Vector3.UP, PI * 0.5 * float(k))
		var side: Vector3 = basis * Vector3(HALF, 0.0, 0.0)
		var face: Vector3 = basis * Vector3(0.0, 0.0, 1.0)
		var normal: Vector3 = face.lerp(Vector3.UP, SKY_BIAS).normalized()
		var top: Vector3 = Vector3(0.0, HEIGHT, 0.0)
		var quad: Array[Vector3] = [
			-side, side, top + side * 0.55,
			-side, top + side * 0.55, top - side * 0.55,
		]
		for vertex: Vector3 in quad:
			st.set_normal(normal)
			st.add_vertex(vertex)
	return st.commit()


## Corolle : cinq pétales à plat en éventail autour d'un cœur légèrement
## surélevé. Six triangles, une seule face — le shader désactive le culling.
func _bloom_mesh() -> ArrayMesh:
	const PETALS: int = 5
	const RADIUS: float = 0.085
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var heart: Vector3 = Vector3(0.0, 0.035, 0.0)
	for k: int in range(PETALS):
		var a0: float = TAU * float(k) / float(PETALS)
		var a1: float = TAU * float(k + 1) / float(PETALS)
		var petal: Array[Vector3] = [
			heart,
			Vector3(cos(a0) * RADIUS, 0.0, sin(a0) * RADIUS),
			Vector3(cos(a1) * RADIUS, 0.0, sin(a1) * RADIUS),
		]
		for vertex: Vector3 in petal:
			st.set_normal(Vector3.UP)
			st.add_vertex(vertex)
	return st.commit()


# ---------------------------------------------------------------------------
# 4. L'ARCHE DE PIERRE — pont naturel sur la rivière
# ---------------------------------------------------------------------------
#
# Les deux gués connus sont à x = 20 et x = 95. L'arche enjambe la rivière à
# x = −14 : c'est donc un VRAI raccourci (§2), la seule traversée de l'ouest,
# celle qui relie la route du village à la plaine nord sans détour.
#
# Elle se franchit PAR-DESSUS — tablier plein à y = 5,2 et deux rampes de 18°
# qui retombent sur chaque plaine — et se visite PAR-DESSOUS : 4,4 m de tirant
# d'air au-dessus de l'eau, une rampe de rive qui descend sur le lit, et à
# l'ombre du tablier la récolte qui récompense le détour.
func _build_stone_bridge() -> void:
	var place: Node3D = Node3D.new()
	place.name = "ArcheDePierre"
	add_child(place)
	place.position = SITE_STONE_BRIDGE   # y = 0 : les blocs portent leur Y monde

	var deck_centre: float = BRIDGE_DECK_Y - BRIDGE_DECK_THICKNESS * 0.5
	# Tablier : 6,5 m de large, 16,6 m de portée (z local −8,3 à +8,3, soit
	# z monde 1,7 à 18,3 — il couvre tout le lit, large de 4 à 16).
	_solid(place, "Tablier", Vector3(0, deck_centre, 0),
		Vector3(6.5, BRIDGE_DECK_THICKNESS, 16.6), COL_ROCK)

	# Les deux culées, posées sur les plaines (z monde 0-4 et 16-20), jamais
	# dans le lit : c'est ce qui laisse la travée centrale complètement libre.
	for side: float in [-1.0, 1.0]:
		var tag: String = "Nord" if side < 0.0 else "Sud"
		_solid(place, "Culee%s" % tag, Vector3(0, 1.95, side * 8.0),
			Vector3(7.6, 3.9, 4.0), COL_ROCK_SHADE)
		# Blocs erratiques AU PIED de la culée : ils cassent la silhouette de
		# boîte sans monter sur la chaussée.
		#
		# Ils étaient posés SUR la culée (y = 3,4) et aux échelles 1,50 / 1,85 /
		# 2,20. Boîtes englobantes monde relevées dans la vallée montée : le
		# troisième bloc de la culée sud occupait x −17,66..−7,03, y 2,71..7,80,
		# z 11,44..22,10, soit 10,63 m d'emprise pour une culée qui n'en fait que
		# 7,60 (x −17,80..−10,20) sur 4,00 de profondeur. Deux conséquences
		# mesurées, pas supposées :
		#  - 3,17 m de roche pendaient dans le vide à l'est de la culée, entre
		#    2,71 et 7,80 m d'altitude, au-dessus d'une plaine à y = 2 — la
		#    masse sombre flottante vue à hauteur de joueur ;
		#  - le bloc recouvrait le tablier (x −17,25..−10,75, y 3,90..5,20) de
		#    z 11,44 à 18,30 : la chaussée du pont était enterrée sous un rocher
		#    que l'on traverse, `_piece` ne posant aucune collision. Le bloc
		#    symétrique de la culée nord faisait de même (x −14,11..−4,95).
		# Correction : échelle ramenée dans la bande de la bible §3 (rochers
		# proches 0,15–4 m) et ancrage sur le FLANC OUEST, au sol. Le flanc est
		# reste libre — `RampeDeRive` y descend, x 4,0..7,0.
		# Vérifié bloc par bloc : Rock_Medium_1/2/3 culminent à 1,989 / 1,848 /
		# 2,001 m nus, donc à 0,70 / 0,85 / 0,90 leurs sommets tombent à
		# y 3,39 / 3,57 / 3,80 — tous SOUS le dessous du tablier (3,90). Et
		# à z local ≥ 7,80 − 2,15 = 5,65 ils restent sur la plaine, dont le bord
		# est à z local ±6,00 (le lit occupe z monde 4..16).
		var blocks: Array[Array] = [
			[Vector3(-4.1, 2.0, side * 7.8), 0.70],
			[Vector3(-3.7, 2.0, side * 8.7), 0.85],
			[Vector3(-4.6, 2.0, side * 9.8), 0.90],
		]
		for i: int in range(blocks.size()):
			var block: Array = blocks[i]
			_piece("Rock_Medium_%d" % (1 + i), block[0] as Vector3,
				float(i) * 1.4 + side, place, float(block[1]))
		# Rampe d'accès : 3,2 m de dénivelé sur 10 m, soit 17,7° — très en
		# dessous des 46° franchissables, on la monte en courant.
		_ramp_solid(place, "Rampe%s" % tag,
			Vector3(0, BRIDGE_DECK_Y, side * 8.3),
			Vector3(0, 2.0, side * 18.3), 5.0, 1.0, COL_ROCK)

	# Parapet suggéré : des roches le long des deux rives du tablier. Sans
	# collision — on DOIT pouvoir sauter du pont, c'est un pont, pas un couloir.
	for i: int in range(8):
		var along: float = -7.0 + float(i % 4) * 4.6
		var edge: float = 3.0 if i < 4 else -3.0
		_piece("Rock_Medium_%d" % (1 + i % 3),
			Vector3(edge, BRIDGE_DECK_Y - 0.2, along), float(i) * 0.9, place, 0.55)
	var deck_grass: Array[String] = ["Grass_Common_Tall", "Grass_Wispy_Short"]
	_scatter(place, deck_grass, Vector3(0, BRIDGE_DECK_Y, 0), 1.6, 2.6, 4, 0.7, 1.4)

	# Vignes sous le tablier : elles disent « naturel » là où la géométrie dit
	# « bloc », et elles se voient d'en dessous.
	for i: int in range(4):
		var vine: String = "Prop_Vine1" if i % 2 == 0 else "Prop_Vine2"
		_piece(vine, Vector3(-2.9 + float(i % 2) * 5.8,
			BRIDGE_DECK_Y - BRIDGE_DECK_THICKNESS,
			-4.5 + float(i) * 3.0), float(i), place, 1.2)

	# Descente de rive SUD : on marche jusqu'au lit (y = −1,5). 3,71 m sur 6 m
	# de course, soit 31,7° — on descend en marchant, on remonte de même.
	# Elle partait de z local 8,5, c'est-à-dire monde 18,5, alors que PlainSouth
	# (valley_terrain.gd:254, dalle pleine z 16..256, dessus y = 2) commence à
	# z = 16 : les 2,5 premiers mètres de la rampe étaient ENTERRÉS, et sa
	# surface au bord de la plaine tombait à y = 0,583. Il y avait donc une
	# marche sèche de 1,42 m — ni montable ni descendable au pas (step_height
	# 0,30-0,38 m, §8.2), et la récompense sous le tablier pouvait devenir un
	# cul-de-sac. Le départ est ramené à z local 6,5 et relevé à y 2,31 : la
	# surface passe par y = 2,00 exactement à z local 6,0, soit le bord de la
	# plaine — zéro marche. Le demi-mètre en amont forme une lèvre de 0,31 m,
	# sous le step_height, donc franchissable au pas. Le pied descend à z local
	# 0,5 dans le lit, à y −1,4 pour un fond à −1,5. La rampe occupe x 4,0..7,0
	# et la Culée Sud s'arrête à x 3,8 : aucun recouvrement.
	_ramp_solid(place, "RampeDeRive", Vector3(5.5, 2.31, 6.5),
		Vector3(5.5, -1.4, 0.5), 3.0, 0.8, COL_ROCK_SHADE)

	# La récompense du détour, à l'ombre du tablier, sur la berge SÈCHE du sud
	# (le ruban d'eau ne dépasse pas z local +2,6 à cette abscisse).
	var shade_crop: Array[String] = ["Mushroom_Common", "Mushroom_Laetiporus"]
	_scatter(place, shade_crop, Vector3(0.0, -1.45, 4.6), 0.8, 2.6, 5, 1.0, 2.2)
	var bank_ferns: Array[String] = ["Fern_1"]
	_scatter(place, bank_ferns, Vector3(-2.2, -1.45, 5.2), 0.8, 2.2, 3, 0.24, 0.7)
	for i: int in range(5):
		_piece("Pebble_Square_%d" % (1 + i % 2),
			Vector3(-3.0 + float(i) * 1.5, -1.45, 3.2 + float(i % 3) * 0.7),
			float(i) * 1.1, place, 1.6)

	_declare(place, POI_STONE_BRIDGE, "L'Arche de pierre", &"riviere",
		Vector3(26, 16, 30), Vector3(0, 4, 0))


# ---------------------------------------------------------------------------
# 5. LE BELVÉDÈRE DU GUETTEUR — plaine est
# ---------------------------------------------------------------------------
#
# §4 : « plusieurs destinations perceptibles depuis chaque point élevé ». À
# 22 m au-dessus de la plaine est, le sommet ouvre sur le pylône (80 m au
# nord-ouest), le camp (125 m à l'ouest), la citadelle au fond et, par temps
# de vent, la couronne du doyen. C'est la seule raison d'aller à l'est — donc
# elle doit payer.
#
# Géométrie volontairement SIMPLE : une masse sommitale et une rampe d'échine
# continue de 29°, plus une épaule est qui offre un premier palier à mi-course.
# Les contreforts restent SOUS la ligne de la rampe : la vue s'ouvre pendant
# la montée au lieu d'être murée jusqu'au sommet.
#
# Fragment d'histoire : quelqu'un a veillé ici. Cairn, arbre mort couché par
# le vent, torche, clôture cassée, caisse et corde. Aucun texte.
func _build_overlook() -> void:
	var place: Node3D = Node3D.new()
	place.name = "BelvedereDuGuetteur"
	add_child(place)
	place.position = SITE_OVERLOOK   # y = 0 : les gradins portent leur Y monde

	# Masse sommitale : 14 × 14 m, de la plaine (y = 2) au sommet (y = 22).
	_solid(place, "MasseSommet", Vector3(0, 12.0, -13.0),
		Vector3(14, 20, 14), COL_ROCK)
	# Échine : rampe unique de (0, 2, 30) à (0, 22, −6) — 20 m de montée sur
	# 36 m de course, soit 29°. Son extrémité haute affleure exactement le
	# bord sud de la masse sommitale (z = −6) : aucune marche au raccord.
	_ramp_solid(place, "Echine", Vector3(0, 2.0, 30.0),
		Vector3(0, OVERLOOK_SUMMIT_Y, -6.0), 9.0, 1.8, COL_ROCK)

	# --- L'assise de l'échine ----------------------------------------------
	#
	# L'ÉCHINE N'ÉTAIT ACCROCHÉE À RIEN, et c'est elle, la « planche orange
	# couchée en diagonale au travers du paysage ».
	#
	# Boîte englobante monde relevée dans la vallée montée : `EchineMesh`
	# occupe x 163,50..172,50, y 0,43..22,00, z 33,13..70,00 — une dalle ocre
	# (COL_ROCK) de 9 × 1,8 × 41,2 m inclinée à 29°, longue de 36,9 m au sol.
	# Les masses censées faire la montagne la BORDENT sans jamais passer
	# dessous : le commentaire des contreforts le dit lui-même, « hors de son
	# emprise en x ». Mesuré, sous l'emprise x −4,50..4,50 :
	#   Contrefort0 x −17..−5 · Contrefort1 x −18..−6 · Contrefort2 x −16..−6
	#   Contrefort3 x 7..17   · EpauleEst   x 5..17   · MasseSommet z −20..−6
	# Aucune ne recouvre l'abscisse de la rampe entre z = −6 et z = 30. À
	# mi-course (z = 12) la surface est à y = 12,0 pour une plaine à y = 2 : dix
	# mètres d'air sous une dalle de 9 m de large, sur 30 m de long.
	#
	# On ne touche NI la surface franchissable NI sa pente de 29° — l'audit des
	# ancrages (`RewardAnchorAudit`) fait réellement monter un corps par ici. On
	# lui donne son massif. Les cotes sont DÉRIVÉES de la rampe, jamais saisies
	# à la main : la surface vaut `y(z) = 2 + (30 − z) × 20/36` ; l'épaisseur de
	# 1,8 m est mesurée perpendiculairement, donc verticalement
	# `1,8 × 41,23/36 = 2,0591` ; le dessous vaut `y(z) − 2,0591` et rejoint la
	# plaine à z = 26,29. Le dessus de chaque gradin est le dessous de la dalle
	# mesuré à l'extrémité BASSE de son segment : aucun gradin ne peut percer la
	# rampe. Résultat RE-MESURÉ dans le moteur, en sondant le dessous de la
	# dalle tous les 0,9 m : le vide sous la rampe ne dépasse plus 1,97 m, là
	# où il montait à 10 m. Douze gradins, soit un ressaut de 1,49 m.
	const SPINE_SLOPE: float = 20.0 / 36.0
	const SPINE_VERTICAL_THICKNESS: float = 2.0591
	const SPINE_Z_TOP: float = -6.0
	const SPINE_Z_GROUND: float = 26.29
	const SPINE_STEPS: int = 12
	for i: int in range(SPINE_STEPS):
		var z_low: float = lerpf(SPINE_Z_TOP, SPINE_Z_GROUND,
			float(i + 1) / float(SPINE_STEPS))
		var z_high: float = lerpf(SPINE_Z_TOP, SPINE_Z_GROUND,
			float(i) / float(SPINE_STEPS))
		var top: float = 2.0 + (30.0 - z_low) * SPINE_SLOPE - SPINE_VERTICAL_THICKNESS
		if top <= 0.0:
			continue
		# Largeur 9,0 : exactement celle de la rampe, donc aucune corniche
		# marchable nouvelle le long du chemin. Base à y = 0, soit 2 m enterrés
		# dans la plaine.
		_solid(place, "AssiseDEchine%d" % i,
			Vector3(0.0, top * 0.5, (z_low + z_high) * 0.5),
			Vector3(9.0, top, z_low - z_high), COL_ROCK_SHADE)

	# Épaule est : palier à mi-hauteur, au niveau EXACT de la rampe en z = 12
	# (y = 12). On y sort de la montée pour souffler et regarder le camp. Son
	# bord ouest (x = 5) laisse 50 cm de vide avec le bord de la rampe
	# (x = 4,5) : un pas de côté, jamais un trou où l'on tombe — une capsule
	# de 70 cm de diamètre ne passe pas.
	_solid(place, "EpauleEst", Vector3(11.0, 7.0, 12.0),
		Vector3(12, 10, 12), COL_ROCK_SHADE)

	# Contreforts : masse de la montagne, toujours SOUS la rampe à leur
	# abscisse, et hors de son emprise en x.
	var buttresses: Array[Array] = [
		[Vector3(-11.0, 2.5, 20.0), Vector3(12, 5, 14)],
		[Vector3(-12.0, 5.5, 6.0), Vector3(12, 11, 16)],
		[Vector3(-11.0, 8.0, -8.0), Vector3(10, 16, 14)],
		[Vector3(12.0, 3.0, 24.0), Vector3(10, 6, 12)],
	]
	for i: int in range(buttresses.size()):
		var entry: Array = buttresses[i]
		_solid(place, "Contrefort%d" % i, entry[0] as Vector3,
			entry[1] as Vector3, COL_ROCK_SHADE)

	# Habillage rocheux : les blocs cassent les arêtes des gradins.
	# Ils étaient posés sur un CERCLE de rayon 8 autour de (0, ·, −13), alors
	# que la masse qu'ils habillent est un CARRÉ de 14 m : demi-emprise 7,0 aux
	# cardinales, 9,90 aux diagonales. Un rayon constant tombait donc DEDANS
	# aux diagonales et DANS LE VIDE aux cardinales — cinq blocs sur huit
	# avaient leur centre dans un solide, et le seul vraiment visible flottait
	# à 6,3 m au-dessus de la plaine.
	# On les pose maintenant sur les FACES EXPOSÉES, mesurées une par une.
	# Attention : la face ouest (x = −7) n'est pas exposée entre z = −15 et
	# z = −1, où Contrefort2 (x −16..−6, y 0..16, z −15..−1) la recouvre — un
	# bloc « projeté sur le carré » y serait encore enterré. Il ne reste donc
	# qu'un seul ancrage ouest, au nord du contrefort.
	# Vérifié pour les huit : aucun centre dans un solide, et chacun mord de
	# 2,1 à 7,9 m dans la masse — à moitié dedans, à moitié dehors.
	#
	# RESTE À CORRIGER, ET C'EST LA HAUTEUR. Les huit blocs étaient étagés par
	# `2,0 + (i % 3) × 3,4`, c'est-à-dire par une CONSTANTE DE CONSTRUCTION et
	# non par le sol. Boîtes englobantes monde relevées dans la vallée montée :
	#   bloc 1 : y 5,30..8,91, x 172,50..178,77 — la face est du sommet est à
	#            x = 175, il en sort donc 3,77 m, à 3,30 m au-dessus du vide ;
	#   bloc 2 : y 8,29..12,00, x 172,70..180,39 — 5,39 m dans le vide ;
	#   blocs 4, 5, 7 : même faute sur les faces nord, ouest et sud.
	# Cinq blocs sur huit avaient donc leur base entre 5,3 et 8,3 m d'altitude
	# avec la plaine à y = 2 et rien dessous : des masses de roche suspendues le
	# long d'une paroi. Ils sont ramenés au SOL (y = 2, la plaine ; ce site
	# travaille en Y monde), là où un éboulis s'accumule réellement, et
	# l'échelle passe de 1,60/1,90 à 0,95/1,15 pour rentrer dans la bande de la
	# bible §3 (rochers proches 0,15–4 m) : au sol, un bloc de 7,70 m devant une
	# masse de 14 m n'habille plus rien, il la remplace.
	# Un seul ancrage bouge : (0,0 ; −5,4) tombait au milieu de la nouvelle
	# assise de l'échine (x −4,50..4,50, z −6..0) et y aurait été entièrement
	# enterré. Il passe à l'angle sud-est du sommet, hors de cette emprise.
	var dressing: Array[Vector2] = [
		Vector2(7.6, -8.0), Vector2(7.6, -13.0), Vector2(7.6, -18.0),  # face est
		Vector2(3.5, -20.6), Vector2(-3.5, -20.6),                     # face nord
		Vector2(-7.6, -17.5),                                          # face ouest
		Vector2(6.2, -5.4), Vector2(4.5, -5.4),                        # angle sud-est
	]
	for i: int in range(dressing.size()):
		var anchor: Vector2 = dressing[i]
		var angle: float = TAU * float(i) / 8.0
		var at: Vector3 = Vector3(anchor.x, 2.0, anchor.y)
		_piece("Rock_Medium_%d" % (1 + i % 3), at, angle * 1.6, place,
			0.95 + 0.2 * float(i % 2))
	# Bordure de la rampe : on voit le vide sans qu'un mur cache la vallée.
	# Les blocs étaient à x = ±4,6 sur une rampe large de 9 m (bord ±4,50) et
	# posés à `height − 0,4` alors que `height` EST déjà la surface : ils
	# débordaient dans le vide, base à 1,63 m d'air pour le plus bas et à
	# 15,85 m pour le plus haut. Deux mesures :
	#  - le bord est calculé PAR BLOC. Un simple ±3,2 ne suffit pas : chaque
	#    rocher est tourné de i × 1,2 rad et son maillage n'est pas centré sur
	#    son origine, si bien que sa demi-emprise en x varie de 0,89 à 2,16 m
	#    selon le modèle et l'angle. Les six valeurs ci-dessous placent la face
	#    extérieure de chaque bloc exactement à x = ±4,45, soit 5 cm en deçà du
	#    bord de la rampe : plus aucun porte-à-faux ;
	#  - l'origine descend à `height − 0,25`, ce qui met la base 0,44 m sous la
	#    surface, donc DANS la dalle (2,06 m d'épaisseur à la verticale).
	var border_x: Array[float] = [3.40, -3.26, 2.29, -2.94, 3.56, -2.72]
	for i: int in range(border_x.size()):
		var along: float = 26.0 - float(i) * 6.4
		var height: float = 2.0 + (30.0 - along) * (20.0 / 36.0)
		_piece("Rock_Medium_%d" % (1 + i % 3),
			Vector3(border_x[i], height - 0.25, along), float(i) * 1.2, place, 0.7)

	# Le poste de guet, au sommet.
	var watch: Node3D = Node3D.new()
	watch.name = "PosteDeGuet"
	place.add_child(watch)
	watch.position = Vector3(0, OVERLOOK_SUMMIT_Y, -13.0)
	# Cairn : trois pierres empilées, à collision — c'est le repère qu'on voit
	# se détacher sur le ciel depuis la plaine.
	_solid(watch, "Cairn", Vector3(2.4, 0.9, 1.2), Vector3(1.6, 1.8, 1.6),
		COL_ROCK_SHADE)
	for i: int in range(3):
		_piece("Rock_Medium_%d" % (1 + i),
			Vector3(2.4, float(i) * 0.55, 1.2), float(i) * 1.9, watch,
			0.55 - 0.12 * float(i))
	_piece("DeadTree_1", Vector3(-2.8, 0.0, -1.4), 1.3, watch, 0.75)
	_piece("Torch_Metal", Vector3(0.9, 0.0, -2.2), 0.4, watch, 1.0)
	_piece("Prop_WoodenFence_Single", Vector3(-1.2, 0.0, 2.6), 0.25, watch, 1.0)
	_piece("Crate_Wooden", Vector3(-3.4, 0.0, 1.8), 0.9, watch, 1.0)
	_piece("Rope_1", Vector3(-2.6, 0.0, 0.6), 2.1, watch, 1.0)
	var summit_grass: Array[String] = ["Grass_Wispy_Short", "Clover_2"]
	_scatter(watch, summit_grass, Vector3.ZERO, 3.0, 5.4, 7, 0.6, 1.1)

	_declare(place, POI_OVERLOOK, "Le Belvédère du guetteur", &"hauteurs",
		Vector3(30, 26, 34), Vector3(0, 12, -8))
