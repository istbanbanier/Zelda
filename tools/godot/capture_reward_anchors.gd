## PLANCHE DE CONTRÔLE des 31 récompenses, en UNE passe.
##
## Pourquoi pas `capture_reference.gd` trente et une fois : chaque exécution
## recharge la vallée entière — terrain, 31 lieux, végétation instanciée — et
## recompile les shaders. Mesuré à 3,4 minutes par capture, soit près de deux
## heures pour une planche. La vallée est donc montée UNE fois et la caméra
## se déplace d'un ancrage à l'autre.
##
## Chaque vue est prise depuis le POINT DE STATION du joueur, à hauteur
## d'yeux, tournée vers la récompense : ce qu'on voit est ce que le joueur
## verra. Aucun cadrage choisi ailleurs, qui flatterait la pose.
##
##   xvfb-run -a -s "-screen 0 960x540x24" godot --path . \
##       --rendering-driver opengl3 \
##       --script tools/godot/capture_reward_anchors.gd -- --out=evidence/rewards
##
## Un manifeste JSON accompagne la planche : commit, propreté de l'arbre,
## moteur, renderer, résolution et liste des vues. Sans lui, une image n'est
## pas une preuve.
extends SceneTree

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const EYE: float = 1.55
## Le recul est NUL : la caméra se tient exactement où le joueur se tiendra
## pour interagir. Un recul, même d'un mètre et demi, faisait entrer dans le
## cadre un tronc ou un rocher qui n'est pas entre le joueur et sa récompense —
## et faisait conclure à tort qu'elle était masquée.
const PULL_BACK: float = 0.0
## Frames laissées au renderer avant la première vue : les shaders se
## compilent, la végétation s'instancie.
const WARMUP: int = 40
## Frames par vue, une fois la caméra posée.
const SETTLE: int = 6

var _out_dir: String = "evidence/rewards"
var _width: int = 960
var _height: int = 540


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			_out_dir = argument.substr(6)
		elif argument.begins_with("--size="):
			var parts: PackedStringArray = argument.substr(7).split("x")
			if parts.size() == 2:
				_width = int(parts[0])
				_height = int(parts[1])
	DisplayServer.window_set_size(Vector2i(_width, _height))
	root.content_scale_size = Vector2i(_width, _height)

	var packed: PackedScene = load(VALLEY) as PackedScene
	if packed == null:
		push_error("[planche] vallée introuvable")
		quit(2)
		return
	var world: Node3D = packed.instantiate() as Node3D
	root.add_child(world)

	var camera: Camera3D = Camera3D.new()
	camera.name = "VueAncrage"
	camera.fov = 55.0
	root.add_child(camera)
	camera.current = true

	for i: int in range(WARMUP):
		await process_frame

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://%s" % _out_dir)
		if not _out_dir.begins_with("/") else _out_dir)

	var shots: Array[Dictionary] = []
	var failures: int = 0
	for node: Node in world.find_children("*", "RewardAnchor", true, false):
		var anchor: RewardAnchor = node as RewardAnchor
		var name: String = String(anchor.place_id).replace("valley.poi.", "") \
			.replace(".01", "")
		var stand: Vector3 = anchor.standing_point()
		var back: Vector3 = stand - anchor.global_position
		back.y = 0.0
		if back.length() < 0.05:
			back = Vector3.FORWARD
		var eye: Vector3 = stand + back.normalized() * PULL_BACK \
			+ Vector3(0, EYE, 0)
		if eye.distance_to(anchor.global_position) < 0.4:
			eye = anchor.global_position + back.normalized() * 1.2 \
				+ Vector3(0, EYE, 0)
		camera.global_position = eye
		camera.look_at(anchor.global_position + Vector3(0, 0.45, 0), Vector3.UP)
		for i: int in range(SETTLE):
			await process_frame
		var image: Image = root.get_texture().get_image()
		if image == null:
			push_error("[planche] rendu vide pour %s" % anchor.place_id)
			failures += 1
			continue
		var path: String = "%s/%s.png" % [_out_dir, name]
		var absolute: String = path if path.begins_with("/") \
			else ProjectSettings.globalize_path("res://%s" % path)
		if image.save_png(absolute) != OK:
			push_error("[planche] écriture impossible : %s" % absolute)
			failures += 1
			continue
		shots.append({
			"place": String(anchor.place_id),
			"kind": anchor.kind,
			"png": path,
			"camera": [eye.x, eye.y, eye.z],
			"target": [anchor.global_position.x, anchor.global_position.y,
				anchor.global_position.z],
		})
		print("[planche] %-30s -> %s" % [name, path])

	_write_manifest(shots, failures)
	print("[planche] %d vue(s), %d échec(s)" % [shots.size(), failures])
	quit(1 if failures > 0 or shots.is_empty() else 0)


func _write_manifest(shots: Array[Dictionary], failures: int) -> void:
	var manifest: Dictionary = {
		"label": "reward_anchors",
		"engine": Engine.get_version_info(),
		"renderer": RenderingServer.get_video_adapter_name(),
		"size": [_width, _height],
		"commit": _git("rev-parse HEAD"),
		"repo_dirty": not _git("status --porcelain").is_empty(),
		"generated_utc": Time.get_datetime_string_from_system(true),
		"failures": failures,
		"shots": shots,
	}
	var path: String = ProjectSettings.globalize_path(
		"res://%s/manifest.json" % _out_dir) if not _out_dir.begins_with("/") \
		else "%s/manifest.json" % _out_dir
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[planche] manifeste non écrit : %s" % path)
		return
	file.store_string(JSON.stringify(manifest, "  "))
	file.close()
	print("[planche] manifeste -> %s" % path)


func _git(arguments: String) -> String:
	var output: Array = []
	var parts: PackedStringArray = arguments.split(" ")
	var argv: Array[String] = []
	argv.assign(parts)
	if OS.execute("git", argv, output, true) != 0:
		return ""
	return String(output[0]).strip_edges() if not output.is_empty() else ""
