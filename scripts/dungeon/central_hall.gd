## Citadelle de l'Œil-Tempête — SALLE CENTRALE (§15.9).
##
## | §15.9 | ici |
## |---|---|
## | trois récepteurs indépendants alimentent la porte du boss SIMULTANÉMENT | trois branches ÉLECTRIQUEMENT séparées ; la porte a trois conditions et n'ouvre qu'à la troisième (`ElectricDoor.required_paths`) |
## | trois anneaux | un `ReceiverRing` par récepteur, sur trois piliers distincts |
## | progression mécanique | la porte du boss monte réellement, avec son délai de §15.5 |
## | carte murale et lignes continues | un panneau à trois lignes, chacune allumée par SON récepteur — pas un compteur abstrait |
## | l'ouverture est une vraie conséquence du graphe | chaque branche est alimentée par un `SourceNode` dont `enabled` vaut « cette salle est résolue » ; l'état vient de la sauvegarde, jamais d'un booléen local |
##
## **Quelle salle fournit quel récepteur** (§15.9 l'exige explicitement) :
##
## | Récepteur | Circuit | Salle |
## |---|---|---|
## | Ouest | `hall.feed.west` | salle 2 — circuit vertical (§15.6) |
## | Nord | `hall.feed.north` | salle 3 — relais rotatifs (§15.7) |
## | Est | `hall.feed.east` | salle 4 — batterie transportable (§15.8) |
##
## La salle 1 (initiation, §15.5) n'alimente aucun récepteur : elle est sur
## le CHEMIN, entre le vestibule et cette salle. C'est le cas prévu par
## §15.9 (« si le quatrième puzzle est séquentiel »), documenté ici.
##
## Architecture à deux niveaux : les portes des salles et les trois piliers
## sont au sol ; la porte du boss est sur la galerie nord, six mètres plus
## haut, atteinte par deux rampes. On VOIT d'en bas ce qu'on va ouvrir.
class_name CentralHall
extends DungeonRoom

signal circuits_changed(count: int)

const ROOM1: String = "res://scenes/dungeon/rooms/Room1Initiation.tscn"
const ROOM2: String = "res://scenes/dungeon/rooms/Room2Vertical.tscn"
const ROOM3: String = "res://scenes/dungeon/rooms/Room3Relays.tscn"
const ROOM4: String = "res://scenes/dungeon/rooms/Room4Battery.tscn"
const ANTECHAMBER: String = "res://scenes/dungeon/rooms/Antechamber.tscn"
const WIRE_Y: float = 0.12
const GALLERY_Y: float = 6.0

## Quel circuit vient de quelle salle (§15.9 : à documenter précisément).
const CIRCUITS: Array[Dictionary] = [
	{"key": "west", "room": "dungeon.room.vertical.02", "x": -9.0},
	{"key": "north", "room": "dungeon.room.relays.03", "x": 0.0},
	{"key": "east", "room": "dungeon.room.battery.04", "x": 9.0},
]

var _boss_door: ElectricDoor = null
var _receivers: Array[ElectricNode] = []
var _feeds: Array[ElectricNode] = []
var _map_bars: Array[MeshInstance3D] = []

@onready var _player: PlayerController = get_node_or_null("Player") \
	as PlayerController


func _ready() -> void:
	room_id = &"dungeon.room.central.05"
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 3)  # GameState.Flow.DUNGEON
	var spawn_tag: StringName = consume_spawn_tag()
	_build_shell()
	_build_circuits()
	_build_map()
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
	_apply_solved_rooms()
	# §6.1 : chaque seuil a son point d'arrivée, devant la porte franchie.
	place_player_at_spawn(_player, spawn_tag, {
		&"hall_from_room1": Vector3(0, 0.3, 12.5),
		&"hall_from_room2": Vector3(-12.5, 0.3, -2.0),
		&"hall_from_room3": Vector3(0, 0.3, -12.5),
		&"hall_from_room4": Vector3(12.5, 0.3, -2.0),
		&"hall_from_antechamber": Vector3(0, GALLERY_Y + 0.3, -12.0),
	})


