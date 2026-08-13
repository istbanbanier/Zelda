## V2.1 — le VRAI joueur MARCHE la vallée : quatre routes, zéro téléportation.
##
## Même contrat que `test_physical_run.gd` (V1) : tout passe par `InputIntent`
## et le `PlayerController` — la même porte d'entrée qu'un clavier (D-013).
## CE QUE CE FICHIER S'INTERDIT : écrire `global_position` après le spawn,
## dégager un obstacle, ou « aider » le héros autrement qu'en poussant une
## direction. Deux mesures l'attestent à CHAQUE tick physique :
##   - le plus bas y relevé (jamais sous le monde) ;
##   - le plus grand déplacement en un tick (une téléportation ferait > 3 m).
##
## Quatre tests, un par route : le trajet principal (spawn → camp → gué est →
## pylône → steppe → rampe → porte) et les trois identités alternatives.
## La route de la rivière traverse le gué ouest — c'est la preuve physique du
## raccourci `shortcut.village_ford` ; le tablier du pont magnétique y porte
## le héros au-dessus du bras nord.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const BELOW_WORLD: float = -8.0
const DISCONTINUITY_M: float = 3.0
const ARRIVE_M: float = 3.0
const LEG_BUDGET_S: float = 40.0
## Jalons d'approche du camp depuis le spawn (début du trajet principal) —
## réutilisés par les routes qui partent du camp.
const TO_CAMP: Array[Vector2] = [
	Vector2(0, 170), Vector2(6, 150), Vector2(-6, 128), Vector2(10, 96),
	Vector2(30, 74), Vector2(45, 65),
]
## But final : le seuil de la porte du donjon (ancre §3.3 en 0, -210).
const GATE_GOAL: Vector2 = Vector2(0, -206)

## Détection d'enlisement (mêmes valeurs que le parcours V1).
const _STALL_TRIGGER_S: float = 1.2
const _SIDESTEP_S: float = 0.9
const _SIDESTEP_ANGLE: float = 1.15

var _world: Node3D = null
var _walk_report: String = ""
var _lowest_y: float = INF
var _frames_sampled: int = 0
var _max_jump: float = 0.0
var _jump_at: Vector3 = Vector3.ZERO


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Monte le monde et rend le joueur PILOTABLE, posé au sol. Le placement au
## spawn est fait par `WorldV2Root._ready()` — la seule écriture de position
## autorisée ; tout le reste est de la marche.
func _mount_and_pilot(intent: InputIntent) -> PlayerController:
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_world)
	await _tree().process_frame
	await _tree().physics_frame
	var player: PlayerController = _world.get_node("Player") as PlayerController
	if player == null:
		return null
	player.set_intent_source(intent)
	var grounded: float = 0.0
	while not player.is_on_floor() and grounded < 8.0:
		await _tree().physics_frame
		grounded += _tree().root.get_physics_process_delta_time()
	_lowest_y = player.global_position.y
	_frames_sampled = 0
	_max_jump = 0.0
	return player


func _camera_relative(player: PlayerController, world_dir: Vector3) -> Vector2:
	var yaw: Basis = player.camera_rig().get_yaw_basis()
	var forward: Vector3 = -yaw.z
	var right: Vector3 = yaw.x
	forward.y = 0.0
	right.y = 0.0
	var wish: Vector3 = world_dir
	wish.y = 0.0
	if wish.length_squared() < 0.000001:
		return Vector2.ZERO
	wish = wish.normalized()
	return Vector2(wish.dot(right.normalized()),
		wish.dot(forward.normalized())).normalized()


func _sample_safety(player: PlayerController, previous: Vector3) -> void:
	var here: Vector3 = player.global_position
	_lowest_y = minf(_lowest_y, here.y)
	_frames_sampled += 1
	var jump: float = previous.distance_to(here)
	if jump > _max_jump:
		_max_jump = jump
		_jump_at = here


## Pousse une direction jusqu'au but — jamais une position. Un pilote enlisé
## fait ce qu'un joueur fait : obliquer d'un côté puis de l'autre, en sautant.
func _walk_to(player: PlayerController, intent: InputIntent, goal: Vector2,
		arrive: float, budget_s: float, sprint: bool = true) -> bool:
	var elapsed: float = 0.0
	var progress: float = INF
	var stalled: float = 0.0
	var sidestep_left: float = 0.0
	var sidestep_sign: float = 1.0
	while elapsed <= budget_s:
		var step: float = _tree().root.get_physics_process_delta_time()
		var here: Vector2 = Vector2(player.global_position.x, player.global_position.z)
		var to_goal: Vector2 = goal - here
		var span: float = to_goal.length()
		if span <= arrive:
			_walk_report = ""
			return true
		if span < progress - 0.05:
			progress = span
			stalled = 0.0
		else:
			stalled += step
		var wish: Vector2 = to_goal.normalized()
		if sidestep_left > 0.0:
			sidestep_left -= step
			wish = wish.rotated(_SIDESTEP_ANGLE * sidestep_sign)
		elif stalled > _STALL_TRIGGER_S:
			sidestep_left = _SIDESTEP_S
			sidestep_sign = -sidestep_sign
			stalled = 0.0
			intent.jump_pressed = true
		intent.move = _camera_relative(player, Vector3(wish.x, 0.0, wish.y))
		intent.sprint_held = sprint
		var was: Vector3 = player.global_position
		await _tree().physics_frame
		_sample_safety(player, was)
		elapsed += step
	var stop: Vector3 = player.global_position
	_walk_report = "arrêté en (%.0f, %.1f, %.0f) à %.1f m du but, sol=%s" \
		% [stop.x, stop.y, stop.z, Vector2(stop.x, stop.z).distance_to(goal),
			str(player.is_on_floor())]
	return false


