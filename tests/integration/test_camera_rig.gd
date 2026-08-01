## Caméra de jeu (MASTER_SPEC §8.3) — vérifiée par ses effets, pas par lecture du
## code.
##
## §8.3 impose une structure précise (pivots + `SpringArm3D` avec `Camera3D`
## **enfant direct**) et des enveloppes chiffrées. La structure n'est pas un
## détail de goût, et la raison exacte a été mesurée : un descendant plus profond
## que l'enfant direct conserve son décalage local, dont le cast du bras ne tient
## pas compte. Configuration éprouvée : caméra petite-fille décalée de 1 m sur
## l'axe du bras, retrouvée **0,64 m au-delà** de la face du mur — la traversée
## que §23.1 interdit.
##
## Ce qu'ils ne prouvent PAS : l'absence de jitter et le confort. §8.3 exige
## « zéro traversée/jitter » ; la traversée est testable ici, le jitter demande
## une observation en mouvement à framerate réel — il relève du Gate B manuel.
extends GateTestCase

const SANDBOX: String = "res://scenes/tests/TraversalSandbox.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"

const TICK: float = 1.0 / 60.0

var _world: Node = null
var _player: PlayerController = null
var _rig: CameraRig = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


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
	_rig = _player.get_node("CameraRig") as CameraRig

	await _settle(30)
	return _rig != null


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	_rig = null
	_intent = null


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


## Fait pivoter le lacet jusqu'à `target` radians. `apply_look` est la seule voie
## d'entrée du rig ; on ne triche pas en écrivant la rotation à la main, sinon le
## test ne prouverait rien du chemin réellement emprunté par le jeu.
func _turn_to_yaw(target: float) -> void:
	var delta_yaw: float = target - _rig.get_yaw()
	_rig.apply_look(Vector2(-delta_yaw / (_rig.tuning.camera_stick_speed * TICK), 0.0), TICK)


func test_camera_is_a_direct_child_of_the_spring_arm() -> void:
	## §8.3, contrainte structurelle. Un nœud intercalé casserait l'anti-traversée
	## sans qu'aucune autre erreur ne se manifeste.
	if not await _setup(Vector3(0, 1, 0)):
		_teardown()
		return
	var arm: SpringArm3D = _rig.get_spring_arm()
	var cam: Camera3D = _rig.get_camera()
	check_not_null(arm, "SpringArm3D")
	check_not_null(cam, "Camera3D")
	if arm != null and cam != null:
		check(cam.get_parent() == arm,
			"la Camera3D doit être enfant DIRECT du SpringArm3D (parent réel : %s)"
			% cam.get_parent().name)
	_teardown()


func test_camera_sits_behind_and_above_the_player() -> void:
	## Le repos du rig : caméra en arrière du personnage (+Z quand le lacet est nul)
	## et au-dessus de ses pieds, à la distance de §8.3.
	if not await _setup(Vector3(0, 1, 0)):
		_teardown()
		return
	var cam: Camera3D = _rig.get_camera()
	var offset: Vector3 = cam.global_position - _player.global_position
	check(offset.z > 3.5, "la caméra doit être derrière le héros (z = %.2f)" % offset.z)
	check(offset.y > 1.0, "la caméra doit surplomber les pieds (y = %.2f)" % offset.y)

	var planar: float = Vector2(offset.x, offset.z).length()
	check_approx(planar, _rig.tuning.camera_distance, 0.6,
		"distance horizontale caméra-héros")
	_teardown()


