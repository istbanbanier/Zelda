## Sonde de MÉTRIQUES du paysage V2.2/V2.2R — instances et architecture.
##
## Livrable §2 de la directive V2.2R : « métriques d'instances/architecture ».
## Tout vient du monde MONTÉ : les comptes de végétation sortent des plans de
## plantation (métas écrites dans la même boucle que le moteur — le renderer
## factice du headless jette les données MultiMesh, jamais les métas), les
## comptes d'architecture sortent des groupes réels. Aucun chiffre recopié.
##
## Usage :
##   godot --headless --path . --script \
##       tools/godot/probe_world_v2_landscape_metrics.gd > sortie.log
## puis extraire entre === METRICS_BEGIN === et === METRICS_END ===.
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var build_start: int = Time.get_ticks_msec()
	var world: Node3D = (load(WORLD) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	await process_frame
	await physics_frame
	var doc: Dictionary = {
		"montage_ms": Time.get_ticks_msec() - build_start,
		"commit": _commit(),
	}

	# --- Végétation : instances par couche, cellules, colliders.
	var per_layer: Dictionary = {}
	var cells: Dictionary = {}
	var instances_total: int = 0
	for node: Node in get_nodes_in_group(&"world_v2_vegetation"):
		var origins: PackedVector3Array = node.get_meta(&"instance_origins",
			PackedVector3Array()) as PackedVector3Array
		instances_total += origins.size()
		cells[node.get_parent().name] = true
		# Nom d'instance : « veg_c<x>r<z>_<couche> » — la couche est la fin.
		var parts: PackedStringArray = String(node.name).split("_")
		var layer: String = "_".join(parts.slice(2))
		per_layer[layer] = int(per_layer.get(layer, 0)) + origins.size()
	var trunk_colliders: int = 0
	var boulder_colliders: int = 0
	for body: Node in get_nodes_in_group(&"world_v2_vegetation_colliders"):
		if String(body.name).begins_with("trunk"):
			trunk_colliders += 1
		else:
			boulder_colliders += 1
	doc["vegetation"] = {
		"instances_total": instances_total,
		"cellules": cells.size(),
		"multimesh_noeuds": get_nodes_in_group(&"world_v2_vegetation").size(),
		"par_couche": per_layer,
		"colliders_troncs": trunk_colliders,
		"colliders_rochers": boulder_colliders,
	}

	# --- Architecture du paysage : frontières, atmosphère, eau.
	var guards: int = get_nodes_in_group(&"world_v2_border_guards").size()
	var far_peaks: int = 0
	var far: Node = world.get_node_or_null("TerrainChunks/FarSilhouettes")
	if far != null:
		far_peaks = far.get_child_count()
	var storm: Node = world.get_node_or_null("Lighting/StormCloud")
	var storm_parts: int = storm.get_child_count() if storm != null else 0
	var water_quads: Dictionary = {}
	for ribbon_name: String in ["MainCourseWater", "TributaryWater", "StormLakeWater"]:
		var instance: MeshInstance3D = world.get_node_or_null(
			"Water/" + ribbon_name) as MeshInstance3D
		if instance != null and instance.mesh != null:
			var arrays: Array = instance.mesh.surface_get_arrays(0)
			water_quads[ribbon_name] = \
				(arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 6
	doc["architecture"] = {
		"gardes_frontiere": guards,
		"pics_lointains": far_peaks,
		"elements_orage": storm_parts,
		"quads_eau": water_quads,
		"chunks_terrain": get_nodes_in_group(&"world_v2_terrain").size(),
	}

	# --- Matériaux et shaders réellement montés.
	var shaders: Dictionary = {}
	_collect_shaders(world, shaders)
	doc["shaders_montes"] = shaders.keys()

	print("=== METRICS_BEGIN ===")
	print(JSON.stringify(doc, "  "))
	print("=== METRICS_END ===")
	quit(0)


func _collect_shaders(node: Node, out: Dictionary) -> void:
	if node is GeometryInstance3D:
		var override: Material = (node as GeometryInstance3D).material_override
		if override is ShaderMaterial \
				and (override as ShaderMaterial).shader != null:
			out[(override as ShaderMaterial).shader.resource_path] = true
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mesh: Mesh = (node as MeshInstance3D).mesh
		for s: int in range(mesh.get_surface_count()):
			var material: Material = mesh.surface_get_material(s)
			if material is ShaderMaterial \
					and (material as ShaderMaterial).shader != null:
				out[(material as ShaderMaterial).shader.resource_path] = true
	for child: Node in node.get_children():
		_collect_shaders(child, out)


func _commit() -> String:
	var out: Array = []
	var rc: int = OS.execute("git", ["-C",
		ProjectSettings.globalize_path("res://"), "rev-parse", "HEAD"], out, true)
	if rc != 0 or out.is_empty():
		return "inconnu"
	return String(out[0]).strip_edges()
