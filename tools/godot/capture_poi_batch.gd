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

## `--scene=` EST OBLIGATOIRE — et voici pourquoi, mesuré le 2026-08-14.
##
## Cet outil avait `res://scenes/world/valley/ValleyWorld.tscn` (la vallée
## V1) pour défaut. Une passe de captures V2.3-A.R a été lancée SANS
## `--scene` : les 21 plans sont sortis, le code retour a été 0, le
## manifeste s'est écrit, et pendant vingt minutes j'ai cherché pourquoi
## le pylône refait « ne rendait pas ». Il rendait très bien — dans un
## monde qui n'était pas le sien. La vallée V1 partage les ancres §3.3,
## donc les caméras visaient des objets PLAUSIBLES : rien dans l'image ne
## criait l'erreur.
##
## Un défaut qui produit une image crédible et un code retour 0 ne se
## rattrape pas à l'œil. Le défaut par défaut est donc supprimé : sans
## `--scene`, l'outil s'arrête en BLOQUÉ (3). Le manifeste porte déjà le
## chemin de scène ; c'est lui qu'il faut lire avant de croire un plan.
var _scene_path: String = ""
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
	if _scene_path.is_empty():
		printerr("[poi] BLOQUÉ : --scene=<res://…> requis — aucun défaut, "
			+ "une capture du mauvais monde ressemble à une bonne capture")
		quit(3)
		return
	var perimes: PackedStringArray = _assets_non_reimportes()
	if not perimes.is_empty():
		printerr("[poi] BLOQUÉ : %d asset(s) modifié(s) depuis leur import. "
			% perimes.size()
			+ "La capture rendrait la GÉOMÉTRIE PRÉCÉDENTE, et l'image "
			+ "serait parfaitement crédible. Lancer d'abord :\n"
			+ "    godot --headless --path . --import")
		for chemin: String in perimes:
			printerr("[poi]   %s" % chemin)
		quit(3)
		return
	_run()


## LE CACHE D'IMPORT EST PÉRIMÉ, ET L'IMAGE NE LE DIT PAS.
##
## Mesuré le 2026-08-15. `SM_WaterfallCave.glb` réexporté à 16:11, cache
## d'import daté de 10:52 : la passe de captures a rendu l'ANCIENNE grotte,
## pixel pour pixel identique à celle de la tranche précédente. Le code
## retour était 0, le manifeste s'est écrit avec le bon commit et
## `repo_dirty: false`, et rien dans l'image ne criait l'erreur — j'ai failli
## livrer comme preuve d'un travail la photographie de son état antérieur.
##
## C'est la même famille que le défaut `--scene=` documenté plus haut : une
## capture plausible et fausse ne se rattrape pas à l'œil. On compare donc
## la date de chaque source importable à celle de l'artefact qu'elle a
## produit, et on refuse de capturer si l'une est plus récente.
func _assets_non_reimportes() -> PackedStringArray:
	var perimes: PackedStringArray = PackedStringArray()
	_parcourir_imports("res://assets", perimes)
	return perimes


func _parcourir_imports(dossier: String, perimes: PackedStringArray) -> void:
	var acces: DirAccess = DirAccess.open(dossier)
	if acces == null:
		return
	acces.list_dir_begin()
	var nom: String = acces.get_next()
	while nom != "":
		var chemin: String = dossier.path_join(nom)
		if acces.current_is_dir():
			if not nom.begins_with("."):
				_parcourir_imports(chemin, perimes)
		elif nom.ends_with(".import"):
			var source: String = chemin.trim_suffix(".import")
			var produit: String = _artefact_importe(chemin)
			if produit.is_empty():
				perimes.append(source + " (aucun artefact importé)")
			else:
				var t_source: int = FileAccess.get_modified_time(
					ProjectSettings.globalize_path(source))
				var t_produit: int = FileAccess.get_modified_time(
					ProjectSettings.globalize_path(produit))
				if t_produit == 0:
					perimes.append(source + " (artefact absent)")
				elif t_source > t_produit:
					perimes.append(source)
		nom = acces.get_next()
	acces.list_dir_end()


func _artefact_importe(chemin_import: String) -> String:
	var fichier: FileAccess = FileAccess.open(chemin_import, FileAccess.READ)
	if fichier == null:
		return ""
	while not fichier.eof_reached():
		var ligne: String = fichier.get_line().strip_edges()
		if ligne.begins_with("path="):
			fichier.close()
			return ligne.trim_prefix("path=").replace("\"", "")
	fichier.close()
	return ""


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
