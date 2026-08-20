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


## ---------------------------------------------------------------------------
## ISS-063 — TOUT LANCEMENT DU MOTEUR PREND LE VERROU CANONIQUE ET UNE CLOISON
## ---------------------------------------------------------------------------
## Dette mesurée AVANT de poser ce contrôle (PROMPT4_METHOD §1 : compter les
## violations existantes d'abord) : le 2026-08-20, **13 fichiers et 35 sites**
## lançaient le moteur, dont **11 fichiers sans verrou ni cloison**. Inventaire
## complet : `evidence/world_v2/v2_3_r2b3_1/iss063/INVENTAIRE_POINTS_ENTREE.md`.
##
## Ce n'est donc PAS un contrôle anti-régression posé sur du propre : c'est le
## contrôle qui rend durable la conversion de ces 11 fichiers. Sans lui, le
## douzième script se réécrit nu au prochain jalon — et la dérive ne se voit
## qu'à la prochaine sauvegarde fabriquée.
##
## CE QU'IL NE VOIT PAS, dit ici plutôt que découvert plus tard : une commande
## tapée à la volée dans un appel Bash n'écrit aucun fichier, donc ne rougit
## jamais. Ce test couvre ce qui est VERSIONNÉ. L'angle mort est réel.
const LANCEURS_EXEMPTES: Dictionary = {
	"tools/lancer_godot.sh":
		"c'est le mécanisme lui-même : verrou + cloison éphémère",
	"tools/lancer_godot_autotest.sh":
		"CONTRÔLE NÉGATIF : il partage user:// exprès, pour démontrer la fuite",
	"tools/lib/godot_env.sh":
		"définition du verrou et de la cloison ; ne lance rien",
	"tools/manual_validation_kit.sh":
		"--version seulement ; le reste IMPRIME des instructions destinées au "
		+ "propriétaire, sur SA machine, où la concurrence de ce conteneur "
		+ "n'existe pas. Il appelle tools/env_report.sh, qui prend le verrou.",
	".github/workflows/publish-playtest.yml":
		"runner GitHub éphémère : aucun user:// partagé, rien à sérialiser",
	"tools/dev_report.py":
		"LIT user:// pour en faire un rapport ; ne lance pas le moteur",
}

## Motif d'un LANCEMENT : une référence au binaire suivie, sur la même ligne,
## d'un argument. Le piège que ce motif évite : « le fichier mentionne godot »
## n'est pas « le fichier lance godot ». Les 46 en-têtes `.gd` du dépôt CITENT
## la commande dans un commentaire — un `.gd` ne lance rien.
const EXTENSIONS_EXECUTABLES: Array[String] = ["sh", "py", "yml", "yaml"]


