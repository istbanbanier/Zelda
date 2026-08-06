## L'enregistreur du mode développement (docs/MODE_DEV.md).
##
## Ce qu'on exige de lui, et pourquoi : c'est la boîte noire du jeu. Un
## journal qui perd des événements, qui écrit un Variant illisible ou qui se
## remplit sans fin ne prouve rien — pire, il ferait croire qu'on a une trace.
##
## Ce que ces tests ne prouvent PAS : que le mode dev soit agréable à utiliser,
## ni que les touches F3/F4/F5 fonctionnent sur un vrai clavier. Cela demande
## un écran et des doigts (voir docs/MANUAL_VALIDATION.md).
extends GateTestCase


func _fresh() -> DevRecorder:
	return DevRecorder.new()


func test_a_recorder_writes_nothing_until_it_is_started() -> void:
	## Éteint par défaut : un joueur qui n'a jamais appuyé sur F3 ne doit pas
	## voir un octet écrit sur son disque.
	var recorder: DevRecorder = _fresh()
	check(not recorder.is_recording(), "un enregistreur neuf est à l'arrêt")
	recorder.record(&"marqueur", {"note": "avant démarrage"})
	check_equal(recorder.event_count(), 0,
		"aucun événement ne doit être retenu hors session")
	check(recorder.directory().is_empty(), "aucun dossier créé")


func test_a_session_writes_a_readable_journal_and_a_summary() -> void:
	var recorder: DevRecorder = _fresh()
	check(recorder.start("test"), "la session doit s'ouvrir")
	recorder.record(&"marqueur", {"numero": 1, "note": "coincé"})
	recorder.record(&"message", {"texte": "Découvert : Aqueduc ancien"})
	var folder: String = recorder.stop("fin de test")
	check(not folder.is_empty(), "la clôture doit rendre le dossier")

	var journal: String = folder + "/journal.jsonl"
	check(FileAccess.file_exists(journal), "journal.jsonl écrit")
	check(FileAccess.file_exists(folder + "/resume.md"), "resume.md écrit")
	check(FileAccess.file_exists(folder + "/environnement.json"),
		"environnement.json écrit")

	# Chaque ligne DOIT être un JSON valide et autonome : c'est ce qui rend le
	# journal lisible par n'importe quel outil, même coupé par un plantage.
	var text: String = FileAccess.get_file_as_string(journal)
	var lines: PackedStringArray = text.strip_edges().split("\n")
	check(lines.size() >= 4, "début, deux événements et fin (%d lignes)"
		% lines.size())
	var kinds: Array[String] = []
	for line: String in lines:
		var parsed: Variant = JSON.parse_string(line)
		check(parsed is Dictionary, "ligne JSON valide : %s" % line.substr(0, 60))
		if parsed is Dictionary:
			var entry: Dictionary = parsed as Dictionary
			check(entry.has("t"), "chaque ligne est horodatée")
			kinds.append(String(entry.get("type", "")))
	check(kinds.has("marqueur"), "le marqueur est consigné")
	check(kinds.has("message"), "le message du jeu est consigné")
	_cleanup(folder)


func test_repeated_samples_are_thinned_instead_of_flooding_the_journal() -> void:
	## Une position par seconde suffit à reconstituer un trajet. Cent par
	## seconde rempliraient le disque sans rien apprendre — et noieraient les
	## marqueurs, qui sont la seule chose qu'un humain a voulu dire.
	var recorder: DevRecorder = _fresh()
	check(recorder.start("regroupement"), "session ouverte")
	for i: int in range(50):
		recorder.record(&"position", {"x": float(i)})
	var after_positions: int = recorder.event_count()
	check(after_positions <= 2,
		"50 positions d'affilée doivent être regroupées (%d écrites)"
			% after_positions)

	# Un marqueur, lui, n'est JAMAIS regroupé : deux problèmes signalés coup
	# sur coup sont deux problèmes.
	recorder.record(&"marqueur", {"numero": 1})
	recorder.record(&"marqueur", {"numero": 2})
	check_equal(recorder.event_count(), after_positions + 2,
		"les marqueurs ne sont jamais fusionnés")
	_cleanup(recorder.stop())


func test_the_journal_stops_growing_instead_of_filling_the_disk() -> void:
	## Une session oubliée toute une nuit ne doit pas remplir le disque de
	## quelqu'un. Le journal se tronque et le DIT — un journal silencieusement
	## incomplet serait pire que pas de journal.
	var recorder: DevRecorder = _fresh()
	check(recorder.start("plafond"), "session ouverte")
	for i: int in range(DevRecorder.MAX_EVENTS + 50):
		recorder.record(&"marqueur", {"numero": i})
	check(recorder.event_count() <= DevRecorder.MAX_EVENTS,
		"le plafond doit tenir (%d écrits pour un maximum de %d)"
			% [recorder.event_count(), DevRecorder.MAX_EVENTS])
	var folder: String = recorder.stop()
	var text: String = FileAccess.get_file_as_string(folder + "/journal.jsonl")
	check(text.contains("journal_tronque"),
		"la troncature doit être écrite dans le journal, pas silencieuse")
	_cleanup(folder)


func test_the_summary_speaks_french_and_names_what_was_recorded() -> void:
	## Le résumé est le fichier qu'une personne ouvre en premier. S'il ne dit
	## rien de lisible, tout le mode dev ne sert qu'à moi — ce qui n'est pas le
	## but (docs/MODE_DEV.md).
	var recorder: DevRecorder = _fresh()
	check(recorder.start("resume"), "session ouverte")
	recorder.record(&"marqueur", {"numero": 1, "note": "caméra dans le décor"})
	var folder: String = recorder.stop("la caméra passe à travers")
	var summary: String = FileAccess.get_file_as_string(folder + "/resume.md")
	check(summary.contains("Session de jeu enregistrée"), "titre présent")
	check(summary.contains("marqueur"), "le résumé compte les marqueurs")
	check(summary.contains("la caméra passe à travers"),
		"le verdict de la personne est repris tel quel")
	check(summary.contains("Rien n'a été envoyé sur Internet"),
		"la promesse de vie privée est écrite dans le fichier lui-même")
	_cleanup(folder)


## Les sessions de test vivent dans `user://` comme les vraies : on les efface
## pour qu'une suite ne laisse pas de dossiers derrière elle.
func _cleanup(folder: String) -> void:
	if folder.is_empty():
		return
	var directory: DirAccess = DirAccess.open(folder)
	if directory == null:
		return
	for file_name: String in directory.get_files():
		directory.remove(file_name)
	DirAccess.remove_absolute(folder)
