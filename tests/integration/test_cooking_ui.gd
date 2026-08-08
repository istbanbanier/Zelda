## E.2b (§13.3) — la cuisine VISIBLE au feu de camp : le feu est un
## interactable réel de la vallée, l'atelier s'ouvre en pause, l'aperçu
## suit la sélection, la confirmation est ATOMIQUE (retrait + plat, ou
## rien), l'annulation ne coûte rien, et le label de buff du HUD suit le
## composant d'état. Tout est mesuré sur la vraie scène.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"

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
	await _settle(5)
	_shell = _valley.get_node("GameplayShell") as GameplayShell
	_player = _valley.call("player") as PlayerController


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


func test_the_campfire_opens_the_cooking_workshop_in_pause() -> void:
	await _load_valley()
	var fires: Array[Node] = _valley.find_children("*", "Campfire", true, false)
	check_equal(fires.size(), 1, "UN feu de cuisine dans la vallée")
	var fire: Campfire = fires[0] as Campfire
	check(fire.is_in_group("interactable"), "le feu est un interactable")
	check_equal(fire.prompt_verb(), "Cuisiner", "l'invite dit Cuisiner")
	check(bool(fire.interact(_player)), "l'interaction ouvre l'atelier")
	check(_shell.is_cooking_open(), "l'atelier est ouvert")
	check(_tree().paused, "le monde est en pause (§13.3 : aucune minuterie)")
	_shell.close_cooking()
	check(not _tree().paused, "fermer rend le monde")
	await _unload_valley()


func test_the_selection_previews_and_confirms_atomically() -> void:
	await _load_valley()
	var inventory: InventoryComponent = _player.inventory()
	var fruit: IngredientDefinition = load("res://resources/ingredients/heal_fruit.tres")
	var herb: IngredientDefinition = load("res://resources/ingredients/stamina_herb.tres")
	inventory.add_ingredient(fruit, 2)
	inventory.add_ingredient(herb, 1)
	check(bool(_shell.open_cooking(_player)), "atelier ouvert")
	check(_shell.cooking_add(&"heal_fruit"), "ajout fruit accepté")
	check(_shell.cooking_add(&"stamina_herb"), "ajout herbe accepté")
	check(_shell.cooking_preview_text().contains("grimpeur"),
		"l'aperçu annonce la famille : %s" % _shell.cooking_preview_text())
	check(_shell.cooking_add(&"heal_fruit"), "second fruit accepté (stock 2)")
	check(not _shell.cooking_add(&"heal_fruit"),
		"jamais plus que le stock possédé")
	var meals_before: int = inventory.meal_count()
	_shell.cooking_confirm()
	check_equal(inventory.meal_count(), meals_before + 1, "UN plat créé")
	check_equal(inventory.ingredient_count(&"heal_fruit"), 0,
		"les fruits choisis sont consommés")
	check_equal(inventory.ingredient_count(&"stamina_herb"), 0,
		"l'herbe choisie est consommée")
	check(not _shell.is_cooking_open(), "l'atelier se ferme sur le succès")
	check(not _tree().paused, "…et rend le monde")
	await _unload_valley()


func test_cancelling_returns_everything_and_costs_nothing() -> void:
	await _load_valley()
	var inventory: InventoryComponent = _player.inventory()
	# Bases de départ : la sauvegarde du test précédent peut avoir restauré
	# un plat — c'est le comportement VOULU (autosave sur meals_changed).
	var fruit_before: int = inventory.ingredient_count(&"heal_fruit")
	var meals_before: int = inventory.meal_count()
	var fruit: IngredientDefinition = load("res://resources/ingredients/heal_fruit.tres")
	inventory.add_ingredient(fruit, 3)
	check(bool(_shell.open_cooking(_player)), "atelier ouvert")
	check(_shell.cooking_add(&"heal_fruit"), "un fruit choisi")
	_shell.close_cooking()
	check_equal(inventory.ingredient_count(&"heal_fruit"), fruit_before + 3,
		"annuler rend TOUJOURS les ingrédients (§13.3)")
	check_equal(inventory.meal_count(), meals_before, "aucun plat fantôme")
	check_equal(_shell.cooking_selection_size(), 0, "le plan est effacé")
	await _unload_valley()


func test_the_hud_shows_the_active_buff_and_clears_on_expiry() -> void:
	await _load_valley()
	check_equal(_shell.buff_label_text(), "", "aucun buff : label vide")
	_player.status().apply_buff(&"stamina", 1.0, 30.0)
	check(await _label_reaches("Endurance"),
		"le label nomme la famille : %s" % _shell.buff_label_text())
	check(_shell.buff_label_text().contains("s"), "…et le temps restant")
	# ISS-038 — ce bloc appliquait un buff de 0,2 s puis attendait DIX frames de
	# rendu avant d'affirmer qu'il remplace l'ancien. À 60 im/s dix frames font
	# 0,167 s : le test tenait à 33 millisecondes près, et la moindre charge
	# machine le faisait échouer. C'est ce que le dépôt world-of-claudecraft
	# résume par « an unbounded run flakes heavy suites under core contention ».
	#
	# Règle qui en découle, et qui vaut pour TOUS les tests d'ici :
	#   un test ne doit jamais exiger que la machine soit RAPIDE ;
	#   il ne peut exiger que le passage d'ASSEZ de temps.
	# Attendre trop est sans danger ; attendre trop peu ne l'est pas.
	#
	# CORRECTIF INCOMPLET, repris — le premier passage n'avait allongé que la
	# DURÉE du buff en gardant un compte de frames FIXE. La suite complète sous
	# contention (4 processus sur 4 cœurs) l'a fait échouer à nouveau, sur la
	# même assertion : ce n'est pas le buff qui expirait, c'est le LABEL du HUD
	# qui n'avait pas eu le temps de se rafraîchir en dix frames.
	#
	# La règle s'applique donc jusqu'au bout : on n'attend plus un COMPTE, on
	# attend la CONDITION, bornée. Un plafond haut rend le test insensible à la
	# vitesse ; il reste sensible à un vrai blocage, qui épuise la borne.
	_player.status().apply_buff(&"attack", 0.25, 5.0)
	check(await _label_reaches("Attaque"),
		"un nouveau buff REMPLACE l'ancien au label")
	# L'expiration se prouve avec une durée très courte, puis l'attente que le
	# label se VIDE — même principe, dans l'autre sens.
	_player.status().apply_buff(&"attack", 0.25, 0.05)
	check(await _label_reaches(""), "expiré : label effacé")
	await _unload_valley()


## Attend que le label du HUD atteigne l'état voulu, BORNÉ.
##
## ISS-038 : `attendre N frames puis affirmer` exige que la machine soit rapide.
## Sous contention, dix frames de rendu ne suffisaient plus à rafraîchir le
## label, et la suite entière basculait au rouge sans qu'aucun code de jeu soit
## en cause. `needle` vide signifie « label vidé ».
##
## Rend `true` dès que la condition est vraie, `false` si la borne est épuisée —
## un vrai blocage échoue donc encore, il ne pend pas.
func _label_reaches(needle: String, max_frames: int = 600) -> bool:
	for i: int in range(max_frames):
		var text: String = _shell.buff_label_text()
		if (needle == "" and text == "") or (needle != "" and text.contains(needle)):
			return true
		await _tree().process_frame
	return false
