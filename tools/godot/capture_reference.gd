## Capture déterministe depuis le renderer réel (MASTER_SPEC §21.5, §21.8).
##
## Usage :
##   godot --path . --rendering-driver opengl3 \
##       --script tools/godot/capture_reference.gd -- \
##       --scene=res://scenes/boot/Boot.tscn --out=evidence/captures/boot.png \
##       --size=2560x1440 --frames=30 --label=phase0_smoke
##
## Écrit aussi un manifeste JSON à côté du PNG : commit, version du moteur,
## renderer, résolution, nombre de frames, scène et horodatage — sans quoi une
## capture n'est pas reproductible et ne vaut pas comme preuve.
##
## INTERDIT : présenter une image produite hors de ce chemin comme une capture
## du moteur. Si le rendu échoue, ce script sort en code non nul ; ne pas
## contourner en fournissant une image d'une autre origine.
extends SceneTree

const DEFAULT_FRAMES: int = 30

var _scene_path: String = "res://scenes/boot/Boot.tscn"
var _out_path: String = "evidence/captures/capture.png"
var _width: int = 2560
var _height: int = 1440
var _frames: int = DEFAULT_FRAMES
var _label: String = "unlabeled"


func _initialize() -> void:
	_parse_args()
	print("[capture] scène    : %s" % _scene_path)
	print("[capture] sortie   : %s" % _out_path)
	print("[capture] taille   : %dx%d, frames=%d" % [_width, _height, _frames])
	print("[capture] renderer : %s / %s" % [
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
		elif arg.begins_with("--frames="):
			_frames = maxi(1, arg.trim_prefix("--frames=").to_int())
		elif arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
		elif arg.begins_with("--size="):
			var parts: PackedStringArray = arg.trim_prefix("--size=").split("x")
			if parts.size() == 2:
				_width = parts[0].to_int()
				_height = parts[1].to_int()


func _capture() -> void:
	var packed: PackedScene = load(_scene_path) as PackedScene
	if packed == null:
		printerr("[capture] ÉCHEC: scène introuvable ou illisible: %s" % _scene_path)
		quit(1)
		return

	DisplayServer.window_set_size(Vector2i(_width, _height))
	root.content_scale_size = Vector2i(_width, _height)

	var instance: Node = packed.instantiate()
	root.add_child(instance)

	# Laisser passer des frames réelles : chargement, compilation de shaders et
	# stabilisation temporelle. Une capture à la frame 0 ne prouve rien.
	for i: int in range(_frames):
		await process_frame

	var image: Image = root.get_texture().get_image()
	if image == null:
		printerr("[capture] ÉCHEC: viewport sans image — aucun rendu produit.")
		quit(2)
		return

	var abs_out: String = ProjectSettings.globalize_path("res://").path_join(_out_path)
	DirAccess.make_dir_recursive_absolute(abs_out.get_base_dir())
	var err: Error = image.save_png(abs_out)
	if err != OK:
		printerr("[capture] ÉCHEC: écriture PNG impossible (%d) vers %s" % [err, abs_out])
		quit(3)
		return

	_write_manifest(abs_out, image)
	print("[capture] OK -> %s (%dx%d)" % [abs_out, image.get_width(), image.get_height()])
	quit(0)


func _write_manifest(png_abs: String, image: Image) -> void:
	var manifest: Dictionary = {
		"label": _label,
		"scene": _scene_path,
		"png": _out_path,
		"width": image.get_width(),
		"height": image.get_height(),
		"frames_waited": _frames,
		"engine_version": Engine.get_version_info().get("string", "?"),
		"rendering_method": ProjectSettings.get_setting("rendering/renderer/rendering_method", "?"),
		"rendering_driver": RenderingServer.get_video_adapter_name(),
		"display_server": DisplayServer.get_name(),
		"timestamp_utc": Time.get_datetime_string_from_system(true, true),
	}
	var f: FileAccess = FileAccess.open(png_abs.get_basename() + ".json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(manifest, "  "))
		f.close()
