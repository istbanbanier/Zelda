## Contrôleur du joueur — locomotion caméra-relative (MASTER_SPEC §8.1, §8.2).
##
## D-013 : ce script ne consulte **jamais** l'InputMap ni un périphérique. Il
## consomme une `InputIntent` produite par `PlayerInputReader`, ou injectée par un
## test. C'est ce qui rend la locomotion vérifiable en headless sans simuler la
## moindre touche — et ce qui garde la dette `CONTROLLER-001` payable.
##
## §20.9 : toute la logique de mouvement vit dans `_physics_process()`. Aucun
## transform de gameplay n'est écrit depuis `_process()`.
##
## ÉTAT B.4 : marche, course, sprint, saut, gravité, coyote time, jump buffer,
## **franchissement de marche** (§8.2), **escalade** (§9.2) et **mantle** (§9.3).
## Tous consomment le même `StaminaComponent`, qui n'a pas eu à changer pour les
## accueillir. §8.2 est désormais couvert en entier.
class_name PlayerController
extends CharacterBody3D

## Émis au contact du sol, avec la vitesse verticale d'impact (négative).
## Les dégâts de chute (§8.2) s'y brancheront sans modifier ce script.
signal landed(impact_speed: float)
signal left_ground()
## Émis au franchissement d'une marche (§8.2), avec l'altitude atteinte.
signal stepped_up(new_height: float)
## Accroche et lâcher de paroi (§9.2). `reason` dit pourquoi le mur a été lâché :
## `released`, `exhausted` ou `lost_contact`.
signal grabbed_wall(normal: Vector3)
signal released_wall(reason: StringName)
## Franchissement (§9.3). `refused` porte la raison nommée par le détecteur.
signal mantle_started(target: Vector3)
signal mantle_finished()
signal mantle_refused(reason: StringName)

## Modes de locomotion effectivement implémentés.
##
## §8.1 énumère vingt états, dont la moitié appartient au combat. Construire la
## machine complète maintenant reviendrait à écrire dix-huit états vides : ce
## `Mode` couvre exactement ce qui existe, et la `StateMachine` de §8.1 arrivera
## avec la Phase C, quand les états de combat auront un contenu (D-018).
enum Mode { LOCOMOTION, CLIMBING, MANTLING }

## Rappel vers la distance de paroi : gain en (m/s) par mètre d'écart, et vitesse
## maximale de correction. Bornés à dessein — voir `_apply_climb_motion()`.
const WALL_HOLD_GAIN: float = 8.0
const WALL_HOLD_MAX_SPEED: float = 1.5

## Hauteur dont le sommet du trajet de mantle dépasse la surface d'arrivée.
## Voir `_try_mantle()`.
const LEDGE_RISE_CLEARANCE: float = 0.06

## Marge de descente lors de la recherche du dessus d'une marche. Voir
## `_try_step_up()`.
const STEP_LANDING_MARGIN: float = 0.05

## Fraction de la distance demandée en deçà de laquelle le tick est considéré comme
## bloqué, et un franchissement tenté. Voir `_maybe_step_up()`.
const STEP_BLOCKED_RATIO: float = 0.5

@export var tuning: LocomotionTuning

@onready var _visual_root: Node3D = $VisualRoot
@onready var _camera_rig: CameraRig = $CameraRig
@onready var _input_reader: PlayerInputReader = $Components/PlayerInputReader
@onready var _stamina: StaminaComponent = $Components/StaminaComponent
@onready var _climbing: ClimbingComponent = $Components/ClimbingComponent
@onready var _ledge: LedgeDetectorComponent = $Components/LedgeDetectorComponent
@onready var _alignment: ActionAlignmentComponent = $Components/ActionAlignmentComponent
@onready var _collision: CollisionShape3D = $CollisionShape3D

## Intention courante. Remplacée par un test via `set_intent_source()`.
var _intent: InputIntent = null
var _use_reader: bool = true

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = true

var _mode: Mode = Mode.LOCOMOTION
## Normale de paroi lissée (§9.2 : « lissage normale 0,08–0,16 s »). Sans ce
## lissage, la moindre aspérité ferait pivoter le personnage d'un coup.
var _wall_normal: Vector3 = Vector3.ZERO
## Empêche de se raccrocher à la paroi dans le tick qui suit un lâcher volontaire
## ou un saut d'escalade : le joueur est encore contre le mur, il se rattraperait
## immédiatement et ne partirait jamais.
var _grab_cooldown: float = 0.0


