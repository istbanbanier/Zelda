## PYLÔNE DE RÉSONANCE (ancre §3.3 `pylon`, r07) — premier hero asset
## architectural de V2.3 : le repère vertical entre le camp et la marche
## de l'orage.
##
## Grammaire (VISUAL_ASSET_BIBLE §11.2) : base ÉTAGÉE, fût effilé, trois
## canaux creux, anneau INCOMPLET, couronne bifide asymétrique — cuivre
## patiné + céramique ivoire, émission cyan RARE (une bande runique).
##
## Implantation MESURÉE : l'ancre `(115, 18, −25)` est un jalon des
## routes principale ET des hauteurs — la structure est donc décalée en
## local (9.0, 4.5) (l'AABB du socle laisse > 1,2 m aux couloirs), sa terrasse d'arrivée reste le point de route ; le
## rayon de l'ancre touche le terrain nu ; les colliders (r ≤ 4 m)
## laissent ≥ 1,5 m aux couloirs de route ; les rayons de visée gelés de
## cam02/cam03 passent à plus de 9 m.
class_name ResonancePylonLandmark
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## Centre local de la structure (l'ancre reste libre).
const CENTER: Vector3 = Vector3(9.0, 0.0, 4.5)
const COL_STONE: Color = Color(0.55, 0.48, 0.42)
const COL_COPPER: Color = Color(0.46, 0.50, 0.43)
const COL_IVORY: Color = Color(0.88, 0.84, 0.74)
const COL_CYAN_CORE: Color = Color(0.13, 0.85, 0.93)


func default_place_id() -> StringName:
	return &"pylon"


