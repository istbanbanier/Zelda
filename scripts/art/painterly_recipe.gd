## RECETTE PAINTERLY PARTAGÉE — le point UNIQUE de la direction
## artistique, comme `KitScale` l'est pour l'échelle.
##
## Le HeroShotLab a servi de laboratoire : half-Lambert, deux paliers
## fondus, chaud/froid réservé au soleil, grain procédural, surfaces
## photoscannées en MODULATION (AD-006), teinte reprise des modèles
## sans texture. Cette recette y a été réglée à la mesure et à l'œil.
## Elle vit désormais ici pour que la VALLÉE ENTIÈRE la porte sans
## qu'on la recopie — six fabriques `_material()` séparées existaient
## dans `scripts/world/`, corriger six fois garantit qu'une septième
## oubliera.
##
## RÈGLE DE SÛRETÉ, non négociable : un matériau ÉMISSIF n'est jamais
## repeint. Les câbles cyan, les récepteurs, les dangers électriques et
## les noyaux du boss sont des TÉLÉGRAPHES de jeu (§20.2, §12) — leur
## lisibilité appartient au gameplay, qui reste intouchable. La recette
## les reconnaît et passe son chemin.
class_name PainterlyRecipe
extends RefCounted

const PAINTERLY: String = \
	"res://shaders/characters/SH_CharacterPainterly.gdshader"
const PAINTERLY_CUTOUT: String = \
	"res://shaders/characters/SH_CharacterPainterlyCutout.gdshader"
const SURFACES: String = "res://assets/textures/surfaces/"

## Seuil d'émission RÉELLE (énergie × canal le plus fort). En dessous,
## un matériau « émissif » ne l'est que sur le papier — c'est le piège
## que la revue contradictoire avait trouvé dans le lab.
const EMISSIVE_THRESHOLD: float = 0.5

static var _grain: NoiseTexture2D = null
static var _shader: Shader = null
static var _shader_cutout: Shader = null


static func shader() -> Shader:
	if _shader == null:
		_shader = load(PAINTERLY) as Shader
	return _shader


static func shader_cutout() -> Shader:
	if _shader_cutout == null:
		_shader_cutout = load(PAINTERLY_CUTOUT) as Shader
	return _shader_cutout


## Grain procédural PARTAGÉ (AD-001 : généré par le moteur, aucune
## image téléchargée). Une seule ressource pour tout le monde : le
## grain doit UNIFIER la matière, pas donner un motif par objet.
static func grain() -> NoiseTexture2D:
	if _grain != null:
		return _grain
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012   # grandes formes, §21.1 — jamais du microbruit
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.42
	noise.seed = 20260806
	_grain = NoiseTexture2D.new()
	_grain.noise = noise
	_grain.width = 512
	_grain.height = 512
	_grain.seamless = true
	return _grain


## Un matériau émet-il VRAIMENT ? (énergie × canal le plus fort)
static func is_emissive(material: BaseMaterial3D) -> bool:
	if material == null or not material.emission_enabled:
		return false
	var peak: float = maxf(material.emission.r,
		maxf(material.emission.g, material.emission.b))
	return material.emission_energy_multiplier * peak >= EMISSIVE_THRESHOLD


## Fabrique de base : la peinture, avec sa teinte et sa texture.
static func paint(colour: Color, rough: float = 0.85,
		texture: Texture2D = null, cutout: bool = false) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader_cutout() if cutout else shader()
	material.set_shader_parameter("albedo_color", colour)
	material.set_shader_parameter("roughness_value", rough)
	material.set_shader_parameter("ramp_soft", 0.16)
	material.set_shader_parameter("grain_texture", grain())
	material.set_shader_parameter("grain_strength", 0.12)
	material.set_shader_parameter("grain_scale", 0.35)
	material.set_shader_parameter("grain_roughness", 0.18)
	if texture == null:
		var image: Image = Image.create(1, 1, false, Image.FORMAT_RGB8)
		image.fill(Color.WHITE)
		texture = ImageTexture.create_from_image(image)
	material.set_shader_parameter("albedo_texture", texture)
	return material


## Surface photoscannée (AD-006) : la COULEUR reste subordonnée à la
## palette peinte, le RELIEF monte franchement. `tile_m` est la taille
## d'une tuile en MÈTRES — l'invariant du projet, pas un nombre magique.
static func with_surface(material: ShaderMaterial, family: String,
		tile_m: float, blend: float = 0.70,
		relief: float = 1.0) -> ShaderMaterial:
	if material == null:
		return material
	var base: String = SURFACES + family + "_"
	if not ResourceLoader.exists(base + "Albedo.jpg"):
		return material
	material.set_shader_parameter("surface_texture", load(base + "Albedo.jpg"))
	material.set_shader_parameter("surface_normal", load(base + "Normal.jpg"))
	material.set_shader_parameter("surface_rough", load(base + "Rough.jpg"))
	material.set_shader_parameter("surface_tile_m", tile_m)
	material.set_shader_parameter("surface_blend", blend)
	material.set_shader_parameter("surface_normal_depth", relief)
	return material


