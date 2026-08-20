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
## MODE `--paires` — LE SEUL QUI MESURE QUELQUE CHOSE DANS CE MONDE.
## Mesuré le 2026-08-20 : deux exécutions séparées du MÊME code, sans rien
## éteindre, diffèrent déjà de 0,9 % à 6,4 % des pixels, sur des vues où l'objet
## visé n'apparaît même pas. La cause est la végétation animée : deux processus
## ne se stabilisent pas à la même phase du vent, et toute l'herbe change. Un
## diff inter-processus ne peut donc RIEN attribuer ici.
## En mode `--paires`, chaque vue est rendue deux fois dans le MÊME processus,
## à une trame d'écart : avec l'objet, puis sans. Le vent n'a avancé que d'une
## trame, et la seule variable qui reste est la visibilité.
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
var _paires: bool = false


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
		elif arg == "--paires":
			_paires = true
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
			+ "capture_poi_batch et son résultat serait pris pour une ablation. "
			+ "Pour le TÉMOIN, écrire --masquer=AUCUN explicitement.")
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

	# LE TÉMOIN DOIT PASSER PAR LE MÊME CODE QUE L'ABLATION.
	#
	# Mesuré le 2026-08-20 : comparer un lot de `capture_poi_batch` à un lot de
	# cet outil-ci rendait 2 à 5 % de pixels changés sur TOUTES les vues, y
	# compris celles où l'objet éteint n'est pas visible — donc du bruit
	# d'exécution (llvmpipe, nombre de trames de stabilisation différent), pas
	# une contribution. Un témoin capturé par le MÊME chemin de code isole la
	# seule variable qui compte : les deux maillages éteints.
	var temoin: bool = (_masques.size() == 1 and _masques[0] == "AUCUN")
	var eteints: int = 0
	if not temoin:
		for node: Node in monde.find_children("*", "MeshInstance3D", true, false):
			var chemin: String = String(monde.get_path_to(node))
			for motif: String in _masques:
				if chemin.contains(motif):
					(node as MeshInstance3D).visible = false
					eteints += 1
					break
	if temoin:
		print("[ablation] TÉMOIN : aucun maillage éteint, même chemin de code")
	else:
		print("[ablation] %d maillage(s) éteint(s) pour %s" % [eteints,
			", ".join(_masques)])
	if eteints == 0 and not temoin:
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
	# GELER LE VENT AVANT DE MESURER — quatrième tentative, et la seule qui vaut.
	#
	# Pairer les deux états à une trame d'écart ne suffisait PAS : mesuré le
	# 2026-08-20, `ferme_seuil` rendait encore 0,84 % de pixels changés avec une
	# boîte plein cadre, alors que les débris n'y sont pas. Une seule trame de
	# balancement déplace assez de brins fins et contrastés pour noyer le signal.
	#
	# On ne contourne donc plus le confondant : on l'éteint. `sway_amplitude` est
	# le paramètre du shader d'herbe (`world_v2_vegetation_builder.gd`). Mis à
	# zéro, la végétation est immobile et la seule variable restante est la
	# visibilité de l'objet.
	#
	# Ces images sont des IMAGES DE MESURE, jamais des preuves : une capture de
	# preuve garde le vent du jeu.
	var geles: int = 0
	if _paires:
		for node: Node in monde.find_children("*", "GeometryInstance3D", true, false):
			var gi: GeometryInstance3D = node as GeometryInstance3D
			for k: int in range(maxi(1, gi.get_surface_override_material_count())):
				var mat: Material = gi.get_surface_override_material(k)
				if mat == null and gi is MeshInstance3D:
					var mi: MeshInstance3D = gi as MeshInstance3D
					if mi.mesh != null and k < mi.mesh.get_surface_count():
						mat = mi.mesh.surface_get_material(k)
				var sm: ShaderMaterial = mat as ShaderMaterial
				if sm != null and sm.get_shader_parameter(&"sway_amplitude") != null:
					sm.set_shader_parameter(&"sway_amplitude", 0.0)
					geles += 1
			var mm: Material = gi.material_override
			var smo: ShaderMaterial = mm as ShaderMaterial
			if smo != null and smo.get_shader_parameter(&"sway_amplitude") != null:
				smo.set_shader_parameter(&"sway_amplitude", 0.0)
				geles += 1
		print("[ablation] vent gelé sur %d matériau(x)" % geles)
		if geles == 0:
			printerr("BLOQUÉ : aucun `sway_amplitude` trouvé — le vent n'est pas "
				+ "gelé, et la mesure serait du bruit qui ressemble à un résultat")
			quit(2)
			return
		for i: int in range(12):
			await process_frame

	var cibles: Array[MeshInstance3D] = []
	for node: Node in monde.find_children("*", "MeshInstance3D", true, false):
		var chemin: String = String(monde.get_path_to(node))
		for motif: String in _masques:
			if chemin.contains(motif):
				cibles.append(node as MeshInstance3D)
				break
	for plan: Variant in plans:
		var d: Dictionary = plan as Dictionary
		var nom: String = String(d.get("name", "plan"))
		var f: Array = d.get("from", [0, 10, 0]) as Array
		var l: Array = d.get("look", [0, 0, 0]) as Array
		cam.fov = float(d.get("fov", 60.0))
		cam.position = Vector3(float(f[0]), float(f[1]), float(f[2]))
		cam.look_at(Vector3(float(l[0]), float(l[1]), float(l[2])), Vector3.UP)
		cam.make_current()
		for i: int in range(6):
			await process_frame
		if _paires:
			for c: MeshInstance3D in cibles:
				c.visible = true
			await process_frame
			var avec: Image = root.get_texture().get_image()
			for c: MeshInstance3D in cibles:
				c.visible = false
			await process_frame
			var sans: Image = root.get_texture().get_image()
			if avec == null or sans == null:
				printerr("ÉCHEC : rendu nul sur %s — lancer sous xvfb-run, "
					+ "SANS --headless" % nom)
				quit(2)
				return
			avec.save_png("%s/%s_avec.png" % [_out, nom])
			sans.save_png("%s/%s_sans.png" % [_out, nom])
			continue
		var img: Image = root.get_texture().get_image()
		if img == null:
			printerr("ÉCHEC : rendu nul sur %s — lancer sous xvfb-run, "
				+ "SANS --headless" % nom)
			quit(2)
			return
		img.save_png("%s/%s.png" % [_out, nom])
	print("[ablation] OK : %d plans" % plans.size())
	quit(0)


func _cacher_interface(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for enfant: Node in node.get_children():
		_cacher_interface(enfant)
