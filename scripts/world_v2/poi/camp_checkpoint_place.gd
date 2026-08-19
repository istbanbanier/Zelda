## CAMP / CHECKPOINT (r05_terrasse_du_camp) — la halte de route ENTRETENUE.
##
## R2B (plan approuvé, agent A) : la peau du lieu est faite de MODULES du
## kit CC0 — plus aucune primitive procédurale hors le feu canonique
## (`CampfireProp`, exemption NOMMÉE de l'arbitrage R2B, décision c). La
## halle procédurale, le mât à fanions et la fumée en boîtes translucides
## disparaissent (fumée : SUPPRIMÉE SANS REMPLACEMENT — décision lead,
## pas de VFX dans cette passe).
##
## Identité : une halte de route — halle charpentée (poteaux
## `Corner_Exterior_Wood`, plancher `Floor_WoodDark` ×4, toit
## `Roof_Wooden_2x1_L/R` en deux rangées), wagon et étal à l'entrée NO,
## deux bannières `Banner_1`, le feu, les dalles de pas. Teintes chaudes.
##
## Contraintes MESURÉES qui gouvernent l'implantation :
##  - l'ancre §3.3 `(45, 6, 65)` est l'ORIGINE locale : son rayon
##    vertical doit continuer de toucher le terrain nu — rien au centre ;
##  - `cam02_camp_pylone` traverse le camp par l'origine, direction
##    locale (0,61 ; −0,79) : la bande |perp| < 4 m reste BASSE
##    (< 1,5 m), et la perpendiculaire se mesure au BORD de l'emprise,
##    pas au centre. La halle axis-alignée avait son coin de toit à
##    3,45 m du rayon (6,06 − [2,13·0,79 + 1,52·0,61]) : elle est donc
##    TOURNÉE de 52,3° pour aligner son faîte sur le rayon — demi-emprise
##    perpendiculaire 1,52 m, bord à 4,54 m > 4 m ;
##  - le camp est un CARREFOUR à quatre couloirs (principale NO et SE,
##    hauteurs ENE, ruines SSO) : wagon et étal tiennent ≥ 2,5 m des
##    fils, mesuré en AABB monde (wagon AABB nord [−7,1;−2,7]×[7,6;11,4]
##    à 2,88 m du fil NO ; étal sud [−14,6;−11,5]×[0,9;3,3] à 3,02 m) ;
##  - le wagon vit DANS la bande basse de cam02 (perp centre 1,93 m) :
##    il est réduit à 0,95 — hauteur 1,45 m < 1,5 m.
class_name CampCheckpointPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## Lacet de la halle : faîte aligné sur le rayon de `cam02_camp_pylone`
## (direction locale (0,61 ; −0,79) → 52,3°).
const HALL_YAW_DEG: float = 52.3
## Hauteur du plan d'appui des sablières (origine des panneaux, bord haut) :
## dessous du toit à 2,42 − 0,16 = 2,26 m, faîte à 2,42 + 1,09 = 3,51 m.
## Le plan annonçait ~3,2 m : le module impose 1,25 m de pente — écart
## mesuré, consigné au rapport.
const HALL_EAVE_M: float = 2.42


func default_place_id() -> StringName:
	return &"camp"


