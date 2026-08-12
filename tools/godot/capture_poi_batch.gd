## Capture EN SÉRIE des lieux de la vallée, monde monté UNE SEULE FOIS.
##
## Pourquoi : la preuve finale de la finition monde exige une capture par
## POI (31), plus les vues générales — relancer Godot et rebâtir la vallée
## par cliché coûterait ~45 s × 36. Ce script charge la scène une fois,
## déplace une caméra de plan en plan, et écrit un PNG + une ligne de
## manifeste par plan.
##
## Usage :
##   xvfb-run -a --server-args="-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --script tools/godot/capture_poi_batch.gd -- \
##     --shots=<shots.json> --out-dir=evidence/.../poi --size=1280x720
##
## `shots.json` : [{"name": "...", "from": [x,y,z], "look": [x,y,z],
##                  "fov": 60.0}, …]
## Le brouillard et l'exposition du JEU sont conservés : la preuve montre le
## rendu réel, pas une version aplatie. Le manifeste porte commit et
## `repo_dirty` — une capture d'arbre sale ne prouve rien (evidence.md).
extends SceneTree

const DEFAULT_SCENE: String = "res://scenes/world/valley/ValleyWorld.tscn"

var _scene_path: String = DEFAULT_SCENE
var _shots_path: String = ""
var _out_dir: String = "evidence/poi_batch"
var _width: int = 1280
var _height: int = 720
var _build_frames: int = 45
var _settle_frames: int = 10


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_path = arg.trim_prefix("--shots=")
		elif arg.begins_with("--out-dir="):
			_out_dir = arg.trim_prefix("--out-dir=")
		elif arg.begins_with("--scene="):
			_scene_path = arg.trim_prefix("--scene=")
		elif arg.begins_with("--build-frames="):
			_build_frames = maxi(1, arg.trim_prefix("--build-frames=").to_int())
		elif arg.begins_with("--size="):
			var parts: PackedStringArray = arg.trim_prefix("--size=").split("x")
			if parts.size() == 2:
				_width = parts[0].to_int()
				_height = parts[1].to_int()
	if _shots_path.is_empty():
		printerr("[poi] BLOQUÉ : --shots=<json> requis")
		quit(3)
		return
	_run()


func _run() -> void:
	var file: FileAccess = FileAccess.open(_shots_path, FileAccess.READ)
	if file == null:
		printerr("[poi] BLOQUÉ : plan illisible : %s" % _shots_path)
		quit(3)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Array):
		printerr("[poi] BLOQUÉ : JSON invalide")
		quit(3)
		return
	var shots: Array = parsed as Array

	DisplayServer.window_set_size(Vector2i(_width, _height))
	root.content_scale_size = Vector2i(_width, _height)
	var packed: PackedScene = load(_scene_path) as PackedScene
	if packed == null:
		printerr("[poi] ÉCHEC : scène introuvable : %s" % _scene_path)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	if not world.is_node_ready():
		await world.ready
	for i: int in range(_build_frames):
		await process_frame
	_hide_interface(root)

	var camera: Camera3D = Camera3D.new()
	camera.name = "PoiBatchCamera"
	camera.near = 0.2
	camera.far = 1600.0
	world.add_child(camera)

	if not DirAccess.dir_exists_absolute(_out_dir):
		DirAccess.make_dir_recursive_absolute(_out_dir)
	var manifest: Array = []
	for shot: Variant in shots:
		var plan: Dictionary = shot as Dictionary
		var shot_name: String = String(plan.get("name", "plan"))
		var from_a: Array = plan.get("from", [0, 10, 0]) as Array
		var look_a: Array = plan.get("look", [0, 0, 0]) as Array
		camera.fov = float(plan.get("fov", 60.0))
		camera.position = Vector3(float(from_a[0]), float(from_a[1]),
			float(from_a[2]))
		camera.look_at(Vector3(float(look_a[0]), float(look_a[1]),
			float(look_a[2])), Vector3.UP)
		camera.make_current()
		for i: int in range(_settle_frames):
			await process_frame
		var image: Image = root.get_texture().get_image()
		if image == null:
			printerr("[poi] ÉCHEC : rendu nul sur %s" % shot_name)
			quit(2)
			return
		var path: String = "%s/%s.png" % [_out_dir, shot_name]
		if image.save_png(path) != OK:
			printerr("[poi] ÉCHEC : écriture %s" % path)
			quit(2)
			return
		print("[poi] %s" % path)
		manifest.append({"name": shot_name, "image": path,
			"from": from_a, "look": look_a, "fov": camera.fov})

	var meta: Dictionary = {
		"scene": _scene_path,
		"engine": Engine.get_version_info()["string"],
		"renderer": ProjectSettings.get_setting(
			"rendering/renderer/rendering_method", "?"),
		"adapter": RenderingServer.get_video_adapter_name(),
		"size": "%dx%d" % [_width, _height],
		"commit": _current_commit(),
		"repo_dirty": _repo_is_dirty(),
		"shots": manifest,
	}
	var out: FileAccess = FileAccess.open("%s/manifest.json" % _out_dir,
		FileAccess.WRITE)
	if out != null:
		out.store_string(JSON.stringify(meta, "  "))
		out.close()
	print("[poi] OK : %d plans" % manifest.size())
	quit(0)


func _hide_interface(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child: Node in node.get_children():
		_hide_interface(child)


func _current_commit() -> String:
	var out: Array = []
	var rc: int = OS.execute("git", ["-C",
		ProjectSettings.globalize_path("res://"), "rev-parse", "HEAD"],
		out, true)
	if rc != 0 or out.is_empty():
		return "inconnu"
	return String(out[0]).strip_edges()


## « Sale » = des fichiers SUIVIS diffèrent du commit ; `evidence/` est la
## sortie de cet outil, jamais son entrée (même règle que capture_world_map).
func _repo_is_dirty() -> bool:
	var out: Array = []
	var rc: int = OS.execute("git", ["-C",
		ProjectSettings.globalize_path("res://"), "status", "--porcelain",
		"--untracked-files=no"], out, true)
	if rc != 0 or out.is_empty():
		return rc != 0
	for line: String in String(out[0]).split("\n", false):
		var entry: String = line.strip_edges()
		if entry == "":
			continue
		if entry.substr(2).strip_edges().begins_with("evidence/"):
			continue
		return true
	return false
