## Vestibule de la Citadelle de l'Œil-Tempête — intérieur graybox (D.1R.4,
## raccordé au donjon en F.6).
##
## PT-D1-10 : l'entrée vue depuis la crête n'est plus une fausse promesse — on
## entre, on explore un vestibule à colonnes éclairé de cyan, et la porte
## du fond ouvre désormais sur la salle 1 du donjon électrique (F.6). La sortie replace le joueur DEVANT la porte de la vallée, jamais
## au spawn (§6.1 : « les transitions ne laissent aucun ancien nœud actif »).
##
## Le décor est construit en code, comme `ValleyTerrain` : déclaratif,
## déterministe, cotes lisibles. §7.8 : « aucun couloir noir » — deux omni cyan
## et une ambiance sombre mais lisible.
class_name CitadelVestibule
extends Node3D

const COL_STONE: Color = Color(0.32, 0.31, 0.36)
const COL_FLOOR: Color = Color(0.26, 0.25, 0.3)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)

@onready var _player: PlayerController = $Player


func _ready() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	var spawn_tag: StringName = &""
	if game_state != null:
		game_state.call("set_flow", 3)  # GameState.Flow.DUNGEON
		spawn_tag = StringName(String(game_state.call("consume_pending_spawn")))
	_build_room()
	_setup_lighting()
	# §6.1 : revenir du donjon replace DEVANT le seuil du fond, pas à l'entrée.
	if spawn_tag == &"vestibule_from_room1" and _player != null:
		_player.global_position = Vector3(0, 0.3, -10.5)


