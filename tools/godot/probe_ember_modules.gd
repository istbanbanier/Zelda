## SONDE TEMPORAIRE R2B.1 (agent C) — inventaire des MODULES du camp braise
## et de leur emprise écran aux caméras de preuve du lieu.
##
## Un « module » a la définition du filet camps
## (tests/world_v2/test_world_v2_r2b_camps.gd `_module_root_of`) : un noeud
## dont `scene_file_path` commence par `res://assets/`.
##
## Emprise écran : boite 2D des huit coins de l'AABB monde du sous-arbre,
## projetee avec la MEME camera que capture_poi_batch (fov vertical, viewport
## 1280x720, KEEP_HEIGHT), puis rognee au cadre.
##
## Usage :
##   godot --headless --path . --script tools/godot/probe_ember_modules.gd
extends SceneTree

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const EMBER_ID: StringName = &"valley.poi.ember_raider_camps.01"
const WIDTH: int = 1280
const HEIGHT: int = 720

const SHOTS: Array = [
	{"name": "approche", "from": Vector3(84.0, 8.0, 110.0),
		"look": Vector3(96.0, 7.0, 120.0), "fov": 60.0},
	{"name": "composition", "from": Vector3(79.0, 12.5, 127.0),
		"look": Vector3(97.5, 6.5, 118.5), "fov": 60.0},
	{"name": "proche", "from": Vector3(92.0, 7.2, 116.0),
		"look": Vector3(98.0, 6.5, 122.0), "fov": 55.0},
	{"name": "guet", "from": Vector3(96.6, 7.8, 119.2),
		"look": Vector3(102.1, 10.0, 125.2), "fov": 60.0},
	{"name": "mi_distance", "from": Vector3(74.0, 6.2, 90.0),
		"look": Vector3(96.0, 7.5, 120.0), "fov": 60.0},
	# Les TROIS plans du lead (evidence/world_v2/v2_3_r2b1/shots_r2b1.json) —
	# ceux qui serviront a l'A/B. Ils approchent par l'EST, la ou les cinq
	# plans R2B approchaient par l'ouest : mesurer aux deux jeux.
	{"name": "L_composition", "from": Vector3(107.0, 13.0, 133.0),
		"look": Vector3(96.0, 7.0, 120.0), "fov": 55.0},
	{"name": "L_proche", "from": Vector3(102.0, 8.4, 127.5),
		"look": Vector3(95.5, 6.6, 119.5), "fov": 55.0},
	{"name": "L_guet", "from": Vector3(104.0, 9.0, 112.0),
		"look": Vector3(95.0, 8.0, 120.0), "fov": 55.0},
]


func _initialize() -> void:
	root.content_scale_size = Vector2i(WIDTH, HEIGHT)
	var world: Node3D = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i: int in range(16):
		await process_frame
	var place: Node3D = null
	for node: Node in root.get_tree().get_nodes_in_group(&"world_v2_places"):
		if node.get_meta(&"place_id", &"") as StringName == EMBER_ID:
			place = node as Node3D
			break
	if place == null:
		print("[braise] LIEU ABSENT")
		quit(1)
		return

	var modules: Array[Node3D] = []
	for node: Node in place.find_children("*", "Node3D", true, false):
		var n3: Node3D = node as Node3D
		if n3 == null:
			continue
		if n3.scene_file_path.begins_with("res://assets/") \
				and _module_root_of(n3.get_parent(), place) == null:
			modules.append(n3)
	var meshes: int = place.find_children("*", "MeshInstance3D", true, false).size()
	var bodies: int = place.find_children("*", "StaticBody3D", true, false).size()
	var tris: int = 0
	for node: Node in place.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh == null:
			continue
		for s: int in range(mi.mesh.get_surface_count()):
			var arrays: Array = mi.mesh.surface_get_arrays(s)
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] \
				if arrays.size() > Mesh.ARRAY_INDEX \
					and arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			if idx.size() > 0:
				tris += idx.size() / 3
			else:
				var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				tris += verts.size() / 3
	print("[braise] modules=%d meshes=%d colliders=%d tris~%d"
		% [modules.size(), meshes, bodies, tris])
	print("[braise] fenetre headless : %s (le cadre de mesure est un SubViewport %dx%d)"
		% [str(root.get_visible_rect().size), WIDTH, HEIGHT])
	print("")

	# CADRE DE PROJECTION : un SubViewport aux dimensions EXACTES de la
	# capture. Defaut mesure au deuxieme run : la fenetre headless fait
	# 64 x 64 — un cadre CARRE, dont le champ horizontal (KEEP_HEIGHT) est
	# bien plus etroit que le 16:9 des captures ; tout ce qui est hors axe
	# en sortait, et les emprises etaient fausses dans les deux sens.
	var frame: SubViewport = SubViewport.new()
	frame.size = Vector2i(WIDTH, HEIGHT)
	root.add_child(frame)
	var cams: Dictionary = {}
	for plan: Dictionary in SHOTS:
		var cam: Camera3D = Camera3D.new()
		frame.add_child(cam)
		cam.fov = float(plan["fov"])
		cam.global_position = plan["from"] as Vector3
		cam.look_at(plan["look"] as Vector3, Vector3.UP)
		cams[plan["name"]] = cam
	await process_frame

	var heightmap: Object = world.call("heightmap")
	for plan: Dictionary in SHOTS:
		var eye: Vector3 = plan["from"] as Vector3
		var sol: float = float(heightmap.call("height_at", eye.x, eye.z))
		print("[oeil] %-16s y=%.2f  sol=%.2f  %s"
			% [plan["name"], eye.y, sol,
				"OK" if eye.y > sol + 0.5 else "SOUS LE TERRAIN"])
	print("[braise] cadre de projection : %s"
		% str((cams[String(SHOTS[0]["name"])] as Camera3D).get_viewport().get_visible_rect().size))
	var header: String = "%-28s %8s %8s %7s" % ["module", "hauteur", "empriseXZ", "tris"]
	for plan: Dictionary in SHOTS:
		header += " %10s" % String(plan["name"]).substr(0, 10)
	print(header)
	var totals: Dictionary = {}
	for m: Node3D in modules:
		var box: AABB = _meshes_bounds(m)
		var mtris: int = _tris_of(m)
		var line: String = "%-28s %8.2f %8.2f %7d" % [String(m.name).substr(0, 28),
			box.size.y, maxf(box.size.x, box.size.z), mtris]
		for plan: Dictionary in SHOTS:
			var cam: Camera3D = cams[plan["name"]] as Camera3D
			var pct: float = _screen_pct(cam, box)
			totals[plan["name"]] = float(totals.get(plan["name"], 0.0)) + pct
			line += " %9.3f%%" % pct
		print(line)
	var foot: String = "%-28s %8s %8s %7s" % ["— somme brute —", "", "", ""]
	for plan: Dictionary in SHOTS:
		foot += " %9.3f%%" % float(totals.get(plan["name"], 0.0))
	print(foot)
	print("RC=0")
	quit(0)


