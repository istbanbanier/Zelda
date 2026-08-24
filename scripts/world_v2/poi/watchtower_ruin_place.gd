## TOUR DE GUET (`valley.poi.watchtower_ruin.01`, r04) — la verticale
## CASSÉE de la moitié ouest : un fût carré qui tient neuf mètres du côté
## du couchant et descend en escalier jusqu'à zéro du côté du vide.
##
## CE QUE LE TERRAIN GELÉ DONNE, ET QUI A DÉCIDÉ DE TOUT (profils mesurés,
## `docs/V2_3_B_LOT1_VOIE_B_PLAN.md` §0) : le site est un pad plat jusqu'à
## r = 3 m, puis la falaise tombe à l'EST — −2,2 m à 6 m, −11,9 m à 12 m,
## −14,0 m à 15 m et plat ensuite. La pente entre 6 et 13 m vaut 1,55 m/m,
## soit 57° : au-delà de 55° le shader de sol rend déjà de la roche
## stratifiée (`SH_WorldV2Ground`, `rock_up_full = 0.574`). La falaise
## n'est donc pas à construire — elle est là, et elle est en pierre.
##
## D'où l'implantation : le fût est posé de façon que sa face est tombe à
## `x_local = −0,2`, quatre mètres AVANT le début de la pente. Rien ne
## flotte au-dessus du vide ; ce qui est dans le vide y est TOMBÉ.
##
## LOT 1.R — CORRECTIVE VISUELLE. Le gate visuel a rejeté la version en
## modules de kit : « elle se lit encore comme un empilement de boîtes ».
## Cause mesurée (même défaut que la ferme R2B.1) : les modules
## `Wall_UnevenBrick_Straight` sont des PLANS sans chant, toutes les arases
## tombent sur la même cote, et les gravats `SM_Dungeon_*` rendent
## terracotta sous la lumière du monde. La maçonnerie est donc désormais un
## GLB dédié (`SM_Watchtower_Ruin.glb`, générateur
## `make_watchtower_ruin.py`, même famille de formes que `SM_Farm_Ruins`,
## le précédent accepté) : quatre murs d'ÉPAISSEUR réelle aux arases
## 8,95 / 6,45 / 5,85 / 3,05 m rompues en gradins d'assise, brèche
## nord-est qui reste l'ENTRÉE, volées d'escalier INTÉGRÉES à la
## maçonnerie, corbeaux et bouts de solives des deux planchers disparus,
## talus d'éclats et pans de mur tombés entiers. La pierre est celle du
## monde : cartes `T_UnevenBrick_*` du kit (recette de la ferme), teinte
## plus froide — la tour a quinze hivers de plus que la ferme.
##
## L'IMPLANTATION, LES CONTRATS ET LES COLLIDERS NE CHANGENT PAS : site,
## fût vers CORE_X/CORE_Z, coffre de flèches dans le fût, découverte 13 m,
## appuis déclarés aux mêmes emprises. Seul le collider du mur nord est
## RACCOURCI (le mur s'arrête désormais à la brèche : un corps au-delà du
## mur serait un mur fantôme dans l'entrée).
class_name WatchtowerRuinPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")
const TOUR_SCENE: PackedScene = preload(
	"res://assets/architecture/watchtower/SM_Watchtower_Ruin.glb")

## Demi-entraxe des murs du fût (le GLB est modélisé sur les axes ±2,0 m,
## épaisseur 0,45 m — les cotes des colliders).
const HALF: float = 2.0
## Centre du fût, en local. Sa face est tombe alors à x = −0,2, soit
## 3,8 m avant le premier mètre de pente (mesuré à r = 4).
const CORE_X: float = -2.2
const CORE_Z: float = 0.4
## Enfoncement du GLB dans le sol : une assise enterrée — un mur posé SUR
## l'herbe se lit comme un meuble (leçon du pignon de la ferme, R2B.2).
const ENFONCEMENT: float = 0.28

