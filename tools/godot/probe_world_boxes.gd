## SONDE DE BOÎTES ENGLOBANTES — mesurer au lieu de juger à l'œil.
##
## La leçon de la passe d'orientation : une correction posée « parce que ça
## semblait mieux » s'est révélée sur le mauvais axe ; seul le relevé de
## sommets a tranché. Cette sonde monte la vallée réelle, puis rend la boîte
## englobante MONDE de toute pièce dont le nom correspond à un motif, et
## signale celles qui FLOTTENT — dessous à plus de `--float` mètres du sol
## trouvé par rayon vertical sous leur centre.
##
##   godot --headless --path . --script tools/godot/probe_world_boxes.gd -- \
##     --match=Crate --region=-60,-30,60,60 --float=0.4
##
## Options :
##   --match=A,B    motifs de nom (sous-chaîne, sans casse) ; défaut : tout
##   --region=x0,z0,x1,z1  n'examine que ce rectangle monde
##   --float=M      seuil de flottement en mètres (défaut 0.35)
##   --limit=N      nombre maximal de lignes (défaut 120)
extends SceneTree

const WORLD: String = "res://scenes/world/valley/ValleyWorld.tscn"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var patterns: PackedStringArray = PackedStringArray()
	var region: Rect2 = Rect2(-1e6, -1e6, 2e6, 2e6)
	var float_threshold: float = 0.35
	var limit: int = 120
	for arg: String in args:
		if arg.begins_with("--match="):
			patterns = arg.substr(8).to_lower().split(",", false)
		elif arg.begins_with("--region="):
			var v: PackedStringArray = arg.substr(9).split(",", false)
			if v.size() == 4:
				region = Rect2(float(v[0]), float(v[1]),
					float(v[2]) - float(v[0]), float(v[3]) - float(v[1]))
		elif arg.begins_with("--float="):
			float_threshold = float(arg.substr(8))
		elif arg.begins_with("--limit="):
			limit = int(arg.substr(8))

	var scene: PackedScene = load(WORLD) as PackedScene
	var world: Node = scene.instantiate()
	root.add_child(world)
	await process_frame
	await physics_frame
	await physics_frame
	var space: PhysicsDirectSpaceState3D = \
		(world as Node3D).get_world_3d().direct_space_state

	print("=== BOÎTES MONDE  motifs=%s  région=%s  seuil=%.2f ==="
		% [", ".join(patterns), region, float_threshold])
	var shown: int = 0
	var floaters: int = 0
	for node: Node in root.find_children("*", "Node3D", true, false):
		var spatial: Node3D = node as Node3D
		if spatial == null or not spatial.is_inside_tree():
			continue
		if not _matches(spatial.name, patterns):
			continue
		var box: AABB = _world_box(spatial)
		if box.size == Vector3.ZERO:
			continue
		var centre: Vector3 = box.get_center()
		if not region.has_point(Vector2(centre.x, centre.z)):
			continue
		# Une pièce d'un sous-arbre déjà listé (`Model/X`, `X/Mesh`) a la même
		# boîte que son parent : on ne la répète pas.
		if _same_box_as_parent(spatial, box):
			continue
		# Sol sous le centre. Le rayon part LÉGÈREMENT AU-DESSUS du dessous de
		# la boîte : partir en dessous le ferait démarrer À L'INTÉRIEUR de la
		# dalle porteuse, qu'il traverserait alors sans la voir — c'est ce qui
		# a fait passer les caisses du camp (posées sur la terrasse à y = 6)
		# pour des flottantes de 4 m au premier essai.
		var ground: float = NAN
		var query: PhysicsRayQueryParameters3D = \
			PhysicsRayQueryParameters3D.create(
				Vector3(centre.x, box.position.y + 0.40, centre.z),
				Vector3(centre.x, box.position.y - 80.0, centre.z), 1)
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			ground = (hit["position"] as Vector3).y
		var gap: float = (box.position.y - ground) if not is_nan(ground) else NAN
		var flag: String = ""
		if not is_nan(gap) and gap > float_threshold:
			flag = "  <<< FLOTTE de %.2f m" % gap
			floaters += 1
		if shown < limit:
			print("  %-42s  x %7.2f..%7.2f  y %7.2f..%7.2f  z %7.2f..%7.2f  sol %s%s"
				% [_path_tail(spatial), box.position.x, box.end.x,
					box.position.y, box.end.y, box.position.z, box.end.z,
					("%.2f" % ground) if not is_nan(ground) else "aucun", flag])
			shown += 1
	print("--- %d pièce(s) listée(s), %d flottante(s) ---" % [shown, floaters])
	quit(0)


func _matches(node_name: StringName, patterns: PackedStringArray) -> bool:
	if patterns.is_empty():
		return true
	var lower: String = String(node_name).to_lower()
	for pattern: String in patterns:
		if lower.contains(pattern):
			return true
	return false


## Boîte englobante MONDE, réunion de toutes les géométries du sous-arbre.
func _world_box(root_node: Node3D) -> AABB:
	var merged: AABB = AABB()
	var first: bool = true
	for node: Node in root_node.find_children("*", "VisualInstance3D", true, false):
		var visual: VisualInstance3D = node as VisualInstance3D
		if visual == null or not visual.is_inside_tree():
			continue
		if visual is MeshInstance3D and (visual as MeshInstance3D).mesh == null:
			continue
		var box: AABB = visual.global_transform * visual.get_aabb()
		if first:
			merged = box
			first = false
		else:
			merged = merged.merge(box)
	if root_node is VisualInstance3D:
		var self_visual: VisualInstance3D = root_node as VisualInstance3D
		var ok: bool = not (self_visual is MeshInstance3D) \
			or (self_visual as MeshInstance3D).mesh != null
		if ok:
			var own: AABB = self_visual.global_transform * self_visual.get_aabb()
			merged = own if first else merged.merge(own)
	return merged


func _same_box_as_parent(node: Node3D, box: AABB) -> bool:
	var parent: Node3D = node.get_parent() as Node3D
	if parent == null or not parent.is_inside_tree():
		return false
	var up: AABB = _world_box(parent)
	if up.size == Vector3.ZERO:
		return false
	return up.position.distance_to(box.position) < 0.01 \
		and up.size.distance_to(box.size) < 0.01


func _path_tail(node: Node3D) -> String:
	var parent: Node = node.get_parent()
	if parent == null:
		return String(node.name)
	return "%s/%s" % [parent.name, node.name]
