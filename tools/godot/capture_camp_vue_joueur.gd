## LE CAMP LIBÉRÉ, VU PAR LE JOUEUR — caméra réelle, interface comprise.
##
## POURQUOI CET OUTIL EXISTE. `capture_camp_libere.gd` MASQUE l'interface et
## CRÉE sa propre caméra, à un FOV et depuis un point qu'aucun joueur
## n'occupe. C'est le bon outil pour lire une composition de lieu ; c'en est
## un mauvais pour juger « est-ce que ça écrase le cadre ? », parce que le
## cadre en question n'est pas celui du jeu.
##
## Ici, rien n'est fabriqué : on monte le monde, on laisse le héros arriver
## avec SA caméra — distance, hauteur et FOV décidés par `player_controller`,
## pas par cet outil — et on déclenche. Le HUD est à l'écran, comme en jeu.
##
## LE MANIFESTE PUBLIE LE FOV RÉELLEMENT LU sur la caméra, jamais une valeur
## demandée. Piège déjà payé : `Player.tscn` porte `fov = 70`, et `_ready()`
## l'écrase. Une preuve qui recopierait la scène annoncerait un cadrage que
## le joueur ne voit pas.
##
## A/B : `--variante=off` désactive `CampVarianteVisuelle` AVANT son montage.
## Même arbre, même sauvegarde, même caméra, une seule variable.
##
## Usage :
##   tools/lancer_godot.sh --rendu --path . \
##     --script tools/godot/capture_camp_vue_joueur.gd -- \
##     --out-dir=evidence/world_v2/camp_variante/captures --variante=on
extends SceneTree

const MONDE: String = "res://scenes/world_v2/WorldV2.tscn"
const DONNEES: String = "res://resources/world_v2/world_v2_camp_liberation.json"
const GARNISONS: String = "res://resources/world_v2/world_v2_garrisons.json"
const SLOT: String = "slot0"
const GARNISON: String = "garrison.ember_camp"
## Demi-côté de la fenêtre échantillonnée autour du coffre, en pixels.
const FENETRE_COFFRE: int = 26

var _out_dir: String = "evidence/world_v2/camp_variante/captures"
var _width: int = 1280
var _height: int = 720
var _variante: bool = true


## Deux points de vue, tous deux atteignables à pied depuis le checkpoint.
## `yaw` oriente le héros ; sa caméra suit derrière lui, comme en jeu.
func _plans() -> Array[Dictionary]:
	return [
		{
			"name": "joueur_01_au_foyer",
			"joueur": Vector3(47.5, 6.0, 72.0),
			# Orienté VERS le coffre (44, 6, 68) par la convention du moteur,
			# `atan2(dx, dz)` — la même que `_face` côté ennemis. Recopier la
			# convention plutôt que l'inventer est ce qui garantit que le
			# héros regarde là où le manifeste dit qu'il regarde.
			"yaw": atan2(44.0 - 47.5, 68.0 - 72.0),
			"note": "debout près du feu, coffre dans le cadre — la vue "
				+ "qu'on a en revenant cuisiner",
		},
		{
			"name": "joueur_02_entree_nord",
			"joueur": Vector3(41.0, 6.6, 79.0),
			"yaw": PI,
			"note": "en arrivant par le nord, le camp entier dans le cadre",
		},
	]


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):
			_out_dir = arg.trim_prefix("--out-dir=")
		elif arg.begins_with("--size="):
			var wh: PackedStringArray = arg.trim_prefix("--size=").split("x")
			if wh.size() == 2:
				_width = int(wh[0])
				_height = int(wh[1])
		elif arg.begins_with("--variante="):
			_variante = arg.trim_prefix("--variante=") != "off"


func _initialize() -> void:
	root.content_scale_size = Vector2i(_width, _height)
	get_root().set_content_scale_mode(Window.CONTENT_SCALE_MODE_VIEWPORT)
	DisplayServer.window_set_size(Vector2i(_width, _height))
	_courir()


