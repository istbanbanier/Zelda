## RUINES DE LA VALLÉE — quatre lieux qui racontent sans une ligne de texte.
##
## Ordre d'extension §2 : « plusieurs ensembles de ruines explorables ». La
## règle centrale n'est pas le nombre de murs posés — c'est que la COMPOSITION
## dise ce qui s'est passé. Une pierre debout ne raconte rien ; une pierre
## tombée dans une direction raconte une chute.
##
## Les quatre ruines, et ce que chacune raconte :
##
##   - `TourDeGuet` (falaise ouest) — la tour a basculé vers le NORD-EST : les
##     murs sud et ouest montent encore à deux étages, les faces nord et est
##     n'ont plus qu'une assise, et le cône de toiture gît dans l'herbe au bout
##     d'une traînée de briques qui s'éclaircit avec la distance. Le lierre ne
##     pousse que sur la moitié restée debout. RAISON D'Y ALLER : le plancher
##     du premier étage a survécu au-dessus des murs survivants — on y monte
##     par l'éboulis et on domine la vallée (belvédère).
##
##   - `Aqueduc` (rivière) — la pile centrale a été emportée : l'arcade s'arrête
##     net des deux côtés de l'eau, le canal est à sec et l'herbe y pousse. La
##     travée manquante est tombée EN AVAL, en travers du lit. RAISON D'Y ALLER :
##     cette travée couchée est un pont — la seule traversée de l'ouest, loin
##     des deux gués. Un échafaudage abandonné au pied d'une pile dit qu'on a
##     essayé de réparer, et le canal pointe vers la citadelle.
##
##   - `FermeAbandonnee` (plaine sud) — on est parti vite : la porte a été
##     arrachée et gît dans la cour, le repas est resté sur la table, une chaise
##     est renversée, les outils sont tombés là où ils servaient, la clôture est
##     trouée et le champ est repris par la broussaille. RAISON D'Y ALLER : la
##     maison est un VRAI abri, entièrement creux, où l'on entre par la baie.
##
##   - `CaravaneFoudroyee` (route du donjon) — le seul désastre RÉCENT : rien
##     n'a repoussé sur la brûlure. L'arbre fendu marque l'impact, le chariot de
##     tête est couché, la cargaison est projetée en éventail dans une seule
##     direction, et une traînée d'objets abandonnés part vers le NORD : les
##     survivants ont continué vers la citadelle. RAISON D'Y ALLER : l'arme du
##     garde est restée sur place, et la traînée est un indice de direction.
##
## §1 est catégorique : ce qui paraît ouvert doit l'être. Les arches de
## l'aqueduc, la brèche de la tour et la baie de la ferme ne portent AUCUNE
## collision en travers — seules les piles, les jambages et les murs pleins en
## ont une. Chaque ruine se déclare au `DiscoveryLog` par son `PointOfInterest`,
## avec un identifiant §19.3 stable.
class_name ValleyRuins
extends Node3D

## Le kit modulaire est réparti sur cinq dossiers (deux lots d'architecture,
## puis props, feuillage et rochers). Une pièce se résout par RECHERCHE, jamais
## par chemin figé : déplacer un asset d'un lot à l'autre casserait les ruines
## en silence.
const KIT_DIRS: Array[String] = [
	"res://assets/environment/village/%s.gltf",
	"res://assets/environment/dungeon/%s.gltf",
	"res://assets/environment/props/%s.gltf",
	"res://assets/environment/foliage/%s.gltf",
	"res://assets/environment/rocks/%s.gltf",
]

## Pas du kit Quaternius, mesuré sur les modules : murs et sols de 2 m.
const MODULE: float = 2.0
## Hauteur d'un mur, mesurée elle aussi (3,12 m).
const WALL_H: float = 3.12
## Largeur laissée libre dans une baie de porte : le joueur passe.
const DOOR_GAP: float = 1.30
## Hauteur d'une marche d'éboulis. §8.2 plafonne le step height à 0,30–0,38 m :
## une ruine ne doit pas devenir une échelle.
const STEP_RISE: float = 3.12 / 9.0
const STEP_RUN: float = 0.55

## Implantations, en coordonnées MONDE (ce nœud reste à l'origine ; chaque
## ruine porte sa propre position). Repères du relief : plaine sud y = 2 pour
## z ≥ 16, plaine nord y = 2 pour z ≤ -4, lit de rivière à z = 10, plateau de
## la falaise d'apprentissage à y = 14. Aucune ne chevauche le village de la
## rivière (-70, 2, 36), le camp (45, 6, 65) ni les ruines centrales.
const SITE_WATCHTOWER: Vector3 = Vector3(-128.0, 14.0, 82.0)
const SITE_AQUEDUCT: Vector3 = Vector3(-12.0, 2.0, 10.0)
const SITE_FARM: Vector3 = Vector3(-16.0, 2.0, 78.0)
const SITE_CARAVAN: Vector3 = Vector3(-38.0, 2.0, -120.0)

## Identifiants §19.3 : `zone.category.name.index`. Quatre lieux DISTINCTS —
## un doublon ferait qu'une ruine se déclarerait découverte à la place d'une
## autre (`DiscoveryLog.register` le refuse, mais mieux vaut ne pas essayer).
const POI_WATCHTOWER: StringName = &"valley.poi.watchtower_ruin.01"
const POI_AQUEDUCT: StringName = &"valley.poi.ancient_aqueduct.01"
const POI_FARM: StringName = &"valley.poi.abandoned_farm.01"
const POI_CARAVAN: StringName = &"valley.poi.storm_caravan.01"

## ANCRAGES de récompense (contrat `RewardAnchor`). Positions éprouvées par
## `tools/godot/probe_reward_anchors.gd` dans la vallée montée, puis figées.
const ANCHORS: Dictionary = {
	POI_WATCHTOWER: {
		"at": Vector3(2.0, 0.0, -2.0), "approach": Vector3(5.0, 0.0, -2.0),
		"kind": RewardAnchor.Kind.CHEST,
	},
	POI_AQUEDUCT: {
		"at": Vector3(4.40, 0.0, 0.0), "approach": Vector3(7.40, 0.0, 0.0),
		"kind": RewardAnchor.Kind.STORY,
	},
	POI_FARM: {
		"at": Vector3(4.0, 0.0, 2.0), "approach": Vector3(7.0, 0.0, 2.0),
		"kind": RewardAnchor.Kind.INGREDIENT,
	},
	POI_CARAVAN: {
		"at": Vector3(0.0, 0.0, -4.0), "approach": Vector3(3.0, 0.0, -4.0),
		"kind": RewardAnchor.Kind.CHEST,
	},
}

## Noms des quatre nœuds de ruine, dans l'ordre de construction.
const RUIN_NODES: Array[String] = [
	"TourDeGuet", "Aqueduc", "FermeAbandonnee", "CaravaneFoudroyee",
]

## Teintes de la brûlure de foudre (§3.4 : ocres et bruns froids, pas de noir
## pur — un trou noir dans l'herbe se lit comme un défaut de rendu).
const COL_SCORCH: Color = Color(0.24, 0.20, 0.17)
const COL_SCORCH_CORE: Color = Color(0.13, 0.11, 0.10)

## Points d'intérêt des quatre ruines, dans l'ordre de `RUIN_NODES`.
var pois: Array[PointOfInterest] = []
## Cote du plancher intérieur de la ferme — la preuve physique s'y réfère.
var farmhouse_floor_y: float = 0.0
## Cote du belvédère de la tour (plancher du premier étage rescapé).
var watchtower_lookout_y: float = 0.0
## Cote du tablier du pont formé par la travée tombée.
var aqueduct_crossing_y: float = 0.0

## Nombre de pièces du kit RÉELLEMENT instanciées. Les volumes que ce script
## fabrique lui-même (collisions, brûlures, repères) n'y entrent pas : le
## compteur doit rester une preuve que les assets se résolvent.
var _built: int = 0
## Assets manquants déjà signalés — un avertissement par asset, pas par pose.
var _missing: Dictionary = {}


func _ready() -> void:
	_build_watchtower()
	_build_aqueduct()
	_build_farm()
	_build_caravan()


func piece_count() -> int:
	return _built


## Ruine par son nom de nœud, pour les tests et le monde.
func ruin(node_name: String) -> Node3D:
	return get_node_or_null(NodePath(node_name)) as Node3D


func poi_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for place: PointOfInterest in pois:
		ids.append(place.poi_id)
	return ids


## Déclare les quatre ruines au journal. `ValleyWorld` fait déjà cette liaison
## en parcourant ses `PointOfInterest` ; cette méthode sert aux scènes et aux
## tests qui montent les ruines seules.
func bind_all(discovery_log: DiscoveryLog) -> int:
	var bound: int = 0
	for place: PointOfInterest in pois:
		place.bind(discovery_log)
		if place.is_bound():
			bound += 1
	return bound


# --- Briques ----------------------------------------------------------------

## Instancie une pièce du kit. Renvoie `null` si l'asset manque, sans lever :
## une ruine amputée d'un modèle doit rester chargeable et le dire.
func _spawn(asset: String, at: Vector3, rot_deg: Vector3, parent: Node3D,
		path: String = "", factor: float = 1.0) -> Node3D:
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
		if not _missing.has(asset):
			_missing[asset] = true
			push_warning("[ruines] pièce absente du kit : %s" % asset)
		return null
	var node: Node3D = packed.instantiate() as Node3D
	# Nom unique : deux pièces homonymes sous le même parent seraient renommées
	# en `@…@` par le moteur, et plus aucun test ne pourrait les désigner.
	node.name = "%s_%03d" % [asset, _built]
	node.position = at
	node.rotation_degrees = rot_deg
	# §3 : correction d'échelle du kit végétal, point unique (`KitScale`).
	var corrected: float = factor * KitScale.factor(asset)
	if not is_equal_approx(corrected, 1.0):
		node.scale = Vector3.ONE * corrected
	# « Rien ne flotte » : une partie du kit a son origine SOUS sa
	# géométrie (Prop_Support commence à +1,21 m). Sans cette
	# correction, l'objet est suspendu en l'air. Voir KitPlacement.
	KitPlacement.seat(node, node.scene_file_path)
	(parent if parent != null else self).add_child(node)
	_built += 1
	return node


## Pose droite : le cas courant.
func _piece(asset: String, at: Vector3, yaw_deg: float, parent: Node3D) -> Node3D:
	return _spawn(asset, at, Vector3(0.0, yaw_deg, 0.0), parent)