func _build() -> void:
	# — Pôle cuisine : feu réel (visuel + interactable canonique). Le feu
	# tient le secteur est du carrefour, sous le rayon de cam02 (1,1 m de
	# haut — bande basse respectée).
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

	_hall()
	_northwest_entrance()

	# — Pôle garde / réserve : râtelier, caisses, tonneaux, table — tous
	# modules, positions héritées (couloirs déjà mesurés : cluster caisses
	# à 5,1 m du fil SE).
	K.module(self, &"WeaponStand", _seated(-3.8, 3.6), 100.0, 1.0, K.TONE_WOOD)
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

	# — DEUX BANNIÈRES `Banner_1` : les signes verticaux de la halte,
	# loin de la bande de visée (perp 9,4 m et 11,2 m). PIÈGE MESURÉ à la
	# sonde d'assise : le pivot Y de Banner_1 est à 65 % de sa hauteur
	# (min à −1,55 m) et l'assise du kit ne corrige pas — posée au sol
	# elle serait enterrée d'1,55 m (défaut préexistant, jamais relevé).
	for banner_data: Array in [[9.0, -3.0, -30.0], [-9.5, -6.0, 140.0]]:
		var banner: Node3D = K.module(self, &"Banner_1",
			_seated(float(banner_data[0]), float(banner_data[1])),
			float(banner_data[2]), 1.0, K.TONE_CLOTH)
		if banner != null:
			banner.position.y += 1.56
		declare_support(_seated(float(banner_data[0]), float(banner_data[1])))

	# — Sol vécu : dalles de pas entre l'entrée ouest et le feu (conservées).
	for slab: Array in [[-6.5, 4.0], [-4.2, 3.0], [-1.8, 2.1], [0.6, 1.4],
			[2.8, 0.6], [4.2, -0.2]]:
		K.module(self, &"RockPath_Round_Small_1",
			_seated(float(slab[0]), float(slab[1])),
			float(slab[0]) * 37.0, 1.0, K.TONE_STONE)


## LA HALLE : masse dominante du camp, entièrement en modules. Charpente
## `Corner_Exterior_Wood`, plancher `Floor_WoodDark` ×4 (4 × 4 m), toit à
## deux rangées `Roof_Wooden_2x1_L/R` (faîte le long de l'axe local X de
## la halle, tourné sur le rayon de cam02 — voir l'en-tête).
func _hall() -> void:
	var hall_at: Vector2 = Vector2(1.8, 7.6)
	# Plan d'assise : le sol le plus HAUT sous les quatre pieds — un
	# plancher posé sur le point bas laisserait l'angle amont enterré.
	var cos_y: float = cos(deg_to_rad(HALL_YAW_DEG))
	var sin_y: float = sin(deg_to_rad(HALL_YAW_DEG))
	var base_y: float = ground_local_y(hall_at.x, hall_at.y)
	var post_feet: Array[Vector2] = []
	for corner: Vector2 in [Vector2(1.9, 1.35), Vector2(1.9, -1.35),
			Vector2(-1.9, 1.35), Vector2(-1.9, -1.35)]:
		var world_xz: Vector2 = Vector2(
			hall_at.x + corner.x * cos_y + corner.y * sin_y,
			hall_at.y - corner.x * sin_y + corner.y * cos_y)
		post_feet.append(world_xz)
		base_y = maxf(base_y, ground_local_y(world_xz.x, world_xz.y))
	var hall: Node3D = Node3D.new()
	hall.name = "Halle"
	hall.position = Vector3(hall_at.x, base_y + 0.02, hall_at.y)
	hall.rotation.y = deg_to_rad(HALL_YAW_DEG)
	add_child(hall)
	for foot: Vector2 in post_feet:
		declare_support(_seated(foot.x, foot.y))

	# Plancher : quatre dalles de 2 × 2 m (pivot CENTRÉ en Y, mesuré à la
	# sonde d'assise — posées à +0,01, dessus à +0,02).
	for tile: Vector2 in [Vector2(1.0, 1.0), Vector2(1.0, -1.0),
			Vector2(-1.0, 1.0), Vector2(-1.0, -1.0)]:
		K.module(hall, &"Floor_WoodDark", Vector3(tile.x, 0.01, tile.y),
			0.0, 1.0, K.TONE_WOOD)
	# Quatre poteaux d'angle sous les rampants (0,78 × 3,00 = 2,34 m :
	# la tête perce le dessous du toit, mesuré à 2,24–2,40 m).
	for post: Vector2 in [Vector2(1.9, 1.35), Vector2(1.9, -1.35),
			Vector2(-1.9, 1.35), Vector2(-1.9, -1.35)]:
		K.module(hall, &"Corner_Exterior_Wood", Vector3(post.x, 0.0, post.y),
			0.0, 0.78, K.TONE_WOOD)
	# Toit : deux rangées dos à dos. Le pivot du panneau est à son bord
	# HAUT (sonde d'assise : y min à −0,16, faîte à +1,09, pente vers +Z
	# local) : les deux rangées se posent sur la ligne de faîte z = 0.
	# Rangée sud (pente vers +Z) : L à −1,0 (déborde à l'ouest), R à +1,0.
	K.module(hall, &"Roof_Wooden_2x1_L", Vector3(-1.0, HALL_EAVE_M, 0.0),
		0.0, 1.0, K.TONE_WOOD)
	K.module(hall, &"Roof_Wooden_2x1_R", Vector3(1.0, HALL_EAVE_M, 0.0),
		0.0, 1.0, K.TONE_WOOD)
	# Rangée nord (yaw 180° — les débords L/R s'inversent avec la rotation).
	K.module(hall, &"Roof_Wooden_2x1_L", Vector3(1.0, HALL_EAVE_M, 0.0),
		180.0, 1.0, K.TONE_WOOD)
	K.module(hall, &"Roof_Wooden_2x1_R", Vector3(-1.0, HALL_EAVE_M, 0.0),
		180.0, 1.0, K.TONE_WOOD)
	# Pôle repos SOUS la halle : lit, sac, corde — sur le plancher.
	K.module(hall, &"Bed_Twin1", Vector3(-0.85, 0.02, 0.3), 4.0, 0.9,
		K.TONE_CLOTH)
	K.module(hall, &"Bag", Vector3(1.3, 0.02, -1.0), 30.0, 1.0, K.TONE_CLOTH)
	K.module(hall, &"Rope_1", Vector3(1.5, 0.02, 1.1), 70.0, 1.0, K.TONE_WOOD)
	K.collider_box(self, "Halle_col",
		Vector3(hall_at.x, base_y + 1.6, hall_at.y),
		Vector3(4.6, 3.2, 3.4), HALL_YAW_DEG)


