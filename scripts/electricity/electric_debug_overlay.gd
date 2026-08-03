## Outil de debug du graphe électrique (MASTER_SPEC §15.11 : « créer un
## outil debug de développement permettant d'afficher IDs, ports, voisins
## et état `powered`, mais le MASQUER dans le build final »).
##
## Deux usages, un seul code :
##   - `dump_lines()` rend le graphe lisible en texte — c'est ce qu'on
##     colle dans un rapport de bug, et ce qu'un test peut vérifier ;
##   - les étiquettes 3D montrent la même chose SUR les nœuds, pour
##     comprendre un circuit en marchant dedans.
##
## Le masquage n'est pas un `visible = false` : dans un build non-debug,
## l'outil se RETIRE de l'arbre. Un overlay qui ne coûte rien est un
## overlay absent.
class_name ElectricDebugOverlay
extends Node3D

const COL_TEXT: Color = Color(0.925, 1.0, 1.0)

@export var graph_path: NodePath
## Étiquettes 3D au-dessus de chaque nœud. Coûteuses : hors par défaut.
@export var show_labels: bool = false
## Cadence de rafraîchissement des étiquettes, en secondes.
@export var refresh_interval: float = 0.5

var _graph: ElectricGraph = null
var _labels: Dictionary[ElectricNode, Label3D] = {}
var _timer: float = 0.0


## Contrat de §15.11, isolé pour être testable sans build de release :
## l'outil n'existe QUE dans un build de développement.
static func is_enabled_for(debug_build: bool) -> bool:
	return debug_build


func _ready() -> void:
	if not is_enabled_for(OS.is_debug_build()):
		queue_free()
		return
	_graph = get_node_or_null(graph_path) as ElectricGraph
	if _graph == null:
		var graphs: Array[Node] = get_tree().get_nodes_in_group("electric_graphs")
		if not graphs.is_empty():
			_graph = graphs[0] as ElectricGraph
	set_process(show_labels)


## Une ligne par nœud : ID, type, alimentation, ports et voisins. C'est la
## réponse aux quatre questions de §15.11, dans l'ordre.
func dump_lines() -> Array[String]:
	var lines: Array[String] = []
	if _graph == null:
		return lines
	for node: ElectricNode in _nodes():
		var neighbour_ids: Array[String] = []
		for neighbour: ElectricNode in node.neighbours():
			neighbour_ids.append(String(neighbour.node_id) if neighbour.node_id != &"" \
				else neighbour.name)
		lines.append("%s | %s | %s | ports=%d | voisins=[%s]" % [
			String(node.node_id) if node.node_id != &"" else node.name,
			_kind_name(node.kind),
			"ALIMENTÉ" if node.is_powered() else "éteint",
			node.world_ports().size(),
			", ".join(neighbour_ids),
		])
	return lines


func dump_text() -> String:
	return "\n".join(dump_lines())


## Résumé chiffré — utile en une ligne dans un rapport.
func summary() -> Dictionary:
	var powered: int = 0
	var sources: int = 0
	var receivers: int = 0
	var orphans: int = 0
	var mobile_idle: int = 0
	for node: ElectricNode in _nodes():
		if node.is_powered():
			powered += 1
		if node.kind == ElectricNode.Kind.SOURCE:
			sources += 1
		elif node.kind == ElectricNode.Kind.RECEIVER:
			receivers += 1
		if not node.neighbours().is_empty():
			continue
		# Un conducteur mobile ou une batterie SANS voisin est normal : il
		# attend qu'on le pose. Un nœud fixe sans voisin, lui, est une
		# faute de pose — il est dans la salle mais hors du circuit.
		if node.kind in [ElectricNode.Kind.MOVABLE_CONDUCTOR,
				ElectricNode.Kind.BATTERY]:
			mobile_idle += 1
		else:
			orphans += 1
	return {
		"nodes": _nodes().size(),
		"powered": powered,
		"sources": sources,
		"receivers": receivers,
		# Nœud FIXE sans voisin : presque toujours une faute de pose.
		"orphans": orphans,
		# Objet mobile hors circuit : normal tant qu'on ne l'a pas posé.
		"mobile_idle": mobile_idle,
		"recomputes": _graph.recompute_count() if _graph != null else 0,
	}


func _nodes() -> Array[ElectricNode]:
	var nodes: Array[ElectricNode] = []
	if _graph == null:
		return nodes
	var root: Node = _graph.get_parent()
	if root == null:
		return nodes
	for node: Node in root.find_children("*", "ElectricNode", true, false):
		nodes.append(node as ElectricNode)
	return nodes


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = refresh_interval
	_refresh_labels()


func _refresh_labels() -> void:
	for node: ElectricNode in _nodes():
		var label: Label3D = _labels.get(node)
		if label == null:
			label = Label3D.new()
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true
			label.font_size = 24
			label.modulate = COL_TEXT
			label.position = Vector3(0, 0.6, 0)
			node.add_child(label)
			_labels[node] = label
		label.text = "%s\n%s | %d voisin(s)" % [
			String(node.node_id) if node.node_id != &"" else node.name,
			"ON" if node.is_powered() else "off",
			node.neighbours().size(),
		]


func _kind_name(kind: ElectricNode.Kind) -> String:
	match kind:
		ElectricNode.Kind.SOURCE: return "SOURCE"
		ElectricNode.Kind.CABLE: return "CABLE"
		ElectricNode.Kind.CONNECTOR: return "CONNECTOR"
		ElectricNode.Kind.SWITCH: return "SWITCH"
		ElectricNode.Kind.MOVABLE_CONDUCTOR: return "MOVABLE"
		ElectricNode.Kind.RELAY: return "RELAY"
		ElectricNode.Kind.RECEIVER: return "RECEIVER"
		ElectricNode.Kind.DOOR: return "DOOR"
		ElectricNode.Kind.HAZARD: return "HAZARD"
		ElectricNode.Kind.BATTERY: return "BATTERY"
		ElectricNode.Kind.WATER_ZONE: return "WATER"
	return "?"