## Collision explicite : le kit est purement visuel. Une boîte statique est
## posée à la main, ce qui permet de LAISSER un trou là où la ruine paraît
## ouverte — un collider unique par façade murerait la brèche.
func _wall_collider(parent: Node3D, centre: Vector3, size: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Bloc%03d" % parent.get_child_count()
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


## Mur À BAIE : deux jambages et un linteau, le passage reste libre. C'est ce
## qui distingue un abri réel d'une façade décorative.
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


## Décor : liste uniforme `[asset, position, rotation, échelle, collision]`.
## Une caisse éventrée barre le passage comme une caisse ; une fleur ne barre
## rien — d'où la collision explicite, entrée par entrée (Vector3.ZERO = aucune).
func _dressing(parent: Node3D, entries: Array[Array]) -> void:
	for entry: Array in entries:
		var at: Vector3 = entry[1] as Vector3
		_spawn(String(entry[0]), at, entry[2] as Vector3, parent, "",
			float(entry[3]))
		var collision: Vector3 = entry[4] as Vector3
		if collision != Vector3.ZERO:
			_wall_collider(parent, at + Vector3(0, collision.y * 0.5, 0),
				collision)


## Sol porteur invisible : les modules de plancher du kit n'ont pas de
## collision, et un « intérieur » sans sol est un mensonge.
func _slab_collider(parent: Node3D, centre: Vector3, size: Vector3) -> void:
	_wall_collider(parent, centre, size)


## Brûlure au sol : aplat sombre sans collision. Le seul moyen, avec ce kit, de
## dire « la foudre est tombée ICI » — les modèles ne portent pas de traces.
func _scorch(parent: Node3D, at: Vector3, radius: float, tone: Color) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "Brulure%03d" % parent.get_child_count()
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.06
	disc.radial_segments = 24
	mesh.mesh = disc
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = tone
	material.roughness = 0.98
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)


## Repère nommé : ancrage de récompense, belvédère, passage. Ce script ne pose
## AUCUN gameplay (§ le point d'intérêt n'est pas un coffre déguisé) ; il
## expose des positions que le monde peut habiller.
func _marker(parent: Node3D, marker_name: String, at: Vector3) -> Marker3D:
	var marker: Marker3D = Marker3D.new()
	marker.name = marker_name
	marker.position = at
	parent.add_child(marker)
	return marker


## Déclare une ruine au monde : identifiant stable, nom affiché, région.
func _place_poi(parent: Node3D, poi_id: StringName, display: String,
		region: StringName, centre: Vector3, extents: Vector3) -> PointOfInterest:
	var place: PointOfInterest = PointOfInterest.new()
	place.name = "PointDInteret"
	place.poi_id = poi_id
	place.display_name = display
	place.region = region
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = extents
	shape.shape = box
	place.add_child(shape)
	place.position = centre
	parent.add_child(place)
	pois.append(place)
	RewardAnchor.attach_from_table(parent, poi_id, ANCHORS, "ruines")
	return place


## Racine d'une ruine : position posée AVANT l'entrée dans l'arbre.
func _site(node_name: String, at: Vector3) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = node_name
	root.position = at
	add_child(root)
	return root


# --- 1. TOUR DE GUET EFFONDRÉE ----------------------------------------------

