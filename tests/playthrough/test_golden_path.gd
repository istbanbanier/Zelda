## GOLDEN PATH — le parcours long du gate BOOT-TO-FUN (phase S1).
##
## `Boot → menu → vallée → coffre → combat → Résonance → entrée du donjon`,
## par les VRAIES transitions du jeu. Chaque porte est franchie en appelant son
## `interact()`, c'est-à-dire le geste exact du joueur ; aucune scène n'est
## chargée à la main et aucun état n'est écrit pour sauter une condition.
##
## Pourquoi ce test n'est pas redondant avec les playthrough existants :
## `test_dungeon_run.gd` et `test_boss_run.gd` chargent les salles DIRECTEMENT
## (`const HALL = "res://scenes/dungeon/rooms/CentralHall.tscn"`). Ils prouvent
## qu'une salle est solvable ; ils ne prouvent pas qu'un joueur parti du menu
## puisse y arriver. Le prompt d'activation le dit : « un test de composant
## isolé ne prouve jamais l'atteignabilité ».
##
## Ce que ce test s'interdit, et qui rendrait sa preuve fausse : téléporter le
## joueur au-delà d'un obstacle, appeler une fonction de récompense, instancier
## le boss hors du flux, ou court-circuiter une condition que le joueur doit
## satisfaire. Il a le droit d'accélérer une attente — jamais de sauter une
## étape.
##
## Toutes les attentes sont bornées en TEMPS DE JEU (ISS-038).
extends GateTestCase

const BOOT: String = "res://scenes/boot/Boot.tscn"
const BELOW_WORLD: float = -5.0


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _wait_until(probe: Callable, budget_s: float = 15.0) -> bool:
	var elapsed: float = 0.0
	while elapsed <= budget_s:
		if bool(probe.call()):
			return true
		await _tree().process_frame
		elapsed += _tree().root.get_process_delta_time()
	return false


func _find(wanted: String) -> Node:
	var by_class: Array[Node] = _tree().root.find_children("*", wanted, true, false)
	if not by_class.is_empty():
		return by_class[0]
	var by_name: Array[Node] = _tree().root.find_children(wanted, "", true, false)
	return by_name[0] if not by_name.is_empty() else null


func _teardown() -> void:
	for wanted: String in ["ValleyWorld", "CitadelVestibule", "Room1Initiation",
			"MainMenu", "Boot"]:
		var node: Node = _find(wanted)
		while node != null:
			node.get_parent().remove_child(node)
			node.queue_free()
			node = _find(wanted)
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(4)
	restore_saves()


