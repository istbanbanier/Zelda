## VESTIGES DE LA VALLÉE — quatre ruines complémentaires de `ValleyRuins`.
##
## Ordre d'extension §2 : « plusieurs ensembles de ruines explorables ». La
## règle centrale reste celle de `ValleyRuins` : la COMPOSITION doit raconter,
## sans une ligne de texte. Une pierre debout ne dit rien ; une rangée de
## stèles couchées TOUTES du même côté dit ce qui est passé par là.
##
## Les quatre vestiges, et ce que chacun raconte :
##
##   - `ObservatoireEnRuine` (plaine sud, est de la crête) — on lisait le ciel
##     ici. La face NORD du tambour est tombée, l'anneau d'instrument s'est
##     brisé et sa moitié manquante gît au nord-est, au bout d'une traînée de
##     bronze et de brique. La moitié restée debout tient encore sur son socle
##     fendu ; le lierre ne monte que sur les faces debout. L'escalier
##     extérieur, lui, a survécu. RAISON D'Y ALLER : la plateforme est un
##     belvédère plein ciel, et la salle basse — ouverte par la brèche —
##     conserve le coffre du veilleur.
##
##   - `CimetiereDuTertre` (plaine nord, route du donjon) — quatre rangées de
##     stèles tournées vers la citadelle. Trois tiennent debout, légèrement de
##     travers ; la QUATRIÈME, celle qui touche le tombeau, est couchée d'un
##     seul et même côté, tournée vers l'extérieur. La dalle du tombeau est
##     descellée, poussée de biais hors de sa feuillure, et une traînée de
##     gravats sort par la porte. RAISON D'Y ALLER : le tombeau est un abri
##     réel, ses offrandes n'ont pas été reprises et les champignons y poussent.
##
##   - `FortificationAncienne` (plaine nord, approche ouest du donjon) — une
##     courtine barrait le passage. Les meurtrières regardent toutes à
##     l'OUEST : on attendait l'ennemi de ce côté. La brèche du centre a été
##     forcée et ses pierres sont retombées à l'INTÉRIEUR — le coup est venu du
##     dehors. Le chemin de ronde nord a tenu ; celui du sud s'est effondré et
##     ses dalles jonchent la cour. RAISON D'Y ALLER : le chemin de ronde est
##     praticable — panorama et raccourci au-dessus de la brèche — et le corps
##     de garde de la tour d'angle n'a jamais été vidé.
##
##   - `SanctuaireForestier` (clairière sud) — la forêt a repris son bien. Un
##     arbre penché s'appuie sur le toit affaissé, les racines soulèvent le
##     dallage du parvis et le sentier disparaît sous les fougères, de plus en
##     plus espacé à mesure qu'on s'éloigne. Les offrandes sont restées sur
##     l'autel : personne n'est revenu. RAISON D'Y ALLER : offrandes et
##     ingrédients, et trois cairns encore alignés vers le NORD — un indice de
##     direction, pas un panneau.
##
## §1 est catégorique : ce qui paraît ouvert doit l'être. La brèche de la
## courtine, la brèche du tambour, l'arche du tombeau et le parvis du
## sanctuaire ne portent AUCUNE collision en travers. Chaque vestige se déclare
## au `DiscoveryLog` par son `PointOfInterest`, sous un identifiant §19.3 stable
## et distinct de tous ceux déjà posés dans la vallée.
class_name ValleyRelics
extends Node3D

## Le kit modulaire est réparti sur cinq dossiers. Une pièce se résout par
## RECHERCHE, jamais par chemin figé : déplacer un asset d'un lot à l'autre
## casserait les vestiges en silence.
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
## Hauteur d'une marche. §8.2 plafonne le step height à 0,30–0,38 m : un
## escalier de ruine ne doit pas devenir une échelle.
const STEP_RISE: float = 3.12 / 9.0
const STEP_RUN: float = 0.55

## Implantations, en coordonnées MONDE (ce nœud reste à l'origine ; chaque
## vestige porte sa propre position). Repères du relief : plaine sud y = 2 pour
## z ≥ 16, plaine nord y = 2 pour z ≤ -4, lit de rivière à z = 10. Aucun de ces
## quatre sites n'approche à moins de 30 m d'un lieu déjà posé — village,
## hameaux, camp, pylône, donjon, crête, landmarks, grottes, ruines.
const SITE_OBSERVATORY: Vector3 = Vector3(76.0, 2.0, 128.0)
const SITE_CEMETERY: Vector3 = Vector3(58.0, 2.0, -78.0)
const SITE_RAMPART: Vector3 = Vector3(-104.0, 2.0, -138.0)
const SITE_SHRINE: Vector3 = Vector3(18.0, 2.0, 102.0)

## Identifiants §19.3 : `zone.category.name.index`. Quatre lieux DISTINCTS, et
## distincts des quinze déjà déclarés ailleurs dans la vallée.
const POI_OBSERVATORY: StringName = &"valley.poi.ruined_observatory.01"
const POI_CEMETERY: StringName = &"valley.poi.barrow_cemetery.01"
const POI_RAMPART: StringName = &"valley.poi.old_rampart.01"
const POI_SHRINE: StringName = &"valley.poi.forest_shrine.01"

