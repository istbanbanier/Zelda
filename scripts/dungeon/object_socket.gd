## Socket EXPLICITE (MASTER_SPEC §15.3, §15.8 : « socket explicite »).
##
## §15.3 refuse qu'une logique s'active « parce que l'objet est proche
## d'un point invisible sans retour visuel ». Ce socket est donc une
## chose : un berceau visible, une zone de détection réelle, un objet qui
## se CALE dedans, et un retour lumineux quand il est occupé.
##
## Il n'ajoute aucune règle électrique : une fois l'objet calé, ce sont
## les PORTS qui se touchent — le graphe ne sait rien du socket.
class_name ObjectSocket
extends Node3D

signal loaded(object: CarryableObject)
signal unloaded()

const COL_EMPTY: Color = Color(0.32, 0.30, 0.28)
const COL_FULL: Color = Color(0.55, 0.36, 0.22)

@export var socket_id: StringName = &""
## N'accepte que les objets portant cette étiquette (§15.8 : un socket de
## batterie n'accueille pas une planche).
@export var accepts_tag: StringName = &"battery"
@export var seat_offset: Vector3 = Vector3(0, 0.75, 0)
@export var detect_size: Vector3 = Vector3(1.6, 1.8, 1.6)

var _area: Area3D = null
var _cradle: MeshInstance3D = null
var _material: StandardMaterial3D = null
var _occupant: CarryableObject = null


func _ready() -> void:
	_build()
	set_physics_process(true)


func _build() -> void:
	_cradle = MeshInstance3D.new()
	_cradle.name = "Cradle"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1.2, 0.3, 1.2)
	_cradle.mesh = box
	_material = StandardMaterial3D.new()
	_material.albedo_color = COL_EMPTY
	_cradle.material_override = _material
	_cradle.position = Vector3(0, 0.15, 0)
	add_child(_cradle)
	# Quatre montants : le berceau se lit de loin comme une PLACE à remplir.
	for i: int in range(4):
		var post: MeshInstance3D = MeshInstance3D.new()
		post.name = "Post%d" % i
		var post_box: BoxMesh = BoxMesh.new()
		post_box.size = Vector3(0.14, 0.5, 0.14)
		post.mesh = post_box
		var post_material: StandardMaterial3D = StandardMaterial3D.new()
		post_material.albedo_color = COL_FULL
		post.material_override = post_material
		post.position = Vector3(0.5 if i % 2 == 0 else -0.5, 0.4,
			0.5 if i < 2 else -0.5)
		add_child(post)
	_area = Area3D.new()
	_area.name = "Zone"
	_area.collision_layer = 0
	_area.collision_mask = 128   # Physics Prop
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = detect_size
	shape.shape = box_shape
	shape.position = Vector3(0, detect_size.y * 0.5, 0)
	_area.add_child(shape)
	add_child(_area)


func _physics_process(_delta: float) -> void:
	if _occupant != null:
		# Un objet repris à la main libère le socket.
		if _occupant.is_carried() or not is_instance_valid(_occupant):
			var gone: CarryableObject = _occupant
			_occupant = null
			_material.albedo_color = COL_EMPTY
			if is_instance_valid(gone):
				gone.release_from_seat()
			unloaded.emit()
			_mark_graph()
		return
	for body: Node3D in _area.get_overlapping_bodies():
		var candidate: CarryableObject = body as CarryableObject
		if candidate == null or candidate.is_carried():
			continue
		if candidate.carry_tag != accepts_tag:
			continue
		_seat(candidate)
		return


func _seat(candidate: CarryableObject) -> void:
	_occupant = candidate
	candidate.seat_at(Transform3D(Basis.IDENTITY,
		global_position + seat_offset))
	_material.albedo_color = COL_FULL
	loaded.emit(candidate)
	_mark_graph()


func _mark_graph() -> void:
	for graph: Node in get_tree().get_nodes_in_group("electric_graphs"):
		(graph as ElectricGraph).mark_dirty()


func is_loaded() -> bool:
	return _occupant != null


func occupant() -> CarryableObject:
	return _occupant
