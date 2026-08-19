## CAMP DES PILLARDS BRAISE (`valley.poi.ember_raider_camps.01`, r06) —
## territoire ennemi SANS acteurs (directive V2.3 §2) : l'architecture
## tactique seulement — enceinte, brèches, couverts, sorties, récompense.
##
## R2B (plan approuvé, agent A) : une enceinte PILLÉE, ÉTEINTE, BRÛLÉE.
##  - pieux : panneaux `Prop_WoodenFence_Single` charbon PENCHÉS
##    (rot.z ± 8°) entre poteaux `Corner_Exterior_Wood`, éboulis
##    `SM_Dungeon_Rubble*` dans les coupures — plus de blocs procéduraux
##    répétés ;
##  - 2 chicots `DeadTree` réduits (≈ 5 m) DANS l'anneau — le bois brûlé
##    debout ;
##  - guet : 4 poteaux + plancher `Floor_WoodDark` à ≥ 4,5 m +
##    garde-corps — le signal vertical du lieu ;
##  - foyer ÉTEINT sans `CampfireProp` : anneau de pierres noircies,
##    cendres (`SM_Dungeon_RubbleSmall` charbon), chaudron renversé —
##    ZÉRO cône de flamme, zéro matériau émissif ;
##  - bannières `Banner_2_Cloth` reteintées EMBER_CLOTH (la toile bleue
##    du kit est REMPLACÉE, pas multipliée) — fini le bleu ;
##  - appentis `Roof_Wooden_2x1` charbon sur poteaux inégaux — plus de
##    toile commune (`AwningTent`) avec le camp du joueur ;
##  - butin : `Shield_Wooden`, `Chain_Coil`, `Prop_Wagon` renversé.
##
## INCHANGÉS (contrat R2B) : les brèches ouest/NE, le flanc éboulé
## 203–244° borné ≤ 1,0 m (mesure `camp_braise_approche` en tête du
## secteur), les colliders d'enceinte, la découverte et la récompense.
##
## Trois zones lisibles depuis la brèche frontale :
##   1. APPROCHE  (ouest) : brèche large, barricade en écharpe, seuil ;
##   2. FOYER     (centre) : feu mort, appentis, la vie interrompue ;
##   3. RETRAITE  (est/nord) : guet, butin, coffre, brèche de sortie.
class_name EmberRaiderCampPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

const CHARRED_WOOD: Color = Color(0.34, 0.26, 0.19)
const RAW_WOOD: Color = Color(0.52, 0.39, 0.25)
const EMBER_CLOTH: Color = Color(0.60, 0.30, 0.20)
const EARTH: Color = Color(0.45, 0.35, 0.25)
## Pierres du foyer mort : noircies, à peine plus claires que le charbon.
const SOOT_STONE: Color = Color(0.30, 0.28, 0.26)
## Chicots morts : bois gris-brun cendré (teinte multipliée sur le kit).
const ASH_BARK: Color = Color(0.45, 0.40, 0.36)

## Les deux brèches, en degrés sur l'enceinte (0° = est local, sens
## trigonométrique ; le lieu n'a PAS de lacet — local = axes du monde).
const WEST_BREACH_DEG: float = 180.0
const NORTHEAST_BREACH_DEG: float = 42.0
const BREACH_HALF_DEG: float = 17.0

## LE FLANC ÉBOULÉ (sud-ouest) — INCHANGÉ en R2B. Mesure d'origine :
## `camp_braise_approche` a l'œil à (84, 8, 110) et vise (96, 7, 120) —
## angle local 219,8° sur l'enceinte, œil à 8,0 m : le flanc reste borné
## à ≈ 1,0 m pour que la vue d'approche passe PAR-DESSUS l'enceinte.
const COLLAPSED_FROM_DEG: float = 203.0
const COLLAPSED_TO_DEG: float = 244.0


func default_place_id() -> StringName:
	return &"valley.poi.ember_raider_camps.01"


func _build() -> void:
	_palisade()
	_west_approach()
	_hearth_zone()
	_retreat_zone()
	_dead_snags()

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