## Noms des quatre nœuds de vestige, dans l'ordre de construction.
const RELIC_NODES: Array[String] = [
	"ObservatoireEnRuine", "CimetiereDuTertre", "FortificationAncienne",
	"SanctuaireForestier",
]

## Teintes des volumes taillés à la main (stèles, dalles, autel). §3.4 : ocres
## et bruns froids, jamais de noir pur — sauf le creux d'une tombe ouverte, qui
## DOIT se lire comme un vide.
const COL_STONE: Color = Color(0.56, 0.51, 0.44)
const COL_STONE_DARK: Color = Color(0.38, 0.35, 0.32)
const COL_VOID: Color = Color(0.09, 0.09, 0.11)

## Points d'intérêt des quatre vestiges, dans l'ordre de `RELIC_NODES`.
var pois: Array[PointOfInterest] = []
## Cote de la plateforme de l'observatoire — la preuve physique s'y réfère.
var observatory_platform_y: float = 0.0
## Cote du chemin de ronde de la courtine — preuve physique elle aussi.
var rampart_walk_y: float = 0.0
## Cote du sol du tombeau.
var tomb_floor_y: float = 0.0
## Cote du sol du sanctuaire.
var shrine_floor_y: float = 0.0

## Nombre de pièces du kit RÉELLEMENT instanciées. Les volumes fabriqués par ce
## script (collisions, stèles, dalles) n'y entrent pas : le compteur doit rester
## une preuve que les assets se résolvent.
var _built: int = 0
## Assets manquants déjà signalés — un avertissement par asset, pas par pose.
var _missing: Dictionary = {}


func _ready() -> void:
	_build_observatory()
	_build_cemetery()
	_build_rampart()
	_build_shrine()


func piece_count() -> int:
	return _built


## Vestige par son nom de nœud, pour les tests et le monde.
func relic(node_name: String) -> Node3D:
	return get_node_or_null(NodePath(node_name)) as Node3D


func poi_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for place: PointOfInterest in pois:
		ids.append(place.poi_id)
	return ids


## Implantations, dans l'ordre de `RELIC_NODES` — le test de séparation les
## compare aux lieux déjà posés dans la vallée.
func sites() -> Array[Vector3]:
	var places: Array[Vector3] = []
	places.append(SITE_OBSERVATORY)
	places.append(SITE_CEMETERY)
	places.append(SITE_RAMPART)
	places.append(SITE_SHRINE)
	return places


## Déclare les quatre vestiges au journal. `ValleyWorld` fait déjà cette liaison
## en parcourant ses `PointOfInterest` ; cette méthode sert aux scènes et aux
## tests qui montent les vestiges seuls.
func bind_all(discovery_log: DiscoveryLog) -> int:
	var bound: int = 0
	for place: PointOfInterest in pois:
		place.bind(discovery_log)
		if place.is_bound():
			bound += 1
	return bound


# --- Briques ----------------------------------------------------------------

## Instancie une pièce du kit. Renvoie `null` si l'asset manque, sans lever :
## un vestige amputé d'un modèle doit rester chargeable et le dire.
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
			push_warning("[vestiges] pièce absente du kit : %s" % asset)
		return null
	var node: Node3D = packed.instantiate() as Node3D
	# Nom unique : deux pièces homonymes sous le même parent seraient renommées
	# en `@…@` par le moteur, et plus aucun test ne pourrait les désigner.
	node.name = "%s_%03d" % [asset, _built]
	node.position = at
	node.rotation_degrees = rot_deg
	if not is_equal_approx(factor, 1.0):
		node.scale = Vector3.ONE * factor
	(parent if parent != null else self).add_child(node)
	_built += 1
	return node


## Pose droite : le cas courant.
func _piece(asset: String, at: Vector3, yaw_deg: float, parent: Node3D) -> Node3D:
	return _spawn(asset, at, Vector3(0.0, yaw_deg, 0.0), parent)


## Collision explicite : le kit est purement visuel. Une boîte statique est
## posée à la main, ce qui permet de LAISSER un trou là où le vestige paraît
## ouvert — un collider unique par façade murerait la brèche.
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


## Décor : liste uniforme `[asset, position, rotation, échelle, collision]`.
## Une caisse barre le passage comme une caisse ; une fleur ne barre rien —
## d'où la collision explicite, entrée par entrée (Vector3.ZERO = aucune).
func _dressing(parent: Node3D, entries: Array[Array]) -> void:
	for entry: Array in entries:
		var at: Vector3 = entry[1] as Vector3
		_spawn(String(entry[0]), at, entry[2] as Vector3, parent, "",
			float(entry[3]))
		var collision: Vector3 = entry[4] as Vector3
		if collision != Vector3.ZERO:
			_wall_collider(parent, at + Vector3(0, collision.y * 0.5, 0),
				collision)


