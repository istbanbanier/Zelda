## Carte de la vallée vue du ciel, rendue par le VRAI moteur.
##
## Pourquoi cet outil : le monde d'Éclats d'Orage est entièrement procédural.
## Il n'existe dans aucun éditeur, aucun plan, aucune image — seulement dans
## 13 000 lignes de GDScript qui le bâtissent au démarrage. Personne ne l'avait
## jamais VU en entier. Cet outil produit la carte manquante : une projection
## orthographique du dessus, à l'échelle, depuis la scène réellement jouée.
##
## Usage :
##   godot --path . --rendering-driver opengl3 \
##       --script tools/godot/capture_world_map.gd -- \
##       --out=evidence/atlas/valley_map.png --size=2048x2048 \
##       --span=520 --height=600 --frames=40
##
## `--span` est le côté couvert en mètres (520 englobe la bordure du monde).
## `--height` est l'altitude de la caméra. Le brouillard est désactivé pour la
## durée du rendu : à 600 m d'altitude il effacerait tout, et une carte blanche
## ne prouve rien.
##
## Écrit un manifeste JSON à côté du PNG, comme `capture_reference.gd` :
## commit, version du moteur, renderer, emprise, altitude. Sans manifeste,
## une image n'est pas une preuve (règle `.claude/rules/evidence.md`).
extends SceneTree

const DEFAULT_SCENE: String = "res://scenes/world/valley/ValleyWorld.tscn"

var _scene_path: String = DEFAULT_SCENE
var _out_path: String = "evidence/atlas/valley_map.png"
var _width: int = 2048
var _height: int = 2048
var _span: float = 520.0
var _altitude: float = 600.0
var _center: Vector3 = Vector3.ZERO
var _frames: int = 40
var _label: String = "carte_vallee"
var _keep_fog: bool = false
## Énergie de la lumière ambiante. Basse (0,12) : les ombres portées révèlent
## le relief — c'est la carte qui dit si le terrain a du modelé ou s'il est plat.
var _ambient: float = 0.55
## Caméra libre : `--from` et `--look` basculent en perspective et permettent
## de photographier n'importe quel point du monde bâti (un hameau, une rive,
## l'entrée du donjon) sans créer une scène de capture par sujet.
var _from: Vector3 = Vector3.INF
var _look: Vector3 = Vector3.ZERO
var _fov: float = 55.0


func _initialize() -> void:
	_parse_args()
	print("[carte] scène    : %s" % _scene_path)
	print("[carte] sortie   : %s" % _out_path)
	print("[carte] emprise  : %.0f m de côté, caméra à %.0f m" % [_span, _altitude])
	print("[carte] renderer : %s / %s" % [
		ProjectSettings.get_setting("rendering/renderer/rendering_method", "?"),
		RenderingServer.get_video_adapter_name(),
	])
	_capture()


func _parse_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			_scene_path = arg.trim_prefix("--scene=")
		elif arg.begins_with("--out="):
			_out_path = arg.trim_prefix("--out=")
		elif arg.begins_with("--span="):
			_span = maxf(10.0, arg.trim_prefix("--span=").to_float())
		elif arg.begins_with("--height="):
			_altitude = maxf(10.0, arg.trim_prefix("--height=").to_float())
		elif arg.begins_with("--frames="):
			_frames = maxi(1, arg.trim_prefix("--frames=").to_int())
		elif arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
		elif arg == "--keep-fog":
			_keep_fog = true
		elif arg.begins_with("--from="):
			var fp: PackedStringArray = arg.trim_prefix("--from=").split(",")
			if fp.size() == 3:
				_from = Vector3(fp[0].to_float(), fp[1].to_float(), fp[2].to_float())
		elif arg.begins_with("--look="):
			var lp: PackedStringArray = arg.trim_prefix("--look=").split(",")
			if lp.size() == 3:
				_look = Vector3(lp[0].to_float(), lp[1].to_float(), lp[2].to_float())
		elif arg.begins_with("--fov="):
			_fov = arg.trim_prefix("--fov=").to_float()
		elif arg.begins_with("--ambient="):
			_ambient = maxf(0.0, arg.trim_prefix("--ambient=").to_float())
		elif arg.begins_with("--center="):
			var c: PackedStringArray = arg.trim_prefix("--center=").split(",")
			if c.size() == 2:
				_center = Vector3(c[0].to_float(), 0.0, c[1].to_float())
		elif arg.begins_with("--size="):
			var parts: PackedStringArray = arg.trim_prefix("--size=").split("x")
			if parts.size() == 2:
				_width = parts[0].to_int()
				_height = parts[1].to_int()