## Cartes du kit branchées sur les matériaux du GLB (recette de la ferme,
## R2B.2 : la couleur plate du générateur n'est pas une matière). La teinte
## multiplie la carte : plus froide et plus grise que la ferme (0,86 /
## 0,70 / 0,54) — quinze hivers de plus face au vent d'ouest.
const TEX_DIR: String = "res://assets/environment/village/"
const TEXTURES_PAR_MATERIAU: Dictionary = {
	"MAT_Tower_Stone": ["T_UnevenBrick_BaseColor", "T_UnevenBrick_Normal",
		"T_UnevenBrick_Roughness"],
	"MAT_Tower_Wood": ["T_WoodTrim_BaseColor", "T_WoodTrim_Normal",
		"T_WoodTrim_Roughness"],
	"MAT_Tower_StoneInner": ["T_UnevenBrick_BaseColor", "T_UnevenBrick_Normal",
		"T_UnevenBrick_Roughness"],
}
## RECALÉ SUR CAPTURE (itération 1, `lot1r/voie_b/iter/tour1/`) : à
## (0,78 / 0,70 / 0,60) la maçonnerie sortait BRUN ROUILLE — plus chaude
## que la pierre du kit qu'elle prolonge. Remontée et refroidie d'un cran.
## Le parement INTÉRIEUR est volontairement plus sombre : sous llvmpipe
## l'intérieur vu par la brèche rendait aussi clair que l'extérieur au
## soleil, et la tour éventrée se relisait comme une boîte fermée.
const TEINTES_TEXTUREES: Dictionary = {
	"MAT_Tower_Stone": Color(0.90, 0.86, 0.78),
	"MAT_Tower_Wood": Color(0.52, 0.43, 0.34),
	# Itération 2 : à 0,50 l'intérieur rendait un aplat NOIR sans matière.
	# Remonté pour garder la lecture « ombre portée » sans perdre la pierre.
	"MAT_Tower_StoneInner": Color(0.63, 0.61, 0.57),
}
## Les pièces TOMBÉES (talus, pans, bloc de couronne) : APLAT painterly,
## SANS texture. Mesuré en itérations 2 à 4 : la carte de mur box-projetée
## sur des facettes de 0,3 m échantillonne surtout le mortier et ses
## rehauts peints — les éclats sortaient « chocolat glacé ». La famille
## qui s'intègre au terrain est celle des falaises (aplat + facettes),
## `BRIEF_COMMUN` §matériaux ; on la rejoint. Valeur à mi-chemin entre le
## mur clair et les blocs sombres gelés du pad.
const ALBEDO_TOMBEE: Color = Color(0.40, 0.38, 0.345)
## Le caillou de pied : gris froid neutre, sans ocre. Il n'est pas de la
## maçonnerie — c'est la roche du plateau, et elle ne doit ni tirer chaud
## (la famille `SM_Dungeon_*` rejetée) ni tirer teal (la surface « grass »
## des pièces `cliff_*` / `rock_large*`, cause mesurée ci-dessous).
const TONE_PIED: Color = Color(0.66, 0.66, 0.63)

static var _cache_materiaux: Dictionary = {}


func default_place_id() -> StringName:
	return &"valley.poi.watchtower_ruin.01"


