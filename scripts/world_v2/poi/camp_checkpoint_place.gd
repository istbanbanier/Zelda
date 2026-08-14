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

	# — Pôle repos : deux auvents asymétriques, hors de la bande de visée
	# (|perp| ≥ 6,8 m), ouverts vers le feu.
	for tent_data: Array in [[1.0, 7.0, -160.0, "AuventNord"],
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
	K.module(self, &"Bed_Twin1", _seated(2.0, 8.2), -160.0, 0.85, K.TONE_CLOTH)

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
	K.module(self, &"Banner_1", _seated(8.5, 5.5), -30.0, 1.0, K.TONE_CLOTH)
	K.module(self, &"Banner_2", _seated(-8.0, -6.5), 140.0, 1.0, K.TONE_CLOTH)
	declare_support(_seated(8.5, 5.5))
	declare_support(_seated(-8.0, -6.5))

	# — Paravent tressé : coupe-vent derrière l'auvent est.
	K.module(self, &"Prop_WoodenFence_Single", _seated(7.6, 6.4), -25.0, 1.0,
		K.TONE_WOOD)
	K.module(self, &"Prop_WoodenFence_Extension1", _seated(9.2, 5.4), -25.0,
		1.0, K.TONE_WOOD)

	# — Sol vécu : dalles de pas entre l'entrée ouest et le feu.
	for slab: Array in [[-6.5, 4.0], [-4.2, 3.0], [-1.8, 2.1], [0.6, 1.4],
			[2.8, 0.6], [4.2, -0.2]]:
		K.module(self, &"RockPath_Round_Small_1",
			_seated(float(slab[0]), float(slab[1])),
			float(slab[0]) * 37.0, 1.0, K.TONE_STONE)


## Position locale posée sur le sol réel (terrain gelé).
func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
