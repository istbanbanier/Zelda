## Pylône de mise à la terre de l'arène (MASTER_SPEC §16.1, §16.3).
##
## §16.3 est explicite : « les pylônes utilisent le MÊME système
## électrique que le donjon ». Ce n'est donc pas un compteur d'arène :
## c'est un `ElectricNode` relié au rail du sol par un CONTACT RÉEL, et
## commandé par un levier `ElectricSwitch` — les mêmes briques que les
## salles 1 à 4.
##
## Et le contact est réel au sens de §15.3 : « la logique ne doit pas
## s'activer seulement parce que l'objet est PROCHE d'un point invisible ».
## Le mât est télescopique. Dressé, il déploie son sabot de cuivre qui
## descend sur le siège du rail : le port du nœud tombe alors exactement
## dessus. Rétracté, le sabot est relevé de 1,6 m — hors de portée, donc
## hors du circuit. La première version pilotait `enabled` : le graphe
## ignore ce drapeau sur un RELAY, et les quatre pylônes s'allumaient dès
## l'ouverture de la scène. Le test `test_a_raised_pylon_is_powered_by_the
## _ground_rail` l'a montré ; la géométrie a remplacé le drapeau.
##
## Le joueur en dresse DEUX ; à la prochaine décharge du Gardien, l'arc
## part dans la terre au lieu de partir dans le joueur, et le colosse
## s'écroule (§16.3 : « mise à la terre étourdit 5-8 s »).
class_name GroundingPylon
extends Node3D

signal raised_changed(raised: bool)

const COL_STONE: Color = Color(0.34, 0.32, 0.30)
const COL_BRONZE: Color = Color(0.42, 0.30, 0.18)
const COL_COPPER: Color = Color(0.55, 0.36, 0.22)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)

## Hauteur du siège de contact, au niveau du rail de terre.
const SEAT_Y: float = 0.2
## De combien le sabot se relève quand le mât est rétracté. Bien au-delà
## de `node_port_reach` : rétracté, il ne peut PAS toucher par accident.
const LIFT: float = 1.6

@export var pylon_id: StringName = &""
## Hauteur du fût déployé. Un pylône se voit de l'autre bout de l'arène.
@export var height: float = 6.0
## Tolérance du contact sabot/siège (§15.3 : réelle, mais tolérante).
@export var node_port_reach: float = 0.5

var _raised: bool = false
var _node: ElectricNode = null
var _switch: ElectricSwitch = null
var _mast: MeshInstance3D = null
var _shoe: MeshInstance3D = null
var _core: MeshInstance3D = null
var _core_material: StandardMaterial3D = null
var _shoe_material: StandardMaterial3D = null
var _glow: OmniLight3D = null


func _ready() -> void:
	_build()
	_node.power_changed.connect(_on_power_changed)
	_switch.flipped.connect(_on_switch_flipped)
	# Un pylône commence RÉTRACTÉ : son sabot est en l'air.
	_apply_raised(false)


