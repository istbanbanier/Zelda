## Vallée de Néris — monde graybox (MASTER_SPEC §22 Phase D, D.1 par D-024).
##
## D.1 : relief macro complet (voir `ValleyTerrain`), proxys du pylône et de la
## citadelle, soleil de fin d'après-midi (§7.7 : ouest/gauche, plongée 18–28°),
## ciel et brume aux couleurs ancres (§3.4), et la caméra de la vue d'ouverture
## `VistaCamera_Hero01` (§3.2) — constantes FIXES : une capture de référence doit
## être reproductible au millimètre (§21.8).
##
## `VALLEY_VISTA=1` dans l'environnement rend la VistaCamera active au chargement
## — c'est le chemin de `tools/godot/capture_reference.gd`, jamais celui du jeu.
class_name ValleyWorld
extends Node3D

## Filet anti-hors-monde (§14.3, esprit) : le graybox n'a pas encore de bords —
## un joueur tombé du monde est replacé au spawn au lieu de chuter sans fin.
const FALL_LIMIT_Y: float = -20.0
const RESCUE_CHECK_INTERVAL: float = 1.0

## §7.7 : soleil à l'ouest (rayons vers +X), plongée 22°.
const SUN_ROTATION_DEG: Vector3 = Vector3(-22.0, -90.0, 0.0)

## §3.2, ajusté SUR CAPTURE (les valeurs de la spec sont des points de départ) :
## à 4,2 m, une capsule de 1,8 m occupait 57 % du cadre — mesuré sur la première
## capture. Reculée à ~7,2 m et montée à 2,6 m au-dessus des pieds : héros à
## ~32 % de la hauteur, dans la bande 32–40 % de §3.2, légèrement à gauche
## (décalage caméra +0,8). FOV horizontal ≈ 68° (vertical 42° en 16:9).
const VISTA_POSITION: Vector3 = Vector3(0.8, 26.9, 177.4)
const VISTA_ROTATION_DEG: Vector3 = Vector3(-6.0, 0.0, 0.0)
const VISTA_FOV: float = 42.0

@onready var _player: PlayerController = $Player
@onready var _spawn: Node3D = $SpawnPoint
@onready var _sun: DirectionalLight3D = $Sun


func _ready() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 2)  # GameState.Flow.VALLEY

	_sun.rotation_degrees = SUN_ROTATION_DEG
	_setup_environment()
	_setup_vista_camera()

	# Cadence lente plutôt que _process : une comparaison par seconde suffit
	# largement à rattraper une chute (§5.4 : timers plutôt que polling).
	var timer: Timer = Timer.new()
	timer.wait_time = RESCUE_CHECK_INTERVAL
	timer.autostart = true
	timer.timeout.connect(_check_fall_rescue)
	add_child(timer)


## Ciel pastel, brume bleutée, lumière ambiante du ciel — les ancres de §3.4 en
## version graybox. Construit en code : une seule source de vérité chiffrée.
func _setup_environment() -> void:
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.663, 0.831, 0.918)      # #A9D4EA
	sky_material.sky_horizon_color = Color(0.686, 0.784, 0.827)  # #AFC8D3
	sky_material.ground_bottom_color = Color(0.365, 0.561, 0.239)
	sky_material.ground_horizon_color = Color(0.686, 0.784, 0.827)
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.6
	# Brume de distance (§7.7 fog classique) : l'étagement atmosphérique de §3.2,
	# sans fog volumétrique (hors budget graybox et hors Compatibility).
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.686, 0.784, 0.827)
	environment.fog_density = 0.0018
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "ValleyEnvironment"
	world_environment.environment = environment
	add_child(world_environment)


func _setup_vista_camera() -> void:
	var vista: Camera3D = Camera3D.new()
	vista.name = "VistaCamera_Hero01"
	vista.position = VISTA_POSITION
	vista.rotation_degrees = VISTA_ROTATION_DEG
	vista.fov = VISTA_FOV
	vista.current = false
	add_child(vista)
	if OS.get_environment("VALLEY_VISTA") == "1":
		# Après que la caméra du joueur s'est déclarée : le différé gagne.
		vista.make_current.call_deferred()


func _check_fall_rescue() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.global_position.y < FALL_LIMIT_Y:
		_player.velocity = Vector3.ZERO
		_player.global_position = _spawn.global_position
		_player.reset_physics_interpolation()


func player() -> PlayerController:
	return _player
