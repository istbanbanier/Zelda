## CAMP DES PILLARDS BRAISE (`valley.poi.ember_raider_camps.01`, r06) —
## territoire ennemi SANS acteurs (directive V2.3 §2) : l'architecture
## tactique seulement — enceinte, brèches, couverts, sorties, récompense.
##
## REJET DU LEAD (V2.3-A) : « Le lieu ressemble à des clôtures et des
## bâches réparties autour de gros rochers » + caméras de preuve
## obstruées. Diagnostic mesuré : quatorze exemplaires du MÊME module
## `Prop_WoodenFence_Single` posés sur un cercle — une répétition
## mécanique (§1.6) qui ne fait ni enceinte ni menace ; et la ligne de
## couvert sud passait dans l'axe de `camp_braise_approche`.
##
## Reconstruction : une enceinte CONSTRUITE — pieux plantés de hauteurs
## inégales, deux tronçons de palissade pleine, une barricade de rondins,
## un remblai de terre — irrégulière, avec DEUX brèches intentionnelles.
## Et trois zones lisibles depuis la brèche frontale :
##   1. APPROCHE  (ouest) : la brèche large, le sol tassé, la barricade
##      qui oblige à contourner — on entre sous surveillance ;
##   2. FOYER     (centre) : le feu éteint, les auvents, la vie du camp ;
##   3. RETRAITE  (est/nord) : la plateforme de guet, le butin, le coffre,
##      et la brèche nord-est par laquelle on décroche.
##
## Palette braise : bois carbonisé, toiles terre cuite, jarres — AUCUN
## cyan. Le feu est éteint, braises seulement : personne n'est là… ou
## presque.
class_name EmberRaiderCampPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

const CHARRED_WOOD: Color = Color(0.34, 0.26, 0.19)
const RAW_WOOD: Color = Color(0.52, 0.39, 0.25)
const EMBER_CLOTH: Color = Color(0.60, 0.30, 0.20)
const EARTH: Color = Color(0.45, 0.35, 0.25)

## Les deux brèches, en degrés sur l'enceinte (0° = est local, sens
## trigonométrique ; le lieu n'a PAS de lacet — local = axes du monde).
const WEST_BREACH_DEG: float = 180.0
const NORTHEAST_BREACH_DEG: float = 42.0
const BREACH_HALF_DEG: float = 17.0

## LE FLANC ÉBOULÉ (sud-ouest). Deux raisons, l'une mesurée, l'autre de
## dessin, et elles vont dans le même sens.
##
## MESURE : `camp_braise_approche` a l'œil à (84, 8, 110) et vise
## (96, 7, 120) — soit un angle local de **219,8°** sur l'enceinte, à
## 15,6 m. L'enceinte y est à 6,5 m de l'œil, et son sommet monte à
## ≈ 8,7–9,0 m contre un œil à 8,0 : la palissade passait DEVANT le camp.
## C'est l'obstruction de caméra signalée par le lead.
##
## DESSIN : une enceinte de pillards n'est pas un mur d'enceinte de
## ville ; elle est réparée là où ça compte. Un flanc effondré donne la
## troisième approche de la doctrine (frontale · contournement · couvert),
## et il la donne SANS trou dans la géométrie.
const COLLAPSED_FROM_DEG: float = 203.0
const COLLAPSED_TO_DEG: float = 244.0


func default_place_id() -> StringName:
	return &"valley.poi.ember_raider_camps.01"


func _build() -> void:
	_palisade()
	_west_approach()
	_hearth_zone()
	_retreat_zone()

	# — Découverte + récompense canonique (coffre — gourdin), dans la zone
	# de RETRAITE : on la voit depuis la brèche frontale, on l'atteint en
	# traversant tout le camp.
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Camp des pillards braise"
	poi.region = "r06_bois_du_levant"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 14.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.CHEST,
		_seated(3.6, 4.6) + Vector3(0.0, 0.1, 0.0), Vector3(-1.4, 0.0, -1.2))