func _build() -> void:
	var base_y: float = ground_local_y(CENTER.x, CENTER.z)
	var root: Node3D = Node3D.new()
	root.name = "Structure"
	root.position = Vector3(CENTER.x, base_y, CENTER.z)
	add_child(root)
	declare_support(Vector3(CENTER.x, base_y, CENTER.z))

	# — Base ÉTAGÉE : trois tambours de pierre décroissants, joints de
	# céramique ivoire entre les lits.
	var tier_y: float = 0.0
	for tier: Array in [[4.0, 1.3], [3.2, 1.15], [2.5, 1.0]]:
		var radius: float = float(tier[0])
		var height: float = float(tier[1])
		_drum(root, "Tambour_%d" % root.get_child_count(),
			Vector3(0, tier_y + height * 0.5, 0), radius, radius * 0.94,
			height, COL_STONE)
		_drum(root, "Joint_%d" % root.get_child_count(),
			Vector3(0, tier_y + height + 0.06, 0), radius * 0.9,
			radius * 0.9, 0.12, COL_IVORY)
		tier_y += height + 0.12
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Base_col"
	body.collision_layer = 1
	body.collision_mask = 0
	var body_shape: CollisionShape3D = CollisionShape3D.new()
	var cylinder_shape: CylinderShape3D = CylinderShape3D.new()
	cylinder_shape.radius = 4.0
	cylinder_shape.height = 3.8
	body_shape.shape = cylinder_shape
	body.add_child(body_shape)
	body.position = Vector3(0, 1.9, 0)
	root.add_child(body)

	# — Trois CONTREFORTS inclinés à 120°, chacun avec son propre appui.
	for i: int in range(3):
		var angle: float = TAU * float(i) / 3.0 + 0.5
		var direction: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var foot_local: Vector3 = CENTER + direction * 4.8
		var foot_y: float = ground_local_y(foot_local.x, foot_local.z)
		var buttress: MeshInstance3D = MeshInstance3D.new()
		buttress.name = "Contrefort_%d" % i
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(1.1, 5.6, 1.4)
		buttress.mesh = box
		buttress.material_override = K.flat_material(COL_STONE)
		buttress.position = Vector3(direction.x * 3.4,
			foot_y - base_y + 2.4, direction.z * 3.4)
		buttress.look_at_from_position(buttress.position,
			buttress.position + direction.cross(Vector3.UP), Vector3.UP)
		buttress.rotate_object_local(Vector3(1, 0, 0), deg_to_rad(-16.0))
		root.add_child(buttress)
		declare_support(Vector3(foot_local.x, foot_y, foot_local.z))

	# — FÛT effilé : six tambours de cuivre patiné, r 2,2 → 1,1, avec
	# trois CANAUX creux (bandes sombres) sur toute la montée.
	var shaft_base: float = tier_y
	var shaft_top: float = 24.0
	var segments: int = 6
	for s: int in range(segments):
		var t0: float = float(s) / float(segments)
		var t1: float = float(s + 1) / float(segments)
		var y0: float = lerpf(shaft_base, shaft_top, t0)
		var y1: float = lerpf(shaft_base, shaft_top, t1)
		_drum(root, "Fut_%d" % s, Vector3(0, (y0 + y1) * 0.5, 0),
			lerpf(2.2, 1.1, t0), lerpf(2.2, 1.1, t1), y1 - y0, COL_COPPER)
	for i: int in range(3):
		var angle: float = TAU * float(i) / 3.0 + 1.1
		var channel: MeshInstance3D = MeshInstance3D.new()
		channel.name = "Canal_%d" % i
		var channel_box: BoxMesh = BoxMesh.new()
		channel_box.size = Vector3(0.34, shaft_top - shaft_base - 0.6, 0.5)
		channel.mesh = channel_box
		channel.material_override = K.flat_material(Color(0.20, 0.19, 0.18))
		var mid_r: float = 1.55
		channel.position = Vector3(cos(angle) * mid_r,
			(shaft_base + shaft_top) * 0.5, sin(angle) * mid_r)
		channel.rotation.y = -angle + PI * 0.5
		channel.rotation.z = deg_to_rad(2.1)
		root.add_child(channel)
	# La bande RUNIQUE : l'unique émission cyan, étroite, face nord.
	var runes: MeshInstance3D = MeshInstance3D.new()
	runes.name = "BandeRunique"
	var rune_box: BoxMesh = BoxMesh.new()
	rune_box.size = Vector3(0.22, 9.0, 0.1)
	runes.mesh = rune_box
	runes.material_override = K.flat_material(Color(0.30, 0.44, 0.46),
		COL_CYAN_CORE, 1.15)
	runes.position = Vector3(0.0, shaft_base + 6.0, -1.72)
	root.add_child(runes)
	var shaft_body: StaticBody3D = StaticBody3D.new()
	shaft_body.name = "Fut_col"
	shaft_body.collision_layer = 1
	shaft_body.collision_mask = 0
	var shaft_shape: CollisionShape3D = CollisionShape3D.new()
	var shaft_cylinder: CylinderShape3D = CylinderShape3D.new()
	shaft_cylinder.radius = 2.1
	shaft_cylinder.height = shaft_top - shaft_base
	shaft_shape.shape = shaft_cylinder
	shaft_body.add_child(shaft_shape)
	shaft_body.position = Vector3(0, (shaft_base + shaft_top) * 0.5, 0)
	root.add_child(shaft_body)

	# — ANNEAU INCOMPLET : douze segments prévus, trois manquent — le
	# cercle ouvert de l'Œil-Tempête, incliné de 8°.
	var ring: Node3D = Node3D.new()
	ring.name = "Anneau"
	ring.position = Vector3(0, 26.2, 0)
	ring.rotation.z = deg_to_rad(8.0)
	root.add_child(ring)
	for i: int in range(12):
		if i in [4, 5, 9]:
			continue
		var angle: float = TAU * float(i) / 12.0
		var segment: MeshInstance3D = MeshInstance3D.new()
		segment.name = "Anneau_seg_%d" % i
		var segment_box: BoxMesh = BoxMesh.new()
		segment_box.size = Vector3(1.9, 0.45, 0.4)
		segment.mesh = segment_box
		segment.material_override = K.flat_material(COL_COPPER)
		segment.position = Vector3(cos(angle) * 3.3, 0.0, sin(angle) * 3.3)
		segment.rotation.y = -angle + PI * 0.5
		ring.add_child(segment)

	# — COURONNE BIFIDE asymétrique : deux dents de hauteurs différentes,
	# coiffées de céramique — la fourche qui appelle la foudre.
	for prong: Array in [[0.75, 6.6, 0.36, "DentHaute"],
			[-0.65, 4.8, 0.30, "DentBasse"]]:
		var prong_x: float = float(prong[0])
		var prong_h: float = float(prong[1])
		var prong_w: float = float(prong[2])
		var tooth: MeshInstance3D = MeshInstance3D.new()
		tooth.name = prong[3] as String
		var tooth_box: BoxMesh = BoxMesh.new()
		tooth_box.size = Vector3(prong_w, prong_h, prong_w * 1.4)
		tooth.mesh = tooth_box
		tooth.material_override = K.flat_material(COL_COPPER)
		tooth.position = Vector3(prong_x, 24.0 + prong_h * 0.5, 0.15 * prong_x)
		tooth.rotation.z = deg_to_rad(-4.0 * signf(prong_x))
		root.add_child(tooth)
		var tip: MeshInstance3D = MeshInstance3D.new()
		tip.name = (prong[3] as String) + "_pointe"
		var tip_box: BoxMesh = BoxMesh.new()
		tip_box.size = Vector3(prong_w * 1.6, 0.5, prong_w * 2.0)
		tip.mesh = tip_box
		tip.material_override = K.flat_material(COL_IVORY)
		tip.position = tooth.position + Vector3(0, prong_h * 0.5 + 0.2, 0)
		tip.rotation.z = tooth.rotation.z
		root.add_child(tip)

	# — La TERRASSE d'arrivée : l'ancre de route reste le parvis — dalles
	# et deux jarres, aucun collider (le jalon se marche).
	for slab: Array in [[0.0, 0.0], [2.2, 1.0], [4.4, 1.9], [1.2, -1.6]]:
		K.module(self, &"RockPath_Square_Wide",
			_seated(float(slab[0]), float(slab[1])),
			float(slab[0]) * 31.0, 1.1, K.TONE_STONE)
	K.module(self, &"Pot_1", _seated(3.0, 6.8), 0.0, 1.0, K.TONE_STONE)
	K.module(self, &"Rope_1", _seated(4.2, 6.2), 70.0, 1.0, K.TONE_WOOD)


## Un tambour conique plein, painterly.
func _drum(parent: Node3D, drum_name: String, at: Vector3, bottom_r: float,
		top_r: float, height: float, color: Color) -> void:
	var drum: MeshInstance3D = MeshInstance3D.new()
	drum.name = drum_name
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.bottom_radius = bottom_r
	mesh.top_radius = top_r
	mesh.height = height
	mesh.radial_segments = 14
	drum.mesh = mesh
	drum.material_override = K.flat_material(color)
	drum.position = at
	parent.add_child(drum)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
