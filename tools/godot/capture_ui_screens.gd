## Capture PNG des écrans UI autonomes (options, victoire) à une résolution
## donnée — la preuve du lot 9 exige « aucun élément hors écran à 720p »,
## et ces panneaux se montent sans lancer une partie.
##
## Usage :
##   xvfb-run -a --server-args="-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --script tools/godot/capture_ui_screens.gd -- \
##     --out-dir=evidence/.../ui --size=1280x720
extends SceneTree

var _out_dir: String = "evidence/ui_screens"
var _width: int = 1280
var _height: int = 720


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):
			_out_dir = arg.trim_prefix("--out-dir=")
		elif arg.begins_with("--size="):
			var parts: PackedStringArray = arg.trim_prefix("--size=").split("x")
			if parts.size() == 2:
				_width = parts[0].to_int()
				_height = parts[1].to_int()
	_run()


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(_width, _height))
	root.content_scale_size = Vector2i(_width, _height)
	if not DirAccess.dir_exists_absolute(_out_dir):
		DirAccess.make_dir_recursive_absolute(_out_dir)
	var suffix: String = "%dp" % _height

	var options: OptionsPanel = OptionsPanel.new()
	root.add_child(options)
	for i: int in range(6):
		await process_frame
	await _shot("ui_options_%s" % suffix)
	print("[ui] options : hauteur de contenu %.0f px (fenêtre %d) — %s"
		% [options.content_height(), _height,
		"TIENT" if options.fits_height(float(_height)) else "DÉBORDE"])
	options.queue_free()
	await process_frame
	await process_frame

	var packed: PackedScene = load("res://scenes/ui/VictoryScreen.tscn") \
		as PackedScene
	if packed != null:
		var victory: Node = packed.instantiate()
		root.add_child(victory)
		for i: int in range(6):
			await process_frame
		await _shot("ui_victoire_%s" % suffix)
		victory.queue_free()
		await process_frame

	quit(0)


func _shot(shot_name: String) -> void:
	var image: Image = root.get_texture().get_image()
	if image == null:
		printerr("[ui] rendu nul : %s" % shot_name)
		return
	var path: String = "%s/%s.png" % [_out_dir, shot_name]
	if image.save_png(path) == OK:
		print("[ui] %s" % path)
