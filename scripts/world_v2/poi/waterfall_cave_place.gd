## GROTTE DE LA CASCADE (`valley.poi.waterfall_cave.01`, r04) — une VRAIE
## poche de roche, jamais un trou dans le terrain (directive V2.3 §2).
##
## REJET V2.3-A : « un tas de rochers surdimensionnés ; l'entrée est
## masquée ; la poche ne lit pas comme un volume rocheux ». Des blocs
## posés côte à côte ne font pas un volume. Refait ici en UNE enveloppe
## continue : parois, plafond et joues de bouche appartiennent au même
## maillage (`WorldV2PlaceKit.hollow_rock_mesh`), avec une bouche SOMBRE
## ouverte vers la route.
##
## IMPLANTATION MESURÉE (`probe_site_section`, coupe centrée (-110, 6)) :
## plateau plat à y = 3,0 de x = -118 à -100 ; le RESSAUT monte à l'ouest
## (x = -120 → 3,1 ; -122 → 4,1 ; -124 → 5,8). La masse est donc adossée
## au ressaut, sa bouche regarde l'EST vers le plateau et la route, et
## son sol intérieur reste au niveau du plateau — aucune marche.
class_name WaterfallCavePlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## Centre de la poche, en LOCAL (la racine est sur le plateau).
const POCKET_CENTER: Vector2 = Vector2(-6.5, 2.6)
const INNER_R: float = 3.2
const WALL_T: float = 4.4
const WALL_H: float = 3.1
## La bouche regarde l'EST-NORD-EST : les massifs de fleurs de la
## végétation GELÉE occupent x ∈ [-109, -106], z ∈ [5, 8,5] (origines
## sondées) et masquaient l'entrée. L'axe -14° passe dans le couloir
## libre — on s'adapte au paysage gelé, on ne le modifie pas.
const MOUTH_DEG: float = 12.0
const MOUTH_HALF_DEG: float = 24.0

const COL_ROCK: Color = Color(0.52, 0.45, 0.36)
const COL_ROCK_DARK: Color = Color(0.31, 0.27, 0.23)
const COL_FLOOR: Color = Color(0.44, 0.40, 0.35)


func default_place_id() -> StringName:
	return &"valley.poi.waterfall_cave.01"