func _build_room() -> void:
	# Salle 22 × 26 (V4.3, réf. 02 : vestibule « jouable sur environ 20 à
	# 30 mètres »), murs de 9 m, plafond plein — la porte d'entrée (sud) est
	# le seul percement.
	_box("Floor", Vector3(0, -0.5, 0), Vector3(22, 1, 26), COL_FLOOR)
	_box("Ceiling", Vector3(0, 9.5, 0), Vector3(22, 1, 26), COL_STONE)
	_box("WallNorth", Vector3(0, 4.5, -13.25), Vector3(22, 9, 0.5), COL_STONE)
	_box("WallWestSouth", Vector3(-6.6, 4.5, 13.25), Vector3(8.8, 9, 0.5), COL_STONE)
	_box("WallEastSouth", Vector3(6.6, 4.5, 13.25), Vector3(8.8, 9, 0.5), COL_STONE)
	_box("WallSouthTop", Vector3(0, 7.5, 13.25), Vector3(4.4, 3, 0.5), COL_STONE)
	_box("WallWest", Vector3(-11.25, 4.5, 0), Vector3(0.5, 9, 26), COL_STONE)
	_box("WallEast", Vector3(11.25, 4.5, 0), Vector3(0.5, 9, 26), COL_STONE)
	for i: int in range(6):
		var x: float = -6.0 if i % 2 == 0 else 6.0
		var z: float = -9.0 + 9.0 * float(i / 2)
		_box("Column%d" % i, Vector3(x, 4.5, z), Vector3(1.2, 9, 1.2), COL_STONE)
		_dress_column(i, Vector3(x, 0.0, z))
	# Braseros (réf. 02 : flammes chaudes dans l'axe) — le CONTRASTE chaud/froid
	# du donjon commence ici : ambre motivé contre veine cyan (§7.8).
	for i: int in range(4):
		var x: float = -6.0 if i % 2 == 0 else 6.0
		var z: float = -6.0 if i < 2 else 6.0
		# REVUE V4 : le brasero était DEUX boîtes — une caisse brune de
		# 0,9 × 1,1 × 0,9 surmontée d'un couvercle orange émissif : ni vasque,
		# ni pied, aucune silhouette de feu. On monte le socle du kit et une
		# vraie vasque (`Cauldron`, 0,989 × 0,8155 × 0,944, origine à la base
		# et centrée en XZ : posable telle quelle).
		_box("Brazier%d" % i, Vector3(x, 0.275, z), Vector3(0.5, 0.55, 0.5),
			Color(0.24, 0.18, 0.14))
		var bowl: PackedScene = AssetRegistry.model(&"Cauldron")
		if bowl != null:
			var pot: Node3D = bowl.instantiate() as Node3D
			pot.name = "BrazierBowl%d" % i
			pot.position = Vector3(x, 0.55, z)   # base sur le socle, bord à 1,363
			pot.rotation.y = PI * 0.5 * float(i)   # casse la répétition des quatre
			# La collision suit le VISIBLE : sans ce cylindre, on traverserait
			# la vasque, que l'ancienne boîte de 0,9 m bloquait.
			var pot_body: StaticBody3D = StaticBody3D.new()
			pot_body.name = "BrazierBowlBody%d" % i
			pot_body.collision_layer = 1
			pot_body.collision_mask = 0
			var pot_shape: CollisionShape3D = CollisionShape3D.new()
			var pot_cylinder: CylinderShape3D = CylinderShape3D.new()
			pot_cylinder.radius = 0.4946   # rayon mesuré de la panse
			pot_cylinder.height = 0.8155   # hauteur mesurée
			pot_shape.shape = pot_cylinder
			pot_shape.position = Vector3(0, 0.4078, 0)
			pot_body.add_child(pot_shape)
			pot.add_child(pot_body)
			add_child(pot)
		# Braises DANS la vasque (bord à 1,363) au lieu d'un couvercle posé.
		_box("BrazierCoal%d" % i, Vector3(x, 1.2, z), Vector3(0.62, 0.14, 0.62),
			Color(0.98, 0.55, 0.18), true)
		var flame: OmniLight3D = OmniLight3D.new()
		flame.name = "BrazierLight%d" % i
		flame.light_color = Color(1.0, 0.62, 0.28)
		flame.light_energy = 1.6
		flame.omni_range = 9.0
		# REVUE V4 : la lampe était à y = 2,00, soit 0,675 m AU-DESSUS des
		# braises qui la motivent — le halo flottait au-dessus du feu (§7.8 :
		# « sources motivées »). Ramenée à 0,35 m au-dessus des braises.
		flame.position = Vector3(x, 1.55, z)
		add_child(flame)
	# La porte SCELLÉE du fond : masse sombre + veine cyan sous un linteau de
	# bronze — « visiblement et honnêtement scellée », le donjon quatre-salles
	# est Phase F. C'est le « second seuil » de la référence 02.
	# F.6 : le seuil du fond n'est plus scellé — il OUVRE sur la salle 1 du
	# donjon électrique. La promesse de D.1R.4 est tenue.
	# REVUE V4 : la veine cyan suit la FACE du vantail. Celui-ci ayant été
	# reculé au nu du cadre (voir plus bas), sa face regarde maintenant
	# z = −12,55 ; à −12,65 la veine se serait retrouvée NOYÉE dans la masse
	# sombre. Recalée à −12,50, elle affleure la porte (−12,55..−12,45) et
	# reste en arrière du nu avant du cadre (−12,37).
	# S2.0 — ORNEMENT, DONC SANS COLLISION. Cette veine était un `StaticBody3D`
	# sur la couche 1, c'est-à-dire un obstacle pour le rayon de ligne de vue des
	# interactions, planté juste devant `DungeonDoor` (−12,50 contre −12,75).
	# Résultat mesuré : au centre du battant, portée et cône parfaits, la porte
	# n'était PAS sélectionnable ; il fallait un pas de côté. Elle garde sa
	# géométrie, sa position et son émission — elle perd son corps.
	_decor_box("SealedSeam", Vector3(0, 3, -12.50), Vector3(0.3, 5.4, 0.1),
		COL_CYAN, true)
	var dungeon_door: SceneDoor = SceneDoor.new()
	dungeon_door.name = "DungeonDoor"
	dungeon_door.verb = "Entrer dans le donjon"
	dungeon_door.target_scene = "res://scenes/dungeon/rooms/Room1Initiation.tscn"
	dungeon_door.spawn_tag = &"room1_from_vestibule"
	dungeon_door.collision_layer = 1
	dungeon_door.collision_mask = 0
	var dungeon_shape: CollisionShape3D = CollisionShape3D.new()
	var dungeon_box: BoxShape3D = BoxShape3D.new()
	# REVUE V4 : le vantail mesurait 5,0 × 6,0 alors que le portail de pierre
	# qui l'encadre ne fait que 3,687 m de large et 5,948 m de haut une fois
	# à l'échelle (DoorFrame_Round_Brick 1,6031 × 2,5862 × 0,4772 × 2,3/2,3/1,4).
	# La masse noire débordait donc de 0,66 m de chaque jambage et par le haut :
	# l'arche se lisait comme un décor collé devant une dalle. Le vantail est
	# ramené à 3,4 × 5,6, entièrement CONTENU dans le cadre (x ±1,70 contre
	# ±1,84 ; sommet 5,60 contre 5,948). La collision suit exactement le
	# visible : les deux boîtes gardent la même cote.
	dungeon_box.size = Vector3(3.4, 5.6, 0.4)
	dungeon_shape.shape = dungeon_box
	dungeon_door.add_child(dungeon_shape)
	var dungeon_mesh: MeshInstance3D = MeshInstance3D.new()
	var dungeon_mesh_box: BoxMesh = BoxMesh.new()
	dungeon_mesh_box.size = Vector3(3.4, 5.6, 0.4)
	dungeon_mesh.mesh = dungeon_mesh_box
	var dungeon_material: StandardMaterial3D = StandardMaterial3D.new()
	dungeon_material.albedo_color = Color(0.12, 0.13, 0.17)
	dungeon_mesh.material_override = dungeon_material
	dungeon_door.add_child(dungeon_mesh)
	# y = 2,8 : le vantail de 5,6 m repose sur le dallage (0,00..5,60), comme le
	# cadre. z = −12,75 : son plan passe au nu ARRIÈRE du cadre (−13,03..−12,37)
	# au lieu de se tenir 0,25 m derrière lui.
	dungeon_door.position = Vector3(0, 2.8, -12.75)   # AVANT add_child
	add_child(dungeon_door)
	_box("SealedLintel", Vector3(0, 6.6, -12.8), Vector3(6.4, 0.8, 0.7),
		Color(0.42, 0.30, 0.18))
	# ART-Q5 : portail de pierre de production autour du seuil scellé —
	# l'arche encadre la masse sombre, décor pur (la collision du mur nord et
	# le SealedDoor gameplay ne bougent pas). ×2.3 : ouverture 3,7 × 5,9 m.
	var seal_frame: PackedScene = AssetRegistry.resolve(&"arch.gate.module")
	if seal_frame != null:
		var frame: Node3D = seal_frame.instantiate() as Node3D
		frame.name = "SealedDoorFrame"
		# Cadre recalé sur le vantail : à −12,62 son épaisseur (−13,03..−12,37)
		# enveloppe la porte (−12,95..−12,55). Le `SealedLintel` (6,2..7,0)
		# reste au-dessus du sommet du cadre (5,948).
		frame.position = Vector3(0, 0, -12.62)
		frame.scale = Vector3(2.3, 2.3, 1.4)
		add_child(frame)

	_dress_interior()

	var exit_door: SceneDoor = SceneDoor.new()
	exit_door.name = "ExitDoor"
	exit_door.verb = "Sortir"
	# ISS-073 — la sortie rend au monde de la CAMPAGNE. Le vestibule est
	# désormais atteint depuis World V2 (le menu n'ouvre plus V1) : le renvoyer
	# vers `ValleyWorld.tscn` déposerait le joueur dans un monde qu'il n'a
	# jamais traversé, sans moyen d'en revenir.
	exit_door.target_scene = "res://scenes/world_v2/WorldV2.tscn"
	exit_door.spawn_tag = &"citadel_door"
	exit_door.collision_layer = 1
	exit_door.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(4.2, 6, 0.4)
	shape.shape = box
	exit_door.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var mesh_box: BoxMesh = BoxMesh.new()
	mesh_box.size = Vector3(4.2, 6, 0.4)
	mesh.mesh = mesh_box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.14, 0.16, 0.2)
	mesh.material_override = material
	exit_door.add_child(mesh)
	exit_door.position = Vector3(0, 3, 13.4)   # AVANT add_child (règle D.0)
	add_child(exit_door)


