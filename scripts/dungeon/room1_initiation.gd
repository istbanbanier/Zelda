## Citadelle de l'Œil-Tempête — SALLE 1, initiation (MASTER_SPEC §15.5).
##
## Le cahier des charges, ligne à ligne, et où il est tenu :
##
## | §15.5 | ici |
## |---|---|
## | source et récepteur séparés par un vide court | la source à l'ouest, le récepteur près de la porte au nord ; entre les deux, 2,8 m de VIDE entre les deux plaques — le seul segment que le câble ne franchit pas |
## | bloc métallique mobile | `PushableBlock`, corps simulé de 40 kg poussé à la main |
## | deux plaques clairement connectées au circuit | `PlateWest` / `PlateEast`, chacune au bout d'une ligne de câbles visible |
## | pousser le bloc pour toucher les deux | le couloir de guidage mène le bloc entre les plaques et une butée l'arrête EXACTEMENT au contact |
## | propagation lumineuse visible | `ElectricVisual` : chaque segment attend son rang de graphe, le cyan parcourt le circuit |
## | porte s'ouvre avec délai 0,6-1,2 s | `ElectricDoor.open_delay = 0.9` |
## | objectif compréhensible sans texte | aucune étiquette dans la salle : la porte sombre au fond, la ligne cyan qui s'arrête net au vide, les chevrons du couloir |
## | bouton reset | `ResetButton` à l'entrée, ramène le bloc à son départ |
## | solution impossible à perdre | butée au nord, rails latéraux, retour du bloc s'il sort du monde, porte LATCHÉE ouverte |
##
## Le décor est construit en code (comme `CitadelVestibule`) : cotes
## lisibles en diff, aucune scène binaire à relire à l'aveugle.
class_name Room1Initiation
extends DungeonRoom

## Le puzzle vient d'être résolu (le récepteur s'allume).
signal solved()

const VESTIBULE: String = "res://scenes/world/citadel/CitadelVestibule.tscn"
const HALL: String = "res://scenes/dungeon/rooms/CentralHall.tscn"
## Hauteur du plan de câblage : tout le circuit court au ras du sol.
const WIRE_Y: float = 0.12
## Axe du couloir de poussée et ligne des plaques.
const CHANNEL_X: float = 0.0
const CONTACT_Z: float = -4.0
## Départ du bloc : 7 m au sud du contact, dans l'axe de l'entrée.
const BLOCK_START: Vector3 = Vector3(0, 0.81, 3.0)

var _door: ElectricDoor = null
var _receiver: ElectricNode = null
var _source: ElectricNode = null
var _block: PushableBlock = null
var _reset_button: ResetButton = null
var _solved: bool = false
var _last_block_position: Vector3 = Vector3.ZERO

@onready var _player: PlayerController = get_node_or_null("Player") \
	as PlayerController


func _ready() -> void:
	room_id = &"dungeon.room.initiation.01"
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 3)  # GameState.Flow.DUNGEON
	var spawn_tag: StringName = consume_spawn_tag()
	_build_shell()
	_build_channel()
	_build_circuit()
	_build_block()
	_build_reset_button()
	_setup_lighting()
	var graph_node: ElectricGraph = ElectricGraph.new()
	graph_node.name = "Graph"
	add_child(graph_node)
	set_graph(graph_node)
	_receiver.power_changed.connect(_on_receiver_power_changed)
	# §19.4 : l'état s'APPLIQUE, il ne se rejoue pas — une salle déjà
	# résolue démarre porte ouverte, sans animation ni délai.
	var state: Dictionary = load_room_state()
	if not state.is_empty():
		apply_room_state(state)
	# §6.1 : on réapparaît DEVANT la porte qu'on vient de franchir.
	place_player_at_spawn(_player, spawn_tag, {
		&"room1_from_hall": Vector3(0, 0.3, -17.5),
		&"room1_from_vestibule": Vector3(0, 0.3, 11.0),
	})