func _build() -> void:
	# UN SEUL niveau d'assise pour tout le fût : un bâtiment ne suit pas le
	# sol sommet par sommet, il se pose sur son point haut et comble par le
	# bas (même règle que la ferme). Les quatre angles déclarent en
	# revanche leur appui RÉEL, chacun à sa hauteur.
	var base_y: float = -INF
	for corner: Vector2 in [Vector2(-HALF, -HALF), Vector2(HALF, -HALF),
			Vector2(-HALF, HALF), Vector2(HALF, HALF)]:
		var foot: Vector3 = _seated(CORE_X + corner.x, CORE_Z + corner.y)
		declare_support(foot)
		base_y = maxf(base_y, foot.y)

	var core: Node3D = Node3D.new()
	core.name = "Fut"
	add_child(core)
	core.position = Vector3(CORE_X, base_y, CORE_Z)

	# LE FÛT — un seul asset, arases rompues, brèche à l'est-nord-est.
	_piece_tour(core, "SM_Watchtower_Shell",
		Vector3(0.0, -ENFONCEMENT, 0.0), Vector3.ZERO)
	_interieur(core)
	_ascension(core)
	_talus(base_y)
	_vegetation_de_fissure(core)

	# — Découverte et récompense. Le coffre est DANS le fût, au pied de la
	# brèche : c'est le seul endroit du lieu qui soit à la fois abrité et
	# atteignable de plain-pied. L'approche vient de l'est, par la brèche
	# elle-même — pas par un mur.
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Tour de guet"
	poi.region = &"r04_falaises_du_couchant"
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Decouverte_forme"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 13.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.CHEST,
		_seated(CORE_X + 0.9, CORE_Z - 0.7) + Vector3(0.0, 0.1, 0.0),
		Vector3(CORE_X + 3.4, 0.0, CORE_Z - 1.2))


## L'INTÉRIEUR, visible par la brèche : les volées d'escalier vivent dans
## le GLB (scellées à la maçonnerie) ; restent les dalles du sol d'origine,
## enfoncées — un intérieur qui a un sol n'est pas un tube vide.
func _interieur(core: Node3D) -> void:
	K.module(core, &"Floor_UnevenBrick", Vector3(-0.5, 0.04, -0.4), 0.0, 1.0,
		K.TONE_STONE)
	K.module(core, &"Floor_UnevenBrick", Vector3(0.7, 0.04, 1.0), 0.0, 1.0,
		K.TONE_STONE)


## L'ASCENSION EST PHYSIQUE, PAS DÉCLARÉE (arbitrage « La vigie
## retrouvée », condition 1). Les marches du GLB sont décoratives : ce qui
## porte la capsule, ce sont ces quatre corps — deux rampes inclinées qui
## suivent la ligne des nez de marche (39,0° et 31,9°, sous les 46° du
## contrôleur), le palier tournant, et la dalle de la vigie à 3,05 m.
## Toutes les cotes sont en local au fût, enfoncement du GLB compris.
## La redescente est toujours possible (condition 2) : par les rampes, ou
## en sautant des bords libres de la vigie — 3,05 m, sous le seuil de
## dégâts de chute (~6 m, §8.2). Aucune barrière invisible (condition 3) :
## les seuls garde-corps sont les murs ouest et sud eux-mêmes.
func _ascension(core: Node3D) -> void:
	var e: float = ENFONCEMENT
	_collider_rampe(core, "Guet_rampe_1",
		Vector3(1.05, 0.0 - e, -1.385), Vector3(-1.05, 1.70 - e, -1.385), 0.80)
	_collider_rampe(core, "Guet_rampe_2",
		Vector3(-1.375, 1.76 - e, -1.45), Vector3(-1.375, 3.05 - e, 0.62), 0.75)
	K.collider_box(core, "Guet_palier_tournant",
		Vector3(-1.15, 1.52 - e, -1.42), Vector3(0.90, 0.20, 0.70))
	K.collider_box(core, "Guet_vigie",
		Vector3(-1.065, 2.94 - e, 1.19), Vector3(1.42, 0.22, 1.18))


