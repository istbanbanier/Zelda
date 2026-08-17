## QUI OCCUPE L'ÉCRAN — identification des masses par catégorie, sans changer
## la caméra.
##
## POURQUOI CET OUTIL EXISTE. Trois sondes successives se sont contredites sur
## les « masses jaunes » devant la bouche de la grotte : l'une les attribuait
## aux fougères du lieu, une autre ne trouvait aucun objet floral à moins de
## 24 m, une troisième ne les listait pas du tout. Les trois partageaient le
## même défaut : elles mesuraient une DISTANCE À UN POINT DU MONDE, alors
## qu'un objet occupe l'écran selon sa position dans le CÔNE DE LA CAMÉRA.
## Un buisson à 3 m de l'objectif remplit le cadre même s'il est à 20 m du
## sujet.
##
## Second piège, plus vicieux : sous le pilote de rendu par défaut en headless,
## les transformations d'instance d'un `MultiMesh` ne survivent pas. Une sonde
## qui lit `multimesh.get_instance_transform()` sans afficheur rend des
## identités et conclut, faussement, que rien n'est là. Cet outil DOIT donc
## tourner sous `xvfb-run … --rendering-driver opengl3`, et il refuse de
## conclure s'il détecte le pilote muet.
##
## Ce qu'il produit :
##   1. l'inventaire trié des occupants du cône, par distance à l'OBJECTIF,
##      avec leur catégorie, leur propriétaire et leur hauteur apparente ;
##   2. une capture par catégorie masquée, à caméra strictement identique,
##      pour que la disparition d'une masse désigne sa catégorie sans discours.
##
## Usage :
##   xvfb-run -a --server-args="-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --script tools/godot/diagnose_screen_occupants.gd -- \
##     --scene=res://scenes/world_v2/WorldV2.tscn --shot=<shot.json> \
##     --out-dir=evidence/… [--size=1280x720] [--top=24]
##
## `shot.json` : UN plan au format de `capture_poi_batch` — mêmes clés
## `from`, `look`, `fov`, même nom. La caméra n'est jamais recalculée ici :
## elle est recopiée, sinon la comparaison ne prouve rien.
extends SceneTree

## Catégories dans l'ORDRE de test. Un nœud reçoit la PREMIÈRE qui s'applique
## en remontant ses parents — un modèle végétal posé par un lieu appartient au
## lieu, pas à la végétation cellulaire, et c'est précisément la distinction
## qu'il faut trancher ici.
const CATEGORIES: Array[Dictionary] = [
	{"cle": "places", "groupes": [&"world_v2_places"]},
	{"cle": "vegetation", "groupes": [&"world_v2_vegetation",
		&"world_v2_vegetation_colliders"]},
	{"cle": "terrain", "groupes": [&"world_v2_terrain", &"world_v2_water",
		&"world_v2_routes", &"world_v2_ford_markers"]},
	{"cle": "distant", "groupes": [&"world_v2_border_guards",
		&"world_v2_regions"]},
	{"cle": "fx", "groupes": [&"world_v2_markers", &"world_v2_whitebox"]},
]

var _scene_path: String = ""
var _shot_path: String = ""
var _out_dir: String = "evidence/diagnostic_ecran"
var _width: int = 1280
var _height: int = 720
var _top: int = 24
var _build_frames: int = 45


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			_scene_path = arg.trim_prefix("--scene=")
		elif arg.begins_with("--shot="):
			_shot_path = arg.trim_prefix("--shot=")
		elif arg.begins_with("--out-dir="):
			_out_dir = arg.trim_prefix("--out-dir=")
		elif arg.begins_with("--top="):
			_top = maxi(1, arg.trim_prefix("--top=").to_int())
		elif arg.begins_with("--size="):
			var parts: PackedStringArray = arg.trim_prefix("--size=").split("x")
			if parts.size() == 2:
				_width = parts[0].to_int()
				_height = parts[1].to_int()
	if _scene_path.is_empty() or _shot_path.is_empty():
		printerr("[ecran] BLOQUÉ : --scene= et --shot= sont requis")
		quit(3)
		return
	_run()