## Emprise ecran en % du cadre : boite 2D des 8 coins projetes, rognee.
## 0.0 si entierement derriere la camera ou hors cadre.
func _screen_pct(cam: Camera3D, box: AABB) -> float:
	if box.size == Vector3.ZERO:
		return 0.0
	# NORMALISER SUR LE RECTANGLE REEL. `unproject_position` rend des pixels
	# du viewport courant (project.godot : 1920x1080), pas de la taille de
	# capture. Diviser par 1280x720 tout en rognant sur 1280x720 ecrasait
	# chaque mesure — defaut mesure au premier run.
	var rect: Vector2 = cam.get_viewport().get_visible_rect().size
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF
	var any_front: bool = false
	for i: int in range(8):
		var corner: Vector3 = box.get_endpoint(i)
		if cam.is_position_behind(corner):
			continue
		any_front = true
		var p: Vector2 = cam.unproject_position(corner)
		min_x = minf(min_x, p.x)
		min_y = minf(min_y, p.y)
		max_x = maxf(max_x, p.x)
		max_y = maxf(max_y, p.y)
	if not any_front:
		return 0.0
	min_x = clampf(min_x, 0.0, rect.x)
	max_x = clampf(max_x, 0.0, rect.x)
	min_y = clampf(min_y, 0.0, rect.y)
	max_y = clampf(max_y, 0.0, rect.y)
	var area: float = maxf(0.0, max_x - min_x) * maxf(0.0, max_y - min_y)
	return area / (rect.x * rect.y) * 100.0


func _module_root_of(node: Node, place: Node3D) -> Node:
	var walker: Node = node
	while walker != null and walker != place:
		if not walker.scene_file_path.is_empty() \
				and walker.scene_file_path.begins_with("res://assets/"):
			return walker
		walker = walker.get_parent()
	return null


func _tris_of(root_node: Node) -> int:
	var total: int = 0
	var targets: Array[Node] = root_node.find_children("*", "MeshInstance3D",
		true, false)
	if root_node is MeshInstance3D:
		targets.append(root_node)
	for node: Node in targets:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh == null:
			continue
		for s: int in range(mi.mesh.get_surface_count()):
			var arrays: Array = mi.mesh.surface_get_arrays(s)
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] \
				if arrays.size() > Mesh.ARRAY_INDEX \
					and arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			if idx.size() > 0:
				total += idx.size() / 3
			else:
				total += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return total


func _meshes_bounds(root_node: Node) -> AABB:
	var merged: AABB = AABB()
	var first: bool = true
	var targets: Array[Node] = root_node.find_children("*", "MeshInstance3D",
		true, false)
	if root_node is MeshInstance3D:
		targets.append(root_node)
	for node: Node in targets:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh == null:
			continue
		var b: AABB = mi.global_transform * mi.mesh.get_aabb()
		if first:
			merged = b
			first = false
		else:
			merged = merged.merge(b)
	return merged
