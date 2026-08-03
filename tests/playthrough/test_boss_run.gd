## G.4 — LE GARDIEN TOMBE, avec le loot garanti et rien d'autre.
##
## Critère de sortie du Gate G (§22) : « run complet graybox sans debug ».
## Ce fichier en couvre la dernière jambe — antichambre → arène → victoire —
## et il la joue plutôt qu'il ne la calcule.
##
## Ce qui est RÉEL ici :
##   - l'équipement vient du coffre garanti de l'antichambre (§11.4), ouvert
##     par le geste du joueur ; aucune arme n'est ajoutée à la main ;
##   - le passage d'une scène à l'autre passe par la sauvegarde commune ;
##   - la mise à la terre est obtenue en dressant DEUX pylônes par leurs
##     leviers, puis en laissant le Gardien décider LUI-MÊME de décharger ;
##   - chaque coup traverse `DamageFormula` puis `HurtboxComponent`, avec
##     l'armure, le point faible et la durabilité réels ;
##   - une arme cassée est retirée et remplacée, comme en jeu.
##
## Ce qui ne l'est PAS, et c'est dit :
##   - le balayage de hitbox n'est pas simulé : le contact est postulé, la
##     visée d'un joueur ne l'est jamais. C'est pourquoi le test se donne
##     une précision de deux coups sur trois plutôt que parfaite ;
##   - la jambe vallée→donjon est prouvée ailleurs (`test_dungeon_run.gd`)
##     et n'est pas rejouée ici : la refaire coûterait des minutes de
##     simulation sans rien démontrer de neuf ;
##   - la DURÉE d'une première victoire (§16.1 : 4-7 min) est un temps
##     HUMAIN. Aucun chiffre de ce fichier ne la mesure.
extends GateTestCase

const ANTE: String = "res://scenes/dungeon/rooms/Antechamber.tscn"
const ARENA: String = "res://scenes/boss/BossArena.tscn"
## Deux coups sur trois portent — le troisième part dans le vide, dans un
## mur, ou pendant une esquive. Délibérément pessimiste.
const MISS_EVERY: int = 3


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


## Un coup, tel que la hitbox le porterait : formule de §10.3 côté
## attaquant, point faible déclaré par la hurtbox, puis un point de
## durabilité. Retourne les dégâts RÉELLEMENT encaissés.
func _swing(player: PlayerController, hurtbox: HurtboxComponent,
		boss: StormGuardian) -> float:
	var weapon: WeaponInstance = player.inventory().equipped()
	if weapon == null or weapon.definition == null:
		return 0.0
	var before: float = boss.health().current()
	var event: DamageEvent = DamageEvent.new()
	event.team = &"player"
	event.instigator = player
	event.damage_type = &"melee"
	event.element = weapon.definition.id
	event.amount = DamageFormula.compute(weapon.definition.base_damage,
		hurtbox.weak_point_multiplier)
	hurtbox.receive_hit(event)
	# §11.2 : la durabilité ne descend QUE quand on touche.
	weapon.current_durability -= 1
	if weapon.current_durability <= 0:
		player.inventory().remove_weapon(weapon)
		if player.inventory().weapon_count() > 0:
			player.inventory().equip_index(0)
	return before - boss.health().current()


## Dresse deux pylônes par leurs leviers, puis laisse le Gardien décider :
## on n'appelle PAS `_ground_out()`. Retourne vrai s'il s'est écroulé.
func _earn_a_grounding(arena: BossArena, boss: StormGuardian) -> bool:
	for pylon: GroundingPylon in arena.pylons():
		if arena.raised_pylons() >= 2:
			break
		if not pylon.is_raised():
			pylon.lever().interact(arena.player())
	await _settle(4)
	if arena.raised_pylons() < 2:
		return false
	# Le joueur se place dans la portée d'arc, hors du corps à corps : c'est
	# là que le Gardien choisit la décharge — celle qui part dans la terre.
	arena.player().global_position = boss.global_position \
		+ Vector3(0, 0.3, 9.0)
	for i: int in range(420):
		await _tree().physics_frame
		if boss.state() == StormGuardian.State.GROUNDED_STUN:
			return true
	return false