## L'ENCEINTE : plus jamais quatorze fois le même panneau. Trois
## grammaires alternées le long d'un ovale irrégulier — pieux plantés,
## palissade pleine, remblai — et deux secteurs LAISSÉS OUVERTS.
func _palisade() -> void:
	var index: int = 0
	for step: int in range(46):
		var angle: float = 360.0 * float(step) / 46.0
		if _in_breach(angle):
			continue
		var radians: float = deg_to_rad(angle)
		# Ovale irrégulier : plus large est-ouest, cabossé par un sinus.
		var r: float = 9.1 + sin(radians * 2.0) * 0.9 + sin(radians * 5.0) * 0.55
		var x: float = cos(radians) * r
		var z: float = sin(radians) * r * 0.92
		var at: Vector3 = _seated(x, z)
		var facing: float = rad_to_deg(radians)
		index += 1
		if angle >= COLLAPSED_FROM_DEG and angle <= COLLAPSED_TO_DEG:
			_collapsed_stretch(at, facing, radians, index)
			continue
		var kind: int = index % 3
		if kind == 0:
			# Remblai : une masse de terre basse, entre deux tronçons.
			K.stone_block(self, "Remblai_%d" % index,
				at + Vector3(0.0, 0.34, 0.0), Vector3(1.5, 0.68, 1.15),
				facing, EARTH, 9800 + index, 0.16)
			continue
		var height: float = 1.75 + fposmod(float(index) * 0.83, 1.0) * 0.95
		if kind == 1:
			# Pieux plantés : trois épieux inégaux et penchés.
			for stake: int in range(3):
				var offset: float = (float(stake) - 1.0) * 0.42
				var h: float = height - abs(offset) * 0.55 \
					+ fposmod(float(index * 3 + stake) * 0.37, 1.0) * 0.4
				var post: MeshInstance3D = K.stone_block(self,
					"Pieu_%d_%d" % [index, stake],
					at + Vector3(-sin(radians) * offset, h * 0.5,
						cos(radians) * offset),
					Vector3(0.22, h, 0.22), facing, CHARRED_WOOD,
					9820 + index * 3 + stake, 0.13)
				post.rotation.z = deg_to_rad(
					fposmod(float(index * 7 + stake * 3), 13.0) - 6.5)
				# La pointe taillée : bois cru, non carbonisé.
				K.stone_block(self, "Pointe_%d_%d" % [index, stake],
					at + Vector3(-sin(radians) * offset, h + 0.12,
						cos(radians) * offset),
					Vector3(0.16, 0.30, 0.16), facing, RAW_WOOD,
					9860 + index * 3 + stake, 0.22)
		else:
			# Palissade pleine : planches jointives derrière deux montants.
			K.stone_block(self, "Palis_%d" % index,
				at + Vector3(0.0, height * 0.5, 0.0),
				Vector3(0.20, height, 1.55), facing, CHARRED_WOOD,
				9900 + index, 0.08)
			K.stone_block(self, "Montant_%d" % index,
				at + Vector3(-sin(radians) * 0.72, height * 0.5 + 0.18,
					cos(radians) * 0.72),
				Vector3(0.26, height + 0.36, 0.26), facing, CHARRED_WOOD,
				9930 + index, 0.10)
		if index % 5 == 2:
			declare_support(at)
	# Colliders : quatre arcs pleins, les deux brèches restent VIDES —
	# c'est par là qu'on entre, et le filet de couloir le vérifie.
	K.collider_box(self, "Enceinte_sud", _seated(0.4, -8.6)
		+ Vector3(0.0, 1.0, 0.0), Vector3(12.4, 2.0, 1.3), 4.0)
	K.collider_box(self, "Enceinte_est", _seated(9.2, -1.4)
		+ Vector3(0.0, 1.0, 0.0), Vector3(1.3, 2.0, 7.4), 8.0)
	K.collider_box(self, "Enceinte_nord", _seated(-1.6, 8.4)
		+ Vector3(0.0, 1.0, 0.0), Vector3(9.6, 2.0, 1.3), -7.0)
	K.collider_box(self, "Enceinte_ouest", _seated(-8.8, 1.4)
		+ Vector3(0.0, 1.0, 0.0), Vector3(1.3, 2.0, 5.6), 5.0)
	# Le flanc éboulé garde un obstacle, mais BAS : on l'enjambe, on ne le
	# franchit pas d'un pas — c'est un couvert, pas une porte.
	K.collider_box(self, "Enceinte_flanc_eboule", _seated(-6.6, -5.3)
		+ Vector3(0.0, 0.45, 0.0), Vector3(5.4, 0.9, 1.6), 39.0)


