## Vallée de Néris — monde graybox (MASTER_SPEC §22 Phase D, D.0 par D-024).
##
## D.0 est une INTÉGRATION : le sol 512 × 512, le joueur, le combat existant, un
## camp avec pillards, un coffre et une arme au sol — dans une seule scène
## chargée depuis « Nouvelle partie ». Le relief, la rivière, le pylône, la
## citadelle et la composition North Star arrivent avec les jalons D suivants ;
## le navmesh (D-022) arrive avec le premier relief, un sol plat n'ayant rien à
## baker que le pilotage direct ne sache déjà traverser.
class_name ValleyWorld
extends Node3D

## Filet anti-hors-monde (§14.3, esprit) : le graybox n'a pas encore de bords —
## un joueur tombé du monde est replacé au spawn au lieu de chuter sans fin.
const FALL_LIMIT_Y: float = -20.0
const RESCUE_CHECK_INTERVAL: float = 1.0

@onready var _player: PlayerController = $Player
@onready var _spawn: Node3D = $SpawnPoint


func _ready() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 2)  # GameState.Flow.VALLEY
	# Cadence lente plutôt que _process : une comparaison par seconde suffit
	# largement à rattraper une chute (§5.4 : timers plutôt que polling).
	var timer: Timer = Timer.new()
	timer.wait_time = RESCUE_CHECK_INTERVAL
	timer.autostart = true
	timer.timeout.connect(_check_fall_rescue)
	add_child(timer)


func _check_fall_rescue() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.global_position.y < FALL_LIMIT_Y:
		_player.velocity = Vector3.ZERO
		_player.global_position = _spawn.global_position
		_player.reset_physics_interpolation()


func player() -> PlayerController:
	return _player