## Bloc taillé à la main : stèle, dalle, socle, jambage. Le kit ne contient
## aucune de ces formes, et une stèle est le seul moyen de raconter un
## cimetière. La collision est ENFANT du visuel : elle hérite donc de sa
## rotation, ce qu'une boîte posée à part ne ferait pas.
func _block(parent: Node3D, block_name: String, centre: Vector3, size: Vector3,
		rot_deg: Vector3, tone: Color, solid: bool) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = block_name
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = tone
	material.roughness = 0.95
	mesh.material_override = material
	mesh.position = centre
	mesh.rotation_degrees = rot_deg
	parent.add_child(mesh)
	if solid:
		var body: StaticBody3D = StaticBody3D.new()
		body.name = "Masse"
		body.collision_layer = 1
		body.collision_mask = 0
		var shape: CollisionShape3D = CollisionShape3D.new()
		var hull: BoxShape3D = BoxShape3D.new()
		hull.size = size
		shape.shape = hull
		body.add_child(shape)
		mesh.add_child(body)
	return mesh


## Stèle : dalle mince plantée. Debout, elle porte sa collision ; couchée, elle
## n'en porte pas — on marche par-dessus une pierre tombée.
func _stele(parent: Node3D, index: int, ground: Vector3, height: float,
		yaw_deg: float, tilt_deg: float, fallen: bool) -> void:
	var lift: float = 0.09 if fallen else height * 0.5
	var pitch: float = 84.0 if fallen else tilt_deg
	var roll: float = 0.0 if fallen else tilt_deg * 0.5
	_block(parent, "Stele%02d" % index, ground + Vector3(0.0, lift, 0.0),
		Vector3(0.62, height, 0.17), Vector3(pitch, yaw_deg, roll),
		COL_STONE, not fallen)


## Volée d'escalier praticable. `direction` est un axe unitaire ; chaque marche
## reçoit sa collision, plus large que le pas pour qu'aucune ne laisse un vide.
func _flight(parent: Node3D, base: Vector3, direction: Vector3, count: int,
		width: float) -> void:
	var axis: Vector3 = direction.abs()
	var run: Vector3 = axis * (STEP_RUN * 2.0)
	var cross: Vector3 = Vector3(1.0 - axis.x, 0.0, 1.0 - axis.z) * width
	var span: Vector3 = Vector3(maxf(run.x, cross.x), 0.4, maxf(run.z, cross.z))
	for i: int in range(count):
		var lift: float = float(i + 1) * STEP_RISE
		var at: Vector3 = base + direction * (float(i) * STEP_RUN)
		_wall_collider(parent, Vector3(at.x, base.y + lift - 0.2, at.z), span)
		_spawn("RockPath_Square_Wide" if i % 2 == 0 else "RockPath_Round_Wide",
			Vector3(at.x, base.y + lift - 0.06, at.z),
			Vector3(0.0, float(i) * 31.0, 0.0), parent, "", 1.1)


## Repère nommé : belvédère, ancrage de récompense, indice. Ce script ne pose
## AUCUN gameplay — un point d'intérêt n'est pas un coffre déguisé ; il expose
## des positions que le monde peut habiller.
func _marker(parent: Node3D, marker_name: String, at: Vector3) -> Marker3D:
	var marker: Marker3D = Marker3D.new()
	marker.name = marker_name
	marker.position = at
	parent.add_child(marker)
	return marker


## Déclare un vestige au monde : identifiant stable, nom affiché, région.
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
	return place


## Racine d'un vestige : position posée AVANT l'entrée dans l'arbre.
func _site(node_name: String, at: Vector3) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = node_name
	root.position = at
	add_child(root)
	return root


## Sous-ensemble nommé d'un vestige (tambour, tombeau, courtine…).
func _part(parent: Node3D, part_name: String, at: Vector3) -> Node3D:
	var node: Node3D = Node3D.new()
	node.name = part_name
	node.position = at
	parent.add_child(node)
	return node


# --- 1. OBSERVATOIRE EN RUINE -----------------------------------------------