## LE FLANC ÉBOULÉ : un remblai bas et des pieux COUCHÉS, jamais un vide.
## L'enceinte continue — elle est seulement tombée. Hauteur totale bornée
## à ≈ 1,0 m pour que l'œil d'approche passe par-dessus (voir la mesure
## en tête de fichier).
func _collapsed_stretch(at: Vector3, facing: float, radians: float,
		index: int) -> void:
	var berm: float = 0.52 + fposmod(float(index) * 0.61, 1.0) * 0.30
	K.stone_block(self, "Eboulis_%d" % index,
		at + Vector3(0.0, berm * 0.5, 0.0), Vector3(1.7, berm, 1.35),
		facing, EARTH, 10150 + index, 0.22)
	if index % 2 == 0:
		# Un pieu arraché, couché en travers, la pointe vers l'intérieur.
		var fallen: MeshInstance3D = K.stone_block(self, "PieuCouche_%d" % index,
			at + Vector3(-cos(radians) * 0.9, berm + 0.14, -sin(radians) * 0.9),
			Vector3(1.9, 0.20, 0.20), facing + 78.0, CHARRED_WOOD,
			10170 + index, 0.14)
		fallen.rotation.z = deg_to_rad(fposmod(float(index) * 9.0, 11.0) - 5.5)
	if index % 3 == 1:
		# Une souche de montant, cassée à ras — la preuve qu'il y avait un mur.
		K.stone_block(self, "SoucheMontant_%d" % index,
			at + Vector3(0.0, berm + 0.22, 0.0), Vector3(0.26, 0.44, 0.26),
			facing, RAW_WOOD, 10190 + index, 0.20)


## Un angle tombe-t-il dans une brèche ?
func _in_breach(angle_deg: float) -> bool:
	for centre: float in [WEST_BREACH_DEG, NORTHEAST_BREACH_DEG]:
		var delta: float = abs(fposmod(angle_deg - centre + 180.0, 360.0) - 180.0)
		if delta <= BREACH_HALF_DEG:
			return true
	return false


## ZONE 1 — APPROCHE (ouest). La brèche est large, mais une barricade de
## rondins la prend en écharpe : on entre de biais, à découvert. Deux
## bannières marquent le seuil. Le sol est tassé, sans herbe.
func _west_approach() -> void:
	# UN ROCHER GELÉ TIENT DÉJÀ LA BRÈCHE. Mesuré au plan
	# `diag_braise_centre` : une masse claire de 4 à 5 m est posée vers
	# le local (−4 ; 0), pile dans l'axe d'entrée. Elle n'appartient pas
	# au lieu — aucune de ses pièces nommées ne fait cette taille — et
	# V2.2 est gelée : on ne la déplace pas, on compose AVEC.
	#
	# Elle devient donc la moitié nord de la chicane, et la barricade
	# prend la moitié sud : on entre en S, entre roche et rondins, à
	# découvert. Le sentier d'usure contourne par le sud pour la même
	# raison — il passait sous le rocher.
	var barricade: Vector3 = _seated(-6.2, -4.4)
	declare_support(barricade)
	for i: int in range(4):
		var t: float = float(i) / 3.0
		var beam: MeshInstance3D = K.stone_block(self, "Rondin_%d" % i,
			barricade + Vector3(0.0, 0.45 + t * 0.62, -0.5 + t * 1.0),
			Vector3(0.30, 0.30, 3.4), 24.0 + t * 8.0, CHARRED_WOOD,
			9960 + i, 0.12)
		beam.rotation.x = deg_to_rad(6.0 - t * 4.0)
	for trestle: float in [-1.5, 1.5]:
		K.stone_block(self, "Chevalet_%.0f" % trestle,
			barricade + Vector3(0.0, 0.72, trestle),
			Vector3(0.26, 1.44, 0.26), 24.0, CHARRED_WOOD,
			9970 + int(trestle * 10.0), 0.10)
	K.collider_box(self, "Barricade_col", barricade + Vector3(0.0, 0.8, 0.0),
		Vector3(1.1, 1.6, 3.6), 24.0)
	# Le sentier d'usure contourne le rocher par le sud.
	for slab: Array in [[-7.8, -1.8], [-6.2, -2.9], [-4.2, -3.1], [-2.2, -2.2]]:
		K.module(self, &"RockPath_Round_Wide",
			_seated(float(slab[0]), float(slab[1])),
			float(slab[0]) * 41.0, 1.15, EARTH * 1.5)
	# Le seuil revendiqué : deux bannières braise de part et d'autre.
	# Écartées à ±4,3 m de l'axe : elles ENCADRENT la vue de composition
	# (œil à 173° local, dans la brèche) au lieu de la traverser.
	K.module(self, &"Banner_2", _seated(-9.3, -4.3), 95.0, 1.0, K.TONE_CLOTH)
	K.module(self, &"Banner_2", _seated(-9.0, 4.4), 95.0, 1.0, K.TONE_CLOTH)


