## Coordinateur de combat (MASTER_SPEC §12.8, D-EN.3) — tokens réels sur
## de vrais pillards en physique : jamais plus de deux attaquants mêlée
## simultanés, le troisième ENCERCLE ; la mort d'un porteur LIBÈRE son
## token (garantie structurelle, aucune référence morte) ; le plafond
## §12.9 endort les IA les plus lointaines au-delà de 14.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const RAIDER: String = "res://scenes/enemies/RaiderRed.tscn"

var _world: Node3D = null
var _player: PlayerController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _setup(player_at: Vector3) -> CombatCoordinator:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = player_at
	_world.add_child(_player)
	_player.set_intent_source(InputIntent.new())
	var coordinator: CombatCoordinator = CombatCoordinator.new()
	_world.add_child(coordinator)
	await _settle(2)
	return coordinator


func _spawn_raider(at: Vector3) -> RaiderRed:
	var raider: RaiderRed = (load(RAIDER) as PackedScene).instantiate() as RaiderRed
	raider.position = at
	_world.add_child(raider)
	# Le cône de vision suit le pivot : chaque pillard REGARDE le joueur
	# au spawn — on teste la coordination, pas l'acquisition (couverte
	# par ailleurs).
	var to_player: Vector3 = _player.global_position - at
	(raider.get_node("Pivot") as Node3D).rotation.y = 		atan2(to_player.x, to_player.z)
	return raider


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	await _settle(1)


func test_never_more_than_two_simultaneous_melee_attackers() -> void:
	## §12.8/§10.5 : « maximum deux attaquants mêlée simultanés » — trois
	## pillards au contact, le compte d'états ATTACK simultanés reste ≤ 2,
	## et le tiers sans token BOUGE (encerclement, pas une statue).
	var coordinator: CombatCoordinator = await _setup(Vector3(0, 0.1, 0))
	var raiders: Array[RaiderRed] = []
	for at: Vector3 in [Vector3(1.4, 0.1, 0), Vector3(-1.4, 0.1, 0),
			Vector3(0, 0.1, 1.4)]:
		raiders.append(_spawn_raider(at))
	await _settle(10)
	var max_simultaneous: int = 0
	var third_moved: float = 0.0
	for i: int in range(360):
		await _tree().physics_frame
		var attacking: int = 0
		for raider: RaiderRed in raiders:
			if raider.state() == RaiderRed.State.ATTACK:
				attacking += 1
			elif raider.state() == RaiderRed.State.CHASE:
				third_moved += Vector2(raider.velocity.x, raider.velocity.z) \
					.length() * (1.0 / 60.0)
		max_simultaneous = maxi(max_simultaneous, attacking)
		if _player.health().is_dead():
			break
	check(max_simultaneous >= 1, "le combat a réellement eu lieu")
	check(max_simultaneous <= 2,
		"JAMAIS plus de deux attaquants simultanés (max %d)" % max_simultaneous)
	check(third_moved > 1.0,
		"les sans-token bougent (encerclement, %.1f m cumulés)" % third_moved)
	check(coordinator.melee_holder_count() <= 2, "la file reste bornée")
	await _teardown()


func test_a_dead_holder_frees_its_token() -> void:
	## §12.8 : « libération garantie du token en cas de mort » — tuer un
	## attaquant en plein élan ne bloque pas la file : un autre attaque.
	var coordinator: CombatCoordinator = await _setup(Vector3(0, 0.1, 0))
	var raiders: Array[RaiderRed] = []
	for at: Vector3 in [Vector3(1.4, 0.1, 0), Vector3(-1.4, 0.1, 0),
			Vector3(0, 0.1, 1.4)]:
		raiders.append(_spawn_raider(at))
	await _settle(10)
	# Attendre un porteur en pleine attaque, le tuer NET.
	var victim: RaiderRed = null
	for i: int in range(240):
		await _tree().physics_frame
		for raider: RaiderRed in raiders:
			if raider.state() == RaiderRed.State.ATTACK:
				victim = raider
				break
		if victim != null:
			break
	check(victim != null, "préalable : un porteur attaque")
	var event: DamageEvent = DamageEvent.new()
	event.amount = 999.0
	victim.health().take_damage(event)
	await _settle(20)
	check(not coordinator.token_holders().has(victim),
		"la purge a sorti LE MORT de la file")
	check(coordinator.melee_holder_count() <= 2, "la file reste bornée")
	# Les survivants continuent d'attaquer — la file n'est pas bloquée.
	var someone_attacked: bool = false
	for i: int in range(300):
		await _tree().physics_frame
		for raider: RaiderRed in raiders:
			if raider != victim and raider.state() == RaiderRed.State.ATTACK:
				someone_attacked = true
				break
		if someone_attacked or _player.health().is_dead():
			break
	check(someone_attacked, "un survivant reprend le token du mort")
	await _teardown()


