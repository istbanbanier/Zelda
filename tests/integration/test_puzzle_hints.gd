## P2-5 (fin) — HINTS GRADUÉS (P2 §9.8) : « après observation d'échecs,
## pas après un simple timer : rappeler loi, attirer vers cause, puis
## montrer relation. Ne jamais donner directement la séquence complète au
## premier hint. » Fail-first : écrit avant l'implémentation.
##
## Contrats : trois échecs OBSERVÉS ouvrent le palier 1 (la loi), le temps
## seul n'ouvre RIEN ; le premier hint n'est jamais la relation complète ;
## une salle résolue se tait ; et les salles RÉELLES branchent leurs vrais
## échecs — bouton reset pressé (salle 1), décharge subie dans l'eau
## (salle 4) — sur le même compteur.
extends GateTestCase

const ROOM1: String = "res://scenes/dungeon/rooms/Room1Initiation.tscn"
const ROOM4: String = "res://scenes/dungeon/rooms/Room4Battery.tscn"

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(3)


func test_failures_escalate_by_observation_never_by_time() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var tracker: PuzzleHintTracker = PuzzleHintTracker.new()
	tracker.set_hints("la loi", "la cause", "la relation")
	_root.add_child(tracker)
	await _settle(1)
	tracker.record_failure(&"reset")
	tracker.record_failure(&"reset")
	check_equal(tracker.level(), 0, "deux échecs : encore aucun hint")
	tracker.record_failure(&"choc")
	check_equal(tracker.level(), 1, "trois échecs : palier 1")
	# Le TEMPS seul n'escalade rien (§9.8 : jamais un simple timer).
	await _settle(120)
	check_equal(tracker.level(), 1, "deux secondes plus tard : toujours 1")
	for i: int in range(3):
		tracker.record_failure(&"reset")
	check_equal(tracker.level(), 2, "six échecs : palier 2")
	for i: int in range(3):
		tracker.record_failure(&"hors_limites")
	check_equal(tracker.level(), 3, "neuf échecs : palier 3")
	for i: int in range(3):
		tracker.record_failure(&"reset")
	check_equal(tracker.level(), 3, "le palier 3 est le plafond")
	check_equal(tracker.count(&"reset"), 8, "les causes sont comptées par type")
	await _teardown()


func test_the_first_hint_is_the_law_never_the_relation() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var tracker: PuzzleHintTracker = PuzzleHintTracker.new()
	tracker.set_hints("la loi", "la cause", "la relation")
	_root.add_child(tracker)
	await _settle(1)
	check_equal(tracker.current_hint(), "", "palier 0 : silence")
	var heard: Array[String] = []
	tracker.hint_ready.connect(
		func(_level: int, text: String) -> void: heard.append(text))
	for i: int in range(3):
		tracker.record_failure(&"reset")
	check_equal(tracker.current_hint(), "la loi",
		"le premier hint RAPPELLE LA LOI")
	check(heard.size() == 1 and heard[0] == "la loi",
		"…et c'est ce qui a été signalé — jamais la relation complète")
	await _teardown()


func test_a_solved_room_stops_hinting() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var tracker: PuzzleHintTracker = PuzzleHintTracker.new()
	tracker.set_hints("la loi", "la cause", "la relation")
	_root.add_child(tracker)
	await _settle(1)
	tracker.record_failure(&"reset")
	tracker.close()
	for i: int in range(6):
		tracker.record_failure(&"reset")
	check_equal(tracker.level(), 0, "salle résolue : les hints se taisent")
	check(tracker.is_closed(), "…définitivement")
	await _teardown()


func test_room1_wires_the_reset_button_as_a_real_failure() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var room: Room1Initiation = (load(ROOM1) as PackedScene).instantiate() \
		as Room1Initiation
	_root.add_child(room)
	await _settle(8)
	var tracker: PuzzleHintTracker = room.hints()
	check(tracker != null, "la salle 1 porte le traqueur de hints")
	if tracker == null:
		await _teardown()
		return
	for i: int in range(3):
		room.reset_button().interact(null)
		await _settle(2)
	check_equal(tracker.count(&"reset"), 3,
		"trois pressions RÉELLES du bouton comptées")
	check_equal(tracker.level(), 1, "…et le palier 1 s'ouvre")
	check(not tracker.current_hint().is_empty(),
		"le hint de la salle 1 existe et parle")
	await _teardown()


