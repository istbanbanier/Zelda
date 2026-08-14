## VILLAGE DE LA RIVIÈRE (`valley.poi.riverside_village.01`, r03) — le
## lieu habité de la route de la rivière.
##
## Grammaire village (contrats §2) : bâti sur trame 2 m, murs 3,12 m,
## toits en tuiles rondes, circulation réelle — la route de la rivière
## TRAVERSE le hameau (segments locaux (4,−1)→(0,−8) puis vers l'est) et
## reste libre ; les bâtiments tiennent la rive OUEST plus haute, le quai
## descend vers l'eau à l'est. Fondations : plinthe posée au point HAUT
## de l'emprise, jupe de pierre jusqu'au sol — le terrain gelé n'est
## jamais remodelé.
class_name RiversideVillagePlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")
const MODULE: float = 2.0
const WALL_H: float = 3.12
const DOOR_GAP: float = 1.30


func default_place_id() -> StringName:
	return &"valley.poi.riverside_village.01"


func _build() -> void:
	# — Auberge 6×6 creuse, porte vers la place. Le gué du bourg (local
	# (0,−8)) est sondé par HUIT rayons sur 12 m (ISS-032) : l'auberge vit
	# dans le coin nord-ouest ENTRE les rayons 90° et 135°, mesurée à
	# > 3,4 m de chacun — les rayons O et NO restent nus.
	_house("Auberge", Vector3(-4.5, 0.0, 6.0), 35.0, "plaster", 6)
	# — Maison basse 6×6 en brique, AU NORD de la place, porte au sud. La
	# route de la rivière traverse le bourg par TROIS segments locaux
	# ((24,−3)→(4,−1)→(0,−8)→(36,−20)) : tout le centre-sud lui
	# appartient — seuls l'ouest (auberge) et le nord sont constructibles.
	_house("MaisonBrique", Vector3(3.5, 0.0, 11.0), 160.0, "brick", 6)

	# — Échoppe ouverte côté place : charrette d'étal sous un surplomb.
	K.module(self, &"Stall_Cart_Empty", _seated(1.5, 6.0), 155.0, 1.0,
		K.TONE_WOOD)
	K.module(self, &"Crate_Wooden", _seated(3.0, 6.8), 40.0, 1.0, K.TONE_WOOD)
	K.module(self, &"Barrel_Apples", _seated(0.2, 7.0), 0.0, 1.0, K.TONE_WOOD)

	# — Quai vers l'eau : l'eau MESURÉE passe au SUD du bourg (bande
	# globale z 18–24 — sondée, jamais devinée) ; le ponton descend au
	# sud-est, HORS du rayon Est du gué (pointe x=12, collider ≥ 13,5) et
	# hors du couloir de route.
	var deck: Node3D = Node3D.new()
	deck.name = "Quai"
	add_child(deck)
	var deck_y: float = ground_local_y(13.8, -5.0) + 0.35
	for ix: int in range(0, 2):
		for iz: int in range(0, 2):
			var piece: Node3D = K.module(deck, &"Floor_WoodDark",
				Vector3(14.8 + float(ix) * MODULE, deck_y,
					-6.4 - float(iz) * MODULE), 0.0, 1.0, K.TONE_WOOD)
			if piece != null:
				piece.position.y = deck_y
	for post: Array in [[13.9, -5.5], [17.6, -5.5], [13.9, -9.2], [17.6, -9.2]]:
		var post_x: float = float(post[0])
		var post_z: float = float(post[1])
		var foot: float = ground_local_y(post_x, post_z)
		var pillar: MeshInstance3D = MeshInstance3D.new()
		pillar.name = "Pilotis_%d" % deck.get_child_count()
		var cylinder: CylinderMesh = CylinderMesh.new()
		cylinder.top_radius = 0.14
		cylinder.bottom_radius = 0.17
		cylinder.height = maxf(deck_y - foot + 0.6, 0.8)
		pillar.mesh = cylinder
		pillar.material_override = K.flat_material(Color(0.30, 0.20, 0.13))
		pillar.position = Vector3(post_x, foot + cylinder.height * 0.5, post_z)
		deck.add_child(pillar)
		declare_support(Vector3(post_x, foot, post_z))
	K.collider_box(self, "Quai_col", Vector3(15.8, deck_y - 0.1, -7.4),
		Vector3(4.6, 0.3, 4.4))
	# Le sentier du ponton : dalles qui descendent de la place vers l'eau.
	for slab: Array in [[6.0, -2.0], [9.0, -3.5], [12.0, -4.6]]:
		K.module(self, &"RockPath_Round_Wide",
			_seated(float(slab[0]), float(slab[1])),
			float(slab[0]) * 29.0, 1.0, K.TONE_STONE)

	# — La place : dalles, puits d'eau non, tonneaux, bannière du bourg.
	for slab: Array in [[-1.5, 1.5], [0.8, 2.6], [-3.2, 3.4], [1.9, 0.2],
			[-0.4, 4.6]]:
		K.module(self, &"RockPath_Square_Wide",
			_seated(float(slab[0]), float(slab[1])),
			float(slab[0]) * 53.0, 1.0, K.TONE_STONE)
	K.module(self, &"Banner_1", _seated(-8.5, 8.5), 60.0, 1.0, K.TONE_CLOTH)
	K.module(self, &"Bench", _seated(-2.6, 0.2), 125.0, 1.0, K.TONE_WOOD)

	# — Clôtures basses qui tiennent la pente ouest, en retrait de la route.
	for fence: Array in [[-11.5, 2.5, 25.0], [-10.0, 4.6, 25.0],
			[-8.4, 6.6, 40.0]]:
		K.module(self, &"Prop_WoodenFence_Single",
			_seated(float(fence[0]), float(fence[1])), float(fence[2]), 1.0,
			K.TONE_WOOD)

	# — Découverte + récompense canonique (arme au sol, via la table
	# existante) : dans la cour, visible de la place.
	_poi_area()
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.WEAPON,
		_seated(2.5, -3.5) + Vector3(0, 0.1, 0), Vector3(1.2, 0.0, 1.2))


