## TERRITOIRES ENNEMIS DE LA VALLÉE — cinq lieux, une famille par lieu.
##
## Ordre d'extension §2, règle centrale : « les ennemis ne doivent pas être
## dispersés aléatoirement ; chaque famille doit occuper un territoire
## cohérent ». Un territoire n'est donc pas un cercle de spawn posé sur
## l'herbe : c'est un ENDROIT, qui se lit avant qu'un seul ennemi n'apparaisse.
##
##   - `CampsDePillardsBraise` — prairie est. Trois campements sommaires et
##     DÉSORDONNÉS : foyers de pierres, auvents de travers, pieux plantés au
##     jugé, fourbi éparpillé. Rien n'est aligné, rien n'est bâti.
##   - `ZoneDePatrouilleAzur` — plaine nord, sur la route du pylône. L'exact
##     contraire : une ronde BALISÉE en boucle fermée, deux postes de guet
##     surélevés, un relais de garde, un poste de contrôle. De l'ordre.
##   - `BastionDesBriseurs` — contreforts ouest. BÂTI et DÉFENDU : enceinte de
##     brique, portail unique flanqué de torches, chemin de ronde au-dessus,
##     chicane de barricades devant, râteliers et forge dans la cour.
##   - `TaniereDuColosse` — ravins est. Le lieu porte les traces de sa MASSE :
##     fer à cheval de blocs déplacés, sillon de traîne, arbres brisés couchés
##     dans le même sens, charrette écrasée, ossements STYLISÉS (des arcs
##     pâles abstraits — ni chair, ni crâne, ni sang).
##   - `TerritoireDuChasseur` — confins sud-est. Dangereux et SIGNALÉ : douze
##     balises plantées sur un cercle de 26 m, armes brisées fichées en terre,
##     sol labouré, végétation morte. On comprend le danger AVANT d'entrer.
##
## Ce fichier pose le DÉCOR et les points d'intérêt. Il ne fait apparaître
## aucun ennemi : le bestiaire vit dans `ValleyWorld._spawn_bestiary()`, et un
## lieu qui se peuplerait lui-même dupliquerait ce câblage. Les territoires
## préparent les endroits ; l'intégration les relie.
##
## Chaque territoire se déclare au `DiscoveryLog` par son propre
## `PointOfInterest`, sous un identifiant §19.3 distinct.
class_name ValleyTerritories
extends Node3D

## Même règle qu'au village et aux hameaux : le kit modulaire est réparti sur
## deux dossiers (les murs sont arrivés avec le lot « donjon », toitures et
## escaliers avec la promotion « monde ouvert »). Une pièce se résout par
## RECHERCHE, pas par chemin figé — sinon déplacer un asset casserait les
## territoires en silence.
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

# --- Implantation -----------------------------------------------------------
#
# Tous les sites sont posés sur une plaine plate (y = 2), à plus de 40 m de
# chaque lieu déjà implanté (village de la rivière, hameaux, grottes, ruines,
# repères) et de chaque ancre du monde (camp existant (45, 6, 65), pylône
# (115, 18, −25), donjon (0, 34, −210), crête de départ (0, 24, 170)). Aucun
# ne tombe dans le lit de rivière (z = 10) ni sur une dalle en relief.

## PRAIRIE EST, au nord du camp existant et à l'écart de la descente en S.
const SITE_BRAISE: Vector3 = Vector3(72.0, 2.0, 112.0)
## PLAINE NORD, à l'ouest de la terrasse du pylône (emprise x 87..143) : la
## ronde surveille la route qui y monte, sans monter dessus.
const SITE_AZURE: Vector3 = Vector3(78.0, 2.0, -78.0)
## CONTREFORTS OUEST de la plaine nord, adossés au massif de bordure.
const SITE_BASTION: Vector3 = Vector3(-140.0, 2.0, -60.0)
## RAVINS EST, entre la mine abandonnée et le fond de la plaine nord.
const SITE_LAIR: Vector3 = Vector3(150.0, 2.0, -140.0)
## CONFINS SUD-EST : hors de toute route obligatoire — le chasseur est
## facultatif (§12.5), donc son territoire ne barre aucun passage.
const SITE_HUNTER: Vector3 = Vector3(128.0, 2.0, 150.0)

## §19.3 : `zone.category.name.index`. Aucun de ces identifiants n'est utilisé
## ailleurs dans la vallée.
const POI_BRAISE: StringName = &"valley.poi.ember_raider_camps.01"
const POI_AZURE: StringName = &"valley.poi.azure_patrol_run.01"
const POI_BASTION: StringName = &"valley.poi.obsidian_bastion.01"
const POI_LAIR: StringName = &"valley.poi.colossus_lair.01"
const POI_HUNTER: StringName = &"valley.poi.hunter_range.01"

## ANCRAGES de récompense (contrat `RewardAnchor`). Positions éprouvées par
## `tools/godot/probe_reward_anchors.gd` dans la vallée montée, puis figées.
##
## Les cinq territoires portent une récompense de nature `COMBAT` : c'est
## l'INTENTION du lieu. Il faut le dire sans détour — le coffre est réel et
## persistant, mais sa condition d'ouverture (territoire nettoyé) n'est pas
## implémentée ; `DiscoveryRewards.deferred_gates()` les nomme.
const ANCHORS: Dictionary = {
	POI_BRAISE: {
		"at": Vector3(2.0, 0.0, 1.0), "approach": Vector3(4.77, 0.0, 2.15),
		"kind": RewardAnchor.Kind.COMBAT,
	},
	POI_AZURE: {
		"at": Vector3(2.12, 0.0, 2.12), "approach": Vector3(4.24, 0.0, 4.24),
		"kind": RewardAnchor.Kind.COMBAT,
	},
	POI_BASTION: {
		"at": Vector3(0.0, 0.0, 0.0), "approach": Vector3(3.0, 0.0, 0.0),
		"kind": RewardAnchor.Kind.COMBAT,
	},
	POI_LAIR: {
		"at": Vector3(0.0, 0.0, 2.0), "approach": Vector3(3.0, 0.0, 2.0),
		"kind": RewardAnchor.Kind.COMBAT,
	},
	POI_HUNTER: {
		"at": Vector3(5.0, 0.80, 0.0), "approach": Vector3(8.0, 0.0, 0.0),
		"kind": RewardAnchor.Kind.COMBAT,
	},
}

## Clés de comptage — un territoire figurant se repère à son décompte.
# Préfixe TERR_ et non le préfixe de touche : le garde-fou D-013 refuse ce
# dernier dans un script de gameplay, parce qu'il y traque la lecture directe
# du clavier. Ce sont des clés de dictionnaire, pas des touches — mais on ne
# désarme pas un garde-fou pour un faux positif, on écarte l'ambiguïté. Et le
# contrôle ne distingue pas code et commentaire, ce qui est la bonne rigueur :
# le citer même en prose le déclenche.
const TERR_BRAISE: StringName = &"camps_braise"
const TERR_AZURE: StringName = &"patrouille_azur"
const TERR_BASTION: StringName = &"bastion_obsidienne"
const TERR_LAIR: StringName = &"taniere_colosse"
const TERR_HUNTER: StringName = &"territoire_chasseur"

