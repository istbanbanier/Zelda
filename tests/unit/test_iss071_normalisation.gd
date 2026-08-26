## ISS-071 — LA RÈGLE DE NORMALISATION DES NOMS DE MODÈLES, ÉPINGLÉE CAS PAR CAS.
##
## POURQUOI CE TEST EXISTE. Dans une build exportée, le fichier source n'est pas
## empaqueté : seul son fichier de métadonnées `<nom>.gltf.import` entre dans le
## PCK, le maillage vivant sous `res://.godot/imported/<nom>.gltf-<md5>.scn`.
## `DirAccess.get_files()` ne rend donc QUE les `.import`, alors que `load()` sur
## le chemin source explicite réussit dans les deux environnements — la
## redirection est transparente pour un chemin, pas pour un listage. Les deux
## résolveurs testaient le suffixe `.glb`/`.gltf` sur le nom listé ; leur index
## sortait VIDE en build, 1 094 appels de placement échouaient et 110 modèles
## manquaient à l'écran sans que le jeu plante. Mesuré sur l'export du SHA
## `919511d`, lab `evidence/…/fumee_build_exportee/lab_dir_access/`.
##
## CE QUE CE TEST NE PROUVE PAS, et il faut le dire plutôt que le laisser croire :
## il s'exécute en ÉDITEUR, où les sources sont présentes. Il n'observe donc pas
## le défaut lui-même — il épingle la RÈGLE qui le corrige, plus la parité
## éditeur/export de l'index telle qu'elle est observable ici. La parité réelle
## build/éditeur se mesure par `tools/gate_export_parite.sh`.
##
## APPEL DYNAMIQUE, ET C'EST DÉLIBÉRÉ. `AssetRegistry.normaliser_entree_modele()`
## écrit en dur ferait échouer le PARSE de ce fichier tant que la fonction
## n'existe pas : le rouge d'avant-correctif serait une erreur de compilation
## désignant `test_runner.gd`, pas une assertion nommée. Vérifié dans la source du
## tag `4.7.1-stable` avant d'en dépendre : `Object::has_method()` retombe sur
## `Script::has_static_method()` pour un objet Script (`core/object/object.cpp`,
## bloc `Object::cast_to<Script>`), et `GDScript::callp()` appelle bien les
## fonctions statiques (`modules/gdscript/gdscript.cpp`).
extends GateTestCase

const CHEMIN_REGISTRE: String = "res://scripts/core/asset_registry.gd"
const CHEMIN_PLACE_KIT: String = "res://scripts/world_v2/poi/world_v2_place_kit.gd"
const NOM_FONCTION: StringName = &"normaliser_entree_modele"

## Table partagée produite en parallèle par la voie « fixtures » de la directive
## S1. Si elle est là, elle FAIT AUTORITÉ ; sinon on retombe sur `CAS_INTERNES`.
const CHEMIN_FIXTURES: String = "res://tests/fixtures/iss071_noms.json"

## `nom` et `source` VIDES signifient « entrée rejetée ». Les rejets comptent
## autant que les acceptations : un correctif qui retirerait `.import` sans
## revérifier l'extension ferait entrer `Foo.bin.import` et `Foo.tres.import`
## dans l'index, c'est-à-dire des ressources qui ne sont pas des scènes.
const CAS_INTERNES: Array[Dictionary] = [
	{"fichier": "Foo.gltf", "nom": "Foo", "source": "Foo.gltf"},
	{"fichier": "Foo.glb", "nom": "Foo", "source": "Foo.glb"},
	{"fichier": "Foo.gltf.import", "nom": "Foo", "source": "Foo.gltf"},
	{"fichier": "Foo.glb.import", "nom": "Foo", "source": "Foo.glb"},
	{"fichier": "Foo.bin", "nom": "", "source": ""},
	{"fichier": "Foo.bin.import", "nom": "", "source": ""},
	{"fichier": "Foo.tres.import", "nom": "", "source": ""},
	{"fichier": "Foo.png", "nom": "", "source": ""},
	{"fichier": "Foo.PNG", "nom": "", "source": ""},
	{"fichier": "Foo.GLB.IMPORT", "nom": "Foo", "source": "Foo.GLB"},
	{"fichier": "A.B.glb", "nom": "A.B", "source": "A.B.glb"},
	{"fichier": "A.B.glb.import", "nom": "A.B", "source": "A.B.glb"},
	{"fichier": "Foo.import", "nom": "", "source": ""},
	# Le suffixe se retire EXACTEMENT une fois : ce qui reste doit être un
	# modèle, pas un second `.import`.
	{"fichier": "Foo.glb.import.import", "nom": "", "source": ""},
	{"fichier": "Foo", "nom": "", "source": ""},
]

