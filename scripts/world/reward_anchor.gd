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

## Le lieu exige-t-il escalade, rampe ou saut pour être atteint ? Si oui, la
## preuve par navigation est REFUSÉE : il faut un scénario physique.
@export var requires_traversal: bool = false

## Pied de la traversée, dans le repère du lieu — la plaine d'où commence la
## montée. N'a de sens que si `requires_traversal` : l'audit y pose un corps et
## exige qu'il ARRIVE, ce qu'aucun navmesh ne saurait démontrer.
@export var traversal_base: Vector3 = Vector3.ZERO

## D'où le joueur arrive, en coordonnées GLOBALES. Laissé à zéro, l'audit part
## du lieu lui-même, ce qui est plus faible : les bâtisseurs doivent le
## renseigner — directement, ou via `approach_local` ci-dessous.
@export var approach_from: Vector3 = Vector3.ZERO

## Le même point, exprimé dans le repère du LIEU. C'est la forme à préférer :
## un bâtisseur connaît le seuil de sa grotte en local, pas en coordonnées de
## vallée, et un point global figé à la construction mentirait si le lieu
## était déplacé ensuite. Résolu au moment de l'audit.
@export var approach_local: Vector3 = Vector3.ZERO

## Rayon dans lequel la récompense doit rester interactible.
const INTERACTION_REACH: float = 2.2
## Distance à laquelle le joueur se tient pour interagir. Assez loin pour ne
## pas se cogner à la récompense, assez près pour rester dans sa portée.
const STAND_OFFSET: float = 1.2
## Couche « World Static » du projet : ce qui constitue le décor porteur.
const WORLD_STATIC: int = 1
## Gabarit du joueur (§8.2).
const BODY_RADIUS: float = 0.35
const BODY_HEIGHT: float = 1.7
## Hauteur au-dessus de l'ancrage d'où l'on sonde le sol. Volontairement
## BASSE : partir de trois mètres faisait rencontrer au rayon la roche en
## surplomb d'un territoire, qui devenait alors « le sol », et l'ancrage
## paraissait enterré sous elle.
const PROBE_HEIGHT: float = 1.2
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
	var mine: Array[RID] = own_bodies()
	var ray: PhysicsRayQueryParameters3D = \
		PhysicsRayQueryParameters3D.create(from, to)
	ray.collide_with_areas = false
	# La récompense pend sous l'ancrage : sans cette exclusion, le rayon
	# rencontre le couvercle du coffre et conclut que l'ancrage est « 70 cm
	# sous le sol ». Un objet ne peut pas servir de preuve sur lui-même.
	ray.exclude = mine
	# Le SOL est de la géométrie statique du monde (couche 1). Sans ce filtre,
	# un ennemi de passage tenait lieu de sol et l'ancrage était déclaré
	# enterré sous lui — un verdict qui changeait selon qui patrouillait.
	ray.collision_mask = WORLD_STATIC
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

	# 2. Le joueur tient debout DEVANT la récompense.
	#
	# Pas dessus : la récompense elle-même est un corps solide, et exiger que
	# la capsule tienne à l'emplacement exact du coffre reviendrait à demander
	# que le coffre n'existe pas. Le gabarit est donc éprouvé à `STAND_OFFSET`
	# du côté d'où l'on arrive — bien en deçà de la portée d'interaction.
	var stand: Vector3 = standing_point()
	var floor_from: Vector3 = stand + Vector3(0, PROBE_HEIGHT, 0)
	var floor_to: Vector3 = stand + Vector3(0, -MAX_DROP - 1.5, 0)
	var floor_ray: PhysicsRayQueryParameters3D = \
		PhysicsRayQueryParameters3D.create(floor_from, floor_to)
	floor_ray.collide_with_areas = false
	floor_ray.exclude = mine
	floor_ray.collision_mask = WORLD_STATIC
	var floor_hit: Dictionary = space.intersect_ray(floor_ray)
	if floor_hit.is_empty():
		verdict.reason = "aucun sol devant la récompense — on ne peut pas s'en approcher"
		return verdict
	var stand_y: float = float((floor_hit["position"] as Vector3).y)

	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = BODY_RADIUS
	shape.height = BODY_HEIGHT
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY,
		Vector3(stand.x, stand_y + BODY_HEIGHT * 0.5 + 0.05, stand.z))
	query.collide_with_areas = false
	query.exclude = mine
	query.collision_mask = WORLD_STATIC
	var blocked: Array[Dictionary] = space.intersect_shape(query, 4)
	if not blocked.is_empty():
		verdict.reason = "ancrage encastré : %d collision(s) au gabarit joueur" \
			% blocked.size()
		return verdict
	verdict.clear = true
	return verdict


