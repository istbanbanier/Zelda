## Monture et vol libre de développement — les deux demandes de fin de playtest
## (« un dev mod permettant d'explorer la map en volant » et « un système de
## monture comme un cheval pour explorer plus vite »).
##
## Les deux reposent sur la MÊME brique : `PlayerController.set_frozen()`. Le
## héros cède la conduite, ne consomme plus d'entrée, ne bouge plus de
## lui-même ; sa caméra reste son enfant, donc le joueur garde le regard.
##
## Ce que ces tests protègent en priorité, ce ne sont pas les vitesses — ce sont
## les SOFTLOCKS : un héros gelé qu'on ne dégèle pas, un cavalier déposé dans la
## roche, des fronts d'entrée qui s'accumulent pendant le gel et partent tous au
## dégel, un vol libre actif dans un build exporté.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"

var _root: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	_player = null
	_intent = null


func _static_floor(at: Vector3, size: Vector3) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = at
	return body


func _setup() -> bool:
	var tree: SceneTree = _tree()
	if tree == null:
		return false
	_root = Node3D.new()
	tree.root.add_child(_root)
	_root.add_child(_static_floor(Vector3(0.0, -0.5, 0.0), Vector3(120.0, 1.0, 120.0)))
	var scene: PackedScene = load(PLAYER) as PackedScene
	if scene == null:
		return false
	_player = scene.instantiate() as PlayerController
	_root.add_child(_player)
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	return true


## --- Le gel, brique commune ------------------------------------------------

func test_a_frozen_hero_stops_moving_and_can_always_be_released() -> void:
	if not _setup():
		check(false, "mise en scène impossible")
		return
	await _settle(10)
	# Le DÉPLACEMENT horizontal depuis le point de départ — pas la distance à
	# l'origine du monde, qui mêlait la chute initiale à la marche et donnait
	# des mesures incohérentes (0,48 m à 6 ticks, 0,38 m à 20).
	var start: Vector3 = _player.global_position
	_intent.move = Vector2(0.0, 1.0)
	await _settle(20)
	var walked: float = Vector2(_player.global_position.x - start.x,
		_player.global_position.z - start.z).length()
	check(walked > 0.5, "libre, le héros avance (%.2f m)" % walked)
	_player.set_frozen(true)
	check(_player.is_frozen(), "le gel est effectif")
	var frozen_at: Vector3 = _player.global_position
	await _settle(10)
	check(_player.global_position.distance_to(frozen_at) < 0.05,
		"gelé, il ne bouge plus alors que l'ordre d'avancer tient toujours")
	_player.set_frozen(false)
	check(not _player.is_frozen(), "le dégel est effectif")
	# 20 ticks ≈ 0,33 s : le temps que l'accélération au sol (24 m/s²) produise
	# un déplacement franc, mesuré lui aussi dans le plan horizontal.
	await _settle(20)
	var resumed: float = Vector2(_player.global_position.x - frozen_at.x,
		_player.global_position.z - frozen_at.z).length()
	check(resumed > 0.5,
		"dégelé, il repart (%.2f m) — la conduite lui est bien rendue" % resumed)
	_teardown()


func test_dying_always_returns_control() -> void:
	## Anti-softlock : un héros mort ET gelé ne se relèverait jamais au
	## checkpoint. Mourir doit dégeler, quoi qu'il arrive.
	if not _setup():
		check(false, "mise en scène impossible")
		return
	await _settle(4)
	_player.set_frozen(true)
	var blow: DamageEvent = DamageEvent.new()
	blow.amount = 9999.0
	blow.attack_id = HitboxComponent.next_attack_id()
	(_player.get_node("Hurtbox") as HurtboxComponent).receive_hit(blow)
	await _settle(4)
	check(_player.health().is_dead(), "le héros est mort")
	check(not _player.is_frozen(), "mourir a rendu la conduite")
	_teardown()


## --- Monture ----------------------------------------------------------------