## ZONE 2 — FOYER (centre). Le feu éteint, deux auvents RECOMPOSÉS : plus
## bas, tordus, adossés à des perches inégales — la même grammaire que le
## camp du joueur, une autre main, et surtout HORS des axes de preuve.
func _hearth_zone() -> void:
	var embers: CampfireProp = CampfireProp.new()
	embers.name = "FoyerBraise"
	embers.position = _seated(0.6, -0.8)
	add_child(embers)
	declare_support(embers.position)
	# Le cercle de pierres du foyer, mangé par les cendres.
	for i: int in range(7):
		var angle: float = TAU * float(i) / 7.0
		K.stone_block(self, "PierreFoyer_%d" % i,
			_seated(0.6 + cos(angle) * 1.25, -0.8 + sin(angle) * 1.25)
				+ Vector3(0.0, 0.16, 0.0),
			Vector3(0.46, 0.32, 0.40), rad_to_deg(angle), Color(0.44, 0.40, 0.36),
			9990 + i, 0.18)
	# Deux auvents : un grand adossé à l'enceinte nord, un petit au sud —
	# ouverts vers le feu, jamais parallèles (symétrie proscrite §3).
	for tent_data: Array in [[2.6, 4.9, 196.0, 0.95, "AuventPillardNord"],
			[-3.4, -4.2, 26.0, 0.80, "AuventPillardSud"]]:
		var tent: AwningTent = AwningTent.new()
		tent.name = tent_data[4] as String
		tent.position = _seated(float(tent_data[0]), float(tent_data[1]))
		tent.rotation.y = deg_to_rad(float(tent_data[2]))
		var factor: float = float(tent_data[3])
		tent.scale = Vector3(factor, factor * 0.88, factor)
		add_child(tent)
		declare_support(tent.position)
		K.collider_box(self, (tent_data[4] as String) + "_col",
			tent.position + Vector3(0.0, 1.0, 0.0),
			Vector3(3.0 * factor, 2.0, 2.6 * factor), float(tent_data[2]))
		# La perche de tension : ce qui fait qu'un auvent tient, et ce qui
		# le distingue d'une bâche posée.
		var guy: MeshInstance3D = K.stone_block(self,
			(tent_data[4] as String) + "_hauban",
			tent.position + Vector3(1.7 * factor, 0.85, -1.3 * factor),
			Vector3(0.12, 1.9, 0.12), float(tent_data[2]), CHARRED_WOOD,
			10020 + int(tent_data[0] * 10.0), 0.09)
		guy.rotation.z = deg_to_rad(21.0)
	# Toiles de rechange et paquetage roulés, groupés PAR USAGE.
	K.module(self, &"Bag", _seated(1.6, 3.4), 25.0, 1.0, K.TONE_CLOTH)
	K.module(self, &"Pouch_Large", _seated(2.3, 2.7), 0.0, 1.0, K.TONE_CLOTH)
	K.stone_block(self, "ToileRoulee", _seated(-3.0, -2.9)
		+ Vector3(0.0, 0.22, 0.0), Vector3(1.7, 0.44, 0.44), 28.0,
		EMBER_CLOTH, 10040, 0.14)


