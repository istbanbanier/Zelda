## Prouve la moitié « moteur » du pipeline d'assets (MASTER_SPEC §0.5, §7.15).
##
## `tools/gltf_inspect.py` valide le .glb hors moteur ; ce test vérifie que Godot
## l'importe réellement en ressources utilisables : mesh, matériau, squelette,
## animation — avec la bonne échelle et le bon pivot.
##
## S'exécute entièrement en headless : aucune capacité de rendu n'est requise.
extends RefCounted

const CUBE_PATH: String = "res://assets/environment/props/SM_TestCube.glb"
const RIG_PATH: String = "res://assets/characters/hero/SK_TestRigAnim.glb"
const ANIM_NAME: String = "AN_TestRig_Idle"

var _reporter: Object = null


func set_reporter(reporter: Object) -> void:
	_reporter = reporter


func _assert(condition: bool, message: String) -> void:
	if not condition and _reporter != null:
		_reporter.call("report_failure", message)


func _instantiate(path: String) -> Node:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		_assert(false, "%s: import impossible ou ressource absente" % path)
		return null
	return packed.instantiate()


func _find_first(node: Node, type_name: String) -> Node:
	if node.is_class(type_name):
		return node
	for child: Node in node.get_children():
		var found: Node = _find_first(child, type_name)
		if found != null:
			return found
	return null


func test_static_cube_imports_with_material_and_scale() -> void:
	var root: Node = _instantiate(CUBE_PATH)
	if root == null:
		return

	var mesh_node: MeshInstance3D = _find_first(root, "MeshInstance3D") as MeshInstance3D
	_assert(mesh_node != null, "cube: aucun MeshInstance3D dans la scène importée")
	if mesh_node == null:
		root.free()
		return

	var mesh: Mesh = mesh_node.mesh
	_assert(mesh != null, "cube: MeshInstance3D sans Mesh")
	if mesh != null:
		_assert(mesh.get_surface_count() == 1,
			"cube: %d surface(s), attendu 1" % mesh.get_surface_count())

		# 1 unité = 1 m : le cube doit mesurer 1 m d'arête, base au sol (min Y ~ 0).
		var box: AABB = mesh.get_aabb()
		_assert(absf(box.size.x - 1.0) < 0.01, "cube: largeur %.3f m, attendu 1.0" % box.size.x)
		_assert(absf(box.size.y - 1.0) < 0.01, "cube: hauteur %.3f m, attendu 1.0" % box.size.y)
		_assert(absf(box.size.z - 1.0) < 0.01, "cube: profondeur %.3f m, attendu 1.0" % box.size.z)
		_assert(absf(box.position.y) < 0.01,
			"cube: bas à Y=%.3f, attendu ~0 (base au sol)" % box.position.y)

		var material: Material = mesh.surface_get_material(0)
		if material == null:
			material = mesh_node.get_active_material(0)
		_assert(material != null, "cube: aucun matériau importé — surface rose probable")

	root.free()


func test_rig_imports_with_skeleton_and_animation() -> void:
	var root: Node = _instantiate(RIG_PATH)
	if root == null:
		return

	var skeleton: Skeleton3D = _find_first(root, "Skeleton3D") as Skeleton3D
	_assert(skeleton != null, "rig: aucun Skeleton3D importé")
	if skeleton != null:
		_assert(skeleton.get_bone_count() == 2,
			"rig: %d os, attendu 2" % skeleton.get_bone_count())
		var bone_names: Array[String] = []
		for i: int in range(skeleton.get_bone_count()):
			bone_names.append(skeleton.get_bone_name(i))
		_assert(bone_names.has("bone_root"), "rig: os 'bone_root' absent (obtenus: %s)" % bone_names)
		_assert(bone_names.has("bone_upper"), "rig: os 'bone_upper' absent (obtenus: %s)" % bone_names)

	var player: AnimationPlayer = _find_first(root, "AnimationPlayer") as AnimationPlayer
	_assert(player != null, "rig: aucun AnimationPlayer importé")
	if player != null:
		var list: PackedStringArray = player.get_animation_list()
		_assert(list.size() >= 1, "rig: aucune animation importée")
		var found: bool = false
		for name: String in list:
			if name.contains(ANIM_NAME):
				found = true
				var anim: Animation = player.get_animation(name)
				_assert(anim.length > 0.0, "rig: animation '%s' de durée nulle" % name)
				_assert(anim.get_track_count() > 0, "rig: animation '%s' sans piste" % name)
		_assert(found, "rig: animation '%s' absente (obtenues: %s)" % [ANIM_NAME, list])

	var mesh_node: MeshInstance3D = _find_first(root, "MeshInstance3D") as MeshInstance3D
	_assert(mesh_node != null, "rig: aucun MeshInstance3D")
	if mesh_node != null and mesh_node.mesh != null:
		var box: AABB = mesh_node.mesh.get_aabb()
		_assert(absf(box.size.y - 2.0) < 0.02, "rig: hauteur %.3f m, attendu 2.0" % box.size.y)

	root.free()


func test_no_pink_missing_resources() -> void:
	## Une ressource manquante rend en magenta. On vérifie plutôt la cause :
	## chaque surface importée possède bien un matériau résolu.
	for path: String in [CUBE_PATH, RIG_PATH]:
		var root: Node = _instantiate(path)
		if root == null:
			continue
		var mesh_node: MeshInstance3D = _find_first(root, "MeshInstance3D") as MeshInstance3D
		if mesh_node != null and mesh_node.mesh != null:
			for surface: int in range(mesh_node.mesh.get_surface_count()):
				var material: Material = mesh_node.mesh.surface_get_material(surface)
				if material == null:
					material = mesh_node.get_active_material(surface)
				_assert(material != null,
					"%s: surface %d sans matériau résolu" % [path, surface])
		root.free()
