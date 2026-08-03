## Registre des découvertes (ordre d'extension §3 et §8).
##
## Ce que ces tests protègent, dans l'ordre d'importance :
##   1. aucune SECONDE récompense après un rechargement — c'est la règle que
##      l'ordre écrit explicitement, et celle qu'un système naïf casse ;
##   2. identifiants uniques (§19.3), sans quoi deux lieux se marqueraient
##      découverts l'un l'autre ;
##   3. une sauvegarde qui ne sérialise que des identifiants (§19.2), et qui
##      survit à la disparition d'un lieu (§19.4).
extends GateTestCase


func _fresh() -> DiscoveryLog:
	var journal: DiscoveryLog = DiscoveryLog.new()
	journal.register(&"valley.poi.riverside_village.01", "Village de la rivière",
		&"riviere")
	journal.register(&"valley.poi.watchtower_ruin.01", "Tour de guet effondrée",
		&"hauteurs")
	journal.register(&"valley.poi.waterfall_cave.01", "Grotte de la cascade",
		&"riviere")
	return journal


func test_a_place_is_new_exactly_once() -> void:
	var journal: DiscoveryLog = _fresh()
	check(journal.visit(&"valley.poi.riverside_village.01"),
		"première arrivée : le lieu est NEUF")
	check(not journal.visit(&"valley.poi.riverside_village.01"),
		"deuxième arrivée : plus de récompense")
	check(not journal.visit(&"valley.poi.riverside_village.01"),
		"…ni la troisième")
	check_equal(journal.discovered_count(), 1, "un seul lieu découvert")


## Le cœur de l'exigence : sauver, recharger, revenir sur place — et NE PAS
## être récompensé une seconde fois.
func test_reloading_a_save_does_not_hand_out_a_second_reward() -> void:
	var journal: DiscoveryLog = _fresh()
	journal.visit(&"valley.poi.riverside_village.01")
	journal.visit(&"valley.poi.waterfall_cave.01")
	var saved: Dictionary = journal.collect_state()

	var reloaded: DiscoveryLog = _fresh()
	reloaded.apply_state(saved)
	check_equal(reloaded.discovered_count(), 2, "les deux découvertes reviennent")
	check(not reloaded.visit(&"valley.poi.riverside_village.01"),
		"revenir au village après chargement ne redonne RIEN")
	check(not reloaded.visit(&"valley.poi.waterfall_cave.01"),
		"…la grotte non plus")
	check(reloaded.visit(&"valley.poi.watchtower_ruin.01"),
		"mais un lieu jamais vu reste découvrable")


func test_the_first_visit_signal_fires_once_and_carries_the_name() -> void:
	var journal: DiscoveryLog = _fresh()
	# Les lambdas GDScript capturent par VALEUR : un tableau reçoit le résultat.
	var seen: Array = []
	journal.discovered.connect(func(poi_id: StringName, display_name: String) -> void:
		seen.append([poi_id, display_name]))
	journal.visit(&"valley.poi.watchtower_ruin.01")
	journal.visit(&"valley.poi.watchtower_ruin.01")
	check_equal(seen.size(), 1, "le signal ne part qu'UNE fois")
	check_equal(String(seen[0][1] as String), "Tour de guet effondrée",
		"il porte le nom affiché")


func test_a_duplicate_identifier_is_refused() -> void:
	var journal: DiscoveryLog = DiscoveryLog.new()
	check(journal.register(&"valley.poi.mill.01", "Moulin", &"riviere"),
		"premier enregistrement accepté")
	check(not journal.register(&"valley.poi.mill.01", "Autre moulin", &"foret"),
		"identifiant EN DOUBLE refusé — §19.3")
	check(not journal.register(&"", "Sans nom", &"foret"),
		"identifiant vide refusé")
	check_equal(journal.registered_count(), 1, "un seul lieu déclaré")


func test_visiting_an_undeclared_place_is_refused() -> void:
	var journal: DiscoveryLog = _fresh()
	check(not journal.visit(&"valley.poi.inexistant.99"),
		"un lieu non déclaré ne se découvre pas")
	check_equal(journal.discovered_count(), 0, "et n'entre pas au journal")


## §19.4 : un objet inconnu après mise à jour est journalisé, pas fatal.
func test_a_save_naming_a_removed_place_still_loads() -> void:
	var journal: DiscoveryLog = _fresh()
	journal.apply_state({"discovered": [
		"valley.poi.riverside_village.01",
		"valley.poi.supprime_par_une_mise_a_jour.01",
		"",
		42,
	]})
	check_equal(journal.discovered_count(), 1,
		"seul le lieu encore présent est retenu")
	check(journal.is_discovered(&"valley.poi.riverside_village.01"),
		"…et c'est le bon")


func test_the_saved_state_holds_only_identifiers() -> void:
	var journal: DiscoveryLog = _fresh()
	journal.visit(&"valley.poi.waterfall_cave.01")
	var state: Dictionary = journal.collect_state()
	var ids: Array = state["discovered"] as Array
	check_equal(ids.size(), 1, "un identifiant sauvegardé")
	check(ids[0] is String, "sérialisé en TEXTE, jamais en référence (§19.2)")
	check_equal(String(ids[0] as String), "valley.poi.waterfall_cave.01",
		"l'identifiant exact")


func test_regions_group_places_for_a_map() -> void:
	var journal: DiscoveryLog = _fresh()
	journal.visit(&"valley.poi.riverside_village.01")
	var grouped: Dictionary = journal.by_region()
	check_equal(int((grouped[&"riviere"] as Dictionary)["total"]), 2,
		"deux lieux dans la région de la rivière")
	check_equal(int((grouped[&"riviere"] as Dictionary)["found"]), 1,
		"un seul y est découvert")
	check_equal(int((grouped[&"hauteurs"] as Dictionary)["found"]), 0,
		"les hauteurs restent inexplorées")


## §19.3 impose le format `zone.category.name.index` : le vérifier ici évite
## de découvrir les identifiants bâclés une fois cinquante lieux posés.
func test_identifiers_follow_the_naming_scheme() -> void:
	var journal: DiscoveryLog = _fresh()
	for poi_id: StringName in journal.registered_ids():
		var parts: PackedStringArray = String(poi_id).split(".")
		check_equal(parts.size(), 4,
			"%s : quatre segments zone.category.name.index" % poi_id)
		check_equal(parts[1], "poi", "%s : catégorie « poi »" % poi_id)
		check(parts[3].is_valid_int(), "%s : index numérique" % poi_id)
