## Vallée de Néris, D.0 (D-024) — l'intégration se prouve : la scène charge avec
## joueur, camp, pillards, coffre et arme au sol ; le ramassage verse dans
## l'inventaire de C.4 ; le coffre donne son loot UNE fois (§11.4) ; le menu
## sait atteindre la scène.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"
const PICKUP: String = "res://scenes/interactables/WeaponPickup.tscn"
const CHEST: String = "res://scenes/interactables/Chest.tscn"
const CLUB: String = "res://resources/weapons/wood_club.tres"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


## Monde de test minimal pour les interactions — même recette que les suites C.
func _setup_flat() -> void:
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
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
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


func test_the_valley_loads_with_player_camp_and_flow() -> void:
	## La scène complète s'instancie : joueur au spawn sud, trois pillards au
	## camp, coffre et arme au sol présents, flux VALLEY affiché.
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)

	var player: PlayerController = valley.player()
	check_not_null(player, "le joueur est dans la vallée")
	if player != null:
		check(player.global_position.z > 140.0, "au spawn sud, sur la crête")
		var grounded: bool = false
		for i: int in range(120):
			if player.is_on_floor():
				grounded = true
				break
			await _tree().physics_frame
		check(grounded, "le joueur atterrit sur le sol de la vallée")

	var raiders: Array[Node] = valley.find_children("*", "RaiderRed", true, false)
	check_equal(raiders.size(), 3, "trois pillards au camp")
	var chest: Chest = valley.get_node("Camp/CampChest") as Chest
	check_not_null(chest, "le coffre du camp existe")
	if chest != null:
		check_equal(String(chest.chest_id), "valley.chest.camp.01",
			"identifiant stable §19.3")
	check_not_null(valley.get_node_or_null("Camp/ClubPickup"), "une arme au sol")
	if game_state != null:
		check_equal(int(game_state.call("get_flow")), 2,
			"le flux affiche VALLEY (§6.1)")

	_tree().root.remove_child(valley)
	valley.queue_free()
	# Rendre le flux à son état d'avant le test : un test ne laisse pas d'empreinte.
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)


func test_a_weapon_on_the_ground_enters_the_inventory() -> void:
	## §14.2 + §11.3 : l'appui d'interaction devant l'objet le ramasse ; le
	## nœud disparaît ; l'arme est un exemplaire neuf dans l'inventaire.
	await _setup_flat()
	var pickup: WeaponPickup = (load(PICKUP) as PackedScene).instantiate() as WeaponPickup
	pickup.definition = load(CLUB) as WeaponDefinition
	_world.add_child(pickup)
	# Devant le visuel : +Z (le nez graybox), à 1,5 m — dans la portée de 2,2 m.
	pickup.global_position = _player.global_position + Vector3(0, 0, 1.5)
	var before: int = _player.inventory().weapon_count()
	await _settle(3)

	_intent.interact_pressed = true
	await _settle(3)

	check_equal(_player.inventory().weapon_count(), before + 1,
		"le gourdin est dans l'inventaire")
	check(not is_instance_valid(pickup) or pickup.is_queued_for_deletion(),
		"l'objet au sol a disparu")
	_teardown()


func test_a_full_inventory_leaves_the_weapon_on_the_ground() -> void:
	## §11.3 : huit armes, pas une de plus — le ramassage refusé laisse l'objet.
	await _setup_flat()
	var inventory: InventoryComponent = _player.inventory()
	var club_def: WeaponDefinition = load(CLUB) as WeaponDefinition
	while inventory.weapon_count() < InventoryComponent.MAX_WEAPONS:
		inventory.add_weapon(WeaponInstance.create(club_def))
	var pickup: WeaponPickup = (load(PICKUP) as PackedScene).instantiate() as WeaponPickup
	pickup.definition = club_def
	_world.add_child(pickup)
	pickup.global_position = _player.global_position + Vector3(0, 0, 1.5)
	await _settle(3)

	_intent.interact_pressed = true
	await _settle(3)

	check_equal(inventory.weapon_count(), 8, "l'inventaire reste à huit")
	check(is_instance_valid(pickup) and not pickup.is_queued_for_deletion(),
		"l'arme refusée RESTE au sol — rien n'est perdu")
	_teardown()


func test_the_chest_gives_its_loot_exactly_once() -> void:
	## §11.4 : loot garanti, « jamais de second loot ». Deux interactions :
	## la première donne l'arme et les flèches, la seconde ne donne RIEN.
	await _setup_flat()
	var chest: Chest = (load(CHEST) as PackedScene).instantiate() as Chest
	chest.chest_id = &"test.chest.flat.01"
	chest.weapon_loot = load("res://resources/weapons/heavy_axe.tres") as WeaponDefinition
	chest.arrows_loot = 12
	# Position posée AVANT add_child : un StaticBody3D ajouté à l'origine puis
	# déplacé passe un tick DANS le joueur — Jolt dépénètre le personnage de
	# 0,6 m et le coffre sort de la portée d'interaction. Mesuré à la sonde.
	chest.position = _player.global_position + Vector3(0, 0, 1.6)
	_world.add_child(chest)
	var inventory: InventoryComponent = _player.inventory()
	var weapons_before: int = inventory.weapon_count()
	var arrows_before: int = inventory.arrows()
	await _settle(3)

	_intent.interact_pressed = true
	await _settle(3)

	check(chest.is_opened(), "le coffre s'ouvre")
	check_equal(inventory.weapon_count(), weapons_before + 1, "la hache est versée")
	check_equal(inventory.arrows(), arrows_before + 12, "les 12 flèches aussi")

	_intent.interact_pressed = true
	await _settle(3)

	check_equal(inventory.weapon_count(), weapons_before + 1,
		"jamais de second loot (§11.4)")
	check_equal(inventory.arrows(), arrows_before + 12, "pas de flèches en double")
	_teardown()