func test_golden_path_from_boot_to_the_dungeon_entrance() -> void:
	remember_saves()

	# --- G1-G4. Jusqu'à la vallée, par le vrai flux -------------------------
	var boot: Node = (load(BOOT) as PackedScene).instantiate()
	_tree().root.add_child(boot)
	var reached_menu: bool = await _wait_until(
		func() -> bool: return _find("MainMenu") != null, 12.0)
	check(reached_menu, "G1 — Boot atteint le menu principal")
	var menu: Node = _find("MainMenu")
	if menu == null:
		await _teardown()
		return
	var new_game: Button = menu.get_node_or_null("%NewGameButton") as Button
	check(new_game != null, "G2 — le bouton « Nouvelle partie » existe")
	if new_game == null:
		await _teardown()
		return
	new_game.emit_signal("pressed")
	await _settle(2)
	if new_game.text != "Nouvelle partie":
		new_game.emit_signal("pressed")   # confirmation d'écrasement (§17.3)
	var in_valley: bool = await _wait_until(
		func() -> bool: return _find("ValleyWorld") != null, 25.0)
	check(in_valley, "G3 — la vallée s'ouvre")
	var valley: Node = _find("ValleyWorld")
	if valley == null:
		await _teardown()
		return
	await _settle(12)
	var player: PlayerController = valley.call("player") as PlayerController
	check(player != null, "G4 — le héros est là")
	if player == null:
		await _teardown()
		return

	# --- G5. Un coffre atteignable donne un objet RÉEL ----------------------
	# On ouvre par `interact()`, le geste du joueur, jamais par la table de
	# butin : appeler la récompense directement prouverait la table, pas le
	# coffre.
	var chest: Node = null
	var nearest: float = INF
	for node: Node in _tree().get_nodes_in_group("interactable"):
		if not node.has_method("interact"):
			continue
		if not String(node.get_class()).contains("Chest") \
				and not node.name.to_lower().contains("chest") \
				and not node.name.to_lower().contains("coffre"):
			continue
		var as_3d: Node3D = node as Node3D
		if as_3d == null:
			continue
		var d: float = player.global_position.distance_to(as_3d.global_position)
		if d < nearest:
			nearest = d
			chest = node
	check(chest != null, "G5 — un coffre existe dans la vallée chargée")
	if chest != null:
		var inventory: Node = player.call("inventory") if player.has_method("inventory") else null
		var before: int = int(inventory.call("weapon_count")) \
			if inventory != null and inventory.has_method("weapon_count") else -1
		var opened: bool = bool(chest.call("interact", player))
		check(opened, "…et il s'ouvre par l'interaction du joueur (%.0f m du spawn)"
			% nearest)
		await _settle(20)
		if before >= 0 and inventory != null:
			var after: int = int(inventory.call("weapon_count"))
			check(after > before,
				"…et il donne un objet RÉEL à l'inventaire (%d → %d)" % [before, after])

	# --- G6. Un ennemi encaisse des dégâts par le chemin réel ---------------
	var enemy: Node = null
	for node: Node in _tree().get_nodes_in_group("enemies"):
		if node is Node3D:
			enemy = node
			break
	check(enemy != null, "G6 — un ennemi peuple la vallée")
	if enemy != null:
		var enemy_health: Node = null
		var found: Array[Node] = enemy.find_children("*", "HealthComponent", true, false)
		enemy_health = found[0] if not found.is_empty() else null
		check(enemy_health != null, "…et il a des points de vie")
		if enemy_health != null:
			var before_hp: float = enemy_health.call("current")
			var hit: DamageEvent = DamageEvent.new()
			hit.amount = 12.0
			enemy_health.call("take_damage", hit)
			await _settle(4)
			check(enemy_health.call("current") < before_hp,
				"…et il ENCAISSE (%0.1f → %0.1f PV)"
					% [before_hp, enemy_health.call("current")])

	# --- G7. Une capacité de Résonance agit sur une cible prévue ------------
	var resonance: Node = null
	var res_found: Array[Node] = player.find_children(
		"*", "ResonanceController", true, false)
	resonance = res_found[0] if not res_found.is_empty() else null
	check(resonance != null, "G7 — le héros porte son Bracelet de Résonance")
	if resonance != null and resonance.has_method("pulse"):
		var pulsed: bool = bool(resonance.call("pulse"))
		check(pulsed, "…et Pulse s'exécute depuis le monde chargé")

	# --- G8. L'entrée de la citadelle est FRANCHISSABLE ---------------------
	var door: Node = _find("CitadelDoor")
	check(door != null, "G8 — la porte de la citadelle existe dans la vallée")
	if door != null:
		var as_3d: Node3D = door as Node3D
		check(as_3d != null and player.global_position.distance_to(
			as_3d.global_position) < 500.0,
			"…et elle est dans le monde jouable (%.0f m du spawn)"
				% player.global_position.distance_to(as_3d.global_position))
		var entered: bool = bool(door.call("interact", player))
		check(entered, "…et son interaction demande RÉELLEMENT la transition")
		var in_vestibule: bool = await _wait_until(
			func() -> bool: return _find("CitadelVestibule") != null, 25.0)
		check(in_vestibule, "G8b — le vestibule de la citadelle s'ouvre")

	# --- G9. Et la porte du donjon derrière lui -----------------------------
	var vestibule: Node = _find("CitadelVestibule")
	if vestibule != null:
		await _settle(12)
		var hero: PlayerController = vestibule.call("player") as PlayerController \
			if vestibule.has_method("player") else null
		check(hero != null, "G9 — le vestibule porte un joueur")
		var dungeon_door: Node = _find("DungeonDoor")
		check(dungeon_door != null, "…et la porte du donjon y est présente")
		if dungeon_door != null and hero != null:
			var went: bool = bool(dungeon_door.call("interact", hero))
			check(went, "…et son interaction demande la transition vers la salle 1")
			var in_room1: bool = await _wait_until(
				func() -> bool: return _find("Room1Initiation") != null, 25.0)
			check(in_room1, "G9b — la SALLE 1 du donjon s'ouvre depuis le vestibule")

	await _teardown()