## Un corps incliné dont la FACE SUPÉRIEURE passe par le segment
## depart→arrivee (la ligne des nez de marche). La base est construite,
## jamais devinée : axe long = le segment, latérale = horizontale
## perpendiculaire, normale = leur produit — redressée vers le haut.
func _collider_rampe(parent: Node3D, nom: String, depart: Vector3,
		arrivee: Vector3, largeur: float) -> void:
	var axe: Vector3 = (arrivee - depart).normalized()
	var laterale: Vector3 = axe.cross(Vector3.UP).normalized()
	var normale: Vector3 = laterale.cross(axe).normalized()
	if normale.y < 0.0:
		normale = -normale
		laterale = -laterale
	var corps: StaticBody3D = StaticBody3D.new()
	corps.name = nom
	corps.collision_layer = 1
	corps.collision_mask = 0
	var forme: CollisionShape3D = CollisionShape3D.new()
	forme.name = nom + "_forme"
	var boite: BoxShape3D = BoxShape3D.new()
	var epaisseur: float = 0.24
	boite.size = Vector3(largeur, epaisseur,
		depart.distance_to(arrivee) + 0.30)
	forme.shape = boite
	corps.add_child(forme)
	corps.basis = Basis(laterale, normale, axe)
	corps.position = (depart + arrivee) * 0.5 - normale * (epaisseur * 0.5)
	parent.add_child(corps)


