## Relief macro de la Vallée de Néris — blockout D.1 (MASTER_SPEC §3.3, §7.4).
##
## Un blockout DÉCLARATIF : dalles (plateaux, terrasses, lit de rivière) et
## rampes en prismes convexes pleins — la leçon de B.1 (une boîte pivotée offre
## un dessous en surplomb ; un prisme convexe n'en a pas). Tout est déterministe,
## sans bruit ni aléa : les tests raisonnent sur des cotes exactes.
##
## La relation de §3.3 est portée par les masses : crête de départ (0, 24, 170),
## descente en S vers la terrasse du camp (45, 6, 65), lit de rivière autour de
## Z = 10 avec deux gués (les « deux routes » de §4.1), falaise d'apprentissage
## à l'ouest avec corniches de repos (§9.3), terrasse du pylône (115, 18, −25),
## forêt claire au sud-est, ruines centrales sur la route du donjon, et plateau
## monumental (0, 34, −210) portant le proxy de citadelle. Le pylône et la
## citadelle sont des PROXYS graybox : des masses à la bonne place, pas de l'art.
class_name ValleyTerrain
extends Node3D

## Épaisseur : toutes les dalles descendent jusqu'à cette profondeur — aucun
## interstice entre volumes voisins, donc aucune chute « dans » le relief.
const BASE_Y: float = -8.0

## Palette §3.4, en aplats graybox.
const COL_GRASS: Color = Color(0.365, 0.561, 0.239)
const COL_GRASS_DARK: Color = Color(0.30, 0.46, 0.21)
const COL_ROCK: Color = Color(0.608, 0.408, 0.259)
const COL_STONE: Color = Color(0.45, 0.44, 0.47)
const COL_WOOD: Color = Color(0.408, 0.251, 0.157)
const COL_COPPER: Color = Color(0.55, 0.36, 0.22)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)
const COL_RIVERBED: Color = Color(0.35, 0.42, 0.45)

## Habillage V4.2 (réf. 01 du pack V4) — différenciation des sols, eau, chemins,
## reliefs superposés. Le cyan de l'eau appartient à la bande « ciel/brume/eau »
## de §3.4, pas aux accents.
const COL_GRASS_LIT: Color = Color(0.58, 0.70, 0.35)     # crêtes exposées
const COL_GRASS_WET: Color = Color(0.28, 0.47, 0.26)     # berges humides
const COL_WATER: Color = Color(0.09, 0.55, 0.60, 0.82)   # ruban turquoise
const COL_PATH: Color = Color(0.62, 0.51, 0.34)          # terre battue
const COL_MOUNTAIN_WARM: Color = Color(0.47, 0.39, 0.33) # grès chaud
const COL_MOUNTAIN_FAR: Color = Color(0.52, 0.56, 0.65)  # lointain bleui


func _ready() -> void:
	_build_border_mountains()
	_build_plains_and_river()
	_build_spawn_ridge_and_descent()
	_build_camp_terrace()
	_build_learning_cliff()
	_build_pylon_terrace_and_proxy()
	_build_forest()
	_build_central_ruins()
	_build_dungeon_plateau_and_citadel()
	# Habillage V4.2 — visuel après les masses (l'eau et les chemins se posent
	# SUR le relief stabilisé ; les contreforts, eux, portent une collision).
	_dress_border_mountains()
	_build_river_water()
	_build_paths()
	_build_ground_variation()
	_build_crest_meadow()


## ---------------------------------------------------------------------------
## Zones
## ---------------------------------------------------------------------------

## Limites du monde (D.1R.4, PT-D1-09) : une chaîne montagneuse continue,
## PHYSIQUE, remplace l'absence de bords — pas un mur invisible. Faces internes
## à ±250, 70 m de haut, marquées `unclimbable` (§9.2 : le groupe de refus
## existe depuis B.3) — l'endurance n'y suffirait de toute façon pas.
const BORDER_INNER: float = 250.0
const BORDER_OUTER: float = 292.0
const BORDER_TOP: float = 70.0
const COL_MOUNTAIN: Color = Color(0.42, 0.38, 0.4)


func _build_border_mountains() -> void:
	var mid: float = (BORDER_INNER + BORDER_OUTER) * 0.5
	var depth: float = BORDER_OUTER - BORDER_INNER
	var span: float = BORDER_OUTER * 2.0
	var walls: Array[Array] = [
		["BorderNorth", Vector2(0, -mid), Vector2(span, depth)],
		["BorderSouth", Vector2(0, mid), Vector2(span, depth)],
		["BorderWest", Vector2(-mid, 0), Vector2(depth, span)],
		["BorderEast", Vector2(mid, 0), Vector2(depth, span)],
	]
	for wall: Array in walls:
		_slab(wall[0], wall[1], wall[2], BORDER_TOP, COL_MOUNTAIN)
		var body: StaticBody3D = get_node_or_null(NodePath(String(wall[0]))) as StaticBody3D
		if body != null:
			body.add_to_group("unclimbable")

func _build_plains_and_river() -> void:
	# Plaine sud (côté spawn/camp) et plaine nord (côté donjon/pylône), séparées
	# par le lit de rivière en bande autour de Z = 10 (§3.3 : « rivière en S
	# autour de Z = 10 » — le S visuel viendra avec l'eau ; le LIT est la bande).
	_slab("PlainSouth", Vector2(0, 136), Vector2(512, 240), 2.0, COL_GRASS)
	_slab("PlainNorth", Vector2(0, -126), Vector2(512, 260), 2.0, COL_GRASS)
	_slab("Riverbed", Vector2(0, 10), Vector2(512, 12), -1.5, COL_RIVERBED)
	# Deux gués : la route du donjon (ouest) et la route du pylône (est).
	_slab("FordWest", Vector2(20, 10), Vector2(12, 12), 2.0, COL_GRASS_DARK)
	_slab("FordEast", Vector2(95, 10), Vector2(12, 12), 2.0, COL_GRASS_DARK)


