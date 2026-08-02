## Présentation d'un nœud électrique (MASTER_SPEC §15.4) — SÉPARÉE de la
## logique (§15.1 : « représentation visuelle/audio séparée de la
## logique »). Ce script écoute `power_changed` et interpole ; il ne
## décide jamais rien, et le graphe ignore jusqu'à son existence.
##
## Langage visuel de §15.4 :
## - source : pulsation lente ;
## - câble non alimenté : métal sombre ; alimenté : ligne CYAN qui se
##   propage de 0 à 1 — la propagation VISIBLE de §15.5 est ici : chaque
##   nœud attend son rang dans le graphe (`hop_depth`) avant de monter,
##   si bien que le courant PARCOURT le circuit au lieu de l'allumer d'un
##   bloc. La logique, elle, est instantanée : c'est la lumière qui voyage ;
## - isolant : céramique ivoire, qui ne s'allume jamais.
class_name ElectricVisual
extends Node3D

const COL_DARK_METAL: Color = Color(0.24, 0.22, 0.26)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)
const COL_CORE: Color = Color(0.925, 1.0, 1.0)
const COL_IVORY: Color = Color(0.90, 0.87, 0.78)
## Vitesse de remplissage : la ligne cyan met ~0,4 s à parcourir un nœud.
const FILL_SPEED: float = 2.5
## Retard par saut de graphe : à 0,05 s, un circuit de 20 segments
## s'allume en 1 s de bout en bout — visible, jamais poussif.
const HOP_DELAY: float = 0.05

@export var node_path: NodePath = NodePath("..")
## Maillage à teinter. Vide : le premier `MeshInstance3D` du parent.
@export var mesh_path: NodePath
## Un isolant ne s'allume jamais : sa céramique ivoire est sa signature.
@export var insulator: bool = false
## §15.4 : « source : pulsation lente ». Sans effet sur un câble.
@export var pulse: bool = false

var _node: ElectricNode = null
var _fill: float = 0.0
var _target_fill: float = 0.0
var _delay: float = 0.0
var _pulse_phase: float = 0.0
var _mesh: MeshInstance3D = null
var _material: StandardMaterial3D = null


func _ready() -> void:
	_node = get_node_or_null(node_path) as ElectricNode
	_mesh = _find_mesh()
	if _mesh != null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = COL_IVORY if insulator else COL_DARK_METAL
		_material.roughness = 0.55
		_mesh.material_override = _material
	if _node != null:
		_node.power_changed.connect(_on_power_changed)
		_target_fill = 1.0 if _node.is_powered() and not insulator else 0.0
		_fill = _target_fill
	_apply_fill()
	set_process(true)


func _find_mesh() -> MeshInstance3D:
	if mesh_path != NodePath():
		return get_node_or_null(mesh_path) as MeshInstance3D
	var parent: Node = get_parent()
	if parent == null:
		return null
	var found: Array[Node] = parent.find_children("*", "MeshInstance3D",
		true, false)
	return found[0] as MeshInstance3D if not found.is_empty() else null


func _on_power_changed(powered: bool, _power: float) -> void:
	_target_fill = 1.0 if powered and not insulator else 0.0
	# Le rang dans le graphe devient un RETARD : c'est ce qui fait voyager
	# la lumière. Une coupure, elle, est immédiate — un circuit qui
	# s'éteint doit se lire tout de suite.
	var hop: int = _node.hop_depth() if _node != null else 0
	_delay = maxf(0.0, float(hop)) * HOP_DELAY if powered else 0.0


## §15.2 pt. 10 : « interpoler visuel/audio vers la nouvelle valeur ».
## L'état logique bascule d'un coup ; la LUMIÈRE, elle, se propage.
func _process(delta: float) -> void:
	if _material == null:
		return
	if _delay > 0.0:
		_delay -= delta
		return
	if is_equal_approx(_fill, _target_fill):
		if pulse and _fill > 0.0:
			_pulse_phase = fmod(_pulse_phase + delta, TAU)
			_apply_fill()
		return
	_fill = move_toward(_fill, _target_fill, FILL_SPEED * delta)
	_apply_fill()


func _apply_fill() -> void:
	if _material == null:
		return
	var base: Color = COL_IVORY if insulator else COL_DARK_METAL
	_material.albedo_color = base.lerp(COL_CYAN, _fill)
	_material.emission_enabled = _fill > 0.01
	_material.emission = COL_CORE.lerp(COL_CYAN, 0.6)
	# §15.4 : la source respire lentement (0,55 Hz), le câble non.
	var breath: float = 1.0
	if pulse:
		breath = 0.72 + 0.28 * sin(_pulse_phase * 3.4)
	_material.emission_energy_multiplier = 2.2 * _fill * breath


## Seam de test : l'avancement RÉEL de la propagation lumineuse.
func fill_ratio() -> float:
	return _fill


## Le nœud attend-il encore son tour dans la propagation ?
func is_waiting() -> bool:
	return _delay > 0.0
