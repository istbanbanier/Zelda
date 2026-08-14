## GROTTE DE LA CASCADE (`valley.poi.waterfall_cave.01`, r04) — une VRAIE
## poche intérieure, jamais un trou dans le terrain (directive V2.3 §2).
##
## Le terrain est GELÉ : la poche est BÂTIE contre la montée ouest — une
## coque de blocs de falaise en C, un toit porté, un seuil lisible ouvert
## vers la chute de l'affluent à l'est. Entrée et sortie par le même
## seuil sûr : sol continu (dalles), hauteur libre ≥ 1,9 m, aucune porte,
## aucun à-pic — le filet de comportement marche le trajet dans les deux
## sens et exige un PLAFOND réel au-dessus de l'intérieur.
##
## Metas contractuelles : `cave_threshold` (devant le seuil, dehors) et
## `cave_interior` (au fond de la poche), locales.
class_name WaterfallCavePlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## La poche : centre local, demi-largeur intérieure, hauteur sous plafond.
const POCKET_CENTER: Vector3 = Vector3(-3.0, 0.0, -1.0)
const INNER_HALF_W: float = 2.6
const INNER_H: float = 2.6


func default_place_id() -> StringName:
	return &"valley.poi.waterfall_cave.01"


func _build() -> void:
	var floor_y: float = ground_local_y(POCKET_CENTER.x, POCKET_CENTER.z)
	var threshold: Vector3 = Vector3(4.0, ground_local_y(4.0, 2.2), 2.2)
	set_meta(&"cave_threshold", threshold)
	set_meta(&"cave_interior", Vector3(POCKET_CENTER.x - 0.6, floor_y,
		POCKET_CENTER.z - 0.6))

	# — Sol intérieur : dalles de pierre en pente TRÈS douce depuis le
	# seuil (le filet refuse toute marche > 0,55 m), avec collider plein.
	var slab_root: Node3D = Node3D.new()
	slab_root.name = "SolInterieur"
	add_child(slab_root)
	var entry_y: float = ground_local_y(1.6, 0.6)
	for step: Array in [[2.8, 1.6, 0.0], [1.6, 0.6, 0.25], [0.2, -0.2, 0.5],
			[-1.4, -0.6, 0.75], [-3.0, -1.0, 1.0]]:
		var t: float = float(step[2])
		var slab_y: float = lerpf(ground_local_y(float(step[0]), float(step[1])),
			floor_y, t)
		K.collider_box(slab_root, "dalle_%d" % slab_root.get_child_count(),
			Vector3(float(step[0]), slab_y - 0.15, float(step[1])),
			Vector3(2.6, 0.3, 2.6))
		var slab: MeshInstance3D = MeshInstance3D.new()
		slab.name = "dalle_visuelle_%d" % slab_root.get_child_count()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(2.5, 0.24, 2.5)
		slab.mesh = box
		slab.material_override = K.flat_material(Color(0.42, 0.38, 0.35))
		slab.position = Vector3(float(step[0]), slab_y - 0.12, float(step[1]))
		slab.rotation.y = t * 0.5
		slab_root.add_child(slab)
	declare_support(Vector3(2.8, entry_y, 1.6))
	declare_support(Vector3(POCKET_CENTER.x, floor_y, POCKET_CENTER.z))

	# — La coque : un MASSIF de gros rochers ocres (Rock_Medium — le même
	# langage que les rochers V2.2), en C autour de la poche, ouverts vers
	# le seuil (est). À l'inspection, les panneaux CaveWall lisaient comme
	# des rectangles marron posés dans l'herbe — remplacés par des masses.
	var shell: Node3D = Node3D.new()
	shell.name = "Coque"
	add_child(shell)
	for block: Array in [
		[-6.6, -1.0, 0.0, 4.6, "Rock_Medium_1"],
		[-5.4, -4.6, 40.0, 4.2, "Rock_Medium_2"],
		[-1.6, -6.0, 80.0, 4.4, "Rock_Medium_3"],
		[2.4, -4.6, 120.0, 3.6, "Rock_Medium_1"],
		[-5.8, 2.8, -45.0, 4.3, "Rock_Medium_2"],
		[-2.2, 4.4, -85.0, 4.0, "Rock_Medium_3"],
		[2.0, 5.0, -120.0, 3.2, "Rock_Medium_2"]]:
		var piece: Node3D = K.module(shell, StringName(block[4] as String),
			_seated(float(block[0]), float(block[1])), float(block[2]),
			float(block[3]), K.TONE_STONE)
		if piece == null:
			continue
	# Colliders muraux du C (l'ouverture est reste libre, largeur 2,4 m).
	for wall: Array in [
		[-5.6, -1.0, 0.0, 2.2, 6.4], [-3.4, -4.0, 55.0, 2.2, 5.6],
		[0.6, -4.6, 100.0, 2.2, 5.0], [-3.6, 2.4, -55.0, 2.2, 5.6],
		[0.8, 3.6, -105.0, 2.2, 4.6]]:
		K.collider_box(shell, "paroi_%d" % shell.get_child_count(),
			Vector3(float(wall[0]),
				ground_local_y(float(wall[0]), float(wall[1])) + INNER_H * 0.5,
				float(wall[1])),
			Vector3(float(wall[4]), INNER_H + 2.4, 1.6), float(wall[2]))

	# — Le TOIT : gros rochers posés sur la coque + collider plafond réel
	# (le filet tire un rayon vertical depuis l'intérieur).
	var roof_y: float = floor_y + INNER_H
	var cap: Node3D = K.module(shell, &"Rock_Medium_1",
		Vector3(POCKET_CENTER.x - 0.6, roof_y + 0.2, POCKET_CENTER.z + 0.4),
		65.0, 5.2, K.TONE_STONE)
	if cap != null:
		cap.position.y = roof_y - 0.6
	var cap_east: Node3D = K.module(shell, &"Rock_Medium_3",
		Vector3(0.8, roof_y + 0.1, 0.6), -30.0, 4.0, K.TONE_STONE)
	if cap_east != null:
		cap_east.position.y = roof_y - 0.4
	K.collider_box(shell, "plafond", Vector3(POCKET_CENTER.x, roof_y + 0.5,
		POCKET_CENTER.z), Vector3(7.0, 1.0, 7.0))
	# Auvent du seuil : le plafond déborde au-dessus de l'entrée, le seuil
	# se lit comme une BOUCHE et pas comme un interstice.
	K.collider_box(shell, "auvent_seuil", Vector3(1.8, roof_y + 0.7, 1.0),
		Vector3(3.4, 0.9, 3.2), 35.0)
	# Le SOURCIL du seuil : deux montants de roche + un linteau — la bouche
	# se lit comme une bouche.
	K.module(shell, &"Rock_Medium_2", _seated(3.6, -1.2), 15.0, 2.6,
		K.TONE_STONE)
	K.module(shell, &"Rock_Medium_1", _seated(3.2, 3.8), -20.0, 2.4,
		K.TONE_STONE)
	var brow: Node3D = K.module(shell, &"Rock_Medium_3",
		Vector3(2.8, roof_y + 0.3, 1.3), 125.0, 3.2, K.TONE_STONE)
	if brow != null:
		brow.position.y = roof_y - 0.3
		declare_support(_seated(2.8, 1.3))

	# — Dehors : éboulis du seuil, fougères d'ombre, dalles d'approche.
	K.module(self, &"Rock_Medium_2", _seated(5.6, -1.6), 200.0, 1.6,
		K.TONE_STONE)
	K.module(self, &"Fern_1", _seated(4.6, 3.6), 20.0, 1.0, K.TONE_PLANT)
	K.module(self, &"Fern_1", _seated(3.0, -2.2), 160.0, 0.9, K.TONE_PLANT)
	K.module(self, &"Mushroom_Common", _seated(5.2, 3.0), 0.0, 1.0,
		K.TONE_PLANT)
	for slab: Array in [[5.4, 2.8], [4.2, 2.0]]:
		K.module(self, &"RockPath_Round_Small_1",
			_seated(float(slab[0]), float(slab[1])), float(slab[0]) * 29.0,
			1.0, K.TONE_STONE)

	# — Découverte + récompense canonique (champignon de soin, AU FOND —
	# la poche récompense d'être entrée).
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Grotte de la cascade"
	poi.region = "r04_falaises_du_couchant"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 10.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.INGREDIENT,
		Vector3(POCKET_CENTER.x - 0.8, floor_y + 0.1, POCKET_CENTER.z - 1.2),
		Vector3(1.4, 0.0, 1.4))


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
