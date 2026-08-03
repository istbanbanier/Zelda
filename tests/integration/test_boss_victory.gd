## G.3 — CONCLUSION et VICTOIRE (MASTER_SPEC §16.8, §17.3).
##
## §16.8 énumère huit choses ; ce fichier les prend une par une :
## arrêter les hazards, animation de mort, tempête qui se dissipe
## PARTIELLEMENT, énergie cyan qui passe de violente à calme, coffre final,
## sauvegarde `boss_defeated`, courte cinématique PASSABLE, écran victoire
## avec ses trois issues.
##
## Deux choses ne sont volontairement pas jouées ici : le changement de
## scène lui-même (`SceneFlow.go_to()` met l'arbre en pause et détruit la
## scène courante — celle du runner), et le jugement esthétique de
## l'apaisement du ciel. La cible et le déclenchement sont prouvés ; le
## reste appartient à l'œil humain et à la Phase H.
extends GateTestCase

const ARENA: String = "res://scenes/boss/BossArena.tscn"
const VICTORY: String = "res://scenes/ui/VictoryScreen.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open(path: String) -> Node:
	var scene: Node = (load(path) as PackedScene).instantiate()
	_tree().root.add_child(scene)
	await _settle(8)
	return scene


func _close(scene: Node) -> void:
	scene.get_parent().remove_child(scene)
	scene.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(3)


func _erase_save() -> void:
	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	if save_system == null:
		return
	var path: String = String(save_system.call("slot_path", "slot0"))
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _kill_boss(arena: BossArena) -> void:
	var event: DamageEvent = DamageEvent.new()
	event.team = &"player"
	event.amount = arena.boss().health().maximum() * 2.0
	arena.boss().health().take_damage(event)
	await _settle(6)


## §16.8 : « coffre final ». Il n'existe pas avant la victoire, et il
## contient un butin certain — pas une table de probabilités.
func test_the_final_chest_appears_only_after_the_guardian_falls() -> void:
	await _erase_save()
	var arena: BossArena = await _open(ARENA) as BossArena
	arena.auto_show_victory = false
	check_not_null(arena.boss(), "le Gardien est là")
	check(arena.final_chest() == null,
		"aucun coffre final tant qu'il est debout")
	await _kill_boss(arena)
	check_not_null(arena.final_chest(), "le coffre final est apparu")
	check_equal(String(arena.final_chest().chest_id), "boss.chest.final.01",
		"…avec un identifiant stable (§19.3)")
	check_not_null(arena.final_chest().weapon_loot,
		"…et une arme garantie")
	check(arena.final_chest().arrows_loot > 0, "…et des flèches")
	var flat: Vector2 = Vector2(arena.final_chest().position.x,
		arena.final_chest().position.z)
	check(flat.length() < 6.0,
		"il naît au centre de l'arène (%.1f m) : on n'a pas à le chercher"
		% flat.length())
	await _close(arena)
	await _erase_save()


## §16.8 : « arrêter tous les hazards », « énergie cyan qui passe de
## violente à calme ». Après la victoire, plus une veine ne conduit.
func test_the_cyan_goes_quiet_when_he_dies() -> void:
	await _erase_save()
	var arena: BossArena = await _open(ARENA) as BossArena
	arena.auto_show_victory = false
	# Deux pylônes debout : l'arène est vivante juste avant la fin.
	arena.pylons()[0].lever().interact(arena.player())
	arena.pylons()[1].lever().interact(arena.player())
	await _settle(6)
	check(arena.powered_pylons() >= 1, "l'arène est encore sous tension")
	var lit_before: int = 0
	for node: ElectricNode in arena.rail():
		if node.is_powered():
			lit_before += 1
	check(lit_before > 0, "%d nœuds du rail sont allumés" % lit_before)

	await _kill_boss(arena)
	check_equal(arena.raised_pylons(), 0, "les pylônes sont retombés")
	var lit_after: int = 0
	for node: ElectricNode in arena.rail():
		if node.is_powered():
			lit_after += 1
	check_equal(lit_after, 0,
		"le rail est éteint : le puits de terre s'est tu (%d → %d)"
		% [lit_before, lit_after])
	await _close(arena)
	await _erase_save()