## Transforme UN matériau standard en peinture, en préservant ce qui
## portait l'information : sa texture si elle existe, sinon sa TEINTE
## (les modèles OBJ n'ont que ça — l'ignorer peignait les saules en
## blanc), sa découpe alpha, sa rugosité.
## (`convert` est un nom réservé de GDScript — d'où `from_standard`.)
static func from_standard(source: StandardMaterial3D) -> ShaderMaterial:
	if source == null:
		return null
	var texture: Texture2D = source.albedo_texture
	var cutout: bool = source.transparency \
		!= BaseMaterial3D.TRANSPARENCY_DISABLED \
		or source.cull_mode == BaseMaterial3D.CULL_DISABLED
	var tint: Color = Color.WHITE
	if texture == null:
		tint = source.albedo_color
		# Les kits sans texture sont souvent très sombres : posés tels
		# quels sous le soleil ils rendent noir. On remonte la VALEUR
		# en gardant la teinte.
		var peak: float = maxf(tint.r, maxf(tint.g, tint.b))
		if peak > 0.001 and peak < 0.45:
			tint = tint * (0.55 / peak)
		tint.a = 1.0
	return paint(tint, source.roughness, texture, cutout)


## Choisit la famille de surface d'après le nom du nœud et sa teinte —
## une heuristique assumée, réglable en un point, jamais une table de
## cas particuliers dispersée dans six fichiers.
static func family_for(node_name: String, tint: Color) -> String:
	var lowered: String = node_name.to_lower()
	if lowered.contains("rock") or lowered.contains("cliff") \
			or lowered.contains("stone") or lowered.contains("boulder"):
		return "T_Rock_Strata"
	if lowered.contains("tree") or lowered.contains("trunk") \
			or lowered.contains("log") or lowered.contains("wood") \
			or lowered.contains("plank"):
		return "T_Bark_Tree"
	if lowered.contains("tent") or lowered.contains("canvas") \
			or lowered.contains("banner") or lowered.contains("cloth"):
		return "T_Fabric_Canvas"
	if lowered.contains("path") or lowered.contains("dirt") \
			or lowered.contains("earth") or lowered.contains("ground"):
		return "T_Ground_Earth"
	if lowered.contains("grass") or lowered.contains("meadow") \
			or lowered.contains("terrain") or lowered.contains("chunk"):
		return "T_Grass_Field"
	# Sans indice de nom : la teinte décide entre végétal et minéral.
	if tint.g > tint.r and tint.g > tint.b:
		return "T_Grass_Field"
	return "T_Rock_Mossy"


## Taille de tuile par famille, en mètres.
static func tile_for(family: String) -> float:
	match family:
		"T_Grass_Field": return 6.0
		"T_Ground_Earth": return 5.0
		"T_Rock_Strata": return 4.0
		"T_Rock_Mossy": return 3.0
		"T_Bark_Tree": return 2.4
		"T_Fabric_Canvas": return 1.2
	return 4.0


## LE point d'entrée : peint un arbre de scène entier.
##
## Retourne le nombre de surfaces repeintes. Ne touche JAMAIS un
## matériau qui émet vraiment (télégraphes de jeu), ni un matériau déjà
## peint. Les nœuds dont le nom figure dans `skip` sont ignorés, eux et
## leur descendance — c'est ainsi qu'on protège un système entier
## (l'orage, un boss, un circuit) d'une passe cosmétique.
static func paint_world(root: Node, skip: Array[String] = [],
		with_surfaces: bool = true) -> int:
	var painted: int = 0
	# MUTUALISATION : la vallée porte des milliers de matériaux dont
	# l'immense majorité sont identiques (même teinte, même texture).
	# Sans cache, une passe globale fabriquerait autant de matériaux
	# distincts que de surfaces — donc autant d'états de rendu à
	# changer. On les regroupe par signature.
	var cache: Dictionary[String, ShaderMaterial] = {}
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null or _is_skipped(mesh, root, skip):
			continue
		if mesh.material_override != null:
			var override: StandardMaterial3D = \
				mesh.material_override as StandardMaterial3D
			if override != null and not is_emissive(override):
				mesh.material_override = _shared(cache, override,
					String(mesh.name), with_surfaces)
				painted += 1
			continue
		for s: int in range(mesh.mesh.get_surface_count()):
			if mesh.get_surface_override_material(s) is ShaderMaterial:
				continue
			var source: StandardMaterial3D = \
				mesh.get_active_material(s) as StandardMaterial3D
			if source == null or is_emissive(source):
				continue
			mesh.set_surface_override_material(s,
				_shared(cache, source, String(mesh.name), with_surfaces))
			painted += 1
	return painted


## Un matériau peint par SIGNATURE : deux surfaces de même teinte, même
## texture et même famille partagent le même objet.
static func _shared(cache: Dictionary[String, ShaderMaterial],
		source: StandardMaterial3D, node_name: String,
		with_surfaces: bool) -> ShaderMaterial:
	var texture: Texture2D = source.albedo_texture
	var family: String = ""
	if with_surfaces:
		family = family_for(node_name, source.albedo_color)
	var key: String = "%s|%s|%.3f|%d|%s" % [
		source.albedo_color, "" if texture == null else texture.resource_path,
		source.roughness, int(source.cull_mode), family]
	if cache.has(key):
		return cache[key]
	var material: ShaderMaterial = from_standard(source)
	if with_surfaces and family != "":
		with_surface(material, family, tile_for(family), 0.62, 0.9)
	cache[key] = material
	return material


static func _is_skipped(node: Node, root: Node,
		skip: Array[String]) -> bool:
	if skip.is_empty():
		return false
	var walker: Node = node
	while walker != null and walker != root:
		if String(walker.name) in skip:
			return true
		walker = walker.get_parent()
	return false
