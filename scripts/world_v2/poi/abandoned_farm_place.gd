## FERME ABANDONNÉE (`valley.poi.abandoned_farm.01`, r02) — grammaire
## rurale et RUINE récente : la maison tient encore, le toit a cédé d'un
## pan, la clôture est rompue, le verger repousse en friche.
##
## REJET DU LEAD (V2.3-A.R2) : « de longues planches plantées dans le
## bâtiment » — la charpente en `K.stone_block` ne portait sur rien, et le
## socle en blocs juxtaposés reproduisait « le gros rectangle de
## fondation » à l'échelle du bloc.
##
## R2B : la ruine de toiture est un asset GLB (`SM_Farm_Ruins.glb`,
## générateur `make_farm_ruins.py`) — une CHARPENTE d'un seul trait
## (faîtière cassée en deux, chevrons SOLIDAIRES du faîte à l'arase,
## sablières posées sur les murs), un pan de couverture intact posé à 22°
## sur le versant ouest, un pan TOMBÉ dont la géométrie porte le pli (un
## bout au sol, un bout contre le mur est), deux tas de gravats fusionnés.
## Le socle est un anneau d'assises loftées `SM_Village_Wall.glb` (golden
## master réutilisé en LECTURE — arbitrage R2B). L'effondrement est MOTIVÉ :
## les murs ouest et nord portent, le mur est réduit a lâché — le pan est
## tombé de ce côté-là.
##
## R2B.1 — SECONDE REVUE DU LEAD : « se lit comme une boîte beige inachevée
## ou un greybox ; murs rectangulaires lisses, charpente trop vide, peu de
## masse effondrée et presque aucune histoire structurelle visible ». Deux
## causes MESURÉES, jamais supposées (sonde du 2026-08-19) :
##
##   1. `ARASES : n=15 min=3.059 max=3.173 moy=3.142 ecart_type=0.050 m` — les
##      onze modules de mur sont TOUS à 3,173 m. Cinq centimètres de
##      dispersion sur 6,4 m de bâtiment : la maçonnerie ne casse nulle part,
##      d'où le contour « rectangle + chapeau ».
##   2. Le module de kit `Wall_UnevenBrick_Straight` est fait de DEUX PLANS
##      STRICTS sans face de chant (inspection glTF : `MI_UnevenBrick` à
##      Z = 0,000 en 4 tris, `MI_Plaster` à Z = -0,200 en 2 tris). Sa face
##      intérieure est UN quad de 2,00 × 3,00 m — 6,00 m² pour deux triangles.
##
## ET UNE ERREUR DE ROTATION, établie par le calcul puis confirmée en image :
## la face brique du module est en +Z local, donc `yaw` 0° (sud) et 180°
## (nord) la présentent dehors, mais `yaw` 90° (ouest) et 270° (est) la
## présentaient DEDANS — les cinq modules de ces deux murs montraient leur
## plâtre à l'extérieur. C'est le grand panneau uni de `ferme_laterale`. Les
## yaw sont corrigés à 270° et 90° ci-dessous ; `_wall()` en tire un collider
## identique (`along.abs()` ne distingue pas 90 de 270).
##
## Réponse géométrique : cinq pièces de maçonnerie ajoutées au GLB — pignon
## nord ROMPU en gradins d'assise, moignon du mur est, talus de moellons au
## pied de la brèche, tableaux de baie, ossature intérieure — plus un verger
## qui devient un ALIGNEMENT. Le contraste est préservé : ouest et nord
## portent encore et restent couverts.
##
## Pièges consignés appliqués : `Floor_Brick` a son pivot CENTRÉ en X/Z
## (probe_kit_seating 2026-08-19 : 2,00 × 0,02 × 2,00, pivot centre) — les
## dalles posées à ±1 m couvrent 4 × 4 m autour du centre, jamais « à
## l'œil » ; Wall_UnevenBrick_* mesure 2,00 × 3,12 × 0,41, l'arase est à
## 3,12 m et c'est là que la charpente pose son plan zéro.
class_name AbandonedFarmPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")
const FERME_SCENE: PackedScene = preload(
	"res://assets/architecture/farm/SM_Farm_Ruins.glb")
