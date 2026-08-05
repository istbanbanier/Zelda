## Lien d'Arc Link (P2 §3.3) — un nœud CABLE temporaire injecté dans le graphe
## électrique du Gate F. Il TRANSPORTE : la propagation, les cycles, la perte
## et l'idempotence sont ceux d'`ElectricGraph` — aucune seconde logique.
##
## Le lien s'auto-surveille au tick physique : port détruit, sorti de l'arbre
## ou écarté au-delà de la marge → dissolution immédiate et graphes marqués
## `dirty`. L'annulation est TOUJOURS sûre (P2 §3.3) : retrait de l'arbre
## AVANT `queue_free`, pour que le recalcul suivant ne le voie plus.
class_name ResonanceLinkNode
extends ElectricNode

signal dissolved()

## Au-delà de cet écart entre les extrémités liées et la position ACTUELLE
## des ports, le lien casse — un conducteur mobile qui s'éloigne rompt l'arc.
const BREAK_MARGIN: float = 1.5

var _a: ElectricNode = null
var _b: ElectricNode = null
var _a_port: Vector3 = Vector3.ZERO
var _b_port: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group(&"resonance_links")


## À appeler APRÈS l'ajout à l'arbre (les conversions monde→local en dépendent).
func bind(a: ElectricNode, b: ElectricNode, a_port: Vector3, b_port: Vector3) -> void:
	_a = a
	_b = b
	_a_port = a_port
	_b_port = b_port
	kind = Kind.CABLE
	conductivity = 1.0
	node_id = &"resonance.link.active.01"
	global_position = (a_port + b_port) * 0.5
	port_offsets = [to_local(a_port), to_local(b_port)]
	port_flows = []


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_a) or not is_instance_valid(_b) \
			or not _a.is_inside_tree() or not _b.is_inside_tree():
		dissolve()
		return
	# Les ports ont-ils bougé ? Le lien suit jusqu'à la marge, puis casse.
	if _nearest_port_gap(_a, _a_port) > BREAK_MARGIN \
			or _nearest_port_gap(_b, _b_port) > BREAK_MARGIN:
		dissolve()


func dissolve() -> void:
	if not is_inside_tree():
		return
	var parent: Node = get_parent()
	if parent != null:
		parent.remove_child(self)
	_mark_graphs_dirty()
	dissolved.emit()
	queue_free()


func _nearest_port_gap(node: ElectricNode, bound_at: Vector3) -> float:
	var best: float = INF
	for port: Dictionary in node.world_ports():
		best = minf(best, (port["position"] as Vector3).distance_to(bound_at))
	return best


func _mark_graphs_dirty() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for graph: Node in tree.get_nodes_in_group(&"electric_graphs"):
		if graph.has_method("mark_dirty"):
			graph.call("mark_dirty")
