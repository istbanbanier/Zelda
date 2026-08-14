## PLANCHE DE MINIATURES (et sa variante niveaux de gris) — outil de preuve.
##
## LE DÉFAUT QU'IL CORRIGE. La première planche V2.3-A était ENTIÈREMENT
## uniforme : une seule couleur, `#141416`, celle du fond. Mesuré après
## coup : `Image.blit_rect()` exige que SOURCE et DESTINATION partagent le
## même format. Les captures PNG se chargent en `FORMAT_RGBA8`, la
## planche était créée en `FORMAT_RGB8` : chaque blit échouait **en
## silence**, sans une seule erreur dans le journal, et la planche partait
## en preuve. Le lead l'a vue, pas nous.
##
## La règle appliquée ici : convertir explicitement chaque vignette au
## format de la planche AVANT de la coller, puis écrire un MANIFESTE JSON
## des tuiles pour que `tests/world_v2/test_world_v2_proof_boards.gd`
## puisse vérifier, tuile par tuile, que le sujet est réellement là.
##
## Usage :
##   godot --headless --path . --script tools/godot/compose_contact_sheet.gd -- \
##       --out=evidence/.../planche.png --columns=3 [--gray] \
##       --sources=a.png,b.png,c.png
extends SceneTree

const THUMB_W: int = 426
const THUMB_H: int = 240
const BACKGROUND: Color = Color(0.08, 0.08, 0.09)

var _out_path: String = ""
var _columns: int = 3
var _gray: bool = false
var _sources: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			_out_path = argument.trim_prefix("--out=")
		elif argument.begins_with("--columns="):
			_columns = maxi(1, argument.trim_prefix("--columns=").to_int())
		elif argument == "--gray":
			_gray = true
		elif argument.begins_with("--sources="):
			_sources = argument.trim_prefix("--sources=").split(",", false)
	if _out_path.is_empty() or _sources.is_empty():
		printerr("[planche] BLOQUÉ : --out= et --sources= requis")
		quit(3)
		return

	var rows: int = int(ceil(float(_sources.size()) / float(_columns)))
	var sheet: Image = Image.create(_columns * THUMB_W, rows * THUMB_H,
		false, Image.FORMAT_RGBA8)
	sheet.fill(BACKGROUND)
	var tiles: Array = []
	for i: int in range(_sources.size()):
		var source_path: String = _sources[i]
		var thumb: Image = Image.load_from_file(source_path)
		if thumb == null:
			printerr("[planche] ÉCHEC : vignette illisible %s" % source_path)
			quit(1)
			return
		thumb.resize(THUMB_W, THUMB_H, Image.INTERPOLATE_LANCZOS)
		if _gray:
			for y: int in range(thumb.get_height()):
				for x: int in range(thumb.get_width()):
					var c: Color = thumb.get_pixel(x, y)
					var v: float = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
					thumb.set_pixel(x, y, Color(v, v, v, 1.0))
		# LA CORRECTION : même format, sinon le blit est un no-op muet.
		if thumb.get_format() != sheet.get_format():
			thumb.convert(sheet.get_format())
		var origin: Vector2i = Vector2i((i % _columns) * THUMB_W,
			(i / _columns) * THUMB_H)
		sheet.blit_rect(thumb, Rect2i(0, 0, THUMB_W, THUMB_H), origin)
		tiles.append({
			"source": source_path,
			"x": origin.x, "y": origin.y,
			"width": THUMB_W, "height": THUMB_H,
			"source_luma_mean": _luma_mean(thumb),
		})
	var error: int = sheet.save_png(_out_path)
	if error != OK:
		printerr("[planche] ÉCHEC d'écriture : %s" % _out_path)
		quit(1)
		return

	var manifest: Dictionary = {
		"png": _out_path,
		"grayscale": _gray,
		"columns": _columns,
		"background": BACKGROUND.to_html(false),
		"tiles": tiles,
	}
	var handle: FileAccess = FileAccess.open(
		_out_path.get_basename() + ".json", FileAccess.WRITE)
	handle.store_string(JSON.stringify(manifest, "\t") + "\n")
	handle.close()
	print("[planche] écrite : %s (%d vignette(s), %s)"
		% [_out_path, _sources.size(),
			"niveaux de gris" if _gray else "couleur"])
	quit(0)


func _luma_mean(image: Image) -> float:
	var total: float = 0.0
	var count: int = 0
	for y: int in range(0, image.get_height(), 4):
		for x: int in range(0, image.get_width(), 4):
			var c: Color = image.get_pixel(x, y)
			total += c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			count += 1
	return total / maxf(float(count), 1.0)