## Cas nominatif exigé par la directive S1, sur un fichier RÉEL du dépôt.
const BARROW_DIR: String = "res://assets/architecture/barrow"
const BARROW_ENTREE: String = "SM_Barrow_Stones.glb.import"
const BARROW_NOM: String = "SM_Barrow_Stones"
const BARROW_SOURCE: String = "SM_Barrow_Stones.glb"


func _registre() -> Script:
	return load(CHEMIN_REGISTRE) as Script


## `false` quand le correctif ISS-071 n'est pas posé. Chaque test qui en dépend
## le dit alors explicitement, au lieu de tomber sur une erreur de moteur.
func _regle_disponible(script: Script) -> bool:
	return script != null and script.has_method(NOM_FONCTION)


func _normaliser(script: Script, fichier: String) -> PackedStringArray:
	var brut: Variant = script.call(NOM_FONCTION, fichier)
	if typeof(brut) != TYPE_PACKED_STRING_ARRAY:
		return PackedStringArray()
	var sortie: PackedStringArray = brut
	return sortie


## Table de cas : la fixture partagée si elle existe, sinon la table interne.
## Une fixture présente mais illisible ÉCHOUE — l'ignorer en silence rendrait la
## voie « fixtures » de la directive invisible depuis ici.
func _cas() -> Array[Dictionary]:
	if not FileAccess.file_exists(CHEMIN_FIXTURES):
		return CAS_INTERNES
	var texte: String = FileAccess.get_file_as_string(CHEMIN_FIXTURES)
	var brut: Variant = JSON.parse_string(texte)
	var liste: Array = []
	if brut is Array:
		liste = brut as Array
	elif brut is Dictionary:
		liste = (brut as Dictionary).get("cas", []) as Array
	var sortie: Array[Dictionary] = []
	for entree: Variant in liste:
		if not (entree is Dictionary):
			continue
		var d: Dictionary = entree as Dictionary
		if not d.has("fichier"):
			continue
		sortie.append({
			"fichier": String(d["fichier"]),
			"nom": String(d.get("nom", "")),
			"source": String(d.get("source", "")),
		})
	check(not sortie.is_empty(),
		("%s existe mais n'a livré aucun cas exploitable ; forme attendue : "
		+ "un tableau JSON (ou une clé « cas ») d'objets "
		+ "{\"fichier\": …, \"nom\": …, \"source\": …}, « nom » vide = rejeté")
		% CHEMIN_FIXTURES)
	return sortie


func test_la_regle_de_normalisation_est_exposee() -> void:
	## Elle doit être PUBLIQUE et STATIQUE sur `AssetRegistry` : c'est le point
	## unique par lequel les deux résolveurs partagent la même règle. Deux copies
	## divergeraient — c'est exactement ainsi qu'ISS-071 a survécu, chacun des
	## deux résolveurs servant de recours à l'autre avec le même défaut.
	var script: Script = _registre()
	check_not_null(script, "script d'AssetRegistry lisible en %s" % CHEMIN_REGISTRE)
	check(_regle_disponible(script),
		("AssetRegistry n'expose pas la fonction statique %s : le correctif "
		+ "ISS-071 n'est pas posé, l'index reste bâti sur le suffixe du nom "
		+ "LISTÉ et sortira vide dans une build exportée")
		% NOM_FONCTION)