func _build_spawn_ridge_and_descent() -> void:
	# Crête de départ : le héros domine la vallée (§3.2, spawn §3.3 (0, 24, 170)).
	_slab("SpawnRidge", Vector2(0, 176), Vector2(100, 64), 24.0, COL_GRASS)
	# Descente en S : trois rampes douces alternant la direction, deux paliers.
	_ramp("DescentA", Vector3(20, 24, 146), Vector3(34, 16, 118), 10.0, COL_GRASS_DARK)
	_slab("DescentLanding1", Vector2(36, 110), Vector2(14, 16), 16.0, COL_GRASS)
	_ramp("DescentB", Vector3(34, 16, 104), Vector3(20, 8, 84), 10.0, COL_GRASS_DARK)
	_slab("DescentLanding2", Vector2(18, 78), Vector2(14, 12), 8.0, COL_GRASS)
	_ramp("DescentC", Vector3(20, 8, 74), Vector3(34, 6, 66), 8.0, COL_GRASS_DARK)


func _build_camp_terrace() -> void:
	# Terrasse du camp (§3.3 : (45, 6, 65)) et sa sortie vers la plaine sud.
	_slab("CampTerrace", Vector2(45, 65), Vector2(44, 40), 6.0, COL_GRASS)
	_ramp("CampExit", Vector3(40, 6, 47), Vector3(40, 2, 30), 10.0, COL_GRASS_DARK)
	# V4.3 (réf. 01 : tentes + feux) — le camp se LIT depuis la crête. Tentes
	# en tente (PrismMesh) avec collision boîte, à l'écart du chemin ; foyer de
	# pierre, braise émissive et lumière chaude. La colonne de fumée vit déjà
	# dans ValleyWorld.tscn.
	var camp: Node3D = Node3D.new()
	camp.name = "CampDressing"
	add_child(camp)
	var tents: Array[Array] = [
		# [pied xz, yaw, teinte]
		[Vector2(54, 58), 0.4, Color(0.55, 0.25, 0.18)],
		[Vector2(57, 70), -0.7, Color(0.50, 0.30, 0.16)],
		[Vector2(34, 76), 1.2, Color(0.45, 0.24, 0.20)],
	]
	for i: int in range(tents.size()):
		var tent: Array = tents[i]
		var foot: Vector2 = tent[0]
		var body: StaticBody3D = StaticBody3D.new()
		body.name = "Tent%d" % i
		body.collision_layer = 1
		body.collision_mask = 0
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(3.6, 2.4, 3.2)
		shape.shape = box
		shape.position = Vector3(0, 1.2, 0)
		body.add_child(shape)
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = "Tent%dMesh" % i
		var prism: PrismMesh = PrismMesh.new()
		prism.size = Vector3(3.8, 2.6, 3.4)
		mesh.mesh = prism
		mesh.material_override = _material(tent[2] as Color, false)
		mesh.position = Vector3(0, 1.3, 0)
		body.add_child(mesh)
		body.rotation.y = float(tent[1])
		body.position = Vector3(foot.x, 6.0, foot.y)   # AVANT add_child (règle D.0)
		camp.add_child(body)
	# Foyer : anneau de pierre, braise émissive, lumière chaude motivée (§7.7 :
	# « aucun visage de combat noir » — le camp reste lisible au crépuscule).
	_cylinder_in("FirePit", camp, Vector3(45, 6.0, 64), 1.1, 0.4, COL_STONE, false)
	_cylinder_in("FireCoals", camp, Vector3(45, 6.35, 64), 0.7, 0.3,
		Color(0.98, 0.55, 0.18), false)
	var coals: MeshInstance3D = camp.get_node("FireCoals") as MeshInstance3D
	var coal_material: StandardMaterial3D = coals.material_override as StandardMaterial3D
	coal_material.emission_enabled = true
	coal_material.emission = Color(0.98, 0.45, 0.12)
	coal_material.emission_energy_multiplier = 2.4
	var fire_light: OmniLight3D = OmniLight3D.new()
	fire_light.name = "CampFireLight"
	fire_light.light_color = Color(1.0, 0.62, 0.28)
	fire_light.light_energy = 1.8
	fire_light.omni_range = 14.0
	fire_light.position = Vector3(45, 7.4, 64)
	camp.add_child(fire_light)
	# ART-Q3 : props de production (registre ; repli boîte graybox). Le camp
	# vit : caisses empilées près des tentes, tonneaux au bord du foyer.
	# COLLISION à hauteur du modèle — le décor bloque, comme les boîtes.
	var camp_props: Array[Array] = [
		# [id, position, lacet, taille de collision]
		[&"prop.crate", Vector3(51.5, 6.0, 59.5), 0.35, Vector3(1.1, 1.2, 1.17)],
		[&"prop.crate", Vector3(52.7, 6.0, 60.8), 1.15, Vector3(1.1, 1.2, 1.17)],
		[&"prop.barrel", Vector3(41.2, 6.0, 61.0), 0.0, Vector3(0.72, 0.9, 0.72)],
		[&"prop.barrel", Vector3(40.4, 6.0, 62.2), 0.9, Vector3(0.72, 0.9, 0.72)],
	]
	for entry: Array in camp_props:
		_mount_camp_prop(camp, entry[0] as StringName, entry[1] as Vector3,
			float(entry[2]), entry[3] as Vector3)
	# Anneau de galets autour du foyer (env.rock.pebble_*) — décor pur, sans
	# collision : le foyer de pierre garde la sienne.
	var pebble_ids: Array[StringName] = [&"env.rock.pebble_a",
		&"env.rock.pebble_b", &"env.rock.pebble_c"]
	for i: int in range(8):
		var packed: PackedScene = AssetRegistry.resolve(pebble_ids[i % 3])
		if packed == null:
			break   # galets pas livrés : le cylindre de pierre suffit
		var pebble: Node3D = packed.instantiate() as Node3D
		pebble.name = "Pebble%d" % i   # noms uniques — pas de renommage @auto@
		var angle: float = TAU * float(i) / 8.0 + 0.23
		pebble.position = Vector3(45.0 + cos(angle) * 1.05, 6.28,
			64.0 + sin(angle) * 1.05)
		pebble.rotation.y = angle * 3.1
		pebble.scale = Vector3.ONE * (1.35 + 0.25 * float(i % 3))
		camp.add_child(pebble)