## §16.8 : « tempête qui se dissipe PARTIELLEMENT ». On mesure : le ciel
## s'éclaircit et le brouillard tombe — mais rien ne saute d'un coup, et
## l'orage ne redevient pas un midi bleu.
func test_the_storm_partially_clears_after_the_victory() -> void:
	await _erase_save()
	var arena: BossArena = await _open(ARENA) as BossArena
	arena.auto_show_victory = false
	var world_environment: WorldEnvironment = arena.get_node(
		"ArenaEnvironment") as WorldEnvironment
	var environment: Environment = world_environment.environment
	var sky_before: Color = environment.background_color
	var fog_before: float = environment.fog_density
	var light: DirectionalLight3D = arena.get_node("StormLight") \
		as DirectionalLight3D
	var energy_before: float = light.light_energy

	check(not arena.is_calming(), "rien ne bouge pendant le combat")
	await _kill_boss(arena)
	check(arena.is_calming(), "l'apaisement a commencé")
	# Un pas isolé reste petit : c'est une dissipation, pas une coupure.
	var previous: Color = environment.background_color
	var biggest_step: float = 0.0
	for i: int in range(180):
		await _tree().physics_frame
		var current: Color = environment.background_color
		biggest_step = maxf(biggest_step,
			absf(current.v - previous.v))
		previous = current
	check(biggest_step < 0.05,
		"le plus grand pas de luminance vaut %.4f : le ciel s'OUVRE, il ne saute pas"
		% biggest_step)
	check(environment.background_color.v > sky_before.v,
		"le ciel s'est éclairci (%.3f → %.3f)"
		% [sky_before.v, environment.background_color.v])
	check(environment.fog_density < fog_before,
		"le brouillard est tombé (%.4f → %.4f)"
		% [fog_before, environment.fog_density])
	check(light.light_energy > energy_before,
		"la lumière est revenue (%.2f → %.2f)"
		% [energy_before, light.light_energy])
	# « PARTIELLEMENT » : on reste dans la continuité dorée de §7.7.
	check(environment.background_color.v < 0.75,
		"…sans redevenir un midi bleu (luminance %.2f)"
		% environment.background_color.v)
	await _close(arena)
	await _erase_save()


## §16.8 : « courte cinématique PASSABLE ». Ouvrir le coffre la termine
## sur-le-champ ; sinon elle s'arrête d'elle-même.
func test_the_conclusion_can_be_cut_short_by_opening_the_chest() -> void:
	await _erase_save()
	var arena: BossArena = await _open(ARENA) as BossArena
	arena.auto_show_victory = false
	await _kill_boss(arena)
	await _settle(30)
	check(not arena.conclusion_is_over(),
		"une demi-seconde après, la conclusion court encore")
	check(arena.conclusion_elapsed() < BossArena.CONCLUSION_TIME,
		"…et on est loin des %.0f s" % BossArena.CONCLUSION_TIME)

	# Le joueur ouvre le coffre : il a fini de regarder.
	arena.player().global_position = arena.final_chest().global_position \
		+ Vector3(0, 0.3, 1.4)
	await _settle(4)
	check(arena.final_chest().interact(arena.player()),
		"le coffre final s'ouvre")
	await _settle(4)
	check(arena.conclusion_is_over(),
		"la conclusion est passée : le joueur n'attend pas un compte à rebours")
	check(arena.victory_shown(), "…et l'écran de victoire est demandé")
	check_equal(arena.victory_target(), VICTORY, "vers le bon écran")
	check(ResourceLoader.exists(arena.victory_target()),
		"…qui existe pour de bon")
	await _close(arena)
	await _erase_save()


