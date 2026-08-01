## Vérifie le mécanisme de sauvegarde (MASTER_SPEC §19.2, §19.4).
##
## Portée : l'écriture atomique, le schéma versionné et le refus des fichiers
## invalides. Le contenu du jeu n'est pas encore sérialisé — c'est la Phase E.
extends GateTestCase

const SLOT: String = "test_zqa_slot"


func _save_system() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath("SaveSystem"))


func _cleanup(system: Node) -> void:
	var path: String = String(system.call("slot_path", SLOT))
	for candidate: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func test_roundtrip_preserves_payload() -> void:
	var system: Node = _save_system()
	check_not_null(system, "SaveSystem")
	if system == null:
		return
	_cleanup(system)

	var payload: Dictionary = {
		"checkpoint": "valley.camp.start",
		"arrows": 18,
		"health": 42.5,
		"chests_opened": ["valley.chest.river_ledge.01"],
	}
	check(bool(system.call("save_slot", SLOT, payload)), "l'écriture doit réussir")
	check(bool(system.call("has_save", SLOT)), "le fichier doit exister après écriture")

	var loaded: Dictionary = system.call("load_slot", SLOT)
	check_equal(String(loaded.get("checkpoint", "")), "valley.camp.start", "checkpoint relu")
	check_equal(int(loaded.get("arrows", 0)), 18, "flèches relues")
	check_approx(float(loaded.get("health", 0.0)), 42.5, 0.001, "santé relue")
	check_equal((loaded.get("chests_opened", []) as Array).size(), 1, "coffres relus")

	_cleanup(system)


func test_previous_save_is_kept_as_backup() -> void:
	## §19.2 : conserver une sauvegarde précédente récupérable.
	var system: Node = _save_system()
	if system == null:
		check(false, "SaveSystem absent")
		return
	_cleanup(system)

	check(bool(system.call("save_slot", SLOT, {"pass": 1})), "première écriture")
	check(bool(system.call("save_slot", SLOT, {"pass": 2})), "seconde écriture")
	var backup: String = String(system.call("slot_path", SLOT)) + ".bak"
	check(FileAccess.file_exists(backup), "la sauvegarde précédente doit être conservée en .bak")

	var loaded: Dictionary = system.call("load_slot", SLOT)
	check_equal(int(loaded.get("pass", 0)), 2, "le slot courant doit porter la dernière écriture")

	_cleanup(system)


func test_no_temporary_file_survives_a_successful_save() -> void:
	## Un .tmp laissé derrière signale une écriture non atomique.
	var system: Node = _save_system()
	if system == null:
		check(false, "SaveSystem absent")
		return
	_cleanup(system)
	check(bool(system.call("save_slot", SLOT, {"x": 1})), "écriture")
	check(not FileAccess.file_exists(String(system.call("slot_path", SLOT)) + ".tmp"),
		"aucun fichier temporaire ne doit subsister après une écriture réussie")
	_cleanup(system)


func test_corrupted_file_is_refused_not_half_applied() -> void:
	## §19.4 : un fichier illisible est signalé, jamais appliqué à moitié.
	var system: Node = _save_system()
	if system == null:
		check(false, "SaveSystem absent")
		return
	_cleanup(system)

	var path: String = String(system.call("slot_path", SLOT))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	check_not_null(file, "création du fichier corrompu")
	if file != null:
		file.store_string("{ ceci n'est pas du JSON valide")
		file.close()

	var loaded: Dictionary = system.call("load_slot", SLOT)
	check(loaded.is_empty(), "un fichier corrompu doit rendre un dictionnaire vide")

	_cleanup(system)


func test_future_schema_is_refused() -> void:
	## §19.4 : ne jamais écraser silencieusement une sauvegarde plus récente que
	## le jeu qui la lit.
	var system: Node = _save_system()
	if system == null:
		check(false, "SaveSystem absent")
		return
	_cleanup(system)

	var future: int = int(system.get("SCHEMA_VERSION")) + 99
	var path: String = String(system.call("slot_path", SLOT))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({
			"schema_version": future, "slot": SLOT, "data": {"x": 1},
		}))
		file.close()

	var loaded: Dictionary = system.call("load_slot", SLOT)
	check(loaded.is_empty(), "un schéma plus récent doit être refusé, pas appliqué")
	check(FileAccess.file_exists(path), "le fichier refusé doit rester intact sur le disque")

	_cleanup(system)


func test_missing_slot_reports_failure() -> void:
	var system: Node = _save_system()
	if system == null:
		check(false, "SaveSystem absent")
		return
	_cleanup(system)
	check(not bool(system.call("has_save", SLOT)), "aucun slot ne doit exister")
	check((system.call("load_slot", SLOT) as Dictionary).is_empty(),
		"charger un slot absent rend un dictionnaire vide")
