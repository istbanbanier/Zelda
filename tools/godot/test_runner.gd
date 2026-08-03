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
##   - les méthodes de test **asynchrones** (`await`) sont attendues. Sans cela
##     leurs assertions seraient comptabilisées dans un autre test, ou perdues.
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


## Tout le travail a lieu dans `_initialize()`, pas dans `_init()` : pendant
## `_init()` la `SceneTree` n'est pas encore installée comme boucle principale et
## `Engine.get_main_loop()` renvoie null. Un test qui interroge l'arbre — c'est le
## cas de tout test de fondation — échouerait alors alors que le jeu fonctionne.
func _initialize() -> void:
	var filter: String = _read_filter()
	print("=== TEST RUNNER — Godot %s ===" % Engine.get_version_info().get("string", "?"))
	_install_autoloads()
	# Les `_ready()` des autoloads ne s'exécutent qu'au premier traitement de
	# l'arbre. Sans cette frame, un autoload est présent mais non initialisé —
	# `AudioManager` n'aurait pas encore créé ses bus, par exemple.
	await process_frame
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
		# `_run_script()` attend les tests asynchrones : elle est donc elle-même une
		# coroutine. L'appeler sans `await` la ferait rendre la main au premier
		# `await` interne, et le runner passerait au fichier suivant en abandonnant
		# silencieusement les tests restants — c'est arrivé, et seul le décompte
		# l'a révélé. Le plancher MIN_TESTS est la seconde ligne de défense.
		await _run_script(path)

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


## Un `MainLoop` personnalisé lancé par `--script` remplace la `SceneTree` par
## défaut, et Godot n'y installe PAS les autoloads déclarés dans `project.godot`.
## Sans cela, tout test touchant à la fondation échouerait ici alors que le jeu
## fonctionne — un faux rouge aussi trompeur qu'un faux vert. On reconstitue donc
## l'environnement réel : chaque autoload déclaré est instancié et ajouté à la
## racine, dans l'ordre du fichier.
func _install_autoloads() -> void:
	var installed: Array[String] = []
	for setting: Dictionary in ProjectSettings.get_property_list():
		var key: String = String(setting.get("name", ""))
		if not key.begins_with("autoload/"):
			continue
		var autoload_name: String = key.trim_prefix("autoload/")
		var value: String = String(ProjectSettings.get_setting(key, ""))
		if value == "":
			continue
		# Le préfixe « * » marque un singleton activé ; son absence = désactivé.
		if not value.begins_with("*"):
			printerr("  autoload « %s » déclaré mais désactivé — ignoré" % autoload_name)
			continue
		var path: String = value.substr(1)
		if root.has_node(NodePath(autoload_name)):
			continue
		var script: Script = load(path) as Script
		if script == null or not script.can_instantiate():
			printerr("  autoload « %s » : script illisible (%s)" % [autoload_name, path])
			continue
		var node: Node = script.new() as Node
		if node == null:
			printerr("  autoload « %s » : le script n'est pas un Node (%s)" % [autoload_name, path])
			continue
		node.name = autoload_name
		root.add_child(node)
		installed.append(autoload_name)
	if not installed.is_empty():
		print("autoloads installés: %s" % ", ".join(installed))


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


## Méthodes du contrat déclarées quelque part dans la chaîne d'héritage du test.
##
## Q1/Q2 (4e revue) : la version précédente testait `begins_with("func ")` avec un
## espace littéral — `func<TAB>check(` passait — et ne lisait que le fichier de
## test, donc une classe de base intermédiaire (nommée hors du motif `test_*`)
## passait aussi. On utilise une regex tolérante et on remonte les scripts parents
## jusqu'à `GateTestCase` exclu.
func _declared_contract_methods(script: Script) -> Array[String]:
	var found: Array[String] = []
	var names: String = "|".join(GateTestCase.CONTRACT_METHODS)
	var regex: RegEx = RegEx.new()
	regex.compile("(?m)^[ \\t]*(static[ \\t]+)?func[ \\t]+(%s)[ \\t]*\\(" % names)

	var current: Script = script
	while current != null:
		var path: String = current.resource_path
		# S'arrêter à la classe de base du contrat : ses déclarations sont légitimes.
		if path == "res://tests/test_case.gd":
			break
		if path != "":
			var source: String = FileAccess.get_file_as_string(path)
			for m: RegExMatch in regex.search_all(source):
				var method_name: String = m.get_string(2)
				if not found.has(method_name):
					found.append(method_name)
		current = current.get_base_script()
	return found


