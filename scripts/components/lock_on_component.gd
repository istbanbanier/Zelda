## Verrouillage de cible (MASTER_SPEC §8.4).
##
## §8.4 : score par cône caméra, distance et ligne de vue ; libération si la
## cible meurt, se cache ou s'éloigne ; « jamais à travers mur ». Ce composant
## choisit et surveille la cible — la caméra et l'orientation du personnage
## consomment le résultat, ils ne choisissent rien.
##
## La LOS est revérifiée par cadence (§12.9 : pas de raycast par frame quand une
## fraction du tick suffit), avec une période de grâce : une cible masquée un
## instant par un pilier ne décroche pas, une cible réfugiée derrière un mur si.
class_name LockOnComponent
extends Node

signal target_acquired(target: Node3D)
signal target_released(reason: StringName)

## §8.4 : acquisition à 18–24 m.
@export var acquire_range: float = 22.0
## Libération au-delà — plus loin que l'acquisition, pour éviter le clignotement
## d'une cible qui danse autour de la limite.
@export var release_range: float = 26.0
## Demi-angle du cône d'acquisition autour de l'axe caméra.
@export var acquire_half_angle_deg: float = 40.0
## LOS perdue en continu pendant cette durée → libération (§8.4 « cachée »).
@export var los_grace: float = 0.5
## Couches bloquant la ligne de vue (décor statique).
@export_flags_3d_physics var los_mask: int = 1

var _target: Node3D = null
var _los_lost_for: float = 0.0
var _los_tick: int = 0


## Cherche la meilleure cible depuis `origin`, dans le cône de `camera_forward`.
## Score §8.4 : l'angle domine, la distance départage.
func acquire(owner_body: PhysicsBody3D, origin: Vector3, camera_forward: Vector3) -> Node3D:
	var best: Node3D = null
	var best_score: float = INF
	var cos_limit: float = cos(deg_to_rad(acquire_half_angle_deg))
	for node: Node in owner_body.get_tree().get_nodes_in_group("lock_on_targets"):
		var candidate: Node3D = node as Node3D
		if candidate == null or candidate == owner_body \
				or candidate.is_ancestor_of(owner_body) or owner_body.is_ancestor_of(candidate):
			continue
		if _is_dead(candidate):
			continue
		var to_target: Vector3 = _aim_point(candidate) - origin
		var distance: float = to_target.length()
		if distance > acquire_range or distance < 0.001:
			continue
		var direction: Vector3 = to_target / distance
		var alignment: float = direction.dot(camera_forward.normalized())
		if alignment < cos_limit:
			continue
		if not _has_los(owner_body, origin, candidate):
			continue
		# Angle d'abord, distance ensuite : la cible visée l'emporte sur la proche.
		var score: float = (1.0 - alignment) * 100.0 + distance
		if score < best_score:
			best_score = score
			best = candidate
	if best != null:
		_target = best
		_los_lost_for = 0.0
		target_acquired.emit(best)
	return best


func release(reason: StringName) -> void:
	if _target == null:
		return
	_target = null
	target_released.emit(reason)


## À appeler au rythme physique tant qu'une cible est tenue. Vérifie mort,
## distance et — par cadence — la ligne de vue.
func update(owner_body: PhysicsBody3D, origin: Vector3, delta: float) -> void:
	if _target == null:
		return
	if not is_instance_valid(_target) or _is_dead(_target):
		release(&"target_dead")
		return
	if (_aim_point(_target) - origin).length() > release_range:
		release(&"out_of_range")
		return
	_los_tick += 1
	if _los_tick % 6 == 0:
		if _has_los(owner_body, origin, _target):
			_los_lost_for = 0.0
		else:
			_los_lost_for += delta * 6.0
			if _los_lost_for >= los_grace:
				release(&"line_of_sight_lost")


## Changement de cible directionnel (§8.4). Les candidates valides sont triées
## par azimut caméra (gauche → droite) ; `direction` +1 va vers la droite, -1
## vers la gauche, sans boucler — un pas au-delà du bord ne fait rien, ce qui
## évite le « target switch absurde » que §10.8 traque.
func switch_target(owner_body: PhysicsBody3D, origin: Vector3,
		camera_forward: Vector3, direction: int) -> Node3D:
	if _target == null:
		return null
	var forward: Vector3 = camera_forward.normalized()
	var right: Vector3 = forward.cross(Vector3.UP).normalized()
	var candidates: Array[Node3D] = []
	for node: Node in owner_body.get_tree().get_nodes_in_group("lock_on_targets"):
		var candidate: Node3D = node as Node3D
		if candidate == null or candidate == owner_body \
				or candidate.is_ancestor_of(owner_body) or owner_body.is_ancestor_of(candidate):
			continue
		if _is_dead(candidate):
			continue
		if (_aim_point(candidate) - origin).length() > release_range:
			continue
		if not _has_los(owner_body, origin, candidate):
			continue
		candidates.append(candidate)
	if candidates.size() < 2 or not candidates.has(_target):
		return _target
	# Azimut signé : négatif à gauche de la caméra, positif à droite.
	candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return _bearing(origin, right, forward, a) < _bearing(origin, right, forward, b))
	var index: int = candidates.find(_target)
	var next_index: int = clampi(index + signi(direction), 0, candidates.size() - 1)
	if next_index == index:
		return _target
	_target = candidates[next_index]
	_los_lost_for = 0.0
	target_acquired.emit(_target)
	return _target


func _bearing(origin: Vector3, right: Vector3, forward: Vector3, node: Node3D) -> float:
	var to_node: Vector3 = _aim_point(node) - origin
	return atan2(to_node.dot(right), to_node.dot(forward))


func target() -> Node3D:
	return _target if _target != null and is_instance_valid(_target) else null


func has_target() -> bool:
	return target() != null


## Point visé : le torse, pas les pieds (§12.7 fait pareil pour la perception).
func _aim_point(node: Node3D) -> Vector3:
	return node.global_position + Vector3.UP * 1.0


func _has_los(owner_body: PhysicsBody3D, origin: Vector3, candidate: Node3D) -> bool:
	var space: PhysicsDirectSpaceState3D = owner_body.get_world_3d().direct_space_state
	if space == null:
		return false
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin, _aim_point(candidate), los_mask, [owner_body.get_rid()])
	return space.intersect_ray(query).is_empty()


## Une cible morte se décroche (§8.4). Convention : la cible expose `health()`.
func _is_dead(candidate: Node3D) -> bool:
	if candidate.has_method("health"):
		var health: HealthComponent = candidate.call("health") as HealthComponent
		return health != null and health.is_dead()
	return false