func _fichiers_du_depot(racine: String, out: Array[String],
		extensions: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(racine)
	if dir == null:
		return
	dir.list_dir_begin()
	var entree: String = dir.get_next()
	while entree != "":
		var complet: String = "%s/%s" % [racine, entree]
		if dir.current_is_dir():
			if entree != ".git" and entree != ".godot" and entree != "evidence":
				_fichiers_du_depot(complet, out, extensions)
		elif extensions.has(entree.get_extension().to_lower()):
			out.append(complet)
		entree = dir.get_next()
	dir.list_dir_end()


## Un fichier « lance le moteur » dès qu'il RÉFÉRENCE le binaire hors
## commentaire. Volontairement large, et voici pourquoi.
##
## La première version de ce prédicat exigeait un ` --` après le binaire. La
## contre-épreuve du 2026-08-20 a reproduit sa panne sur un site réel :
## `tools/capture_ab.sh` construit ses arguments dans un TABLEAU puis lance
## `RUN "$GODOT_BIN" "${args[@]}"`. Aucun `--` sur la ligne, donc site invisible
## — et ce site tourne deux fois par invocation. Un prédicat qui rate un vrai
## lancement est pire qu'absent : il donne l'illusion de la couverture.
##
## Sur-inclure est le bon sens de l'erreur pour un garde-fou : un faux positif
## se règle par une exemption NOMMÉE et justifiée dans `LANCEURS_EXEMPTES`, ce
## qui laisse une trace lisible ; un faux négatif ne laisse rien.
func _lance_le_moteur(texte: String) -> bool:
	for ligne: String in texte.split("\n"):
		var nette: String = ligne.strip_edges()
		if nette.begins_with("#"):
			continue
		for jeton: String in ["$GODOT_BIN", "${GODOT_BIN", "/usr/local/bin/godot"]:
			if nette.contains(jeton):
				return true
	return false


func test_tout_lancement_godot_prend_verrou_et_cloison() -> void:
	var fichiers: Array[String] = []
	_fichiers_du_depot("res://tools", fichiers, EXTENSIONS_EXECUTABLES)
	_fichiers_du_depot("res://.github", fichiers, EXTENSIONS_EXECUTABLES)
	_fichiers_du_depot("res://scripts", fichiers, EXTENSIONS_EXECUTABLES)
	# GARDE-FOU contre l'assertion sautée : si le balayage rend zéro fichier, ce
	# test passerait en ne regardant rien. Le compte réel au 2026-08-20 est de
	# plusieurs dizaines ; on exige seulement qu'il ne soit pas vide.
	check(not fichiers.is_empty(),
		"aucun exécutable balayé — le balayage est cassé, pas le dépôt")

	var fautifs: Array[String] = []
	for chemin: String in fichiers:
		var relatif: String = chemin.trim_prefix("res://")
		if LANCEURS_EXEMPTES.has(relatif):
			continue
		var texte: String = FileAccess.get_file_as_string(chemin)
		if texte.is_empty() or not _lance_le_moteur(texte):
			continue
		# Trois jetons de conformité, et pas un de plus. `heavy_tools.lock`
		# existe pour les points d'entrée qui ne PEUVENT pas sourcer un script
		# shell — `tools/blackbox_player/server.py` implémente le verrou
		# canonique en Python (`_prendre_verrou_lourd`). Ce test vérifie que le
		# verrou CANONIQUE est nommé ; que `flock` réussisse est l'affaire de
		# l'exécution, pas d'un balayage de fichiers. La limite est réelle et
		# elle est écrite ici plutôt que découverte plus tard.
		var conforme: bool = texte.contains("godot_env.sh") \
			or texte.contains("lancer_godot.sh") \
			or texte.contains("heavy_tools.lock")
		if not conforme:
			fautifs.append(relatif)
	check(fautifs.is_empty(),
		"lancement Godot sans verrou canonique ni cloison user:// dans : %s\n"
		% str(fautifs)
		+ "        Sourcer tools/lib/godot_env.sh, puis godot_cloison_arbre et\n"
		+ "        godot_verrou_prendre — ou passer par tools/lancer_godot.sh.\n"
		+ "        Une exemption se justifie NOMMÉMENT dans LANCEURS_EXEMPTES.")


## ---------------------------------------------------------------------------
## ISS-059 — TOUT CACHE `static` DE RESSOURCES A UN CHEMIN DE LIBÉRATION
## ---------------------------------------------------------------------------
## Mesuré le 2026-08-20 : une seule montée de la scène de monde laissait
## `281 DummyMaterial · 214 DummyMesh · 65 DummyTexture` au rapport de sortie,
## alors que le nœud était bien libéré. L'ablation à variable unique a nommé les
## porteurs — des conteneurs `static` sans propriétaire ni fin de vie.
## Preuves : `evidence/…/v2_3_r2b3_1/iss059/CHAINE_CAUSALE.md`.
##
## Le correctif n'est pas de supprimer les caches : leur rétention est VOULUE et
## borne une fuite bien pire. Le correctif est de leur donner une fin de vie —
## `static func liberer_caches() -> int`, inscrite au chargement du script par
## `_static_init()` auprès de `StaticResourceCaches`, appelée à l'extinction du
## moteur par `SceneFlow._exit_tree()`.
##
## CE TEST VÉRIFIE LES DEUX MOITIÉS, et c'est délibéré : une fonction de
## libération qui n'est jamais inscrite ne sera jamais appelée, et une
## inscription sans fonction plante. Vérifier l'une sans l'autre laisserait
## passer exactement le cas où le cache dort.
func test_tout_cache_statique_de_ressources_est_liberable() -> void:
	var fichiers: Array[String] = []
	_fichiers_du_depot("res://scripts", fichiers, ["gd"])
	check(not fichiers.is_empty(), "aucun script balayé — le balayage est cassé")

	# Les statiques qui ne peuvent PAS contenir de ressource : compteurs et
	# drapeaux. Nommées une par une, jamais par un motif large — un motif large
	# se met à tout exempter sans qu'on s'en aperçoive.
	var sans_ressource: Array[String] = [
		"_next_attack_id", "_next_instance_id", "interior_mode",
		"seated_count", "inspected_count", "_porteurs",
	]
	var fautifs: Array[String] = []
	var porteurs_vus: int = 0
	for chemin: String in fichiers:
		var texte: String = FileAccess.get_file_as_string(chemin)
		if texte.is_empty():
			continue
		var a_un_cache: bool = false
		for ligne: String in texte.split("\n"):
			var nette: String = ligne.strip_edges()
			if not nette.begins_with("static var "):
				continue
			var nom: String = nette.trim_prefix("static var ").split(":")[0] \
				.split("=")[0].strip_edges()
			if sans_ressource.has(nom):
				continue
			a_un_cache = true
			break
		if not a_un_cache:
			continue
		porteurs_vus += 1
		var a_fonction: bool = texte.contains("static func liberer_caches(")
		var a_inscription: bool = texte.contains(
			"StaticResourceCaches.enregistrer(")
		if not a_fonction:
			fautifs.append("%s (aucun liberer_caches())" % chemin)
		elif not a_inscription:
			fautifs.append("%s (liberer_caches() jamais inscrit)" % chemin)
	# GARDE-FOU contre l'assertion sautée : si le balayage ne trouvait plus aucun
	# porteur, ce test passerait en ne regardant rien. Le compte réel au
	# 2026-08-20 est de onze.
	check(porteurs_vus >= 8,
		"seulement %d cache(s) statique(s) vu(s) — le balayage est cassé, pas le dépôt"
			% porteurs_vus)
	check(fautifs.is_empty(),
		"cache statique sans chemin de libération : %s\n" % str(fautifs)
		+ "        Ajouter `static func liberer_caches() -> int` au fichier et\n"
		+ "        l'inscrire par `_static_init()` auprès de StaticResourceCaches.")
