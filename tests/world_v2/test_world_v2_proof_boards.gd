## V2.3-A.R — FILET des PLANCHES DE PREUVE : une planche vide ne part
## plus en revue.
##
## Écrit ROUGE d'abord sur les planches livrées en V2.3-A (code aa45a74).
## Mesuré : `planche_silhouettes_v23a.png` et
## `planche_niveaux_de_gris_v23a.png` ne contenaient **qu'une seule
## couleur**, `#141416` — le fond. `Image.blit_rect()` exige des formats
## identiques ; les captures se chargent en RGBA8, la planche était créée
## en RGB8, et chaque collage échouait SANS ERREUR. Deux fichiers de
## preuve entièrement vides ont donc été livrés au lead, qui les a vus le
## premier. Aucun test ne regardait le CONTENU d'une preuve.
##
## Ce filet regarde donc le contenu, tuile par tuile :
##   1. la planche existe et n'est pas uniforme (le défaut exact) ;
##   2. son manifeste liste les tuiles ;
##   3. chaque tuile porte réellement son sujet — fond largement
##      recouvert, luminance variée, moyenne cohérente avec la capture
##      source (une tuile ratée retombe sur le fond et se dénonce) ;
##   4. une planche annoncée « niveaux de gris » l'est vraiment.
extends GateTestCase

## Les planches VIVANTES — celles qui partent en preuve. Les deux planches
## vides de V2.3-A sont conservées sous
## `evidence/world_v2/v2_3/controles/planches_vides_v23a/` : ce filet les a
## fait rougir deux fois (journaux dans `controles/`), elles restent le
## contrôle négatif de référence et NE doivent pas revenir ici.
const BOARDS: Array[String] = [
	"res://evidence/world_v2/v2_3/planche_silhouettes_v23ar.png",
	"res://evidence/world_v2/v2_3/planche_niveaux_de_gris_v23ar.png",
]

## Une planche entière : au moins ce nombre de couleurs distinctes.
const MIN_BOARD_COLORS: int = 256
## … mais une planche en NIVEAUX DE GRIS ne peut pas en porter 256 :
## r = v = b, donc son plafond arithmétique EST 256, atteint seulement si
## chacune des 256 valeurs apparaît. Mesuré sur la planche réparée : 237.
## Le seuil couleur y était donc IMPOSSIBLE à franchir — un test qui ne
## pouvait que rougir, quelle que soit la qualité de la preuve.
##
## Ce n'est pas un seuil qu'on abaisse pour faire passer une correction
## (le lead l'interdit, à raison) : c'est une borne fausse qu'on remplace
## par la borne juste. Le vrai détecteur de planche vide reste
## `MIN_BOARD_STDDEV`, qui vaut 0,0000 sur un aplat et ne dépend d'aucune
## palette — et les deux planches vides de V2.3-A échouent toujours sur
## LES DEUX critères (1 couleur, écart-type nul).
const MIN_GRAY_BOARD_COLORS: int = 64
## Une planche entière : écart-type de luminance minimal.
const MIN_BOARD_STDDEV: float = 0.05
## Une tuile : fraction minimale de pixels DIFFÉRENTS du fond.
const MIN_TILE_SUBJECT_RATIO: float = 0.60
## Une tuile : écart-type de luminance minimal (une tuile plate est vide).
const MIN_TILE_STDDEV: float = 0.03
## Une tuile : écart maximal entre sa luminance moyenne et celle de la
## capture source — c'est ce qui prouve que le SUJET est là, pas un aplat.
const MAX_TILE_LUMA_DRIFT: float = 0.08
## Saturation maximale tolérée sur une planche en niveaux de gris.
const MAX_GRAY_SATURATION: float = 0.02