## LE TALUS ET LES BLOCS PRIS DANS LA PENTE — la seconde et la troisième
## masse de la silhouette. Tout vient du même GLB que la tour : le talus
## est fait des MÊMES pierres, les pans tombés correspondent aux manques
## visibles dans les murs (le mur est n'a plus qu'une travée, le nord
## s'arrête à la brèche — voilà où est parti le reste).
func _talus(base_y: float) -> void:
	# Le talus d'éclats, au pied de la brèche, en éventail vers l'est.
	var talus_at: Vector3 = _seated(1.9, -0.3)
	_piece_tour(self, "SM_Watchtower_Talus", talus_at, Vector3.ZERO, "tombee")
	declare_support(talus_at)
	# Deux pans de mur TOMBÉS entiers : la maçonnerie du haut est retombée
	# par plaques, elle ne s'est pas dissoute en cailloux. Enfoncés de
	# 0,20 m : ils émergent sous la hauteur de marche — on les enjambe.
	# Chaque pan DÉCLARE son assise : ce sont eux qui portent l'emprise au
	# sud (z = +3,2) et au nord (z = −3,15).
	#
	# LOT 1.R, FINITION 2 — « une dalle pavée coupée par le bord droit du
	# cadre, sans liaison lisible avec la tour » (audit, points 11 et B-t4-2,
	# signalé trois fois). Deux causes, deux corrections :
	#   a. « PAVÉE » venait de la carte de brique box-projetée sur la plaque ;
	#      elle est traitée par la variante `tombee` en aplat (commit
	#      précédent) — la plaque est désormais de la pierre, pas un dallage.
	#   b. « SANS LIAISON » venait de l'isolement : 2,7 m d'herbe rase entre
	#      le talus et la plaque, et rien entre les deux. Le pan recule de
	#      0,65 m vers l'ouest (il quitte le bord du cadre et perd du poids
	#      apparent), son grand axe pointe vers la brèche, et une TRAÎNÉE de
	#      chutes le relie au talus. On lit alors une coulée d'effondrement,
	#      pas une dalle posée.
	#   c. RESTE APRÈS PREMIÈRE CAPTURE (tour5) : dégrisée et reliée, la
	#      plaque lisait encore « banc de pierre » — une grande face SUPÉRIEURE
	#      plate de 2,3 × 2,7 m au soleil, bordée du côté DROIT de son contour,
	#      qui est le seul bord non déchiré du maillage (`pan_tombe` :
	#      `[(0,0)] + profil + [(longueur,0)]`, la ligne y = 0 est rectiligne).
	#      Trois corrections mesurables : le lacet tourne de 90° pour présenter
	#      le bord DÉCHIRÉ à la caméra, le roulis passe de 4° à 13° pour que
	#      la grande face cesse d'être horizontale (elle cesse alors de
	#      recevoir le soleil à plat, ce qui la faisait sortir sable clair),
	#      et l'enfoncement passe de 0,20 à 0,34 m.
	var pan_a: Vector3 = _seated(1.55, -3.15)
	_piece_tour(self, "SM_Watchtower_Slab_A",
		pan_a + Vector3(0.0, -0.34, 0.0),
		Vector3(deg_to_rad(13.0), deg_to_rad(142.0), 0.0), "tombee")
	declare_support(pan_a)
	_trainee_de_chute()
	var pan_b: Vector3 = _seated(4.1, 3.2)
	_piece_tour(self, "SM_Watchtower_Slab_B",
		pan_b + Vector3(0.0, -0.20, 0.0),
		Vector3(deg_to_rad(-3.0), deg_to_rad(-104.0), 0.0), "tombee")
	declare_support(pan_b)
	# LE BLOC DE COURONNE, resté pris sous la lèvre. À 6,4 m à l'est le sol
	# est déjà 2,6 m plus bas : il est franchement dans la pente, et c'est
	# lui qui raconte que la tour est tombée dans le vide.
	var bloc: Vector3 = _seated(6.4, -0.6)
	_piece_tour(self, "SM_Watchtower_CrownBlock",
		bloc + Vector3(0.0, -0.30, 0.0),
		Vector3(0.0, deg_to_rad(118.0), deg_to_rad(-14.0)), "tombee")
	declare_support(bloc)
	# LE CAILLOU DE PIED. Il déclare son assise : c'est le point porté le plus
	# à l'ouest, et il tient le tiers bas de l'axe X pour D2.
	#
	# LOT 1.R, FINITION 3 — « un petit disque TEAL plat posé dans l'herbe
	# derrière la tour » (audit, points 12 et B-t4-3, signalé trois fois).
	# IDENTIFIÉ, pas deviné : la sonde écran le place à 11,5 m de la caméra
	# joueur, emprise pixel 725-892 × 364-413, qui couvre le rectangle
	# incriminé 790-840 × 365-385 — et aucun autre nœud ne le couvre. Le
	# coupable est ce caillou, et la cause est dans son glTF :
	# `rock_largeC.glb` porte DEUX matériaux, `dirt` et **`grass`**, et la
	# surface « grass » des kits Kenney rend menthe/sarcelle sous la lumière
	# de ce monde (audit, point 16 transverse : même teal en chapeau de
	# crête, en vasque et ici en disque au sol). Le caillou était donc une
	# galette brune de 1,90 m posée sur une flaque verte plate.
	#
	# Corrigé par CHANGEMENT DE FAMILLE, pas par teinte : `Rock_Medium_2`
	# (atlas `Rocks_Diffuse`, matériau unique « Rocks », rendu gris neutre —
	# BRIEF_COMMUN §matériaux) n'a pas de surface d'herbe à rendre teal.
	# Échelle : natif 3,05 × 1,90 × 2,48 m, `KitScale` ne le corrige pas
	# (facteur 1,0) ; à 0,30 il fait 0,91 × 0,57 × 0,74 m — même hauteur
	# apparente que la galette qu'il remplace, donc ni collider nouveau ni
	# changement de franchissement, mais une vraie masse au lieu d'un disque.
	var pied: Vector3 = _seated(-5.1, -3.6)
	K.module(self, &"Rock_Medium_2", pied, -21.0, 0.30, TONE_PIED)
	declare_support(pied)
	_collisions(base_y)


## LA TRAÎNÉE DE CHUTE — trois poignées d'éclats entre le talus et le pan
## tombé nord. C'est le MÊME maillage que le talus (`SM_Watchtower_Talus`,
## un éventail de neuf éclats), réduit et retourné : la matière est donc de
## la maçonnerie de la tour par construction, et non un caillou du kit posé
## là pour combler. Aucun collider : à 0,3 et 0,2 d'échelle ces chutes font
## 7 et 5 cm de haut, très en dessous de la hauteur de marche.
func _trainee_de_chute() -> void:
	for spec: Array in [[2.05, -1.75, 0.34, 41.0], [1.35, -2.45, 0.26, -68.0],
			[2.55, -2.60, 0.21, 133.0]]:
		var at: Vector3 = _seated(float(spec[0]), float(spec[1]))
		var chute: Node3D = _piece_tour(self, "SM_Watchtower_Talus",
			at + Vector3(0.0, -0.06, 0.0),
			Vector3(0.0, deg_to_rad(float(spec[3])), 0.0), "tombee",
			"Chute_%d" % int(float(spec[2]) * 100.0))
		chute.scale = Vector3.ONE * float(spec[2])


