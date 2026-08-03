## Visuel du Gardien de l'Orage — hero asset original (Phase H, lot H.1).
##
## Le modèle vient de `tools/blender/make_storm_guardian.py` : création du
## projet, procédurale et reproductible, aucune silhouette empruntée. Il est
## livré en 27 meshes NOMMÉS, et c'est délibéré — la phase 2 révèle les
## cristaux, la phase 3 fait pendre des plaques, la mise à la terre ouvre le
## noyau (§16.3 à §16.5). Rien de tout cela n'est possible depuis une masse
## unique, et rien de tout cela ne doit passer par un `find_children()`
## répété à chaque frame : l'index est construit une fois.
##
## Règle ART-P0, inchangée depuis l'épée : **le modèle est un visuel**. Il
## ne porte ni collision, ni état, ni décision. Les hurtbox et la capsule de
## `StormGuardian.tscn` restent l'autorité de gameplay ; ce script ne fait
## que montrer, cacher et allumer.
class_name GuardianVisual
extends Node3D

const CRYSTAL_NAMES: Array[String] = ["CrystalA", "CrystalB"]
const ARMOUR_COUNT: int = 8
const RING_COUNT: int = 3
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)

var _index: Dictionary[String, MeshInstance3D] = {}
var _core_material: StandardMaterial3D = null


func _ready() -> void:
	_build_index()
	_isolate_core_material()
	# §16.4 : les cristaux ne sortent qu'en phase 2. Ils partent cachés.
	for name: String in CRYSTAL_NAMES:
		set_crystal_visible(name, false)


func _build_index() -> void:
	for node: Node in find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		# Godot suffixe les doublons ; le nom d'origine reste le préfixe.
		_index[mesh.name] = mesh


## Le noyau pulse et change de couleur : son matériau doit être PROPRE à
## cette instance, jamais partagé avec le modèle importé (§5.4).
func _isolate_core_material() -> void:
	var core: MeshInstance3D = _index.get("Core", null)
	if core == null:
		return
	var source: BaseMaterial3D = core.get_active_material(0) as BaseMaterial3D
	_core_material = StandardMaterial3D.new()
	if source != null:
		_core_material.albedo_color = source.albedo_color
	_core_material.emission_enabled = true
	_core_material.emission = COL_CYAN
	_core_material.emission_energy_multiplier = 1.0
	core.material_override = _core_material


func mesh(mesh_name: String) -> MeshInstance3D:
	return _index.get(mesh_name, null)


func set_crystal_visible(crystal_name: String, value: bool) -> void:
	var crystal: MeshInstance3D = _index.get(crystal_name, null)
	if crystal != null:
		crystal.visible = value


## §16.3/§16.5 : le noyau s'allume quand il est nu, et s'éteint sous
## l'armure. C'est le seul retour qui dit au joueur qu'il peut frapper.
func set_core_exposed(exposed: bool) -> void:
	if _core_material == null:
		return
	_core_material.emission_energy_multiplier = 4.0 if exposed else 0.6


## §16.5 : « certaines plaques pendent » en phase 3. Elles ne disparaissent
## pas — une masse qui s'évapore casserait la silhouette.
func hang_armour(fraction: float) -> void:
	var count: int = int(clampf(fraction, 0.0, 1.0) * float(ARMOUR_COUNT))
	for i: int in range(ARMOUR_COUNT):
		var plate: MeshInstance3D = _index.get("ArmourPlate%d" % i, null)
		if plate == null:
			continue
		var hanging: bool = i < count
		plate.rotation.z = deg_to_rad(-34.0 if hanging else 0.0)
		plate.position.y = -0.22 if hanging else 0.0


## §15.3 de la bible : « l'anneau divisé tourne autour d'un axe instable ».
func spin_ring(angle: float) -> void:
	for i: int in range(RING_COUNT):
		var segment: MeshInstance3D = _index.get("GuardianRing%d" % i, null)
		if segment != null:
			segment.rotation.y = angle + float(i) * 0.12


func mesh_names() -> Array[String]:
	var names: Array[String] = []
	for key: String in _index.keys():
		names.append(key)
	names.sort()
	return names
