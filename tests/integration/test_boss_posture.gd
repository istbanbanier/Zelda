## P2-5 tranche 2 — le boss porte la POSTURE (P2 §7.4, §10.2) : la rupture
## expose le noyau. « Réponse principale claire, alternative plus lente par
## posture » — la terre reste le chemin roi, l'agression au brise-garde en
## devient un second, honnête et plus lent. Fail-first : écrit avant
## l'implémentation.
##
## Contrats : seuls les coups à INTENTION brise-garde (posture_damage > 0)
## nourrissent la jauge, et seulement armure intacte en phase de combat ;
## la rupture écroule le Gardien sur une fenêtre PLUS COURTE que la mise à
## la terre ; l'intro et la fenêtre déjà ouverte ne nourrissent rien ; la
## mise à la terre remet la jauge à neuf ; la fin de fenêtre referme
## l'armure et la jauge repart pleine.
extends GateTestCase

const ARENA: String = "res://scenes/boss/BossArena.tscn"


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


func _break_hit(posture: float, amount: float = 4.0) -> DamageEvent:
	var event: DamageEvent = DamageEvent.new()
	event.team = &"player"
	event.damage_type = &"physical"
	event.amount = amount
	event.posture_damage = posture
	return event


func _posture_of(boss: StormGuardian) -> PostureComponent:
	return boss.get_node_or_null("PostureComponent") as PostureComponent


func test_posture_rupture_opens_a_short_core_window() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	var posture: PostureComponent = _posture_of(boss)
	check(posture != null, "le Gardien porte le composant de posture PARTAGÉ")
	boss.debug_force_state(StormGuardian.State.PHASE1)
	var body: HurtboxComponent = boss.get_node("Pivot/BodyHurtbox") \
		as HurtboxComponent
	# Trois lourdes de hache (posture 12) : la voie de l'agression.
	for i: int in range(3):
		body.receive_hit(_break_hit(12.0))
		await _settle(2)
	check_equal(boss.state(), StormGuardian.State.GROUNDED_STUN,
		"la rupture de posture ÉCROULE le Gardien (état : %s)"
		% boss.state_name())
	check(not boss.is_armoured(), "…et le noyau est nu")
	# §10.2 : « alternative plus lente » — fenêtre PLUS COURTE que les 6 s
	# de la mise à la terre. Valeurs en dur, à dessein (fail-first).
	check(boss._timer > 3.0 and boss._timer < 4.0,
		"fenêtre de posture courte (%.2f s, attendu ~3,5)" % boss._timer)
	await _close(arena)


func test_hits_without_break_intent_leave_the_gauge_alone() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	var posture: PostureComponent = _posture_of(boss)
	check(posture != null, "composant présent")
	boss.debug_force_state(StormGuardian.State.PHASE1)
	var body: HurtboxComponent = boss.get_node("Pivot/BodyHurtbox") \
		as HurtboxComponent
	for i: int in range(6):
		body.receive_hit(_break_hit(0.0, 20.0))
		await _settle(1)
	if posture != null:
		check_equal(posture.current(), posture.max_posture,
			"les coups SANS intention brise-garde ne touchent pas la jauge")
	check_equal(boss.state(), StormGuardian.State.PHASE1,
		"…et le Gardien tient debout")
	await _close(arena)


func test_intro_and_open_window_feed_nothing() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	var posture: PostureComponent = _posture_of(boss)
	check(posture != null, "composant présent")
	var body: HurtboxComponent = boss.get_node("Pivot/BodyHurtbox") \
		as HurtboxComponent
	# INTRO : §16.1 protège l'éveil — rien ne nourrit la jauge.
	check_equal(boss.state(), StormGuardian.State.INTRO, "éveil en cours")
	body.receive_hit(_break_hit(12.0))
	await _settle(1)
	if posture != null:
		check_equal(posture.current(), posture.max_posture,
			"l'intro ne nourrit pas la posture")
	# Rupture en phase 1, puis frappes PENDANT la fenêtre : rien ne bouge.
	boss.debug_force_state(StormGuardian.State.PHASE1)
	for i: int in range(3):
		body.receive_hit(_break_hit(12.0))
		await _settle(1)
	check_equal(boss.state(), StormGuardian.State.GROUNDED_STUN,
		"fenêtre ouverte")
	for i: int in range(2):
		body.receive_hit(_break_hit(12.0))
		await _settle(1)
	check_equal(boss.state(), StormGuardian.State.GROUNDED_STUN,
		"une fenêtre ouverte ne se ré-ouvre pas")
	if posture != null:
		check_equal(posture.current(), posture.max_posture,
			"…et la jauge, remise à neuf à la rupture, n'a pas bougé")
	await _close(arena)


func test_grounding_resets_the_gauge() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	var posture: PostureComponent = _posture_of(boss)
	check(posture != null, "composant présent")
	boss.debug_force_state(StormGuardian.State.PHASE1)
	var body: HurtboxComponent = boss.get_node("Pivot/BodyHurtbox") \
		as HurtboxComponent
	body.receive_hit(_break_hit(12.0))
	await _settle(1)
	if posture != null:
		check(posture.current() < posture.max_posture,
			"la jauge a été entamée (%.1f)" % posture.current())
	# La mise à la terre — le chemin ROI — remet la jauge à neuf : les deux
	# chemins ne s'additionnent pas en double peine pour le Gardien.
	boss._ground_out()
	await _settle(1)
	check_equal(boss.state(), StormGuardian.State.GROUNDED_STUN,
		"mise à la terre effective")
	if posture != null:
		check_equal(posture.current(), posture.max_posture,
			"…et la jauge repart pleine")
	await _close(arena)


func test_window_expiry_restores_armour_and_a_full_gauge() -> void:
	var arena: BossArena = await _open(ARENA) as BossArena
	var boss: StormGuardian = arena.boss()
	var posture: PostureComponent = _posture_of(boss)
	check(posture != null, "composant présent")
	boss.debug_force_state(StormGuardian.State.PHASE1)
	var body: HurtboxComponent = boss.get_node("Pivot/BodyHurtbox") \
		as HurtboxComponent
	for i: int in range(3):
		body.receive_hit(_break_hit(12.0))
		await _settle(1)
	check_equal(boss.state(), StormGuardian.State.GROUNDED_STUN,
		"fenêtre ouverte")
	# La fenêtre s'écoule EN ENTIER (~3,5 s) : le combat reprend, armure
	# refermée, jauge pleine — pas de noyau nu perpétuel (§16.3).
	var ticks: int = 0
	while boss.state() == StormGuardian.State.GROUNDED_STUN and ticks < 300:
		await _tree().physics_frame
		ticks += 1
	check_equal(boss.state(), StormGuardian.State.PHASE1,
		"santé pleine : retour en phase 1 (état : %s)" % boss.state_name())
	check(boss.is_armoured(), "l'armure est refermée")
	if posture != null:
		check_equal(posture.current(), posture.max_posture,
			"la jauge est pleine pour la prochaine tentative")
	await _close(arena)