func test_shoulder_offset_survives_the_spring_arm() -> void:
	## Défaut réel constaté en B.1 : `SpringArm3D` réécrit **intégralement** la
	## position de ses enfants directs à chaque image. Une caméra placée en
	## x = 0,32 revenait donc en x = 0, et §8.3 (« épaule 0,25–0,40 m ») était
	## silencieusement perdu. Le décalage vit désormais sur le bras.
	if not await _setup(Vector3(0, 1, 0)):
		_teardown()
		return
	var cam: Camera3D = _rig.get_camera()
	var offset: Vector3 = cam.global_position - _player.global_position
	check_approx(absf(offset.x), _rig.tuning.camera_shoulder_offset, 0.05,
		"décalage d'épaule effectif")
	check(_rig.tuning.camera_shoulder_offset >= 0.25
		and _rig.tuning.camera_shoulder_offset <= 0.40,
		"épaule hors de l'enveloppe §8.3 (0,25–0,40 m) : %.2f"
		% _rig.tuning.camera_shoulder_offset)
	_teardown()


func test_pitch_is_clamped_to_the_specified_range() -> void:
	## §8.3 : pitch -65°/+45°. Sans butée, le joueur retourne la caméra et perd
	## tout repère — et le déplacement caméra-relatif s'inverse.
	if not await _setup(Vector3(0, 1, 0)):
		_teardown()
		return
	# Ordre volontairement démesuré, appliqué plusieurs fois.
	for i: int in range(10):
		_rig.apply_look(Vector2(0.0, 500.0), TICK)
	check(_rig.get_pitch() >= deg_to_rad(_rig.tuning.camera_pitch_min_deg) - 0.001,
		"butée basse franchie : %.1f°" % rad_to_deg(_rig.get_pitch()))

	for i: int in range(10):
		_rig.apply_look(Vector2(0.0, -500.0), TICK)
	check(_rig.get_pitch() <= deg_to_rad(_rig.tuning.camera_pitch_max_deg) + 0.001,
		"butée haute franchie : %.1f°" % rad_to_deg(_rig.get_pitch()))
	_teardown()


func test_spring_arm_pulls_the_camera_in_front_of_a_wall() -> void:
	## §23.1 : « la caméra ne traverse pas les murs ». On adosse le héros au mur du
	## bac à sable (x ∈ [29,75 ; 30,25]) et on tourne le regard pour que le bras
	## pointe dans le mur. Le bras doit se raccourcir et la caméra rester en deçà.
	if not await _setup(Vector3(28.5, 1, 0)):
		_teardown()
		return
	var arm: SpringArm3D = _rig.get_spring_arm()
	var cam: Camera3D = _rig.get_camera()

	# Sans obstacle, le bras est à pleine longueur : point de départ de la mesure.
	check_approx(arm.get_hit_length(), _rig.tuning.camera_distance, 0.05,
		"bras à pleine longueur avant l'obstacle")

	# Lacet +90° : le +Z local du bras pointe vers +X, donc vers le mur.
	_turn_to_yaw(PI / 2.0)
	await _settle(10)

	check(arm.get_hit_length() < _rig.tuning.camera_distance - 1.0,
		"le bras doit se raccourcir face au mur (%.2f m au lieu de %.2f)"
		% [arm.get_hit_length(), _rig.tuning.camera_distance])

	# Ne pas franchir la face ne suffit pas : mesuré avec un rayon simple, la
	# caméra s'arrêtait à 0,8 mm du mur — techniquement en deçà, visuellement
	# dedans. On exige un dégagement réel, celui de la sonde volumique.
	var clearance: float = 29.75 - cam.global_position.x
	check(clearance > _rig.tuning.camera_probe_radius * 0.5,
		"la caméra doit garder un dégagement devant le mur (%.3f m)" % clearance)
	check(cam.global_position.x > _player.global_position.x,
		"la caméra ne doit pas s'effondrer sur le héros (x = %.2f)" % cam.global_position.x)
	_teardown()


