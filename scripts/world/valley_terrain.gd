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
## Pierre de la citadelle : ASSOMBRIE et légèrement chaude. Mesure sur la
## capture de référence : la bande d'horizon tenait entre 55 % et 80 % de
## valeur, monument compris — le but du jeu ne se détachait de rien. Un sujet
## se lit par sa valeur avant sa forme.
const COL_STONE: Color = Color(0.255, 0.238, 0.243)
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
	_build_secondary_structures()
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
## Bordure : plus CLAIRE et plus FROIDE que la citadelle (0,45 / 0,44 / 0,47).
## La capture de la vue d'ouverture montrait les deux à la même valeur : le
## monument se fondait dans la montagne, exactement le « focales fusionnées »
## que §30.2 compte comme un échec. La perspective aérienne se peint dans la
## couleur — monter la densité du brouillard dissolvait le plan moyen.
const COL_MOUNTAIN: Color = Color(0.545, 0.575, 0.635)


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
	_build_border_crests()
	_build_far_skyline()


## CRÊTES sur la bordure, et MASSIFS LOINTAINS derrière.
##
## La capture de la vue d'ouverture a tranché : la bordure formait un MUR gris
## uniforme d'un bord à l'autre du cadre, à hauteur constante, à 440 m. Aucun
## étagement, donc aucune profondeur — §1.3 demande trois plans, et §9.4 des
## montagnes « éclaircies, refroidies et simplifiées » entre 550 et 1 200 m.
##
## Deux gestes, pas un shader :
##
##  1. la ligne de crête se BRISE — des sommets de hauteurs et de largeurs
##     irrégulières posés sur la bordure ;
##  2. un ARRIÈRE-PLAN s'ajoute au-delà, en deux rangs de plus en plus clairs
##     et bleutés. La perspective aérienne est ainsi PEINTE dans la couleur
##     plutôt que confiée au brouillard : monter la densité du fog avait dissous
##     le plan moyen à 150 m, l'inverse de ce qu'on cherche.
##
## Sans collision : ces masses sont hors du monde jouable, derrière une
## bordure qui, elle, porte la sienne. Rien d'accessible ne devient traversable.
func _build_border_crests() -> void:
	var crests: Node3D = Node3D.new()
	crests.name = "BorderCrests"
	add_child(crests)
	var mid: float = (BORDER_INNER + BORDER_OUTER) * 0.5
	# Déterministe : une capture de référence doit être rejouable (§21.8).
	var seed_value: int = 0
	for axis: int in range(4):
		for i: int in range(11):
			seed_value += 1
			var t: float = float(i) / 10.0
			var along: float = lerpf(-BORDER_OUTER, BORDER_OUTER, t)
			# Hauteurs irrégulières : deux sinus de périodes premières entre
			# elles évitent la répétition visible à laquelle un seul mènerait.
			var height: float = 18.0 + 14.0 * sin(t * 7.3 + float(axis)) \
				+ 9.0 * sin(t * 17.1 + float(axis) * 2.1)
			var width: float = 34.0 + 16.0 * sin(t * 5.7 + float(axis) * 1.3)
			var depth: float = BORDER_OUTER - BORDER_INNER
			var centre: Vector3
			match axis:
				0: centre = Vector3(along, BORDER_TOP + height * 0.5, -mid)
				1: centre = Vector3(along, BORDER_TOP + height * 0.5, mid)
				2: centre = Vector3(-mid, BORDER_TOP + height * 0.5, along)
				_: centre = Vector3(mid, BORDER_TOP + height * 0.5, along)
			var size: Vector3 = Vector3(width, height, depth * 0.8) if axis < 2 \
				else Vector3(depth * 0.8, height, width)
			_visual_box("Crest%d_%d" % [axis, i], crests, centre, size,
				COL_MOUNTAIN_WARM if i % 3 == 0 else COL_MOUNTAIN)


func _build_far_skyline() -> void:
	var far: Node3D = Node3D.new()
	far.name = "FarSkyline"
	add_child(far)
	# Deux rangs : 560 m et 860 m. Le second est plus clair et plus froid —
	# c'est ainsi que l'œil lit la distance, bien avant la taille apparente.
	var rows: Array[Array] = [
		[560.0, 9, 120.0, 60.0, COL_MOUNTAIN_FAR],
		[860.0, 7, 175.0, 95.0, Color(0.63, 0.68, 0.76)],
	]
	for row_index: int in range(rows.size()):
		var row: Array = rows[row_index]
		var distance: float = row[0]
		var count: int = int(row[1])
		var spread: float = float(row[2])
		var tall: float = float(row[3])
		var tint: Color = row[4]
		for axis: int in range(4):
			for i: int in range(count):
				var t: float = (float(i) + 0.5) / float(count)
				var along: float = lerpf(-distance * 1.15, distance * 1.15, t)
				var height: float = tall * (0.55 + 0.45
					* absf(sin(t * 9.1 + float(axis) * 1.7 + float(row_index))))
				var width: float = spread * (0.7 + 0.5
					* absf(sin(t * 4.3 + float(axis))))
				var centre: Vector3
				match axis:
					0: centre = Vector3(along, height * 0.5 - 8.0, -distance)
					1: centre = Vector3(along, height * 0.5 - 8.0, distance)
					2: centre = Vector3(-distance, height * 0.5 - 8.0, along)
					_: centre = Vector3(distance, height * 0.5 - 8.0, along)
				var size: Vector3 = Vector3(width, height, spread * 0.6) \
					if axis < 2 else Vector3(spread * 0.6, height, width)
				_visual_box("Far%d_%d_%d" % [row_index, axis, i], far,
					centre, size, tint)

func _build_plains_and_river() -> void:
	# Plaine sud (côté spawn/camp) et plaine nord (côté donjon/pylône), séparées
	# par le lit de rivière en bande autour de Z = 10 (§3.3 : « rivière en S
	# autour de Z = 10 » — le S visuel viendra avec l'eau ; le LIT est la bande).
	_slab("PlainSouth", Vector2(0, 136), Vector2(512, 240), 2.0, COL_GRASS)
	_slab("PlainNorth", Vector2(0, -126), Vector2(512, 260), 2.0, COL_GRASS)
	_slab("Riverbed", Vector2(0, 10), Vector2(512, 12), -1.5, COL_RIVERBED)
	# BERGES EN PENTE, sur toute la longueur du lit.
	#
	# Sans elles, le lit est une tranchée de 3,5 m à parois VERTICALES qui
	# traverse les 512 m de la vallée, avec deux gués pour seules sorties. Un
	# playtest en boîte noire s'y est retrouvé prisonnier, à se débattre dans
	# une pose disloquée : il a cru à un bug d'animation, c'était une géométrie
	# dont on ne peut pas sortir. Une marche de 3,5 m n'est ni franchissable
	# (`step_height` 0,30-0,38 m) ni escaladable (le lit n'est pas `climbable`).
	#
	# 3,5 m de dénivelé sur 4 m d'emprise = 41°, sous la limite de pente de 46°
	# (§8.2) : la berge se remonte à pied, partout, sans détour par un gué.
	_ramp("RiverBankSouth", Vector3(0, 2.0, 16), Vector3(0, -1.5, 12), 512.0,
		COL_RIVERBED)
	_ramp("RiverBankNorth", Vector3(0, 2.0, 4), Vector3(0, -1.5, 8), 512.0,
		COL_RIVERBED)
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
	# DUPLIQUER avant de personnaliser : le matériau vient du cache partagé
	# (lot 15) — le muter en place teinterait tous les volumes de même clé.
	var coal_material: StandardMaterial3D = \
		coals.material_override.duplicate() as StandardMaterial3D
	coal_material.emission_enabled = true
	coal_material.emission = Color(0.98, 0.45, 0.12)
	coal_material.emission_energy_multiplier = 2.4
	coals.material_override = coal_material
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
	_dress_camp_life(camp)
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


