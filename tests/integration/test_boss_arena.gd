## G.1 — ARÈNE du Gardien de l'Orage (MASTER_SPEC §16.1, §16.6).
##
## Ce que ces tests cherchent à faire ÉCHOUER, plutôt qu'à confirmer :
##   - une arène « circulaire » qui serait en réalité une boîte, ou dont le
##     diamètre sortirait des 32-42 m exigés ;
##   - des pylônes qui seraient un COMPTEUR déguisé — d'où le test qui
##     coupe le puits de terre : un pylône dressé mais non alimenté doit
##     rester éteint, et l'anneau fermé (un CYCLE) doit terminer ;
##   - un mur qui laisserait le Gardien sortir, ou pousser le joueur
##     dehors ;
##   - une caméra qui « s'élargirait » par un saut plutôt que par une
##     interpolation (§8.3 : aucun snap) ;
##   - un « Réessayer » qui renverrait dans la vallée au lieu de relancer
##     le combat, ou qui rendrait la main les mains vides.
extends GateTestCase

const ARENA: String = "res://scenes/boss/BossArena.tscn"
const ANTE: String = "res://scenes/dungeon/rooms/Antechamber.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open(path: String) -> Node3D:
	var scene: Node3D = (load(path) as PackedScene).instantiate() as Node3D
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


## §16.1 : « arène circulaire de 32-42 m ». On mesure la GÉOMÉTRIE, pas la
## constante : un sol en boîte passerait le test des constantes.
func test_the_arena_is_a_disc_between_32_and_42_metres() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var floor_body: StaticBody3D = arena.get_node("ArenaFloor") as StaticBody3D
	var shape: CollisionShape3D = floor_body.get_child(0) as CollisionShape3D
	var cylinder: CylinderShape3D = shape.shape as CylinderShape3D
	check_not_null(cylinder, "le sol est un CYLINDRE, pas une boîte (§16.1)")
	var diameter: float = cylinder.radius * 2.0
	check(diameter >= 32.0 and diameter <= 42.0,
		"diamètre %.1f m, dans les 32-42 m de §16.1" % diameter)
	# Trois zones de sol distinctes, du noyau vers la marge (§16.1).
	var radii: Array[float] = []
	for zone_name: String in ["ZoneCore", "ZoneRing", "ZoneOuter"]:
		var zone: MeshInstance3D = arena.get_node(zone_name) as MeshInstance3D
		check_not_null(zone, "zone de sol %s présente" % zone_name)
		radii.append((zone.mesh as CylinderMesh).top_radius)
	check(radii[0] < radii[1] and radii[1] < radii[2],
		"les trois zones sont emboîtées : %.0f < %.0f < %.0f m"
		% [radii[0], radii[1], radii[2]])
	await _close(arena)


## §16.1 : « aucun pilier bloquant durablement la caméra ». On balaie le
## disque : au-dessus du sol, rien entre le centre et la marge sauf les
## quatre pylônes.
func test_nothing_stands_in_the_middle_of_the_arena() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var offenders: Array[String] = []
	for child: Node in arena.get_children():
		var body: StaticBody3D = child as StaticBody3D
		if body == null or body.name == "ArenaFloor":
			continue
		var flat: Vector2 = Vector2(body.global_position.x,
			body.global_position.z)
		# Sous 13 m du centre et au-dessus du sol = un obstacle de cadrage.
		if flat.length() < 13.0 and body.global_position.y > 0.6:
			offenders.append("%s @ %.1f m" % [body.name, flat.length()])
	check(offenders.is_empty(),
		"rien ne se dresse au milieu de l'arène (trouvé : %s)"
		% ", ".join(offenders))
	check_equal(arena.pylons().size(), 4, "quatre pylônes (§16.1)")
	for pylon: GroundingPylon in arena.pylons():
		var radius: float = Vector2(pylon.position.x, pylon.position.z).length()
		check_approx(radius, 14.0, 0.1,
			"%s est sur l'anneau, à 14 m du centre" % pylon.name)
	await _close(arena)


