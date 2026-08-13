## Cartes DOCUMENTAIRES World V2 (V2.2R §2) : carte régionale à onze zones
## avec légende lisible, et carte de densité végétale.
##
## Pourquoi cet outil : la carte régionale de V2.2 était un rendu du ciel —
## la revue du lead l'a rejetée (« onze zones réellement distinctes avec
## légende lisible »). Ici la carte est SCHÉMATIQUE : chaque pixel interroge
## `region_id_at` du vrai bâtisseur (aucune palette recopiée à la main), et
## la densité vient des plans de plantation réellement montés (métas écrites
## dans la même boucle que le moteur). La légende est du texte rendu — cet
## outil exige donc un renderer réel (xvfb + opengl3), jamais `--headless`.
##
## Usage :
##   xvfb-run -a godot --path . --rendering-driver opengl3 \
##       --script tools/godot/render_world_v2_maps.gd -- \
##       --out-dir=evidence/world_v2/v2_2/captures [--label=v22r]
##
## Écrit : carte_regions_legende.png + .json, carte_densite_vegetale.png + .json.
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"
## Étendue cartographiée : le monde jouable (±233 m) + l'anneau (jusqu'à 292 m).
const SPAN_M: int = 600
const HALF_M: float = 300.0
## Cellule de la carte de densité, en mètres.
const DENSITY_CELL_M: float = 8.0
## Onze couleurs FRANCHEMENT distinctes — c'est une carte, pas un rendu :
## la lisibilité prime sur la palette peinte du monde (§30.2 ne s'applique
## pas à un schéma documentaire).
const REGION_COLORS: Dictionary = {
	&"r01_crete_de_l_aube": Color(0.98, 0.83, 0.37),
	&"r02_prairie_mille_fleurs": Color(0.56, 0.83, 0.34),
	&"r03_val_de_neris": Color(0.25, 0.62, 0.40),
	&"r04_falaises_du_couchant": Color(0.80, 0.45, 0.25),
	&"r05_terrasse_du_camp": Color(0.92, 0.62, 0.55),
	&"r06_bois_du_levant": Color(0.13, 0.42, 0.22),
	&"r07_hauteurs_de_l_orient": Color(0.72, 0.60, 0.36),
	&"r08_steppe_du_nord": Color(0.82, 0.78, 0.58),
	&"r09_ruines_du_coeur": Color(0.58, 0.48, 0.66),
	&"r10_marche_de_l_orage": Color(0.42, 0.40, 0.48),
	&"r11_anneau_frontalier": Color(0.36, 0.30, 0.26),
}
const COLOR_WATER: Color = Color(0.22, 0.48, 0.72)
const COLOR_ROUTE: Color = Color(0.35, 0.22, 0.12)
const COLOR_OUTSIDE: Color = Color(0.12, 0.12, 0.14)

var _out_dir: String = "evidence/world_v2/v2_2/captures"
var _label: String = "v22r"
var _world: Node3D = null
var _terrain: RefCounted = null
var _heightmap: RefCounted = null
var _layout: Dictionary = {}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):
			_out_dir = arg.trim_prefix("--out-dir=")
		elif arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
	DisplayServer.window_set_size(Vector2i(1620, 1100))
	root.content_scale_size = Vector2i(1620, 1100)
	_run()


func _run() -> void:
	var packed: PackedScene = load(WORLD) as PackedScene
	if packed == null:
		printerr("[cartes] ÉCHEC : scène introuvable")
		quit(1)
		return
	_world = packed.instantiate() as Node3D
	root.add_child(_world)
	if not _world.is_node_ready():
		await _world.ready
	for i: int in range(10):
		await process_frame
	# Le HUD de jeu n'a rien à faire sur une carte documentaire — mesuré :
	# les cœurs et le panneau d'arme saignaient par-dessus le titre.
	var shell: Node = _world.get_node_or_null("GameplayShell")
	if shell != null:
		shell.set("visible", false)
	_terrain = _world.get("_terrain_builder") as RefCounted
	_heightmap = _world.get("_heightmap") as RefCounted
	var layout_text: String = FileAccess.get_file_as_string(
		"res://resources/world_v2/world_v2_layout.json")
	_layout = JSON.parse_string(layout_text) as Dictionary
	if _terrain == null or _heightmap == null or _layout.is_empty():
		printerr("[cartes] ÉCHEC : bâtisseurs ou layout inaccessibles")
		quit(2)
		return

	var regions_map: Image = _build_regions_image()
	var density: Dictionary = _build_density_data()
	await _compose_and_save(regions_map, _regions_legend(),
		"Vallée de Néris — onze régions contractuelles",
		_out_dir + "/carte_regions_legende.png",
		{"kind": "carte_regions", "span_m": SPAN_M,
			"metres_par_pixel": 1.0, "regions": REGION_COLORS.size()})
	await _compose_and_save(density["image"] as Image,
		_density_legend(float(density["max_density"])),
		"Densité végétale réelle (plans de plantation montés)",
		_out_dir + "/carte_densite_vegetale.png",
		{"kind": "carte_densite", "cell_m": DENSITY_CELL_M,
			"instances_total": density["total"],
			"max_instances_par_m2": density["max_density"]})
	print("[cartes] OK")
	quit(0)


