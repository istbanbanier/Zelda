## Prouve la moitié « moteur » du pipeline d'assets (MASTER_SPEC §0.5, §7.15).
##
## `tools/gltf_inspect.py` valide le .glb hors moteur ; ce test vérifie que Godot
## l'importe réellement en ressources utilisables : mesh, matériau, squelette,
## animation — avec la bonne échelle et le bon pivot.
##
## S'exécute entièrement en headless : aucune capacité de rendu n'est requise.
extends GateTestCase

const CUBE_PATH: String = "res://assets/environment/props/SM_TestCube.glb"
const RIG_PATH: String = "res://assets/characters/hero/SK_TestRigAnim.glb"
const ANIM_NAME: String = "AN_TestRig_Idle"


func _instantiate(path: String) -> Node:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		check(false, "%s : import impossible ou ressource absente" % path)
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
	check_not_null(mesh_node, "cube : MeshInstance3D dans la scène importée")
	if mesh_node == null:
		root.free()
		return

	var mesh: Mesh = mesh_node.mesh
	check_not_null(mesh, "cube : Mesh du MeshInstance3D")
	if mesh != null:
		check_equal(mesh.get_surface_count(), 1, "cube : nombre de surfaces")

		# 1 unité = 1 m : arête de 1 m, base au sol (min Y ≈ 0).
		var box: AABB = mesh.get_aabb()
		check_approx(box.size.x, 1.0, 0.01, "cube : largeur en m")
		check_approx(box.size.y, 1.0, 0.01, "cube : hauteur en m")
		check_approx(box.size.z, 1.0, 0.01, "cube : profondeur en m")
		check_approx(box.position.y, 0.0, 0.01, "cube : altitude du bas (base au sol)")

		var material: Material = mesh.surface_get_material(0)
		if material == null:
			material = mesh_node.get_active_material(0)
		check_not_null(material, "cube : matériau importé (sinon surface magenta)")

	root.free()


func test_rig_imports_with_skeleton_and_animation() -> void:
	var root: Node = _instantiate(RIG_PATH)
	if root == null:
		return

	var skeleton: Skeleton3D = _find_first(root, "Skeleton3D") as Skeleton3D
	check_not_null(skeleton, "rig : Skeleton3D importé")
	if skeleton != null:
		check_equal(skeleton.get_bone_count(), 2, "rig : nombre d'os")
		var bone_names: Array[String] = []
		for i: int in range(skeleton.get_bone_count()):
			bone_names.append(skeleton.get_bone_name(i))
		# str() est obligatoire : passer un Array directement à `%s` fait échouer
		# le formatage GDScript (« not all arguments converted ») — défaut D4.
		check(bone_names.has("bone_root"),
			"rig : os 'bone_root' absent (obtenus : %s)" % str(bone_names))
		check(bone_names.has("bone_upper"),
			"rig : os 'bone_upper' absent (obtenus : %s)" % str(bone_names))

	var player: AnimationPlayer = _find_first(root, "AnimationPlayer") as AnimationPlayer
	check_not_null(player, "rig : AnimationPlayer importé")
	if player != null:
		var list: PackedStringArray = player.get_animation_list()
		check(list.size() >= 1, "rig : aucune animation importée")
		var found: bool = false
		for anim_name: String in list:
			if anim_name.contains(ANIM_NAME):
				found = true
				var anim: Animation = player.get_animation(anim_name)
				check(anim.length > 0.0, "rig : animation '%s' de durée nulle" % anim_name)
				check(anim.get_track_count() > 0, "rig : animation '%s' sans piste" % anim_name)
		check(found, "rig : animation '%s' absente (obtenues : %s)" % [ANIM_NAME, str(list)])

	var mesh_node: MeshInstance3D = _find_first(root, "MeshInstance3D") as MeshInstance3D
	check_not_null(mesh_node, "rig : MeshInstance3D")
	if mesh_node != null and mesh_node.mesh != null:
		check_approx(mesh_node.mesh.get_aabb().size.y, 2.0, 0.02, "rig : hauteur en m")

	root.free()


func test_no_pink_missing_resources() -> void:
	## Une ressource manquante rend en magenta. On vérifie la cause plutôt que la
	## couleur : chaque surface importée possède bien un matériau résolu.
	for path: String in [CUBE_PATH, RIG_PATH]:
		var root: Node = _instantiate(path)
		if root == null:
			continue
		var mesh_node: MeshInstance3D = _find_first(root, "MeshInstance3D") as MeshInstance3D
		check_not_null(mesh_node, "%s : MeshInstance3D" % path)
		if mesh_node != null and mesh_node.mesh != null:
			for surface: int in range(mesh_node.mesh.get_surface_count()):
				var material: Material = mesh_node.mesh.surface_get_material(surface)
				if material == null:
					material = mesh_node.get_active_material(surface)
				check_not_null(material, "%s : matériau de la surface %d" % [path, surface])
		root.free()