func test_table_de_normalisation() -> void:
	var script: Script = _registre()
	if not _regle_disponible(script):
		check(false,
			"table non évaluée : %s absente d'AssetRegistry (correctif ISS-071 absent)"
			% NOM_FONCTION)
		return
	var cas: Array[Dictionary] = _cas()
	var source_table: String = ("fixture %s" % CHEMIN_FIXTURES) \
		if FileAccess.file_exists(CHEMIN_FIXTURES) else "table interne"
	check(cas.size() >= 12,
		"table de cas trop courte (%d, %s) — les rejets doivent y figurer autant que les acceptations"
			% [cas.size(), source_table])
	for c: Dictionary in cas:
		var fichier: String = String(c["fichier"])
		var attendu_nom: String = String(c["nom"])
		var attendu_src: String = String(c["source"])
		var obtenu: PackedStringArray = _normaliser(script, fichier)
		if attendu_nom.is_empty():
			check(obtenu.is_empty(),
				"« %s » doit être REJETÉ (ce n'est pas une scène glTF) ; obtenu %s"
					% [fichier, str(obtenu)])
			continue
		check(obtenu.size() == 2,
			"« %s » doit rendre [nom, source] ; obtenu %s" % [fichier, str(obtenu)])
		if obtenu.size() != 2:
			continue
		check_equal(obtenu[0], attendu_nom, "nom canonique de « %s »" % fichier)
		check_equal(obtenu[1], attendu_src, "fichier source de « %s »" % fichier)


func test_cas_nominatif_barrow_de_la_directive() -> void:
	## Bout en bout sur un fichier réel : entrée `.import` telle qu'un PCK la
	## livre → nom canonique → chemin source → `ResourceLoader` → `PackedScene`.
	## C'est la chaîne entière qu'ISS-071 rompait, et elle est démontrée ici sur
	## `SM_Barrow_Stones`, le modèle même du laboratoire.
	var script: Script = _registre()
	if not _regle_disponible(script):
		check(false, "cas Barrow non évalué : %s absente (correctif ISS-071 absent)"
			% NOM_FONCTION)
		return
	var obtenu: PackedStringArray = _normaliser(script, BARROW_ENTREE)
	check(obtenu.size() == 2, "« %s » doit être reconnu ; obtenu %s"
		% [BARROW_ENTREE, str(obtenu)])
	if obtenu.size() != 2:
		return
	check_equal(obtenu[0], BARROW_NOM, "nom canonique du cas de la directive")
	check_equal(obtenu[1], BARROW_SOURCE, "fichier source du cas de la directive")
	var chemin: String = "%s/%s" % [BARROW_DIR, obtenu[1]]
	check(ResourceLoader.exists(chemin, "PackedScene"),
		"%s doit être chargeable comme PackedScene depuis son chemin SOURCE" % chemin)
	var scene: PackedScene = load(chemin) as PackedScene
	check_not_null(scene, "load(%s) doit rendre une PackedScene" % chemin)


func _index_du_manifeste(manifeste: Dictionary) -> Dictionary:
	var index: Dictionary = {}
	for cle: Variant in (manifeste.get("index", {}) as Dictionary).keys():
		index[String(cle)] = String((manifeste["index"] as Dictionary)[cle])
	return index


## Applique la règle à la VUE D'EXPORT d'un répertoire — c'est-à-dire aux seules
## entrées `.import`, exactement ce que le PCK laisse voir.
##
## `premier_gagne` REFLÈTE la priorité du résolveur comparé, et n'est pas un
## détail : `WorldV2PlaceKit` garde le PREMIER chemin trouvé, `AssetRegistry`
## garde le DERNIER. Aucun nom ne collisionne entre répertoires aujourd'hui, donc
## les deux formes rendent le même résultat ; le jour où une collision naît, un
## oracle à priorité unique accuserait faussement l'un des deux. Un test qui
## rougit pour la mauvaise raison ne vaut pas mieux qu'un test qui ne rougit pas.
func _vue_export(script: Script, dirs: Array, premier_gagne: bool) -> Dictionary:
	var couples: Dictionary = {}
	for d: Variant in dirs:
		var dir_path: String = String(d)
		var dir: DirAccess = DirAccess.open(dir_path)
		if dir == null:
			continue
		for fichier: String in dir.get_files():
			if not fichier.to_lower().ends_with(".import"):
				continue
			var norme: PackedStringArray = _normaliser(script, fichier)
			if norme.size() != 2:
				continue
			if premier_gagne and couples.has(norme[0]):
				continue
			couples[norme[0]] = dir_path + "/" + norme[1]
	return couples