func _courir() -> void:
	if not DirAccess.dir_exists_absolute(_out_dir):
		DirAccess.make_dir_recursive_absolute(_out_dir)
	var lignes: Array[Dictionary] = []
	for plan: Dictionary in _plans():
		var ligne: Dictionary = await _un_plan(plan)
		if ligne.is_empty():
			printerr("[vue] ÉCHEC sur %s" % plan.get("name"))
			quit(2)
			return
		lignes.append(ligne)

	var meta: Dictionary = {
		"scene": MONDE,
		"variante": "on" if _variante else "off",
		"engine": Engine.get_version_info()["string"],
		"renderer": ProjectSettings.get_setting(
			"rendering/renderer/rendering_method", "?"),
		"adapter": RenderingServer.get_video_adapter_name(),
		"size": "%dx%d" % [_width, _height],
		"commit": _commit(),
		"repo_dirty": _arbre_sale(),
		"interface": "VISIBLE — c'est le point de cet outil ; le HUD fait "
			+ "partie de ce que le joueur regarde et donc de ce qu'on juge",
		"avertissement": "Rendu LOGICIEL (llvmpipe, conteneur sans GPU) : "
			+ "utilisable pour comparer deux cadres produits dans les MÊMES "
			+ "conditions, jamais pour juger une lumière finale ni une "
			+ "performance. Les particules d'un rendu logiciel ne préjugent "
			+ "pas de leur rendu sur une vraie carte.",
		"plans": lignes,
	}
	var f: FileAccess = FileAccess.open("%s/manifest.json" % _out_dir,
		FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(meta, "  "))
		f.close()
	print("[vue] OK : %d plan(s), variante=%s"
		% [lignes.size(), "on" if _variante else "off"])
	quit(0)


func _un_plan(plan: Dictionary) -> Dictionary:
	_semer(plan["joueur"] as Vector3, float(plan["yaw"]))

	var monde: Node = (load(MONDE) as PackedScene).instantiate()
	# AVANT l'entrée dans l'arbre : `_installer()` est différé, donc le poser
	# ici suffit, et c'est le seul moment où « off » veut dire quelque chose.
	var variante: Node = monde.get_node_or_null("CampVarianteVisuelle")
	if variante != null:
		variante.set("actif", _variante)
	root.add_child(monde)
	if not monde.is_node_ready():
		await monde.ready
	# Le camp se libère au montage (garnison déjà tombée dans le slot) et le
	# coffre arrive avec. On attend le FAIT, pas un nombre de frames.
	# BUDGET GÉNÉREUX ET ÉCHEC DUR. Premier passage mesuré : 300 frames n'ont
	# pas suffi au PREMIER montage — 64 chunks de terrain, ~6 s, caches froids
	# — et l'outil a publié une image d'un camp NON LIBÉRÉ en annonçant
	# `foyer_visible: false`. Le manifeste était exact et l'image ne montrait
	# pas ce que le plan promettait : exactement la forme de preuve fausse que
	# `capture_camp_libere.gd` a déjà payée. On attend beaucoup plus long, et
	# si le fait n'arrive pas, on ÉCHOUE au lieu de livrer.
	var coffre: Node3D = null
	for _i: int in range(2400):
		coffre = _coffre(monde)
		if coffre != null:
			break
		await process_frame
	if coffre == null or not _foyer_visible(monde):
		printerr("[vue] %s : le camp n'est pas libéré au déclenchement "
			% plan["name"] + "(coffre=%s, foyer=%s) — aucune image publiée"
			% [coffre != null, _foyer_visible(monde)])
		root.remove_child(monde)
		monde.queue_free()
		return {}
	for _i: int in range(60):
		await process_frame

	var camera: Camera3D = _camera_du_joueur(monde)
	if camera == null:
		printerr("[vue] aucune caméra courante — le héros n'est pas monté")
		root.remove_child(monde)
		monde.queue_free()
		return {}

	var image: Image = root.get_texture().get_image()
	var chemin: String = "%s/%s.png" % [_out_dir, plan["name"]]
	if image == null or image.save_png(chemin) != OK:
		return {}
	print("[vue] %s" % chemin)

	var mesure: Dictionary = _mesurer_coffre(camera, image, coffre)
	var ligne: Dictionary = {
		"name": plan["name"],
		"image": chemin,
		"note": plan["note"],
		# LU sur la caméra, jamais demandé.
		"camera_fov_vertical": camera.fov,
		"camera_position": [camera.global_position.x,
			camera.global_position.y, camera.global_position.z],
		"hud_visible": _interface_visible(monde),
		"foyer_visible": _foyer_visible(monde),
		"foyer_lumiere": _foyer_a_une_lumiere(monde),
		"coffre_present": coffre != null,
		"gardes_vivants": _vivants(monde),
	}
	ligne.merge(mesure)

	root.remove_child(monde)
	monde.queue_free()
	for _i: int in range(4):
		await process_frame
	return ligne


