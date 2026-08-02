## Pilote visuel du joueur (ART-Q1) — traduit l'état GAMEPLAY du contrôleur
## en états d'animation du `CharacterVisual`, chaque tick physique.
##
## Sens unique strict : le contrôleur décide (mode, vitesses, fenêtres),
## ce pilote VISUALISE. Il n'écrit rien dans le gameplay — la capsule et
## les fenêtres de combat restent l'autorité (ordre ART-Q1, §7.18 : « le
## contrôleur détient l'autorité ; l'animation visualise »).
##
## En repli (modèle absent) : le pilote se désactive, le graybox garde tout.
class_name PlayerVisualDriver
extends Node

## Seuils de LECTURE visuelle — points médians entre les vitesses de §8.2
## (marche 3,5 / course 6,0 / sprint 9,0 m/s). Ce ne sont PAS des seuils
## de gameplay : ils choisissent un clip, rien d'autre.
const WALK_MAX_SPEED: float = 4.75
const RUN_MAX_SPEED: float = 7.5
const IDLE_MAX_SPEED: float = 0.35
## La réception se tient un court instant, sauf si la course reprend.
const LAND_HOLD_S: float = 0.30

@export var visual_path: NodePath = NodePath("../../VisualRoot/CharacterVisual")

var _player: PlayerController = null
var _visual: CharacterVisual = null
var _last_mode: int = -1
var _attack_restart: bool = false
var _land_until_ms: int = 0
var _was_airborne: bool = false


func _ready() -> void:
	_player = owner as PlayerController
	_visual = get_node_or_null(visual_path) as CharacterVisual
	if _player == null or _visual == null or _visual.is_fallback_active():
		set_physics_process(false)
		return
	# Le modèle riggé remplace le graybox — les mailles capsule/nez se
	# masquent, la CAPSULE DE COLLISION du contrôleur ne bouge pas.
	for graybox_name: String in ["BodyMesh", "NoseMesh"]:
		var mesh: MeshInstance3D = _player.get_node_or_null(
			"VisualRoot/" + graybox_name) as MeshInstance3D
		if mesh != null:
			mesh.visible = false
	var controller: AttackControllerComponent = _player.attack_controller()
	if controller != null:
		controller.attack_started.connect(_on_attack_started)


func _on_attack_started(_definition: AttackDefinition, _link: int) -> void:
	# Chaque maillon de combo RELANCE son clip — sans cela le deuxième coup
	# léger garderait la pose finie du premier.
	_attack_restart = true


func _physics_process(_delta: float) -> void:
	var mode: int = _player.mode()
	var entered: bool = mode != _last_mode
	_last_mode = mode
	match mode:
		PlayerController.Mode.DEAD:
			_visual.play_state(&"death")
		PlayerController.Mode.HURT:
			_visual.play_state(&"hurt", entered)
		PlayerController.Mode.DODGING:
			_visual.play_state(&"dodge", entered)
		PlayerController.Mode.ATTACKING:
			_play_attack()
		PlayerController.Mode.MANTLING:
			# Pas de clip de mantle dans les douze états : le départ de saut
			# est la lecture la plus proche (limite documentée, TEST_REPORT).
			_visual.play_state(&"jump", entered)
		PlayerController.Mode.CLIMBING:
			_visual.play_state(&"walk" if _player.velocity.length()
				> IDLE_MAX_SPEED else &"idle")
		_:
			_play_locomotion()


func _play_attack() -> void:
	var controller: AttackControllerComponent = _player.attack_controller()
	var heavy: bool = controller != null \
		and controller.current_attack() == controller.heavy_attack
	_visual.play_state(&"attack_heavy" if heavy else &"attack_light",
		_attack_restart)
	_attack_restart = false


func _play_locomotion() -> void:
	var now: int = Time.get_ticks_msec()
	if not _player.is_on_floor():
		_was_airborne = true
		_visual.play_state(&"jump" if _player.velocity.y > 0.5 else &"fall")
		return
	var speed: float = _player.horizontal_speed()
	if _was_airborne:
		_was_airborne = false
		_land_until_ms = now + int(LAND_HOLD_S * 1000.0)
		_visual.play_state(&"land", true)
		return
	# La réception tient LAND_HOLD_S, mais la course reprend sans figer.
	if now < _land_until_ms and speed <= WALK_MAX_SPEED:
		return
	if speed <= IDLE_MAX_SPEED:
		_visual.play_state(&"idle")
	elif speed <= WALK_MAX_SPEED:
		_visual.play_state(&"walk")
	elif speed <= RUN_MAX_SPEED:
		_visual.play_state(&"run")
	else:
		_visual.play_state(&"sprint")