func _ready() -> void:
	if tuning == null:
		tuning = LocomotionTuning.new()
		push_warning("[player] aucun LocomotionTuning assigné — valeurs par défaut utilisées.")
	# Le rig partage le même réglage : une seule source pour la caméra et le corps.
	if _camera_rig != null and _camera_rig.tuning == null:
		_camera_rig.tuning = tuning
	floor_max_angle = deg_to_rad(tuning.max_floor_angle_deg)
	floor_snap_length = tuning.floor_snap_length
	# Le corps ne tourne jamais : seule la représentation visuelle s'oriente. Sans
	# cela le `CameraRig`, enfant du corps, hériterait de sa rotation et tournerait
	# avec le personnage — la caméra deviendrait incontrôlable.
	floor_stop_on_slope = true


## Permet à un test de piloter le contrôleur sans aucun périphérique.
func set_intent_source(intent: InputIntent) -> void:
	_intent = intent
	_use_reader = false
	if _input_reader != null:
		_input_reader.set_capture_enabled(false)


func current_intent() -> InputIntent:
	if _use_reader and _input_reader != null:
		return _input_reader.get_intent()
	return _intent if _intent != null else InputIntent.new()


func _physics_process(delta: float) -> void:
	var intent: InputIntent = current_intent()

	# La caméra est mise à jour avant tout le reste : le repère utilisé pour
	# « avant » est celui que le joueur voit à cet instant.
	_camera_rig.apply_look(intent.look, delta)

	match _mode:
		Mode.MANTLING:
			_process_mantle(delta)
		Mode.CLIMBING:
			_process_climb(delta, intent)
		_:
			_process_locomotion(delta, intent)

	_orient_visual(delta)

	# Après les demandes d'effort, jamais avant : c'est `update()` qui décide si le
	# tick a consommé ou s'il faut régénérer.
	if _stamina != null:
		_stamina.update(delta)

	if _use_reader and _input_reader != null:
		_input_reader.clear_edges()
	elif _intent != null:
		_intent.consume_edges()


func _process_locomotion(delta: float, intent: InputIntent) -> void:
	# Une seule décision de sprint par tick, prise ici et transmise ensuite. La
	# caméra, la vitesse et l'endurance doivent s'accorder sur la même réponse :
	# recalculer la condition à trois endroits les ferait diverger au moment précis
	# où la jauge se vide.
	var sprinting: bool = _resolve_sprint(delta, intent)
	_camera_rig.update_fov(sprinting, delta)

	_update_timers(delta, intent)
	_apply_gravity(delta)
	_apply_horizontal_motion(delta, intent, sprinting)
	_try_jump()

	var was_on_floor: bool = is_on_floor()
	var vertical_before: float = velocity.y
	# Repères pris **avant** le déplacement : ils servent à mesurer ce que le tick
	# a réellement accompli, donc à détecter un blocage.
	var before: Vector3 = global_position
	var intended_speed: float = Vector2(velocity.x, velocity.z).length()
	move_and_slide()
	_detect_ground_transitions(was_on_floor, vertical_before)

	# Franchissement de marche avant l'accroche : une marche de 30 cm doit se
	# monter en marchant, pas déclencher une escalade.
	_maybe_step_up(delta, intent, before, intended_speed)

	# L'accroche est tentée **après** le déplacement : la paroi est sondée depuis
	# la position réellement atteinte, pas depuis celle du tick précédent.
	_try_grab(intent)


## Le sprint n'est accordé que s'il est demandé, que le joueur se déplace
## réellement, et que l'endurance le soutient (§9.1). Sprinter sur place ne
## consomme rien : c'est un état de locomotion, pas une posture.
##
## À zéro, `try_sustain()` refuse et le joueur retombe en course — la bascule de
## §9.1 est donc portée par le composant, pas par une condition dispersée ici.
func _resolve_sprint(delta: float, intent: InputIntent) -> bool:
	if not intent.sprint_held or not intent.has_move():
		return false
	if _stamina == null:
		return true
	return _stamina.try_sustain(_stamina.tuning.sprint_drain, delta)


func _update_timers(delta: float, intent: InputIntent) -> void:
	_grab_cooldown = maxf(0.0, _grab_cooldown - delta)
	if is_on_floor():
		_coyote_timer = tuning.coyote_time
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	# Le saut demandé trop tôt n'est pas perdu : il attend l'atterrissage (§8.2).
	if intent.jump_pressed:
		_jump_buffer_timer = tuning.jump_buffer
	else:
		_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta


