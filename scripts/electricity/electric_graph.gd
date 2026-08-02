## Graphe électrique (MASTER_SPEC §15.2) — la propagation, et rien
## d'autre : aucune ligne de rendu, aucun son, aucune règle de salle.
##
## L'algorithme de §15.2, point par point :
## 1. un déplacement, une rotation ou un interrupteur marque `dirty` ;
## 2. les changements sont REGROUPÉS jusqu'à la fin du tick physique —
##    dix objets bougés dans la même frame = UN seul recalcul ;
## 3. les connexions spatiales sont reconstruites ;
## 4. le parcours part de TOUTES les sources actives ;
## 5. BFS avec ensemble `visited` : les cycles sont autorisés et ne
##    provoquent jamais de récursion infinie ;
## 6. chaque arête vérifie distance, sens de port, isolant et
##    interrupteur ;
## 7. les récepteurs atteints sont calculés ;
## 8-9. l'ancien état est comparé au nouveau et les signaux ne partent
##    QUE sur changement (`set_powered` est idempotent) ;
## 10. la présentation interpole depuis ces signaux, ailleurs.
##
## « Ne jamais parcourir tout le donjon à chaque frame » : sans `dirty`,
## `_physics_process` ne fait rien du tout.
class_name ElectricGraph
extends Node

## Le graphe vient de se recalculer (utile aux tests et à la carte murale).
signal graph_recomputed(powered_receivers: int)

## Racine des nœuds. Vide = le parent du graphe.
@export var nodes_root: NodePath

var _dirty: bool = true
var _recompute_count: int = 0
var _nodes: Array[ElectricNode] = []
## Profondeur BFS par nœud au dernier calcul (0 = source). Sert à la
## PRÉSENTATION seule ; la propagation logique, elle, est instantanée.
var _hops: Dictionary[ElectricNode, int] = {}


func _ready() -> void:
	add_to_group("electric_graphs")
	mark_dirty()


## §15.2 pt. 1-2 : marquer, et attendre la fin du tick. Appelable
## autant de fois qu'on veut dans la même frame : un seul recalcul.
func mark_dirty() -> void:
	_dirty = true


func _physics_process(_delta: float) -> void:
	if not _dirty:
		return
	_dirty = false
	recompute()


## Recalcul complet, à la demande (les tests l'appellent directement).
func recompute() -> void:
	_recompute_count += 1
	_collect_nodes()
	_rebuild_connections()
	var reached: Dictionary[ElectricNode, float] = _propagate()
	var powered_receivers: int = 0
	for node: ElectricNode in _nodes:
		var power: float = float(reached.get(node, 0.0))
		# La profondeur AVANT le signal : la présentation en a besoin au
		# moment même où elle apprend qu'elle s'allume.
		node.set_hop_depth(int(_hops.get(node, -1)))
		# §15.2 pt. 8-9 : idempotent — le signal ne part qu'au changement.
		node.set_powered(power > 0.0, power)
		if node.kind == ElectricNode.Kind.RECEIVER and power > 0.0:
			powered_receivers += 1
	graph_recomputed.emit(powered_receivers)


func _collect_nodes() -> void:
	_nodes.clear()
	var root: Node = get_node_or_null(nodes_root) if nodes_root != NodePath() \
		else get_parent()
	if root == null:
		return
	for node: Node in root.find_children("*", "ElectricNode", true, false):
		_nodes.append(node as ElectricNode)


## §15.2 pt. 3 et 6 : deux nœuds sont voisins si un port de l'un touche
## un port de l'autre (distance ≤ portée des DEUX) et si les sens de
## port sont compatibles. Un nœud isolant n'est jamais voisin.
func _rebuild_connections() -> void:
	var links: Dictionary[ElectricNode, Array] = {}
	for node: ElectricNode in _nodes:
		links[node] = []
	for i: int in range(_nodes.size()):
		for j: int in range(i + 1, _nodes.size()):
			var a: ElectricNode = _nodes[i]
			var b: ElectricNode = _nodes[j]
			if a.conductivity <= 0.0 or b.conductivity <= 0.0:
				continue
			if not _ports_touch(a, b):
				continue
			(links[a] as Array).append(b)
			(links[b] as Array).append(a)
	for node: ElectricNode in _nodes:
		var typed: Array[ElectricNode] = []
		for neighbour: Variant in links[node]:
			typed.append(neighbour as ElectricNode)
		node.set_neighbours(typed)


