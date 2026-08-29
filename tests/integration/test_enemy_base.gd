## Socle ennemi D-EN.0 (MASTER_SPEC §12.7, §12.9, §12.1-§12.2) — les
## comportements NOUVEAUX du socle, mesurés sur le vrai pillard braise en
## physique réelle : mémoire de dernière position puis investigation et
## retour, territoire borné (aucune poursuite infinie), ouïe (bruit →
## suspicion → investigation), fuite à la mort d'un allié, alerte.
## Les tunings de test sont COURTS : on teste la mécanique, pas la montre.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const RAIDER: String = "res://scenes/enemies/RaiderRed.tscn"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _short_tuning() -> EnemyTuning:
	var tuning: EnemyTuning = EnemyTuning.new()
	tuning.id = &"raider_red"
	tuning.memory_duration = 0.4
	tuning.search_duration = 0.3
	tuning.max_pursuit_distance = 12.0
	tuning.flee_duration = 0.5
	return tuning


func _setup(player_at: Vector3, raider_at: Vector3,
		tuning: EnemyTuning = null) -> RaiderRed:
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
	var raider: RaiderRed = _spawn_raider(raider_at, tuning)
	await _settle(2)
	for i: int in range(120):
		if _player.is_on_floor():
			break
		await _tree().physics_frame
	return raider


func _spawn_raider(at: Vector3, tuning: EnemyTuning = null) -> RaiderRed:
	var raider: RaiderRed = (load(RAIDER) as PackedScene).instantiate() as RaiderRed
	if tuning != null:
		raider.tuning = tuning
	raider.position = at
	_world.add_child(raider)
	return raider


func _wall_at(position: Vector3, size: Vector3) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	wall.add_child(shape)
	wall.position = position
	_world.add_child(wall)


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	await _settle(1)


func test_a_lost_target_becomes_a_memory_then_a_search_then_home() -> void:
	## §12.7 : cible perdue de vue → mémoire courte → INVESTIGATE de la
	## dernière position → recherche → RETURN au territoire → IDLE.
	var raider: RaiderRed = await _setup(
		Vector3(0, 0.1, 6), Vector3(0, 0.1, 0), _short_tuning())
	await _settle(20)
	check_equal(raider.state(), RaiderRed.State.CHASE, "aggro initial")
	# Le joueur « disparaît » : téléporté LOIN derrière un mur épais, hors
	# du territoire — plus aucune ligne de vue possible.
	_wall_at(Vector3(0, 2, 40), Vector3(30, 4, 1))
	await _settle(2)
	_player.global_position = Vector3(0, 0.1, 55)
	var saw_investigate: bool = false
	var saw_return: bool = false
	for i: int in range(360):
		await _tree().physics_frame
		if raider.state() == RaiderRed.State.INVESTIGATE:
			saw_investigate = true
		if raider.state() == RaiderRed.State.RETURN:
			saw_return = true
		if raider.state() == RaiderRed.State.IDLE:
			break
	check(saw_investigate, "la mémoire expirée mène à l'INVESTIGATION")
	check(saw_return, "la recherche vide mène au RETOUR")
	check_equal(raider.state(), RaiderRed.State.IDLE,
		"…et le pillard finit CHEZ LUI, au repos")
	check(raider.global_position.distance_to(raider.territory_origin()) < 2.5,
		"à moins de 2,5 m de son origine (%.1f m)"
		% raider.global_position.distance_to(raider.territory_origin()))
	await _teardown()


func test_pursuit_is_bounded_by_the_territory() -> void:
	## §12.9 : aucune poursuite infinie — au-delà de la distance maximale,
	## l'ennemi abandonne et rentre, même si le joueur reste visible.
	var tuning: EnemyTuning = _short_tuning()
	tuning.max_pursuit_distance = 5.0
	# Le joueur commence DANS le territoire (4 m < 5 m) : l'aggro est
	# légitime — c'est la fuite du joueur qui franchira la frontière.
	var raider: RaiderRed = await _setup(
		Vector3(0, 0.1, 4), Vector3(0, 0.1, 0), tuning)
	await _settle(20)
	check_equal(raider.state(), RaiderRed.State.CHASE, "aggro initial")
	# Le joueur recule plus loin que la frontière : le pillard le suit,
	# franchit sa limite, et DOIT abandonner.
	_player.global_position = Vector3(0, 0.1, 20)
	var abandoned: bool = false
	for i: int in range(300):
		await _tree().physics_frame
		if raider.state() == RaiderRed.State.RETURN:
			abandoned = true
			break
	check(abandoned, "la frontière du territoire arrête la poursuite")
	# Et il ne ré-aggro PAS tant que le joueur reste hors territoire.
	for i: int in range(120):
		await _tree().physics_frame
	check(raider.state() != RaiderRed.State.CHASE,
		"aucune oscillation retour/poursuite à la frontière (%s)"
		% String(raider.state_name()))
	await _teardown()


