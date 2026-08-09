## PARCOURS DE CÂBLAGE — ce que le flux RELIE, jamais ce qu'un joueur ATTEINT.
##
## Ce fichier s'appelait `test_golden_path.gd`. L'audit indépendant du
## 2026-08-09 a exigé son renommage, et il avait raison : appeler « golden path »
## une suite d'appels directs à `interact()` revenait à annoncer une couverture
## qui n'existait pas.
##
## CE QU'IL PROUVE — le câblage, et rien d'autre :
##   - `Boot` → menu → `SceneFlow` → vallée ;
##   - `Chest.interact()` → inventaire du joueur ;
##   - `HealthComponent.take_damage()` → mort de l'ennemi ;
##   - `SceneDoor.interact()` → `SceneFlow` → vestibule, puis salle 1.
##
## CE QU'IL NE PROUVE PAS, et qu'aucun de ses verdicts ne doit laisser croire :
##   - qu'un joueur puisse ATTEINDRE ces objets. Ici, rien ne marche : la cible
##     est saisie dans le groupe `interactable` et sa méthode est appelée là où
##     elle est, fût-elle à 344 m. `SceneDoor.interact()` ne vérifie aucune
##     distance — la portée vit dans `PlayerController._select_interactable()`,
##     qui n'est jamais sollicité ici ;
##   - que le COMBAT fonctionne. Écrire dans `HealthComponent` prouve la
##     comptabilité des points de vie, pas une hitbox, pas une portée, pas une
##     animation ;
##   - que la RÉSONANCE agisse. `try_pulse()` appelé à la main rend `fired` même
##     si aucune touche ne peut l'atteindre.
##
## Le parcours qui joue réellement ces gestes est `test_physical_run.gd`. Les
## deux sont nécessaires : celui-ci tombe vite et désigne le fil coupé, l'autre
## est lent et dit si un joueur y arrive.
##
## Toutes les attentes sont bornées en TEMPS DE JEU (ISS-038).
extends GateTestCase

const BOOT: String = "res://scenes/boot/Boot.tscn"


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
	# Retirer par DELTA, pas par liste de noms : la dernière action du parcours
	# demande la salle 1, et la scène chargée se posait APRÈS ce nettoyage sous
	# un nom anonyme (`@Node@…`) qu'aucune liste ne pouvait prévoir.
	# Voir `GateTestCase.restore_root()`.
	var clean: bool = await restore_root()
	check(clean, "W10 — la racine est rendue telle qu'elle était (SceneFlow au repos, "
		+ "aucune scène tardive)")
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	# L'AMBIANCE SURVIT AU MONDE. `ValleyWorld._ready()` demande
	# `AudioManager.play_ambience(&"amb_valley")`, et `AudioManager` est un
	# autoload : son lecteur et le WAV restent référencés après la disparition
	# de la vallée. En fin de processus, Godot le signale — « 2 ObjectDB
	# instances were leaked », « Resource still in use: amb_valley.wav ». Ce
	# n'est pas une fuite de gameplay ; c'est un test qui ne rend pas le
	# processus tel qu'il l'a trouvé. On le rend.
	var audio: Node = _tree().root.get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("stop_ambience"):
		audio.call("stop_ambience")
	await _settle(4)
	restore_saves()


