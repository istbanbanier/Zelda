## SILHOUETTE ISOLÉE — le sujet seul, forme sombre unie sur fond clair.
##
## POURQUOI CET OUTIL EXISTE. La « planche de silhouettes » des passes
## précédentes était un montage de captures de JEU passées en niveaux de
## gris. Le lead l'a tranché sans détour : « encore une mosaïque de
## couleurs — ce n'est pas un test de silhouette ». Il avait raison, et le
## défaut n'était pas cosmétique : une vignette qui contient le terrain, le
## ciel, la brume et la végétation ne peut pas répondre à la question que
## pose un test de silhouette, qui est « reconnaît-on le sujet à sa seule
## forme ? ». Tant que le fond est dans l'image, on répond avec le fond.
##
## Ici l'environnement n'est pas assombri : il est ABSENT. Le sujet est
## instancié seul, dans une scène vide, tous ses matériaux remplacés par un
## unshaded sombre, devant un fond de couleur plate. L'image ne peut donc
## contenir que deux valeurs — et un filet le VÉRIFIE avant d'écrire quoi
## que ce soit (voir `_controle_bimodal`). Une image qui n'est pas bimodale
## n'est pas une silhouette, et l'outil sort en échec plutôt que de livrer
## une preuve qui n'en est pas une.
##
## Cadrage déterministe : la distance et la hauteur découlent de l'AABB
## réelle du sujet, pas d'un réglage à la main. Deux sujets différents sont
## donc cadrés par la même règle, et un même sujet recapturé après
## modification est comparable au pixel près.
##
## Usage :
##   xvfb-run -a --server-args="-screen 0 900x1200x24" godot --path . \
##     --rendering-driver opengl3 --script tools/godot/capture_silhouette.gd -- \
##     --scene=res://assets/architecture/pylon/SM_Pylon_Resonance.glb \
##     --out-dir=evidence/... --name=pylone --angles=0,90 --size=900x1200
extends SceneTree

## Valeur du sujet et du fond. L'écart est volontairement énorme : le test
## porte sur la FORME, et toute nuance intermédiaire serait du bruit.
const VALEUR_SUJET: Color = Color(0.045, 0.045, 0.055)
const VALEUR_FOND: Color = Color(0.88, 0.89, 0.91)

## Marge autour de l'AABB, en fraction de la plus grande dimension.
const MARGE: float = 0.10