## Corps physiques appartenant à la récompense elle-même. Les sondes les
## excluent : un coffre ne peut pas prouver qu'il repose sur du solide en
## interceptant le rayon censé chercher le sol sous lui.
func own_bodies() -> Array[RID]:
	var rids: Array[RID] = []
	for node: Node in find_children("*", "CollisionObject3D", true, false):
		rids.append((node as CollisionObject3D).get_rid())
	return rids


## Point où le joueur se tient pour interagir : à `STAND_OFFSET` de l'ancrage,
## du côté d'où il arrive. Sans direction d'approche déclarée, on se rabat sur
## un décalage arbitraire — d'où l'insistance à renseigner `approach_local`.
func standing_point() -> Vector3:
	var toward: Vector3 = approach_point() - global_position
	toward.y = 0.0
	if toward.length() < 0.05:
		toward = Vector3.FORWARD
	return global_position + toward.normalized() * STAND_OFFSET


## Point d'où l'accessibilité se mesure. Retombe sur l'ancrage lui-même si le
## bâtisseur n'a rien renseigné — l'audit le signale alors comme faible.
func approach_point() -> Vector3:
	if not approach_local.is_equal_approx(Vector3.ZERO):
		var host: Node3D = get_parent() as Node3D
		if host != null:
			return host.to_global(approach_local)
	if not approach_from.is_equal_approx(Vector3.ZERO):
		return approach_from
	return global_position + Vector3(0, 0.1, 0)


## Pied de la traversée en coordonnées globales, ou INF si le lieu n'en
## déclare pas — auquel cas un lieu marqué `requires_traversal` est INCOMPLET,
## et l'audit doit le dire au lieu de le laisser passer.
func traversal_base_point() -> Vector3:
	if traversal_base.is_equal_approx(Vector3.ZERO):
		return Vector3.INF
	var host: Node3D = get_parent() as Node3D
	if host == null:
		return Vector3.INF
	return host.to_global(traversal_base)


func has_declared_approach() -> bool:
	return not approach_local.is_equal_approx(Vector3.ZERO) \
		or not approach_from.is_equal_approx(Vector3.ZERO)


## Pose un ancrage sous `host`, en coordonnées LOCALES du lieu.
##
## Neuf familles de lieux doivent poser 31 ancrages ; sans ce point d'entrée
## unique, chacune réécrirait la même quinzaine de lignes — c'est exactement
## ainsi qu'est né le problème d'origine, huit bâtisseurs et huit conventions
## de nommage différentes. Le nom du nœud est donc fixé ICI, une fois.
static func attach(host: Node3D, place: StringName, what: Kind,
		local_at: Vector3, local_approach: Vector3,
		traversal: bool = false) -> RewardAnchor:
	var anchor: RewardAnchor = RewardAnchor.new()
	anchor.name = "AncrageRecompense"
	anchor.place_id = place
	anchor.kind = what
	anchor.requires_traversal = traversal
	anchor.approach_local = local_approach
	anchor.position = local_at
	host.add_child(anchor)
	return anchor


## Pose l'ancrage d'un lieu à partir de la table de sa famille.
##
## Neuf familles décrivent 31 ancrages. Sans ce point d'entrée, chacune
## réécrirait la même lecture de dictionnaire — et c'est précisément ainsi que
## la première tentative a produit huit conventions divergentes. La table reste
## chez le bâtisseur, qui seul connaît son terrain ; la MÉCANIQUE est ici.
##
## Clés attendues : `at` et `approach` (Vector3 locaux), `kind`, et pour un
## lieu à gravir `traversal` (bool) plus `base` (pied de la montée).
static func attach_from_table(host: Node3D, place: StringName,
		table: Dictionary, family: String) -> RewardAnchor:
	var spec: Dictionary = table.get(place, {}) as Dictionary
	if spec.is_empty():
		# Bruyant DÈS LA CONSTRUCTION : un lieu sans ancrage est un lieu sans
		# récompense, et l'ordre d'extension §3 l'interdit.
		push_warning("[%s] %s : aucun ancrage de récompense déclaré"
			% [family, place])
		return null
	var what: Kind = spec.get("kind", Kind.CHEST)
	var anchor: RewardAnchor = attach(host, place, what,
		spec.get("at", Vector3.ZERO) as Vector3,
		spec.get("approach", Vector3.ZERO) as Vector3,
		bool(spec.get("traversal", false)))
	anchor.traversal_base = spec.get("base", Vector3.ZERO) as Vector3
	return anchor
