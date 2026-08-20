## Matériau de PAYSAGE du terrain V2 — fabrique unique (phase V2.2-B).
##
## UN seul ShaderMaterial partagé par les 64 chunks : la matière est une
## décision de monde, pas de chunk — et un matériau partagé interdit par
## construction toute couture de teinte entre voisins. Les surfaces réelles
## sont les textures ambientCG CC0 déjà attribuées (ART-T1) ; le grain est
## généré par le moteur (AD-001 : aucune image téléchargée), avec une graine
## FIXE — le déterminisme du paysage est un contrat testé.
class_name WorldV2GroundMaterial
extends RefCounted

const SHADER_PATH: String = "res://shaders/world_v2/SH_WorldV2Ground.gdshader"
const SURFACE_DIR: String = "res://assets/textures/surfaces/"
const GRAIN_SEED: int = 20260813

static var _shared: ShaderMaterial = null
static var _grain: NoiseTexture2D = null


static func create() -> ShaderMaterial:
	if _shared != null:
		return _shared
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load(SHADER_PATH) as Shader
	_set_family(material, "grass", "T_Grass_Field", true)
	_set_family(material, "rock", "T_Rock_Strata", true)
	_set_family(material, "earth", "T_Ground_Earth", false)
	material.set_shader_parameter(&"grain_texture", grain_texture())
	_shared = material
	return _shared


static func _set_family(material: ShaderMaterial, prefix: String,
		family: String, with_rough: bool) -> void:
	var base: String = SURFACE_DIR + family + "_"
	material.set_shader_parameter(StringName(prefix + "_albedo"),
		load(base + "Albedo.jpg") as Texture2D)
	material.set_shader_parameter(StringName(prefix + "_normal"),
		load(base + "Normal.jpg") as Texture2D)
	if with_rough:
		material.set_shader_parameter(StringName(prefix + "_rough"),
			load(base + "Rough.jpg") as Texture2D)


## Même recette que le grain validé du HeroShotLab (grandes formes, raccord
## sans couture) — copie assumée plutôt qu'une dépendance du monde V2 vers
## une scène de laboratoire.
static func grain_texture() -> NoiseTexture2D:
	if _grain != null:
		return _grain
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.42
	noise.seed = GRAIN_SEED
	_grain = NoiseTexture2D.new()
	_grain.noise = noise
	_grain.width = 512
	_grain.height = 512
	_grain.seamless = true
	_grain.generate_mipmaps = true
	return _grain

## ISS-059 — fin de vie du cache statique. Inscrite au démarrage du
## script par `_static_init()`, appelée UNE fois à l'extinction du moteur
## par `SceneFlow._exit_tree()`. Sans elle, ces entrées vivent jusqu'à la
## mort du processus et sortent au rapport de fuite : mesure et ablation à
## variable unique, `evidence/…/v2_3_r2b3_1/iss059/CHAINE_CAUSALE.md`.
##
## Le sens de la dépendance est imposé : le porteur connaît le noyau, le
## noyau ne connaît aucun porteur (test_aucune_reference_croisee_interdite).
static func _static_init() -> void:
	StaticResourceCaches.enregistrer("WorldV2GroundMaterial", liberer_caches)


static func liberer_caches() -> int:
	var n: int = (1 if _shared != null else 0) + (1 if _grain != null else 0)
	_shared = null
	_grain = null
	return n