## Monte un prop du registre (ou sa boîte graybox de repli) avec une
## collision fixe : les IDs, le loot et les interactions du camp ne passent
## JAMAIS par ces décors — ce sont des obstacles muets (§14.1).
func _mount_camp_prop(parent: Node3D, id: StringName, at: Vector3,
		yaw: float, collision_size: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "CampProp_%s_%d" % [String(id).get_slice(".", 1),
		parent.get_child_count()]
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = collision_size
	shape.shape = box
	shape.position = Vector3(0, collision_size.y * 0.5, 0)
	body.add_child(shape)
	var packed: PackedScene = AssetRegistry.resolve(id)
	if packed != null:
		body.add_child(packed.instantiate())
	else:
		var mesh: MeshInstance3D = MeshInstance3D.new()
		var fallback: BoxMesh = BoxMesh.new()
		fallback.size = collision_size
		mesh.mesh = fallback
		mesh.material_override = _material(Color(0.5, 0.36, 0.2), false)
		mesh.position = Vector3(0, collision_size.y * 0.5, 0)
		body.add_child(mesh)
	body.rotation.y = yaw
	body.position = at   # AVANT add_child (règle D.0)
	parent.add_child(body)


func _build_learning_cliff() -> void:
	# Falaise d'apprentissage (§3.3 : ouest). Mur est du plateau : 12 m depuis la
	# plaine (y 2 → 14) — deux corniches de repos (§9.3) jalonnent la montée,
	# et le plateau récompense d'un panorama.
	_slab("LearningCliff", Vector2(-110, 65), Vector2(60, 50), 14.0, COL_ROCK)
	_slab("CliffLedgeLow", Vector2(-79.5, 58), Vector2(1.0, 6), 6.0, COL_ROCK)
	_slab("CliffLedgeHigh", Vector2(-79.5, 72), Vector2(1.0, 6), 10.5, COL_ROCK)


func _build_pylon_terrace_and_proxy() -> void:
	# Terrasse du pylône (§3.3 : (115, 18, −25)) et sa rampe d'accès nord.
	_slab("PylonTerrace", Vector2(115, -25), Vector2(56, 50), 18.0, COL_ROCK)
	# La rampe atterrit AU RAS du bord ouest (x = 87) : une arrivée à l'intérieur
	# de l'emprise laisserait un mur en travers de la pente — mesuré à la sonde
	# (y = 18 rencontré à mi-rampe avant correction).
	_ramp("PylonRamp", Vector3(64, 2, 2), Vector3(87, 18, -14), 10.0, COL_ROCK)
	# Proxy du pylône (V4.3, réf. 01 : tour de pierre ouvragée, anneaux, orbe) :
	# socle de pierre, fût de cuivre, deux anneaux de bronze, bande RUNIQUE
	# cyan émissive, tête-orbe — l'ancre verticale du tiers droit (§3.2).
	_cylinder("PylonPlinth", Vector3(115, 18, -25), 4.2, 2.4, COL_STONE, true)
	_cylinder("PylonShaft", Vector3(115, 20.4, -25), 2.5, 19.6, COL_COPPER, true)
	_cylinder("PylonRingLow", Vector3(115, 27.5, -25), 3.3, 1.0,
		Color(0.42, 0.30, 0.18), false)
	_cylinder("PylonRingHigh", Vector3(115, 35.0, -25), 3.1, 0.8,
		Color(0.42, 0.30, 0.18), false)
	_cylinder("PylonRunes", Vector3(115, 31.4, -25), 2.65, 1.2, COL_CYAN, false)
	var runes: MeshInstance3D = get_node("PylonRunes") as MeshInstance3D
	var rune_material: StandardMaterial3D = runes.material_override as StandardMaterial3D
	rune_material.emission_enabled = true
	rune_material.emission = COL_CYAN
	rune_material.emission_energy_multiplier = 1.6
	_orb("PylonHead", Vector3(115, 41.5, -25), 3.0, COL_CYAN)


func _build_forest() -> void:
	# Forêt claire au sud-est du centre (§3.3) : troncs à collision, couronnes
	# visuelles. Positions déterministes, espacées — des obstacles francs pour
	# la preuve de navigation.
	var trunks: Array[Vector2] = [
		Vector2(58, 24), Vector2(66, 33), Vector2(75, 22), Vector2(84, 30),
		Vector2(93, 24), Vector2(62, 44), Vector2(72, 40), Vector2(82, 46),
		Vector2(91, 38), Vector2(69, 52), Vector2(79, 56), Vector2(88, 52),
	]
	var forest: Node3D = Node3D.new()
	forest.name = "Forest"
	add_child(forest)
	# Trois tons de couronne (V4.2 : casser l'uniformité — §7.17, variation de
	# teinte contrôlée).
	var canopy_tones: Array[Color] = [
		COL_GRASS_DARK, Color(0.26, 0.42, 0.23), Color(0.34, 0.50, 0.20),
	]
	for i: int in range(trunks.size()):
		var at: Vector2 = trunks[i]
		_cylinder_in("Trunk%02d" % i, forest, Vector3(at.x, 2.0, at.y),
			0.5, 7.0, COL_WOOD, true)
		_orb_in("Canopy%02d" % i, forest, Vector3(at.x, 9.5, at.y), 2.6,
			canopy_tones[i % canopy_tones.size()])


func _build_central_ruins() -> void:
	# Ruines centrales, sur la route plaine nord → donjon : fragments de murs
	# avec de vrais passages — le détour que la navigation devra prouver.
	var ruins: Node3D = Node3D.new()
	ruins.name = "Ruins"
	add_child(ruins)
	var walls: Array[Array] = [
		# [centre xz, taille xz, hauteur]
		[Vector2(-6, -30), Vector2(12, 1.2), 3.0],
		[Vector2(8, -38), Vector2(1.2, 10), 2.4],
		[Vector2(4, -52), Vector2(14, 1.2), 3.2],
		[Vector2(-4, -62), Vector2(1.2, 12), 2.6],
		[Vector2(14, -60), Vector2(8, 1.2), 1.8],
		# Salle éventrée en U, ouverte au sud : trois murs. C'est le piège de la
		# preuve de navigation — un pilotage direct s'y coince, un chemin la
		# contourne par l'ouverture.
		[Vector2(-14, -44), Vector2(10, 1.2), 2.0],
		[Vector2(-18, -54), Vector2(1.2, 20), 2.2],
		[Vector2(-10, -54), Vector2(1.2, 20), 2.2],
	]
	for i: int in range(walls.size()):
		var wall: Array = walls[i]
		var center: Vector2 = wall[0]
		var size: Vector2 = wall[1]
		var height: float = wall[2]
		_box_in("RuinWall%02d" % i, ruins,
			Vector3(center.x, 2.0 + height * 0.5, center.y),
			Vector3(size.x, height, size.y), COL_STONE, true)


func _build_dungeon_plateau_and_citadel() -> void:
	# Plateau monumental (§3.3 : donjon (0, 34, −210)) et sa rampe processionnelle.
	_slab("DungeonPlateau", Vector2(0, -210), Vector2(130, 90), 34.0, COL_ROCK)
	# Même règle que la rampe du pylône : arrivée au ras du bord nord (z = -165).
	_ramp("DungeonRamp", Vector3(0, 2, -110), Vector3(0, 34, -165), 16.0, COL_ROCK)
	# Proxy de citadelle : masse centrale, quatre tours, cœur cyan — la
	# silhouette du fond de la vue d'ouverture (§3.2 : 300–420 m du spawn).
	var citadel: Node3D = Node3D.new()
	citadel.name = "CitadelProxy"
	add_child(citadel)
	_box_in("Keep", citadel, Vector3(0, 34 + 23, -210), Vector3(24, 46, 24), COL_STONE, true)
	for i: int in range(4):
		var dx: float = -14.0 if i % 2 == 0 else 14.0
		var dz: float = -14.0 if i < 2 else 14.0
		_box_in("Tower%d" % i, citadel, Vector3(dx, 34 + 28, -210 + dz),
			Vector3(8, 56, 8), COL_STONE, true)
	_box_in("EnergyCore", citadel, Vector3(0, 34 + 32, -210 + 12.2),
		Vector3(3, 10, 0.6), COL_CYAN, false, true)
	# V4.3 (réf. 02) : étagement de la masse — deux gradins sous le donjon pour
	# la silhouette pyramidale de la référence 01. Collision : on marche dessus.
	# Gradins DERRIÈRE le plan de la porte (z ≤ −200 : une première pose à
	# z −194 aurait muré la façade, cotes vérifiées avant capture).
	_box_in("TierLow", citadel, Vector3(0, 34 + 4, -215), Vector3(40, 8, 30),
		COL_STONE, true)
	_box_in("TierHigh", citadel, Vector3(0, 34 + 9, -217), Vector3(32, 10, 24),
		COL_STONE, true)
	# Façade monumentale (réf. 02) : piliers de bronze gravés de CONDUITS cyan
	# verticaux, linteau massif, large ouverture sombre en retrait — le
	# personnage est dominé par le bâtiment.
	for side_index: int in range(2):
		var x_side: float = -6.5 if side_index == 0 else 6.5
		_box_in("GatePillar%d" % side_index, citadel,
			Vector3(x_side, 34 + 8, -197.2), Vector3(3.0, 16.0, 3.0),
			Color(0.40, 0.30, 0.20), true)
		_box_in("GateConduit%d" % side_index, citadel,
			Vector3(x_side, 34 + 8, -195.6), Vector3(0.5, 13.0, 0.2),
			COL_CYAN, false, true)
	_box_in("GateLintel", citadel, Vector3(0, 34 + 16.6, -197.2),
		Vector3(16.0, 3.2, 3.4), Color(0.40, 0.30, 0.20), true)
	# Retrait sombre AFFLEURANT la face du donjon (z −198) : la porte
	# interactive garde 0,2 m d'avance — l'ouverture paraît large, l'entrée
	# reste la vraie porte.
	_box_in("GateRecess", citadel, Vector3(0, 34 + 6.5, -198.35),
		Vector3(10.0, 13.0, 1.0), Color(0.05, 0.06, 0.09), false)
	# Braseros de seuil : le chaud motive l'approche, le cyan reste la menace.
	for side_index: int in range(2):
		var x_side: float = -5.0 if side_index == 0 else 5.0
		_box_in("GateBrazier%d" % side_index, citadel,
			Vector3(x_side, 34 + 0.6, -194.5), Vector3(0.9, 1.2, 0.9),
			Color(0.30, 0.22, 0.16), true)
		_box_in("GateBrazierCoal%d" % side_index, citadel,
			Vector3(x_side, 34 + 1.35, -194.5), Vector3(0.6, 0.3, 0.6),
			Color(0.98, 0.55, 0.18), false, true)
		var brazier_light: OmniLight3D = OmniLight3D.new()
		brazier_light.name = "GateBrazierLight%d" % side_index
		brazier_light.light_color = Color(1.0, 0.62, 0.28)
		brazier_light.light_energy = 1.5
		brazier_light.omni_range = 10.0
		brazier_light.position = Vector3(x_side, 34 + 2.2, -194.5)
		citadel.add_child(brazier_light)
	# Marches processionnelles : trois emmarchements bas (≤ step height 0,30).
	_slab("GateStepLow", Vector2(0, -192.0), Vector2(14, 2.4), 34.15, COL_STONE)
	_slab("GateStepMid", Vector2(0, -194.2), Vector2(12, 2.2), 34.3, COL_STONE)
	_slab("GateStepHigh", Vector2(0, -196.2), Vector2(10, 1.8), 34.45, COL_STONE)
	# Ouverture encadrée de cyan (D.1R.4) : le seuil intérieur, dans le retrait.
	_box_in("DoorFrameLeft", citadel, Vector3(-2.2, 34 + 3, -197.8),
		Vector3(0.8, 6.0, 0.6), COL_CYAN, false, true)
	_box_in("DoorFrameRight", citadel, Vector3(2.2, 34 + 3, -197.8),
		Vector3(0.8, 6.0, 0.6), COL_CYAN, false, true)
	_box_in("DoorFrameTop", citadel, Vector3(0, 34 + 6.2, -197.8),
		Vector3(5.2, 0.8, 0.6), COL_CYAN, false, true)
	var door: SceneDoor = SceneDoor.new()
	door.name = "CitadelDoor"
	door.verb = "Entrer"
	door.target_scene = "res://scenes/world/citadel/CitadelVestibule.tscn"
	door.spawn_tag = &"from_valley"
	door.collision_layer = 1
	door.collision_mask = 0
	var door_shape: CollisionShape3D = CollisionShape3D.new()
	var door_box: BoxShape3D = BoxShape3D.new()
	door_box.size = Vector3(3.6, 6.0, 0.5)
	door_shape.shape = door_box
	door.add_child(door_shape)
	var door_mesh: MeshInstance3D = MeshInstance3D.new()
	var door_mesh_box: BoxMesh = BoxMesh.new()
	door_mesh_box.size = Vector3(3.6, 6.0, 0.5)
	door_mesh.mesh = door_mesh_box
	var door_material: StandardMaterial3D = StandardMaterial3D.new()
	door_material.albedo_color = Color(0.08, 0.09, 0.12)
	door_mesh.material_override = door_material
	door.add_child(door_mesh)
	door.position = Vector3(0, 34 + 3, -197.9)   # AVANT add_child (règle D.0)
	citadel.add_child(door)


## ---------------------------------------------------------------------------
## Habillage V4.2 — profondeur, eau, chemins, prairie
## ---------------------------------------------------------------------------

## Pics et contreforts sur l'anneau : la 4e capture V4.1 montrait quatre murs
## plats gris — un rideau, pas des montagnes. Pics VISUELS au-dessus de la
## crête de l'anneau (inatteignables), rangée lointaine bleuie pour la
## superposition atmosphérique, et contreforts À COLLISION (`unclimbable`) qui
## avancent dans la plaine — aucun décor plat ne masque un vide accessible.
func _dress_border_mountains() -> void:
	var dressing: Node3D = Node3D.new()
	dressing.name = "MountainDressing"
	add_child(dressing)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260802
	var mid: float = (BORDER_INNER + BORDER_OUTER) * 0.5
	# [axe (0 = mur X constant, 1 = mur Z constant), signe]
	var sides: Array[Array] = [[0, -1.0], [0, 1.0], [1, -1.0], [1, 1.0]]
	var peak_index: int = 0
	for side: Array in sides:
		var axis: int = side[0]
		var sign_value: float = side[1]
		# Le mur nord (axe 0, signe −1) porte la citadelle devant lui (sommet
		# y = 80) : ses pics proches de l'axe restent SOUS elle — la silhouette
		# du donjon domine le fond (réf. 01), les montagnes ne l'écrasent pas.
		var behind_citadel: bool = axis == 0 and sign_value < 0.0
		for i: int in range(9):
			var along: float = -240.0 + 60.0 * float(i) + rng.randf_range(-9.0, 9.0)
			var height: float = rng.randf_range(58.0, 96.0)
			if behind_citadel and absf(along) < 100.0:
				height = minf(height, 58.0)
			var warm: bool = rng.randf() < 0.45
			var center: Vector3 = Vector3(along, 38.0 + height * 0.5, mid * sign_value) \
				if axis == 0 else Vector3(mid * sign_value, 38.0 + height * 0.5, along)
			# Tente (PrismMesh, arête le long de Z) : une boîte lisait
			# « gratte-ciel », pas « montagne » (capture V4.2 n° 1).
			_visual_prism("Peak%02d" % peak_index, dressing, center,
				Vector3(rng.randf_range(22.0, 34.0), height,
					rng.randf_range(38.0, 60.0)),
				COL_MOUNTAIN_WARM if warm else COL_MOUNTAIN, axis == 0)
			peak_index += 1
		# Rangée lointaine bleuie : plus haute, au bord extérieur — la
		# superposition qui fait lire « chaîne », pas « mur ».
		for i: int in range(5):
			var along_far: float = -220.0 + 110.0 * float(i) + rng.randf_range(-14.0, 14.0)
			var height_far: float = rng.randf_range(96.0, 122.0)
			if behind_citadel and absf(along_far) < 110.0:
				height_far = minf(height_far, 84.0)
			var center_far: Vector3 = Vector3(along_far, 20.0 + height_far * 0.5,
				(BORDER_OUTER - 3.0) * sign_value) if axis == 0 \
				else Vector3((BORDER_OUTER - 3.0) * sign_value, 20.0 + height_far * 0.5,
					along_far)
			_visual_prism("FarPeak%02d" % peak_index, dressing, center_far,
				Vector3(10.0, height_far, 88.0), COL_MOUNTAIN_FAR, axis == 0)
			peak_index += 1
	# Contreforts : avancées PHYSIQUES du massif dans la plaine (2 par côté).
	var buttresses: Array[Array] = [
		[Vector2(-150, -244), Vector2(44, 14)], [Vector2(130, -243), Vector2(38, 12)],
		[Vector2(-120, 244), Vector2(40, 13)], [Vector2(160, 243), Vector2(46, 14)],
		[Vector2(-244, -120), Vector2(13, 42)], [Vector2(-243, 100), Vector2(12, 38)],
		[Vector2(244, -90), Vector2(14, 44)], [Vector2(243, 140), Vector2(13, 40)],
	]
	for i: int in range(buttresses.size()):
		var foot: Array = buttresses[i]
		_slab("Buttress%02d" % i, foot[0], foot[1], 46.0,
			COL_MOUNTAIN_WARM if i % 2 == 0 else COL_MOUNTAIN)
		var body: StaticBody3D = get_node_or_null(
			NodePath("Buttress%02d" % i)) as StaticBody3D
		if body != null:
			body.add_to_group("unclimbable")


## Ruban d'eau turquoise en S DANS le lit (réf. 01 : « rivière turquoise
## lisible formant une direction en S »). Visuel pur : pas de collision, pas de
## nage — l'eau-gameplay est hors périmètre V4. Surface à −0,55, sous les gués.
func _build_river_water() -> void:
	var water: Node3D = Node3D.new()
	water.name = "RiverWater"
	add_child(water)
	var segment_index: int = 0
	var x: float = -250.0
	while x <= 250.0:
		var meander: float = 10.0 + 3.1 * sin(x * 0.030)
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = "WaterRibbon%02d" % segment_index
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(13.0, 0.3, 7.6)
		mesh.mesh = box
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = COL_WATER
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.roughness = 0.15
		material.metallic = 0.1
		mesh.material_override = material
		mesh.position = Vector3(x, -0.7, meander)
		water.add_child(mesh)
		segment_index += 1
		x += 11.0


## Chemins de terre battue (réf. 01 : « routes guidant naturellement la
## descente »). Bandes VISUELLES posées 4 cm au-dessus des zones planes — les
## rampes gardent leur teinte sombre qui fait déjà office de route.
func _build_paths() -> void:
	var paths: Node3D = Node3D.new()
	paths.name = "Paths"
	add_child(paths)
	# [de (x,z), à (x,z), hauteur du sol]
	var segments: Array[Array] = [
		[Vector2(0, 154), Vector2(17, 147), 24.0],       # crête → rampe A
		[Vector2(33, 112), Vector2(37, 106), 16.0],      # palier 1
		[Vector2(16, 80), Vector2(20, 76), 8.0],         # palier 2
		[Vector2(34, 64), Vector2(41, 52), 6.0],         # terrasse du camp
		[Vector2(40, 29), Vector2(21, 13), 2.0],         # sortie camp → gué ouest
		[Vector2(20, 8), Vector2(2, -28), 2.0],          # gué → ruines
		[Vector2(0, -50), Vector2(-1, -107), 2.0],       # ruines → rampe du donjon
		[Vector2(24, 10), Vector2(60, 10), 2.0],         # gué ouest → route est
		[Vector2(60, 10), Vector2(93, 11), 2.0],         # …devant la forêt
		[Vector2(94, 8), Vector2(66, 3), 2.0],           # gué est → rampe du pylône
	]
	for i: int in range(segments.size()):
		var segment: Array = segments[i]
		var from: Vector2 = segment[0]
		var to: Vector2 = segment[1]
		var ground: float = segment[2]
		var delta: Vector2 = to - from
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = "PathStrip%02d" % i
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(delta.length() + 2.0, 0.08, 2.4)
		mesh.mesh = box
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = COL_PATH
		material.roughness = 0.95
		mesh.material_override = material
		var center: Vector2 = (from + to) * 0.5
		mesh.position = Vector3(center.x, ground + 0.04, center.y)
		mesh.rotation.y = -atan2(delta.y, delta.x)
		paths.add_child(mesh)


## Variation des sols (réf. 01 : « matériaux de sol mieux différenciés ») :
## crête exposée éclaircie, berges humides, taches de prairie — des aplats
## visuels 2 cm au-dessus des dalles, sans collision.
func _build_ground_variation() -> void:
	var variation: Node3D = Node3D.new()
	variation.name = "GroundVariation"
	add_child(variation)
	var patches: Array[Array] = [
		# [nom, centre xz, taille xz, sommet, couleur]
		["CrestLit", Vector2(-8, 172), Vector2(64, 36), 24.02, COL_GRASS_LIT],
		["BankSouth", Vector2(0, 18.6), Vector2(512, 5.0), 2.02, COL_GRASS_WET],
		["BankNorth", Vector2(0, 1.4), Vector2(512, 5.0), 2.02, COL_GRASS_WET],
		["MeadowEast", Vector2(150, 60), Vector2(90, 70), 2.02, COL_GRASS_LIT],
		["MeadowWest", Vector2(-160, -60), Vector2(100, 80), 2.02, COL_GRASS_DARK],
		["ScrubNorth", Vector2(120, -150), Vector2(110, 70), 2.02, COL_GRASS_DARK],
	]
	for patch: Array in patches:
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = String(patch[0])
		var box: BoxMesh = BoxMesh.new()
		var size_xz: Vector2 = patch[2]
		box.size = Vector3(size_xz.x, 0.05, size_xz.y)
		mesh.mesh = box
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = patch[4] as Color
		material.roughness = 0.95
		mesh.material_override = material
		var center_xz: Vector2 = patch[1]
		mesh.position = Vector3(center_xz.x, float(patch[3]), center_xz.y)
		variation.add_child(mesh)


## Prairie de la crête (réf. 01 : herbe et fleurs au premier plan). §7.5 :
## MultiMesh PARTITIONNÉ (deux cellules + fleurs), scatter déterministe,
## exclusion du chemin, vent par `SH_FoliageWind` — aucun recalcul CPU.
func _build_crest_meadow() -> void:
	var meadow: Node3D = Node3D.new()
	meadow.name = "CrestMeadow"
	add_child(meadow)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260803
	var shader: Shader = load("res://shaders/foliage/foliage_wind.gdshader") as Shader
	# Deux cellules de brins (§7.5 : « jamais toute la vallée dans un
	# MultiMesh unique ») : ouest et est de la crête.
	var cells: Array[Array] = [
		[Vector2(-46, 2), "CellWest"], [Vector2(2, 46), "CellEast"],
	]
	var tuft: ArrayMesh = _tuft_mesh()
	var tuft_material: ShaderMaterial = ShaderMaterial.new()
	tuft_material.shader = shader
	tuft_material.set_shader_parameter(&"blade_height", 0.42)
	for cell: Array in cells:
		var bounds: Vector2 = cell[0]
		var blades: MultiMeshInstance3D = MultiMeshInstance3D.new()
		blades.name = String(cell[1])
		blades.material_override = tuft_material
		var multimesh: MultiMesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = tuft
		multimesh.instance_count = 700
		# Seam de test : en headless, le RenderingServer factice ne stocke pas
		# les tampons MultiMesh (get_instance_transform rend l'identité —
		# mesuré). Les origines et teintes écrites dans le tampon sont donc
		# AUSSI consignées en métadonnées, par la même boucle.
		var origins: PackedVector3Array = PackedVector3Array()
		var tints: PackedColorArray = PackedColorArray()
		var placed: int = 0
		# §7.5/§7.17 : « touffes regroupées plutôt qu'uniformes » — grappes de
		# 5 à 9 touffes autour d'un centre, avec de vrais VIDES entre elles
		# (les 700 brins isolés de la capture précédente lisaient « bâtons »).
		while placed < multimesh.instance_count:
			var cluster_center: Vector3 = _meadow_point(rng, bounds)
			var cluster_size: int = rng.randi_range(5, 9)
			for j: int in range(cluster_size):
				if placed >= multimesh.instance_count:
					break
				var position: Vector3 = cluster_center + Vector3(
					rng.randf_range(-0.9, 0.9), 0.0, rng.randf_range(-0.9, 0.9))
				var basis: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)) \
					.scaled(Vector3.ONE * rng.randf_range(0.7, 1.15))
				var tint: Color = COL_GRASS.lerp(COL_GRASS_LIT, rng.randf())
				multimesh.set_instance_transform(placed,
					Transform3D(basis, position))
				multimesh.set_instance_color(placed, tint)
				origins.append(position)
				tints.append(tint)
				placed += 1
		blades.multimesh = multimesh
		blades.set_meta(&"origins", origins)
		blades.set_meta(&"tints", tints)
		meadow.add_child(blades)
	# Fleurs blanches/jaunes/bleues (§7.5), une seule petite cellule.
	var flowers: MultiMeshInstance3D = MultiMeshInstance3D.new()
	flowers.name = "Flowers"
	var flower_multimesh: MultiMesh = MultiMesh.new()
	flower_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	flower_multimesh.use_colors = true
	var petal: BoxMesh = BoxMesh.new()
	petal.size = Vector3(0.11, 0.09, 0.11)
	var petal_material: ShaderMaterial = ShaderMaterial.new()
	petal_material.shader = shader
	petal.material = petal_material
	flower_multimesh.mesh = petal
	flower_multimesh.instance_count = 130
	var petal_colors: Array[Color] = [
		Color(0.95, 0.95, 0.91), Color(0.91, 0.79, 0.30), Color(0.42, 0.56, 0.83),
	]
	for i: int in range(flower_multimesh.instance_count):
		var position: Vector3 = _meadow_point(rng, Vector2(-44, 44))
		flower_multimesh.set_instance_transform(i,
			Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)),
				position + Vector3(0, 0.22, 0)))
		flower_multimesh.set_instance_color(i, petal_colors[i % petal_colors.size()])
	flowers.multimesh = flower_multimesh
	meadow.add_child(flowers)