## ------------------------------------------------------------------------
## La mesure : « moins dominant » doit être un NOMBRE, pas une impression
## ------------------------------------------------------------------------
## Projette le coffre à l'écran, échantillonne une fenêtre autour de lui, et
## compare sa luminance médiane à celle de l'image entière. C'est CE rapport
## qui dit s'il écrase le cadre — une luminance absolue ne dirait rien, deux
## expositions différentes suffiraient à la faire varier.
##
## Rend `coffre_dans_le_cadre: false` quand la projection tombe hors écran ou
## derrière la caméra : le manifeste préfère l'avouer plutôt que publier une
## mesure prise sur des pixels qui ne regardent pas le coffre.
func _mesurer_coffre(camera: Camera3D, image: Image,
		coffre: Node3D) -> Dictionary:
	if coffre == null:
		return {"coffre_dans_le_cadre": false}
	var cible: Vector3 = coffre.global_position + Vector3.UP * 0.35
	if camera.is_position_behind(cible):
		return {"coffre_dans_le_cadre": false}
	var p: Vector2 = camera.unproject_position(cible)
	var largeur: int = image.get_width()
	var hauteur: int = image.get_height()
	# `unproject_position` travaille dans la taille du viewport ; l'image
	# capturée peut différer. On ramène en fraction avant de repixelliser.
	var vp: Vector2 = Vector2(root.size)
	var fx: float = p.x / maxf(1.0, vp.x)
	# Fraction, puis repixellisation : sûr même si viewport != image.
	var fy: float = p.y / maxf(1.0, vp.y)
	if fx < 0.0 or fx > 1.0 or fy < 0.0 or fy > 1.0:
		return {"coffre_dans_le_cadre": false}
	var cx: int = int(fx * float(largeur))
	var cy: int = int(fy * float(hauteur))

	var autour: Array[float] = []
	for y: int in range(maxi(0, cy - FENETRE_COFFRE),
			mini(hauteur, cy + FENETRE_COFFRE)):
		for x: int in range(maxi(0, cx - FENETRE_COFFRE),
				mini(largeur, cx + FENETRE_COFFRE)):
			autour.append(image.get_pixel(x, y).get_luminance())
	var cadre: Array[float] = []
	var pas: int = maxi(1, mini(largeur, hauteur) / 96)
	var yy: int = 0
	while yy < hauteur:
		var xx: int = 0
		while xx < largeur:
			cadre.append(image.get_pixel(xx, yy).get_luminance())
			xx += pas
		yy += pas
	if autour.is_empty() or cadre.is_empty():
		return {"coffre_dans_le_cadre": false}
	var l_coffre: float = _mediane(autour)
	var l_cadre: float = _mediane(cadre)
	return {
		"coffre_dans_le_cadre": true,
		"coffre_ecran": [cx, cy],
		"coffre_luminance_mediane": snappedf(l_coffre, 0.001),
		"cadre_luminance_mediane": snappedf(l_cadre, 0.001),
		# > 1 : le coffre est plus clair que son cadre. C'est le nombre à
		# faire baisser, et le seul que l'A/B compare.
		"coffre_sur_cadre": snappedf(l_coffre / maxf(0.0001, l_cadre), 0.001),
	}


func _mediane(valeurs: Array[float]) -> float:
	valeurs.sort()
	return valeurs[valeurs.size() / 2]


