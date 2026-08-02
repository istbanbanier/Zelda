## Interrupteur qui REDIRIGE le courant (MASTER_SPEC §15.1 `SwitchNode`,
## §15.6 : « interrupteur supérieur redirige le courant »).
##
## Rediriger n'est pas allumer : le levier ferme une branche ET en ouvre
## une autre, dans le même geste. Il pilote donc DEUX ensembles de nœuds
## `SWITCH` réels, posés dans les branches concernées — la redirection est
## une propriété du graphe, jamais un booléen de salle (§26 : « graphe
## générique, pas booléens de salle »).
class_name ElectricSwitch
extends StaticBody3D

signal flipped(state: bool)

const COL_BRONZE: Color = Color(0.42, 0.30, 0.18)
const COL_IVORY: Color = Color(0.90, 0.87, 0.78)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)

@export var verb: String = "Basculer"
## Nœuds `SWITCH` qui CONDUISENT quand le levier est basculé.
@export var closes_paths: Array[NodePath] = []
## Nœuds `SWITCH` qui COUPENT quand le levier est basculé.
@export var opens_paths: Array[NodePath] = []
## Le levier peut-il revenir en arrière ? Un aiguillage d'énigme reste
## rejouable ; un verrou de progression, non.
@export var reversible: bool = true

var _state: bool = false
var _lever: MeshInstance3D = null
var _lever_material: StandardMaterial3D = null


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 0
	if find_children("*", "CollisionShape3D", false, false).is_empty():
		_build()
	# L'état a pu être appliqué AVANT `_ready` (§19.4 : l'ordre entre
	# chargement et `_ready` est indifférent) : on le RELIT sur le graphe.
	_state = _read_state_from_nodes()
	_apply(false)


func _build() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.9, 1.3, 0.9)
	shape.shape = box
	add_child(shape)
	var socle: MeshInstance3D = MeshInstance3D.new()
	socle.name = "Socle"
	var socle_box: BoxMesh = BoxMesh.new()
	socle_box.size = Vector3(0.9, 1.3, 0.9)
	socle.mesh = socle_box
	var socle_material: StandardMaterial3D = StandardMaterial3D.new()
	socle_material.albedo_color = COL_BRONZE
	socle.material_override = socle_material
	add_child(socle)
	_lever = MeshInstance3D.new()
	_lever.name = "Lever"
	var lever_box: BoxMesh = BoxMesh.new()
	lever_box.size = Vector3(0.16, 0.9, 0.16)
	_lever.mesh = lever_box
	_lever_material = StandardMaterial3D.new()
	_lever_material.albedo_color = COL_IVORY
	_lever.material_override = _lever_material
	_lever.position = Vector3(0, 1.05, 0)
	add_child(_lever)


func prompt_verb() -> String:
	return verb if reversible or not _state else ""


func interact(_player: PlayerController) -> bool:
	if _state and not reversible:
		return false
	_state = not _state
	_apply(true)
	flipped.emit(_state)
	return true


func is_flipped() -> bool:
	return _state


## Force l'état sans interaction — restauration d'une sauvegarde.
func set_flipped(value: bool) -> void:
	_state = value
	_apply(true)


func _apply(mark_graph: bool) -> void:
	for path: NodePath in closes_paths:
		var node: ElectricNode = get_node_or_null(path) as ElectricNode
		if node != null:
			node.enabled = _state
	for path: NodePath in opens_paths:
		var node: ElectricNode = get_node_or_null(path) as ElectricNode
		if node != null:
			node.enabled = not _state
	if _lever != null:
		# Le levier BOUGE : §15.4, « chaque activation associe mouvement
		# mécanique, son et lumière ».
		_lever.rotation.z = deg_to_rad(38.0 if _state else -38.0)
		_lever_material.albedo_color = COL_CYAN if _state else COL_IVORY
		_lever_material.emission_enabled = _state
		_lever_material.emission = COL_CYAN
		_lever_material.emission_energy_multiplier = 2.2 if _state else 0.0
	if not mark_graph:
		return
	for graph: Node in get_tree().get_nodes_in_group("electric_graphs"):
		(graph as ElectricGraph).mark_dirty()


## L'état vrai du levier est celui des nœuds qu'il commande — jamais une
## copie qui pourrait diverger de la sauvegarde.
func _read_state_from_nodes() -> bool:
	for path: NodePath in closes_paths:
		var node: ElectricNode = get_node_or_null(path) as ElectricNode
		if node != null:
			return node.enabled
	return _state
