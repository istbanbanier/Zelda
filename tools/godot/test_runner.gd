## Runner de tests headless, sans dépendance externe.
##
## Usage :
##   godot --headless --path . --script tools/godot/test_runner.gd
##   godot --headless --path . --script tools/godot/test_runner.gd -- --filter=stamina
##
## Découvre res://tests/**/test_*.gd, instancie chaque script, appelle toute
## méthode commençant par `test_`, et sort avec un code retour non nul si un seul
## test échoue.
##
## Garde-fous issus de la revue adverse du Gate 0 :
##   - D3 : un script qui n'étend pas `GateTestCase` est un ÉCHEC, pas un test
##     silencieux. Le câblage du reporter n'est plus du boilerplate recopiable.
##   - une méthode de test qui n'exécute aucune assertion est un ÉCHEC : elle donne
##     l'illusion d'une couverture inexistante.
##   - D2 : les erreurs d'exécution GDScript n'interrompent pas l'appel et ne
##     peuvent pas être interceptées ici ; c'est `validate_fast.sh` qui inspecte le
##     journal à la recherche de `SCRIPT ERROR`. Les deux protections sont
##     nécessaires, aucune ne suffit seule.
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
		printerr("AUCUN TEST TROUVÉ dans %s — suite vide traitée comme un échec." % ", ".join(TEST_ROOTS))
		quit(1)
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

	# D3 : refuser tout test hors du contrat commun.
	if not (instance is GateTestCase):
		_fail("%s: doit étendre GateTestCase (res://tests/test_case.gd) — " % path
			+ "sans ce contrat les assertions seraient avalées en silence")
		return
	var test_case: GateTestCase = instance as GateTestCase

	var methods: Array[String] = []
	for method: Dictionary in test_case.get_method_list():
		var method_name: String = String(method.get("name", ""))
		if method_name.begins_with("test_") and not methods.has(method_name):
			methods.append(method_name)

	if methods.is_empty():
		_fail("%s: aucune méthode test_*" % path)
		return

	for method_name: String in methods:
		_current = "%s::%s" % [path.get_file(), method_name]
		var before_failed: int = _failed
		test_case.set_reporter(self)
		test_case.call(method_name)

		if test_case.get_check_count() == 0:
			_fail("%s — aucune assertion exécutée (couverture illusoire)" % _current)
			continue
		if _failed == before_failed:
			_passed += 1
			print("  ok   %s (%d assertions)" % [_current, test_case.get_check_count()])


## Appelé par les cas de test via le reporter injecté.
func report_failure(message: String) -> void:
	_fail("%s — %s" % [_current, message])


func _fail(message: String) -> void:
	_failed += 1
	_failures.append(message)
	printerr("  ÉCHEC %s" % message)
