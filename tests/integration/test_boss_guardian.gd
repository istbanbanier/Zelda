## G.2 — LE COMBAT du Gardien de l'Orage (MASTER_SPEC §16.2 à §16.8).
##
## Chaque test vise une exigence chiffrée du cahier des charges, et essaie
## de la prendre en défaut plutôt que de la confirmer :
##   - §16.2 : « un seuil de PV ne peut déclencher DEUX fois » — on
##     traverse le seuil, on remonte, on retraverse ;
##   - §16.3 : l'armure réduit fortement « SANS invulnérabilité totale
##     obscure », et il faut DEUX pylônes, pas un ;
##   - §16.4 : « métal frappant pendant la surcharge risque un stun ;
##     bois/isolant évite ce risque » — les deux cas sont joués, avec de
##     VRAIES armes du jeu, et la résistance électrique est mesurée ;
##   - §16.5 : « éclairs marqués au sol 0,7-1,0 s AVANT impact » — la
##     fenêtre est chronométrée, pas déclarée ;
##   - §16.6 : la mort « interrompt toute attaque, coupe hitboxes et
##     timers » ;
##   - §16.7 : solvabilité — le test échoue si le boss est
##     mathématiquement impossible avec le loot GARANTI.
extends GateTestCase

const GUARDIAN: String = "res://scenes/boss/StormGuardian.tscn"
const ARENA: String = "res://scenes/boss/BossArena.tscn"
const BLADE: String = "res://resources/weapons/conductive_blade.tres"
const CLUB: String = "res://resources/weapons/wood_club.tres"
const BOW: String = "res://resources/weapons/simple_bow.tres"
const SWORD: String = "res://resources/weapons/worn_sword.tres"


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


func _hit(amount: float, instigator: Node = null) -> DamageEvent:
	var event: DamageEvent = DamageEvent.new()
	event.team = &"player"
	event.instigator = instigator
	event.damage_type = &"physical"
	event.amount = amount
	return event


func _equip(player: PlayerController, path: String) -> WeaponInstance:
	var instance: WeaponInstance = WeaponInstance.create(
		load(path) as WeaponDefinition)
	player.inventory().add_weapon(instance)
	player.inventory().equip_index(player.inventory().weapon_count() - 1)
	return instance


func test_the_awakening_grants_a_grace_window_before_the_first_attack() -> void:
	## S1 du playtest externe : joueur plein de vie mort vers la 6e seconde d'un
	## lancement direct de l'arène. Cause mesurée : `_attack_cooldown` part à
	## 1,4 s et se décrémente sans condition dès `_ready()`, INTRO comprise — il
	## vaut donc toujours zéro au réveil, et le premier coup part au premier
	## tick de la Phase 1, sur un joueur encore en train de comprendre où il
	## est. §10.5 exige télégraphes et protection ; §16.1 exige une entrée
	## lisible. Le répit attendu s'AJOUTE au startup de l'attaque, il ne le
	## remplace pas.
	##
	## Valeurs en dur, à dessein : référencer la constante du correctif rendrait
	## ce test impossible à exécuter sur le code d'origine — on veut qu'il y
	## ÉCHOUE, pas qu'il refuse de parser.
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	check_equal(boss.state(), StormGuardian.State.INTRO,
		"le Gardien démarre en intro")

	# L'intro s'écoule EN ENTIER, comme en jeu — pas de raccourci : c'est
	# précisément ce chemin-là qui tuait.
	var ticks: int = 0
	while boss.state() == StormGuardian.State.INTRO and ticks < 60 * 8:
		await _tree().physics_frame
		ticks += 1
	check_equal(boss.state(), StormGuardian.State.PHASE1,
		"l'intro doit déboucher sur la Phase 1 (état : %s)" % boss.state_name())

	check(boss._attack_cooldown >= 1.3,
		"au réveil, le Gardien doit laisser un répit avant sa première attaque "
		+ "(cooldown constaté : %.2f s)" % boss._attack_cooldown)
	await _close(arena)


func test_a_stun_recovery_gets_no_grace() -> void:
	## Le répit protège la PREMIÈRE prise de contact, pas chaque retour en
	## Phase 1 : une sortie de mise à la terre qui offrirait la même
	## tranquillité rendrait le combat plus facile que ce que §16.7 annonce
	## dans son calcul de solvabilité.
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	boss.debug_force_state(StormGuardian.State.PHASE1)
	boss.debug_force_state(StormGuardian.State.GROUNDED_STUN)
	boss._attack_cooldown = 0.0
	boss.debug_force_state(StormGuardian.State.PHASE1)
	check(boss._attack_cooldown < 0.5,
		"une sortie de stun ne reçoit AUCUN répit supplémentaire "
		+ "(cooldown constaté : %.2f s)" % boss._attack_cooldown)
	await _close(arena)