## Coupe le brouillard et le ciel pour la durée du rendu. Une carte doit montrer
## le SOL ; l'atmosphère de gameplay la rendrait illisible depuis 600 m.
func _flatten_atmosphere(node: Node) -> void:
	if node is WorldEnvironment:
		var env: Environment = (node as WorldEnvironment).environment
		if env != null:
			env.fog_enabled = false
			env.volumetric_fog_enabled = false
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.08, 0.09, 0.11)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(1.0, 0.98, 0.94)
			env.ambient_light_energy = _ambient
	for child: Node in node.get_children():
		_flatten_atmosphere(child)


## Masque l'interface : le HUD d'un jeu n'a rien à faire sur une carte.
func _hide_interface(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child: Node in node.get_children():
		_hide_interface(child)


func _count_geometry(node: Node) -> int:
	var total: int = 0
	if node is GeometryInstance3D and (node as Node3D).is_visible_in_tree():
		total += 1
	for child: Node in node.get_children():
		total += _count_geometry(child)
	return total


func _capture() -> void:
	var packed: PackedScene = load(_scene_path) as PackedScene
	if packed == null:
		printerr("[carte] ÉCHEC: scène introuvable: %s" % _scene_path)
		quit(1)
		return

	DisplayServer.window_set_size(Vector2i(_width, _height))
	root.content_scale_size = Vector2i(_width, _height)

	var instance: Node = packed.instantiate()
	root.add_child(instance)
	if not instance.is_node_ready():
		await instance.ready

	# Laisser le monde se bâtir : tout est construit dans les `_ready()`.
	for i: int in range(_frames):
		await process_frame

	if not _keep_fog:
		_flatten_atmosphere(instance)
		_flatten_atmosphere(root)
	_hide_interface(instance)

	var geometry: int = _count_geometry(instance)
	print("[carte] géométrie : %d instances visibles" % geometry)
	if geometry < 50:
		printerr("[carte] ÉCHEC: %d géométries seulement — le monde ne s'est pas bâti."
			% geometry)
		quit(5)
		return

	var camera: Camera3D = Camera3D.new()
	camera.name = "AtlasCamera"
	camera.near = 0.2
	camera.far = _altitude + 1400.0
	if _from == Vector3.INF:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = _span
		camera.near = 1.0
		camera.position = Vector3(_center.x, _altitude, _center.z)
		camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	else:
		camera.fov = _fov
		camera.position = _from
	instance.add_child(camera)
	if _from != Vector3.INF:
		# `look_at` exige d'être dans l'arbre : la caméra vient d'y entrer.
		camera.look_at(_look, Vector3.UP)
	camera.make_current()

	for i: int in range(12):
		await process_frame

	var image: Image = root.get_texture().get_image()
	if image == null:
		printerr("[carte] ÉCHEC: aucun rendu produit.")
		quit(2)
		return

	var dir: String = _out_path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var err: Error = image.save_png(_out_path)
	if err != OK:
		printerr("[carte] ÉCHEC: écriture impossible (%d): %s" % [err, _out_path])
		quit(3)
		return

	var manifest: Dictionary = {
		"label": _label,
		"scene": _scene_path,
		"image": _out_path,
		"engine": Engine.get_version_info()["string"],
		"renderer": ProjectSettings.get_setting(
			"rendering/renderer/rendering_method", "?"),
		"adapter": RenderingServer.get_video_adapter_name(),
		"size": "%dx%d" % [_width, _height],
		"span_m": _span,
		"altitude_m": _altitude,
		"center": "%.1f,%.1f" % [_center.x, _center.z],
		"metres_per_pixel": _span / float(_width),
		"geometry_instances": geometry,
		"fog": "désactivé" if not _keep_fog else "conservé",
	}
	var json_path: String = _out_path.get_basename() + ".json"
	var file: FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "  "))
		file.close()

	print("[carte] OK : %s (%.2f m/pixel)" % [_out_path, _span / float(_width)])
	quit(0)
