## P2-5 — BossDirector (P2 §10.5) : le choix de pattern du boss devient une
## SÉLECTION LÉGALE, TRAÇABLE et REPRODUCTIBLE — « ne pas utiliser de random
## pur sans historique ». Fail-first : écrit avant l'implémentation.
##
## Contrats : seuls les patterns LÉGAUX (portée, phase, cooldown) sont
## éligibles ; jamais deux fois le même de suite quand une alternative légale
## existe (anti-répétition) ; un seul légal peut se répéter (pas de famine) ;
## même seed = même séquence (reproduction de bug) ; rien de légal = verdict
## vide, le boss attend — le fallback est DÉTERMINISTE.
extends GateTestCase


func _library() -> Array[Dictionary]:
	return [
		{ "id": &"combo", "min_range": 0.0, "max_range": 4.0,
			"phases": [&"phase1", &"phase2", &"phase3"], "cooldown": 2.0,
			"weight": 1.0 },
		{ "id": &"frappe_sol", "min_range": 0.0, "max_range": 4.0,
			"phases": [&"phase3"], "cooldown": 4.0, "weight": 0.8 },
		{ "id": &"arc", "min_range": 4.0, "max_range": 14.0,
			"phases": [&"phase1", &"phase2", &"phase3"], "cooldown": 3.0,
			"weight": 1.0 },
	]


func test_only_legal_patterns_are_ever_picked() -> void:
	var director: BossDirector = BossDirector.new(7)
	director.set_library(_library())
	for i: int in range(30):
		var pick: StringName = director.pick(2.0, &"phase1")
		check(pick != &"frappe_sol", "jamais un pattern d'une autre phase")
		check(pick != &"arc", "jamais un pattern hors portée")
		director.tick(10.0)
	for i: int in range(30):
		var pick: StringName = director.pick(8.0, &"phase3")
		check(pick == &"arc" or pick == &"",
			"à 8 m : l'arc ou rien (obtenu %s)" % pick)
		director.tick(10.0)


func test_no_immediate_repeat_when_an_alternative_is_legal() -> void:
	var director: BossDirector = BossDirector.new(11)
	director.set_library(_library())
	var previous: StringName = &""
	for i: int in range(24):
		var pick: StringName = director.pick(2.0, &"phase3")
		if pick == &"":
			director.tick(0.5)
			continue
		check(pick != previous or previous == &"",
			"jamais deux fois de suite (%s après %s)" % [pick, previous])
		previous = pick
		director.tick(10.0)


func test_a_single_legal_pattern_may_repeat_no_starvation() -> void:
	var director: BossDirector = BossDirector.new(3)
	director.set_library(_library())
	var picks: int = 0
	for i: int in range(10):
		if director.pick(8.0, &"phase1") == &"arc":
			picks += 1
		director.tick(10.0)
	check(picks == 10, "le seul légal est choisi à chaque fois (%d/10)" % picks)


func test_the_same_seed_replays_the_same_sequence() -> void:
	var first: Array[StringName] = []
	var second: Array[StringName] = []
	for sequence: Array[StringName] in [first, second]:
		var director: BossDirector = BossDirector.new(42)
		director.set_library(_library())
		for i: int in range(15):
			sequence.append(director.pick(2.0, &"phase3"))
			director.tick(10.0)
	check(first == second, "seed 42 rejoue exactement la même séquence")
	check(first.size() == 15 and not (&"" in first), "quinze choix pleins")


func test_cooldown_gates_and_history_records() -> void:
	var director: BossDirector = BossDirector.new(5)
	director.set_library(_library())
	var pick: StringName = director.pick(8.0, &"phase1")
	check(pick == &"arc", "l'arc part")
	check(director.pick(8.0, &"phase1") == &"",
		"cooldown : plus rien de légal juste après")
	director.tick(3.5)
	check(director.pick(8.0, &"phase1") == &"arc", "après le cooldown : repart")
	check(director.history().size() == 2, "l'historique consigne chaque choix")
	check(director.history()[0] == &"arc", "…dans l'ordre")
