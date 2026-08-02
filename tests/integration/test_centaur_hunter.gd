## Chasseur quadrupède (MASTER_SPEC §12.5, D-EN.5) — la CINQUIÈME
## famille : ~650 PV, silhouette centauroïde originale (corps bas
## allongé + torse haut), CRI avant toute attaque majeure, CHARGE en
## ligne figée (donc esquivable), SALVE d'arc à cadence plafonnée,
## repositionnement circulaire, et territoire dont la frontière ARRÊTE
## la poursuite. Physique réelle sur la vraie scène.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const HUNTER: String = "res://scenes/enemies/CentaurHunter.tscn"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _setup(player_at: Vector3, hunter_at: Vector3) -> CentaurHunter:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(240, 1, 240)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = player_at
	_world.add_child(_player)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	var hunter: CentaurHunter = (load(HUNTER) as PackedScene).instantiate() \
		as CentaurHunter
	hunter.position = hunter_at
	_world.add_child(hunter)
	var to_player: Vector3 = player_at - hunter_at
	(hunter.get_node("Pivot") as Node3D).rotation.y = atan2(to_player.x, to_player.z)
	await _settle(2)
	for i: int in range(120):
		if _player.is_on_floor():
			break
		await _tree().physics_frame
	return hunter


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	await _settle(1)


func test_hunter_tuning_and_silhouette_match_the_spec() -> void:
	## §12.5 / §12.6 : ~650 PV, vision 48 m / 130°, audition 38 m,
	## poursuite 10-13 m/s, et une silhouette CENTAUROÏDE réelle : corps
	## bas ALLONGÉ (plus long que large) surmonté d'un torse HAUT.
	var hunter: CentaurHunter = await _setup(Vector3(0, 0.1, -60), Vector3(0, 0.1, 0))
	check_equal(hunter.tuning.max_health, 650.0, "650 PV (§12.5)")
	check_equal(hunter.tuning.vision_range, 48.0, "vision 48 m (§12.6)")
	check_equal(hunter.tuning.vision_half_angle_deg, 65.0, "cône 130°")
	check_equal(hunter.tuning.hearing_range, 38.0, "audition 38 m")
	check(hunter.tuning.pursuit_speed >= 10.0
		and hunter.tuning.pursuit_speed <= 13.0,
		"poursuite 10-13 m/s (%.1f) — le plus rapide du bestiaire"
		% hunter.tuning.pursuit_speed)
	var lower: BoxMesh = (hunter.get_node("Pivot/BodyMesh") as MeshInstance3D) \
		.mesh as BoxMesh
	var torso: MeshInstance3D = hunter.get_node("Pivot/TorsoMesh") \
		as MeshInstance3D
	check(lower.size.z > lower.size.x * 1.5,
		"corps bas ALLONGÉ (%.1f de long pour %.1f de large) — quadrupède"
		% [lower.size.z, lower.size.x])
	check(torso.position.y > lower.size.y * 1.5,
		"torse HAUT au-dessus du corps (y = %.2f)" % torso.position.y)
	check(torso.position.z > 0.4, "…et porté vers l'AVANT (centauroïde)")
	await _teardown()


func test_the_hunter_roars_before_a_major_move() -> void:
	## §12.5 : « cri/posture avant attaque majeure » — le chasseur
	## s'IMMOBILISE et annonce avant de charger ou de tirer.
	var hunter: CentaurHunter = await _setup(Vector3(0, 0.1, 12.0), Vector3(0, 0.1, 0))
	var roared: bool = false
	var speed_while_roaring: float = -1.0
	for i: int in range(240):
		await _tree().physics_frame
		if hunter.is_roaring():
			roared = true
			speed_while_roaring = Vector2(hunter.velocity.x,
				hunter.velocity.z).length()
			break
	check(roared, "le chasseur ANNONCE avant sa manœuvre majeure")
	check(speed_while_roaring < 0.5,
		"…immobile pendant l'annonce (%.2f m/s)" % speed_while_roaring)
	await _teardown()


func test_the_charge_holds_its_line_and_can_be_sidestepped() -> void:
	## §12.5 : « charge rapide en ligne lisible » — la direction est FIGÉE
	## au départ : elle ne suit pas la proie qui se décale (donc esquivable).
	var hunter: CentaurHunter = await _setup(Vector3(0, 0.1, 12.0), Vector3(0, 0.1, 0))
	# Attendre le début de la charge elle-même.
	var charging: bool = false
	for i: int in range(300):
		await _tree().physics_frame
		if hunter.current_move() == CentaurHunter.Move.CHARGE:
			charging = true
			break
	check(charging, "la charge part après l'annonce")
	var start_position: Vector3 = hunter.global_position
	# La proie se décale FORTEMENT sur le côté pendant la charge : la
	# trajectoire RÉELLE (déplacements successifs) doit rester la ligne
	# de départ — c'est ce qui rend la charge esquivable. La référence se
	# prend sur le PREMIER déplacement mesuré : au tick de détection, la
	# vitesse est encore celle du cri (nulle).
	_player.global_position = Vector3(14.0, 0.1, 12.0)
	var previous: Vector3 = hunter.global_position
	var start_direction: Vector3 = Vector3.ZERO
	var worst_alignment: float = 1.0
	var travelled: float = 0.0
	for i: int in range(20):
		await _tree().physics_frame
		if hunter.current_move() != CentaurHunter.Move.CHARGE:
			break
		var step: Vector3 = hunter.global_position - previous
		step.y = 0.0
		previous = hunter.global_position
		if step.length() < 0.02:
			continue
		travelled += step.length()
		if start_direction == Vector3.ZERO:
			start_direction = step.normalized()
			continue
		worst_alignment = minf(worst_alignment,
			start_direction.dot(step.normalized()))
	check(travelled > 1.0,
		"la charge avance réellement (%.1f m)" % travelled)
	check(worst_alignment > 0.95,
		"…et GARDE sa ligne malgré le décalage de la proie (%.2f)"
		% worst_alignment)
	check(hunter.global_position.distance_to(start_position) > 1.0,
		"…loin de son point de départ")
	await _teardown()


