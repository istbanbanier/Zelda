## Citadelle de l'Œil-Tempête — SALLE 2, circuit vertical (§15.6).
##
## | §15.6 | ici |
## |---|---|
## | ascenseur non alimenté | `ElevatorPlatform` immobile : son récepteur est derrière l'aiguillage, coupé au départ |
## | puits latéral escaladable | trois blocs de pierre décalés le long du mur ouest ; le mur lui-même est `unclimbable`, la voie passe par eux |
## | électrodes intermittentes au rythme observable | trois `ElectricHazard`, 1,1 s de décharge pour 1,7 s de calme, phases décalées — on regarde d'en bas, on compte, on monte |
## | interrupteur supérieur redirige le courant | `ElectricSwitch` sur la mezzanine : il FERME la branche ascenseur et OUVRE la branche danger, dans le même geste |
## | corniches de repos | le sommet de chaque bloc EST la corniche : on s'y hisse, l'endurance remonte |
## | une jauge pleine suffit si timing correct | segments de 5,5 m ≈ 50 points sur 100 (§9.1 : 18/s à 2 m/s) |
## | chute renvoie à un palier proche | les blocs étant décalés, une chute retombe sur le toit du bloc précédent — 3 à 5 m, sous le seuil de dégâts de §8.2 |
## | ascenseur ne peut écraser ni coincer | deux zones de garde ; un corps dans le sens de la marche arrête la plateforme |
## | sauvegarde d'état cohérente | l'aiguillage vit dans le graphe (§19.1), pas dans un booléen de salle |
##
## Anti-softlock (§15.11) : l'aiguillage est IRRÉVERSIBLE. Le rendre
## rebasculable permettrait de réarmer les électrodes depuis le haut,
## puis de redescendre à travers — hostile sans être intéressant. Une fois
## le courant redirigé, la voie reste sûre dans les deux sens.
class_name Room2Vertical
extends DungeonRoom

## L'aiguillage vient d'être basculé : ascenseur vivant, électrodes mortes.
signal rerouted()

const ROOM1: String = "res://scenes/dungeon/rooms/Room1Initiation.tscn"
const WIRE_Y: float = 0.12
## Ligne d'escalade : le mur ouest, trois blocs décalés en Z.
const CLIMB_X: float = -6.2
const MEZZANINE_Y: float = 16.5

var _switch: ElectricSwitch = null
var _elevator: ElevatorPlatform = null
var _door: ElectricDoor = null
var _receiver: ElectricNode = null
var _source: ElectricNode = null
var _hazards: Array[ElectricHazard] = []
var _reset_button: ResetButton = null
var _rerouted: bool = false

@onready var _player: PlayerController = get_node_or_null("Player") \
	as PlayerController


func _ready() -> void:
	room_id = &"dungeon.room.vertical.02"
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 3)  # GameState.Flow.DUNGEON
		game_state.call("consume_pending_spawn")
	_build_shell()
	_build_climb()
	_build_circuit()
	_build_elevator()
	_build_switch()
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


