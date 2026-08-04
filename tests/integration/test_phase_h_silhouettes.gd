## Phase H, passe H-1 « Horizon, orage, arbres, citadelle » — régressions de
## SILHOUETTE. La capture `vista_horizon_etage` a tranché : crêtes et skyline
## en `BoxMesh` lisaient « gratte-ciels », le nuage (lobes de 8-13 m de haut
## pour ~26 m de rayon) lisait « soucoupe », la citadelle (masse de 24 m sans
## spire) disparaissait devant les montagnes, et les feuilles des arbres
## torsadés (texture moyenne RGB 95/13/13) couvraient la vallée de rouge sang
## — le ratio §3.4 exige 60 % de verts/ocres.
##
## Ces tests encodent les invariants de forme, pas le goût : une capture reste
## la preuve visuelle (§21.8), mais aucune régression ne doit pouvoir remettre
## une boîte dans le ciel sans faire rougir la suite.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const FOLIAGE_DIR: String = "res://assets/environment/foliage/"
const TWISTED_GLTFS: Array[String] = [
	"TwistedTree_1.gltf", "TwistedTree_2.gltf", "TwistedTree_3.gltf",
	"Bush_Common.gltf",
]
const OLIVE_TEXTURE: String = "Leaves_TwistedTree_C_olive.png"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


## Compte les meshes BoxMesh / PrismMesh sous un nœud (enfants directs).
func _count_shapes(parent: Node) -> Dictionary:
	var boxes: int = 0
	var prisms: int = 0
	for child: Node in parent.get_children():
		var mesh_instance: MeshInstance3D = child as MeshInstance3D
		if mesh_instance == null:
			continue
		if mesh_instance.mesh is BoxMesh:
			boxes += 1
		elif mesh_instance.mesh is PrismMesh:
			prisms += 1
	return {"boxes": boxes, "prisms": prisms}


func test_silhouettes_montagnes_nuage_et_citadelle() -> void:
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(8)

	# --- Montagnes : silhouettes triangulaires, plus jamais de boîtes. ---
	var terrain: Node = valley.get_node("Terrain")
	var crests: Node = terrain.get_node("BorderCrests")
	var crest_shapes: Dictionary = _count_shapes(crests)
	check_equal(int(crest_shapes["boxes"]), 0,
		"aucune crête n'est une boîte (le « mur de gratte-ciels » de la capture)")
	check(int(crest_shapes["prisms"]) >= 40,
		"les crêtes sont des prismes (%d)" % int(crest_shapes["prisms"]))
	var skyline: Node = terrain.get_node("FarSkyline")
	var far_shapes: Dictionary = _count_shapes(skyline)
	check_equal(int(far_shapes["boxes"]), 0,
		"aucun massif lointain n'est une boîte")
	check(int(far_shapes["prisms"]) >= 56,
		"les massifs lointains sont des prismes (%d)" % int(far_shapes["prisms"]))

	# --- Nuage : cumuliforme, pas une galette. ---
	var storm: StormCell = valley.get_node("CitadelStorm") as StormCell
	check_not_null(storm, "la cellule d'orage existe au-dessus de la citadelle")
	if storm != null:
		var lumps: int = 0
		var ratio_sum: float = 0.0
		for child: Node in storm.get_children():
			if not child.name.begins_with("CloudLayer"):
				continue
			var lump: MeshInstance3D = child as MeshInstance3D
			var sphere: SphereMesh = lump.mesh as SphereMesh
			if sphere == null:
				continue
			lumps += 1
			ratio_sum += sphere.height / sphere.radius
		check(lumps >= 12, "au moins 12 grumeaux (%d) — 8 lisaient « galette »" % lumps)
		if lumps > 0:
			var mean_ratio: float = ratio_sum / float(lumps)
			check(mean_ratio >= 0.8,
				"grumeaux dodus : hauteur/rayon moyen %.2f ≥ 0,8 (avant : ~0,55)"
					% mean_ratio)

	# --- Citadelle : masse élargie et spire qui domine ses tours (§2.4). ---
	var citadel: Node3D = valley.get_node("Terrain/CitadelProxy") as Node3D
	check_not_null(citadel, "le proxy de citadelle existe")
	var spire_top: float = -INF
	if citadel != null:
		var keep: MeshInstance3D = citadel.get_node_or_null("Keep/KeepMesh") \
			as MeshInstance3D
		if keep == null:
			keep = citadel.get_node_or_null("Keep") as MeshInstance3D
		check_not_null(keep, "la masse centrale (Keep) existe")
		if keep != null:
			var keep_box: BoxMesh = keep.mesh as BoxMesh
			check(keep_box != null and keep_box.size.x >= 30.0,
				"masse centrale élargie : %.0f m ≥ 30 (avant : 24 — une cabane)"
					% (keep_box.size.x if keep_box != null else 0.0))
		for child: Node in citadel.get_children():
			if not child.name.begins_with("Spire"):
				continue
			var segment: MeshInstance3D = child as MeshInstance3D
			if segment == null or not (segment is MeshInstance3D):
				continue
			var aabb: AABB = segment.get_aabb()
			var top: float = (segment.global_transform * aabb).get_support(Vector3.UP).y
			spire_top = maxf(spire_top, top)
		check(spire_top >= 34.0 + 60.0,
			"une spire domine la citadelle : sommet y %.1f ≥ 94" % spire_top)

	# --- L'éclair frappe la spire, pas un toit invisible. ---
	if storm != null and spire_top > -INF:
		var strike_world: Vector3 = storm.global_position + storm.strike_offset
		check(absf(strike_world.y - spire_top) <= 6.0,
			"l'éclair frappe le sommet de la spire (impact y %.1f, spire y %.1f)"
				% [strike_world.y, spire_top])

	_tree().root.remove_child(valley)
	valley.queue_free()
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)


func test_les_feuilles_torsadees_sont_olive() -> void:
	## La texture rouge sang (moyenne RGB 95/13/13) reste sur disque, mais plus
	## AUCUN arbre du monde ne la référence : les quatre `.gltf` pointent vers
	## la variante olive, dont le vert domine réellement le rouge.
	for gltf_name: String in TWISTED_GLTFS:
		var file: FileAccess = FileAccess.open(FOLIAGE_DIR + gltf_name,
			FileAccess.READ)
		check_not_null(file, "%s se lit" % gltf_name)
		if file == null:
			continue
		var text: String = file.get_as_text()
		file.close()
		check(text.contains(OLIVE_TEXTURE),
			"%s référence la variante olive" % gltf_name)
	var image: Image = Image.new()
	var error: int = image.load(
		ProjectSettings.globalize_path(FOLIAGE_DIR + OLIVE_TEXTURE))
	check_equal(error, OK, "la texture olive existe et se charge")
	if error == OK:
		image.resize(8, 8, Image.INTERPOLATE_BILINEAR)
		var red_sum: float = 0.0
		var green_sum: float = 0.0
		for y: int in range(8):
			for x: int in range(8):
				var pixel: Color = image.get_pixel(x, y)
				red_sum += pixel.r
				green_sum += pixel.g
		check(green_sum > red_sum * 1.2,
			"le vert domine le rouge (G %.2f vs R %.2f) — avant : 13 contre 95"
				% [green_sum, red_sum])