func test_the_menu_reaches_the_valley_scene() -> void:
	## Le câblage « Nouvelle partie » → vallée : la constante du menu pointe une
	## scène que SceneFlow accepte réellement de charger.
	var menu_script: GDScript = load("res://scripts/ui/main_menu.gd") as GDScript
	var constants: Dictionary = menu_script.get_script_constant_map()
	check(constants.has("VALLEY_SCENE"), "le menu déclare la scène de la vallée")
	var path: String = String(constants.get("VALLEY_SCENE", ""))
	check_equal(path, VALLEY, "et c'est bien ValleyWorld.tscn")
	var flow: Node = _tree().root.get_node_or_null("/root/SceneFlow")
	check_not_null(flow, "SceneFlow est chargé")
	if flow != null:
		check(bool(flow.call("can_go_to", path)),
			"SceneFlow accepte la transition vers la vallée")


func test_the_spawn_ridge_holds_the_player_and_shows_the_landmarks() -> void:
	## D.1 : spawn SÛR sur la crête (y = 24), et les proxys qui portent la
	## relation héros → camp → pylône → citadelle existent aux cotes de §3.3.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)
	var player: PlayerController = valley.player()
	var grounded: bool = false
	for i: int in range(120):
		if player.is_on_floor():
			grounded = true
			break
		await _tree().physics_frame
	check(grounded, "le joueur atterrit sur la crête")
	check(absf(player.global_position.y - 24.0) < 1.0,
		"…à l'altitude de la crête (§3.3 : 24) — y = %.1f" % player.global_position.y)

	var pylon: Node3D = valley.get_node_or_null("Terrain/PylonShaft") as Node3D
	var keep: Node3D = valley.get_node_or_null("Terrain/CitadelProxy/Keep") as Node3D
	check_not_null(pylon, "proxy du pylône présent")
	check_not_null(keep, "proxy de la citadelle présent")
	if pylon != null:
		check(pylon.global_position.x > 80.0 and pylon.global_position.z < 0.0,
			"pylône dans le tiers droit-lointain (§3.3 : (115, -25))")
	if keep != null:
		check(keep.global_position.z < -180.0 and keep.global_position.y > 34.0,
			"citadelle au fond, DOMINANTE (§3.3 : (0, -210), plateau 34)")
	var vista: Camera3D = valley.get_node_or_null("VistaCamera_Hero01") as Camera3D
	check_not_null(vista, "VistaCamera_Hero01 en place (§3.2)")
	if vista != null:
		check(not vista.current, "…inactive en jeu : elle ne vole pas la caméra du joueur")

	# Guidage vers le camp (S3, quatre playtests perdus) : la fumée doit COUPER
	# la ligne d'horizon depuis la crête — sommet au-dessus de l'œil du joueur
	# (~27 m), sinon elle se fond dans les falaises grises, invisible par
	# construction. Et elle doit BOUGER (§2.2 P2 : « le mouvement attire ») —
	# le script de balancement est ce qui la distingue d'un décor.
	var smoke: MeshInstance3D = valley.get_node_or_null("Camp/SmokeColumn") as MeshInstance3D
	check_not_null(smoke, "colonne de fumée du camp présente")
	if smoke != null:
		var mesh_height: float = (smoke.mesh as CylinderMesh).height
		var top_y: float = smoke.global_position.y + mesh_height * 0.5
		check(top_y > 30.0,
			"le sommet de la fumée dépasse l'œil de crête (%.1f m > 30)" % top_y)
		check(smoke.get_script() != null,
			"la fumée est animée — une colonne statique est un décor, pas un signal")
	check_not_null(valley.get_node_or_null("Camp/CampFireLight"),
		"le feu du camp éclaire (§24 : « feu du camp visible à distance »)")
	check_not_null(valley.get_node_or_null("Camp/CampFlame"),
		"la flamme orange existe (§10.1 bible : elle rend le camp lisible à 100 m)")
	_tree().root.remove_child(valley)
	valley.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)