const MUR_SCENE: PackedScene = preload(
	"res://assets/architecture/village/SM_Village_Wall.glb")

const MODULE: float = 2.0
const WALL_H: float = 3.12
## Assise mesurée du module de mur (`SM_Village_Wall.glb`) : 0,45 m de
## haut, 4,00 m de long — mêmes cotes que le hameau qui l'a produit.
const ASSISE_H: float = 0.45
const ASSISE_L: float = 4.00
## Plafond painterly commun aux GLB du monde (même règle que le hameau).
const ALBEDO_MAX: float = 0.80

static var _cache_materiaux: Dictionary = {}


func default_place_id() -> StringName:
	return &"valley.poi.abandoned_farm.01"


func _build() -> void:
	_ruined_house(Vector3(-2.0, 0.0, -1.0), 25.0)

	# — Clôture ROMPUE : une course de piquets qui s'interrompt, deux
	# segments tombés.
	for fence: Array in [[-8.5, 5.0, 115.0, false], [-6.6, 6.2, 115.0, false],
			[-4.6, 7.2, 100.0, false], [-0.5, 8.6, 80.0, false],
			[1.6, 8.9, 75.0, false], [5.6, 8.2, 55.0, false]]:
		var piece: Node3D = K.module(self, &"Prop_WoodenFence_Single",
			_seated(float(fence[0]), float(fence[1])), float(fence[2]), 1.0,
			K.TONE_WOOD)
		if piece != null and bool(fence[3]):
			piece.rotation.z = deg_to_rad(74.0)
	# Les deux segments tombés, couchés dans l'herbe.
	for fallen: Array in [[-2.6, 8.2, 30.0], [3.7, 8.7, -15.0]]:
		var down: Node3D = K.module(self, &"Prop_WoodenFence_Single",
			_seated(float(fallen[0]), float(fallen[1])) + Vector3(0, 0.12, 0),
			float(fallen[2]), 1.0, K.TONE_WOOD)
		if down != null:
			down.rotation.x = deg_to_rad(84.0)

	# — La charrette qui n'est jamais partie, roues dans la friche.
	K.module(self, &"Prop_Wagon", _seated(4.6, 4.2), -140.0, 1.0, K.TONE_WOOD)
	K.collider_box(self, "Charrette_col", _seated(4.6, 4.2) + Vector3(0, 0.7, 0),
		Vector3(2.6, 1.4, 1.6), -140.0)
	K.module(self, &"FarmCrate_Empty", _seated(2.4, 5.4), 30.0, 1.0, K.TONE_WOOD)
	K.module(self, &"FarmCrate_Apple", _seated(3.3, 5.9), -12.0, 1.0,
		K.TONE_WOOD)

	# — Le verger en friche : l'arbre porteur du fruit de soin, un buisson
	# de baies, la repousse.
	# UN VERGER EST UN RANG. Trois arbres alignés à 3,8-4,3 m de pas disent
	# « planté par quelqu'un » ; un arbre isolé ne dit rien. Le rang part du
	# porteur de fruits et fuit vers le sud-ouest, et la friche le désaligne
	# juste assez pour qu'il ne soit pas une rangée mécanique.
	# ÉCHELLE RECALÉE SUR CAPTURE : posés à 1,0-1,14, ces `CommonTree_4`
	# montaient à 9-10,5 m et masquaient la ferme sur `ferme_composition`
	# comme sur `arbre_lointain_94` — cinq troncs de futaie au premier plan
	# là où il n'y en avait qu'un. Un verger, ce sont des fruitiers de 4-5 m,
	# et le rang passe DERRIÈRE le bâtiment plutôt que devant sa façade.
	for verger: Array in [[8.2, -2.0, 70.0, 0.52], [9.0, -5.8, 15.0, 0.48],
			[9.8, -9.6, -40.0, 0.55]]:
		var pos: Vector3 = _seated(float(verger[0]), float(verger[1]))
		K.module(self, &"CommonTree_4", pos, float(verger[2]),
			float(verger[3]), K.TONE_PLANT)
		declare_support(pos)
	# Le quatrième arbre a poussé HORS du rang, contre le pignon : c'est la
	# repousse, pas la plantation.
	var repousse: Vector3 = _seated(5.4, 2.6)
	K.module(self, &"CommonTree_4", repousse, -25.0, 0.46, K.TONE_PLANT)
	declare_support(repousse)
	# Un tuteur rompu et une souche : le verger a été entretenu, puis laissé.
	var tuteur: Node3D = K.module(self, &"Prop_WoodenFence_Single",
		_seated(6.1, -6.9), 20.0, 0.8, K.TONE_WOOD)
	if tuteur != null:
		tuteur.rotation.z = deg_to_rad(28.0)
	K.module(self, &"Bush_Common_Flowers", _seated(6.0, -3.4), 0.0, 1.0,
		K.TONE_PLANT)
	K.module(self, &"Bush_Common", _seated(8.8, -2.8), 45.0, 1.0, K.TONE_PLANT)

	# — Découverte + récompense canonique (ingrédient — fruit de soin).
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Ferme abandonnée"
	poi.region = "r02_prairie_mille_fleurs"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 13.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.INGREDIENT,
		_seated(7.0, -4.2) + Vector3(0, 0.1, 0), Vector3(-1.4, 0.0, 1.0))