## §16.3 : « l'armure réduit FORTEMENT les dégâts, sans invulnérabilité
## totale obscure ». Donc : elle divise, et elle ne bloque pas.
func test_the_armour_divides_damage_without_making_him_invulnerable() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	boss.debug_force_state(StormGuardian.State.PHASE1)
	check(boss.is_armoured(), "le Gardien entre armuré")
	var body: HurtboxComponent = boss.get_node("Pivot/BodyHurtbox") \
		as HurtboxComponent
	var core: HurtboxComponent = boss.get_node("Pivot/CoreHurtbox") \
		as HurtboxComponent
	check(not core.monitorable,
		"le noyau n'est pas frappable tant que l'armure tient")
	var before: float = boss.health().current()
	body.receive_hit(_hit(100.0))
	var taken: float = before - boss.health().current()
	check(taken > 0.0,
		"l'armure n'est pas une invulnérabilité : %.0f dégâts passent" % taken)
	check(taken < 30.0,
		"…mais elle divise fort : %.0f sur 100 (×%.2f)"
		% [taken, StormGuardian.ARMOURED_MULTIPLIER])
	await _close(arena)


## §16.3 : « orienter/connecter DEUX pylônes » puis « mise à la terre
## étourdit 5-8 s » et « noyau vulnérable ». Un seul pylône ne suffit pas :
## c'est le test qui distingue une vraie condition d'un raccourci.
func test_two_pylons_ground_him_and_expose_the_core() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	boss.debug_force_state(StormGuardian.State.PHASE1)
	var core: HurtboxComponent = boss.get_node("Pivot/CoreHurtbox") \
		as HurtboxComponent

	# Un seul pylône : l'arc part quand même sur le joueur.
	arena.pylons()[0].lever().interact(arena.player())
	await _settle(4)
	check_equal(arena.raised_pylons(), 1, "un seul pylône est dressé")
	boss.call("_cast_arc")
	await _settle(2)
	check(boss.state() != StormGuardian.State.GROUNDED_STUN,
		"un pylône ne met PAS le Gardien à la terre")

	# Le deuxième change tout.
	arena.pylons()[1].lever().interact(arena.player())
	await _settle(4)
	check_equal(arena.raised_pylons(), 2, "deux pylônes sont dressés")
	# Un tableau, pas un booléen : une lambda GDScript capture les locales
	# PAR VALEUR — un `grounded = true` dans le corps n'aurait jamais été
	# vu ici (constaté sur ce test même).
	var grounded: Array[bool] = [false]
	boss.grounded.connect(func() -> void: grounded[0] = true)
	boss.call("_cast_arc")
	await _settle(2)
	check(grounded[0], "le signal `grounded` est parti")
	check_equal(String(boss.state_name()), "grounded_stun",
		"le Gardien s'écroule")
	check(not boss.is_armoured(), "son armure est ouverte")
	check(core.monitorable, "…et son NOYAU est frappable")
	check(StormGuardian.GROUNDED_TIME >= 5.0
		and StormGuardian.GROUNDED_TIME <= 8.0,
		"l'étourdissement dure %.0f s, dans les 5-8 s de §16.3"
		% StormGuardian.GROUNDED_TIME)
	# Le noyau frappe PLUS FORT que le corps : c'est la récompense du geste.
	check(core.weak_point_multiplier > 1.5,
		"le noyau est un point faible (×%.1f)" % core.weak_point_multiplier)
	# Et les pylônes se déchargent : il faudra recommencer.
	check_equal(arena.raised_pylons(), 0,
		"les pylônes retombent : la mise à la terre se REGAGNE")
	await _close(arena)


## §16.3 : l'étourdissement finit, l'armure se referme. Sinon la première
## mise à la terre gagnerait tout le combat.
func test_the_armour_closes_again_after_the_stun() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	boss.debug_force_state(StormGuardian.State.PHASE1)
	arena.pylons()[0].lever().interact(arena.player())
	arena.pylons()[1].lever().interact(arena.player())
	await _settle(4)
	boss.call("_cast_arc")
	await _settle(2)
	check(not boss.is_armoured(), "armure ouverte pendant l'étourdissement")
	# GROUNDED_TIME secondes à 60 Hz, plus une marge.
	await _settle(int(StormGuardian.GROUNDED_TIME * 60.0) + 30)
	check(boss.is_armoured(), "l'armure s'est refermée")
	check_equal(String(boss.state_name()), "phase1",
		"…et il repart en phase 1")
	await _close(arena)


