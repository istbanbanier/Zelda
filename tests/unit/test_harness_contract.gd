## Teste le harnais de test lui-même.
##
## La revue adverse du Gate 0 a montré qu'un harnais peut rester vert alors qu'il
## a cessé de détecter les échecs. Ces cas verrouillent les invariants du contrat
## de test pour que la régression soit visible.
extends GateTestCase


func test_check_counts_assertions() -> void:
	# `check()` doit incrémenter le compteur lu par le runner : c'est lui qui
	# permet de repérer une méthode de test sans aucune assertion.
	var before: int = get_check_count()
	check(true, "assertion vraie de contrôle")
	var after_one: int = get_check_count()
	check(after_one == before + 1,
		"check() doit incrémenter get_check_count() de 1 (avant=%d, après=%d)"
		% [before, after_one])


func test_helpers_are_available() -> void:
	# Tout cas de test hérite des helpers : aucun fichier n'a besoin de recopier
	# son propre `_assert`, ce qui était la cause du défaut D3.
	check(has_method("check_equal"), "check_equal doit être hérité de GateTestCase")
	check(has_method("check_approx"), "check_approx doit être hérité de GateTestCase")
	check(has_method("check_not_null"), "check_not_null doit être hérité de GateTestCase")
	check(has_method("set_reporter"), "set_reporter doit être hérité de GateTestCase")


func test_this_case_extends_gate_test_case() -> void:
	check(self is GateTestCase, "un cas de test doit être un GateTestCase")