## V4 lot 11 — habillage intérieur (§11.J) : allée de dalles vers le seuil
## scellé, panneaux muraux au nord, mobilier martial, lanternes MOTIVÉES
## sur les colonnes médianes. Décor pur : collisions et portes intactes.
func _dress_interior() -> void:
	var dressing: Node3D = Node3D.new()
	dressing.name = "VestibuleDressing"
	add_child(dressing)
	var placements: Array[Array] = [
		# Allée processionnelle : dalles de brique de l'entrée au seuil.
		[&"Floor_Brick", Vector3(0, 0.03, 10), 0.0, 1.0],
		[&"Floor_Brick", Vector3(0, 0.03, 6), 1.57, 1.0],
		[&"Floor_Brick", Vector3(0, 0.03, 2), 0.0, 1.0],
		[&"Floor_Brick", Vector3(0, 0.03, -2), 1.57, 1.0],
		[&"Floor_Brick", Vector3(0, 0.03, -6), 0.0, 1.0],
		[&"Floor_Brick", Vector3(0, 0.03, -10), 1.57, 1.0],
		# Panneaux muraux nord, de part et d'autre du portail scellé.
		[&"Wall_Plaster_Straight", Vector3(-6.5, 0, -12.7), 0.0, 1.35],
		[&"Wall_Plaster_Straight", Vector3(6.5, 0, -12.7), 0.0, 1.35],
		# Mobilier martial : râtelier, bouclier, banc d'attente, caisse.
		[&"WeaponStand", Vector3(-9.6, 0, 4), 1.57, 1.1],
		[&"Shield_Wooden", Vector3(-9.9, 0.3, 5.6), 1.9, 1.1],
		[&"Bench", Vector3(9.6, 0, 8), -1.57, 1.1],
		[&"FarmCrate_Empty", Vector3(9.7, 0, -8.5), 0.4, 1.0],
		[&"Scroll_1", Vector3(9.6, 0.62, -8.4), 2.1, 1.0],
		# Bannières latérales et lanternes sur les colonnes médianes.
		[&"Banner_1", Vector3(-10.9, 5.2, -4), 1.57, 1.4],
		[&"Banner_1", Vector3(10.9, 5.2, -4), -1.57, 1.4],
		[&"Lantern_Wall", Vector3(-5.2, 2.6, 0), 1.57, 1.1],
		[&"Lantern_Wall", Vector3(5.2, 2.6, 0), -1.57, 1.1],
		# Chantier visuel 2026-08-12 — l'ÂGE du lieu : lierre retombant des
		# murs (origine du modèle en HAUT : bbox y −2,12..0,48, on donne la
		# hauteur d'accroche) et gravats aux angles morts. Décor pur, aucune
		# collision, loin des portes (seuils à x ±2,1) et des colonnes.
		[&"Prop_Vine1", Vector3(-3.2, 5.2, -12.9), 0.0, 1.2],
		[&"Prop_Vine2", Vector3(7.9, 5.0, -12.85), 0.0, 1.3],
		[&"Prop_Vine1", Vector3(-10.95, 4.6, 6.5), 1.57, 1.1],
		[&"SM_Dungeon_RubbleSmall", Vector3(-10.2, 0, 11.8), 0.9, 1.4],
		[&"SM_Dungeon_RubbleSmall", Vector3(10.3, 0, -10.9), 2.2, 1.3],
	]
	for entry: Array in placements:
		var packed: PackedScene = AssetRegistry.model(entry[0] as StringName)
		if packed == null:
			continue
		var prop: Node3D = packed.instantiate() as Node3D
		prop.name = "%s_%d" % [String(entry[0] as StringName),
			dressing.get_child_count()]
		prop.position = entry[1] as Vector3
		prop.rotation.y = float(entry[2])
		# §3 : correction d'échelle du kit végétal, point unique (`KitScale`).
		prop.scale = Vector3.ONE * float(entry[3]) \
			* KitScale.factor(String(entry[0] as StringName))
		dressing.add_child(prop)
	# Lumières chaudes MOTIVÉES par les deux lanternes (§7.8 : sources
	# motivées, aucun couloir noir).
	for x: float in [-5.2, 5.2]:
		var glow: OmniLight3D = OmniLight3D.new()
		glow.light_color = Color(1.0, 0.72, 0.38)
		glow.light_energy = 0.9
		glow.omni_range = 6.0
		glow.position = Vector3(x, 2.9, 0)
		dressing.add_child(glow)