## Collisions : QUATRE murs et TROIS masses, jamais un corps par panneau.
## Mêmes volumes qu'avant la corrective, à une exception près : le mur
## nord s'arrête désormais à la brèche (x local +0,95), son collider aussi
## — un corps au-delà du mur serait un mur fantôme dans l'entrée.
func _collisions(base_y: float) -> void:
	var y0: float = base_y
	K.collider_box(self, "Guet_mur_ouest",
		Vector3(CORE_X - HALF, y0 + 4.55, CORE_Z), Vector3(0.45, 9.1, 4.45))
	# Mur nord : de l'angle ouest à la brèche — centre x = −0,6375 local au
	# fût, longueur 3,175 m.
	K.collider_box(self, "Guet_mur_nord",
		Vector3(CORE_X - 0.64, y0 + 3.13, CORE_Z - HALF),
		Vector3(3.18, 6.25, 0.45))
	K.collider_box(self, "Guet_mur_sud",
		Vector3(CORE_X, y0 + 2.95, CORE_Z + HALF), Vector3(4.45, 5.9, 0.45))
	# Mur est : la seule travée debout. La brèche, au nord, reste ouverte —
	# c'est l'entrée, elle ne doit rien porter.
	K.collider_box(self, "Guet_mur_est",
		Vector3(CORE_X + HALF, y0 + 1.6, CORE_Z + 1.0),
		Vector3(0.45, 3.2, 2.2))
	# Le talus ne couvre plus que la moitié SUD du tas : le couloir d'entrée
	# (l'axe de la brèche, z −1,5..−0,4) reste marchable — la sonde
	# d'ascension a mesuré une contremarche de 0,68 m sur l'ancien volume,
	# au-dessus du step_height. Les petits éclats du couloir (≤ 0,2 m) ne
	# portent pas de corps, comme les cailloux du kit.
	K.collider_box(self, "Guet_talus",
		_seated(2.2, 0.9) + Vector3(0.0, 0.34, 0.0), Vector3(3.6, 0.68, 2.6),
		18.0)
	K.collider_box(self, "Guet_bloc_pente",
		_seated(6.4, -0.6) + Vector3(0.0, 1.4, 0.0), Vector3(2.2, 2.8, 2.3),
		118.0)


## VÉGÉTATION DE FISSURE (r04 : « minérale, végétation de fissure »). Elle
## va au NORD et dans les gravats, jamais à l'ouest : la paroi ouest est la
## face escaladable et r04 exige 5 m de dégagement dorsal en mode Climb.
func _vegetation_de_fissure(core: Node3D) -> void:
	# Le lierre reprend la face nord. Piège mesuré (ferme, R2B.1) :
	# `Prop_Vine*` a son ancrage à 2,12 m au-dessus du bas de sa géométrie
	# et `KitPlacement.seat()` ne corrige PAS vers le haut — posé à 0, il
	# pend sous le lieu.
	K.module(core, &"Prop_Vine1", Vector3(-1.0, 2.07, -HALF - 0.1), 180.0, 1.0,
		K.TONE_PLANT)
	K.module(self, &"Bush_Common", _seated(-2.6, -5.2), 34.0, 0.9, K.TONE_PLANT)
	K.module(self, &"Bush_Common", _seated(0.6, -4.4), -76.0, 0.7, K.TONE_PLANT)
	# LOT 1.R, FINITION 1 — « les pétales violets géants » (audit, points 10
	# et B-t4-1, signalé trois fois, confirmé depuis le palier). C'était
	# `Plant_7` : 1,05 × 0,25 × 0,96 m au glTF, matériau unique « Leaves »
	# rendu VIOLET saturé, posé à plat — quatre pétales d'un demi-mètre
	# chacun dans l'herbe, à une échelle qu'aucune plante de ce monde n'a.
	# Il n'appartenait à aucun langage du lieu (ni gravat, ni fissure) et il
	# tirait le regard hors de la brèche. Une touffe d'herbe sèche prend sa
	# place : même rôle de rupture au pied des gravats, aucun accent saturé.
	K.module(self, &"Grass_Common_Tall", _seated(1.9, -2.2), 18.0, 0.9,
		K.TONE_PLANT)


