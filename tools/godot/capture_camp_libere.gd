## LES TROIS PREUVES VISUELLES DU CAMP LIBÉRÉ — approche, combat, libéré.
##
## Destinataire : la revue Codex/Istvan. Ce script ne rend AUCUN verdict
## artistique, et n'en contient aucun seuil : il produit trois images du
## rendu réel, avec leur provenance, et s'arrête là.
##
## POURQUOI PAS `capture_poi_batch.gd`. Cet outil-là monte la scène UNE fois
## et déplace une caméra : parfait quand les plans diffèrent par l'angle. Ici
## les trois plans diffèrent par l'ÉTAT DU MONDE — garnison debout, garnison
## engagée, camp libéré — et cet état se lit dans la sauvegarde au montage.
## Il faut donc semer le slot puis remonter, trois fois.
##
## CE QUE « COMBAT » VEUT DIRE ICI, ET CE QUE ÇA NE VEUT PAS DIRE. On ne met
## pas en scène un tableau : on pose le héros au milieu de la garnison et on
## attend qu'un garde l'ENGAGE réellement, par sa propre perception. Si aucun
## engagement n'a lieu, le script le DIT dans le manifeste au lieu de livrer
## une image qui raconterait un combat inexistant.
##
## Usage :
##   tools/lancer_godot.sh --rendu --path . \
##     --script tools/godot/capture_camp_libere.gd -- \
##     --out-dir=evidence/world_v2/camp_libere/captures
extends SceneTree

const MONDE: String = "res://scenes/world_v2/WorldV2.tscn"
const DONNEES: String = "res://resources/world_v2/world_v2_camp_liberation.json"
const GARNISONS: String = "res://resources/world_v2/world_v2_garrisons.json"
const SLOT: String = "slot0"
const GARNISON: String = "garrison.ember_camp"

var _out_dir: String = "evidence/world_v2/camp_libere/captures"
var _width: int = 1280
var _height: int = 720


## Les trois plans. `joueur` est la position de reprise semée dans le slot ;
## `morts` dit si la garnison est déjà tombée ; `attendre_engagement` déclenche
## la boucle qui exige un vrai engagement avant de déclencher l'obturateur.
func _plans() -> Array[Dictionary]:
	return [
		{
			"name": "01_approche",
			"joueur": Vector3(36.0, 8.0, 96.0),
			"morts": false,
			"attendre_engagement": false,
			"from": Vector3(36.0, 12.5, 104.0),
			"look": Vector3(36.0, 6.0, 68.0),
			"fov": 62.0,
		},
		{
			"name": "02_combat",
			"joueur": Vector3(36.0, 6.6, 70.0),
			"morts": false,
			"attendre_engagement": true,
			"from": Vector3(46.0, 10.0, 78.0),
			"look": Vector3(36.0, 6.5, 68.0),
			"fov": 58.0,
		},
		{
			"name": "03_camp_libere",
			"joueur": Vector3(44.0, 6.5, 72.0),
			"morts": true,
			"attendre_engagement": false,
			"from": Vector3(50.0, 10.0, 78.0),
			"look": Vector3(43.0, 6.2, 67.0),
			"fov": 58.0,
		},
	]


func _init() -> void:
	_lire_arguments()
	_courir.call_deferred()


func _lire_arguments() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):
			_out_dir = arg.substr("--out-dir=".length())
		elif arg.begins_with("--size="):
			var parts: PackedStringArray = arg.substr("--size=".length()).split("x")
			if parts.size() == 2:
				_width = int(parts[0])
				_height = int(parts[1])


func _courir() -> void:
	DisplayServer.window_set_size(Vector2i(_width, _height))
	root.content_scale_size = Vector2i(_width, _height)
	if not DirAccess.dir_exists_absolute(_out_dir):
		DirAccess.make_dir_recursive_absolute(_out_dir)

	var manifeste: Array = []
	for plan: Dictionary in _plans():
		var ligne: Dictionary = await _un_plan(plan)
		if ligne.is_empty():
			printerr("[camp] ÉCHEC sur le plan %s" % plan.get("name"))
			quit(2)
			return
		manifeste.append(ligne)

	var meta: Dictionary = {
		"scene": MONDE,
		"engine": Engine.get_version_info()["string"],
		"renderer": ProjectSettings.get_setting(
			"rendering/renderer/rendering_method", "?"),
		"adapter": RenderingServer.get_video_adapter_name(),
		"size": "%dx%d" % [_width, _height],
		"commit": _commit(),
		"repo_dirty": _arbre_sale(),
		"avertissement": "Rendu LOGICIEL (llvmpipe, conteneur sans GPU) : "
			+ "utilisable pour lire une composition et un état de jeu, "
			+ "jamais pour juger une performance ni une lumière finale.",
		"plans": manifeste,
	}
	var f: FileAccess = FileAccess.open("%s/manifest.json" % _out_dir,
		FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(meta, "  "))
		f.close()
	print("[camp] OK : %d plans" % manifeste.size())
	quit(0)