## Chaque circuit permanent est alimenté par la RÉSOLUTION de sa salle,
## lue dans la sauvegarde commune (§19.1). Aucun compteur local : si le
## fichier dit que la salle 3 est résolue, le circuit nord débite.
func _apply_solved_rooms() -> void:
	var count: int = 0
	for i: int in range(CIRCUITS.size()):
		var solved: bool = _is_room_solved(String(CIRCUITS[i]["room"]))
		_feeds[i].enabled = solved
		if solved:
			count += 1
	if graph() != null:
		graph().mark_dirty()
		graph().recompute()
	circuits_changed.emit(count)


func _is_room_solved(other_room_id: String) -> bool:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null or not bool(save_system.call("has_save", SAVE_SLOT)):
		return false
	var data: Dictionary = save_system.call("load_slot", SAVE_SLOT) as Dictionary
	var rooms: Dictionary = data.get("dungeon", {}) as Dictionary
	var state: Dictionary = rooms.get(other_room_id, {}) as Dictionary
	# Une salle est « résolue » quand elle l'a écrit elle-même — soit par
	# son drapeau, soit par sa porte ouverte.
	return bool(state.get("solved", false)) \
		or bool(state.get("rerouted", false)) \
		or bool(state.get("door_open", false))


func _build_shell() -> void:
	box("Floor", Vector3(0, -0.5, 0), Vector3(30, 1, 30), COL_FLOOR)
	box("Ceiling", Vector3(0, 14.5, 0), Vector3(30, 1, 30), COL_STONE)
	box("WallWestSouth", Vector3(-15.25, 7, 6.5), Vector3(0.5, 14, 17), COL_STONE)
	box("WallWestNorth", Vector3(-15.25, 7, -9.5), Vector3(0.5, 14, 11), COL_STONE)
	box("WallWestLintel", Vector3(-15.25, 9.5, -2), Vector3(0.5, 9, 5), COL_BRONZE)
	box("WallEastSouth", Vector3(15.25, 7, 6.5), Vector3(0.5, 14, 17), COL_STONE)
	box("WallEastNorth", Vector3(15.25, 7, -9.5), Vector3(0.5, 14, 11), COL_STONE)
	box("WallEastLintel", Vector3(15.25, 9.5, -2), Vector3(0.5, 9, 5), COL_BRONZE)
	box("WallSouthWest", Vector3(-8.6, 7, 15.25), Vector3(12.8, 14, 0.5),
		COL_STONE)
	box("WallSouthEast", Vector3(8.6, 7, 15.25), Vector3(12.8, 14, 0.5),
		COL_STONE)
	box("WallSouthLintel", Vector3(0, 9.5, 15.25), Vector3(4.4, 9, 0.5),
		COL_STONE)
	# Nord : au sol, le seuil de la salle 3 ; en haut, la porte du boss.
	box("WallNorthWest", Vector3(-9.5, 7, -15.25), Vector3(11, 14, 0.5),
		COL_STONE)
	box("WallNorthEast", Vector3(9.5, 7, -15.25), Vector3(11, 14, 0.5),
		COL_STONE)
	box("WallNorthMid", Vector3(0, 3, -15.25), Vector3(8, 6, 0.5), COL_STONE)
	box("WallNorthTop", Vector3(0, 12.75, -15.25), Vector3(8, 3.5, 0.5),
		COL_BRONZE)

	# Galerie nord : la porte du boss se VOIT d'en bas, six mètres plus haut.
	box("Gallery", Vector3(0, GALLERY_Y - 0.25, -12.0),
		Vector3(30, 0.5, 6.0), COL_FLOOR)
	box("GalleryRail", Vector3(0, GALLERY_Y + 0.5, -9.2),
		Vector3(30, 1.0, 0.4), COL_BRONZE)
	# Deux rampes INCLINÉES, une de chaque côté. 6 m de montée pour 8 m de
	# course = 36,9°, sous les 46° praticables de §8.2 : on monte en
	# MARCHANT. Un escalier à marches d'un mètre aurait forcé l'escalade.
	# Le PIED de la rampe est enterré dans la dalle : mesuré, une rampe
	# posée sur le sol présente une tranche de 0,75 m — un mur, pas une
	# pente (§8.2 : la marche franchissable s'arrête à 0,38 m). Ici la
	# surface émerge du sol EXACTEMENT à z = -1, sans ressaut.
	for side: int in [-1, 1]:
		var ramp: StaticBody3D = box("Ramp%s" % ("W" if side < 0 else "E"),
			Vector3(12.5 * float(side), 2.385, -4.68),
			Vector3(4.0, 0.6, 11.25), COL_STONE)
		ramp.rotation.x = deg_to_rad(36.87)

	scene_door("DoorRoom1", "Retourner à l'initiation", ROOM1,
		&"room1_from_hall", Vector3(0, 2.5, 15.4), Vector3(4.2, 5.0, 0.4))
	scene_door("DoorRoom2", "Entrer dans le puits", ROOM2,
		&"room2_from_hall", Vector3(-15.4, 2.5, -2), Vector3(0.4, 5.0, 4.2))
	scene_door("DoorRoom3", "Entrer dans la salle des relais", ROOM3,
		&"room3_from_hall", Vector3(0, 2.5, -15.4), Vector3(4.2, 5.0, 0.4))
	scene_door("DoorRoom4", "Entrer dans la salle du canal", ROOM4,
		&"room4_from_hall", Vector3(15.4, 2.5, -2), Vector3(0.4, 5.0, 4.2))
	# Au-delà de la porte du boss : l'antichambre (§15.10).
	scene_door("DoorAntechamber", "Franchir le seuil", ANTECHAMBER,
		&"antechamber_from_hall", Vector3(0, GALLERY_Y + 2.5, -14.9),
		Vector3(4.2, 5.0, 0.4))