## Rayon du balisage du chasseur. Il tient largement à l'intérieur de
## l'écart au lieu voisin le plus proche : l'avertissement ne déborde sur
## personne.
const FRONTIER_RADIUS: float = 26.0
const FRONTIER_MARKS: int = 12

## Nombre de campements braise. Plusieurs PETITS camps, pas un gros.
const BRAISE_CAMPS: int = 3

# Teintes des quelques volumes construits à la main (sol de cour, tell du
# chasseur, ossements, braises). Elles suivent la palette §3.4 : ocres et
# terres, aucun accent saturé.
const COL_EMBER: Color = Color(1.0, 0.55, 0.18)
const COL_ASH: Color = Color(0.22, 0.19, 0.18)
const COL_BONE: Color = Color(0.86, 0.83, 0.72)
const COL_STONE: Color = Color(0.45, 0.42, 0.40)
const COL_EARTH: Color = Color(0.34, 0.28, 0.21)

## Territoires exposés pour que les tests et l'intégrateur les interrogent
## sans deviner un chemin de nœud.
var braise_camps: Node3D = null
var azure_patrol: Node3D = null
var obsidian_bastion: Node3D = null
var colossus_lair: Node3D = null
var hunter_range: Node3D = null

var braise_poi: PointOfInterest = null
var azure_poi: PointOfInterest = null
var bastion_poi: PointOfInterest = null
var lair_poi: PointOfInterest = null
var hunter_poi: PointOfInterest = null

## Hauteurs des deux sols PORTEURS — ce que les tests « on s'y tient debout »
## comparent pour vérifier qu'on n'est pas tombé au fond du monde.
var bastion_court_y: float = 0.0
var lair_floor_y: float = 0.0
## Sommet du tell du chasseur, d'où il domine son territoire.
var hunter_mound_y: float = 0.0

var _built: int = 0
var _counts: Dictionary = {}
var _braise_yaws: Array[float] = []
var _patrol_route: Array[Vector3] = []
var _frontier_marks: Array[Vector3] = []


func _ready() -> void:
	# Chaque territoire porte ses coordonnées absolues : ce nœud reste à
	# l'origine, sinon un décalage du parent déplacerait les cinq lieux.
	position = Vector3.ZERO
	_build_braise_camps()
	_build_azure_patrol()
	_build_obsidian_bastion()
	_build_colossus_lair()
	_build_hunter_range()


# --- Ce que les autres ont le droit de demander -----------------------------

func piece_count() -> int:
	return _built


## Décompte d'un seul territoire : un lieu peut être bâti alors qu'un autre
## est resté une maquette, et le total le masquerait.
func piece_count_of(key: StringName) -> int:
	if not _counts.has(key):
		return 0
	return int(_counts[key])


func territory_keys() -> Array[StringName]:
	var keys: Array[StringName] = [
		TERR_BRAISE, TERR_AZURE, TERR_BASTION, TERR_LAIR, TERR_HUNTER,
	]
	return keys


func territories() -> Array[Node3D]:
	var found: Array[Node3D] = []
	if braise_camps != null:
		found.append(braise_camps)
	if azure_patrol != null:
		found.append(azure_patrol)
	if obsidian_bastion != null:
		found.append(obsidian_bastion)
	if colossus_lair != null:
		found.append(colossus_lair)
	if hunter_range != null:
		found.append(hunter_range)
	return found


## Les cinq lieux, pour un appelant qui veut les lier en une fois. `ValleyWorld`
## n'en a pas besoin (il parcourt les `PointOfInterest` descendants), mais un
## test ou un outil de contrôle, si.
func pois() -> Array[PointOfInterest]:
	var found: Array[PointOfInterest] = []
	if braise_poi != null:
		found.append(braise_poi)
	if azure_poi != null:
		found.append(azure_poi)
	if bastion_poi != null:
		found.append(bastion_poi)
	if lair_poi != null:
		found.append(lair_poi)
	if hunter_poi != null:
		found.append(hunter_poi)
	return found


func sites() -> Array[Vector3]:
	var found: Array[Vector3] = [
		SITE_BRAISE, SITE_AZURE, SITE_BASTION, SITE_LAIR, SITE_HUNTER,
	]
	return found


## Orientation de chaque campement braise. Trois valeurs franchement
## différentes : c'est la mesure du désordre revendiqué.
func camp_yaws() -> Array[float]:
	# Copie construite par `assign` : `duplicate()` renvoie un `Array` non typé
	# du point de vue du compilateur, ce que le typage strict refuse.
	var copy: Array[float] = []
	copy.assign(_braise_yaws)
	return copy


## La ronde azur, en repère MONDE, dans l'ordre de parcours.
func patrol_route() -> Array[Vector3]:
	var copy: Array[Vector3] = []
	copy.assign(_patrol_route)
	return copy


## Les balises du chasseur, en repère MONDE.
func frontier_marks() -> Array[Vector3]:
	var copy: Array[Vector3] = []
	copy.assign(_frontier_marks)
	return copy


func hunter_frontier_radius() -> float:
	return FRONTIER_RADIUS


## Vrai si un point est au-delà du balisage — la question que posera l'IA du
## chasseur pour abandonner sa poursuite à la frontière (§12.5).
func is_inside_hunter_frontier(point: Vector3) -> bool:
	var flat: Vector2 = Vector2(point.x - SITE_HUNTER.x, point.z - SITE_HUNTER.z)
	return flat.length() <= FRONTIER_RADIUS


# --- Briques ----------------------------------------------------------------

## Instancie une pièce du kit. Renvoie `null` si l'asset manque, sans lever :
## un territoire amputé d'un modèle doit rester chargeable et le DIRE.
##
## `tilt_deg` permet de coucher ou d'incliner une pièce (une toiture devient un
## auvent de fortune, un pieu penche, un tronc mort se couche) sans multiplier
## les assets — le kit n'en contient pas d'autre.
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
		push_warning("[territoires] pièce absente du kit : %s" % asset)
		return null
	var node: Node3D = packed.instantiate() as Node3D
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
## posée à la main, ce qui permet de LAISSER un trou dans un portail — un
## collider unique par enceinte enfermerait le bastion.
func _collider(parent: Node3D, centre: Vector3, size: Vector3) -> void:
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
	_collider(parent, at + Vector3(0, WALL_H * 0.5, 0),
		Vector3(maxf(span.x, thick.x), WALL_H, maxf(span.z, thick.z)))