## V4 lot 5 — le camp HABITÉ (§11.D) : cuisine autour du feu, réserve,
## coin de travail, râtelier d'armes, charrette, clôture partielle, abri
## assemblé. Décor PUR autour des entités gameplay existantes (feu, coffre,
## viande) — jamais un doublon d'entité, jamais leur collision.
func _dress_camp_life(camp: Node3D) -> void:
	var life: Node3D = Node3D.new()
	life.name = "CampLife"
	camp.add_child(life)
	var placements: Array[Array] = [
		# Cuisine : chaudron SUR le foyer, table dressée, banc, seau.
		[&"Cauldron", Vector3(45, 6.18, 64), 0.0, 1.0],
		[&"Table_Large", Vector3(47.8, 6, 60.3), 0.45, 1.0,
			Vector3(1.9, 0.9, 1.0), false],
		[&"Bench", Vector3(47.2, 6, 59.0), 0.45, 1.0],
		[&"Stool", Vector3(49.4, 6, 61.3), 1.2, 1.0],
		[&"Pot_1", Vector3(47.5, 6.78, 60.2), 0.8, 1.0],
		[&"Mug", Vector3(48.1, 6.78, 60.6), 2.1, 1.0],
		[&"Bottle_1", Vector3(47.9, 6.78, 59.9), 0.0, 1.0],
		[&"Carrot", Vector3(47.2, 6.78, 60.5), 1.5, 1.0],
		[&"Bucket_Wooden_1", Vector3(46.6, 6, 61.2), 2.8, 1.0],
		# Réserve : tonneau de pommes, cageots, sacs à l'entrée de tente.
		[&"Barrel_Apples", Vector3(50.4, 6, 58.4), 0.6, 1.0],
		[&"FarmCrate_Apple", Vector3(52.9, 6, 58.1), 1.9, 1.0],
		[&"FarmCrate_Empty", Vector3(52.2, 6, 57.0), 0.3, 1.0],
		[&"Bag", Vector3(53.4, 6, 56.2), 2.4, 1.0],
		[&"Pouch_Large", Vector3(54.3, 6, 56.8), 4.0, 1.0],
		# Coin de travail : enclume, billot avec hache, pierre à affûter.
		[&"Anvil", Vector3(41.0, 6, 58.0), 1.1, 1.0,
			Vector3(0.9, 0.8, 0.6), false],
		[&"Anvil_Log", Vector3(40.0, 6, 59.3), 0.2, 1.0],
		[&"Axe_Bronze", Vector3(40.0, 6.55, 59.3), 2.6, 1.0],
		[&"Whetstone", Vector3(41.9, 6, 57.1), 3.3, 1.0],
		[&"Rope_1", Vector3(42.6, 6, 58.8), 0.9, 1.0],
		# Râtelier d'armes près des tentes nord, bouclier appuyé.
		[&"WeaponStand", Vector3(43.5, 6, 70.2), 2.1, 1.0,
			Vector3(1.4, 1.6, 0.5), false],
		[&"Sword_Bronze", Vector3(43.5, 6.62, 70.1), 2.1, 1.0],
		[&"Shield_Wooden", Vector3(42.6, 6.25, 70.9), 2.6, 1.0],
		# Charrette à l'entrée sud du camp, bannière de faction.
		[&"Stall_Cart_Empty", Vector3(40.0, 6, 50.5), 1.35, 1.0,
			Vector3(2.4, 1.4, 1.6), false],
		[&"Banner_2", Vector3(41.2, 6, 48.3), 0.1, 1.2],
		# Clôture PARTIELLE au nord (indice de limite, pas une cage).
		[&"Prop_WoodenFence_Single", Vector3(38.5, 6, 79.0), 0.15, 1.1],
		[&"Prop_WoodenFence_Extension1", Vector3(42.6, 6, 79.4), 0.15, 1.1],
		[&"Prop_WoodenFence_Single", Vector3(47.0, 6, 79.6), 0.4, 1.1],
		# Abri ASSEMBLÉ (§11.D « abris assemblés ») : panneau de toit incliné
		# sur la caisse, couche en dessous — un pillard dort là.
		[&"Roof_Wooden_2x1", Vector3(30.0, 7.4, 72.5), 0.0, 1.6],
		[&"Bed_Twin1", Vector3(30.0, 6, 73.2), 3.14, 1.0],
		[&"CandleStick", Vector3(31.3, 6, 71.8), 0.7, 1.0],
	]
	for entry: Array in placements:
		var collision: Vector3 = entry[4] if entry.size() > 4 else Vector3.ZERO
		_place_model(life, entry[0] as StringName, entry[1] as Vector3,
			float(entry[2]), float(entry[3]), collision, false)
	# Le panneau de toit de l'abri s'incline APRÈS le placement.
	var roof: Node3D = life.get_node_or_null("Roof_Wooden_2x1_27") as Node3D
	if roof == null:
		for child: Node in life.get_children():
			if String(child.name).begins_with("Roof_Wooden"):
				roof = child as Node3D
	if roof != null:
		roof.rotation.z = 0.42   # appui caisse → sol


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
	# Même règle que les braises : dupliquer avant de personnaliser (lot 15).
	var rune_material: StandardMaterial3D = \
		runes.material_override.duplicate() as StandardMaterial3D
	rune_material.emission_enabled = true
	rune_material.emission = COL_CYAN
	rune_material.emission_energy_multiplier = 1.6
	runes.material_override = rune_material
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
	# ART-Q4 : arbres de PRODUCTION (registre) sur les MÊMES collisions de
	# tronc — le navmesh et la preuve de navigation ne bougent pas d'un
	# polygone. Variation lacet/échelle par index (§7.3 : « une simple
	# rotation de 90° ne suffit pas »), grands et moyens alternés en motif
	# irrégulier. Repli : le graybox cylindre+couronne d'avant.
	var canopy_tones: Array[Color] = [
		COL_GRASS_DARK, Color(0.26, 0.42, 0.23), Color(0.34, 0.50, 0.20),
	]
	for i: int in range(trunks.size()):
		var at: Vector2 = trunks[i]
		var tree_id: StringName = &"env.tree.large" if (i % 3 == 0) \
			else &"env.tree.medium"
		var packed: PackedScene = AssetRegistry.resolve(tree_id)
		if packed != null:
			_cylinder_in("Trunk%02d" % i, forest, Vector3(at.x, 2.0, at.y),
				0.5, 7.0, COL_WOOD, true)
			(forest.get_node("Trunk%02d/Trunk%02dMesh" % [i, i])
				as MeshInstance3D).visible = false   # collision gardée, visuel = arbre
			var tree: Node3D = packed.instantiate() as Node3D
			tree.name = "Tree%02d" % i
			tree.position = Vector3(at.x, 2.0, at.y)
			tree.rotation.y = float(i) * 2.399   # angle d'or : jamais aligné
			tree.scale = Vector3.ONE * (0.9 + 0.011 * float((i * 7) % 25))
			forest.add_child(tree)
		else:
			_cylinder_in("Trunk%02d" % i, forest, Vector3(at.x, 2.0, at.y),
				0.5, 7.0, COL_WOOD, true)
			_orb_in("Canopy%02d" % i, forest, Vector3(at.x, 9.5, at.y), 2.6,
				canopy_tones[i % canopy_tones.size()])
	_build_nature_phrases()
	_dress_zone_crest()
	_dress_zone_descent()
	_dress_zone_prairie()
	_dress_zone_forest()
	_dress_zone_river()
	_dress_zone_cliff()
	_dress_zone_pylon()
	_dress_zone_citadel_approach()


## ---------------------------------------------------------------------------
## V4 lot 4 — habillage par zones (§10-§11) : compositions DÉLIBÉRÉES sur la
## topologie existante, via les modèles promus (AssetRegistry.model). Un
## modèle absent laisse un vide — jamais une boîte. Les cotes fonctionnelles
## (rampes, paliers, chemins, couloir de la vista x −12..12) ne bougent pas.
## ---------------------------------------------------------------------------

