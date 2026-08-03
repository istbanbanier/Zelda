## « Continuer » honnête (D.1R.5, PT-D1-05) — la sauvegarde minimale restaure
## inventaire, durabilités, arme équipée, flèches et coffres ouverts, sans
## JAMAIS dupliquer un loot (§11.4 : « jamais de second loot après chargement »).
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const SLOT: String = "slot0"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _save_system() -> Node:
	return _tree().root.get_node_or_null("/root/SaveSystem")


func _clear_save() -> void:
	var system: Node = _save_system()
	if system == null:
		return
	var path: String = String(system.call("slot_path", SLOT))
	for candidate: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _cleanup(world: Node) -> void:
	_tree().root.remove_child(world)
	world.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


func test_chest_and_inventory_survive_a_reload_without_loot_duplication() -> void:
	## La chaîne complète : user l'épée, ouvrir le coffre du camp (l'instantané
	## part sur son signal), recharger la vallée — tout est restauré, et le
	## coffre rouvert ne donne RIEN.
	_clear_save()
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)
	var player: PlayerController = valley.player()
	var inventory: InventoryComponent = player.inventory()
	var sword: WeaponInstance = inventory.equipped()
	for i: int in range(3):
		sword.apply_hit_wear()   # 24 → 21 : la durabilité doit survivre
	var chest: Chest = valley.get_node("Camp/CampChest") as Chest
	check(chest.interact(player), "le coffre du camp s'ouvre (hache + 12 flèches)")
	check_equal(inventory.arrows(), 20, "8 + 12 flèches en main")
	await _settle(2)
	await _cleanup(valley)

	# Rechargement — la partie CONTINUE.
	var reloaded: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(reloaded)
	await _settle(10)
	var back: PlayerController = reloaded.player()
	var restored: InventoryComponent = back.inventory()

	check_equal(restored.weapon_count(), 2, "épée + hache restaurées")
	check_equal(String(restored.equipped().definition_id()), "worn_sword",
		"l'arme ÉQUIPÉE est restaurée")
	check_equal(restored.equipped().current_durability, 21,
		"…avec sa durabilité entamée (24 − 3)")
	check_equal(restored.arrows(), 20, "les flèches aussi")
	var camp_chest: Chest = reloaded.get_node("Camp/CampChest") as Chest
	check(camp_chest.is_opened(), "le coffre du camp est resté ouvert")
	check(not camp_chest.interact(back), "…et ne donne JAMAIS un second loot (§11.4)")
	check_equal(restored.arrows(), 20, "pas une flèche de plus")
	await _cleanup(reloaded)
	_clear_save()


func test_a_taken_pickup_never_respawns_after_reload() -> void:
	## QA-D1R-01 (revue contradictoire) : le gourdin ramassé au camp réapparaissait
	## après « Continuer » — le reprendre donnait DEUX gourdins, à l'infini. Le
	## pickup est maintenant persisté comme les coffres ; ce test mesure l'effet :
	## un seul exemplaire, et plus rien de ramassable au sol.
	_clear_save()
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)
	var player: PlayerController = valley.player()
	var pickup: WeaponPickup = valley.get_node("Camp/ClubPickup") as WeaponPickup
	# L'identifiant est relevé AVANT le ramassage : le pickup se libère
	# lui-même en se donnant, et l'interroger ensuite lit un objet mort.
	var taken_id: StringName = pickup.pickup_id
	check(pickup.interact(player), "le gourdin se ramasse")
	check_equal(player.inventory().weapon_count(), 2, "épée + gourdin en main")
	await _settle(2)   # l'instantané part sur le signal picked_up
	await _cleanup(valley)

	var reloaded: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(reloaded)
	await _settle(10)
	var back: PlayerController = reloaded.player()
	check_equal(back.inventory().weapon_count(), 2, "épée + gourdin restaurés")
	# Le test portait sur le NOMBRE de pickups restants, parce qu'il n'en
	# existait qu'un dans la vallée. Les lieux du monde ouvert en posent
	# maintenant d'autres, jamais ramassés — un total ne dit donc plus rien.
	# La question exacte est : CELUI qu'on a pris est-il revenu ?
	var respawned: bool = false
	var others: int = 0
	for node: Node in reloaded.find_children("*", "WeaponPickup", true, false):
		if not node.is_in_group("interactable"):
			continue
		if (node as WeaponPickup).pickup_id == taken_id:
			respawned = true
		else:
			others += 1
	check(not respawned,
		"le pickup RAMASSÉ (%s) ne réapparaît pas au sol" % taken_id)
	check(others >= 1,
		"…et les pickups jamais touchés sont toujours là (%d)" % others)
	var clubs: int = 0
	for weapon: WeaponInstance in back.inventory().weapons():
		if String(weapon.definition_id()) == "wood_club":
			clubs += 1
	check_equal(clubs, 1, "UN seul gourdin — jamais deux (§11.4)")
	await _cleanup(reloaded)
	_clear_save()


func test_a_fresh_new_game_save_applies_nothing() -> void:
	## L'instantané minimal d'une partie neuve (sans clé d'inventaire) laisse
	## les défauts du bac à sable intacts : épée neuve, 8 flèches, coffres clos.
	_clear_save()
	var system: Node = _save_system()
	system.call("save_slot", SLOT, {
		"schema": 2, "checkpoint": "valley.camp.start", "boss_defeated": false,
	})
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)
	var inventory: InventoryComponent = valley.player().inventory()
	check_equal(inventory.weapon_count(), 1, "l'épée de départ seulement")
	check_equal(inventory.equipped().current_durability, 24, "neuve")
	check_equal(inventory.arrows(), 8, "dotation de départ")
	check(not (valley.get_node("Camp/CampChest") as Chest).is_opened(),
		"coffre du camp fermé")
	check(valley.get_node("Camp/ClubPickup").is_in_group("interactable"),
		"…et le gourdin du camp est bien AU SOL en partie neuve")
	await _cleanup(valley)
	_clear_save()