func test_fov_widens_on_sprint_without_snapping() -> void:
	## §8.3 : « aucun snap de FOV ». On vérifie les deux moitiés de l'exigence —
	## le FOV atteint bien la cible de sprint, et il ne l'atteint pas en une image.
	if not await _setup(Vector3(0, 1, 0)):
		_teardown()
		return
	var cam: Camera3D = _rig.get_camera()
	var rest: float = cam.fov
	check_approx(rest, _rig.tuning.camera_fov, 0.5, "FOV au repos")

	_rig.update_fov(true, TICK)
	var after_one: float = cam.fov
	check(after_one > rest, "le FOV doit commencer à s'élargir")
	check(after_one < rest + 0.5,
		"un seul tick ne doit pas suffire : progression de %.2f°" % (after_one - rest))

	for i: int in range(180):
		_rig.update_fov(true, TICK)
	check_approx(cam.fov, _rig.tuning.camera_fov_sprint, 0.5, "FOV de sprint atteint")

	for i: int in range(180):
		_rig.update_fov(false, TICK)
	check_approx(cam.fov, _rig.tuning.camera_fov, 0.5, "retour au FOV de repos")
	_teardown()


func test_fov_interpolation_is_framerate_independent() -> void:
	## §8.3 : « interpolation framerate-independent ». Une interpolation naïve
	## (`lerp(a, b, 0.1)`) convergerait deux fois plus vite à 120 Hz qu'à 60 Hz : la
	## caméra n'aurait pas le même comportement selon la machine. On compare la même
	## durée réelle découpée en pas de tailles différentes.
	if not await _setup(Vector3(0, 1, 0)):
		_teardown()
		return
	var cam: Camera3D = _rig.get_camera()
	var start: float = cam.fov

	for i: int in range(30):
		_rig.update_fov(true, TICK)
	var at_60: float = cam.fov

	cam.fov = start
	for i: int in range(60):
		_rig.update_fov(true, TICK / 2.0)
	var at_120: float = cam.fov

	check_approx(at_120, at_60, 0.05,
		"0,5 s de sprint doit donner le même FOV à 60 Hz (%.3f) et à 120 Hz (%.3f)"
		% [at_60, at_120])
	_teardown()


func test_look_is_framerate_independent() -> void:
	## Même exigence pour le regard : à durée égale, l'amplitude doit être égale.
	if not await _setup(Vector3(0, 1, 0)):
		_teardown()
		return
	for i: int in range(30):
		_rig.apply_look(Vector2(1.0, 0.0), TICK)
	var yaw_60: float = _rig.get_yaw()

	_teardown()
	if not await _setup(Vector3(0, 1, 0)):
		_teardown()
		return
	for i: int in range(60):
		_rig.apply_look(Vector2(1.0, 0.0), TICK / 2.0)
	var yaw_120: float = _rig.get_yaw()

	check_approx(yaw_120, yaw_60, 0.001,
		"lacet après 0,5 s : 60 Hz %.4f rad, 120 Hz %.4f rad" % [yaw_60, yaw_120])
	_teardown()


func test_tuning_stays_within_the_spec_envelopes() -> void:
	## §8.3 fixe des fourchettes, pas des valeurs uniques. Ce test empêche qu'un
	## réglage « juste pour voir » sorte de l'intention sans décision consignée.
	var tuning: LocomotionTuning = load("res://resources/tuning/locomotion_default.tres") as LocomotionTuning
	check_not_null(tuning, "locomotion_default.tres")
	if tuning == null:
		return
	check(tuning.camera_distance >= 4.0 and tuning.camera_distance <= 4.6,
		"distance caméra hors §8.3 (4,0–4,6 m) : %.2f" % tuning.camera_distance)
	check_approx(tuning.camera_target_height, 1.45, 0.05, "hauteur du point visé (§8.3)")
	check(tuning.camera_fov >= 68.0 and tuning.camera_fov <= 72.0,
		"FOV hors §8.3 (68–72°) : %.1f" % tuning.camera_fov)
	check(tuning.camera_fov_sprint >= 74.0 and tuning.camera_fov_sprint <= 77.0,
		"FOV de sprint hors §8.3 (74–77°) : %.1f" % tuning.camera_fov_sprint)
	check_approx(tuning.camera_pitch_min_deg, -65.0, 0.01, "butée basse (§8.3)")
	check_approx(tuning.camera_pitch_max_deg, 45.0, 0.01, "butée haute (§8.3)")
