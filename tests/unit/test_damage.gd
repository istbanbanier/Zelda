## Formule de dégâts et santé (MASTER_SPEC §10.3, §21.2) — logique pure.
##
## §21.2 exige le test unitaire de la formule. La santé est testée ici aussi :
## clamp, mort idempotente, invulnérabilité — tout ce qui ne demande pas de
## physique.
extends GateTestCase


func _event(amount: float) -> DamageEvent:
	var event: DamageEvent = DamageEvent.new()
	event.amount = amount
	return event


## `HealthComponent` est un `Node` : chaque test libère le sien (leçon B.3 — un
## orphelin fait rougir validate_fast via « resources still in use at exit »).
func _health(maximum: float) -> HealthComponent:
	var node: HealthComponent = HealthComponent.new()
	node.max_health = maximum
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(node)
	return node


func _dispose(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.get_parent().remove_child(node)
		node.free()


func test_formula_multiplies_then_subtracts_armor() -> void:
	## §10.3 : « base × weapon × attack × buff × weak_point × resistance − armor ».
	## Côté attaquant déjà réduit : 10 × 1,5 (point faible) × 0,5 (résistance) − 2.
	check_approx(DamageFormula.compute(10.0, 1.5, 0.5, 2.0), 5.5, 0.001,
		"10 × 1,5 × 0,5 − 2")
	check_approx(DamageFormula.compute(12.0), 12.0, 0.001,
		"valeurs neutres par défaut : le montant attaquant passe inchangé")


func test_formula_never_returns_negative_damage() -> void:
	## « clampé » (§10.3). Une armure épaisse annule un coup faible, elle ne
	## soigne pas.
	check_approx(DamageFormula.compute(5.0, 1.0, 1.0, 50.0), 0.0, 0.001,
		"armure supérieure aux dégâts")
	check_approx(DamageFormula.compute(0.0), 0.0, 0.001, "coup nul")


func test_formula_weak_point_amplifies_before_armor() -> void:
	## L'ordre compte : le point faible multiplie AVANT la soustraction d'armure.
	## 4 × 2 − 5 = 3, alors que (4 − 5) × 2 clampé donnerait 0.
	check_approx(DamageFormula.compute(4.0, 2.0, 1.0, 5.0), 3.0, 0.001,
		"point faible appliqué avant l'armure")


func test_health_clamps_and_reports() -> void:
	var health: HealthComponent = _health(50.0)
	check_approx(health.current(), 50.0, 0.001, "pleine santé au départ")
	health.take_damage(_event(20.0))
	check_approx(health.current(), 30.0, 0.001, "santé après 20 de dégâts")
	check_approx(health.ratio(), 0.6, 0.001, "fraction pour l'UI")
	health.heal(100.0)
	check_approx(health.current(), 50.0, 0.001, "le soin ne dépasse jamais le maximum")
	check(not health.is_dead(), "vivant")
	_dispose(health)


func test_death_is_emitted_once_and_is_final() -> void:
	## Mort idempotente : §16.2 l'exige du boss (« un seuil ne déclenche pas deux
	## fois ») — la règle vaut pour tout ce qui a des PV.
	var health: HealthComponent = _health(30.0)
	var deaths: Array[int] = [0]
	health.died.connect(func(_e: DamageEvent) -> void: deaths[0] += 1)

	health.take_damage(_event(100.0))
	check(health.is_dead(), "la santé épuisée doit déclarer la mort")
	check_equal(deaths[0], 1, "émissions de died après le coup fatal")

	var applied: bool = health.take_damage(_event(10.0))
	check(not applied, "un mort n'encaisse plus rien")
	check_equal(deaths[0], 1, "died jamais réémis")

	health.heal(20.0)
	check_approx(health.current(), 0.0, 0.001,
		"soigner un mort est un respawn, pas un soin : rien ne remonte")

	health.revive()
	check(not health.is_dead(), "revive() restaure explicitement")
	check_approx(health.current(), 30.0, 0.001, "pleine santé après revive")
	_dispose(health)


func test_invulnerability_refuses_damage_without_consuming_it() -> void:
	## Le drapeau que les i-frames d'esquive (§10.2) basculeront en C.1.
	var health: HealthComponent = _health(40.0)
	health.set_invulnerable(true)
	var applied: bool = health.take_damage(_event(15.0))
	check(not applied, "aucun dégât pendant l'invulnérabilité")
	check_approx(health.current(), 40.0, 0.001, "santé intacte")
	health.set_invulnerable(false)
	check(health.take_damage(_event(15.0)), "les dégâts reprennent après")
	check_approx(health.current(), 25.0, 0.001, "santé entamée")
	_dispose(health)


func test_zero_or_null_events_change_nothing() -> void:
	var health: HealthComponent = _health(40.0)
	check(not health.take_damage(null), "événement nul refusé")
	check(not health.take_damage(_event(0.0)), "montant nul refusé")
	check_approx(health.current(), 40.0, 0.001, "santé intacte")
	_dispose(health)
