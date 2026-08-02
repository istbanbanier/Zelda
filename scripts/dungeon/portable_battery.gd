## Batterie transportable (MASTER_SPEC §15.1 `BatteryNode`, §15.8).
##
## §15.3 est explicite : « pour une batterie, distinguer CHARGE STOCKÉE,
## SOCKET et DÉCHARGE ». Les trois vivent ici, séparément :
##   - `charge` monte quand le nœud de la batterie est alimenté par une
##     source extérieure (elle est alors dans le socket de charge) ;
##   - elle DÉBITE dès qu'elle a de la charge, où qu'elle soit — c'est ce
##     qui permet de porter le courant de l'autre côté de l'eau ;
##   - elle se vide lentement en débitant, jamais assez vite pour piéger
##     le joueur : la porte qu'elle ouvre reste ouverte (§15.11).
class_name PortableBattery
extends CarryableObject

signal charge_changed(ratio: float)

const COL_SHELL: Color = Color(0.30, 0.27, 0.24)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)

@export var battery_id: StringName = &""
## Secondes de charge pleine.
@export var capacity: float = 90.0
## Vitesse de remplissage dans le socket de charge (s de réserve/s).
@export var charge_rate: float = 24.0
## Vitesse de vidange en débit (s de réserve/s).
@export var drain_rate: float = 1.0
@export var node_port_offsets: Array[Vector3] = [Vector3(0, -0.35, 0)]
@export var node_port_reach: float = 0.6

var _charge: float = 0.0
var _node: ElectricNode = null
var _material: StandardMaterial3D = null
## Vrai quand une source EXTÉRIEURE l'alimente : elle se recharge alors.
var _external_power: bool = false


func _ready() -> void:
	super()
	carry_tag = &"battery"
	mass = 14.0
	_build_visual()
	_node = ElectricNode.new()
	_node.name = "BatteryNode"
	_node.node_id = battery_id
	_node.kind = ElectricNode.Kind.BATTERY
	_node.conductivity = 1.0
	_node.port_offsets = node_port_offsets
	_node.port_reach = node_port_reach
	_node.enabled = false   # vide au départ : rien à débiter
	add_child(_node)
	_node.power_changed.connect(_on_node_power_changed)


func _build_visual() -> void:
	var mesh: MeshInstance3D = get_node_or_null("Mesh") as MeshInstance3D
	if mesh == null:
		return
	_material = StandardMaterial3D.new()
	_material.albedo_color = COL_SHELL
	_material.roughness = 0.55
	mesh.material_override = _material


## Le graphe alimente la batterie : c'est le socket de charge qui parle.
## Une batterie qui débit s'alimente elle-même — on ne compte donc que la
## puissance reçue quand elle NE débite PAS encore.
func _on_node_power_changed(powered: bool, _power: float) -> void:
	_external_power = powered


func _physics_process(delta: float) -> void:
	super(delta)
	var was_enabled: bool = _node.enabled
	if _external_power and _charge < capacity:
		_charge = minf(capacity, _charge + charge_rate * delta)
	elif _node.enabled and not _external_power:
		_charge = maxf(0.0, _charge - drain_rate * delta)
	_node.enabled = _charge > 0.0
	if _node.enabled != was_enabled:
		_mark_graph()
	_refresh_visual()


func _mark_graph() -> void:
	for graph: Node in get_tree().get_nodes_in_group("electric_graphs"):
		(graph as ElectricGraph).mark_dirty()


func _refresh_visual() -> void:
	if _material == null:
		return
	var ratio: float = charge_ratio()
	_material.albedo_color = COL_SHELL.lerp(COL_CYAN, ratio)
	_material.emission_enabled = ratio > 0.02
	_material.emission = COL_CYAN
	_material.emission_energy_multiplier = 2.4 * ratio


func charge_ratio() -> float:
	return clampf(_charge / maxf(0.01, capacity), 0.0, 1.0)


func is_charged() -> bool:
	return _charge > 0.0


## Pose une charge — restauration d'une sauvegarde, ou mise en place.
func set_charge_seconds(value: float) -> void:
	_charge = clampf(value, 0.0, capacity)
	_node.enabled = _charge > 0.0
	_refresh_visual()
	charge_changed.emit(charge_ratio())


func charge_seconds() -> float:
	return _charge


func node() -> ElectricNode:
	return _node
