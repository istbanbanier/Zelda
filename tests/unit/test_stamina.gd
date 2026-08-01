## Endurance (MASTER_SPEC §9.1) — logique pure, delta piloté à la main.
##
## Aucun tick physique ici : le composant reçoit son `delta` directement, donc les
## mesures sont exactes et non tributaires du cadencement. L'interaction réelle
## avec la locomotion est vérifiée séparément dans `test_locomotion.gd`.
extends GateTestCase

const TICK: float = 1.0 / 60.0


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Construit un composant réellement entré dans l'arbre : `_ready()` doit tourner,
## c'est lui qui remplit la jauge. Un composant instancié hors arbre partirait à
## zéro et tous les tests mesureraient un objet qui n'existe pas en jeu.
func _make(overrides: Dictionary = {}) -> StaminaComponent:
	var tuning: StaminaTuning = load("res://resources/tuning/stamina_default.tres").duplicate()
	for key: String in overrides:
		tuning.set(key, overrides[key])
	var node: StaminaComponent = StaminaComponent.new()
	node.tuning = tuning
	_tree().root.add_child(node)
	return node


func _dispose(node: StaminaComponent) -> void:
	if node != null and is_instance_valid(node):
		node.get_parent().remove_child(node)
		node.queue_free()


## Applique `seconds` d'effort continu au taux donné, par pas de tick.
func _sustain_for(node: StaminaComponent, rate: float, seconds: float) -> void:
	var steps: int = int(round(seconds / TICK))
	for i: int in range(steps):
		node.try_sustain(rate, TICK)
		node.update(TICK)


## Laisse s'écouler `seconds` sans aucun effort.
func _idle_for(node: StaminaComponent, seconds: float) -> void:
	var steps: int = int(round(seconds / TICK))
	for i: int in range(steps):
		node.update(TICK)


## Sprinte jusqu'à l'épuisement et s'arrête **là**, sans le dépasser. Nécessaire
## parce qu'un effort maintenu au-delà laisse la jauge repartir : mesurer « après
## 15 s de sprint » ne mesurerait pas l'état d'épuisement mais un cycle plus tard.
## Retourne le nombre de ticks écoulés ; `-1` si l'épuisement n'est pas survenu.
func _drain_until_exhausted(node: StaminaComponent, rate: float, max_seconds: float) -> int:
	var steps: int = int(round(max_seconds / TICK))
	for i: int in range(steps):
		node.try_sustain(rate, TICK)
		node.update(TICK)
		if node.is_exhausted():
			return i + 1
	return -1


func test_starts_full() -> void:
	var s: StaminaComponent = _make()
	check_approx(s.current(), 100.0, 0.001, "réserve au démarrage")
	check_approx(s.ratio(), 1.0, 0.001, "fraction au démarrage")
	check(not s.is_exhausted(), "un joueur qui vient d'apparaître n'est pas épuisé")
	_dispose(s)


func test_sustained_effort_drains_at_the_declared_rate() -> void:
	## §9.1 : sprint 12/s. Une seconde d'effort doit coûter exactement 12.
	var s: StaminaComponent = _make()
	_sustain_for(s, s.tuning.sprint_drain, 1.0)
	check_approx(s.current(), 88.0, 0.05, "réserve après 1 s de sprint")
	_dispose(s)


func test_the_gauge_never_falls_below_zero() -> void:
	var s: StaminaComponent = _make()
	_sustain_for(s, s.tuning.sprint_drain, 20.0)
	check(s.current() >= 0.0, "la jauge ne doit jamais passer sous zéro (%.3f)" % s.current())
	check_approx(s.current(), 0.0, 0.001, "réserve après un effort prolongé")
	_dispose(s)