## ART-Q5 — colonne de production : TROIS modules de pilier empilés
## (3 × 3,04 m ≈ 9,1 m, architecture modulaire réelle) remplacent le visuel
## graybox ; la COLLISION boîte de la colonne reste l'autorité. Repli :
## le graybox reste visible, rien d'autre ne change.
func _dress_column(index: int, foot: Vector3) -> void:
	# V4 lot 11 : CASSER la répétition (§11.J) — piliers larges et étroits
	# alternés, le même module ne se répète jamais côte à côte.
	var wide: bool = index % 2 == 0
	var packed: PackedScene = AssetRegistry.resolve(&"arch.column.module") \
		if wide else AssetRegistry.model(&"Corner_Exterior_Brick")
	if packed == null:
		packed = AssetRegistry.resolve(&"arch.column.module")
		wide = true   # repli : c'est bien le module LARGE qui est monté
	if packed == null:
		return
	var column_body: Node = get_node_or_null("Column%d" % index)
	if column_body != null:
		for child: Node in column_body.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).visible = false
	var stack: Node3D = Node3D.new()
	stack.name = "ColumnStack%d" % index
	stack.position = foot
	# Alternance de lacet par segment : les briques ne se répètent pas en
	# pile parfaite (§7.3 : variation contre la répétition).
	#
	# REVUE V4 — deux défauts mesurés, corrigés ici :
	# 1. Les deux modules ont leur pivot DANS UN COIN, pas au centre : le
	#    centre de masse est à 0,329 m de l'axe (module large) et 0,262 m
	#    (module étroit). Chaque quart de tour le promenait autour du fût, d'où
	#    des tronçons décalés jusqu'à 0,658 m les uns des autres — les colonnes
	#    zigzaguaient. On remet donc la section sur l'axe AVANT de la tourner,
	#    en retranchant le vecteur pivot lui-même tourné et mis à l'échelle.
	# 2. Le pas d'empilement vaut 3,04 m alors que les modules mesurent
	#    3,0428 m (large, bbox Y −0,0185..3,0243) et 3,0156 m (étroit, bbox Y
	#    −0,0071..3,0085) : les colonnes étroites ouvraient 2,4 cm de fente
	#    traversante à chaque joint, soit six traits de lumière dans la salle.
	#    Plutôt que de changer le pas — la cote 3,04 m est celle du gabarit de
	#    la salle et le test d'intégration la vérifie — on étire la hauteur du
	#    module pour qu'elle TOMBE JUSTE sur le pas : 3,04 / 3,0156 = 1,00809
	#    (étroit, +0,8 %) et 3,04 / 3,0428 = 0,99908 (large, −0,1 %). Les
	#    joints deviennent jointifs sans déformation perceptible.
	const STEP: float = 3.04
	var pivot: Vector3 = Vector3(-0.1337, 0.0, 0.1560) if wide \
		else Vector3(-0.0876, 0.0, 0.0888)
	var flat: Vector3 = Vector3(1.6, STEP / 3.0428, 1.6) if wide \
		else Vector3(2.1, STEP / 3.0156, 2.1)
	for level: int in range(3):
		var segment: Node3D = packed.instantiate() as Node3D
		segment.name = "Segment%d" % level
		var yaw: float = PI * 0.5 * float((index + level) % 4)
		segment.rotation.y = yaw
		segment.scale = flat
		segment.position = Vector3(0, STEP * float(level), 0) \
			- Basis(Vector3.UP, yaw) * (pivot * flat)
		stack.add_child(segment)
	add_child(stack)


