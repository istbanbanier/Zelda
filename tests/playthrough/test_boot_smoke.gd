## BOOT SMOKE — le parcours court du gate BOOT-TO-FUN (phase S1).
##
## Il part du VRAI `Boot.tscn`, traverse le VRAI menu en pressant son bouton,
## et arrive dans World V2 par `SceneFlow`. Rien n'est instancié à la main.
##
## La distinction n'est pas théorique. `test_valley_world.gd` contient déjà
## `test_the_menu_reaches_world_v2`, qui vérifie une CONSTANTE du menu
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
	# Retirer par DELTA, pas par liste de noms, et seulement une fois la
	# transition en vol posée : « Réessayer » recharge la scène, et la recharge
	# se posait APRÈS ce nettoyage. Voir `GateTestCase.restore_root()`.
	var clean: bool = await restore_root()
	check(clean, "B10a — la racine est rendue telle qu'elle était (%s)"
		% ("SceneFlow au repos, aucune scène tardive" if clean
			else restore_root_reason()))
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	# L'audio est un autoload et peut survivre au monde. Le test le rend à son
	# état initial pour ne pas garder de ressource référencée après le parcours.
	var audio: Node = _tree().root.get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("stop_ambience"):
		audio.call("stop_ambience")
	await _settle(4)
	restore_saves()