func test_reaching_zero_raises_exhaustion_once_per_depletion() -> void:
	## Un signal émis à chaque tick sous zéro ferait clignoter l'UI et rejouerait le
	## son de souffle en rafale (§18.2 : « aucun effet mitraillette »).
	var s: StaminaComponent = _make()
	var count: Array[int] = [0]
	s.exhausted.connect(func() -> void: count[0] += 1)
	var ticks: int = _drain_until_exhausted(s, s.tuning.sprint_drain, 15.0)
	check(ticks > 0, "l'épuisement doit survenir")
	check(s.is_exhausted(), "la jauge vidée doit déclarer l'épuisement")
	check_equal(count[0], 1, "nombre d'émissions du signal exhausted")

	# Rester à zéro ne doit pas ré-annoncer l'épuisement à chaque tick.
	for i: int in range(30):
		s.try_sustain(s.tuning.sprint_drain, TICK)
		s.update(TICK)
	check_equal(count[0], 1, "émissions après une demi-seconde de plus à zéro")
	_dispose(s)


func test_a_held_sprint_produces_usable_bursts_not_a_stutter() -> void:
	## Défaut réel de la première implémentation de B.2, trouvé par ce test : en
	## levant l'épuisement dès la première unité régénérée, un sprint maintenu
	## repartait **un seul tick** avant de s'épuiser de nouveau — 7 cycles en 15 s.
	## Le joueur aurait vu la vitesse osciller au lieu de courir.
	##
	## On mesure donc la durée de la seconde rafale : entre la première reprise et
	## l'épuisement suivant. Sans seuil de récupération elle vaut un tick (0,017 s) ;
	## avec, elle vaut la réserve rendue divisée par le débit (D-016).
	var s: StaminaComponent = _make()
	var ticks_before_first: int = _drain_until_exhausted(s, s.tuning.sprint_drain, 30.0)
	check(ticks_before_first > 0, "préalable : première rafale épuisée")

	# Sprint maintenu : on attend la reprise, puis on chronomètre la rafale.
	var granted_ticks: int = 0
	var resumed: bool = false
	var burst_ticks: int = 0
	for i: int in range(int(30.0 / TICK)):
		var granted: bool = s.try_sustain(s.tuning.sprint_drain, TICK)
		s.update(TICK)
		if granted:
			resumed = true
			granted_ticks += 1
		if resumed and s.is_exhausted():
			burst_ticks = granted_ticks
			break
	check(resumed, "le sprint doit finir par redémarrer tout seul")
	var burst_seconds: float = burst_ticks * TICK
	check(burst_seconds > 1.0,
		"la rafale doit être utilisable, pas un bégaiement : %.3f s (un tick = %.3f s)"
		% [burst_seconds, TICK])
	_dispose(s)


func test_regeneration_waits_the_declared_delay() -> void:
	## §9.1 : « régénération après 1 s ». Avant ce délai, rien ne remonte.
	var s: StaminaComponent = _make()
	_sustain_for(s, s.tuning.sprint_drain, 2.0)
	var after_effort: float = s.current()
	_idle_for(s, s.tuning.regen_delay - 0.1)
	check_approx(s.current(), after_effort, 0.001,
		"aucune régénération avant le délai de %.2f s" % s.tuning.regen_delay)
	_idle_for(s, 0.3)
	check(s.current() > after_effort,
		"la régénération doit démarrer après le délai (%.2f -> %.2f)"
		% [after_effort, s.current()])
	_dispose(s)


func test_regeneration_ramps_in_instead_of_snapping() -> void:
	## §9.1 : « reprise progressive 0,20 s ». Les premiers instants de récupération
	## doivent rendre **moins** que le régime nominal, sinon la jauge repart par un
	## à-coup.
	var s: StaminaComponent = _make()
	_sustain_for(s, s.tuning.sprint_drain, 2.0)
	var floor_value: float = s.current()
	_idle_for(s, s.tuning.regen_delay)

	var ramp: float = s.tuning.regen_ramp
	_idle_for(s, ramp)
	var gained_during_ramp: float = s.current() - floor_value
	var nominal: float = s.tuning.regen_rate * ramp
	check(gained_during_ramp < nominal * 0.75,
		"la rampe doit rendre nettement moins que le régime nominal : %.3f contre %.3f"
		% [gained_during_ramp, nominal])
	check(gained_during_ramp > 0.0, "la rampe doit tout de même rendre quelque chose")
	_dispose(s)