## Extrait UNE pièce du GLB de la tour (recette `_piece_ferme` de la
## ferme) : l'instance est élaguée AVANT d'entrer dans l'arbre et porte le
## nom de la pièce — Godot rebaptise les homonymes en `@Node3D@366` et plus
## aucun test ne peut les désigner.
## `nom` sert quand la MÊME pièce est instanciée plusieurs fois (la traînée
## de chute reprend le talus) : sans nom distinct, `add_child` rebaptise les
## homonymes en `@Node3D@366` et plus aucun test ne peut les désigner
## (`scripts/CLAUDE.md`). Il est posé AVANT l'entrée dans l'arbre, sinon la
## collision de noms a déjà eu lieu.
func _piece_tour(parent: Node3D, piece: String, at: Vector3,
		rot: Vector3, variante: String = "mur", nom: String = "") -> Node3D:
	var instance: Node3D = TOUR_SCENE.instantiate() as Node3D
	instance.name = piece
	for enfant: Node in instance.get_children():
		if String(enfant.name) != piece:
			instance.remove_child(enfant)
			enfant.free()
		else:
			enfant.name = "%s_maille" % instance.name
	if not nom.is_empty():
		instance.name = nom
	parent.add_child(instance)
	instance.position = at
	instance.rotation = rot
	_peindre_glb(instance, variante)
	return instance


## Branche les cartes du kit sur les matériaux plats du GLB — matériaux
## DUPLIQUÉS et mis en cache, jamais de mutation d'une ressource importée
## (recette `_peindre_glb` de la ferme, R2B.2).
func _peindre_glb(racine: Node3D, variante: String = "mur") -> void:
	for node: Node in racine.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var base: StandardMaterial3D = instance.get_active_material(
				surface) as StandardMaterial3D
			if base == null:
				continue
			var famille: String = base.resource_name
			var cle: String = "guet|%s|%d" % [variante, base.get_instance_id()]
			var mat: StandardMaterial3D = \
				_cache_materiaux.get(cle) as StandardMaterial3D
			if mat == null:
				mat = base.duplicate() as StandardMaterial3D
				mat.roughness = maxf(mat.roughness, 0.95)
				mat.metallic_specular = 0.1
				if variante == "tombee":
					# Aplat painterly : la géométrie à facettes porte la
					# lecture, pas la carte (voir ALBEDO_TOMBEE).
					mat.albedo_color = ALBEDO_TOMBEE
				elif TEXTURES_PAR_MATERIAU.has(famille):
					var noms: Array = TEXTURES_PAR_MATERIAU[famille] as Array
					mat.albedo_texture = load(
						TEX_DIR + String(noms[0]) + ".png") as Texture2D
					var nrm: Texture2D = load(
						TEX_DIR + String(noms[1]) + ".png") as Texture2D
					if nrm != null:
						mat.normal_enabled = true
						mat.normal_texture = nrm
						mat.normal_scale = 0.65
					mat.roughness_texture = load(
						TEX_DIR + String(noms[2]) + ".png") as Texture2D
					mat.roughness = 1.0
					mat.albedo_color = TEINTES_TEXTUREES[famille] as Color
				_cache_materiaux[cle] = mat
			instance.set_surface_override_material(surface, mat)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
