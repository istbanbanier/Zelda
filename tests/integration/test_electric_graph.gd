## Graphe électrique en SANDBOX AUTOMATISÉE (MASTER_SPEC §15.1-§15.2,
## §22 Phase F point 1 : « graphe électrique dans une sandbox
## automatisée » AVANT toute salle).
##
## Rien de tout ceci n'est une salle : ce sont des circuits construits en
## code, exactement les cas que §15.2 impose — contact réel, isolants,
## interrupteurs, CYCLES, regroupement des changements, idempotence des
## signaux, batterie, et sauvegarde/restauration.
extends GateTestCase

var _world: Node3D = null
var _graph: ElectricGraph = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _sandbox() -> void:
	_world = Node3D.new()
	_world.name = "ElectricSandbox"
	_tree().root.add_child(_world)
	_graph = ElectricGraph.new()
	_graph.name = "Graph"
	_world.add_child(_graph)


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_graph = null
	await _settle(1)


## Fabrique un nœud et le pose. `at` en mètres, ports omnidirectionnels.
func _node(id: String, kind: ElectricNode.Kind, at: Vector3,
		conductivity: float = 1.0) -> ElectricNode:
	var node: ElectricNode = ElectricNode.new()
	node.node_id = StringName(id)
	node.kind = kind
	node.conductivity = conductivity
	node.position = at
	_world.add_child(node)
	return node


func test_a_straight_circuit_powers_its_receiver_and_nothing_else() -> void:
	## §15.2 pt. 4-7 : source → câble → récepteur. Le récepteur s'allume ;
	## un câble POSÉ À L'ÉCART, hors de portée, reste éteint.
	await _sandbox()
	var source: ElectricNode = _node("t.source.01", ElectricNode.Kind.SOURCE,
		Vector3.ZERO)
	var cable: ElectricNode = _node("t.cable.01", ElectricNode.Kind.CABLE,
		Vector3(0.5, 0, 0))
	var receiver: ElectricNode = _node("t.receiver.01",
		ElectricNode.Kind.RECEIVER, Vector3(1.0, 0, 0))
	var orphan: ElectricNode = _node("t.cable.orphan",
		ElectricNode.Kind.CABLE, Vector3(20, 0, 0))
	_graph.recompute()
	check(source.is_powered(), "la source est sous tension")
	check(cable.is_powered(), "le câble transporte")
	check(receiver.is_powered(), "le récepteur est ALIMENTÉ")
	check(not orphan.is_powered(),
		"le câble hors de portée reste ÉTEINT (contact réel, §15.3)")
	await _teardown()


func test_an_open_switch_cuts_the_line_and_closing_it_restores() -> void:
	## §15.2 pt. 6 : l'état d'interrupteur est vérifié à la traversée. Un
	## interrupteur ouvert reçoit le courant mais ne le transmet PAS.
	await _sandbox()
	var source: ElectricNode = _node("t.source.02", ElectricNode.Kind.SOURCE,
		Vector3.ZERO)
	var switch: ElectricNode = _node("t.switch.01", ElectricNode.Kind.SWITCH,
		Vector3(0.5, 0, 0))
	var receiver: ElectricNode = _node("t.receiver.02",
		ElectricNode.Kind.RECEIVER, Vector3(1.0, 0, 0))
	switch.enabled = false
	_graph.recompute()
	check(source.is_powered(), "la source reste sous tension")
	check(switch.is_powered(), "l'interrupteur reçoit le courant…")
	check(not receiver.is_powered(), "…mais OUVERT, il ne transmet rien")
	switch.enabled = true
	_graph.recompute()
	check(receiver.is_powered(), "fermé, il rétablit le circuit")
	await _teardown()


func test_an_insulator_never_conducts() -> void:
	## §14.4 / §15.4 : un isolant (céramique ivoire) a une conductivité
	## nulle — il n'est même pas voisin.
	await _sandbox()
	_node("t.source.03", ElectricNode.Kind.SOURCE, Vector3.ZERO)
	var insulator: ElectricNode = _node("t.insulator.01",
		ElectricNode.Kind.CABLE, Vector3(0.5, 0, 0), 0.0)
	var receiver: ElectricNode = _node("t.receiver.03",
		ElectricNode.Kind.RECEIVER, Vector3(1.0, 0, 0))
	_graph.recompute()
	check(not insulator.is_powered(), "l'isolant ne s'alimente pas")
	check(not receiver.is_powered(), "et il ne laisse RIEN passer")
	check_equal(insulator.neighbours().size(), 0,
		"un isolant n'a même pas de voisins")
	await _teardown()