## L'ENTRÉE NORD-OUEST : le wagon et l'étal de la halte, de part et
## d'autre du couloir de `main_path` ((−15, 9) → origine). Positions
## MESURÉES en AABB monde contre les quatre couloirs (≥ 2,5 m du fil,
## voir l'en-tête) ; le wagon, dans la bande basse de cam02, est réduit
## à 0,95 (1,45 m de haut < 1,5 m).
func _northwest_entrance() -> void:
	var wagon: Node3D = K.module(self, &"Prop_Wagon", _seated(-3.9, 8.9),
		121.0, 0.95, K.TONE_WOOD)
	if wagon != null:
		declare_support(wagon.position)
		# Pivot mesuré à 78 % de l'emprise Z : le centre visuel est à
		# (−4,9 ; 9,5) — le collider le suit, pas l'origine du nœud.
		K.collider_box(self, "Wagon_col",
			_seated(-4.87, 9.48) + Vector3(0.0, 0.75, 0.0),
			Vector3(2.0, 1.5, 3.9), 121.0)
	var stall: Node3D = K.module(self, &"Stall_Cart_Empty", _seated(-12.5, 1.8),
		31.0, 1.0, K.TONE_WOOD)
	if stall != null:
		declare_support(stall.position)
		# Pivot mesuré à 70 % de l'emprise X : centre visuel à (−13,0 ; 2,1).
		K.collider_box(self, "Etal_col",
			_seated(-13.01, 2.11) + Vector3(0.0, 1.2, 0.0),
			Vector3(3.1, 2.4, 1.1), 31.0)


## Position locale posée sur le sol réel (terrain gelé).
func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