## Une clôture posée pièce par pièce, chaque segment avec sa collision : une
## barricade qu'on traverse n'arrête rien. `gap_at` laisse un passage.
func _fence_row(parent: Node3D, kind: String, start: Vector3, step: Vector3,
		count: int, yaw: float, height: float, gap_at: Array[int]) -> void:
	var along: Vector3 = step.normalized()
	for i: int in range(count):
		if gap_at.has(i):
			continue
		var at: Vector3 = start + step * float(i)
		_piece(kind, at, yaw, parent)
		var size: Vector3 = along.abs() * MODULE \
			+ Vector3(absf(along.z), 0.0, absf(along.x)) * 0.35
		_collider(parent, at + Vector3(0, height * 0.5, 0),
			Vector3(maxf(size.x, 0.35), height, maxf(size.z, 0.35)))


## Un pieu planté de travers, avec sa collision. C'est le mot commun aux camps
## braise (plantés au jugé) et à la ronde azur (plantés au cordeau) : même
## objet, deux grammaires de placement.
func _stake(parent: Node3D, at: Vector3, yaw: float, tilt: float) -> void:
	_piece("Prop_WoodenFence_Single", at, yaw, parent, "",
		Vector3(tilt, 0.0, tilt * 0.45))
	_collider(parent, at + Vector3(0, 0.9, 0), Vector3(0.4, 1.8, 0.4))


func _material(tint: Color, glowing: bool) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.86
	if glowing:
		mat.emission_enabled = true
		mat.emission = tint
		mat.emission_energy_multiplier = 1.5
	return mat


## Volume construit à la main, là où le kit n'a rien : sol de cour, tell de
## pierre, cendres, braise. `solid` pose la collision, `glowing` l'émission.
func _block(parent: Node3D, block_name: String, centre: Vector3, size: Vector3,
		tint: Color, solid: bool, glowing: bool = false) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(tint, glowing)
	mesh.name = block_name
	mesh.position = centre
	parent.add_child(mesh)
	_built += 1
	if not solid:
		return
	_collider(parent, centre, size)


## Ossement STYLISÉ : un fuseau pâle, abstrait. Aucune anatomie, aucune
## matière organique reconnaissable — une forme qui dit « quelque chose de
## très grand est mort ici », et rien de plus (§14.4 : non gore).
func _bone(parent: Node3D, at: Vector3, length: float, radius: float,
		rot_deg: Vector3) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius * 1.2
	cyl.height = length
	cyl.radial_segments = 8
	mesh.mesh = cyl
	mesh.material_override = _material(COL_BONE, false)
	mesh.name = "Ossement"
	mesh.position = at
	mesh.rotation_degrees = rot_deg
	parent.add_child(mesh)
	_built += 1


## Foyer : un cercle de pierres, un lit de cendres, une braise qui se voit de
## loin sans coûter une lumière dynamique (§20.4).
func _fire_ring(parent: Node3D, at: Vector3, radius: float) -> void:
	var stones: Array[String] = [
		"Pebble_Round_1", "Pebble_Square_1", "Pebble_Round_3",
		"Pebble_Round_5", "Pebble_Square_2", "Pebble_Round_2",
	]
	for i: int in range(stones.size()):
		var angle: float = TAU * float(i) / float(stones.size())
		_piece(stones[i], at + Vector3(cos(angle) * radius, 0.0,
			sin(angle) * radius), rad_to_deg(angle), parent, ROCKS)
	_block(parent, "Cendres", at + Vector3(0, 0.06, 0),
		Vector3(radius * 1.5, 0.12, radius * 1.5), COL_ASH, false)
	_block(parent, "Braise", at + Vector3(0, 0.22, 0),
		Vector3(0.55, 0.32, 0.55), COL_EMBER, false, true)


# --- 1. Camps de pillards braise --------------------------------------------

## Trois PETITS camps, ni alignés entre eux, ni orientés pareil, ni meublés
## pareil. Le pillard braise est impulsif (§12.1) : son campement est un feu,
## un abri de fortune et ce qu'il a traîné jusque-là. Rien n'est construit,
## rien n'est droit — c'est exactement ce qui le distingue du bastion.
func _build_braise_camps() -> void:
	var before: int = _built
	braise_camps = Node3D.new()
	braise_camps.name = "CampsDePillardsBraise"
	braise_camps.position = SITE_BRAISE
	add_child(braise_camps)

	var spots: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.0),
		Vector3(13.5, 0.0, -9.0),
		Vector3(-8.5, 0.0, 11.5),
	]
	var yaws: Array[float] = [17.0, -64.0, 128.0]
	_braise_yaws.clear()
	for index: int in range(BRAISE_CAMPS):
		var camp: Node3D = Node3D.new()
		camp.name = "Campement%02d" % (index + 1)
		camp.position = spots[index]
		camp.rotation_degrees = Vector3(0, yaws[index], 0)
		braise_camps.add_child(camp)
		_braise_yaws.append(yaws[index])
		_build_one_braise_camp(camp, index)
	_dress_braise_fringe(braise_camps)

	braise_poi = _make_poi(braise_camps, POI_BRAISE,
		"Camps des pillards braise", &"prairie_est", Vector3(2, 5, 1),
		Vector3(46, 12, 46))
	_counts[TERR_BRAISE] = _built - before


func _build_one_braise_camp(camp: Node3D, index: int) -> void:
	_fire_ring(camp, Vector3.ZERO, 1.15)
	_metal_crate(camp, Vector3(1.9, 0.45, -1.3))

	# Auvent de fortune : une toiture posée DE TRAVERS sur deux perches. Elle
	# n'est ni horizontale ni centrée — un abri, pas un toit.
	for side: float in [-1.0, 1.0]:
		var foot: Vector3 = Vector3(side * 1.1, 0.0, -2.7)
		_piece("Prop_Support", foot, 0.0, camp)
		_collider(camp, foot + Vector3(0, 1.2, 0), Vector3(0.3, 2.4, 0.3))
	_piece("Roof_Wooden_2x1", Vector3(0.0, 2.35, -2.7),
		9.0 * float(index + 1), camp, "", Vector3(-19.0, 0.0, 5.0))

	# Toile tendue au sol côté vent : deux modèles alternés pour que les trois
	# camps ne soient pas la même image.
	var cloth: String = "Banner_2_Cloth"
	if index % 2 == 0:
		cloth = "Banner_1_Cloth"
	_piece(cloth, Vector3(2.6, 0.0, -1.5), 63.0 * float(index) - 24.0, camp,
		PROPS, Vector3(0.0, 0.0, 74.0))

	# Pieux plantés AU JUGÉ : trois angles, trois inclinaisons, aucun rythme.
	var pikes: Array[Vector3] = [
		Vector3(2.9, 0.0, 1.4), Vector3(-3.3, 0.0, 0.6), Vector3(1.1, 0.0, 3.2),
	]
	for p: int in range(pikes.size()):
		_stake(camp, pikes[p], float(p) * 53.0 + float(index) * 21.0,
			9.0 + float(p) * 5.0)

	# Fourbi : un sous-ensemble différent par camp, posé en spirale lâche.
	var clutter: Array[String] = [
		"Barrel", "Crate_Wooden", "Pot_1", "Bag", "Bucket_Wooden_1", "Mug",
	]
	for c: int in range(3 + index):
		var kind: String = clutter[(c + index * 2) % clutter.size()]
		var angle: float = float(c) * 1.9 + float(index)
		var at: Vector3 = Vector3(cos(angle) * (2.3 + 0.5 * float(c)), 0.0,
			sin(angle) * (2.1 + 0.6 * float(c)))
		_piece(kind, at, rad_to_deg(angle), camp, PROPS)
		if kind == "Barrel" or kind == "Crate_Wooden":
			_collider(camp, at + Vector3(0, 0.45, 0), Vector3(0.9, 0.9, 0.9))
	_piece("Torch_Metal", Vector3(-1.9, 0.0, -1.6), 0.0, camp, PROPS)


