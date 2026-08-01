## Locomotion du joueur (MASTER_SPEC §8.2) — mesurée, pas supposée.
##
## Ces tests pilotent le contrôleur par `InputIntent` injectée : **aucune touche
## n'est simulée**, aucun périphérique n'est requis. C'est le bénéfice direct de
## D-013 — la locomotion est vérifiable en headless, et le sera à l'identique
## quand la manette entrera en jeu.
##
## Ce qu'ils ne prouvent PAS : le ressenti. §10.6 exige des mesures de latence et
## un essai humain ; ils viendront avec le Gate B et n'ont pas d'équivalent
## automatique.
extends GateTestCase

const SANDBOX: String = "res://scenes/tests/TraversalSandbox.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"

## 60 ticks = 1 s à 60 Hz.
const TICK: float = 1.0 / 60.0

var _world: Node = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Monte le bac à sable et y place le joueur à `spawn`, puis laisse la physique
## le poser au sol.
func _setup(spawn: Vector3) -> bool:
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
	_player.global_position = spawn

	_intent = InputIntent.new()
	_player.set_intent_source(_intent)

	await _settle(30)
	return true


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	_intent = null


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func test_player_falls_and_rests_on_the_floor() -> void:
	if not await _setup(Vector3(0, 3, 0)):
		return
	await _settle(120)
	check(_player.is_on_floor(), "le joueur doit reposer sur le sol")
	check_approx(_player.global_position.y, 0.0, 0.1, "altitude au repos (pieds au sol)")
	check(absf(_player.velocity.y) < 0.5, "vitesse verticale au repos")
	_teardown()


func test_run_speed_matches_tuning() -> void:
	## Le clavier produit toujours une amplitude de 1.0 : il court.
	if not await _setup(Vector3(0, 1, 0)):
		return
	_intent.move = Vector2(1.0, 0.0)
	await _settle(90)
	check_approx(_player.horizontal_speed(), _player.tuning.run_speed, 0.3,
		"vitesse de course atteinte")
	_teardown()


func test_partial_stick_walks_instead_of_running() -> void:
	## Nuance que seule la manette apporte. Le contrôleur n'a aucune branche par
	## périphérique : c'est l'amplitude qui décide (D-013).
	if not await _setup(Vector3(0, 1, 0)):
		return
	_intent.move = Vector2(0.4, 0.0)
	await _settle(90)
	check_approx(_player.horizontal_speed(), _player.tuning.walk_speed, 0.3,
		"faible inclinaison -> marche")
	_teardown()


func test_sprint_is_faster_than_running() -> void:
	if not await _setup(Vector3(0, 1, 0)):
		return
	_intent.move = Vector2(1.0, 0.0)
	_intent.sprint_held = true
	await _settle(120)
	check_approx(_player.horizontal_speed(), _player.tuning.sprint_speed, 0.4,
		"vitesse de sprint atteinte")
	check(_player.tuning.sprint_speed > _player.tuning.run_speed,
		"le sprint doit dépasser la course")
	_teardown()


func test_release_decelerates_to_a_stop() -> void:
	## §10.6 : « relâcher le stick réduit rapidement la vitesse sans arrêt
	## robotique ». On vérifie l'arrêt ; le caractère non robotique est un ressenti.
	if not await _setup(Vector3(0, 1, 0)):
		return
	_intent.move = Vector2(1.0, 0.0)
	await _settle(90)
	check(_player.horizontal_speed() > 4.0, "le joueur doit d'abord se déplacer")

	_intent.move = Vector2.ZERO
	await _settle(45)
	check(_player.horizontal_speed() < 0.2,
		"vitesse résiduelle après relâchement : %.3f m/s" % _player.horizontal_speed())
	_teardown()


func test_movement_is_camera_relative() -> void:
	## §8.2 : « avant » désigne l'écran, pas l'axe -Z du monde. On fait pivoter la
	## caméra d'un quart de tour et la même intention doit produire un déplacement
	## dans une direction du monde différente.
	if not await _setup(Vector3(0, 1, 0)):
		return
	var rig: CameraRig = _player.get_node("CameraRig") as CameraRig
	check_not_null(rig, "CameraRig")
	if rig == null:
		_teardown()
		return

	_intent.move = Vector2(1.0, 0.0)
	await _settle(60)
	var start: Vector3 = _player.global_position
	await _settle(30)
	var dir_default: Vector3 = (_player.global_position - start).normalized()

	# Quart de tour de la caméra vers la gauche.
	rig.apply_look(Vector2(PI / 2.0 / (rig.tuning.camera_stick_speed * TICK), 0.0), TICK)
	await _settle(60)
	var start2: Vector3 = _player.global_position
	await _settle(30)
	var dir_rotated: Vector3 = (_player.global_position - start2).normalized()

	var angle: float = rad_to_deg(dir_default.angle_to(dir_rotated))
	check(angle > 60.0,
		"la direction doit suivre la caméra : écart mesuré %.1f° (attendu ~90°)" % angle)
	_teardown()