## Coque : sol, plafond, murs, seuil d'entrée au sud, porte au nord et
## couloir de sortie honnêtement scellé (la suite du donjon est F.3).
func _build_shell() -> void:
	box("Floor", Vector3(0, -0.5, 0), Vector3(20, 1, 26), COL_FLOOR)
	box("Ceiling", Vector3(0, 8.5, 0), Vector3(20, 1, 26), COL_STONE)
	box("WallWest", Vector3(-10.25, 4, 0), Vector3(0.5, 8, 26), COL_STONE)
	box("WallEast", Vector3(10.25, 4, 0), Vector3(0.5, 8, 26), COL_STONE)
	# Nord : percement de 4 m pour la porte du puzzle.
	box("WallNorthWest", Vector3(-6, 4, -13.25), Vector3(8, 8, 0.5), COL_STONE)
	box("WallNorthEast", Vector3(6, 4, -13.25), Vector3(8, 8, 0.5), COL_STONE)
	box("WallNorthLintel", Vector3(0, 6.5, -13.25), Vector3(4, 3, 0.5), COL_BRONZE)
	# Sud : seuil d'entrée de 4,4 m, occupé par la porte de scène.
	box("WallSouthWest", Vector3(-5.8, 4, 13.25), Vector3(8.4, 8, 0.5), COL_STONE)
	box("WallSouthEast", Vector3(5.8, 4, 13.25), Vector3(8.4, 8, 0.5), COL_STONE)
	box("WallSouthLintel", Vector3(0, 6.5, 13.25), Vector3(4.4, 3, 0.5), COL_STONE)
	# Couloir nord : le débouché de la porte existe VRAIMENT (pas de vide
	# derrière), et se termine sur un seuil scellé — la suite du donjon
	# arrive en F.3. Une porte qui ouvre sur le néant serait un mensonge.
	box("CorridorFloor", Vector3(0, -0.5, -16.8), Vector3(6, 1, 7), COL_FLOOR)
	box("CorridorCeiling", Vector3(0, 6.5, -16.8), Vector3(6, 1, 7), COL_STONE)
	box("CorridorWest", Vector3(-3.25, 3, -16.8), Vector3(0.5, 8, 7), COL_STONE)
	box("CorridorEast", Vector3(3.25, 3, -16.8), Vector3(0.5, 8, 7), COL_STONE)
	# F.6 : le couloir nord ne se termine plus sur un seuil scellé — il
	# MÈNE à la salle centrale. La promesse faite au joueur est tenue.
	box("CorridorEnd", Vector3(0, 2.5, -20.3), Vector3(6, 6, 0.5),
		Color(0.12, 0.12, 0.16))
	decor("CorridorEndSeam", Vector3(0, 2.5, -20.0), Vector3(0.25, 4.4, 0.1),
		COL_CYAN, true)
	scene_door("DoorToHall", "Entrer dans la salle centrale", HALL,
		&"hall_from_room1", Vector3(0, 2.5, -19.9), Vector3(4.2, 5.0, 0.4))

	scene_door("ExitDoor", "Sortir", VESTIBULE, &"vestibule_from_room1",
		Vector3(0, 2.5, 13.4), Vector3(4.2, 5.0, 0.4))


## Le couloir de poussée : deux rails bas, une butée au nord, trois
## chevrons au sol. C'est L'ÉNONCÉ de l'énigme, sans une seule ligne de
## texte (§15.5 : « objectif compréhensible sans texte »).
func _build_channel() -> void:
	# Les rails s'arrêtent 1 m avant les plaques : ils guident la poussée,
	# ils ne masquent jamais le contact que le joueur doit LIRE.
	for side: int in [-1, 1]:
		box("ChannelRail%s" % ("West" if side < 0 else "East"),
			Vector3(CHANNEL_X + 1.35 * float(side), 0.12, 0.5),
			Vector3(0.3, 0.25, 7.0), COL_COPPER)
	# Butée : le bloc poussé jusqu'au bout s'arrête EXACTEMENT au contact.
	# C'est elle qui rend la solution impossible à manquer — et impossible
	# à dépasser.
	box("ChannelStop", Vector3(CHANNEL_X, 0.3, CONTACT_Z - 0.95),
		Vector3(2.7, 0.6, 0.3), COL_COPPER)
	for i: int in range(3):
		decor("Chevron%d" % i, Vector3(CHANNEL_X, 0.02, 1.2 - 2.2 * float(i)),
			Vector3(1.4, 0.04, 0.28), COL_BRONZE)