## Autour des camps : herbe sèche piétinée, un arbre mort, quelques pierres.
## Aucune culture, aucun enclos — on ne s'installe pas, on s'arrête.
func _dress_braise_fringe(parent: Node3D) -> void:
	var fringe: Node3D = Node3D.new()
	fringe.name = "Abords"
	parent.add_child(fringe)
	var tufts: Array[Vector3] = [
		Vector3(6.5, 0, 5.5), Vector3(-5.0, 0, -6.0), Vector3(9.0, 0, -2.0),
		Vector3(-11.0, 0, 3.5), Vector3(4.0, 0, 14.0), Vector3(17.0, 0, -3.0),
	]
	for i: int in range(tufts.size()):
		var kind: String = "Grass_Wispy_Tall"
		if i % 3 == 1:
			kind = "Grass_Common_Tall"
		_piece(kind, tufts[i], float(i) * 61.0, fringe, FOLIAGE)
	_piece("DeadTree_2", Vector3(-13.0, 0, -4.0), 40.0, fringe, FOLIAGE)
	_piece("Bush_Common", Vector3(8.0, 0, 9.5), 130.0, fringe, FOLIAGE)
	_piece("Rock_Medium_3", Vector3(-3.0, 0, -12.0), 25.0, fringe, ROCKS)
	_piece("Rock_Medium_1", Vector3(16.5, 0, 6.0), 200.0, fringe, ROCKS)
	_collider(fringe, Vector3(16.5, 0.6, 6.0), Vector3(1.6, 1.2, 1.6))


# --- 2. Zone de patrouille des pillards azur --------------------------------

## Le pillard azur se repositionne, tient la distance et alerte ses alliés
## (§12.2). Son territoire n'est donc pas un camp : c'est une RONDE. Boucle
## fermée jalonnée, deux postes de guet d'où l'on voit venir, un relais où
## reposer les armes, un poste de contrôle à l'entrée. Tout est régulier —
## la lecture inverse de celle des camps braise, à trente mètres de distance.
func _build_azure_patrol() -> void:
	var before: int = _built
	azure_patrol = Node3D.new()
	azure_patrol.name = "ZoneDePatrouilleAzur"
	azure_patrol.position = SITE_AZURE
	add_child(azure_patrol)

	_build_patrol_circuit(azure_patrol)
	_build_watch_post(azure_patrol, "PosteDeGuet01", Vector3(-15.0, 0, 5.0), 90.0)
	_build_watch_post(azure_patrol, "PosteDeGuet02", Vector3(14.0, 0, -6.0), 270.0)
	_build_guard_relay(azure_patrol)
	_build_patrol_checkpoint(azure_patrol)
	_dress_azure_fringe(azure_patrol)

	azure_poi = _make_poi(azure_patrol, POI_AZURE,
		"Ronde des pillards azur", &"plaine_nord", Vector3(0, 5, 0),
		Vector3(46, 12, 40))
	_counts[TERR_AZURE] = _built - before


## La ronde s'est IMPRIMÉE dans le sol : dalles usées le long du trajet, un
## jalon planté sur deux. Le joueur peut lire le circuit avant de voir le
## premier garde, et donc choisir son moment (§5.6 : infiltration légère).
func _build_patrol_circuit(parent: Node3D) -> void:
	var route: Node3D = Node3D.new()
	route.name = "Ronde"
	parent.add_child(route)
	_patrol_route.clear()
	for i: int in range(12):
		var angle: float = TAU * float(i) / 12.0
		var at: Vector3 = Vector3(cos(angle) * 17.0, 0.0, sin(angle) * 11.5)
		_patrol_route.append(SITE_AZURE + at)
		# Dalle de chemin : sans collision, on marche dessus.
		_piece("RockPath_Square_Wide", at + Vector3(0, 0.03, 0),
			rad_to_deg(angle), route, ROCKS)
		if i % 2 == 0:
			var side: Vector3 = Vector3(-sin(angle) * 1.7, 0.0, cos(angle) * 1.7)
			_stake(route, at + side, rad_to_deg(angle), 3.0)


## Poste de guet : une plate-forme RÉELLE, avec son plancher porteur et son
## escalier. On peut y monter — un mirador décoratif serait un mensonge de
## plus (§1 de l'ordre d'extension).
func _build_watch_post(parent: Node3D, post_name: String, at: Vector3,
		yaw: float) -> void:
	var post: Node3D = Node3D.new()
	post.name = post_name
	post.position = at
	post.rotation_degrees = Vector3(0, yaw, 0)
	parent.add_child(post)
	var deck_y: float = 2.6
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var foot: Vector3 = Vector3(sx * 1.7, 0.0, sz * 1.7)
			_piece("Prop_Support", foot, 0.0, post)
			_collider(post, foot + Vector3(0, deck_y * 0.5, 0),
				Vector3(0.35, deck_y, 0.35))
	for ix: int in [-1, 0]:
		for iz: int in [-1, 0]:
			_piece("Floor_WoodDark",
				Vector3(float(ix) * MODULE + 1.0, deck_y,
					float(iz) * MODULE + 1.0), 0.0, post)
	_collider(post, Vector3(0, deck_y - 0.15, 0), Vector3(4.4, 0.3, 4.4))
	_piece("Stairs_Exterior_Straight", Vector3(0.0, 0.0, 3.3), 180.0, post)
	_piece("Prop_MetalFence_Simple", Vector3(0.0, deck_y, -2.0), 0.0, post)
	_piece("Banner_2", Vector3(1.5, deck_y, -1.5), 0.0, post, PROPS)


## Relais de garde : là où l'on repose les armes entre deux tours. Un râtelier,
## un bouclier, des caisses — de l'ordre, encore.
func _build_guard_relay(parent: Node3D) -> void:
	var relay: Node3D = Node3D.new()
	relay.name = "RelaisDeGarde"
	relay.position = Vector3(1.5, 0.0, 13.5)
	parent.add_child(relay)
	_piece("WeaponStand", Vector3(0.0, 0.0, 0.0), 0.0, relay, PROPS)
	_piece("Shield_Wooden", Vector3(1.3, 0.0, 0.4), 25.0, relay, PROPS)
	_piece("Crate_Metal", Vector3(-1.6, 0.0, 0.6), 12.0, relay, PROPS)
	_collider(relay, Vector3(-1.6, 0.45, 0.6), Vector3(1.0, 0.9, 1.0))
	_piece("Barrel_Holder", Vector3(-2.8, 0.0, -1.0), 0.0, relay, PROPS)
	_collider(relay, Vector3(-2.8, 0.5, -1.0), Vector3(1.1, 1.0, 1.1))
	_piece("Chain_Coil", Vector3(0.8, 0.0, -1.5), 0.0, relay, PROPS)
	_piece("Bottle_1", Vector3(-0.6, 0.0, 1.6), 0.0, relay, PROPS)


