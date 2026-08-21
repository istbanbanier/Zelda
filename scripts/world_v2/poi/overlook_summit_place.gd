## LE BELVÉDÈRE DU GUETTEUR (`valley.poi.overlook_summit.01`, r07) — le
## point haut de l'est. On y monte, et la montée DONNE L'ARC.
##
## CE LIEU EST BÂTI AUTOUR D'UN VIDE, pas d'un volume. Trois masses
## rocheuses ouvrent entre elles une brèche de 4,4 m tournée vers
## l'ouest-sud-ouest : on la franchit, et la vallée entière s'ouvre d'un
## coup sur la crête de départ. Le lieu ne se lit donc pas comme un objet
## posé sur une butte — il se lit comme un passage.
##
## TROIS CONTRAINTES MESURÉES ONT DÉCIDÉ DE L'IMPLANTATION, et aucune n'est
## négociable :
##
##  1. `cam05_belvedere_crete` EST POSÉE ICI. Elle vit à (166 ; 54), soit
##     2,83 m du site, et vise (0, 26, 170). Sa direction locale vaut
##     (−0,82 ; +0,573) : tout point local à x > 0 lui est DERRIÈRE
##     (produit scalaire négatif). Toute la masse va donc à l'est, et la
##     brèche s'ouvre à l'ouest-sud-ouest — ce qui est exactement le
##     « regard de retour » que le layout demande à ce lieu.
##  2. LA ROUTE 2 TRAVERSE LE SOMMET. `heights_route` porte le waypoint
##     littéral [168, 52], entre [158, 42] au nord-ouest et [190, 30] au
##     nord-est. Le filet des lieux échantillonne la route au mètre et
##     refuse tout collider dont l'emprise XZ passe à moins de 1,2 m
##     (`ROUTE_CLEAR_M` du TEST — 1,2 m, et non les 2,3 m de la
##     végétation). Les distances perpendiculaires à la diagonale
##     (0,0) → (+22,−22) sont donc calculées, pas estimées : corne 7,4 m,
##     aile nord 7,8 m, aile sud 8,2 m, épaule 7,8 m.
##  3. LA BUTTE SE MONTE À PIED. `world_v2_heightmap.gd` porte la trace de
##     l'incident : à rayon 22, l'anneau du belvédère tombait de 5 m en
##     quelques mètres et « le parcours réel y restait cloué ». Le rayon a
##     été porté à 30 et le fondu à 12 m. Profils mesurés depuis le
##     centre : plat jusqu'à r ≈ 10, puis −3,2 m à 15 m au sud-sud-est et
##     −6,1 m à 20 m à l'ouest-sud-ouest. L'ancre de récompense déclare
##     donc `requires_traversal = false` : prétendre qu'il faut grimper
##     serait faux, et un filet qui exige alors un scénario physique
##     rougirait pour une raison inventée.
##
## AUCUN CAIRN. Empiler des blocs pour marquer un sommet est précisément
## « l'empilement de blocs » reproché deux fois par le lead. La marque du
## sommet est une masse unique et penchée, plus haute que tout ce qui
## l'entoure, plus un vide qui la traverse.
class_name OverlookSummitPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## Roche des hauteurs : plus froide et plus grise que l'ocre des ruines,
## comme le veut r07 (« minérale, herbes sèches »).
const TONE_CREST: Color = Color(0.86, 0.83, 0.76)
const TONE_LEDGE: Color = Color(0.90, 0.86, 0.78)
## Herbe sèche du sommet : le vert de la prairie n'y monte pas.
const TONE_DRY: Color = Color(0.74, 0.70, 0.48)


func default_place_id() -> StringName:
	return &"valley.poi.overlook_summit.01"