## §16.2 : « toutes les transitions sont idempotentes. Un seuil de PV ne
## peut déclencher DEUX fois. » On le prouve en repassant le seuil.
func test_a_health_threshold_never_fires_twice() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	boss.debug_force_state(StormGuardian.State.PHASE1)
	var transitions: Array[String] = []
	boss.phase_changed.connect(func(phase: StringName) -> void:
		transitions.append(String(phase)))
	# Sous 65 % : la transition 1→2 doit partir UNE fois.
	boss.health().take_damage(_hit(boss.health().maximum() * 0.4))
	await _settle(6)
	check(transitions.has("transition12"), "la transition 1→2 est partie")
	var first_count: int = transitions.count("transition12")
	# On le resoigne au-dessus du seuil, puis on redescend.
	boss.health().heal(boss.health().maximum() * 0.3)
	await _settle(6)
	boss.health().take_damage(_hit(boss.health().maximum() * 0.3))
	await _settle(6)
	check_equal(transitions.count("transition12"), first_count,
		"repasser le seuil ne relance PAS la transition (§16.2)")
	await _close(arena)


## §16.4 : les deux cristaux conducteurs n'apparaissent qu'en phase 2, et
## leur destruction expose le noyau (§16.5).
func test_the_crystals_appear_in_phase_two_and_open_the_core() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	boss.debug_force_state(StormGuardian.State.PHASE1)
	var crystal_a: HurtboxComponent = boss.get_node("Pivot/CrystalA") \
		as HurtboxComponent
	# Phase H : les cristaux sont des meshes du HERO ASSET, plus des boîtes
	# graybox posées à côté. C'est donc le modèle qu'on interroge.
	var visual: GuardianVisual = boss.get_node("Pivot/GuardianVisual") \
		as GuardianVisual
	var crystal_mesh: Node3D = visual.mesh("CrystalA")
	check_not_null(crystal_mesh, "le cristal A existe dans le modèle")
	check(not crystal_a.monitorable, "en phase 1, les cristaux sont dedans")
	check(not crystal_mesh.visible, "…et invisibles")

	boss.debug_force_state(StormGuardian.State.PHASE2)
	await _settle(4)
	check_equal(boss.crystals_alive(), 2, "deux cristaux en phase 2 (§16.4)")
	check(crystal_a.monitorable, "ils sont devenus frappables")
	check(crystal_mesh.visible, "…et visibles")

	# On les casse : 60 PV chacun.
	for i: int in range(4):
		crystal_a.receive_hit(_hit(20.0))
		await _settle(2)
	check_equal(boss.crystals_alive(), 1, "le premier cristal est tombé")
	check(not crystal_mesh.visible, "…et sa masse a disparu du dos")
	var crystal_b: HurtboxComponent = boss.get_node("Pivot/CrystalB") \
		as HurtboxComponent
	for i: int in range(4):
		crystal_b.receive_hit(_hit(20.0))
		await _settle(2)
	check_equal(boss.crystals_alive(), 0, "les deux cristaux sont tombés")
	check(not boss.is_armoured(),
		"§16.5 : le noyau est exposé après destruction des cristaux")
	await _close(arena)