## Le circuit de §15.5 : source → ligne de câbles → PlateWest ‖ VIDE ‖
## PlateEast → ligne de câbles → récepteur → porte.
func _build_circuit() -> void:
	# Source : socle à l'ouest, pulsation lente (§15.4).
	box("SourcePedestal", Vector3(-7, 0.45, CONTACT_Z), Vector3(1.0, 0.9, 1.0),
		COL_BRONZE)
	_source = make_node(&"dungeon.node.room1_source.01",
		ElectricNode.Kind.SOURCE, Vector3(-7, 1.15, CONTACT_Z),
		[Vector3(0.1, WIRE_Y - 1.15, 0)], 0.55)
	_source.name = "Source"
	attach_visual(_source, Vector3(0.7, 0.7, 0.7), Vector3.ZERO, true)

	cable_run("WireWest", Vector3(-6.4, WIRE_Y, CONTACT_Z),
		Vector3(-2.4, WIRE_Y, CONTACT_Z), Vector3.RIGHT, 5)

	_make_plate(&"dungeon.node.room1_plate.01",
		"PlateWest", Vector3(-1.4, 0.55, CONTACT_Z), -1.0)
	# Les deux plaques ne se touchent JAMAIS : 2,8 m les séparent, contre
	# 0,85 m de portée de port. Le vide court de §15.5 est un vrai vide,
	# et un test le mesure au lieu de le supposer.
	_make_plate(&"dungeon.node.room1_plate.02",
		"PlateEast", Vector3(1.4, 0.55, CONTACT_Z), 1.0)

	cable_run("WireEast", Vector3(2.4, WIRE_Y, CONTACT_Z),
		Vector3(6.4, WIRE_Y, CONTACT_Z), Vector3.RIGHT, 5)
	cable_run("WireNorth", Vector3(6.9, WIRE_Y, -4.9),
		Vector3(6.9, WIRE_Y, -11.9), Vector3.FORWARD, 8)
	cable_run("WireDoor", Vector3(6.4, WIRE_Y, -12.4),
		Vector3(4.4, WIRE_Y, -12.4), Vector3.RIGHT, 3)

	# Récepteur : l'anneau qui se ferme, à hauteur d'œil près de la porte.
	box("ReceiverPedestal", Vector3(3.4, 0.6, -12.4), Vector3(0.8, 1.2, 0.6),
		COL_BRONZE)
	_receiver = make_node(&"dungeon.node.room1_receiver.01",
		ElectricNode.Kind.RECEIVER, Vector3(3.4, 1.7, -12.4),
		[Vector3(0.5, WIRE_Y - 1.7, 0), Vector3(-0.5, WIRE_Y - 1.7, 0)], 0.55)
	_receiver.name = "Receiver"
	var ring: ReceiverRing = ReceiverRing.new()
	ring.name = "Ring"
	_receiver.add_child(ring)

	cable_run("WireDoorSpur", Vector3(2.4, WIRE_Y, -12.4),
		Vector3(1.4, WIRE_Y, -12.4), Vector3.RIGHT, 2)

	_door = ElectricDoor.new()
	_door.name = "PuzzleDoor"
	_door.door_id = &"dungeon.door.room1_north.01"
	_door.receiver_path = NodePath("../Receiver")
	_door.open_delay = 0.9      # §15.5 : dans la fenêtre 0,6-1,2 s
	_door.panel_size = Vector3(4.0, 5.0, 0.5)
	_door.travel = 5.2
	# Le nœud de la porte est branché au bout de l'éperon de câble : la
	# porte fait PARTIE du circuit, elle n'est pas commandée en douce.
	_door.node_port_offsets = [Vector3(0.9, WIRE_Y, 0.85)]
	_door.position = Vector3(0, 0, -13.25)
	add_child(_door)