func _build() -> void:
	# — LA CORNE. Une seule masse, penchée vers le vide, seul point aigu du
	# sommet : c'est elle qui se voit d'en bas et qui donne envie de monter.
	# `SM_Dungeon_CaveRock` mesure 2,64 × 4,35 × 2,81 m ; à 1,45 elle fait
	# 3,83 × 6,31 × 4,07, soit près de trois fois la taille du héros.
	var corne_at: Vector3 = _seated(6.5, 4.0)
	var corne: Node3D = K.module(self, &"SM_Dungeon_CaveRock", corne_at, 28.0,
		1.45, TONE_CREST)
	if corne != null:
		# Le fruit penche vers l'ouest-sud-ouest, du côté du vide : une
		# roche de crête est taillée par le vent dominant, elle ne se tient
		# pas droite.
		corne.rotation.z = deg_to_rad(9.0)
	declare_support(corne_at)

	# — LES DEUX AILES, qui ouvrent la brèche. Elles ne sont ni de la même
	# famille, ni de la même hauteur, ni au même azimut : deux fins
	# identiques en vis-à-vis feraient une porte, et une porte se lit
	# construite.
	var aile_n: Vector3 = _seated(9.5, 1.5)
	var nord: Node3D = K.module(self, &"SM_Dungeon_CaveWallTop", aile_n, 118.0,
		1.15, TONE_CREST)
	if nord != null:
		nord.rotation.z = deg_to_rad(-11.0)
	declare_support(aile_n)

	var aile_s: Vector3 = _seated(4.0, 7.6)
	var sud: Node3D = K.module(self, &"SM_Dungeon_CaveWallHalf", aile_s, 200.0,
		0.9, TONE_CREST)
	if sud != null:
		sud.rotation.z = deg_to_rad(14.0)
	declare_support(aile_s)

	# — L'ÉPAULE : deux blocs DEMI-ENTERRÉS au bord de la rupture sud, qui
	# forment une marche puis une tablette. Le sol est encore plat à 8,8 m
	# (mesuré) et casse deux mètres plus loin : la tablette est donc juste
	# au bord, et l'arc y est posé face au vide.
	var marche: Vector3 = _seated(1.0, 6.2)
	K.module(self, &"Rock_Medium_1", marche + Vector3(0.0, -0.90, 0.0), 200.0,
		1.0, TONE_LEDGE)
	var socle: Vector3 = _seated(2.6, 8.4)
	K.module(self, &"Rock_Medium_2", socle + Vector3(0.0, -0.75, 0.0), 41.0,
		1.0, TONE_LEDGE)
	declare_support(socle)
	# La tablette proprement dite : une dalle plate coincée entre la corne
	# et l'épaule. C'est le seul plan horizontal du lieu, donc le seul
	# endroit où poser une arme sans qu'elle ait l'air tombée.
	var tablette: Vector3 = _seated(3.8, 5.6)
	# 0,34, pas 1,6 : `KitScale` applique déjà ×4,83 à `rock_largeC`
	# (0,321 m natif → 1,55 m de cible) et l'échelle d'appel s'y MULTIPLIE.
	# 0,34 donne une dalle de 1,74 × 0,53 × 1,66 m — une tablette, pas un
	# rocher de huit mètres.
	K.module(self, &"rock_largeC", tablette + Vector3(0.0, 0.34, 0.0), 74.0,
		0.34, TONE_LEDGE)
	declare_support(tablette)

	# — LES ÉCLATS ET L'HERBE SÈCHE. Peu, et jamais au centre : le sommet
	# doit rester dégagé, on y arrive par la route et on en repart par elle.
	K.module(self, &"rock_smallB", _seated(8.2, 6.6), 37.0, 1.05, TONE_CREST)
	K.module(self, &"rock_smallB", _seated(5.4, 9.6), -62.0, 0.75, TONE_CREST)
	K.module(self, &"Bush_Common", _seated(7.8, 8.4), 22.0, 0.62, TONE_DRY)
	K.module(self, &"Bush_Common", _seated(11.0, 4.2), -48.0, 0.5, TONE_DRY)
	K.module(self, &"Grass_Wispy_Tall", _seated(3.0, 10.2), 15.0, 1.0, TONE_DRY)
	K.module(self, &"Grass_Wispy_Tall", _seated(9.0, 7.0), -30.0, 1.0, TONE_DRY)

	_collisions()

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Belvédère du guetteur"
	poi.region = &"r07_hauteurs_de_l_orient"
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Decouverte_forme"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 15.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	# L'arc est POSÉ SUR LA TABLETTE, pas jeté dans l'herbe : une arme qu'on
	# a laissée à un poste de guet a été déposée. L'approche vient de la
	# brèche, c'est-à-dire de l'ouest-sud-ouest.
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.WEAPON,
		tablette + Vector3(0.0, 0.52, 0.0), Vector3(1.4, 0.0, 3.4))


## Trois volumes seulement, et tous à ≥ 3,5 m de la diagonale de route.
## L'épaule reçoit UN corps pour ses deux blocs : ils forment une marche
## continue, et deux boîtes accolées créeraient une arête où l'on se cogne.
func _collisions() -> void:
	K.collider_box(self, "Belvedere_corne",
		_seated(6.5, 4.0) + Vector3(0.0, 3.0, 0.0), Vector3(3.4, 6.0, 3.6),
		28.0)
	K.collider_box(self, "Belvedere_aile_nord",
		_seated(9.5, 1.5) + Vector3(0.0, 2.4, 0.0), Vector3(4.4, 4.8, 1.4),
		118.0)
	K.collider_box(self, "Belvedere_aile_sud",
		_seated(4.0, 7.6) + Vector3(0.0, 1.7, 0.0), Vector3(1.8, 3.4, 1.6),
		200.0)
	K.collider_box(self, "Belvedere_epaule",
		_seated(1.8, 7.3) + Vector3(0.0, 0.55, 0.0), Vector3(4.6, 1.1, 3.6),
		24.0)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
