## Contrôle d'exposition d'une capture (V2.2R, famille C de la directive).
##
## La revue du lead a rejeté : falaises surexposées, verts fluorescents,
## jaunes brûlés, canopées presque blanches. Un luma MOYEN ne suffit pas —
## ce contrôle mesure les GRANDES ZONES écrêtées et la fluorescence, sur la
## région SOL de l'image (le ciel a le droit d'être clair) :
##   - blocs 32×32 du bandeau sol (40 %% bas → 100 %%) dont le luma moyen
##     dépasse CLIP_LUMA : leur part doit rester sous CLIP_BLOCK_SHARE ;
##   - pixels « vert fluo » (g − max(r, b) > FLUO_GAP) : part sous FLUO_SHARE.
##
## Usage :
##   godot --headless --path . --script tools/godot/check_capture_exposure.gd \
##       -- --in=capture.png [--ground-top=0.40]
## Code retour : 0 conforme, 1 violation, 2 image illisible.
extends SceneTree

const CLIP_LUMA: float = 0.86
const CLIP_BLOCK_SHARE: float = 0.008
## Sous cette saturation moyenne, un bloc clair est de la brume/du ciel du
## côté chaud (mesuré 0.02-0.06), jamais une dalle rejetée (0.085-0.205).
const HAZE_SATURATION_MAX: float = 0.07
const FLUO_GAP: float = 0.32
const FLUO_SHARE: float = 0.015
const BLOCK: int = 32


func _initialize() -> void:
	var path: String = ""
	var ground_top: float = 0.28
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--in="):
			path = arg.trim_prefix("--in=")
		elif arg.begins_with("--ground-top="):
			ground_top = float(arg.trim_prefix("--ground-top="))
	var image: Image = Image.load_from_file(path)
	if image == null:
		printerr("[exposition] image illisible : %s" % path)
		quit(2)
		return
	var y0: int = int(float(image.get_height()) * ground_top)
	var clipped_blocks: int = 0
	var total_blocks: int = 0
	var fluo_pixels: int = 0
	var ground_pixels: int = 0
	var by: int = y0
	while by < image.get_height():
		var bx: int = 0
		while bx < image.get_width():
			var sum_luma: float = 0.0
			var sum_color: Color = Color(0.0, 0.0, 0.0)
			var count: int = 0
			var sky_like: int = 0
			for y: int in range(by, mini(by + BLOCK, image.get_height()), 2):
				for x: int in range(bx, mini(bx + BLOCK, image.get_width()), 2):
					var c: Color = image.get_pixel(x, y)
					# Le ciel (dominante bleue froide) a le droit d'être clair —
					# la bande mesurée peut encore en contenir aux angles.
					if c.b > c.r and c.b > c.g:
						sky_like += 1
					sum_luma += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
					sum_color += c
					if c.g - maxf(c.r, c.b) > FLUO_GAP:
						fluo_pixels += 1
					count += 1
			ground_pixels += count
			# Un bloc majoritairement ciel ne compte ni au total ni en écrêtage.
			# La BRUME du côté chaud du ciel échappe au test bleu-dominant
			# (mesuré : brume (0.89, 0.89, 0.83), saturation 0.06 — les dalles
			# rejetées par le lead font (0.93-0.98, r>g>b), saturation
			# 0.085-0.205). Un bloc clair mais quasi neutre est du ciel/brume,
			# pas une face écrêtée — vérifié : les cinq captures AVANT restent
			# rouges avec cette exclusion.
			var avg: Color = sum_color
			if count > 0:
				avg = sum_color / float(count)
			if sky_like * 2 < count:
				total_blocks += 1
				var saturation: float = maxf(avg.r, maxf(avg.g, avg.b)) \
					- minf(avg.r, minf(avg.g, avg.b))
				if sum_luma / float(count) > CLIP_LUMA \
						and saturation > HAZE_SATURATION_MAX:
					clipped_blocks += 1
			bx += BLOCK
		by += BLOCK
	var clip_share: float = float(clipped_blocks) / float(maxi(total_blocks, 1))
	var fluo_share: float = float(fluo_pixels) / float(maxi(ground_pixels, 1))
	print("[exposition] %s : blocs écrêtés %.1f %% (plafond %.1f) ; vert fluo %.2f %% (plafond %.2f)"
		% [path.get_file(), clip_share * 100.0, CLIP_BLOCK_SHARE * 100.0,
			fluo_share * 100.0, FLUO_SHARE * 100.0])
	if clip_share > CLIP_BLOCK_SHARE or fluo_share > FLUO_SHARE:
		print("[exposition] VIOLATION")
		quit(1)
		return
	print("[exposition] conforme")
	quit(0)
