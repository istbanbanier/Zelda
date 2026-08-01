## Autoload — écriture atomique, schéma versionné, migrations (MASTER_SPEC §19).
##
## Portée à la Phase A : **le mécanisme**, pas le contenu. La sérialisation de
## l'état de jeu (inventaires, coffres, circuits, boss) arrive en Phase E, quand
## ces systèmes existent. Écrire leur schéma maintenant reviendrait à figer un
## format pour des données imaginaires.
##
## Ce qui est réellement fourni ici :
##   - écriture **atomique** : fichier temporaire, flush, relecture de contrôle,
##     puis remplacement. Une coupure en cours d'écriture ne peut pas laisser une
##     sauvegarde tronquée à la place d'une sauvegarde valide (§19.2) ;
##   - conservation de la sauvegarde précédente en `.bak` ;
##   - schéma versionné et point d'entrée de migration ;
##   - validation au chargement : un fichier illisible ou d'un schéma inconnu est
##     signalé, jamais appliqué à moitié.
##
## §19.2 : ne jamais sérialiser une référence `Node` ou `Resource` comme identité
## durable. Seulement des identifiants, valeurs primitives, tableaux et
## dictionnaires contrôlés.
extends Node

const SCHEMA_VERSION: int = 1
const SAVE_DIR: String = "user://saves"
const BACKUP_SUFFIX: String = ".bak"

signal save_completed(slot: String)
signal save_failed(slot: String, reason: String)
signal load_completed(slot: String)
signal load_failed(slot: String, reason: String)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))


func slot_path(slot: String) -> String:
	return "%s/%s.json" % [SAVE_DIR, slot]


func has_save(slot: String) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## Écrit `payload` de façon atomique. Renvoie `true` seulement si la sauvegarde
## finale a été relue et validée.
func save_slot(slot: String, payload: Dictionary) -> bool:
	var envelope: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"slot": slot,
		"saved_at_utc": Time.get_datetime_string_from_system(true, true),
		"data": payload,
	}
	var text: String = JSON.stringify(envelope, "  ")
	var final_path: String = slot_path(slot)
	var temp_path: String = final_path + ".tmp"

	var temp: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if temp == null:
		_fail_save(slot, "ouverture impossible de %s (%d)" % [temp_path, FileAccess.get_open_error()])
		return false
	temp.store_string(text)
	temp.flush()
	temp.close()

	# Relecture de contrôle AVANT de remplacer quoi que ce soit : un fichier
	# temporaire illisible ne doit jamais écraser une sauvegarde valide.
	var verify: Variant = _read_json(temp_path)
	if verify == null:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		_fail_save(slot, "le fichier temporaire écrit est illisible — ancienne sauvegarde conservée")
		return false

	if FileAccess.file_exists(final_path):
		var backup: String = final_path + BACKUP_SUFFIX
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup))
		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(final_path),
			ProjectSettings.globalize_path(backup))

	var err: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(final_path))
	if err != OK:
		_fail_save(slot, "remplacement impossible (%d)" % err)
		return false

	save_completed.emit(slot)
	return true


## Renvoie les données du slot, ou un dictionnaire vide en cas d'échec.
## L'échec est signalé par `load_failed`, jamais silencieux.
func load_slot(slot: String) -> Dictionary:
	var path: String = slot_path(slot)
	if not FileAccess.file_exists(path):
		_fail_load(slot, "aucune sauvegarde")
		return {}

	var parsed: Variant = _read_json(path)
	if parsed == null:
		_fail_load(slot, "fichier illisible ou JSON invalide")
		return {}
	var envelope: Dictionary = parsed as Dictionary
	if not envelope.has("schema_version") or not envelope.has("data"):
		_fail_load(slot, "enveloppe incomplète (schema_version ou data absent)")
		return {}

	var version: int = int(envelope["schema_version"])
	if version > SCHEMA_VERSION:
		# §19.4 : ne jamais écraser silencieusement une sauvegarde plus récente.
		_fail_load(slot, "schéma %d plus récent que %d — mise à jour du jeu requise"
			% [version, SCHEMA_VERSION])
		return {}

	var data: Dictionary = envelope["data"] as Dictionary
	if version < SCHEMA_VERSION:
		data = migrate(data, version, SCHEMA_VERSION)

	load_completed.emit(slot)
	return data


## Point d'entrée des migrations. Aucune migration n'existe encore : la version 1
## est la première. Chaque incrément futur ajoute ici une étape explicite et un
## test dédié (§21.2).
func migrate(data: Dictionary, from_version: int, to_version: int) -> Dictionary:
	if from_version == to_version:
		return data
	push_warning("[save] aucune migration définie de %d vers %d — données rendues telles quelles"
		% [from_version, to_version])
	return data


func _read_json(path: String) -> Variant:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return null
	if not (json.data is Dictionary):
		return null
	return json.data


func _fail_save(slot: String, reason: String) -> void:
	push_error("[save] échec d'écriture du slot « %s » : %s" % [slot, reason])
	save_failed.emit(slot, reason)


func _fail_load(slot: String, reason: String) -> void:
	load_failed.emit(slot, reason)