## Pose un modèle promu. `collision` : ZERO = décor pur ; sinon boîte
## (x,y,z) ou tronc cylindrique si `trunk` (x = rayon, y = hauteur).
func _place_model(parent: Node3D, model_name: StringName, at: Vector3,
		yaw: float, scale_factor: float = 1.0,
		collision: Vector3 = Vector3.ZERO, trunk: bool = false) -> void:
	var packed: PackedScene = AssetRegistry.model(model_name)
	if packed == null:
		return   # pas promu : le vide reste un vide
	var prop: Node3D = packed.instantiate() as Node3D
	prop.name = "%s_%d" % [String(model_name), parent.get_child_count()]
	prop.position = at
	prop.rotation.y = yaw
	# §3 : le kit végétal est importé sans normalisation d'échelle ; `KitScale`
	# corrige en un point. Le facteur du site reste une VARIATION et se
	# multiplie. Ce chemin-ci passe par `AssetRegistry`, pas par les KIT_DIRS —
	# il avait été oublié au premier lot, et le test de la vallée montée l'a
	# rattrapé en signalant une fleur à 2,98 m.
	prop.scale = Vector3.ONE * scale_factor * KitScale.factor(String(model_name))
	parent.add_child(prop)
	if collision == Vector3.ZERO:
		return
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	if trunk:
		var cylinder: CylinderShape3D = CylinderShape3D.new()
		cylinder.radius = collision.x
		cylinder.height = collision.y
		shape.shape = cylinder
		shape.position = Vector3(0, collision.y * 0.5, 0)
	else:
		var box: BoxShape3D = BoxShape3D.new()
		box.size = collision
		shape.shape = box
		shape.position = Vector3(0, collision.y * 0.5, 0)
	body.add_child(shape)
	prop.add_child(body)


func _dress_zone(zone_name: String, placements: Array[Array]) -> Node3D:
	var zone: Node3D = Node3D.new()
	zone.name = zone_name
	add_child(zone)
	for entry: Array in placements:
		var collision: Vector3 = entry[4] if entry.size() > 4 else Vector3.ZERO
		var trunk: bool = bool(entry[5]) if entry.size() > 5 else false
		_place_model(zone, entry[0] as StringName, entry[1] as Vector3,
			float(entry[2]), float(entry[3]), collision, trunk)
	return zone


## ---------------------------------------------------------------------------
## V4 lot 12 — structures secondaires PÉNÉTRABLES : aucun bâtiment visible
## important ne reste une boîte fermée. Quatre abris de 4×6 m sur le kit
## modulaire 2 m (murs 2,0×3,12×0,4 mesurés au catalogue) ; chaque intérieur
## a une raison d'être, une récompense (ingrédient posé par ValleyWorld, ou
## le récit), une lumière MOTIVÉE (§7.8) et une sortie sûre — l'ouverture de
## porte n'est JAMAIS barrée par une collision pleine (deux flancs + linteau).
## ---------------------------------------------------------------------------

## Un mur modulaire AVEC sa collision. `doorway` : l'arche (~1,2 × 2,3 m)
## reste franche — flancs à |x| ≥ 0,6 et linteau au-dessus de 2,35 m.
func _structure_wall(shelter: Node3D, model_name: StringName, at: Vector3,
		yaw: float, doorway: bool = false) -> void:
	var packed: PackedScene = AssetRegistry.model(model_name)
	if packed == null:
		return   # pas promu : le vide reste un vide
	var wall: Node3D = packed.instantiate() as Node3D
	wall.name = "%s_%d" % [String(model_name), shelter.get_child_count()]
	wall.position = at
	wall.rotation.y = yaw
	shelter.add_child(wall)
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	if doorway:
		for side: float in [-0.8, 0.8]:
			var flank: CollisionShape3D = CollisionShape3D.new()
			var flank_box: BoxShape3D = BoxShape3D.new()
			flank_box.size = Vector3(0.4, 3.12, 0.4)
			flank.shape = flank_box
			flank.position = Vector3(side, 1.56, -0.11)
			body.add_child(flank)
		var lintel: CollisionShape3D = CollisionShape3D.new()
		var lintel_box: BoxShape3D = BoxShape3D.new()
		lintel_box.size = Vector3(2.0, 0.76, 0.4)
		lintel.shape = lintel_box
		lintel.position = Vector3(0, 2.74, -0.11)
		body.add_child(lintel)
	else:
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(2.0, 3.12, 0.4)
		shape.shape = box
		shape.position = Vector3(0, 1.56, -0.11)
		body.add_child(shape)
	wall.add_child(body)


## Coquille d'abri 4×6 m : six dalles, dix murs (porte au sud local, en x=+1),
## quatre pierres d'angle, toit 4×6, lanterne murale et omni chaude. Les faces
## épaisses des murs pointent vers l'extérieur ; le toit se pose au sommet des
## murs (3,05 m, pivot base mesuré au catalogue).
func _build_shelter(holder: Node3D, shelter_name: String, origin: Vector3,
		yaw: float, wall: StringName, door_wall: StringName,
		window_wall: StringName, floor_tile: StringName) -> Node3D:
	var shelter: Node3D = Node3D.new()
	shelter.name = shelter_name
	shelter.position = origin
	shelter.rotation.y = yaw
	holder.add_child(shelter)
	for tile_x: float in [-1.0, 1.0]:
		for tile_z: float in [-2.0, 0.0, 2.0]:
			_place_model(shelter, floor_tile, Vector3(tile_x, 0.03, tile_z),
				0.0, 1.0)
	_structure_wall(shelter, window_wall, Vector3(-1, 0, -3), 0.0)
	_structure_wall(shelter, wall, Vector3(1, 0, -3), 0.0)
	_structure_wall(shelter, wall, Vector3(-1, 0, 3), PI)
	_structure_wall(shelter, door_wall, Vector3(1, 0, 3), PI, true)
	for wall_z: float in [-2.0, 0.0, 2.0]:
		_structure_wall(shelter, wall, Vector3(2, 0, wall_z), -PI * 0.5)
		_structure_wall(shelter, wall, Vector3(-2, 0, wall_z), PI * 0.5)
	for corner: Array in [[-2.0, -3.0, 0.0], [2.0, -3.0, PI * 0.5],
			[2.0, 3.0, PI], [-2.0, 3.0, -PI * 0.5]]:
		_place_model(shelter, &"Corner_Exterior_Brick",
			Vector3(float(corner[0]), 0, float(corner[1])), float(corner[2]), 1.0)
	_place_model(shelter, &"Roof_RoundTiles_4x6", Vector3(0, 3.05, 0), 0.0, 1.0)
	_place_model(shelter, &"Lantern_Wall", Vector3(0, 2.1, -2.8), 0.0, 1.0)
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "ShelterLight"
	light.light_color = Color(1.0, 0.72, 0.38)
	light.light_energy = 0.9
	light.omni_range = 5.0
	light.position = Vector3(0, 2.3, -2.0)
	shelter.add_child(light)
	return shelter


