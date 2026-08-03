## Citadelle de l'Œil-Tempête — SALLE 3, relais rotatifs (§15.7).
##
## | §15.7 | ici |
## |---|---|
## | quatre colonnes | `ElectricRelay` × 4, en carré autour de la salle |
## | ports visibles | deux bras de cuivre sortent EXACTEMENT là où sont les ports (§15.3) |
## | rotations discrètes de 90° | `step_deg = 90`, une rotation à la fois, 0,35 s |
## | chaque segment valide s'allume progressivement | le graphe alimente ce qu'il atteint : la ligne cyan s'arrête AU relais mal tourné |
## | aucune erreur ne tue immédiatement | aucun danger dans cette salle : se tromper coûte un quart de tour |
## | feedback distinct si chemin partiel | la longueur de la ligne allumée DIT jusqu'où le courant passe ; l'anneau du récepteur, lui, reste ouvert |
## | solveur/test automatique | `test_room3_relays` énumère les 256 configurations et prouve qu'au moins une résout — et que celle du départ n'en est pas une |
## | bouton reset | `ResetButton` : les quatre colonnes retrouvent leur orientation de départ |
##
## Le circuit fait le tour de la salle : source à l'ouest, récepteur à
## l'est, et entre les deux un chemin en créneau que seules quatre
## orientations correctes referment.
class_name Room3Relays
extends DungeonRoom

signal solved()

const HALL: String = "res://scenes/dungeon/rooms/CentralHall.tscn"
## Le circuit court à hauteur de main : une énigme de rotation se lit
## debout, pas au ras du sol.
const WIRE_Y: float = 1.0

var _door: ElectricDoor = null
var _receiver: ElectricNode = null
var _source: ElectricNode = null
var _relays: Array[ElectricRelay] = []
var _reset_button: ResetButton = null
var _solved: bool = false

@onready var _player: PlayerController = get_node_or_null("Player") \
	as PlayerController


func _ready() -> void:
	room_id = &"dungeon.room.relays.03"
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 3)  # GameState.Flow.DUNGEON
	var spawn_tag: StringName = consume_spawn_tag()
	_build_shell()
	_build_circuit()
	_build_reset_button()
	_setup_lighting()
	var graph_node: ElectricGraph = ElectricGraph.new()
	graph_node.name = "Graph"
	add_child(graph_node)
	set_graph(graph_node)
	_receiver.power_changed.connect(_on_receiver_power_changed)
	var state: Dictionary = load_room_state()
	if not state.is_empty():
		apply_room_state(state)
	# §6.1 : on réapparaît DEVANT la porte franchie, jamais au spawn.
	place_player_at_spawn(_player, spawn_tag, {
		&"room3_from_hall": Vector3(0, 0.3, 9.0),
		&"room3_from_shortcut": Vector3(13.5, 0.3, -4),
	})


func _build_shell() -> void:
	box("Floor", Vector3(0, -0.5, 0), Vector3(20, 1, 22), COL_FLOOR)
	box("Ceiling", Vector3(0, 9.5, 0), Vector3(20, 1, 22), COL_STONE)
	box("WallWest", Vector3(-10.25, 4.5, 0), Vector3(0.5, 9, 22), COL_STONE)
	box("WallNorth", Vector3(0, 4.5, -11.25), Vector3(20, 9, 0.5), COL_STONE)
	# Est : percement de 4 m pour la porte du puzzle, à hauteur du récepteur.
	box("WallEastNorth", Vector3(10.25, 4.5, -7.5), Vector3(0.5, 9, 7), COL_STONE)
	box("WallEastSouth", Vector3(10.25, 4.5, 3.5), Vector3(0.5, 9, 15), COL_STONE)
	box("WallEastLintel", Vector3(10.25, 7, -4), Vector3(0.5, 4, 4), COL_BRONZE)
	# Sud : seuil d'entrée.
	box("WallSouthWest", Vector3(-5.8, 4.5, 11.25), Vector3(8.4, 9, 0.5), COL_STONE)
	box("WallSouthEast", Vector3(5.8, 4.5, 11.25), Vector3(8.4, 9, 0.5), COL_STONE)
	box("WallSouthLintel", Vector3(0, 7, 11.25), Vector3(4.4, 4, 0.5), COL_STONE)
	# Couloir de sortie à l'est, scellé au fond (F.6 raccordera les salles).
	box("CorridorFloor", Vector3(13.5, -0.5, -4), Vector3(7, 1, 6), COL_FLOOR)
	box("CorridorNorth", Vector3(13.5, 3, -7.25), Vector3(7, 8, 0.5), COL_STONE)
	box("CorridorSouth", Vector3(13.5, 3, -0.75), Vector3(7, 8, 0.5), COL_STONE)
	box("CorridorCeiling", Vector3(13.5, 6.5, -4), Vector3(7, 1, 6), COL_STONE)
	box("CorridorEnd", Vector3(17.0, 2.5, -4), Vector3(0.5, 6, 6),
		Color(0.12, 0.12, 0.16))
	decor("CorridorEndSeam", Vector3(16.7, 2.5, -4),
		Vector3(0.1, 4.4, 0.25), COL_CYAN, true)
	scene_door("DoorToHall", "Rejoindre la salle centrale", HALL,
		&"hall_from_room3", Vector3(16.6, 2.5, -4), Vector3(0.4, 5.0, 4.2))

	var entry: SceneDoor = SceneDoor.new()
	entry.name = "ExitDoor"
	entry.verb = "Sortir"
	entry.target_scene = HALL
	entry.spawn_tag = &"hall_from_room3"
	entry.collision_layer = 1
	entry.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(4.2, 5.0, 0.4)
	shape.shape = box_shape
	entry.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var mesh_box: BoxMesh = BoxMesh.new()
	mesh_box.size = Vector3(4.2, 5.0, 0.4)
	mesh.mesh = mesh_box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.14, 0.16, 0.2)
	mesh.material_override = material
	entry.add_child(mesh)
	entry.position = Vector3(0, 2.5, 11.4)   # AVANT add_child (règle D.0)
	add_child(entry)


