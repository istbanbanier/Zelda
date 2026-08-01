## Souris, caméra, pause, sensibilité — régressions du playtest n° 1 (PT-D1-01).
##
## Le chemin testé est le VRAI : un `InputEventMouseMotion` poussé dans le
## viewport traverse `PlayerInputReader` (pixels × sensibilité → radians) puis
## `CameraRig.apply_look` (radians appliqués TELS QUELS). Le bug d'origine —
## re-multiplication par `camera_stick_speed * delta` — divisait la rotation
## par ~25 : ces tests rougissent si on le réintroduit.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const TICK: float = 1.0 / 60.0

var _world: Node3D = null
var _player: PlayerController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Monde plat, lecteur d'entrée ACTIF (pas d'intention injectée : on teste le
## vrai chemin périphérique → intention → caméra).
func _setup_with_reader() -> void:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	cs.shape = box
	floor_body.add_child(cs)
	_world.add_child(floor_body)
	floor_body.global_position = Vector3(0, -0.5, 0)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_world.add_child(_player)
	_player.global_position = Vector3(0, 0.1, 0)
	for i: int in range(120):
		if _player.is_on_floor():
			break
		await _tree().physics_frame
	check(_player.is_on_floor(), "préalable de setup : joueur atterri")


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _reader() -> PlayerInputReader:
	return _player.get_node("Components/PlayerInputReader") as PlayerInputReader


func _push_mouse(pixels: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.relative = pixels
	_tree().root.push_input(motion)


func test_mouse_pixels_become_radians_through_the_real_path() -> void:
	## 200 px × sensibilité = rotation attendue, mesurée sur le lacet du rig
	## après le VRAI trajet événement → lecteur → contrôleur → caméra.
	await _setup_with_reader()
	var reader: PlayerInputReader = _reader()
	reader.set_mouse_sensitivity(0.002)
	var rig: CameraRig = _player.get_node("CameraRig") as CameraRig
	var yaw_before: float = rig.get_yaw()

	_push_mouse(Vector2(200, 0))
	await _settle(2)

	var rotated: float = absf(wrapf(rig.get_yaw() - yaw_before, -PI, PI))
	check_approx(rotated, 200.0 * 0.002, 0.005,
		"200 px à 0,002 rad/px doivent tourner de 0,4 rad — obtenu %.4f" % rotated)
	check(rotated > 0.1,
		"régression PT-D1-01 : avec l'ancien double-échelonnage, on obtiendrait ~0,016 rad")
	_teardown()


func test_the_same_mouse_distance_rotates_the_same_at_any_frame_pacing() -> void:
	## La même distance physique de tapis produit la même rotation, qu'elle
	## arrive en un seul événement ou étalée sur huit ticks — le delta souris
	## n'est JAMAIS multiplié par le temps de frame.
	await _setup_with_reader()
	var reader: PlayerInputReader = _reader()
	reader.set_mouse_sensitivity(0.002)
	var rig: CameraRig = _player.get_node("CameraRig") as CameraRig

	var yaw_start: float = rig.get_yaw()
	_push_mouse(Vector2(400, 0))
	await _settle(2)
	var one_burst: float = absf(wrapf(rig.get_yaw() - yaw_start, -PI, PI))

	yaw_start = rig.get_yaw()
	for i: int in range(8):
		_push_mouse(Vector2(50, 0))
		await _settle(2)
	var spread: float = absf(wrapf(rig.get_yaw() - yaw_start, -PI, PI))

	check_approx(spread, one_burst, 0.01,
		"400 px d'un coup (%.3f rad) = 8 × 50 px (%.3f rad)" % [one_burst, spread])
	_teardown()


func test_the_yaw_turns_a_full_360_without_any_clamp() -> void:
	## Rotation horizontale libre : assez de pixels pour un tour complet exact —
	## la caméra revient à son orientation de départ, aucun mur de lacet.
	await _setup_with_reader()
	var reader: PlayerInputReader = _reader()
	reader.set_mouse_sensitivity(0.002)
	var rig: CameraRig = _player.get_node("CameraRig") as CameraRig
	var camera: Camera3D = rig.get_camera()
	var forward_before: Vector3 = -camera.global_transform.basis.z

	var pixels_for_full_turn: float = TAU / 0.002   # 3141,6 px
	for i: int in range(8):
		_push_mouse(Vector2(pixels_for_full_turn / 8.0, 0))
		await _settle(2)
	await _settle(2)

	var forward_after: Vector3 = -camera.global_transform.basis.z
	check(forward_before.dot(forward_after) > 0.999,
		"un tour complet ramène le regard au départ (dot = %.4f)"
		% forward_before.dot(forward_after))
	_teardown()


func test_the_stick_channel_still_scales_with_delta() -> void:
	## Le canal ANALOGIQUE reste une vitesse angulaire : même axe tenu, deux
	## deltas différents → rotations proportionnelles au temps. L'inverse du
	## canal souris — les deux contrats sont épinglés.
	await _setup_with_reader()
	var rig: CameraRig = _player.get_node("CameraRig") as CameraRig
	var yaw_before: float = rig.get_yaw()
	rig.apply_look(Vector2(1.0, 0.0), Vector2.ZERO, TICK)
	var full_tick: float = absf(wrapf(rig.get_yaw() - yaw_before, -PI, PI))
	yaw_before = rig.get_yaw()
	rig.apply_look(Vector2(1.0, 0.0), Vector2.ZERO, TICK * 0.5)
	var half_tick: float = absf(wrapf(rig.get_yaw() - yaw_before, -PI, PI))
	check_approx(half_tick, full_tick * 0.5, 0.0005,
		"un demi-delta tourne moitié moins (stick = vitesse × temps)")
	_teardown()


func test_pause_freezes_the_world_and_resume_restores_control() -> void:
	## PT-D1-11 : Échap suspend RÉELLEMENT le gameplay ; Reprendre rend
	## exactement le contrôle. Mesuré sur le mouvement du joueur, pas sur un
	## drapeau. La souris voulue passe VISIBLE en pause, CAPTURÉE en jeu
	## (l'état effectif se vérifie sur écran — headless refuse CAPTURED, mesuré).
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var player: PlayerController = valley.player()
	var intent: InputIntent = InputIntent.new()
	player.set_intent_source(intent)
	for i: int in range(120):
		if player.is_on_floor():
			break
		await _tree().physics_frame
	var shell: GameplayShell = valley.get_node("GameplayShell") as GameplayShell
	check_not_null(shell, "la coquille de gameplay est dans la vallée")
	check(shell.wants_mouse_captured(), "en jeu : souris voulue CAPTURÉE (PT-D1-02)")

	shell.toggle_pause()
	check(_tree().paused, "Échap suspend l'arbre")
	check(not shell.wants_mouse_captured(), "en pause : souris rendue au curseur")
	var frozen_at: Vector3 = player.global_position
	intent.move = Vector2(0, 1)
	await _settle(30)
	check((player.global_position - frozen_at).length() < 0.001,
		"le monde est RÉELLEMENT gelé : l'intention de mouvement n'a aucun effet")

	shell.toggle_pause()
	check(not _tree().paused, "Reprendre dépause")
	check(shell.wants_mouse_captured(), "…et veut recapturer la souris")
	await _settle(30)
	intent.move = Vector2.ZERO
	check((player.global_position - frozen_at).length() > 1.0,
		"le contrôle est restauré : le joueur bouge à nouveau")

	_tree().root.remove_child(valley)
	valley.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)


