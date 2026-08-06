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
	# Revue : le fondu adouci n'était contractuel que sur le héros.
	if cliff != null and cliff.material_override is ShaderMaterial:
		var rock_soft: Variant = (cliff.material_override as ShaderMaterial) \
			.get_shader_parameter("ramp_soft")
		check(rock_soft is float and float(rock_soft) >= 0.08,
			"le rocher aussi a son fondu ADOUCI (%s ≥ 0,08)" % str(rock_soft))
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
	# 3. Le HÉROS : chaque SURFACE de chaque mesh — la revue
	# contradictoire a prouvé que compter les meshes laissait la peau
	# des bras (surface 1 de Male_Ranger_Arms) en PBR standard.
	var hero: Node3D = lab.get_node_or_null("Hero") as Node3D
	check(hero != null, "héros présent")
	var painterly_surfaces: int = 0
	var total_surfaces: int = 0
	if hero != null:
		for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			if mesh.get_parent() is BoneAttachment3D \
					or mesh.get_parent().get_parent() is BoneAttachment3D:
				continue   # les signes graybox gardent leur matière simple
			if mesh.mesh == null:
				continue
			for s: int in range(mesh.mesh.get_surface_count()):
				total_surfaces += 1
				if _is_painterly(mesh.get_surface_override_material(s)):
					painterly_surfaces += 1
	check(total_surfaces > 0 and painterly_surfaces == total_surfaces,
		"le héros ENTIER porte le painterly — par SURFACE (%d/%d)"
		% [painterly_surfaces, total_surfaces])
	await _teardown()


func test_the_hero_keeps_his_albedo_texture_and_soft_ramps() -> void:
	var lab: HeroShotLab = await _open_lab()
	var hero: Node3D = lab.get_node_or_null("Hero") as Node3D
	if hero == null:
		check(false, "héros absent")
		await _teardown()
		return
	var checked: int = 0
	var real_textures: int = 0
	for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null:
			continue
		for s: int in range(mesh.mesh.get_surface_count()):
			var material: ShaderMaterial = \
				mesh.get_surface_override_material(s) as ShaderMaterial
			if material == null:
				continue
			checked += 1
			var texture: Variant = \
				material.get_shader_parameter("albedo_texture")
			check(texture is Texture2D,
				"%s/s%d garde une texture d'albedo" % [mesh.name, s])
			# Revue : le fallback blanc 1×1 rendait ce test infalsifiable.
			# La VRAIE peau/tenue du modèle est plus grande qu'un pixel.
			if texture is Texture2D \
					and (texture as Texture2D).get_size().x > 1.0:
				real_textures += 1
			var softness: Variant = material.get_shader_parameter("ramp_soft")
			check(softness is float and float(softness) >= 0.08,
				"%s/s%d : fondu ADOUCI explicite (%s ≥ 0,08)"
				% [mesh.name, s, str(softness)])
	check(checked > 0, "au moins une surface du héros vérifiée (%d)" % checked)
	check(real_textures >= 6,
		"la MAJORITÉ des surfaces portent la vraie texture du modèle, "
		+ "pas le fallback 1×1 (%d ≥ 6)" % real_textures)
	await _teardown()