## La maison de ferme : quatre murs de brique inégale, la ruine de toiture
## GLB posée dessus — le ciel entre par le trou du versant est.
func _ruined_house(at: Vector3, yaw_deg: float) -> void:
	var house: Node3D = Node3D.new()
	house.name = "Fermette"
	add_child(house)
	var half: float = 3.0
	var top: float = -1e9
	var low: float = 1e9
	for corner: Vector3 in [Vector3(-half, 0, -half), Vector3(half, 0, -half),
			Vector3(-half, 0, half), Vector3(half, 0, half)]:
		var rotated: Vector3 = corner.rotated(Vector3.UP, deg_to_rad(yaw_deg))
		var ground: float = ground_local_y(at.x + rotated.x, at.z + rotated.z)
		top = maxf(top, ground)
		low = minf(low, ground)
		declare_support(Vector3(at.x + rotated.x, ground, at.z + rotated.z))
	house.position = Vector3(at.x, top + 0.05, at.z)
	house.rotation.y = deg_to_rad(yaw_deg)
	# SOCLE D'ASSISES LOFTÉES, jamais une boîte ni des blocs juxtaposés :
	# l'anneau reprend `SM_Village_Wall.glb` (golden master, lecture seule),
	# volume continu à fruit et joints creusés dans le profil.
	_socle_assises(house, half, top - low)
	K.collider_box(house, "Fermette_plinthe", Vector3(0, -0.2, 0),
		Vector3(6.4, 0.6, 6.4))
	# Sol de terre battue : dalles de brique disjointes, pas un plancher.
	# `Floor_Brick` a son pivot CENTRÉ (2×2 m d'emprise autour du point) :
	# quatre dalles à ±1 m couvrent le cœur des 6×6 m sans sortir des murs.
	for tile: Array in [[-1.0, -1.0], [1.0, -1.0], [-1.0, 1.0], [1.0, 0.6]]:
		K.module(house, &"Floor_Brick",
			Vector3(float(tile[0]), 0.03, float(tile[1])), 0.0, 1.0,
			K.TONE_STONE)
	K.collider_box(house, "Fermette_sol", Vector3(0, -0.1, 0),
		Vector3(6.2, 0.26, 6.2))
	# Faces : la porte SUD est une baie VIDE (la porte gît au sol) ; le mur
	# est n'a plus que deux segments — c'est LUI qui motive l'effondrement ;
	# l'ouest et le nord portent.
	for i: int in range(3):
		var x: float = (float(i) - 1.0) * MODULE
		if i == 1:
			K.module(house, &"Wall_UnevenBrick_Door_Round",
				Vector3(x, 0, half), 0.0, 1.0, Color(0.86, 0.70, 0.54))
			_jambs(house, Vector3(x, 0, half), 0.0)
		else:
			_wall(house, Vector3(x, 0, half), 0.0,
				&"Wall_UnevenBrick_Window_Thin_Round")
		_wall(house, Vector3(x, 0, -half), 180.0, &"Wall_UnevenBrick_Straight")
		var z: float = (float(i) - 1.0) * MODULE
		# 270° et 90°, PAS 90° et 270° : la face brique du module est en +Z
		# local, et l'ancienne paire présentait le plâtre à l'extérieur sur
		# les deux murs latéraux (5 modules, 6,00 m² de quad chacun).
		_wall(house, Vector3(-half, 0, z), 270.0, &"Wall_UnevenBrick_Straight")
		# Le mur EST n'a plus qu'UN segment debout : c'est lui qui a lâché,
		# et c'est ce qui motive la chute du pan de toiture de ce côté. Le
		# vide est occupé par le moignon arraché, pas laissé en trou net.
		if i == 0:
			_wall(house, Vector3(half, 0, z), 90.0,
				&"Wall_UnevenBrick_Straight")
	for corner: Vector3 in [Vector3(-half, 0, -half), Vector3(half, 0, -half),
			Vector3(-half, 0, half), Vector3(half, 0, half)]:
		K.module(house, &"Corner_Exterior_Brick", corner, 0.0, 1.0,
			K.TONE_STONE)
	_toiture_rompue(house)
	# La porte ARRACHÉE, posée à plat devant le seuil.
	var door: Node3D = K.module(house, &"Door_1_Round",
		Vector3(0.7, 0.10, half + 1.2), 24.0, 1.0, K.TONE_WOOD)
	if door != null:
		door.rotation.x = deg_to_rad(-86.0)
	# Le lierre reprend deux murs. MESURÉ (sonde du 2026-08-19, silhouette
	# 0°) : `Prop_Vine*` a son pivot à 0,81 de sa hauteur et
	# `KitPlacement.seat()` ne le corrige pas — posé à y=0, le lierre
	# pendait 2,07 m SOUS la maison et n'en montrait que la pointe. Posé à
	# +2,07, il drape le mur de 0 à 2,60 m.
	K.module(house, &"Prop_Vine1", Vector3(-half + 0.1, 2.07, -1.0), 90.0, 1.0,
		K.TONE_PLANT)
	K.module(house, &"Prop_Vine2", Vector3(1.0, 2.07, -half + 0.1), 180.0, 1.0,
		K.TONE_PLANT)