func test_a_noise_makes_an_idle_enemy_suspicious_then_investigate() -> void:
	## §12.7 : un bruit dans l'audition rend SUSPICIEUX (pause orientée)
	## puis pousse à INVESTIGUER la position du bruit. Un bruit hors
	## d'audition ne fait rien.
	var raider: RaiderRed = await _setup(
		Vector3(0, 0.1, -30), Vector3(0, 0.1, 0), _short_tuning())
	await _settle(10)
	check_equal(raider.state(), RaiderRed.State.IDLE,
		"préalable : joueur derrière, hors du cône — repos")
	NoiseEvents.emit(_tree(), Vector3(6, 0, 4), 60.0, &"test")
	await _settle(2)
	check_equal(raider.state(), RaiderRed.State.SUSPICIOUS,
		"le bruit rend suspicieux")
	var investigated: bool = false
	for i: int in range(120):
		await _tree().physics_frame
		if raider.state() == RaiderRed.State.INVESTIGATE:
			investigated = true
			break
	check(investigated, "la suspicion mène à l'investigation")
	check(raider.last_known_position().distance_to(Vector3(6, 0, 4)) < 0.1,
		"…vers la position DU BRUIT")
	# Bruit hors d'audition (l'ouïe du braise : 15 m) : ignoré.
	var deaf_raider: RaiderRed = _spawn_raider(Vector3(40, 0.1, 0))
	await _settle(4)
	NoiseEvents.emit(_tree(), Vector3(90, 0, 0), 8.0, &"test")
	await _settle(2)
	check_equal(deaf_raider.state(), RaiderRed.State.IDLE,
		"un bruit hors d'audition ne distrait pas")
	await _teardown()


func test_the_red_raider_flees_when_an_ally_dies_nearby() -> void:
	## §12.1 : « peut fuir 2-4 s après la mort d'un allié » — la mort d'un
	## pillard fait détaler l'autre (dos au corps), puis il rentre.
	var raider: RaiderRed = await _setup(
		Vector3(0, 0.1, -30), Vector3(0, 0.1, 0), _short_tuning())
	var doomed: RaiderRed = _spawn_raider(Vector3(3, 0.1, 0))
	await _settle(6)
	var event: DamageEvent = DamageEvent.new()
	event.amount = 999.0
	doomed.health().take_damage(event)
	await _settle(3)
	check_equal(raider.state(), RaiderRed.State.FLEE,
		"la mort de l'allié déclenche la fuite")
	var start_gap: float = raider.global_position.distance_to(
		doomed.global_position)
	await _settle(20)
	check(raider.global_position.distance_to(doomed.global_position)
		> start_gap + 0.5, "…et il S'ÉLOIGNE réellement du corps")
	await _teardown()


