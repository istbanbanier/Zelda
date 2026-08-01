## Accroche et déplacement sur paroi (MASTER_SPEC §9.2, §5.8).
##
## Ce composant ne déplace personne : il **répond** à des questions — cette paroi
## est-elle saisissable, à quelle distance, selon quelle normale. Le contrôleur
## décide. Séparation voulue : les sondes sont ainsi testables sans joueur, et le
## mantle (§9.3) réutilise les mêmes réponses sans dupliquer les requêtes.
##
## §9.2 impose trois sondes — tête, torse, pieds. Elles ne servent pas seulement à
## confirmer un contact : leur **combinaison** distingue une paroi pleine d'un
## rebord (tête dans le vide) et d'un surplomb (pieds dans le vide, à refuser).
class_name ClimbingComponent
extends Node

## Surfaces qu'aucune paroi ne doit offrir (§9.2). Un décor de graybox est en
## pierre : la règle est donc un **refus** explicite, pas une autorisation
## explicite. Le jour où une surface franchement lisse existe, elle porte le
## groupe `unclimbable` et cesse d'être saisissable — voir D-017.
const REFUSING_GROUPS: Array[StringName] = [
	&"unclimbable", &"electrified", &"burning", &"spiked",
	&"fragile_unsupported", &"water",
]

@export var tuning: ClimbTuning
## Couches sondées. Le décor statique vit sur la couche 1 (§5.7).
@export_flags_3d_physics var probe_mask: int = 1

## Résultat d'une passe de sondes, pour que le contrôleur n'ait pas à refaire les
## requêtes.
class WallProbe extends RefCounted:
	var foot_hit: bool = false
	var chest_hit: bool = false
	var head_hit: bool = false
	## Normale retenue : celle du torse, sonde de référence pour l'orientation.
	var normal: Vector3 = Vector3.ZERO
	var point: Vector3 = Vector3.ZERO
	var collider: Object = null
	## Paroi saisissable : pieds et torse en contact, surface autorisée et assez
	## raide.
	var grabbable: bool = false
	## Tête dans le vide alors que le torse touche : un rebord est probable.
	var ledge_likely: bool = false
	## Renseigné quand `grabbable` est faux, pour que les tests et le debug disent
	## *pourquoi* plutôt que « ça n'a pas marché ».
	var refusal: StringName = &""


func _ready() -> void:
	if tuning == null:
		tuning = ClimbTuning.new()
		push_warning("[climb] aucun ClimbTuning assigné — valeurs par défaut utilisées.")


## Une surface portant l'un des groupes de refus n'est jamais saisissable (§9.2).
func is_surface_climbable(collider: Object) -> bool:
	var node: Node = collider as Node
	if node == null:
		return false
	for group: StringName in REFUSING_GROUPS:
		if node.is_in_group(group):
			return false
	return true


## Lance les trois sondes de §9.2 depuis `feet_position`, dans la direction
## `forward` (horizontale, normalisée par l'appelant).
func probe_wall(space: PhysicsDirectSpaceState3D, feet_position: Vector3,
		forward: Vector3, exclude: Array[RID]) -> WallProbe:
	var result: WallProbe = WallProbe.new()
	if space == null or tuning == null:
		result.refusal = &"no_space"
		return result

	var foot: Dictionary = _cast(space, feet_position, tuning.probe_foot_height, forward, exclude)
	var chest: Dictionary = _cast(space, feet_position, tuning.probe_chest_height, forward, exclude)
	var head: Dictionary = _cast(space, feet_position, tuning.probe_head_height, forward, exclude)

	result.foot_hit = not foot.is_empty()
	result.chest_hit = not chest.is_empty()
	result.head_hit = not head.is_empty()

	if not result.chest_hit:
		result.refusal = &"no_wall"
		return result

	result.normal = chest["normal"]
	result.point = chest["position"]
	result.collider = chest.get("collider")

	# §9.2 : « refuser vides/concavités ». Des pieds dans le vide sous un torse en
	# contact décrivent un surplomb : s'y accrocher laisserait le personnage
	# pendre dans le vide sans appui.
	if not result.foot_hit:
		result.refusal = &"overhang"
		return result

	if not is_surface_climbable(result.collider):
		result.refusal = &"forbidden_surface"
		return result

	# Une surface trop couchée n'est pas une paroi mais une pente : §8.2 la fait
	# gravir en marchant, l'escalader serait un doublon incohérent.
	var angle: float = rad_to_deg(acos(clampf(result.normal.dot(Vector3.UP), -1.0, 1.0)))
	if angle < tuning.min_wall_angle_deg:
		result.refusal = &"too_shallow"
		return result

	result.grabbable = true
	# La tête dans le vide au-dessus d'un torse en contact annonce un rebord ; la
	# confirmation revient au `LedgeDetectorComponent`, qui seul vérifie que le
	# dessus est praticable et dégagé.
	result.ledge_likely = not result.head_hit
	return result


func _cast(space: PhysicsDirectSpaceState3D, feet: Vector3, height: float,
		forward: Vector3, exclude: Array[RID]) -> Dictionary:
	var origin: Vector3 = feet + Vector3.UP * height
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin, origin + forward * tuning.grab_reach_m, probe_mask, exclude)
	return space.intersect_ray(query)
