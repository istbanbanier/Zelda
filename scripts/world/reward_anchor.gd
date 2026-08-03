## ANCRAGE DE RÉCOMPENSE — le point où une découverte se matérialise.
##
## Contrat commun aux 31 lieux. Il existe parce que la première tentative a
## échoué de deux façons : deux bâtisseurs sur huit seulement avaient posé un
## ancrage, chacun avec son propre nom, et les 23 lieux restants ont reçu un
## coffre posé au centre de leur volume — plausible, jamais vérifié, parfois
## dans un mur.
##
## Un ancrage n'est PAS une position. C'est une promesse vérifiable :
##
##  1. il repose sur un sol réel — sonde verticale ;
##  2. le joueur y tient debout — capsule de dégagement ;
##  3. il est ACCESSIBLE : soit un chemin de navigation existe depuis le
##     point d'entrée du lieu, soit — pour un lieu qui exige escalade ou
##     saut — un scénario de traversée physique le démontre ;
##  4. la récompense est à portée d'interaction une fois arrivé ;
##  5. on peut REPARTIR : un ancrage au fond d'un puits sans sortie est un
##     piège, pas une récompense.
##
## Le point 3 mérite d'être explicite : un `NavigationServer3D` répond
## volontiers « accessible » pour une corniche qu'aucun joueur ne peut
## atteindre, parce que le navmesh ignore la hauteur de saut et l'endurance.
## Un lieu marqué `requires_traversal` refuse donc la preuve par navigation
## et exige un corps qui fait réellement le trajet.
class_name RewardAnchor
extends Marker3D

## Nature de la récompense attendue ici. La pose concrète est décidée par
## `DiscoveryRewards` : l'ancrage dit CE QUI convient au lieu, pas comment
## l'instancier.
enum Kind {
	CHEST,        ## coffre — le cas ordinaire
	WEAPON,       ## arme posée au sol, ramassable
	INGREDIENT,   ## ingrédient rare à récolter
	RECIPE,       ## recette / savoir
	STORY,        ## fragment d'histoire
	PUZZLE,       ## récompense d'énigme
	COMBAT,       ## récompense après combat
}

## Identifiant du lieu qui porte cet ancrage. Renseigné par le bâtisseur ;
## `DiscoveryRewards` en dérive l'identifiant persistant de la récompense.
@export var place_id: StringName = &""
@export var kind: Kind = Kind.CHEST

## Le lieu exige-t-il escalade ou saut pour être atteint ? Si oui, la preuve
## par navigation est REFUSÉE : il faut un scénario physique.
@export var requires_traversal: bool = false

## D'où le joueur arrive. Point au sol, hors du décor, depuis lequel
## l'accessibilité est mesurée. Laissé à zéro, l'audit part du lieu lui-même,
## ce qui est plus faible : les bâtisseurs doivent le renseigner.
@export var approach_from: Vector3 = Vector3.ZERO

## Rayon dans lequel la récompense doit rester interactible.
const INTERACTION_REACH: float = 2.2
## Gabarit du joueur (§8.2).
const BODY_RADIUS: float = 0.35
const BODY_HEIGHT: float = 1.7
## Hauteur au-dessus de l'ancrage d'où l'on sonde le sol.
const PROBE_HEIGHT: float = 3.0
## Distance de chute tolérée sous l'ancrage avant de le déclarer « dans le
## vide ». Au-delà, la récompense flotte.
const MAX_DROP: float = 1.2


## Résultat d'audit, lisible par un test qui doit NOMMER ce qui ne va pas.
class Verdict extends RefCounted:
	var place_id: StringName = &""
	var has_ground: bool = false
	var ground_y: float = 0.0
	var drop: float = 0.0
	var clear: bool = false
	var reachable: bool = false
	var can_leave: bool = false
	var reason: String = ""

	func ok() -> bool:
		return has_ground and clear and reachable and can_leave

	func describe() -> String:
		if ok():
			return "%s : ancrage sain (sol %.2f, chute %.2f)" \
				% [place_id, ground_y, drop]
		return "%s : %s" % [place_id, reason]


## Audit complet. `space` vient de `get_world_3d().direct_space_state`.
## Les points 3 à 5 demandent un corps réel : ils sont menés par
## `RewardAnchorAudit`, qui a besoin d'attendre des frames physiques — chose
## qu'un `Marker3D` ne peut pas faire. Ici on tranche ce qui est immédiat.
func probe_ground(space: PhysicsDirectSpaceState3D) -> Verdict:
	var verdict: Verdict = Verdict.new()
	verdict.place_id = place_id

	# 1. Sol réel sous l'ancrage.
	var from: Vector3 = global_position + Vector3(0, PROBE_HEIGHT, 0)
	var to: Vector3 = global_position + Vector3(0, -MAX_DROP - 1.0, 0)
	var ray: PhysicsRayQueryParameters3D = \
		PhysicsRayQueryParameters3D.create(from, to)
	ray.collide_with_areas = false
	var hit: Dictionary = space.intersect_ray(ray)
	if hit.is_empty():
		verdict.reason = "aucun sol sous l'ancrage — la récompense flotterait"
		return verdict
	verdict.has_ground = true
	verdict.ground_y = float((hit["position"] as Vector3).y)
	verdict.drop = global_position.y - verdict.ground_y
	if verdict.drop > MAX_DROP:
		verdict.reason = "ancrage %.2f m au-dessus du sol — récompense en l'air" \
			% verdict.drop
		return verdict
	if verdict.drop < -0.4:
		verdict.reason = "ancrage %.2f m SOUS le sol — récompense enterrée" \
			% -verdict.drop
		return verdict

	# 2. Le joueur tient debout ici, et la récompense a la place d'exister.
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = BODY_RADIUS
	shape.height = BODY_HEIGHT
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY,
		Vector3(global_position.x, verdict.ground_y + BODY_HEIGHT * 0.5 + 0.05,
			global_position.z))
	query.collide_with_areas = false
	var blocked: Array[Dictionary] = space.intersect_shape(query, 4)
	if not blocked.is_empty():
		verdict.reason = "ancrage encastré : %d collision(s) au gabarit joueur" \
			% blocked.size()
		return verdict
	verdict.clear = true
	return verdict


## Point d'où l'accessibilité se mesure. Retombe sur l'ancrage lui-même si le
## bâtisseur n'a rien renseigné — l'audit le signale alors comme faible.
func approach_point() -> Vector3:
	if approach_from.is_equal_approx(Vector3.ZERO):
		return global_position + Vector3(0, 0.1, 0)
	return approach_from


func has_declared_approach() -> bool:
	return not approach_from.is_equal_approx(Vector3.ZERO)