## §16.3 : « les pylônes utilisent le MÊME système électrique que le
## donjon ». Preuve : dresser un pylône l'ALLUME, parce que le courant du
## puits de terre lui parvient par l'anneau — et couper le puits l'éteint.
func test_a_raised_pylon_is_powered_by_the_ground_rail() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	check(arena.rail().size() >= 20, "l'anneau de terre existe (%d nœuds)"
		% arena.rail().size())
	check_not_null(arena.earth_source(), "le puits de terre est une SOURCE")
	check_equal(arena.raised_pylons(), 0, "les quatre pylônes commencent baissés")
	check_equal(arena.powered_pylons(), 0, "…et donc aucun n'est allumé")

	var pylon: GroundingPylon = arena.pylons()[0]
	check(pylon.lever().interact(arena.player()),
		"le levier du pylône répond au joueur")
	await _settle(6)
	check(pylon.is_raised(), "le pylône est DRESSÉ")
	check(pylon.is_powered(),
		"…et il est ALIMENTÉ : le courant lui vient de l'anneau, pas d'un drapeau")
	check_equal(arena.powered_pylons(), 1, "lui seul est allumé")

	# La preuve inverse : sans le puits, un pylône dressé reste noir.
	arena.earth_source().enabled = false
	arena.graph().mark_dirty()
	arena.graph().recompute()
	await _settle(4)
	check(pylon.is_raised(), "il est toujours dressé…")
	check(not pylon.is_powered(),
		"…mais éteint : ce n'est donc PAS un compteur déguisé")
	arena.earth_source().enabled = true
	arena.graph().mark_dirty()
	arena.graph().recompute()
	await _settle(4)
	check(pylon.is_powered(), "le puits rétabli, il se rallume")
	await _close(arena)


## §15.2 pt. 5 : l'anneau est un CYCLE fermé. Le calcul doit terminer et ne
## visiter chaque nœud qu'une fois — c'est le piège classique du graphe.
func test_the_closed_ground_ring_terminates() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var start: int = Time.get_ticks_msec()
	for i: int in range(50):
		arena.graph().mark_dirty()
		arena.graph().recompute()
	var elapsed: int = Time.get_ticks_msec() - start
	check(elapsed < 4000,
		"50 recalculs de l'anneau fermé en %d ms — aucune récursion infinie"
		% elapsed)
	var powered: int = 0
	for node: ElectricNode in arena.rail():
		if node.is_powered():
			powered += 1
	check_equal(powered, arena.rail().size(),
		"le courant fait le TOUR de l'anneau : %d/%d nœuds alimentés"
		% [powered, arena.rail().size()])
	await _close(arena)


## §16.6 : « nav/steering garde le boss dans l'arène ». On le pousse vers
## le mur et on vérifie qu'il n'en sort pas.
func test_the_guardian_never_leaves_the_arena() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	check_not_null(boss, "le Gardien est dans l'arène")
	boss.debug_force_state(StormGuardian.State.PHASE1)
	# On place le joueur DEHORS : le boss va vouloir l'y suivre.
	arena.player().global_position = Vector3(0, 0.3, 30.0)
	var worst: float = 0.0
	for i: int in range(240):
		await _tree().physics_frame
		worst = maxf(worst, Vector2(boss.global_position.x,
			boss.global_position.z).length())
	check(worst <= BossArena.ARENA_RADIUS,
		"le Gardien reste dans le disque : au pire %.1f m sur %.0f m"
		% [worst, BossArena.ARENA_RADIUS])
	await _close(arena)


## §16.6 : « le boss ne pousse pas le joueur à travers les murs ». Le
## joueur est collé au mur, le colosse lui fonce dessus.
func test_the_guardian_cannot_push_the_player_through_the_wall() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	boss.debug_force_state(StormGuardian.State.PHASE1)
	var player: PlayerController = arena.player()
	# Contre le mur ouest, à l'opposé du seuil sud (qui, lui, est ouvert).
	player.global_position = Vector3(-17.5, 0.3, 0.0)
	boss.global_position = Vector3(-10.0, 0.2, 0.0)
	await _settle(4)
	var worst: float = 0.0
	for i: int in range(240):
		await _tree().physics_frame
		worst = maxf(worst, Vector2(player.global_position.x,
			player.global_position.z).length())
	check(worst < BossArena.WALL_RADIUS,
		"le joueur reste dans l'arène : au pire %.2f m, mur à %.1f m"
		% [worst, BossArena.WALL_RADIUS])
	await _close(arena)