func test_the_activity_cap_puts_the_farthest_to_sleep() -> void:
	## §12.9 : « limiter à 10-14 IA pleinement actives » — 16 vivantes,
	## les plus lointaines dorment (physique coupée), le compte actif ≤ 14.
	var coordinator: CombatCoordinator = await _setup(Vector3(0, 0.1, -60))
	var raiders: Array[RaiderRed] = []
	for i: int in range(16):
		raiders.append(_spawn_raider(Vector3(
			8.0 * float(i % 4) - 12.0, 0.1, 10.0 + 6.0 * float(i / 4))))
	await _settle(30)
	check(coordinator.active_enemy_count() <= 14,
		"au plus 14 IA actives (%d)" % coordinator.active_enemy_count())
	var sleeping: int = 0
	for raider: RaiderRed in raiders:
		if not raider.is_physics_processing():
			sleeping += 1
	check_equal(sleeping, 2, "les 2 excédentaires dorment")
	# …et ce sont bien les plus LOINTAINES du joueur qui dorment.
	var max_active_distance: float = 0.0
	var min_sleeping_distance: float = INF
	for raider: RaiderRed in raiders:
		var d: float = raider.global_position.distance_to(_player.global_position)
		if raider.is_physics_processing():
			max_active_distance = maxf(max_active_distance, d)
		else:
			min_sleeping_distance = minf(min_sleeping_distance, d)
	check(min_sleeping_distance >= max_active_distance - 0.1,
		"les dormeuses sont les plus lointaines (%.1f ≥ %.1f)"
		% [min_sleeping_distance, max_active_distance])
	await _teardown()


func test_a_capped_enemy_never_freezes_with_an_armed_hitbox() -> void:
	## §12.9 + §12.10 (revue Gate D) : le plafond ne doit JAMAIS geler une
	## IA en pleine attaque — sa fenêtre de frappe resterait armée à
	## jamais et son token confisqué. Reproduction exacte du défaut :
	## un attaquant au contact, quinze alliés lointains, puis le joueur
	## téléporté au milieu du paquet (l'attaquant devient le plus loin).
	var coordinator: CombatCoordinator = await _setup(Vector3(0, 0.1, 0))
	var attacker: RaiderRed = _spawn_raider(Vector3(0, 0.1, 1.3))
	var crowd: Array[RaiderRed] = []
	for i: int in range(15):
		crowd.append(_spawn_raider(Vector3(60.0 + float(i), 0.1, 60.0)))
	await _settle(10)
	var attacking: bool = false
	for i: int in range(240):
		await _tree().physics_frame
		if attacker.state() == RaiderRed.State.ATTACK:
			attacking = true
			break
	check(attacking, "préalable : l'attaquant est en pleine attaque")
	# Le joueur rejoint la foule : l'attaquant devient le plus lointain.
	_player.global_position = Vector3(67.0, 0.1, 60.0)
	await _settle(40)
	check(not attacker.is_physics_processing(),
		"le plafond a bien gelé le plus lointain")
	var hitbox: HitboxComponent = attacker.get_node("Pivot/ClubHitbox") \
		as HitboxComponent
	check(not hitbox.is_active(),
		"…mais sa fenêtre de frappe est FERMÉE (§12.10)")
	check(not coordinator.token_holders().has(attacker),
		"…et son token est RENDU à la file (§12.8)")
	await _teardown()