## ------------------------------------------------------------------------
## Constats
## ------------------------------------------------------------------------
func _camera_du_joueur(monde: Node) -> Camera3D:
	for n: Node in monde.find_children("*", "Camera3D", true, false):
		if (n as Camera3D).current:
			return n as Camera3D
	return null


func _interface_visible(monde: Node) -> bool:
	for n: Node in monde.find_children("*", "CanvasLayer", true, false):
		if (n as CanvasLayer).visible:
			return true
	return false


func _foyer_visible(monde: Node) -> bool:
	var foyer: Node3D = _foyer(monde)
	return foyer != null and foyer.visible


func _foyer_a_une_lumiere(monde: Node) -> bool:
	var foyer: Node3D = _foyer(monde)
	if foyer == null:
		return false
	return not foyer.find_children("*", "OmniLight3D", true, false).is_empty()


func _foyer(monde: Node) -> Node3D:
	var brut: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(DONNEES))
	if not (brut is Dictionary):
		return null
	for entree: Variant in ((brut as Dictionary).get("camps", []) as Array):
		var chemin: String = String((entree as Dictionary)
			.get("foyer_visuel", ""))
		var n: Node3D = monde.get_node_or_null(chemin) as Node3D
		if n != null:
			return n
	return null


func _coffre(monde: Node) -> Node3D:
	var brut: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(DONNEES))
	if not (brut is Dictionary):
		return null
	for entree: Variant in ((brut as Dictionary).get("camps", []) as Array):
		var vise: String = String(((entree as Dictionary)
			.get("recompense", {}) as Dictionary).get("coffre_id", ""))
		if vise == "":
			continue
		for n: Node in monde.find_children("*", "Chest", true, false):
			if String(n.get("chest_id")) == vise:
				return n as Node3D
	return null


func _vivants(monde: Node) -> int:
	var n: int = 0
	for e: Node in monde.find_children("*", "EnemyBase", true, false):
		var sante: Node = e.call("health") as Node
		if sante != null and not bool(sante.call("is_dead")):
			n += 1
	return n


## ------------------------------------------------------------------------
## Sauvegarde semée et provenance
## ------------------------------------------------------------------------
func _semer(joueur: Vector3, yaw: float) -> void:
	var systeme: Node = root.get_node_or_null("/root/SaveSystem")
	if systeme == null:
		return
	var ids: Array = []
	var brut: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(GARNISONS))
	if brut is Dictionary:
		for entree: Variant in ((brut as Dictionary).get("garrisons", []) as Array):
			var g: Dictionary = entree as Dictionary
			if String(g.get("id", "")) != GARNISON:
				continue
			for fiche: Variant in (g.get("enemies", []) as Array):
				ids.append(String((fiche as Dictionary).get("id", "")))
	systeme.call("save_slot", SLOT, {
		"schema": 4,
		"world_version": "neris_v2",
		"checkpoint": "world_v2.valley",
		"player_position": {"x": joueur.x, "y": joueur.y, "z": joueur.z},
		"player_yaw": yaw,
		"enemies_slain": ids,
	})


func _commit() -> String:
	var out: Array = []
	var rc: int = OS.execute("git", ["-C",
		ProjectSettings.globalize_path("res://"), "rev-parse", "HEAD"], out, true)
	if rc != 0 or out.is_empty():
		return "inconnu"
	return String(out[0]).strip_edges()


## `evidence/` est la SORTIE de cet outil, jamais son entrée — on ne saute
## QUE ces entrées, un `.gd` modifié doit toujours rendre `true`.
func _arbre_sale() -> bool:
	var out: Array = []
	var rc: int = OS.execute("git", ["-C",
		ProjectSettings.globalize_path("res://"), "status", "--porcelain",
		"--untracked-files=no"], out, true)
	if rc != 0:
		return true
	if out.is_empty():
		return false
	for ligne: String in String(out[0]).split("\n", false):
		var entree: String = ligne.strip_edges()
		if entree == "":
			continue
		if entree.substr(2).strip_edges().begins_with("evidence/"):
			continue
		return true
	return false