## Touffe d'herbe : trois quads croisés à 60°, effilés vers le haut, origine au
## SOL. Une touffe, pas un brin — c'est la grappe de quads qui donne la
## silhouette pleine à 5 m sans coûter plus de 6 triangles.
func _tuft_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in range(3):
		var basis: Basis = Basis(Vector3.UP, PI * float(k) / 3.0)
		var a: Vector3 = basis * Vector3(-0.17, 0.0, 0.0)
		var b: Vector3 = basis * Vector3(0.17, 0.0, 0.0)
		var c: Vector3 = basis * Vector3(0.05, 0.42, 0.0)
		var d: Vector3 = basis * Vector3(-0.05, 0.42, 0.0)
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(d)
	st.generate_normals()
	return st.commit()


## Point de prairie sur la crête (sommet y = 24), HORS du couloir du chemin
## crête → rampe A (exclusion de gameplay §7.5 : le chemin reste lisible).
func _meadow_point(rng: RandomNumberGenerator, x_bounds: Vector2) -> Vector3:
	for attempt: int in range(12):
		var x: float = rng.randf_range(x_bounds.x, x_bounds.y)
		# Bande AVANT de la crête (z 144-170) : le cadre §3.2 montre z ≤ 160 —
		# une prairie étalée jusqu'à 203 vivait derrière la caméra (capture
		# V4.2 n° 1 : un seul brin visible).
		var z: float = rng.randf_range(144.5, 170.0)
		var to_path: float = _distance_to_segment(Vector2(x, z),
			Vector2(0, 154), Vector2(17, 147))
		if to_path > 2.6:
			return Vector3(x, 24.0, z)
	return Vector3(x_bounds.x, 24.0, 168.0)