## L'ENCEINTE : trois grammaires de MODULES alternées le long d'un ovale
## irrégulier — panneaux charbon penchés, poteaux d'angle, éboulis dans
## les coupures — et deux secteurs LAISSÉS OUVERTS (les brèches).
## Pas 20° (arc ≈ 3,1 m) : un panneau agrandi par tronçon — le budget §4
## (camp ≤ 45 modules) interdit la palissade dense du premier jet.
func _palisade() -> void:
	var index: int = 0
	for step: int in range(18):
		var angle: float = 360.0 * float(step) / 18.0
		if _in_breach(angle):
			continue
		var radians: float = deg_to_rad(angle)
		# Ovale irrégulier : plus large est-ouest, cabossé par un sinus.
		var r: float = 9.1 + sin(radians * 2.0) * 0.9 + sin(radians * 5.0) * 0.55
		var x: float = cos(radians) * r
		var z: float = sin(radians) * r * 0.92
		var at: Vector3 = _seated(x, z)
		# Lacet du panneau : tangent à l'anneau (la sonde d'assise donne
		# l'emprise du panneau en X — on la couche le long de l'enceinte).
		var facing: float = -rad_to_deg(radians) + 90.0
		index += 1
		if angle >= COLLAPSED_FROM_DEG and angle <= COLLAPSED_TO_DEG:
			_collapsed_stretch(at, rad_to_deg(radians), radians, index)
			continue
		var kind: int = index % 4
		if kind == 0:
			# La coupure : un tas d'éboulis entre deux tronçons.
			var rubble: StringName = &"SM_Dungeon_RubbleLarge" \
				if index % 2 == 0 else &"SM_Dungeon_RubbleSmall"
			K.module(self, rubble, at, facing + 34.0,
				1.25 + fposmod(float(index) * 0.47, 1.0) * 0.5, K.TONE_CHARRED)
			continue
		# Panneau charbon PENCHÉ (rot.z ± 8°), hauteur inégale par
		# l'échelle — jamais deux répliques alignées.
		var lean: float = 8.0 if index % 2 == 0 else -8.0
		var fence_scale: float = 1.55 + fposmod(float(index) * 0.83, 1.0) * 0.35
		var fence: Node3D = K.module(self, &"Prop_WoodenFence_Single", at,
			facing, fence_scale, K.TONE_CHARRED)
		if fence != null:
			fence.rotation.z = deg_to_rad(lean)
		if kind == 1:
			# Le poteau qui tient le tronçon : décalé le long de la
			# tangente, légèrement hors d'aplomb lui aussi.
			var tangent: Vector3 = Vector3(-sin(radians), 0.0, cos(radians))
			var post_at: Vector3 = at + tangent * 1.15
			post_at.y = ground_local_y(post_at.x, post_at.z)
			var post: Node3D = K.module(self, &"Corner_Exterior_Wood", post_at,
				facing, 0.58 + fposmod(float(index) * 0.37, 1.0) * 0.14,
				K.TONE_CHARRED)
			if post != null:
				post.rotation.z = deg_to_rad(fposmod(float(index) * 7.0, 9.0) - 4.5)
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
## à ≈ 1,0 m pour que l'œil d'approche passe par-dessus (INCHANGÉ R2B).
func _collapsed_stretch(at: Vector3, facing: float, radians: float,
		index: int) -> void:
	var berm: float = 0.52 + fposmod(float(index) * 0.61, 1.0) * 0.30
	K.stone_block(self, "Eboulis_%d" % index,
		at + Vector3(0.0, berm * 0.5, 0.0), Vector3(1.7, berm, 1.35),
		facing, EARTH, 10150 + index, 0.22)
	# Un panneau arraché, couché À PLAT sur le remblai : la bascule se
	# fait autour de son axe LONG (rotation.x), pas autour de son
	# épaisseur — un roll.z aurait dressé sa longueur à la verticale et
	# enterré 0,89 m de panneau (calculé sur l'emprise sondée).
	var fallen: Node3D = K.module(self, &"Prop_WoodenFence_Single",
		at + Vector3(-cos(radians) * 0.9, berm + 0.10, -sin(radians) * 0.9),
		facing + 78.0, 1.3, K.TONE_CHARRED)
	if fallen != null:
		fallen.rotation.x = deg_to_rad(80.0)
	if index % 2 == 0:
		# Une souche de montant, cassée à ras — la preuve du mur.
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
## bannières braise marquent le seuil. Le sol est tassé, sans herbe.
func _west_approach() -> void:
	# UN ROCHER GELÉ TIENT DÉJÀ LA BRÈCHE (mesuré au plan
	# `diag_braise_centre`, V2.2 gelée) : il est la moitié nord de la
	# chicane, la barricade prend la moitié sud — on entre en S.
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
	# Le seuil revendiqué : deux bannières braise de part et d'autre,
	# écartées de l'axe de composition (œil à 173° local, dans la brèche).
	_ember_banner(-9.3, -4.3, 95.0)
	_ember_banner(-9.0, 4.4, 95.0)