func test_regeneration_reaches_the_declared_rate_after_the_ramp() -> void:
	## §9.1 : 22/s une fois la reprise établie.
	var s: StaminaComponent = _make()
	_sustain_for(s, s.tuning.sprint_drain, 3.0)
	_idle_for(s, s.tuning.regen_delay + s.tuning.regen_ramp)
	var before: float = s.current()
	_idle_for(s, 1.0)
	check_approx(s.current() - before, s.tuning.regen_rate, 0.5,
		"gain sur 1 s à plein régime")
	_dispose(s)


func test_the_gauge_never_exceeds_its_maximum() -> void:
	var s: StaminaComponent = _make()
	_sustain_for(s, s.tuning.sprint_drain, 1.0)
	_idle_for(s, 30.0)
	check_approx(s.current(), s.tuning.max_stamina, 0.001, "réserve après repos prolongé")
	check(s.current() <= s.tuning.max_stamina, "la jauge ne doit jamais dépasser son maximum")
	_dispose(s)


func test_an_unaffordable_cost_is_refused_and_consumes_nothing() -> void:
	## Une jauge à moitié vidée par une action refusée serait un vol silencieux.
	var s: StaminaComponent = _make()
	s.set_current(10.0)
	var granted: bool = s.try_spend(s.tuning.dodge_cost)
	check(not granted, "une esquive à 10 d'endurance doit être refusée (coût %.0f)"
		% s.tuning.dodge_cost)
	check_approx(s.current(), 10.0, 0.001, "réserve inchangée après un refus")
	_dispose(s)


func test_an_affordable_cost_is_deducted_exactly_once() -> void:
	var s: StaminaComponent = _make()
	var granted: bool = s.try_spend(s.tuning.dodge_cost)
	check(granted, "une esquive à pleine réserve doit être accordée")
	check_approx(s.current(), 100.0 - s.tuning.dodge_cost, 0.001,
		"réserve après une esquive")
	_dispose(s)


func test_the_exhaustion_lockout_refuses_an_otherwise_affordable_cost() -> void:
	## §9.1 : « 0,45 s avant action consommatrice ». Avec les valeurs de la spec ce
	## verrou est masqué par le délai de régénération (voir le test suivant) ; on
	## raccourcit donc ce délai pour prouver que le verrou est du code vivant et non
	## une constante décorative.
	var s: StaminaComponent = _make({"regen_delay": 0.0, "regen_ramp": 0.0, "regen_rate": 1000.0})
	# Un unique tick d'effort suffit à vider une réserve déjà quasi nulle : rester
	# à sprinter au-delà relancerait le cycle et brouillerait la mesure.
	s.set_current(0.1)
	check(s.try_sustain(s.tuning.sprint_drain, TICK), "préalable : l'effort doit être accordé")
	s.update(TICK)
	check(s.is_exhausted(), "préalable : la jauge doit être vidée")

	_idle_for(s, 0.1)
	check(s.current() > s.tuning.dodge_cost,
		"préalable : la réserve doit être redevenue suffisante (%.1f)" % s.current())
	check(not s.can_spend(s.tuning.dodge_cost),
		"le verrou d'épuisement doit refuser une action pourtant payable")

	_idle_for(s, s.tuning.exhaustion_lockout)
	check(s.can_spend(s.tuning.dodge_cost),
		"passé %.2f s, l'action doit redevenir possible" % s.tuning.exhaustion_lockout)
	_dispose(s)


func test_with_spec_values_the_lockout_is_subsumed_by_the_regen_delay() -> void:
	## Constat honnête, transformé en fait vérifié plutôt qu'en remarque de marge :
	## avec les valeurs de §9.1, le verrou (0,45 s) expire alors que la jauge est
	## encore à zéro, puisque la régénération n'a pas commencé (1 s). Toute action
	## reste donc refusée par manque de réserve, pas par le verrou.
	##
	## Ce test échouera si quelqu'un règle `regen_delay` sous `exhaustion_lockout` —
	## et c'est voulu : le comportement observable changerait, il faudrait une
	## décision, pas une dérive.
	var s: StaminaComponent = _make()
	check(s.tuning.regen_delay > s.tuning.exhaustion_lockout,
		"délai de régénération (%.2f s) et verrou d'épuisement (%.2f s)"
		% [s.tuning.regen_delay, s.tuning.exhaustion_lockout])

	check(_drain_until_exhausted(s, s.tuning.sprint_drain, 30.0) > 0, "préalable : épuisement")
	_idle_for(s, s.tuning.exhaustion_lockout + 0.05)
	check_approx(s.current(), 0.0, 0.001,
		"à l'expiration du verrou, la réserve est encore nulle")
	_dispose(s)