func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((point - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return point.distance_to(a + ab * t)


## Boîte purement visuelle (décor hors de portée).
func _visual_box(box_name: String, parent: Node3D, center: Vector3, size: Vector3,
		color: Color) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = box_name
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color, false)
	mesh.position = center
	parent.add_child(mesh)


## Tente purement visuelle (pics). L'arête du PrismMesh court le long de Z
## (vérifié dans la source 4.7.1) : `ridge_along_x` pivote de 90° pour les
## murs nord/sud, longs en X.
func _visual_prism(prism_name: String, parent: Node3D, center: Vector3,
		size: Vector3, color: Color, ridge_along_x: bool) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = prism_name
	var prism: PrismMesh = PrismMesh.new()
	prism.size = size
	mesh.mesh = prism
	mesh.material_override = _material(color, false)
	mesh.position = center
	if ridge_along_x:
		mesh.rotation.y = PI * 0.5
	parent.add_child(mesh)


## ---------------------------------------------------------------------------
## Briques de construction
## ---------------------------------------------------------------------------

## Dalle pleine : sommet à `top`, fond commun à BASE_Y.
func _slab(slab_name: String, center_xz: Vector2, size_xz: Vector2, top: float,
		color: Color) -> void:
	var height: float = top - BASE_Y
	_box_in(slab_name, self,
		Vector3(center_xz.x, BASE_Y + height * 0.5, center_xz.y),
		Vector3(size_xz.x, height, size_xz.y), color, true)


## Boîte avec collision optionnelle et émission optionnelle.
func _box_in(box_name: String, parent: Node3D, center: Vector3, size: Vector3,
		color: Color, with_collision: bool, emissive: bool = false) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = box_name + "Mesh"
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color, emissive)
	if with_collision:
		var body: StaticBody3D = StaticBody3D.new()
		body.name = box_name
		body.collision_layer = 1
		body.collision_mask = 0
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box_shape: BoxShape3D = BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		body.add_child(mesh)
		# Position AVANT add_child — règle D.0 : un corps ajouté à l'origine puis
		# déplacé y passe un tick physique. Mesuré ici même : les montagnes
		# périmétrales à l'origine enveloppaient le spawn et catapultaient le
		# joueur de 4,6 m au premier tick (sonde BorderWest).
		body.position = center
		parent.add_child(body)
	else:
		mesh.name = box_name
		mesh.position = center
		parent.add_child(mesh)