## Poste de contrôle : deux rangs de barrières encadrent l'entrée sud de la
## ronde, avec un passage franc au milieu. On entre par là, et on RESSORT par
## là — jamais de clôture qui enferme (§15.11).
func _build_patrol_checkpoint(parent: Node3D) -> void:
	var post: Node3D = Node3D.new()
	post.name = "PosteDeControle"
	parent.add_child(post)
	var no_gap: Array[int] = []
	_fence_row(post, "Prop_MetalFence_Simple", Vector3(-9.0, 0, 15.5),
		Vector3(MODULE, 0, 0), 3, 0.0, 1.5, no_gap)
	_fence_row(post, "Prop_MetalFence_Simple", Vector3(5.0, 0, 15.5),
		Vector3(MODULE, 0, 0), 3, 0.0, 1.5, no_gap)
	for side: float in [-1.0, 1.0]:
		_piece("Prop_Support", Vector3(side * 2.6, 0, 15.5), 0.0, post)
		_collider(post, Vector3(side * 2.6, 1.2, 15.5), Vector3(0.35, 2.4, 0.35))
	_piece("Torch_Metal", Vector3(3.2, 0, 15.0), 0.0, post, PROPS)


func _dress_azure_fringe(parent: Node3D) -> void:
	var fringe: Node3D = Node3D.new()
	fringe.name = "Abords"
	parent.add_child(fringe)
	var greens: Array[Vector3] = [
		Vector3(-20.0, 0, -9.0), Vector3(19.0, 0, 10.0),
		Vector3(-6.0, 0, -16.0), Vector3(9.0, 0, 17.0),
	]
	for i: int in range(greens.size()):
		var kind: String = "Pine_2"
		if i % 2 == 1:
			kind = "Pine_4"
		_piece(kind, greens[i], float(i) * 73.0, fringe, FOLIAGE)
	_piece("Rock_Medium_2", Vector3(-18.0, 0, 13.0), 55.0, fringe, ROCKS)
	_collider(fringe, Vector3(-18.0, 0.6, 13.0), Vector3(1.6, 1.2, 1.6))
	_piece("Grass_Wispy_Short", Vector3(6.0, 0, -14.0), 0.0, fringe, FOLIAGE)


# --- 3. Bastion des briseurs d'obsidienne -----------------------------------

## Le briseur tient l'espace, garde et contrôle (§12.3). Son territoire est le
## seul BÂTI : une enceinte de brique inégale, un portail unique tenu d'en
## haut, une chicane de barricades devant, une cour où l'on entretient les
## armures. On voit d'un coup d'œil que ce lieu se défend — et qu'il n'a
## qu'une entrée.
func _build_obsidian_bastion() -> void:
	var before: int = _built
	obsidian_bastion = Node3D.new()
	obsidian_bastion.name = "BastionDesBriseurs"
	obsidian_bastion.position = SITE_BASTION
	add_child(obsidian_bastion)

	_build_bastion_court(obsidian_bastion)
	_build_bastion_wall(obsidian_bastion)
	_build_bastion_gate(obsidian_bastion)
	_build_bastion_barricades(obsidian_bastion)
	_build_bastion_yard(obsidian_bastion)

	bastion_poi = _make_poi(obsidian_bastion, POI_BASTION,
		"Bastion des briseurs d'obsidienne", &"contreforts", Vector3(0, 5, 0),
		Vector3(40, 12, 40))
	_counts[TERR_BASTION] = _built - before


## COUR : un sol porteur qui déborde l'enceinte de quelques dizaines de
## centimètres, pour qu'on ne tombe nulle part le long des murs.
func _build_bastion_court(parent: Node3D) -> void:
	var court: Node3D = Node3D.new()
	court.name = "CourInterieure"
	parent.add_child(court)
	_block(court, "SolDeCour", Vector3(0, -0.05, 0),
		Vector3(15.4, 0.1, 15.4), COL_EARTH, false)
	for ix: int in range(-2, 3):
		for iz: int in range(-2, 3):
			_piece("Floor_Brick", Vector3(float(ix) * MODULE, 0.02,
				float(iz) * MODULE), 0.0, court)
	bastion_court_y = SITE_BASTION.y + 0.02
	# Sol porteur sous le dallage : la cour est un VOLUME où l'on se tient.
	_collider(court, Vector3(0, -0.3, 0), Vector3(15.4, 0.6, 15.4))


## ENCEINTE : sept modules au nord et au sud, six à l'ouest, six à l'est dont
## deux retirés — le portail. Les angles sont épaulés de contreforts.
func _build_bastion_wall(parent: Node3D) -> void:
	var wall: Node3D = Node3D.new()
	wall.name = "Enceinte"
	parent.add_child(wall)
	for ix: int in range(-3, 4):
		var x: float = float(ix) * MODULE
		_wall(wall, Vector3(x, 0, -7.0), 180.0, "Wall_UnevenBrick_Straight")
		_wall(wall, Vector3(x, 0, 7.0), 0.0, "Wall_UnevenBrick_Straight")
	for iz: int in range(-3, 3):
		var z: float = float(iz) * MODULE + 1.0
		_wall(wall, Vector3(-7.0, 0, z), 90.0, "Wall_UnevenBrick_Straight")
		# Face EST : deux modules retirés, soit 4 m de passage franc.
		if absf(z) < 2.0:
			continue
		_wall(wall, Vector3(7.0, 0, z), 270.0, "Wall_UnevenBrick_Straight")
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var corner: Vector3 = Vector3(sx * 7.0, 0.0, sz * 7.0)
			_piece("Corner_Exterior_Brick", corner, 0.0, wall)
			_collider(wall, corner + Vector3(0, WALL_H * 0.5, 0),
				Vector3(0.9, WALL_H, 0.9))
			_piece("Prop_Support", corner + Vector3(sx * 0.9, 0, sz * 0.9),
				0.0, wall)