## §16.8 : « écran victoire avec recommencer, continuer/explorer ou menu ».
## §17.3 : navigation clavier/manette, focus visible, AUCUN piège de focus.
func test_the_victory_screen_offers_three_real_ways_out() -> void:
	await _erase_save()
	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	save_system.call("save_slot", "slot0", {
		"schema": 2, "boss_defeated": true, "playtime_seconds": 1830.0,
	})
	var screen: Control = await _open(VICTORY) as Control
	screen.set("auto_navigate", false)
	var buttons: Array[Button] = screen.call("buttons") as Array[Button]
	check_equal(buttons.size(), 3, "trois issues (§16.8)")
	# Les deux autres issues mènent bien où elles disent.
	buttons[0].pressed.emit()
	check_equal(String(screen.call("last_target")),
		"res://scenes/world/valley/ValleyWorld.tscn",
		"« Continuer l'exploration » ramène dans la vallée")
	buttons[2].pressed.emit()
	check_equal(String(screen.call("last_target")),
		"res://scenes/ui/MainMenu.tscn", "« Menu principal » ramène au menu")
	for button: Button in buttons:
		check(not button.disabled,
			"« %s » est réellement disponible" % button.text)
	# §17.3 : le cycle de focus se referme — on ne s'y perd pas.
	for button: Button in buttons:
		check(not button.focus_neighbor_bottom.is_empty(),
			"« %s » a un voisin en bas" % button.text)
		check(not button.focus_neighbor_top.is_empty(),
			"« %s » a un voisin en haut" % button.text)
	var last: Button = buttons[buttons.size() - 1]
	check_equal(last.focus_neighbor_bottom, buttons[0].get_path(),
		"le dernier boucle sur le premier : pas de piège de focus")
	# La durée affichée vient de la sauvegarde, pas d'un compteur inventé.
	var time_label: Label = screen.get_node("Layout/Column/TimeLabel") as Label
	check(time_label.text.contains("30"),
		"le temps de jeu vient du fichier : « %s »" % time_label.text)
	await _close(screen)
	await _erase_save()


## Et il refuse d'annoncer une victoire qui n'a pas eu lieu — on peut y
## atterrir par une transition de debug (§0.2 : ne pas présenter comme
## acquis ce qui ne l'est pas).
func test_the_victory_screen_does_not_claim_a_victory_that_never_happened() -> void:
	await _erase_save()
	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	save_system.call("save_slot", "slot0", {"schema": 2, "boss_defeated": false})
	var screen: Control = await _open(VICTORY) as Control
	check(String(screen.call("status_text")).contains("Aucune victoire"),
		"l'écran le dit : « %s »" % String(screen.call("status_text")))
	await _close(screen)
	await _erase_save()


## §17.3 : « confirmation avant écrasement d'une sauvegarde ». Recommencer
## efface une partie terminée : on le demande une fois, puis on écrit une
## partie NEUVE — un slot absent et un slot vierge ne se valent pas.
func test_restarting_asks_before_erasing_a_finished_run() -> void:
	await _erase_save()
	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	save_system.call("save_slot", "slot0", {
		"schema": 2, "boss_defeated": true, "playtime_seconds": 900.0,
	})
	var screen: Control = await _open(VICTORY) as Control
	screen.set("auto_navigate", false)
	var buttons: Array[Button] = screen.call("buttons") as Array[Button]
	var restart: Button = buttons[1]
	restart.pressed.emit()
	await _settle(2)
	check(bool(screen.call("is_confirming_restart")),
		"le premier appui DEMANDE confirmation")
	var data: Dictionary = save_system.call("load_slot", "slot0") as Dictionary
	check(bool(data.get("boss_defeated", false)),
		"…et n'a encore rien effacé")

	restart.pressed.emit()
	await _settle(2)
	data = save_system.call("load_slot", "slot0") as Dictionary
	check(not bool(data.get("boss_defeated", true)),
		"le second appui écrit une partie neuve")
	check_approx(float(data.get("playtime_seconds", -1.0)), 0.0, 0.01,
		"…avec son compteur remis à zéro")
	check(bool(save_system.call("has_save", "slot0")),
		"le slot existe toujours : on n'a pas supprimé le fichier")
	check_equal(String(screen.call("last_target")),
		"res://scenes/world/valley/ValleyWorld.tscn",
		"…et il repart dans la vallée")
	await _close(screen)
	await _erase_save()
