## Latence d'entrée (MASTER_SPEC §10.6, §23.1) — mesurée en ticks, pas affirmée.
##
## §23.1 : « entrée mouvement visible au tick physique suivant et latence d'action
## instrumentée ». §10.6 : « action bufferisée valide part idéalement en un à deux
## ticks physiques après la première fenêtre légale ». Depuis le repos, la fenêtre
## est immédiatement légale : l'idéal est donc **un** tick, et c'est ce qui est
## exigé — une action lente doit être *intentionnellement* anticipée, pas tardive
## par architecture.
##
## Périmètre honnête : l'instrument pose l'intention entre deux ticks, à la place
## exacte où `PlayerInputReader` la poserait. Il mesure le pipeline intention →
## mouvement. La latence périphérique → intention et la latence d'affichage sont
## hors de portée headless, et §10.6 les exclut (« hors latence
## écran/périphérique »).
extends GateTestCase

const SANDBOX: String = "res://scenes/tests/TraversalSandbox.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"

## Assez d'essais pour attraper une latence intermittente ; assez peu pour que la
## suite reste rapide.
const TRIALS: int = 5

var _world: Node = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _setup() -> bool:
	var tree: SceneTree = _tree()
	if tree == null:
		check(false, "SceneTree indisponible")
		return false
	var world_scene: PackedScene = load(SANDBOX) as PackedScene
	var player_scene: PackedScene = load(PLAYER) as PackedScene
	if world_scene == null or player_scene == null:
		check(false, "scènes de test introuvables")
		return false
	_world = world_scene.instantiate()
	tree.root.add_child(_world)
	_player = player_scene.instantiate() as PlayerController
	_world.add_child(_player)
	_player.global_position = Vector3(0, 1, 0)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	return true


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	_intent = null


func test_movement_responds_at_the_next_physics_tick() -> void:
	## §23.1, au mot près. Cinq essais : le PIRE doit tenir en un tick, pas la
	## moyenne — une latence intermittente est une latence.
	if not _setup():
		return
	var report: LatencyInstrument.Report = await LatencyInstrument.measure_move(
		_tree(), _player, _intent, TRIALS)
	check(not report.timed_out, "aucun essai ne doit expirer")
	check_equal(report.trials, TRIALS, "nombre d'essais menés à terme")
	check(report.max_ticks <= 1,
		"le mouvement doit être visible au tick suivant — mesuré : %s" % report.summary())
	_teardown()


func test_jump_responds_at_the_next_physics_tick() -> void:
	## Depuis le repos au sol, la fenêtre de saut est immédiatement légale (§10.6) :
	## le buffer ne doit introduire aucun tick d'attente. Le contrôle négatif L2
	## vérifie que ce test sent une réorganisation qui coûterait un tick.
	if not _setup():
		return
	var report: LatencyInstrument.Report = await LatencyInstrument.measure_jump(
		_tree(), _player, _intent, TRIALS)
	check(not report.timed_out, "aucun essai ne doit expirer")
	check_equal(report.trials, TRIALS, "nombre d'essais menés à terme")
	check(report.max_ticks <= 1,
		"le saut au repos doit partir au tick suivant — mesuré : %s" % report.summary())
	_teardown()


func test_latency_is_stable_across_repeated_trials() -> void:
	## Une latence qui varie d'un essai à l'autre est un frame pacing d'entrée
	## cassé (§20.9) même si la moyenne est bonne : min et max doivent coïncider.
	if not _setup():
		return
	var report: LatencyInstrument.Report = await LatencyInstrument.measure_move(
		_tree(), _player, _intent, TRIALS)
	check(not report.timed_out, "aucun essai ne doit expirer")
	check_equal(report.min_ticks, report.max_ticks,
		"latence identique à chaque essai — mesuré : %s" % report.summary())
	_teardown()


func test_the_report_converts_ticks_at_the_real_tick_rate() -> void:
	## La conversion en millisecondes doit suivre le tick réellement configuré —
	## un « 16,7 ms » codé en dur mentirait dès que le tick change.
	var report: LatencyInstrument.Report = LatencyInstrument.Report.new()
	var expected: float = 1000.0 / float(Engine.physics_ticks_per_second)
	check_approx(report.ticks_to_ms(1.0), expected, 0.001,
		"1 tick converti au taux réel (%d Hz)" % Engine.physics_ticks_per_second)
	check_approx(report.ticks_to_ms(3.0), expected * 3.0, 0.001, "3 ticks")