## Trois branches SÉPARÉES. Aucune ne touche les autres : sans cela, le
## courant du premier circuit résolu remonterait dans les deux suivants et
## les trois anneaux se fermeraient d'un coup.
func _build_circuits() -> void:
	for i: int in range(CIRCUITS.size()):
		var key: String = String(CIRCUITS[i]["key"])
		var x: float = float(CIRCUITS[i]["x"])
		var suffix: String = key.capitalize()
		box("FeedPedestal%s" % suffix, Vector3(x, 0.45, 9.0),
			Vector3(1.0, 0.9, 1.0), COL_BRONZE)
		var feed: ElectricNode = make_node(
			StringName("dungeon.node.hall_feed.%s" % key),
			ElectricNode.Kind.SOURCE, Vector3(x, 1.15, 9.0),
			[Vector3(0, WIRE_Y - 1.15, -0.5)], 0.55)
		feed.name = "Feed%s" % suffix
		feed.enabled = false
		attach_visual(feed, Vector3(0.7, 0.7, 0.7), Vector3.ZERO, true)
		_feeds.append(feed)

		cable_run("Wire%s" % suffix, Vector3(x, WIRE_Y, 8.0),
			Vector3(x, WIRE_Y, 3.0), Vector3.FORWARD, 6)

		box("Pillar%s" % suffix, Vector3(x, 1.0, 2.0), Vector3(1.2, 2.0, 1.2),
			COL_STONE)
		var receiver: ElectricNode = make_node(
			StringName("dungeon.node.hall_receiver.%s" % key),
			ElectricNode.Kind.RECEIVER, Vector3(x, 2.6, 2.0),
			[Vector3(0, WIRE_Y - 2.6, 0.5)], 0.6)
		receiver.name = "Receiver%s" % suffix
		var ring: ReceiverRing = ReceiverRing.new()
		ring.name = "Ring"
		ring.radius = 0.7
		receiver.add_child(ring)
		receiver.power_changed.connect(_on_receiver_changed)
		_receivers.append(receiver)

		# La « ligne continue » de §15.9 : un conduit qui part du pilier et
		# monte vers la porte du boss. Il n'est PAS dans le graphe — c'est
		# la présentation du récepteur, branchée sur lui.
		var conduit: MeshInstance3D = MeshInstance3D.new()
		conduit.name = "Conduit%s" % suffix
		var conduit_box: BoxMesh = BoxMesh.new()
		conduit_box.size = Vector3(0.2, 0.2, 13.0)
		conduit.mesh = conduit_box
		conduit.position = Vector3(x, 3.4, -4.5)
		add_child(conduit)
		var conduit_visual: ElectricVisual = ElectricVisual.new()
		conduit_visual.name = "ConduitVisual%s" % suffix
		conduit_visual.node_path = receiver.get_path()
		conduit_visual.mesh_path = conduit.get_path()
		add_child(conduit_visual)

	_boss_door = ElectricDoor.new()
	_boss_door.name = "BossDoor"
	_boss_door.door_id = &"dungeon.door.hall_boss.01"
	_boss_door.required_paths = [
		NodePath("../ReceiverWest"), NodePath("../ReceiverNorth"),
		NodePath("../ReceiverEast"),
	]
	_boss_door.open_delay = 1.2
	_boss_door.open_time = 3.0    # une porte monumentale prend son temps
	_boss_door.panel_size = Vector3(8.0, 6.5, 0.6)
	_boss_door.travel = 6.6
	_boss_door.position = Vector3(0, GALLERY_Y, -15.25)
	add_child(_boss_door)