func test_a_cycle_terminates_and_powers_everything_once() -> void:
	## §15.2 pt. 5 : « les cycles sont autorisés et ne doivent pas
	## provoquer de récursion infinie ». Un ANNEAU de quatre câbles bouclé
	## sur lui-même : le calcul termine, tout le monde est alimenté.
	await _sandbox()
	_node("t.source.04", ElectricNode.Kind.SOURCE, Vector3.ZERO)
	var ring: Array[ElectricNode] = []
	var positions: Array[Vector3] = [
		Vector3(0.5, 0, 0), Vector3(1.0, 0, 0),
		Vector3(1.0, 0, 0.5), Vector3(0.5, 0, 0.5),
	]
	for i: int in range(positions.size()):
		ring.append(_node("t.ring.%02d" % i, ElectricNode.Kind.CABLE,
			positions[i]))
	# La boucle est fermée : le dernier touche le premier (0,5 m d'écart).
	_graph.recompute()
	for node: ElectricNode in ring:
		check(node.is_powered(), "%s alimenté" % String(node.node_id))
	check_equal(_graph.node_count(), 5, "cinq nœuds dans la sandbox")
	# Le vrai test : ceci s'est TERMINÉ. Un second recalcul aussi.
	_graph.recompute()
	check(ring[0].is_powered(), "le recalcul d'un cycle termine encore")
	await _teardown()


func test_ten_changes_in_one_tick_cost_a_single_recompute() -> void:
	## §15.2 pt. 2 : « regrouper les changements jusqu'à la fin du tick
	## physique » — et « ne jamais parcourir tout le donjon à chaque
	## frame ». Dix marquages = UN recalcul ; zéro marquage = zéro.
	await _sandbox()
	_node("t.source.05", ElectricNode.Kind.SOURCE, Vector3.ZERO)
	_node("t.receiver.05", ElectricNode.Kind.RECEIVER, Vector3(0.5, 0, 0))
	await _settle(2)
	var before: int = _graph.recompute_count()
	for i: int in range(10):
		_graph.mark_dirty()
	await _settle(2)
	check_equal(_graph.recompute_count(), before + 1,
		"dix changements dans le même tick : UN seul recalcul")
	# Rien ne bouge : le graphe ne travaille pas.
	var idle_before: int = _graph.recompute_count()
	await _settle(20)
	check_equal(_graph.recompute_count(), idle_before,
		"vingt ticks sans changement : AUCUN recalcul")
	await _teardown()


func test_power_signals_fire_only_on_real_change() -> void:
	## §15.1 (`set_powered` idempotent) et §15.2 pt. 9 : « émettre des
	## signaux uniquement en cas de changement ». Trois recalculs
	## identiques ne produisent qu'UN signal.
	await _sandbox()
	_node("t.source.06", ElectricNode.Kind.SOURCE, Vector3.ZERO)
	var receiver: ElectricNode = _node("t.receiver.06",
		ElectricNode.Kind.RECEIVER, Vector3(0.5, 0, 0))
	var signals: Array[int] = [0]
	receiver.power_changed.connect(
		func(_powered: bool, _power: float) -> void: signals[0] += 1)
	_graph.recompute()
	check_equal(signals[0], 1, "l'allumage émet UNE fois")
	_graph.recompute()
	_graph.recompute()
	check_equal(signals[0], 1, "deux recalculs identiques : AUCUN signal de plus")
	receiver.set_powered(true, 1.0)
	check_equal(signals[0], 1, "set_powered à valeur égale : idempotent")
	await _teardown()


func test_moving_a_conductor_connects_two_plates() -> void:
	## §15.5 (le cœur de la salle 1, prouvé ICI en sandbox) : un bloc
	## métallique mobile relie deux plaques séparées par un vide. Loin :
	## rien. Poussé entre les deux : le récepteur s'allume.
	await _sandbox()
	_node("t.source.07", ElectricNode.Kind.SOURCE, Vector3.ZERO)
	var plate_a: ElectricNode = _node("t.plate.a", ElectricNode.Kind.CONNECTOR,
		Vector3(0.5, 0, 0))
	var plate_b: ElectricNode = _node("t.plate.b", ElectricNode.Kind.CONNECTOR,
		Vector3(1.6, 0, 0))
	var receiver: ElectricNode = _node("t.receiver.07",
		ElectricNode.Kind.RECEIVER, Vector3(2.1, 0, 0))
	var block: ElectricNode = _node("t.block.01",
		ElectricNode.Kind.MOVABLE_CONDUCTOR, Vector3(0, 0, 8))
	_graph.recompute()
	check(plate_a.is_powered(), "la première plaque est alimentée")
	check(not plate_b.is_powered(),
		"le vide coupe : la seconde plaque est éteinte")
	check(not receiver.is_powered(), "…donc le récepteur aussi")
	# Le joueur POUSSE le bloc entre les deux plaques.
	block.position = Vector3(1.05, 0, 0)
	_graph.mark_dirty()
	_graph.recompute()
	check(block.is_powered(), "le bloc conduit")
	check(plate_b.is_powered(), "la seconde plaque reçoit PAR LE BLOC")
	check(receiver.is_powered(), "le récepteur s'allume (§15.5)")
	# Et le retirer ÉTEINT tout — le circuit est réversible.
	block.position = Vector3(0, 0, 8)
	_graph.recompute()
	check(not receiver.is_powered(), "retirer le bloc éteint le récepteur")
	await _teardown()