## Chemin en créneau : source → C1 → sud → C2 → est → C3 → nord → C4 →
## récepteur. Chaque colonne doit regarder dans les DEUX bonnes
## directions ; une seule mal tournée coupe la ligne, et cela se voit.
func _build_circuit() -> void:
	box("SourcePedestal", Vector3(-7.6, 0.4, -4), Vector3(1.0, 0.8, 1.0),
		COL_BRONZE)
	_source = make_node(&"dungeon.node.room3_source.01",
		ElectricNode.Kind.SOURCE, Vector3(-7.6, WIRE_Y, -4),
		[Vector3(0.5, 0, 0)], 0.55)
	_source.name = "Source"
	attach_visual(_source, Vector3(0.6, 0.6, 0.6), Vector3.ZERO, true)

	cable_run("WireIn", Vector3(-6.6, WIRE_Y, -4), Vector3(-5.6, WIRE_Y, -4),
		Vector3.RIGHT, 2)
	_relay(&"dungeon.node.room3_relay.01", "RelayA", Vector3(-4.4, 0, -4), 0)
	cable_run("WireSouth", Vector3(-4.4, WIRE_Y, -2.7),
		Vector3(-4.4, WIRE_Y, 0.3), Vector3.BACK, 4)
	_relay(&"dungeon.node.room3_relay.02", "RelayB", Vector3(-4.4, 0, 1.6), 1)
	cable_run("WireEast", Vector3(-3.1, WIRE_Y, 1.6), Vector3(0.9, WIRE_Y, 1.6),
		Vector3.RIGHT, 5)
	_relay(&"dungeon.node.room3_relay.03", "RelayC", Vector3(2.2, 0, 1.6), 0)
	cable_run("WireNorth", Vector3(2.2, WIRE_Y, 0.3), Vector3(2.2, WIRE_Y, -2.7),
		Vector3.FORWARD, 4)
	_relay(&"dungeon.node.room3_relay.04", "RelayD", Vector3(2.2, 0, -4), 2)
	cable_run("WireOut", Vector3(3.5, WIRE_Y, -4), Vector3(5.5, WIRE_Y, -4),
		Vector3.RIGHT, 3)

	box("ReceiverPedestal", Vector3(6.6, 0.5, -4), Vector3(0.8, 1.0, 0.6),
		COL_BRONZE)
	_receiver = make_node(&"dungeon.node.room3_receiver.01",
		ElectricNode.Kind.RECEIVER, Vector3(6.6, WIRE_Y + 0.5, -4),
		[Vector3(-0.5, -0.5, 0), Vector3(0.5, -0.5, 0)], 0.6)
	_receiver.name = "Receiver"
	var ring: ReceiverRing = ReceiverRing.new()
	ring.name = "Ring"
	_receiver.add_child(ring)

	cable_run("WireDoor", Vector3(7.6, WIRE_Y, -4), Vector3(8.6, WIRE_Y, -4),
		Vector3.RIGHT, 2)

	_door = ElectricDoor.new()
	_door.name = "PuzzleDoor"
	_door.door_id = &"dungeon.door.room3_east.01"
	_door.receiver_path = NodePath("../Receiver")
	_door.open_delay = 1.0      # §15.5 : fenêtre 0,6-1,2 s
	_door.panel_size = Vector3(0.5, 5.0, 4.0)
	_door.travel = 5.2
	_door.node_port_offsets = [Vector3(-1.15, WIRE_Y, 0)]
	_door.position = Vector3(10.25, 0, -4)
	add_child(_door)


