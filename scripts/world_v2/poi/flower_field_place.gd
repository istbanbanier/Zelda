## LE CHAMP DES MILLE FLEURS (`valley.poi.flower_field.01`, r02) — la
## respiration, et le premier lieu que le joueur atteindra.
##
## C'EST LE SEUL LIEU DU LOT SANS MASSE VERTICALE, et c'est un choix, pas
## un manque. Trois faits mesurés l'imposent :
##
##  1. **Il a deux voisins immédiats, et ils ont déjà pris les deux
##     silhouettes disponibles.** La ferme abandonnée est à 32,2 m (un bâti
##     ruiné), l'arbre foudroyé à 36,9 m (un arbre isolé de 10,8 m, et le
##     layout en fait explicitement « le landmark de l'horizon ouest » de
##     r02). Bâtir ou planter ici, c'est doubler l'un des deux à portée de
##     regard. Le champ ne peut donc être ni un bâti, ni un arbre.
##  2. **La prairie fleurie existe déjà.** La végétation V2.2 est gelée et
##     peuple r02 en « fleurs en phrases, clairières 2-8 m ». Repeindre le
##     champ par-dessus serait doubler un tapis qui est là. Même parti que
##     l'arbre foudroyé, qui a RETIRÉ ses propres fleurs pour laisser jouer
##     la prairie gelée.
##  3. **Le layout lui donne une fonction, pas un objet** : r02 sert au
##     « premier choix de route ». Le lieu est le point où l'on décide.
##
## D'où l'identité : **une fourche**. Une ligne de dalles pâles à demi
## avalées descend du sud-est — de la crête de départ, dont le sol monte
## de +3,7 m à 16 m et +7,3 m à 20 m dans cette direction — arrive au pied
## d'une pierre erratique penchée, et se SÉPARE en deux : une branche au
## nord-ouest vers la rivière, une au sud-ouest vers la ferme. On ne trouve
## pas un monument, on trouve un carrefour dans les fleurs.
##
## En aplat noir, les cinq autres lieux du lot sont des volumes ; celui-ci
## est une bande vide avec un seul caillou de 1,7 m. Aucune confusion
## possible — c'est le seul dont la silhouette soit un VIDE.
class_name FlowerFieldPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## Pierre pâle des dalles : la valeur claire du lieu, celle qui dessine la
## fourche dans le vert. Reste sous la bande haute de `VISUAL_ASSET_BIBLE`
## §1.5 — une dalle plus claire que le ciel tirerait l'œil hors de la
## composition (leçon ISS-037 du chemin de terre).
const TONE_DALLE: Color = Color(0.88, 0.86, 0.79)
## L'erratique est plus sombre et plus froid que les dalles : il est venu
## d'ailleurs, il n'est pas de la même pierre que le chemin.
const TONE_ERRATIQUE: Color = Color(0.70, 0.71, 0.70)


func default_place_id() -> StringName:
	return &"valley.poi.flower_field.01"


func _build() -> void:
	# — LA PIERRE-REPÈRE. Un seul bloc, PENCHÉ et demi-enterré : posé
	# d'aplomb il ferait un socle, et un socle appelle une statue. Penché de
	# 19° et enfoncé de 0,55 m, `Rock_Medium_1` (3,23 × 2,26 × 2,99 m) ne
	# montre plus que 1,7 m — la hauteur d'un homme, l'échelle juste pour un
	# repère qu'on rejoint à pied.
	var pierre: Vector3 = _seated(-1.2, 0.8)
	var erratique: Node3D = K.module(self, &"Rock_Medium_1",
		pierre + Vector3(0.0, -0.55, 0.0), 37.0, 1.0, TONE_ERRATIQUE)
	if erratique != null:
		erratique.rotation.z = deg_to_rad(19.0)
	declare_support(pierre)
	K.collider_box(self, "Champ_pierre",
		pierre + Vector3(0.0, 0.80, 0.0), Vector3(2.9, 1.7, 2.6), 37.0)

	# — LA FOURCHE. Trois dalles arrivent du sud-est, deux partent au
	# nord-ouest, deux au sud-ouest. Toutes ENFONCÉES de cinq à sept
	# centimètres : une dalle qui affleure l'herbe se lit neuve, une dalle
	# à demi avalée se lit ancienne — et c'est la seule façon de raconter
	# que ce carrefour servait avant qu'on arrive.
	#
	# Aucune ne porte de collider. Un chemin se marche ; un chemin qui
	# arrête le pas est un mur bas.
	var dalles: Array[Array] = [
		# la venue, depuis la crête de départ
		[7.4, 7.4, 41.0, &"RockPath_Round_Small_1", -0.06],
		[4.6, 4.6, -12.0, &"RockPath_Round_Wide", -0.07],
		[2.4, 2.6, 63.0, &"RockPath_Square_Small_1", -0.06],
		# la branche nord-ouest, vers la rivière
		[-2.8, -1.4, 24.0, &"RockPath_Round_Small_1", -0.05],
		[-5.4, -3.2, -37.0, &"RockPath_Square_Small_1", -0.06],
		# la branche sud-ouest, vers la ferme
		[-1.4, 4.4, 78.0, &"RockPath_Round_Small_1", -0.05],
		[-3.6, 7.0, -21.0, &"RockPath_Square_Small_1", -0.06],
	]
	for spec: Array in dalles:
		var at: Vector3 = _seated(float(spec[0]), float(spec[1]))
		K.module(self, spec[3] as StringName,
			at + Vector3(0.0, float(spec[4]), 0.0), float(spec[2]), 1.0,
			TONE_DALLE)
	declare_support(_seated(4.6, 4.6))
	declare_support(_seated(-5.4, -3.2))
	declare_support(_seated(-3.6, 7.0))

	# — LE HALO. Quatre touffes seulement, et toutes SERRÉES dans l'angle
	# de la fourche et sous le vent de la pierre : c'est la densité locale
	# qui dit « ici », pas un tapis de plus. La prairie gelée fait le reste
	# au-delà, et elle le fait mieux qu'une répétition posée par-dessus.
	K.module(self, &"Bush_Common_Flowers", _seated(-3.2, 1.8), 52.0, 0.90,
		K.TONE_PLANT)
	K.module(self, &"Bush_Common_Flowers", _seated(1.0, -2.4), -28.0, 0.75,
		K.TONE_PLANT)
	K.module(self, &"Flower_4_Group", _seated(0.4, 2.2), 15.0, 1.0,
		K.TONE_PLANT)
	K.module(self, &"Grass_Wispy_Tall", _seated(-4.6, 0.4), -66.0, 1.0,
		K.TONE_PLANT)

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Le Champ des mille fleurs"
	poi.region = &"r02_prairie_mille_fleurs"
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Decouverte_forme"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 14.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	# L'herbe d'endurance pousse SOUS LE VENT de la pierre, du côté abrité :
	# c'est la seule justification qu'un lieu plat puisse donner à une
	# récolte localisée, et elle place la récompense là où le joueur
	# s'arrête déjà — au pied du repère, au moment du choix de route.
	RewardAnchor.attach(self, default_place_id(),
		RewardAnchor.Kind.INGREDIENT,
		_seated(-2.6, 1.6) + Vector3(0.0, 0.1, 0.0), Vector3(1.2, 0.0, 1.2))


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