## PORTAIL : jambages, torches, bannières, et un chemin de ronde AU-DESSUS —
## l'entrée est tenue d'en haut. Le passage lui-même reste franc.
func _build_bastion_gate(parent: Node3D) -> void:
	var gate: Node3D = Node3D.new()
	gate.name = "Portail"
	parent.add_child(gate)
	for side: float in [-1.0, 1.0]:
		_piece("Prop_Brick1", Vector3(7.0, 0.0, side * 2.6), 270.0, gate)
		_collider(gate, Vector3(7.0, WALL_H * 0.5, side * 2.6),
			Vector3(0.6, WALL_H, 0.8))
		_piece("Torch_Metal", Vector3(6.3, 0.0, side * 2.3), 270.0, gate, PROPS)
		_piece("Banner_2", Vector3(7.5, 0.0, side * 3.4), 270.0, gate, PROPS)
	for iz: int in [-1, 0]:
		_piece("Floor_WoodDark",
			Vector3(7.0, WALL_H, float(iz) * MODULE + 1.0), 0.0, gate)
	# Le tablier passe au-dessus de la baie : on marche dessus, on passe dessous.
	_collider(gate, Vector3(7.0, WALL_H - 0.15, 0.0), Vector3(2.4, 0.3, 4.4))
	_piece("Stairs_Exterior_Straight", Vector3(4.6, 0.0, 0.0), 270.0, gate)
	_piece("Prop_MetalFence_Simple", Vector3(7.0, WALL_H, 1.7), 0.0, gate)


## BARRICADES : deux rangs décalés devant le portail. On y entre toujours, mais
## pas en ligne droite — c'est une approche, pas un couloir.
func _build_bastion_barricades(parent: Node3D) -> void:
	var chicane: Node3D = Node3D.new()
	chicane.name = "Barricades"
	parent.add_child(chicane)
	var no_gap: Array[int] = []
	# Premier rang au sud de l'axe du portail, second rang décalé de 3,5 m au
	# nord : la sortie reste FRANCHE juste devant la baie, puis oblique. On
	# ralentit l'assaillant ; on n'enferme pas l'occupant.
	_fence_row(chicane, "Prop_WoodenFence_Extension1", Vector3(10.0, 0, -8.0),
		Vector3(0, 0, MODULE), 4, 90.0, 1.7, no_gap)
	_fence_row(chicane, "Prop_WoodenFence_Extension1", Vector3(13.5, 0, 0.0),
		Vector3(0, 0, MODULE), 4, 90.0, 1.7, no_gap)
	for i: int in range(3):
		_stake(chicane, Vector3(11.5 + float(i) * 1.4, 0, 6.5 - float(i) * 0.8),
			float(i) * 37.0, 14.0)
	_piece("Rock_Medium_1", Vector3(12.0, 0, -9.5), 30.0, chicane, ROCKS)
	_collider(chicane, Vector3(12.0, 0.6, -9.5), Vector3(1.6, 1.2, 1.6))


## COUR ARMÉE : râteliers le long du mur nord, forge d'entretien à l'angle
## sud-ouest, caisses et torches. On répare ici des armures lourdes.
func _build_bastion_yard(parent: Node3D) -> void:
	var yard: Node3D = Node3D.new()
	yard.name = "CourArmee"
	parent.add_child(yard)
	for i: int in range(3):
		var x: float = -4.0 + float(i) * 4.0
		_piece("WeaponStand", Vector3(x, 0, 5.6), 180.0, yard, PROPS)
		_collider(yard, Vector3(x, 0.6, 5.6), Vector3(1.2, 1.2, 0.6))
	_piece("Sword_Bronze", Vector3(-2.6, 0, 5.0), 12.0, yard, PROPS)
	_piece("Axe_Bronze", Vector3(1.4, 0, 5.0), -20.0, yard, PROPS)
	_piece("Shield_Wooden", Vector3(4.9, 0, 4.6), 40.0, yard, PROPS)

	_piece("Anvil_Log", Vector3(-4.8, 0, -4.6), 15.0, yard, PROPS)
	_piece("Anvil", Vector3(-4.8, 0.62, -4.6), 15.0, yard, PROPS)
	_collider(yard, Vector3(-4.8, 0.45, -4.6), Vector3(1.1, 0.9, 0.9))
	_piece("Workbench", Vector3(-2.2, 0, -5.4), 0.0, yard, PROPS)
	_collider(yard, Vector3(-2.2, 0.45, -5.4), Vector3(1.8, 0.9, 0.8))
	_piece("Whetstone", Vector3(-0.4, 0, -4.8), 0.0, yard, PROPS)

	_piece("Crate_Metal", Vector3(4.4, 0, -4.8), 22.0, yard, PROPS)
	_collider(yard, Vector3(4.4, 0.45, -4.8), Vector3(1.0, 0.9, 1.0))
	_piece("Crate_Wooden", Vector3(5.4, 0, -3.2), -14.0, yard, PROPS)
	_collider(yard, Vector3(5.4, 0.45, -3.2), Vector3(0.9, 0.9, 0.9))
	_piece("Chain_Coil", Vector3(2.8, 0, -5.6), 0.0, yard, PROPS)
	for side: float in [-1.0, 1.0]:
		_piece("Torch_Metal", Vector3(-6.4, 0, side * 3.0), 90.0, yard, PROPS)
		_piece("Banner_1", Vector3(side * 3.0, 0, 6.4), 180.0, yard, PROPS)


# --- 4. Tanière du colosse des ravins ---------------------------------------

## Le colosse détruit les couvertures et déplace la matière (§12.4). Son lieu
## ne se lit donc pas à ce qu'on y a POSÉ, mais à ce qui y a été DÉPLACÉ :
## blocs traînés en fer à cheval, sillon dans la terre, arbres brisés couchés
## dans le même sens, charrette écrasée. Les ossements sont des formes pâles
## abstraites — le lieu doit impressionner, pas être une boucherie.
func _build_colossus_lair() -> void:
	var before: int = _built
	colossus_lair = Node3D.new()
	colossus_lair.name = "TaniereDuColosse"
	colossus_lair.position = SITE_LAIR
	add_child(colossus_lair)

	_build_lair_hollow(colossus_lair)
	_build_lair_furrow(colossus_lair)
	_build_lair_broken_trees(colossus_lair)
	_build_lair_bones(colossus_lair)
	_build_lair_wreck(colossus_lair)

	lair_poi = _make_poi(colossus_lair, POI_LAIR,
		"Tanière du colosse des ravins", &"ravins", Vector3(0, 5, 2),
		Vector3(42, 14, 42))
	_counts[TERR_LAIR] = _built - before


## ANTRE : sept blocs énormes en fer à cheval, ouverture au SUD vers la
## vallée. La terre y est nue et tassée — rien n'y repousse.
func _build_lair_hollow(parent: Node3D) -> void:
	var hollow: Node3D = Node3D.new()
	hollow.name = "AntreDeRocaille"
	parent.add_child(hollow)
	_block(hollow, "SolTasse", Vector3(0, -0.25, 0), Vector3(17.0, 0.5, 17.0),
		COL_EARTH, true)
	lair_floor_y = SITE_LAIR.y

	var kinds: Array[String] = ["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"]
	var angles: Array[float] = [60.0, 100.0, 140.0, 180.0, 220.0, 260.0, 300.0]
	for i: int in range(angles.size()):
		var a: float = deg_to_rad(angles[i])
		var at: Vector3 = Vector3(sin(a) * 9.2, 0.0, cos(a) * 9.2)
		var rock: Node3D = _piece(kinds[i % kinds.size()], at,
			angles[i] + 30.0, hollow, ROCKS)
		if rock != null:
			rock.scale = Vector3.ONE * (3.2 + 0.45 * float(i % 3))
		_collider(hollow, at + Vector3(0, 2.6, 0), Vector3(5.2, 5.2, 5.2))
	_piece("Grass_Wispy_Tall", Vector3(-6.0, 0, 7.0), 40.0, hollow, FOLIAGE)


