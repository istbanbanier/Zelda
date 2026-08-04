## Régression des bugs 2 et 3 de TESTS.md (passe de diagnostic).
##
## Bug 3 : l'autosave de la vallée écrivait un payload FIGÉ — tout champ posé
## par une autre scène disparaissait, dont `boss_defeated` que l'arène pose en
## fusionnant. Battre le boss puis ouvrir un coffre effaçait la victoire.
##
## Bug 2 : ni la santé ni l'endurance n'étaient sauvegardées (§19.1 les exige) —
## recharger soignait gratuitement.
##
## Même doctrine que le transform : le fichier de sauvegarde est une entrée
## NON FIABLE, une valeur absurde retombe sur les valeurs pleines sans crash.
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


func _load_valley() -> ValleyWorld:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)
	return valley


func _cleanup(world: Node) -> void:
	_tree().root.remove_child(world)
	world.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


func test_the_valley_autosave_preserves_the_boss_victory() -> void:
	## Le scénario exact du bug 3 : la victoire est posée dans le slot (comme le
	## fait `boss_arena.gd`), puis la vallée autosauvegarde. Le champ doit
	## SURVIVRE — avant correction, il ressortait à `false`, écrit en dur.
	_clear_save()
	var system: Node = _save_system()
	check_not_null(system, "SaveSystem")
	if system == null:
		return
	var valley: ValleyWorld = await _load_valley()

	# La victoire, posée par-dessus l'état courant — le modèle de l'arène.
	var data: Dictionary = {}
	if bool(system.call("has_save", SLOT)):
		data = system.call("load_slot", SLOT) as Dictionary
	data["boss_defeated"] = true
	system.call("save_slot", SLOT, data)

	# Puis la vie continue : un autosave de la vallée (coffre, récolte, repas…).
	valley._autosave()
	await _settle(2)

	var after: Dictionary = system.call("load_slot", SLOT) as Dictionary
	check(bool(after.get("boss_defeated", false)),
		"la victoire sur le boss doit survivre à l'autosave de la vallée")
	await _cleanup(valley)
	_clear_save()


func test_health_and_stamina_survive_a_reload() -> void:
	## Le scénario exact du bug 2 : perdre de la vie et de l'endurance,
	## sauvegarder, « recharger » — les valeurs doivent revenir, pas la pleine
	## forme gratuite.
	_clear_save()
	var valley: ValleyWorld = await _load_valley()
	var player: PlayerController = valley.player()
	check_not_null(player.health(), "HealthComponent")
	if player.health() == null:
		await _cleanup(valley)
		return

	player.health().revive(37.0)
	if player.stamina() != null:
		player.stamina().set_current(42.0)
	valley._autosave()
	await _settle(2)

	# Le « rechargement » : la pleine forme revient (comme à l'instanciation
	# d'une scène neuve), puis la sauvegarde s'applique par-dessus.
	player.health().revive()
	if player.stamina() != null:
		player.stamina().set_current(player.stamina().maximum())
	valley._apply_save()
	await _settle(2)

	check_approx(player.health().current(), 37.0, 0.5,
		"la santé sauvegardée doit être restaurée — pas de soin gratuit")
	if player.stamina() != null:
		check_approx(player.stamina().current(), 42.0, 0.5,
			"l'endurance sauvegardée doit être restaurée")
	await _cleanup(valley)
	_clear_save()


func test_corrupt_vitals_fall_back_to_full_health_without_crashing() -> void:
	## Fichier édité à la main : santé négative et endurance textuelle. Aucune
	## de ces valeurs ne doit passer, aucune ne doit crasher, et surtout aucune
	## ne doit TUER le joueur au chargement.
	_clear_save()
	var system: Node = _save_system()
	var valley: ValleyWorld = await _load_valley()
	var player: PlayerController = valley.player()

	var data: Dictionary = {}
	if bool(system.call("has_save", SLOT)):
		data = system.call("load_slot", SLOT) as Dictionary
	data["player_health"] = -5.0
	data["player_stamina"] = "beaucoup"
	system.call("save_slot", SLOT, data)

	valley._apply_save()
	await _settle(2)

	check(not player.health().is_dead(),
		"une santé sauvegardée absurde ne tue jamais le joueur")
	check_approx(player.health().current(), player.health().maximum(), 0.5,
		"santé absurde → pleine vie, le repli documenté")
	await _cleanup(valley)
	_clear_save()