## ZONE 2 — FOYER (centre). Le feu est MORT : pierres noircies, cendres,
## chaudron renversé — personne n'est là… ou presque. Un appentis
## charbon sur poteaux inégaux remplace les auvents du camp joueur.
func _hearth_zone() -> void:
	var hearth: Vector3 = _seated(0.6, -0.8)
	declare_support(hearth)
	# Le cercle de pierres, mangé par les cendres — pas de flamme, pas
	# d'émissif : le contrôle négatif « éteint » l'épingle.
	for i: int in range(7):
		var angle: float = TAU * float(i) / 7.0
		K.stone_block(self, "PierreFoyer_%d" % i,
			_seated(0.6 + cos(angle) * 1.25, -0.8 + sin(angle) * 1.25)
				+ Vector3(0.0, 0.16, 0.0),
			Vector3(0.46, 0.32, 0.40), rad_to_deg(angle), SOOT_STONE,
			9990 + i, 0.18)
	# Les cendres : un éboulis charbon DANS l'anneau.
	K.module(self, &"SM_Dungeon_RubbleSmall", hearth, 15.0, 0.85,
		K.TONE_CHARRED)
	# Le chaudron renversé contre les pierres : la marmite abandonnée.
	var cauldron: Node3D = K.module(self, &"Cauldron", _seated(1.9, -1.6),
		250.0, 1.0, K.TONE_CHARRED)
	if cauldron != null:
		cauldron.rotation.z = deg_to_rad(104.0)
		# Emprise 0,99 × 0,82 basculée : le bord bas descend à −0,67 sous
		# le pivot — remonté pour reposer DANS la cendre (10 cm enfoncé).
		cauldron.position.y += 0.60
	# UN appentis charbon adossé au nord, ouvert vers le feu (le plan §4
	# borne le camp à 45 modules : le second abri est la toile roulée).
	_lean_to("AppentisNord", 2.6, 4.9, 196.0, 1.0)
	# Toiles de rechange et paquetage roulés, groupés PAR USAGE.
	K.module(self, &"Bag", _seated(1.6, 3.4), 25.0, 1.0, K.TONE_CLOTH)
	K.module(self, &"Pouch_Large", _seated(2.3, 2.7), 0.0, 1.0, K.TONE_CLOTH)
	K.stone_block(self, "ToileRoulee", _seated(-3.0, -2.9)
		+ Vector3(0.0, 0.22, 0.0), Vector3(1.7, 0.44, 0.44), 28.0,
		EMBER_CLOTH, 10040, 0.14)


## UN APPENTIS DE PILLARD : un panneau `Roof_Wooden_2x1` charbon posé sur
## deux poteaux INÉGAUX devant et deux chicots bas derrière — la même
## fonction que l'auvent du camp joueur, une toute autre main. Le panneau
## a son pivot au bord HAUT (sonde d'assise) : posé en tête des poteaux,
## il descend de 1,25 m vers l'arrière.
func _lean_to(lean_name: String, local_x: float, local_z: float,
		yaw_deg: float, factor: float) -> void:
	var lean: Node3D = Node3D.new()
	lean.name = lean_name
	lean.position = _seated(local_x, local_z)
	lean.rotation.y = deg_to_rad(yaw_deg)
	lean.scale = Vector3.ONE * factor
	add_child(lean)
	declare_support(lean.position)
	# Deux poteaux hauts devant (0,55/0,48 → 1,65 m et 1,44 m), deux
	# chicots derrière (0,40 m et 0,54 m) : rien d'aplomb, rien d'égal.
	for post: Array in [[-1.0, 0.7, 0.55, 3.0], [1.0, 0.7, 0.48, -4.0],
			[-1.0, -0.8, 0.18, 2.0], [1.0, -0.8, 0.13, -3.0]]:
		var upright: Node3D = K.module(lean, &"Corner_Exterior_Wood",
			Vector3(float(post[0]), 0.0, float(post[1])), 0.0,
			float(post[2]), K.TONE_CHARRED)
		if upright != null:
			upright.rotation.z = deg_to_rad(float(post[3]))
	# Le panneau charbon : bord haut sur les poteaux avant (z = +0,76),
	# pente vers l'arrière (yaw 180° local), léger dévers.
	var roof: Node3D = K.module(lean, &"Roof_Wooden_2x1",
		Vector3(0.0, 0.52, 0.76), 180.0, 1.0, K.TONE_CHARRED)
	if roof != null:
		roof.rotation.z = deg_to_rad(-3.5)
	K.collider_box(self, lean_name + "_col",
		lean.position + Vector3(0.0, 0.9, 0.0),
		Vector3(2.4 * factor, 1.8, 1.9 * factor), yaw_deg)