## Déplacement **relatif à la caméra** (§8.2) : « avant » signifie l'écran, pas
## l'axe -Z du monde. C'est le pivot de lacet qui définit ce repère.
func _apply_horizontal_motion(delta: float, intent: InputIntent, sprinting: bool) -> void:
	var basis_yaw: Basis = _camera_rig.get_yaw_basis()
	var forward: Vector3 = -basis_yaw.z
	var right: Vector3 = basis_yaw.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var wish: Vector3 = right * intent.move.x + forward * intent.move.y
	var magnitude: float = minf(wish.length(), 1.0)
	if magnitude > 0.0:
		wish = wish.normalized()

	# `target_speed()` reste le seul endroit qui décide d'une vitesse. L'épuisement
	# n'y ajoute pas de branche : il se contente de faire arriver `sprinting` à
	# faux (§9.1, « sprint → course »).
	var speed: float = tuning.target_speed(magnitude, sprinting)
	var desired: Vector3 = wish * speed

	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = 0.0
	if is_on_floor():
		rate = tuning.ground_acceleration if magnitude > 0.0 else tuning.ground_deceleration
	else:
		# §8.2 : contrôle aérien réduit à 35 %. On ne peut pas changer de direction
		# en l'air aussi librement qu'au sol.
		rate = tuning.air_acceleration * tuning.air_control

	horizontal = horizontal.move_toward(desired, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _try_jump() -> void:
	if _jump_buffer_timer <= 0.0 or _coyote_timer <= 0.0:
		return
	velocity.y = tuning.jump_velocity
	_jump_buffer_timer = 0.0
	# Consommer le coyote empêche un second saut pendant la fenêtre restante.
	_coyote_timer = 0.0


func _detect_ground_transitions(was_on_floor: bool, vertical_before: float) -> void:
	var now_on_floor: bool = is_on_floor()
	if now_on_floor and not was_on_floor:
		landed.emit(vertical_before)
	elif not now_on_floor and was_on_floor:
		left_ground.emit()
	_was_on_floor = now_on_floor


## Oriente la représentation visuelle vers le déplacement. Le corps, lui, garde
## une rotation nulle : voir `_ready()`.
func _orient_visual(delta: float) -> void:
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length_squared() < 0.04:
		return
	var target_yaw: float = atan2(horizontal.x, horizontal.z)
	# Interpolation indépendante du framerate (§8.3) : à 30 comme à 120 FPS, la
	# rotation met le même temps réel à converger.
	var weight: float = 1.0 - exp(-tuning.visual_turn_speed * delta)
	_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, target_yaw, weight)


## Décide s'il y a lieu de tenter un franchissement de marche.
##
## Le déclencheur est le **blocage mesuré** — la distance réellement parcourue
## comparée à celle qui était demandée — et non `is_on_wall()`. Ce dernier a été
## mesuré peu fiable : plaqué contre le mur de 6 m du bac à sable, poussant depuis
## deux secondes, `is_on_wall()` renvoie **faux**. Y adosser le franchissement le
## rendait muet précisément dans les situations qu'il doit traiter, sans que rien
## ne le signale — la marche du bac à sable, elle, le déclenchait.
func _maybe_step_up(delta: float, intent: InputIntent, before: Vector3,
		intended_speed: float) -> void:
	if not is_on_floor() or intended_speed <= 0.001:
		return
	var wish: Vector3 = _wish_direction(intent)
	if wish.length_squared() < 0.04:
		return
	var travelled: float = Vector2(global_position.x - before.x,
		global_position.z - before.z).length()
	if travelled >= intended_speed * delta * STEP_BLOCKED_RATIO:
		return  # le tick a avancé normalement : rien ne gêne
	_try_step_up(wish)


