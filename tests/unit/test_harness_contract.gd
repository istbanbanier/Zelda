## Teste le harnais de test lui-même.
##
## Trois revues adverses ont montré qu'un harnais peut rester vert alors qu'il a
## cessé de détecter les échecs. Ces cas verrouillent les invariants du contrat.
##
## Note : ce fichier ne manipule aucun compteur interne. La version précédente
## appelait `_failures.remove_at()` — c'est-à-dire qu'elle pratiquait dans l'arbre
## l'échappatoire même que le contrat devait interdire. Les vecteurs de
## contournement sont désormais testés par des contrôles négatifs externes
## (`evidence/gate0/negative_controls/`), pas depuis l'intérieur de la suite.
extends GateTestCase


func test_recorder_is_injected_by_runner() -> void:
	# Sans enregistreur, aucune assertion ne peut être comptabilisée : le runner
	# doit donc toujours en injecter un avant d'appeler une méthode de test.
	check(_recorder != null, "le runner doit injecter un GateTestRecorder")
	check(_recorder is GateTestRecorder, "l'enregistreur doit être un GateTestRecorder")


func test_recorder_counts_and_records() -> void:
	# On vérifie le comportement de l'enregistreur sur une instance séparée, sans
	# toucher à celle qui juge ce test.
	var probe: GateTestRecorder = GateTestRecorder.new()
	probe.record(true, "assertion vraie")
	check_equal(probe.checks(), 1, "une assertion enregistrée")
	check_equal(probe.failures().size(), 0, "aucun échec pour une assertion vraie")

	probe.record(false, "assertion fausse")
	check_equal(probe.checks(), 2, "deux assertions enregistrées")
	check_equal(probe.failures().size(), 1, "un échec pour une assertion fausse")


func test_failures_list_is_a_copy() -> void:
	# `failures()` rend une copie : un appelant ne peut pas vider la liste réelle.
	var probe: GateTestRecorder = GateTestRecorder.new()
	probe.record(false, "échec de contrôle")
	var copy: Array[String] = probe.failures()
	copy.clear()
	check_equal(probe.failures().size(), 1,
		"vider la copie ne doit pas effacer les échecs enregistrés")


func test_contract_methods_are_declared() -> void:
	# Le runner s'appuie sur cette liste pour refuser une redéfinition.
	check(GateTestCase.CONTRACT_METHODS.has("check"), "check doit être protégé")
	check(GateTestCase.CONTRACT_METHODS.has("check_equal"), "check_equal doit être protégé")
	check(GateTestCase.CONTRACT_METHODS.has("check_approx"), "check_approx doit être protégé")
	check(GateTestCase.CONTRACT_METHODS.has("check_not_null"), "check_not_null doit être protégé")


func test_this_case_extends_gate_test_case() -> void:
	check(self is GateTestCase, "un cas de test doit être un GateTestCase")
