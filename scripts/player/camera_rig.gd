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

## Couches physiques (project.godot [layer_names]) pertinentes pour la sonde
## de caméra. `Player.tscn` pose `SpringArm3D.collision_mask = 1` — la seule
## couche « World Static ». Playtest externe (KNOWN_ISSUES, S1), capture
## `10-boss-death.png` : « caméra à l'intérieur du modèle du boss ». Cause
## RÉELLE, prouvée par bitmask (`1 & StormGuardian.collision_layer(4) == 0`)
## et par un cast isolé sans le monde du jeu (SpringArm3D sur `WORLD_STATIC`
## seul : franchit un corps posé sur `ENEMY` sans jamais raccourcir son bras,
## `get_hit_length()` reste au maximum) : les ennemis — le Gardien y compris,
## 9,58 m de long — sont posés sur la couche « Enemy », invisible à la sonde.
## §8.3 exige « zéro traversée » et PROMPT2_SPEC §5.5 exige d'« empêcher
## géométrie entre caméra et héros » ; un corps solide qui se tient devant la
## caméra en fait partie autant qu'un mur. Ce n'est PAS spécifique au boss :
## toute la classe « Enemy » (raiders, colosse, chasseur) partage la couche.
const WORLD_STATIC_LAYER: int = 1
const ENEMY_LAYER: int = 4

## Amplitude du sondage vertical du garde-sol (voir `_keep_camera_above_ground`).
## Le rayon part au-dessus de la caméra pour attraper aussi le cas où elle est
## DÉJÀ enfoncée sous une pente : partir de la caméra elle-même ne trouverait
## alors que le sol d'en dessous, et confirmerait l'erreur au lieu de la voir.
const GROUND_PROBE_UP: float = 2.0
const GROUND_PROBE_DOWN: float = 6.0

## Opacité courante du héros, pour n'écrire dans les instances qu'au changement.
var _hero_opacity: float = 1.0

@export var tuning: LocomotionTuning

@onready var _yaw_pivot: Node3D = $YawPivot
@onready var _pitch_pivot: Node3D = $YawPivot/PitchPivot
@onready var _spring_arm: SpringArm3D = $YawPivot/PitchPivot/SpringArm3D
@onready var _camera: Camera3D = $YawPivot/PitchPivot/SpringArm3D/Camera3D

var _pitch: float = -0.15
## Inversion du regard vertical, chargée une fois depuis `user://settings.cfg`.
var invert_look_y: bool = false
var _yaw: float = 0.0
## Cible de verrouillage (§8.4, §10.9 mode LockOn). Tant qu'elle est valide, le
## lacet et le tangage convergent vers elle et l'entrée de regard est ignorée —
## reprendre brutalement la main au décrochage est interdit (§10.9), d'où la
## convergence lissée dans les deux sens.
var _lock_target: Node3D = null
## §16.6 : « la caméra élargit distance/FOV PROGRESSIVEMENT » face au boss.
## Ce sont des SUPPLÉMENTS demandés par la scène (l'arène), jamais des
## valeurs absolues écrasant le réglage : le rig reste maître de sa base,
## et §8.3 (« aucun snap de FOV ») s'applique aussi à la distance — les
## deux convergent par interpolation framerate-independent.
var _framing_distance_target: float = 0.0
var _framing_fov_target: float = 0.0
var _framing_distance: float = 0.0
var _framing_fov: float = 0.0

## Secousse de contact (§10.7). Il n'en existait AUCUNE dans le projet : ni
## impulsion, ni réglage — un `grep` sur tout le dépôt ne trouvait que le
## commentaire d'un panneau d'options constatant l'absence. Un coup reçu ne
## produisait donc rien à l'écran, et le joueur perdait sa vie sans le sentir.
##
## Elle est ANGULAIRE, appliquée aux pivots, et jamais à la position de la
## caméra : `SpringArm3D` réécrit intégralement la position de ses enfants à
## chaque image — le projet a déjà payé ce piège une fois avec le décalage
## d'épaule. Elle est aussi purement ADDITIVE (§10.7) : `_yaw` et `_pitch`, qui
## sont la vérité du regard, ne sont jamais touchés, donc aucune secousse ne
## peut faire dériver le cadrage.
const SHAKE_DECAY: float = 9.0
## ~2,9° de débattement maximal : au-delà, l'écran devient illisible pendant
## l'instant précis où le joueur a besoin de lire ce qui l'a frappé.
const SHAKE_MAX_RAD: float = 0.05
const SHAKE_FREQUENCY: float = 32.0
var _shake_amplitude: float = 0.0
var _shake_time: float = 0.0
## Intensité voulue par le joueur, de 0 (aucune secousse) à 1. §17.5 exige que
## la secousse soit désactivable ; ce champ est le point unique où le régler.
var shake_scale: float = 1.0