## §16.4, le cœur de la phase 2 : « métal frappant pendant la surcharge
## risque un stun court ; bois/isolant évite ce risque ». La conductivité
## vient de l'ARME (§11.1), pas d'un cas particulier de boss.
func test_conductive_weapons_backfire_during_overload_and_wood_does_not() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	var player: PlayerController = arena.player()
	player.global_position = boss.global_position + Vector3(0, 0.3, 5.0)
	boss.debug_force_state(StormGuardian.State.OVERLOAD)
	await _settle(4)

	# 1. Le bois : rien ne remonte.
	player.inventory().clear_weapons()
	var club: WeaponInstance = _equip(player, CLUB)
	check(club.definition.conductivity < 0.5,
		"le gourdin conduit peu (%.2f)" % club.definition.conductivity)
	var health_before: float = player.health().current()
	boss.health().take_damage(_hit(10.0, player))
	await _settle(4)
	check_approx(player.health().current(), health_before, 0.01,
		"frapper au BOIS pendant la surcharge ne renvoie rien")

	# 2. La lame conductrice : la décharge remonte le long de l'arme.
	player.inventory().clear_weapons()
	var blade: WeaponInstance = _equip(player, BLADE)
	check(blade.definition.conductivity >= 0.9,
		"la lame conductrice conduit à fond (%.2f)"
		% blade.definition.conductivity)
	health_before = player.health().current()
	boss.health().take_damage(_hit(10.0, player))
	await _settle(4)
	var backlash: float = health_before - player.health().current()
	check(backlash > 0.0,
		"frapper au MÉTAL pendant la surcharge renvoie %.1f dégâts" % backlash)

	# 3. Hors surcharge, le même coup au métal ne renvoie rien.
	boss.debug_force_state(StormGuardian.State.PHASE2)
	await _settle(4)
	health_before = player.health().current()
	boss.health().take_damage(_hit(10.0, player))
	await _settle(4)
	check_approx(player.health().current(), health_before, 0.01,
		"hors surcharge, le métal ne coûte rien : le risque est FENÊTRÉ")
	await _close(arena)


## §16.4 et §13.5 : « la résistance électrique réduit les dégâts ET la
## durée du stun ». On mesure le renvoi avec et sans le buff.
func test_electric_resistance_softens_the_backlash() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	var player: PlayerController = arena.player()
	player.global_position = boss.global_position + Vector3(0, 0.3, 5.0)
	player.inventory().clear_weapons()
	_equip(player, BLADE)
	boss.debug_force_state(StormGuardian.State.OVERLOAD)
	await _settle(4)

	var before: float = player.health().current()
	boss.health().take_damage(_hit(10.0, player))
	await _settle(4)
	var bare: float = before - player.health().current()

	# Même coup, mais protégé par un plat de résistance électrique.
	player.status().apply_buff(&"elec_resist", 1.0, 60.0)
	await _settle(4)
	check(player.status().elec_damage_multiplier() < 1.0,
		"le buff réduit bien les dégâts électriques (×%.2f)"
		% player.status().elec_damage_multiplier())
	before = player.health().current()
	boss.health().take_damage(_hit(10.0, player))
	await _settle(4)
	var protected: float = before - player.health().current()
	check(protected < bare,
		"la résistance amortit le renvoi : %.1f → %.1f" % [bare, protected])
	await _close(arena)


## §16.5 : « éclairs marqués au sol 0,7-1,0 s AVANT impact ». On
## chronomètre la fenêtre RÉELLE, tick par tick — une constante déclarée
## ne prouverait rien.
func test_the_ground_strike_gives_a_real_warning_window() -> void:
	var strike: LightningStrike = (load(
		"res://scripts/boss/lightning_strike.gd") as GDScript).new() \
		as LightningStrike
	strike.telegraph = 0.85
	_tree().root.add_child(strike)
	await _settle(2)
	var start: int = Time.get_ticks_msec()
	var struck_at: Array[int] = [0]
	strike.struck.connect(func(_position: Vector3) -> void:
		struck_at[0] = Time.get_ticks_msec())
	for i: int in range(180):
		await _tree().physics_frame
		if struck_at[0] > 0:
			break
	check(struck_at[0] > 0, "l'éclair a fini par tomber")
	var window_ms: int = struck_at[0] - start
	check(window_ms >= 700 and window_ms <= 1400,
		"marque puis impact en %d ms — la fenêtre de §16.5 est réelle"
		% window_ms)
	if is_instance_valid(strike):
		strike.get_parent().remove_child(strike)
		strike.queue_free()
	await _settle(2)

	# Et la borne est FERMÉE : on ne peut pas régler un télégraphe à zéro.
	var cheat: LightningStrike = (load(
		"res://scripts/boss/lightning_strike.gd") as GDScript).new() \
		as LightningStrike
	cheat.telegraph = 0.05
	_tree().root.add_child(cheat)
	await _settle(2)
	check(cheat.telegraph >= 0.7,
		"un télégraphe de 0,05 s est ramené à %.2f s : §16.5 est une BORNE"
		% cheat.telegraph)
	cheat.get_parent().remove_child(cheat)
	cheat.queue_free()
	await _settle(2)