## LA RUINE DE TOITURE — quatre pièces du GLB, posées sur ce qui les porte.
##
## La charpente pose son plan zéro sur l'ARASE mesurée des murs (3,12 m),
## enfoncée de 6 cm : les sablières mordent l'arase au lieu de flotter
## dessus. Le pan intact est tourné à 22° sur le versant OUEST — les
## rotations composées de Godot s'appliquent Z puis Y : le roulis de -22°
## couche le pan sur sa pente, le lacet de 180° l'envoie côté ouest. Le pan
## TOMBÉ porte son pli dans sa géométrie : posé au sol de la maison, son
## bout relevé s'appuie vers le mur est réduit — le trou par lequel il a
## cédé. Les gravats s'entassent sous lui et hors de la brèche.
func _toiture_rompue(house: Node3D) -> void:
	_piece_ferme(house, "SM_Farm_Truss",
		Vector3(0.0, WALL_H - 0.06, 0.0), Vector3.ZERO)
	_piece_ferme(house, "SM_Farm_RoofPan_Intact",
		Vector3(0.0, WALL_H + 1.32, 0.0),
		Vector3(0.0, PI, deg_to_rad(-22.0)))
	_piece_ferme(house, "SM_Farm_RoofPan_Fallen",
		Vector3(-0.7, 0.14, 0.5), Vector3(0.0, deg_to_rad(-12.0), 0.0))
	_piece_ferme(house, "SM_Farm_Debris_A",
		Vector3(1.9, 0.12, 1.8), Vector3(0.0, deg_to_rad(40.0), 0.0))
	_piece_ferme(house, "SM_Farm_Debris_B",
		Vector3(3.6, -0.05, 2.5), Vector3(0.0, deg_to_rad(-70.0), 0.0))
	_maconnerie_rompue(house)


