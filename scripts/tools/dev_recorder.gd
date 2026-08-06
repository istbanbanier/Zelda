## Enregistreur de session de développement — la boîte noire du jeu.
##
## Il ÉCRIT ce qui s'est passé, il ne juge pas et ne modifie rien. Un joueur
## qui trouve un défaut n'a plus à le décrire : il envoie le dossier de sa
## session, et le journal dit l'heure, l'endroit, l'état et l'enchaînement.
##
## Trois fichiers par session, sous `user://dev_sessions/<horodatage>/` :
##   - `journal.jsonl` — un événement par ligne, horodaté, en primitifs ;
##   - `environnement.json` — moteur, plateforme, écran, réglages ;
##   - `resume.md` — écrit à la clôture, lisible sans outil.
##
## Règles de vie privée (PROMPT2_SPEC §14.4) : tout reste LOCAL, rien n'est
## envoyé nulle part, aucune donnée personnelle n'est collectée, et
## l'enregistrement est désactivé par défaut.
##
## Ce script ne dépend d'AUCUN nœud du jeu : il se teste seul, et un défaut
## d'enregistrement ne peut pas casser une partie.
class_name DevRecorder
extends RefCounted

## Racine des sessions. `user://` — jamais le dépôt : une partie ne doit
## jamais écrire dans les sources.
const ROOT: String = "user://dev_sessions"

## Au-delà, le journal est tronqué et le dit. Une session de trois heures ne
## doit pas remplir le disque de quelqu'un.
const MAX_EVENTS: int = 40000

## Événements dont la répétition n'apprend rien : on les regroupe au lieu de
## les écrire mille fois (un pas, une frame, une position).
const COALESCED: Array[StringName] = [&"position", &"pas", &"frame"]

var _directory: String = ""
var _file: FileAccess = null
var _count: int = 0
var _truncated: bool = false
var _started_unix: float = 0.0
var _counts: Dictionary = {}
var _last_coalesced: Dictionary = {}


func directory() -> String:
	return _directory


func event_count() -> int:
	return _count


func is_recording() -> bool:
	return _file != null


func counts_by_kind() -> Dictionary:
	return _counts.duplicate()


## Ouvre une session. Retourne `false` si le disque refuse — l'appelant
## continue de jouer, il n'y a simplement pas de trace.
func start(label: String = "") -> bool:
	if _file != null:
		return true
	var stamp: String = Time.get_datetime_string_from_system(false, false) \
		.replace("-", "").replace(":", "").replace("T", "_")
	var suffix: String = "" if label.is_empty() else "_" + _slug(label)
	_directory = "%s/%s%s" % [ROOT, stamp, suffix]
	if DirAccess.make_dir_recursive_absolute(_directory) != OK:
		push_warning("[dev] impossible de créer %s" % _directory)
		return false
	_file = FileAccess.open(_directory + "/journal.jsonl", FileAccess.WRITE)
	if _file == null:
		push_warning("[dev] journal non ouvrable dans %s" % _directory)
		return false
	_started_unix = Time.get_unix_time_from_system()
	_count = 0
	_truncated = false
	_counts.clear()
	_last_coalesced.clear()
	_write_environment()
	record(&"session", {"etat": "debut", "etiquette": label})
	return true


## Consigne un événement. `data` ne doit contenir que des PRIMITIFS : le
## journal se relit avec n'importe quel outil, et un Variant sérialisé serait
## illisible dans six mois (§19.2, même exigence que la sauvegarde).
func record(kind: StringName, data: Dictionary = {}) -> void:
	if _file == null:
		return
	if _count >= MAX_EVENTS:
		if not _truncated:
			_truncated = true
			_file.store_line(JSON.stringify({
				"t": _elapsed(), "type": "journal_tronque",
				"limite": MAX_EVENTS}))
			_file.flush()
		return
	if COALESCED.has(kind):
		# Une seconde entre deux échantillons du même type suffit à
		# reconstituer un trajet ; dix par seconde ne disent rien de plus.
		var now: float = _elapsed()
		var previous: float = float(_last_coalesced.get(kind, -10.0))
		if now - previous < 1.0:
			return
		_last_coalesced[kind] = now
	var line: Dictionary = {"t": _elapsed(), "type": String(kind)}
	for key: Variant in data.keys():
		line[String(key)] = data[key]
	_file.store_line(JSON.stringify(line))
	# Écriture immédiate sur le disque : une session qui se termine par un
	# plantage est précisément celle qu'on veut pouvoir lire.
	_file.flush()
	_count += 1
	_counts[kind] = int(_counts.get(kind, 0)) + 1


## Ferme la session et écrit le résumé lisible.
func stop(verdict: String = "") -> String:
	if _file == null:
		return ""
	record(&"session", {"etat": "fin", "verdict": verdict})
	_file.close()
	_file = null
	_write_summary(verdict)
	return _directory


func _elapsed() -> float:
	return snappedf(Time.get_unix_time_from_system() - _started_unix, 0.001)


func _slug(text: String) -> String:
	var out: String = ""
	for character: String in text.to_lower():
		out += character if character.is_valid_identifier() \
			or character in "abcdefghijklmnopqrstuvwxyz0123456789" else "_"
	return out.substr(0, 32)


func _write_environment() -> void:
	var environment: Dictionary = {
		"moteur": Engine.get_version_info().get("string", "inconnu"),
		"plateforme": OS.get_name(),
		"processeur": OS.get_processor_name(),
		"rendu": RenderingServer.get_video_adapter_name(),
		"pilote": ProjectSettings.get_setting(
			"rendering/renderer/rendering_method", "inconnu"),
		"fenetre": [DisplayServer.window_get_size().x,
			DisplayServer.window_get_size().y],
		"debut": Time.get_datetime_string_from_system(),
	}
	var file: FileAccess = FileAccess.open(
		_directory + "/environnement.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(environment, "  "))
		file.close()


## Résumé en français, écrit pour être lu par quelqu'un qui n'a pas ouvert le
## journal — c'est le fichier qu'on envoie.
func _write_summary(verdict: String) -> void:
	var file: FileAccess = FileAccess.open(
		_directory + "/resume.md", FileAccess.WRITE)
	if file == null:
		return
	var minutes: float = _elapsed() / 60.0
	file.store_line("# Session de jeu enregistrée")
	file.store_line("")
	file.store_line("- Durée : %.1f minute(s)" % minutes)
	file.store_line("- Événements consignés : %d%s"
		% [_count, " (journal tronqué)" if _truncated else ""])
	if not verdict.is_empty():
		file.store_line("- Ce que la personne a noté : %s" % verdict)
	file.store_line("")
	file.store_line("## Ce qui s'est passé, par nature")
	file.store_line("")
	var kinds: Array = _counts.keys()
	kinds.sort()
	for kind: Variant in kinds:
		file.store_line("- %s : %d" % [String(kind as StringName), _counts[kind]])
	file.store_line("")
	file.store_line("## Quoi en faire")
	file.store_line("")
	file.store_line("Envoyer le DOSSIER entier (ce fichier, `journal.jsonl` et")
	file.store_line("`environnement.json`). Le journal contient l'ordre exact des")
	file.store_line("événements avec leur seconde : c'est lui qui permet de")
	file.store_line("reproduire un défaut sans avoir à le décrire.")
	file.store_line("")
	file.store_line("Rien n'a été envoyé sur Internet. Tout est resté sur cette")
	file.store_line("machine, dans ce dossier.")
	file.close()