## Carte murale (§15.9) : trois lignes, une par circuit, allumées par LEUR
## récepteur. Ce n'est pas un compteur : chaque ligne dit quelle salle.
func _build_map() -> void:
	box("MapPanel", Vector3(-14.6, 4.0, 6.0), Vector3(0.4, 4.0, 6.0),
		Color(0.18, 0.17, 0.20))
	for i: int in range(CIRCUITS.size()):
		var bar: MeshInstance3D = decor("MapLine%d" % i,
			Vector3(-14.35, 5.0 - 1.2 * float(i), 6.0),
			Vector3(0.1, 0.3, 4.4), Color(0.26, 0.24, 0.28))
		_map_bars.append(bar)
		var visual: ElectricVisual = ElectricVisual.new()
		visual.name = "MapVisual%d" % i
		visual.node_path = _receivers[i].get_path()
		visual.mesh_path = bar.get_path()
		add_child(visual)


func _on_receiver_changed(_powered: bool, _power: float) -> void:
	circuits_changed.emit(powered_circuits())


func powered_circuits() -> int:
	var count: int = 0
	for receiver: ElectricNode in _receivers:
		if receiver.is_powered():
			count += 1
	return count


func _setup_lighting() -> void:
	for i: int in range(6):
		var warm: OmniLight3D = OmniLight3D.new()
		warm.name = "HallGlow%d" % i
		warm.light_color = Color(1.0, 0.74, 0.42)
		warm.light_energy = 2.6
		warm.omni_range = 18.0
		warm.position = Vector3(-13.0 if i % 2 == 0 else 13.0, 4.0,
			11.0 - 9.0 * float(i / 2))
		add_child(warm)
		box("Brazier%d" % i, warm.position - Vector3(0, 3.3, 0),
			Vector3(0.7, 1.4, 0.7), COL_BRONZE)
		decor("BrazierCoal%d" % i, warm.position - Vector3(0, 2.5, 0),
			Vector3(0.5, 0.22, 0.5), Color(0.98, 0.58, 0.22), true)
	var boss_light: OmniLight3D = OmniLight3D.new()
	boss_light.name = "BossDoorGlow"
	boss_light.light_color = Color(0.5, 0.9, 0.95)
	boss_light.light_energy = 2.4
	boss_light.omni_range = 16.0
	boss_light.position = Vector3(0, GALLERY_Y + 4.0, -12.5)
	add_child(boss_light)
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.04, 0.05, 0.07)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.26, 0.29, 0.34)
	environment.ambient_light_energy = 1.0
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "RoomEnvironment"
	world_environment.environment = environment
	add_child(world_environment)


## Force les trois circuits — capture, et test du cas « tout est résolu ».
func capture_state_all_circuits() -> void:
	for feed: ElectricNode in _feeds:
		feed.enabled = true
	if graph() != null:
		graph().mark_dirty()
		graph().recompute()


func boss_door() -> ElectricDoor:
	return _boss_door


func receivers() -> Array[ElectricNode]:
	return _receivers


func feeds() -> Array[ElectricNode]:
	return _feeds


func player() -> PlayerController:
	return _player
