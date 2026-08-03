## Citadelle de l'Œil-Tempête — SALLE 4, batterie transportable (§15.8).
##
## | §15.8 | ici |
## |---|---|
## | une source, deux mécanismes successifs | 1. charger la batterie au socket de la source ; 2. la porter jusqu'au socket de la porte, de l'autre côté de l'eau |
## | batterie chargeable et transportable | `PortableBattery` : charge stockée, socket et décharge sont trois choses distinctes (§15.3) |
## | socket explicite | `ObjectSocket` : un berceau visible, une zone réelle, un calage franc — jamais « proche d'un point invisible » |
## | zone d'eau conductrice dangereuse lorsqu'alimentée | la nappe est un nœud `WATER_ZONE` : sous tension elle frappe en continu, coupée elle est inoffensive |
## | couper le courant OU créer une passerelle isolante | les deux marchent : le levier coupe la source (l'eau s'éteint), ou la planche de bois se pose sur les berceaux et on passe au-dessus |
## | batterie hors limites réapparaît | héritée de `PushableBlock` (§14.3) ; son transform de secours est du côté de la CHARGE |
## | aucune porte ne verrouille la batterie du mauvais côté | aucune porte entre la batterie et son socket de charge ; la porte du fond, elle, reste ouverte une fois ouverte |
## | retour toujours possible | l'eau ne tue pas (12 points par seconde), le levier est rebasculable, la planche est reprenable |
class_name Room4Battery
extends DungeonRoom

signal solved()

const HALL: String = "res://scenes/dungeon/rooms/CentralHall.tscn"
const WIRE_Y: float = 0.12
## Position de départ de la batterie : côté charge, jamais côté porte.
const BATTERY_START: Vector3 = Vector3(-9.5, 0.6, 2.0)
const PLANK_START: Vector3 = Vector3(-6.0, 0.4, 3.5)

var _door: ElectricDoor = null
var _receiver: ElectricNode = null
var _source: ElectricNode = null
var _battery: PortableBattery = null
var _plank: CarryableObject = null
var _water: ElectricHazard = null
var _switch: ElectricSwitch = null
var _charge_socket: ObjectSocket = null
var _door_socket: ObjectSocket = null
var _reset_button: ResetButton = null
var _solved: bool = false

@onready var _player: PlayerController = get_node_or_null("Player") \
	as PlayerController


func _ready() -> void:
	room_id = &"dungeon.room.battery.04"
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 3)  # GameState.Flow.DUNGEON
	var spawn_tag: StringName = consume_spawn_tag()
	_build_shell()
	_build_channel()
	_build_circuit()
	_build_objects()
	_build_reset_button()
	_setup_lighting()
	var graph_node: ElectricGraph = ElectricGraph.new()
	graph_node.name = "Graph"
	add_child(graph_node)
	set_graph(graph_node)
	# §15.11 : outil de debug des IDs, ports, voisins et états. Il se
	# RETIRE de lui-même dans un build non-debug.
	var debug_overlay: ElectricDebugOverlay = ElectricDebugOverlay.new()
	debug_overlay.name = "ElectricDebug"
	debug_overlay.graph_path = NodePath("../Graph")
	add_child(debug_overlay)
	_receiver.power_changed.connect(_on_receiver_power_changed)
	var state: Dictionary = load_room_state()
	if not state.is_empty():
		apply_room_state(state)
	# §6.1 : on réapparaît DEVANT la porte franchie, jamais au spawn.
	place_player_at_spawn(_player, spawn_tag, {
		&"room4_from_hall": Vector3(-6.0, 0.3, 7.5),
		&"room4_from_shortcut": Vector3(16.5, 0.3, -2),
	})