func test_a_rotated_relay_only_connects_through_its_ports() -> void:
	## §15.3 / §15.7 : « pour une colonne rotative, dépendre de
	## l'orientation des ports ». Le relais ne relie que si SES ports
	## regardent les deux voisins.
	await _sandbox()
	_node("t.source.08", ElectricNode.Kind.SOURCE, Vector3.ZERO)
	var relay: ElectricNode = _node("t.relay.01", ElectricNode.Kind.RELAY,
		Vector3(1.0, 0, 0))
	relay.port_offsets = [Vector3(-0.5, 0, 0), Vector3(0.5, 0, 0)]
	relay.port_flows = [ElectricNode.PortFlow.BOTH, ElectricNode.PortFlow.BOTH]
	var receiver: ElectricNode = _node("t.receiver.08",
		ElectricNode.Kind.RECEIVER, Vector3(2.0, 0, 0))
	# Ports alignés sur l'axe X : la ligne passe.
	_graph.recompute()
	check(receiver.is_powered(), "relais aligné : le courant passe")
	# Quart de tour : les ports regardent Z, plus personne n'est touché.
	relay.rotation.y = PI * 0.5
	_graph.mark_dirty()
	_graph.recompute()
	check(not receiver.is_powered(),
		"relais tourné d'un quart : la ligne est COUPÉE")
	# Demi-tour de plus : réaligné, le courant repasse.
	relay.rotation.y = PI
	_graph.recompute()
	check(receiver.is_powered(), "réaligné : le courant repasse")
	await _teardown()


func test_a_battery_carries_charge_to_a_remote_mechanism() -> void:
	## §15.8 : la batterie transportable alimente un mécanisme LOIN de
	## toute source — et déchargée, elle n'alimente rien.
	await _sandbox()
	var battery: ElectricNode = _node("t.battery.01",
		ElectricNode.Kind.BATTERY, Vector3(50, 0, 0))
	battery.source_power = 1.0
	var door: ElectricNode = _node("t.door.01", ElectricNode.Kind.DOOR,
		Vector3(50.5, 0, 0))
	_graph.recompute()
	check(door.is_powered(),
		"la batterie CHARGÉE alimente le mécanisme, loin de toute source")
	battery.enabled = false
	_graph.mark_dirty()
	_graph.recompute()
	check(not door.is_powered(), "déchargée, elle n'alimente plus rien")
	await _teardown()


func test_the_graph_state_survives_a_save_and_restore() -> void:
	## §19.1 : les interrupteurs sont SAUVEGARDÉS ; l'alimentation, elle,
	## se RECALCULE au chargement (jamais stockée, jamais désynchronisée).
	await _sandbox()
	_node("t.source.09", ElectricNode.Kind.SOURCE, Vector3.ZERO)
	var switch: ElectricNode = _node("t.switch.09", ElectricNode.Kind.SWITCH,
		Vector3(0.5, 0, 0))
	var receiver: ElectricNode = _node("t.receiver.09",
		ElectricNode.Kind.RECEIVER, Vector3(1.0, 0, 0))
	switch.enabled = true
	_graph.recompute()
	check(receiver.is_powered(), "préalable : circuit fermé")
	var snapshot: Array[Dictionary] = _graph.save_state()
	check_equal(snapshot.size(), 3, "trois nœuds sauvegardés")
	for state: Dictionary in snapshot:
		check(not (state.get("id", "") as String).is_empty(),
			"chaque état porte son ID stable")
		check(not state.has("powered"),
			"l'alimentation n'est PAS sauvegardée : elle se recalcule")
	# Le joueur rouvre l'interrupteur… puis on RESTAURE l'instantané.
	switch.enabled = false
	_graph.recompute()
	check(not receiver.is_powered(), "ouvert : le récepteur s'éteint")
	_graph.apply_state(snapshot)
	check(switch.enabled, "l'interrupteur retrouve son état sauvegardé")
	check(receiver.is_powered(),
		"…et l'alimentation est RECALCULÉE, pas restaurée")
	await _teardown()


func test_every_node_needs_a_stable_unique_id() -> void:
	## §19.3 : un ID vide ou dupliqué est une faute de conception — le
	## validateur la trouve, il ne la devine pas.
	await _sandbox()
	_node("t.source.10", ElectricNode.Kind.SOURCE, Vector3.ZERO)
	var twin: ElectricNode = _node("t.source.10", ElectricNode.Kind.CABLE,
		Vector3(0.5, 0, 0))
	var nameless: ElectricNode = _node("", ElectricNode.Kind.CABLE,
		Vector3(1.0, 0, 0))
	_graph.recompute()
	var problems: Array[String] = _graph.validate_ids()
	check_equal(problems.size(), 2, "deux fautes trouvées")
	var joined: String = " | ".join(problems)
	check(joined.contains("dupliqué"), "le doublon est signalé : %s" % joined)
	check(joined.contains("sans ID"), "l'ID vide est signalé")
	check(twin != null and nameless != null, "les nœuds fautifs existent bien")
	await _teardown()
