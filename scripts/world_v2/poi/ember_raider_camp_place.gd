## CAMP DES PILLARDS BRAISE (`valley.poi.ember_raider_camps.01`, r06) —
## territoire ennemi SANS acteurs (directive V2.3 §2) : l'architecture
## tactique seulement — couverts, accès, sorties, ancre de récompense.
##
## Trois approches lisibles (doctrine du camp, PROMPT2 §5.6) :
##  1. FRONTALE : la brèche ouest de la palissade, face au feu ;
##  2. CONTOURNEMENT : la brèche nord-est, derrière la plateforme ;
##  3. COUVERT : la ligne de rochers sud, qui voit le camp sans être vue.
## Palette braise : bois carbonisé, toiles terre cuite, jarres — AUCUN
## cyan. Le feu est éteint, braises seulement : personne n'est là… ou
## presque.
class_name EmberRaiderCampPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")


func default_place_id() -> StringName:
	return &"valley.poi.ember_raider_camps.01"


func _build() -> void:
	# — Palissade IRRÉGULIÈRE : segments de clôture renforcée en arc de
	# cercle, DEUX brèches (ouest frontale, nord-est de contournement).
	# Angles volontairement inégaux, piquets penchés.
	for stake: Array in [
		[-8.6, -2.0, 100.0], [-7.8, -5.0, 118.0], [-5.8, -7.4, 140.0],
		[-3.0, -8.8, 162.0], [0.4, -9.2, 178.0], [3.8, -8.4, 205.0],
		[6.6, -6.4, 228.0], [8.4, -3.6, 250.0], [9.0, -0.2, 268.0],
		[6.4, 6.8, 318.0], [3.4, 8.4, 340.0], [-4.4, 8.6, 30.0],
		[-7.0, 6.4, 55.0], [-8.6, 3.4, 78.0]]:
		var fence: Node3D = K.module(self, &"Prop_WoodenFence_Single",
			_seated(float(stake[0]), float(stake[1])), float(stake[2]), 1.15,
			K.TONE_CHARRED)
		if fence != null:
			fence.rotation.z = deg_to_rad(fposmod(float(stake[0]) * 7.3, 9.0) - 4.5)
	# Colliders de palissade : quatre arcs pleins, les brèches restent vides.
	K.collider_box(self, "Palissade_sud", _seated(0.0, -8.8) + Vector3(0, 1.0, 0),
		Vector3(12.0, 2.0, 1.2), 0.0)
	K.collider_box(self, "Palissade_est", _seated(8.6, -1.6) + Vector3(0, 1.0, 0),
		Vector3(1.2, 2.0, 7.0), 8.0)
	K.collider_box(self, "Palissade_nord", _seated(-0.6, 8.6) + Vector3(0, 1.0, 0),
		Vector3(9.0, 2.0, 1.2), -8.0)
	K.collider_box(self, "Palissade_ouest", _seated(-8.4, 0.8) + Vector3(0, 1.0, 0),
		Vector3(1.2, 2.0, 6.4), 5.0)
	declare_support(_seated(0.4, -9.2))
	declare_support(_seated(-8.6, 3.4))

	# — Le feu du camp : ÉTEINT, braises froides — le prop visuel seul,
	# aucun interactable (la cuisine appartient au joueur, au checkpoint).
	var embers: CampfireProp = CampfireProp.new()
	embers.name = "FoyerBraise"
	embers.position = _seated(0.6, -0.8)
	add_child(embers)
	declare_support(embers.position)

	# — Deux auvents de pillards, plus bas et plus tordus que ceux du camp
	# du joueur : la même grammaire, une autre main.
	for tent_data: Array in [[4.2, 3.2, 200.0, "AuventPillardNord"],
			[-4.6, -3.8, 20.0, "AuventPillardSud"]]:
		var tent: AwningTent = AwningTent.new()
		tent.name = tent_data[3] as String
		tent.position = _seated(float(tent_data[0]), float(tent_data[1]))
		tent.rotation.y = deg_to_rad(float(tent_data[2]))
		tent.scale = Vector3(0.9, 0.82, 0.9)
		add_child(tent)
		declare_support(tent.position)
		K.collider_box(self, (tent_data[3] as String) + "_col",
			tent.position + Vector3(0, 1.0, 0), Vector3(3.0, 2.0, 2.6),
			float(tent_data[2]))

	# — La PLATEFORME de guet : l'escalier extérieur du kit monté sur sa
	# butte de caisses — le point haut qui surveille la brèche ouest.
	K.module(self, &"Stairs_Exterior_Platform", _seated(5.8, 5.6), 225.0, 1.0,
		K.TONE_CHARRED)
	K.collider_box(self, "Plateforme_col", _seated(5.8, 5.6) + Vector3(0, 1.2, 0),
		Vector3(2.6, 2.4, 2.6), 225.0)
	K.module(self, &"Crate_Wooden", _seated(7.2, 4.4), 30.0, 1.0, K.TONE_CHARRED)

	# — Le butin : jarres, sacs, tonneau — et le COFFRE du camp (gourdin)
	# au fond, sous l'auvent nord, visible depuis la brèche frontale.
	K.module(self, &"Pot_1", _seated(-2.2, 2.6), 0.0, 1.0, K.TONE_STONE)
	K.module(self, &"Pot_1", _seated(-2.9, 2.1), 70.0, 0.85, K.TONE_STONE)
	K.module(self, &"Bag", _seated(-1.4, 3.2), 25.0, 1.0, K.TONE_CLOTH)
	K.module(self, &"Barrel", _seated(2.8, -3.6), 0.0, 1.0, K.TONE_CHARRED)
	K.module(self, &"Pouch_Large", _seated(1.8, 1.4), 0.0, 1.0, K.TONE_CLOTH)

	# — Bannières braise aux deux brèches : le territoire se REVENDIQUE.
	K.module(self, &"Banner_2", _seated(-8.2, -1.2), 95.0, 1.0, K.TONE_CLOTH)
	K.module(self, &"Banner_2", _seated(4.6, 7.6), 320.0, 1.0, K.TONE_CLOTH)

	# — Le couvert SUD : trois rochers en ligne, hauteur d'épaule — la
	# troisième approche.
	for rock: Array in [[-2.4, -12.6, 0.55], [1.2, -13.2, 0.5],
			[4.6, -12.2, 0.6]]:
		K.module(self, &"rock_largeA",
			_seated(float(rock[0]), float(rock[1])), float(rock[0]) * 31.0,
			float(rock[2]), K.TONE_STONE)
	K.collider_box(self, "Couvert_sud_col",
		_seated(1.2, -12.8) + Vector3(0, 0.8, 0), Vector3(8.6, 1.6, 2.2))

	# — Découverte + récompense canonique (coffre — gourdin).
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
		_seated(3.6, 4.6) + Vector3(0, 0.1, 0), Vector3(-1.4, 0.0, -1.2))


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