func _build_secondary_structures() -> void:
	var holder: Node3D = Node3D.new()
	holder.name = "SecondaryStructures"
	add_child(holder)
	# Avant-poste de la route nord : le guet des ruines centrales. Porte à
	# l'OUEST, face à la route du donjon. Récompense : viande (ValleyWorld,
	# valley.ingredient.outpost_meat.01) ; récit : les ordres sur la table.
	var outpost: Node3D = _build_shelter(holder, "OutpostNorthRoad",
		Vector3(22, 2, -52), -PI * 0.5, &"Wall_UnevenBrick_Straight",
		&"Wall_UnevenBrick_Door_Round", &"Wall_UnevenBrick_Window_Thin_Round",
		&"Floor_UnevenBrick")
	_place_model(outpost, &"Table_Large", Vector3(-0.8, 0.05, -1.8), 0.2, 1.0,
		Vector3(1.9, 0.9, 1.0))
	_place_model(outpost, &"Scroll_1", Vector3(-0.9, 0.83, -1.7), 1.2, 1.0)
	_place_model(outpost, &"Stool", Vector3(-0.9, 0.05, -0.6), 2.4, 1.0)
	_place_model(outpost, &"WeaponStand", Vector3(1.5, 0.05, -1.0), -PI * 0.5,
		1.0, Vector3(0.6, 1.6, 0.9))
	_place_model(outpost, &"Axe_Bronze", Vector3(1.45, 0.6, -1.0), 1.9, 1.0)
	_place_model(outpost, &"Barrel_Apples", Vector3(-1.4, 0.05, 1.9), 0.9, 1.0,
		Vector3(0.8, 0.9, 0.8))
	_place_model(outpost, &"Banner_2", Vector3(-0.9, 2.5, 3.32), 0.0, 1.1)
	# Abri de rivière : la cabane du pêcheur du coude ouest. Porte au NORD,
	# face à l'eau. Récompense : fruit de soin (valley.ingredient
	# .shelter_fruit.01) ; récit : le lit, l'étagère, la corde.
	var shelter: Node3D = _build_shelter(holder, "RiverShelter",
		Vector3(-30, 2, 22), PI, &"Wall_Plaster_Straight",
		&"Wall_Plaster_Door_Round", &"Wall_Plaster_Window_Wide_Round",
		&"Floor_WoodDark")
	_place_model(shelter, &"Bed_Twin1", Vector3(-1.2, 0.05, -1.9), PI * 0.5,
		1.0, Vector3(1.0, 0.6, 2.0))
	_place_model(shelter, &"Shelf_Simple", Vector3(0.9, 0.05, -2.75), 0.0, 1.0)
	_place_model(shelter, &"Bottle_1", Vector3(0.85, 1.0, -2.72), 0.7, 1.0)
	_place_model(shelter, &"Bucket_Wooden_1", Vector3(1.5, 0.05, 0.6), 2.1, 1.0)
	_place_model(shelter, &"Rope_1", Vector3(1.3, 0.05, 1.6), 0.4, 1.0)
	_place_model(shelter, &"Chair_1", Vector3(0.2, 0.05, -1.2), 2.6, 1.0)
	_place_model(shelter, &"FarmCrate_Empty", Vector3(-1.2, 0, 3.6), 0.5, 1.0)
	# Sanctuaire de la falaise : l'autel au sommet de l'ascension (§9.3) —
	# l'épice rare EXISTANTE (valley.ingredient.cliff_spice.01, au centre)
	# devient l'offrande devant l'autel. Porte à l'EST, face à l'arrivée.
	var sanctuary: Node3D = _build_shelter(holder, "CliffSanctuary",
		Vector3(-108, 14, 62), PI * 0.5, &"Wall_Plaster_Straight",
		&"Wall_Plaster_Door_Round", &"Wall_Plaster_Window_Wide_Round",
		&"Floor_Brick")
	_place_model(sanctuary, &"Bench", Vector3(0, 0.05, -2.2), 0.0, 1.0,
		Vector3(1.6, 0.5, 0.6))
	_place_model(sanctuary, &"CandleStick", Vector3(-0.7, 0.05, -2.0), 0.3, 1.0)
	_place_model(sanctuary, &"CandleStick", Vector3(0.7, 0.05, -2.0), 3.9, 1.0)
	_place_model(sanctuary, &"Book_Stack_1", Vector3(0.25, 0.05, -1.55), 1.1, 1.0)
	_place_model(sanctuary, &"Pot_1", Vector3(-1.5, 0.05, 1.2), 0.8, 1.0)
	_place_model(sanctuary, &"Prop_Vine1", Vector3(0.5, 1.6, -3.2), 0.0, 1.1)
	_place_model(sanctuary, &"Banner_1", Vector3(-0.9, 2.5, 3.32), 0.0, 1.0)
	# Poste de garde de la citadelle : le dernier seuil avant la rampe. Porte
	# à l'OUEST, face à la route. Récompense : baie d'orage (valley.ingredient
	# .guardpost_berry.01 — §13.5 : enseigner la résistance AVANT le donjon).
	var guard_post: Node3D = _build_shelter(holder, "CitadelGuardPost",
		Vector3(13, 2, -102), -PI * 0.5, &"Wall_UnevenBrick_Straight",
		&"Wall_UnevenBrick_Door_Round", &"Wall_UnevenBrick_Window_Thin_Round",
		&"Floor_UnevenBrick")
	_place_model(guard_post, &"WeaponStand", Vector3(-1.4, 0.05, -2.2), 0.4,
		1.0, Vector3(0.6, 1.6, 0.9))
	_place_model(guard_post, &"Shield_Wooden", Vector3(-1.6, 0.05, -1.3), 1.1, 1.0)
	_place_model(guard_post, &"Bench", Vector3(1.4, 0.05, -1.0), -PI * 0.5,
		1.0, Vector3(0.6, 0.5, 1.6))
	_place_model(guard_post, &"Chain_Coil", Vector3(-1.5, 0.05, 1.6), 2.2, 1.0)
	_place_model(guard_post, &"Pouch_Large", Vector3(0.9, 0.05, -2.5), 0.9, 1.0)
	_place_model(guard_post, &"Torch_Metal", Vector3(-0.3, 0, 3.5), 0.0, 1.0)
	_place_model(guard_post, &"Banner_2", Vector3(-0.9, 2.5, 3.32), 0.0, 1.1)


## Zone E — forêt (§11.E) : lisière lisible à l'ouest, intérieur densifié
## avec DEUX clairières préservées, sous-bois aux pieds des troncs, morts-
## bois au nord, et une ruine-curiosité (arche + briques) comme repère.
## Le couloir diagonal (60,50)→(90,28) reste praticable.
func _dress_zone_forest() -> void:
	const TRUNK: Vector3 = Vector3(0.45, 6.0, 0.0)
	_dress_zone("DressZoneForest", [
		# Densification intérieure — jamais dans le couloir diagonal.
		[&"CommonTree_2", Vector3(61, 2, 37), 0.7, 1.05, TRUNK, true],
		[&"CommonTree_5", Vector3(68, 2, 47), 2.1, 0.95, TRUNK, true],
		[&"CommonTree_3", Vector3(77, 2, 31), 3.9, 1.1, TRUNK, true],
		[&"DeadTree_1", Vector3(86, 2, 36), 1.3, 1.0, TRUNK, true],
		[&"DeadTree_2", Vector3(57, 2, 50), 4.7, 0.9, TRUNK, true],
		[&"Pine_3", Vector3(95, 2, 45), 0.4, 1.05, TRUNK, true],
		# Lisière ouest : buissons en phrase, jeunes plants.
		[&"Bush_Common", Vector3(55.5, 2, 26), 0.9, 1.1],
		[&"Bush_Common", Vector3(54.8, 2, 34), 2.6, 0.9],
		[&"Bush_Common_Flowers", Vector3(56.2, 2, 42), 4.2, 1.05],
		[&"Plant_1", Vector3(57.5, 2, 46.5), 1.5, 1.0],
		# Sous-bois : fougères aux pieds des troncs, trèfles, grandes plantes.
		[&"Fern_1", Vector3(65.2, 2, 32.5), 0.3, 1.2],
		[&"Fern_1", Vector3(74.5, 2, 23.5), 2.0, 1.0],
		[&"Fern_1", Vector3(83.0, 2, 31.5), 3.7, 1.15],
		[&"Plant_1_Big", Vector3(71.5, 2, 41.5), 1.1, 1.0],
		[&"Plant_1_Big", Vector3(90.0, 2, 39.5), 4.4, 0.9],
		[&"Clover_1", Vector3(63.5, 2, 45.5), 2.4, 1.3],
		[&"Clover_2", Vector3(80.5, 2, 47.5), 0.6, 1.2],
		# Champignons : ronde commune (repère 1) + laetiporus sur morts-bois.
		[&"Mushroom_Common", Vector3(73.0, 2, 44.0), 0.0, 1.2],
		[&"Mushroom_Common", Vector3(73.9, 2, 44.6), 2.1, 0.9],
		[&"Mushroom_Common", Vector3(72.4, 2, 44.9), 4.2, 1.05],
		[&"Mushroom_Laetiporus", Vector3(86.4, 2, 36.6), 1.7, 1.1],
		[&"Mushroom_Laetiporus", Vector3(57.4, 2, 50.6), 3.2, 0.95],
		# Ruine-curiosité (repère 2) : arche moussue, briques tombées, lierre.
		[&"Wall_Arch", Vector3(85, 2, 49), 0.8, 1.3],
		[&"Prop_Brick1", Vector3(84.1, 2, 50.2), 1.9, 1.2],
		[&"Prop_Brick1", Vector3(86.2, 2, 48.1), 3.4, 1.0],
		[&"Prop_Vine1", Vector3(85, 3.4, 49.2), 0.8, 1.3],
	])