## Franchit une marche basse (§8.2 : 0,30–0,38 m).
##
## `move_and_slide()` n'en monte aucune : mesuré sur le moteur installé, une marche
## de 0,32 m arrête le personnage net — `is_on_wall()` vrai, position figée, aucune
## erreur. Sans ce shape cast, le moindre rebord de décor devient un mur.
##
## Trois questions, dans cet ordre, chacune pouvant refuser :
##   1. y a-t-il la place de se hisser d'une hauteur de marche ?
##   2. une fois surélevé, la place d'avancer ?
##   3. y a-t-il, sous ce point, un sol **praticable** à moins d'une marche ?
## Un « non » à l'une des trois signifie que ce n'était pas une marche mais un mur,
## un plafond ou un vide — et le personnage reste où il est.
func _try_step_up(direction: Vector3) -> bool:
	if _collision == null or _collision.shape == null:
		return false
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return false

	var step: float = tuning.step_height
	var up: Vector3 = Vector3.UP * step
	var ahead: Vector3 = flat.normalized() * tuning.step_forward_probe

	# 1. Dégagement au-dessus. Un plafond bas interdit de se hisser.
	if test_move(global_transform, up):
		return false
	var raised: Transform3D = global_transform.translated(up)

	# 2. Dégagement devant, une fois surélevé. S'il n'y en a pas, l'obstacle est
	# plus haut qu'une marche : c'est un mur, et l'escalade s'en chargera.
	if test_move(raised, ahead):
		return false
	var advanced: Transform3D = raised.translated(ahead)

	# 3. Sol praticable dessous, à moins d'une hauteur de marche. La marge évite de
	# rater un contact au millimètre près ; sans sol, on serait au bord d'un vide et
	# se hisser reviendrait à léviter.
	var landing: KinematicCollision3D = KinematicCollision3D.new()
	if not test_move(advanced, Vector3.DOWN * (step + STEP_LANDING_MARGIN), landing):
		return false
	var normal: Vector3 = landing.get_normal()
	var angle: float = rad_to_deg(acos(clampf(normal.dot(Vector3.UP), -1.0, 1.0)))
	if angle > tuning.max_floor_angle_deg:
		return false

	global_position = advanced.origin + landing.get_travel()
	stepped_up.emit(global_position.y)
	return true


## ---------------------------------------------------------------------------
## Escalade (§9.2) et mantle (§9.3)
## ---------------------------------------------------------------------------

## Direction horizontale demandée, exprimée dans le monde (repère caméra).
func _wish_direction(intent: InputIntent) -> Vector3:
	var basis_yaw: Basis = _camera_rig.get_yaw_basis()
	var forward: Vector3 = -basis_yaw.z
	var right: Vector3 = basis_yaw.x
	forward.y = 0.0
	right.y = 0.0
	var wish: Vector3 = right.normalized() * intent.move.x + forward.normalized() * intent.move.y
	wish.y = 0.0
	return wish


func _space() -> PhysicsDirectSpaceState3D:
	var world: World3D = get_world_3d()
	if world == null:
		return null
	return world.direct_space_state


## Tente l'accroche. §9.2 ne fixe aucune touche : pousser vers une paroi
## saisissable suffit, au sol comme en l'air (D-017). Une action dédiée obligerait
## à l'ajouter partout — clavier, manette, remapping — pour un geste que le joueur
## fait déjà naturellement.
func _try_grab(intent: InputIntent) -> void:
	if _grab_cooldown > 0.0 or _climbing == null or not intent.has_move():
		return
	if _stamina != null and not _stamina.can_sustain():
		return  # épuisé : §9.1 fait lâcher le mur, s'y raccrocher serait absurde

	var wish: Vector3 = _wish_direction(intent)
	if wish.length_squared() < 0.04:
		return

	var probe: ClimbingComponent.WallProbe = _climbing.probe_wall(
		_space(), global_position, wish.normalized(), [get_rid()])
	if not probe.grabbable:
		return

	_enter_climb(probe.normal)


func _enter_climb(normal: Vector3) -> void:
	_mode = Mode.CLIMBING
	_wall_normal = normal
	velocity = Vector3.ZERO
	# L'accroche au sol doit être coupée pendant l'escalade : `floor_snap_length`
	# rabattrait le personnage vers le sol dès qu'il décolle du bas de la paroi,
	# et la montée s'arrêterait au premier mètre sans qu'aucune erreur ne le dise.
	floor_snap_length = 0.0
	grabbed_wall.emit(normal)


## Rétablit les réglages de locomotion coupés pendant l'escalade.
func _restore_ground_settings() -> void:
	floor_snap_length = tuning.floor_snap_length


## Lâche la paroi. Nommer la raison n'est pas cosmétique : `exhausted` et
## `released` produisent la même chute mais pas le même retour au joueur (§9.1
## demande une respiration), et un test doit pouvoir les distinguer.
func _release_wall(reason: StringName) -> void:
	if _mode != Mode.CLIMBING:
		return
	_mode = Mode.LOCOMOTION
	_wall_normal = Vector3.ZERO
	_grab_cooldown = 0.25
	_restore_ground_settings()
	released_wall.emit(reason)