## LA MAÇONNERIE ROMPUE (R2B.1) — ce que le kit de murs ne sait pas produire.
##
## Le kit ne connaît qu'un module plein hauteur : avec lui, une arase ne casse
## jamais et une brèche est un trou net entre deux murs pleins. Les cinq
## pièces posées ici apportent la masse manquante, chacune sur ce qui la
## justifie :
##
##   * le PIGNON coiffe le mur nord, enfoncé de 6 cm dans l'arase comme la
##     charpente ; son arrachement regarde l'EST, du côté où le mur a cédé —
##     la rupture haute et la rupture basse racontent le même effondrement ;
##   * le MOIGNON occupe le vide du mur est, reculé de 8 cm du plan des
##     modules pour qu'aucune face ne soit coplanaire avec le parement ;
##   * le TALUS gît dehors au pied de la brèche : la matière d'un mur écroulé
##     doit se retrouver au sol, et elle couvre le soubassement mis à nu ;
##   * les TABLEAUX donnent au percement la tranche que les deux plans du
##     module n'ont pas ;
##   * l'OSSATURE et les SOLIVES disent l'étage disparu — poteaux contre les
##     murs qui portent, bouts de solives rompus contre les deux autres.
func _maconnerie_rompue(house: Node3D) -> void:
	var half: float = 3.0
	_piece_ferme(house, "SM_Farm_GableBreak",
		Vector3(0.0, WALL_H - 0.06, -half), Vector3.ZERO)
	_piece_ferme(house, "SM_Farm_WallStub_East",
		Vector3(half - 0.18, 0.0, 2.0),
		Vector3(0.0, deg_to_rad(90.0), 0.0), "", 1.20)
	_piece_ferme(house, "SM_Farm_Rubble_Wall",
		Vector3(half + 1.05, 0.0, 1.9),
		Vector3(0.0, deg_to_rad(35.0), 0.0))
	# ×1,45 sur les tableaux : ils vivent dans l'embrasure, donc à l'ombre
	# portée du mur, et la pierre y rendait GRIS UNI — le même écart que
	# celui déjà consigné pour le socle d'assises. Mesuré sur `ferme_seuil` :
	# deux colonnes plus sombres et plus unies que tout ce qui les entoure.
	_piece_ferme(house, "SM_Farm_Jamb_Door",
		Vector3(0.0, 0.01, half), Vector3.ZERO, "", 1.45)
	_piece_ferme(house, "SM_Farm_Jamb_Breach",
		Vector3(MODULE, 0.01, half), Vector3.ZERO, "", 1.45)
	# Ossature : les poteaux vont aux murs QUI PORTENT (ouest, nord) ; les
	# bouts de solives aux deux autres, où le plancher était seulement scellé.
	# Chaque pièce saille vers +X dans sa source : la rotation la retourne
	# vers l'intérieur, jamais vers le mur.
	_piece_ferme(house, "SM_Farm_InteriorFrame",
		Vector3(-half + 0.42, 0.02, -0.20), Vector3.ZERO, "ouest")
	_piece_ferme(house, "SM_Farm_InteriorFrame",
		Vector3(0.10, 0.02, -half + 0.42),
		Vector3(0.0, deg_to_rad(-90.0), 0.0), "nord")
	_piece_ferme(house, "SM_Farm_JoistStubs",
		Vector3(half - 0.48, 2.05, 0.10),
		Vector3(0.0, deg_to_rad(180.0), 0.0), "est")
	_piece_ferme(house, "SM_Farm_JoistStubs",
		Vector3(-0.10, 2.05, half - 0.48),
		Vector3(0.0, deg_to_rad(90.0), 0.0), "sud")
	# Deux volumes solides seulement : ce qui bloque réellement le passage.
	# L'ossature n'en reçoit pas — des poteaux de 17 cm espacés de 2 m se
	# franchissent, et un collider invisible entre eux serait un mur fantôme.
	K.collider_box(house, "Moignon_est_col",
		Vector3(half - 0.18, 0.42, 2.0), Vector3(0.44, 0.84, 2.10))
	K.collider_box(house, "Talus_col",
		Vector3(half + 1.05, 0.26, 1.9), Vector3(2.30, 0.52, 1.60), 35.0)


