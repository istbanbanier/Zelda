## Lot 11 — les VRAIES textures de surface (ambientCG CC0, déposées par
## le propriétaire du projet le 2026-08-06). Fail-first : écrit avant.
##
## Le manque dominant de trois évaluations — « zéro texture, albedos
## plats » — cesse ici. Contrats : les six matériaux existent et se
## chargent ; ils sont inscrits dans ATTRIBUTIONS avant d'entrer dans le
## build (règle absolue §2) ; le shader painterly sait les projeter en
## espace monde avec une échelle RÉELLE (une tuile de roche ne fait pas
## 40 m) ; et les surfaces du lab les portent.
extends GateTestCase

const SURFACES: String = "res://assets/textures/surfaces/"
const FAMILIES: Array[String] = [
	"T_Rock_Strata", "T_Rock_Mossy", "T_Ground_Earth",
	"T_Grass_Field", "T_Bark_Tree", "T_Fabric_Canvas",
]
const MAPS: Array[String] = ["Albedo", "Normal", "Rough"]
const LAB: String = "res://scenes/lookdev/HeroShotLab.tscn"

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	await _settle(3)


func test_the_six_surfaces_exist_and_load() -> void:
	for family: String in FAMILIES:
		for map_name: String in MAPS:
			var path: String = "%s%s_%s.jpg" % [SURFACES, family, map_name]
			check(ResourceLoader.exists(path),
				"%s_%s présent" % [family, map_name])
			var texture: Texture2D = load(path) as Texture2D
			check(texture != null and texture.get_width() >= 512,
				"%s_%s se charge en %d px (≥ 512)"
				% [family, map_name,
					0 if texture == null else texture.get_width()])
	await _settle(1)


func test_they_are_attributed_before_entering_the_build() -> void:
	# Règle ABSOLUE du projet (§2) : pas de ressource externe dans le
	# build sans licence inscrite AVANT. Ce test la rend exécutable.
	var file: FileAccess = FileAccess.open("res://ATTRIBUTIONS.md",
		FileAccess.READ)
	check(file != null, "ATTRIBUTIONS.md lisible")
	if file == null:
		await _settle(1)
		return
	var text: String = file.get_as_text()
	file.close()
	check("ambientCG" in text, "l'auteur des textures est nommé")
	check("CC0" in text, "la licence est nommée")
	for family: String in FAMILIES:
		check(family in text,
			"%s est inscrit dans ATTRIBUTIONS" % family)
	await _settle(1)


func test_the_shader_projects_them_at_a_real_scale() -> void:
	var shader: Shader = load(
		"res://shaders/characters/SH_CharacterPainterly.gdshader") as Shader
	check(shader != null, "le shader du style se charge")
	if shader == null:
		await _settle(1)
		return
	var code: String = shader.code
	check("surface_texture" in code and "surface_normal" in code,
		"le shader accepte une surface texturée ET son relief")
	check("surface_tile_m" in code,
		"…avec une taille de tuile en MÈTRES (1 unité = 1 m, invariant)")
	await _settle(1)


func test_the_lab_wears_them() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var lab: HeroShotLab = (load(LAB) as PackedScene).instantiate() \
		as HeroShotLab
	_root.add_child(lab)
	await _settle(6)
	var textured: int = 0
	var tiles: Array[float] = []
	for node: Node in lab.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		var material: ShaderMaterial = mesh.material_override \
			as ShaderMaterial
		if material == null:
			continue
		var surface: Variant = material.get_shader_parameter("surface_texture")
		if not (surface is Texture2D):
			continue
		if (surface as Texture2D).get_width() <= 1:
			continue
		textured += 1
		var tile: Variant = material.get_shader_parameter("surface_tile_m")
		if tile is float:
			tiles.append(float(tile))
	check(textured >= 4,
		"au moins quatre familles de surface du lab sont texturées (%d)"
		% textured)
	var sane: bool = not tiles.is_empty()
	for tile: float in tiles:
		# Une tuile hors de 0,3-12 m trahit une échelle inventée : soit
		# un grain microscopique qui scintille, soit une tache géante.
		if tile < 0.3 or tile > 12.0:
			sane = false
	check(sane, "les tuiles gardent une taille PHYSIQUE crédible (%s m)"
		% str(tiles))
	await _teardown()
