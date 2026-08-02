## E.1 — Ingrédients et récolte (§13.1, §13.2) : stacks bornés, ajout
## ATOMIQUE, double collecte impossible, placement réel dans la vallée,
## persistance sans respawn. Chaque test mesure l'effet (comptes, présence,
## refus), jamais la présence d'un nœud.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"
const SLOT: String = "slot0"

var _world: Node3D = null
var _player: PlayerController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _definition(name: String) -> IngredientDefinition:
	return load("res://resources/ingredients/%s.tres" % name) as IngredientDefinition


func _setup_player() -> void:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = Vector3(0, 0.1, 0)
	_world.add_child(_player)
	await _settle(3)


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	await _settle(1)


func _clear_save() -> void:
	var system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	if system == null:
		return
	var path: String = String(system.call("slot_path", SLOT))
	for candidate: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _cleanup_valley(valley: Node) -> void:
	_tree().root.remove_child(valley)
	valley.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


func test_stacks_are_bounded_and_consumption_is_all_or_nothing() -> void:
	## §13.1 : maximum de stack par DÉFINITION ; §13.3 : consommation tout ou
	## rien, jamais de compte négatif.
	await _setup_player()
	var inventory: InventoryComponent = _player.inventory()
	var spice: IngredientDefinition = _definition("rare_spice")   # stack 4
	for i: int in range(4):
		check(inventory.add_ingredient(spice), "ajout %d/4 accepté" % (i + 1))
	check(not inventory.add_ingredient(spice), "le 5e est REFUSÉ (stack 4)")
	check_equal(inventory.ingredient_count(&"rare_spice"), 4, "compte exact")
	check(not inventory.consume_ingredients(&"rare_spice", 5),
		"consommer 5 sur 4 : refusé, rien n'est prélevé")
	check_equal(inventory.ingredient_count(&"rare_spice"), 4, "…compte intact")
	check(inventory.consume_ingredients(&"rare_spice", 4), "consommer 4 sur 4")
	check_equal(inventory.ingredient_count(&"rare_spice"), 0, "réserve vidée")
	_teardown()


func test_harvest_is_atomic_and_refusal_leaves_the_item_on_the_ground() -> void:
	## §13.2 : l'objet ne disparaît QU'APRÈS le succès de l'ajout — réserve
	## pleine, il RESTE au sol et le compte ne bouge pas.
	await _setup_player()
	var inventory: InventoryComponent = _player.inventory()
	var fruit: IngredientDefinition = _definition("heal_fruit")
	var pickup: IngredientPickup = IngredientPickup.new()
	pickup.definition = fruit
	pickup.pickup_id = &"test.ingredient.fruit.01"
	pickup.position = Vector3(0, 0, 1.2)
	_world.add_child(pickup)
	await _settle(2)

	check(pickup.interact(_player), "récolte acceptée")
	check_equal(inventory.ingredient_count(&"heal_fruit"), 1, "un fruit en réserve")
	check(not pickup.interact(_player),
		"DOUBLE collecte impossible : le second appui de la même frame est refusé")
	check_equal(inventory.ingredient_count(&"heal_fruit"), 1, "…toujours UN fruit")

	# Réserve saturée : le pickup suivant refuse et RESTE.
	while inventory.add_ingredient(fruit):
		pass
	check_equal(inventory.ingredient_count(&"heal_fruit"), fruit.max_stack,
		"préalable : stack plein (%d)" % fruit.max_stack)
	var second: IngredientPickup = IngredientPickup.new()
	second.definition = fruit
	second.pickup_id = &"test.ingredient.fruit.02"
	second.position = Vector3(0.4, 0, 1.2)
	_world.add_child(second)
	await _settle(2)
	check(not second.interact(_player), "réserve pleine : récolte refusée")
	await _settle(2)
	check(is_instance_valid(second) and second.is_inside_tree(),
		"…et l'ingrédient RESTE au sol (§13.2 : rien n'est perdu)")
	_teardown()


func test_the_valley_offers_the_seven_ingredient_families() -> void:
	## §13.1 : les sept familles sont réellement posées, IDs stables uniques.
	_clear_save()
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var pickups: Array[Node] = valley.find_children("*", "IngredientPickup",
		true, false)
	check(pickups.size() >= 8, "au moins huit points de récolte (%d)" % pickups.size())
	var families: Dictionary = {}
	var ids: Dictionary = {}
	for node: Node in pickups:
		var pickup: IngredientPickup = node as IngredientPickup
		families[pickup.definition.id] = true
		var id: String = String(pickup.pickup_id)
		check(not id.is_empty() and not ids.has(id),
			"ID persistant unique : %s" % id)
		ids[id] = true
	check_equal(families.size(), 7, "les SEPT familles de §13.1 sont dans la vallée")
	await _cleanup_valley(valley)


func test_harvested_ingredients_survive_a_reload_and_never_respawn() -> void:
	## §13.1 (politique v0.1 explicite) + §19.4 : récolter → autosave →
	## recharger → la réserve est restaurée et le point de récolte NE
	## réapparaît PAS. Partie neuve : réserve vide, tout est au sol.
	_clear_save()
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var player: PlayerController = valley.player()
	var target: IngredientPickup = valley.find_children(
		"valley_ingredient_crest_fruit_01", "IngredientPickup", true, false)[0] \
		as IngredientPickup
	check(target.interact(player), "récolte du fruit de la crête")
	await _settle(3)   # l'autosave part sur le signal collected
	await _cleanup_valley(valley)

	var reloaded: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(reloaded)
	await _settle(5)
	check_equal(reloaded.player().inventory().ingredient_count(&"heal_fruit"), 1,
		"la réserve est restaurée (1 fruit)")
	var leftovers: Array[Node] = reloaded.find_children(
		"valley_ingredient_crest_fruit_01", "IngredientPickup", true, false)
	var still_there: bool = false
	for node: Node in leftovers:
		if node.is_in_group("interactable"):
			still_there = true
	check(not still_there, "le point récolté ne RÉAPPARAÎT pas")
	check(reloaded.find_children("valley_ingredient_crest_fruit_02",
		"IngredientPickup", true, false)[0].is_in_group("interactable"),
		"…mais le fruit NON récolté est toujours là")
	await _cleanup_valley(reloaded)
	_clear_save()