func _ready() -> void:
	if tuning == null:
		tuning = LocomotionTuning.new()
	invert_look_y = UserSettings.load_invert_look_y()
	position.y = tuning.camera_target_height
	_spring_arm.spring_length = tuning.camera_distance
	# Épaule portée par le bras (voir l'en-tête). Effet secondaire recherché :
	# l'origine du cast se décale aussi — c'est bien depuis l'épaule, et non
	# depuis l'axe du personnage, qu'il faut tester l'obstacle.
	_spring_arm.position.x = tuning.camera_shoulder_offset
	_camera.position = Vector3.ZERO
	# Le mode est POSÉ ici, jamais laissé au défaut : c'est lui qui décide si
	# `fov` se lit en hauteur ou en largeur, et le projet a déjà payé cette
	# ambiguïté une fois (voir `LocomotionTuning.camera_fov`). `KEEP_HEIGHT`
	# est le choix du paysage : un écran plus large montre PLUS sur les côtés
	# au lieu de rogner le haut et le bas.
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.fov = tuning.camera_fov
	# Sonde volumique plutôt que rayon : voir `camera_probe_radius`. La forme est
	# créée ici, pas partagée dans la scène — deux joueurs ne doivent jamais
	# écrire dans la même ressource.
	var probe: SphereShape3D = SphereShape3D.new()
	probe.radius = tuning.camera_probe_radius
	_spring_arm.shape = probe
	# `Player.tscn` pose `collision_mask = 1` (World Static seul) : on l'étend
	# ICI, en code, pour que la caméra voie aussi les corps ennemis — voir
	# `ENEMY_LAYER` ci-dessus pour la preuve et la référence au bug.
	_spring_arm.collision_mask = WORLD_STATIC_LAYER | ENEMY_LAYER
	_apply_rotation()


## Deux garde-fous que `SpringArm3D` n'offre pas, appliqués APRÈS lui.
##
## Le bras résout dans `NOTIFICATION_INTERNAL_PHYSICS_PROCESS` ; ce correctif
## vit dans `_process` — donc toujours après, quel que soit l'ordre des nœuds
## dans l'arbre, et c'est bien cette valeur-là que le rendu lit. Dépendre de
## l'ordre de traitement aurait donné un défaut qui n'apparaît qu'une fois
## sur deux, c'est-à-dire le pire des deux mondes.
func _process(_delta: float) -> void:
	if tuning == null:
		return
	_enforce_minimum_distance()
	_keep_camera_above_ground()
	_fade_hero_when_camera_is_close()


## 1. LA CAMÉRA NE RENTRE PLUS DANS LE HÉROS.
##
## `get_hit_length()` peut valoir 0 (obstacle collé au pivot). On repose donc
## la caméra nous-mêmes, jamais plus près que `camera_min_distance`. L'axe est
## +Z local : c'est la direction de cast du bras (`spring_arm_3d.cpp:142`).
func _enforce_minimum_distance() -> void:
	var resolved: float = maxf(_spring_arm.get_hit_length(),
		tuning.camera_min_distance)
	_camera.position = Vector3(0.0, 0.0, resolved)


## 2. LA CAMÉRA NE PASSE PLUS SOUS LE SOL.
##
## Le bras ne sonde QUE le segment pivot→caméra. Au bord d'une tranchée — le
## lit de la rivière en est une, 3,5 m de creux sur 512 m — ce segment peut
## passer au-dessus du vide sans rien toucher, et la caméra atterrit sous la
## berge d'en face. On sonde donc verticalement le sol réellement sous elle.
func _keep_camera_above_ground() -> void:
	var here: Vector3 = _camera.global_position
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if space == null:
		return
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		here + Vector3.UP * GROUND_PROBE_UP, here - Vector3.UP * GROUND_PROBE_DOWN,
		WORLD_STATIC_LAYER)
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return
	var floor_y: float = (hit["position"] as Vector3).y
	var lowest: float = floor_y + tuning.camera_ground_clearance
	if here.y < lowest:
		_camera.global_position = Vector3(here.x, lowest, here.z)


## 3. SOUS LE SEUIL, LE HÉROS S'EFFACE.
##
## Quand un mur force vraiment la caméra à bout touchant, la remonter à
## `camera_min_distance` ne suffit pas : à 0,85 m le dos du héros occupe encore
## tout l'écran. On le rend progressivement transparent — §17.4 « aucune
## information cachée » vaut d'abord pour ce que le joueur doit voir devant lui.
## L'opacité revient dès que la caméra recule : rien n'est définitif.
func _fade_hero_when_camera_is_close() -> void:
	var visual: Node3D = get_parent().get_node_or_null("VisualRoot") as Node3D
	if visual == null:
		return
	var span: float = maxf(0.01,
		tuning.camera_fade_distance - tuning.camera_min_distance)
	# Distance RÉELLE pivot→caméra, pas `_camera.position.z` : le garde-sol
	# ci-dessus a pu réécrire la position globale, et le Z local ne mesure
	# alors plus rien. Lire la mauvaise valeur ici ferait clignoter le héros
	# au bord de la rivière — un second défaut né de la correction du premier.
	var distance: float = _spring_arm.global_position.distance_to(
		_camera.global_position)
	var opacity: float = clampf(
		(distance - tuning.camera_min_distance) / span, 0.0, 1.0)
	# `visible` plutôt qu'une transparence quand l'opacité tombe à zéro : un
	# matériau transparent coûte un tri et un overdraw pour un objet qu'on ne
	# voit pas. En dessous d'un pouième, on coupe.
	visual.visible = opacity > 0.02
	_apply_opacity(visual, opacity)


