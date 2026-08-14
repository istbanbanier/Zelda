## ARCHE DE PIERRE (`valley.poi.stone_bridge.01`, r03) — le repère
## naturel du gué central : une arche qui enjambe la rivière, plus
## ancienne que tout le bâti de la vallée.
##
## La route des ruines TRAVERSE le gué à côté — l'arche est le REPÈRE,
## pas le passage : ses culées portent des colliders, son tablier ruiné
## n'en a pas (on ne marche pas dessus), et rien n'approche à moins de
## 1,2 m du couloir de route contractuel. Le lit, les berges et l'eau
## gelés ne sont pas touchés : les culées ÉPOUSENT chaque rive.
class_name StoneBridgePlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")


func default_place_id() -> StringName:
	return &"valley.poi.stone_bridge.01"


func _build() -> void:
	# L'arche enjambe le bras d'eau en AVAL du gué central : le gué (local
	# (6,−10)) est sondé par huit rayons sur 12 m (ISS-032) — les culées
	# sont posées HORS de l'éventail (l'ancienne implantation coupait les
	# rayons 135° et 225°, mesuré par la sonde des gués).
	var axis: Vector3 = Vector3(4.3, 0.0, -10.1).normalized()
	var north_foot: Vector3 = _seated(-8.0, -6.0)
	var south_foot: Vector3 = _seated(-3.7, -16.1)
	declare_support(north_foot)
	declare_support(south_foot)

	_abutment("CuleeNord", north_foot, axis, 1.0)
	_abutment("CuleeSud", south_foot, -axis, -1.0)

	# — Le bandeau de l'arche : neuf voussoirs en plein cintre, du gros
	# bloc de rive au sommet plus fin. Aucun collider : c'est un repère.
	var mid: Vector3 = (north_foot + south_foot) * 0.5
	var span: float = north_foot.distance_to(south_foot)
	var crown_y: float = maxf(north_foot.y, south_foot.y) + 4.6
	for i: int in range(9):
		var t: float = float(i) / 8.0
		var along: Vector3 = north_foot.lerp(south_foot, t)
		var rise: float = sin(t * PI)
		var stone: Node3D = K.module(self, &"SM_Dungeon_ArchBlock",
			Vector3(along.x, lerpf(along.y + 1.0, crown_y, rise), along.z),
			rad_to_deg(atan2(axis.x, axis.z)) + 90.0,
			1.25 - 0.35 * rise, K.TONE_STONE)
		if stone != null:
			stone.rotation.x = deg_to_rad(lerpf(-38.0, 38.0, t))
	# Deux voussoirs TOMBÉS dans le lit, là où le bandeau s'est ouvert.
	var fallen_a: Node3D = K.module(self, &"SM_Dungeon_RubbleLarge",
		mid + Vector3(1.6, -0.2, 0.8) - Vector3(0, mid.y, 0)
			+ Vector3(0, ground_local_y(mid.x + 1.6, mid.z + 0.8), 0),
		140.0, 1.0, K.TONE_STONE)
	if fallen_a != null:
		fallen_a.rotation.z = deg_to_rad(20.0)
	K.module(self, &"SM_Dungeon_RubbleSmall",
		Vector3(mid.x - 1.2, ground_local_y(mid.x - 1.2, mid.z - 1.5),
			mid.z - 1.5), 60.0, 1.0, K.TONE_STONE)

	# — Le pied de lecture : trois dalles et la stèle du fragment
	# d'histoire, sur la berge nord, hors du couloir de route.
	for slab: Array in [[-6.2, -3.2], [-7.6, -1.8], [-5.4, -1.6]]:
		K.module(self, &"RockPath_Square_Wide",
			_seated(float(slab[0]), float(slab[1])),
			float(slab[0]) * 41.0, 1.0, K.TONE_STONE)
	var stele: Node3D = K.module(self, &"SM_Dungeon_PillarStub",
		_seated(-8.4, -3.2), 15.0, 0.8, K.TONE_DARK_STONE)
	if stele != null:
		stele.rotation.z = deg_to_rad(6.0)
		declare_support(_seated(-8.4, -3.2))
	K.module(self, &"Prop_Vine1", _seated(-8.0, -2.6), 60.0, 0.9, K.TONE_PLANT)

	# — Découverte + récompense canonique (fragment d'histoire) à la stèle.
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Arche de pierre"
	poi.region = "r03_val_de_neris"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 12.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.STORY,
		_seated(-7.4, -2.4) + Vector3(0, 0.15, 0), Vector3(1.3, 0.0, 0.8))


## Une culée : gros blocs de falaise empilés qui ÉPOUSENT la berge, avec
## un collider borné à la masse (loin du couloir de route).
func _abutment(part_name: String, foot: Vector3, toward: Vector3,
		lean: float) -> void:
	var pile: Node3D = Node3D.new()
	pile.name = part_name
	pile.position = foot
	add_child(pile)
	K.module(pile, &"cliff_blockSlope_rock", Vector3.ZERO,
		rad_to_deg(atan2(toward.x, toward.z)), 0.5, K.TONE_STONE)
	K.module(pile, &"rock_largeA", Vector3(-toward.x * 1.4, 0.0, -toward.z * 1.4),
		rad_to_deg(atan2(toward.x, toward.z)) + 35.0 * lean, 0.42,
		K.TONE_STONE)
	K.module(pile, &"rock_smallB", Vector3(toward.z * 1.6 * lean, 0.0,
		-toward.x * 1.6 * lean), 80.0 * lean, 0.5, K.TONE_STONE)
	K.collider_box(self, part_name + "_col", foot + Vector3(0, 1.1, 0),
		Vector3(2.6, 2.4, 2.6), rad_to_deg(atan2(toward.x, toward.z)))


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