## Puits de 22 m : sol, murs, mezzanine nord au sommet, seuil sud en bas,
## porte au nord en haut, couloir de sortie honnêtement scellé (F.6
## raccordera les salles entre elles).
func _build_shell() -> void:
	# Le puits est prolongé de 6 m vers le sud : sans ce recul, la caméra
	# d'épaule bute dans le mur d'entrée et le joueur remplit l'image —
	# mesuré sur la première capture, la salle y était illisible.
	box("Floor", Vector3(0, -0.5, 3), Vector3(14, 1, 20), COL_FLOOR)
	box("Ceiling", Vector3(0, 22.5, 3), Vector3(14, 1, 20), COL_STONE)
	# Le mur ouest est INACCROCHABLE : sans cela, on grimperait à côté des
	# électrodes et l'énigme n'existerait pas (§9.2, groupe de refus).
	var west: StaticBody3D = box("WallWest", Vector3(-7.25, 11, 3),
		Vector3(0.5, 22, 20), COL_STONE)
	west.add_to_group("unclimbable")
	var east: StaticBody3D = box("WallEast", Vector3(7.25, 11, 3),
		Vector3(0.5, 22, 20), COL_STONE)
	east.add_to_group("unclimbable")
	# Nord : percement de 4 m au niveau de la mezzanine.
	box("WallNorthWest", Vector3(-3.5, 11, -7.25), Vector3(7, 22, 0.5), COL_STONE)
	box("WallNorthEast", Vector3(5.5, 11, -7.25), Vector3(3, 22, 0.5), COL_STONE)
	box("WallNorthUnder", Vector3(2, 8.25, -7.25), Vector3(4, 16.5, 0.5), COL_STONE)
	box("WallNorthLintel", Vector3(2, 21.75, -7.25), Vector3(4, 1.5, 0.5), COL_BRONZE)
	# Sud : seuil d'entrée en bas.
	box("WallSouthWest", Vector3(-4.8, 11, 13.25), Vector3(4.4, 22, 0.5), COL_STONE)
	box("WallSouthEast", Vector3(4.8, 11, 13.25), Vector3(4.4, 22, 0.5), COL_STONE)
	box("WallSouthLintel", Vector3(0, 13.5, 13.25), Vector3(5.2, 17, 0.5), COL_STONE)
	# Mezzanine : le palier d'arrivée, à l'est de la voie d'escalade.
	# La mezzanine s'arrête à 0,6 m du mur est : cette gaine laisse passer
	# la colonne montante de la branche ascenseur, qui doit se VOIR (§7.8 :
	# « trajet du courant visible à distance »), pas se noyer dans la dalle.
	box("Mezzanine", Vector3(0.5, MEZZANINE_Y - 0.25, -4.0),
		Vector3(11.8, 0.5, 6.0), COL_FLOOR)
	# Couloir de sortie, scellé au fond (la suite du donjon est F.4-F.6).
	box("CorridorFloor", Vector3(2, MEZZANINE_Y - 0.25, -10.5),
		Vector3(6, 0.5, 7), COL_FLOOR)
	box("CorridorWest", Vector3(-1.25, MEZZANINE_Y + 3, -10.5),
		Vector3(0.5, 6, 7), COL_STONE)
	box("CorridorEast", Vector3(5.25, MEZZANINE_Y + 3, -10.5),
		Vector3(0.5, 6, 7), COL_STONE)
	box("CorridorCeiling", Vector3(2, MEZZANINE_Y + 6.25, -10.5),
		Vector3(6, 0.5, 7), COL_STONE)
	box("CorridorSeal", Vector3(2, MEZZANINE_Y + 2.5, -13.75),
		Vector3(6, 5.5, 0.5), Color(0.1, 0.1, 0.14))
	decor("CorridorSealSeam", Vector3(2, MEZZANINE_Y + 2.5, -13.45),
		Vector3(0.25, 4.0, 0.1), COL_CYAN, true)

	var entry: SceneDoor = SceneDoor.new()
	entry.name = "ExitDoor"
	entry.verb = "Sortir"
	entry.target_scene = ROOM1
	entry.spawn_tag = &"room2_door"
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
	entry.position = Vector3(0, 2.5, 13.4)   # AVANT add_child (règle D.0)
	add_child(entry)


## L'escalier de pierre : trois blocs décalés, chacun plus haut que le
## précédent. On grimpe la face SUD de chacun et on se hisse sur son toit,
## qui est la corniche de repos du segment suivant (§15.6).
func _build_climb() -> void:
	box("ClimbBlockA", Vector3(CLIMB_X, 2.75, 1.5), Vector3(1.6, 5.5, 3.0),
		COL_STONE)
	box("ClimbBlockB", Vector3(CLIMB_X, 5.5, -1.5), Vector3(1.6, 11.0, 3.0),
		COL_STONE)
	box("ClimbBlockC", Vector3(CLIMB_X, 8.1, -4.5), Vector3(1.6, 16.2, 3.0),
		COL_STONE)
	# Marques de prise : le regard doit trouver la voie sans texte.
	for i: int in range(3):
		var z: float = 3.0 - 3.0 * float(i)
		var top: float = 5.5 + 5.5 * float(i)
		if i == 2:
			top = 16.2
		for step: int in range(3):
			decor("Grip%d_%d" % [i, step],
				Vector3(CLIMB_X, top - 4.2 + 1.4 * float(step), z + 0.05),
				Vector3(0.8, 0.12, 0.1), COL_COPPER)