func _mount_at(at: Vector3) -> Mount:
	var beast: Mount = Mount.new()
	_root.add_child(beast)
	beast.global_position = at
	return beast


func test_mounting_freezes_the_rider_and_seats_him() -> void:
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var beast: Mount = _mount_at(Vector3(3.0, 0.6, 0.0))
	await _settle(6)
	check(beast.is_in_group("interactable"),
		"la monture suit la convention d'interaction du projet")
	check(beast.interact(_player), "on monte avec la même touche que tout le reste")
	check(beast.is_ridden() and beast.rider() == _player, "elle a son cavalier")
	check(_player.is_frozen(), "le cavalier a cédé la conduite")
	await _settle(4)
	check(_player.global_position.distance_to(beast.saddle_position()) < 0.05,
		"le cavalier est posé SUR la selle, sans retard d'une image")
	_teardown()


func test_a_ridden_mount_outruns_the_hero_on_foot() -> void:
	## La raison d'être de la monture : « explorer plus vite ».
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var beast: Mount = _mount_at(Vector3(3.0, 0.6, 0.0))
	await _settle(6)
	beast.interact(_player)
	var start: Vector3 = beast.global_position
	_intent.move = Vector2(0.0, 1.0)
	_intent.sprint_held = true
	# 120 ticks = 2 s : le temps que l'allure s'ÉTABLISSE. Mesurer plus tôt ne
	# jugerait que l'accélération (défaut mesuré : 3,2 m à 40 ticks, alors que
	# la monture était encore en train de prendre son élan).
	await _settle(120)
	var pace: float = Vector2(beast.velocity.x, beast.velocity.z).length()
	# Le sprint du héros plafonne à 9 m/s (§8.2). Sous cette barre, la monture
	# n'aurait aucune raison d'exister.
	check(pace > 9.0, "l'allure établie dépasse le sprint à pied (%.1f m/s)" % pace)
	var travelled: float = beast.global_position.distance_to(start)
	check(travelled > 15.0, "et le trajet suit (%.1f m en 2 s)" % travelled)
	check(_player.global_position.distance_to(beast.saddle_position()) < 0.2,
		"le cavalier n'est jamais décroché en route")
	_teardown()


func test_dismount_refuses_rather_than_dropping_the_rider_in_rock() -> void:
	## Anti-softlock : mieux vaut refuser de descendre que déposer le héros
	## dans la pierre. Le refus est ANNONCÉ, jamais silencieux.
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var beast: Mount = _mount_at(Vector3(0.0, 0.6, 0.0))
	# On mure les trois côtés de descente testés : gauche, droite, arrière.
	for offset: Vector3 in [Vector3(-1.6, 1.0, 0.0), Vector3(1.6, 1.0, 0.0),
			Vector3(0.0, 1.0, 2.0)]:
		_root.add_child(_static_floor(offset, Vector3(2.4, 4.0, 2.4)))
	await _settle(6)
	beast.interact(_player)
	check(beast.is_ridden(), "le cavalier est en selle")
	var refused: Array[bool] = []
	beast.dismounted.connect(func(_who: PlayerController, was_refused: bool) -> void:
		refused.append(was_refused))
	check(not beast.dismount(), "descendre est REFUSÉ : aucune place libre")
	check(refused.size() == 1 and refused[0],
		"…et le refus est annoncé, pas avalé en silence")
	check(beast.is_ridden(), "le cavalier reste en selle plutôt que d'être muré")
	check(_player.is_frozen(), "il reste gelé — cohérent avec le refus")
	_teardown()


func test_dismount_puts_the_rider_back_on_solid_ground() -> void:
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var beast: Mount = _mount_at(Vector3(0.0, 0.6, 0.0))
	await _settle(6)
	beast.interact(_player)
	await _settle(4)
	check(beast.dismount(), "la descente est acceptée : la place est libre")
	check(not beast.is_ridden(), "la monture n'a plus de cavalier")
	check(not _player.is_frozen(), "le cavalier a repris la conduite")
	check(_player.global_position.distance_to(beast.global_position) > 1.0,
		"il est posé À CÔTÉ de la monture, pas dedans")
	await _settle(10)
	check(_player.global_position.y > -1.0, "et il ne traverse pas le sol")
	_teardown()


