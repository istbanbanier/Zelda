## Runner de tests headless, sans dépendance externe.
##
## Usage :
##   godot --headless --path . --script tools/godot/test_runner.gd
##   godot --headless --path . --script tools/godot/test_runner.gd -- --filter=stamina
##
## Découvre res://tests/**/test_*.gd, instancie chaque script, appelle toute
## méthode commençant par `test_`, et sort avec un code retour non nul si un seul
## test échoue. Un test échoue par `assert_*` ou par exception de parsing.
extends SceneTree

const TEST_ROOTS: Array[String] = ["res://tests/unit", "res://tests/integration"]

var _passed: int = 0
var _failed: int = 0
var _failures: Array[String] = []
var _current: String = ""


func _init() -> void:
	var filter: String = _read_filter()
	print("=== TEST RUNNER — Godot %s ===" % Engine.get_version_info().get("string", "?"))
	if filter != "":
		print("filtre: %s" % filter)

	var scripts: Array[String] = []
	for root: String in TEST_ROOTS:
		_collect(root, scripts)
	scripts.sort()

	if scripts.is_empty():
		print("AUCUN TEST TROUVÉ dans %s" % ", ".join(TEST_ROOTS))
		print("RÉSULTAT: 0 réussi, 0 échoué — runner opérationnel, suite vide.")
		quit(0)
		return

	for path: String in scripts:
		if filter != "" and not path.contains(filter):
			continue
		_run_script(path)

	print("")
	print("=== RÉSULTAT: %d réussi(s), %d échoué(s) ===" % [_passed, _failed])
	for f: String in _failures:
		print("  ÉCHEC: %s" % f)
	quit(1 if _failed > 0 else 0)


func _read_filter() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			return arg.trim_prefix("--filter=")
	return ""


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_collect(full, out)
		elif entry.begins_with("test_") and entry.ends_with(".gd"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()


func _run_script(path: String) -> void:
	var script: Script = load(path) as Script
	if script == null:
		_fail("%s: chargement impossible" % path)
		return
	var instance: Object = script.new()
	if instance == null:
		_fail("%s: instanciation impossible" % path)
		return

	for method: Dictionary in instance.get_method_list():
		var name: String = String(method.get("name", ""))
		if not name.begins_with("test_"):
			continue
		_current = "%s::%s" % [path.get_file(), name]
		var before_failed: int = _failed
		if instance.has_method("set_reporter"):
			instance.call("set_reporter", self)
		instance.call(name)
		if _failed == before_failed:
			_passed += 1
			print("  ok   %s" % _current)

	if instance is RefCounted:
		pass
	elif instance is Node:
		(instance as Node).free()


## Appelé par les cas de test via set_reporter().
func report_failure(message: String) -> void:
	_fail("%s — %s" % [_current, message])


func _fail(message: String) -> void:
	_failed += 1
	_failures.append(message)
	printerr("  ÉCHEC %s" % message)
