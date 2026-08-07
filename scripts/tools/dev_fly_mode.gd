## VOL LIBRE DE DÉVELOPPEMENT — explorer la carte sans la parcourir à pied.
##
## Outil de développement, pas une mécanique de jeu (MASTER_SPEC §6.1 : « un
## debug overlay désactivé dans le build final » ; P2 §10.8 : « outils debug
## activables uniquement en développement »). Il refuse donc de s'activer dans
## un build exporté, sauf `--allow-dev-fly` explicite.
##
## D-013 tenu : ce script ne consulte AUCUN périphérique. Il consomme la même
## `InputIntent` que le reste du jeu, produite par `PlayerInputReader`.
##
## Principe : le héros est GELÉ (il cède la conduite, cf. `set_frozen`) et une
## caméra libre prend la main. En sortant, le héros est reposé au sol sous la
## caméra si l'endroit est valide — c'est ce qui rend l'outil utile pour aller
## inspecter un point précis. Si l'endroit ne l'est pas, le héros reste
## exactement où il était : jamais de téléportation dans un mur.
class_name DevFlyMode
extends Node3D

signal fly_entered()
signal fly_exited(teleported: bool)

const BASE_SPEED: float = 18.0
const SPRINT_MULTIPLIER: float = 3.5
## Accélération douce : une caméra qui démarre au quart de tour donne des
## captures inexploitables.
const ACCEL: float = 9.0
const VERTICAL_SPEED: float = 12.0
## Portée du sondage de sol à la sortie.
const DROP_REACH: float = 200.0
## Hauteur libre exigée au-dessus du point de dépose (capsule du héros).
const CLEARANCE: float = 2.0

var _player: PlayerController = null
var _camera: Camera3D = null
var _active: bool = false
var _velocity: Vector3 = Vector3.ZERO
## Caméra rendue à la sortie — celle du héros, retrouvée à l'entrée.
var _previous_camera: Camera3D = null


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.name = "CameraVolLibre"
	_camera.current = false
	add_child(_camera)
	set_physics_process(true)


## Autorisé en éditeur et en debug ; refusé dans un build exporté, sauf drapeau
## explicite. Un joueur ne doit pas pouvoir sortir du monde par accident.
static func is_allowed() -> bool:
	if OS.has_feature("editor") or OS.is_debug_build():
		return true
	return OS.get_cmdline_args().has("--allow-dev-fly")


func bind(player: PlayerController) -> void:
	_player = player


func is_active() -> bool:
	return _active


func camera() -> Camera3D:
	return _camera


func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	# L'intention EFFECTIVE, jamais le lecteur brut : celui-ci est désactivé
	# dès qu'une intention est injectée (tests, scénarios), et le vol libre
	# deviendrait sourd sans que rien ne le dise.
	var intent: InputIntent = _player.current_intent()
	if intent.fly_toggle_pressed:
		intent.fly_toggle_pressed = false
		toggle()
	if _active:
		_fly(intent, _delta)
		# Le héros gelé ne vide plus les fronts : c'est au geleur de le faire,
		# sinon tous les ordres saisis en vol partiraient d'un coup au dégel.
		intent.consume_edges()


func toggle() -> void:
	if _active:
		exit()
	else:
		enter()


func enter() -> void:
	if _active or _player == null or not is_allowed():
		return
	_active = true
	_velocity = Vector3.ZERO
	var rig: CameraRig = _player.camera_rig()
	_previous_camera = rig.get_camera() if rig != null else null
	# On part exactement d'où le joueur regardait : aucun saut de cadrage.
	if _previous_camera != null:
		global_transform = _previous_camera.global_transform
	_camera.current = true
	_player.set_frozen(true)
	fly_entered.emit()


## Sortie du vol. Repose le héros sous la caméra si le sol est atteignable et
## la place libre ; sinon le laisse où il était et le dit par le signal.
func exit() -> void:
	if not _active:
		return
	_active = false
	_camera.current = false
	if _previous_camera != null and is_instance_valid(_previous_camera):
		_previous_camera.current = true
	var teleported: bool = _drop_player()
	_player.set_frozen(false)
	_previous_camera = null
	fly_exited.emit(teleported)


## Cherche un sol sous la caméra, puis vérifie que la capsule du héros y tient.
## Deux refus possibles, tous deux sûrs : pas de sol, ou place occupée.
func _drop_player() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var space: PhysicsDirectSpaceState3D = _player.get_world_3d().direct_space_state
	var from: Vector3 = global_position
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, from + Vector3.DOWN * DROP_REACH, 1, [_player.get_rid()])
	var hit: Dictionary = space.intersect_ray(ray)
	if hit.is_empty():
		return false
	var landing: Vector3 = (hit["position"] as Vector3) + Vector3.UP * 0.1
	var shape_node: CollisionShape3D = \
		_player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null or shape_node.shape == null:
		return false
	# La capsule doit TENIR à l'arrivée : sans ce contrôle, on déposerait le
	# héros dans la roche et il faudrait recharger une sauvegarde.
	var params: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	params.shape = shape_node.shape
	params.transform = Transform3D(Basis.IDENTITY,
		landing + Vector3.UP * CLEARANCE * 0.5)
	params.collision_mask = 1
	params.exclude = [_player.get_rid()]
	if not space.intersect_shape(params, 1).is_empty():
		return false
	_player.global_position = landing
	_player.velocity = Vector3.ZERO
	# Téléportation : l'interpolation physique doit repartir de zéro, sinon le
	# héros « glisse » depuis son ancienne position pendant une image (§20.9).
	_player.reset_physics_interpolation()
	return true


## Déplacement libre, repère caméra. Le regard réutilise les mêmes unités que
## le jeu : le stick est un axe converti en vitesse angulaire, la souris est
## déjà en radians (constat PT-D1-01 — ne jamais mélanger les deux).
func _fly(intent: InputIntent, delta: float) -> void:
	const LOOK_SPEED: float = 2.6
	var yaw: float = -intent.look_mouse.x - intent.look_analog.x * LOOK_SPEED * delta
	var pitch: float = -intent.look_mouse.y + intent.look_analog.y * LOOK_SPEED * delta
	rotation.y += yaw
	rotation.x = clampf(rotation.x + pitch, -1.5, 1.5)
	rotation.z = 0.0
	var basis_now: Basis = global_transform.basis
	var wanted: Vector3 = basis_now.z * -intent.move.y + basis_now.x * intent.move.x
	if intent.fly_up_held:
		wanted += Vector3.UP
	if intent.fly_down_held:
		wanted += Vector3.DOWN
	if wanted.length_squared() > 1.0:
		wanted = wanted.normalized()
	var speed: float = BASE_SPEED * (SPRINT_MULTIPLIER if intent.sprint_held else 1.0)
	var target: Vector3 = wanted * speed
	if intent.fly_up_held or intent.fly_down_held:
		target.y = wanted.y * VERTICAL_SPEED \
			* (SPRINT_MULTIPLIER if intent.sprint_held else 1.0)
	_velocity = _velocity.move_toward(target, ACCEL * speed * delta)
	global_position += _velocity * delta
