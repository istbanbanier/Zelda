## Galerie paginée de développement (ordre V4, §8) — inspection de TOUS les
## modèles canoniques du catalogue, page par page, jamais les 375 d'un coup.
##
## Sélection par environnement :
##   GALLERY_CATEGORY  (défaut « Nature »)
##   GALLERY_PAGE      (0-based, 12 modèles par page en grille 4×3)
##   VALLEY_LIGHT=1    éclairage vallée au lieu du neutre
##   QUATERNIUS_ROOT   racine d'extraction pour les modèles NON promus
##                     (défaut /tmp/eclats-quaternius.X2JMwF/extracted)
##
## Un modèle promu se charge depuis le dépôt (AssetRegistry.model) ; un
## candidat non promu se charge à l'exécution depuis l'extraction via
## GLTFDocument. Une erreur sur UN asset devient un jalon orange consigné —
## jamais un écran vide. Scène de DEV : exclue de tout export final.
class_name AssetGallery
extends Node3D

const PAGE_SIZE: int = 12
const COLS: int = 4
var _spacing: float = 4.0

var page_entries: int = 0
var mounted_models: int = 0
var failed_models: int = 0


func _ready() -> void:
	_build_stage()
	var category: String = OS.get_environment("GALLERY_CATEGORY")
	if category.is_empty():
		category = "Nature"
	var page: int = int(OS.get_environment("GALLERY_PAGE").to_int())
	var custom_spacing: String = OS.get_environment("GALLERY_SPACING")
	if not custom_spacing.is_empty():
		_spacing = custom_spacing.to_float()
	var entries: Array = _catalog_models(category)
	var start: int = page * PAGE_SIZE
	var slice: Array = entries.slice(start, start + PAGE_SIZE)
	page_entries = slice.size()
	print("[galerie] %s page %d : %d/%d modèles" % [category, page,
		slice.size(), entries.size()])
	for i: int in range(slice.size()):
		var entry: Dictionary = slice[i]
		var at: Vector3 = Vector3(
			(i % COLS - (COLS - 1) * 0.5) * _spacing, 0.0,
			float(i / COLS) * -_spacing)
		_build_slot(entry, at)


func _catalog_models(category: String) -> Array:
	var text: String = FileAccess.get_file_as_string(
		"res://docs/assets/quaternius_catalog.json")
	var parsed: Variant = JSON.parse_string(text)
	var models: Array = []
	for entry: Variant in (parsed as Dictionary).get("entries", []):
		var e: Dictionary = entry
		if e.has("score") and String(e.get("category", "")) == category:
			models.append(e)
	models.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int((a["score"] as Dictionary)["total"]) \
			> int((b["score"] as Dictionary)["total"]))
	return models


func _build_slot(entry: Dictionary, at: Vector3) -> void:
	var slot: Node3D = Node3D.new()
	slot.name = "Slot_" + String(entry["name"]).get_basename()
	slot.position = at
	add_child(slot)
	var pedestal: MeshInstance3D = MeshInstance3D.new()
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 1.4
	disc.bottom_radius = 1.5
	disc.height = 0.08
	pedestal.mesh = disc
	pedestal.position = Vector3(0, -0.04, 0)
	slot.add_child(pedestal)
	var label: Label3D = Label3D.new()
	var score: Dictionary = entry.get("score", {})
	label.text = "%s\n%s · %d pts · %s" % [
		String(entry["name"]).get_basename(), String(entry["pack"]).split(".")[0],
		int(score.get("total", 0)), String(entry["status"])]
	label.font_size = 30
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 3.0, 0)
	slot.add_child(label)

	var packed: PackedScene = AssetRegistry.model(
		StringName(String(entry["name"]).get_basename()))
	if packed != null:
		slot.add_child(packed.instantiate())
		label.modulate = Color(0.7, 0.95, 0.7)
		mounted_models += 1
		return
	var runtime: Node = _load_from_extraction(String(entry["path"]))
	if runtime != null:
		slot.add_child(runtime)
		label.modulate = Color(0.65, 0.85, 1.0)
		mounted_models += 1
		return
	failed_models += 1
	push_warning("[galerie] modèle illisible : %s" % String(entry["path"]))
	label.modulate = Color(1.0, 0.65, 0.25)
	label.text += "\nÉCHEC DE CHARGEMENT"
	var placeholder: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.6, 1.0, 0.6)
	placeholder.mesh = box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.55, 0.15)
	placeholder.material_override = material
	placeholder.position = Vector3(0, 0.5, 0)
	slot.add_child(placeholder)


## Chargement RUNTIME d'un candidat non promu, directement depuis
## l'extraction — la galerie inspecte tout le catalogue sans committer.
func _load_from_extraction(rel_path: String) -> Node:
	var root: String = OS.get_environment("QUATERNIUS_ROOT")
	if root.is_empty():
		root = "/tmp/eclats-quaternius.X2JMwF/extracted"
	var absolute: String = root + "/" + rel_path
	if not FileAccess.file_exists(absolute):
		return null
	var document: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	if document.append_from_file(absolute, state) != OK:
		return null
	return document.generate_scene(state)


func _build_stage() -> void:
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	floor_mesh.name = "Floor"
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(40, 30)
	plane.center_offset = Vector3(0, 0, -6)
	floor_mesh.mesh = plane
	var floor_material: StandardMaterial3D = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.42, 0.42, 0.45)
	floor_mesh.material_override = floor_material
	add_child(floor_mesh)
	var reference: MeshInstance3D = MeshInstance3D.new()
	reference.name = "ReferenceCube1m"
	var cube: BoxMesh = BoxMesh.new()
	cube.size = Vector3.ONE
	reference.mesh = cube
	reference.position = Vector3(-9.0, 0.5, 3.0)
	add_child(reference)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.shadow_enabled = true
	if OS.get_environment("VALLEY_LIGHT") == "1":
		sun.light_color = Color(1.0, 0.839, 0.541)
		sun.light_energy = 1.25
		sun.rotation_degrees = Vector3(-22, -90, 0)
	else:
		sun.light_color = Color.WHITE
		sun.light_energy = 1.0
		sun.rotation_degrees = Vector3(-45, -30, 0)
	add_child(sun)
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.32, 0.34, 0.38)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.6, 0.6, 0.62)
	environment.ambient_light_energy = 0.7
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var camera: Camera3D = Camera3D.new()
	camera.position = Vector3(0, 6.5, 12.0)
	camera.rotation_degrees = Vector3(-20, 0, 0)
	camera.fov = 60
	add_child(camera)
	camera.make_current()