## SILLON : quelque chose de très lourd a été traîné depuis la plaine jusqu'à
## l'antre. La terre retournée n'a pas de collision — on marche dedans, on
## suit la trace, on comprend d'où vient la bête.
func _build_lair_furrow(parent: Node3D) -> void:
	var furrow: Node3D = Node3D.new()
	furrow.name = "SillonDeTraine"
	parent.add_child(furrow)
	for i: int in range(7):
		var t: float = float(i)
		var at: Vector3 = Vector3(2.0 + t * 1.1, 0.04, 11.0 + t * 3.4)
		_piece("RockPath_Round_Thin", at, 24.0 + t * 6.0, furrow, ROCKS)
		var stray: Vector3 = at + Vector3(3.0 - t * 0.35, -0.04, 1.2)
		var rock: Node3D = _piece("Rock_Medium_%d" % (1 + i % 3), stray,
			t * 41.0, furrow, ROCKS)
		var size: float = 1.7 - 0.15 * t
		if rock != null:
			rock.scale = Vector3.ONE * size
		_collider(furrow, stray + Vector3(0, size * 0.6, 0),
			Vector3(size * 1.4, size * 1.2, size * 1.4))


## ARBRES BRISÉS : couchés dans le MÊME sens que le sillon, plus deux troncs
## cassés net encore debout. Un abattage serait net et empilé ; ceci ne l'est pas.
func _build_lair_broken_trees(parent: Node3D) -> void:
	var trees: Node3D = Node3D.new()
	trees.name = "ArbresBrises"
	parent.add_child(trees)
	var fallen: Array[Vector3] = [
		Vector3(-8.0, 0, 13.0), Vector3(6.5, 0, 16.5),
		Vector3(-13.0, 0, 6.0), Vector3(11.5, 0, 4.5),
	]
	for i: int in range(fallen.size()):
		var kind: String = "DeadTree_1"
		if i % 2 == 1:
			kind = "DeadTree_2"
		_piece(kind, fallen[i], 30.0 + float(i) * 55.0, trees, FOLIAGE,
			Vector3(-64.0 - float(i) * 6.0, 0.0, 8.0))
		_collider(trees, fallen[i] + Vector3(0, 0.6, 0), Vector3(4.4, 1.2, 1.4))
	for i: int in range(2):
		var stump: Vector3 = Vector3(-3.5 + float(i) * 15.0, 0, 9.0)
		_piece("TwistedTree_2", stump, float(i) * 88.0, trees, FOLIAGE)
		_collider(trees, stump + Vector3(0, 1.0, 0), Vector3(1.0, 2.0, 1.0))


## OSSEMENTS STYLISÉS : deux arcs de fuseaux pâles plantés en terre, deux
## pièces longues couchées. Des formes, pas une carcasse.
func _build_lair_bones(parent: Node3D) -> void:
	var bones: Node3D = Node3D.new()
	bones.name = "OssementsStylises"
	parent.add_child(bones)
	for arc: int in range(2):
		var centre: Vector3 = Vector3(-4.5 + float(arc) * 9.5, 0.0,
			4.0 - float(arc) * 3.5)
		for rib: int in range(5):
			var t: float = float(rib) - 2.0
			_bone(bones, centre + Vector3(t * 0.85, 0.95, 0.0),
				2.2 - absf(t) * 0.25, 0.11,
				Vector3(0.0, 20.0 * float(arc), 13.0 * t))
	_bone(bones, Vector3(1.5, 0.14, 7.5), 3.4, 0.16, Vector3(90.0, 24.0, 0.0))
	_bone(bones, Vector3(-2.2, 0.14, -5.5), 2.8, 0.14, Vector3(90.0, -37.0, 0.0))


## CHARRETTE ÉCRASÉE : ce que la bête a traîné jusqu'ici. Elle relie la
## tanière au reste du monde — les convois passent, celui-ci n'est pas passé.
func _build_lair_wreck(parent: Node3D) -> void:
	var wreck: Node3D = Node3D.new()
	wreck.name = "CharretteBrisee"
	wreck.position = Vector3(7.5, 0.0, 12.5)
	parent.add_child(wreck)
	_piece("Prop_Wagon", Vector3.ZERO, 34.0, wreck, "", Vector3(0.0, 0.0, 38.0))
	_collider(wreck, Vector3(0, 0.7, 0), Vector3(2.6, 1.4, 1.8))
	_piece("Crate_Wooden", Vector3(2.2, 0, 1.1), 63.0, wreck, PROPS,
		Vector3(24.0, 0.0, 12.0))
	_piece("Barrel", Vector3(-1.9, 0.35, 1.6), 0.0, wreck, PROPS,
		Vector3(0.0, 0.0, 90.0))
	_piece("Bag", Vector3(1.2, 0, -1.7), 20.0, wreck, PROPS)
	_piece("Pebble_Square_2", Vector3(-2.6, 0, -1.2), 70.0, wreck, ROCKS)


# --- 5. Territoire du chasseur quadrupède -----------------------------------

## Le chasseur est FACULTATIF (§12.5) : le joueur doit pouvoir décider de ne
## pas entrer. Cela n'a de sens que si la frontière se voit de l'extérieur.
## Douze balises plantées sur un cercle de 26 m, chacune avec sa perche, sa
## banderole et son cairn — trois signaux pour une seule information, jamais
## la couleur seule (§17.4). À l'intérieur : armes brisées fichées en terre,
## sol labouré, bois mort, et un tell de pierre d'où la bête surveille.
func _build_hunter_range() -> void:
	var before: int = _built
	hunter_range = Node3D.new()
	hunter_range.name = "TerritoireDuChasseur"
	hunter_range.position = SITE_HUNTER
	add_child(hunter_range)

	_build_hunter_frontier(hunter_range)
	_build_hunter_mound(hunter_range)
	_build_hunter_trophies(hunter_range)
	_build_hunter_scars(hunter_range)

	hunter_poi = _make_poi(hunter_range, POI_HUNTER,
		"Territoire du chasseur", &"confins_sud_est", Vector3(0, 6, 0),
		Vector3(54, 14, 54))
	_counts[TERR_HUNTER] = _built - before


