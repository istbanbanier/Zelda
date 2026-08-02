## Pillard azur — `raider_blue` (MASTER_SPEC §12.2).
##
## L'adversaire qui APPREND l'espace au joueur : 85 PV, LANCE à longue
## portée, approche en CONTOURNEMENT (jamais frontale à mi-distance),
## ALERTE des alliés (14 m, via le socle), MAINTIEN DE DISTANCE entre
## deux piques (il ressort de la mêlée pendant son cooldown), et ESQUIVE
## OCCASIONNELLE d'une lourde très télégraphiée — pas latéral vif,
## cooldown 8 s (§12.2 : « ne spamme pas l'esquive ; cooldown 6-10 s »).
## Ses nombres vivent dans `raider_blue_default.tres` (§5.4).
class_name RaiderBlue
extends EnemyBase

## Bande de contournement : entre ces distances, l'approche mêle une
## composante latérale — le flanc est choisi une fois par acquisition.
const FLANK_MIN: float = 2.8
const FLANK_MAX: float = 8.0
const FLANK_BLEND: float = 0.45
## Distance rouverte pendant le cooldown d'attaque (alternance §12.2).
const SPACING_DISTANCE: float = 3.4
## Esquive de lourde : fenêtre de détection, impulsion, cadence.
const DODGE_TRIGGER_RANGE: float = 3.8
const SIDESTEP_TIME: float = 0.28
const SIDESTEP_SPEED: float = 7.5
const DODGE_COOLDOWN: float = 8.0

var _flank_side: float = 1.0
var _sidestep_timer: float = 0.0
var _sidestep_direction: Vector3 = Vector3.ZERO
var _dodge_cooldown: float = 0.0


func _family_ready() -> void:
	telegraph_color = Color(0.25, 0.55, 1.0)
	# Lance visible (même règle PT-D1-03 que le gourdin du braise).
	var spear: MeshInstance3D = MeshInstance3D.new()
	spear.name = "SpearMesh"
	var shaft: BoxMesh = BoxMesh.new()
	shaft.size = Vector3(0.06, 0.06, 1.7)
	spear.mesh = shaft
	var spear_material: StandardMaterial3D = StandardMaterial3D.new()
	spear_material.albedo_color = Color(0.55, 0.42, 0.26)
	spear.material_override = spear_material
	spear.position = Vector3(0.3, 1.05, 0.5)
	_pivot.add_child(spear)
	# Le flanc dépend de l'instance, stable pour la vie de l'ennemi —
	# déterministe par position de spawn (pas d'aléa par frame).
	_flank_side = 1.0 if int(absf(global_position.x * 7.0)) % 2 == 0 else -1.0


func _family_visual_mounted() -> void:
	var spear: MeshInstance3D = _pivot.get_node_or_null("SpearMesh") \
		as MeshInstance3D
	if spear == null:
		return
	var socket: BoneAttachment3D = _visual.weapon_socket()
	if socket == null:
		return
	var grip: Node3D = Node3D.new()
	grip.name = "SpearGrip"
	socket.add_child(grip)
	grip.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	grip.position = Vector3(0.0, 0.05, 0.0)
	spear.get_parent().remove_child(spear)
	grip.add_child(spear)
	spear.position = Vector3(0.0, 0.0, 0.45)
	spear.rotation = Vector3.ZERO


## Esquive latérale : elle a la MAIN sur tout le reste tant qu'elle dure.
func _process_family_state(delta: float) -> bool:
	_dodge_cooldown = maxf(0.0, _dodge_cooldown - delta)
	if _sidestep_timer > 0.0:
		_sidestep_timer -= delta
		velocity.x = _sidestep_direction.x * SIDESTEP_SPEED
		velocity.z = _sidestep_direction.z * SIDESTEP_SPEED
		move_and_slide()
		return true
	if _state == State.CHASE and _dodge_cooldown <= 0.0:
		_maybe_dodge_telegraphed_heavy()
	return false


## §12.2 : « esquive occasionnellement une lourde très télégraphiée » —
## la DÉTECTION lit le contrat d'attaque du joueur (startup d'une lourde
## à portée), jamais l'animation.
func _maybe_dodge_telegraphed_heavy() -> void:
	var player: PlayerController = _target as PlayerController
	if player == null:
		return
	var controller: AttackControllerComponent = player.attack_controller()
	if controller == null or controller.current_attack() == null:
		return
	if controller.current_attack() != controller.heavy_attack:
		return
	if controller.phase() != AttackControllerComponent.Phase.STARTUP:
		return
	if global_position.distance_to(player.global_position) > DODGE_TRIGGER_RANGE:
		return
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.0001:
		return
	_sidestep_direction = to_player.normalized() \
		.cross(Vector3.UP) * _flank_side
	_sidestep_timer = SIDESTEP_TIME
	_dodge_cooldown = DODGE_COOLDOWN


## Contournement et alternance distance/attaque (§12.2) : pendant le
## cooldown il ROUVRE la distance ; à mi-distance il aborde de FLANC.
func _family_chase_velocity(direction: Vector3, distance: float) -> Vector3:
	if _attack_cooldown > 0.0 and distance < SPACING_DISTANCE:
		return -direction * tuning.retreat_speed
	if distance >= FLANK_MIN and distance <= FLANK_MAX:
		var flank: Vector3 = direction.cross(Vector3.UP) * _flank_side
		var blended: Vector3 = (direction * (1.0 - FLANK_BLEND)
			+ flank * FLANK_BLEND)
		if blended.length_squared() > 0.0001:
			blended = blended.normalized()
		return blended * tuning.pursuit_speed
	return direction * tuning.pursuit_speed


## Seam de test : le flanc choisi (±1) et l'état de l'esquive.
func flank_side() -> float:
	return _flank_side


func is_sidestepping() -> bool:
	return _sidestep_timer > 0.0


func dodge_cooldown_left() -> float:
	return _dodge_cooldown