func _build_shell() -> void:
	# Deux berges séparées par un canal : la salle DIT son problème avant
	# qu'on ait fait trois pas.
	box("FloorWest", Vector3(-8, -0.5, 0), Vector3(10, 1, 18), COL_FLOOR)
	box("FloorEast", Vector3(8, -0.5, 0), Vector3(10, 1, 18), COL_FLOOR)
	box("Ceiling", Vector3(0, 9.5, 0), Vector3(26, 1, 18), COL_STONE)
	box("WallWest", Vector3(-13.25, 4.5, 0), Vector3(0.5, 9, 18), COL_STONE)
	box("WallNorth", Vector3(0, 4.5, -9.25), Vector3(26, 9, 0.5), COL_STONE)
	box("WallSouthWest", Vector3(-9.8, 4.5, 9.25), Vector3(6.4, 9, 0.5),
		COL_STONE)
	box("WallSouthEast", Vector3(2.6, 4.5, 9.25), Vector3(20.8, 9, 0.5),
		COL_STONE)
	box("WallSouthLintel", Vector3(-6.0, 7, 9.25), Vector3(4.4, 4, 0.5),
		COL_STONE)
	# Est : percement de 4 m pour la porte du puzzle.
	box("WallEastNorth", Vector3(13.25, 4.5, -5.5), Vector3(0.5, 9, 7),
		COL_STONE)
	box("WallEastSouth", Vector3(13.25, 4.5, 5.0), Vector3(0.5, 9, 8),
		COL_STONE)
	box("WallEastLintel", Vector3(13.25, 7, -2), Vector3(0.5, 4, 4), COL_BRONZE)
	# Couloir de sortie, scellé au fond (F.6 raccordera les salles).
	box("CorridorFloor", Vector3(16.5, -0.5, -2), Vector3(7, 1, 6), COL_FLOOR)
	box("CorridorNorth", Vector3(16.5, 3, -5.25), Vector3(7, 8, 0.5), COL_STONE)
	box("CorridorSouth", Vector3(16.5, 3, 1.25), Vector3(7, 8, 0.5), COL_STONE)
	box("CorridorCeiling", Vector3(16.5, 6.5, -2), Vector3(7, 1, 6), COL_STONE)
	box("CorridorEnd", Vector3(20.0, 2.5, -2), Vector3(0.5, 6, 6),
		Color(0.12, 0.12, 0.16))
	decor("CorridorEndSeam", Vector3(19.7, 2.5, -2), Vector3(0.1, 4.4, 0.25),
		COL_CYAN, true)
	scene_door("DoorToHall", "Rejoindre la salle centrale", HALL,
		&"hall_from_room4", Vector3(19.6, 2.5, -2), Vector3(0.4, 5.0, 4.2))

	var entry: SceneDoor = SceneDoor.new()
	entry.name = "ExitDoor"
	entry.verb = "Sortir"
	entry.target_scene = HALL
	entry.spawn_tag = &"hall_from_room4"
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
	entry.position = Vector3(-6.0, 2.5, 9.4)   # AVANT add_child (règle D.0)
	add_child(entry)


## Le canal : 6 m de large — au-delà de la portée d'un saut de §8.2 — avec
## un îlot central et deux berceaux à planche. La nappe est un nœud du
## graphe, pas un décor : sous tension, elle frappe.
func _build_channel() -> void:
	box("ChannelFloor", Vector3(0, -1.9, 0), Vector3(6, 1, 18), COL_STONE)
	box("Island", Vector3(0, -0.7, 0), Vector3(1.5, 1.4, 3.0), COL_STONE)
	var water: MeshInstance3D = decor("WaterSurface", Vector3(0, -0.75, 0),
		Vector3(6, 1.1, 18), Color(0.12, 0.28, 0.34))
	var water_material: StandardMaterial3D = water.material_override \
		as StandardMaterial3D
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.albedo_color = Color(0.12, 0.28, 0.34, 0.72)

	_water = ElectricHazard.new()
	_water.name = "WaterZone"
	_water.hazard_id = &"dungeon.node.room4_water.01"
	_water.node_kind = ElectricNode.Kind.WATER_ZONE
	_water.on_time = 1.0
	_water.off_time = 0.0     # nappe alimentée = danger CONTINU, pas rythmé
	_water.damage = 12.0
	_water.damage_interval = 1.0
	# La zone s'arrête SOUS le niveau de la planche : passer au-dessus
	# protège, patauger dedans non.
	_water.area_size = Vector3(6.0, 1.3, 18.0)
	_water.area_offset = Vector3(0, -0.65, 0)
	_water.node_port_offsets = [Vector3(-3.4, 0.22, -2.0)]
	_water.node_port_reach = 0.6
	_water.position = Vector3(0, -0.1, 0)   # AVANT add_child (règle D.0)
	add_child(_water)

	for side: int in [-1, 1]:
		var socket: ObjectSocket = ObjectSocket.new()
		socket.name = "PlankSocket%s" % ("West" if side < 0 else "East")
		socket.socket_id = StringName("dungeon.socket.room4_plank.%s"
			% ("w" if side < 0 else "e"))
		socket.accepts_tag = &"plank"
		socket.seat_offset = Vector3(1.125 * float(side), 0.38, 0)
		socket.detect_size = Vector3(2.8, 2.0, 2.0)
		socket.position = Vector3(3.0 * float(side), -0.5, 0)
		add_child(socket)


