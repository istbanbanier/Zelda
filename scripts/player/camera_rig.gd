## Support de caméra (MASTER_SPEC §8.3).
##
## Structure imposée : pivots + `SpringArm3D` avec `Camera3D` **enfant direct**.
##
## Comportement de `SpringArm3D` mesuré sur le moteur installé, pas supposé :
##   - il **réécrit intégralement** la position locale de ses enfants directs à
##     chaque image ; un décalage posé là est perdu en silence (constaté : caméra
##     placée en x = 0,32, relue en x = 0) ;
##   - un descendant plus profond conserve, lui, son décalage — mais le cast n'en
##     tient pas compte : caméra petite-fille décalée de 1 m sur l'axe du bras,
##     mesurée **0,64 m au-delà** de la face du mur. C'est là, précisément, que
##     l'exigence « enfant direct » de §8.3 protège de la traversée.
## D'où la répartition retenue : décalage d'épaule sur le bras, caméra enfant
## direct à position nulle.
##
## Le rig n'hérite d'aucune rotation du personnage : `PlayerController` maintient
## le corps à rotation nulle et n'oriente que `VisualRoot`. Sans cette séparation,
## la caméra tournerait avec le personnage et deviendrait incontrôlable.
##
## §8.3 : « interpolation framerate-independent », « aucun snap de FOV ».
class_name CameraRig
extends Node3D

## Vitesse de convergence vers la cible verrouillée (§8.4), en unités
## exponentielles par seconde — même famille que l'interpolation de FOV.
const LOCK_CONVERGENCE_SPEED: float = 6.0

@export var tuning: LocomotionTuning

@onready var _yaw_pivot: Node3D = $YawPivot
@onready var _pitch_pivot: Node3D = $YawPivot/PitchPivot
@onready var _spring_arm: SpringArm3D = $YawPivot/PitchPivot/SpringArm3D
@onready var _camera: Camera3D = $YawPivot/PitchPivot/SpringArm3D/Camera3D

var _pitch: float = -0.15
var _yaw: float = 0.0
## Cible de verrouillage (§8.4, §10.9 mode LockOn). Tant qu'elle est valide, le
## lacet et le tangage convergent vers elle et l'entrée de regard est ignorée —
## reprendre brutalement la main au décrochage est interdit (§10.9), d'où la
## convergence lissée dans les deux sens.
var _lock_target: Node3D = null


func _ready() -> void:
	if tuning == null:
		tuning = LocomotionTuning.new()
	position.y = tuning.camera_target_height
	_spring_arm.spring_length = tuning.camera_distance
	# Épaule portée par le bras (voir l'en-tête). Effet secondaire recherché :
	# l'origine du cast se décale aussi — c'est bien depuis l'épaule, et non
	# depuis l'axe du personnage, qu'il faut tester l'obstacle.
	_spring_arm.position.x = tuning.camera_shoulder_offset
	_camera.position = Vector3.ZERO
	_camera.fov = tuning.camera_fov
	# Sonde volumique plutôt que rayon : voir `camera_probe_radius`. La forme est
	# créée ici, pas partagée dans la scène — deux joueurs ne doivent jamais
	# écrire dans la même ressource.
	var probe: SphereShape3D = SphereShape3D.new()
	probe.radius = tuning.camera_probe_radius
	_spring_arm.shape = probe
	_apply_rotation()


## Le regard est appliqué au rythme physique, comme le reste du mouvement (§20.9).
## `look` est déjà normalisé par `PlayerInputReader` : ce script ignore si l'ordre
## vient d'une souris ou d'un stick.
func apply_look(analog: Vector2, mouse: Vector2, delta: float) -> void:
	if tuning == null:
		return
	if _lock_target != null and is_instance_valid(_lock_target):
		_apply_lock_look(delta)
		return
	# Stick : vitesse angulaire × delta. Souris : radians, TELS QUELS — la même
	# distance de tapis produit la même rotation quel que soit le framerate
	# (PT-D1-01). Lacet libre sur 360°, replié pour rester borné.
	_yaw -= analog.x * tuning.camera_stick_speed * delta + mouse.x
	_yaw = wrapf(_yaw, -PI, PI)
	_pitch -= analog.y * tuning.camera_stick_speed * delta + mouse.y
	_pitch = clampf(_pitch,
		deg_to_rad(tuning.camera_pitch_min_deg),
		deg_to_rad(tuning.camera_pitch_max_deg))
	_apply_rotation()


## Convergence vers la cible verrouillée : framerate-independent, butées de
## pitch conservées — le verrouillage n'a pas le droit de retourner la caméra.
func _apply_lock_look(delta: float) -> void:
	var to_target: Vector3 = (_lock_target.global_position + Vector3.UP * 1.0) \
		- global_position
	var flat: Vector2 = Vector2(to_target.x, to_target.z)
	if flat.length_squared() < 0.0001:
		return
	# Lacet : -Z regarde la cible. atan2(-x, -z) donne l'angle du repère Godot.
	var desired_yaw: float = atan2(-to_target.x, -to_target.z)
	# Tangage : léger plongé vers la cible, sans jamais dépasser les butées.
	var desired_pitch: float = clampf(
		atan2(to_target.y - tuning.camera_target_height, flat.length()) * 0.5 - 0.12,
		deg_to_rad(tuning.camera_pitch_min_deg),
		deg_to_rad(tuning.camera_pitch_max_deg))
	var weight: float = 1.0 - exp(-LOCK_CONVERGENCE_SPEED * delta)
	_yaw = lerp_angle(_yaw, desired_yaw, weight)
	_pitch = lerpf(_pitch, desired_pitch, weight)
	_apply_rotation()


## Élargit le champ pendant le sprint, par interpolation : §8.3 interdit tout snap.
func update_fov(sprinting: bool, delta: float) -> void:
	if tuning == null:
		return
	var target: float = tuning.camera_fov_sprint if sprinting else tuning.camera_fov
	var weight: float = 1.0 - exp(-tuning.camera_fov_speed * delta)
	_camera.fov = lerpf(_camera.fov, target, weight)


func _apply_rotation() -> void:
	_yaw_pivot.rotation.y = _yaw
	_pitch_pivot.rotation.x = _pitch


func get_pitch() -> float:
	return _pitch


func get_yaw() -> float:
	return _yaw


## Base de référence du déplacement caméra-relatif : c'est le **pivot de lacet**
## qui porte l'orientation, pas le rig lui-même dont la rotation reste nulle.
## Se tromper de nœud ici ferait ignorer la caméra par le déplacement.
func get_yaw_basis() -> Basis:
	return _yaw_pivot.global_transform.basis


func set_lock_target(target: Node3D) -> void:
	_lock_target = target


func clear_lock_target() -> void:
	_lock_target = null


func get_camera() -> Camera3D:
	return _camera


func get_spring_arm() -> SpringArm3D:
	return _spring_arm