var _scene_path: String = ""
var _out_dir: String = "evidence/silhouettes"
var _nom: String = "sujet"
var _angles: PackedFloat32Array = PackedFloat32Array([0.0, 90.0])
var _width: int = 900
var _height: int = 1200
var _settle_frames: int = 8


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--scene="):
			_scene_path = argument.trim_prefix("--scene=")
		elif argument.begins_with("--out-dir="):
			_out_dir = argument.trim_prefix("--out-dir=")
		elif argument.begins_with("--name="):
			_nom = argument.trim_prefix("--name=")
		elif argument.begins_with("--angles="):
			_angles = PackedFloat32Array()
			for part: String in argument.trim_prefix("--angles=").split(",", false):
				_angles.append(part.to_float())
		elif argument.begins_with("--size="):
			var parts: PackedStringArray = argument.trim_prefix("--size=").split("x")
			if parts.size() == 2:
				_width = parts[0].to_int()
				_height = parts[1].to_int()
	if _scene_path.is_empty():
		printerr("[silhouette] BLOQUÉ : --scene=<res://…> requis")
		quit(3)
		return
	_run()


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(_width, _height))
	root.content_scale_size = Vector2i(_width, _height)

	var packed: PackedScene = load(_scene_path) as PackedScene
	if packed == null:
		printerr("[silhouette] BLOQUÉ : scène introuvable — %s" % _scene_path)
		quit(3)
		return
	var sujet: Node3D = packed.instantiate() as Node3D
	if sujet == null:
		printerr("[silhouette] BLOQUÉ : la scène n'est pas un Node3D")
		quit(3)
		return

	var scene_root: Node3D = Node3D.new()
	scene_root.name = "SilhouetteRoot"
	root.add_child(scene_root)
	scene_root.add_child(sujet)
	await process_frame

	# Fond plat, aucune lumière, aucun brouillard : rien qui puisse
	# introduire une troisième valeur dans l'image.
	var monde: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = VALEUR_FOND
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.BLACK
	env.ambient_light_energy = 0.0
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.glow_enabled = false
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	monde.environment = env
	scene_root.add_child(monde)

	var aplat: StandardMaterial3D = StandardMaterial3D.new()
	aplat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aplat.albedo_color = VALEUR_SUJET
	aplat.disable_receive_shadows = true
	var couvertes: int = _aplatir(sujet, aplat)
	if couvertes == 0:
		printerr("[silhouette] ÉCHEC : aucun maillage dans %s" % _scene_path)
		quit(1)
		return

	var boite: AABB = _emprise(sujet)
	if boite.size.length() <= 0.0:
		printerr("[silhouette] ÉCHEC : emprise vide")
		quit(1)
		return
	print("[silhouette] %s — %d maillages, emprise %.2f × %.2f × %.2f m"
		% [_nom, couvertes, boite.size.x, boite.size.y, boite.size.z])

	var camera: Camera3D = Camera3D.new()
	camera.name = "SilhouetteCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.05
	camera.far = 4000.0
	scene_root.add_child(camera)

	if not DirAccess.dir_exists_absolute(_out_dir):
		DirAccess.make_dir_recursive_absolute(_out_dir)

	var manifeste: Array = []
	for angle: float in _angles:
		var image: Image = await _capturer(camera, boite, angle)
		if image == null:
			quit(2)
			return
		var mesure: Dictionary = _controle_bimodal(image)
		if not bool(mesure["bimodal"]):
			printerr(("[silhouette] ÉCHEC %s %.0f° : l'image n'est pas bimodale "
				+ "(%.1f %% des pixels hors des deux valeurs) — ce n'est pas "
				+ "une silhouette, c'est une capture assombrie")
				% [_nom, angle, float(mesure["hors_bandes_pct"])])
			quit(1)
			return
		if float(mesure["sujet_pct"]) < 2.0:
			printerr("[silhouette] ÉCHEC %s %.0f° : le sujet n'occupe que %.1f %% de l'image"
				% [_nom, angle, float(mesure["sujet_pct"])])
			quit(1)
			return
		var chemin: String = "%s/silhouette_%s_%03d.png" % [_out_dir, _nom, int(angle)]
		if image.save_png(chemin) != OK:
			printerr("[silhouette] ÉCHEC : écriture %s" % chemin)
			quit(2)
			return
		print("[silhouette] %s — sujet %.1f %% de l'image, hors bandes %.3f %%"
			% [chemin, float(mesure["sujet_pct"]), float(mesure["hors_bandes_pct"])])
		manifeste.append({
			"angle_deg": angle, "image": chemin,
			"sujet_pct": mesure["sujet_pct"],
			"hors_bandes_pct": mesure["hors_bandes_pct"],
		})

	var meta: Dictionary = {
		"sujet": _nom,
		"scene": _scene_path,
		"engine": Engine.get_version_info()["string"],
		"renderer": ProjectSettings.get_setting(
			"rendering/renderer/rendering_method", "?"),
		"adapter": RenderingServer.get_video_adapter_name(),
		"size": "%dx%d" % [_width, _height],
		"projection": "orthogonale",
		"emprise_m": [boite.size.x, boite.size.y, boite.size.z],
		"commit": _current_commit(),
		"repo_dirty": _repo_is_dirty(),
		"vues": manifeste,
	}
	var out: FileAccess = FileAccess.open(
		"%s/manifest_silhouettes_%s.json" % [_out_dir, _nom], FileAccess.WRITE)
	if out != null:
		out.store_string(JSON.stringify(meta, "  "))
		out.close()
	print("[silhouette] OK : %d vue(s)" % manifeste.size())
	quit(0)