## ZONE 3 — RETRAITE (est / nord-est). Le GUET domine la brèche frontale
## (le signal vertical du lieu), le butin s'entasse dessous, le coffre
## attend au fond, la brèche nord-est est la porte de sortie.
func _retreat_zone() -> void:
	var watch: Vector3 = _seated(6.1, 5.2)
	declare_support(watch)
	var watch_tower: Node3D = Node3D.new()
	watch_tower.name = "Guet"
	watch_tower.position = watch
	add_child(watch_tower)
	# Quatre poteaux hauts, tous inégaux (3,00 m × échelle) — la
	# plateforme perce sur les uns, flotte d'un doigt sur les autres.
	for post: Array in [[-0.95, -0.95, 1.58, 2.0], [0.95, -0.95, 1.62, -1.5],
			[-0.95, 0.95, 1.56, 1.0], [0.95, 0.95, 1.60, -2.0]]:
		var upright: Node3D = K.module(watch_tower, &"Corner_Exterior_Wood",
			Vector3(float(post[0]), 0.0, float(post[1])), 0.0,
			float(post[2]), K.TONE_CHARRED)
		if upright != null:
			upright.rotation.z = deg_to_rad(float(post[3]))
	# Le plancher de guet : ≥ 4,5 m au-dessus du sol gelé (pivot CENTRÉ
	# en Y, mesuré à la sonde — dessus à 4,75 m).
	K.module(watch_tower, &"Floor_WoodDark", Vector3(0.0, 4.74, 0.0),
		12.0, 1.2, K.TONE_CHARRED)
	# Garde-corps : deux panneaux bas côté brèche frontale et côté foyer.
	var rail_west: Node3D = K.module(watch_tower, &"Prop_WoodenFence_Single",
		Vector3(-1.05, 4.76, 0.0), 90.0, 0.85, K.TONE_CHARRED)
	var rail_south: Node3D = K.module(watch_tower, &"Prop_WoodenFence_Single",
		Vector3(0.0, 4.76, -1.05), 0.0, 0.85, K.TONE_CHARRED)
	if rail_west != null:
		rail_west.rotation.z = deg_to_rad(3.0)
	if rail_south != null:
		rail_south.rotation.z = deg_to_rad(-2.5)
	# L'échelle : six barreaux côté camp, jusqu'au plancher.
	for rung: int in range(6):
		K.stone_block(watch_tower, "Barreau_%d" % rung,
			Vector3(-1.15, 0.70 + float(rung) * 0.72, 0.0),
			Vector3(0.36, 0.10, 0.66), 12.0, RAW_WOOD, 10100 + rung, 0.10)
	K.collider_box(self, "Guet_col", watch + Vector3(0.0, 2.5, 0.0),
		Vector3(2.6, 5.0, 2.6), 12.0)
	# Le butin, entassé sous la plateforme et derrière : ce qu'ils ont
	# pris, ce qu'on reprend.
	K.module(self, &"Crate_Wooden", _seated(7.6, 3.5), 30.0, 1.0, K.TONE_CHARRED)
	K.module(self, &"Pot_1", _seated(4.9, 6.4), 0.0, 1.0, K.TONE_STONE)
	var shield: Node3D = K.module(self, &"Shield_Wooden", _seated(5.0, 4.35),
		200.0, 1.0, K.TONE_CHARRED)
	if shield != null:
		# Pivot CENTRÉ en Y (sonde d'assise) : posé au sol il serait à
		# moitié enterré — remonté d'une demi-hauteur, adossé au montant.
		shield.rotation.z = deg_to_rad(14.0)
		shield.position.y += 0.32
	K.module(self, &"Chain_Coil", _seated(7.0, 4.3), 55.0, 1.0, K.TONE_STONE)
	# Le wagon renversé : le pillage interrompu, couché sur le flanc.
	var wagon: Node3D = K.module(self, &"Prop_Wagon", _seated(7.4, 1.6),
		305.0, 0.9, K.TONE_CHARRED)
	if wagon != null:
		wagon.rotation.z = deg_to_rad(104.0)
		# Emprise 1,95 de large basculée à 104° : le flanc descend à
		# −1,32 sous le pivot (calculé sur la sonde) — remonté pour que
		# le plateau touche le sol sans s'y enfoncer.
		wagon.position.y += 1.35
		K.collider_box(self, "WagonRenverse_col",
			_seated(7.4, 1.6) + Vector3(0.0, 0.9, 0.0),
			Vector3(2.0, 1.8, 3.6), 305.0)
	# Le râtelier : ce qu'on prend en décrochant.
	K.module(self, &"WeaponStand", _seated(2.1, 6.3), 190.0, 1.0, K.TONE_CHARRED)
	# La brèche nord-est : sa toile braise pendue au poteau NE du guet
	# (le guet borde la brèche — pas de mât dédié, budget §4), et deux
	# blocs de couvert qui permettent de décrocher sans être vu du foyer.
	var exit_cloth: Node3D = K.module(self, &"Banner_2_Cloth",
		watch + Vector3(0.95, 4.55, 0.95), 320.0, 1.0, Color.WHITE)
	if exit_cloth != null:
		_replace_banner_cloth(exit_cloth)
	for cover: Array in [[9.6, 8.4, 1.35], [11.4, 6.6, 1.05]]:
		K.stone_block(self, "CouvertSortie_%.0f" % float(cover[0]),
			_seated(float(cover[0]), float(cover[1]))
				+ Vector3(0.0, float(cover[2]) * 0.5, 0.0),
			Vector3(1.9, float(cover[2]), 1.6), float(cover[0]) * 23.0,
			Color(0.58, 0.54, 0.48), 10120 + int(cover[0]), 0.17)
	K.collider_box(self, "CouvertSortie_col", _seated(10.5, 7.5)
		+ Vector3(0.0, 0.7, 0.0), Vector3(4.4, 1.4, 3.4), 20.0)


