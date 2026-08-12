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
var _rotation_pending: bool = false
var _powered_before_turn: int = 0
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
	_build_dressing()
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
		&"room3_from_hall": Vector3(0, 0.3, 9.0),
		&"room3_from_shortcut": Vector3(13.5, 0.3, -4),
	})
	# P2 §9.8 : hints gradués sur échecs OBSERVÉS — loi, cause, relation.
	install_hints(
		"Un relais transmet par ses ports : leur orientation décide du chemin.",
		"Un segment ne s'allume que si deux ports se font face — cherche celui qui tourne le dos.",
		"Tourne les colonnes pour aligner leurs ports deux à deux, de la source jusqu'au récepteur.")
	# ISS-031 : la salle n'avait que le reset comme source d'échec — une
	# rotation qui ne fait pas PROGRESSER le courant est un échec observé
	# (§9.8), et c'est le geste même de l'énigme.
	for relay: ElectricRelay in _relays:
		relay.turned.connect(_on_relay_turned)
	if graph() != null:
		graph().graph_recomputed.connect(_on_recompute_after_turn)


func _build_shell() -> void:
	box("Floor", Vector3(0, -0.5, 0), Vector3(20, 1, 22), COL_FLOOR)
	box("Ceiling", Vector3(0, 9.5, 0), Vector3(20, 1, 22), COL_STONE)
	box("WallWest", Vector3(-10.25, 4.5, 0), Vector3(0.5, 9, 22), COL_STONE)
	box("WallNorth", Vector3(0, 4.5, -11.25), Vector3(20, 9, 0.5), COL_STONE)
	# Est : percement de 4 m pour la porte du puzzle, à hauteur du récepteur.
	# BLOCAGE corrige : les deux pans se rejoignaient sous le linteau et
	# muraient la porte. Ouverture retablie de z = -6 a z = -2.
	box("WallEastNorth", Vector3(10.25, 4.5, -8.5), Vector3(0.5, 9, 5), COL_STONE)
	box("WallEastSouth", Vector3(10.25, 4.5, 4.5), Vector3(0.5, 9, 13), COL_STONE)
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


