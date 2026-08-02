## V4 lot 15 — mesures CPU-indicatives du monde (ordre §19). AUCUN FPS :
## llvmpipe n'est jamais une mesure de rendu (CLAUDE.md). Ce script mesure
## ce que le CPU headless mesure honnêtement : temps d'instanciation de la
## vallée, comptes de nœuds/maillages/collisions, matériaux UNIQUES
## réellement référencés (l'effet du cache du lot 15 se lit ici).
##
##   godot --headless --path . --script tools/godot/measure_world_metrics.gd
##
## Sortie : evidence/v4lot15/world_metrics.json (commit, moteur, mesures).
extends SceneTree

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const OUTPUT: String = "evidence/v4lot15/world_metrics.json"


func _initialize() -> void:
	var load_start: int = Time.get_ticks_usec()
	var packed: PackedScene = load(VALLEY) as PackedScene
	var load_us: int = Time.get_ticks_usec() - load_start

	var instantiate_start: int = Time.get_ticks_usec()
	var world: Node = packed.instantiate()
	root.add_child(world)
	var instantiate_us: int = Time.get_ticks_usec() - instantiate_start

	# La vallée achève sa construction sur les premiers ticks (appels
	# différés, spawns) : compter avant serait mesurer la scène statique.
	for i: int in range(10):
		await process_frame

	var nodes: int = 0
	var meshes: int = 0
	var collisions: int = 0
	var lights: int = 0
	var materials: Dictionary = {}
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		nodes += 1
		for child: Node in node.get_children():
			stack.append(child)
		if node is CollisionShape3D:
			collisions += 1
		if node is Light3D:
			lights += 1
		if node is MeshInstance3D:
			meshes += 1
			var mesh_node: MeshInstance3D = node as MeshInstance3D
			if mesh_node.material_override != null:
				materials[mesh_node.material_override.get_instance_id()] = true
			var surface_count: int = mesh_node.mesh.get_surface_count() \
				if mesh_node.mesh != null else 0
			for surface: int in range(surface_count):
				var material: Material = mesh_node.get_active_material(surface)
				if material != null:
					materials[material.get_instance_id()] = true

	var report: Dictionary = {
		"date": Time.get_datetime_string_from_system(),
		"commit": _commit(),
		"engine": Engine.get_version_info()["string"],
		"caveat": "mesures CPU headless : jamais un budget de frame (llvmpipe)",
		"scene": VALLEY,
		"load_ms": load_us / 1000.0,
		"instantiate_ms": instantiate_us / 1000.0,
		"nodes": nodes,
		"mesh_instances": meshes,
		"collision_shapes": collisions,
		"lights": lights,
		"unique_materials": materials.size(),
	}
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT).get_base_dir())
	var handle: FileAccess = FileAccess.open(OUTPUT, FileAccess.WRITE)
	handle.store_string(JSON.stringify(report, "  "))
	handle.close()
	print("[metrics] %s" % JSON.stringify(report))
	quit(0)


func _commit() -> String:
	var output: Array = []
	OS.execute("git", ["rev-parse", "--short", "HEAD"], output)
	return String(output[0]).strip_edges() if not output.is_empty() else "inconnu"
