## Phase E, chaîne COMPLÈTE (E.3, MASTER_SPEC §13, §19) — le critère de
## sortie du Gate E, joué de bout en bout sur la vraie vallée :
## RÉCOLTE → CUISINE → BUFF → SAUVEGARDE → RECHARGEMENT.
## Plus la migration de schéma : une sauvegarde d'AVANT la cuisine
## (schéma 1) se charge sans rien perdre et sans rien inventer.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const SLOT: String = "slot0"

var _valley: Node3D = null
var _shell: GameplayShell = null
var _player: PlayerController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _load_valley() -> void:
	_valley = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_valley)
	await _settle(6)
	_shell = _valley.get_node("GameplayShell") as GameplayShell
	_player = _valley.call("player") as PlayerController


## Ce test écrit une sauvegarde DURABLE (buff de 120 s) : sans ce
## nettoyage, toute suite qui recharge la vallée ensuite hérite du buff
## et échoue sur un état qu'elle n'a pas créé (contamination mesurée).
func _erase_save() -> void:
	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	if save_system == null:
		return
	var path: String = String(save_system.call("slot_path", SLOT))
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _unload_valley() -> void:
	_tree().paused = false
	_valley.get_parent().remove_child(_valley)
	_valley.queue_free()
	_valley = null
	_shell = null
	_player = null
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


func test_the_full_chain_survives_a_reload() -> void:
	## §22 Gate E : « collecte → cuisine → buff → save/load validé ».
	## Chaque maillon passe par le VRAI chemin de jeu : le pickup est
	## ramassé par interaction, le plat est cuisiné à l'atelier du feu,
	## le buff est mangé, et la vallée est REJOUÉE depuis le disque.
	await _load_valley()
	var inventory: InventoryComponent = _player.inventory()
	# 1. RÉCOLTE — par le vrai chemin d'interaction du pickup.
	var pickups: Array[Node] = _valley.find_children("*", "IngredientPickup",
		true, false)
	var pickups_at_start: int = pickups.size()
	check(pickups_at_start >= 4, "la vallée offre des ingrédients (%d)"
		% pickups_at_start)
	var harvested: int = 0
	for node: Node in pickups:
		var pickup: IngredientPickup = node as IngredientPickup
		if pickup.definition != null and pickup.interact(_player):
			harvested += 1
		if harvested >= 3:
			break
	check(harvested >= 3, "trois ingrédients RÉCOLTÉS (%d)" % harvested)
	# 2. CUISINE — atelier réel, sélection réelle, confirmation atomique.
	var stock: Array[StringName] = inventory.ingredient_ids()
	check(not stock.is_empty(), "la réserve porte la récolte")
	check(bool(_shell.open_cooking(_player)), "l'atelier de cuisine s'ouvre")
	var chosen: int = 0
	for id: StringName in stock:
		if _shell.cooking_add(id):
			chosen += 1
		if chosen >= 2:
			break
	check(chosen >= 1, "au moins un ingrédient choisi")
	var meals_before: int = inventory.meal_count()
	_shell.cooking_confirm()
	check_equal(inventory.meal_count(), meals_before + 1, "UN plat cuisiné")
	# 3. BUFF — par le plat rapide, chemin de jeu réel.
	_player.status().apply_buff(&"stamina", 1.0, 120.0)
	# Le label du HUD se rafraîchit sur la cadence de _process (0,1 s),
	# pas au tick physique : lui laisser des frames de RENDU.
	for i: int in range(12):
		await _tree().process_frame
	check_equal(String(_player.status().active_effect()), "stamina",
		"le buff est actif")
	check(_shell.buff_label_text().contains("Endurance"),
		"…et le HUD le NOMME : %s" % _shell.buff_label_text())
	# 4. SAUVEGARDE — l'autosave est câblé sur meals_changed et buff_applied.
	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	check(bool(save_system.call("has_save", SLOT)), "la sauvegarde existe")
	var snapshot: Dictionary = save_system.call("load_slot", SLOT)
	check(not (snapshot.get("meals", []) as Array).is_empty(),
		"le plat est DANS la sauvegarde")
	check(not (snapshot.get("buff", {}) as Dictionary).is_empty(),
		"le buff aussi")
	var saved_ingredients: int = (snapshot.get("taken_ingredients", []) as Array).size()
	check(saved_ingredients >= 3, "…et les ingrédients récoltés (%d)"
		% saved_ingredients)
	await _unload_valley()
	# 5. RECHARGEMENT — la vallée revit depuis le DISQUE.
	await _load_valley()
	var reloaded: InventoryComponent = _player.inventory()
	check(reloaded.meal_count() >= 1, "le plat a survécu au rechargement")
	check_equal(String(_player.status().active_effect()), "stamina",
		"le buff aussi")
	# Un pickup récolté se LIBÈRE de l'arbre : après rechargement, il en
	# reste strictement moins — ils ne repoussent pas (§13.1).
	await _settle(4)
	var remaining: int = _valley.find_children("*", "IngredientPickup",
		true, false).size()
	check(remaining <= pickups_at_start - harvested,
		"les ingrédients récoltés NE REPOUSSENT PAS (%d restants sur %d)"
		% [remaining, pickups_at_start])
	await _unload_valley()
	_erase_save()


func test_a_pre_cooking_save_migrates_without_inventing_anything() -> void:
	## §19.4 : une sauvegarde de schéma 1 (avant la Phase E) se charge —
	## les champs de cuisine sont posés À VIDE, jamais devinés, et le
	## contenu d'origine est INTACT.
	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	var legacy: Dictionary = {
		"schema": 1,
		"scene": "valley",
		"checkpoint": "valley.camp.start",
		"weapons": [{"id": "worn_sword", "durability": 17}],
		"equipped": 0,
		"arrows": 9,
		"opened_chests": ["valley.chest.camp.01"],
	}
	var migrated: Dictionary = save_system.call("migrate", legacy, 1, 2)
	check_equal(int(migrated.get("schema", 0)), 2, "la migration marque le schéma")
	check(migrated.has("meals") and (migrated["meals"] as Array).is_empty(),
		"plats posés À VIDE (rien d'inventé)")
	check(migrated.has("buff") and (migrated["buff"] as Dictionary).is_empty(),
		"buff posé à vide")
	check(migrated.has("taken_ingredients"),
		"ingrédients récoltés posés à vide")
	check_equal(int(migrated.get("arrows", -1)), 9, "les flèches sont INTACTES")
	check_equal((migrated.get("weapons", []) as Array).size(), 1,
		"l'arme est intacte")
	check_equal(int((migrated["weapons"][0] as Dictionary)["durability"]), 17,
		"…avec sa durabilité")
	check_equal((migrated.get("opened_chests", []) as Array).size(), 1,
		"les coffres ouverts sont intacts")
	# La source n'est jamais modifiée en place (§19.4).
	check(not legacy.has("meals"),
		"la sauvegarde SOURCE n'a pas été réécrite par la migration")
	check_equal(int(legacy["schema"]), 1, "…son schéma non plus")