## Extrait UNE pièce du GLB de ruine : l'instance est élaguée AVANT
## d'entrer dans l'arbre, et porte le nom de la pièce — le filet R2B la
## désigne par ce nom, et Godot ne renomme jamais un enfant unique.
func _piece_ferme(parent: Node3D, piece: String, at: Vector3,
		rot: Vector3, suffixe: String = "", gain: float = 1.0) -> Node3D:
	var instance: Node3D = FERME_SCENE.instantiate() as Node3D
	# MESURÉ le 2026-08-19 : deux instances de la MÊME pièce posées sous le
	# même parent sortent de `add_child` sous le nom `@Node3D@3` — Godot ne
	# suffixe pas, il rebaptise, et le nom de la pièce disparaît. Toute pièce
	# posée plus d'une fois doit donc porter son propre suffixe.
	instance.name = piece if suffixe.is_empty() else "%s_%s" % [piece, suffixe]
	for enfant: Node in instance.get_children():
		if String(enfant.name) != piece:
			instance.remove_child(enfant)
			enfant.free()
		else:
			enfant.name = "%s_maille" % instance.name
	parent.add_child(instance)
	instance.position = at
	instance.rotation = rot
	_peindre_glb(instance, gain)
	return instance


## L'anneau de socle : quatre assises loftées sur le pourtour, ajustées EN
## LONGUEUR seulement (les joints s'étirent, jamais les hauteurs d'assise —
## règle du hameau). Couronnement retiré : c'est une plinthe sous un mur,
## pas un parapet. Le site est un pad plat (sonde du 2026-08-19 :
## dénivelé 0,000 sous les quatre coins) : une assise enterrée de 0,35 m
## suffit, et chaque run déclare son appui.
func _socle_assises(house: Node3D, half: float, drop: float) -> void:
	var socle: Node3D = Node3D.new()
	socle.name = "Socle"
	house.add_child(socle)
	var base_y: float = -ASSISE_H + 0.10 - drop
	var runs: Array[Array] = [
		[Vector3(-half - 0.30, base_y, -half - 0.30), 0.0, half * 2.0 + 0.6],
		[Vector3(half + 0.30, base_y, half + 0.30), 180.0, half * 2.0 + 0.6],
		[Vector3(-half - 0.30, base_y, half + 0.30), 90.0, half * 2.0 + 0.6],
		[Vector3(half + 0.30, base_y, -half - 0.30), -90.0, half * 2.0 + 0.6],
	]
	for i: int in range(runs.size()):
		var depart: Vector3 = runs[i][0] as Vector3
		var yaw: float = float(runs[i][1])
		var longueur: float = float(runs[i][2])
		var assise: Node3D = MUR_SCENE.instantiate() as Node3D
		assise.name = "SocleAssise_%d" % i
		for enfant: Node in assise.get_children():
			if String(enfant.name).contains("Coping"):
				assise.remove_child(enfant)
				enfant.free()
		socle.add_child(assise)
		assise.position = depart
		assise.rotation.y = deg_to_rad(yaw)
		assise.scale = Vector3(longueur / ASSISE_L, 1.0, 1.0)
		# ×1,55 : mesuré sur `ferme_proche` — à l'ombre des faces est et
		# nord, la pierre du hameau rendait un bandeau noir sous les murs.
		_peindre_glb(assise, 1.55)
		# L'appui du run, au sol du lieu (coordonnées locales du lieu).
		var milieu: Vector3 = house.position + (depart + Vector3(
			cos(deg_to_rad(yaw)) * longueur * 0.5, 0.0,
			-sin(deg_to_rad(yaw)) * longueur * 0.5)).rotated(
			Vector3.UP, house.rotation.y)
		declare_support(Vector3(milieu.x,
			ground_local_y(milieu.x, milieu.z), milieu.z))