func _comparer(reel: Dictionary, attendu: Dictionary, quoi: String) -> void:
	var manquants: Array[String] = []
	var en_trop: Array[String] = []
	var divergents: Array[String] = []
	for nom: Variant in attendu.keys():
		if not reel.has(nom):
			manquants.append(String(nom))
		elif String(reel[nom]) != String(attendu[nom]):
			divergents.append("%s : %s ≠ %s" % [nom, reel[nom], attendu[nom]])
	for nom: Variant in reel.keys():
		if not attendu.has(nom):
			en_trop.append(String(nom))
	# La TAILLE examinée est publiée avec le verdict : un « aucune différence »
	# sans « sur N couples » ne prouve rien (règle générale de `tools/CLAUDE.md`).
	check(attendu.size() > 0,
		"%s : la vue d'export doit livrer des couples, sinon la comparaison est vide"
			% quoi)
	check(manquants.is_empty() and en_trop.is_empty() and divergents.is_empty(),
		("%s : %d couples comparés — absents de l'index : %s ; absents de la vue "
		+ "d'export : %s ; chemins divergents : %s")
			% [quoi, attendu.size(), str(manquants), str(en_trop), str(divergents)])


func test_parite_index_et_vue_export_place_kit() -> void:
	## I1/I2 du contrat, évalués ici : chaque nom que la vue d'export peut
	## dériver doit être dans l'index, sur le MÊME chemin source. Ce test rougit
	## aussi sur le défaut voisin — un modèle source déposé sans être importé,
	## donc présent en éditeur et absent du PCK.
	var script: Script = _registre()
	if not _regle_disponible(script):
		check(false, "parité non évaluée : %s absente (correctif ISS-071 absent)"
			% NOM_FONCTION)
		return
	var kit: Script = load(CHEMIN_PLACE_KIT) as Script
	check_not_null(kit, "script de WorldV2PlaceKit lisible")
	var dirs: Array = kit.get_script_constant_map().get("MODULE_DIRS", []) as Array
	check(dirs.size() >= 6, "MODULE_DIRS doit garder ses six répertoires (%d)" % dirs.size())
	var manifeste: Dictionary = kit.call(&"manifeste_iss071") as Dictionary
	_comparer(_index_du_manifeste(manifeste), _vue_export(script, dirs, true),
		"WorldV2PlaceKit")


func test_parite_index_et_vue_export_asset_registry() -> void:
	var script: Script = _registre()
	if not _regle_disponible(script):
		check(false, "parité non évaluée : %s absente (correctif ISS-071 absent)"
			% NOM_FONCTION)
		return
	var dirs: Array = script.get_script_constant_map().get("MODEL_DIRS", []) as Array
	check(dirs.size() >= 6, "MODEL_DIRS doit garder ses six répertoires (%d)" % dirs.size())
	var manifeste: Dictionary = script.call(&"manifeste_iss071") as Dictionary
	_comparer(_index_du_manifeste(manifeste), _vue_export(script, dirs, false),
		"AssetRegistry")


func test_aucune_ressource_non_scene_dans_les_index() -> void:
	## Le garde-fou du rejet, vu depuis l'autre bout : quoi qu'ait fait la règle,
	## aucun chemin indexé ne doit pointer ailleurs que sur un `.gltf`/`.glb`.
	var script: Script = _registre()
	if not _regle_disponible(script):
		check(false, "non évalué : %s absente (correctif ISS-071 absent)" % NOM_FONCTION)
		return
	var kit: Script = load(CHEMIN_PLACE_KIT) as Script
	check_not_null(kit, "script de WorldV2PlaceKit lisible")
	var examines: int = 0
	var fautifs: Array[String] = []
	for manifeste: Dictionary in [
			script.call(&"manifeste_iss071") as Dictionary,
			kit.call(&"manifeste_iss071") as Dictionary]:
		var index: Dictionary = _index_du_manifeste(manifeste)
		for nom: Variant in index.keys():
			examines += 1
			var ext: String = String(index[nom]).get_extension().to_lower()
			if ext != "gltf" and ext != "glb":
				fautifs.append("%s -> %s" % [nom, index[nom]])
	check(examines > 0, "les deux index doivent porter des chemins à examiner")
	check(fautifs.is_empty(),
		"%d chemins examinés ; non-scènes indexées : %s" % [examines, str(fautifs)])
