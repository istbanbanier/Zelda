## BASSIN CONDUCTEUR (`valley.poi.conductive_basin.01`, r03) — le site
## systémique de l'école Arc Link, HABILLÉ sans toucher à sa logique.
##
## Le comportement canonique est la classe `ConductiveBasin` elle-même,
## instanciée TELLE QUELLE : son `ElectricGraph` reste ENFANT du site
## (jamais plus haut — il capterait tous les nœuds du monde), ses IDs de
## nœuds, ses ports et sa zone d'eau ne changent pas. Le filet de
## comportement vérifie la classe, le graphe et le circuit qui ATTEND.
##
## L'habillage raconte la leçon : pierre qui contient, céramique ivoire
## qui isole, cuivre patiné qui conduit — le cyan n'apparaît que sur les
## nœuds actifs du diorama lui-même.
class_name ConductiveBasinPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")


func default_place_id() -> StringName:
	return &"valley.poi.conductive_basin.01"


func _build() -> void:
	# — Le comportement canonique, intact.
	var basin: ConductiveBasin = ConductiveBasin.new()
	basin.name = "BassinConducteur"
	basin.position = Vector3(0.0, ground_local_y(0.0, 0.0) + 0.05, 0.0)
	add_child(basin)
	declare_support(Vector3(0.0, ground_local_y(0.0, 0.0), 0.0))

	# — La MARGELLE : anneau de pierres qui contient le bassin, ouvert aux
	# deux rives (les ports est/ouest restent lisibles et atteignables).
	for stone: Array in [[-3.4, 2.9, 0.7], [-1.2, 3.3, 0.6], [1.4, 3.1, 0.65],
			[3.4, 2.6, 0.6], [-3.6, -2.8, 0.65], [-1.4, -3.3, 0.7],
			[1.2, -3.2, 0.6], [3.5, -2.7, 0.68]]:
		K.module(self, &"Rock_Medium_1",
			_seated(float(stone[0]), float(stone[1])),
			float(stone[0]) * 47.0, float(stone[2]), K.TONE_STONE)
	K.collider_box(self, "Margelle_nord", _seated(0.0, 3.1) + Vector3(0, 0.5, 0),
		Vector3(7.6, 1.0, 1.0))
	K.collider_box(self, "Margelle_sud", _seated(0.0, -3.1) + Vector3(0, 0.5, 0),
		Vector3(7.6, 1.0, 1.0))
	declare_support(_seated(-3.4, 2.9))
	declare_support(_seated(3.5, -2.7))

	# — Côté SOURCE (ouest) : le socle ancien — dalles de céramique ivoire
	# (isolant) autour du pied de la source, conduit de cuivre patiné qui
	# monte du sol. La leçon se lit : l'énergie sort D'ICI.
	for plate: Array in [[-8.6, 1.2], [-9.4, -0.6], [-7.8, -1.4]]:
		K.module(self, &"Floor_Brick",
			_seated(float(plate[0]), float(plate[1])) + Vector3(0, 0.04, 0),
			float(plate[0]) * 23.0, 1.0, Color(0.92, 0.88, 0.78))
	K.module(self, &"Prop_MetalFence_Simple", _seated(-10.2, 0.4), 90.0, 0.9,
		Color(0.68, 0.52, 0.38))
	K.module(self, &"SM_Dungeon_PillarStub", _seated(-11.0, -1.0), 20.0, 0.6,
		K.TONE_DARK_STONE)

	# — Côté RÉCEPTEUR (est) : l'anneau d'arrivée sur son socle de pierre,
	# et la porte de l'énigme — le coffre attend derrière le récepteur.
	K.module(self, &"RockPath_Square_Wide", _seated(4.6, 0.2), 15.0, 1.0,
		K.TONE_STONE)
	K.module(self, &"RockPath_Square_Small_1", _seated(6.0, -0.8), 60.0, 1.0,
		K.TONE_STONE)

	# — Roseaux et verdure d'eau AUX ANGLES morts seulement : les deux
	# axes de visée (source→eau, eau→récepteur) restent dégagés.
	K.module(self, &"Plant_1", _seated(-2.6, 4.3), 0.0, 1.0, K.TONE_PLANT)
	K.module(self, &"Grass_Common_Tall", _seated(2.2, 4.1), 40.0, 1.0,
		K.TONE_PLANT)
	K.module(self, &"Plant_1", _seated(2.8, -4.2), 160.0, 0.9, K.TONE_PLANT)
	K.module(self, &"Fern_1", _seated(-2.0, -4.4), 220.0, 0.9, K.TONE_PLANT)

	# — Découverte + récompense canonique (récompense d'énigme — coffre).
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Bassin conducteur"
	poi.region = "r03_val_de_neris"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 13.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.PUZZLE,
		_seated(7.2, 1.6) + Vector3(0, 0.1, 0), Vector3(-1.4, 0.0, -0.8))


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