func _box(box_name: String, center: Vector3, size: Vector3, color: Color,
		emissive: bool = false) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = box_name
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var mesh_box: BoxMesh = BoxMesh.new()
	mesh_box.size = size
	mesh.mesh = mesh_box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.0
	mesh.material_override = material
	body.add_child(mesh)
	body.position = center   # AVANT add_child (règle D.0)
	add_child(body)


## Une masse PUREMENT VISUELLE : même boîte, même matériau, aucune collision.
##
## `_box()` produit un `StaticBody3D` sur la couche 1, et c'est juste pour un
## mur ou un pilier. Pour un ORNEMENT posé devant un interactable, c'est un
## défaut : la couche 1 est celle que `PlayerController._has_interact_los()`
## interroge pour savoir si la vue est dégagée. Un décor y devient un obstacle.
##
## Mesuré le 2026-08-09 (`P9c` de `test_physical_run.gd`) : debout à 0,75 m de
## `DungeonDoor`, parfaitement en face, cône et portée valides, la sélection ne
## rendait RIEN — le rayon partait dans la veine cyan. Un pas de côté rendait la
## porte sélectionnable. Le joueur, lui, appuie sur `E` au centre du battant,
## n'obtient rien et en conclut que la touche ne marche pas : c'est le défaut
## nº 1 du playtest humain du 2026-08-07, reproduit par du décor.
##
## Un ornement ne doit donc porter ni corps, ni forme de collision. Il reste
## visible, il cesse d'être un mur.
func _decor_box(box_name: String, center: Vector3, size: Vector3, color: Color,
		emissive: bool = false) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = box_name
	var mesh_box: BoxMesh = BoxMesh.new()
	mesh_box.size = size
	mesh.mesh = mesh_box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.0
	mesh.material_override = material
	mesh.position = center   # AVANT add_child (règle D.0)
	add_child(mesh)


