## AUDIT d'accessibilité d'un ancrage de récompense.
##
## `RewardAnchor.probe_ground()` tranche ce qui est immédiat : sol réel,
## dégagement au gabarit du joueur. Ce qui suit demande du TEMPS PHYSIQUE —
## faire marcher un corps — et vit donc à part.
##
## Pourquoi ne pas se contenter d'un chemin de navigation : un navmesh répond
## « accessible » pour une corniche à six mètres, parce qu'il ne connaît ni la
## hauteur de saut, ni l'endurance, ni les surfaces escaladables. Pour un lieu
## marqué `requires_traversal`, la preuve par navigation est donc REFUSÉE et
## l'audit exige que le corps fasse réellement le trajet.
##
## L'audit vérifie aussi le RETOUR. Un ancrage au fond d'un puits sans sortie
## satisfait « on y arrive » et reste un piège.
class_name RewardAnchorAudit
extends RefCounted

## Vitesse de marche du corps d'audit, en dessous de la course du jeu : on
## teste l'accessibilité, pas la performance.
const WALK_SPEED: float = 4.0
const GRAVITY: float = 24.0
## Budget de ticks pour rejoindre l'ancrage, puis pour en repartir.
const APPROACH_TICKS: int = 420
const RETURN_TICKS: int = 420
## Distance à laquelle on considère l'ancrage atteint — la portée
## d'interaction du jeu.
const ARRIVAL: float = RewardAnchor.INTERACTION_REACH


static func _make_body() -> CharacterBody3D:
	var body: CharacterBody3D = CharacterBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = RewardAnchor.BODY_RADIUS
	capsule.height = RewardAnchor.BODY_HEIGHT
	shape.shape = capsule
	body.add_child(shape)
	return body


## Marche un corps de `from` vers `to`, en le laissant glisser sur le décor.
## Renvoie la distance horizontale minimale atteinte.
static func _walk(tree: SceneTree, body: CharacterBody3D, from: Vector3,
		to: Vector3, ticks: int) -> float:
	body.global_position = from + Vector3(0, 0.6, 0)
	var best: float = 1e9
	for i: int in range(ticks):
		var delta: Vector3 = to - body.global_position
		delta.y = 0.0
		best = minf(best, delta.length())
		if best <= ARRIVAL:
			break
		body.velocity = delta.normalized() * WALK_SPEED
		if not body.is_on_floor():
			body.velocity.y = -GRAVITY * 0.5
		else:
			body.velocity.y = -1.0
		body.move_and_slide()
		await tree.physics_frame
	return best


## Audit complet d'UN ancrage, dans le monde déjà monté `world`.
##
## `tree` sert à attendre les frames physiques ; `anchor` doit être dans
## l'arbre. Le verdict renvoyé est celui de `probe_ground`, complété.
static func audit(tree: SceneTree, world: Node3D,
		anchor: RewardAnchor) -> RewardAnchor.Verdict:
	var space: PhysicsDirectSpaceState3D = \
		world.get_world_3d().direct_space_state
	var verdict: RewardAnchor.Verdict = anchor.probe_ground(space)
	if not verdict.has_ground or not verdict.clear:
		return verdict

	var body: CharacterBody3D = _make_body()
	world.add_child(body)
	var start: Vector3 = anchor.approach_point()
	var target: Vector3 = anchor.global_position

	# ALLER : le corps doit arriver à portée d'interaction.
	var reached: float = await _walk(tree, body, start, target, APPROACH_TICKS)
	verdict.reachable = reached <= ARRIVAL
	if not verdict.reachable:
		verdict.reason = ("inaccessible : le corps s'arrête à %.1f m de "
			+ "l'ancrage (porte fermée, pente, obstacle ?)") % reached
		body.queue_free()
		return verdict

	# RETOUR : on doit pouvoir repartir. Un ancrage dont on ne ressort pas
	# est un piège, même s'il est atteignable.
	var back: float = await _walk(tree, body, body.global_position, start,
		RETURN_TICKS)
	verdict.can_leave = back <= ARRIVAL * 2.0
	if not verdict.can_leave:
		verdict.reason = ("piège : on atteint la récompense mais on ne "
			+ "repart pas (bloqué à %.1f m du départ)") % back
	body.queue_free()
	return verdict


## Audit de TOUS les ancrages d'un monde monté. Renvoie la liste des verdicts,
## dans l'ordre des ancrages trouvés.
static func audit_all(tree: SceneTree,
		world: Node3D) -> Array[RewardAnchor.Verdict]:
	var verdicts: Array[RewardAnchor.Verdict] = []
	for node: Node in world.find_children("*", "RewardAnchor", true, false):
		verdicts.append(await audit(tree, world, node as RewardAnchor))
	return verdicts
