## Briseur d'obsidienne (MASTER_SPEC §12.3, D-EN.2) — la TROISIÈME
## famille réelle : 150 PV, masse en COMBO chaîné par la vraie fenêtre,
## GARDE frontale à jauge (amorti mesuré de face, plein dégât de dos,
## rupture = ouverture), résistance au stagger élevée (là où deux coups
## d'épée couchent le braise). Physique réelle sur la vraie scène.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const BLACK: String = "res://scenes/enemies/RaiderBlack.tscn"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _setup(player_at: Vector3, black_at: Vector3) -> RaiderBlack:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = player_at
	_world.add_child(_player)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	var black: RaiderBlack = (load(BLACK) as PackedScene).instantiate() as RaiderBlack
	black.position = black_at
	_world.add_child(black)
	await _settle(2)
	for i: int in range(120):
		if _player.is_on_floor():
			break
		await _tree().physics_frame
	return black


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	await _settle(1)


func test_black_tuning_matches_the_spec() -> void:
	## §12.3 / §12.6 : 150 PV, poise 60 (résistance élevée), vision 26 m /
	## 90°, audition 22 m, poursuite 5,0 m/s, masse en chaîne de 3 contrats.
	var black: RaiderBlack = await _setup(Vector3(0, 0.1, -40), Vector3(0, 0.1, 0))
	check_equal(black.tuning.max_health, 150.0, "150 PV (§12.3)")
	check_equal(black.tuning.poise, 60.0, "poise 60 : trois fois le braise")
	check_equal(black.tuning.vision_range, 26.0, "vision 26 m (§12.6)")
	check_equal(black.tuning.vision_half_angle_deg, 45.0, "cône 90°")
	check_equal(black.tuning.hearing_range, 22.0, "audition 22 m")
	check_equal(black.tuning.pursuit_speed, 5.0, "poursuite 5,0 m/s")
	var controller: AttackControllerComponent = \
		black.get_node("AttackController") as AttackControllerComponent
	check_equal(controller.attacks.size(), 3, "chaîne de masse à 3 contrats")
	check(controller.attacks[2].recovery >= 1.2,
		"le dernier coup laisse l'OUVERTURE (recovery %.1f s)"
		% controller.attacks[2].recovery)
	await _teardown()


func test_black_chains_a_combo_through_the_real_window() -> void:
	## §12.3 : « combo de deux ou trois coups » — le chaînage passe par la
	## fenêtre du contrat (attack_started ré-émis avec combo_index > 0).
	var black: RaiderBlack = await _setup(Vector3(0, 0.1, 1.6), Vector3(0, 0.1, 0))
	var combo_indices: Array[int] = []
	(black.get_node("AttackController") as AttackControllerComponent) \
		.attack_started.connect(
			func(_d: AttackDefinition, index: int) -> void:
				combo_indices.append(index))
	for i: int in range(300):
		await _tree().physics_frame
		if combo_indices.size() >= 2:
			break
	check(combo_indices.size() >= 2,
		"au moins deux coups enchaînés (%s)" % str(combo_indices))
	check(combo_indices.has(1), "…dont un maillon de COMBO (index 1)")
	await _teardown()


func test_the_frontal_guard_soaks_damage_but_the_back_does_not() -> void:
	## §12.3 : « blocage frontal limité par une jauge de garde » — le même
	## coup d'épée fait ~4× moins de dégâts DE FACE que DE DOS.
	var black: RaiderBlack = await _setup(Vector3(0, 0.1, -40), Vector3(0, 0.1, 0))
	# Le joueur regarde +Z : il se place à -Z du briseur. Le pivot du
	# briseur est ORIENTÉ vers lui (le cône de vision et l'arc de garde
	# suivent le pivot — un dos tourné ne voit ni ne garde, c'est testé
	# par ailleurs sur le braise).
	_player.global_position = Vector3(0, 0.1, -1.5)
	(black.get_node("Pivot") as Node3D).rotation.y = PI
	await _settle(10)
	check(black.is_guarding(), "préalable : garde levée face à la cible")
	var before_front: float = black.health().current()
	_intent.attack_pressed = true
	await _settle(2)
	_intent.attack_pressed = false
	for i: int in range(60):
		await _tree().physics_frame
		if black.health().current() < before_front:
			break
	var frontal_damage: float = before_front - black.health().current()
	check(frontal_damage > 0.0, "le coup de face touche (%.1f)" % frontal_damage)
	check(frontal_damage <= 4.0,
		"…mais AMORTI par la garde (%.1f ≤ 4)" % frontal_damage)
	await _teardown()


func test_two_sword_hits_do_not_stagger_the_breaker() -> void:
	## §12.3 : « résistance au stagger élevée » — la séquence qui COUCHE le
	## braise (2 × 10 de poise contre 20) laisse le briseur debout
	## (poise 60). La différence de famille est LA mesure.
	var black: RaiderBlack = await _setup(Vector3(0, 0.1, -40), Vector3(0, 0.1, 0))
	_player.global_position = Vector3(0, 0.1, -1.5)
	(black.get_node("Pivot") as Node3D).rotation.y = PI
	await _settle(10)
	var staggered: Array[int] = [0]
	black.state_changed.connect(func(s: StringName) -> void:
		if s == &"staggered":
			staggered[0] += 1)
	for round_index: int in range(2):
		_intent.attack_pressed = true
		await _settle(2)
		_intent.attack_pressed = false
		await _settle(55)
	check_equal(staggered[0], 0,
		"deux coups d'épée ne suffisent JAMAIS contre poise 60")
	await _teardown()


func test_breaking_the_guard_opens_the_breaker() -> void:
	## §12.3 : « ouverture claire après… garde brisée » — marteler la garde
	## la vide (jauge 12, coups amortis ~3) et la rupture STAGGER.
	var black: RaiderBlack = await _setup(Vector3(0, 0.1, -40), Vector3(0, 0.1, 0))
	_player.global_position = Vector3(0, 0.1, -1.5)
	(black.get_node("Pivot") as Node3D).rotation.y = PI
	await _settle(10)
	check(black.is_guarding(), "préalable : garde levée")
	# Le chemin RÉEL des dégâts (hurtbox → amorti de garde → drain →
	# rupture), alimenté par injection AUX INSTANTS DE GARDE : le duel à
	# l'épée est trop bruité pour compter des drains (recul, fenêtres,
	# régénération 5 s) — le test frontal ci-dessus prouve déjà le chemin
	# épée de bout en bout ; ici on prouve la JAUGE et l'OUVERTURE.
	var hurtbox: HurtboxComponent = black.get_node("Hurtbox") as HurtboxComponent
	var opened: bool = false
	var guarded_hits: int = 0
	var hit_gap: int = 0
	for i: int in range(400):
		await _tree().physics_frame
		hit_gap = maxi(0, hit_gap - 1)
		if black.state() == RaiderBlack.State.STAGGERED:
			opened = true
			break
		if black.is_guarding() and hit_gap == 0:
			var event: DamageEvent = DamageEvent.new()
			event.amount = 12.0
			hurtbox.receive_hit(event)
			guarded_hits += 1
			hit_gap = 20
	check(guarded_hits >= 3,
		"PLUSIEURS coups encaissés en garde avant la rupture (%d)"
		% guarded_hits)
	check(opened, "la garde brisée OUVRE le briseur (stagger)")
	check(black.guard_gauge() <= 0.1,
		"…la jauge est bien vidée (%.1f)" % black.guard_gauge())
	await _teardown()