func _build() -> void:
	# Le fourreau : toujours là, c'est lui qu'on voit de loin quand le mât
	# est rentré. Il est solide — le Gardien ne le traverse pas.
	var housing: StaticBody3D = StaticBody3D.new()
	housing.name = "Housing"
	housing.collision_layer = 1
	housing.collision_mask = 0
	housing.add_to_group("unclimbable")
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(1.6, 2.2, 1.6)
	shape.shape = box
	housing.add_child(shape)
	var housing_mesh: MeshInstance3D = MeshInstance3D.new()
	var housing_box: BoxMesh = BoxMesh.new()
	housing_box.size = Vector3(1.6, 2.2, 1.6)
	housing_mesh.mesh = housing_box
	var housing_material: StandardMaterial3D = StandardMaterial3D.new()
	housing_material.albedo_color = COL_STONE
	housing_material.roughness = 0.85
	housing_mesh.material_override = housing_material
	housing.add_child(housing_mesh)
	housing.position = Vector3(0, 1.1, 0)
	add_child(housing)

	# Le mât télescopique : sa hauteur DIT l'état, de loin, sans un mot.
	_mast = MeshInstance3D.new()
	_mast.name = "Mast"
	var mast_box: BoxMesh = BoxMesh.new()
	mast_box.size = Vector3(1.0, height, 1.0)
	_mast.mesh = mast_box
	var mast_material: StandardMaterial3D = StandardMaterial3D.new()
	mast_material.albedo_color = COL_BRONZE
	mast_material.roughness = 0.7
	_mast.material_override = mast_material
	add_child(_mast)

	# Le sabot de cuivre : c'est LUI qui touche le rail, et c'est sur lui
	# que vit le nœud du graphe.
	_shoe = MeshInstance3D.new()
	_shoe.name = "Shoe"
	var shoe_box: BoxMesh = BoxMesh.new()
	shoe_box.size = Vector3(1.1, 0.3, 1.1)
	_shoe.mesh = shoe_box
	_shoe_material = StandardMaterial3D.new()
	_shoe_material.albedo_color = COL_COPPER
	_shoe.material_override = _shoe_material
	add_child(_shoe)

	# Port unique, au centre du nœud : le nœud EST le point de contact
	# (§15.3). Aucun offset invisible à interpréter.
	_node = ElectricNode.new()
	_node.name = "PylonNode"
	_node.node_id = pylon_id
	_node.kind = ElectricNode.Kind.RELAY
	_node.conductivity = 1.0
	_node.port_offsets = []
	_node.port_reach = node_port_reach
	add_child(_node)

	_core = MeshInstance3D.new()
	_core.name = "Core"
	var core_box: BoxMesh = BoxMesh.new()
	core_box.size = Vector3(0.8, 0.8, 0.8)
	_core.mesh = core_box
	_core_material = StandardMaterial3D.new()
	_core_material.albedo_color = COL_BRONZE
	_core.material_override = _core_material
	add_child(_core)

	_glow = OmniLight3D.new()
	_glow.name = "Glow"
	_glow.light_color = COL_CYAN
	_glow.light_energy = 0.0
	_glow.omni_range = 12.0
	add_child(_glow)

	# Le levier au pied : c'est lui qu'on frappe entre deux esquives. Il ne
	# pilote AUCUN `enabled` — il déploie le mât, et la géométrie fait le
	# reste.
	_switch = ElectricSwitch.new()
	_switch.name = "Lever"
	_switch.verb = "Dresser le pylône"
	_switch.reversible = true
	_switch.position = Vector3(0, 0.65, 1.5)
	add_child(_switch)
	_switch.set_flipped(false)


func _on_switch_flipped(state: bool) -> void:
	_apply_raised(state)
	raised_changed.emit(state)


## Déploie ou rétracte. Tout est ici : la géométrie du contact, la
## silhouette du mât, et le recalcul du graphe qui en découle.
func _apply_raised(raised: bool) -> void:
	_raised = raised
	# `lower()` est publique : elle peut arriver avant `_build()` si un
	# appelant réinitialise l'arène très tôt. L'état est alors mémorisé, et
	# `_ready()` le posera sur la géométrie.
	if _mast == null:
		return
	var deployed: float = height if raised else 1.4
	(_mast.mesh as BoxMesh).size = Vector3(1.0, deployed, 1.0)
	_mast.position = Vector3(0, deployed * 0.5, 0)
	var seat: float = SEAT_Y if raised else SEAT_Y + LIFT
	_shoe.position = Vector3(0, seat, 0)
	if _node != null:
		_node.position = Vector3(0, seat, 0)
	_core.position = Vector3(0, deployed + 0.4, 0)
	_glow.position = _core.position
	_shoe_material.albedo_color = COL_COPPER if raised else COL_BRONZE
	for graph: Node in get_tree().get_nodes_in_group("electric_graphs"):
		graph.call("mark_dirty")


func _on_power_changed(powered: bool, _power: float) -> void:
	_core_material.albedo_color = COL_CYAN if powered else COL_BRONZE
	_core_material.emission_enabled = powered
	_core_material.emission = COL_CYAN
	_core_material.emission_energy_multiplier = 3.0 if powered else 0.0
	_shoe_material.emission_enabled = powered
	_shoe_material.emission = COL_CYAN
	_shoe_material.emission_energy_multiplier = 2.0 if powered else 0.0
	_glow.light_energy = 2.8 if powered else 0.0


## Dressé = le mât est déployé, donc son sabot est sur le rail. Ce que le
## Gardien compte pour décider si son arc part dans la terre (§16.3).
func is_raised() -> bool:
	return _raised


## Alimenté = le courant du puits de terre lui parvient VRAIMENT. C'est ce
## que voit le joueur (noyau cyan) ; les deux peuvent différer si le rail
## est coupé, et c'est une information, pas un bug.
func is_powered() -> bool:
	return _node != null and _node.is_powered()


func lever() -> ElectricSwitch:
	return _switch


func node() -> ElectricNode:
	return _node


func mast_height() -> float:
	return (_mast.mesh as BoxMesh).size.y if _mast != null else 0.0


## Remise à zéro entre deux tentatives (§16.6 : retry rapide).
func lower() -> void:
	if _switch != null:
		_switch.set_flipped(false)
	_apply_raised(false)
