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
## LA RUINE EST MOTIVÉE, comme celle de la ferme : la tour s'est ouverte
## du côté où le sol se dérobe. L'angle nord-est manque, la brèche est de
## ce côté, le talus s'étale de ce côté, et deux blocs de la couronne sont
## restés pris dans la pente sous la lèvre. Les murs ouest et nord, eux,
## portent encore et montent le plus haut.
##
## POURQUOI PAS UN FÛT ROND. Un tambour octogonal de huit panneaux de 2 m
## est une répétition équidistante, ce que `WORLD_V2_POI_CONTRACTS.md` §4
## interdit explicitement — et huit fois le même panneau au même azimut se
## lit comme un empilement, exactement le reproche déjà porté deux fois par
## le lead. Le carré, lui, autorise trois assises INÉGALES (7, 4 puis 2
## panneaux) et une arase brisée : la silhouette est une diagonale, pas un
## anneau.
##
## PIÈGES CONSIGNÉS APPLIQUÉS. `Wall_UnevenBrick_Straight` porte sa face
## de brique en +Z local (inspection glTF : bbox z ∈ [−0,314 ; +0,092]) —
## donc yaw 270° pour un mur OUEST et 90° pour un mur EST, jamais
## l'inverse, faute de quoi le plâtre sort dehors (erreur mesurée sur la
## ferme, R2B.1). `Prop_Vine1` a son ancrage à 2,12 m AU-DESSUS du bas de
## sa géométrie : posé à y = 0 il pend sous le lieu, d'où le +2,07 ci-dessous.
class_name WatchtowerRuinPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## Module de mur mesuré : 2,00 × 3,1227 × 0,4065 m, base à y = 0.
const MODULE_L: float = 2.0
const COURSE_H: float = 3.1227
## Demi-emprise du fût : quatre mètres de côté, deux panneaux par face.
const HALF: float = 2.0
## Centre du fût, en local. Sa face est tombe alors à x = −0,2, soit
## 3,8 m avant le premier mètre de pente (mesuré à r = 4).
const CORE_X: float = -2.2
const CORE_Z: float = 0.4

## Pierre du guet : plus froide et plus grise que celle de la ferme — la
## tour est plus vieille, elle a pris quinze hivers de plus face au vent
## d'ouest. Reste dans la famille ocre de la bible §1.4.
const TONE_TOWER: Color = Color(0.80, 0.72, 0.62)
const TONE_FALLEN: Color = Color(0.72, 0.66, 0.60)


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

	_course_basse(core)
	_course_mediane(core)
	_couronne_rompue(core)
	_interieur(core)
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