## Remplace TOUT matériau par l'aplat. `material_override` gagne sur les
## surcharges de surface comme sur le matériau du maillage : une seule
## écriture par nœud suffit, et rien ne peut repasser devant.
func _aplatir(noeud: Node, aplat: StandardMaterial3D) -> int:
	var total: int = 0
	for enfant: Node in noeud.find_children("*", "GeometryInstance3D", true, false):
		(enfant as GeometryInstance3D).material_override = aplat
		(enfant as GeometryInstance3D).cast_shadow = \
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		total += 1
	if noeud is GeometryInstance3D:
		(noeud as GeometryInstance3D).material_override = aplat
		total += 1
	return total


## Emprise MONDE, accumulée sur toutes les instances géométriques.
## `GeometryInstance3D` et non `MeshInstance3D` : un MultiMesh échapperait
## au second (tools/CLAUDE.md), et une emprise fausse cadre à côté.
func _emprise(sujet: Node3D) -> AABB:
	var total: AABB = AABB()
	var premier: bool = true
	for enfant: Node in sujet.find_children("*", "GeometryInstance3D", true, false):
		var instance: GeometryInstance3D = enfant as GeometryInstance3D
		var locale: AABB = instance.get_aabb()
		var monde: AABB = instance.global_transform * locale
		if premier:
			total = monde
			premier = false
		else:
			total = total.merge(monde)
	return total


func _capturer(camera: Camera3D, boite: AABB, angle_deg: float) -> Image:
	var centre: Vector3 = boite.get_center()
	var rayon: float = boite.size.length() * 0.5
	var a: float = deg_to_rad(angle_deg)
	camera.position = centre + Vector3(cos(a), 0.0, sin(a)) * (rayon * 4.0 + 10.0)
	camera.look_at(centre, Vector3.UP)
	# Projection orthogonale : la taille cadre la HAUTEUR. Le sujet est
	# vertical, donc c'est elle qui commande, et la marge est identique
	# d'une vue à l'autre — condition d'une comparaison honnête.
	var largeur_apparente: float = maxf(boite.size.x, boite.size.z)
	var hauteur_requise: float = maxf(
		boite.size.y, largeur_apparente * float(_height) / float(_width))
	camera.size = hauteur_requise * (1.0 + MARGE * 2.0)
	camera.make_current()
	for i: int in range(_settle_frames):
		await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null:
		printerr("[silhouette] ÉCHEC : rendu nul à %.0f°" % angle_deg)
	return image


## LE FILET. Une vraie silhouette n'a que deux populations de pixels. On
## tolère une frange d'anticrénelage — mesurée, pas supposée — mais pas un
## fond de scène. Le contrôle négatif est direct : passer une capture de
## jeu ici la ferait rougir immédiatement.
func _controle_bimodal(image: Image) -> Dictionary:
	var sujet: int = 0
	var fond: int = 0
	var hors: int = 0
	var pas: int = 2   # échantillonnage : 1 pixel sur 4, largement suffisant
	var total: int = 0
	for y: int in range(0, image.get_height(), pas):
		for x: int in range(0, image.get_width(), pas):
			var v: float = image.get_pixel(x, y).get_luminance()
			total += 1
			if v <= 0.18:
				sujet += 1
			elif v >= 0.62:
				fond += 1
			else:
				hors += 1
	var hors_pct: float = 100.0 * float(hors) / float(maxi(total, 1))
	return {
		"bimodal": hors_pct <= 3.0,
		"sujet_pct": 100.0 * float(sujet) / float(maxi(total, 1)),
		"fond_pct": 100.0 * float(fond) / float(maxi(total, 1)),
		"hors_bandes_pct": hors_pct,
	}


func _current_commit() -> String:
	var out: Array = []
	var rc: int = OS.execute("git", ["-C",
		ProjectSettings.globalize_path("res://"), "rev-parse", "HEAD"],
		out, true)
	if rc != 0 or out.is_empty():
		return "inconnu"
	return String(out[0]).strip_edges()


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
