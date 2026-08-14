## Outillage commun des lieux V2.3 — poser une pièce de kit CC0 avec le
## MÊME langage painterly que la végétation V2.2, sans rien télécharger.
##
## Règles portées ici (docs/WORLD_V2_POI_CONTRACTS.md §4) :
##  - résolution par NOM canonique sur les dossiers importés (village,
##    dungeon, props, cliffs, rocks, foliage) — `AssetRegistry.model()`
##    n'indexe pas village/ ni cliffs/, d'où le résolveur local ;
##  - toute pièce passe par `KitScale.factor()` (échelles fautives
##    mesurées) puis `KitPlacement.seat()` (origines fautives mesurées) ;
##  - matériaux DUPLIQUÉS et mis en cache par (matériau, teinte) :
##    roughness ≥ 0,95, spéculaire 0,1, teinte par catégorie — jamais de
##    mutation d'une ressource partagée ;
##  - chaque pièce reçoit un NOM explicite (Godot rebaptise les homonymes
##    en `@Node3D@366`, et plus aucun test ne peut les désigner).
class_name WorldV2PlaceKit
extends RefCounted

const MODULE_DIRS: Array[String] = [
	"res://assets/environment/village",
	"res://assets/environment/dungeon",
	"res://assets/environment/props",
	"res://assets/environment/cliffs",
	"res://assets/environment/rocks",
	"res://assets/environment/foliage",
]

## Teintes painterly par matière (cohérentes avec `_category_tone` de la
## végétation V2.2 : arbres olive, roches ocre).
const TONE_WOOD: Color = Color(0.86, 0.74, 0.58)
const TONE_STONE: Color = Color(0.95, 0.88, 0.78)
const TONE_PLANT: Color = Color(0.60, 0.63, 0.50)
const TONE_CLOTH: Color = Color(0.88, 0.66, 0.48)
const TONE_DARK_STONE: Color = Color(0.62, 0.58, 0.55)
const TONE_CHARRED: Color = Color(0.30, 0.27, 0.25)

static var _index: Dictionary = {}
static var _material_cache: Dictionary = {}


## `PackedScene` d'une pièce de kit par nom canonique, ou null.
static func scene_for(model_name: StringName) -> PackedScene:
	if _index.is_empty():
		for dir_path: String in MODULE_DIRS:
			var dir: DirAccess = DirAccess.open(dir_path)
			if dir == null:
				continue
			for file: String in dir.get_files():
				var lower: String = file.to_lower()
				if lower.ends_with(".gltf") or lower.ends_with(".glb"):
					if not _index.has(StringName(file.get_basename())):
						_index[StringName(file.get_basename())] = \
							dir_path + "/" + file
	var path: String = String(_index.get(model_name, ""))
	if path.is_empty():
		return AssetRegistry.model(model_name)
	return load(path) as PackedScene


## Pose une pièce de kit : échelle corrigée, assise corrigée, teinte
## painterly, nom explicite. Rend null (et signale) si le modèle manque.
static func module(parent: Node3D, model_name: StringName, local_pos: Vector3,
		rot_y_deg: float = 0.0, extra_scale: float = 1.0,
		tone: Color = Color.WHITE) -> Node3D:
	var packed: PackedScene = scene_for(model_name)
	if packed == null:
		push_error("[world_v2] kit : modèle inconnu %s" % model_name)
		return null
	var node: Node3D = packed.instantiate() as Node3D
	node.name = "%s_%d" % [model_name, parent.get_child_count()]
	var factor: float = KitScale.factor(String(model_name)) * extra_scale
	node.scale = Vector3.ONE * factor
	node.rotation.y = deg_to_rad(rot_y_deg)
	node.position = local_pos
	parent.add_child(node)
	KitPlacement.seat(node, String(model_name))
	if tone != Color.WHITE:
		apply_tone(node, tone)
	return node


## Teinte painterly : matériau actif DUPLIQUÉ (cache par matériau+teinte),
## albédo multiplié, roughness ≥ 0,95, spéculaire réduit.
static func apply_tone(root: Node3D, tone: Color) -> void:
	var targets: Array[Node] = root.find_children("*", "MeshInstance3D",
		true, false)
	if root is MeshInstance3D:
		targets.append(root)
	for node: Node in targets:
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var active: Material = instance.get_active_material(surface)
			var base: StandardMaterial3D = active as StandardMaterial3D
			if base == null:
				continue
			var key: String = "%d|%s" % [base.get_instance_id(), tone]
			var tinted: StandardMaterial3D = \
				_material_cache.get(key) as StandardMaterial3D
			if tinted == null:
				tinted = base.duplicate() as StandardMaterial3D
				tinted.albedo_color = Color(
					base.albedo_color.r * tone.r, base.albedo_color.g * tone.g,
					base.albedo_color.b * tone.b, base.albedo_color.a)
				tinted.roughness = maxf(tinted.roughness, 0.95)
				tinted.metallic_specular = 0.1
				_material_cache[key] = tinted
			instance.set_surface_override_material(surface, tinted)


## Matériau plein painterly (géométrie procédurale des lieux).
static func flat_material(albedo: Color, emission: Color = Color.BLACK,
		emission_energy: float = 0.0) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.96
	material.metallic_specular = 0.1
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material


## Collider boîte simple (layer 1, mask 0 — même contrat que la
## végétation : le monde le porte, il ne sonde rien).
static func collider_box(parent: Node3D, box_name: String, local_pos: Vector3,
		size: Vector3, rot_y_deg: float = 0.0) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = box_name
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = box_name + "_forme"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.rotation.y = deg_to_rad(rot_y_deg)
	body.position = local_pos
	parent.add_child(body)
	return body
