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
## ÉTAT B.2 : marche, course, sprint **à l'endurance**, saut, gravité, coyote
## time, jump buffer. Escalade et mantle (§9.2, §9.3) suivent en B.3 ; ils
## consommeront le même `StaminaComponent`, sans le modifier.
class_name PlayerController
extends CharacterBody3D

## Émis au contact du sol, avec la vitesse verticale d'impact (négative).
## Les dégâts de chute (§8.2) s'y brancheront en B.2 sans modifier ce script.
signal landed(impact_speed: float)
signal left_ground()

@export var tuning: LocomotionTuning

@onready var _visual_root: Node3D = $VisualRoot
@onready var _camera_rig: CameraRig = $CameraRig
@onready var _input_reader: PlayerInputReader = $Components/PlayerInputReader
@onready var _stamina: StaminaComponent = $Components/StaminaComponent

## Intention courante. Remplacée par un test via `set_intent_source()`.
var _intent: InputIntent = null
var _use_reader: bool = true

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = true


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

	# Une seule décision de sprint par tick, prise ici et transmise ensuite. La
	# caméra, la vitesse et l'endurance doivent s'accorder sur la même réponse :
	# recalculer la condition à trois endroits les ferait diverger au moment précis
	# où la jauge se vide.
	var sprinting: bool = _resolve_sprint(delta, intent)

	# La caméra est mise à jour avant le déplacement : le repère utilisé pour
	# « avant » est celui que le joueur voit à cet instant.
	_camera_rig.apply_look(intent.look, delta)
	_camera_rig.update_fov(sprinting, delta)

	_update_timers(delta, intent)
	_apply_gravity(delta)
	_apply_horizontal_motion(delta, intent, sprinting)
	_try_jump()

	var was_on_floor: bool = is_on_floor()
	var vertical_before: float = velocity.y
	move_and_slide()
	_detect_ground_transitions(was_on_floor, vertical_before)

	_orient_visual(delta)

	# Après les demandes d'effort, jamais avant : c'est `update()` qui décide si le
	# tick a consommé ou s'il faut régénérer.
	if _stamina != null:
		_stamina.update(delta)

	if _use_reader and _input_reader != null:
		_input_reader.clear_edges()
	elif _intent != null:
		_intent.consume_edges()


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


## Vitesse horizontale, exposée pour les tests et l'UI de debug.
func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## Exposé pour les tests, la jauge de §17.2 et la sauvegarde de §19.1.
func stamina() -> StaminaComponent:
	return _stamina
