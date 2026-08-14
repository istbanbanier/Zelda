## Métriques GÉOMÉTRIQUES des lieux V2.3 — preuve §7, jamais une mesure
## de performance (llvmpipe ne mesure rien).
##
## Usage :
##   godot --headless --path . --script tools/godot/probe_place_metrics.gd
##
## Pour chaque lieu du groupe `world_v2_places` : maillages visibles,
## corps de collision, points de support déclarés, emprise (AABB) et
## budget du contrat (docs/WORLD_V2_POI_CONTRACTS.md §4).
extends SceneTree

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"


func _initialize() -> void:
	var world: Node3D = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i: int in range(12):
		await process_frame
	print("%-38s %6s %6s %6s %22s" % ["lieu", "mesh", "colls", "appuis", "emprise (m)"])
	var total_meshes: int = 0
	var total_bodies: int = 0
	for node: Node in root.get_tree().get_nodes_in_group(&"world_v2_places"):
		var place: Node3D = node as Node3D
		var meshes: int = place.find_children("*", "MeshInstance3D", true, false).size()
		var bodies: int = place.find_children("*", "StaticBody3D", true, false).size()
		var supports: int = 0
		var supports_meta: Variant = place.get_meta(&"support_points", null)
		if supports_meta is PackedVector3Array:
			supports = (supports_meta as PackedVector3Array).size()
		var bounds: AABB = _visual_bounds(place)
		total_meshes += meshes
		total_bodies += bodies
		print("%-38s %6d %6d %6d %10.1f x %4.1f x %5.1f"
			% [String(place.get_meta(&"place_id", &"?")), meshes, bodies,
				supports, bounds.size.x, bounds.size.y, bounds.size.z])
	print("%-38s %6d %6d" % ["TOTAL", total_meshes, total_bodies])
	quit(0)


func _visual_bounds(place: Node3D) -> AABB:
	var merged: AABB = AABB()
	var first: bool = true
	for mesh_node: Node in place.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = mesh_node as MeshInstance3D
		if instance.mesh == null:
			continue
		var box: AABB = instance.global_transform * instance.mesh.get_aabb()
		if first:
			merged = box
			first = false
		else:
			merged = merged.merge(box)
	return merged