## Maison creuse sur plinthe : trame 2 m, quatre faces, angles, toit à
## deux pentes, colliders muraux — la recette V1, ASSISE sur le sol gelé.
func _house(house_name: String, at: Vector3, yaw_deg: float,
		style: String, span: int) -> void:
	var house: Node3D = Node3D.new()
	house.name = house_name
	add_child(house)
	var half: float = float(span) * 0.5
	# Plinthe au point HAUT de l'emprise (sondé aux quatre coins).
	var top: float = -1e9
	var low: float = 1e9
	for corner: Vector3 in [Vector3(-half, 0, -half), Vector3(half, 0, -half),
			Vector3(-half, 0, half), Vector3(half, 0, half)]:
		var rotated: Vector3 = corner.rotated(Vector3.UP, deg_to_rad(yaw_deg))
		var ground: float = ground_local_y(at.x + rotated.x, at.z + rotated.z)
		top = maxf(top, ground)
		low = minf(low, ground)
		declare_support(Vector3(at.x + rotated.x, ground, at.z + rotated.z))
	house.position = Vector3(at.x, top + 0.06, at.z)
	house.rotation.y = deg_to_rad(yaw_deg)
	# Jupe de fondation : la pierre descend jusque SOUS le sol le plus bas.
	var skirt_h: float = top - low + 0.8
	var skirt: MeshInstance3D = MeshInstance3D.new()
	skirt.name = "Jupe"
	var skirt_box: BoxMesh = BoxMesh.new()
	skirt_box.size = Vector3(float(span) + 0.6, skirt_h, float(span) + 0.6)
	skirt.mesh = skirt_box
	skirt.material_override = K.flat_material(Color(0.52, 0.44, 0.37))
	skirt.position = Vector3(0, -skirt_h * 0.5 + 0.05, 0)
	house.add_child(skirt)
	K.collider_box(house, house_name + "_plinthe", Vector3(0, -0.2, 0),
		Vector3(float(span) + 0.4, 0.6, float(span) + 0.4))

	var wall_full: StringName = &"Wall_Plaster_Straight" \
		if style == "plaster" else &"Wall_UnevenBrick_Straight"
	var wall_window: StringName = &"Wall_Plaster_Window_Wide_Round" \
		if style == "plaster" else &"Wall_UnevenBrick_Window_Wide_Round"
	var wall_door: StringName = &"Wall_Plaster_Door_Round" \
		if style == "plaster" else &"Wall_UnevenBrick_Door_Round"
	var tiles: int = span / 2
	var offset: float = half + 0.0
	# Plancher + sol porteur.
	for ix: int in range(tiles):
		for iz: int in range(tiles):
			K.module(house, &"Floor_WoodLight" if style == "plaster"
				else &"Floor_Brick",
				Vector3((float(ix) - float(tiles - 1) * 0.5) * MODULE, 0.04,
					(float(iz) - float(tiles - 1) * 0.5) * MODULE),
				0.0, 1.0, K.TONE_WOOD)
	K.collider_box(house, house_name + "_sol", Vector3(0, -0.12, 0),
		Vector3(float(span) + 0.2, 0.3, float(span) + 0.2))
	# Quatre faces : porte au sud local, fenêtres en face, pleins ailleurs.
	for i: int in range(tiles):
		var x: float = (float(i) - float(tiles - 1) * 0.5) * MODULE
		if i == tiles / 2:
			_door_wall(house, Vector3(x, 0, offset), 0.0, wall_door)
		else:
			_wall(house, Vector3(x, 0, offset), 0.0, wall_window)
		_wall(house, Vector3(x, 0, -offset), 180.0, wall_full)
		var z: float = (float(i) - float(tiles - 1) * 0.5) * MODULE
		_wall(house, Vector3(-offset, 0, z), 90.0, wall_full)
		_wall(house, Vector3(offset, 0, z), 270.0,
			wall_window if i == tiles / 2 else wall_full)
	for corner: Vector3 in [Vector3(-half, 0, -half), Vector3(half, 0, -half),
			Vector3(-half, 0, half), Vector3(half, 0, half)]:
		K.module(house, &"Corner_Exterior_Wood", corner, 0.0, 1.0, K.TONE_WOOD)
	# Toit à deux pentes + pignons.
	K.module(house, StringName("Roof_RoundTiles_%dx%d" % [span, span]),
		Vector3(0, WALL_H, 0), 0.0, 1.0, K.TONE_CLOTH)
	for side: int in [-1, 1]:
		K.module(house, StringName("Roof_Front_Brick%d" % span),
			Vector3(0, WALL_H, half * float(side)),
			0.0 if side > 0 else 180.0, 1.0, K.TONE_STONE)
	# Meublé : une maison vide est une boîte avec un toit.
	K.module(house, &"Table_Large", Vector3(-1.1, 0.08, -0.7), 15.0, 0.9,
		K.TONE_WOOD)
	K.module(house, &"Stool", Vector3(-1.9, 0.08, -0.2), 0.0, 1.0, K.TONE_WOOD)
	K.module(house, &"Barrel", Vector3(1.9, 0.08, -1.7), 0.0, 1.0, K.TONE_WOOD)
	K.module(house, &"Bed_Twin1", Vector3(1.6, 0.08, 1.6), -90.0, 0.85,
		K.TONE_CLOTH)