## -- carte régionale ----------------------------------------------------------

func _build_regions_image() -> Image:
	var image: Image = Image.create(SPAN_M, SPAN_M, false, Image.FORMAT_RGB8)
	for pz: int in range(SPAN_M):
		for px: int in range(SPAN_M):
			var x: float = -HALF_M + float(px) + 0.5
			var z: float = -HALF_M + float(pz) + 0.5
			var color: Color = COLOR_OUTSIDE
			if Vector2(x, z).length() <= 292.0:
				var region: StringName = _terrain.call("region_id_at", x, z)
				color = REGION_COLORS.get(region, COLOR_OUTSIDE) as Color
				if bool(_heightmap.call("is_in_water", x, z)):
					color = COLOR_WATER
			image.set_pixel(px, pz, color)
	_stamp_routes(image)
	return image


func _stamp_routes(image: Image) -> void:
	var routes: Dictionary = _layout.get("routes", {}) as Dictionary
	for route_name: String in routes.keys():
		# `shortcuts` est une LISTE, pas une route à jalons — on ne trace
		# que les quatre routes contractuelles.
		if not routes[route_name] is Dictionary:
			continue
		var waypoints: Array = (routes[route_name] as Dictionary) \
			.get("waypoints_xz", []) as Array
		for i: int in range(waypoints.size() - 1):
			var a: Array = waypoints[i] as Array
			var b: Array = waypoints[i + 1] as Array
			_stamp_line(image, Vector2(float(a[0]), float(a[1])),
				Vector2(float(b[0]), float(b[1])))


func _stamp_line(image: Image, a: Vector2, b: Vector2) -> void:
	var steps: int = maxi(2, int(a.distance_to(b)))
	for s: int in range(steps + 1):
		var p: Vector2 = a.lerp(b, float(s) / float(steps))
		var px: int = int(p.x + HALF_M)
		var pz: int = int(p.y + HALF_M)
		for dz: int in range(-1, 2):
			for dx: int in range(-1, 2):
				var qx: int = px + dx
				var qz: int = pz + dz
				if qx >= 0 and qx < SPAN_M and qz >= 0 and qz < SPAN_M:
					image.set_pixel(qx, qz, COLOR_ROUTE)


func _regions_legend() -> Array[Array]:
	var rows: Array[Array] = []
	for entry: Variant in _layout.get("regions", []) as Array:
		var region: Dictionary = entry as Dictionary
		var id: StringName = StringName(String(region.get("id", "")))
		var swatch: Color = REGION_COLORS.get(id, COLOR_OUTSIDE) as Color
		rows.append([swatch, "%s — %s" % [String(id).substr(0, 3),
			String(region.get("name", "?"))]])
	rows.append([COLOR_WATER, "eau (rivières, lac)"])
	rows.append([COLOR_ROUTE, "routes (layout gelé)"])
	rows.append([COLOR_OUTSIDE, "hors région nommée (transitions)"])
	return rows


## -- carte de densité ---------------------------------------------------------

func _build_density_data() -> Dictionary:
	var cells: int = int(float(SPAN_M) / DENSITY_CELL_M)
	var counts: PackedInt32Array = PackedInt32Array()
	counts.resize(cells * cells)
	var total: int = 0
	for node: Node in root.get_tree().get_nodes_in_group(&"world_v2_vegetation"):
		var origins: PackedVector3Array = node.get_meta(&"instance_origins",
			PackedVector3Array()) as PackedVector3Array
		for origin: Vector3 in origins:
			var cx: int = int((origin.x + HALF_M) / DENSITY_CELL_M)
			var cz: int = int((origin.z + HALF_M) / DENSITY_CELL_M)
			if cx >= 0 and cx < cells and cz >= 0 and cz < cells:
				counts[cz * cells + cx] += 1
				total += 1
	var cell_area: float = DENSITY_CELL_M * DENSITY_CELL_M
	var max_density: float = 0.0
	for c: int in counts:
		max_density = maxf(max_density, float(c) / cell_area)
	var image: Image = Image.create(cells, cells, false, Image.FORMAT_RGB8)
	for pz: int in range(cells):
		for px: int in range(cells):
			var density: float = float(counts[pz * cells + px]) / cell_area
			image.set_pixel(px, pz, _density_color(density, max_density))
	return {"image": image, "max_density": max_density, "total": total}


