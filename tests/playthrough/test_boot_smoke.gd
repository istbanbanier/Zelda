## BOOT SMOKE — le parcours court du gate BOOT-TO-FUN (phase S1).
##
## Il part du VRAI `Boot.tscn`, traverse le VRAI menu en pressant son bouton,
## et arrive dans la vallée par `SceneFlow`. Rien n'est instancié à la main.
##
## La distinction n'est pas théorique. `test_valley_world.gd` contient déjà
## `test_the_menu_reaches_the_valley_scene`, qui vérifie une CONSTANTE du menu
## et `can_go_to()`. C'est un test de câblage : il resterait vert si le bouton
## n'était plus connecté, si `_ready()` plantait, ou si la vallée s'ouvrait sans
## joueur. Un test de présence ne prouve jamais l'atteignabilité.
##
## Toutes les attentes sont bornées en TEMPS DE JEU, jamais en nombre de frames
## (ISS-038) : une borne épuisée fait ÉCHOUER le test, elle ne le fait pas pendre.
extends GateTestCase

const BOOT: String = "res://scenes/boot/Boot.tscn"
## Sous le niveau du monde : le sol jouable de la vallée est à y ≥ 2 hors lit
## de rivière (−1,5). −5 est franchement sous tout terrain légitime.
const BELOW_WORLD: float = -5.0


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


## Attend qu'une condition devienne vraie, bornée en temps de jeu.
func _wait_until(probe: Callable, budget_s: float = 12.0) -> bool:
	var elapsed: float = 0.0
	while elapsed <= budget_s:
		if bool(probe.call()):
			return true
		await _tree().process_frame
		elapsed += _tree().root.get_process_delta_time()
	return false


## Premier nœud portant ce NOM ou cette CLASSE sous la racine, ou null.
##
## Chercher par classe seule ne suffit pas : `MainMenu` n'a pas de `class_name`
## (`main_menu.gd` étend `Control` tout court), et la première version de ce
## test l'a déclaré introuvable alors qu'il était bien dans l'arbre — le runner,
## lui, le voyait. Un test qui cherche mal accuse le jeu à tort.
func _find(wanted: String) -> Node:
	var by_class: Array[Node] = _tree().root.find_children("*", wanted, true, false)
	if not by_class.is_empty():
		return by_class[0]
	var by_name: Array[Node] = _tree().root.find_children(wanted, "", true, false)
	return by_name[0] if not by_name.is_empty() else null


## Retire du monde tout ce que ce test a pu y laisser. Appelé sur CHAQUE sortie,
## y compris les sorties anticipées : le runner refuse les nœuds résiduels, et
## il a raison — un test qui pollue l'arbre fait échouer le suivant.
func _teardown() -> void:
	for wanted: String in ["ValleyWorld", "MainMenu", "Boot"]:
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