func _un_plan(plan: Dictionary) -> Dictionary:
	_semer(plan["joueur"] as Vector3, bool(plan["morts"]))

	var monde: Node = (load(MONDE) as PackedScene).instantiate()
	root.add_child(monde)
	if not monde.is_node_ready():
		await monde.ready
	for _i: int in range(45):
		await process_frame

	var engage: bool = false
	if bool(plan["attendre_engagement"]):
		engage = await _attendre_engagement(monde)

	_masquer_interface(root)
	var camera: Camera3D = Camera3D.new()
	camera.name = "CameraPreuve"
	camera.near = 0.2
	camera.far = 1600.0
	camera.fov = float(plan["fov"])
	monde.add_child(camera)
	camera.position = plan["from"] as Vector3
	camera.look_at(plan["look"] as Vector3, Vector3.UP)
	camera.make_current()
	for _i: int in range(12):
		await process_frame

	var image: Image = root.get_texture().get_image()
	var chemin: String = "%s/%s.png" % [_out_dir, plan["name"]]
	if image == null or image.save_png(chemin) != OK:
		return {}
	print("[camp] %s" % chemin)

	var ligne: Dictionary = {
		"name": plan["name"],
		"image": chemin,
		"from": [camera.position.x, camera.position.y, camera.position.z],
		"look": [(plan["look"] as Vector3).x, (plan["look"] as Vector3).y,
			(plan["look"] as Vector3).z],
		"fov": camera.fov,
		"gardes_vivants": _vivants(monde),
		"foyer_visible": _foyer_visible(monde),
		"coffre_present": _coffre_present(monde),
	}
	if bool(plan["attendre_engagement"]):
		# On PUBLIE le fait, vrai ou faux. Une image de « combat » sans
		# engagement serait un mensonge poli.
		ligne["engagement_reel"] = engage

	root.remove_child(monde)
	monde.queue_free()
	for _i: int in range(4):
		await process_frame
	return ligne


## Attend qu'un garde ait RÉELLEMENT acquis le héros, jusqu'à ~8 s de jeu.
func _attendre_engagement(monde: Node) -> bool:
	for _i: int in range(480):
		for e: Node in monde.find_children("*", "EnemyBase", true, false):
			var etat: StringName = e.call("state_name") as StringName
			if etat == &"chase" or etat == &"attack" or etat == &"reposition":
				return true
		await process_frame
	return false


func _semer(joueur: Vector3, morts: bool) -> void:
	var systeme: Node = root.get_node_or_null("/root/SaveSystem")
	if systeme == null:
		return
	var payload: Dictionary = {
		"schema": 4,
		"world_version": "neris_v2",
		"checkpoint": "world_v2.valley",
		"player_position": {"x": joueur.x, "y": joueur.y, "z": joueur.z},
		"player_yaw": PI,
	}
	if morts:
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
		payload["enemies_slain"] = ids
	systeme.call("save_slot", SLOT, payload)


func _vivants(monde: Node) -> int:
	var n: int = 0
	for e: Node in monde.find_children("*", "EnemyBase", true, false):
		var sante: Node = e.call("health") as Node
		if sante != null and not bool(sante.call("is_dead")):
			n += 1
	return n


func _foyer_visible(monde: Node) -> bool:
	var brut: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(DONNEES))
	if not (brut is Dictionary):
		return false
	for entree: Variant in ((brut as Dictionary).get("camps", []) as Array):
		var chemin: String = String((entree as Dictionary).get("foyer_visuel", ""))
		var foyer: Node3D = monde.get_node_or_null(chemin) as Node3D
		if foyer != null:
			return foyer.visible
	return false


## DÉFAUT MESURÉ AU PREMIER RUN, ET IL FAISAIT MENTIR LA PREUVE. Cette
## fonction comptait N'IMPORTE QUEL `Chest` du monde — or les POI de la vallée
## en posent déjà (le camp braise de r06, entre autres). Le manifeste annonçait
## donc « coffre présent » sur les plans où le camp n'est PAS libéré, ce qu'un
## relecteur aurait lu comme « la récompense existe avant la victoire ».
## L'indicateur vise désormais le coffre DU CAMP, par son identifiant.
func _coffre_present(monde: Node) -> bool:
	var brut: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(DONNEES))
	if not (brut is Dictionary):
		return false
	for entree: Variant in ((brut as Dictionary).get("camps", []) as Array):
		var vise: String = String(((entree as Dictionary)
			.get("recompense", {}) as Dictionary).get("coffre_id", ""))
		if vise == "":
			continue
		for n: Node in monde.find_children("*", "Chest", true, false):
			if String(n.get("chest_id")) == vise:
				return true
	return false


func _masquer_interface(noeud: Node) -> void:
	if noeud is CanvasLayer:
		(noeud as CanvasLayer).visible = false
		return
	for enfant: Node in noeud.get_children():
		_masquer_interface(enfant)


func _commit() -> String:
	var out: Array = []
	var rc: int = OS.execute("git", ["-C",
		ProjectSettings.globalize_path("res://"), "rev-parse", "HEAD"], out, true)
	if rc != 0 or out.is_empty():
		return "inconnu"
	return String(out[0]).strip_edges()


## `evidence/` est la SORTIE de cet outil, jamais son entrée : les fichiers
## non suivis ne comptent pas.
func _arbre_sale() -> bool:
	var out: Array = []
	var rc: int = OS.execute("git", ["-C",
		ProjectSettings.globalize_path("res://"), "status", "--porcelain",
		"--untracked-files=no"], out, true)
	if rc != 0:
		return true
	if out.is_empty():
		return false
	return String(out[0]).strip_edges() != ""
