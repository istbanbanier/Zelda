## Teste le harnais de test lui-même.
##
## Les deux revues adverses du Gate 0 ont montré qu'un harnais peut rester vert
## alors qu'il a cessé de détecter les échecs. Ces cas verrouillent les invariants
## du contrat pour que la régression soit visible.
extends GateTestCase


func test_check_counts_assertions() -> void:
	# `_checks` est lu directement par le runner : c'est lui qui permet de repérer
	# une méthode de test qui n'assertionne rien.
	var before: int = _checks
	check(true, "assertion vraie de contrôle")
	check(_checks == before + 1,
		"check() doit incrémenter _checks de 1 (avant=%d, après=%d)" % [before, _checks])


func test_failures_are_recorded_in_member_not_via_method() -> void:
	# N3 : la comptabilité ne doit dépendre d'aucune méthode redéfinissable.
	# On provoque un échec, on vérifie qu'il est bien inscrit dans `_failures`,
	# puis on le retire pour ne pas faire échouer ce test volontairement.
	var before: int = _failures.size()
	check(false, "échec volontaire de contrôle interne")
	var recorded: bool = _failures.size() == before + 1
	if recorded:
		_failures.remove_at(_failures.size() - 1)
	check(recorded, "un échec doit être inscrit dans le membre _failures")


func test_helpers_are_available() -> void:
	check(has_method("check_equal"), "check_equal doit être hérité de GateTestCase")
	check(has_method("check_approx"), "check_approx doit être hérité de GateTestCase")
	check(has_method("check_not_null"), "check_not_null doit être hérité de GateTestCase")


func test_this_case_extends_gate_test_case() -> void:
	check(self is GateTestCase, "un cas de test doit être un GateTestCase")