func _build_circuit() -> void:
	box("SourcePedestal", Vector3(-11.5, 0.45, -4), Vector3(1.0, 0.9, 1.0),
		COL_BRONZE)
	_source = make_node(&"dungeon.node.room4_source.01",
		ElectricNode.Kind.SOURCE, Vector3(-11.5, 1.15, -4),
		[Vector3(0, WIRE_Y - 1.15, 0.5)], 0.55)
	_source.name = "Source"
	attach_visual(_source, Vector3(0.7, 0.7, 0.7), Vector3.ZERO, true)

	var gate: ElectricNode = make_node(&"dungeon.node.room4_gate.01",
		ElectricNode.Kind.SWITCH, Vector3(-11.5, WIRE_Y, -3.0),
		[Vector3(0, 0, -0.5), Vector3(0, 0, 0.5)], 0.55)
	gate.name = "MainGate"
	gate.enabled = true
	attach_visual(gate, Vector3(0.5, 0.34, 0.5), Vector3.ZERO, false)

	var junction: ElectricNode = make_node(&"dungeon.node.room4_junction.01",
		ElectricNode.Kind.CONNECTOR, Vector3(-11.5, WIRE_Y, -2.0),
		[Vector3(0, 0, -0.5), Vector3(0, 0, 0.5), Vector3(0.6, 0, 0)], 0.55)
	junction.name = "Junction"
	attach_visual(junction, Vector3(0.5, 0.28, 0.5), Vector3.ZERO, false)

	# Branche CHARGE : jusqu'au berceau de la batterie.
	cable_run("WireChargeA", Vector3(-11.5, WIRE_Y, -1.0),
		Vector3(-11.5, WIRE_Y, 0.0), Vector3.BACK, 2)
	cable_run("WireChargeB", Vector3(-11.0, WIRE_Y, 0.5),
		Vector3(-9.0, WIRE_Y, 0.5), Vector3.RIGHT, 3)
	var charge_contact: ElectricNode = make_node(
		&"dungeon.node.room4_charge_contact.01", ElectricNode.Kind.CONNECTOR,
		Vector3(-8.0, 0.4, 0.5),
		[Vector3(0, 0, 0), Vector3(-0.5, WIRE_Y - 0.4, 0)], 0.6)
	charge_contact.name = "ChargeContact"
	attach_visual(charge_contact, Vector3(0.3, 0.2, 0.3), Vector3.ZERO, false)

	_charge_socket = ObjectSocket.new()
	_charge_socket.name = "ChargeSocket"
	_charge_socket.socket_id = &"dungeon.socket.room4_charge.01"
	_charge_socket.accepts_tag = &"battery"
	_charge_socket.seat_offset = Vector3(0, 0.4, 0)
	_charge_socket.position = Vector3(-8.0, 0, 0.5)
	add_child(_charge_socket)

	# Branche EAU : la nappe du canal.
	cable_run("WireWater", Vector3(-10.4, WIRE_Y, -2.0),
		Vector3(-4.4, WIRE_Y, -2.0), Vector3.RIGHT, 7)

	# Côté EST : rien ne vient de la source. Seule la batterie apporte le
	# courant — c'est tout le sujet de §15.8.
	var door_contact: ElectricNode = make_node(
		&"dungeon.node.room4_door_contact.01", ElectricNode.Kind.CONNECTOR,
		Vector3(7.0, 0.4, -2.0),
		[Vector3(0, 0, 0), Vector3(0.5, WIRE_Y - 0.4, 0)], 0.6)
	door_contact.name = "DoorContact"
	attach_visual(door_contact, Vector3(0.3, 0.2, 0.3), Vector3.ZERO, false)

	_door_socket = ObjectSocket.new()
	_door_socket.name = "DoorSocket"
	_door_socket.socket_id = &"dungeon.socket.room4_door.01"
	_door_socket.accepts_tag = &"battery"
	_door_socket.seat_offset = Vector3(0, 0.4, 0)
	_door_socket.position = Vector3(7.0, 0, -2.0)
	add_child(_door_socket)

	cable_run("WireEast", Vector3(8.0, WIRE_Y, -2.0),
		Vector3(10.0, WIRE_Y, -2.0), Vector3.RIGHT, 3)

	box("ReceiverPedestal", Vector3(11.0, 0.4, -2.0), Vector3(0.8, 0.8, 0.6),
		COL_BRONZE)
	_receiver = make_node(&"dungeon.node.room4_receiver.01",
		ElectricNode.Kind.RECEIVER, Vector3(11.0, 0.9, -2.0),
		[Vector3(-0.5, WIRE_Y - 0.9, 0), Vector3(0.5, WIRE_Y - 0.9, 0)], 0.6)
	_receiver.name = "Receiver"
	var ring: ReceiverRing = ReceiverRing.new()
	ring.name = "Ring"
	_receiver.add_child(ring)

	cable_run("WireDoor", Vector3(11.6, WIRE_Y, -2.0),
		Vector3(12.6, WIRE_Y, -2.0), Vector3.RIGHT, 2)

	_door = ElectricDoor.new()
	_door.name = "PuzzleDoor"
	_door.door_id = &"dungeon.door.room4_east.01"
	_door.receiver_path = NodePath("../Receiver")
	_door.open_delay = 0.7
	_door.panel_size = Vector3(0.5, 5.0, 4.0)
	_door.travel = 5.2
	_door.node_port_offsets = [Vector3(-0.15, WIRE_Y, 0)]
	_door.position = Vector3(13.25, 0, -2.0)
	add_child(_door)

	_switch = ElectricSwitch.new()
	_switch.name = "MainSwitch"
	_switch.verb = "Couper le courant"
	_switch.reversible = true    # on doit pouvoir recharger : jamais un piège
	_switch.opens_paths = [NodePath("../MainGate")]
	_switch.position = Vector3(-11.5, 0.65, -6.0)
	add_child(_switch)