## Plaine sud, à l'est de la route de la crête, sur une avancée dégagée.
##
## Tout le récit tient dans une direction : la face NORD est tombée, et
## l'instrument est parti du même côté. La brèche du rez-de-chaussée n'est pas
## une porte — c'est l'endroit où le mur n'est plus, et c'est par là qu'on
## entre. L'escalier extérieur, adossé au flanc est, a survécu : il mène à la
## plateforme, qui est la raison de venir.
func _build_observatory() -> void:
	var obs: Node3D = _site("ObservatoireEnRuine", SITE_OBSERVATORY)
	var half: float = 3.0                       # emprise 6 × 6 m
	var slots: Array[float] = [-2.0, 0.0, 2.0]
	var top: float = WALL_H * 2.0               # plateforme à 6,24 m
	observatory_platform_y = SITE_OBSERVATORY.y + top

	# LE TAMBOUR : deux niveaux de murs qui portent la plateforme. Sud, est et
	# ouest tiennent ; le nord n'a plus qu'un module d'angle.
	var drum: Node3D = _part(obs, "Tambour", Vector3.ZERO)
	for x: float in slots:
		for z: float in slots:
			_piece("Floor_UnevenBrick", Vector3(x, 0.02, z), 0.0, drum)
	_wall_collider(drum, Vector3(0, -0.25, 0), Vector3(6.4, 0.5, 6.4))
	for level: int in range(2):
		var y: float = float(level) * WALL_H
		for x: float in slots:
			_wall(drum, Vector3(x, y, half), 0.0,
				"Wall_UnevenBrick_Window_Wide_Round" if x == 0.0 and level == 0
				else "Wall_UnevenBrick_Straight")
		for z: float in slots:
			_wall(drum, Vector3(-half, y, z), 90.0,
				"Wall_UnevenBrick_Window_Thin_Round" if z == 0.0
				else "Wall_UnevenBrick_Straight")
			_wall(drum, Vector3(half, y, z), 270.0, "Wall_UnevenBrick_Straight")
		# NORD : un seul module debout, à l'angle ouest. Les quatre mètres
		# restants sont la BRÈCHE — aucune collision en travers (§1).
		_wall(drum, Vector3(-2.0, y, -half), 180.0, "Wall_UnevenBrick_Straight")

	# LA PLATEFORME : le plancher haut a tenu là où ses murs ont tenu. Ouverte
	# au nord et à l'est — c'est ce qui en fait un belvédère et pas une pièce.
	var deck: Node3D = _part(obs, "Plateforme", Vector3.ZERO)
	for x: float in slots:
		for z: float in slots:
			_piece("Floor_Brick", Vector3(x, top + 0.02, z), 0.0, deck)
	_wall_collider(deck, Vector3(0, top - 0.2, 0), Vector3(6.4, 0.4, 6.4))
	# Parapet survivant : ouest et angle sud-ouest seulement. Bas (0,6 m) : il
	# borde la vue sans la couper.
	for z: float in slots:
		_piece("Prop_ExteriorBorder_Straight1", Vector3(-2.9, top + 0.02, z),
			90.0, deck)
	_wall_collider(deck, Vector3(-2.9, top + 0.3, 0.0), Vector3(0.4, 0.6, 6.2))
	_piece("Prop_ExteriorBorder_Straight1", Vector3(-2.0, top + 0.02, 2.9),
		0.0, deck)
	_wall_collider(deck, Vector3(-2.2, top + 0.3, 2.9), Vector3(2.0, 0.6, 0.4))

	# L'ESCALIER EXTÉRIEUR, adossé au flanc est : dix-huit marches de 0,347 m,
	# sous le plafond de §8.2. Une courte passerelle le raccorde à la
	# plateforme, au nord-est, par-dessus le chemin de ronde du tambour.
	var stair: Node3D = _part(obs, "Escalier", Vector3.ZERO)
	_flight(stair, Vector3(4.4, 0.0, 9.0), Vector3(0, 0, -1), 18, 1.9)
	_wall_collider(stair, Vector3(3.6, top - 0.2, -1.6), Vector3(1.8, 0.4, 2.0))
	_piece("Floor_Brick", Vector3(3.6, top + 0.02, -1.6), 0.0, stair)
	var props: Array[Array] = [
		["Prop_Support", Vector3(4.9, 0.0, -1.6), Vector3(0, 0, 0), 1.0,
			Vector3(0.4, top, 0.4)],
		["Prop_Support", Vector3(5.2, 0.0, 3.2), Vector3(0, 0, 6.0), 1.0,
			Vector3.ZERO],
		["Prop_Vine1", Vector3(3.05, 0.0, 2.0), Vector3(0, 270, 0), 1.0,
			Vector3.ZERO],
	]
	_dressing(stair, props)

	# L'INSTRUMENT BRISÉ : la moitié sud tient encore sur son socle fendu ; la
	# moitié nord est partie par-dessus le parapet manquant.
	var ring: Node3D = _part(obs, "InstrumentBrise", Vector3.ZERO)
	_block(ring, "SocleFendu", Vector3(-1.4, top + 0.42, -1.2),
		Vector3(1.8, 0.84, 1.8), Vector3(0, 12, 0), COL_STONE_DARK, true)
	_block(ring, "EclatDuSocle", Vector3(0.1, top + 0.12, -2.2),
		Vector3(0.8, 0.24, 0.6), Vector3(0, 34, 9), COL_STONE_DARK, false)
	var arc: Array[Array] = [
		["Wall_Arch", Vector3(-1.4, top + 0.84, -1.2), Vector3(0, 20, 6.0), 0.7,
			Vector3.ZERO],
		["Prop_MetalFence_Ornament", Vector3(-1.4, top + 0.86, -1.2),
			Vector3(0, 110, 0), 0.9, Vector3.ZERO],
		["Prop_MetalFence_Ornament", Vector3(-0.6, top + 0.86, -1.9),
			Vector3(24.0, 60.0, 0.0), 0.8, Vector3.ZERO],
	]
	_dressing(ring, arc)
	# LA CHUTE, au nord-est : l'anneau brisé, puis la traînée qui s'éclaircit.
	var fall: Array[Array] = [
		["Wall_Arch", Vector3(8.6, 0.35, -9.4), Vector3(82.0, 38.0, 0.0), 0.7,
			Vector3.ZERO],
		["Prop_MetalFence_Ornament", Vector3(7.2, 0.12, -7.6),
			Vector3(88.0, 22.0, 0.0), 0.9, Vector3.ZERO],
		["Prop_MetalFence_Simple", Vector3(10.4, 0.1, -11.8),
			Vector3(90.0, 64.0, 0.0), 1.0, Vector3.ZERO],
		["Wall_UnevenBrick_Straight", Vector3(4.6, 0.18, -5.8),
			Vector3(86.0, 28.0, 0.0), 1.0, Vector3.ZERO],
		["Wall_UnevenBrick_Window_Wide_Round", Vector3(6.4, 0.1, -12.6),
			Vector3(92.0, 47.0, 0.0), 1.0, Vector3.ZERO],
	]
	_dressing(ring, fall)
	# Traînée de gravats DÉTERMINISTE (angle d'or) : deux chargements de la
	# vallée doivent donner exactement la même ruine.
	var debris: Array[String] = [
		"Prop_Brick1", "Pebble_Square_1", "Pebble_Round_2", "Rock_Medium_3",
		"Pebble_Square_2", "Prop_Brick1", "Rock_Medium_1",
	]
	for i: int in range(16):
		var spread: float = 3.6 + float(i) * 0.9
		var swing: float = sin(float(i) * 2.399) * (1.2 + float(i) * 0.2)
		var at: Vector3 = Vector3(spread * 0.7 + swing, 0.0,
			-spread * 0.72 + swing * 0.55)
		_spawn(debris[i % debris.size()], at, Vector3(0, float(i) * 47.0, 0),
			ring, "", 1.2 - 0.04 * float(i % 6))

	# LA SALLE BASSE, ouverte par la brèche : le poste du veilleur du ciel. Le
	# coffre n'a jamais été repris — c'est la récompense de la ruine.
	var inside: Array[Array] = [
		["Chest_Wood", Vector3(-1.7, 0.05, 1.7), Vector3(0, 24, 0), 1.0,
			Vector3(1.1, 0.8, 0.8)],
		["Bookcase_2", Vector3(-2.2, 0.05, -1.6), Vector3(0, 0, 0), 1.0,
			Vector3(1.2, 1.8, 0.5)],
		["Shelf_Simple", Vector3(2.1, 0.05, 1.4), Vector3(0, 270, 0), 1.0,
			Vector3.ZERO],
		["Book_Stack_1", Vector3(2.1, 1.0, 1.4), Vector3(0, 18, 0), 1.0,
			Vector3.ZERO],
		["Scroll_1", Vector3(1.2, 0.05, -0.4), Vector3(0, 40, 0), 1.0,
			Vector3.ZERO],
		["Scroll_1", Vector3(0.4, 0.05, -1.9), Vector3(0, 130, 0), 1.0,
			Vector3.ZERO],
		["Stool", Vector3(0.9, 0.05, 1.2), Vector3(0, 0, 0), 1.0, Vector3.ZERO],
		["Barrel", Vector3(-2.2, 0.3, 0.2), Vector3(0, 0, 94.0), 1.0,
			Vector3.ZERO],
		["Mushroom_Common", Vector3(-2.4, 0.05, 2.5), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Mushroom_Laetiporus", Vector3(-1.1, 0.05, 2.7), Vector3(0, 120, 0),
			1.0, Vector3.ZERO],
		["Grass_Common_Short", Vector3(1.6, 0.05, -2.6), Vector3(0, 60, 0), 0.9,
			Vector3.ZERO],
		["Prop_Vine2", Vector3(-2.95, 0.0, -1.0), Vector3(0, 90, 0), 1.0,
			Vector3.ZERO],
	]
	_dressing(drum, inside)

	# LA TABLE DU VEILLEUR, restée sur la plateforme, et le belvédère lui-même.
	var lookout: Array[Array] = [
		["Workbench", Vector3(-2.0, top + 0.05, 1.7), Vector3(0, 8, 0), 1.0,
			Vector3(1.6, 1.0, 0.9)],
		["Book_Stack_1", Vector3(-2.0, top + 0.95, 1.7), Vector3(0, 22, 0), 1.0,
			Vector3.ZERO],
		["CandleStick", Vector3(-2.6, top + 0.95, 1.2), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Bottle_1", Vector3(-1.3, top + 0.06, 2.4), Vector3(0, 0, 88.0), 1.0,
			Vector3.ZERO],
		["Lantern_Wall", Vector3(-2.85, top + 1.5, -0.4), Vector3(0, 90, 0),
			1.0, Vector3.ZERO],
	]
	_dressing(deck, lookout)
	_marker(obs, "Belvedere", Vector3(1.2, top + 0.1, 1.2))
	_marker(obs, "AncrageRecompense", Vector3(-1.7, 0.1, 1.7))

	# LA VIE REVIENT SUR LA MOITIÉ DEBOUT — et nulle part sur la traînée.
	var life: Array[Array] = [
		["Prop_Vine1", Vector3(-3.15, 0.0, 1.4), Vector3(0, 90, 0), 1.0,
			Vector3.ZERO],
		["Prop_Vine2", Vector3(-3.15, WALL_H, -1.4), Vector3(0, 90, 0), 1.0,
			Vector3.ZERO],
		["Prop_Vine1", Vector3(1.0, 0.0, 3.15), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Bush_Common", Vector3(-5.4, 0.0, 3.6), Vector3(0, 22, 0), 1.1,
			Vector3.ZERO],
		["Bush_Common_Flowers", Vector3(-5.0, 0.0, -1.4), Vector3(0, 140, 0),
			1.0, Vector3.ZERO],
		["Fern_1", Vector3(-3.6, 0.02, 2.6), Vector3(0, 60, 0), 1.0,
			Vector3.ZERO],
		["Flower_4_Group", Vector3(-6.2, 0.02, 0.8), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Grass_Common_Tall", Vector3(-4.4, 0.0, -4.2), Vector3(0, 10, 0), 1.0,
			Vector3.ZERO],
		["Grass_Wispy_Tall", Vector3(2.2, 0.0, -5.4), Vector3(0, 300, 0), 1.0,
			Vector3.ZERO],
		["Grass_Wispy_Short", Vector3(12.0, 0.0, -14.5), Vector3(0, 80, 0), 1.0,
			Vector3.ZERO],
		["TwistedTree_3", Vector3(-8.6, 0.0, -5.0), Vector3(0, 130, 0), 1.0,
			Vector3(0.9, 4.0, 0.9)],
		["CommonTree_2", Vector3(-9.5, 0.0, 6.5), Vector3(0, 40, 0), 1.0,
			Vector3(1.0, 5.0, 1.0)],
		["Pine_4", Vector3(11.5, 0.0, 8.5), Vector3(0, 200, 0), 1.0,
			Vector3(1.0, 5.0, 1.0)],
		["RockPath_Round_Wide", Vector3(6.2, 0.02, 8.4), Vector3(0, 12, 0), 1.0,
			Vector3.ZERO],
		["RockPath_Round_Thin", Vector3(8.4, 0.02, 10.0), Vector3(0, 24, 0),
			1.0, Vector3.ZERO],
		["RockPath_Square_Small_1", Vector3(10.8, 0.02, 12.2),
			Vector3(0, 6, 0), 1.0, Vector3.ZERO],
	]
	_dressing(obs, life)

	_place_poi(obs, POI_OBSERVATORY, "Observatoire en ruine", &"plaine_sud",
		Vector3(2.0, 5.0, -1.0), Vector3(40.0, 18.0, 40.0))