## Zone F — rivière et gués (§11.F) : berges de roseaux, pierres émergentes
## dans le lit, saule tordu au coude OUEST, accessoires abandonnés au gué
## EST — l'axe de profondeur turquoise vers la citadelle reste dégagé.
func _dress_zone_river() -> void:
	const TRUNK: Vector3 = Vector3(0.5, 5.0, 0.0)
	_dress_zone("DressZoneRiver", [
		# Coude ouest : arbre tordu penché + roseaux, la corniche au coffre.
		[&"TwistedTree_3", Vector3(-42, 2, 16.5), 1.2, 1.1, TRUNK, true],
		[&"Grass_Wispy_Tall", Vector3(-38.5, 2.02, 17.5), 0.4, 1.3],
		[&"Grass_Wispy_Tall", Vector3(-36, 2.02, 16.2), 2.2, 1.1],
		[&"Plant_7", Vector3(-44.5, 2.02, 17.8), 3.6, 1.45],
		# Pierres émergentes du lit (hors des deux gués praticables).
		[&"RockPath_Round_Wide", Vector3(-15, 0.55, 10), 0.7, 1.4],
		[&"RockPath_Round_Thin", Vector3(4, 0.5, 9), 2.3, 1.2],
		[&"RockPath_Square_Wide", Vector3(48, 0.55, 11), 4.0, 1.3],
		[&"RockPath_Round_Small_1", Vector3(-28, 0.5, 10.5), 1.1, 1.5],
		# Berge nord (côté donjon) : herbes éparses, plante humide.
		[&"Grass_Wispy_Short", Vector3(-8, 2.02, 3.5), 0.8, 1.2],
		[&"Grass_Wispy_Short", Vector3(12, 2.02, 4.2), 2.5, 1.0],
		[&"Plant_7", Vector3(34, 2.02, 3.8), 4.3, 1.1],
		# Gué est : bivouac abandonné — seau renversé, corde, bouteille.
		[&"Bucket_Metal", Vector3(99, 2.05, 15.5), 1.9, 1.0],
		[&"Rope_1", Vector3(97.5, 2.02, 16.3), 0.5, 1.0],
		[&"Bottle_1", Vector3(98.6, 2.02, 14.8), 3.1, 1.0],
		[&"Grass_Common_Short", Vector3(101, 2.02, 16.5), 2.7, 1.2],
	])
	var river: Node3D = get_node("DressZoneRiver") as Node3D
	for child: Node in river.get_children():
		if String(child.name).begins_with("Bucket_Metal"):
			(child as Node3D).rotation.z = 1.35   # renversé, §11.F


## Zone G — falaise ouest (§11.G) : pins au sommet (les hauteurs), gros
## rochers au pied, formation empilée, mort-bois en repère de corniche.
## Les surfaces d'escalade et les deux corniches de repos ne changent pas.
func _dress_zone_cliff() -> void:
	const TRUNK: Vector3 = Vector3(0.45, 6.0, 0.0)
	_dress_zone("DressZoneCliff", [
		# Sommet : bosquet de pins — silhouette de hauteur (§12 Nature).
		[&"Pine_1", Vector3(-95, 14, 60), 0.6, 1.15, TRUNK, true],
		[&"Pine_3", Vector3(-104, 14, 51), 2.3, 1.0, TRUNK, true],
		[&"Pine_5", Vector3(-88, 14, 68), 4.0, 0.9, TRUNK, true],
		[&"DeadTree_1", Vector3(-82.5, 14, 57), 1.4, 0.95, TRUNK, true],
		# Sommet : sous-bois de pins clairsemé.
		[&"Fern_1", Vector3(-97, 14, 57), 3.1, 1.1],
		[&"Clover_2", Vector3(-91, 14, 63), 0.8, 1.2],
		[&"Pebble_Round_5", Vector3(-99, 14, 63.5), 2.0, 1.6],
		# Pied de falaise : gros rochers d'appui et formation EMPILÉE.
		[&"Rock_Medium_3", Vector3(-76.5, 2, 44), 0.9, 1.4,
			Vector3(4.4, 3.0, 4.4), false],
		[&"Rock_Medium_1", Vector3(-77.5, 2, 71), 2.5, 1.25,
			Vector3(3.8, 2.6, 3.4), false],
		[&"Rock_Medium_2", Vector3(-76.8, 3.6, 70.2), 4.2, 0.8],
		# Herbes sèches au pied (zone minérale, végétation clairsemée).
		[&"Grass_Wispy_Short", Vector3(-74, 2.02, 52), 1.2, 1.2],
		[&"Grass_Wispy_Short", Vector3(-75.5, 2.02, 62), 3.5, 1.0],
	])


## Zone H — pylône (§11.H) : composition RITUELLE — cercle de dalles,
## piliers de brique encadrant l'approche, bannières — l'énergie cyan
## existante reste la seule « électricité », rien de gameplay ne change.
func _dress_zone_pylon() -> void:
	_dress_zone("DressZonePylon", [
		# Cercle de dalles autour du socle (115, 18, -25).
		[&"RockPath_Square_Wide", Vector3(111.5, 18.02, -25), 0.0, 1.2],
		[&"RockPath_Square_Wide", Vector3(118.5, 18.02, -25), 1.57, 1.2],
		[&"RockPath_Square_Wide", Vector3(115, 18.02, -21.5), 0.79, 1.2],
		[&"RockPath_Square_Wide", Vector3(115, 18.02, -28.5), 2.36, 1.2],
		[&"RockPath_Square_Small_1", Vector3(112.2, 18.02, -22.2), 1.1, 1.3],
		[&"RockPath_Square_Small_1", Vector3(117.8, 18.02, -27.8), 2.7, 1.3],
		# Piliers de brique encadrant l'approche est (rampe du pylône).
		[&"Corner_Exterior_Brick", Vector3(120.5, 18, -20.5), 0.3, 1.2,
			Vector3(0.8, 3.2, 0.8), false],
		[&"Corner_Exterior_Brick", Vector3(120.5, 18, -29.5), 0.3, 1.2,
			Vector3(0.8, 3.2, 0.8), false],
		# Bannières de seuil — le lieu est ENTRETENU, pas abandonné.
		[&"Banner_2", Vector3(119.6, 18, -21.2), 4.71, 1.25],
		[&"Banner_2", Vector3(119.6, 18, -28.8), 4.71, 1.25],
		# Pierres votives éparses, végétation quasi absente (§7.5 : rare
		# près des dangers électriques).
		[&"Pebble_Round_4", Vector3(110.5, 18.02, -28.5), 0.6, 1.5],
		[&"Pebble_Round_5", Vector3(112, 18.02, -20), 2.9, 1.3],
	])


