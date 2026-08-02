## Colonne-relais rotative (MASTER_SPEC §15.1 `RelayNode`, §15.3, §15.7).
##
## §15.3 est explicite : « pour une colonne rotative, dépendre de
## l'ORIENTATION DES PORTS ». C'est exactement ce qui se passe ici — le
## nœud est enfant du pivot, ses ports tournent avec lui, et le graphe ne
## sait rien d'autre que « ces deux ports se touchent ou non ».
##
## §15.7 impose des rotations DISCRÈTES (90° par défaut) et des ports
## VISIBLES : deux bras de cuivre sortent de la colonne, exactement là où
## sont les ports. Ce que le joueur voit est ce que le graphe calcule.
##
## Le graphe n'est marqué qu'à la FIN de la rotation (§15.2 pt. 2) : une
## colonne qui tourne ne fait pas clignoter le circuit pendant 0,35 s.
class_name ElectricRelay
extends StaticBody3D

signal turned(step: int)

const COL_METAL: Color = Color(0.36, 0.34, 0.32)
const COL_COPPER: Color = Color(0.55, 0.36, 0.22)

@export var relay_id: StringName = &""
@export var verb: String = "Tourner"
## Pas de rotation, en degrés (§15.7 : « rotations discrètes de 90° ou
## angles définis »).
@export var step_deg: float = 90.0
## Position de départ, en pas. Le joueur la retrouve avec le bouton reset.
@export var initial_step: int = 0
## Les deux ports du coude, en LOCAL. Par défaut : est et nord.
@export var port_a: Vector3 = Vector3(0.8, 0, 0)
@export var port_b: Vector3 = Vector3(0, 0, -0.8)
@export var turn_time: float = 0.35
@export var port_reach: float = 0.55

var _pivot: Node3D = null
var _node: ElectricNode = null
var _step: int = 0
var _turning: float = 0.0
var _from_angle: float = 0.0
var _to_angle: float = 0.0


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 0
	_build()
	_step = initial_step
	_pivot.rotation.y = deg_to_rad(step_deg * float(_step))
	set_physics_process(false)


func _build() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.8, 2.2, 0.8)
	shape.shape = box
	shape.position = Vector3(0, 0.1, 0)
	add_child(shape)
	var column: MeshInstance3D = MeshInstance3D.new()
	column.name = "Column"
	var column_box: BoxMesh = BoxMesh.new()
	column_box.size = Vector3(0.8, 2.2, 0.8)
	column.mesh = column_box
	var column_material: StandardMaterial3D = StandardMaterial3D.new()
	column_material.albedo_color = COL_METAL
	column_material.roughness = 0.6
	column.material_override = column_material
	column.position = Vector3(0, 0.1, 0)
	add_child(column)

	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)

	_node = ElectricNode.new()
	_node.name = "RelayNode"
	_node.node_id = relay_id
	_node.kind = ElectricNode.Kind.RELAY
	_node.conductivity = 1.0
	_node.port_offsets = [port_a, port_b]
	_node.port_reach = port_reach
	_pivot.add_child(_node)

	# §15.7 : « ports visibles ». Les bras SONT les ports — même position,
	# même rotation. Rien à deviner.
	for i: int in range(2):
		var offset: Vector3 = port_a if i == 0 else port_b
		var arm: MeshInstance3D = MeshInstance3D.new()
		arm.name = "Arm%d" % i
		var arm_box: BoxMesh = BoxMesh.new()
		arm_box.size = Vector3(absf(offset.x) * 2.0 + 0.2, 0.18,
			absf(offset.z) * 2.0 + 0.2)
		arm.mesh = arm_box
		var arm_material: StandardMaterial3D = StandardMaterial3D.new()
		arm_material.albedo_color = COL_COPPER
		arm.material_override = arm_material
		arm.position = offset * 0.5
		_pivot.add_child(arm)
	# La présentation du nœud teinte les bras : un relais alimenté est cyan.
	var visual: ElectricVisual = ElectricVisual.new()
	visual.name = "Visual"
	visual.node_path = NodePath("../RelayNode")
	visual.mesh_path = NodePath("../Arm0")
	_pivot.add_child(visual)
	var visual_b: ElectricVisual = ElectricVisual.new()
	visual_b.name = "VisualB"
	visual_b.node_path = NodePath("../RelayNode")
	visual_b.mesh_path = NodePath("../Arm1")
	_pivot.add_child(visual_b)


func prompt_verb() -> String:
	return verb


func interact(_player: PlayerController) -> bool:
	if _turning > 0.0:
		return false   # une rotation à la fois : le geste reste lisible
	turn_one_step()
	return true


func turn_one_step() -> void:
	_from_angle = _pivot.rotation.y
	_step += 1
	_to_angle = deg_to_rad(step_deg * float(_step))
	_turning = turn_time
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_turning -= delta
	var ratio: float = clampf(1.0 - _turning / maxf(0.01, turn_time), 0.0, 1.0)
	_pivot.rotation.y = lerp_angle(_from_angle, _to_angle, ratio)
	if _turning > 0.0:
		return
	_pivot.rotation.y = _to_angle
	set_physics_process(false)
	# §15.2 pt. 1-2 : le graphe n'est marqué qu'une fois, à l'arrivée.
	for graph: Node in get_tree().get_nodes_in_group("electric_graphs"):
		(graph as ElectricGraph).mark_dirty()
	turned.emit(step_index())


## Position courante, ramenée dans [0, nombre de pas[.
func step_index() -> int:
	var count: int = int(round(360.0 / maxf(1.0, step_deg)))
	return ((_step % count) + count) % count


func step_count() -> int:
	return int(round(360.0 / maxf(1.0, step_deg)))


## Pose une orientation SANS animation — reset, chargement, et solveur
## automatique de §15.7 qui doit essayer toutes les configurations.
func set_step_index(value: int) -> void:
	_step = value
	_turning = 0.0
	set_physics_process(false)
	if _pivot != null:
		_pivot.rotation.y = deg_to_rad(step_deg * float(_step))


func reset_to_initial() -> void:
	set_step_index(initial_step)


func is_turning() -> bool:
	return _turning > 0.0


func node() -> ElectricNode:
	return _node