# --- 2. CIMETIÈRE DU TERTRE -------------------------------------------------

## Plaine nord, en bordure de la route du donjon.
##
## Quatre rangées de stèles tournées vers la citadelle. Trois penchent au
## hasard, comme penche une pierre qu'on n'a pas redressée depuis longtemps.
## La quatrième, celle qui touche le tombeau, est couchée d'un seul et même
## côté, tournée vers l'extérieur : c'est la seule chose qui raconte que la
## dalle n'est pas tombée toute seule.
func _build_cemetery() -> void:
	var yard: Node3D = _site("CimetiereDuTertre", SITE_CEMETERY)

	# LE TOMBEAU : 4 × 4 m, une arche plein sud. L'arche est OUVERTE — seuls
	# les jambages portent une collision (§1).
	var tomb: Node3D = _part(yard, "Tombeau", Vector3(0.0, 0.0, -10.0))
	var half: float = 2.0
	var slots: Array[float] = [-1.0, 1.0]
	for x: float in slots:
		for z: float in slots:
			_piece("Floor_Brick", Vector3(x, 0.02, z), 0.0, tomb)
	tomb_floor_y = SITE_CEMETERY.y + 0.02
	_wall_collider(tomb, Vector3(0, -0.25, 0), Vector3(4.4, 0.5, 4.4))
	for x: float in slots:
		_wall(tomb, Vector3(x, 0, -half), 180.0, "Wall_UnevenBrick_Straight")
	for z: float in slots:
		_wall(tomb, Vector3(-half, 0, z), 90.0,
			"Wall_UnevenBrick_Window_Thin_Round" if z > 0.0
			else "Wall_UnevenBrick_Straight")
		_wall(tomb, Vector3(half, 0, z), 270.0, "Wall_UnevenBrick_Straight")
	# Façade sud : l'arche et ses deux jambages, deux mètres de passage libre.
	_piece("Wall_Arch", Vector3(0.0, 0.0, half), 0.0, tomb)
	_piece("DoorFrame_Round_Brick", Vector3(0.0, 0.0, half - 0.05), 0.0, tomb)
	for side: float in [-1.0, 1.0]:
		_wall_collider(tomb, Vector3(side * 1.5, WALL_H * 0.5, half),
			Vector3(1.0, WALL_H, 0.4))
	_wall_collider(tomb, Vector3(0.0, WALL_H - 0.35, half),
		Vector3(4.0, 0.7, 0.4))
	_spawn("Roof_RoundTiles_4x4", Vector3(0.1, WALL_H, -0.1),
		Vector3(0.0, 0.0, -5.0), tomb)

	# LA DALLE DESCELLÉE : sa feuillure est vide et noire, elle-même repose de
	# biais à moitié dehors. La traînée de gravats sort par la porte.
	_block(tomb, "Feuillure", Vector3(0.0, 0.0, -0.5),
		Vector3(1.7, 0.14, 1.05), Vector3.ZERO, COL_VOID, false)
	_block(tomb, "DalleDescellee", Vector3(0.55, 0.16, 0.55),
		Vector3(1.75, 0.24, 1.15), Vector3(0, 16, 5), COL_STONE_DARK, true)
	_marker(yard, "DalleDescellee", Vector3(0.55, -9.45, 0.0))
	var drag: Array[String] = [
		"Pebble_Round_1", "Pebble_Square_2", "Prop_Brick1", "Pebble_Round_4",
		"Pebble_Square_1", "Pebble_Round_3",
	]
	for i: int in range(8):
		var reach: float = 1.4 + float(i) * 1.25
		var swing: float = sin(float(i) * 2.399) * 0.7
		_spawn(drag[i % drag.size()],
			Vector3(0.35 + swing, 0.02, -10.0 + reach),
			Vector3(0, float(i) * 53.0, 0), yard, "", 1.0 - 0.05 * float(i % 4))

	# LES OFFRANDES, jamais reprises : la récompense du tombeau.
	var offerings: Array[Array] = [
		["Chest_Wood", Vector3(-1.2, 0.05, -1.2), Vector3(0, 18, 0), 1.0,
			Vector3(1.1, 0.8, 0.8)],
		["Pot_1", Vector3(1.25, 0.05, -1.3), Vector3(0, 30, 0), 1.0,
			Vector3.ZERO],
		["Bottle_1", Vector3(1.5, 0.05, -0.2), Vector3(0, 0, 86.0), 1.0,
			Vector3.ZERO],
		["CandleStick", Vector3(-1.5, 0.05, 0.2), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Candle_1", Vector3(1.1, 0.05, 0.9), Vector3(0, 0, 74.0), 1.0,
			Vector3.ZERO],
		["Bag", Vector3(-0.7, 0.05, 1.3), Vector3(0, 120, 0), 1.0, Vector3.ZERO],
		["Mushroom_Common", Vector3(-1.7, 0.05, -1.8), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Mushroom_Common", Vector3(-1.3, 0.05, -1.9), Vector3(0, 70, 0), 0.9,
			Vector3.ZERO],
		["Mushroom_Laetiporus", Vector3(1.7, 0.05, -1.7), Vector3(0, 140, 0),
			1.0, Vector3.ZERO],
		["Clover_1", Vector3(0.9, 0.05, 1.7), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Prop_Vine1", Vector3(-2.15, 0.0, -0.6), Vector3(0, 90, 0), 1.0,
			Vector3.ZERO],
		["Prop_Vine2", Vector3(-0.8, 0.0, -2.15), Vector3(0, 180, 0), 1.0,
			Vector3.ZERO],
	]
	_dressing(tomb, offerings)
	_marker(yard, "AncrageRecompense", Vector3(-1.2, 0.1, -11.2))

	# LES RANGÉES : quatre lignes tournées vers la citadelle. La dernière, au
	# contact du tombeau, est couchée VERS L'EXTÉRIEUR, toute entière.
	var rows: Node3D = _part(yard, "Rangees", Vector3.ZERO)
	var columns: Array[float] = [-6.0, -3.6, -1.2, 1.2, 3.6, 6.0]
	var lines: Array[float] = [-4.0, -1.0, 2.0, 5.0]
	var index: int = 0
	for line: float in lines:
		var toppled: bool = is_equal_approx(line, -4.0)
		for x: float in columns:
			var wobble: float = sin(float(index) * 1.7)
			var height: float = 0.92 + 0.24 * absf(cos(float(index) * 0.9))
			_stele(rows, index, Vector3(x + wobble * 0.12, 0.0, line),
				height, 4.0 * wobble if not toppled else 26.0,
				5.5 * wobble, toppled)
			index += 1
	# Deux tombes plus soignées : un entourage bas et un cairn.
	for side: float in [-1.0, 1.0]:
		_block(rows, "Entourage%d" % int(side + 2.0),
			Vector3(side * 3.6, 0.13, 6.9), Vector3(2.2, 0.26, 0.22),
			Vector3(0, 2.0 * side, 0), COL_STONE, false)
	for i: int in range(3):
		var angle: float = TAU * float(i) / 3.0
		_spawn("Rock_Medium_%d" % (1 + i % 3),
			Vector3(-8.4 + cos(angle) * 0.5, 0.0, 7.8 + sin(angle) * 0.5),
			Vector3(0, angle * 57.3, 0), rows, "", 0.7)

	# L'ENCLOS : un muret sec à l'ouest et à l'est, un portail au sud dont le
	# linteau est tombé. Le nord est fermé par le tombeau lui-même.
	var fence: Node3D = _part(yard, "Enclos", Vector3.ZERO)
	for i: int in range(5):
		var z: float = -6.0 + float(i) * 3.2
		for side: float in [-1.0, 1.0]:
			if i == 2 and side > 0.0:
				continue                       # une brèche du muret, à l'est
			_block(fence, "Muret%d" % (i * 2 + int(side + 1.0)),
				Vector3(side * 9.0, 0.28, z), Vector3(0.42, 0.56, 2.9),
				Vector3(0, 1.5 * float(i), 0), COL_STONE, true)
	for side: float in [-1.0, 1.0]:
		_block(fence, "Jambage%d" % int(side + 2.0),
			Vector3(side * 1.7, 1.05, 8.4), Vector3(0.7, 2.1, 0.7),
			Vector3(0, 0, 2.0 * side), COL_STONE, true)
	_block(fence, "LinteauTombe", Vector3(0.4, 0.16, 9.9),
		Vector3(3.4, 0.32, 0.8), Vector3(0, 12, 4), COL_STONE_DARK, false)
	var gate: Array[Array] = [
		["Bench", Vector3(4.4, 0.05, 9.2), Vector3(0, 8, 0), 1.0,
			Vector3(1.6, 0.5, 0.6)],
		["Banner_1", Vector3(-4.6, 0.0, 9.4), Vector3(0.0, 20.0, 22.0), 1.0,
			Vector3.ZERO],
		["Pot_1_Lid", Vector3(2.6, 0.05, 8.6), Vector3(0, 40, 0), 1.0,
			Vector3.ZERO],
		["RockPath_Square_Wide", Vector3(0.0, 0.02, 10.6), Vector3(0, 4, 0),
			1.0, Vector3.ZERO],
		["RockPath_Round_Wide", Vector3(0.3, 0.02, 12.8), Vector3(0, 22, 0),
			1.0, Vector3.ZERO],
		["RockPath_Round_Thin", Vector3(-0.2, 0.02, 15.4), Vector3(0, 10, 0),
			1.0, Vector3.ZERO],
	]
	_dressing(fence, gate)

	# LA VIE : l'herbe court entre les rangées, les arbres cernent l'enclos, et
	# le lierre ne monte que sur le tombeau — la seule maçonnerie qui reste.
	var life: Array[Array] = [
		["TwistedTree_2", Vector3(-11.5, 0.0, -5.0), Vector3(0, 95, 0), 1.0,
			Vector3(0.9, 4.0, 0.9)],
		["DeadTree_1", Vector3(11.0, 0.0, 2.5), Vector3(0, 40, 0), 1.0,
			Vector3(0.9, 4.0, 0.9)],
		["CommonTree_5", Vector3(-12.5, 0.0, 6.5), Vector3(0, 20, 0), 1.0,
			Vector3(1.0, 5.0, 1.0)],
		["Pine_2", Vector3(12.5, 0.0, -8.5), Vector3(0, 150, 0), 1.0,
			Vector3(1.0, 5.0, 1.0)],
		["Bush_Common", Vector3(-9.8, 0.0, 1.5), Vector3(0, 60, 0), 1.1,
			Vector3.ZERO],
		["Bush_Common_Flowers", Vector3(9.6, 0.0, -3.5), Vector3(0, 130, 0),
			1.0, Vector3.ZERO],
		["Fern_1", Vector3(-2.6, 0.0, -7.4), Vector3(0, 210, 0), 1.0,
			Vector3.ZERO],
		["Fern_1", Vector3(2.9, 0.0, -7.8), Vector3(0, 40, 0), 1.0,
			Vector3.ZERO],
		["Flower_3_Group", Vector3(-4.8, 0.02, 3.4), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Flower_4_Group", Vector3(5.2, 0.02, -2.6), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Clover_2", Vector3(0.4, 0.02, 4.2), Vector3(0, 0, 0), 1.0,
			Vector3.ZERO],
		["Mushroom_Common", Vector3(-7.2, 0.02, -6.4), Vector3(0, 90, 0), 1.0,
			Vector3.ZERO],
	]
	_dressing(yard, life)
	var blades: Array[String] = [
		"Grass_Common_Short", "Grass_Wispy_Short", "Grass_Common_Tall",
		"Grass_Wispy_Tall",
	]
	for i: int in range(20):
		var x: float = -7.4 + float(i % 7) * 2.5 + sin(float(i) * 2.399) * 0.8
		var z: float = -5.4 + float(i / 7) * 3.1 + cos(float(i) * 1.7) * 0.9
		_spawn(blades[i % blades.size()], Vector3(x, 0.0, z),
			Vector3(0, float(i) * 61.0, 0), yard, "", 0.9)

	_place_poi(yard, POI_CEMETERY, "Cimetière du tertre", &"plaine_nord",
		Vector3(0.0, 5.0, -1.0), Vector3(40.0, 14.0, 44.0))