## Zone I — approche de la citadelle (§11.I), en QUATRE couches : ruines
## extérieures dans la plaine, rampe fortifiée (piliers-torchères,
## bannières), terrasse d'accueil (murs d'enceinte partiels, charrette,
## ravitaillement), seuil monumental (bannières sur les piliers V4.3).
## La rampe processionnelle et la SceneDoor ne changent pas.
func _dress_zone_citadel_approach() -> void:
	_dress_zone("DressZoneCitadel", [
		# 1. Ruines extérieures — la route traverse un passé effondré.
		[&"Wall_UnevenBrick_Window_Thin_Round", Vector3(-13, 2, -88), 0.35, 1.2,
			Vector3(2.2, 3.4, 0.6), false],
		[&"Corner_Exterior_Brick", Vector3(-10.5, 2, -84), 0.35, 1.2,
			Vector3(0.8, 3.2, 0.8), false],
		[&"Prop_Brick1", Vector3(-11.5, 2, -86), 1.8, 1.3],
		[&"Prop_Brick1", Vector3(-8.9, 2, -83), 3.9, 1.1],
		[&"Wall_UnevenBrick_Door_Round", Vector3(14, 2, -96), 2.9, 1.25,
			Vector3(2.2, 3.6, 0.6), false],
		[&"Prop_Vine2", Vector3(14, 3.2, -95.6), 2.9, 1.2],
		[&"Prop_Brick1", Vector3(12.2, 2, -93.5), 0.7, 1.2],
		# 2. Rampe fortifiée : deux paires pilier+torchère, bannières.
		[&"Corner_Exterior_Brick", Vector3(-6.8, 10.7, -125), 0.0, 1.3,
			Vector3(0.9, 3.6, 0.9), false],
		[&"Corner_Exterior_Brick", Vector3(6.8, 10.7, -125), 0.0, 1.3,
			Vector3(0.9, 3.6, 0.9), false],
		[&"Torch_Metal", Vector3(-6.8, 13.6, -124.4), 3.14, 1.2],
		[&"Torch_Metal", Vector3(6.8, 13.6, -124.4), 3.14, 1.2],
		[&"Corner_Exterior_Brick", Vector3(-6.8, 22.4, -145), 0.0, 1.3,
			Vector3(0.9, 3.6, 0.9), false],
		[&"Corner_Exterior_Brick", Vector3(6.8, 22.4, -145), 0.0, 1.3,
			Vector3(0.9, 3.6, 0.9), false],
		[&"Banner_1", Vector3(-6.8, 25.4, -144.6), 3.14, 1.3],
		[&"Banner_1", Vector3(6.8, 25.4, -144.6), 3.14, 1.3],
		# 3. Terrasse : murs d'enceinte PARTIELS en corridor, ravitaillement.
		[&"Wall_UnevenBrick_Straight", Vector3(-11, 34, -180), 0.0, 1.4,
			Vector3(2.8, 4.4, 0.6), false],
		[&"Wall_UnevenBrick_Straight", Vector3(11, 34, -180), 0.0, 1.4,
			Vector3(2.8, 4.4, 0.6), false],
		[&"Wall_UnevenBrick_Window_Wide_Round", Vector3(-14, 34, -182.5), 0.5,
			1.4, Vector3(2.8, 4.4, 0.6), false],
		[&"Wall_UnevenBrick_Window_Wide_Round", Vector3(14, 34, -182.5), -0.5,
			1.4, Vector3(2.8, 4.4, 0.6), false],
		[&"Prop_Wagon", Vector3(-16, 34, -188), 1.1, 1.0,
			Vector3(2.2, 1.4, 1.5), false],
		[&"FarmCrate_Empty", Vector3(16.5, 34, -187), 0.4, 1.0],
		[&"Bag", Vector3(17.4, 34, -186.2), 2.2, 1.0],
		# 4. Seuil : bannières sur les piliers de bronze existants.
		[&"Banner_1", Vector3(-6.5, 42.5, -195.6), 0.0, 1.5],
		[&"Banner_1", Vector3(6.5, 42.5, -195.6), 0.0, 1.5],
	])


## Zone A — crête d'ouverture (§11.A) : cadre végétal LATÉRAL, rochers
## héroïques, fleurs au premier plan — le couloir central (x −12..12) vers
## la citadelle reste VIDE de toute silhouette haute.
func _dress_zone_crest() -> void:
	const TRUNK: Vector3 = Vector3(0.45, 6.0, 0.0)
	_dress_zone("DressZoneCrest", [
		# Cadre gauche (ouest) — feuillus étagés.
		[&"CommonTree_2", Vector3(-34, 24, 154), 0.8, 1.1, TRUNK, true],
		[&"CommonTree_5", Vector3(-42, 24, 161), 2.3, 0.95, TRUNK, true],
		[&"TwistedTree_1", Vector3(-25, 24, 169), 4.1, 1.0, TRUNK, true],
		# Cadre droit (est) — un pin marque la hauteur, un feuillu ferme.
		[&"Pine_2", Vector3(38, 24, 157), 1.6, 1.1, TRUNK, true],
		[&"CommonTree_3", Vector3(45, 24, 164), 5.0, 1.0, TRUNK, true],
		# Rochers héroïques aux épaules du cadre, HORS couloir.
		[&"Rock_Medium_3", Vector3(-18, 24, 151), 0.7, 1.15,
			Vector3(3.6, 2.4, 3.6), false],
		[&"Rock_Medium_1", Vector3(22, 24, 153), 2.9, 0.9,
			Vector3(3.0, 2.0, 2.8), false],
		# Premier plan fleuri (bas : n'obstrue pas la vue) et touffes.
		[&"Flower_3_Group", Vector3(-7.5, 24, 155.5), 0.4, 1.2],
		[&"Flower_3_Group", Vector3(-5.2, 24, 157.8), 2.2, 0.9],
		[&"Flower_4_Group", Vector3(6.5, 24, 155.0), 1.1, 1.1],
		[&"Flower_4_Group", Vector3(9.0, 24, 157.5), 3.6, 0.85],
		[&"Flower_3_Single", Vector3(-3.0, 24, 154.2), 5.2, 1.0],
		[&"Grass_Common_Tall", Vector3(-10.5, 24, 156.5), 0.9, 1.3],
		[&"Grass_Common_Tall", Vector3(-12.5, 24, 159.0), 2.7, 1.1],
		[&"Grass_Wispy_Tall", Vector3(11.5, 24, 156.0), 1.8, 1.2],
		[&"Grass_Wispy_Tall", Vector3(13.0, 24, 158.5), 4.4, 1.0],
		[&"Fern_1", Vector3(-16.5, 24, 152.5), 3.3, 1.1],
		[&"Fern_1", Vector3(20.0, 24, 155.0), 0.6, 0.9],
		[&"Clover_1", Vector3(4.0, 24, 158.5), 1.4, 1.2],
		[&"Pebble_Round_4", Vector3(-14.0, 24, 154.0), 2.1, 1.4],
		[&"Pebble_Round_5", Vector3(16.5, 24, 153.5), 5.0, 1.2],
	])


