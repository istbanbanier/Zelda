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

## Schéma 2 (E.3) : la cuisine ajoute `meals`, `buff` et
## `taken_ingredients`. Une sauvegarde de schéma 1 (avant la Phase E)
## reste chargeable — la migration pose les champs manquants à vide.
## Schéma 3 (S2 « Continuer au spawn ») : la vallée écrit `player_position`
## et `player_yaw` (§19.1 : « position/rotation sûre du joueur »). L'ABSENCE
## de ces champs est un état valide — « position inconnue » — et le monde
## replace alors le joueur à son point d'apparition (§19.4) : la migration
## 2 → 3 ne pose donc AUCUN champ.
const SCHEMA_VERSION: int = 4
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


## Point d'entrée des migrations (§19.4) : une ÉTAPE EXPLICITE par
## incrément, appliquée en chaîne, sur une COPIE — la sauvegarde source
## n'est jamais réécrite avant un chargement réussi.
##
## 1 → 2 (E.3) : la Phase E ajoute la cuisine. Une sauvegarde d'avant
## n'a ni plats, ni buff, ni ingrédients récoltés ; les poser à vide est
## la seule lecture correcte de « ce joueur n'avait pas encore cuisiné ».
func migrate(data: Dictionary, from_version: int, to_version: int) -> Dictionary:
	if from_version == to_version:
		return data
	var migrated: Dictionary = data.duplicate(true)
	var version: int = from_version
	while version < to_version:
		match version:
			1:
				if not migrated.has("meals"):
					migrated["meals"] = []
				if not migrated.has("buff"):
					migrated["buff"] = {}
				if not migrated.has("taken_ingredients"):
					migrated["taken_ingredients"] = []
				if not migrated.has("ingredients"):
					migrated["ingredients"] = {}
			2:
				# 2 → 3 : position/rotation du joueur (§19.1). Rien à poser —
				# une sauvegarde sans `player_position` signifie « position
				# inconnue », et le monde reprend au point d'apparition
				# (§19.4). Inventer une position ici serait mentir.
				pass
			3:
				# 3 → 4 : santé/endurance (§19.1) et autosave par FUSION.
				# Même doctrine : l'absence de `player_health` vaut « santé
				# inconnue », et le monde repart à pleine vie — c'est ce que
				# faisaient déjà toutes les sauvegardes v3.
				pass
			_:
				push_warning("[save] aucune migration définie de %d vers %d — "
					% [version, version + 1] + "données rendues telles quelles")
		version += 1
	migrated["schema"] = to_version
	return migrated


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
