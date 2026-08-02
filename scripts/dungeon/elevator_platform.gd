## Ascenseur du puits (MASTER_SPEC §15.6, §14.1).
##
## `AnimatableBody3D` — §14.1 : « pour portes/plateformes pilotées ». Il
## est déplacé au tick PHYSIQUE, jamais depuis `_process`, et `sync_to_
## physics` fait que le personnage posé dessus est emporté correctement.
##
## §15.6 : « l'ascenseur ne peut écraser ou coincer le joueur ». Deux
## garde-corps, pas un :
##   - une zone au-dessus et une en dessous ; un corps détecté DANS LE
##     SENS DE LA MARCHE arrête la plateforme, qui repart quand la voie
##     est libre ;
##   - la course est bornée : ni traversée du sol, ni écrasement contre
##     le plafond.
##
## Sans courant, il ne bouge pas du tout — c'est l'état initial de §15.6.
class_name ElevatorPlatform
extends AnimatableBody3D

signal arrived(at_top: bool)
## L'ascenseur s'est arrêté parce qu'un corps était sur son chemin.
signal blocked_by_body()

const COL_METAL: Color = Color(0.44, 0.42, 0.40)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)

@export var platform_id: StringName = &""
@export var receiver_path: NodePath
@export var size: Vector3 = Vector3(3.6, 0.4, 3.6)
@export var bottom_y: float = 0.7
@export var top_y: float = 16.3
@export var speed: float = 1.8
## Temps d'arrêt à chaque extrémité — le joueur doit avoir le temps de
## monter ou de descendre sans course.
@export var dwell: float = 2.5

var _receiver: ElectricNode = null
var _going_up: bool = true
var _dwell_timer: float = 0.0
var _guard_up: Area3D = null
var _guard_down: Area3D = null
var _material: StandardMaterial3D = null
var _blocked: bool = false


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1   # World Static : on marche dessus
	collision_mask = 0
	_build()
	_receiver = get_node_or_null(receiver_path) as ElectricNode
	if _receiver != null:
		_receiver.power_changed.connect(_on_power_changed)
	position.y = bottom_y
	set_physics_process(true)


func _build() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "Mesh"
	var mesh_box: BoxMesh = BoxMesh.new()
	mesh_box.size = size
	mesh.mesh = mesh_box
	_material = StandardMaterial3D.new()
	_material.albedo_color = COL_METAL
	_material.roughness = 0.5
	mesh.material_override = _material
	add_child(mesh)
	# La zone HAUTE commence au-dessus de la tête d'un passager : mesuré,
	# une garde collée à la plateforme prend le passager lui-même pour un
	# obstacle et l'ascenseur ne démarre jamais. Elle surveille donc la
	# tranche 1,9-3,9 m au-dessus du plancher — de quoi voir une dalle ou
	# un corps coincé, jamais celui qui voyage debout dessus.
	_guard_up = _make_guard("GuardUp", Vector3(0, size.y * 0.5 + 2.9, 0))
	# La zone BASSE, elle, commence juste sous la plateforme : personne ne
	# voyage là, et c'est exactement là qu'un corps se ferait écraser.
	_guard_down = _make_guard("GuardDown", Vector3(0, -size.y * 0.5 - 1.1, 0))


func _make_guard(guard_name: String, offset: Vector3) -> Area3D:
	var area: Area3D = Area3D.new()
	area.name = guard_name
	area.collision_layer = 0
	area.collision_mask = 2   # Player
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(size.x * 0.96, 2.0, size.z * 0.96)
	shape.shape = box
	area.add_child(shape)
	area.position = offset
	add_child(area)
	return area


func _on_power_changed(powered: bool, _power: float) -> void:
	_material.albedo_color = COL_METAL.lerp(COL_CYAN, 0.35) if powered \
		else COL_METAL
	_material.emission_enabled = powered
	_material.emission = COL_CYAN
	_material.emission_energy_multiplier = 1.2 if powered else 0.0
	if powered:
		_dwell_timer = dwell


func _physics_process(delta: float) -> void:
	if _receiver == null or not _receiver.is_powered():
		return
	if _dwell_timer > 0.0:
		_dwell_timer -= delta
		return
	# Garde anti-écrasement : un corps DANS LE SENS DE LA MARCHE arrête
	# tout. La plateforme ne recule pas sur lui, elle attend.
	var guard: Area3D = _guard_up if _going_up else _guard_down
	var obstructed: bool = not guard.get_overlapping_bodies().is_empty()
	if obstructed:
		if not _blocked:
			_blocked = true
			blocked_by_body.emit()
		return
	_blocked = false
	var target: float = top_y if _going_up else bottom_y
	position.y = move_toward(position.y, target, speed * delta)
	if is_equal_approx(position.y, target):
		_going_up = not _going_up
		_dwell_timer = dwell
		arrived.emit(not _going_up)


func is_running() -> bool:
	return _receiver != null and _receiver.is_powered()


func is_blocked() -> bool:
	return _blocked


func going_up() -> bool:
	return _going_up


## Repose l'ascenseur en bas, à l'arrêt (reset de salle, §15.11).
func reset_to_bottom() -> void:
	position.y = bottom_y
	_going_up = true
	_dwell_timer = dwell
	_blocked = false