## Vérifie par le COMPORTEMENT que les méthodes d'assertion parviennent bien à
## l'enregistreur du runner. Contrairement à l'analyse de source, ce contrôle est
## insensible aux astuces de syntaxe et couvre toute la chaîne d'héritage.
func _contract_probe_fails(test_case: GateTestCase) -> String:
	var probe: GateTestRecorder = GateTestRecorder.new()
	test_case.set("_recorder", probe)
	test_case.check(true, "sonde de contrat")
	test_case.check_equal(1, 1, "sonde de contrat")
	test_case.check_approx(0.0, 0.0, 0.0001, "sonde de contrat")
	test_case.check_not_null(self, "sonde de contrat")
	if probe.checks() != 4:
		return "%d assertion(s) parvenues à l'enregistreur au lieu de 4" % probe.checks()
	if not probe.failures().is_empty():
		return "la sonde a produit %d échec(s) inattendu(s)" % probe.failures().size()
	return ""


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
	var overridden: Array[String] = _declared_contract_methods(script)
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

	# Contrôle comportemental du contrat, indépendant de toute analyse textuelle.
	var probe_error: String = _contract_probe_fails(test_case)
	if probe_error != "":
		_fail("%s: contrat d'assertion rompu — %s" % [path, probe_error])
		return

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
		# Photo de la racine AVANT le test : ce qui reste APRÈS est une fuite.
		var roots_before: Array[String] = _root_children()

		# Enregistreur neuf par méthode, détenu par le runner. Le résultat est lu
		# ici et nulle part ailleurs : le cas de test ne participe pas au verdict.
		var recorder: GateTestRecorder = GateTestRecorder.new()
		test_case.set("_recorder", recorder)

		# Une méthode de test contenant `await` rend la main immédiatement en
		# renvoyant un objet de coroutine (TYPE_OBJECT), et non `null`. Sans
		# l'attendre, le runner enchaînerait sur le test suivant et les assertions
		# tardives atterriraient dans l'enregistreur d'un AUTRE test. Vérifié par
		# sonde sur 4.7.1 : appel synchrone -> NIL, appel de coroutine -> objet.
		var pending: Variant = test_case.call(method_name)
		if typeof(pending) == TYPE_OBJECT and pending != null:
			await pending

		# Une scène laissée dans l'arbre POISONNE tous les tests suivants.
		# Mesuré (F.6) : une erreur de script au milieu d'un test avortait sa
		# fonction avant le nettoyage ; le vestibule restait chargé, et le
		# parcours de traversal — trente fichiers plus loin — démarrait à
		# l'intérieur de ses colonnes. Le vrai défaut était invisible et le
		# faux coupable était ailleurs. On le nomme donc ICI, tout de suite.
		var leaked: Array[String] = await _leaked_roots(roots_before)
		var failures: Array[String] = recorder.failures()
		if not failures.is_empty():
			for message: String in failures:
				_fail("%s — %s" % [_current, message])
			if not leaked.is_empty():
				_fail("%s — et laisse %s dans l'arbre" % [_current,
					", ".join(leaked)])
			continue
		if recorder.checks() == 0:
			_fail("%s — aucune assertion exécutée (couverture illusoire)" % _current)
			continue
		if not leaked.is_empty():
			_fail("%s — laisse %s dans l'arbre : les tests suivants hériteraient de sa géométrie"
				% [_current, ", ".join(leaked)])
			continue
		_passed += 1
		print("  ok   %s (%d assertions)" % [_current, recorder.checks()])


## Noms des enfants de la racine, autoloads compris.
func _root_children() -> Array[String]:
	var names: Array[String] = []
	var tree_root: Window = root
	if tree_root == null:
		return names
	for child: Node in tree_root.get_children():
		names.append(child.name)
	return names


## Ce que le test a laissé derrière lui. Deux frames de grâce : `queue_free()`
## ne libère qu'en fin de frame, et un test propre a le droit de finir sur un
## `queue_free()` sans attendre lui-même.
func _leaked_roots(before: Array[String]) -> Array[String]:
	await process_frame
	await physics_frame
	var leaked: Array[String] = []
	for name: String in _root_children():
		if not before.has(name) and not leaked.has(name):
			leaked.append(name)
	return leaked


func _fail(message: String) -> void:
	_failed += 1
	_failures.append(message)
	printerr("  ÉCHEC %s" % message)