func test_the_route_from_ridge_to_north_plain_is_walkable() -> void:
	## D.1, risque critique « parcours praticable » : un pilote scripté sans
	## triche descend la crête par la descente en S, traverse la terrasse du
	## camp, sort vers la plaine, franchit le gué ouest et atteint la plaine
	## nord. Aucune téléportation, aucun saut requis — que des pentes de §8.2.
	## Les pillards sont retirés d'abord : ce test juge le TERRAIN, pas le combat.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	for raider: Node in valley.find_children("*", "RaiderRed", true, false):
		raider.queue_free()
	await _settle(5)
	var player: PlayerController = valley.player()
	var intent: InputIntent = InputIntent.new()
	player.set_intent_source(intent)
	for i: int in range(120):
		if player.is_on_floor():
			break
		await _tree().physics_frame
	check(player.is_on_floor(), "préalable : joueur posé sur la crête")

	var waypoints: Array[Vector2] = [
		Vector2(14, 152),    # bord sud-est de la crête
		Vector2(26, 134),    # rampe A
		Vector2(36, 112),    # palier 1
		Vector2(27, 94),     # rampe B (le S s'inverse)
		Vector2(18, 79),     # palier 2
		Vector2(28, 70),     # rampe C
		Vector2(40, 60),     # terrasse du camp
		Vector2(40, 38),     # sortie du camp
		Vector2(36, 22),     # plaine sud
		Vector2(20, 10),     # gué ouest
		Vector2(12, -8),     # plaine nord — rivière franchie
	]
	var reached: int = 0
	var ticks: int = 0
	var lowest: float = 100.0
	while reached < waypoints.size() and ticks < 3600:
		var target: Vector2 = waypoints[reached]
		var to_target: Vector2 = target - Vector2(player.global_position.x, player.global_position.z)
		if to_target.length() < 2.5:
			reached += 1
			continue
		intent.move = Vector2(to_target.x, -to_target.y).normalized()
		await _tree().physics_frame
		ticks += 1
		lowest = minf(lowest, player.global_position.y)
		if player.global_position.y < -0.5:
			break
	intent.move = Vector2.ZERO

	check_equal(reached, waypoints.size(),
		"tous les jalons atteints dans l'ordre (%d/%d, %d ticks)"
		% [reached, waypoints.size(), ticks])
	check(lowest > -0.5,
		"jamais sous le niveau du monde en route (min y = %.2f)" % lowest)
	check(ticks < 3600, "aucun blocage : budget de temps respecté (%d ticks)" % ticks)
	_tree().root.remove_child(valley)
	valley.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)


func test_a_fall_out_of_the_world_is_rescued_to_spawn() -> void:
	## D.1, risque critique « absence de chute hors monde » : sous la limite, le
	## filet ramène au spawn — sur le NOUVEAU relief, le spawn est la crête.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var player: PlayerController = valley.player()
	player.global_position = Vector3(200, -25, 200)
	player.reset_physics_interpolation()

	var rescued: bool = false
	for i: int in range(400):   # le filet vérifie chaque seconde — large marge
		await _tree().process_frame
		if player.global_position.y > 20.0:
			rescued = true
			break
	check(rescued, "le joueur est repêché")
	if rescued:
		check((player.global_position - Vector3(0, 24.3, 150)).length() < 3.0,
			"…au spawn de la crête")
	_tree().root.remove_child(valley)
	valley.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)


func test_a_raider_navigates_out_of_a_dead_end_to_reach_the_player() -> void:
	## D.1, risque critique « navigation ennemie » (D-022) : le pillard est posé
	## DANS la salle en U des ruines, le joueur au nord derrière le mur. Le
	## pilotage direct s'y coince (pousser au nord = glisser entre deux murs) ;
	## seul le chemin du navmesh sort par l'ouverture SUD puis contourne. Deux
	## preuves : il passe réellement au sud de la poche, et il ARRIVE au contact.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var player: PlayerController = valley.player()
	player.global_position = Vector3(-14, 2.2, -38)
	player.reset_physics_interpolation()
	var raider: RaiderRed = (load("res://scenes/enemies/RaiderRed.tscn") as PackedScene) \
		.instantiate() as RaiderRed
	raider.position = Vector3(-14, 2.1, -48)   # au fond de la poche en U
	valley.add_child(raider)
	await _settle(10)

	# Révéler l'attaquant : un impact est un événement sonore (§12.7).
	var poke: DamageEvent = DamageEvent.new()
	poke.instigator = player
	poke.team = &"player"
	poke.amount = 1.0
	poke.attack_id = HitboxComponent.next_attack_id()
	(raider.get_node("Hurtbox") as HurtboxComponent).receive_hit(poke)

	var went_south: bool = false
	var arrived: bool = false
	for i: int in range(900):
		await _tree().physics_frame
		if raider.global_position.z < -63.0:
			went_south = true
		var gap: Vector3 = player.global_position - raider.global_position
		gap.y = 0.0
		if gap.length() < 2.2:
			arrived = true
			break
	check(went_south,
		"le pillard est sorti par l'ouverture SUD — le chemin, pas la glissade")
	check(arrived,
		"…et il ARRIVE au contact (distance finale %.1f m)"
		% Vector3(player.global_position - raider.global_position).length())
	_tree().root.remove_child(valley)
	valley.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)