func _run() -> void:
	var adapter: String = RenderingServer.get_video_adapter_name()
	if adapter.is_empty() or adapter.to_lower().find("dummy") >= 0:
		printerr("[ecran] BLOQUÉ : pilote de rendu muet (« %s »). Les "
			% adapter + "transformations de MultiMesh n'y survivent pas ; "
			+ "l'inventaire serait faux ET vraisemblable. Relancer sous "
			+ "xvfb avec --rendering-driver opengl3.")
		quit(3)
		return

	var file: FileAccess = FileAccess.open(_shot_path, FileAccess.READ)
	if file == null:
		printerr("[ecran] BLOQUÉ : plan illisible : %s" % _shot_path)
		quit(3)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		printerr("[ecran] BLOQUÉ : le plan doit être UN objet JSON")
		quit(3)
		return
	var plan: Dictionary = parsed as Dictionary
	var shot_name: String = String(plan.get("name", "plan"))
	var from_a: Array = plan.get("from", [0, 10, 0]) as Array
	var look_a: Array = plan.get("look", [0, 0, 0]) as Array
	var oeil: Vector3 = Vector3(float(from_a[0]), float(from_a[1]),
		float(from_a[2]))
	var cible: Vector3 = Vector3(float(look_a[0]), float(look_a[1]),
		float(look_a[2]))

	DisplayServer.window_set_size(Vector2i(_width, _height))
	root.content_scale_size = Vector2i(_width, _height)
	var packed: PackedScene = load(_scene_path) as PackedScene
	if packed == null:
		printerr("[ecran] ÉCHEC : scène introuvable : %s" % _scene_path)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	if not world.is_node_ready():
		await world.ready
	for i: int in range(_build_frames):
		await process_frame
	_masquer_interface(root)

	var camera: Camera3D = Camera3D.new()
	camera.name = "DiagnosticEcranCamera"
	camera.near = 0.2
	camera.far = 1600.0
	camera.fov = float(plan.get("fov", 60.0))
	world.add_child(camera)
	camera.position = oeil
	camera.look_at(cible, Vector3.UP)
	camera.make_current()
	for i: int in range(10):
		await process_frame

	if not DirAccess.dir_exists_absolute(_out_dir):
		DirAccess.make_dir_recursive_absolute(_out_dir)

	var occupants: Array[Dictionary] = _inventorier(world, camera)
	_imprimer(occupants, adapter)

	# Passe 0 : la référence. Toutes les autres lui sont comparées.
	var images: Array[Dictionary] = []
	images.append(await _capturer("%s/%s_00_reference.png" % [_out_dir, shot_name],
		"reference"))
	var index: int = 1
	for categorie: Dictionary in CATEGORIES:
		var cle: String = String(categorie["cle"])
		var caches: Array[CanvasItem] = []
		var caches3d: Array[Node3D] = _masquer_categorie(world, cle)
		for i: int in range(4):
			await process_frame
		images.append(await _capturer("%s/%s_%02d_sans_%s.png"
			% [_out_dir, shot_name, index, cle], cle))
		for n: Node3D in caches3d:
			n.visible = true
		for i: int in range(2):
			await process_frame
		index += 1
		caches.clear()

	_ecrire_manifeste(shot_name, plan, occupants, images, adapter)
	print("[ecran] OK : %d catégorie(s) + référence" % CATEGORIES.size())
	quit(0)


## Tout ce qui est réellement dessiné dans le cône, MultiMesh instance par
## instance. La profondeur est mesurée sur l'axe de visée, pas en distance
## euclidienne : c'est elle qui décide de l'ordre d'occlusion.
func _inventorier(world: Node, camera: Camera3D) -> Array[Dictionary]:
	var avant: Vector3 = -camera.global_transform.basis.z
	var oeil: Vector3 = camera.global_position
	var lignes: Array[Dictionary] = []
	for n: Node in world.find_children("*", "GeometryInstance3D", true, false):
		var gi: GeometryInstance3D = n as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		var categorie: String = _categorie_de(gi)
		var proprietaire: String = _proprietaire(gi)
		var mm: MultiMeshInstance3D = gi as MultiMeshInstance3D
		if mm != null and mm.multimesh != null and mm.multimesh.instance_count > 0:
			var vers: Transform3D = mm.global_transform
			var maille: Mesh = mm.multimesh.mesh
			var hauteur_native: float = 0.0
			if maille != null:
				hauteur_native = maille.get_aabb().size.y
			var meilleur: Dictionary = {}
			for i: int in range(mm.multimesh.instance_count):
				var t: Transform3D = vers * mm.multimesh.get_instance_transform(i)
				var echelle: float = t.basis.get_scale().y
				var ligne: Dictionary = _projeter(t.origin, oeil, avant, camera,
					hauteur_native * echelle)
				if ligne.is_empty():
					continue
				if meilleur.is_empty() or float(ligne["prof"]) < float(meilleur["prof"]):
					meilleur = ligne
			if not meilleur.is_empty():
				meilleur["nom"] = String(gi.name)
				meilleur["cat"] = categorie
				meilleur["prop"] = proprietaire
				meilleur["inst"] = mm.multimesh.instance_count
				lignes.append(meilleur)
		else:
			var boite: AABB = gi.global_transform * gi.get_aabb()
			var ligne2: Dictionary = _projeter(boite.get_center(), oeil, avant,
				camera, boite.size.y)
			if ligne2.is_empty():
				continue
			ligne2["nom"] = String(gi.name)
			ligne2["cat"] = categorie
			ligne2["prop"] = proprietaire
			ligne2["inst"] = 1
			lignes.append(ligne2)
	lignes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["prof"]) < float(b["prof"]))
	return lignes