## Rampe : prisme convexe PLEIN entre deux extrémités de surface (centres des
## arêtes haute et basse). Huit sommets, aucun dessous en surplomb (leçon B.1).
func _ramp(ramp_name: String, from: Vector3, to: Vector3, width: float,
		color: Color) -> void:
	var along: Vector3 = to - from
	var flat: Vector3 = Vector3(along.x, 0.0, along.z)
	if flat.length_squared() < 0.0001:
		push_error("[terrain] rampe dégénérée : %s" % ramp_name)
		return
	var side: Vector3 = flat.normalized().cross(Vector3.UP) * (width * 0.5)
	var points: PackedVector3Array = PackedVector3Array([
		from + side, from - side,                                # arête haute, sommet
		to + side, to - side,                                    # arête basse, sommet
		Vector3(from.x + side.x, BASE_Y, from.z + side.z),        # fonds
		Vector3(from.x - side.x, BASE_Y, from.z - side.z),
		Vector3(to.x + side.x, BASE_Y, to.z + side.z),
		Vector3(to.x - side.x, BASE_Y, to.z - side.z),
	])
	var body: StaticBody3D = StaticBody3D.new()
	body.name = ramp_name
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var hull: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	hull.points = points
	shape.shape = hull
	body.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = ramp_name + "Mesh"
	mesh.mesh = _hull_mesh(points)
	mesh.material_override = _material(color, false)
	body.add_child(mesh)
	add_child(body)