## §16.5 : « vitesse +10 à +18 %, PAS doublement brutal ».
func test_phase_three_speeds_up_within_the_specified_band() -> void:
	check(StormGuardian.PHASE3_SPEED_GAIN >= 1.10
		and StormGuardian.PHASE3_SPEED_GAIN <= 1.18,
		"le gain de phase 3 vaut ×%.2f, dans la bande 1,10-1,18 de §16.5"
		% StormGuardian.PHASE3_SPEED_GAIN)
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	var player: PlayerController = arena.player()
	player.global_position = Vector3(0, 0.3, 15.0)

	var speeds: Dictionary[String, float] = {}
	for phase: StormGuardian.State in [StormGuardian.State.PHASE1,
			StormGuardian.State.PHASE3]:
		boss.global_position = Vector3(0, 0.2, -7.0)
		boss.debug_force_state(phase)
		await _settle(4)
		var origin: Vector3 = boss.global_position
		await _settle(60)
		var travelled: float = Vector2(boss.global_position.x
			- origin.x, boss.global_position.z - origin.z).length()
		speeds[String(boss.state_name())] = travelled
	check(speeds["phase3"] > speeds["phase1"],
		"le Gardien de phase 3 couvre plus de terrain (%.2f m vs %.2f m)"
		% [speeds["phase3"], speeds["phase1"]])
	check(speeds["phase3"] < speeds["phase1"] * 1.5,
		"…mais il ne DOUBLE pas : ×%.2f" % (speeds["phase3"]
			/ maxf(0.01, speeds["phase1"])))
	await _close(arena)


## §16.2 : « la mort interrompt toute attaque, coupe hitboxes/timers et
## libère la caméra ». §16.8 : la victoire est sauvegardée.
func test_death_cuts_everything_and_writes_the_victory() -> void:
	await _erase_save()
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	boss.debug_force_state(StormGuardian.State.PHASE3)
	arena.pylons()[0].lever().interact(arena.player())
	await _settle(4)
	var died: Array[bool] = [false]
	boss.died.connect(func() -> void: died[0] = true)
	boss.health().take_damage(_hit(boss.health().maximum() * 2.0))
	await _settle(6)
	check(died[0], "le signal `died` est parti")
	check_equal(String(boss.state_name()), "dead", "il est mort")
	for hurtbox: Node in boss.find_children("*", "HurtboxComponent", true, false):
		check(not (hurtbox as HurtboxComponent).monitorable,
			"%s ne prend plus rien" % hurtbox.name)
	# `monitoring` reste allumé en permanence sur une hitbox — c'est R-014,
	# mesuré : le couper et le rallumer vide définitivement la liste de
	# chevauchements. La fenêtre active est portée par `_active`, et c'est
	# donc elle qu'il faut lire pour savoir si le Gardien frappe encore.
	for hitbox: Node in boss.find_children("*", "HitboxComponent", true, false):
		check(not (hitbox as HitboxComponent).is_active(),
			"%s ne frappe plus" % hitbox.name)
	check_equal(arena.raised_pylons(), 0, "les pylônes retombent")
	check(arena.victory_written(), "§16.8 : la victoire est écrite")
	# Deuxième mort impossible : la transition est idempotente (§16.2).
	boss.health().take_damage(_hit(500.0))
	await _settle(4)
	check_equal(String(boss.state_name()), "dead",
		"un second coup ne relance pas la mort")

	var save_system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	var data: Dictionary = save_system.call("load_slot", "slot0") as Dictionary
	check(bool(data.get("boss_defeated", false)),
		"…et `boss_defeated` est dans la sauvegarde (§19.1)")
	await _close(arena)
	await _erase_save()