func test_the_guardian_falls_to_the_loot_the_game_guarantees() -> void:
	await _erase_save()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	game_state.call("set_pending_spawn", &"antechamber_from_hall")

	# --- Antichambre : on prend ce que le jeu GARANTIT, et rien de plus.
	var ante: Antechamber = await _open(ANTE) as Antechamber
	check(ante.checkpoint_written(), "le checkpoint de l'antichambre est posé")
	check(ante.chest().interact(ante.player()),
		"le coffre garanti s'ouvre (§11.4)")
	await _settle(4)
	ante.call("_write_checkpoint")
	var carried: int = ante.player().inventory().weapon_count()
	check(carried >= 1, "%d arme(s) en poche" % carried)
	await _close(ante)

	# --- Arène : le checkpoint est relu, on entre avec cet équipement.
	game_state.call("set_pending_spawn", &"arena_from_antechamber")
	var arena: BossArena = await _open(ARENA) as BossArena
	arena.auto_show_victory = false
	var boss: StormGuardian = arena.boss()
	var player: PlayerController = arena.player()
	check(arena.checkpoint_restored(), "l'arène a relu le checkpoint")
	check_equal(player.inventory().weapon_count(), carried,
		"le même arsenal qu'à la sortie de l'antichambre")

	var body: HurtboxComponent = boss.get_node("Pivot/BodyHurtbox") \
		as HurtboxComponent
	var core: HurtboxComponent = boss.get_node("Pivot/CoreHurtbox") \
		as HurtboxComponent

	# On laisse l'éveil se terminer : §16.1, on ne frappe pas une statue.
	for i: int in range(400):
		await _tree().physics_frame
		if boss.state() != StormGuardian.State.INTRO:
			break
	check(boss.state() != StormGuardian.State.INTRO,
		"le Gardien s'est éveillé et le combat commence")

	# --- Le combat. À chaque tour, le joueur fait ce qu'un joueur ferait :
	# il frappe ce qui est OUVERT, casse les cristaux quand ils sortent, et
	# va chercher une mise à la terre quand plus rien n'est offert.
	#
	# Un coup ne porte que sur une hurtbox `monitorable` : c'est ce qu'un
	# balayage de hitbox trouverait. Frapper un noyau fermé ne fait rien —
	# et c'est exactement ce que §16.3 et §16.5 veulent imposer.
	var crystals: Array[HurtboxComponent] = [
		boss.get_node("Pivot/CrystalA") as HurtboxComponent,
		boss.get_node("Pivot/CrystalB") as HurtboxComponent,
	]
	var groundings: int = 0
	var swings: int = 0
	var core_hits: int = 0
	var crystal_hits: int = 0
	var broken: int = 0
	var rounds: int = 0
	var phases_seen: Array[String] = []
	while not boss.health().is_dead() and rounds < 220:
		rounds += 1
		if player.inventory().weapon_count() == 0:
			break
		var phase: String = String(boss.state_name())
		if not phases_seen.has(phase):
			phases_seen.append(phase)

		var target: HurtboxComponent = null
		if core.monitorable:
			target = core
		else:
			for crystal: HurtboxComponent in crystals:
				if crystal.monitorable:
					target = crystal
					break
		if target == null:
			# Rien d'ouvert : on va chercher la fenêtre par les pylônes.
			if await _earn_a_grounding(arena, boss):
				groundings += 1
				continue
			# Faute de mieux, on cogne l'armure. Ça avance peu — c'est
			# précisément ce que §16.3 veut faire ressentir.
			target = body

		swings += 1
		if swings % MISS_EVERY == 0:
			await _settle(14)
			continue
		var weapons_before: int = player.inventory().weapon_count()
		var dealt: float = _swing(player, target, boss)
		if player.inventory().weapon_count() < weapons_before:
			broken += 1
		if target == core and dealt > 0.0:
			core_hits += 1
		elif target != body and target != core:
			crystal_hits += 1
		await _settle(14)

	# Le runner ne montre pas les messages des assertions réussies ; ce run
	# est une PREUVE, ses chiffres doivent donc atterrir dans le journal.
	print("[run boss] %d mise(s) à la terre · %d coups (%d noyau, %d cristal) · "
		% [groundings, swings, core_hits, crystal_hits]
		+ "%d arme(s) brisée(s) · phases : %s · vie restante %.0f/%.0f"
		% [broken, ", ".join(phases_seen), boss.health().current(),
			boss.health().maximum()])
	check(groundings >= 1,
		"%d mise(s) à la terre obtenue(s) par les leviers, sans forcer d'état"
		% groundings)
	check(core_hits > 0, "%d coups portés au noyau découvert" % core_hits)
	check(crystal_hits > 0,
		"%d coups portés aux cristaux de la phase 2 (§16.4)" % crystal_hits)
	# Le vrai enjeu du Gate G : le combat TRAVERSE ses trois phases. Un
	# Gardien tué pendant sa première fenêtre de noyau — ce que faisait la
	# première version — n'aurait montré ni §16.4 ni §16.5.
	for expected: String in ["phase1", "phase2", "phase3"]:
		check(phases_seen.has(expected),
			"le combat est passé par %s (vu : %s)"
			% [expected, ", ".join(phases_seen)])
	check(boss.health().is_dead(),
		"le Gardien est tombé — vie restante %.0f sur %.0f, en %d coups (%d arme(s) brisée(s))"
		% [boss.health().current(), boss.health().maximum(), swings, broken])
	check_equal(String(boss.state_name()), "dead", "…et son état le dit")
	await _settle(6)
	check(arena.victory_written(), "§16.8 : la victoire est écrite")
	check_not_null(arena.final_chest(), "…et le coffre final est là")

	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	var data: Dictionary = save_system.call("load_slot", "slot0") as Dictionary
	check(bool(data.get("boss_defeated", false)),
		"`boss_defeated` a traversé jusqu'au fichier (§19.1)")
	await _close(arena)
	await _erase_save()