func _setup_lighting() -> void:
	# §7.8 : sources motivées, aucun couloir noir. Deux omni cyan près du seuil
	# scellé — l'énergie du donjon filtre par la veine.
	for i: int in range(2):
		var light: OmniLight3D = OmniLight3D.new()
		light.name = "CyanLight%d" % i
		light.light_color = Color(0.5, 0.9, 0.95)
		light.light_energy = 2.2
		light.omni_range = 14.0
		light.position = Vector3(-4.0 if i == 0 else 4.0, 5.5, -8.0)
		add_child(light)
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.04, 0.05, 0.07)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.25, 0.3, 0.36)
	environment.ambient_light_energy = 0.8
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "VestibuleEnvironment"
	world_environment.environment = environment
	add_child(world_environment)


func player() -> PlayerController:
	return _player


## Caméra de référence §21.5 (« entrée du donjon ») — outil de capture
## uniquement : depuis le seuil sud, regard vers le fond de la salle.
func capture_reference_view() -> void:
	var camera: Camera3D = Camera3D.new()
	camera.name = "ReferenceCamera"
	add_child(camera)
	camera.global_position = Vector3(0, 3.2, 11.5)
	camera.look_at(Vector3(0, 2.2, -13.0), Vector3.UP)
	camera.fov = 60.0
	camera.current = true