## Zone B — descente principale (§11.B) : la lecture du relief se fait par
## bornes de pierre aux paliers, buissons aux bords EXTÉRIEURS des rampes,
## un pin en jalon — jamais rien SUR la surface de course.
func _dress_zone_descent() -> void:
	const TRUNK: Vector3 = Vector3(0.45, 6.0, 0.0)
	_dress_zone("DressZoneDescent", [
		# Bornes de palier (pierres plates lisibles).
		[&"RockPath_Round_Wide", Vector3(42.5, 16, 110), 0.3, 1.3],
		[&"RockPath_Round_Thin", Vector3(11.5, 8, 78), 1.7, 1.2],
		[&"RockPath_Round_Small_1", Vector3(27.0, 6, 66.5), 0.9, 1.3],
		# Buissons aux bords extérieurs des rampes.
		[&"Bush_Common", Vector3(28.5, 20.2, 134), 0.7, 1.1],
		[&"Bush_Common", Vector3(41.5, 16, 116), 2.4, 0.95],
		[&"Bush_Common", Vector3(27.5, 12.2, 95), 4.0, 1.05],
		[&"Bush_Common_Flowers", Vector3(12.5, 8, 82), 1.2, 1.0],
		# Jalons verticaux : un pin au premier palier, un feuillu au pied.
		[&"Pine_4", Vector3(44.5, 16, 106), 2.0, 1.0, TRUNK, true],
		[&"CommonTree_5", Vector3(10.0, 6.2, 63), 3.8, 0.9, TRUNK, true],
		# Petites pierres dans les virages (jamais sur l'axe).
		[&"Pebble_Round_4", Vector3(38.5, 16, 119), 1.1, 1.6],
		[&"Pebble_Round_4", Vector3(15.0, 8, 75), 2.8, 1.4],
		[&"Rock_Medium_2", Vector3(46.5, 16, 112), 3.5, 0.8,
			Vector3(2.4, 1.5, 2.0), false],
	])


## Zone C — prairie centrale (§11.C) : respiration — arbres ISOLÉS, bouquets,
## herbes de berge humide, lignes de vue dégagées vers camp/pylône/citadelle.
func _dress_zone_prairie() -> void:
	const TRUNK: Vector3 = Vector3(0.45, 6.0, 0.0)
	_dress_zone("DressZonePrairie", [
		# Deux arbres isolés, appuis de composition — loin des chemins.
		[&"CommonTree_1", Vector3(-30, 2, 42), 1.9, 1.1, TRUNK, true],
		[&"TwistedTree_2", Vector3(-27, 2, 25), 4.6, 1.0, TRUNK, true],
		# Bouquets de fleurs, groupés avec de vrais vides entre eux.
		[&"Flower_4_Group", Vector3(-21, 2, 36), 0.8, 1.2],
		[&"Flower_4_Group", Vector3(-18.5, 2, 38.5), 2.5, 0.9],
		[&"Flower_3_Group", Vector3(-45, 2, 30), 1.3, 1.1],
		[&"Flower_3_Single", Vector3(-43, 2, 32.5), 3.9, 1.0],
		[&"Flower_4_Single", Vector3(4, 2, 44), 0.2, 1.0],
		# Herbes hautes de berge (bande humide z 20-24).
		[&"Grass_Wispy_Tall", Vector3(-14, 2.02, 21.5), 0.5, 1.3],
		[&"Grass_Wispy_Tall", Vector3(-11.5, 2.02, 23), 2.1, 1.1],
		[&"Grass_Common_Tall", Vector3(8, 2.02, 22), 3.3, 1.2],
		[&"Grass_Common_Tall", Vector3(10.5, 2.02, 23.5), 5.1, 1.0],
		[&"Plant_7", Vector3(-26, 2.02, 22.5), 1.6, 1.1],
		# Trèfles et fougères en accents discrets.
		[&"Clover_2", Vector3(-32, 2, 45.5), 2.2, 1.3],
		[&"Fern_1", Vector3(-7, 2, 30), 4.2, 1.0],
		# Un rocher franc à l'ouest, obstacle honnête.
		[&"Rock_Medium_2", Vector3(-50, 2, 50), 0.9, 1.1,
			Vector3(3.2, 2.0, 2.6), false],
		# Galets du gué OUEST (route du donjon, x 20 z 10).
		[&"RockPath_Square_Small_1", Vector3(16, 2.02, 15.5), 1.0, 1.5],
		[&"Pebble_Round_5", Vector3(23.5, 2.02, 15), 2.6, 1.8],
		[&"Pebble_Round_4", Vector3(18.5, 2.02, 13.5), 4.1, 1.5],
	])


## ART-Q4 — « phrases » de végétation (§7.17 : grande touffe + moyenne +
## vide, répétition irrégulière). Placements DÉTERMINISTES à la main, en
## groupes autour des focales — jamais une dispersion uniforme. Buissons et
## galets sont du décor sans collision ; les rochers moyens bloquent.
func _build_nature_phrases() -> void:
	var phrases: Node3D = Node3D.new()
	phrases.name = "NaturePhrases"
	add_child(phrases)
	# [id, position, lacet, échelle]
	var placements: Array[Array] = [
		# Lisière ouest de la forêt : trois buissons serrés, un vide, un isolé.
		[&"env.plant.bush", Vector3(54.0, 2.0, 28.0), 0.4, 1.15],
		[&"env.plant.bush", Vector3(56.2, 2.0, 30.4), 2.1, 0.9],
		[&"env.plant.bush", Vector3(53.1, 2.0, 31.6), 4.4, 1.0],
		[&"env.plant.bush", Vector3(61.0, 2.0, 49.0), 1.2, 1.25],
		# Bord de crête (départ) : deux buissons qui cadrent la descente —
		# TOUS deux hors du couloir de vista x −12..12 (revue V4 lot 16 :
		# celui de droite était à x = 11, 1,5 m de haut dans le couloir).
		[&"env.plant.bush", Vector3(-14.0, 24.0, 162.0), 0.9, 1.1],
		[&"env.plant.bush", Vector3(14.5, 24.0, 158.0), 3.6, 0.95],
		# Coude de rivière : galets en langue, humides de contexte (§7.5).
		[&"env.rock.pebble_a", Vector3(24.0, 2.02, 23.5), 0.3, 2.4],
		[&"env.rock.pebble_b", Vector3(25.8, 2.02, 24.6), 1.7, 2.0],
		[&"env.rock.pebble_c", Vector3(23.2, 2.02, 25.8), 3.1, 2.2],
		[&"env.rock.pebble_a", Vector3(27.5, 2.02, 22.9), 4.6, 1.6],
		# Pied de la falaise d'apprentissage : deux rochers francs.
		[&"env.rock.medium", Vector3(-72.0, 2.0, 58.0), 0.7, 1.0],
		[&"env.rock.large", Vector3(-76.5, 2.0, 64.0), 2.3, 0.8],
	]
	for entry: Array in placements:
		var packed: PackedScene = AssetRegistry.resolve(entry[0] as StringName)
		if packed == null:
			continue   # pas livré : le vide reste un vide, jamais une boîte
		var prop: Node3D = packed.instantiate() as Node3D
		prop.name = "Phrase_%s_%d" % [String(entry[0] as StringName)
			.get_slice(".", 1), phrases.get_child_count()]
		prop.position = entry[1] as Vector3
		prop.rotation.y = float(entry[2])
		prop.scale = Vector3.ONE * float(entry[3])
		phrases.add_child(prop)
		# Les rochers moyens/grands sont des OBSTACLES : collision boîte
		# approchée, hors chemins (positions choisies pour).
		if String(entry[0] as StringName).begins_with("env.rock.medium") \
				or String(entry[0] as StringName).begins_with("env.rock.large"):
			var body: StaticBody3D = StaticBody3D.new()
			body.collision_layer = 1
			body.collision_mask = 0
			var shape: CollisionShape3D = CollisionShape3D.new()
			var box: BoxShape3D = BoxShape3D.new()
			box.size = Vector3(2.6, 2.0, 2.6) * float(entry[3])
			shape.shape = box
			shape.position = Vector3(0, 1.0 * float(entry[3]), 0)
			body.add_child(shape)
			prop.add_child(body)


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
	# ART-Q5 : l'arche de pierre de production HABILLE le seuil réel — même
	# module que le vestibule (continuité de matière), à l'échelle
	# monumentale. Décor pur : la SceneDoor et ses cotes ne bougent pas.
	var gate_frame: PackedScene = AssetRegistry.resolve(&"arch.gate.module")
	if gate_frame != null:
		var frame: Node3D = gate_frame.instantiate() as Node3D
		frame.name = "GateStoneArch"
		frame.position = Vector3(0, 34.0, -197.4)
		frame.scale = Vector3(2.5, 2.45, 1.5)
		citadel.add_child(frame)
	# Piliers de production au pied des marches : le langage modulaire de la
	# citadelle commence AVANT la porte.
	var flank: PackedScene = AssetRegistry.resolve(&"arch.column.module")
	if flank != null:
		for side_index: int in range(2):
			var pillar: Node3D = flank.instantiate() as Node3D
			pillar.name = "GateFlankPillar%d" % side_index
			pillar.position = Vector3(-8.6 if side_index == 0 else 8.6,
				34.0, -191.2)
			pillar.rotation.y = PI * 0.5 * float(side_index)
			pillar.scale = Vector3(1.8, 1.5, 1.8)
			citadel.add_child(pillar)
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
## Emprise de la prairie de crête, en mètres.
const MEADOW_X: Vector2 = Vector2(-46.0, 46.0)
const MEADOW_Z: Vector2 = Vector2(144.5, 170.0)
## §7.5 : « cellules de 24-48 m ». Quatre cellules de 23 m de large.
const MEADOW_CELLS: int = 4
## §7.2, densités en TOUFFES par m² : 7-14 dans la zone héroïque (0-18 m de
## la caméra), 4-8 au-delà. La prairie tournait à 0,6 touffe/m² — vingt fois
## sous la bande — et le tiers inférieur du cadre §3.2, censé porter « une
## pente herbeuse riche », se lisait comme un aplat vert avec quelques
## cônes posés dessus.
const MEADOW_NEAR_DENSITY: float = 9.0
const MEADOW_FAR_DENSITY: float = 4.5
## Rayon de la zone héroïque autour de la caméra d'ouverture.
const MEADOW_NEAR_RADIUS: float = 18.0