## Maillage du prisme : les six faces du coin, en quads triangulés.
func _hull_mesh(p: PackedVector3Array) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var quads: Array[Array] = [
		[0, 1, 3, 2],   # dessus (la pente)
		[4, 6, 7, 5],   # dessous
		[0, 2, 6, 4],   # flanc +side
		[1, 5, 7, 3],   # flanc -side
		[0, 4, 5, 1],   # face haute
		[2, 3, 7, 6],   # face basse
	]
	for quad: Array in quads:
		st.add_vertex(p[quad[0]]); st.add_vertex(p[quad[1]]); st.add_vertex(p[quad[2]])
		st.add_vertex(p[quad[0]]); st.add_vertex(p[quad[2]]); st.add_vertex(p[quad[3]])
	st.generate_normals()
	return st.commit()


func _cylinder(cyl_name: String, base: Vector3, radius: float, height: float,
		color: Color, with_collision: bool) -> void:
	_cylinder_in(cyl_name, self, base, radius, height, color, with_collision)


## Cylindre posé sur `base` (pied au sol, §7.15 : bas de l'objet au sol).
func _cylinder_in(cyl_name: String, parent: Node3D, base: Vector3, radius: float,
		height: float, color: Color, with_collision: bool) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = cyl_name + "Mesh"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	mesh.mesh = cyl
	mesh.material_override = _material(color, false)
	var center: Vector3 = base + Vector3(0, height * 0.5, 0)
	if with_collision:
		var body: StaticBody3D = StaticBody3D.new()
		body.name = cyl_name
		body.collision_layer = 1
		body.collision_mask = 0
		var shape: CollisionShape3D = CollisionShape3D.new()
		var cyl_shape: CylinderShape3D = CylinderShape3D.new()
		cyl_shape.radius = radius
		cyl_shape.height = height
		shape.shape = cyl_shape
		body.add_child(shape)
		body.add_child(mesh)
		body.position = center   # AVANT add_child (règle D.0)
		parent.add_child(body)
	else:
		mesh.name = cyl_name
		mesh.position = center
		parent.add_child(mesh)


func _orb(orb_name: String, center: Vector3, radius: float, color: Color) -> void:
	_orb_in(orb_name, self, center, radius, color)


## Sphère visuelle sans collision (têtes de pylône, couronnes d'arbres).
func _orb_in(orb_name: String, parent: Node3D, center: Vector3, radius: float,
		color: Color) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = orb_name
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh.mesh = sphere
	var emissive: bool = color == COL_CYAN
	mesh.material_override = _material(color, emissive)
	mesh.position = center
	parent.add_child(mesh)


func _material(color: Color, emissive: bool) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if emissive:
		# Cœur blanc, halo cyan (§7.9) — version proxy : émission simple.
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0
	return mat
