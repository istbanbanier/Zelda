## Esquive (MASTER_SPEC §10.2) — i-frames, coût, directions, dodge cancel.
##
## Les i-frames sont vérifiées par leur EFFET : une hitbox réelle frappe pendant
## la fenêtre et la santé ne bouge pas. Lire le drapeau d'invulnérabilité ne
## suffirait pas — c'est le refus du dégât qui compte.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const TICK: float = 1.0 / 60.0

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _setup() -> void:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(30, 1, 30)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = Vector3(0, 0.1, 0)
	_world.add_child(_player)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	# Leçon C1-2 : attendre l'ÉTAT atterri, jamais un nombre de ticks.
	await _settle(2)
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
	_intent = null


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func test_dodge_moves_in_the_stick_direction() -> void:
	## §10.2 « esquive quatre directions » : celle du stick, en repère caméra.
	await _setup()
	var start: Vector3 = _player.global_position
	_intent.move = Vector2(-1.0, 0.0)   # gauche caméra = -X monde au repos
	_intent.dodge_pressed = true
	await _settle(30)   # la durée (0,42 s) n'est pas finie, l'essentiel est fait
	var moved: Vector3 = _player.global_position - start
	check(moved.x < -1.0, "l'esquive doit partir vers la gauche (dx = %.2f)" % moved.x)
	check(absf(moved.z) < 0.5, "sans dérive avant/arrière (dz = %.2f)" % moved.z)
	_teardown()


func test_dodge_without_direction_rolls_backward() -> void:
	## Sans direction : une reculade — le dos du personnage. Au repos le
	## personnage regarde +Z, son dos est -Z.
	await _setup()
	var start: Vector3 = _player.global_position
	_intent.dodge_pressed = true
	await _settle(30)
	check(_player.global_position.z - start.z < -1.0,
		"la reculade doit partir dans le dos (dz = %.2f)" % (_player.global_position.z - start.z))
	_teardown()


func test_iframes_refuse_a_real_blow_then_expire() -> void:
	## La preuve par l'effet, dans les deux sens : un coup pendant la fenêtre ne
	## fait rien, le même coup après la fenêtre porte. La fenêtre (0,02 → 0,27)
	## est celle du `.tres`.
	await _setup()
	var hitbox: HitboxComponent = HitboxComponent.new()
	hitbox.team = &"enemies"
	# Sans ce masque, la hitbox ne voit pas la couche Hurtbox (32) du joueur et
	# la première assertion passerait POUR LA MAUVAISE RAISON — aucun coup ne
	# porterait jamais, i-frames ou pas (piège B3-1). Le contrôle inverse en fin
	# de test — le coup DOIT porter hors fenêtre — est ce qui l'a révélé.
	hitbox.collision_mask = 32
	var cs: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 4.0   # englobe le joueur pendant toute la roulade
	cs.shape = sphere
	hitbox.add_child(cs)
	hitbox.position = _player.global_position
	_world.add_child(hitbox)
	await _settle(3)

	var health: HealthComponent = _player.get_node("Components/HealthComponent")
	var before: float = health.current()

	# Coup pendant les i-frames : esquive lancée, frappe à ~0,1 s (fenêtre 0,02–0,27).
	_intent.dodge_pressed = true
	await _settle(6)
	hitbox.activate(10.0)
	await _settle(3)
	hitbox.deactivate()
	check_approx(health.current(), before, 0.001,
		"aucun dégât pendant la fenêtre d'invulnérabilité")

	# Fin de l'esquive (0,42 s) : le même coup doit porter. La roulade plus
	# l'élan résiduel déplacent le joueur de ~4,8 m — la hitbox est reposée sur
	# lui, sinon on mesurerait la distance parcourue, pas la fin des i-frames.
	await _settle(30)
	check(not _player.is_dodging(), "esquive finie")
	hitbox.global_position = _player.global_position
	await _settle(2)
	hitbox.activate(10.0)
	await _settle(3)
	hitbox.deactivate()
	check_approx(health.current(), before - 10.0, 0.001,
		"le même coup porte une fois la fenêtre fermée")
	_teardown()


func test_dodge_consumes_stamina_and_is_refused_when_broke() -> void:
	## §9.1 : 15 d'endurance — déclaré depuis B.2, consommé depuis C.2. À jauge
	## insuffisante, l'esquive ne part pas et le corps ne bouge pas.
	await _setup()
	var stamina: StaminaComponent = _player.stamina()
	var before: float = stamina.current()
	_intent.dodge_pressed = true
	await _settle(30)
	check_approx(before - stamina.current(), stamina.tuning.dodge_cost, 0.5,
		"coût d'endurance de l'esquive")
	await _settle(30)   # finir la roulade

	stamina.set_current(5.0)   # sous le coût de 15
	var start: Vector3 = _player.global_position
	_intent.dodge_pressed = true
	await _settle(20)
	check((_player.global_position - start).length() < 0.2,
		"à 5 d'endurance, l'esquive est refusée — le corps ne part pas")
	# La régénération (22/s après 1 s d'inaction) a pu repartir pendant l'attente :
	# on vérifie qu'aucun PRÉLÈVEMENT n'a eu lieu — la jauge n'est jamais passée
	# sous sa valeur posée — pas qu'elle est restée figée.
	check(stamina.current() >= 4.9,
		"rien n'est prélevé pour une esquive refusée (%.1f)" % stamina.current())
	_teardown()


func test_dodge_cancels_attack_recovery_but_not_startup() -> void:
	## §10.6 : la recovery est annulable par l'esquive, l'engagement (startup +
	## actif) ne l'est pas.
	await _setup()
	var attack: AttackControllerComponent = _player.attack_controller()

	# Pendant le startup (0,12 s) : l'esquive ne part pas, l'attaque continue.
	_intent.attack_pressed = true
	await _settle(4)   # ~0,07 s : startup
	check_equal(attack.phase(), AttackControllerComponent.Phase.STARTUP, "préalable : startup")
	_intent.dodge_pressed = true
	await _settle(2)
	check(_player.is_attacking(), "le startup n'est pas annulable")

	# Pendant la recovery : l'esquive interrompt.
	await _settle(10)   # atteint la recovery (startup 0,12 + actif 0,10)
	check_equal(attack.phase(), AttackControllerComponent.Phase.RECOVERY, "préalable : recovery")
	_intent.dodge_pressed = true
	await _settle(2)
	check(not _player.is_attacking(), "la recovery est annulée par l'esquive")
	check(_player.mode() == PlayerController.Mode.DODGING,
		"l'esquive a pris la main")
	_teardown()


func test_dodge_definition_matches_the_spec() -> void:
	## §10.2 épinglé : i-frames de 0,22–0,27 s de LONGUEUR, buffer 0,12 s.
	var def: DodgeDefinition = load("res://resources/combat/dodge_default.tres")
	check_not_null(def, "dodge_default.tres")
	if def == null:
		return
	check(def.iframes_length() >= 0.22 and def.iframes_length() <= 0.27,
		"longueur des i-frames hors §10.2 (0,22–0,27 s) : %.3f" % def.iframes_length())
	check_approx(def.input_buffer, 0.12, 0.001, "buffer d'esquive (§10.2)")
	check(def.iframes_end <= def.duration,
		"la fenêtre d'invulnérabilité doit se fermer avant la fin de l'esquive")
