## CAMP / CHECKPOINT (r05_terrasse_du_camp) — le premier lieu habité sûr.
##
## Langage (VISUAL_ASSET_BIBLE §10.2) : masses basses et irrégulières,
## auvents asymétriques à trois appuis (`AwningTent` — jamais de tipi),
## bois fendu, corde, textiles, feu lisible de loin. Trois pôles
## d'activité : repos (auvents), cuisine (feu + réserve), garde (râtelier
## + bannières).
##
## Contraintes MESURÉES qui gouvernent l'implantation :
##  - l'ancre §3.3 `(45, 6, 65)` est l'ORIGINE locale : son rayon
##    vertical doit continuer de toucher le terrain nu — rien au centre ;
##  - le rayon de visée de `cam02_camp_pylone` traverse le camp par
##    l'origine, direction locale (0.61, −0.79), à ≈3,7 m au-dessus du
##    sol : la bande |perp| < 4 m reste BASSE (< 1,5 m) ;
##  - la route principale entre par le nord-ouest local (−15, 9) et
##    ressort vers (25, −25) : aucun collider à moins de 1,2 m de ces
##    segments, et le feu est décalé pour que la marche ne le traverse pas.
class_name CampCheckpointPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")


func default_place_id() -> StringName:
	return &"camp"


