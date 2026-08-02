## Scène de calibration d'assets (ordre de nuit ART-Q0).
##
## Contrôle sur une scène NEUTRE et reproductible : échelle réelle (références
## 1 m / 1,8 m / 2 m), orientation, matériaux, ombres, AABB — et l'état du
## registre : chaque id du CATALOG a son socle ; l'asset résolu s'y monte,
## l'asset MANQUANT est un jalon orange étiqueté (jamais une case invisible).
## `VALLEY_LIGHT=1` bascule l'éclairage vallée (soleil doré) pour juger les
## matériaux dans les deux lumières.
class_name AssetCalibration
extends Node3D

const SLOT_SPACING: float = 2.4


func _ready() -> void:
	_build_stage()
	_build_references()
	var ids: Array[StringName] = AssetRegistry.known_ids()
	ids.sort()
	for i: int in range(ids.size()):
		var x: float = -float(ids.size() - 1) * SLOT_SPACING * 0.5 \
			+ float(i) * SLOT_SPACING
		_build_slot(ids[i], Vector3(x, 0.0, 0.0))


func _build_slot(id: StringName, at: Vector3) -> void:
	var slot: Node3D = Node3D.new()
	slot.name = "Slot_%s" % String(id).replace(".", "_")
	slot.position = at
	add_child(slot)
	var label: Label3D = Label3D.new()
	label.text = String(id)
	label.font_size = 40
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.4, 0)
	slot.add_child(label)
	var packed: PackedScene = AssetRegistry.resolve(id)
	if packed != null:
		var instance: Node = packed.instantiate()
		slot.add_child(instance)
		label.modulate = Color(0.7, 0.95, 0.7)
		return
	# Jalon MANQUANT : orange, honnête, mesurable.
	label.modulate = Color(1.0, 0.65, 0.25)
	var placeholder: MeshInstance3D = MeshInstance3D.new()
	placeholder.name = "MissingPlaceholder"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.6, 1.0, 0.6)
	placeholder.mesh = box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.55, 0.15)
	placeholder.material_override = material
	placeholder.position = Vector3(0, 0.5, 0)
	slot.add_child(placeholder)


## Références d'échelle : cube 1 m, capsule 1,8 m (le joueur), poteau 2 m.
func _build_references() -> void:
	var cube: MeshInstance3D = MeshInstance3D.new()
	cube.name = "ReferenceCube1m"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3.ONE
	cube.mesh = box
	cube.position = Vector3(0, 0.5, 3.0)
	add_child(cube)
	var capsule: MeshInstance3D = MeshInstance3D.new()
	capsule.name = "ReferenceCapsule180"
	var shape: CapsuleMesh = CapsuleMesh.new()
	shape.radius = 0.35
	shape.height = 1.8
	capsule.mesh = shape
	capsule.position = Vector3(1.6, 0.9, 3.0)
	add_child(capsule)
	var pole: MeshInstance3D = MeshInstance3D.new()
	pole.name = "ReferencePole2m"
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = 0.05
	cylinder.bottom_radius = 0.05
	cylinder.height = 2.0
	pole.mesh = cylinder
	pole.position = Vector3(-1.6, 1.0, 3.0)
	add_child(pole)


func _build_stage() -> void:
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	floor_mesh.name = "Floor"
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(80, 50)
	floor_mesh.mesh = plane
	var floor_material: StandardMaterial3D = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.45, 0.45, 0.47)
	floor_mesh.material_override = floor_material
	add_child(floor_mesh)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.shadow_enabled = true
	if OS.get_environment("VALLEY_LIGHT") == "1":
		sun.light_color = Color(1.0, 0.839, 0.541)
		sun.light_energy = 1.25
		sun.rotation_degrees = Vector3(-22, -90, 0)
	else:
		sun.light_color = Color.WHITE
		sun.light_energy = 1.0
		sun.rotation_degrees = Vector3(-45, -30, 0)
	add_child(sun)

	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.35, 0.37, 0.40)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.6, 0.6, 0.62)
	environment.ambient_light_energy = 0.7
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	# Cadrage AUTO : la rangée grandit avec le catalogue — la caméra recule
	# pour la tenir entière (la capture doit montrer TOUS les socles, y
	# compris arches et arbres, pas les sept du centre).
	var row_width: float = float(AssetRegistry.known_ids().size()) * SLOT_SPACING
	var distance: float = maxf(9.5, row_width * 0.62)
	var camera: Camera3D = Camera3D.new()
	camera.position = Vector3(0, 3.2 + distance * 0.22, distance)
	camera.rotation_degrees = Vector3(-14, 0, 0)
	camera.fov = 62
	add_child(camera)
	camera.make_current()
