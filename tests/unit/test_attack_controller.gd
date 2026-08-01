## Contrat d'attaque (MASTER_SPEC §10.2, §10.6) — timing piloté à la main.
##
## §10.6 : « startup, actif, recovery, fenêtres de buffer et de combo » sont des
## données inspectables. Ces tests vérifient que l'exécution OBÉIT au contrat :
## la hitbox s'allume exactement pendant la fenêtre active, l'enchaînement ne
## part que dans la fenêtre de combo, le buffer expire. Delta injecté : les
## mesures sont exactes, aucun tick physique.
extends GateTestCase

const TICK: float = 1.0 / 60.0


## Contrôleur + hitbox réels, hors physique (aucune victime : on teste le timing,
## pas le contact — `test_combat_exchange.gd` fait l'autre moitié).
func _make() -> AttackControllerComponent:
	var root: Node = Node.new()
	var hitbox: HitboxComponent = HitboxComponent.new()
	hitbox.name = "Hitbox"
	root.add_child(hitbox)
	var controller: AttackControllerComponent = AttackControllerComponent.new()
	controller.name = "Attack"
	controller.attacks = [
		load("res://resources/combat/sword/light_1.tres"),
		load("res://resources/combat/sword/light_2.tres"),
		load("res://resources/combat/sword/light_3.tres"),
	]
	controller.hitbox_path = NodePath("../Hitbox")
	controller.base_damage = 12.0
	root.add_child(controller)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(root)
	return controller


func _dispose(controller: AttackControllerComponent) -> void:
	var root: Node = controller.get_parent()
	root.get_parent().remove_child(root)
	root.free()


func _hitbox(controller: AttackControllerComponent) -> HitboxComponent:
	return controller.get_node("../Hitbox") as HitboxComponent


## Avance de `seconds` par pas de tick.
func _step(controller: AttackControllerComponent, seconds: float) -> void:
	var steps: int = int(round(seconds / TICK))
	for i: int in range(steps):
		controller.update(TICK)


func test_the_hitbox_is_active_exactly_during_the_active_window() -> void:
	## §10.5 : un coup sans anticipation serait illisible ; §10.1 : la fenêtre
	## active est bornée. light_1 : startup 0,12 / actif 0,10 / recovery 0,30.
	var c: AttackControllerComponent = _make()
	check(c.try_attack(), "l'attaque doit partir depuis l'idle")
	check(not _hitbox(c).is_active(), "hitbox éteinte à l'instant du départ")

	_step(c, 0.06)   # milieu du startup
	check(not _hitbox(c).is_active(), "hitbox éteinte pendant l'anticipation")
	check_equal(c.phase(), AttackControllerComponent.Phase.STARTUP, "phase startup")

	_step(c, 0.10)   # t = 0,16 : dans la fenêtre active (0,12 → 0,22)
	check(_hitbox(c).is_active(), "hitbox allumée pendant la fenêtre active")
	check_equal(c.phase(), AttackControllerComponent.Phase.ACTIVE, "phase active")

	_step(c, 0.10)   # t = 0,26 : recovery
	check(not _hitbox(c).is_active(), "hitbox éteinte en recovery")
	check_equal(c.phase(), AttackControllerComponent.Phase.RECOVERY, "phase recovery")

	_step(c, 0.35)   # t = 0,61 : au-delà de la durée totale (0,52)
	check(not c.is_attacking(), "l'attaque doit être terminée")
	_dispose(c)


func test_a_buffered_press_chains_at_the_window_not_before() -> void:
	## §10.2 : l'appui mémorisé enchaîne DANS les derniers 25–35 % de la recovery,
	## jamais avant. light_1 : fenêtre à 0,12+0,10+0,30×0,70 = 0,43.
	var c: AttackControllerComponent = _make()
	var starts: Array[int] = []
	c.attack_started.connect(func(_d: AttackDefinition, i: int) -> void: starts.append(i))
	c.try_attack()

	_step(c, 0.30)   # recovery, avant la fenêtre
	check(not c.try_attack(), "l'appui avant la fenêtre est mémorisé, pas exécuté")
	_step(c, 0.06)   # t = 0,36 : toujours avant 0,43
	check_equal(c.combo_index(), 0, "aucun enchaînement avant la fenêtre")

	_step(c, 0.09)   # t = 0,45 : la fenêtre est ouverte, le buffer (0,15) est frais
	check_equal(c.combo_index(), 1, "l'enchaînement part à l'ouverture de la fenêtre")
	check_equal(starts.size(), 2, "deux départs d'attaque signalés")
	_dispose(c)


func test_an_early_press_expires_before_the_window() -> void:
	## §10.2 : le buffer dure 0,15 s. Un appui à t = 0,05 meurt à 0,20, bien avant
	## la fenêtre (0,43) : le coup 2 ne doit PAS partir. Sans ce test, un buffer
	## immortel transformerait tout double-clic nerveux en combo complet.
	var c: AttackControllerComponent = _make()
	c.try_attack()
	_step(c, 0.05)
	check(not c.try_attack(), "l'appui précoce est mémorisé")
	_step(c, 0.50)   # traverse fenêtre et fin d'attaque
	check(not c.is_attacking(), "l'attaque doit s'être terminée SANS enchaîner")
	check_equal(c.combo_index(), 0, "le combo est revenu à zéro")
	_dispose(c)