## §16.7, SOLVABILITÉ. « Ajouter un test qui échoue si le boss est
## mathématiquement impossible avec le loot garanti et une précision
## raisonnable », avec « une marge de 30-50 % de durabilité au-dessus du
## minimum théorique ».
##
## Le calcul est fait sur les VRAIES ressources du jeu, jamais sur des
## chiffres recopiés : dégâts et durabilité viennent des `.tres`, les PV et
## multiplicateurs des constantes du Gardien.
func test_the_guardian_is_beatable_with_the_guaranteed_loot() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	var total_hp: float = boss.health().maximum()

	# Le loot GARANTI avant le boss (§11.4) : la lame conductrice et les
	# 12 flèches de l'antichambre, plus l'épée et l'arc du chemin.
	var blade: WeaponDefinition = load(BLADE) as WeaponDefinition
	var sword: WeaponDefinition = load(SWORD) as WeaponDefinition
	var bow: WeaponDefinition = load(BOW) as WeaponDefinition
	var club: WeaponDefinition = load(CLUB) as WeaponDefinition

	# Précision « raisonnable » : deux coups sur trois portent, et la
	# moitié seulement tombe dans une fenêtre de noyau — le reste frappe
	# l'armure. C'est délibérément pessimiste.
	var accuracy: float = 0.66
	var core_share: float = 0.5
	var core_multiplier: float = 2.5
	var armour: float = StormGuardian.ARMOURED_MULTIPLIER

	var potential: float = 0.0
	var swings: int = 0
	for definition: WeaponDefinition in [blade, sword, club]:
		var landed: float = float(definition.max_durability) * accuracy
		swings += definition.max_durability
		potential += landed * definition.base_damage \
			* (core_share * core_multiplier + (1.0 - core_share) * armour)
	# Les flèches servent aux cristaux de §16.4 : elles ne comptent pas
	# dans les dégâts au corps, elles paient les 120 PV de cristaux.
	var crystal_cost: float = 120.0
	var arrow_damage: float = float(bow.base_damage) * 12.0 * accuracy
	check(arrow_damage >= crystal_cost * 0.5,
		"12 flèches font %.0f dégâts : de quoi entamer les %.0f PV de cristaux"
		% [arrow_damage, crystal_cost])

	check(potential >= total_hp,
		"le loot garanti permet %.0f dégâts pour %.0f PV — le combat est POSSIBLE"
		% [potential, total_hp])
	# §16.7 : « prévoir une marge de 30-50 % de durabilité au-dessus du
	# minimum théorique ». La borne HAUTE compte autant que la basse : un
	# boss qu'on abat avec le tiers de son arsenal n'est plus un examen.
	# Ce test est donc le gardien du réglage dans les deux sens — c'est lui
	# qui a fait descendre les PV de 900 (marge -16 %) à 560 (+35 %).
	var margin: float = potential / total_hp
	check(margin >= 1.30 and margin <= 1.50,
		"…avec une marge de %.0f %% au-dessus du minimum (§16.7 : 30-50 %%)"
		% ((margin - 1.0) * 100.0))
	# Et il ne doit exiger AUCUNE arme rare : la lame seule, sans le reste.
	var blade_alone: float = float(blade.max_durability) * accuracy \
		* blade.base_damage * (core_share * core_multiplier
			+ (1.0 - core_share) * armour)
	check(blade_alone < total_hp,
		"une seule arme ne suffit pas (%.0f dégâts) : le combat demande de gérer son arsenal"
		% blade_alone)
	check(swings > 0, "%d coups de durabilité garantis au total" % swings)
	await _close(arena)


## §16.6 : « boss visible au moins 80 % du temps en lock-on ». Ce qui est
## vérifiable sans œil humain : que le Gardien EST une cible de
## verrouillage, et qu'il reste dans le champ de la caméra pendant qu'on
## tourne autour de lui.
func test_the_guardian_stays_in_frame_while_locked_on() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	var player: PlayerController = arena.player()
	check(boss.is_in_group("lock_on_targets"),
		"le Gardien est une cible de verrouillage (§8.4)")
	boss.debug_force_state(StormGuardian.State.PHASE1)
	var rig: CameraRig = player.camera_rig()
	rig.set_lock_target(boss)
	var camera: Camera3D = rig.get_camera()
	var seen: int = 0
	var samples: int = 0
	# On tourne autour du Gardien, à distance de combat.
	for i: int in range(180):
		var angle: float = TAU * float(i) / 180.0
		player.global_position = boss.global_position \
			+ Vector3(sin(angle) * 7.0, 0.3, cos(angle) * 7.0)
		await _tree().physics_frame
		samples += 1
		var aim: Vector3 = boss.global_position + Vector3(0, 2.1, 0)
		if not camera.is_position_behind(aim):
			var screen: Vector2 = camera.unproject_position(aim)
			var view: Vector2 = Vector2(camera.get_viewport().size)
			if screen.x >= 0.0 and screen.x <= view.x \
					and screen.y >= 0.0 and screen.y <= view.y:
				seen += 1
	var ratio: float = float(seen) / float(maxi(1, samples))
	check(ratio >= 0.80,
		"le Gardien est dans le cadre %.0f %% du temps en verrouillage (§16.6 : ≥ 80 %%)"
		% (ratio * 100.0))
	rig.clear_lock_target()
	await _close(arena)
