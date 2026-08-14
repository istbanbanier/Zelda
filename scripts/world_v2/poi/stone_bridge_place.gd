## ARCHE DE PIERRE (`valley.poi.stone_bridge.01`, r03) — le pont du gué
## central, plus ancien que tout le bâti de la vallée.
##
## REJET V2.3-A : « un arc blanc lisse, ni tablier, ni voussoirs, ni
## parapets, ni culées — une primitive ». Refait ici comme un ouvrage
## d'art : appareil de pierre ocre à joints, voussoirs en coin, tympans,
## tablier RÉELLEMENT traversable, parapets partiellement ruinés, culées
## ancrées dans les deux berges, gravats dans le lit.
##
## IMPLANTATION MESURÉE (`probe_site_section`, coupe centrée (-10, 8)) :
## le lit court d'est en ouest ; à `x = -18` la tranchée va de `z = 14`
## (berge sud, sol −0,6) à `z = -2` (berge nord, sol −1,1), et le fil
## d'eau passe au milieu. C'est aussi la SEULE fenêtre libre : le gué
## central `(-4, 12)` est sondé par huit rayons de 12 m (ISS-032) — à
## `x ≤ -16`, tout point est à plus de 12 m ; à l'ouest de `x = -21`
## commence la confluence soudée en V2.2R.2, intouchable. Le pont vit
## donc dans la bande `x ∈ [-20, -16]`, et se lit depuis le gué.
class_name StoneBridgePlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## Axe du pont en coordonnées LOCALES (racine du lieu = berge sud).
const SOUTH_END: Vector2 = Vector2(-8.0, -8.0)
const NORTH_END: Vector2 = Vector2(-8.0, -24.0)
const DECK_HALF_W: float = 2.0
const PARAPET_H: float = 0.95
const ARCH_RISE: float = 4.1
## Pierre ocre du langage des ruines (VISUAL_ASSET_BIBLE §1.4).
const COL_ASHLAR: Color = Color(0.60, 0.50, 0.38)
const COL_VOUSSOIR: Color = Color(0.66, 0.56, 0.43)
const COL_SPANDREL: Color = Color(0.55, 0.46, 0.36)
const COL_DECK: Color = Color(0.52, 0.47, 0.40)


func default_place_id() -> StringName:
	return &"valley.poi.stone_bridge.01"


func _build() -> void:
	var south_ground: float = ground_local_y(SOUTH_END.x, SOUTH_END.y)
	var north_ground: float = ground_local_y(NORTH_END.x, NORTH_END.y)
	var springing: float = maxf(south_ground, north_ground) + 0.35
	var crown: float = springing + ARCH_RISE
	var deck_y: float = crown + 0.85
	var span: float = SOUTH_END.distance_to(NORTH_END)
	var axis: Vector3 = Vector3(NORTH_END.x - SOUTH_END.x, 0.0,
		NORTH_END.y - SOUTH_END.y).normalized()
	var across: Vector3 = Vector3(-axis.z, 0.0, axis.x)
	var yaw: float = rad_to_deg(atan2(axis.x, axis.z))

	var bridge: Node3D = Node3D.new()
	bridge.name = "Ouvrage"
	add_child(bridge)

	_abutment(bridge, "CuleeSud", SOUTH_END, south_ground, springing, axis,
		across, yaw, 1.0)
	_abutment(bridge, "CuleeNord", NORTH_END, north_ground, springing, axis,
		across, yaw, -1.0)
	_arch_ring(bridge, springing, crown, span, axis, across, yaw)
	_spandrels_and_deck(bridge, springing, crown, deck_y, span, axis, across,
		yaw)
	_parapets(bridge, deck_y, span, axis, across, yaw)
	_rubble(bridge, springing, span, axis, across)

	declare_support(Vector3(SOUTH_END.x, south_ground, SOUTH_END.y))
	declare_support(Vector3(NORTH_END.x, north_ground, NORTH_END.y))

	# — Le pied de lecture, sur la berge sud, à la racine du lieu :
	# dalles d'approche et stèle du fragment d'histoire.
	for slab: Array in [[-2.0, -1.4], [-3.6, -3.0], [-5.2, -4.6],
			[-6.6, -6.2]]:
		K.module(self, &"RockPath_Square_Wide",
			_seated(float(slab[0]), float(slab[1])),
			float(slab[0]) * 41.0, 1.0, K.TONE_STONE)
	var stele_at: Vector3 = _seated(-4.0, -0.6)
	K.stone_block(self, "Stele", stele_at + Vector3(0, 1.05, 0),
		Vector3(0.85, 2.1, 0.7), 18.0, COL_ASHLAR, 4021, 0.07)
	K.stone_block(self, "SteleSocle", stele_at + Vector3(0, 0.14, 0),
		Vector3(1.5, 0.28, 1.3), 12.0, COL_ASHLAR, 4022, 0.05)
	declare_support(stele_at)
	K.module(self, &"Prop_Vine1", _seated(-4.9, -1.1), 60.0, 0.9, K.TONE_PLANT)

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Arche de pierre"
	poi.region = "r03_val_de_neris"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 16.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.STORY,
		_seated(-2.6, -0.2) + Vector3(0, 0.15, 0), Vector3(1.4, 0.0, 1.0))