## MultiMesh PARTITIONNÉ (quatre cellules + fleurs), scatter déterministe,
## exclusion du chemin, vent par `SH_FoliageWind` — aucun recalcul CPU.
func _build_crest_meadow() -> void:
	var meadow: Node3D = Node3D.new()
	meadow.name = "CrestMeadow"
	add_child(meadow)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260803
	var shader: Shader = load("res://shaders/foliage/foliage_wind.gdshader") as Shader
	# Cellules de brins (§7.5 : « jamais toute la vallée dans un MultiMesh
	# unique »), découpées en bandes de 23 m sur la largeur de la crête.
	var cells: Array[Array] = []
	var cell_width: float = (MEADOW_X.y - MEADOW_X.x) / float(MEADOW_CELLS)
	for index: int in range(MEADOW_CELLS):
		var low: float = MEADOW_X.x + cell_width * float(index)
		cells.append([Vector2(low, low + cell_width), "Cell%d" % index])
	var tuft: ArrayMesh = _tuft_mesh()
	var tuft_material: ShaderMaterial = ShaderMaterial.new()
	tuft_material.shader = shader
	# §3.1 : le premier plan porte de l'herbe LONGUE. Avec 0,42 m et une
	# échelle de 0,7-1,15, aucune touffe ne dépassait 0,48 m — la bande
	# « herbe longue héroïque » de la bible commence à 0,65 m.
	tuft_material.set_shader_parameter(&"blade_height", 0.55)
	var cell_area: float = cell_width * (MEADOW_Z.y - MEADOW_Z.x)
	for cell: Array in cells:
		var bounds: Vector2 = cell[0]
		var blades: MultiMeshInstance3D = MultiMeshInstance3D.new()
		blades.name = String(cell[1])
		blades.material_override = tuft_material
		var multimesh: MultiMesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = tuft
		# La densité TOMBE avec la distance (§7.2) : plein tarif dans la zone
		# héroïque autour de la caméra d'ouverture, moitié moins sur les
		# bandes latérales, qu'on ne voit qu'en tournant.
		var centre_x: float = (bounds.x + bounds.y) * 0.5
		var density: float = MEADOW_NEAR_DENSITY \
			if absf(centre_x - ValleyWorld.VISTA_POSITION.x) < MEADOW_NEAR_RADIUS \
			else MEADOW_FAR_DENSITY
		multimesh.instance_count = int(cell_area * density)
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
					.scaled(Vector3.ONE * rng.randf_range(0.75, 1.35))
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
	flower_multimesh.instance_count = 420
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
## Touffe = un ÉVENTAIL DE BRINS FINS, pas trois quads larges.
##
## La version précédente croisait trois quads de 34 cm de large qui
## s'effilaient vers le haut : à faible densité on ne les voyait pas, mais
## une fois la prairie à la densité de la bible, le premier plan s'est
## couvert de petits sapins vert foncé. Deux causes, corrigées ici :
##
##  - la LARGEUR. Un brin fait 3 à 4 cm, pas 34. Sept brins étroits, écartés
##    et inclinés, lisent « touffe » ; trois plaques larges lisent « cône » ;
##  - les NORMALES. `generate_normals()` sur des quads verticaux donne des
##    normales horizontales : la touffe ne recevait presque rien du ciel et
##    ressortait bien plus sombre que le sol qu'elle est censée prolonger.
##    Les normales sont donc inclinées vers le haut, comme le veut l'usage
##    pour l'herbe — la masse s'éclaire, elle ne se découpe plus en carton.
func _tuft_mesh() -> ArrayMesh:
	const BLADES: int = 7
	const BASE_WIDTH: float = 0.036
	const TIP_WIDTH: float = 0.012
	## Part de la normale ramenée vers le ciel.
	const SKY_BIAS: float = 0.72
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k: int in range(BLADES):
		var yaw: float = TAU * float(k) / float(BLADES) + 0.31 * float(k % 3)
		var basis: Basis = Basis(Vector3.UP, yaw)
		# Chaque brin s'écarte du centre et se COUCHE vers sa pointe : c'est
		# ce ploiement qui donne la silhouette d'une touffe au repos.
		var lean: float = 0.10 + 0.055 * float(k % 4)
		var height: float = 0.42 * (0.72 + 0.09 * float(k % 4))
		var root: Vector3 = basis * Vector3(0.0, 0.0, 0.028 * float(k % 3))
		var mid: Vector3 = root + basis * Vector3(lean * 0.45, height * 0.58, 0.0)
		var tip: Vector3 = root + basis * Vector3(lean, height, 0.0)
		var side: Vector3 = basis * Vector3(0.0, 0.0, 1.0)
		var face: Vector3 = basis * Vector3(1.0, 0.0, 0.0)
		var normal: Vector3 = (face.lerp(Vector3.UP, SKY_BIAS)).normalized()
		var levels: Array[Array] = [
			[root, BASE_WIDTH], [mid, BASE_WIDTH * 0.62], [tip, TIP_WIDTH],
		]
		for level: int in range(levels.size() - 1):
			var low: Vector3 = levels[level][0] as Vector3
			var low_w: float = levels[level][1] as float
			var high: Vector3 = levels[level + 1][0] as Vector3
			var high_w: float = levels[level + 1][1] as float
			for vertex: Vector3 in [
				low - side * low_w, low + side * low_w, high + side * high_w,
				low - side * low_w, high + side * high_w, high - side * high_w,
			]:
				st.set_normal(normal)
				st.add_vertex(vertex)
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


## V4 lot 15 — matériaux graybox PARTAGÉS par clé (couleur, émission) :
## des centaines de volumes réutilisent la même ressource au lieu d'en
## créer chacun une. Quiconde veut PERSONNALISER un matériau issu d'ici
## doit le DUPLIQUER d'abord (braises, runes) — muter en place teinterait
## tous les volumes de même clé.
var _material_cache: Dictionary[String, StandardMaterial3D] = {}


func _material(color: Color, emissive: bool) -> StandardMaterial3D:
	var key: String = "%s|%s" % [color.to_html(), emissive]
	var cached: StandardMaterial3D = _material_cache.get(key) as StandardMaterial3D
	if cached != null:
		return cached
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if emissive:
		# Cœur blanc, halo cyan (§7.9) — version proxy : émission simple.
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0
	_material_cache[key] = mat
	return mat