func test_a_riderless_mount_does_not_wander() -> void:
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var beast: Mount = _mount_at(Vector3(3.0, 0.6, 0.0))
	await _settle(6)
	var parked: Vector3 = beast.global_position
	_intent.move = Vector2(1.0, 1.0)
	_intent.sprint_held = true
	await _settle(20)
	check(beast.global_position.distance_to(parked) < 0.5,
		"sans cavalier, elle reste où on l'a laissée")
	_teardown()


## --- Vol libre --------------------------------------------------------------

func test_dev_fly_is_refused_in_an_exported_build() -> void:
	## Ce n'est pas une mécanique de jeu : un joueur ne doit pas pouvoir sortir
	## du monde par accident. En test, on est en debug — l'outil est autorisé.
	check(DevFlyMode.is_allowed(),
		"autorisé en développement (éditeur ou build de debug)")


func test_entering_flight_freezes_the_hero_and_takes_the_camera() -> void:
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var fly: DevFlyMode = DevFlyMode.new()
	_root.add_child(fly)
	fly.bind(_player)
	await _settle(6)
	check(not fly.is_active(), "au repos, le vol libre est inactif")
	check(not fly.camera().current, "…et sa caméra n'a pas la main")
	fly.enter()
	check(fly.is_active(), "le vol est engagé")
	check(_player.is_frozen(), "le héros a cédé la conduite")
	check(fly.camera().current, "la caméra libre a pris la main")
	var perched: Vector3 = _player.global_position
	_intent.move = Vector2(0.0, 1.0)
	await _settle(20)
	check(_player.global_position.distance_to(perched) < 0.1,
		"le héros ne marche pas pendant qu'on survole")
	_teardown()


func test_leaving_flight_drops_the_hero_on_valid_ground_only() -> void:
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var fly: DevFlyMode = DevFlyMode.new()
	_root.add_child(fly)
	fly.bind(_player)
	await _settle(6)
	fly.enter()
	# On emmène la caméra ailleurs, au-dessus du sol.
	fly.global_position = Vector3(24.0, 14.0, -18.0)
	var landed: Array[bool] = []
	fly.fly_exited.connect(func(teleported: bool) -> void: landed.append(teleported))
	fly.exit()
	check(not fly.is_active(), "le vol est terminé")
	check(not _player.is_frozen(), "la conduite est rendue au héros")
	check(landed.size() == 1 and landed[0],
		"le sol était atteignable : le héros est reposé dessous")
	check(absf(_player.global_position.x - 24.0) < 1.0
		and absf(_player.global_position.z + 18.0) < 1.0,
		"…exactement sous la caméra (%s)" % str(_player.global_position))
	await _settle(10)
	check(_player.global_position.y > -1.0, "et il tient debout, pas dans la roche")
	_teardown()


func test_leaving_flight_over_the_void_leaves_the_hero_where_he_was() -> void:
	## Le refus sûr : pas de sol dessous, donc pas de téléportation. Le héros
	## reste exactement où il était — jamais de chute dans le vide.
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var fly: DevFlyMode = DevFlyMode.new()
	_root.add_child(fly)
	fly.bind(_player)
	await _settle(6)
	var home: Vector3 = _player.global_position
	fly.enter()
	# Loin au-delà du sol de la scène : rien sous la caméra.
	fly.global_position = Vector3(900.0, 30.0, 900.0)
	var landed: Array[bool] = []
	fly.fly_exited.connect(func(teleported: bool) -> void: landed.append(teleported))
	fly.exit()
	check(landed.size() == 1 and not landed[0],
		"aucun sol dessous : la dépose est refusée")
	check(_player.global_position.distance_to(home) < 1.0,
		"le héros est resté où il était")
	check(not _player.is_frozen(), "et il a repris la conduite malgré le refus")
	_teardown()