## CULÉE : massif d'appareil ancré dans la berge, en retrait par gradins —
## la pierre entre dans le talus, elle ne se pose pas dessus.
func _abutment(parent: Node3D, part_name: String, end_xz: Vector2,
		ground: float, springing: float, axis: Vector3, across: Vector3,
		yaw: float, inward: float) -> void:
	var pile: Node3D = Node3D.new()
	pile.name = part_name
	parent.add_child(pile)
	var base: Vector3 = Vector3(end_xz.x, ground - 1.4, end_xz.y)
	var courses: int = 7
	var seed_base: int = 900 + int(absf(end_xz.y) * 10.0)
	for course: int in range(courses):
		var y: float = base.y + 0.42 * float(course) + 0.21
		if y > springing + 0.9:
			break
		# Le massif s'élargit vers le bas et rentre dans la berge.
		var width: float = 5.6 - 0.14 * float(course)
		var depth: float = 3.9 - 0.10 * float(course)
		var blocks: int = 3
		for b: int in range(blocks):
			var offset: float = (float(b) - float(blocks - 1) * 0.5) \
				* (width / float(blocks))
			var jitter: float = float((course * 7 + b * 13) % 5) * 0.03
			var at: Vector3 = Vector3(end_xz.x, y, end_xz.y) \
				+ across * offset \
				+ axis * (-inward) * (0.35 + jitter + 0.05 * float(course))
			K.stone_block(pile, "%s_bloc_%d_%d" % [part_name, course, b], at,
				Vector3(width / float(blocks) + 0.10, 0.46, depth),
				yaw + float((course + b) % 3) * 1.6 - 1.6, COL_ASHLAR,
				seed_base + course * 11 + b, 0.05)
	# Une seule masse de collision : la culée est un obstacle, pas 21.
	K.collider_box(parent, part_name + "_col",
		Vector3(end_xz.x, (base.y + springing) * 0.5, end_xz.y)
			+ axis * (-inward) * 0.9,
		Vector3(5.4, springing - base.y + 0.6, 3.4), yaw)


## BANDEAU DE VOUSSOIRS : des claveaux en coin, joints radiaux visibles,
## posés en plein cintre entre les deux naissances.
func _arch_ring(parent: Node3D, springing: float, crown: float, span: float,
		axis: Vector3, across: Vector3, yaw: float) -> void:
	var ring: Node3D = Node3D.new()
	ring.name = "Bandeau"
	parent.add_child(ring)
	var center: Vector3 = Vector3(
		(SOUTH_END.x + NORTH_END.x) * 0.5, springing,
		(SOUTH_END.y + NORTH_END.y) * 0.5)
	var half_span: float = span * 0.5
	var voussoirs: int = 17
	for i: int in range(voussoirs):
		var t: float = (float(i) + 0.5) / float(voussoirs)
		var angle: float = PI * t
		# Ellipse surbaissée : plus large que haute, comme un pont ancien.
		var point: Vector3 = center \
			+ axis * (cos(angle) * half_span) \
			+ Vector3(0.0, sin(angle) * (crown - springing), 0.0)
		var tangent: Vector3 = (axis * (-sin(angle) * half_span)
			+ Vector3(0.0, cos(angle) * (crown - springing), 0.0)).normalized()
		# Chaque claveau est tourné pour que son joint soit RADIAL.
		var depth: float = 1.30 - 0.16 * sin(angle)
		for side: int in range(3):
			var lateral: float = (float(side) - 1.0) * 1.28
			# Repère du claveau : X = radial (épaisseur du bandeau),
			# Y = TANGENTIEL (le pas de l'arc), Z = latéral (largeur du
			# pont). Mesuré à l'inspection : 0,92 en tangentiel pour un pas
			# d'arc de 1,14 ouvrait le ciel entre chaque claveau.
			var block: MeshInstance3D = K.stone_block(ring,
				"Voussoir_%d_%d" % [i, side],
				point + across * lateral,
				Vector3(1.30, 1.26, depth + 0.42), 0.0, COL_VOUSSOIR,
				5100 + i * 5 + side, 0.04)
			var up: Vector3 = tangent
			var forward: Vector3 = across
			block.basis = Basis(forward.cross(up).normalized(), up, forward)