func test_recovery_requires_the_lockout_and_a_usable_reserve() -> void:
	## Lever l'épuisement au seul écoulement du verrou, ou à la première unité
	## régénérée, ferait osciller le sprint (D-016). Il faut les deux conditions :
	## verrou écoulé **et** réserve au moins égale au seuil de récupération.
	var s: StaminaComponent = _make()
	var recovered: Array[int] = [0]
	s.recovered.connect(func() -> void: recovered[0] += 1)

	check(_drain_until_exhausted(s, s.tuning.sprint_drain, 30.0) > 0, "préalable : épuisement")
	_idle_for(s, s.tuning.exhaustion_lockout + 0.05)
	check(s.is_exhausted(),
		"verrou écoulé mais réserve nulle : l'épuisement doit tenir")
	check_equal(recovered[0], 0, "aucune récupération annoncée tant que la réserve est nulle")

	# Assez pour redémarrer la régénération, pas assez pour atteindre le seuil.
	_idle_for(s, s.tuning.regen_delay + 0.1)
	check(s.current() > 0.0, "préalable : la régénération a repris (%.2f)" % s.current())
	check(s.current() < s.tuning.exhaustion_recovery_threshold,
		"préalable : le seuil n'est pas encore atteint (%.2f)" % s.current())
	check(s.is_exhausted(),
		"une réserve non nulle mais inférieure au seuil ne lève pas l'épuisement")

	_idle_for(s, 5.0)
	check(not s.is_exhausted(), "le seuil atteint, l'épuisement doit se lever")
	check_equal(recovered[0], 1, "nombre d'émissions du signal recovered")
	_dispose(s)


func test_declared_values_match_the_spec() -> void:
	## §9.1 fixe ces nombres. Ce test empêche qu'un réglage « juste pour voir »
	## s'installe sans décision consignée.
	var t: StaminaTuning = load("res://resources/tuning/stamina_default.tres") as StaminaTuning
	check_not_null(t, "stamina_default.tres")
	if t == null:
		return
	check_approx(t.max_stamina, 100.0, 0.001, "maximum (§9.1)")
	check_approx(t.sprint_drain, 12.0, 0.001, "sprint par seconde (§9.1)")
	check_approx(t.climb_drain, 18.0, 0.001, "escalade par seconde (§9.1)")
	check_approx(t.climb_lateral_drain, 16.0, 0.001, "latéral par seconde (§9.1)")
	check_approx(t.climb_jump_cost, 20.0, 0.001, "saut d'escalade (§9.1)")
	check_approx(t.dodge_cost, 15.0, 0.001, "esquive (§9.1)")
	check_approx(t.heavy_attack_cost, 20.0, 0.001, "attaque lourde (§9.1)")
	check_approx(t.regen_delay, 1.0, 0.001, "délai de régénération (§9.1)")
	check_approx(t.regen_rate, 22.0, 0.001, "régime de régénération (§9.1)")
	check_approx(t.regen_ramp, 0.20, 0.001, "reprise progressive (§9.1)")
	check_approx(t.exhaustion_lockout, 0.45, 0.001, "verrou d'épuisement (§9.1)")
	# Absent de §9.1 : valeur propre au projet, justifiée par une mesure (D-016).
	check(t.exhaustion_recovery_threshold > 0.0
		and t.exhaustion_recovery_threshold < t.max_stamina,
		"seuil de récupération dans une plage utilisable : %.1f"
		% t.exhaustion_recovery_threshold)
