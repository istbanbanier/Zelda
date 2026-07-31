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
var _allow_uniform: bool = false
var _min_visuals: int = 1
var _allow_unknown_commit: bool = false


## Statistiques de contenu : sert à prouver qu'une image a été *rendue*, pas
## seulement écrite. Échantillonnage régulier pour rester peu coûteux en 1440p.
func _analyse(image: Image) -> Dictionary:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var step: int = maxi(1, mini(width, height) / 64)
	var seen: Dictionary = {}
	var lumas: Array[float] = []
	var y: int = 0
	while y < height:
		var x: int = 0
		while x < width:
			var c: Color = image.get_pixel(x, y)
			seen[c.to_rgba32()] = true
			lumas.append(c.get_luminance())
			x += step
		y += step
	var mean: float = 0.0
	for l: float in lumas:
		mean += l
	mean /= maxf(1.0, float(lumas.size()))
	var variance: float = 0.0
	for l: float in lumas:
		variance += (l - mean) * (l - mean)
	variance /= maxf(1.0, float(lumas.size()))
	return {
		"distinct": seen.size(),
		"mean_luma": mean,
		"stddev": sqrt(variance),
		"samples": lumas.size(),
	}


## Commit auquel la capture correspond : sans lui une preuve visuelle n'est
## rattachable à aucun état du dépôt (défaut D7).
func _current_commit() -> String:
	var out: Array = []
	var rc: int = OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"),
		"rev-parse", "HEAD"], out, true)
	if rc != 0 or out.is_empty():
		return "inconnu"
	return String(out[0]).strip_edges()


func _repo_is_dirty() -> bool:
	var out: Array = []
	var rc: int = OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"),
		"status", "--porcelain"], out, true)
	if rc != 0 or out.is_empty():
		return true
	return String(out[0]).strip_edges() != ""


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
		elif arg == "--allow-uniform":
			_allow_uniform = true
		elif arg == "--allow-unknown-commit":
			_allow_unknown_commit = true
		elif arg.begins_with("--min-visuals="):
			_min_visuals = maxi(0, arg.trim_prefix("--min-visuals=").to_int())
		elif arg.begins_with("--size="):
			var parts: PackedStringArray = arg.trim_prefix("--size=").split("x")
			if parts.size() == 2:
				_width = parts[0].to_int()
				_height = parts[1].to_int()


## Compte la géométrie réellement susceptible d'apparaître à l'image.
##
## Trois pièges démontrés par la 3e revue adverse, tous corrigés ici :
##   - `Light3D` dérive de `VisualInstance3D` : une scène « ciel + caméra + soleil »
##     passait pour de la géométrie. On exige donc `GeometryInstance3D`.
##   - un `MeshInstance3D` sans maillage assigné comptait quand même : on vérifie
##     que la ressource existe et possède au moins une surface.
##   - `node.visible` est LOCAL : un vrai cube sous un parent masqué comptait.
##     On utilise `is_visible_in_tree()`.
func _count_visual_instances(node: Node) -> int:
	var total: int = 0
	if node is GeometryInstance3D and (node as Node3D).is_visible_in_tree():
		if _has_renderable_geometry(node as GeometryInstance3D):
			total += 1
	for child: Node in node.get_children():
		total += _count_visual_instances(child)
	return total


func _has_renderable_geometry(instance: GeometryInstance3D) -> bool:
	if instance is MeshInstance3D:
		var mesh: Mesh = (instance as MeshInstance3D).mesh
		return mesh != null and mesh.get_surface_count() > 0
	if instance is MultiMeshInstance3D:
		var mm: MultiMesh = (instance as MultiMeshInstance3D).multimesh
		return mm != null and mm.mesh != null and mm.instance_count > 0
	# CSG, particules, labels 3D… : pas de ressource simple à interroger, on les
	# accepte plutôt que de rejeter à tort une scène légitime.
	return true


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

	# N4 : compter les couleurs ne prouve pas qu'une géométrie a été rendue — une
	# scène réduite à un ciel procédural produisait 863 couleurs distinctes, plus
	# que la vraie capture de référence. On interroge donc la scène elle-même.
	# Le comptage a lieu APRÈS les frames d'attente : la visibilité héritée et les
	# `_ready()` ne sont pas encore établis au moment de `add_child()`.
	var visuals: int = _count_visual_instances(instance)
	print("[capture] géométrie : %d géométrie(s) visible(s) dans la scène" % visuals)
	if visuals < _min_visuals:
		printerr("[capture] ÉCHEC: %d géométrie(s) visible(s), minimum exigé %d — "
			% [visuals, _min_visuals]
			+ "la scène ne contient pas la géométrie attendue. "
			+ "Utiliser --min-visuals=0 si une scène sans mesh est réellement voulue.")
		quit(5)
		return

	var image: Image = root.get_texture().get_image()
	if image == null:
		printerr("[capture] ÉCHEC: viewport sans image — aucun rendu produit.")
		quit(2)
		return

	# Défaut D6 de la revue adverse : écrire un PNG ne prouve pas qu'une scène a été
	# rendue. Une scène vide produisait un fichier valide, avec manifeste complet,
	# indiscernable d'une vraie capture. On exige donc un contenu non uniforme.
	var stats: Dictionary = _analyse(image)
	print("[capture] contenu   : %d couleurs distinctes (échantillon), écart-type luma %.2f"
		% [stats["distinct"], stats["stddev"]])
	if not _allow_uniform and int(stats["distinct"]) < 2:
		printerr("[capture] ÉCHEC: image uniforme (%d couleur) — aucune géométrie rendue. "
			% int(stats["distinct"])
			+ "Utiliser --allow-uniform si une image unie est réellement attendue.")
		quit(4)
		return

	# Le rattachement au commit est vérifié AVANT toute écriture : sinon un PNG
	# orphelin, sans manifeste, restait sur le disque après l'échec.
	var commit: String = _current_commit()
	if commit == "inconnu" and not _allow_unknown_commit:
		printerr("[capture] ÉCHEC: commit indéterminé — une preuve visuelle non "
			+ "rattachable à un état du dépôt n'a pas de valeur (§21.8). "
			+ "Utiliser --allow-unknown-commit pour une capture jetable.")
		quit(6)
		return

	# --out accepte un chemin relatif au projet ou un chemin absolu ; joindre
	# aveuglément un chemin absolu à res:// crée un dossier fantôme dans le dépôt.
	var abs_out: String = _out_path
	if not _out_path.is_absolute_path():
		abs_out = ProjectSettings.globalize_path("res://").path_join(_out_path)
	DirAccess.make_dir_recursive_absolute(abs_out.get_base_dir())
	var err: Error = image.save_png(abs_out)
	if err != OK:
		printerr("[capture] ÉCHEC: écriture PNG impossible (%d) vers %s" % [err, abs_out])
		quit(3)
		return

	_write_manifest(abs_out, image, stats, commit)
	print("[capture] OK -> %s (%dx%d)" % [abs_out, image.get_width(), image.get_height()])
	quit(0)


func _write_manifest(png_abs: String, image: Image, stats: Dictionary, commit: String) -> void:
	var manifest: Dictionary = {
		"label": _label,
		"commit": commit,
		"repo_dirty": _repo_is_dirty(),
		"distinct_colors_sampled": stats.get("distinct", 0),
		"luma_mean": snappedf(float(stats.get("mean_luma", 0.0)), 0.0001),
		"luma_stddev": snappedf(float(stats.get("stddev", 0.0)), 0.0001),
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
