## ART-P0 — rend l'icône d'inventaire depuis le VRAI modèle (jamais dessinée
## arbitrairement). Fond transparent, cadrage orthographique diagonal.
##
## Usage :
##   xvfb-run godot --path . --rendering-driver opengl3 \
##       --script tools/godot/render_weapon_icon.gd -- \
##       --scene=res://scenes/weapons/WornSword.tscn \
##       --out=assets/weapons/T_WornSword_Icon.png
extends SceneTree

const SIZE: int = 256

var _scene_path: String = ""
var _out_path: String = ""


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			_scene_path = arg.trim_prefix("--scene=")
		elif arg.begins_with("--out="):
			_out_path = arg.trim_prefix("--out=")
	if _scene_path == "" or _out_path == "":
		push_error("[icon] --scene= et --out= requis")
		quit(2)
		return
	_render.call_deferred()


func _render() -> void:
	var window: Window = root
	window.size = Vector2i(SIZE, SIZE)
	window.transparent_bg = true

	var model: Node3D = (load(_scene_path) as PackedScene).instantiate() as Node3D
	if model == null:
		push_error("[icon] scène invalide : %s" % _scene_path)
		quit(3)
		return
	# Lame en diagonale du cadre (bas-gauche → haut-droite), face de lame vers
	# la caméra. Le modèle est lame +Z, plat vers +Y.
	model.rotation_degrees = Vector3.ZERO
	root.add_child(model)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.87, 0.65)
	sun.light_energy = 1.4
	sun.rotation_degrees = Vector3(-55, -30, 0)
	root.add_child(sun)
	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.light_color = Color(0.62, 0.72, 0.88)
	fill.light_energy = 0.5
	fill.rotation_degrees = Vector3(35, 140, 0)
	root.add_child(fill)

	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 0.86
	# Vue plongeante sur le plat de lame ; pivot au milieu de la poignée
	# (ART-P0R) : l'épée s'étend de z −0,12 à +0,86, recentrée ici.
	camera.position = Vector3(0.0, 2.0, 0.37)
	camera.rotation_degrees = Vector3(-90, 0, 45)
	root.add_child(camera)
	camera.make_current()

	for i: int in range(12):
		await process_frame
	var image: Image = root.get_viewport().get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	var absolute: String = ProjectSettings.globalize_path(_out_path)
	var err: int = image.save_png(absolute)
	if err != OK:
		push_error("[icon] échec d'écriture : %s (%d)" % [absolute, err])
		quit(4)
		return
	print("[icon] écrit : %s (%dx%d)" % [absolute, image.get_width(),
		image.get_height()])
	quit(0)
