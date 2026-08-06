## Lot 10 — le grain procédural : casser les aplats unis (manque
## dominant nommé par TROIS évaluations successives — « zéro texture :
## albedos plats », matériaux 6,5/10). Fail-first : écrit avant.
##
## Doctrine (AD-001) : aucune image téléchargée — le grain naît d'un
## bruit généré PAR LE MOTEUR (`NoiseTexture2D` + `FastNoiseLite`,
## vérifiés dans la source 4.7.1), donc reproductible depuis le dépôt,
## sans licence ni poids binaire.
##
## Contrats : le shader painterly SAIT lire un grain (uniformes
## présents), le grain est de GRANDES formes (§21.1 : « variation macro
## très lente », pas du microbruit), il reste DISCRET (jamais un
## deuxième langage de matière), et les surfaces du lab en portent un.
extends GateTestCase

const PAINTERLY: String = \
	"res://shaders/characters/SH_CharacterPainterly.gdshader"
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


func test_the_painterly_shader_can_read_a_grain() -> void:
	var shader: Shader = load(PAINTERLY) as Shader
	check(shader != null, "le shader du style se charge")
	if shader == null:
		await _settle(1)
		return
	var code: String = shader.code
	check("grain_texture" in code,
		"le shader accepte une texture de GRAIN")
	check("grain_strength" in code and "grain_scale" in code,
		"…avec force et échelle réglables (jamais un grain imposé)")
	# §21.1 : le grain module la matière, il ne la remplace pas — il
	# agit sur l'albedo ET la rugosité, sans toucher la silhouette.
	check("ROUGHNESS" in code, "la rugosité reste pilotée")
	await _settle(1)


func test_the_grain_is_procedural_large_and_discreet() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var lab: HeroShotLab = (load(LAB) as PackedScene).instantiate() \
		as HeroShotLab
	_root.add_child(lab)
	await _settle(6)
	var grained: int = 0
	var checked: int = 0
	for node: Node in lab.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		var material: ShaderMaterial = mesh.material_override \
			as ShaderMaterial
		if material == null or material.shader == null \
				or material.shader.resource_path != PAINTERLY:
			continue
		checked += 1
		var grain: Variant = material.get_shader_parameter("grain_texture")
		if not (grain is NoiseTexture2D):
			continue
		grained += 1
		var noise: Noise = (grain as NoiseTexture2D).noise
		check(noise is FastNoiseLite,
			"%s : grain GÉNÉRÉ par le moteur, aucune image importée"
			% mesh.name)
		if noise is FastNoiseLite:
			var frequency: float = (noise as FastNoiseLite).frequency
			check(frequency <= 0.02,
				"%s : grandes formes, pas du microbruit (fréquence %.4f "
				% [mesh.name, frequency] + "≤ 0,02 — §21.1)")
		var strength: Variant = \
			material.get_shader_parameter("grain_strength")
		check(strength is float and float(strength) > 0.0
			and float(strength) <= 0.22,
			"%s : grain DISCRET (%s ≤ 0,22 — il module, il ne domine pas)"
			% [mesh.name, str(strength)])
	check(checked > 0, "des surfaces peintes ont été inspectées (%d)"
		% checked)
	check(grained >= 3,
		"au moins trois familles de surface portent un grain (%d)" % grained)
	await _teardown()