func _process_climb(delta: float, intent: InputIntent) -> void:
	_camera_rig.update_fov(false, delta)
	_grab_cooldown = maxf(0.0, _grab_cooldown - delta)

	# §9.1 : à endurance nulle, le personnage lâche la paroi. La condition vit dans
	# le composant ; ici on ne fait qu'en tirer la conséquence.
	if _stamina != null and not _stamina.can_sustain():
		_release_wall(&"exhausted")
		return

	# §9.2 : « valider contact à chaque mouvement ». Une paroi qui s'interrompt
	# doit faire lâcher, pas laisser le personnage grimper dans le vide.
	var into_wall: Vector3 = -_wall_normal
	into_wall.y = 0.0
	if into_wall.length_squared() < 0.0001:
		_release_wall(&"lost_contact")
		return
	into_wall = into_wall.normalized()

	var probe: ClimbingComponent.WallProbe = _climbing.probe_wall(
		_space(), global_position, into_wall, [get_rid()])
	if not probe.grabbable:
		# Torse encore en contact mais pieds dans le vide : c'est le haut de la
		# paroi. On tente le franchissement avant de conclure à une perte de contact.
		if probe.chest_hit and _try_mantle(into_wall):
			return
		_release_wall(&"lost_contact")
		return

	# Lissage de la normale (§9.2) : framerate-independent, comme le reste.
	var weight: float = 1.0
	if _climb_tuning().normal_smoothing > 0.0:
		weight = 1.0 - exp(-delta / _climb_tuning().normal_smoothing)
	_wall_normal = _wall_normal.lerp(probe.normal, weight).normalized()

	# Le haut atteint : si un rebord franchissable existe et que le joueur pousse
	# vers le haut, on franchit (§9.3).
	if probe.ledge_likely and intent.move.y > 0.1 and _try_mantle(into_wall):
		return

	if intent.jump_pressed:
		_climb_jump(into_wall)
		return

	_apply_climb_motion(delta, intent, probe)


func _apply_climb_motion(delta: float, intent: InputIntent,
		probe: ClimbingComponent.WallProbe) -> void:
	var tune: ClimbTuning = _climb_tuning()
	# Repère de la paroi : « haut » reste le haut du monde, « droite » suit le mur.
	var wall_right: Vector3 = Vector3.UP.cross(_wall_normal).normalized()
	var vertical: float = intent.move.y * tune.climb_speed_up
	var lateral: float = intent.move.x * tune.climb_speed_lateral

	# §9.1 : l'escalade coûte 18/s, le latéral 16/s. On facture le mouvement
	# réellement demandé, dominante d'abord — cumuler les deux ferait payer deux
	# fois une diagonale.
	if _stamina != null:
		var rate: float = 0.0
		if absf(vertical) > 0.01 or absf(lateral) > 0.01:
			rate = _stamina.tuning.climb_drain if absf(intent.move.y) >= absf(intent.move.x) \
				else _stamina.tuning.climb_lateral_drain
		if rate > 0.0 and not _stamina.try_sustain(rate, delta):
			_release_wall(&"exhausted")
			return

	velocity = Vector3.UP * vertical + wall_right * lateral

	# Maintien à la bonne distance de la paroi (§9.2) : sans ce rappel, le
	# personnage dérive et finit par perdre le contact sur une paroi irrégulière.
	# Rappel **proportionnel et borné**, jamais une correction divisée par delta :
	# celle-ci ramènerait l'écart à zéro en une image, ce qui est un snap — et
	# ferait osciller le personnage contre la paroi, la capsule ne pouvant pas
	# s'approcher plus près que son rayon.
	var flat: Vector3 = Vector3(probe.point.x - global_position.x, 0.0,
		probe.point.z - global_position.z)
	var error: float = flat.length() - tune.wall_distance_m
	velocity += -_wall_normal * clampf(error * WALL_HOLD_GAIN, -WALL_HOLD_MAX_SPEED, WALL_HOLD_MAX_SPEED)

	move_and_slide()


