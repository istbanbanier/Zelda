## P2-1 — latence entrée→logique instrumentée (P2 §5.1/§7.2, §23.1).
##
## Ces tests passent par la VRAIE chaîne d'entrée : `Input.parse_input_event`
## → dispatch `_input` → `PlayerInputReader` (front) → `InputIntent` → tick
## physique du contrôleur. Aucun `set_intent_source` : injecter l'intention
## court-circuiterait précisément ce que l'on mesure.
##
## Le critère est en TICKS PHYSIQUES, jamais en millisecondes : les ms sous
## llvmpipe et en contention machine ne prouvent rien (R-017) ; le tick est
## l'unité logique du contrat §10.6.
extends GateTestCase

const COURSE: String = "res://scenes/tests/TraversalCourse.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"

var _world: Node = null
var _player: PlayerController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null


func _spawn() -> bool:
	var tree: SceneTree = _tree()
	if tree == null:
		return false
	var course_scene: PackedScene = load(COURSE) as PackedScene
	var player_scene: PackedScene = load(PLAYER) as PackedScene
	if course_scene == null or player_scene == null:
		return false
	_world = course_scene.instantiate()
	tree.root.add_child(_world)
	_player = player_scene.instantiate() as PlayerController
	_world.add_child(_player)
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	return true


func _press(action: StringName) -> void:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)


func _release(action: StringName) -> void:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)


func _probe() -> LatencyProbe:
	var reader: PlayerInputReader = _player.get_node("Components/PlayerInputReader") as PlayerInputReader
	return reader.probe


func test_a_grounded_jump_is_consumed_at_most_one_physics_tick_after_reception() -> void:
	var tree: SceneTree = _tree()
	if not _spawn():
		check(false, "mise en scène impossible")
		return
	for i: int in range(30):
		await tree.physics_frame
	check(_player.is_on_floor(), "préalable : le joueur est posé au sol")

	var left: Array[int] = [0]
	_player.left_ground.connect(func() -> void: left[0] += 1)
	_press(&"jump")
	for i: int in range(5):
		await tree.physics_frame
	_release(&"jump")

	check(left[0] >= 1, "le saut est réellement parti (le sol a été quitté)")
	var entry: Dictionary = _probe().last(&"jump")
	check(not entry.is_empty(), "la sonde a une mesure pour le saut")
	if not entry.is_empty():
		var ticks: int = int(entry["ticks"])
		check(ticks <= 1,
			"saut légal consommé au tick suivant au plus (mesuré : %d ticks)" % ticks)
	_teardown()


func test_a_light_attack_from_locomotion_is_consumed_within_one_tick() -> void:
	var tree: SceneTree = _tree()
	if not _spawn():
		check(false, "mise en scène impossible")
		return
	for i: int in range(30):
		await tree.physics_frame

	_press(&"attack_light")
	for i: int in range(5):
		await tree.physics_frame
	_release(&"attack_light")

	var entry: Dictionary = _probe().last(&"attack_light")
	check(not entry.is_empty(), "la sonde a une mesure pour l'attaque légère")
	if not entry.is_empty():
		var ticks: int = int(entry["ticks"])
		check(ticks <= 1,
			"attaque légale consommée au tick suivant au plus (mesuré : %d ticks)" % ticks)
	_teardown()