func test_the_flow_wires_boot_to_the_first_dungeon_room() -> void:
	remember_saves()
	remember_root()

	# --- W1-W4. Le flux mène jusqu'à la vallée ------------------------------
	var boot: Node = (load(BOOT) as PackedScene).instantiate()
	_tree().root.add_child(boot)
	var reached_menu: bool = await _wait_until(
		func() -> bool: return _find("MainMenu") != null, 12.0)
	check(reached_menu, "W1 — Boot mène au menu principal")
	var menu: Node = _find("MainMenu")
	if menu == null:
		await _teardown()
		return
	var new_game: Button = menu.get_node_or_null("%NewGameButton") as Button
	check(new_game != null, "W2 — le menu expose un bouton « Nouvelle partie »")
	if new_game == null:
		await _teardown()
		return
	new_game.emit_signal("pressed")
	await _settle(2)
	# Sans sauvegarde, ce premier appui part droit vers la vallée et libère le
	# menu : lire `.text` ensuite lève une erreur qui avorte la méthode EN
	# SILENCE. Voir le commentaire long de `test_boot_smoke.gd`.
	var asked_confirmation: bool = is_instance_valid(new_game) \
		and new_game.text != "Nouvelle partie"
	if asked_confirmation:
		new_game.emit_signal("pressed")   # confirmation d'écrasement (§17.3)
	var in_valley: bool = await _wait_until(
		func() -> bool: return _find("ValleyWorld") != null, 25.0)
	check(in_valley, "W3 — le signal du bouton mène à la vallée (%s)"
		% ("après confirmation" if asked_confirmation else "sans sauvegarde"))
	var valley: Node = _find("ValleyWorld")
	if valley == null:
		await _teardown()
		return
	await _settle(12)
	var player: PlayerController = valley.call("player") as PlayerController
	check(player != null, "W4 — la vallée instancie un joueur")
	if player == null:
		await _teardown()
		return

	# --- W5. Coffre → inventaire -------------------------------------------
	# APPEL DIRECT ASSUMÉ : `Chest.interact()` est invoquée là où le coffre se
	# trouve. Cela prouve le fil coffre→inventaire ; cela ne prouve ni portée,
	# ni orientation, ni ligne de vue, ni qu'on puisse s'y rendre.
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
	check(chest != null, "W5 — la vallée chargée contient un coffre")
	if chest != null:
		var inventory: Node = player.call("inventory") if player.has_method("inventory") else null
		var before: int = int(inventory.call("weapon_count")) \
			if inventory != null and inventory.has_method("weapon_count") else -1
		var opened: bool = bool(chest.call("interact", player))
		check(opened,
			"…et `Chest.interact()` appelée DIRECTEMENT rend vrai (coffre à %.0f m, "
			% nearest + "distance non éprouvée)")
		await _settle(20)
		# ÉCHOUER FERMÉ : si l'inventaire n'expose pas de quoi compter, on ne
		# saute pas la vérification en silence — on la déclare non prouvée.
		if before >= 0 and inventory != null:
			var after: int = int(inventory.call("weapon_count"))
			check(after > before,
				"…et le fil coffre→inventaire porte l'objet (%d → %d armes)"
					% [before, after])
		else:
			check(false,
				"…mais le fil coffre→inventaire est NON VÉRIFIÉ : l'inventaire "
				+ "n'expose pas `weapon_count` (obtenu : %s)" % str(inventory))

	# --- W6. Santé → mort ---------------------------------------------------
	# APPEL DIRECT ASSUMÉ : on écrit dans `HealthComponent`. Cela prouve la
	# comptabilité des PV et la sortie `died` ; cela ne prouve AUCUN combat —
	# ni hitbox, ni portée, ni fenêtre active, ni animation.
	var enemy: Node = null
	for node: Node in _tree().get_nodes_in_group("enemies"):
		if node is Node3D:
			enemy = node
			break
	check(enemy != null, "W6 — la vallée chargée peuple un ennemi")
	if enemy != null:
		var enemy_health: Node = null
		var found: Array[Node] = enemy.find_children("*", "HealthComponent", true, false)
		enemy_health = found[0] if not found.is_empty() else null
		check(enemy_health != null, "…et il porte un HealthComponent")
		if enemy_health != null:
			var before_hp: float = enemy_health.call("current")
			var hit: DamageEvent = DamageEvent.new()
			hit.amount = 12.0
			enemy_health.call("take_damage", hit)
			await _settle(4)
			check(enemy_health.call("current") < before_hp,
				"…et `take_damage()` appelée DIRECTEMENT décompte (%0.1f → %0.1f PV, "
					% [before_hp, enemy_health.call("current")]
				+ "aucune hitbox éprouvée)")

	# --- W7. Le Bracelet est monté et répond à un appel direct --------------
	# APPEL DIRECT ASSUMÉ : `try_pulse()` rend `fired` même si aucune touche ne
	# peut l'atteindre. C'est un test de montage, pas d'action.
	var resonance: Node = null
	var res_found: Array[Node] = player.find_children(
		"*", "ResonanceController", true, false)
	resonance = res_found[0] if not res_found.is_empty() else null
	check(resonance != null, "W7 — le joueur instancié porte un ResonanceController")
	# `try_pulse(body)` rend `&"fired"` ou `&"cooldown"`
	# (`resonance_controller.gd:117`), PAS un motif d'échec.
	if resonance != null and resonance.has_method("try_pulse"):
		var verdict: StringName = resonance.call("try_pulse", player)
		check(verdict == &"fired",
			"…et `try_pulse()` appelée DIRECTEMENT rend « %s » (effet observable "
				% String(verdict) + "non éprouvé ici)")
	else:
		check(false,
			"…mais le montage est NON VÉRIFIÉ : pas de méthode `try_pulse` sur le "
			+ "contrôleur (obtenu : %s)" % str(resonance))

	# --- W8. SceneDoor → SceneFlow → vestibule ------------------------------
	# APPEL DIRECT ASSUMÉ, et c'est ici que le mot « franchissable » serait un
	# mensonge : `SceneDoor.interact()` ne consulte aucune distance. Le joueur
	# est à des centaines de mètres et la transition part quand même.
	var door: Node = _find("CitadelDoor")
	check(door != null, "W8 — la vallée construit une CitadelDoor")
	if door != null:
		var as_3d: Node3D = door as Node3D
		var span: float = player.global_position.distance_to(as_3d.global_position) \
			if as_3d != null else -1.0
		var entered: bool = bool(door.call("interact", player))
		check(entered,
			"…et `SceneDoor.interact()` appelée DIRECTEMENT demande la transition "
			+ "(joueur à %.0f m ; AUCUNE distance n'est vérifiée par cette méthode)"
				% span)
		var in_vestibule: bool = await _wait_until(
			func() -> bool: return _find("CitadelVestibule") != null, 25.0)
		check(in_vestibule, "W8b — SceneFlow ouvre le vestibule de la citadelle")

	# --- W9. Et la porte du donjon derrière lui -----------------------------
	var vestibule: Node = _find("CitadelVestibule")
	if vestibule != null:
		await _settle(12)
		var hero: PlayerController = vestibule.call("player") as PlayerController \
			if vestibule.has_method("player") else null
		check(hero != null, "W9 — le vestibule instancie un joueur")
		var dungeon_door: Node = _find("DungeonDoor")
		check(dungeon_door != null, "…et construit une DungeonDoor")
		if dungeon_door != null and hero != null:
			var went: bool = bool(dungeon_door.call("interact", hero))
			check(went, "…dont l'appel direct demande la transition vers la salle 1")
			var in_room1: bool = await _wait_until(
				func() -> bool: return _find("Room1Initiation") != null, 25.0)
			check(in_room1, "W9b — SceneFlow ouvre la SALLE 1 depuis le vestibule")

	await _teardown()
