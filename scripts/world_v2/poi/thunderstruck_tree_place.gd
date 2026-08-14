## ARBRE FOUDROYÉ (`valley.poi.thunderstruck_tree.01`, r02) — la
## merveille de la prairie, landmark ouest de la région : un doyen fendu
## par la foudre, mort d'un côté, têtu de l'autre.
##
## POI par affordance (contrats §2) : le tronc noirci se lit de loin
## (silhouette au-dessus de la prairie plate), le sol vitrifié raconte
## l'impact, la repousse enseigne que la foudre nourrit — et l'épice rare
## (savoir) pousse dans le creux. Aucun cyan : la foudre est PASSÉE.
class_name ThunderstruckTreePlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")


func default_place_id() -> StringName:
	return &"valley.poi.thunderstruck_tree.01"


func _build() -> void:
	# — Le doyen : DEUX troncs morts qui divergent du même pied — l'arbre
	# fendu en V par l'impact. Le grand penche, le petit est cassé net.
	var foot: Vector3 = _seated(0.0, 0.0)
	declare_support(foot)
	var trunk_a: Node3D = K.module(self, &"DeadTree_1", foot, 15.0, 1.9,
		K.TONE_CHARRED)
	if trunk_a != null:
		trunk_a.rotation.z = deg_to_rad(-9.0)
	var trunk_b: Node3D = K.module(self, &"DeadTree_2",
		foot + Vector3(0.7, 0.0, 0.4), 160.0, 1.25, K.TONE_CHARRED)
	if trunk_b != null:
		trunk_b.rotation.z = deg_to_rad(14.0)
	K.collider_box(self, "Tronc_col", foot + Vector3(0.3, 1.6, 0.2),
		Vector3(1.6, 3.2, 1.6))

	# — La FENTE pâle : le cœur du bois mis à nu entre les deux troncs
	# (bois clair, non brûlé — le contraste raconte la déchirure).
	var scar: MeshInstance3D = MeshInstance3D.new()
	scar.name = "Fente"
	var scar_box: BoxMesh = BoxMesh.new()
	scar_box.size = Vector3(0.22, 2.6, 0.5)
	scar.mesh = scar_box
	scar.material_override = K.flat_material(Color(0.82, 0.74, 0.58))
	scar.position = foot + Vector3(0.35, 1.5, 0.3)
	scar.rotation.z = deg_to_rad(-4.0)
	add_child(scar)

	# — Le sol d'impact : anneau de pierres sombres « vitrifiées », terre
	# nue en dalles sombres, branches tombées.
	for ring: Array in [[2.2, 0.4], [1.4, -1.9], [-0.9, -2.2], [-2.3, -0.5],
			[-1.7, 1.8], [0.5, 2.5]]:
		K.module(self, &"Rock_Medium_2",
			_seated(float(ring[0]), float(ring[1])),
			float(ring[0]) * 67.0, 0.8, K.TONE_CHARRED)
	for patch: Array in [[0.9, 0.9], [-0.8, 0.2], [0.1, -1.2]]:
		K.module(self, &"RockPath_Round_Wide",
			_seated(float(patch[0]), float(patch[1])),
			float(patch[1]) * 43.0, 1.1, K.TONE_CHARRED)
	var branch: Node3D = K.module(self, &"DeadTree_2", _seated(3.4, -2.6),
		75.0, 0.6, K.TONE_CHARRED)
	if branch != null:
		branch.rotation.x = deg_to_rad(78.0)

	# — La REPOUSSE : la vie revient en cercle extérieur, plus dense côté
	# soleil — et l'épice rare dans le creux du pied.
	K.module(self, &"Bush_Common_Flowers", _seated(3.8, 1.6), 30.0, 1.0,
		K.TONE_PLANT)
	K.module(self, &"Bush_Common", _seated(-3.4, 2.4), 100.0, 0.9,
		K.TONE_PLANT)
	K.module(self, &"Plant_1", _seated(2.9, -3.6), 0.0, 1.0, K.TONE_PLANT)
	K.module(self, &"Flower_4_Group", _seated(-2.8, -2.8), 55.0, 1.0,
		K.TONE_PLANT)
	K.module(self, &"Flower_3_Group", _seated(4.4, -0.8), 0.0, 1.0,
		K.TONE_PLANT)

	# — Découverte + récompense canonique (savoir — épice rare) au creux.
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Arbre foudroyé"
	poi.region = "r02_prairie_mille_fleurs"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 11.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.RECIPE,
		foot + Vector3(-0.9, 0.15, 0.8), Vector3(-1.2, 0.0, 1.2))


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