## Contact RÉEL entre ports (§15.3), avec tolérance et sens. Un port de
## sortie ne se relie qu'à une entrée ou un port bidirectionnel.
func _ports_touch(a: ElectricNode, b: ElectricNode) -> bool:
	var reach: float = minf(a.port_reach, b.port_reach)
	for port_a: Dictionary in a.world_ports():
		for port_b: Dictionary in b.world_ports():
			var gap: float = (port_a["position"] as Vector3).distance_to(
				port_b["position"] as Vector3)
			if gap > reach:
				continue
			if _flows_compatible(int(port_a["flow"]), int(port_b["flow"])):
				return true
	return false


func _flows_compatible(flow_a: int, flow_b: int) -> bool:
	if flow_a == ElectricNode.PortFlow.BOTH \
			or flow_b == ElectricNode.PortFlow.BOTH:
		return true
	return flow_a != flow_b


## §15.2 pt. 4-7 : BFS depuis TOUTES les sources actives. L'ensemble
## `visited` rend les cycles inoffensifs. La puissance décroît selon la
## conductivité traversée : un conducteur médiocre affaiblit le courant.
func _propagate() -> Dictionary[ElectricNode, float]:
	var reached: Dictionary[ElectricNode, float] = {}
	var queue: Array[ElectricNode] = []
	_hops.clear()
	for node: ElectricNode in _nodes:
		if node.is_emitting():
			reached[node] = node.source_power
			_hops[node] = 0
			queue.append(node)
	var head: int = 0
	while head < queue.size():
		var current: ElectricNode = queue[head]
		head += 1
		# Un nœud qui ne CONDUIT pas peut être alimenté sans rien
		# transmettre : un interrupteur ouvert s'allume côté source et
		# coupe côté sortie.
		if not current.conducts():
			continue
		var current_power: float = float(reached[current])
		for neighbour: ElectricNode in current.neighbours():
			var transmitted: float = current_power * neighbour.conductivity
			if transmitted <= 0.0:
				continue
			# Déjà atteint AVEC AU MOINS AUTANT de puissance : ne pas
			# re-parcourir (c'est ce qui borne les cycles).
			if reached.has(neighbour) \
					and float(reached[neighbour]) >= transmitted - 0.0001:
				continue
			reached[neighbour] = transmitted
			# Le chemin le plus court l'emporte : un nœud re-visité par une
			# branche plus longue garde sa profondeur d'origine.
			var depth: int = int(_hops.get(current, 0)) + 1
			if not _hops.has(neighbour) or depth < int(_hops[neighbour]):
				_hops[neighbour] = depth
			queue.append(neighbour)
	return reached


## Nombre de recalculs depuis le démarrage — le test s'en sert pour
## prouver le REGROUPEMENT (§15.2 pt. 2) : dix changements, un recalcul.
func recompute_count() -> int:
	return _recompute_count


func node_count() -> int:
	return _nodes.size()


## Récupère un nœud par son ID stable (§19.3) — pour la sauvegarde et
## les règles de salle.
func find_node(id: StringName) -> ElectricNode:
	for node: ElectricNode in _nodes:
		if node.node_id == id:
			return node
	return null


## §19.1 : l'état sauvegardable du circuit — ce que le joueur a changé.
## L'alimentation n'est PAS sauvegardée : elle se recalcule.
func save_state() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	for node: ElectricNode in _nodes:
		if node.node_id != &"":
			states.append(node.save_state())
	return states


func apply_state(states: Array) -> void:
	_collect_nodes()
	for entry: Variant in states:
		var state: Dictionary = entry as Dictionary
		var node: ElectricNode = find_node(StringName(String(state.get("id", ""))))
		if node != null:
			node.apply_state(state)
	mark_dirty()
	recompute()


## Validateur d'IDs (§19.3) : vide ou dupliqué = faute de conception.
func validate_ids() -> Array[String]:
	var problems: Array[String] = []
	var seen: Dictionary[StringName, bool] = {}
	for node: ElectricNode in _nodes:
		if node.node_id == &"":
			problems.append("nœud sans ID : %s" % node.name)
			continue
		if seen.has(node.node_id):
			problems.append("ID dupliqué : %s" % String(node.node_id))
		seen[node.node_id] = true
	return problems