func _density_color(density: float, max_density: float) -> Color:
	if max_density <= 0.0:
		return Color(0.08, 0.09, 0.08)
	var t: float = clampf(density / max_density, 0.0, 1.0)
	if t <= 0.001:
		return Color(0.08, 0.09, 0.08)
	if t < 0.5:
		return Color(0.08, 0.09, 0.08).lerp(Color(0.30, 0.65, 0.25), t * 2.0)
	return Color(0.30, 0.65, 0.25).lerp(Color(1.0, 0.95, 0.55), (t - 0.5) * 2.0)


func _density_legend(max_density: float) -> Array[Array]:
	return [
		[Color(0.08, 0.09, 0.08), "0 instance/m² (vide voulu : steppe, marche)"],
		[Color(0.30, 0.65, 0.25), "%.2f instance/m²" % (max_density * 0.5)],
		[Color(1.0, 0.95, 0.55), "%.2f instance/m² (maximum mesuré)" % max_density],
	]


## -- composition et sauvegarde ------------------------------------------------

func _compose_and_save(map_image: Image, legend: Array[Array], title: String,
		out_path: String, extra: Dictionary) -> void:
	var side: int = 1000
	var scaled: Image = map_image.duplicate() as Image
	scaled.resize(side, side, Image.INTERPOLATE_NEAREST)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 120
	root.add_child(layer)
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.10, 0.10, 0.12)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(background)
	var title_label: Label = Label.new()
	title_label.text = title
	title_label.position = Vector2(40, 18)
	title_label.add_theme_font_size_override(&"font_size", 30)
	layer.add_child(title_label)
	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.texture = ImageTexture.create_from_image(scaled)
	texture_rect.position = Vector2(40, 70)
	texture_rect.size = Vector2(side, side)
	layer.add_child(texture_rect)
	var legend_box: VBoxContainer = VBoxContainer.new()
	legend_box.position = Vector2(side + 70, 90)
	legend_box.add_theme_constant_override(&"separation", 14)
	layer.add_child(legend_box)
	for row: Array in legend:
		var line: HBoxContainer = HBoxContainer.new()
		line.add_theme_constant_override(&"separation", 12)
		var swatch: ColorRect = ColorRect.new()
		swatch.color = row[0] as Color
		swatch.custom_minimum_size = Vector2(30, 30)
		line.add_child(swatch)
		var label: Label = Label.new()
		label.text = String(row[1])
		label.add_theme_font_size_override(&"font_size", 21)
		line.add_child(label)
		legend_box.add_child(line)
	var footer: Label = Label.new()
	footer.text = "1 px = %.1f m · commit %s" % [
		float(SPAN_M) / float(side), _commit().substr(0, 12)]
	footer.position = Vector2(side + 70, 1030)
	footer.add_theme_font_size_override(&"font_size", 16)
	layer.add_child(footer)

	for i: int in range(6):
		await process_frame
	var shot: Image = root.get_texture().get_image()
	var global_out: String = ProjectSettings.globalize_path("res://" + out_path) \
		if not out_path.begins_with("/") else out_path
	DirAccess.make_dir_recursive_absolute(global_out.get_base_dir())
	var err: int = shot.save_png(global_out)
	if err != OK:
		printerr("[cartes] ÉCHEC d'écriture : %s" % global_out)
		quit(3)
		return
	var manifest: Dictionary = {
		"label": _label,
		"png": out_path,
		"commit": _commit(),
		"repo_dirty": _dirty(),
		"engine_version": "%s-%s (%s)" % [Engine.get_version_info()["string"],
			Engine.get_version_info()["status"], Engine.get_version_info()["build"]],
		"rendering_driver": RenderingServer.get_video_adapter_name(),
		"scene": WORLD,
		"timestamp_utc": Time.get_datetime_string_from_system(true, true),
	}
	manifest.merge(extra)
	var manifest_file: FileAccess = FileAccess.open(
		global_out.get_basename() + ".json", FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest, " ", false))
	manifest_file.close()
	print("[cartes] écrit : %s" % out_path)
	layer.queue_free()
	await process_frame


func _commit() -> String:
	var out: Array = []
	var rc: int = OS.execute("git", ["-C",
		ProjectSettings.globalize_path("res://"), "rev-parse", "HEAD"], out, true)
	if rc != 0 or out.is_empty():
		return "inconnu"
	return String(out[0]).strip_edges()


func _dirty() -> bool:
	var out: Array = []
	var rc: int = OS.execute("git", ["-C",
		ProjectSettings.globalize_path("res://"), "status", "--porcelain",
		"--untracked-files=no"], out, true)
	if rc != 0 or out.is_empty():
		return rc != 0
	for line: String in String(out[0]).split("\n", false):
		var entry: String = line.strip_edges()
		if entry == "" or entry.substr(2).strip_edges().begins_with("evidence/"):
			continue
		return true
	return false