func _apply_opacity(visual: Node3D, opacity: float) -> void:
	if is_equal_approx(opacity, _hero_opacity):
		return
	_hero_opacity = opacity
	for node: Node in visual.find_children("*", "GeometryInstance3D", true, false):
		var geometry: GeometryInstance3D = node as GeometryInstance3D
		# `transparency` est la voie d'instance : elle n'oblige à dupliquer
		# aucun matériau, donc deux héros ne se repeignent pas l'un l'autre
		# et le télégraphe de combat garde sa surface d'écriture.
		geometry.transparency = clampf(1.0 - opacity, 0.0, 1.0)


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
	# Inversion de l'axe vertical (§17.5) : un réglage, pas une opinion. Lu au
	# chargement, pas par frame — un `ConfigFile` par image serait un accès
	# disque à 60 Hz.
	var vertical: float = analog.y * tuning.camera_stick_speed * delta + mouse.y
	_pitch -= -vertical if invert_look_y else vertical
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
## Le supplément de cadrage boss (§16.6) s'ajoute ici, sur la MÊME courbe :
## un colosse de 6,4 m ne tient pas dans le cadre d'exploration, et le
## recul doit se sentir sans qu'on le voie arriver d'un coup.
func update_fov(sprinting: bool, delta: float) -> void:
	if tuning == null:
		return
	var weight: float = 1.0 - exp(-tuning.camera_fov_speed * delta)
	_framing_fov = lerpf(_framing_fov, _framing_fov_target, weight)
	_framing_distance = lerpf(_framing_distance, _framing_distance_target, weight)
	var target: float = tuning.camera_fov_sprint if sprinting else tuning.camera_fov
	_camera.fov = lerpf(_camera.fov, target + _framing_fov, weight)
	# Le bras s'allonge, mais le `SpringArm3D` continue de sonder : reculer
	# ne fait donc jamais traverser un mur (§8.3), il fait seulement place.
	_spring_arm.spring_length = tuning.camera_distance + _framing_distance


## §16.6 — appelé par l'arène tant que le boss est vivant et proche. Deux
## suppléments, pas deux réglages absolus ; `0, 0` rend la caméra normale.
func set_boss_framing(extra_distance: float, extra_fov: float) -> void:
	_framing_distance_target = maxf(0.0, extra_distance)
	_framing_fov_target = maxf(0.0, extra_fov)


## Seams de mesure : c'est le supplément RÉELLEMENT appliqué, pas la consigne.
func boss_framing_distance() -> float:
	return _framing_distance


func boss_framing_fov() -> float:
	return _framing_fov


## Demande une secousse, en radians de débattement : 0,012 pour un coup léger,
## 0,025 pour un coup lourd, 0,04 pour un événement de boss. Les demandes ne
## s'additionnent pas — on garde la plus forte, sinon trois impacts dans la
## même seconde rendraient le combat illisible au moment où il compte.
func add_shake(strength: float) -> void:
	if shake_scale <= 0.0 or strength <= 0.0:
		return
	_shake_amplitude = minf(
		maxf(_shake_amplitude, strength * shake_scale), SHAKE_MAX_RAD)


func shake_amplitude() -> float:
	return _shake_amplitude


## Avance la secousse au rythme physique, comme le reste du rig (§20.9).
func update_shake(delta: float) -> void:
	if _shake_amplitude <= 0.00001:
		if _shake_amplitude != 0.0:
			_shake_amplitude = 0.0
			_apply_rotation()
		return
	_shake_time += delta
	_shake_amplitude = maxf(0.0,
		_shake_amplitude - SHAKE_DECAY * _shake_amplitude * delta)
	_apply_rotation()


## Décalage angulaire courant. Deux sinus de fréquences premières entre elles :
## un mouvement franc mais non périodique, qui ne ressemble pas à une vibration.
func _shake_offset() -> Vector2:
	if _shake_amplitude <= 0.0:
		return Vector2.ZERO
	return Vector2(
		sin(_shake_time * SHAKE_FREQUENCY) * _shake_amplitude,
		sin(_shake_time * SHAKE_FREQUENCY * 1.37 + 1.1) * _shake_amplitude * 0.6)


func _apply_rotation() -> void:
	var shake: Vector2 = _shake_offset()
	_yaw_pivot.rotation.y = _yaw + shake.x
	_pitch_pivot.rotation.x = _pitch + shake.y


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