## Plateau de la falaise d'apprentissage, à l'écart du sanctuaire (-108, 14, 62).
##
## Tout le récit tient dans une asymétrie : le sud et l'ouest montent, le nord
## et l'est sont tombés. La brèche du rez-de-chaussée n'est pas une porte —
## c'est l'endroit où le mur n'est plus là, et c'est par là qu'on entre.
func _build_watchtower() -> void:
	var tower: Node3D = _site("TourDeGuet", SITE_WATCHTOWER)
	var face: float = 4.0          # emprise 8 × 8 m (4 modules de côté)
	var slots: Array[float] = [-3.0, -1.0, 1.0, 3.0]

	# Plancher du rez-de-chaussée et sol porteur.
	for x: float in slots:
		for z: float in slots:
			_piece("Floor_UnevenBrick", Vector3(x, 0.02, z), 0.0, tower)
	_slab_collider(tower, Vector3(0, -0.25, 0), Vector3(8.4, 0.5, 8.4))

	# Rez-de-chaussée : sud et ouest complets ; nord et est réduits à leur
	# module d'angle — la brèche fait 6 m de large, on y entre de plain-pied.
	for x: float in slots:
		_wall(tower, Vector3(x, 0, face), 0.0, "Wall_UnevenBrick_Straight")
	for z: float in slots:
		_wall(tower, Vector3(-face, 0, z), 90.0,
			"Wall_UnevenBrick_Window_Thin_Round" if z > 0.0
			else "Wall_UnevenBrick_Straight")
	_wall(tower, Vector3(-3.0, 0, -face), 180.0, "Wall_UnevenBrick_Straight")
	_wall(tower, Vector3(face, 0, 3.0), 270.0, "Wall_UnevenBrick_Straight")

	# Premier étage : seules les deux façades debout. Elles ferment le belvédère
	# au sud et à l'ouest et laissent la vue ouverte au nord et à l'est.
	for x: float in slots:
		_wall(tower, Vector3(x, WALL_H, face), 0.0, "Wall_UnevenBrick_Straight")
	for z: float in slots:
		_wall(tower, Vector3(-face, WALL_H, z), 90.0,
			"Wall_UnevenBrick_Window_Wide_Round" if z < 0.0
			else "Wall_UnevenBrick_Straight")

	# Deuxième étage : un moignon d'angle sud-ouest, cassé net.
	for x: float in [-3.0, -1.0]:
		_wall(tower, Vector3(x, WALL_H * 2.0, face), 0.0,
			"Wall_UnevenBrick_Straight")
	for z: float in [3.0, 1.0]:
		_wall(tower, Vector3(-face, WALL_H * 2.0, z), 90.0,
			"Wall_UnevenBrick_Straight")

	# ÉBOULIS PRATICABLE : les pierres du mur nord se sont empilées contre la
	# façade ouest et forment la seule montée. Neuf marches de 0,347 m — sous
	# le plafond de §8.2. C'est l'effondrement lui-même qui donne l'accès.
	for i: int in range(9):
		var top: float = float(i + 1) * STEP_RISE
		var z: float = -3.4 + float(i) * STEP_RUN
		_wall_collider(tower, Vector3(-3.0, top - 0.2, z),
			Vector3(1.6, 0.4, 1.1))
		_spawn("RockPath_Square_Wide" if i % 2 == 0 else "RockPath_Round_Wide",
			Vector3(-3.0, top - 0.06, z), Vector3(0, float(i) * 37.0, 0), tower,
			"", 1.1)

	# BELVÉDÈRE : le plancher du premier étage a tenu là où ses murs ont tenu.
	# 6 × 2 m au-dessus des façades sud et ouest — la raison de monter.
	#
	# CORRECTIF (revue 117) — le plancher était centré en z = 2,0, donc il
	# s'arrêtait à z = 3,0 ; le mur sud du premier étage (z = 4,0, épaisseur de
	# collision 0,4) commence à z = 3,8. Il restait une FENTE de 0,80 m sur les
	# 6 m du belvédère, à 3,12 m de haut : la capsule du joueur (r = 0,35 m,
	# donc 0,70 m de diamètre, scenes/player/Player.tscn) y tombait en allant
	# regarder la vallée. Décalé à z = 2,6 : le plancher couvre z 1,6..3,6, il
	# ne reste que 0,20 m contre le mur (infranchissable) et 0,05 m côté
	# éboulis, dont le dernier bloc va jusqu'à z = 1,55. Le bord EST (x = 2)
	# n'est PAS touché : il est ouvert par intention, comme le nord.
	for x: float in [-3.0, -1.0, 1.0]:
		_piece("Floor_Brick", Vector3(x, WALL_H + 0.02, 2.6), 0.0, tower)
	_wall_collider(tower, Vector3(-1.0, WALL_H - 0.2, 2.6),
		Vector3(6.0, 0.4, 2.0))
	watchtower_lookout_y = SITE_WATCHTOWER.y + WALL_H
	_marker(tower, "Belvedere", Vector3(-1.0, WALL_H + 0.1, 2.0))
	_marker(tower, "AncrageRecompense", Vector3(-2.6, WALL_H + 0.1, 2.4))

	# LA CHUTE : le cône de toiture gît au bout de la traînée, au nord-est.
	#
	# CORRECTIF (revue 117) — posé à y = 0,5, le cône (5,65 × 7,36 × 5,43 m
	# mesurés) basculé à 76° descendait jusqu'à y = −2,27 : plus de deux mètres
	# avalés par le terrain, alors que le récit dit qu'il « gît dans l'herbe ».
	# Remonté de 1,9 m : le point bas passe à −0,37 m, soit à peine enfoncé,
	# ce qui est bien l'effet voulu.
	_spawn("Roof_Tower_RoundTiles", Vector3(11.5, 2.4, -11.0),
		Vector3(76.0, 34.0, 0.0), tower)
	# Trois pans de mur couchés, de plus en plus loin et de plus en plus enfouis.
	var fallen: Array[Array] = [
		["Wall_UnevenBrick_Straight", Vector3(5.6, 0.18, -5.4),
			Vector3(88.0, 24.0, 0.0), 1.0, Vector3.ZERO],
		["Wall_UnevenBrick_Straight", Vector3(8.4, 0.12, -8.2),
			Vector3(92.0, -12.0, 0.0), 1.0, Vector3.ZERO],
		["Wall_UnevenBrick_Window_Wide_Round", Vector3(7.0, 0.08, -12.0),
			Vector3(94.0, 51.0, 0.0), 1.0, Vector3.ZERO],
		# CORRECTIF (revue 117) — à 84° de tangage, l'axe réel de la poutre
		# (diagonale locale (0 ; 1,709 ; 2,036) de `Prop_Support`) plongeait :
		# ses deux bouts tombaient à y = +0,22 et y = −1,63, la poutre était
		# plantée dans le sol aux deux tiers. 40° est l'angle qui met cet axe à
		# l'horizontale — 1,7086·cos40 − 2,0363·sin40 ≈ 0 — et, l'assise de
		# `KitPlacement` retirant 0,928 m, la poutre repose à plat à y ≈ 0,18.
		["Prop_Support", Vector3(4.2, 0.1, -7.6), Vector3(40.0, 8.0, 0.0),
			1.0, Vector3.ZERO],
	]
	_dressing(tower, fallen)
	# Traînée de gravats : dense au pied de la brèche, clairsemée au loin.
	# Distribution DÉTERMINISTE (angle d'or), jamais un aléa — deux chargements
	# de la vallée doivent donner exactement la même ruine.
	var debris: Array[String] = [
		"Prop_Brick1", "Pebble_Square_1", "Pebble_Round_2", "Rock_Medium_3",
		"Pebble_Square_2", "Prop_Brick1", "Rock_Medium_1",
	]
	for i: int in range(18):
		var spread: float = 4.0 + float(i) * 0.85
		var swing: float = sin(float(i) * 2.399) * (1.4 + float(i) * 0.22)
		var at: Vector3 = Vector3(spread * 0.72 + swing, 0.0,
			-spread * 0.72 + swing * 0.6)
		_spawn(debris[i % debris.size()], at,
			Vector3(0, float(i) * 47.0, 0), tower, "",
			1.25 - 0.04 * float(i % 6))

	# LA MOITIÉ DEBOUT REVERDIT : le lierre ne monte que là où il y a un mur.
	#
	# CORRECTIF (revue 117) — `Prop_Vine1` et `Prop_Vine2` ont leur origine au
	# POINT D'ACCROCHE : la plante pend SOUS elle (bbox y = −2,1205..+0,4820,
	# mesurée). C'est le piège symétrique de `Prop_Support`, et `KitPlacement`
	# ne le corrige pas — sa règle (l. 20-26) est de ne JAMAIS remonter un
	# modèle qui descend sous son ancrage, faute de connaître l'intention.
	# Posés à y = 0, ces lierres étaient donc enterrés à 82 % : il n'en
	# dépassait que 0,48 m. Accrochés à y = WALL_H, ils occupent y 1,00..3,60,
	# c'est-à-dire du lierre sur le mur. La seule pose déjà correcte du bloc
	# est la quatrième, laissée telle quelle.
	#
	# Le décalage horizontal ne vaut que pour les poses à yaw 90 : le modèle
	# est plaqué le long de son axe X local, donc à yaw 90 son épaisseur part
	# vers +X et il faut reculer de 0,21 m pour affleurer le parement OUEST
	# (x = −4,314). À yaw 0 ou 180 (murs sud et nord) la pose actuelle laisse
	# déjà 0,013 m de jeu contre le parement : on n'y touche pas.
	var life: Array[Array] = [
		["Prop_Vine1", Vector3(-4.36, WALL_H, 1.0), Vector3(0, 90, 0), 1.0,
			Vector3.ZERO],
		["Prop_Vine2", Vector3(-4.36, WALL_H, -2.4), Vector3(0, 90, 0), 1.0,
			Vector3.ZERO],
		["Prop_Vine1", Vector3(1.2, WALL_H, 4.15), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Prop_Vine2", Vector3(-2.8, WALL_H, 4.15), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Bush_Common", Vector3(-5.6, 0.0, 3.2), Vector3(0, 22, 0), 1.1,
			Vector3.ZERO],
		["Bush_Common_Flowers", Vector3(-5.2, 0.0, -1.6), Vector3(0, 140, 0),
			1.0, Vector3.ZERO],
		["Fern_1", Vector3(-3.4, 0.02, 3.4), Vector3(0, 60, 0), 1.0,
			Vector3.ZERO],
		["Grass_Common_Tall", Vector3(2.6, 0.02, -3.6), Vector3(0, 10, 0), 1.0,
			Vector3.ZERO],
		["Grass_Common_Tall", Vector3(6.4, 0.0, -6.8), Vector3(0, 200, 0), 1.0,
			Vector3.ZERO],
		["Grass_Wispy_Tall", Vector3(9.6, 0.0, -9.4), Vector3(0, 300, 0), 1.0,
			Vector3.ZERO],
		["Grass_Wispy_Short", Vector3(13.0, 0.0, -13.5), Vector3(0, 80, 0), 1.0,
			Vector3.ZERO],
		["TwistedTree_1", Vector3(-9.5, 0.0, -6.0), Vector3(0, 130, 0), 1.0,
			Vector3.ZERO],
		["Flower_3_Group", Vector3(-6.4, 0.02, 0.6), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
	]
	_dressing(tower, life)

	# LE POSTE ABANDONNÉ : on veillait ici, on n'y veille plus. Le brasier de
	# signal est renversé DEHORS, du côté de la chute.
	var post: Array[Array] = [
		["Cauldron", Vector3(6.8, 0.25, -3.4), Vector3(74.0, 20.0, 0.0), 1.0,
			Vector3.ZERO],
		["Torch_Metal", Vector3(2.2, 0.05, -2.0), Vector3(86.0, 40.0, 0.0), 1.0,
			Vector3.ZERO],
		["Lantern_Wall", Vector3(-3.75, 1.9, 0.0), Vector3(0, 90, 0), 1.0,
			Vector3.ZERO],
		["Bench", Vector3(-1.6, 0.05, 3.2), Vector3(0, 0, 0), 1.0,
			Vector3(1.6, 0.5, 0.6)],
		["Barrel", Vector3(2.6, 0.3, 3.2), Vector3(0, 0, 96.0), 1.0,
			Vector3.ZERO],
		["Crate_Wooden", Vector3(1.0, 0.05, 2.2), Vector3(0, 18, 0), 1.0,
			Vector3(1.0, 1.0, 1.0)],
		["Shield_Wooden", Vector3(-2.2, 0.4, 3.7), Vector3(0, 0, 68.0), 1.0,
			Vector3.ZERO],
		["Chain_Coil", Vector3(-0.4, 0.05, 1.2), Vector3(0, 55, 0), 1.0,
			Vector3.ZERO],
		["Banner_1_Cloth", Vector3(-2.4, WALL_H + 0.06, 2.6),
			Vector3(88.0, 12.0, 0.0), 1.0, Vector3.ZERO],
		# Suit le plancher du belvédère décalé à z = 2,6 : à z = 1,4 la pile de
		# livres se serait retrouvée dans le vide, hors dalle (z 1,6..3,6).
		["Book_Stack_1", Vector3(-3.0, WALL_H + 0.06, 1.8), Vector3(0, 30, 0),
			1.0, Vector3.ZERO],
		["Bottle_1", Vector3(0.6, WALL_H + 0.06, 2.2), Vector3(0, 0, 82.0), 1.0,
			Vector3.ZERO],
	]
	_dressing(tower, post)

	_place_poi(tower, POI_WATCHTOWER, "Tour de guet effondrée", &"falaise",
		Vector3(2.0, 5.0, -2.0), Vector3(38.0, 16.0, 38.0))


# --- 2. AQUEDUC ANCIEN ------------------------------------------------------

## Il enjambait la rivière (lit à z = 10) et menait l'eau vers le nord, donc
## vers la citadelle. La pile qui tenait dans le courant a cédé : l'arcade
## s'interrompt des deux côtés de l'eau et la travée manquante gît EN AVAL, en
## travers du lit. Elle sert désormais de pont — c'est la seule traversée de
## l'ouest, les deux gués étant à x = 20 et x = 95.
func _build_aqueduct() -> void:
	var aqueduct: Node3D = _site("Aqueduc", SITE_AQUEDUCT)
	# Repère local : y = 0 est le niveau des deux plaines ; le lit de la
	# rivière est 3,5 m plus bas.
	var bed_y: float = -3.5
	var arcade_y: float = WALL_H * 2.0          # naissance des arches : 6,24 m
	# CORRECTIF (revue 117) — le canal était calé sur TROIS assises de mur
	# (9,36 m), mais ce n'est pas un mur qui le porte : c'est `Wall_Arch`, qui
	# mesure 3,000 m de haut exactement (bbox y 0..3,0, sommet plat sur toute
	# la largeur). Le sommet réel des arches est donc à 6,24 + 3,00 = 9,24 m,
	# et le tablier posé à 9,36 laissait 0,11 m de JOUR continu sur les 14
	# travées, soit 28 m de fente de ciel à 9 m de haut. On dérive maintenant
	# la cote du support mesuré. Bordures, lierre, briques et végétation du
	# canal en dépendent tous : un seul point à corriger.
	var channel_y: float = arcade_y + 3.0       # canal : 9,24 m
	aqueduct_crossing_y = SITE_AQUEDUCT.y

	# QUATRE PILES, deux par rive. Aucune au milieu : c'est justement celle qui
	# manque. Colonne de 2 × 2 m, deux assises de quatre murs.
	var piers: Array[float] = [-20.0, -8.0, 8.0, 20.0]
	for pier_z: float in piers:
		for level: int in range(2):
			var y: float = float(level) * WALL_H
			_piece("Wall_UnevenBrick_Straight",
				Vector3(0, y, pier_z + MODULE * 0.5), 0.0, aqueduct)
			_piece("Wall_UnevenBrick_Straight",
				Vector3(0, y, pier_z - MODULE * 0.5), 180.0, aqueduct)
			_piece("Wall_UnevenBrick_Straight",
				Vector3(-MODULE * 0.5, y, pier_z), 90.0, aqueduct)
			_piece("Wall_UnevenBrick_Straight",
				Vector3(MODULE * 0.5, y, pier_z), 270.0, aqueduct)
		# UNE seule collision par pile, du sol à l'arcade : c'est la pile qui
		# barre, pas l'arche. On passe dessous à pied — §1.
		_wall_collider(aqueduct, Vector3(0, arcade_y * 0.5, pier_z),
			Vector3(2.4, arcade_y, 2.4))

	# ARCADE ET CANAL : sept travées par rive, interrompues net au-dessus de
	# l'eau. Le canal est à sec depuis si longtemps que l'herbe y a poussé.
	#
	# CORRECTIF (revue 117) — il n'y avait qu'UNE pièce d'arche par travée, à
	# x = 0. Or `Wall_Arch` est un PANNEAU : 2,000 × 3,000 × 0,064 m mesurés.
	# Posée à x = 0 en yaw 90 elle n'occupait que x 0,000..0,064, sous un
	# tablier de 2 m (x ±1) et entre des piles de 2,6 m d'emprise : l'arcade
	# était 31 fois plus mince que ce qu'elle portait, et de trois quarts —
	# l'angle d'approche depuis la rivière — on voyait le sol de part et
	# d'autre. On pose donc UN PAREMENT PAR FACE, aligné sur les rives du
	# tablier : x −1,000..−0,936 et x +0,936..+1,000, dans l'emprise des piles
	# (±1,314). Rien n'est ajouté en collision : on passe toujours dessous, §1.
	for side: float in [-1.0, 1.0]:
		for k: int in range(7):
			var z: float = side * (9.0 + float(k) * 2.0)
			_piece("Wall_Arch", Vector3(-1.0, arcade_y, z), 90.0, aqueduct)
			_piece("Wall_Arch", Vector3(1.0, arcade_y, z), 270.0, aqueduct)
			_piece("Floor_Brick", Vector3(0, channel_y, z), 0.0, aqueduct)
			_piece("Prop_ExteriorBorder_Straight1",
				Vector3(-0.9, channel_y, z), 90.0, aqueduct)
			_piece("Prop_ExteriorBorder_Straight1",
				Vector3(0.9, channel_y, z), 270.0, aqueduct)
	# Les deux lèvres de la cassure : une travée à demi arrachée de chaque côté,
	# du lierre qui pend dans le vide, des briques prêtes à tomber.
	var brink: Array[Array] = [
		# Mêmes deux parements que les travées entières (voir plus haut) : la
		# lèvre arrachée serait sinon la seule arche « en papier » restante.
		# Le roulis est INVERSÉ sur la pièce à yaw 270, sinon le miroir
		# inclinerait les deux parements dans des sens opposés : mesuré, yaw
		# 270 / roulis −16 donne exactement la même emprise en z (−8,561..
		# −5,812) que yaw 90 / roulis +16.
		["Wall_Arch", Vector3(-1.0, arcade_y, -7.6), Vector3(0, 90, 16.0), 1.0,
			Vector3.ZERO],
		["Wall_Arch", Vector3(1.0, arcade_y, -7.6), Vector3(0, 270, -16.0),
			1.0, Vector3.ZERO],
		["Wall_Arch", Vector3(-1.0, arcade_y, 7.6), Vector3(0, 90, -13.0), 1.0,
			Vector3.ZERO],
		["Wall_Arch", Vector3(1.0, arcade_y, 7.6), Vector3(0, 270, 13.0), 1.0,
			Vector3.ZERO],
		["Prop_Vine1", Vector3(0.0, channel_y - 1.2, -8.6), Vector3(0, 90, 0),
			1.0, Vector3.ZERO],
		["Prop_Vine2", Vector3(0.0, channel_y - 1.4, 8.6), Vector3(0, 90, 0),
			1.0, Vector3.ZERO],
		["Prop_Brick1", Vector3(0.5, channel_y, -8.9), Vector3(12.0, 40.0, 0.0),
			1.0, Vector3.ZERO],
		["Prop_Brick1", Vector3(-0.6, channel_y, 8.8), Vector3(-9.0, 20.0, 0.0),
			1.0, Vector3.ZERO],
	]
	_dressing(aqueduct, brink)
	# La végétation du canal : la preuve visible que l'eau ne passe plus.
	#
	# DÉFAUT D'ATTACHE MESURÉ (revue orientation) — la cote `channel_y` est une
	# CONSTANTE DE BÂTIMENT (9,24 m), pas une hauteur de terrain : une plante
	# qui la porte n'est juste que si un module de canal se trouve VRAIMENT
	# sous elle. Or le z était une suite arithmétique ouverte,
	# `sign_z * (9,5 + 1,7·i)`, qui allait jusqu'à ±24,8, alors que les sept
	# travées bâties ne posent de `Floor_Brick` qu'en z ±9, ±11 … ±21 (module
	# de 2 m, donc dallage continu de ±8 à ±22). Boîtes monde relevées sur les
	# sommets : la fougère du rang i = 8 occupait z −14,26..−12,01 et l'herbe
	# du rang i = 9 z +34,73..+34,90 — toutes deux HORS dallage, en l'air à
	# y = 11,24, c'est-à-dire 9,24 m au-dessus de la plaine et 2 m au-delà du
	# bout de l'arcade. Rien ne les portait.
	#
	# Le z ne se calcule donc plus : il se DÉRIVE de la travée, comme le canal
	# lui-même. Cinq travées par rive (0, 3, 6, 2, 5 — parcours déterministe,
	# jamais un aléa), plus un décalage borné à ±0,6 m qui reste sur la dalle
	# (demi-module 1,0 m). Aucune pose ne peut plus sortir du dallage.
	var dry: Array[String] = [
		"Grass_Wispy_Short", "Plant_1", "Fern_1", "Grass_Common_Short",
		"Clover_2", "Mushroom_Laetiporus",
	]
	for i: int in range(10):
		var sign_z: float = -1.0 if i % 2 == 0 else 1.0
		var bay: int = ((i / 2) * 3) % 7
		var along: float = 9.0 + float(bay) * 2.0 + sin(float(i) * 2.399) * 0.6
		_spawn(dry[i % dry.size()],
			Vector3(0.0, channel_y + 0.05, sign_z * along),
			Vector3(0, float(i) * 63.0, 0), aqueduct, "", 0.8)

	# LA TRAVÉE TOMBÉE, devenue pont. Le tablier affleure les deux rives : on
	# traverse de plain-pied, et il y a du vide dessous — c'est un pont, pas
	# un gué.
	_wall_collider(aqueduct, Vector3(6.0, -0.35, 0.0), Vector3(3.2, 0.7, 15.0))
	for k: int in range(7):
		var z: float = -6.0 + float(k) * 2.0
		_spawn("RockPath_Square_Wide" if k % 2 == 0 else "RockPath_Round_Wide",
			Vector3(6.0, -0.06, z), Vector3(0, float(k) * 29.0, 0), aqueduct,
			"", 1.15)

	# LE CORPS DE LA TRAVÉE : il manquait ENTIÈREMENT.
	#
	# DÉFAUT MESURÉ (revue orientation) — le « pont » n'était que les sept
	# dalles ci-dessus, boîtes monde y 1,928..2,131 relevées sur les sommets,
	# et son unique appui était le `_wall_collider` de la ligne précédente,
	# c'est-à-dire un corps de collision : INVISIBLE. Sous les dalles il y
	# avait 3,43 m de vide franc jusqu'au fond du lit (dalle `Riverbed` de
	# valley_terrain.gd, dessus y = −1,5) — et à cette abscisse les berges en
	# pente sont justement épargnées (fenêtre x −24..−4 réservée au site de
	# pont). Vu depuis le lit, ce tablier se lisait exactement comme ce que le
	# propriétaire décrit : des masses de pierre sombre suspendues en l'air le
	# long de l'aqueduc.
	#
	# CORRECTIF. On bâtit ce que la fiction affirme déjà : la travée tombée est
	# un morceau d'ARCADE. On reprend donc le parement `Wall_Arch` du tablier
	# debout, pied au fond du lit et sommet sous les dalles. Mesures hors
	# moteur : `Wall_Arch` fait 2,000 × 3,000 × 0,064 m ; il faut 3,4285 m
	# entre le fond (y local −3,5) et le dessous des dalles (y local −0,0715,
	# soit −0,010 × 1,15 − 0,06) ; d'où le facteur 1,143 → hauteur 3,429,
	# longueur 2,286. Vérifié après pose : y monde −1,500..1,929, c'est-à-dire
	# pied POSÉ sur le lit et sommet AU CONTACT du tablier, zéro jour.
	# Cinq travées couvrent z monde 4,285..15,715, soit 11,43 m des 12 m de
	# lit ; les 0,285 m restants de chaque bout portent sur la berge.
	#
	# Le sens des lacets suit celui de l'arcade debout : à yaw 90 le parement
	# occupe x +0,000..+0,073 de sa pose, à yaw 270 −0,073..0 — les deux faces
	# extérieures affleurent donc les rives de la dalle (x local 5 et 7), la
	# dalle mesurée débordant de 4,79 à 7,22. Aucune collision n'est ajoutée :
	# comme sous l'arcade debout, on passe DESSOUS (§1), et le lit reste
	# parcourable dans le sens du courant par les arches.
	const FALLEN_ARCH_FACTOR: float = 1.143
	const FALLEN_ARCH_BAY: float = 2.0 * FALLEN_ARCH_FACTOR
	for k: int in range(5):
		var z: float = (float(k) - 2.0) * FALLEN_ARCH_BAY
		_spawn("Wall_Arch", Vector3(5.0, bed_y, z), Vector3(0, 90, 0),
			aqueduct, "", FALLEN_ARCH_FACTOR)
		_spawn("Wall_Arch", Vector3(7.0, bed_y, z), Vector3(0, 270, 0),
			aqueduct, "", FALLEN_ARCH_FACTOR)
	_marker(aqueduct, "PassageDeLArche", Vector3(6.0, 0.1, 0.0))
	var span: Array[Array] = [
		# Les deux extrémités de la travée, encore reconnaissables.
		#
		# DÉFAUT MESURÉ — il n'y avait qu'UN panneau par extrémité. `Wall_Arch`
		# est épais de 0,064 m : basculé au bord du passage, là où le joueur le
		# longe, il se voyait par la tranche. Même remède que pour l'arcade
		# debout et que pour les lèvres de la cassure : un parement par face,
		# aux rives du tablier (x local 5 et 7).
		# Le tangage est INVERSÉ sur la pièce à yaw 270 : en ordre YXZ,
		# Ry(90) envoie l'axe X local sur −Z monde et Ry(270) sur +Z, donc un
		# même tangage donnerait deux inclinaisons opposées. Vérifié sur les
		# sommets — yaw 270 / tangage −22 rend la même emprise en z
		# (0,600..2,600) et la même en y (2,20..5,01 contre 2,18..4,98) que
		# yaw 90 / tangage +22 : les deux parements sont bien parallèles.
		["Wall_Arch", Vector3(5.0, 0.2, -8.4), Vector3(22.0, 90.0, 0.0), 1.0,
			Vector3.ZERO],
		["Wall_Arch", Vector3(7.0, 0.2, -8.4), Vector3(-22.0, 270.0, 0.0), 1.0,
			Vector3.ZERO],
		# Extrémité SUD remontée de 0,6 m : posée à y = −0,7, sa boîte monde
		# commençait à y = 1,300 pour une plaine à 2,00, soit 0,70 m de
		# l'arche avalés par le sol. À −0,1 elle part de 1,900 — juste assise
		# dans l'herbe, ce que dit le récit.
		["Wall_Arch", Vector3(5.0, -0.1, 8.0), Vector3(-26.0, 90.0, 0.0), 1.0,
			Vector3.ZERO],
		["Wall_Arch", Vector3(7.0, -0.1, 8.0), Vector3(26.0, 270.0, 0.0), 1.0,
			Vector3.ZERO],
		# La pile emportée, plantée de travers dans le lit.
		["Wall_UnevenBrick_Straight", Vector3(2.4, bed_y + 0.6, 0.8),
			Vector3(34.0, 78.0, 0.0), 1.0, Vector3.ZERO],
		# CORRECTIF (revue 117) — même piège que la poutre de la tour : à 70°
		# de tangage, l'axe de `Prop_Support` descendait de +0,11 à −1,22 par
		# rapport à sa pose, soit un bout enfoncé de 1,02 m SOUS le fond du lit
		# (bed_y = −3,5). À 40°, l'axe est horizontal et la poutre repose à
		# y = −3,22, donc 0,28 m au-dessus du fond, couchée dans les galets.
		["Prop_Support", Vector3(3.4, bed_y + 0.2, -2.6),
			Vector3(40.0, 30.0, 0.0), 1.0, Vector3.ZERO],
		["Rock_Medium_1", Vector3(4.6, bed_y, 3.4), Vector3(0, 40, 0), 1.2,
			Vector3.ZERO],
		["Rock_Medium_2", Vector3(8.4, bed_y, -1.2), Vector3(0, 210, 0), 1.0,
			Vector3.ZERO],
		["Rock_Medium_3", Vector3(9.6, bed_y, 2.8), Vector3(0, 95, 0), 1.1,
			Vector3.ZERO],
		["Prop_Brick1", Vector3(7.2, bed_y, -3.8), Vector3(0, 12, 0), 1.0,
			Vector3.ZERO],
		["Prop_Brick1", Vector3(11.0, bed_y, 0.6), Vector3(0, 130, 0), 1.0,
			Vector3.ZERO],
		# CORRECTIF (revue 117) — lierre à origine haute (voir le bloc de la
		# tour) : posé à y = −0,2 il occupait y −2,32..+0,28, donc enterré. Il
		# pend maintenant de l'arche couchée voisine, dont le sommet mesuré
		# monte à y = 2,98 : la plante occupe y 0,08..2,68.
		["Prop_Vine2", Vector3(6.6, 2.2, -7.9), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Grass_Common_Short", Vector3(5.2, 0.0, -6.6), Vector3(0, 70, 0), 1.0,
			Vector3.ZERO],
		["Grass_Common_Short", Vector3(6.8, 0.0, 6.4), Vector3(0, 250, 0), 1.0,
			Vector3.ZERO],
	]
	_dressing(aqueduct, span)

	# LA RÉPARATION ABANDONNÉE, au pied de la pile de la rive nord : on a monté
	# un échafaudage, on n'a jamais fini. C'est l'indice qui date la ruine.
	var repair: Array[Array] = [
		["Prop_Support", Vector3(-2.0, 0.0, -9.6), Vector3(0, 0, 14.0), 1.0,
			Vector3.ZERO],
		# DÉFAUT MESURÉ — cet étai était le seul des trois à ENJAMBER la lèvre
		# du lit. `Prop_Support` s'étend de z 0 à z +1,918 depuis son ancrage :
		# posé en z local −6,8 (z monde 3,2), sa boîte relevée sur les sommets
		# allait de 3,082 à 5,118, alors que la plaine nord s'arrête à z = 16
		# côté sud et à z = 4 ici (dalles de valley_terrain.gd). 1,12 m de
		# poutre pendaient donc au-dessus de 3,5 m de vide, sans appui — une
		# planche flottante. Un demi-tour de LACET, sans toucher à la pose ni
		# à l'inclinaison, retourne la poutre vers l'intérieur : boîte mesurée
		# z 1,282..3,318, entièrement sur la plaine, 0,68 m avant la lèvre, et
		# l'étai s'appuie désormais VERS la pile qu'il était censé étayer.
		["Prop_Support", Vector3(-2.4, 0.0, -6.8), Vector3(0, 180, -9.0), 1.0,
			Vector3.ZERO],
		["Prop_Support", Vector3(2.2, 0.0, -8.2), Vector3(0, 0, 11.0), 1.0,
			Vector3.ZERO],
		["Workbench", Vector3(-4.2, 0.0, -7.4), Vector3(0, 24, 0), 1.0,
			Vector3(1.6, 1.0, 0.9)],
		["Pickaxe_Bronze", Vector3(-3.2, 0.06, -9.0), Vector3(88.0, 55.0, 0.0),
			1.0, Vector3.ZERO],
		["Bucket_Metal", Vector3(-2.6, 0.05, -10.6), Vector3(0, 0, 104.0), 1.0,
			Vector3.ZERO],
		["Rope_1", Vector3(-1.4, 0.05, -10.2), Vector3(0, 130, 0), 1.0,
			Vector3.ZERO],
		["Chain_Coil", Vector3(1.8, 0.05, -6.4), Vector3(0, 20, 0), 1.0,
			Vector3.ZERO],
		["Crate_Wooden", Vector3(-4.6, 0.0, -10.0), Vector3(0, 40, 0), 1.0,
			Vector3(1.0, 1.0, 1.0)],
		["Prop_Brick1", Vector3(-3.6, 0.0, -11.4), Vector3(0, 62, 0), 1.0,
			Vector3.ZERO],
		["Prop_Brick1", Vector3(-4.8, 0.0, -12.0), Vector3(0, 8, 0), 1.0,
			Vector3.ZERO],
		["Bush_Common", Vector3(-5.8, 0.0, -14.0), Vector3(0, 100, 0), 1.1,
			Vector3.ZERO],
		["Bush_Common_Flowers", Vector3(4.6, 0.0, -13.2), Vector3(0, 30, 0),
			1.0, Vector3.ZERO],
		["Fern_1", Vector3(1.6, 0.0, -12.4), Vector3(0, 210, 0), 1.0,
			Vector3.ZERO],
		# DÉFAUT MESURÉ — c'est de là que venaient « les arbres qui poussent sur
		# le tablier ». `TwistedTree_3` est un spécimen héros : boîte relevée
		# sur les sommets 11,36 × 16,07 × 11,51 m, et sa couronne (primitive
		# x −4,49..+6,87) est FRANCHEMENT dissymétrique — à yaw 60 elle
		# déborde de +7,75 m en x depuis le tronc. Posé en x local −8, elle
		# atteignait donc x monde −12,25, c'est-à-dire ENTRE les deux parements
		# de l'arcade (x −13,00..−12,94 et −11,06..−11,00), sur z monde
		# −12..−1,12, et montait à y = 17,87 quand le canal est à 11,24 : les
		# branches sortaient à la naissance des arches (y monde 8,24, soit
		# 6,24 m au-dessus de la plaine — les « 6 m du sol » observés) puis
		# ressortaient 6,6 m au-dessus du tablier.
		# Le lacet ne peut rien y faire : la couronne fait 15,6 m de large quel
		# que soit l'angle (mesuré à 60°, 210° et 240°). Il faut donc éloigner
		# le tronc. À x local −11, z −19, la couronne s'arrête à x monde
		# −15,25, soit 2,25 m à l'ouest du parement — dégagée pour de bon,
		# encore dans l'emprise du point d'intérêt, et à l'écart de
		# l'échafaudage (z monde −18,21..−2,62 contre 0,3..3,9 pour les étais).
		["TwistedTree_3", Vector3(-11.0, 0.0, -19.0), Vector3(0, 60, 0), 1.0,
			Vector3.ZERO],
		["CommonTree_4", Vector3(9.5, 0.0, 15.0), Vector3(0, 150, 0), 1.0,
			Vector3.ZERO],
	]
	_dressing(aqueduct, repair)
	_marker(aqueduct, "AncrageRecompense", Vector3(-4.0, 0.1, -8.4))
	# Lierre le long des piles : la ruine est ancienne, contrairement à la
	# caravane foudroyée.
	# CORRECTIF (revue 117) — `WALL_H * (i % 2)` donnait y = 0 pour i = 0 et
	# i = 2 : deux lierres sur quatre étaient enterrés à 82 % (origine haute,
	# cf. le bloc de la tour). Les piles font DEUX assises, soit 6,24 m : les
	# deux hauteurs 3,12 et 6,24 restent donc toutes deux sur la maçonnerie.
	for i: int in range(4):
		_spawn("Prop_Vine1" if i % 2 == 0 else "Prop_Vine2",
			Vector3(-1.05, WALL_H * float(1 + i % 2), piers[i]),
			Vector3(0, 90, 0), aqueduct)

	_place_poi(aqueduct, POI_AQUEDUCT, "Aqueduc ancien", &"riviere",
		Vector3(3.0, 6.0, 0.0), Vector3(48.0, 26.0, 60.0))


# --- 3. FERME ABANDONNÉE ----------------------------------------------------

## Plaine sud, entre le village de la rivière et la descente du camp.
##
## Le récit est celui d'un départ précipité : la porte arrachée gît dans la
## cour, le repas est resté sur la table, une chaise est renversée, les outils
## sont tombés là où ils servaient. La maison, elle, est un VRAI abri — c'est la
## ruine sur laquelle porte la preuve physique.
func _build_farm() -> void:
	var farm: Node3D = _site("FermeAbandonnee", SITE_FARM)
	var house: Node3D = Node3D.new()
	house.name = "Maison"
	house.position = Vector3.ZERO
	farm.add_child(house)
	var face: float = 3.0                       # emprise 6 × 6 m
	var slots: Array[float] = [-2.0, 0.0, 2.0]

	for x: float in slots:
		for z: float in slots:
			_piece("Floor_WoodDark", Vector3(x, 0.02, z), 0.0, house)
	farmhouse_floor_y = SITE_FARM.y + 0.02
	_slab_collider(house, Vector3(0, -0.25, 0), Vector3(6.4, 0.5, 6.4))

	# Quatre faces closes, une seule ouverture : la baie de l'est, dont le
	# vantail est dehors. Ce qui paraît fermé l'est vraiment.
	for x: float in slots:
		_wall(house, Vector3(x, 0, face), 0.0,
			"Wall_UnevenBrick_Window_Wide_Round" if x == 0.0
			else "Wall_UnevenBrick_Straight")
		_wall(house, Vector3(x, 0, -face), 180.0,
			"Wall_UnevenBrick_Window_Thin_Round" if x == 0.0
			else "Wall_UnevenBrick_Straight")
	for z: float in slots:
		_wall(house, Vector3(-face, 0, z), 90.0, "Wall_UnevenBrick_Straight")
	_door_wall(house, Vector3(face, 0, 0.0), 270.0,
		"Wall_UnevenBrick_Door_Round")
	_wall(house, Vector3(face, 0, -2.0), 270.0, "Wall_UnevenBrick_Straight")
	_wall(house, Vector3(face, 0, 2.0), 270.0,
		"Wall_UnevenBrick_Window_Thin_Round")

	# Toiture qui s'affaisse : décalée et inclinée, plus un pan tombé au sol.
	_spawn("Roof_RoundTiles_6x6", Vector3(0.35, WALL_H, 0.0),
		Vector3(0.0, 0.0, 6.0), house)
	# CORRECTIF (revue 117) — le toit était posé SANS pignons. Mesuré :
	# `Roof_RoundTiles_6x6` a sa faîtière selon Z (les sommets à y ≈ 4,89
	# courent de z = −3,94 à z = +4,09 à x ≈ 0) ; c'est donc un toit à deux
	# pans, et ses deux triangles d'about, en z = ±span/2, étaient OUVERTS.
	# Contrôle du maillage : à chaque bout il n'y a que 2,12 m² de bois de
	# rive sur une ouverture de 6,7 × 4,4 m — rien qui la bouche. Dans le SEUL
	# intérieur habitable du jeu, on voyait le ciel par les deux bouts.
	# `Roof_Front_Brick6` est le bouchon prévu par le kit (6,694 × 4,516 m).
	# Vérifié hors moteur : base à 2,64, soit 0,48 m SOUS l'arase des murs
	# (3,12) donc aucun jour au raccord ; faîte à 7,83, soit 0,58 m sous la
	# faîtière (8,41) donc rien ne perce les tuiles ; emprise x −3,44..3,69,
	# à l'intérieur de celle du toit (−4,26..4,53).
	# Le roulis −6 sur la pièce à yaw 180 compense le miroir : en ordre YXZ,
	# Ry(180)·Rz(θ) produit un roulis monde −θ, donc les deux pignons suivent
	# le même affaissement que le toit.
	_spawn("Roof_Front_Brick6", Vector3(0.35, WALL_H, 3.0),
		Vector3(0.0, 0.0, 6.0), house)
	_spawn("Roof_Front_Brick6", Vector3(0.35, WALL_H, -3.0),
		Vector3(0.0, 180.0, -6.0), house)
	_spawn("Prop_Chimney", Vector3(-1.6, WALL_H + 0.4, -1.4),
		Vector3(0.0, 0.0, -8.0), house)
	_marker(house, "AncrageRecompense", Vector3(-2.0, 0.1, -2.0))

	# LE DÉPART PRÉCIPITÉ, dedans : le couvert n'a jamais été débarrassé.
	var indoors: Array[Array] = [
		["Table_Large", Vector3(-0.6, 0.05, -0.4), Vector3(0, 6, 0), 1.0,
			Vector3(1.9, 0.9, 1.0)],
		["Pot_1", Vector3(-0.9, 0.83, -0.5), Vector3(0, 20, 0), 1.0,
			Vector3.ZERO],
		["Pot_1_Lid", Vector3(-0.1, 0.05, 0.6), Vector3(0, 40, 0), 1.0,
			Vector3.ZERO],
		["Mug", Vector3(-0.1, 0.83, -0.9), Vector3(0, 0, 0), 1.0, Vector3.ZERO],
		["Mug", Vector3(-1.2, 0.83, 0.1), Vector3(0, 0, 96.0), 1.0,
			Vector3.ZERO],
		["Bottle_1", Vector3(-0.4, 0.83, 0.2), Vector3(0, 0, 88.0), 1.0,
			Vector3.ZERO],
		["Candle_1", Vector3(-1.4, 0.83, -0.8), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Carrot", Vector3(0.4, 0.06, -1.5), Vector3(84.0, 30.0, 0.0), 1.0,
			Vector3.ZERO],
		["Chair_1", Vector3(0.7, 0.25, 0.3), Vector3(78.0, 24.0, 0.0), 1.0,
			Vector3.ZERO],
		["Stool", Vector3(-1.9, 0.05, -1.2), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Bed_Twin1", Vector3(-1.7, 0.05, 1.8), Vector3(0, 90, 0), 1.0,
			Vector3(1.0, 0.6, 2.0)],
		# CORRECTIF (revue 117) — `Shelf_Simple` est une étagère MURALE : son
		# origine est la tablette et ses équerres descendent (bbox y
		# −0,2011..+0,1077). Posée à y = 0,05 elle était donc À PLAT SUR LE
		# PLANCHER, tandis que la pile de livres, posée à y = 1,00, flottait
		# 0,84 m au-dessus d'elle. En profondeur elle s'arrêtait à z = −2,556
		# alors que le parement intérieur du mur nord est à −2,686 : elle ne
		# touchait pas le mur non plus. Accrochée à 1,15 m, elle occupe
		# y 0,949..1,258 et z −2,686..−2,394, dos exactement sur le mur ; les
		# livres à 1,26 reposent sur la tablette (y 1,261..1,475) et restent
		# dans son emprise.
		["Shelf_Simple", Vector3(1.9, 1.15, -2.73), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Book_Stack_1", Vector3(1.9, 1.26, -2.54), Vector3(0, 12, 0), 1.0,
			Vector3.ZERO],
		["Bucket_Wooden_1", Vector3(2.0, 0.2, 1.9), Vector3(0, 0, 100.0), 1.0,
			Vector3.ZERO],
		["Pouch_Large", Vector3(1.2, 0.05, 1.2), Vector3(0, 50, 0), 1.0,
			Vector3.ZERO],
		# La nature rentre : mousse et champignons dans l'angle humide du nord,
		# herbe sur le seuil que plus personne ne balaie.
		["Mushroom_Common", Vector3(-2.4, 0.05, -2.4), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Mushroom_Common", Vector3(-2.0, 0.05, -2.7), Vector3(0, 60, 0), 0.9,
			Vector3.ZERO],
		["Mushroom_Laetiporus", Vector3(-2.7, 0.05, -1.6), Vector3(0, 130, 0),
			1.0, Vector3.ZERO],
		["Clover_1", Vector3(2.4, 0.05, 0.2), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Grass_Common_Short", Vector3(2.9, 0.05, -0.1), Vector3(0, 90, 0), 0.9,
			Vector3.ZERO],
		# CORRECTIF (revue 117) — lierres à origine haute, enterrés à 82 %
		# (même mesure que pour la tour). Accrochés à WALL_H, ils occupent
		# y 1,00..3,60. Seule la pose à yaw 90 est aussi reculée de 0,21 m
		# pour affleurer le parement ouest (x = −3,314) ; celle à yaw 180
		# laisse déjà 0,013 m de jeu contre le parement nord, on n'y touche pas.
		["Prop_Vine1", Vector3(-3.36, WALL_H, 1.0), Vector3(0, 90, 0), 1.0,
			Vector3.ZERO],
		["Prop_Vine2", Vector3(-1.0, WALL_H, -3.15), Vector3(0, 180, 0), 1.0,
			Vector3.ZERO],
	]
	_dressing(house, indoors)

	# LA PORTE ARRACHÉE, à plat dans la cour : le premier signe qu'on lit en
	# arrivant, avant même de voir l'intérieur.
	_spawn("Door_2_Round", Vector3(5.1, 0.06, 0.4), Vector3(86.0, 14.0, 0.0),
		farm)
	_spawn("DoorFrame_Round_WoodDark", Vector3(4.6, 0.05, -1.9),
		Vector3(80.0, 40.0, 0.0), farm)

	# LA GRANGE, ouverte sur la cour : trois murs, un toit, du matériel resté là.
	var barn: Node3D = Node3D.new()
	barn.name = "Grange"
	barn.position = Vector3(11.0, 0.0, 5.0)
	farm.add_child(barn)
	for z: float in slots:
		_wall(barn, Vector3(-MODULE, 0, z), 90.0, "Wall_Plaster_Straight")
	for x: float in [-1.0, 1.0]:
		_wall(barn, Vector3(x, 0, -MODULE * 1.5), 180.0,
			"Wall_Plaster_Straight")
	# CORRECTIF (revue 117) — le commentaire annonce « trois murs » ; il n'y en
	# avait que DEUX (ouest sur z −3..3, nord sur x −2..2), soit un simple L :
	# la face est et la face sud manquaient toutes les deux et le coin sud-est
	# n'était fermé par rien. On ne peut pas ouvrir sur la cour, qui est à
	# l'OUEST (maison en x local 0, grange en x local 11) et dont le mur est
	# justement le seul long mur bâti ; on ferme donc la face EST, celle qui
	# donne sur le champ, et la grange devient un appentis ouvert au SUD.
	# Mesuré : trois modules de 2 m couvrent z −3..3 comme la face ouest, le
	# mur occupe x 1,908..2,314 et recouvre le mur nord (qui va jusqu'à x = 2)
	# au coin nord-est.
	for z: float in slots:
		_wall(barn, Vector3(MODULE, 0, z), 270.0, "Wall_Plaster_Straight")
	# CORRECTIF (revue 117) — la couverture était UNE pièce
	# `Roof_Wooden_2x1_Center` de 2 × 1,5 m posée sur une emprise de 4 × 6 m :
	# 3 m² pour 24 m², soit 12,5 %. L'établi, la meule, l'enclume et le chariot
	# étaient sous la pluie et la grange se lisait comme un mur d'angle avec
	# une planche dessus. `Roof_RoundTiles_4x6` (mesuré x ±2,757, z ±3,786)
	# couvre exactement l'emprise avec 0,76 m de débord ; ses égouts tombent à
	# y = 2,41, sous l'arase des murs (3,12), donc pas de jour au raccord.
	# Le pignon ferme le bout NORD (base 2,84, sous l'arase ; faîte 6,20, sous
	# la faîtière du toit à 7,02), roulis inversé pour compenser le miroir de
	# yaw 180 ; `Roof_FrontSupports` pose la poutre de rive au bout SUD, resté
	# ouvert, comme le fait déjà la cabane des bûcherons (hamlets.gd).
	_spawn("Roof_RoundTiles_4x6", Vector3(0.0, WALL_H, 0.0),
		Vector3(0.0, 0.0, -4.0), barn)
	_spawn("Roof_Front_Brick4", Vector3(0.0, WALL_H, -3.0),
		Vector3(0.0, 180.0, 4.0), barn)
	_spawn("Roof_FrontSupports", Vector3(0.0, WALL_H - 0.2, 3.0),
		Vector3(0.0, 0.0, -4.0), barn)
	# Trois props reculés de la face EST, désormais bâtie (voir plus haut) :
	# mesurés à leur pose d'origine, le chariot dépassait de 0,52 m dans le
	# nouveau mur (x jusqu'à 2,428 contre un parement intérieur à 1,908),
	# l'enclume de 0,99 m et le sac de 0,42 m. Aucun n'est déplacé de plus de
	# ce qu'il fallait pour rentrer.
	var barn_yard: Array[Array] = [
		["Stall_Cart_Empty", Vector3(0.85, 0.05, 1.6), Vector3(0.0, 22.0, 12.0),
			1.0, Vector3(2.4, 1.2, 1.6)],
		["FarmCrate_Empty", Vector3(-0.8, 0.3, 1.0), Vector3(0, 30, 104.0), 1.0,
			Vector3.ZERO],
		["FarmCrate_Carrot", Vector3(-1.2, 0.05, -1.4), Vector3(0, 8, 0), 1.0,
			Vector3(0.9, 0.6, 0.9)],
		["Barrel", Vector3(0.6, 0.35, -2.2), Vector3(96.0, 0.0, 0.0), 1.0,
			Vector3.ZERO],
		["Anvil_Log", Vector3(1.15, 0.05, -0.6), Vector3(0, 40, 0), 1.0,
			Vector3(0.7, 0.7, 0.7)],
		# CORRECTIF (revue 117) — la hache était NOYÉE dans le billot : posée à
		# y = 0,62 elle occupait y 0,27..1,03 et son empreinte au sol tenait
		# tout entière dans celle de l'enclume (y 0,05..1,125), on n'en voyait
		# que ce qui dépassait du flanc. Remontée à 1,29, sa tête vient sur la
		# table de l'enclume (1,125) et le manche retombe à côté du billot.
		# Elle suit l'enclume en x et en z : la hache posée dessus n'a de sens
		# que sur la même verticale.
		["Axe_Bronze", Vector3(1.15, 1.29, -0.6), Vector3(28.0, 40.0, 0.0),
			1.0, Vector3.ZERO],
		["Workbench", Vector3(-1.0, 0.05, 2.6), Vector3(0, 0, 0), 1.0,
			Vector3(1.6, 1.0, 0.9)],
		["Whetstone", Vector3(-1.6, 0.05, 3.4), Vector3(0, 70, 0), 1.0,
			Vector3.ZERO],
		["Bag", Vector3(1.4, 0.05, 2.8), Vector3(0, 120, 0), 1.0, Vector3.ZERO],
		["Rope_1", Vector3(0.2, 0.05, 3.2), Vector3(0, 10, 0), 1.0,
			Vector3.ZERO],
		# CORRECTIF (revue 117) — lierre à origine haute, enterré à 82 % ;
		# accroché à WALL_H il occupe y 1,00..3,60, et reculé de 0,21 m il
		# affleure le parement ouest de la grange (x = −2,314).
		["Prop_Vine1", Vector3(-2.31, WALL_H, 1.0), Vector3(0, 90, 0), 1.0,
			Vector3.ZERO],
	]
	_dressing(barn, barn_yard)

	# LE PUITS : un anneau de pierres, un seau et une corde. Bas, plein, on en
	# fait le tour — pas un décor traversable.
	var well: Node3D = Node3D.new()
	well.name = "Puits"
	well.position = Vector3(6.0, 0.0, -6.5)
	farm.add_child(well)
	for i: int in range(7):
		var angle: float = TAU * float(i) / 7.0
		_spawn("Rock_Medium_%d" % (1 + i % 3),
			Vector3(cos(angle) * 1.15, 0.1, sin(angle) * 1.15),
			Vector3(0, angle * 57.3, 0), well, "", 0.8)
	_wall_collider(well, Vector3(0, 0.4, 0), Vector3(2.8, 0.8, 2.8))
	# Variable typée plutôt que littéral passé directement : un `Array` non
	# typé refuserait de s'affecter au paramètre `Array[Array]`.
	var well_side: Array[Array] = [
		["Bucket_Wooden_1", Vector3(1.6, 0.05, 0.7), Vector3(0, 0, 92.0), 1.0,
			Vector3.ZERO],
		["Rope_1", Vector3(1.2, 0.05, -0.9), Vector3(0, 40, 0), 1.0,
			Vector3.ZERO],
		["Grass_Common_Tall", Vector3(-1.9, 0.0, 0.4), Vector3(0, 20, 0), 1.0,
			Vector3.ZERO],
	]
	_dressing(well, well_side)

	# LA CLÔTURE TROUÉE : deux piquets manquent, un troisième est couché. Les
	# bêtes sont sorties par là ; le champ est repris par la broussaille.
	var fence: Node3D = Node3D.new()
	fence.name = "Cloture"
	fence.position = Vector3(0.0, 0.0, 11.0)
	farm.add_child(fence)
	for i: int in range(13):
		if i == 5 or i == 6:
			continue                               # la trouée
		var x: float = -13.2 + float(i) * 2.2
		if i == 7:
			# Le piquet arraché, à plat juste après la brèche.
			_spawn("Prop_WoodenFence_Single", Vector3(x, 0.08, -0.9),
				Vector3(84.0, 24.0, 0.0), fence)
			continue
		_spawn("Prop_WoodenFence_Extension1" if i % 2 == 0
			else "Prop_WoodenFence_Single",
			Vector3(x, 0.0, 0.0), Vector3(0.0, float(i % 3) * 3.0, 0.0), fence)

	# LE CHAMP RETOURNÉ À LA FRICHE : les rangs sont encore lisibles, mais la
	# broussaille les mange. Placement déterministe, avec des trous.
	var field: Node3D = Node3D.new()
	field.name = "Champ"
	field.position = Vector3(0.0, 0.0, 6.5)
	farm.add_child(field)
	var crops: Array[String] = [
		"Plant_7", "Plant_1", "Plant_7_Big", "Plant_1_Big", "Bush_Common",
	]
	for row: int in range(3):
		for k: int in range(9):
			if (row * 9 + k) % 7 == 3:
				continue                           # trous : le champ meurt
			_spawn(crops[(row * 3 + k) % crops.size()],
				Vector3(-8.0 + float(k) * 2.0, 0.0, float(row) * 1.8),
				Vector3(0, float(row * 9 + k) * 41.0, 0), field, "",
				0.85 + 0.05 * float(k % 4))
	# Le travail interrompu, au bout du dernier rang : la récolte laissée sur
	# place, la pioche tombée, le seau renversé.
	var abandoned_row: Array[Array] = [
		["FarmCrate_Apple", Vector3(9.0, 0.05, 1.6), Vector3(0, 30, 0), 1.0,
			Vector3(0.9, 0.6, 0.9)],
		["Pickaxe_Bronze", Vector3(7.6, 0.06, 2.4), Vector3(88.0, 62.0, 0.0),
			1.0, Vector3.ZERO],
		["Bucket_Metal", Vector3(8.4, 0.2, 3.2), Vector3(0, 0, 98.0), 1.0,
			Vector3.ZERO],
		["Barrel_Apples", Vector3(10.2, 0.35, 2.6), Vector3(94.0, 0.0, 0.0),
			1.0, Vector3.ZERO],
	]
	_dressing(field, abandoned_row)

	# LA COUR ET SES ABORDS : arbres, broussaille, fleurs — la ferme s'efface
	# dans le paysage plutôt que d'y être posée.
	var surroundings: Array[Array] = [
		["DeadTree_1", Vector3(-8.5, 0.0, -3.5), Vector3(0, 40, 0), 1.0,
			Vector3(0.9, 4.0, 0.9)],
		["CommonTree_3", Vector3(17.0, 0.0, -3.0), Vector3(0, 150, 0), 1.0,
			Vector3(1.0, 5.0, 1.0)],
		["TwistedTree_2", Vector3(-11.5, 0.0, 8.5), Vector3(0, 95, 0), 1.0,
			Vector3(0.9, 4.0, 0.9)],
		["CommonTree_5", Vector3(-6.0, 0.0, -12.0), Vector3(0, 20, 0), 1.0,
			Vector3(1.0, 5.0, 1.0)],
		["Bush_Common", Vector3(-5.0, 0.0, 4.5), Vector3(0, 60, 0), 1.1,
			Vector3.ZERO],
		["Bush_Common_Flowers", Vector3(4.0, 0.0, 6.0), Vector3(0, 130, 0), 1.0,
			Vector3.ZERO],
		["Bush_Common", Vector3(13.5, 0.0, -8.0), Vector3(0, 200, 0), 1.0,
			Vector3.ZERO],
		["Grass_Common_Tall", Vector3(-4.2, 0.0, -6.0), Vector3(0, 10, 0), 1.0,
			Vector3.ZERO],
		["Grass_Common_Tall", Vector3(8.0, 0.0, -10.5), Vector3(0, 240, 0), 1.0,
			Vector3.ZERO],
		["Grass_Wispy_Tall", Vector3(-9.0, 0.0, 2.0), Vector3(0, 170, 0), 1.0,
			Vector3.ZERO],
		["Grass_Wispy_Short", Vector3(3.0, 0.0, -9.0), Vector3(0, 80, 0), 1.0,
			Vector3.ZERO],
		["Flower_4_Group", Vector3(-2.5, 0.02, 5.5), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Flower_3_Group", Vector3(9.5, 0.02, -5.0), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Clover_2", Vector3(1.5, 0.02, 4.0), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Fern_1", Vector3(-3.6, 0.0, -4.4), Vector3(0, 210, 0), 1.0,
			Vector3.ZERO],
		["RockPath_Round_Small_1", Vector3(4.2, 0.02, 0.4), Vector3(0, 0, 0),
			1.0, Vector3.ZERO],
		["RockPath_Round_Thin", Vector3(6.4, 0.02, 0.9), Vector3(0, 14, 0), 1.0,
			Vector3.ZERO],
		["RockPath_Round_Wide", Vector3(8.6, 0.02, 1.6), Vector3(0, 5, 0), 1.0,
			Vector3.ZERO],
		["Pebble_Round_3", Vector3(3.4, 0.02, -2.4), Vector3(0, 60, 0), 1.0,
			Vector3.ZERO],
		["Pebble_Square_1", Vector3(5.6, 0.02, -3.6), Vector3(0, 120, 0), 1.0,
			Vector3.ZERO],
	]
	_dressing(farm, surroundings)

	_place_poi(farm, POI_FARM, "Ferme abandonnée", &"plaine_sud",
		Vector3(4.0, 5.0, 2.0), Vector3(46.0, 16.0, 42.0))


# --- 4. CARAVANE FOUDROYÉE --------------------------------------------------

## Route de la plaine nord, sur le chemin du donjon.
##
## La seule ruine RÉCENTE des quatre : rien n'a repoussé sur la brûlure, aucun
## lierre ne monte, le bois n'est pas gris. L'arbre fendu marque l'impact, la
## cargaison est projetée en éventail dans UNE direction, et une traînée
## d'objets perdus part vers le nord — les survivants ont continué vers la
## citadelle.
func _build_caravan() -> void:
	var wreck: Node3D = _site("CaravaneFoudroyee", SITE_CARAVAN)

	# L'IMPACT : deux disques de brûlure concentriques et l'arbre fendu.
	_scorch(wreck, Vector3(0.0, 0.04, 0.0), 5.2, COL_SCORCH)
	_scorch(wreck, Vector3(0.0, 0.05, 0.0), 1.8, COL_SCORCH_CORE)
	_spawn("DeadTree_2", Vector3(0.0, 0.0, 0.0), Vector3(19.0, 40.0, 0.0),
		wreck)
	_wall_collider(wreck, Vector3(0.4, 1.6, 0.4), Vector3(0.9, 3.2, 0.9))
	# La moitié haute du tronc, arrachée et jetée avec le reste.
	_spawn("DeadTree_1", Vector3(4.2, 0.4, -3.0), Vector3(92.0, 25.0, 0.0),
		wreck, "", 0.8)

	# LES CHARIOTS : le premier couché sur le flanc, le deuxième planté du nez
	# dans l'ornière, le troisième intact mais abandonné plus loin sur la route.
	var wagons: Array[Array] = [
		# CORRECTIF (revue 117) — collision confiée à `_wall_collider` juste
		# après, d'où le `Vector3.ZERO` ici : voir l'explication sous
		# `_dressing`.
		["Prop_Wagon", Vector3(-6.5, 1.0, 1.5), Vector3(0.0, -20.0, 98.0), 1.0,
			Vector3.ZERO],
		["Prop_Wagon", Vector3(5.8, 0.0, 5.2), Vector3(-17.0, 8.0, 0.0), 1.0,
			Vector3(2.4, 1.8, 4.4)],
		["Prop_Wagon", Vector3(-1.2, 0.0, -9.8), Vector3(0.0, 6.0, 0.0), 1.0,
			Vector3(2.4, 1.8, 4.4)],
	]
	_dressing(wreck, wagons)
	# CORRECTIF (revue 117) — le chariot COUCHÉ ne pouvait pas utiliser la
	# boîte automatique de `_dressing`, qui pose le collider en
	# `at + (0, taille.y * 0,5, 0)` et suppose donc que `at.y` est le sol. Ici
	# `at.y` vaut 1,0 pour redresser un modèle roulé à 98°, si bien que la
	# boîte allait de y = 1,0 à 2,6 alors que la géométrie occupe y −0,18..1,96
	# : le joueur traversait le mètre inférieur du chariot — roues, ridelles,
	# essieu — puis se cognait dans le vide au-dessus de la caisse. Même
	# décalage en plan, l'origine de `Prop_Wagon` n'étant pas son centre
	# (z local −3,15..0,87). Les valeurs ci-dessous sont la boîte englobante
	# MONDE mesurée de cette pose exacte (x −8,35..−5,30, y −0,18..1,96,
	# z −2,03..2,37), ramenée au sol.
	_wall_collider(wreck, Vector3(-6.83, 0.98, 0.17), Vector3(3.06, 1.96, 4.40))

	# LA CARGAISON EN ÉVENTAIL : tout part du point d'impact vers l'est-sud-est,
	# de plus en plus loin et de plus en plus dispersé. C'est cette direction
	# unique qui raconte le souffle — un éparpillement au hasard ne dirait rien.
	var cargo: Array[String] = [
		"Crate_Wooden", "Barrel", "Prop_Crate", "Crate_Metal", "FarmCrate_Empty",
		"Pot_1", "Bag", "Bottle_1", "Barrel_Apples", "Crate_Wooden",
		"FarmCrate_Apple", "Pouch_Large",
	]
	for i: int in range(cargo.size()):
		var reach: float = 3.2 + float(i) * 1.35
		var drift: float = sin(float(i) * 1.91) * (1.0 + float(i) * 0.42)
		var at: Vector3 = Vector3(reach * 0.86 + drift, 0.0,
			reach * 0.5 - drift * 0.8)
		# Les caisses les plus loin sont éventrées : elles gisent à plat.
		var toppled: bool = i >= 5
		var rot: Vector3 = Vector3(96.0 if toppled else 0.0,
			float(i) * 53.0, 12.0 if toppled else 0.0)
		if toppled:
			at.y = 0.3
		_spawn(cargo[i], at, rot, wreck)
		if not toppled:
			_wall_collider(wreck, at + Vector3(0, 0.5, 0),
				Vector3(1.0, 1.0, 1.0))
	# Ce qui est sorti des caisses, plus léger, va plus loin encore.
	var spill: Array[Array] = [
		["Pot_1_Lid", Vector3(11.5, 0.05, 4.0), Vector3(0, 70, 0), 1.0,
			Vector3.ZERO],
		["Carrot", Vector3(9.0, 0.05, 2.2), Vector3(88.0, 20.0, 0.0), 1.0,
			Vector3.ZERO],
		["Carrot", Vector3(12.2, 0.05, 6.4), Vector3(84.0, 140.0, 0.0), 1.0,
			Vector3.ZERO],
		["Mug", Vector3(7.4, 0.05, 6.0), Vector3(0, 0, 104.0), 1.0,
			Vector3.ZERO],
		["Bottle_1", Vector3(14.0, 0.05, 3.2), Vector3(0, 0, 86.0), 1.0,
			Vector3.ZERO],
		["Scroll_1", Vector3(6.2, 0.05, 8.4), Vector3(0, 35, 0), 1.0,
			Vector3.ZERO],
		["Book_Stack_1", Vector3(4.6, 0.05, 9.6), Vector3(0, 0, 74.0), 1.0,
			Vector3.ZERO],
		["Pebble_Round_1", Vector3(8.2, 0.02, -1.0), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Pebble_Square_2", Vector3(10.6, 0.02, 0.4), Vector3(0, 50, 0), 1.0,
			Vector3.ZERO],
	]
	_dressing(wreck, spill)

	# L'ATTELAGE ROMPU et l'ÉQUIPEMENT DU GARDE. L'arme est la raison de venir :
	# elle est restée là où l'homme est tombé, contre le chariot couché.
	var escort: Array[Array] = [
		["Chain_Coil", Vector3(-4.6, 0.05, 3.6), Vector3(0, 25, 0), 1.0,
			Vector3.ZERO],
		["Rope_1", Vector3(-3.2, 0.05, 4.6), Vector3(0, 130, 0), 1.0,
			Vector3.ZERO],
		["Sword_Bronze", Vector3(-8.4, 0.06, 3.4), Vector3(88.0, 62.0, 0.0),
			1.0, Vector3.ZERO],
		["Shield_Wooden", Vector3(-8.8, 0.45, 1.4), Vector3(0.0, 20.0, 72.0),
			1.0, Vector3.ZERO],
		["WeaponStand", Vector3(-7.0, 0.25, -1.2), Vector3(80.0, 40.0, 0.0),
			1.0, Vector3.ZERO],
		["Banner_2_Cloth", Vector3(-5.0, 0.06, -2.0), Vector3(87.0, 12.0, 0.0),
			1.0, Vector3.ZERO],
		["Banner_2", Vector3(-9.6, 0.0, -4.4), Vector3(0.0, 10.0, 24.0), 1.0,
			Vector3.ZERO],
		["Torch_Metal", Vector3(-2.4, 0.05, 2.6), Vector3(78.0, 55.0, 0.0), 1.0,
			Vector3.ZERO],
		["Lantern_Wall", Vector3(-6.9, 1.3, 0.4), Vector3(0.0, 0.0, 96.0), 1.0,
			Vector3.ZERO],
	]
	_dressing(wreck, escort)
	_marker(wreck, "AncrageRecompense", Vector3(-8.4, 0.2, 3.4))

	# LA TRAÎNÉE VERS LE NORD : ce que les survivants ont porté puis lâché, de
	# plus en plus espacé. Elle pointe vers la citadelle — c'est l'indice.
	var trail: Array[Array] = [
		["Bag", Vector3(-1.8, 0.05, -14.0), Vector3(0, 30, 0), 1.0,
			Vector3.ZERO],
		["Bucket_Wooden_1", Vector3(-0.6, 0.2, -16.5), Vector3(0.0, 0.0, 96.0),
			1.0, Vector3.ZERO],
		["Pouch_Large", Vector3(-1.1, 0.05, -20.5), Vector3(0, 110, 0), 1.0,
			Vector3.ZERO],
		["Mug", Vector3(0.6, 0.05, -25.0), Vector3(0.0, 0.0, 88.0), 1.0,
			Vector3.ZERO],
		["Bottle_1", Vector3(-0.2, 0.05, -30.0), Vector3(0.0, 0.0, 92.0), 1.0,
			Vector3.ZERO],
	]
	_dressing(wreck, trail)

	# RIEN N'A REPOUSSÉ : l'herbe reprend seulement au bord de la brûlure, et
	# les buissons intacts sont au-delà. Contraste voulu avec les trois autres
	# ruines, toutes anciennes et reverdies.
	var fringe: Array[Array] = [
		["Grass_Wispy_Short", Vector3(-6.0, 0.0, -5.6), Vector3(0, 40, 0), 1.0,
			Vector3.ZERO],
		["Grass_Wispy_Short", Vector3(6.6, 0.0, -6.2), Vector3(0, 190, 0), 1.0,
			Vector3.ZERO],
		["Grass_Common_Short", Vector3(-7.4, 0.0, 7.0), Vector3(0, 90, 0), 1.0,
			Vector3.ZERO],
		["Bush_Common", Vector3(-12.0, 0.0, -3.0), Vector3(0, 70, 0), 1.1,
			Vector3.ZERO],
		["Bush_Common", Vector3(13.5, 0.0, -8.5), Vector3(0, 210, 0), 1.0,
			Vector3.ZERO],
		["Bush_Common_Flowers", Vector3(-10.5, 0.0, 9.0), Vector3(0, 20, 0),
			1.0, Vector3.ZERO],
		["Pine_3", Vector3(-16.0, 0.0, 4.0), Vector3(0, 60, 0), 1.0,
			Vector3(1.0, 5.0, 1.0)],
		["Pine_1", Vector3(15.5, 0.0, 10.5), Vector3(0, 130, 0), 1.0,
			Vector3(1.0, 5.0, 1.0)],
		["DeadTree_1", Vector3(9.0, 0.0, -12.0), Vector3(0.0, 25.0, 9.0), 1.0,
			Vector3(0.9, 4.0, 0.9)],
	]
	_dressing(wreck, fringe)

	_place_poi(wreck, POI_CARAVAN, "Caravane foudroyée", &"route_du_donjon",
		Vector3(0.0, 5.0, -4.0), Vector3(44.0, 14.0, 52.0))