## §16.6 : « la caméra élargit distance et FOV PROGRESSIVEMENT ».
## §8.3 : aucun snap. On mesure les deux : ça monte, et ça monte par pas.
func test_the_camera_widens_progressively_near_the_boss() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var rig: CameraRig = arena.player().camera_rig()
	var boss: StormGuardian = arena.boss()
	# Le Gardien reste en INTRO : il ne bouge pas de cinq secondes (§16.1),
	# donc c'est bien la DISTANCE qu'on mesure ici, pas sa poursuite.
	check_equal(String(boss.state_name()), "intro",
		"le Gardien s'éveille encore : il ne charge pas pendant la mesure")
	# Loin : cadrage d'exploration. La position est RELATIVE au Gardien, comme
	# l'approche ci-dessous. Elle était absolue, et le Gardien se tient à
	# z = -7 : la boucle rouvrait donc sur une téléportation de 7 m que le
	# commentaire prétendait avoir supprimée. Le même littéral avait deux sens.
	# 25 m tient dans l'arène (WALL_RADIUS = 19,6 depuis le centre, soit 18 m
	# ici) tout en restant hors de la portée d'élargissement du cadrage.
	arena.player().global_position = boss.global_position + Vector3(0, 0.3, 25.0)
	await _settle(60)
	var far_distance: float = rig.boss_framing_distance()
	check(far_distance < 0.6,
		"loin du Gardien, la caméra garde sa distance d'exploration (+%.2f m)"
		% far_distance)
	# On s'approche : le cadrage s'ouvre, sans jamais sauter.
	#
	# ISS-032 (2ᵉ échec) : ce bloc TÉLÉPORTAIT le joueur de 16,5 m à 6 m, puis
	# reprochait à la caméra son premier pas. Or ce pas n'était pas un snap :
	# `update_fov()` lisse par `lerpf` à poids exponentiel, et le premier pas
	# d'une exponentielle vers une cible qui vient de sauter est toujours le
	# plus grand — 0,431 m mesuré. §20.9 dit d'ailleurs qu'après une
	# téléportation on RÉINITIALISE l'interpolation ; on ne la juge pas.
	#
	# Un joueur, lui, s'approche. On le rapproche donc pas à pas, ce qui teste
	# ce que §16.6 promet réellement : le cadrage s'ouvre PENDANT qu'on avance.
	# Les trois seuils sont inchangés — c'est le scénario qui devient physique,
	# pas le critère qui s'assouplit.
	const APPROACH_TICKS: int = 90
	const APPROACH_FROM: float = 25.0
	const APPROACH_TO: float = 6.0
	var previous: float = rig.boss_framing_distance()
	var biggest_step: float = 0.0
	for i: int in range(APPROACH_TICKS):
		var t: float = float(i + 1) / float(APPROACH_TICKS)
		arena.player().global_position = boss.global_position + Vector3(
			0, 0.3, lerpf(APPROACH_FROM, APPROACH_TO, t))
		await _tree().physics_frame
		var current: float = rig.boss_framing_distance()
		biggest_step = maxf(biggest_step, absf(current - previous))
		previous = current
	# Littéral, et non `far_distance + 1.0` : relire l'attendu depuis le sujet
	# testé fait suivre au test toute dérive de la mesure « loin ». Le voisin
	# borne far_distance sous 0,6 ; 1,6 est donc au moins aussi strict, et
	# strictement plus fort puisqu'il ne bouge pas. Mesuré : 6,76 m.
	check(previous > 1.6,
		"au contact, la caméra a reculé de %.2f m" % previous)
	# Seuil RESSERRÉ, pas assoupli. Sans la téléportation résiduelle, le pas
	# maximal mesuré tombe à 0,051 m : un plafond à 0,25 absolvait tout, y
	# compris un vrai snap. 0,10 laisse le double de marge et reste strict.
	check(biggest_step < 0.10,
		"le plus grand pas d'un tick vaut %.3f m — c'est une interpolation, pas un snap"
		% biggest_step)
	check(rig.boss_framing_fov() > 2.0,
		"…et le champ s'est ouvert de %.1f°" % rig.boss_framing_fov())
	# Le Gardien mort, la caméra revient d'elle-même.
	boss.health().take_damage(_lethal_hit(boss))
	await _settle(90)
	check(rig.boss_framing_distance() < previous,
		"le combat fini, le cadrage se referme")
	await _close(arena)
	# Le Gardien est mort ici : l'arène a écrit `boss_defeated`. On efface,
	# sinon les tests suivants hériteraient d'une victoire qu'ils n'ont pas
	# jouée.
	await _erase_save()


func _lethal_hit(boss: StormGuardian) -> DamageEvent:
	var event: DamageEvent = DamageEvent.new()
	event.team = &"player"
	event.amount = boss.health().maximum() * 2.0
	event.damage_type = &"physical"
	return event


## §16.6 : « checkpoint juste avant », §19.5. L'antichambre écrit, l'arène
## relit : on ne recommence pas le boss les mains vides.
func test_the_arena_restores_the_antechamber_checkpoint() -> void:
	await _erase_save()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	game_state.call("set_pending_spawn", &"antechamber_from_hall")
	var ante: Antechamber = await _open(ANTE) as Antechamber
	# Le joueur ouvre le coffre garanti : lame conductrice + 12 flèches.
	check(ante.chest().interact(ante.player()), "le coffre garanti s'ouvre")
	await _settle(4)
	# Puis le checkpoint est réécrit avec ce qu'il porte VRAIMENT.
	ante.call("_write_checkpoint")
	check(ante.checkpoint_written(), "le checkpoint est écrit")
	var carried: int = ante.player().inventory().weapon_count()
	var arrows: int = ante.player().inventory().arrows()
	await _close(ante)

	game_state.call("set_pending_spawn", &"arena_from_antechamber")
	var arena: BossArena = await _open(ARENA) as BossArena
	check(arena.checkpoint_restored(), "l'arène a relu le checkpoint")
	check_equal(arena.player().inventory().weapon_count(), carried,
		"les %d armes du checkpoint sont là" % carried)
	check_equal(arena.player().inventory().arrows(), arrows,
		"les %d flèches aussi" % arrows)
	check_approx(arena.player().health().current(),
		arena.player().health().maximum(), 0.01,
		"§19.5 : on repart avec une santé correcte, pas à trois PV")
	# Et on est bien déposé DEVANT le seuil sud, dans l'arène.
	check(arena.player().global_position.z > 10.0,
		"le joueur entre par le sud (z = %.1f)"
		% arena.player().global_position.z)
	await _close(arena)
	await _erase_save()