func _build_block() -> void:
	_block = PushableBlock.new()
	_block.name = "MetalBlock"
	_block.persistent_id = &"dungeon.block.room1_conductor.01"
	_block.collision_layer = 128   # Physics Prop
	_block.collision_mask = 3      # World Static + Player
	_block.bounds = Vector3(14, 20, 20)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(1.6, 1.6, 1.6)
	shape.shape = box_shape
	_block.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "Mesh"
	var mesh_box: BoxMesh = BoxMesh.new()
	mesh_box.size = Vector3(1.6, 1.6, 1.6)
	mesh.mesh = mesh_box
	# §15.4 : « conducteur : cuivre/métal patiné ». Le bloc doit se LIRE
	# comme du métal, sinon rien ne dit au joueur qu'il conduit — mesuré
	# sur la capture d'entrée : sans matériau, il passait pour une caisse.
	var metal: StandardMaterial3D = StandardMaterial3D.new()
	# Métal patiné CLAIR : sous ces lampes, un métallique élevé sans sonde
	# de réflexion rend noir (mesuré sur la capture d'entrée). L'albédo
	# porte donc la lecture, et la bande conductrice tranchera dessus.
	metal.albedo_color = Color(0.60, 0.62, 0.60)
	metal.metallic = 0.2
	metal.roughness = 0.45
	mesh.material_override = metal
	_block.add_child(mesh)
	_block.position = BLOCK_START   # AVANT add_child (règle D.0)
	add_child(_block)
	_block.set_rescue_transform(Transform3D(Basis.IDENTITY, BLOCK_START))
	register_block(_block)

	# Le conducteur mobile de §15.1, porté par le bloc : ses deux ports
	# sortent par les faces est et ouest, à hauteur des plaques.
	var conductor: ElectricNode = make_node(
		&"dungeon.node.room1_block.01", ElectricNode.Kind.MOVABLE_CONDUCTOR,
		Vector3.ZERO, [Vector3(-0.85, 0, 0), Vector3(0.85, 0, 0)], 0.85,
		_block)
	conductor.name = "Conductor"
	attach_visual(conductor, Vector3(1.62, 0.3, 1.62), Vector3(0, 0.2, 0), false)
	_last_block_position = BLOCK_START


## §15.2 pt. 1-2 : « un déplacement marque le sous-graphe `dirty` », et
## les changements sont regroupés jusqu'à la fin du tick. Le seuil de
## 2 cm est ce qui empêche un recalcul par image sur un bloc qui frémit :
## tant que rien ne bouge VRAIMENT, le graphe ne travaille pas.
func _physics_process(_delta: float) -> void:
	if _block == null or graph() == null:
		return
	if _block.global_position.distance_squared_to(_last_block_position) < 0.0004:
		return
	_last_block_position = _block.global_position
	graph().mark_dirty()


func _build_reset_button() -> void:
	_reset_button = ResetButton.new()
	_reset_button.name = "ResetButton"
	_reset_button.position = Vector3(-3.6, 0.55, 6.0)
	add_child(_reset_button)
	decor("ResetMarker", Vector3(-3.6, 0.03, 6.0), Vector3(1.6, 0.04, 1.6),
		COL_IVORY)


func _make_plate(id: StringName, plate_name: String, at: Vector3,
		facing: float) -> ElectricNode:
	box(plate_name + "Pedestal", at + Vector3(0, -0.3, 0),
		Vector3(0.7, 0.6, 1.4), COL_BRONZE)
	var plate: ElectricNode = make_node(id, ElectricNode.Kind.CONNECTOR, at,
		[Vector3(-0.45 * facing, 0.25, 0), Vector3(0.5 * facing, -0.43, 0)],
		0.85)
	plate.name = plate_name
	attach_visual(plate, Vector3(0.22, 0.8, 1.2),
		Vector3(-0.3 * facing, 0.1, 0), false)
	return plate