## DEUX CHICOTS MORTS dans l'anneau : `DeadTree` réduits à ≈ 5 m
## (9,50 × 0,53 et 11,49 × 0,44 — mesurés à la sonde d'assise, pivot au
## pied, min_y au sol après seat). Hors du rayon de la caméra d'approche
## (perp mesurées 5,8 m et 6,6 m du rayon local (0,768 ; 0,640)).
func _dead_snags() -> void:
	var north: Node3D = K.module(self, &"DeadTree_1", _seated(-2.5, 5.5),
		130.0, 0.53, ASH_BARK)
	if north != null:
		declare_support(north.position)
	var south: Node3D = K.module(self, &"DeadTree_2", _seated(4.8, -4.6),
		245.0, 0.44, ASH_BARK)
	if south != null:
		declare_support(south.position)


## UNE BANNIÈRE BRAISE : poteau charbon + toile `Banner_2_Cloth` dont la
## toile bleue du kit est REMPLACÉE par un matériau plat EMBER_CLOTH —
## une teinte multipliée laisserait le bleu de la texture gagner.
## (Sonde d'assise : la toile a son pivot en HAUT — elle se pose au
## sommet du poteau et pend.)
func _ember_banner(local_x: float, local_z: float, yaw_deg: float) -> void:
	var foot: Vector3 = _seated(local_x, local_z)
	var pole: Node3D = K.module(self, &"Corner_Exterior_Wood", foot, yaw_deg,
		0.80, K.TONE_CHARRED)
	if pole == null:
		return
	var cloth: Node3D = K.module(self, &"Banner_2_Cloth",
		foot + Vector3(0.0, 2.32, 0.0), yaw_deg, 1.0, Color.WHITE)
	if cloth == null:
		return
	_replace_banner_cloth(cloth)
	declare_support(foot)


## La toile bleue du kit (`MI_Banner`, texturée) est REMPLACÉE par un
## matériau plat EMBER_CLOTH : une teinte multipliée laisserait le bleu
## de la texture gagner — le contrôle négatif « sans bleu » l'épingle.
func _replace_banner_cloth(cloth: Node3D) -> void:
	var targets: Array[Node] = cloth.find_children("*", "MeshInstance3D",
		true, false)
	if cloth is MeshInstance3D:
		targets.append(cloth)
	for node: Node in targets:
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var material: Material = instance.get_active_material(surface)
			if material != null \
					and String(material.resource_name).contains("Banner"):
				instance.set_surface_override_material(surface,
					K.flat_material(EMBER_CLOTH))


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