## Le circuit de §15.6 : une source, un aiguillage, deux branches. Au
## départ le courant part vers les électrodes ; le levier du haut l'envoie
## vers l'ascenseur et la porte.
func _build_circuit() -> void:
	box("SourcePedestal", Vector3(6.4, 0.45, 5.5), Vector3(1.0, 0.9, 1.0),
		COL_BRONZE)
	_source = make_node(&"dungeon.node.room2_source.01",
		ElectricNode.Kind.SOURCE, Vector3(6.4, 1.15, 5.5),
		[Vector3(0, WIRE_Y - 1.15, -0.5)], 0.55)
	_source.name = "Source"
	attach_visual(_source, Vector3(0.7, 0.7, 0.7), Vector3.ZERO, true)

	# Tronc commun : de la source au carrefour, le long du mur sud.
	cable_run("WireTrunk", Vector3(6.4, WIRE_Y, 5.0), Vector3(6.4, WIRE_Y, 4.0),
		Vector3.FORWARD, 2)

	# Carrefour : trois ports, un par direction. Les deux branches en
	# partent par des ports ÉLOIGNÉS l'un de l'autre — sans quoi elles se
	# toucheraient directement et les aiguillages ne serviraient à rien
	# (mesuré : tout le circuit alimenté d'un bloc, portes comprises).
	var junction: ElectricNode = make_node(
		&"dungeon.node.room2_junction.01", ElectricNode.Kind.CONNECTOR,
		Vector3(6.4, WIRE_Y, 3.15),
		[Vector3(0, 0, 0.35), Vector3(-0.9, 0, 0), Vector3(0, 0, -0.9)], 0.55)
	junction.name = "Junction"
	attach_visual(junction, Vector3(0.5, 0.28, 0.5), Vector3.ZERO, false)

	# Aiguillage : deux nœuds SWITCH, un par branche, commandés par un seul
	# levier — c'est ce qui fait une REDIRECTION et non un allumage.
	var hazard_gate: ElectricNode = make_node(
		&"dungeon.node.room2_gate_hazard.01", ElectricNode.Kind.SWITCH,
		Vector3(5.0, WIRE_Y, 3.15),
		[Vector3(0.5, 0, 0), Vector3(-0.5, 0, 0)], 0.55)
	hazard_gate.name = "HazardGate"
	hazard_gate.enabled = true
	attach_visual(hazard_gate, Vector3(0.5, 0.34, 0.5), Vector3.ZERO, false)
	var elevator_gate: ElectricNode = make_node(
		&"dungeon.node.room2_gate_elevator.01", ElectricNode.Kind.SWITCH,
		Vector3(6.4, WIRE_Y, 1.6),
		[Vector3(0, 0, 0.65), Vector3(0, 0, -0.65)], 0.55)
	elevator_gate.name = "ElevatorGate"
	elevator_gate.enabled = false
	attach_visual(elevator_gate, Vector3(0.5, 0.34, 0.5), Vector3.ZERO, false)

	_build_hazard_branch()
	_build_elevator_branch()


## Branche DANGER : du carrefour au pied du mur ouest, puis en zigzag le
## long des trois blocs, une électrode par segment.
func _build_hazard_branch() -> void:
	cable_run("WireHazardFloor", Vector3(4.0, WIRE_Y, 3.15),
		Vector3(-5.0, WIRE_Y, 3.15), Vector3.LEFT, 10)
	# Les colonnes montent le long de la face EST des blocs : le câble doit
	# se voir, pas être noyé dans la pierre.
	cable_run("WireHazardA", Vector3(-5.2, 0.6, 3.15),
		Vector3(-5.2, 3.6, 3.15), Vector3.UP, 4)
	cable_run("WireHazardLinkA", Vector3(-5.2, 4.1, 2.65),
		Vector3(-5.2, 4.1, 0.65), Vector3.FORWARD, 3)
	cable_run("WireHazardB", Vector3(-5.2, 4.6, 0.15),
		Vector3(-5.2, 9.6, 0.15), Vector3.UP, 6)
	cable_run("WireHazardLinkB", Vector3(-5.2, 10.1, -0.35),
		Vector3(-5.2, 10.1, -2.35), Vector3.FORWARD, 3)
	cable_run("WireHazardC", Vector3(-5.2, 10.6, -2.85),
		Vector3(-5.2, 14.6, -2.85), Vector3.UP, 5)

	# Trois électrodes, une par segment, phases décalées. Chacune garde le
	# bloc dont elle couvre la face : sous tension, ce bloc n'est plus
	# accrochable (§9.2, groupe `electrified`).
	var placements: Array[Array] = [
		["A", Vector3(CLIMB_X, 3.0, 3.15)],
		["B", Vector3(CLIMB_X, 8.2, 0.15)],
		["C", Vector3(CLIMB_X, 13.6, -2.85)],
	]
	for i: int in range(placements.size()):
		var entry: Array = placements[i]
		var hazard: ElectricHazard = ElectricHazard.new()
		hazard.name = "Electrode%s" % String(entry[0])
		hazard.hazard_id = StringName("dungeon.node.room2_electrode.%s"
			% String(entry[0]).to_lower())
		hazard.phase_offset = 0.9 * float(i)
		hazard.area_size = Vector3(2.2, 2.0, 1.4)
		hazard.area_offset = Vector3(0, 0, 0.75)
		hazard.node_port_offsets = [Vector3(1.0, 0, 0)]
		hazard.node_port_reach = 0.6
		hazard.guarded_body_path = NodePath("../ClimbBlock%s" % String(entry[0]))
		hazard.position = entry[1] as Vector3   # AVANT add_child (règle D.0)
		add_child(hazard)
		_hazards.append(hazard)