func test_boot_smoke_from_boot_to_a_playable_valley() -> void:
	remember_saves()

	# --- B1. Le vrai Boot démarre ------------------------------------------
	var boot: Node = (load(BOOT) as PackedScene).instantiate()
	_tree().root.add_child(boot)
	await _settle(4)
	check(is_instance_valid(boot), "B1 — Boot.tscn s'instancie et survit à _ready()")

	# --- B2. Il atteint le menu principal, par lui-même ---------------------
	var reached_menu: bool = await _wait_until(
		func() -> bool: return _find("MainMenu") != null, 12.0)
	check(reached_menu, "B2 — Boot atteint le MENU PRINCIPAL sans intervention")
	var menu: Node = _find("MainMenu")
	if menu == null:
		await _teardown()
		return

	# --- B3. Le bouton du joueur existe et est pressable --------------------
	var new_game: Button = menu.get_node_or_null("%NewGameButton") as Button
	check(new_game != null, "B3 — le menu porte un bouton « Nouvelle partie »")
	check(new_game != null and not new_game.disabled,
		"…et il est actionnable, pas grisé")
	if new_game == null:
		await _teardown()
		return

	# --- B4. On le presse. Comme un joueur. ---------------------------------
	#
	# Et comme un joueur, on répond à la CONFIRMATION. §17.3 exige une
	# confirmation avant d'écraser une sauvegarde : quand une partie existe,
	# le bouton devient « Écraser la sauvegarde ? » et attend un second appui
	# (`main_menu.gd:_on_new_game`). Un test qui ne pressait qu'une fois voyait
	# donc la vallée s'ouvrir ou non SELON qu'un passage précédent avait laissé
	# une sauvegarde — un piège de déterminisme dans le test lui-même.
	new_game.emit_signal("pressed")
	await _settle(2)
	var asked_confirmation: bool = new_game.text != "Nouvelle partie"
	if asked_confirmation:
		check(true, "B4a — une sauvegarde existe : le menu DEMANDE confirmation (« %s »)"
			% new_game.text)
		new_game.emit_signal("pressed")
	var reached_valley: bool = await _wait_until(
		func() -> bool: return _find("ValleyWorld") != null, 25.0)
	check(reached_valley,
		"B4 — presser « Nouvelle partie » ouvre RÉELLEMENT la vallée")
	var valley: Node = _find("ValleyWorld")
	if valley == null:
		await _teardown()
		return
	await _settle(12)

	# --- B5. Un joueur vivant, posé sur un sol valide -----------------------
	var player: PlayerController = valley.call("player") as PlayerController
	check(player != null, "B5 — la vallée porte un joueur")
	if player == null:
		await _teardown()
		return
	var grounded: bool = await _wait_until(
		func() -> bool: return player.is_on_floor(), 8.0)
	check(grounded, "…qui se pose sur un sol valide")
	var health: Node = player.get_node_or_null("Components/HealthComponent")
	if health == null:
		var found: Array[Node] = player.find_children("*", "HealthComponent", true, false)
		health = found[0] if not found.is_empty() else null
	# `current` est une MÉTHODE (`health_component.gd:92`), pas une propriété.
	# `health.get("current")` rendait null, et `float(null)` levait une
	# « Nonexistent float constructor » qui avortait le test EN SILENCE — le
	# runner ne l'a vue que par le garde-fou ISS-027 du journal.
	check(health != null and health.call("current") > 0.0,
		"…et il est VIVANT (%s PV)"
			% (str(health.call("current")) if health != null else "aucun HealthComponent"))

	# --- B6. Caméra et HUD présents ----------------------------------------
	var rig: Node = player.call("camera_rig") if player.has_method("camera_rig") else null
	check(rig != null, "B6 — le joueur porte son rig de caméra")
	var shell: Node = valley.get_node_or_null("GameplayShell")
	check(shell != null, "…et le HUD de jeu est monté")

	# --- B7. Il ne tombe pas sous le monde ----------------------------------
	var lowest: float = player.global_position.y
	for i: int in range(180):
		await _tree().physics_frame
		lowest = minf(lowest, player.global_position.y)
	check(lowest > BELOW_WORLD,
		"B7 — le héros ne passe pas sous le monde en trois secondes (min y = %.2f)"
			% lowest)

	# --- B8. Une interaction et un ennemi sont ATTEIGNABLES depuis le spawn --
	# « Atteignable » veut dire : présent dans le monde chargé ET à portée de
	# marche depuis le spawn. La présence seule ne prouverait rien.
	var spawn: Vector3 = player.global_position
	var nearest_interactable: float = INF
	for node: Node in _tree().get_nodes_in_group("interactable"):
		var as_3d: Node3D = node as Node3D
		if as_3d != null:
			nearest_interactable = minf(nearest_interactable,
				spawn.distance_to(as_3d.global_position))
	check(nearest_interactable < 220.0,
		"B8 — une interaction est à portée de marche du spawn (%.0f m)"
			% nearest_interactable)
	var nearest_enemy: float = INF
	for node: Node in _tree().get_nodes_in_group("enemies"):
		var as_3d: Node3D = node as Node3D
		if as_3d != null:
			nearest_enemy = minf(nearest_enemy, spawn.distance_to(as_3d.global_position))
	check(nearest_enemy < 220.0,
		"…et un ennemi aussi (%.0f m)" % nearest_enemy)

	# --- B9. Mourir, puis reprendre -----------------------------------------
	# On tue par le VRAI chemin de dégâts (`take_damage` + `DamageEvent`), pas
	# en écrivant la vie à zéro : écrire l'état contournerait précisément ce
	# qu'on veut prouver — que mourir et reprendre FONCTIONNENT.
	var lethal: DamageEvent = DamageEvent.new()
	lethal.amount = 9999.0
	health.call("take_damage", lethal)
	var died: bool = await _wait_until(
		func() -> bool: return health.call("current") <= 0.0, 4.0)
	check(died, "B9 — le héros peut mourir par le chemin de dégâts réel")
	# Le jeu ne ressuscite pas tout seul, et c'est VOULU : mourir ouvre un
	# panneau (`%DeathPanel`) dont « Réessayer » recharge la scène au
	# checkpoint (`gameplay_shell.gd:20`). Un test qui attendait une reprise
	# spontanée accusait le jeu d'un défaut inexistant — il lui manquait le
	# geste du joueur.
	var panel_shown: bool = await _wait_until(
		func() -> bool:
			var found: Array[Node] = shell.find_children("DeathPanel", "", true, false)
			var panel: Control = found[0] as Control if not found.is_empty() else null
			return panel != null and panel.visible,
		6.0)
	check(panel_shown, "B9a — la mort ouvre le panneau de reprise")
	# `%RetryButton` ne se résout pas depuis ici : les noms uniques sont
	# relatifs au PROPRIÉTAIRE de scène, et `GameplayShell` est instancié dans
	# `ValleyWorld`. On cherche donc par nom, ce qui marche quel que soit
	# l'imbriquement.
	var retries: Array[Node] = shell.find_children("RetryButton", "", true, false)
	var retry: Button = retries[0] as Button if not retries.is_empty() else null
	check(retry != null, "B9b — le panneau porte un bouton « Réessayer »")
	if retry != null:
		retry.emit_signal("pressed")
	var recovered: bool = await _wait_until(
		func() -> bool:
			# La scène est RECHARGÉE : l'ancien joueur est détruit, il faut
			# donc interroger le nouveau, pas la référence d'avant.
			var world: Node = _find("ValleyWorld")
			if world == null:
				return false
			var hero: Node = world.call("player")
			if hero == null or not is_instance_valid(hero):
				return false
			var hp: Node = hero.call("health") if hero.has_method("health") else null
			return hp != null and hp.call("current") > 0.0 \
				and (hero as Node3D).global_position.y > BELOW_WORLD,
		30.0)
	check(recovered, "B9c — « Réessayer » rend un héros VIVANT dans le monde")

	# --- B10. Arrêt propre ---------------------------------------------------
	await _teardown()
	check(_find("ValleyWorld") == null and _find("MainMenu") == null,
		"B10 — l'arrêt ne laisse ni vallée ni menu résiduels sous la racine")