func test_a_press_after_the_window_opens_fires_immediately() -> void:
	## §10.6 : « action bufferisée valide part idéalement en un à deux ticks après
	## la première fenêtre légale ». Ici l'appui ARRIVE fenêtre déjà ouverte : il
	## part dans le même appel, zéro tick d'attente.
	var c: AttackControllerComponent = _make()
	c.try_attack()
	_step(c, 0.46)   # fenêtre ouverte (0,43), aucun appui encore
	check_equal(c.combo_index(), 0, "rien n'enchaîne sans appui")
	check(c.try_attack(), "l'appui en fenêtre ouverte part immédiatement")
	check_equal(c.combo_index(), 1, "coup 2 engagé")
	_dispose(c)


func test_the_chain_never_exceeds_three_and_restarts_from_zero() -> void:
	## §10.2 : « combo trois légères ». Il n'existe pas de quatrième maillon : le
	## troisième coup ne peut qu'aboutir — ou relancer un combo NEUF depuis zéro
	## si un appui est encore frais à sa fin (§10.6 : l'action bufferisée part à
	## la première fenêtre légale, qui est ici la fin du combo).
	var c: AttackControllerComponent = _make()
	var starts: Array[int] = []
	c.attack_started.connect(func(_d: AttackDefinition, i: int) -> void: starts.append(i))

	c.try_attack()                       # coup 1
	_step(c, 0.45)                       # fenêtre du coup 1 ouverte (0,43)
	check(c.try_attack(), "enchaînement vers le coup 2")
	_step(c, 0.45)                       # fenêtre du coup 2 ouverte (0,424)
	check(c.try_attack(), "enchaînement vers le coup 3")

	_step(c, 0.60)                       # coup 3 : fenêtre ouverte (0,575)…
	check(not c.try_attack(),
		"…mais il n'y a pas de quatrième maillon : l'appui est mémorisé, pas enchaîné")
	check_equal(c.combo_index(), 2, "toujours dans le troisième coup")

	_step(c, 0.15)                       # traverse la fin du coup 3 (0,71)
	check(c.is_attacking(), "l'appui resté frais relance un combo à la fin du dernier coup")
	check_equal(c.combo_index(), 0, "le combo relancé repart du premier coup")
	check_equal(starts, [0, 1, 2, 0] as Array[int],
		"jamais d'index 3 : la chaîne plafonne à trois, puis repart de zéro")

	c.cancel()
	_dispose(c)


func test_a_stale_press_does_not_restart_after_the_last_attack() -> void:
	## Le report de fin de combo obéit au MÊME buffer de 0,15 s : un appui posé
	## trop tôt dans le troisième coup est oublié, le combo se termine sans
	## relance. Sans cette borne, tout appui pendant le troisième coup relancerait
	## un combo — un martèlement involontaire.
	var c: AttackControllerComponent = _make()
	c.try_attack()
	_step(c, 0.45)
	c.try_attack()
	_step(c, 0.45)
	c.try_attack()                       # coup 3 engagé
	_step(c, 0.20)                       # t = 0,20 dans le coup 3
	check(not c.try_attack(), "appui mémorisé pendant le startup/actif du coup 3")
	_step(c, 0.60)                       # buffer mort à 0,35, fin du coup à 0,71
	check(not c.is_attacking(), "l'appui périmé ne relance rien : combo terminé")
	check_equal(c.combo_index(), 0, "retour à zéro")
	_dispose(c)


func test_cancel_kills_the_hitbox_and_resets() -> void:
	## §16.2 (généralisé) : une interruption coupe hitbox et timers. Le stagger de
	## C.2 appellera exactement ceci.
	var c: AttackControllerComponent = _make()
	c.try_attack()
	_step(c, 0.16)   # fenêtre active
	check(_hitbox(c).is_active(), "préalable : hitbox allumée")
	c.cancel()
	check(not _hitbox(c).is_active(), "cancel() éteint la hitbox")
	check(not c.is_attacking(), "cancel() rend l'idle")
	check_equal(c.combo_index(), 0, "combo remis à zéro")
	_dispose(c)


func test_definitions_match_the_spec_windows() -> void:
	## §10.2 fixe le buffer (0,15 s) et la fenêtre de combo (25–35 %). Épinglé
	## pour les trois coups — leçon de la revue du Gate B : une valeur de spec se
	## vérifie contre la SPEC, jamais contre le tuning qui la porte.
	for path: String in ["res://resources/combat/sword/light_1.tres",
			"res://resources/combat/sword/light_2.tres",
			"res://resources/combat/sword/light_3.tres"]:
		var def: AttackDefinition = load(path) as AttackDefinition
		check_not_null(def, path)
		if def == null:
			continue
		check_approx(def.input_buffer, 0.15, 0.001, "%s : buffer (§10.2)" % def.id)
		check(def.combo_window_fraction >= 0.25 and def.combo_window_fraction <= 0.35,
			"%s : fenêtre de combo hors §10.2 (25–35 %%) : %.2f"
			% [def.id, def.combo_window_fraction])
		check(def.startup > 0.0, "%s : un coup sans anticipation est illisible (§10.5)" % def.id)
		check(def.hit_stop >= 0.035 and def.hit_stop <= 0.055,
			"%s : hit-stop léger hors §10.2 (0,035–0,055 s) : %.3f" % [def.id, def.hit_stop])