func _build() -> void:
	var floor_y: float = ground_local_y(POCKET_CENTER.x, POCKET_CENTER.y)
	var mouth_out: Vector2 = POCKET_CENTER + Vector2(INNER_R + WALL_T + 1.4, 0.0)
	set_meta(&"cave_threshold", Vector3(mouth_out.x,
		ground_local_y(mouth_out.x, mouth_out.y), mouth_out.y))
	set_meta(&"cave_interior", Vector3(POCKET_CENTER.x - 1.2, floor_y,
		POCKET_CENTER.y - 0.8))

	# — L'ENVELOPPE : un seul maillage creux, parois + plafond + joues.
	var shell: MeshInstance3D = MeshInstance3D.new()
	shell.name = "Enveloppe"
	shell.mesh = K.hollow_rock_mesh(INNER_R, WALL_T, WALL_H, MOUTH_DEG,
		MOUTH_HALF_DEG, 20260814, 44)
	var rock_material: StandardMaterial3D = K.flat_material(COL_ROCK)
	rock_material.vertex_color_use_as_albedo = true
	shell.material_override = rock_material
	shell.position = Vector3(POCKET_CENTER.x, floor_y, POCKET_CENTER.y)
	add_child(shell)
	declare_support(shell.position)

	# UNE SEULE coque : au premier jet une seconde enveloppe « massif »
	# l'enrobait — les deux parois se croisaient et se lisaient comme deux
	# grands panneaux beiges détachés. La masse vient de l'épaisseur
	# (WALL_T) et du profil, pas d'un empilement d'enveloppes.

	# — Les parois portantes : un anneau de colliders qui suit l'enveloppe,
	# ouvert au secteur de la bouche (le joueur entre et ressort).
	var walls: Node3D = Node3D.new()
	walls.name = "Parois"
	add_child(walls)
	var segments: int = 12
	for i: int in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		var degrees: float = rad_to_deg(angle)
		if absf(wrapf(degrees - MOUTH_DEG, -180.0, 180.0)) < MOUTH_HALF_DEG + 6.0:
			continue
		# La boîte est tournée de -angle : son X devient RADIAL. Mesuré à
		# l'inspection : une épaisseur radiale de 5,4 m mordait 2,7 m DANS
		# la chambre — le filet de marche y voyait un mur et un plafond
		# bas au milieu de la poche. La face intérieure du collider est
		# désormais exactement sur INNER_R.
		var radius: float = INNER_R + 1.0
		var at: Vector3 = Vector3(
			POCKET_CENTER.x + cos(angle) * radius, floor_y + WALL_H * 0.6,
			POCKET_CENTER.y + sin(angle) * radius)
		K.collider_box(walls, "paroi_%d" % i, at,
			Vector3(2.0, WALL_H * 2.4, TAU * radius / float(segments) * 1.35),
			rad_to_deg(-angle))
	K.collider_box(walls, "plafond",
		Vector3(POCKET_CENTER.x, floor_y + WALL_H * 1.32, POCKET_CENTER.y),
		Vector3(INNER_R * 2.2, 0.8, INNER_R * 2.2))

	# — Le SEUIL et le SOL. Mesuré : le terrain MONTE dans le ressaut — le
	# plateau est à y = 3,00 devant la bouche, le fond de la poche à 3,54.
	# Un sol plat posé au niveau du fond faisait donc une marche de 0,58 m
	# pile sur le pas de la porte. Le seuil est donc une VOLÉE de dalles
	# qui rattrape la différence par paliers de moins de 10 cm.
	var floor_root: Node3D = Node3D.new()
	floor_root.name = "SolInterieur"
	add_child(floor_root)
	var mouth_x: float = POCKET_CENTER.x + INNER_R + WALL_T * 0.55
	var mouth_ground: float = ground_local_y(mouth_x, POCKET_CENTER.y)
	var landings: int = 7
	for i: int in range(landings):
		var t: float = float(i) / float(landings - 1)
		var x: float = lerpf(mouth_x + 0.9, POCKET_CENTER.x + 0.6, t)
		var y: float = lerpf(mouth_ground, floor_y, t)
		var at: Vector3 = Vector3(x, y + 0.06, POCKET_CENTER.y
			+ sin(t * 2.1) * 0.35)
		K.stone_block(floor_root, "dalle_seuil_%d" % i, at,
			Vector3(2.4, 0.24, 3.0), 12.0 * t - 6.0, COL_FLOOR,
			3100 + i, 0.05)
		K.collider_box(floor_root, "seuil_col_%d" % i,
			Vector3(x, y - 0.10, POCKET_CENTER.y),
			Vector3(2.6, 0.34, 3.4))
	# Le fond de la poche : UN sol de roche continu — des dalles séparées
	# laissaient voir l'herbe du terrain entre elles (mesuré en capture).
	var cave_floor: MeshInstance3D = MeshInstance3D.new()
	cave_floor.name = "SolDeRoche"
	cave_floor.mesh = K.rock_floor_mesh(INNER_R + 0.9, 5150)
	var floor_material: StandardMaterial3D = K.flat_material(COL_FLOOR)
	floor_material.vertex_color_use_as_albedo = true
	cave_floor.material_override = floor_material
	cave_floor.position = Vector3(POCKET_CENTER.x, floor_y + 0.12,
		POCKET_CENTER.y)
	floor_root.add_child(cave_floor)
	K.collider_box(floor_root, "sol_col",
		Vector3(POCKET_CENTER.x - 1.1, floor_y - 0.10, POCKET_CENTER.y),
		Vector3(INNER_R * 1.7, 0.32, INNER_R * 2.0))

	# — La BOUCHE : les JOUES de l'enveloppe encadrent déjà l'ouverture.
	# Au premier jet, deux piédroits et un linteau y étaient ajoutés : ils
	# débordaient de la masse et se lisaient comme des blocs détachés. Il
	# ne reste qu'un SOURCIL — une saillie de roche au-dessus du vide, qui
	# porte l'ombre et fait la lèvre supérieure.
	var mouth: Node3D = Node3D.new()
	mouth.name = "Bouche"
	add_child(mouth)
	var mouth_dir: Vector2 = Vector2(cos(deg_to_rad(MOUTH_DEG)),
		sin(deg_to_rad(MOUTH_DEG)))
	var brow_at: Vector2 = POCKET_CENTER + mouth_dir * (INNER_R + WALL_T * 0.32)
	K.stone_block(mouth, "Sourcil",
		Vector3(brow_at.x, floor_y + WALL_H + 0.15, brow_at.y),
		Vector3(2.9, 1.05, 4.6), MOUTH_DEG - 4.0, COL_ROCK, 4402, 0.11)
	# Deux petits blocs d'éboulis au pied des joues — au premier jet, deux
	# « épaules » de 2,2 m débordaient de la masse et se lisaient comme
	# des panneaux détachés posés sur l'herbe.
	for side: int in [-1, 1]:
		var cheek: Vector2 = POCKET_CENTER \
			+ mouth_dir.rotated(deg_to_rad(float(side) * 34.0)) \
				* (INNER_R + WALL_T * 0.92)
		K.stone_block(mouth, "PiedDeJoue_%d" % side,
			Vector3(cheek.x, ground_local_y(cheek.x, cheek.y) + 0.34, cheek.y),
			Vector3(1.5, 0.9, 1.3), MOUTH_DEG + float(side) * 22.0,
			COL_ROCK, 4400 + side, 0.14)
	# La PROFONDEUR se lit par la poche elle-même : au premier jet, un
	# bloc sombre « gorge » avait été posé DANS le volume — il bouchait
	# l'intérieur au lieu de le creuser. Ce qui donne la lecture, c'est
	# une lampe motivée par la bouche : le jour entre, s'arrête vite, et
	# la récompense au fond reste visible sans éclairer la roche comme
	# un décor de studio.
	var daylight: OmniLight3D = OmniLight3D.new()
	daylight.name = "JourDeLaBouche"
	daylight.light_color = Color(1.0, 0.94, 0.82)
	daylight.light_energy = 1.15
	daylight.omni_range = 9.0
	daylight.shadow_enabled = false
	daylight.position = Vector3(POCKET_CENTER.x + INNER_R * 0.55,
		floor_y + 1.9, POCKET_CENTER.y - 0.4)
	add_child(daylight)
	var deep: OmniLight3D = OmniLight3D.new()
	deep.name = "FondDeLaPoche"
	deep.light_color = Color(0.82, 0.86, 0.92)
	deep.light_energy = 0.45
	deep.omni_range = 6.0
	deep.shadow_enabled = false
	deep.position = Vector3(POCKET_CENTER.x - 2.2, floor_y + 1.6,
		POCKET_CENTER.y - 0.8)
	add_child(deep)

	# — Les ABORDS : éboulis du seuil et végétation d'ombre, posés HORS de
	# l'axe d'entrée (le lead a vu l'entrée masquée par des fleurs : la
	# bande |z local − 0,5| < 2,4 devant la bouche reste NUE).
	for scree: Array in [[6.4, 3.4, 1.15], [5.2, -3.6, 0.9], [7.6, -4.4, 0.75],
			[7.0, 4.6, 0.8]]:
		var at: Vector3 = Vector3(POCKET_CENTER.x + float(scree[0]), 0.0,
			POCKET_CENTER.y + float(scree[1]))
		at.y = ground_local_y(at.x, at.z) + float(scree[2]) * 0.35
		K.stone_block(self, "Eboulis_%d" % get_child_count(), at,
			Vector3(float(scree[2]) * 1.7, float(scree[2]) * 1.1,
				float(scree[2]) * 1.4), float(scree[0]) * 31.0, COL_ROCK,
			4500 + get_child_count(), 0.13)
	K.module(self, &"Fern_1", _seated(POCKET_CENTER.x + 5.6,
		POCKET_CENTER.y + 3.2), 20.0, 1.0, K.TONE_PLANT)
	K.module(self, &"Fern_1", _seated(POCKET_CENTER.x + 5.0,
		POCKET_CENTER.y - 3.1), 160.0, 0.9, K.TONE_PLANT)
	K.module(self, &"Mushroom_Common", _seated(POCKET_CENTER.x + 6.8,
		POCKET_CENTER.y + 2.9), 0.0, 1.0, K.TONE_PLANT)
	# Le chemin d'approche : dalles qui montent du plateau vers la bouche,
	# dans l'axe — elles GUIDENT le regard vers la bouche sombre.
	for step: Array in [[9.2, 0.9], [7.6, 0.4], [6.0, 0.1]]:
		K.module(self, &"RockPath_Round_Wide",
			_seated(POCKET_CENTER.x + float(step[0]),
				POCKET_CENTER.y + float(step[1])),
			float(step[0]) * 27.0, 1.1, K.TONE_STONE)

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Grotte de la cascade"
	poi.region = "r04_falaises_du_couchant"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 12.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	# La récompense est AU FOND : la poche paie d'être entrée.
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.INGREDIENT,
		Vector3(POCKET_CENTER.x - 2.4, floor_y + 0.18, POCKET_CENTER.y - 1.1),
		Vector3(2.0, 0.0, 1.0))


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