## Branche ASCENSEUR : du carrefour au mur est, puis jusqu'au récepteur de
## la mezzanine et à la porte. Le trajet du courant se voit de loin (§7.8).
func _build_elevator_branch() -> void:
	cable_run("WireLiftFloor", Vector3(6.4, WIRE_Y, 0.45),
		Vector3(6.4, WIRE_Y, -2.55), Vector3.FORWARD, 4)
	cable_run("WireLiftRise", Vector3(6.7, 0.6, -3.05),
		Vector3(6.7, 16.1, -3.05), Vector3.UP, 17)
	cable_run("WireLiftTop", Vector3(6.7, 16.6, -3.55),
		Vector3(6.7, 16.6, -5.55), Vector3.FORWARD, 3)

	box("ReceiverPedestal", Vector3(6.0, MEZZANINE_Y + 0.6, -5.8),
		Vector3(0.8, 1.2, 0.6), COL_BRONZE)
	_receiver = make_node(&"dungeon.node.room2_receiver.01",
		ElectricNode.Kind.RECEIVER, Vector3(6.0, MEZZANINE_Y + 1.4, -5.8),
		[Vector3(0.7, 16.6 - (MEZZANINE_Y + 1.4), 0.0),
		Vector3(-0.5, 16.6 - (MEZZANINE_Y + 1.4), 0.0)], 0.6)
	_receiver.name = "Receiver"
	var ring: ReceiverRing = ReceiverRing.new()
	ring.name = "Ring"
	_receiver.add_child(ring)

	cable_run("WireLiftDoor", Vector3(5.0, 16.6, -5.8),
		Vector3(4.0, 16.6, -5.8), Vector3.LEFT, 2)

	_door = ElectricDoor.new()
	_door.name = "PuzzleDoor"
	_door.door_id = &"dungeon.door.room2_north.01"
	_door.receiver_path = NodePath("../Receiver")
	_door.open_delay = 0.8      # §15.5/§15.6 : fenêtre 0,6-1,2 s
	_door.panel_size = Vector3(4.0, 5.0, 0.5)
	_door.travel = 5.2
	_door.node_port_offsets = [Vector3(1.5, 16.6 - MEZZANINE_Y, 1.45)]
	_door.position = Vector3(2.0, MEZZANINE_Y, -7.25)
	add_child(_door)


func _build_elevator() -> void:
	_elevator = ElevatorPlatform.new()
	_elevator.name = "Elevator"
	_elevator.platform_id = &"dungeon.lift.room2.01"
	_elevator.receiver_path = NodePath("../Receiver")
	_elevator.bottom_y = 0.7
	_elevator.top_y = MEZZANINE_Y - 0.2
	_elevator.position = Vector3(1.0, 0.7, 1.0)   # AVANT add_child
	add_child(_elevator)
	# Repère au sol : la cage se lit même quand la plateforme est en haut.
	for side: int in [-1, 1]:
		decor("LiftMark%d" % side, Vector3(1.0 + 1.9 * float(side), 0.02, 1.0),
			Vector3(0.2, 0.04, 3.6), COL_COPPER)


func _build_switch() -> void:
	_switch = ElectricSwitch.new()
	_switch.name = "RerouteSwitch"
	_switch.verb = "Rediriger le courant"
	_switch.reversible = false   # anti-softlock, voir l'en-tête
	_switch.closes_paths = [NodePath("../ElevatorGate")]
	_switch.opens_paths = [NodePath("../HazardGate")]
	_switch.position = Vector3(-3.6, MEZZANINE_Y + 0.65, -2.0)
	add_child(_switch)
	_switch.flipped.connect(_on_switch_flipped)