func test_les_planches_de_preuve_portent_vraiment_leurs_sujets() -> void:
	var faults: Array[String] = []
	for board_path: String in BOARDS:
		faults.append_array(_board_faults(board_path))
	var shown: Array[String] = faults.slice(0, 8)
	if faults.size() > 8:
		shown.append("… et %d autres" % (faults.size() - 8))
	check(faults.is_empty(),
		"les planches de preuve portent leurs sujets (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(shown)])


func _board_faults(board_path: String) -> Array[String]:
	var faults: Array[String] = []
	var absolute: String = ProjectSettings.globalize_path(board_path)
	var board: Image = Image.load_from_file(absolute)
	if board == null:
		return ["%s : planche ABSENTE ou illisible" % board_path.get_file()]

	# 1. La planche entière n'est pas un aplat (le défaut exact de V2.3-A).
	var stats: Dictionary = _region_stats(board,
		Rect2i(0, 0, board.get_width(), board.get_height()))
	var gray_board: bool = board_path.get_file().contains("niveaux_de_gris")
	var min_colors: int = MIN_GRAY_BOARD_COLORS if gray_board \
		else MIN_BOARD_COLORS
	if int(stats["colors"]) < min_colors:
		faults.append("%s : %d couleur(s) sur toute la planche (< %d) — VIDE"
			% [board_path.get_file(), int(stats["colors"]), min_colors])
	if float(stats["stddev"]) < MIN_BOARD_STDDEV:
		faults.append("%s : écart-type de luminance %.4f — aplat"
			% [board_path.get_file(), float(stats["stddev"])])

	# 2. Le manifeste des tuiles.
	var manifest_path: String = absolute.get_basename() + ".json"
	if not FileAccess.file_exists(manifest_path):
		faults.append("%s : manifeste de tuiles ABSENT (%s)"
			% [board_path.get_file(), manifest_path.get_file()])
		return faults
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(manifest_path))
	if not (parsed is Dictionary):
		faults.append("%s : manifeste illisible" % board_path.get_file())
		return faults
	var manifest: Dictionary = parsed as Dictionary
	var tiles: Array = manifest.get("tiles", []) as Array
	if tiles.is_empty():
		faults.append("%s : manifeste sans tuile" % board_path.get_file())
		return faults
	var background: Color = Color(String(manifest.get("background", "141416")))
	var grayscale: bool = bool(manifest.get("grayscale", false))

	# 3. Chaque tuile porte son sujet.
	for entry: Variant in tiles:
		var tile: Dictionary = entry as Dictionary
		var rect: Rect2i = Rect2i(int(tile["x"]), int(tile["y"]),
			int(tile["width"]), int(tile["height"]))
		var label: String = String(tile.get("source", "?")).get_file()
		var tile_stats: Dictionary = _region_stats(board, rect, background)
		if float(tile_stats["subject_ratio"]) < MIN_TILE_SUBJECT_RATIO:
			faults.append("%s/%s : %.0f %% de la tuile est le FOND"
				% [board_path.get_file(), label,
					(1.0 - float(tile_stats["subject_ratio"])) * 100.0])
			continue
		if float(tile_stats["stddev"]) < MIN_TILE_STDDEV:
			faults.append("%s/%s : tuile plate (écart-type %.4f)"
				% [board_path.get_file(), label, float(tile_stats["stddev"])])
		var expected: float = float(tile.get("source_luma_mean", -1.0))
		if expected >= 0.0 \
				and absf(float(tile_stats["mean"]) - expected) > MAX_TILE_LUMA_DRIFT:
			faults.append("%s/%s : luminance %.3f, source %.3f — sujet absent"
				% [board_path.get_file(), label, float(tile_stats["mean"]),
					expected])
		if grayscale and float(tile_stats["max_saturation"]) > MAX_GRAY_SATURATION:
			faults.append("%s/%s : saturation %.3f sur une planche NIVEAUX DE GRIS"
				% [board_path.get_file(), label,
					float(tile_stats["max_saturation"])])
	return faults


## Statistiques d'une région : couleurs distinctes, moyenne et écart-type
## de luminance, saturation maximale, et fraction de pixels différents du
## fond (« rapport sujet/fond »).
func _region_stats(image: Image, rect: Rect2i,
		background: Color = Color.TRANSPARENT) -> Dictionary:
	var colors: Dictionary = {}
	var total: float = 0.0
	var total_squared: float = 0.0
	var max_saturation: float = 0.0
	var subject: int = 0
	var count: int = 0
	var step: int = 2
	for y: int in range(rect.position.y, rect.end.y, step):
		for x: int in range(rect.position.x, rect.end.x, step):
			var c: Color = image.get_pixel(x, y)
			colors[c.to_html(false)] = true
			var luma: float = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			total += luma
			total_squared += luma * luma
			max_saturation = maxf(max_saturation,
				maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b)))
			if background.a > 0.0:
				if absf(c.r - background.r) > 0.02 \
						or absf(c.g - background.g) > 0.02 \
						or absf(c.b - background.b) > 0.02:
					subject += 1
			count += 1
	var mean: float = total / maxf(float(count), 1.0)
	var variance: float = maxf(total_squared / maxf(float(count), 1.0)
		- mean * mean, 0.0)
	return {
		"colors": colors.size(),
		"mean": mean,
		"stddev": sqrt(variance),
		"max_saturation": max_saturation,
		"subject_ratio": float(subject) / maxf(float(count), 1.0),
	}
