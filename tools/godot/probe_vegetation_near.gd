## Sonde : que pose la VÉGÉTATION GELÉE (V2.2) autour d'un point ?
##
## Née d'une question qu'aucune capture ne tranche : le lead a écrit
## « l'arbre noir entouré de fleurs jaunes ». Ces fleurs viennent-elles du
## lieu (que je peux retirer) ou du semis de la prairie (gelé, intouchable) ?
## Répondre à l'œil sur une image, c'est deviner. On compte les instances.
##
## Usage :
##   godot --headless --path . --script tools/godot/probe_vegetation_near.gd \
##     -- --center=-92,132 --radius=8
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"


func _initialize() -> void:
	var center: Vector2 = Vector2.ZERO
	var radius: float = 8.0
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--center="):
			var parts: PackedStringArray = argument.substr(9).split(",")
			center = Vector2(float(parts[0]), float(parts[1]))
		elif argument.begins_with("--radius="):
			radius = float(argument.substr(9))
	var world: Node = (load(WORLD) as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	print("centre=(%.1f, %.1f) rayon=%.1f m" % [center.x, center.y, radius])
	var counts: Dictionary = {}
	_walk(world, center, radius, counts)
	var names: Array = counts.keys()
	names.sort()
	var total: int = 0
	for key: Variant in names:
		var n: int = int(counts[key])
		total += n
		print("  %-44s %d" % [String(key), n])
	print("TOTAL instances de végétation dans le rayon : %d" % total)
	quit(0)


func _walk(node: Node, center: Vector2, radius: float, counts: Dictionary) -> void:
	var multi: MultiMeshInstance3D = node as MultiMeshInstance3D
	if multi != null and multi.multimesh != null:
		var origin: Transform3D = multi.global_transform
		for i: int in range(multi.multimesh.instance_count):
			var point: Vector3 = (origin * multi.multimesh.get_instance_transform(i)).origin
			if Vector2(point.x, point.z).distance_to(center) <= radius:
				var key: String = multi.name
				counts[key] = int(counts.get(key, 0)) + 1
	for child: Node in node.get_children():
		_walk(child, center, radius, counts)
