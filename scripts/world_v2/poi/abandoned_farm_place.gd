## FERME ABANDONNÉE (`valley.poi.abandoned_farm.01`, r02) — grammaire
## rurale et RUINE récente : la maison tient encore, le toit a cédé d'un
## pan, la clôture est rompue, le verger repousse en friche.
##
## La ruine raconte l'abandon par l'asymétrie : un pan de toit affaissé
## (incliné, glissé), l'autre absent ; la porte arrachée posée au sol ;
## des caisses de récolte éventrées ; le lierre qui reprend les murs.
class_name AbandonedFarmPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")
const MODULE: float = 2.0
const WALL_H: float = 3.12


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
	K.module(self, &"CommonTree_4", _seated(7.5, -5.5), 70.0, 1.1, K.TONE_PLANT)
	K.module(self, &"Bush_Common_Flowers", _seated(6.0, -3.4), 0.0, 1.0,
		K.TONE_PLANT)
	K.module(self, &"Bush_Common", _seated(8.8, -2.8), 45.0, 1.0, K.TONE_PLANT)
	declare_support(_seated(7.5, -5.5))

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


## La maison de ferme : quatre murs de brique inégale, un pan de toit
## AFFAISSÉ, l'autre parti — le ciel entre par le trou.
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
	var skirt: MeshInstance3D = MeshInstance3D.new()
	skirt.name = "Jupe"
	var skirt_box: BoxMesh = BoxMesh.new()
	skirt_box.size = Vector3(6.6, top - low + 0.8, 6.6)
	skirt.mesh = skirt_box
	skirt.material_override = K.flat_material(Color(0.50, 0.42, 0.35))
	skirt.position = Vector3(0, -(top - low + 0.8) * 0.5 + 0.04, 0)
	house.add_child(skirt)
	K.collider_box(house, "Fermette_plinthe", Vector3(0, -0.2, 0),
		Vector3(6.4, 0.6, 6.4))
	# Sol de terre battue : dalles de brique disjointes, pas un plancher.
	for tile: Array in [[-1.0, -1.0], [1.0, -1.0], [-1.0, 1.0], [1.0, 0.6]]:
		K.module(house, &"Floor_Brick",
			Vector3(float(tile[0]), 0.03, float(tile[1])), 0.0, 1.0,
			K.TONE_STONE)
	K.collider_box(house, "Fermette_sol", Vector3(0, -0.1, 0),
		Vector3(6.2, 0.26, 6.2))
	# Faces : la porte SUD est une baie VIDE (la porte gît au sol) ; le mur
	# est n'a plus que deux segments ; l'ouest tient.
	for i: int in range(3):
		var x: float = (float(i) - 1.0) * MODULE
		if i == 1:
			K.module(house, &"Wall_UnevenBrick_Door_Round",
				Vector3(x, 0, half), 0.0, 1.0, K.TONE_STONE)
			_jambs(house, Vector3(x, 0, half), 0.0)
		else:
			_wall(house, Vector3(x, 0, half), 0.0,
				&"Wall_UnevenBrick_Window_Thin_Round")
		_wall(house, Vector3(x, 0, -half), 180.0, &"Wall_UnevenBrick_Straight")
		var z: float = (float(i) - 1.0) * MODULE
		_wall(house, Vector3(-half, 0, z), 90.0, &"Wall_UnevenBrick_Straight")
		if i != 2:
			_wall(house, Vector3(half, 0, z), 270.0,
				&"Wall_UnevenBrick_Straight")
	for corner: Vector3 in [Vector3(-half, 0, -half), Vector3(half, 0, -half),
			Vector3(-half, 0, half), Vector3(half, 0, half)]:
		K.module(house, &"Corner_Exterior_Brick", corner, 0.0, 1.0,
			K.TONE_STONE)
	# Le pan de toit AFFAISSÉ : glissé et incliné, appuyé sur le mur ouest.
	var roof: Node3D = K.module(house, &"Roof_Wooden_2x1_L",
		Vector3(-1.4, WALL_H - 0.7, 0.0), 0.0, 2.6, K.TONE_WOOD)
	if roof != null:
		roof.rotation.z = deg_to_rad(-16.0)
	# Une panne de charpente nue là où l'autre pan manque.
	var beam: MeshInstance3D = MeshInstance3D.new()
	beam.name = "Panne"
	var beam_box: BoxMesh = BoxMesh.new()
	beam_box.size = Vector3(0.18, 0.22, 6.2)
	beam.mesh = beam_box
	beam.material_override = K.flat_material(Color(0.33, 0.24, 0.16))
	beam.position = Vector3(1.4, WALL_H + 0.5, 0.0)
	beam.rotation.z = deg_to_rad(7.0)
	house.add_child(beam)
	# La porte ARRACHÉE, posée à plat devant le seuil.
	var door: Node3D = K.module(house, &"Door_1_Round",
		Vector3(0.7, 0.10, half + 1.2), 24.0, 1.0, K.TONE_WOOD)
	if door != null:
		door.rotation.x = deg_to_rad(-86.0)
	# Le lierre reprend deux murs.
	K.module(house, &"Prop_Vine1", Vector3(-half + 0.1, 0.0, -1.0), 90.0, 1.0,
		K.TONE_PLANT)
	K.module(house, &"Prop_Vine2", Vector3(1.0, 0.0, -half + 0.1), 180.0, 1.0,
		K.TONE_PLANT)


func _wall(parent: Node3D, at: Vector3, yaw: float, kind: StringName) -> void:
	K.module(parent, kind, at, yaw, 1.0, K.TONE_STONE)
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