func test_boot_smoke_from_boot_to_playable_world_v2() -> void:
	remember_saves()
	remember_root()

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
	# Le menu n'est utilisable qu'une fois le fondu terminé : presser plus tôt
	# fait refuser la transition EN SILENCE (`SceneFlow.can_go_to()` rend faux
	# tant que `_busy`). Voir `GateTestCase.await_flow_idle()`.
	var menu_ready: bool = await await_flow_idle()
	check(menu_ready, "B3b — le menu devient RÉELLEMENT utilisable (flux au repos)")
	new_game.emit_signal("pressed")
	await _settle(2)
	# `is_instance_valid` n'est pas de la prudence décorative. Sans sauvegarde,
	# le premier appui part DIRECTEMENT vers la vallée et `change_scene_to_file()`
	# libère le menu : lire `.text` sur l'objet libéré lève une erreur qui AVORTE
	# la méthode en silence. Le nettoyage ne s'exécutait alors plus, la vallée
	# restait dans l'arbre, et dix-sept assertions du donjon tombaient trente
	# fichiers plus loin. Le seul témoin était le garde-fou ISS-027 du journal.
	#
	# Le test se comportait donc différemment SELON qu'un passage précédent avait
	# laissé une sauvegarde. Les deux branches doivent marcher, et surtout
	# produire le MÊME nombre d'assertions — un compte qui varie d'un passage à
	# l'autre est un test qu'on ne peut pas comparer à lui-même.
	var asked_confirmation: bool = is_instance_valid(new_game) \
		and new_game.text != "Nouvelle partie"
	if asked_confirmation:
		new_game.emit_signal("pressed")
	# Pas de borne fixe sur un CHARGEMENT : voir `GateTestCase.await_scene()`.
	# Une borne fixe exigeait que la machine soit rapide, et B4 a fini par
	# rougir dans la suite complète après être passé seul.
	var reached_world: bool = await await_scene("WorldV2")
	# DIRE POURQUOI. `_on_new_game()` a trois sorties muettes : pas de
	# SaveSystem, confirmation demandée, et — la plus discrète — échec de
	# `save_slot()`, qui n'écrit qu'une phrase dans le libellé d'état et ne
	# déclenche aucune transition. Sans ces trois champs, l'échec ne dit pas
	# laquelle des trois s'est produite.
	# `menu` est LIBÉRÉ dès que la transition aboutit : interroger le libellé
	# d'état sans garde relève la même erreur silencieuse que `new_game.text`,
	# et avorte la méthode avant le nettoyage. Je viens de la commettre.
	var status: Label = menu.get_node_or_null("%StatusLabel") as Label \
		if is_instance_valid(menu) else null
	var flow: Node = _tree().root.get_node_or_null("/root/SceneFlow")
	check(reached_world,
		"B4 — presser « Nouvelle partie » ouvre RÉELLEMENT World V2 (%s"
			% ("après confirmation d'écrasement (§17.3)" if asked_confirmation
				else "aucune sauvegarde : départ direct")
		+ " · bouton « %s » · état « %s » · flux occupé=%s)"
			% [new_game.text if is_instance_valid(new_game) else "libéré",
				status.text if status != null else "(pas de StatusLabel)",
				str(flow.call("is_busy")) if flow != null else "?"])
	var world: Node = _find("WorldV2")
	if world == null:
		await _teardown()
		return
	await _settle(12)

	# --- B5. Un joueur vivant, posé sur un sol valide -----------------------
	var player: PlayerController = world.call("player") as PlayerController
	check(player != null, "B5 — World V2 porte un joueur")
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
	var player_camera: Camera3D = rig.call("get_camera") as Camera3D \
		if rig != null and rig.has_method("get_camera") else null
	var active_camera: Camera3D = world.get_viewport().get_camera_3d()
	check(player_camera != null and active_camera == player_camera,
		"…et la vue active est celle du JOUEUR, jamais une caméra de preuve "
			+ "(active : %s)" % (active_camera.name if active_camera != null else "aucune"))
	var shell: Node = world.get_node_or_null("GameplayShell")
	check(shell != null, "…et le HUD de jeu est monté")

	# --- B7. Il ne tombe pas sous le monde ----------------------------------
	var lowest: float = player.global_position.y
	for i: int in range(180):
		await _tree().physics_frame
		lowest = minf(lowest, player.global_position.y)
	check(lowest > BELOW_WORLD,
		"B7 — le héros ne passe pas sous le monde en trois secondes (min y = %.2f)"
			% lowest)

	# --- B7b. Le héros RÉPOND au monde --------------------------------------
	#
	# Trouvé par le contrôle négatif : avec `gravity = 0`, tout le reste de ce
	# parcours restait VERT. « Vivant, posé, HUD présent » ne prouve rien du
	# contrôle — un héros figé satisfait ces trois critères. Le gate ne voyait
	# donc pas un jeu injouable.
	#
	# On le soulève et on exige qu'il retombe et se repose. C'est le plus petit
	# geste qui éprouve gravité ET collision d'un coup.
	var ground_y: float = player.global_position.y
	player.global_position += Vector3(0.0, 3.0, 0.0)
	player.velocity = Vector3.ZERO
	var fell_back: bool = await _wait_until(
		func() -> bool:
			return player.is_on_floor() \
				and absf(player.global_position.y - ground_y) < 0.5,
		8.0)
	check(fell_back,
		"B7b — soulevé de 3 m, le héros RETOMBE et se repose (y %.2f → %.2f)"
			% [ground_y + 3.0, player.global_position.y])

	# --- B8. Le joueur MARCHE dans le vrai World V2 -------------------------
	# V2.3-A ne contient volontairement aucun acteur ennemi. Une présence
	# d'ennemi serait donc un faux critère de jouabilité. On injecte la même
	# intention que le clavier/manette et on exige un déplacement réel sur le
	# terrain monté, puis la présence du lot pilote et des 64 chunks.
	var start: Vector3 = player.global_position
	var intent: InputIntent = InputIntent.new()
	player.set_intent_source(intent)
	intent.move = Vector2(0.0, 1.0)
	for i: int in range(90):
		await _tree().physics_frame
	intent.move = Vector2.ZERO
	var walked: float = Vector2(start.x, start.z).distance_to(
		Vector2(player.global_position.x, player.global_position.z))
	check(walked > 1.0,
		"B8 — une intention joueur déplace le héros de %.2f m dans World V2" % walked)
	check_equal(_tree().get_nodes_in_group(&"world_v2_terrain").size(), 64,
		"…les 64 chunks du monde sont réellement montés")
	check_equal(_tree().get_nodes_in_group(&"world_v2_places").size(), 9,
		"…et les neuf lieux du lot pilote sont présents")

	# --- B9. Le CÂBLAGE santé → mort → panneau → reprise --------------------
	#
	# On appelle `take_damage()` avec un `DamageEvent` : cela prouve le FIL
	# `HealthComponent` → mort → `%DeathPanel` → « Réessayer » → héros vivant.
	# Cela ne prouve AUCUN combat — ni hitbox, ni portée, ni fenêtre active, ni
	# animation. Le combat réel est prouvé par `P5` de `test_physical_run.gd`,
	# qui frappe avec `attack_pressed` et vérifie que l'instigateur du dégât est
	# le joueur. L'audit a demandé que les mots le disent ; ils le disent.
	var lethal: DamageEvent = DamageEvent.new()
	lethal.amount = 9999.0
	health.call("take_damage", lethal)
	var died: bool = await _wait_until(
		func() -> bool: return health.call("current") <= 0.0, 4.0)
	check(died, "B9 — le câblage `HealthComponent.take_damage()` → mort répond "
		+ "(aucun combat éprouvé ici)")
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
	# `WorldV2`. On cherche donc par nom, ce qui marche quel que soit
	# l'imbriquement.
	var retries: Array[Node] = shell.find_children("RetryButton", "", true, false)
	var retry: Button = retries[0] as Button if not retries.is_empty() else null
	check(retry != null, "B9b — le panneau porte un bouton « Réessayer »")
	if retry != null:
		retry.emit_signal("pressed")
	# La reprise RECHARGE la scène : on laisse d'abord la transition finir à son
	# rythme, puis on borne seulement la VÉRIFICATION de vitalité. Chronométrer
	# le chargement reviendrait à exiger une machine rapide.
	await await_scene("WorldV2")
	var recovered: bool = await _wait_until(
		func() -> bool:
			# La scène est RECHARGÉE : l'ancien joueur est détruit, il faut
			# donc interroger le nouveau, pas la référence d'avant.
			var reloaded_world: Node = _find("WorldV2")
			if reloaded_world == null:
				return false
			var hero: Node = reloaded_world.call("player")
			if hero == null or not is_instance_valid(hero):
				return false
			var hp: Node = hero.call("health") if hero.has_method("health") else null
			return hp != null and hp.call("current") > 0.0 \
				and (hero as Node3D).global_position.y > BELOW_WORLD,
		30.0)
	check(recovered, "B9c — « Réessayer » rend un héros VIVANT dans le monde")

	# --- B10. Arrêt propre ---------------------------------------------------
	await _teardown()
	check(_find("WorldV2") == null and _find("MainMenu") == null,
		"B10 — l'arrêt ne laisse ni World V2 ni menu résiduels sous la racine")