func _relay(id: StringName, relay_name: String, at: Vector3,
		start_step: int) -> void:
	var relay: ElectricRelay = ElectricRelay.new()
	relay.name = relay_name
	relay.relay_id = id
	relay.initial_step = start_step
	relay.port_a = Vector3(0.8, 0, 0)
	relay.port_b = Vector3(0, 0, -0.8)
	relay.position = at + Vector3(0, WIRE_Y, 0)   # AVANT add_child
	add_child(relay)
	_relays.append(relay)


func _build_reset_button() -> void:
	_reset_button = ResetButton.new()
	_reset_button.name = "ResetButton"
	_reset_button.verb = "Réinitialiser les colonnes"
	_reset_button.position = Vector3(-3.0, 0.55, 8.0)
	add_child(_reset_button)
	decor("ResetMarker", Vector3(-3.0, 0.03, 8.0), Vector3(1.6, 0.04, 1.6),
		COL_IVORY)


## §15.7 : « bouton reset remet la configuration initiale ».
func reset_room() -> void:
	super()
	for relay: ElectricRelay in _relays:
		relay.reset_to_initial()
	if graph() != null:
		graph().mark_dirty()


func _on_receiver_power_changed(powered: bool, _power: float) -> void:
	if not powered or _solved:
		return
	_solved = true
	save_room_state()
	solved.emit()


func room_state() -> Dictionary:
	var state: Dictionary = super()
	var steps: Array[Dictionary] = []
	for relay: ElectricRelay in _relays:
		steps.append({"id": String(relay.relay_id), "step": relay.step_index()})
	state["relays"] = steps
	state["solved"] = _solved
	state["door_open"] = _door != null and _door.is_latched()
	return state


func apply_room_state(state: Dictionary) -> void:
	super(state)
	for entry: Variant in (state.get("relays", []) as Array):
		var relay_state: Dictionary = entry as Dictionary
		var id: StringName = StringName(String(relay_state.get("id", "")))
		for relay: ElectricRelay in _relays:
			if relay.relay_id == id:
				relay.set_step_index(int(relay_state.get("step", 0)))
	_solved = bool(state.get("solved", false))
	if graph() != null:
		graph().mark_dirty()
		graph().recompute()
	if bool(state.get("door_open", false)) and _door != null:
		_door.force_open()


func _setup_lighting() -> void:
	for i: int in range(4):
		var warm: OmniLight3D = OmniLight3D.new()
		warm.name = "HallGlow%d" % i
		warm.light_color = Color(1.0, 0.74, 0.42)
		warm.light_energy = 2.4
		warm.omni_range = 16.0
		warm.position = Vector3(-7.5 if i % 2 == 0 else 7.5, 3.6,
			8.0 - 11.0 * float(i / 2))
		add_child(warm)
		box("Brazier%d" % i, warm.position - Vector3(0, 2.9, 0),
			Vector3(0.7, 1.4, 0.7), COL_BRONZE)
		decor("BrazierCoal%d" % i, warm.position - Vector3(0, 2.1, 0),
			Vector3(0.5, 0.22, 0.5), Color(0.98, 0.58, 0.22), true)
	var door_light: OmniLight3D = OmniLight3D.new()
	door_light.name = "DoorGlow"
	door_light.light_color = Color(0.5, 0.9, 0.95)
	door_light.light_energy = 2.0
	door_light.omni_range = 12.0
	door_light.position = Vector3(8.0, 3.0, -4)
	add_child(door_light)
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


## Pose la configuration gagnante — celle qu'un joueur atteint en tournant
## les colonnes. Sert aux captures ; aucune règle de jeu.
func capture_state_solved() -> void:
	var solution: Array[int] = [2, 0, 1, 3]
	for i: int in range(mini(solution.size(), _relays.size())):
		_relays[i].set_step_index(solution[i])
	if graph() != null:
		graph().mark_dirty()
		graph().recompute()


func relays() -> Array[ElectricRelay]:
	return _relays


func door() -> ElectricDoor:
	return _door


func receiver() -> ElectricNode:
	return _receiver


func source() -> ElectricNode:
	return _source


func reset_button() -> ResetButton:
	return _reset_button


func is_solved() -> bool:
	return _solved


func player() -> PlayerController:
	return _player