## TYMPANS et TABLIER : le mur de front remplit entre l'extrados et le
## tablier ; le tablier est une chaussée réellement praticable.
func _spandrels_and_deck(parent: Node3D, springing: float, crown: float,
		deck_y: float, span: float, axis: Vector3, across: Vector3,
		yaw: float) -> void:
	var spandrel: Node3D = Node3D.new()
	spandrel.name = "Tympans"
	parent.add_child(spandrel)
	var center: Vector3 = Vector3(
		(SOUTH_END.x + NORTH_END.x) * 0.5, 0.0,
		(SOUTH_END.y + NORTH_END.y) * 0.5)
	var half_span: float = span * 0.5
	var courses: int = 12
	for i: int in range(courses):
		var t: float = (float(i) + 0.5) / float(courses)
		var along: float = lerpf(-half_span - 1.2, half_span + 1.2, t)
		# Hauteur du remplissage : du dos de l'arche jusqu'au tablier.
		var normalized: float = clampf(absf(along) / half_span, 0.0, 1.0)
		var extrados: float = springing \
			+ sqrt(maxf(1.0 - normalized * normalized, 0.0)) \
				* (crown - springing) + 0.55
		if extrados > deck_y - 0.25:
			continue
		var fill_h: float = deck_y - 0.22 - extrados
		var rows: int = maxi(1, int(fill_h / 0.5))
		for row: int in range(rows):
			var y: float = extrados + fill_h * (float(row) + 0.5) / float(rows)
			for side: int in [-1, 1]:
				# X = LATÉRAL (épaisseur du mur de front), Z = le long du
				# pont : permuté au premier jet, le tympan était une file
				# de plaquettes de 0,62 espacées de 1,55.
				K.stone_block(spandrel, "Tympan_%d_%d_%d" % [i, row, side],
					center + axis * along
						+ across * (float(side) * (DECK_HALF_W - 0.30))
						+ Vector3(0.0, y, 0.0),
					Vector3(0.86, fill_h / float(rows) - 0.04, 1.72),
					yaw + float((i + row) % 3) * 1.4, COL_SPANDREL,
					6200 + i * 9 + row * 3 + side, 0.045)
	# TABLIER : dalles de chaussée + collider unique praticable.
	var deck: Node3D = Node3D.new()
	deck.name = "Tablier"
	parent.add_child(deck)
	var slabs: int = 15
	for i: int in range(slabs):
		var t: float = (float(i) + 0.5) / float(slabs)
		var along: float = lerpf(-half_span - 2.4, half_span + 2.4, t)
		for lane: int in range(2):
			K.stone_block(deck, "Dalle_%d_%d" % [i, lane],
				center + axis * along
					+ across * ((float(lane) - 0.5) * 1.85)
					+ Vector3(0.0, deck_y - 0.14, 0.0),
				Vector3(1.75, 0.26, (span + 4.8) / float(slabs) - 0.05),
				yaw + float(i % 3) * 0.9 - 0.9, COL_DECK,
				7300 + i * 3 + lane, 0.035)
	K.collider_box(parent, "Tablier_col",
		center + Vector3(0.0, deck_y - 0.30, 0.0),
		Vector3(DECK_HALF_W * 2.0, 0.42, span + 4.8), yaw)