func test_room4_counts_water_shocks_as_failures() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var room: Room4Battery = (load(ROOM4) as PackedScene).instantiate() \
		as Room4Battery
	_root.add_child(room)
	await _settle(8)
	var tracker: PuzzleHintTracker = room.hints()
	check(tracker != null, "la salle 4 porte le traqueur de hints")
	if tracker == null or room.player() == null:
		await _teardown()
		return
	# Le joueur patauge dans la nappe SOUS TENSION : chaque décharge subie
	# est un échec observé — pas un minuteur.
	room.player().global_position = Vector3(0.0, -1.0, 5.0)
	var ticks: int = 0
	while tracker.count(&"choc") < 2 and ticks < 240:
		await _tree().physics_frame
		ticks += 1
	check(tracker.count(&"choc") >= 2,
		"les décharges subies sont comptées (%d)" % tracker.count(&"choc"))
	# Une pression de reset s'ADDITIONNE : troisième échec, palier 1.
	room.player().global_position = Vector3(-9.0, 0.3, 5.0)
	await _settle(2)
	room.reset_button().interact(null)
	await _settle(2)
	check(tracker.level() >= 1,
		"chocs + reset franchissent le palier 1 (%d échecs)"
		% tracker.failures())
	await _teardown()

func test_room3_counts_fruitless_rotations() -> void:
	## ISS-031 : la salle 3 n'avait qu'UNE source d'échec (reset). Une
	## rotation qui ne fait pas PROGRESSER le courant est un échec observé
	## (§9.8) — huit pas de rotation d'une même colonne (deux tours
	## complets) en produisent au moins trois.
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var room: Room3Relays = (load("res://scenes/dungeon/rooms/Room3Relays.tscn")
		as PackedScene).instantiate() as Room3Relays
	_root.add_child(room)
	await _settle(8)
	var tracker: PuzzleHintTracker = room.hints()
	check(tracker != null, "la salle 3 porte le traqueur")
	if tracker == null or room.relays().is_empty():
		await _teardown()
		return
	var relay: ElectricRelay = room.relays()[0]
	# `turn_one_step` incrémente l'index IMMÉDIATEMENT ; c'est la fin de
	# l'ANIMATION (0,35 s) qui émet `turned` et marque le graphe — on
	# attend donc la rotation entière plus le recalcul.
	for i: int in range(8):
		relay.turn_one_step()
		await _settle(30)
	check(tracker.count(&"rotation_vaine") >= 3,
		"les rotations SANS progrès sont comptées (%d)"
		% tracker.count(&"rotation_vaine"))
	check(tracker.level() >= 1, "…et le palier 1 s'ouvre")
	await _teardown()


func test_room2_counts_real_falls() -> void:
	## ISS-031 : « chute dans le puits » — un vrai plongeon compte, une
	## descente d'ascenseur ou d'escalade NON (le compteur exige une chute
	## AÉRIENNE et rapide).
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var room: Room2Vertical = (load("res://scenes/dungeon/rooms/Room2Vertical.tscn")
		as PackedScene).instantiate() as Room2Vertical
	_root.add_child(room)
	await _settle(8)
	var tracker: PuzzleHintTracker = room.hints()
	check(tracker != null, "la salle 2 porte le traqueur")
	if tracker == null or room.player() == null:
		await _teardown()
		return
	var before: int = tracker.count(&"chute")
	room.player().global_position = Vector3(1.5, 8.3, 7.0)
	# `is_on_floor()` reste vrai un tick ou deux après un téléport (état du
	# dernier move_and_slide) : laisser la chute COMMENCER avant d'attendre
	# l'atterrissage — sinon la boucle sort immédiatement.
	await _settle(3)
	var ticks: int = 0
	while not room.player().is_on_floor() and ticks < 360:
		await _tree().physics_frame
		ticks += 1
	await _settle(6)
	check(tracker.count(&"chute") > before,
		"le plongeon dans le puits est un échec observé (%d)"
		% tracker.count(&"chute"))
	await _teardown()