func test_sensitivity_setting_persists_and_reaches_the_reader() -> void:
	## PT-D1-11 : la valeur du curseur est bornée, sauvegardée dans user://, et
	## atteint réellement le lecteur d'entrée. Trois valeurs → trois rotations
	## mesurablement différentes.
	var saved: bool = UserSettings.save_mouse_sensitivity(0.003)
	check(saved, "écriture de user://settings.cfg")
	check_approx(UserSettings.load_mouse_sensitivity(), 0.003, 0.00001,
		"relecture après écriture")
	UserSettings.save_mouse_sensitivity(999.0)
	check_approx(UserSettings.load_mouse_sensitivity(),
		UserSettings.MAX_MOUSE_SENSITIVITY, 0.00001, "valeur folle bornée au max")

	await _setup_with_reader()
	var rig: CameraRig = _player.get_node("CameraRig") as CameraRig
	var reader: PlayerInputReader = _reader()
	var rotations: Array[float] = []
	for sensitivity: float in [0.0005, 0.0015, 0.004]:
		reader.set_mouse_sensitivity(sensitivity)
		var before: float = rig.get_yaw()
		_push_mouse(Vector2(100, 0))
		await _settle(2)
		rotations.append(absf(wrapf(rig.get_yaw() - before, -PI, PI)))
	check(rotations[0] < rotations[1] and rotations[1] < rotations[2],
		"basse < moyenne < haute : %.4f / %.4f / %.4f"
		% [rotations[0], rotations[1], rotations[2]])
	check(rotations[2] > rotations[0] * 5.0, "l'écart est mesurable, pas cosmétique")
	UserSettings.save_mouse_sensitivity(UserSettings.DEFAULT_MOUSE_SENSITIVITY)
	_teardown()


func test_a_corrupt_settings_file_falls_back_within_bounds() -> void:
	## QA-D1R-02 (revue contradictoire) : `settings.cfg` est éditable à la main.
	## Un tableau y produisait une erreur de constructeur puis 0,0 (souris morte,
	## SOUS le minimum) ; `nan` traversait `clampf` jusqu'au lecteur (caméra
	## gelée). Chaque valeur hostile doit retomber DANS les bornes — mesuré
	## jusqu'au lecteur d'entrée, pas seulement dans l'utilitaire.
	var config: ConfigFile = ConfigFile.new()
	for hostile: Variant in [[1, 2, 3], "vite", NAN, INF, -5.0, null]:
		config.set_value("input", "mouse_sensitivity", hostile)
		check_equal(config.save(UserSettings.PATH), OK,
			"préalable : fichier hostile écrit (%s)" % str(hostile))
		var loaded: float = UserSettings.load_mouse_sensitivity()
		check(is_finite(loaded)
			and loaded >= UserSettings.MIN_MOUSE_SENSITIVITY
			and loaded <= UserSettings.MAX_MOUSE_SENSITIVITY,
			"valeur hostile %s → %.5f, dans [%.4f, %.4f]" % [str(hostile), loaded,
				UserSettings.MIN_MOUSE_SENSITIVITY, UserSettings.MAX_MOUSE_SENSITIVITY])

	# Défense en profondeur : le LECTEUR aussi part borné, même si le fichier
	# est resté hostile au moment de son _ready.
	config.set_value("input", "mouse_sensitivity", NAN)
	config.save(UserSettings.PATH)
	await _setup_with_reader()
	var sensitivity: float = _reader().mouse_sensitivity
	check(is_finite(sensitivity)
		and sensitivity >= UserSettings.MIN_MOUSE_SENSITIVITY
		and sensitivity <= UserSettings.MAX_MOUSE_SENSITIVITY,
		"le lecteur démarre borné malgré un fichier nan (%.5f)" % sensitivity)
	UserSettings.save_mouse_sensitivity(UserSettings.DEFAULT_MOUSE_SENSITIVITY)
	_teardown()
