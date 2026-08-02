## Bouton de réinitialisation d'une salle (MASTER_SPEC §14.3, §15.5,
## §15.11 : « chaque salle : reset »).
##
## Il ne réinitialise QUE ce qui peut se perdre — les objets déplaçables
## et le circuit. Une porte déjà ouverte reste ouverte : le reset sert à
## rejouer une énigme, jamais à retirer un acquis (anti-softlock).
class_name ResetButton
extends StaticBody3D

signal pressed()

const COL_BRONZE: Color = Color(0.42, 0.30, 0.18)
const COL_IVORY: Color = Color(0.90, 0.87, 0.78)

@export var verb: String = "Réinitialiser"

var _press_count: int = 0


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 0
	if find_children("*", "CollisionShape3D", false, false).is_empty():
		_build()


func _build() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.8, 1.1, 0.8)
	shape.shape = box
	add_child(shape)
	var socle: MeshInstance3D = MeshInstance3D.new()
	socle.name = "Socle"
	var socle_box: BoxMesh = BoxMesh.new()
	socle_box.size = Vector3(0.8, 1.1, 0.8)
	socle.mesh = socle_box
	var socle_material: StandardMaterial3D = StandardMaterial3D.new()
	socle_material.albedo_color = COL_BRONZE
	socle.material_override = socle_material
	add_child(socle)
	# Champignon ivoire : la céramique isolante de §15.4 — ce bouton
	# n'appartient PAS au circuit, il le remet en ordre.
	var cap: MeshInstance3D = MeshInstance3D.new()
	cap.name = "Cap"
	var cap_box: BoxMesh = BoxMesh.new()
	cap_box.size = Vector3(0.44, 0.16, 0.44)
	cap.mesh = cap_box
	var cap_material: StandardMaterial3D = StandardMaterial3D.new()
	cap_material.albedo_color = COL_IVORY
	cap.material_override = cap_material
	cap.position = Vector3(0, 0.62, 0)
	add_child(cap)


func prompt_verb() -> String:
	return verb


func interact(_player: PlayerController) -> bool:
	var room: DungeonRoom = _owning_room()
	if room == null:
		return false
	room.reset_room()
	_press_count += 1
	pressed.emit()
	return true


func press_count() -> int:
	return _press_count


func _owning_room() -> DungeonRoom:
	var node: Node = get_parent()
	while node != null:
		if node is DungeonRoom:
			return node as DungeonRoom
		node = node.get_parent()
	return null