## §16.6 : « retry en moins de 20 s après mort ». Ce qui est prouvable ici
## est la CIBLE du bouton et le coût réel de rechargement de la scène ;
## le ressenti d'un joueur qui appuie reste à valider humainement.
func test_retry_reloads_the_arena_not_the_valley() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var shell: GameplayShell = arena.get_node("GameplayShell") as GameplayShell
	check_equal(shell.retry_target(), ARENA,
		"« Réessayer » relance le combat, pas la vallée")
	await _close(arena)

	var start: int = Time.get_ticks_msec()
	var reloaded: BossArena = await _open(ARENA) as BossArena
	var elapsed_ms: int = Time.get_ticks_msec() - start
	check_not_null(reloaded.boss(), "le Gardien est là, entier")
	check_approx(reloaded.boss().health().current(),
		reloaded.boss().health().maximum(), 0.01,
		"…et à pleine vie : la reprise est propre")
	check_equal(reloaded.raised_pylons(), 0,
		"les pylônes sont rebaissés pour la nouvelle tentative")
	check(elapsed_ms < 20000,
		"chargement + mise en place de l'arène : %d ms (§16.6 : < 20 s)"
		% elapsed_ms)
	await _close(reloaded)


## §17.2 « barre de boss » et §16.1 « barre de vie originale ». Elle ne
## s'affiche QUE face au boss, elle suit la vraie vie, et elle nomme la phase.
func test_the_hud_shows_a_boss_bar_only_in_the_arena() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var shell: GameplayShell = arena.get_node("GameplayShell") as GameplayShell
	var boss: StormGuardian = arena.boss()
	boss.debug_force_state(StormGuardian.State.PHASE1)
	# Le HUD se rafraîchit sur une cadence : on attend le temps, pas la frame.
	var deadline: int = Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline and not shell.is_boss_bar_visible():
		await _tree().process_frame
	check(shell.is_boss_bar_visible(), "la barre de boss apparaît")
	check_approx(shell.boss_bar_value(), boss.health().current(), 1.0,
		"elle affiche la vie RÉELLE du Gardien")
	check(shell.boss_phase_text().length() > 0,
		"…et nomme la phase : « %s »" % shell.boss_phase_text())
	var before: float = shell.boss_bar_value()
	var hit: DamageEvent = DamageEvent.new()
	hit.team = &"player"
	hit.amount = 120.0
	boss.health().take_damage(hit)
	deadline = Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline and shell.boss_bar_value() >= before:
		await _tree().process_frame
	check(shell.boss_bar_value() < before,
		"un coup encaissé fait descendre la barre (%.0f → %.0f)"
		% [before, shell.boss_bar_value()])
	await _close(arena)


## §15.11 s'applique jusqu'à l'arène : on n'y enferme personne. La porte du
## sud rouvre sur l'antichambre — donc sur le feu de cuisine.
func test_the_arena_is_never_a_one_way_trap() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var door: SceneDoor = arena.get_node("DoorAntechamber") as SceneDoor
	check_not_null(door, "le seuil sud existe")
	check_equal(door.target_scene, ANTE, "il ramène à l'antichambre")
	check_equal(String(door.spawn_tag), "antechamber_from_arena",
		"…devant son propre seuil, pas au spawn de la salle")
	check(ResourceLoader.exists(door.target_scene),
		"la scène cible existe pour de bon")
	await _close(arena)

	# Et symétriquement : l'antichambre a une porte VERS l'arène.
	var ante: Antechamber = await _open(ANTE) as Antechamber
	var to_arena: SceneDoor = ante.get_node("DoorArena") as SceneDoor
	check_not_null(to_arena, "l'antichambre ouvre sur l'arène")
	check_equal(to_arena.target_scene, ARENA, "elle mène bien à l'arène")
	check(ResourceLoader.exists(to_arena.target_scene), "…qui existe")
	await _close(ante)
