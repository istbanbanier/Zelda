## Vestibule de la Citadelle de l'Œil-Tempête — intérieur graybox (D.1R.4).
##
## PT-D1-10 : l'entrée vue depuis la crête n'est plus une fausse promesse — on
## entre, on explore un vestibule à colonnes éclairé de cyan, et la porte
## SCELLÉE du fond dit honnêtement que le donjon électrique est plus loin
## (Phase F). La sortie replace le joueur DEVANT la porte de la vallée, jamais
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
	if game_state != null:
		game_state.call("set_flow", 3)  # GameState.Flow.DUNGEON
		game_state.call("consume_pending_spawn")  # tag d'entrée consommé
	_build_room()
	_setup_lighting()


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
	# Braseros (réf. 02 : flammes chaudes dans l'axe) — le CONTRASTE chaud/froid
	# du donjon commence ici : ambre motivé contre veine cyan (§7.8).
	for i: int in range(4):
		var x: float = -6.0 if i % 2 == 0 else 6.0
		var z: float = -6.0 if i < 2 else 6.0
		_box("Brazier%d" % i, Vector3(x, 0.55, z), Vector3(0.9, 1.1, 0.9),
			Color(0.30, 0.22, 0.16))
		_box("BrazierCoal%d" % i, Vector3(x, 1.2, z), Vector3(0.6, 0.25, 0.6),
			Color(0.98, 0.55, 0.18), true)
		var flame: OmniLight3D = OmniLight3D.new()
		flame.name = "BrazierLight%d" % i
		flame.light_color = Color(1.0, 0.62, 0.28)
		flame.light_energy = 1.6
		flame.omni_range = 9.0
		flame.position = Vector3(x, 2.0, z)
		add_child(flame)
	# La porte SCELLÉE du fond : masse sombre + veine cyan sous un linteau de
	# bronze — « visiblement et honnêtement scellée », le donjon quatre-salles
	# est Phase F. C'est le « second seuil » de la référence 02.
	_box("SealedDoor", Vector3(0, 3, -12.9), Vector3(5, 6, 0.4), Color(0.1, 0.1, 0.14))
	_box("SealedSeam", Vector3(0, 3, -12.65), Vector3(0.3, 5.4, 0.1), COL_CYAN, true)
	_box("SealedLintel", Vector3(0, 6.6, -12.8), Vector3(6.4, 0.8, 0.7),
		Color(0.42, 0.30, 0.18))

	var exit_door: SceneDoor = SceneDoor.new()
	exit_door.name = "ExitDoor"
	exit_door.verb = "Sortir"
	exit_door.target_scene = "res://scenes/world/valley/ValleyWorld.tscn"
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