func _build_hunter_frontier(parent: Node3D) -> void:
	var frontier: Node3D = Node3D.new()
	frontier.name = "FrontiereBalisee"
	parent.add_child(frontier)
	_frontier_marks.clear()
	for i: int in range(FRONTIER_MARKS):
		var angle: float = TAU * float(i) / float(FRONTIER_MARKS)
		var at: Vector3 = Vector3(cos(angle) * FRONTIER_RADIUS, 0.0,
			sin(angle) * FRONTIER_RADIUS)
		_frontier_marks.append(SITE_HUNTER + at)
		var mark: Node3D = Node3D.new()
		mark.name = "Balise%02d" % (i + 1)
		mark.position = at
		mark.rotation_degrees = Vector3(0, rad_to_deg(angle), 0)
		frontier.add_child(mark)
		# Perche haute : elle se voit de loin, et elle est PHYSIQUE — un
		# avertissement qu'on traverse n'avertit personne.
		var post: Node3D = _piece("Prop_Support", Vector3.ZERO, 0.0, mark)
		if post != null:
			post.scale = Vector3(1.0, 1.7, 1.0)
		_collider(mark, Vector3(0, 2.0, 0), Vector3(0.4, 4.0, 0.4))
		_piece("Banner_2_Cloth", Vector3(0.35, 2.6, 0.0), 90.0, mark, PROPS)
		_piece("Pebble_Square_1", Vector3(-0.9, 0.0, 0.5), float(i) * 31.0,
			mark, ROCKS)


## TELL : trois assises de pierre. Ce qu'on lit de loin, c'est la HAUTEUR —
## la bête domine son terrain, et on la voit avant qu'elle ne charge.
func _build_hunter_mound(parent: Node3D) -> void:
	var mound: Node3D = Node3D.new()
	mound.name = "MonticuleDuChasseur"
	parent.add_child(mound)
	_block(mound, "Assise", Vector3(0, 0.4, 0), Vector3(11.0, 0.8, 11.0),
		COL_STONE, true)
	_block(mound, "Gradin", Vector3(0, 1.2, 0), Vector3(7.6, 0.8, 7.6),
		COL_STONE, true)
	_block(mound, "Sommet", Vector3(0, 2.0, 0), Vector3(4.6, 0.8, 4.6),
		COL_STONE, true)
	hunter_mound_y = SITE_HUNTER.y + 2.4
	_piece("WeaponStand", Vector3(1.2, 2.4, -0.8), 24.0, mound, PROPS)
	_piece("Banner_1", Vector3(-1.4, 2.4, 0.9), 0.0, mound, PROPS)
	_piece("Chain_Coil", Vector3(0.5, 2.4, 1.5), 0.0, mound, PROPS)


## TROPHÉES : des armes brisées fichées en terre autour du tell, calées par
## des pierres. Menaçant, lisible, et sans un cadavre à l'écran.
func _build_hunter_trophies(parent: Node3D) -> void:
	var trophies: Node3D = Node3D.new()
	trophies.name = "TropheesPlantes"
	parent.add_child(trophies)
	var arms: Array[String] = [
		"Sword_Bronze", "Axe_Bronze", "Sword_Bronze", "Shield_Wooden",
		"Axe_Bronze", "Sword_Bronze", "Shield_Wooden",
	]
	for i: int in range(arms.size()):
		var angle: float = TAU * float(i) / float(arms.size()) + 0.4
		var radius: float = 9.0 + float(i % 3) * 2.4
		var at: Vector3 = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		_piece(arms[i], at + Vector3(0, 0.55, 0), rad_to_deg(angle), trophies,
			PROPS, Vector3(0.0, 0.0, 12.0 + float(i) * 7.0))
		_piece("Pebble_Round_%d" % (1 + i % 5), at + Vector3(0.45, 0.0, 0.3),
			float(i) * 47.0, trophies, ROCKS)
		_collider(trophies, at + Vector3(0, 0.55, 0), Vector3(0.5, 1.1, 0.5))


## SOL LABOURÉ et BOIS MORT : rien de vert, rien d'accueillant. Les gouges
## sont parallèles et vont toutes vers le tell.
func _build_hunter_scars(parent: Node3D) -> void:
	var scars: Node3D = Node3D.new()
	scars.name = "SolLaboure"
	parent.add_child(scars)
	# Les gouges courent à l'OUEST du tell : posées dessous, elles seraient
	# enterrées dans son assise (11 m de côté) et ne se verraient jamais.
	for lane: int in range(3):
		for step: int in range(3):
			var at: Vector3 = Vector3(-18.0 + float(step) * 4.0,
				0.04, -6.0 + float(lane) * 5.5)
			_piece("RockPath_Round_Thin", at, 18.0 + float(lane) * 5.0,
				scars, ROCKS)
	var dead: Array[Vector3] = [
		Vector3(15.0, 0, -12.0), Vector3(-17.0, 0, 9.0), Vector3(6.0, 0, 17.0),
	]
	for i: int in range(dead.size()):
		_piece("DeadTree_2", dead[i], float(i) * 97.0, scars, FOLIAGE,
			Vector3(float(i) * 7.0, 0.0, -4.0))
		_collider(scars, dead[i] + Vector3(0, 1.2, 0), Vector3(0.9, 2.4, 0.9))
	_piece("TwistedTree_3", Vector3(-10.0, 0, -15.0), 130.0, scars, FOLIAGE)
	_piece("Grass_Wispy_Short", Vector3(11.0, 0, 12.0), 0.0, scars, FOLIAGE)
	_piece("Rock_Medium_3", Vector3(-6.0, 0, 14.0), 65.0, scars, ROCKS)
	_collider(scars, Vector3(-6.0, 0.6, 14.0), Vector3(1.6, 1.2, 1.6))


# --- Déclaration au journal des découvertes ---------------------------------

## Chaque territoire se DÉCLARE : identifiant stable §19.3, nom affiché,
## région. Le volume d'approche est large (le lieu se découvre en y arrivant,
## pas en marchant sur un point précis) mais reste borné à son emprise.
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
	RewardAnchor.attach_from_table(parent, poi_id, ANCHORS, "territoires")
	return poi


## Caisse métallique chargeable (P2-3, camp trois approches) : l'approche
## « environnement » — cible légitime de Polarité (projeter) et de Ground
## (neutraliser). Butin de pillards : du métal récupéré, cabossé.
func _metal_crate(camp: Node3D, at: Vector3) -> void:
	var crate: RigidBody3D = RigidBody3D.new()
	crate.name = "CaisseMetal"
	crate.mass = 35.0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.7, 0.7, 0.7)
	shape.shape = box
	crate.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(0.7, 0.7, 0.7)
	mesh.mesh = box_mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.36, 0.35, 0.33)
	material.metallic = 0.7
	material.roughness = 0.55
	mesh.material_override = material
	crate.add_child(mesh)
	var state: MaterialStateComponent = MaterialStateComponent.new()
	state.name = "MaterialStateComponent"
	state.profile = load("res://resources/materials/MAT_PROFILE_metal.tres") \
		as MaterialProfile
	crate.add_child(state)
	var marker: ResonanceTargetComponent = ResonanceTargetComponent.new()
	marker.kind = &"polarity"
	crate.add_child(marker)
	camp.add_child(crate)
	crate.position = at
	_built += 1