func _build_objects() -> void:
	_battery = PortableBattery.new()
	_battery.name = "Battery"
	_battery.persistent_id = &"dungeon.battery.room4.01"
	_battery.battery_id = &"dungeon.node.room4_battery.01"
	_battery.collision_layer = 128
	_battery.collision_mask = 3
	_battery.bounds = Vector3(24, 20, 16)
	_battery.kill_y = -1.0    # tombée dans le canal = perdue, donc rendue
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(0.7, 0.9, 0.7)
	shape.shape = box_shape
	_battery.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "Mesh"
	var mesh_box: BoxMesh = BoxMesh.new()
	mesh_box.size = Vector3(0.7, 0.9, 0.7)
	mesh.mesh = mesh_box
	_battery.add_child(mesh)
	_battery.position = BATTERY_START   # AVANT add_child (règle D.0)
	add_child(_battery)
	_battery.set_rescue_transform(Transform3D(Basis.IDENTITY, BATTERY_START))
	register_block(_battery)

	# La planche : bois, donc ISOLANTE (§14.4). Elle ne conduit rien ; elle
	# porte. C'est la deuxième solution de §15.8.
	_plank = CarryableObject.new()
	_plank.name = "Plank"
	_plank.persistent_id = &"dungeon.plank.room4.01"
	_plank.carry_tag = &"plank"
	_plank.collision_layer = 128
	_plank.collision_mask = 3
	_plank.bounds = Vector3(24, 20, 16)
	_plank.kill_y = -1.0
	var plank_shape: CollisionShape3D = CollisionShape3D.new()
	var plank_box: BoxShape3D = BoxShape3D.new()
	plank_box.size = Vector3(2.6, 0.24, 1.2)
	plank_shape.shape = plank_box
	_plank.add_child(plank_shape)
	var plank_mesh: MeshInstance3D = MeshInstance3D.new()
	plank_mesh.name = "Mesh"
	var plank_mesh_box: BoxMesh = BoxMesh.new()
	plank_mesh_box.size = Vector3(2.6, 0.24, 1.2)
	plank_mesh.mesh = plank_mesh_box
	var plank_material: StandardMaterial3D = StandardMaterial3D.new()
	plank_material.albedo_color = Color(0.41, 0.25, 0.14)
	plank_mesh.material_override = plank_material
	_plank.add_child(plank_mesh)
	_plank.add_to_group("insulated")
	_plank.position = PLANK_START   # AVANT add_child (règle D.0)
	add_child(_plank)
	_plank.set_rescue_transform(Transform3D(Basis.IDENTITY, PLANK_START))
	register_block(_plank)