## Les GLB portent déjà leurs valeurs (sRGB converti en linéaire dans le
## générateur). On borne rugosité, spéculaire et albédo pour rester dans
## le langage painterly du monde — matériaux DUPLIQUÉS et mis en cache.
##
## `gain` : multiplicateur d'albédo local, plafonné. Mesuré sur la
## capture `ferme_proche` du 2026-08-19 : le socle en pierre du hameau
## (albédo 0,232) vit ici sur les faces à l'OMBRE et rendait un bandeau
## NOIR — le gain réel du monde à l'ombre est bien plus bas que le ×1,8
## du plein soleil (scripts/CLAUDE.md, gain non linéaire).
func _peindre_glb(racine: Node3D, gain: float = 1.0) -> void:
	for node: Node in racine.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var base: StandardMaterial3D = instance.get_active_material(
				surface) as StandardMaterial3D
			if base == null:
				continue
			var cle: String = "glb|%d|%.2f" % [base.get_instance_id(), gain]
			var mat: StandardMaterial3D = \
				_cache_materiaux.get(cle) as StandardMaterial3D
			if mat == null:
				mat = base.duplicate() as StandardMaterial3D
				mat.roughness = maxf(mat.roughness, 0.95)
				mat.metallic_specular = 0.1
				var a: Color = mat.albedo_color
				mat.albedo_color = Color(minf(a.r * gain, ALBEDO_MAX),
					minf(a.g * gain, ALBEDO_MAX), minf(a.b * gain, ALBEDO_MAX),
					a.a)
				_cache_materiaux[cle] = mat
			instance.set_surface_override_material(surface, mat)


func _wall(parent: Node3D, at: Vector3, yaw: float, kind: StringName) -> void:
	K.module(parent, kind, at, yaw, 1.0, Color(0.86, 0.70, 0.54))
	var along: Vector3 = Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
	var thick: Vector3 = Vector3(absf(along.z), 0, absf(along.x)) * 0.4
	var span: Vector3 = along.abs() * MODULE
	K.collider_box(parent, "mur_col_%d" % parent.get_child_count(),
		at + Vector3(0, WALL_H * 0.5, 0),
		Vector3(maxf(span.x, thick.x), WALL_H, maxf(span.z, thick.z)))


func _jambs(parent: Node3D, at: Vector3, yaw: float) -> void:
	var along: Vector3 = Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
	for side: float in [-1.0, 1.0]:
		K.collider_box(parent, "jambage_%d" % parent.get_child_count(),
			at + along * side * 0.83 + Vector3(0, WALL_H * 0.5, 0),
			Vector3(maxf(along.abs().x * 0.35, 0.4), WALL_H,
				maxf(along.abs().z * 0.35, 0.4)))
	K.collider_box(parent, "linteau_%d" % parent.get_child_count(),
		at + Vector3(0, WALL_H - 0.4, 0),
		Vector3(maxf(along.abs().x * MODULE, 0.4), 0.8,
			maxf(along.abs().z * MODULE, 0.4)))


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
