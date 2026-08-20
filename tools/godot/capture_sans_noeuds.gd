extends SceneTree
## Capture la MÊME scène avec certains nœuds masqués — pour attribuer à un objet
## sa contribution réelle à l'image.
##
## POURQUOI. Un défaut vu sur une capture est attribué de mémoire à l'objet qu'on
## soupçonne, et c'est faux une fois sur deux : en R2B.2, une aile sombre attribuée
## au jupon de racines appartenait en réalité à une branche, et une « plaque crème
## sans matière » s'est révélée être de l'herbe verte. La seule façon de trancher
## est d'éteindre l'objet et de regarder ce qui disparaît.
##
## Le diff se fait ensuite hors moteur, contre un lot capturé aux MÊMES caméras.
##
## Usage :
##   godot --path . --script tools/godot/capture_sans_noeuds.gd -- \
##     --scene=… --shots=… --out-dir=… --size=1280x720 --masquer=Motif1,Motif2

var _scene: String = ""
var _shots: String = ""
var _out: String = ""
var _w: int = 1280
var _h: int = 720
var _masques: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			_scene = arg.trim_prefix("--scene=")
		elif arg.begins_with("--shots="):
			_shots = arg.trim_prefix("--shots=")
		elif arg.begins_with("--out-dir="):
			_out = arg.trim_prefix("--out-dir=")
		elif arg.begins_with("--masquer="):
			_masques = arg.trim_prefix("--masquer=").split(",", false)
		elif arg.begins_with("--size="):
			var p: PackedStringArray = arg.trim_prefix("--size=").split("x")
			if p.size() == 2:
				_w = p[0].to_int()
				_h = p[1].to_int()
	if _scene.is_empty() or _shots.is_empty() or _out.is_empty():
		printerr("BLOQUÉ : --scene= --shots= --out-dir= requis")
		quit(3)
		return
	if _masques.is_empty():
		printerr("BLOQUÉ : --masquer= requis — sans lui cet outil duplique "
			+ "capture_poi_batch et son résultat serait pris pour une ablation")
		quit(3)
		return
	_run()


func _run() -> void:
	var texte: String = FileAccess.get_file_as_string(_shots)
	var plans: Variant = JSON.parse_string(texte)
	if not (plans is Array):
		printerr("BLOQUÉ : le fichier de vues doit être un Array nu")
		quit(3)
		return
	DisplayServer.window_set_size(Vector2i(_w, _h))
	root.content_scale_size = Vector2i(_w, _h)
	var paquet: PackedScene = load(_scene) as PackedScene
	var monde: Node = paquet.instantiate()
	root.add_child(monde)
	if not monde.is_node_ready():
		await monde.ready
	for i: int in range(90):
		await process_frame

	var eteints: int = 0
	for node: Node in monde.find_children("*", "MeshInstance3D", true, false):
		var chemin: String = String(monde.get_path_to(node))
		for motif: String in _masques:
			if chemin.contains(motif):
				(node as MeshInstance3D).visible = false
				eteints += 1
				break
	print("[ablation] %d maillage(s) éteint(s) pour %s" % [eteints,
		", ".join(_masques)])
	if eteints == 0:
		printerr("BLOQUÉ : aucun maillage éteint — le motif ne correspond à rien, "
			+ "et l'image serait IDENTIQUE tout en passant pour une ablation")
		quit(2)
		return
	_cacher_interface(root)

	var cam: Camera3D = Camera3D.new()
	cam.near = 0.2
	cam.far = 1600.0
	monde.add_child(cam)
	DirAccess.make_dir_recursive_absolute(_out)
	for plan: Variant in plans:
		var d: Dictionary = plan as Dictionary
		var f: Array = d.get("from", [0, 10, 0]) as Array
		var l: Array = d.get("look", [0, 0, 0]) as Array
		cam.fov = float(d.get("fov", 60.0))
		cam.position = Vector3(float(f[0]), float(f[1]), float(f[2]))
		cam.look_at(Vector3(float(l[0]), float(l[1]), float(l[2])), Vector3.UP)
		cam.make_current()
		for i: int in range(6):
			await process_frame
		var img: Image = root.get_texture().get_image()
		if img == null:
			printerr("ÉCHEC : rendu nul sur %s — lancer sous xvfb-run, "
				+ "SANS --headless" % String(d.get("name", "?")))
			quit(2)
			return
		img.save_png("%s/%s.png" % [_out, String(d.get("name", "plan"))])
	print("[ablation] OK : %d plans" % plans.size())
	quit(0)


func _cacher_interface(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for enfant: Node in node.get_children():
		_cacher_interface(enfant)