## PARAPETS partiellement RUINÉS : une file de blocs sur chaque bord, avec
## une brèche franche côté aval — l'ouvrage a vécu.
func _parapets(parent: Node3D, deck_y: float, span: float, axis: Vector3,
		across: Vector3, yaw: float) -> void:
	var parapets: Node3D = Node3D.new()
	parapets.name = "Parapets"
	parent.add_child(parapets)
	var center: Vector3 = Vector3(
		(SOUTH_END.x + NORTH_END.x) * 0.5, 0.0,
		(SOUTH_END.y + NORTH_END.y) * 0.5)
	var half_span: float = span * 0.5
	var count: int = 17
	for i: int in range(count):
		var t: float = (float(i) + 0.5) / float(count)
		var along: float = lerpf(-half_span - 2.2, half_span + 2.2, t)
		for side: int in [-1, 1]:
			# La brèche : quatre blocs manquants côté est, au tiers nord.
			if side == 1 and i >= 9 and i <= 12:
				continue
			var lean: float = 0.0
			var height: float = PARAPET_H
			# Deux blocs de rive descellés, penchés vers le vide.
			if side == -1 and (i == 4 or i == 13):
				lean = 7.0
				height = PARAPET_H * 0.72
			K.stone_block(parapets, "Parapet_%d_%d" % [i, side],
				center + axis * along
					+ across * (float(side) * (DECK_HALF_W - 0.26))
					+ Vector3(0.0, deck_y + height * 0.5 - 0.02, 0.0),
				Vector3(0.52, height, (span + 4.4) / float(count) - 0.07),
				yaw + float(i % 4) * 1.7 - 2.5, COL_ASHLAR,
				8400 + i * 3 + side, 0.055).rotation.z += deg_to_rad(lean)
		# Les blocs tombés de la brèche, dans le lit, sous le parapet.
	for fallen: Array in [[2.2, -1.6, 26.0], [3.4, 0.4, -40.0],
			[1.4, 1.9, 12.0]]:
		var at: Vector3 = center + axis * float(fallen[0]) \
			+ across * (DECK_HALF_W + float(fallen[1]))
		var ground: float = ground_local_y(at.x, at.z)
		K.stone_block(parapets, "Parapet_tombe_%d" % parapets.get_child_count(),
			Vector3(at.x, ground + 0.24, at.z), Vector3(0.5, 0.48, 1.05),
			yaw + float(fallen[2]), COL_ASHLAR,
			8600 + int(float(fallen[0]) * 10.0), 0.07).rotation.z += \
				deg_to_rad(float(fallen[2]) * 0.4)


## GRAVATS du lit : ce qui est tombé de l'ouvrage, posé au sol réel.
func _rubble(parent: Node3D, springing: float, span: float, axis: Vector3,
		across: Vector3) -> void:
	var rubble: Node3D = Node3D.new()
	rubble.name = "Gravats"
	parent.add_child(rubble)
	var center: Vector3 = Vector3(
		(SOUTH_END.x + NORTH_END.x) * 0.5, 0.0,
		(SOUTH_END.y + NORTH_END.y) * 0.5)
	for stone: Array in [[-5.5, 3.0, 0.9], [-2.0, -3.6, 0.7],
			[4.8, 2.6, 1.1], [6.9, -2.2, 0.8], [0.5, 4.2, 0.6]]:
		var at: Vector3 = center + axis * float(stone[0]) \
			+ across * float(stone[1])
		var ground: float = ground_local_y(at.x, at.z)
		var size: float = float(stone[2])
		K.stone_block(rubble, "Gravat_%d" % rubble.get_child_count(),
			Vector3(at.x, ground + size * 0.3, at.z),
			Vector3(size * 1.4, size * 0.62, size * 1.1),
			float(stone[0]) * 23.0, COL_SPANDREL,
			9700 + rubble.get_child_count(), 0.12)
	K.module(self, &"Prop_Vine2", Vector3(center.x + across.x * 2.4,
		ground_local_y(center.x + across.x * 2.4, center.z + across.z * 2.4),
		center.z + across.z * 2.4), 40.0, 0.9, K.TONE_PLANT)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
