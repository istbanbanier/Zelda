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
##   - N3 : la comptabilité ne vit plus dans le cas de test. Le runner crée un
##     `GateTestRecorder` par méthode, l'injecte, et ne lit QUE son propre
##     enregistreur. Il refuse en outre tout script qui redéfinit une méthode du
##     contrat (`GateTestCase.CONTRACT_METHODS`), vecteur démontré par la 3e revue.
##   - B2/B3 : un fichier qui ne s'instancie pas, ou une exécution qui n'a lancé
##     aucun test, sont des ÉCHECS. Le runner sortait 0 dans les deux cas.
##   - D2 : les erreurs d'exécution GDScript n'interrompent pas l'appel et ne
##     peuvent pas être interceptées ici ; c'est `validate_fast.sh` qui inspecte le
##     journal. Les deux protections sont nécessaires, aucune ne suffit seule.
extends SceneTree

# N2 : `tests/playthrough` existait, était annoncé dans le README, et n'était
# jamais collecté — un test déposé là disparaissait en silence.
const TEST_ROOTS: Array[String] = [
	"res://tests/unit",
	"res://tests/integration",
	"res://tests/playthrough",
]

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

	# B3 : « 0 réussi, 0 échoué » sortait en 0. Une suite qui n'exécute rien ne
	# prouve rien — c'est un échec, pas un succès.
	if _passed == 0 and _failed == 0:
		_fail("aucun test n'a été exécuté alors que %d fichier(s) ont été collecté(s)"
			% scripts.size())

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


## Méthodes du contrat déclarées localement par un fichier de test.
func _declared_contract_methods(path: String) -> Array[String]:
	var found: Array[String] = []
	var source: String = FileAccess.get_file_as_string(path)
	if source.is_empty():
		return found
	for line: String in source.split("\n"):
		var trimmed: String = line.strip_edges()
		if not trimmed.begins_with("func "):
			continue
		var signature: String = trimmed.trim_prefix("func ").strip_edges()
		var paren: int = signature.find("(")
		if paren <= 0:
			continue
		var method_name: String = signature.substr(0, paren).strip_edges()
		if GateTestCase.CONTRACT_METHODS.has(method_name) and not found.has(method_name):
			found.append(method_name)
	return found


func _run_script(path: String) -> void:
	var script: Script = load(path) as Script
	if script == null:
		_fail("%s: chargement impossible" % path)
		return

	# B2 : un script avec erreur de parsing se charge en GDScript invalide ; l'appel
	# à new() échouait AVANT le garde et le fichier disparaissait en silence.
	if not script.can_instantiate():
		_fail("%s: script illisible ou non instanciable (erreur de parsing ?)" % path)
		return

	# N3 (3e revue) : un cas de test qui redéfinit `check()` neutralise toute la
	# comptabilité, y compris via les helpers qui l'appellent en dispatch virtuel.
	#
	# `get_script_method_list()` inclut les méthodes HÉRITÉES (vérifié sur 4.7.1 :
	# tous les cas de test paraissaient redéfinir le contrat), il ne permet donc pas
	# de distinguer une déclaration locale. On lit la source, seule à porter
	# l'information « ce fichier déclare lui-même cette méthode ».
	var overridden: Array[String] = _declared_contract_methods(path)
	if not overridden.is_empty():
		_fail("%s: redéfinit des méthodes du contrat (%s) — interdit, la " % [path, ", ".join(overridden)]
			+ "comptabilité des assertions cesserait de fonctionner")
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

		# Enregistreur neuf par méthode, détenu par le runner. Le résultat est lu
		# ici et nulle part ailleurs : le cas de test ne participe pas au verdict.
		var recorder: GateTestRecorder = GateTestRecorder.new()
		test_case.set("_recorder", recorder)

		test_case.call(method_name)

		var failures: Array[String] = recorder.failures()
		if not failures.is_empty():
			for message: String in failures:
				_fail("%s — %s" % [_current, message])
			continue
		if recorder.checks() == 0:
			_fail("%s — aucune assertion exécutée (couverture illusoire)" % _current)
			continue
		_passed += 1
		print("  ok   %s (%d assertions)" % [_current, recorder.checks()])


func _fail(message: String) -> void:
	_failed += 1
	_failures.append(message)
	printerr("  ÉCHEC %s" % message)
