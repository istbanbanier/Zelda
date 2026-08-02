## Habillage d'un modèle d'arme de production (ART-P0, révisé ART-P0R).
##
## Rôle unique : présenter le mesh importé et porter la variation d'USURE
## (§11.2 : « usure visuelle » sous 25 %) — RÉELLEMENT perceptible (métal
## terni et bruni, brillance des arêtes perdue), RÉVERSIBLE (les valeurs
## d'origine sont mémorisées et restaurées), et PAR INSTANCE : les matériaux
## sont dupliqués à la première teinte, jamais la ressource partagée.
##
## La géométrie de gameplay n'est PAS ici : hitbox et portée restent portées
## par les volumes du contrôleur — ce modèle est un visuel.
class_name WeaponModel
extends Node3D

const WORN_TINT: Color = Color(0.62, 0.55, 0.47)   # terne et bruni
const WORN_ROUGHNESS: float = 0.92                  # arêtes sans éclat

var _worn: bool = false
var _materials_duplicated: bool = false
## Matériau dupliqué → {albedo d'origine, roughness d'origine, metallic}.
var _originals: Dictionary = {}


## Usure visible sous le seuil. Idempotent et réversible.
func set_worn(worn: bool) -> void:
	if worn == _worn:
		return
	_worn = worn
	_ensure_instance_materials()
	for material: BaseMaterial3D in _originals.keys():
		var original: Dictionary = _originals[material]
		if _worn:
			material.albedo_color = WORN_TINT
			material.roughness = WORN_ROUGHNESS
			material.metallic = original["metallic"] * 0.5
		else:
			material.albedo_color = original["albedo"]
			material.roughness = original["roughness"]
			material.metallic = original["metallic"]


## Duplique les matériaux UNE fois et mémorise leurs valeurs d'origine —
## la ressource partagée du .glb n'est jamais mutée (mesuré par test).
func _ensure_instance_materials() -> void:
	if _materials_duplicated:
		return
	for mesh: Node in find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = mesh as MeshInstance3D
		for surface: int in range(instance.mesh.get_surface_count()):
			var shared: Material = instance.get_active_material(surface)
			if shared == null:
				continue
			var owned: BaseMaterial3D = shared.duplicate() as BaseMaterial3D
			if owned == null:
				continue
			instance.set_surface_override_material(surface, owned)
			_originals[owned] = {
				"albedo": owned.albedo_color,
				"roughness": owned.roughness,
				"metallic": owned.metallic,
			}
	_materials_duplicated = true


func is_worn() -> bool:
	return _worn