## Saut d'escalade (§9.2 : 0,75–1,0 m ; §9.1 : 20 d'endurance).
func _climb_jump(into_wall: Vector3) -> void:
	var tune: ClimbTuning = _climb_tuning()
	if _stamina != null and not _stamina.try_spend(_stamina.tuning.climb_jump_cost):
		return
	_release_wall(&"released")
	# v = sqrt(2gh) : la hauteur demandée par §9.2 détermine la vitesse, pas
	# l'inverse. Coder la vitesse en dur rendrait la hauteur dépendante de la
	# gravité et donc fausse au premier réglage.
	velocity = Vector3.UP * sqrt(2.0 * tuning.gravity * tune.climb_jump_height)
	velocity += -into_wall * 1.5


## Tente le franchissement. Retourne `true` si le mantle démarre.
func _try_mantle(into_wall: Vector3) -> bool:
	if _ledge == null or _alignment == null or _collision == null:
		return false
	var result: LedgeDetectorComponent.LedgeResult = _ledge.find_ledge(
		_space(), global_position, into_wall, _collision.shape,
		_collision.position.y, tuning.max_floor_angle_deg, [get_rid()])
	if not result.valid:
		mantle_refused.emit(result.refusal)
		return false

	# Trajet en deux temps : monter au-dessus du rebord, puis avancer (§9.3,
	# « mantle bas/haut »). La droite du pied au dessus traverserait le rebord
	# lui-même, et le contrôle de capsule l'annulerait à mi-chemin — défaut
	# constaté, le franchissement nominal échouait sans qu'aucune géométrie ne soit
	# en cause. Le point haut dépasse la cible de `LEDGE_RISE_CLEARANCE` pour que
	# les pieds soient déjà au-dessus de la surface quand ils passent au-dessus.
	var tune: ClimbTuning = _climb_tuning()
	var apex: Vector3 = Vector3(global_position.x,
		result.target_feet.y + LEDGE_RISE_CLEARANCE, global_position.z)
	var path: PackedVector3Array = PackedVector3Array([global_position, apex, result.target_feet])
	if not _alignment.begin_path(path, tune.mantle_duration, tune.mantle_max_correction_m):
		mantle_refused.emit(&"correction_capped")
		return false

	_mode = Mode.MANTLING
	_wall_normal = Vector3.ZERO
	velocity = Vector3.ZERO
	floor_snap_length = 0.0
	mantle_started.emit(result.target_feet)
	return true


func _process_mantle(delta: float) -> void:
	_camera_rig.update_fov(false, delta)
	if not _alignment.is_active():
		_finish_mantle()
		return

	var next: Vector3 = _alignment.advance(delta)
	# §7.12 : annuler si la capsule se retrouve bloquée. Le décor peut bouger
	# pendant les 0,45 s du franchissement ; le valider une seule fois au départ ne
	# suffirait pas.
	if _capsule_blocked_at(next):
		_alignment.cancel(&"blocked")
		_mode = Mode.LOCOMOTION
		_grab_cooldown = 0.25
		_restore_ground_settings()
		mantle_refused.emit(&"blocked_midway")
		return

	global_position = next
	velocity = Vector3.ZERO
	if not _alignment.is_active():
		_finish_mantle()


func _finish_mantle() -> void:
	_mode = Mode.LOCOMOTION
	_grab_cooldown = 0.25
	velocity = Vector3.ZERO
	_restore_ground_settings()
	mantle_finished.emit()


func _capsule_blocked_at(feet: Vector3) -> bool:
	var space: PhysicsDirectSpaceState3D = _space()
	if space == null or _collision == null or _collision.shape == null:
		return false
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = _collision.shape
	query.transform = Transform3D(Basis.IDENTITY, feet + Vector3.UP * _collision.position.y)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	# Marge négative : frôler une surface pendant un franchissement est normal,
	# seule une pénétration franche doit annuler.
	query.margin = -0.05
	return not space.intersect_shape(query, 1).is_empty()


func _climb_tuning() -> ClimbTuning:
	if _climbing != null and _climbing.tuning != null:
		return _climbing.tuning
	return ClimbTuning.new()


## Mode courant, exposé pour les tests et le debug.
func mode() -> Mode:
	return _mode


func is_climbing() -> bool:
	return _mode == Mode.CLIMBING


func is_mantling() -> bool:
	return _mode == Mode.MANTLING


## Normale de paroi lissée, nulle hors escalade.
func wall_normal() -> Vector3:
	return _wall_normal


## Vitesse horizontale, exposée pour les tests et l'UI de debug.
func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## Exposé pour les tests, la jauge de §17.2 et la sauvegarde de §19.1.
func stamina() -> StaminaComponent:
	return _stamina
