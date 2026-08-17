## Montages A/B RÉELS (V2.2R §2) : V2.1 à GAUCHE, V2.2R à DROITE — mêmes
## caméras gelées, même FOV, même résolution. Aucun redressement, aucun
## recadrage : les deux PNG sont posés côte à côte tels que capturés, avec
## un libellé rendu au-dessus de chaque moitié.
##
## Exige un renderer réel (xvfb + opengl3) pour le texte — jamais --headless.
##
## Usage (une paire par argument, champs séparés par « | ») :
##   xvfb-run -a godot --path . --rendering-driver opengl3 \
##       --script tools/godot/compose_ab_montages.gd -- \
##       "--pair=gauche.png|droite.png|sortie.png|cam01 — crête du spawn"
extends SceneTree

var _pairs: Array[PackedStringArray] = []


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--pair="):
			var fields: PackedStringArray = arg.trim_prefix("--pair=").split("|")
			## SIX CHAMPS, PLUS DE DÉFAUT — et voici ce que le défaut a coûté.
			##
			## L'outil acceptait quatre champs et stampait alors « AVANT —
			## V2.1 whitebox » et « APRÈS — V2.2R » quelles que soient les
			## images. Les A/B de la grotte R2a-3.2 comparaient R2a-3.1 à la
			## tranche 2 : les deux bandeaux étaient donc FAUX, et le lead
			## l'a relevé. L'image, elle, était juste — c'est précisément ce
			## qui rend ce défaut coûteux : rien dans le montage ne crie
			## l'erreur, et il finit dans un dossier de preuves.
			##
			## Même leçon que `--scene=` dans capture_poi_batch : un défaut
			## qui produit un artefact plausible ne se rattrape pas à l'œil.
			## On exige donc les deux libellés, toujours.
			if fields.size() != 6:
				printerr("[montage] paire invalide : SIX champs exigés — "
					+ "gauche|droite|sortie|titre|libelle_gauche|"
					+ "libelle_droite. Reçu %d : %s" % [fields.size(), arg])
				quit(1)
				return
			_pairs.append(fields)
	if _pairs.is_empty():
		printerr("[montage] aucune paire fournie")
		quit(1)
		return
	_run()


func _run() -> void:
	for fields: PackedStringArray in _pairs:
		var left_tag: String = fields[4]
		var right_tag: String = fields[5]
		var ok: bool = await _compose(fields[0], fields[1], fields[2],
			fields[3], left_tag, right_tag)
		if not ok:
			quit(2)
			return
	print("[montage] OK — %d montage(s)" % _pairs.size())
	quit(0)


func _compose(left_path: String, right_path: String, out_path: String,
		title: String, left_tag: String, right_tag: String) -> bool:
	var left: Image = Image.load_from_file(_absolute(left_path))
	var right: Image = Image.load_from_file(_absolute(right_path))
	if left == null or right == null:
		printerr("[montage] image illisible : %s / %s" % [left_path, right_path])
		return false
	if left.get_size() != right.get_size():
		printerr("[montage] RÉSOLUTIONS DIFFÉRENTES (%s vs %s) — un montage "
			% [left.get_size(), right.get_size()]
			+ "A/B n'a de sens qu'à cadre identique : %s" % out_path)
		return false
	var w: int = left.get_width()
	var h: int = left.get_height()
	var header: int = 64
	var gap: int = 4
	DisplayServer.window_set_size(Vector2i(w * 2 + gap, h + header))
	root.content_scale_size = Vector2i(w * 2 + gap, h + header)

	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 20
	root.add_child(layer)
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.08, 0.08, 0.10)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(background)
	var left_rect: TextureRect = TextureRect.new()
	left_rect.texture = ImageTexture.create_from_image(left)
	left_rect.position = Vector2(0, header)
	layer.add_child(left_rect)
	var right_rect: TextureRect = TextureRect.new()
	right_rect.texture = ImageTexture.create_from_image(right)
	right_rect.position = Vector2(w + gap, header)
	layer.add_child(right_rect)
	var left_label: Label = Label.new()
	left_label.text = "%s · %s" % [left_tag, title]
	left_label.position = Vector2(16, 16)
	left_label.add_theme_font_size_override(&"font_size", 24)
	layer.add_child(left_label)
	var right_label: Label = Label.new()
	right_label.text = "%s · %s" % [right_tag, title]
	right_label.position = Vector2(w + gap + 16, 16)
	right_label.add_theme_font_size_override(&"font_size", 24)
	layer.add_child(right_label)

	for i: int in range(6):
		await process_frame
	var shot: Image = root.get_texture().get_image()
	var global_out: String = _absolute(out_path)
	DirAccess.make_dir_recursive_absolute(global_out.get_base_dir())
	if shot.save_png(global_out) != OK:
		printerr("[montage] ÉCHEC d'écriture : %s" % out_path)
		return false
	## Les clés s'appelaient `gauche_v2_1` et `droite_v2_2r` : un nom de
	## jalon figé dans un format de données. Tout A/B ultérieur héritait donc
	## d'une étiquette fausse jusque dans son manifeste. La clé dit le CÔTÉ ;
	## le jalon est une valeur, et il vit à côté du chemin qu'il décrit.
	var manifest: Dictionary = {
		"gauche": left_path,
		"gauche_libelle": left_tag,
		"droite": right_path,
		"droite_libelle": right_tag,
		"png": out_path,
		"titre": title,
		"resolution_par_moitie": "%dx%d" % [w, h],
		"timestamp_utc": Time.get_datetime_string_from_system(true, true),
	}
	var manifest_file: FileAccess = FileAccess.open(
		global_out.get_basename() + ".json", FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest, " ", false))
	manifest_file.close()
	print("[montage] écrit : %s" % out_path)
	layer.queue_free()
	await process_frame
	return true


func _absolute(path: String) -> String:
	if path.begins_with("/"):
		return path
	return ProjectSettings.globalize_path("res://" + path)