func _on_receiver_power_changed(powered: bool, _power: float) -> void:
	if not powered or _solved:
		return
	_solved = true
	save_room_state()
	solved.emit()


## §19.1 : la salle ajoute son propre fait — l'énigme est-elle résolue ?
func room_state() -> Dictionary:
	var state: Dictionary = super()
	state["solved"] = _solved
	state["door_open"] = _door != null and _door.is_latched()
	return state


func apply_room_state(state: Dictionary) -> void:
	super(state)
	_solved = bool(state.get("solved", false))
	if bool(state.get("door_open", false)) and _door != null:
		_door.force_open()


func _setup_lighting() -> void:
	# §7.8 : ocre/bronze sombre, énergie cyan directionnelle, AUCUN
	# couloir noir. Deux sources motivées : le socle de la source à
	# l'ouest, l'anneau du récepteur au nord.
	var source_light: OmniLight3D = OmniLight3D.new()
	source_light.name = "SourceGlow"
	source_light.light_color = Color(0.5, 0.9, 0.95)
	source_light.light_energy = 2.4
	source_light.omni_range = 12.0
	source_light.position = Vector3(-7, 1.6, CONTACT_Z)
	add_child(source_light)
	var door_light: OmniLight3D = OmniLight3D.new()
	door_light.name = "DoorGlow"
	door_light.light_color = Color(0.5, 0.9, 0.95)
	door_light.light_energy = 1.8
	door_light.omni_range = 11.0
	door_light.position = Vector3(2.4, 3.0, -12.0)
	add_child(door_light)
	# §7.8 : « aucun couloir noir », et §15.5 : l'énigme doit se lire sans
	# texte — donc se VOIR. Mesuré sur la première capture d'entrée : le
	# premier plan tombait dans le noir et le bloc disparaissait. Quatre
	# braseros ambre jalonnent le couloir de poussée.
	for i: int in range(4):
		var warm: OmniLight3D = OmniLight3D.new()
		warm.name = "EntryGlow%d" % i
		warm.light_color = Color(1.0, 0.74, 0.42)
		warm.light_energy = 2.2
		warm.omni_range = 14.0
		warm.position = Vector3(-6.5 if i % 2 == 0 else 6.5, 3.6,
			10.0 - 7.0 * float(i / 2))
		add_child(warm)
		box("Brazier%d" % i, warm.position - Vector3(0, 2.85, 0),
			Vector3(0.7, 1.5, 0.7), COL_BRONZE)
		decor("BrazierCoal%d" % i, warm.position - Vector3(0, 2.0, 0),
			Vector3(0.5, 0.22, 0.5), Color(0.98, 0.58, 0.22), true)
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.04, 0.05, 0.07)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.26, 0.29, 0.34)
	environment.ambient_light_energy = 1.05
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "RoomEnvironment"
	world_environment.environment = environment
	add_child(world_environment)


## Amène la salle à l'état QUE LE JOUEUR ATTEINT en poussant le bloc :
## le conducteur au contact, et rien d'autre. La suite — courant, anneau,
## délai, mécanisme — se déroule toute seule par le chemin normal. Utilisé
## par `capture_reference.gd --call=` pour photographier un état de jeu, et
## par aucune règle de gameplay.
func capture_state_solved() -> void:
	if _block == null:
		return
	_block.place_at(Transform3D(Basis.IDENTITY,
		Vector3(CHANNEL_X, BLOCK_START.y, CONTACT_Z)))
	if graph() != null:
		graph().mark_dirty()


func door() -> ElectricDoor:
	return _door


func receiver() -> ElectricNode:
	return _receiver


func source() -> ElectricNode:
	return _source


func block() -> PushableBlock:
	return _block


func reset_button() -> ResetButton:
	return _reset_button


func is_solved() -> bool:
	return _solved


func player() -> PlayerController:
	return _player