## ASSISE BASSE (0 → 3,12 m) — sept panneaux. Le huitième, à l'angle
## nord-est, est la BRÈCHE : c'est par là que la tour s'est vidée, et
## c'est par là qu'on entre.
func _course_basse(core: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		_panneau(core, Vector3(-HALF, 0.0, side * (MODULE_L * 0.5)), 270.0)
		_panneau(core, Vector3(side * (MODULE_L * 0.5), 0.0, HALF), 0.0)
		_panneau(core, Vector3(side * (MODULE_L * 0.5), 0.0, -HALF), 180.0)
	# Mur EST : une seule travée, côté sud. Au nord, la brèche.
	_panneau(core, Vector3(HALF, 0.0, MODULE_L * 0.5), 90.0)
	# Chaînages : trois angles sur quatre. Le nord-est est tombé avec la
	# brèche — un chaînage intact au-dessus d'un trou redonnerait le
	# rectangle qu'on vient d'ouvrir (leçon R2B.2 de la ferme).
	for corner: Vector2 in [Vector2(-HALF, -HALF), Vector2(-HALF, HALF),
			Vector2(HALF, HALF)]:
		K.module(core, &"Corner_Exterior_Brick",
			Vector3(corner.x, 0.0, corner.y), 0.0, 1.0, K.TONE_STONE)


## ASSISE MÉDIANE (3,12 → 6,25 m) — quatre panneaux : l'ouest entier, une
## travée au nord et une au sud. Le mur est n'existe plus à cette hauteur.
func _course_mediane(core: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		_panneau(core, Vector3(-HALF, COURSE_H, side * (MODULE_L * 0.5)), 270.0)
	_panneau(core, Vector3(-MODULE_L * 0.5, COURSE_H, HALF), 0.0)
	_panneau(core, Vector3(-MODULE_L * 0.5, COURSE_H, -HALF), 180.0)
	for corner: Vector2 in [Vector2(-HALF, -HALF), Vector2(-HALF, HALF)]:
		K.module(core, &"Corner_Exterior_Brick",
			Vector3(corner.x, COURSE_H, corner.y), 0.0, 1.0, K.TONE_STONE)


## COURONNE ROMPUE (6,25 → 9,12 m) — deux panneaux à l'ouest SEULEMENT, et
## ENFONCÉS de 0,25 et 0,62 m dans l'assise du dessous.
##
## C'est la correction que la ferme a payée en une revue : ses onze modules
## de mur arrivaient tous à 3,173 m, écart-type 0,050 m sur 6,4 m de
## bâtiment — « la maçonnerie ne casse nulle part », d'où le contour
## « rectangle + chapeau ». Ici les deux derniers panneaux ne montent pas à
## la même hauteur, et trois masses de gravats posées SUR les arases
## achèvent de casser la ligne. Écart d'arase attendu : 0,37 m entre les
## deux panneaux hauts, 2,87 m entre l'ouest et le nord.
func _couronne_rompue(core: Node3D) -> void:
	var enfoncements: Array[float] = [0.25, 0.62]
	for i: int in range(2):
		var side: float = -1.0 if i == 0 else 1.0
		_panneau(core, Vector3(-HALF, COURSE_H * 2.0 - enfoncements[i],
			side * (MODULE_L * 0.5)), 270.0)
	K.module(core, &"Corner_Exterior_Brick",
		Vector3(-HALF, COURSE_H * 2.0 - 0.25, -HALF), 0.0, 1.0, K.TONE_STONE)
	# Gravats POSÉS SUR les arases : ce qui reste des assises manquantes.
	# Chacun mord son arase de quelques centimètres — un bloc qui affleure
	# sans mordre se lit « décoration superposée ».
	K.module(core, &"SM_Dungeon_ArchBlock",
		Vector3(-0.35, COURSE_H * 2.0 - 0.16, -HALF + 0.05), 24.0, 0.85,
		TONE_TOWER)
	K.module(core, &"SM_Dungeon_ArchBlock",
		Vector3(-1.25, COURSE_H * 2.0 - 0.22, HALF - 0.08), -37.0, 0.72,
		TONE_TOWER)
	K.module(core, &"SM_Dungeon_RubbleSmall",
		Vector3(HALF - 0.12, COURSE_H - 0.14, MODULE_L * 0.5 + 0.2), 63.0,
		0.9, TONE_TOWER)


## L'INTÉRIEUR, visible par la brèche : deux volées d'escalier qui montent
## en tournant, et deux dalles de sol. Sans elles la tour est un tube vide,
## et un tube vide ne dit pas ce qu'était la tour.
func _interieur(core: Node3D) -> void:
	K.module(core, &"Floor_UnevenBrick", Vector3(-0.5, 0.04, -0.4), 0.0, 1.0,
		K.TONE_STONE)
	K.module(core, &"Floor_UnevenBrick", Vector3(0.7, 0.04, 1.0), 0.0, 1.0,
		K.TONE_STONE)
	# Première volée le long du mur nord, seconde contre le mur ouest, un
	# quart de tour plus haut : c'est ainsi qu'on monte dans une tour.
	K.module(core, &"Stairs_Exterior_Straight", Vector3(-0.6, 0.0, -0.85),
		90.0, 1.0, TONE_TOWER)
	K.module(core, &"Stairs_Exterior_Straight", Vector3(-0.9, 1.2, 0.75),
		180.0, 1.0, TONE_TOWER)


## LE TALUS ET LES BLOCS PRIS DANS LA PENTE — la seconde et la troisième
## masse de la silhouette.
##
## Chaque pièce est assise sur SON sol : le talus est encore sur le plat,
## mais les deux blocs de couronne sont sur une face à 57° et doivent la
## suivre, sinon l'un flotte et l'autre s'enterre (le défaut mesuré sur les
## dalles de la grotte, groupe 1).
func _talus(base_y: float) -> void:
	var pente: Node3D = Node3D.new()
	pente.name = "Talus"
	add_child(pente)
	# Sur le plat, au pied de la brèche.
	for spec: Array in [[1.6, -1.2, 41.0, 1.0], [2.9, 1.5, -68.0, 0.85]]:
		var at: Vector3 = _seated(float(spec[0]), float(spec[1]))
		K.module(pente, &"SM_Dungeon_RubbleLarge", at, float(spec[2]),
			float(spec[3]), TONE_FALLEN)
		declare_support(at)
	K.module(pente, &"SM_Dungeon_RubbleSmall", _seated(0.9, 2.6), 12.0, 0.95,
		TONE_FALLEN)
	# Deux panneaux de mur COUCHÉS : la maçonnerie du haut est retombée
	# entière par plaques, elle ne s'est pas dissoute en cailloux.
	for spec: Array in [[2.2, -3.0, 27.0, 84.0], [4.1, 3.2, -14.0, 79.0]]:
		var plaque: Node3D = K.module(self, &"Wall_UnevenBrick_Straight",
			_seated(float(spec[0]), float(spec[1])), float(spec[2]), 1.0,
			TONE_FALLEN)
		_coucher(plaque, float(spec[3]), 0.02)
	# LE BLOC DE COURONNE, resté pris sous la lèvre. À 6,4 m à l'est le sol
	# est déjà 2,6 m plus bas : il est franchement dans la pente, et c'est
	# lui qui raconte que la tour est tombée dans le vide.
	var bloc: Vector3 = _seated(6.4, -0.6)
	var caillou: Node3D = K.module(self, &"SM_Dungeon_CaveRock", bloc, 118.0,
		0.82, TONE_FALLEN)
	if caillou != null:
		caillou.rotation.z = deg_to_rad(-14.0)
	declare_support(bloc)
	# 0,37 et non 1,35 : `KitScale` corrige DÉJÀ `rock_largeC` d'un facteur
	# 4,83 (0,321 m natif → 1,55 m de cible), et l'échelle d'appel se
	# MULTIPLIE à cette correction. À 1,35 ce caillou de pied aurait fait
	# 6,9 m de large — mesure faite avant de poser, pas après capture.
	K.module(self, &"rock_largeC", _seated(-5.1, -3.6), -21.0, 0.37,
		K.TONE_DARK_STONE)
	_collisions(base_y)


## Collisions : QUATRE murs et TROIS masses, jamais un corps par panneau.
## Le filet de couloir compte les corps et leur emprise, pas les copeaux —
## et un collider par module ferait quatorze corps pour un seul volume.
func _collisions(base_y: float) -> void:
	var y0: float = base_y
	K.collider_box(self, "Guet_mur_ouest",
		Vector3(CORE_X - HALF, y0 + 4.55, CORE_Z), Vector3(0.45, 9.1, 4.45))
	K.collider_box(self, "Guet_mur_nord",
		Vector3(CORE_X, y0 + 3.13, CORE_Z - HALF), Vector3(4.45, 6.25, 0.45))
	K.collider_box(self, "Guet_mur_sud",
		Vector3(CORE_X, y0 + 3.13, CORE_Z + HALF), Vector3(4.45, 6.25, 0.45))
	# Mur est : la seule travée debout. La brèche, au nord, reste ouverte —
	# c'est l'entrée, elle ne doit rien porter.
	K.collider_box(self, "Guet_mur_est",
		Vector3(CORE_X + HALF, y0 + 1.6, CORE_Z + MODULE_L * 0.5),
		Vector3(0.45, 3.2, 2.2))
	K.collider_box(self, "Guet_talus",
		_seated(2.2, 0.1) + Vector3(0.0, 0.34, 0.0), Vector3(3.6, 0.68, 4.2),
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
	K.module(self, &"Plant_7", _seated(1.9, -2.2), 18.0, 1.0, K.TONE_PLANT)


## Un panneau de mur, teinté et tourné. La face de BRIQUE du module est en
## +Z local : yaw 0 la met au sud, 180 au nord, 270 à l'ouest, 90 à l'est.
func _panneau(core: Node3D, at: Vector3, yaw: float) -> void:
	K.module(core, &"Wall_UnevenBrick_Straight", at, yaw, 1.0, TONE_TOWER)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)

## COUCHER UNE PIÈCE, ET LA RÉASSEOIR SUR SA VRAIE EMPRISE.
##
## `KitPlacement.seat()` mesure AVANT que l'appelant n'ajoute un roulis ou un
## basculement — il ne peut donc rien pour une pièce qu'on couche ensuite. Et
## le décalage à rattraper n'est pas devinable : mesuré au glTF,
## `cliff_half_rock` a son épaisseur en +Z (bbox z ∈ [0,0815 ; 0,500]) et son
## origine sur une ARÊTE, si bien qu'un basculement de +86° l'envoie
## ENTIÈREMENT sous le sol — 11 cm visibles sur 1,06 m. `SM_Dungeon_PillarStub`
## est centré en X/Z et se comporte autrement, `Wall_UnevenBrick_Straight`
## autrement encore (z ∈ [−0,314 ; +0,092]).
##
## On ne devine donc pas : on bascule, on remesure l'emprise dans le repère du
## parent, et on enfonce de la fraction VOULUE. `enfoncement` est la profondeur
## en mètres sous le sol — zéro pose la pièce exactement dessus.
##
## (Troisième emploi dans ce lot : sa place serait `world_v2_place_kit.gd`
## selon la règle de trois. Il reste ici parce que ce fichier-là est partagé
## par les trois voies du lot et qu'une édition concurrente y coûte une fusion ;
## remonté au lead pour intégration.)
func _coucher(piece: Node3D, deg_x: float, enfoncement: float) -> void:
	if piece == null:
		return
	piece.rotation.x = deg_to_rad(deg_x)
	var boite: AABB = Transform3D(piece.transform.basis, Vector3.ZERO) \
		* KitPlacement.local_aabb(piece)
	piece.position.y -= boite.position.y + enfoncement
