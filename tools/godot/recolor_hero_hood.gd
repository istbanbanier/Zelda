## V4 lot 13 — capuche du héros RÉELLEMENT bleu-vert (§7.11 : « bande/cape
## turquoise », palette §3.4 tissu #168F9B), sans teinter peau ni cuir.
##
## Méthode : la pièce modulaire Male_Ranger_Head_Hood (même UV que la tenue
## complète, matériau MI_Ranger) fournit le MASQUE — ses triangles UV sont
## rasterisés sur la texture, puis la teinte des pixels masqués est virée
## vers le turquoise cible en conservant la luminance. Sortie : une texture
## DÉRIVÉE committée + manifeste JSON. Déterministe et rejouable :
##
##   godot --headless --path . --script tools/godot/recolor_hero_hood.gd
##
## L'édition d'un asset CC0 est licite ; la dérivation est consignée dans
## ATTRIBUTIONS.md (source, script, nature de la modification).
extends SceneTree

const HOOD_PART: String = "res://assets/characters/parts/Male_Ranger_Head_Hood.gltf"
const SOURCE_TEXTURE: String = "res://assets/characters/hero/T_Ranger_BaseColor.png"
const OUTPUT_TEXTURE: String = "res://assets/characters/hero/T_Ranger_Hero_BaseColor.png"
## Tissu turquoise §3.4.
const TARGET_HUE: float = 0.518
const TARGET_SATURATION: float = 0.72
## Dilatation du masque (px) : couvre le bleed des mips aux coutures UV.
const MASK_DILATION: int = 2


func _init() -> void:
	var packed: PackedScene = load(HOOD_PART) as PackedScene
	if packed == null:
		push_error("[recolor] pièce capuche introuvable : %s" % HOOD_PART)
		quit(1)
		return
	var source_image: Image = (load(SOURCE_TEXTURE) as Texture2D).get_image()
	source_image.decompress()
	source_image.convert(Image.FORMAT_RGBA8)
	var width: int = source_image.get_width()
	var height: int = source_image.get_height()

	var mask: PackedByteArray = PackedByteArray()
	mask.resize(width * height)
	var triangles: int = _rasterize_part_uvs(packed, mask, width, height)
	if triangles == 0:
		push_error("[recolor] aucun triangle UV rasterisé — masque vide.")
		quit(1)
		return
	for i: int in range(MASK_DILATION):
		mask = _dilate(mask, width, height)

	var recolored: int = 0
	for y: int in range(height):
		for x: int in range(width):
			if mask[y * width + x] == 0:
				continue
			var pixel: Color = source_image.get_pixel(x, y)
			var shifted: Color = Color.from_hsv(TARGET_HUE,
				clampf(pixel.s * 0.4 + TARGET_SATURATION * 0.6, 0.0, 1.0),
				pixel.v, pixel.a)
			source_image.set_pixel(x, y, shifted)
			recolored += 1
	var error: int = source_image.save_png(OUTPUT_TEXTURE)
	if error != OK:
		push_error("[recolor] échec d'écriture : %d" % error)
		quit(1)
		return
	var manifest: Dictionary = {
		"source": SOURCE_TEXTURE,
		"mask_part": HOOD_PART,
		"output": OUTPUT_TEXTURE,
		"triangles": triangles,
		"pixels_recolored": recolored,
		"target_hue": TARGET_HUE,
		"dilation": MASK_DILATION,
		"engine": Engine.get_version_info()["string"],
	}
	var handle: FileAccess = FileAccess.open(
		OUTPUT_TEXTURE.replace(".png", ".manifest.json"), FileAccess.WRITE)
	handle.store_string(JSON.stringify(manifest, "  "))
	handle.close()
	print("[recolor] %d triangle(s), %d pixel(s) -> %s"
		% [triangles, recolored, OUTPUT_TEXTURE])
	quit(0)


func _rasterize_part_uvs(packed: PackedScene, mask: PackedByteArray,
		width: int, height: int) -> int:
	var triangles: int = 0
	var root: Node = packed.instantiate()
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (node as MeshInstance3D).mesh
		if mesh == null:
			continue
		for surface: int in range(mesh.get_surface_count()):
			var arrays: Array = mesh.surface_get_arrays(surface)
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for i: int in range(0, indices.size(), 3):
				_fill_triangle(mask, width, height, uvs[indices[i]],
					uvs[indices[i + 1]], uvs[indices[i + 2]])
				triangles += 1
	root.free()
	return triangles


## Remplissage barycentrique borné à la boîte du triangle — texture unique,
## exécution unique : la simplicité prime sur la vitesse.
func _fill_triangle(mask: PackedByteArray, width: int, height: int,
		a: Vector2, b: Vector2, c: Vector2) -> void:
	var pa: Vector2 = Vector2(a.x * width, a.y * height)
	var pb: Vector2 = Vector2(b.x * width, b.y * height)
	var pc: Vector2 = Vector2(c.x * width, c.y * height)
	var min_x: int = maxi(0, int(floorf(minf(pa.x, minf(pb.x, pc.x)))))
	var max_x: int = mini(width - 1, int(ceilf(maxf(pa.x, maxf(pb.x, pc.x)))))
	var min_y: int = maxi(0, int(floorf(minf(pa.y, minf(pb.y, pc.y)))))
	var max_y: int = mini(height - 1, int(ceilf(maxf(pa.y, maxf(pb.y, pc.y)))))
	var denominator: float = (pb.y - pc.y) * (pa.x - pc.x) \
		+ (pc.x - pb.x) * (pa.y - pc.y)
	if absf(denominator) < 0.000001:
		return
	for y: int in range(min_y, max_y + 1):
		for x: int in range(min_x, max_x + 1):
			var point: Vector2 = Vector2(float(x) + 0.5, float(y) + 0.5)
			var u: float = ((pb.y - pc.y) * (point.x - pc.x)
				+ (pc.x - pb.x) * (point.y - pc.y)) / denominator
			var v: float = ((pc.y - pa.y) * (point.x - pc.x)
				+ (pa.x - pc.x) * (point.y - pc.y)) / denominator
			if u >= -0.001 and v >= -0.001 and u + v <= 1.001:
				mask[y * width + x] = 1


func _dilate(mask: PackedByteArray, width: int, height: int) -> PackedByteArray:
	var grown: PackedByteArray = mask.duplicate()
	for y: int in range(height):
		for x: int in range(width):
			if mask[y * width + x] == 0:
				continue
			for offset: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0),
					Vector2i(0, -1), Vector2i(0, 1)]:
				var nx: int = x + offset.x
				var ny: int = y + offset.y
				if nx >= 0 and nx < width and ny >= 0 and ny < height:
					grown[ny * width + nx] = 1
	return grown