func test_the_volley_is_capped_and_then_rests() -> void:
	## §12.5 : « salve d'arc avec cadence plafonnée » — trois flèches
	## exactement, puis un long repos ; jamais un tir continu.
	var hunter: CentaurHunter = await _setup(Vector3(0, 0.1, 20.0), Vector3(0, 0.1, 0))
	var volleying: bool = false
	for i: int in range(300):
		await _tree().physics_frame
		if hunter.current_move() == CentaurHunter.Move.VOLLEY:
			volleying = true
			break
	check(volleying, "la salve part")
	check_equal(hunter.arrows_left_in_volley(), CentaurHunter.VOLLEY_ARROWS,
		"la salve compte exactement trois flèches")
	# Attendre la fin de la salve : la cadence est ensuite BLOQUÉE.
	for i: int in range(240):
		await _tree().physics_frame
		if hunter.current_move() != CentaurHunter.Move.VOLLEY:
			break
	check(hunter.volley_cooldown_left() > 2.0,
		"un long repos suit la salve (%.1f s) — aucun tir continu"
		% hunter.volley_cooldown_left())
	await _teardown()


func test_the_hunter_abandons_at_its_territory_border() -> void:
	## §12.5 : « abandonne la poursuite à la frontière » — le duel est
	## FACULTATIF : fuir hors du territoire met fin au danger.
	var tuning: EnemyTuning = load(
		"res://resources/enemies/centaur_hunter_default.tres").duplicate() \
		as EnemyTuning
	tuning.max_pursuit_distance = 8.0
	tuning.memory_duration = 0.5
	var hunter: CentaurHunter = await _setup(Vector3(0, 0.1, 5.0), Vector3(0, 0.1, 0))
	hunter.tuning = tuning
	await _settle(20)
	check_equal(hunter.state(), CentaurHunter.State.CHASE, "préalable : chasse")
	# La proie fuit LOIN, hors du territoire.
	_player.global_position = Vector3(0, 0.1, 40.0)
	var abandoned: bool = false
	for i: int in range(420):
		await _tree().physics_frame
		if hunter.state() == CentaurHunter.State.RETURN:
			abandoned = true
			break
	check(abandoned, "le chasseur ABANDONNE à sa frontière (rencontre facultative)")
	check(hunter.global_position.distance_to(hunter.territory_origin()) <= 12.0,
		"…et il ne s'éloigne jamais de son territoire (%.1f m)"
		% hunter.global_position.distance_to(hunter.territory_origin()))
	await _teardown()


func test_the_charge_runs_at_its_declared_speed() -> void:
	## §10.6 : « les nombres d'une action sont éditables et inspectables ;
	## l'animation et les effets se calent sur le contrat, ils ne le
	## redéfinissent pas ». La revue du Gate D a mesuré 30 m/s pour 15
	## déclarés — `move_and_slide()` était appelé DEUX FOIS par tick.
	## Ce test mesure le déplacement RÉEL par tick physique.
	var hunter: CentaurHunter = await _setup(Vector3(0, 0.1, 14.0), Vector3(0, 0.1, 0))
	var charging: bool = false
	for i: int in range(300):
		await _tree().physics_frame
		if hunter.current_move() == CentaurHunter.Move.CHARGE:
			charging = true
			break
	check(charging, "préalable : la charge est partie")
	var previous: Vector3 = hunter.global_position
	var fastest: float = 0.0
	for i: int in range(15):
		await _tree().physics_frame
		if hunter.current_move() != CentaurHunter.Move.CHARGE:
			break
		var step: Vector3 = hunter.global_position - previous
		step.y = 0.0
		previous = hunter.global_position
		fastest = maxf(fastest, step.length() * 60.0)
	check(fastest > CentaurHunter.CHARGE_SPEED * 0.7,
		"la charge atteint sa vitesse déclarée (%.1f m/s pour %.1f)"
		% [fastest, CentaurHunter.CHARGE_SPEED])
	check(fastest <= CentaurHunter.CHARGE_SPEED * 1.15,
		"…et ne la DÉPASSE PAS (%.1f m/s ≤ %.1f) — aucun déplacement double"
		% [fastest, CentaurHunter.CHARGE_SPEED * 1.15])
	await _teardown()