func _projeter(p: Vector3, oeil: Vector3, avant: Vector3, camera: Camera3D,
		hauteur_m: float) -> Dictionary:
	var v: Vector3 = p - oeil
	var prof: float = v.dot(avant)
	if prof <= camera.near or prof > 120.0:
		return {}
	if camera.is_position_behind(p):
		return {}
	var ecran: Vector2 = camera.unproject_position(p)
	if ecran.x < -80.0 or ecran.x > float(_width) + 80.0:
		return {}
	if ecran.y < -80.0 or ecran.y > float(_height) + 80.0:
		return {}
	# Hauteur apparente : combien de pixels l'objet couvre à cette profondeur.
	# C'est la seule mesure qui dit « il occupe l'écran », pas « il est près ».
	var focale: float = float(_height) * 0.5 / tan(deg_to_rad(camera.fov) * 0.5)
	return {"prof": prof, "x": ecran.x, "y": ecran.y, "h_m": hauteur_m,
		"h_px": hauteur_m * focale / prof, "p": p}


func _imprimer(occupants: Array[Dictionary], adapter: String) -> void:
	print("[ecran] pilote : %s" % adapter)
	print("[ecran] %d occupant(s) du cône (profondeur <= 120 m)"
		% occupants.size())
	print("%-34s %-11s %-30s %6s %6s %6s %7s %7s" % ["nœud", "catégorie",
		"propriétaire", "prof", "x", "y", "haut_m", "haut_px"])
	for l: Dictionary in occupants.slice(0, _top):
		print("%-34s %-11s %-30s %6.2f %6.0f %6.0f %7.2f %7.0f" % [
			String(l["nom"]).substr(0, 34), l["cat"],
			String(l["prop"]).substr(0, 30), l["prof"], l["x"], l["y"],
			l["h_m"], l["h_px"]])


func _categorie_de(noeud: Node) -> String:
	var courant: Node = noeud
	while courant != null:
		for categorie: Dictionary in CATEGORIES:
			for groupe: StringName in (categorie["groupes"] as Array):
				if courant.is_in_group(groupe):
					return String(categorie["cle"])
		courant = courant.get_parent()
	return "autre"


func _proprietaire(noeud: Node) -> String:
	var courant: Node = noeud
	while courant != null:
		if courant.is_in_group(&"world_v2_places"):
			return "lieu " + String(courant.get_meta("place_id", courant.name))
		courant = courant.get_parent()
	var p: Node = noeud.get_parent()
	return String(p.name) if p != null else "?"


## Masque une catégorie SANS toucher la caméra ni l'éclairage : seul le
## contenu change, donc toute différence d'image est imputable à elle.
func _masquer_categorie(world: Node, cle: String) -> Array[Node3D]:
	var caches: Array[Node3D] = []
	for n: Node in world.find_children("*", "GeometryInstance3D", true, false):
		var gi: GeometryInstance3D = n as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		if _categorie_de(gi) != cle:
			continue
		gi.visible = false
		caches.append(gi)
	return caches


func _capturer(chemin: String, etiquette: String) -> Dictionary:
	for i: int in range(6):
		await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null:
		printerr("[ecran] ÉCHEC : rendu nul sur %s" % etiquette)
		quit(2)
		return {}
	if image.save_png(chemin) != OK:
		printerr("[ecran] ÉCHEC : écriture %s" % chemin)
		quit(2)
		return {}
	print("[ecran] %s" % chemin)
	return {"passe": etiquette, "image": chemin}


func _ecrire_manifeste(shot_name: String, plan: Dictionary,
		occupants: Array[Dictionary], images: Array[Dictionary],
		adapter: String) -> void:
	var tete: Array = []
	for l: Dictionary in occupants.slice(0, _top):
		tete.append({"noeud": l["nom"], "categorie": l["cat"],
			"proprietaire": l["prop"], "instances": l["inst"],
			"profondeur_m": snappedf(float(l["prof"]), 0.01),
			"ecran_x": roundi(float(l["x"])), "ecran_y": roundi(float(l["y"])),
			"hauteur_m": snappedf(float(l["h_m"]), 0.01),
			"hauteur_px": roundi(float(l["h_px"]))})
	var meta: Dictionary = {
		"outil": "diagnose_screen_occupants",
		"scene": _scene_path,
		"plan": plan,
		"engine": Engine.get_version_info()["string"],
		"renderer": ProjectSettings.get_setting(
			"rendering/renderer/rendering_method", "?"),
		"adapter": adapter,
		"size": "%dx%d" % [_width, _height],
		"commit": _commit(),
		"repo_dirty": _depot_sale(),
		"occupants_du_cone": occupants.size(),
		"tete_de_cone": tete,
		"passes": images,
	}
	var out: FileAccess = FileAccess.open("%s/%s_diagnostic.json"
		% [_out_dir, shot_name], FileAccess.WRITE)
	if out != null:
		out.store_string(JSON.stringify(meta, "  "))
		out.close()


func _masquer_interface(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child: Node in node.get_children():
		_masquer_interface(child)


func _commit() -> String:
	var out: Array = []
	var rc: int = OS.execute("git", ["-C",
		ProjectSettings.globalize_path("res://"), "rev-parse", "HEAD"],
		out, true)
	if rc != 0 or out.is_empty():
		return "inconnu"
	return String(out[0]).strip_edges()


func _depot_sale() -> bool:
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