func _build() -> void:
	# — Pôle cuisine : feu réel (visuel + interactable canonique). Le camp
	# est un CARREFOUR : quatre couloirs de route partent de l'ancre
	# (principale NO et SE, hauteurs ENE, ruines SSO) — chaque pôle vit
	# dans un SECTEUR libre entre deux couloirs, mesuré à ≥ 2,5 m des
	# fils. Le feu tient le secteur est, sous le rayon de cam02.
	var fire_pos: Vector3 = _seated(5.1, -1.0)
	var fire_visual: CampfireProp = CampfireProp.new()
	fire_visual.name = "FeuVisuel"
	fire_visual.position = fire_pos
	add_child(fire_visual)
	var fire: Campfire = Campfire.new()
	fire.name = "FeuDeCuisine"
	fire.position = fire_pos
	add_child(fire)
	declare_support(fire_pos)
	K.module(self, &"Cauldron", _seated(6.0, -0.2), 140.0, 1.0, K.TONE_WOOD)
	K.module(self, &"Bucket_Wooden_1", _seated(6.9, -1.6), 30.0, 1.0, K.TONE_WOOD)

	# — LA HALLE : la masse DOMINANTE qui manquait. Charpente de bois
	# fendu, toile en deux pans superposés de hauteurs différentes,
	# ouverte au sud — elle donne au camp une silhouette au lieu d'objets
	# éparpillés dans une prairie (rejet du lead).
	var hall: Node3D = Node3D.new()
	hall.name = "Halle"
	# MESURÉ : posée à (−2,0 ; 6,4), l'emprise de la halle mordait le
	# couloir de `main_path` au point monde (40, 68) — le filet de route a
	# rougi. Reculée au nord-est, elle libère le passage ET se place
	# DERRIÈRE le feu vue de l'arrivée : la masse dominante ferme le fond
	# du camp au lieu de barrer son entrée.
	# Contrôle de la bande de visée gelée de `cam02_camp_pylone`
	# (direction locale (0,61 ; −0,79)) : perpendiculaire de la halle
	# = |1,8 × (−0,79) − 7,6 × 0,61| = 6,06 m > 4 m — hors bande basse,
	# elle a donc le droit d'être haute.
	var hall_at: Vector2 = Vector2(1.8, 7.6)
	hall.position = _seated(hall_at.x, hall_at.y)
	add_child(hall)
	declare_support(hall.position)
	var wood: Color = Color(0.40, 0.28, 0.18)
	for post: Array in [[-2.7, -2.0, 3.5], [2.7, -2.0, 3.1],
			[-2.7, 2.0, 2.6], [2.7, 2.0, 2.3]]:
		K.stone_block(hall, "PoteauHalle_%d" % hall.get_child_count(),
			Vector3(float(post[0]), float(post[2]) * 0.5, float(post[1])),
			Vector3(0.30, float(post[2]), 0.30),
			float(post[0]) * 2.0, wood, 8100 + hall.get_child_count(), 0.04)
	K.stone_block(hall, "PoutreHalle_ouest", Vector3(-2.7, 3.05, 0.0),
		Vector3(0.24, 0.26, 4.3), 0.0, wood, 8120, 0.03)
	K.stone_block(hall, "PoutreHalle_est", Vector3(2.7, 2.7, 0.0),
		Vector3(0.24, 0.26, 4.3), 0.0, wood, 8121, 0.03)
	for pan: Array in [[-1.3, 3.35, -13.0, 3.6], [1.4, 2.95, 12.0, 3.2]]:
		var canvas: MeshInstance3D = K.stone_block(hall,
			"ToileHalle_%d" % hall.get_child_count(),
			Vector3(float(pan[0]), float(pan[1]), 0.0),
			Vector3(float(pan[3]), 0.10, 4.5), 0.0,
			Color(0.62, 0.34, 0.22), 8130 + hall.get_child_count(), 0.02)
		canvas.rotation.z = deg_to_rad(float(pan[2]))
	K.collider_box(self, "Halle_col", hall.position + Vector3(0, 1.6, 0),
		Vector3(5.6, 3.2, 4.4))
	K.module(hall, &"Bed_Twin1", Vector3(-1.6, 0.1, 1.2), 10.0, 0.9,
		K.TONE_CLOTH)
	K.module(hall, &"Bag", Vector3(1.5, 0.1, 1.4), 30.0, 1.0, K.TONE_CLOTH)
	K.module(hall, &"Rope_1", Vector3(2.2, 0.1, -1.3), 70.0, 1.0, K.TONE_WOOD)

	# — DEUX SIGNES VERTICAUX lisibles à 70–110 m : le mât à bannière et
	# la colonne de fumée du foyer.
	# Le mât sort lui aussi de la bande basse de `cam02_camp_pylone` :
	# perpendiculaire = |−8,6 × (−0,79) − 0,6 × 0,61| = 6,43 m > 4 m. À
	# (−6,0 ; 4,2) elle valait 2,18 m — un mât de 5,8 m plein travers du
	# rayon de la caméra gelée.
	var mast_at: Vector3 = _seated(-8.6, 0.6)
	K.stone_block(self, "Mat", mast_at + Vector3(0, 2.9, 0),
		Vector3(0.22, 5.8, 0.22), 4.0, wood, 8200, 0.02)
	for flag: int in range(3):
		K.stone_block(self, "Fanion_%d" % flag,
			mast_at + Vector3(0.55, 4.5 - float(flag) * 0.75, 0.0),
			Vector3(1.05, 0.62, 0.06), 6.0 - float(flag) * 4.0,
			Color(0.72, 0.38, 0.24), 8210 + flag, 0.03)
	declare_support(mast_at)
	_smoke_column(fire_pos + Vector3(0.0, 1.1, 0.0))

	# — Pôle repos : deux auvents asymétriques, hors de la bande de visée
	# (|perp| ≥ 6,8 m), ouverts vers le feu.
	for tent_data: Array in [[6.6, 5.4, -200.0, "AuventNord"],
			[-8.6, -1.8, 75.0, "AuventOuest"]]:
		var tent: AwningTent = AwningTent.new()
		tent.name = tent_data[3] as String
		tent.position = _seated(float(tent_data[0]), float(tent_data[1]))
		tent.rotation.y = deg_to_rad(float(tent_data[2]))
		add_child(tent)
		declare_support(tent.position)
		K.collider_box(self, (tent_data[3] as String) + "_col",
			tent.position + Vector3(0, 1.1, 0), Vector3(3.2, 2.2, 2.8),
			float(tent_data[2]))
	K.module(self, &"Bed_Twin1", _seated(7.8, 4.2), -200.0, 0.85, K.TONE_CLOTH)

	# — Pôle garde / réserve : râtelier, caisses, tonneaux, table.
	K.module(self, &"WeaponStand", _seated(-3.8, 3.6), 100.0, 1.0, K.TONE_WOOD)
	# Les caisses tiennent l'écart de la route principale (sortie sud-est
	# locale (0,0)→(25,−25)) : cluster décalé en perpendiculaire, mesuré
	# à 5,1 m du fil — le filet de couloir rougissait à (50, 60).
	var crates: Node3D = K.module(self, &"Crate_Wooden", _seated(8.7, -1.3),
		15.0, 1.0, K.TONE_WOOD)
	K.module(self, &"Crate_Wooden", _seated(9.6, -0.4), 65.0, 0.85, K.TONE_WOOD)
	K.module(self, &"Barrel", _seated(-6.9, -2.8), 0.0, 1.0, K.TONE_WOOD)
	K.module(self, &"Barrel_Apples", _seated(-7.6, -3.6), 40.0, 1.0, K.TONE_WOOD)
	K.module(self, &"Table_Large", _seated(2.2, -4.2), -20.0, 0.9, K.TONE_WOOD)
	K.module(self, &"Stool", _seated(3.1, -3.4), 10.0, 1.0, K.TONE_WOOD)
	if crates != null:
		K.collider_box(self, "Caisses_col",
			crates.position + Vector3(0.4, 0.55, 0.5),
			Vector3(2.2, 1.1, 2.0), 15.0)
		declare_support(crates.position)
	K.collider_box(self, "Tonneaux_col", _seated(-7.2, -3.2) + Vector3(0, 0.6, 0),
		Vector3(1.8, 1.2, 2.2))

	# — Bannières hautes LOIN de la bande de visée (perp ≥ 10 m).
	K.module(self, &"Banner_1", _seated(9.8, 3.2), -30.0, 1.0, K.TONE_CLOTH)
	K.module(self, &"Banner_2", _seated(-8.0, -6.5), 140.0, 1.0, K.TONE_CLOTH)
	declare_support(_seated(9.8, 3.2))
	declare_support(_seated(-8.0, -6.5))

	# — Paravent tressé : coupe-vent derrière l'auvent est.
	K.module(self, &"Prop_WoodenFence_Single", _seated(9.4, 8.2), -25.0, 1.0,
		K.TONE_WOOD)
	K.module(self, &"Prop_WoodenFence_Extension1", _seated(10.6, 6.9), -25.0,
		1.0, K.TONE_WOOD)

	# — Sol vécu : dalles de pas entre l'entrée ouest et le feu.
	for slab: Array in [[-6.5, 4.0], [-4.2, 3.0], [-1.8, 2.1], [0.6, 1.4],
			[2.8, 0.6], [4.2, -0.2]]:
		K.module(self, &"RockPath_Round_Small_1",
			_seated(float(slab[0]), float(slab[1])),
			float(slab[0]) * 37.0, 1.0, K.TONE_STONE)


## COLONNE DE FUMÉE : six panneaux croisés, de plus en plus larges,
## pâles et transparents en montant — le signe vertical qui fait lire un
## camp habité depuis l'autre versant.
func _smoke_column(base: Vector3) -> void:
	var smoke: Node3D = Node3D.new()
	smoke.name = "Fumee"
	add_child(smoke)
	for i: int in range(6):
		var t: float = float(i) / 5.0
		var puff: MeshInstance3D = MeshInstance3D.new()
		puff.name = "Bouffee_%d" % i
		puff.mesh = K.irregular_box_mesh(
			Vector3(0.8 + t * 2.2, 1.5, 0.7 + t * 1.9), 0.22, 8300 + i)
		var material: StandardMaterial3D = K.flat_material(
			Color(0.86, 0.84, 0.80))
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.34 - t * 0.20
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.mesh.surface_set_material(0, material)
		puff.position = base + Vector3(t * 1.5, 1.0 + t * 5.4, t * 0.7)
		puff.rotation.y = t * 2.2
		smoke.add_child(puff)


## Position locale posée sur le sol réel (terrain gelé).
func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