## Habillage d'identité (bible §12.2) — SALLE 3 = GALERIE CÉRÉMONIELLE :
## colonnade, céramique ivoire, bannières et torchères. C'est la salle la
## plus « civilisée » du donjon : les relais y sont exposés comme des
## instruments, pas entassés comme des machines. Décor PUR, aucune
## collision, ≥ 2 m du champ des relais (x −4,4..2,2 · z −4..1,6), de la
## source, du récepteur et du reset.
func _build_dressing() -> void:
	const IVORY_CLOTH: Color = Color(0.80, 0.76, 0.65)
	const CRACK: Color = Color(0.10, 0.10, 0.12)
	# Colonnade : rangée nord derrière le circuit, paire sud encadrant
	# l'approche. Module réel du kit (0,53 m × 3,02 m) étiré à ~8,7 m.
	var north_cols: Array[float] = [-7.5, -2.5, 2.5, 7.5]
	for i: int in range(north_cols.size()):
		dress_prop(&"Corner_Exterior_Brick", "GalleryColumnN%d" % i,
			Vector3(north_cols[i], 0.0, -8.5), PI * 0.5 * float(i % 4),
			Vector3(1.6, 2.9, 1.6))
	for i: int in range(2):
		var x: float = -5.5 if i == 0 else 5.5
		dress_prop(&"Corner_Exterior_Brick", "GalleryColumnS%d" % i,
			Vector3(x, 0.0, 8.5), PI * 0.5 * float(i),
			Vector3(1.6, 2.9, 1.6))
	# Arcade AVEUGLE sur le mur nord, entre les colonnes : le langage des
	# seuils, gravé dans la pierre pleine — zéro risque de passage.
	for i: int in range(3):
		dress_prop(&"SM_Dungeon_ArchBlock", "BlindArchN%d" % i,
			Vector3(-5.0 + 5.0 * float(i), 0.0, -10.7), 0.0,
			Vector3(3.4, 3.4, 0.9))
	# Céramique ivoire : plinthes au pied des murs, bandeau à mi-hauteur.
	decor("CeramicPlinthNorth", Vector3(0, 0.3, -10.8), Vector3(19.0, 0.6, 0.3),
		COL_IVORY)
	decor("CeramicPlinthWest", Vector3(-9.8, 0.3, 0), Vector3(0.3, 0.6, 20.0),
		COL_IVORY)
	decor("CeramicPlinthEastS", Vector3(9.8, 0.3, 5.0), Vector3(0.3, 0.6, 11.0),
		COL_IVORY)
	decor("CeramicPlinthEastN", Vector3(9.8, 0.3, -8.75),
		Vector3(0.3, 0.6, 4.5), COL_IVORY)
	decor("CeramicBandNorth", Vector3(0, 5.8, -10.85), Vector3(19.0, 0.35, 0.2),
		COL_IVORY)
	# Bordures de sol : deux lignes ivoire cadrent le champ des relais
	## (à 2,2 m et 2,4 m des colonnes les plus proches du circuit).
	decor("FloorBorderSouth", Vector3(-1.0, 0.02, 4.0), Vector3(10.0, 0.04, 0.5),
		COL_IVORY)
	decor("FloorBorderNorth", Vector3(-0.5, 0.02, -6.2), Vector3(14.0, 0.04, 0.5),
		COL_IVORY)
	# Deux bandes de plafond : la galerie a une charpente de pierre, pas une
	# dalle nue (plafond à y = 9,0).
	decor("CeilingRibNorth", Vector3(0, 8.85, -4.0), Vector3(19.5, 0.25, 0.6),
		COL_IVORY)
	decor("CeilingRibSouth", Vector3(0, 8.85, 4.0), Vector3(19.5, 0.25, 0.6),
		COL_IVORY)
	# Bannières hautes, teinte ivoire imposée : les couleurs vives du kit
	# château sortiraient de la palette du donjon (§12.1).
	dress_prop(&"SM_Dungeon_Banner", "BannerWestN",
		Vector3(-9.55, 3.2, -7.5), 0.0, Vector3.ONE * 1.6, IVORY_CLOTH)
	dress_prop(&"SM_Dungeon_Banner", "BannerWestS",
		Vector3(-9.55, 3.2, 6.0), 0.0, Vector3.ONE * 1.6, IVORY_CLOTH)
	dress_prop(&"SM_Dungeon_Banner", "BannerEastS",
		Vector3(9.55, 3.2, 3.0), PI, Vector3.ONE * 1.6, IVORY_CLOTH)
	dress_prop(&"SM_Dungeon_Banner", "BannerEastN",
		Vector3(9.55, 3.2, -9.0), PI, Vector3.ONE * 1.6, IVORY_CLOTH)
	# Torchères sur les colonnes sud, et leurs lumières MOTIVÉES
	# (bornes du chantier : énergie ≤ 2, portée ≤ 12).
	for i: int in range(2):
		var x: float = -5.5 if i == 0 else 5.5
		dress_prop(&"Torch_Metal", "ColumnTorch%d" % i,
			Vector3(x, 2.2, 7.95), PI)
		var glow: OmniLight3D = OmniLight3D.new()
		glow.name = "ColumnTorchGlow%d" % i
		glow.light_color = Color(1.0, 0.72, 0.38)
		glow.light_energy = 0.9
		glow.omni_range = 6.0
		glow.position = Vector3(x, 2.6, 7.5)
		add_child(glow)
	# Usure : gravats au coin nord-ouest, fissure haute sur la coque nue.
	dress_prop(&"SM_Dungeon_RubbleSmall", "RubbleNW",
		Vector3(-9.2, 0.0, -10.0), 1.9, Vector3.ONE * 1.4)
	decor("CrackNorth", Vector3(3.2, 7.6, -10.94), Vector3(0.10, 1.7, 0.05),
		CRACK)
	decor("CrackWest", Vector3(-9.94, 7.4, 6.5), Vector3(0.05, 1.5, 0.10),
		CRACK)


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


## ISS-031 — le « progrès » du courant : relais alimentés, et le
## récepteur VAUT la solution (jamais « vain » quand il s'allume).
func _powered_progress() -> int:
	var count: int = 0
	for relay: ElectricRelay in _relays:
		if relay.node().is_powered():
			count += 1
	if _receiver != null and _receiver.is_powered():
		count += 10
	return count


func _on_relay_turned(_step: int) -> void:
	_rotation_pending = true


func _on_recompute_after_turn(_powered_receivers: int) -> void:
	if not _rotation_pending:
		_powered_before_turn = _powered_progress()
		return
	_rotation_pending = false
	var after: int = _powered_progress()
	if after <= _powered_before_turn and not _solved and hints() != null:
		hints().record_failure(&"rotation_vaine")
	_powered_before_turn = after


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
