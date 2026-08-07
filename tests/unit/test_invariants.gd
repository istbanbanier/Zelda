## Rend EXÉCUTABLES les invariants du `CLAUDE.md` qui n'étaient jusqu'ici que de la
## prose. Inspiration directe : `tests/architecture.test.ts` de world-of-claudecraft
## (voir R-014 dans `docs/RESEARCH_LEDGER.md`), qui applique le même principe — un
## invariant écrit dans un document se dégrade en silence ; un invariant vérifié par
## un test rougit à la seconde où quelqu'un le casse.
##
## PARTAGE DES RÔLES avec `.claude/hooks/qa-stop.sh` : le hook regarde les lignes
## AJOUTÉES et bloque en millisecondes, à chaque tour. Ce test regarde l'ÉTAT DU
## PROJET — un réglage de `project.godot`, une touche remappée, un fichier déjà
## présent — que jamais aucun diff ne montrera. Les deux sont nécessaires ; aucun ne
## remplace l'autre.
##
## LIMITE ASSUMÉE : ces contrôles prouvent une LIAISON, pas un appui de touche réel.
## Que `move_left` porte bien la touche physique attendue n'établit pas que la
## marche à gauche fonctionne manette en main : c'est `docs/MANUAL_VALIDATION.md`
## qui en décide, et le CLAUDE.md rappelle que ce conteneur n'a ni écran ni clavier.
extends GateTestCase

## Godot : `KEY_A` vaut 65. Sur un clavier AZERTY, la touche PHYSIQUEMENT située à
## la place du `A` d'un QWERTY est le `Q`. Lier `move_left` au *physical_keycode*
## 65 est donc précisément ce qui réalise « Q = gauche » sans configuration.
## Utiliser `keycode` à la place produirait un `A` sur AZERTY : le bug que cet
## invariant existe pour empêcher.
const PHYSICAL_KEY_A: int = 65

## Surface de code réellement livrée. Les trois cahiers des charges CITENT les
## termes interdits pour les interdire : `docs/` est donc hors périmètre.
const SCANNED_ROOTS: Array[String] = [
	"res://scripts", "res://scenes", "res://resources", "res://shaders",
]
const SCANNED_EXTENSIONS: Array[String] = ["gd", "tscn", "tres", "gdshader"]


func _key_events(action: String) -> Array[InputEventKey]:
	var out: Array[InputEventKey] = []
	if not InputMap.has_action(action):
		return out
	for event: InputEvent in InputMap.action_get_events(action):
		var key: InputEventKey = event as InputEventKey
		if key != null:
			out.append(key)
	return out


func test_azerty_q_moves_left() -> void:
	## L'invariant le plus répété du projet : « AZERTY prioritaire : Q = gauche ».
	var events: Array[InputEventKey] = _key_events("move_left")
	check(not events.is_empty(), "move_left ne porte aucun événement clavier")
	var physical: Array[int] = []
	for key: InputEventKey in events:
		physical.append(key.physical_keycode)
	check(physical.has(PHYSICAL_KEY_A),
		"move_left doit être lié au physical_keycode %d (KEY_A = le Q d'un AZERTY) ; trouvé %s"
		% [PHYSICAL_KEY_A, str(physical)])


func test_left_uses_physical_keycode_not_keycode() -> void:
	## Le piège exact : `keycode = KEY_A` donnerait « A » sur AZERTY. Seul
	## `physical_keycode` raisonne en position de touche.
	for key: InputEventKey in _key_events("move_left"):
		if key.physical_keycode == PHYSICAL_KEY_A:
			check(key.keycode == 0,
				"move_left doit s'appuyer sur physical_keycode seul ; keycode = %d est posé en plus"
				% key.keycode)


func test_lock_on_is_never_bound_to_q() -> void:
	## « Ne jamais mapper Q sur le lock-on » — interdiction nommée dans le
	## CLAUDE.md comme dans MASTER_SPEC §8.5.
	for key: InputEventKey in _key_events("lock_on"):
		check(key.physical_keycode != PHYSICAL_KEY_A,
			"lock_on est lié au physical_keycode %d, c'est-à-dire au Q d'un AZERTY"
			% PHYSICAL_KEY_A)


func test_engine_version_is_exactly_4_7_1() -> void:
	## « Godot 4.7.1-stable exactement. Jamais 4.8 dev/beta/RC. »
	var info: Dictionary = Engine.get_version_info()
	check_equal(int(info.get("major", 0)), 4, "version majeure")
	check_equal(int(info.get("minor", 0)), 7, "version mineure")
	check_equal(int(info.get("patch", -1)), 1, "version corrective")
	check_equal(String(info.get("status", "")), "stable",
		"statut de version (jamais dev/beta/rc)")


func test_gdscript_typing_warnings_stay_enabled() -> void:
	## Les avertissements de typage sont le filet qui rend crédible la règle
	## « GDScript typé ». Les désactiver pour faire taire un problème réel est
	## nommément interdit par `.claude/rules/gdscript.md`.
	for warning: String in [
		"untyped_declaration", "unsafe_property_access",
		"unsafe_method_access", "unsafe_cast",
	]:
		var setting: String = "debug/gdscript/warnings/%s" % warning
		check(int(ProjectSettings.get_setting(setting, 0)) != 0,
			"l'avertissement GDScript « %s » a été désactivé" % warning)


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var full: String = "%s/%s" % [dir_path, entry]
		if dir.current_is_dir():
			_collect(full, out)
		elif SCANNED_EXTENSIONS.has(entry.get_extension().to_lower()):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()


func test_no_nintendo_content_in_shipped_code() -> void:
	## « Aucun contenu Nintendo : ni modèle, ni son, ni carte, ni UI, ni nom
	## affiché. » Les noms de code imposés sont raider_red/blue/black,
	## ravine_troll, centaur_hunter.
	##
	## Les motifs sont ASSEMBLÉS par morceaux, à dessein : écrits en clair, ce
	## fichier déclencherait le hook `qa-stop.sh` qui applique la même règle sur
	## les lignes ajoutées, et le test se signalerait lui-même.
	var forbidden: Array[String] = [
		"boko" + "blin", "ly" + "nel", "hy" + "rule", "shei" + "kah",
		"ga" + "non", "ko" + "rok", "tri" + "force", "de" + "ku",
		"zo" + "nai", "mob" + "lin", "hyl" + "ian",
	]
	var files: Array[String] = []
	for root: String in SCANNED_ROOTS:
		_collect(root, files)
	check(not files.is_empty(), "aucun fichier scanné — le balayage est cassé")

	var offenders: Array[String] = []
	for path: String in files:
		var text: String = FileAccess.get_file_as_string(path).to_lower()
		if text.is_empty():
			continue
		for term: String in forbidden:
			if text.contains(term):
				offenders.append("%s (« %s »)" % [path, term])
				break
	check(offenders.is_empty(),
		"contenu Nintendo dans le code livré : %s" % str(offenders))


func test_reference_image_is_never_a_game_asset() -> void:
	## « L'image de référence n'est jamais un asset (ni skybox, ni billboard, ni
	## texture). » Elle sert au cadrage, à la comparaison, à rien d'autre.
	var files: Array[String] = []
	for root: String in SCANNED_ROOTS:
		_collect(root, files)
	var offenders: Array[String] = []
	for path: String in files:
		var text: String = FileAccess.get_file_as_string(path)
		if text.is_empty():
			continue
		if text.contains("docs/references/") or text.contains("NORTH_STAR"):
			offenders.append(path)
	check(offenders.is_empty(),
		"l'image de référence est employée comme asset dans : %s" % str(offenders))
