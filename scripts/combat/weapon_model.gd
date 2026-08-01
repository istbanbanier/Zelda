## Habillage d'un modèle d'arme de production (ART-P0).
##
## Rôle unique : présenter le mesh importé et porter la variation d'USURE
## (§11.2 : « usure visuelle » sous 25 %) sans jamais toucher la ressource
## partagée — les matériaux sont DUPLIQUÉS à la première teinte, par instance
## de scène (même règle que les téléphones graybox : un matériau de scène est
## partagé tant qu'on ne le duplique pas, mesuré en D.1R.3).
##
## La géométrie de gameplay n'est PAS ici : hitbox et portée restent portées
## par les volumes du contrôleur — ce modèle est un visuel.
class_name WeaponModel
extends Node3D

var _worn: bool = false
var _materials_duplicated: bool = false


## Usure visible sous le seuil : lame ternie et assombrie. Idempotent.
func set_worn(worn: bool) -> void:
	if worn == _worn:
		return
	_worn = worn
	for mesh: Node in find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = mesh as MeshInstance3D
		for surface: int in range(instance.mesh.get_surface_count()):
			if not _materials_duplicated:
				var shared: Material = instance.get_active_material(surface)
				if shared != null:
					instance.set_surface_override_material(surface,
						shared.duplicate() as Material)
			var material: BaseMaterial3D = \
				instance.get_surface_override_material(surface) as BaseMaterial3D
			if material != null:
				material.albedo_color = \
					Color(0.62, 0.60, 0.58) if _worn else Color.WHITE
				material.roughness = 1.0 if _worn else material.roughness
	_materials_duplicated = true


func is_worn() -> bool:
	return _worn