func test_jump_reaches_expected_apex() -> void:
	## §8.2 : 8,2 m/s sous 24 m/s² -> apex d'environ 1,40 m.
	if not await _setup(Vector3(0, 1, 0)):
		return
	var ground: float = _player.global_position.y
	_intent.jump_pressed = true

	var apex: float = ground
	for i: int in range(90):
		await _tree().physics_frame
		apex = maxf(apex, _player.global_position.y)
	var height: float = apex - ground
	check_approx(height, 1.4, 0.2, "hauteur de saut (m)")
	_teardown()


func test_coyote_time_allows_a_late_jump() -> void:
	## §8.2 : saut encore accepté 0,12 s après avoir quitté le sol.
	if not await _setup(Vector3(0, 1.0, 20)):
		return
	# Marcher hors de la marche pour quitter le sol sans sauter.
	_intent.move = Vector2(1.0, 0.0)
	var left_ground: bool = false
	for i: int in range(120):
		await _tree().physics_frame
		if not _player.is_on_floor():
			left_ground = true
			break
	check(left_ground, "le joueur doit avoir quitté le sol")
	if not left_ground:
		_teardown()
		return

	# Deux ticks après la perte de contact : dans la fenêtre de coyote.
	await _settle(2)
	_intent.move = Vector2.ZERO
	_intent.jump_pressed = true
	await _settle(2)
	check(_player.velocity.y > 3.0,
		"le saut doit être accepté pendant le coyote time (vy = %.2f)" % _player.velocity.y)
	_teardown()


func test_jump_buffer_survives_an_early_press() -> void:
	## §8.2 : saut demandé avant l'atterrissage, honoré à la reprise de contact.
	if not await _setup(Vector3(0, 1, 0)):
		return
	# Sauter une première fois pour être en l'air.
	_intent.jump_pressed = true
	await _settle(20)
	check(not _player.is_on_floor(), "le joueur doit être en l'air")

	# Demander le second saut pendant la descente, dans la fenêtre de buffer.
	var landed_once: bool = false
	for i: int in range(180):
		await _tree().physics_frame
		if not landed_once and _player.velocity.y < 0.0 and _player.global_position.y < 0.4:
			_intent.jump_pressed = true
			landed_once = true
		if landed_once and _player.velocity.y > 3.0:
			break
	check(landed_once, "la fenêtre de demande anticipée doit être atteinte")
	check(_player.velocity.y > 3.0,
		"le saut bufferisé doit partir à l'atterrissage (vy = %.2f)" % _player.velocity.y)
	_teardown()


func test_gentle_slope_is_climbable() -> void:
	## Pente à 40°, sous le seuil de 46° de §8.2. Le prisme monte de 4,20 m puis
	## débouche sur un plateau : après deux secondes le joueur doit s'y tenir.
	if not await _setup(Vector3(-20, 1.5, 4.5)):
		return
	await _settle(60)
	var start_y: float = _player.global_position.y
	# move.y = +1 signifie « avant », soit -Z avec la caméra au repos : c'est bien
	# la direction du pied de la rampe, situé à z = 3.
	_intent.move = Vector2(0.0, 1.0)
	await _settle(120)
	check(_player.global_position.y > start_y + 3.0,
		"une pente à 40° doit être gravie : Y %.2f -> %.2f" % [start_y, _player.global_position.y])
	check(_player.is_on_floor(),
		"le joueur doit se tenir sur le plateau, pas flotter ni retomber")
	_teardown()


func test_steep_slope_is_rejected() -> void:
	## Contre-épreuve du test précédent : sans elle, un contrôleur qui gravirait
	## n'importe quelle paroi passerait pour conforme. 60° dépasse le seuil de 46°
	## de §8.2 — la surface doit compter comme un mur, pas comme un sol.
	if not await _setup(Vector3(-30, 1.5, 4.5)):
		return
	await _settle(60)
	var start_y: float = _player.global_position.y
	_intent.move = Vector2(0.0, 1.0)
	await _settle(120)
	check(_player.global_position.y < start_y + 0.6,
		"une pente à 60° ne doit pas être gravie : Y %.2f -> %.2f"
		% [start_y, _player.global_position.y])
	check(_player.horizontal_speed() < 1.0,
		"le joueur doit être arrêté par la pente (%.2f m/s)" % _player.horizontal_speed())
	_teardown()


func test_body_never_rotates() -> void:
	## Le `CameraRig` est enfant du corps : si le corps tournait, la caméra
	## tournerait avec le personnage et deviendrait incontrôlable.
	if not await _setup(Vector3(0, 1, 0)):
		return
	_intent.move = Vector2(1.0, 1.0)
	await _settle(60)
	check_approx(_player.rotation.y, 0.0, 0.001, "lacet du corps")
	check_approx(_player.rotation.x, 0.0, 0.001, "tangage du corps")

	var visual: Node3D = _player.get_node("VisualRoot") as Node3D
	check_not_null(visual, "VisualRoot")
	if visual != null:
		check(absf(visual.rotation.y) > 0.01,
			"la représentation visuelle, elle, doit s'orienter vers le déplacement")
	_teardown()