func _wall(parent: Node3D, at: Vector3, yaw: float, kind: StringName) -> void:
	K.module(parent, kind, at, yaw, 1.0, K.TONE_STONE)
	var along: Vector3 = Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
	var thick: Vector3 = Vector3(absf(along.z), 0, absf(along.x)) * 0.4
	var span: Vector3 = along.abs() * MODULE
	K.collider_box(parent, String(kind) + "_col_%d" % parent.get_child_count(),
		at + Vector3(0, WALL_H * 0.5, 0),
		Vector3(maxf(span.x, thick.x), WALL_H, maxf(span.z, thick.z)))


func _door_wall(parent: Node3D, at: Vector3, yaw: float,
		kind: StringName) -> void:
	K.module(parent, kind, at, yaw, 1.0, K.TONE_STONE)
	var along: Vector3 = Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
	var jamb: float = (MODULE - DOOR_GAP) * 0.5
	for side: float in [-1.0, 1.0]:
		var centre: Vector3 = at + along * side * (DOOR_GAP + jamb) * 0.5 \
			+ Vector3(0, WALL_H * 0.5, 0)
		var size: Vector3 = along.abs() * jamb + Vector3(0.4, 0, 0.4) \
			* Vector3(absf(along.z), 0, absf(along.x))
		K.collider_box(parent, "jambage_%d" % parent.get_child_count(), centre,
			Vector3(maxf(size.x, 0.4), WALL_H, maxf(size.z, 0.4)))
	K.collider_box(parent, "linteau_%d" % parent.get_child_count(),
		at + Vector3(0, WALL_H - 0.4, 0),
		Vector3(maxf(along.abs().x * MODULE, 0.4), 0.8,
			maxf(along.abs().z * MODULE, 0.4)))


func _poi_area() -> void:
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Village de la rivière"
	poi.region = "r03_val_de_neris"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 16.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