func _build_reset_button() -> void:
	# §15.11 : chaque salle a son reset. Ici il ne touche PAS à
	# l'aiguillage — remettre les électrodes sous tension serait une
	# punition, pas une réparation. Il renvoie l'ascenseur en bas, ce qui
	# suffit à débloquer le seul mécanisme mobile de la salle.
	_reset_button = ResetButton.new()
	_reset_button.name = "ResetButton"
	_reset_button.verb = "Rappeler l'ascenseur"
	_reset_button.position = Vector3(4.0, 0.55, 5.6)
	add_child(_reset_button)
	decor("ResetMarker", Vector3(4.0, 0.03, 5.6), Vector3(1.6, 0.04, 1.6),
		COL_IVORY)


func reset_room() -> void:
	super()
	if _elevator != null:
		_elevator.reset_to_bottom()


func _on_switch_flipped(state: bool) -> void:
	if not state or _rerouted:
		return
	_rerouted = true
	save_room_state()
	rerouted.emit()


func _on_receiver_power_changed(powered: bool, _power: float) -> void:
	if powered and not _rerouted:
		_rerouted = true
		save_room_state()
		rerouted.emit()


func room_state() -> Dictionary:
	var state: Dictionary = super()
	state["rerouted"] = _rerouted
	state["door_open"] = _door != null and _door.is_latched()
	return state


func apply_room_state(state: Dictionary) -> void:
	super(state)
	_rerouted = bool(state.get("rerouted", false))
	if _switch != null:
		# Le levier lit son état sur les nœuds restaurés (§19.4) : aucune
		# copie parallèle qui pourrait diverger du fichier.
		var gate: ElectricNode = get_node_or_null("ElevatorGate") as ElectricNode
		if gate != null:
			_switch.set_flipped(gate.enabled)
	if bool(state.get("door_open", false)) and _door != null:
		_door.force_open()


func _setup_lighting() -> void:
	# §7.8 : ocre/bronze sombre, énergie cyan directionnelle, aucun couloir
	# noir. Les braseros jalonnent la montée : on voit toujours la corniche
	# suivante.
	var lamps: Array[Vector3] = [
		Vector3(5.6, 2.6, 10.5), Vector3(-5.6, 2.6, 10.5),
		Vector3(5.6, 2.6, 5.4), Vector3(5.6, 7.6, 2.4),
		Vector3(5.6, 12.6, -0.6), Vector3(5.6, 17.6, -3.6),
	]
	for i: int in range(lamps.size()):
		var warm: OmniLight3D = OmniLight3D.new()
		warm.name = "ShaftGlow%d" % i
		warm.light_color = Color(1.0, 0.74, 0.42)
		warm.light_energy = 2.6
		warm.omni_range = 16.0
		warm.position = lamps[i]
		add_child(warm)
		box("Brazier%d" % i, warm.position - Vector3(0, 1.9, 0),
			Vector3(0.7, 1.4, 0.7), COL_BRONZE)
		decor("BrazierCoal%d" % i, warm.position - Vector3(0, 1.1, 0),
			Vector3(0.5, 0.22, 0.5), Color(0.98, 0.58, 0.22), true)
	var top: OmniLight3D = OmniLight3D.new()
	top.name = "MezzanineGlow"
	top.light_color = Color(0.5, 0.9, 0.95)
	top.light_energy = 2.2
	top.omni_range = 14.0
	top.position = Vector3(3.0, MEZZANINE_Y + 3.0, -4.5)
	add_child(top)
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


## Amène la salle à l'état que le joueur atteint en basculant le levier.
## Utilisé par `capture_reference.gd --call=` ; aucune règle de gameplay.
func capture_state_rerouted() -> void:
	if _switch != null:
		_switch.interact(null)


func elevator() -> ElevatorPlatform:
	return _elevator


func reroute_switch() -> ElectricSwitch:
	return _switch


func hazards() -> Array[ElectricHazard]:
	return _hazards


func door() -> ElectricDoor:
	return _door


func receiver() -> ElectricNode:
	return _receiver


func source() -> ElectricNode:
	return _source


func reset_button() -> ResetButton:
	return _reset_button


func is_rerouted() -> bool:
	return _rerouted


func player() -> PlayerController:
	return _player