## Enchaîne les jalons d'une route et rend le nombre atteint.
func _walk_route(player: PlayerController, intent: InputIntent,
		goals: Array[Vector2]) -> int:
	var reached: int = 0
	for goal: Vector2 in goals:
		if not await _walk_to(player, intent, goal, ARRIVE_M, LEG_BUDGET_S):
			break
		reached += 1
	intent.move = Vector2.ZERO
	intent.sprint_held = false
	return reached


## Les jalons d'une route du layout, lus sur le NŒUD inspectable du monde.
func _route_goals(route_name: String, skip_first: int = 0) -> Array[Vector2]:
	var goals: Array[Vector2] = []
	for node: Node in _tree().get_nodes_in_group(&"world_v2_routes"):
		if String(node.name) != route_name:
			continue
		var waypoints: Array = node.get_meta(&"waypoints_xz", []) as Array
		for i: int in range(skip_first, waypoints.size()):
			goals.append(Vector2(float((waypoints[i] as Array)[0]),
				float((waypoints[i] as Array)[1])))
	return goals


## Les trois garanties communes de fin de parcours.
func _assert_run_integrity(player: PlayerController, label: String) -> void:
	check(_lowest_y > BELOW_WORLD,
		"%s : jamais sous le monde sur %d ticks (min y = %.2f)"
			% [label, _frames_sampled, _lowest_y])
	check(_max_jump < DISCONTINUITY_M,
		"%s : aucune discontinuité — plus grand saut %.2f m en un tick, en (%.0f, %.1f, %.0f)"
			% [label, _max_jump, _jump_at.x, _jump_at.y, _jump_at.z])
	check(not player.health().is_dead(),
		"%s : le héros arrive VIVANT (%.0f PV)" % [label, player.health().current()])


func _teardown() -> void:
	var clean: bool = await restore_root()
	check(clean, "démontage propre — %s" % restore_root_reason())
	restore_saves()


func test_le_trajet_principal_se_marche_du_spawn_a_la_porte() -> void:
	remember_saves()
	remember_root()
	var intent: InputIntent = InputIntent.new()
	var player: PlayerController = await _mount_and_pilot(intent)
	check_not_null(player, "le monde V2 porte le vrai joueur")
	if player == null:
		await _teardown()
		return
	var start: Vector3 = player.global_position

	var goals: Array[Vector2] = _route_goals("main_path")
	goals.append(GATE_GOAL)
	var reached: int = await _walk_route(player, intent, goals)
	check_equal(reached, goals.size(),
		"le trajet principal se marche en entier (%d/%d jalons%s)"
			% [reached, goals.size(),
				"" if _walk_report == "" else " — " + _walk_report])
	var travelled: float = Vector2(start.x, start.z).distance_to(
		Vector2(player.global_position.x, player.global_position.z))
	check(travelled > 300.0,
		"…%.0f m parcourus à pied depuis le spawn" % travelled)
	# Arrivé au SEUIL : l'ancre de la porte est là, à portée de main.
	check(Vector2(player.global_position.x, player.global_position.z)
		.distance_to(Vector2(0, -210)) < 8.0,
		"…et le héros se tient au seuil de la porte du donjon")
	_assert_run_integrity(player, "trajet principal")
	await _teardown()


func test_la_route_de_la_riviere_traverse_gues_et_pont() -> void:
	remember_saves()
	remember_root()
	var intent: InputIntent = InputIntent.new()
	var player: PlayerController = await _mount_and_pilot(intent)
	check_not_null(player, "le monde V2 porte le vrai joueur")
	if player == null:
		await _teardown()
		return

	var goals: Array[Vector2] = _route_goals("river_route")
	var reached: int = await _walk_route(player, intent, goals)
	check_equal(reached, goals.size(),
		"la route de la rivière se marche en entier (%d/%d jalons%s)"
			% [reached, goals.size(),
				"" if _walk_report == "" else " — " + _walk_report])
	_assert_run_integrity(player, "route de la rivière")
	await _teardown()


func test_la_route_des_hauteurs_grimpe_et_redescend_a_la_rampe() -> void:
	remember_saves()
	remember_root()
	var intent: InputIntent = InputIntent.new()
	var player: PlayerController = await _mount_and_pilot(intent)
	check_not_null(player, "le monde V2 porte le vrai joueur")
	if player == null:
		await _teardown()
		return

	# La route des hauteurs PART du camp : on y va d'abord à pied.
	var goals: Array[Vector2] = TO_CAMP.duplicate()
	goals.append_array(_route_goals("heights_route", 1))
	var reached: int = await _walk_route(player, intent, goals)
	check_equal(reached, goals.size(),
		"la route des hauteurs se marche en entier (%d/%d jalons%s)"
			% [reached, goals.size(),
				"" if _walk_report == "" else " — " + _walk_report])
	_assert_run_integrity(player, "route des hauteurs")
	await _teardown()


func test_la_route_des_ruines_rejoint_la_rampe_par_le_coeur() -> void:
	remember_saves()
	remember_root()
	var intent: InputIntent = InputIntent.new()
	var player: PlayerController = await _mount_and_pilot(intent)
	check_not_null(player, "le monde V2 porte le vrai joueur")
	if player == null:
		await _teardown()
		return

	var goals: Array[Vector2] = TO_CAMP.duplicate()
	goals.append_array(_route_goals("ruins_route", 1))
	var reached: int = await _walk_route(player, intent, goals)
	check_equal(reached, goals.size(),
		"la route des ruines se marche en entier (%d/%d jalons%s)"
			% [reached, goals.size(),
				"" if _walk_report == "" else " — " + _walk_report])
	_assert_run_integrity(player, "route des ruines")
	await _teardown()
