## PYLÔNE DE RÉSONANCE (ancre §3.3 `pylon`, r07) — premier hero asset
## architectural de V2.3 : le repère vertical entre le camp et la marche
## de l'orage.
##
## Grammaire (VISUAL_ASSET_BIBLE §11.2) : base ÉTAGÉE, fût effilé, trois
## canaux creux, anneau INCOMPLET, couronne bifide asymétrique — cuivre
## patiné + céramique ivoire, émission cyan RARE (une bande runique).
##
## REJET V2.3-A : « un obélisque blanc très simple ; couronne, anneau
## et canaux trop faibles à distance ». Refait : base TRIPODE étagée en
## appareil, fût en DOUZE dosserets verticaux dont trois manquent —
## les canaux sont des vides RÉELS, pas des bandes peintes —, bandes de
## joint tous les quatre mètres, anneau incomplet épaissi, couronne
## bifide massive à coiffes de céramique. Les primitives ne servent que
## de noyau invisible.
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
## Fond de canal : plus sombre que les piliers, sinon le creux se comble
## visuellement et le canal disparaît (défaut mesuré le 2026-08-14).
const COL_CORE_STONE: Color = Color(0.24, 0.24, 0.23)
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

	# — BASE TRIPODE : trois massifs d'appareil à 120°, reliés par deux
	# lits étagés. Chaque massif a son propre appui sur le terrain gelé.
	# Six assises par pied, pas quatre : à 40 m la base de quatre assises
	# se lisait comme un simple socle. Elle doit porter le fût, donc se voir.
	var tier_y: float = 0.0
	for leg: int in range(3):
		var angle: float = TAU * float(leg) / 3.0 + 0.4
		var direction: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var foot_local: Vector3 = CENTER + direction * 4.3
		var foot_y: float = ground_local_y(foot_local.x, foot_local.z)
		# Quatre assises TRAPUES plutôt que six minces : à six, le retrait
		# régulier dessinait un escalier et les pieds paraissaient grêles.
		for course: int in range(4):
			var y: float = foot_y - base_y + 0.52 + 1.02 * float(course)
			var reach: float = 4.05 - 0.52 * float(course)
			K.stone_block(root, "Pied_%d_%d" % [leg, course],
				direction * reach + Vector3(0.0, y, 0.0),
				Vector3(3.5 - 0.22 * float(course), 1.04,
					3.0 - 0.30 * float(course)),
				rad_to_deg(-angle), COL_STONE, 9100 + leg * 9 + course, 0.05)
		declare_support(Vector3(foot_local.x, foot_y, foot_local.z))
	for lit: int in range(2):
		tier_y = 4.3 + 0.88 * float(lit)
		var radius: float = 3.25 - 0.42 * float(lit)
		for i: int in range(10):
			var angle: float = TAU * float(i) / 10.0
			K.stone_block(root, "Lit_%d_%d" % [lit, i],
				Vector3(cos(angle) * radius, tier_y, sin(angle) * radius),
				Vector3(1.15, 0.82, TAU * radius / 10.0 * 1.35),
				rad_to_deg(-angle), COL_STONE if lit == 0 else COL_IVORY,
				9200 + lit * 13 + i, 0.045)
	tier_y += 0.58
	var body_col: StaticBody3D = StaticBody3D.new()
	body_col.name = "Base_col"
	body_col.collision_layer = 1
	body_col.collision_mask = 0
	var body_shape: CollisionShape3D = CollisionShape3D.new()
	var cylinder_shape: CylinderShape3D = CylinderShape3D.new()
	cylinder_shape.radius = 4.2
	cylinder_shape.height = 3.6
	body_shape.shape = cylinder_shape
	body_col.add_child(body_shape)
	body_col.position = Vector3(0, 1.8, 0)
	root.add_child(body_col)

	# — FÛT : DOUZE dosserets verticaux sur un anneau, TROIS manquants à
	# 120° — les canaux sont donc des vides réels, visibles en contre-jour
	# à distance. Cinq registres, séparés par des bandes de joint.
	# UN CANAL N'EST PAS UNE BANDE PEINTE — mesuré sur la capture du
	# 2026-08-14. Douze dosserets jointifs (tangentielle = 1,05 × l'arc)
	# formaient un cylindre presque plein : les trois manquants ne
	# laissaient qu'une rainure de quelques pixels à 37 m, et le lead a
	# raison de dire que les canaux sont « trop faibles à distance ».
	#
	# Correction structurelle : un NOYAU plein et sombre à l'intérieur,
	# puis des PILIERS détachés à l'extérieur. Le canal devient alors ce
	# qu'il est dans une architecture réelle — le fond d'ombre entre deux
	# piliers — et il se lit d'autant mieux que le soleil est rasant.
	var shaft_base: float = tier_y
	var shaft_top: float = 25.2
	var registers: int = 5
	var slots: int = 12
	for r: int in range(registers):
		var t0: float = float(r) / float(registers)
		var t1: float = float(r + 1) / float(registers)
		var y0: float = lerpf(shaft_base, shaft_top, t0)
		var y1: float = lerpf(shaft_base, shaft_top, t1)
		var radius: float = lerpf(2.45, 1.45, (t0 + t1) * 0.5)
		var core_radius: float = radius - 0.62
		# Le noyau : douze pans jointifs, pierre sombre — c'est le FOND
		# des canaux, et il ne doit jamais briller.
		for i: int in range(slots):
			var core_angle: float = TAU * float(i) / float(slots) + 0.18
			K.stone_block(root, "Noyau_%d_%d" % [r, i],
				Vector3(cos(core_angle) * core_radius, (y0 + y1) * 0.5,
					sin(core_angle) * core_radius),
				Vector3(0.36, y1 - y0 + 0.10,
					TAU * core_radius / float(slots) * 1.30),
				rad_to_deg(-core_angle), COL_CORE_STONE,
				9250 + r * 19 + i, 0.03)
		for i: int in range(slots):
			if i % 4 == 1:
				continue
			var angle: float = TAU * float(i) / float(slots) + 0.18
			# Tangentielle 0,74 × l'arc : les piliers NE se touchent plus.
			K.stone_block(root, "Dosseret_%d_%d" % [r, i],
				Vector3(cos(angle) * radius, (y0 + y1) * 0.5,
					sin(angle) * radius),
				Vector3(0.92, y1 - y0 - 0.30,
					TAU * radius / float(slots) * 0.74),
				rad_to_deg(-angle), COL_COPPER, 9300 + r * 17 + i, 0.035)
		# Bande de joint : une couronne de céramique ivoire fissurée, qui
		# ceinture piliers ET canaux — elle donne l'étage et le rythme.
		for i: int in range(slots):
			var angle: float = TAU * float(i) / float(slots) + 0.18
			K.stone_block(root, "Joint_%d_%d" % [r, i],
				Vector3(cos(angle) * (radius + 0.10), y1 - 0.14,
					sin(angle) * (radius + 0.10)),
				Vector3(0.62, 0.40, TAU * radius / float(slots) * 1.18),
				rad_to_deg(-angle), COL_IVORY, 9400 + r * 17 + i, 0.05)
	var shaft_body: StaticBody3D = StaticBody3D.new()
	shaft_body.name = "Fut_col"
	shaft_body.collision_layer = 1
	shaft_body.collision_mask = 0
	var shaft_shape: CollisionShape3D = CollisionShape3D.new()
	var shaft_cylinder: CylinderShape3D = CylinderShape3D.new()
	shaft_cylinder.radius = 2.3
	shaft_cylinder.height = shaft_top - shaft_base
	shaft_shape.shape = shaft_cylinder
	shaft_body.add_child(shaft_shape)
	shaft_body.position = Vector3(0, (shaft_base + shaft_top) * 0.5, 0)
	root.add_child(shaft_body)

	# — LE COURANT : une seule veine cyan, logée AU FOND d'un canal creux
	# (là où le vide laisse voir le cœur du fût).
	# Elle était logée à r = 1,25 quand le fût en fait 2,45 : invisible sur
	# TOUTES les captures. Elle vit maintenant sur la face du noyau, au
	# fond du canal ouvert — visible dans la fente, cachée ailleurs.
	# Un seul canal sur trois brille : le cyan reste rare (§1.4).
	var vein_angle: float = TAU * 5.0 / 12.0 + 0.18
	for r: int in range(registers):
		var t0: float = float(r) / float(registers)
		var t1: float = float(r + 1) / float(registers)
		var y0: float = lerpf(shaft_base, shaft_top, t0)
		var y1: float = lerpf(shaft_base, shaft_top, t1)
		var radius: float = lerpf(2.45, 1.45, (t0 + t1) * 0.5) - 0.34
		var vein: MeshInstance3D = MeshInstance3D.new()
		vein.name = "VeineDeResonance_%d" % r
		vein.mesh = K.irregular_box_mesh(
			Vector3(0.12, y1 - y0 - 0.55, 0.52), 0.02, 9500 + r)
		vein.material_override = K.flat_material(Color(0.26, 0.40, 0.43),
			COL_CYAN_CORE, 1.5)
		vein.position = Vector3(cos(vein_angle) * radius,
			(y0 + y1) * 0.5, sin(vein_angle) * radius)
		vein.rotation.y = -vein_angle
		root.add_child(vein)

	# — ANNEAU INCOMPLET, ÉPAISSI : dix claveaux de bronze sur douze, le
	# cercle ouvert de l'Œil-Tempête, incliné.
	var ring: Node3D = Node3D.new()
	ring.name = "Anneau"
	# 26,4 m plaçait l'anneau DANS la fourche : les deux se traversaient et
	# le sommet devenait une grappe illisible (capture du 2026-08-14).
	# Descendu sous la couronne, l'anneau redevient un cercle distinct.
	ring.position = Vector3(0, 22.3, 0)
	ring.rotation.z = deg_to_rad(9.0)
	root.add_child(ring)
	# Épaissi : 1,05 × 0,95 se lisait comme un fil de fer à 37 m. Deux
	# rangs décalés donnent au cercle une VRAIE section, donc une ombre.
	for i: int in range(14):
		if i in [5, 6, 10]:
			continue
		var angle: float = TAU * float(i) / 14.0
		K.stone_block(ring, "Claveau_%d" % i,
			Vector3(cos(angle) * 4.35, 0.0, sin(angle) * 4.35),
			Vector3(1.55, 1.45, TAU * 4.35 / 14.0 * 1.14),
			rad_to_deg(-angle), COL_COPPER, 9600 + i, 0.05)
		K.stone_block(ring, "ClaveauDoublure_%d" % i,
			Vector3(cos(angle) * 3.85, -0.28, sin(angle) * 3.85),
			Vector3(0.95, 0.85, TAU * 3.85 / 14.0 * 1.10),
			rad_to_deg(-angle), COL_IVORY, 9640 + i, 0.06)
	# Deux consoles qui rattachent l'anneau au fût : sans elles, il flotte.
	for bracket: int in range(2):
		var bracket_angle: float = PI * 0.5 + PI * float(bracket)
		K.stone_block(ring, "Console_%d" % bracket,
			Vector3(cos(bracket_angle) * 2.6, -0.15,
				sin(bracket_angle) * 2.6),
			Vector3(2.6, 0.62, 0.72), rad_to_deg(-bracket_angle),
			COL_COPPER, 9660 + bracket, 0.05)

	# — COURONNE BIFIDE : deux dents massives de hauteurs inégales,
	# coiffées d'ivoire — la fourche qui appelle la foudre.
	# Élargies et allongées : à 0,95 m de section, la fourche disparaissait
	# dans le ciel. C'est elle qui doit rester lisible en vignette.
	for prong: Array in [[1.45, 8.6, 1.45, "DentHaute"],
			[-1.25, 6.0, 1.20, "DentBasse"]]:
		var prong_x: float = float(prong[0])
		var prong_h: float = float(prong[1])
		var prong_w: float = float(prong[2])
		# DEUX segments par dent, presque droits : à trois segments écartés
		# de 0,7 et vrillés de 6°, la fourche devenait une griffe confuse
		# qui se mêlait à l'anneau (capture du 2026-08-14). Une fourche se
		# lit par son ÉCART entre deux dents, pas par le nombre de pièces.
		for segment: int in range(2):
			var t: float = (float(segment) + 0.5) / 2.0
			var block: MeshInstance3D = K.stone_block(root,
				"%s_%d" % [prong[3], segment],
				Vector3(prong_x * (0.85 + t * 0.30),
					shaft_top - 0.6 + prong_h * t,
					0.10 * prong_x * t),
				Vector3(prong_w * (1.10 - t * 0.22), prong_h / 2.0 + 0.12,
					prong_w * (1.20 - t * 0.24)),
				float(segment) * 2.0, COL_COPPER,
				9700 + int(prong_x * 10.0) + segment, 0.05)
			block.rotation.z = deg_to_rad(-3.0 * signf(prong_x))
		K.stone_block(root, String(prong[3]) + "_coiffe",
			Vector3(prong_x * 1.15, shaft_top - 0.6 + prong_h + 0.34,
				0.10 * prong_x),
			Vector3(prong_w * 1.05, 0.85, prong_w * 1.15),
			-4.0 * signf(prong_x), COL_IVORY,
			9800 + int(prong_x * 10.0), 0.07)

	# — LA TERRASSE d'arrivée : l'ancre de route reste le parvis.
	for slab: Array in [[0.0, 0.0], [2.2, 1.0], [4.4, 1.9], [1.2, -1.6]]:
		K.module(self, &"RockPath_Square_Wide",
			_seated(float(slab[0]), float(slab[1])),
			float(slab[0]) * 31.0, 1.1, K.TONE_STONE)
	K.module(self, &"Pot_1", _seated(3.0, 6.8), 0.0, 1.0, K.TONE_STONE)
	K.module(self, &"Rope_1", _seated(4.2, 6.2), 70.0, 1.0, K.TONE_WOOD)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