func test_an_alerting_enemy_shares_its_target_with_nearby_allies() -> void:
	## §12.2 : l'alerte partage la cible acquise dans un rayon limité —
	## un allié endormi HORS de vue du joueur passe en chasse.
	var alert_tuning: EnemyTuning = _short_tuning()
	alert_tuning.alert_radius = 12.0
	# Le joueur démarre LOIN derrière : personne ne voit rien tant que
	# l'allié n'est pas en place — l'alerte doit avoir un receveur.
	var seer: RaiderRed = await _setup(
		Vector3(0, 0.1, -40), Vector3(0, 0.1, 0), alert_tuning)
	# ISS-083, 2026-08-29 — L'ALLIÉ A CHANGÉ DE PLACE, ET IL FAUT DIRE
	# POURQUOI. Il dormait en (-8, -4), soit 12,806 m du joueur pour un
	# `max_pursuit_distance` de 12,0. Sa cécité ne venait donc PAS de ses yeux :
	# il voit à 22 m et la cible était à 38,7° dans un demi-cône de 47,5°. Elle
	# venait de la garde de territoire — sur le seul chemin de la vision. Ce
	# test démontrait ainsi, sans le savoir, l'incohérence même d'ISS-083 : la
	# vision refusait, l'alerte acceptait.
	#
	# L'intention DÉCLARÉE de ce cas — « un allié endormi HORS de vue passe en
	# chasse » — est intacte. Ce qui change est la RAISON de sa cécité : le
	# cône, un fait de perception, au lieu d'une garde de poursuite. Les deux
	# préalables ci-dessous l'exigent désormais, pour que ce cas ne puisse plus
	# jamais être vert par accident.
	var sleeper: RaiderRed = _spawn_raider(Vector3(-8, 0.1, 2),
		_short_tuning())
	await _settle(6)
	check_equal(sleeper.state(), RaiderRed.State.IDLE,
		"préalable : l'allié dort")
	# Le joueur surgit DEVANT le guetteur (dans son cône +Z, hors de celui
	# de l'allié qui regarde aussi +Z depuis plus loin à l'ouest).
	_player.global_position = Vector3(0, 0.1, 6)

	# LE MOMENT COMPTE AUTANT QUE L'AXE, et c'est le second défaut que la
	# correction du premier a révélé. Mesuré APRÈS `_settle(20)`, l'écart au
	# cône valait 8,6° : l'allié était déjà en chasse et s'était TOURNÉ vers le
	# joueur — `_face()` travaille dans tous les états actifs. On mesurait donc
	# l'orientation qu'il a PARCE QU'il a été alerté, pour prouver qu'il ne
	# pouvait pas voir avant de l'être. La mesure se prend maintenant à
	# l'instant où le joueur apparaît, pivot encore à son lacet d'origine.
	var vers: Vector3 = _player.global_position - sleeper.global_position
	var angle: float = _cone_ecart_deg(sleeper, _player.global_position)
	check(angle >= 0.0, "préalable : le Pivot du garde est lisible")
	check(angle > sleeper.tuning.vision_half_angle_deg,
		"préalable : l'allié est AVEUGLE par son cône à l'instant où le joueur "
		+ "paraît (%.1f° > %.1f°) — c'est ce que « hors de vue » doit vouloir "
		% [angle, sleeper.tuning.vision_half_angle_deg] + "dire")
	check(vers.length() < sleeper.tuning.max_pursuit_distance,
		"préalable : la cible criée est DANS son territoire (%.2f m < %.1f) — "
		% [vers.length(), sleeper.tuning.max_pursuit_distance]
		+ "un allié ne peut plus en imposer une qui n'y est pas (ISS-083)")
	check_equal(sleeper.state(), RaiderRed.State.IDLE,
		"préalable : et il n'a rien vu de lui-même — sans cela, la chasse "
		+ "ci-dessous ne prouverait rien du cri")

	await _settle(20)

	check_equal(seer.state(), RaiderRed.State.CHASE, "le guetteur a vu")
	check_equal(sleeper.state(), RaiderRed.State.CHASE,
		"l'allié ALERTÉ chasse aussi — sans avoir rien vu")
	await _teardown()


## L'AXE QUE REGARDE VRAIMENT UN ENNEMI, LU OÙ LE CODE LE LIT.
##
## DÉFAUT MESURÉ, ET IL RENDAIT LE PRÉALABLE INCAPABLE DE ROUGIR. La première
## rédaction comparait à `Vector3.FORWARD`, c'est-à-dire **−Z**. Or
## `enemy_base.gd::_tick_perception` lit `_pivot.global_transform.basis.z`,
## c'est-à-dire **+Z**. Les deux angles sont supplémentaires : une cible en
## PLEIN CENTRE du cône (0° réel) mesurait 180° contre −Z et passait donc pour
## « hors du cône ». Le préalable était vrai par accident sur la géométrie
## choisie, et faux sur le seul cas qu'il existe pour exclure.
##
## On lit désormais `Pivot`, le nœud même que la perception interroge : le
## préalable ne peut plus diverger de la règle qu'il vérifie.
func _cone_ecart_deg(garde: Node3D, cible: Vector3) -> float:
	var pivot: Node3D = garde.get_node_or_null("Pivot") as Node3D
	if pivot == null:
		return -1.0
	var avant: Vector3 = pivot.global_transform.basis.z
	avant = Vector3(avant.x, 0.0, avant.z).normalized()
	var vers: Vector3 = cible - garde.global_position
	vers = Vector3(vers.x, 0.0, vers.z).normalized()
	return rad_to_deg(avant.angle_to(vers))
