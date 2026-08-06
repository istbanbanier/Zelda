## Lot 2 — `SH_CharacterPainterly` : LE shader du style (bible §21.1,
## décision verrouillée n°2), validé D'ABORD sur trois pilotes du
## HeroShotLab — un rocher, une touffe, le héros — jamais sur le monde
## entier. Fail-first : écrit avant l'implémentation.
##
## Contrats : le shader EXISTE et se charge ; les trois pilotes du lab le
## portent réellement (ShaderMaterial, pas StandardMaterial) ; le héros
## GARDE sa texture d'albedo (le painterly grade la lumière, il n'efface
## pas la peau du modèle) ; et les fondus sont ADOUCIS (`ramp_soft`
## explicite ≥ 0,08 — le toon dur à cassure sèche est interdit).
extends GateTestCase

const SHADER_PATH: String = "res://shaders/characters/SH_CharacterPainterly.gdshader"
## Déclinaison feuillage : le MÊME modèle de lumière peinte, plus le
## vent au sommet (vertex) — la vidéo de stabilité a PROUVÉ (diffs 0,00
## sur la phase immobile) que l'herbe du lab était figée, contre §11.1.
const FOLIAGE_SHADER_PATH: String = \
	"res://shaders/foliage/SH_FoliageWindPainterly.gdshader"
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


func _open_lab() -> HeroShotLab:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var lab: HeroShotLab = (load(LAB) as PackedScene).instantiate() \
		as HeroShotLab
	_root.add_child(lab)
	await _settle(6)
	return lab


func _is_painterly(material: Material) -> bool:
	var shader_material: ShaderMaterial = material as ShaderMaterial
	if shader_material == null or shader_material.shader == null:
		return false
	return shader_material.shader.resource_path == SHADER_PATH


func test_the_shader_exists_and_loads() -> void:
	check(ResourceLoader.exists(SHADER_PATH),
		"SH_CharacterPainterly existe — le chantier nommé depuis la Phase H")
	var shader: Shader = load(SHADER_PATH) as Shader
	check(shader != null, "…et se charge comme Shader")
	if shader != null:
		var code: String = shader.code
		check("light()" in code or "void light" in code,
			"le modèle de lumière est bien DANS le shader (bloc light)")
		check("smoothstep" in code,
			"les paliers sont fondus par smoothstep (ramps adoucies)")
		check("LIGHT_IS_DIRECTIONAL" in code,
			"le chaud/froid est réservé au soleil — le feu garde sa couleur")
	await _settle(1)


func test_the_three_lab_pilots_wear_it() -> void:
	var lab: HeroShotLab = await _open_lab()
	# 1. Le ROCHER pilote.
	var cliff: MeshInstance3D = lab.get_node_or_null("CliffLeftNear") \
		as MeshInstance3D
	check(cliff != null and _is_painterly(cliff.material_override),
		"le rocher pilote porte le painterly")
	# 2. L'HERBE : toutes les cellules portent la déclinaison feuillage
	# (lumière peinte + VENT — une herbe figée a échoué au dolly).
	var grass_cells: int = 0
	var windy_cells: int = 0
	for node: Node in lab.get_children():
		if node.name.begins_with("Grass_"):
			grass_cells += 1
			var cell: MultiMeshInstance3D = node as MultiMeshInstance3D
			var material: ShaderMaterial = \
				cell.material_override as ShaderMaterial
			if material != null and material.shader != null \
					and material.shader.resource_path == FOLIAGE_SHADER_PATH:
				windy_cells += 1
	check(grass_cells > 0 and windy_cells == grass_cells,
		"TOUTES les cellules d'herbe portent le feuillage painterly venté "
		+ "(%d/%d)" % [windy_cells, grass_cells])
	var foliage: Shader = load(FOLIAGE_SHADER_PATH) as Shader
	check(foliage != null and "TIME" in foliage.code
		and "smoothstep" in foliage.code,
		"la déclinaison feuillage a le VENT (TIME) et les ramps adoucies")
	# 3. Le HÉROS : chaque mesh de son modèle.
	var hero: Node3D = lab.get_node_or_null("Hero") as Node3D
	check(hero != null, "héros présent")
	var painterly_meshes: int = 0
	var total_meshes: int = 0
	if hero != null:
		for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			if mesh.get_parent() is BoneAttachment3D \
					or mesh.get_parent().get_parent() is BoneAttachment3D:
				continue   # les signes graybox gardent leur matière simple
			total_meshes += 1
			if _is_painterly(mesh.get_surface_override_material(0)):
				painterly_meshes += 1
	check(total_meshes > 0 and painterly_meshes == total_meshes,
		"le héros ENTIER porte le painterly (%d/%d meshes)"
		% [painterly_meshes, total_meshes])
	await _teardown()


func test_the_hero_keeps_his_albedo_texture_and_soft_ramps() -> void:
	var lab: HeroShotLab = await _open_lab()
	var hero: Node3D = lab.get_node_or_null("Hero") as Node3D
	if hero == null:
		check(false, "héros absent")
		await _teardown()
		return
	var checked: int = 0
	for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		var material: ShaderMaterial = \
			mesh.get_surface_override_material(0) as ShaderMaterial
		if material == null:
			continue
		checked += 1
		var texture: Variant = material.get_shader_parameter("albedo_texture")
		check(texture is Texture2D,
			"%s garde sa texture d'albedo (le shader grade, il n'efface pas)"
			% mesh.name)
		var softness: Variant = material.get_shader_parameter("ramp_soft")
		check(softness is float and float(softness) >= 0.08,
			"%s : fondu ADOUCI explicite (%s ≥ 0,08 — toon dur interdit)"
			% [mesh.name, str(softness)])
	check(checked > 0, "au moins un mesh du héros vérifié (%d)" % checked)
	await _teardown()
