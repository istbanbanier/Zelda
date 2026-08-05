## Contrôleur du Bracelet de Résonance (P2 §3) — porte les cinq opérations.
## Tranche 1 : **Pulse** (P2 §3.2). Les suivantes (Arc Link, Polarité,
## Arc Step, Ground) s'ajouteront ici, chacune fail-first.
##
## Le contrôleur ne lit JAMAIS l'InputMap (D-013) : `PlayerController` lui
## transmet la décision et marque lui-même consommation/refus dans la sonde
## de latence. Interdits durs (GAMEPLAY_BIBLE §3.5) : aucune révélation à
## travers un mur — LOS calquée sur celle des ennemis (couche 1, monde
## statique) ; le Pulse est AUDIBLE (coût de bruit, §12.7).
class_name ResonanceController
extends Node

signal pulse_fired(revealed_count: int)

## Valeurs de départ P2 §3.2 — à migrer en Resource de tuning quand les
## cinq opérations existeront (une `ResonanceActionDefinition` par opération).
const PULSE_RADIUS: float = 10.0
const PULSE_COOLDOWN: float = 1.5
const REVEAL_DURATION: float = 3.0
## Rayon du bruit émis — entre flèche (8) et sprint (12) : discret mais réel.
const PULSE_NOISE_RADIUS: float = 9.0
## Hauteur de l'« œil » du Bracelet pour la ligne de vue.
const EYE_HEIGHT: float = 1.4

var _pulse_cooldown: float = 0.0


## À appeler chaque tick physique par le propriétaire, quel que soit le mode.
func tick(delta: float) -> void:
	_pulse_cooldown = maxf(0.0, _pulse_cooldown - delta)


## Tente un Pulse depuis `body`. Retourne `&"fired"` ou `&"cooldown"` — le
## propriétaire traduit ce verdict vers la sonde de latence.
func try_pulse(body: CharacterBody3D) -> StringName:
	if _pulse_cooldown > 0.0:
		return &"cooldown"
	_pulse_cooldown = PULSE_COOLDOWN
	var revealed_count: int = 0
	var space: PhysicsDirectSpaceState3D = body.get_world_3d().direct_space_state
	var eye: Vector3 = body.global_position + Vector3.UP * EYE_HEIGHT
	for node: Node in get_tree().get_nodes_in_group(&"resonance_targets"):
		var target: ResonanceTargetComponent = node as ResonanceTargetComponent
		if target == null:
			continue
		var anchor: Node3D = target.anchor()
		if anchor == null:
			continue
		if anchor.global_position.distance_to(body.global_position) > PULSE_RADIUS:
			continue
		if not _has_los(space, eye, anchor.global_position, body):
			continue
		target.reveal(REVEAL_DURATION)
		revealed_count += 1
	# Le Pulse s'entend (P2 §3.2) — même canal que sprint/impact/flèche.
	NoiseEvents.emit(get_tree(), body.global_position, PULSE_NOISE_RADIUS, &"pulse")
	pulse_fired.emit(revealed_count)
	return &"fired"


## LOS calquée sur `EnemyBase._has_los` : monde statique (couche 1), deux
## hauteurs de visée — voir l'une des deux suffit.
func _has_los(space: PhysicsDirectSpaceState3D, from: Vector3,
		target: Vector3, body: CharacterBody3D) -> bool:
	for height: float in [0.2, 0.8]:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			from, target + Vector3.UP * height, 1, [body.get_rid()])
		if space.intersect_ray(query).is_empty():
			return true
	return false
