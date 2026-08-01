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
		check(player.global_position.z > 160.0, "au spawn sud (§3.3 : z = 170)")
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