## ZONE 3 — RETRAITE (est / nord-est). La plateforme de guet domine la
## brèche frontale, le butin s'entasse derrière, le coffre attend au fond,
## et la brèche nord-est est la porte de sortie.
func _retreat_zone() -> void:
	# La plateforme : sur quatre montants inégaux et une plate-forme de
	# planches — pas un escalier de kit posé au sol.
	var watch: Vector3 = _seated(6.1, 5.2)
	declare_support(watch)
	for post: Array in [[-1.2, -1.1, 2.35], [1.2, -1.1, 2.55],
			[-1.2, 1.1, 2.15], [1.2, 1.1, 2.40]]:
		K.stone_block(self, "MontantGuet_%d" % get_child_count(),
			watch + Vector3(float(post[0]), float(post[2]) * 0.5, float(post[1])),
			Vector3(0.24, float(post[2]), 0.24), 12.0, CHARRED_WOOD,
			10060 + get_child_count(), 0.10)
	for plank: int in range(5):
		K.stone_block(self, "PlancherGuet_%d" % plank,
			watch + Vector3(0.0, 2.48, -1.1 + float(plank) * 0.55),
			Vector3(2.7, 0.14, 0.50), 12.0, RAW_WOOD, 10080 + plank, 0.07)
	K.stone_block(self, "GardeCorpsGuet", watch + Vector3(0.0, 2.94, -1.25),
		Vector3(2.7, 0.78, 0.14), 12.0, CHARRED_WOOD, 10090, 0.11)
	# L'échelle : trois barreaux côté camp.
	for rung: int in range(3):
		K.stone_block(self, "Barreau_%d" % rung,
			watch + Vector3(-1.35, 0.70 + float(rung) * 0.62, 0.0),
			Vector3(0.36, 0.10, 0.66), 12.0, RAW_WOOD, 10100 + rung, 0.10)
	K.collider_box(self, "Guet_col", watch + Vector3(0.0, 1.3, 0.0),
		Vector3(2.9, 2.6, 2.6), 12.0)
	# Le butin, entassé sous la plateforme et derrière.
	K.module(self, &"Crate_Wooden", _seated(7.6, 3.5), 30.0, 1.0, K.TONE_CHARRED)
	K.module(self, &"Barrel", _seated(6.9, 2.2), 0.0, 1.0, K.TONE_CHARRED)
	K.module(self, &"Pot_1", _seated(4.9, 6.4), 0.0, 1.0, K.TONE_STONE)
	K.module(self, &"Pot_1", _seated(5.6, 6.9), 70.0, 0.85, K.TONE_STONE)
	# Le râtelier : ce qu'on prend en décrochant.
	K.module(self, &"WeaponStand", _seated(2.1, 6.3), 190.0, 1.0, K.TONE_CHARRED)
	# La brèche nord-est : sa bannière, et deux blocs de couvert qui
	# permettent de décrocher sans être vu depuis le foyer.
	K.module(self, &"Banner_2", _seated(7.6, 6.6), 320.0, 1.0, K.TONE_CLOTH)
	for cover: Array in [[9.6, 8.4, 1.35], [11.4, 6.6, 1.05]]:
		K.stone_block(self, "CouvertSortie_%.0f" % float(cover[0]),
			_seated(float(cover[0]), float(cover[1]))
				+ Vector3(0.0, float(cover[2]) * 0.5, 0.0),
			Vector3(1.9, float(cover[2]), 1.6), float(cover[0]) * 23.0,
			Color(0.58, 0.54, 0.48), 10120 + int(cover[0]), 0.17)
	K.collider_box(self, "CouvertSortie_col", _seated(10.5, 7.5)
		+ Vector3(0.0, 0.7, 0.0), Vector3(4.4, 1.4, 3.4), 20.0)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
