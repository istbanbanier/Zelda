## Anneau de récepteur (MASTER_SPEC §15.4 : « récepteur : anneau qui se
## ferme »). Huit segments s'allument L'UN APRÈS L'AUTRE : la fermeture
## est le signal que le circuit est complet — distinct de la ligne cyan
## qui, elle, court le long des câbles.
##
## Présentation pure : aucune décision, aucune règle de salle. Le
## récepteur logique reste un `ElectricNode` ordinaire.
class_name ReceiverRing
extends Node3D

const COL_DARK: Color = Color(0.26, 0.24, 0.28)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)
const SEGMENTS: int = 8
## Durée de fermeture complète — assez lente pour se lire, assez rapide
## pour ne pas retarder la porte (§15.5 : 0,6-1,2 s de délai APRÈS).
const CLOSE_TIME: float = 0.5

@export var node_path: NodePath = NodePath("..")
@export var radius: float = 0.55

var _node: ElectricNode = null
var _materials: Array[StandardMaterial3D] = []
var _ratio: float = 0.0
var _target: float = 0.0


func _ready() -> void:
	_build()
	_node = get_node_or_null(node_path) as ElectricNode
	if _node != null:
		_node.power_changed.connect(_on_power_changed)
		_target = 1.0 if _node.is_powered() else 0.0
		_ratio = _target
	_apply()
	set_process(true)


func _build() -> void:
	for i: int in range(SEGMENTS):
		var angle: float = TAU * float(i) / float(SEGMENTS)
		var segment: MeshInstance3D = MeshInstance3D.new()
		segment.name = "Segment%d" % i
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.16, 0.34, 0.12)
		segment.mesh = box
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = COL_DARK
		material.roughness = 0.5
		segment.material_override = material
		_materials.append(material)
		segment.position = Vector3(cos(angle) * radius, sin(angle) * radius, 0)
		segment.rotation.z = angle
		add_child(segment)


func _on_power_changed(powered: bool, _power: float) -> void:
	_target = 1.0 if powered else 0.0


func _process(delta: float) -> void:
	if is_equal_approx(_ratio, _target):
		return
	_ratio = move_toward(_ratio, _target, delta / CLOSE_TIME)
	_apply()


func _apply() -> void:
	var lit: float = _ratio * float(SEGMENTS)
	for i: int in range(_materials.size()):
		var on: bool = float(i) < lit
		var material: StandardMaterial3D = _materials[i]
		material.albedo_color = COL_CYAN if on else COL_DARK
		material.emission_enabled = on
		material.emission = COL_CYAN
		material.emission_energy_multiplier = 2.4 if on else 0.0


## Seam de test : 0 = anneau ouvert, 1 = anneau fermé.
func closed_ratio() -> float:
	return _ratio


func lit_segments() -> int:
	var count: int = 0
	for material: StandardMaterial3D in _materials:
		if material.emission_enabled:
			count += 1
	return count
