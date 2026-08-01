## Détection du rebord franchissable (MASTER_SPEC §9.3, §5.8).
##
## §9.3 fixe l'ordre : « détecter haut → surface marchable → dégagement capsule →
## transform cible ». Chacune de ces étapes peut refuser, et le refus doit être
## **nommé** : « le mantle n'a pas eu lieu » n'est pas un diagnostic, ni pour le
## joueur ni pour un test.
##
## Le dégagement de capsule est la garantie anti-softlock de §9.3 (« annuler
## proprement si invalide ») : franchir sous un plafond enfermerait le personnage
## dans la géométrie, exactement le cas manuel exigé par §21.4.
class_name LedgeDetectorComponent
extends Node

## Décollement vertical du test de dégagement, en mètres. Voir `find_ledge()`.
const GROUND_CLEARANCE: float = 0.05

@export var tuning: ClimbTuning
@export_flags_3d_physics var probe_mask: int = 1

## Résultat d'une recherche de rebord.
class LedgeResult extends RefCounted:
	var valid: bool = false
	## Position **des pieds** une fois le franchissement terminé.
	var target_feet: Vector3 = Vector3.ZERO
	var surface_normal: Vector3 = Vector3.UP
	## Raison du refus, vide si `valid`. Vocabulaire fermé, lisible en test.
	var refusal: StringName = &""


func _ready() -> void:
	if tuning == null:
		tuning = ClimbTuning.new()
		push_warning("[ledge] aucun ClimbTuning assigné — valeurs par défaut utilisées.")


## Cherche un rebord franchissable au-dessus de `wall_point`, en avançant dans
## `forward`. `capsule` et `capsule_offset` servent au test de dégagement ;
## `max_floor_angle_deg` vient du contrôleur, pour que « marchable » ait ici
## exactement le sens qu'il a en locomotion (§8.2).
func find_ledge(space: PhysicsDirectSpaceState3D, feet_position: Vector3,
		forward: Vector3, capsule: Shape3D, capsule_offset: float,
		max_floor_angle_deg: float, exclude: Array[RID]) -> LedgeResult:
	var result: LedgeResult = LedgeResult.new()
	if space == null or tuning == null or capsule == null:
		result.refusal = &"no_space"
		return result

	# 1. Chercher le dessus : rayon vers le bas, depuis un point au-delà du rebord.
	var probe_ahead: float = tuning.wall_distance_m + tuning.ledge_depth_m
	var from: Vector3 = feet_position + Vector3.UP * tuning.ledge_search_height + forward * probe_ahead
	var to: Vector3 = from + Vector3.DOWN * tuning.ledge_search_height
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, to, probe_mask, exclude)
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		# Rien sous le point de recherche : soit le mur monte encore, soit le
		# dessus est hors de portée. Dans les deux cas, il n'y a pas de rebord ici.
		result.refusal = &"no_top"
		return result

	# 2. Le dessus doit être **marchable**, au sens de §8.2.
	var normal: Vector3 = hit["normal"]
	var angle: float = rad_to_deg(acos(clampf(normal.dot(Vector3.UP), -1.0, 1.0)))
	if angle > max_floor_angle_deg:
		result.refusal = &"top_not_walkable"
		return result

	var target_feet: Vector3 = hit["position"]

	# 3. Dégagement de capsule à l'arrivée. Sans ce test, un rebord surmonté d'un
	# plafond bas laisserait le personnage franchir **dans** la géométrie.
	#
	# La capsule est décollée de `GROUND_CLEARANCE` : posée pile sur la surface
	# d'arrivée, elle **touche** celle-ci et tout rebord parfaitement dégagé se
	# déclarait `blocked`. Le défaut était doublement trompeur — le cas nominal
	# échouait, et le test du plafond passait en accusant le rebord au lieu du
	# plafond. Une marge de requête nulle complète le décollement : les deux
	# ensemble ne laissent subsister que les obstacles réels.
	var shape_query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	shape_query.shape = capsule
	shape_query.transform = Transform3D(Basis.IDENTITY,
		target_feet + Vector3.UP * (capsule_offset + GROUND_CLEARANCE))
	shape_query.collision_mask = probe_mask
	shape_query.exclude = exclude
	shape_query.margin = 0.0
	if not space.intersect_shape(shape_query, 1).is_empty():
		result.refusal = &"blocked"
		return result

	# 4. Correction plafonnée (§7.12) : un franchissement qui demanderait un bond
	# démesuré doit être refusé, pas amorti.
	if target_feet.distance_to(feet_position) > tuning.mantle_max_correction_m:
		result.refusal = &"too_far"
		return result

	result.valid = true
	result.target_feet = target_feet
	result.surface_normal = normal
	return result