func _build_reset_button() -> void:
	_reset_button = ResetButton.new()
	_reset_button.name = "ResetButton"
	_reset_button.verb = "Rappeler la batterie"
	_reset_button.position = Vector3(-11.0, 0.55, 3.0)
	add_child(_reset_button)
	decor("ResetMarker", Vector3(-11.0, 0.03, 3.0), Vector3(1.6, 0.04, 1.6),
		COL_IVORY)


## §15.8 : « batterie hors limites réapparaît ». Le reset la ramène AUSSI,
## et toujours du côté de la charge — jamais derrière une porte.
func reset_room() -> void:
	if _battery != null and _battery.is_seated():
		_battery.release_from_seat()
	if _plank != null and _plank.is_seated():
		_plank.release_from_seat()
	super()


func _on_receiver_power_changed(powered: bool, _power: float) -> void:
	if not powered or _solved:
		return
	_solved = true
	save_room_state()
	solved.emit()


func room_state() -> Dictionary:
	var state: Dictionary = super()
	state["solved"] = _solved
	state["door_open"] = _door != null and _door.is_latched()
	state["battery_charge"] = _battery.charge_seconds() if _battery != null \
		else 0.0
	return state


func apply_room_state(state: Dictionary) -> void:
	super(state)
	_solved = bool(state.get("solved", false))
	if _battery != null:
		_battery.set_charge_seconds(float(state.get("battery_charge", 0.0)))
	if bool(state.get("door_open", false)) and _door != null:
		_door.force_open()


func _setup_lighting() -> void:
	for i: int in range(4):
		var warm: OmniLight3D = OmniLight3D.new()
		warm.name = "BankGlow%d" % i
		warm.light_color = Color(1.0, 0.74, 0.42)
		warm.light_energy = 2.4
		warm.omni_range = 16.0
		warm.position = Vector3(-10.5 if i % 2 == 0 else 10.5, 3.6,
			6.0 - 12.0 * float(i / 2))
		add_child(warm)
		box("Brazier%d" % i, warm.position - Vector3(0, 2.9, 0),
			Vector3(0.7, 1.4, 0.7), COL_BRONZE)
		decor("BrazierCoal%d" % i, warm.position - Vector3(0, 2.1, 0),
			Vector3(0.5, 0.22, 0.5), Color(0.98, 0.58, 0.22), true)
	var water_light: OmniLight3D = OmniLight3D.new()
	water_light.name = "ChannelGlow"
	water_light.light_color = Color(0.5, 0.9, 0.95)
	water_light.light_energy = 1.6
	water_light.omni_range = 14.0
	water_light.position = Vector3(0, 2.0, 0)
	add_child(water_light)
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


## État que le joueur atteint : batterie chargée, courant coupé, batterie
## posée dans le socket de la porte. Sert aux captures ; aucune règle.
func capture_state_solved() -> void:
	if _battery == null:
		return
	_battery.set_charge_seconds(_battery.capacity)
	if _switch != null:
		_switch.interact(null)
	_battery.seat_at(Transform3D(Basis.IDENTITY,
		_door_socket.global_position + _door_socket.seat_offset))
	if graph() != null:
		graph().mark_dirty()
		graph().recompute()


func battery() -> PortableBattery:
	return _battery


func plank() -> CarryableObject:
	return _plank


func water() -> ElectricHazard:
	return _water


func main_switch() -> ElectricSwitch:
	return _switch


func charge_socket() -> ObjectSocket:
	return _charge_socket


func door_socket() -> ObjectSocket:
	return _door_socket


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
