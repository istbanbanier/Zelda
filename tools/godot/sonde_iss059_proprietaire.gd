## Sonde ISS-059 — QUI retient les `PackedScene` épinglées à l'instanciation ?
##
## POURQUOI ELLE EXISTE
## --------------------
## La bissection de R2B.3 (`evidence/world_v2/v2_3_r2b3/iss059/bissection/`) a
## localisé le résidu de fuite entre la 70e et la 74e scene instanciee : rien
## jusqu'a `ValleyWorld.tscn`, puis d'un coup 281 `DummyMaterial`, 214
## `DummyMesh`, 67 `DummyTexture` quand on ajoute `WorldV2.tscn`,
## `WorldV2Bootstrap.tscn` et `ResonancePylon.tscn`. Elle a MONTRE 107
## `PackedScene` vivantes en fin de processus ; elle ne les a pas NOMMEES.
##
## Une correlation numerique ne suffit pas. Cette sonde repond a trois
## questions que la precedente ne posait pas :
##
##   1. LAQUELLE des trois scenes porte le residu ? -> `--scenes=`
##   2. Le residu est-il STABLE ou CUMULATIF ?      -> `--cycles=2` et plus
##   3. QUI le retient ?                            -> `--ablation=`
##
## L'ablation est un INSTRUMENT DE DIAGNOSTIC, pas un correctif : elle vide un
## conteneur candidat JUSTE AVANT `quit()` et laisse le moteur imprimer son
## rapport. Si le rapport perd ses objets, le conteneur les tenait. Le correctif,
## lui, doit agir a la source — vider en fin de test serait exactement le
## nettoyage artificiel que la directive interdit.
##
## CE QU'ELLE MESURE, ET AVEC QUOI
## -------------------------------
## `Performance.OBJECT_*` est lu DANS le processus, avant la sortie : il donne
## la croissance par cycle sans dependre du rapport de sortie. Le rapport de
## sortie de Godot, lui, est lu APRES, dans le journal. Les deux sont
## necessaires : le premier distingue stable de cumulatif, le second dit ce que
## le moteur considere comme fuite.
##
## PIEGE DEJA PAYE : `--headless` DESACTIVE le rendu, et la signature
## `RendererDummy::DummyMaterial` n'existe QUE sous le renderer factice. Cette
## sonde se lance donc en `--headless`, contrairement aux captures.
##
## USAGE
##   tools/lancer_godot.sh --headless --path . \
##     --script tools/godot/sonde_iss059_proprietaire.gd -- \
##     --scenes=worldv2 --cycles=2 --ablation=aucune
##
##   --scenes=    aucune | worldv2 | bootstrap | pylone, combinables par `+`
##                (`aucune` est le TEMOIN : meme processus, memes autoloads,
##                 zero instanciation. Un compte n'a de sens que par son ecart
##                 avec lui.)
##   --cycles=N   nombre de cycles montage/demontage dans LE MEME processus
##   --ablation=  aucune | kit_scene | kit_material | kit_index |
##                registry_model | registry_index | tout, combinables par `+`
##   --detail=oui enumere le contenu des caches (cle, chemin, compteur de refs)
extends SceneTree

const SCENES: Dictionary = {
	"worldv2": "res://scenes/world_v2/WorldV2.tscn",
	"bootstrap": "res://scenes/world_v2/WorldV2Bootstrap.tscn",
	"pylone": "res://scenes/world_v2/landmarks/ResonancePylon.tscn",
}

var _paquets_faibles: Array[WeakRef] = []
var _noeuds_faibles: Array[WeakRef] = []
var _cles_paquets: Array[String] = []


func _initialize() -> void:
	var scenes_arg: String = _arg("--scenes=", "aucune")
	var cycles: int = maxi(1, int(_arg("--cycles=", "1")))
	var ablation: String = _arg("--ablation=", "aucune")
	var detail: bool = _arg("--detail=", "non") == "oui"

	print("=== SONDE ISS-059 PROPRIETAIRE ===")
	print("scenes=%s cycles=%d ablation=%s" % [scenes_arg, cycles, ablation])

	_install_autoloads()
	await process_frame
	await process_frame

	var cles: Array[String] = []
	if scenes_arg != "aucune":
		for brut: String in scenes_arg.split("+", false):
			var cle: String = brut.strip_edges()
			if SCENES.has(cle):
				cles.append(cle)
			else:
				printerr("ARRET : scene inconnue %s ; connues : %s"
					% [cle, ", ".join(PackedStringArray(SCENES.keys()))])
				quit(2)
				return

	_mesure("apres_autoloads_avant_tout_cycle")

	for cycle: int in range(cycles):
		for cle: String in cles:
			await _monter_puis_demonter(cle, cycle)
		_mesure("fin_cycle_%d" % (cycle + 1))

	print("--- etat des conteneurs candidats ---")
	_etat_caches(detail)

	print("--- survie apres demontage (WeakRef) ---")
	_etat_weakrefs()

	if ablation != "aucune":
		print("--- ABLATION DIAGNOSTIQUE : %s ---" % ablation)
		_ablation(ablation)
		await process_frame
		await process_frame
		await process_frame
		_mesure("apres_ablation")

	print("=== SONDE TERMINEE ===")
	quit(0)


## Un cycle complet : charger, instancier, monter, demonter, liberer.
## Les `await` sont volontairement au nombre de trois apres `queue_free()` :
## la file de suppression est videe en fin de frame, et un seul `await` a deja
## suffi a faire croire qu'un noeud survivait.
func _monter_puis_demonter(cle: String, cycle: int) -> void:
	var chemin: String = String(SCENES[cle])
	var paquet: PackedScene = load(chemin) as PackedScene
	if paquet == null:
		printerr("ARRET : chargement impossible %s" % chemin)
		quit(2)
		return
	if cycle == 0:
		_paquets_faibles.append(weakref(paquet))
		_cles_paquets.append(cle)
	var noeud: Node = paquet.instantiate()
	if noeud == null:
		printerr("ARRET : instanciation impossible %s" % chemin)
		quit(2)
		return
	root.add_child(noeud)
	await process_frame
	await process_frame
	if cycle == 0:
		_noeuds_faibles.append(weakref(noeud))
	root.remove_child(noeud)
	noeud.queue_free()
	await process_frame
	await process_frame
	await process_frame
	print("  cycle %d : %s monte puis demonte" % [cycle + 1, cle])


## Compteurs lus DANS le processus. Ils ne dependent pas du rapport de sortie,
## et c'est le seul moyen de distinguer une allocation stable d'une croissance
## cumulative sans lancer N processus.
func _mesure(etiquette: String) -> void:
	print("MESURE %s | objets=%d ressources=%d noeuds=%d orphelins=%d"
		% [etiquette,
			int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))])


func _etat_caches(detail: bool) -> void:
	print("CACHE WorldV2PlaceKit._scene_cache    = %d" % WorldV2PlaceKit._scene_cache.size())
	print("CACHE WorldV2PlaceKit._material_cache = %d" % WorldV2PlaceKit._material_cache.size())
	print("CACHE WorldV2PlaceKit._index          = %d" % WorldV2PlaceKit._index.size())
	print("CACHE AssetRegistry._model_cache      = %d" % AssetRegistry._model_cache.size())
	print("CACHE AssetRegistry._model_index      = %d" % AssetRegistry._model_index.size())
	if not detail:
		return
	var sans_chemin: int = 0
	for cle: Variant in WorldV2PlaceKit._scene_cache.keys():
		var res: Resource = WorldV2PlaceKit._scene_cache[cle] as Resource
		if res == null:
			continue
		if res.resource_path.is_empty():
			sans_chemin += 1
		print("  kit[%s] chemin=%s refs=%d"
			% [String(cle), res.resource_path, res.get_reference_count()])
	print("  kit : %d entrees SANS resource_path" % sans_chemin)
	for cle2: Variant in AssetRegistry._model_cache.keys():
		var res2: Resource = AssetRegistry._model_cache[cle2] as Resource
		if res2 == null:
			continue
		print("  registry[%s] chemin=%s refs=%d"
			% [String(cle2), res2.resource_path, res2.get_reference_count()])


## Un `WeakRef` ne retient rien : s'il rend encore l'objet, quelqu'un D'AUTRE le
## retient. C'est la mesure directe de la question « est-ce libere ? ».
func _etat_weakrefs() -> void:
	for i: int in range(_noeuds_faibles.size()):
		var cle: String = _cles_paquets[i] if i < _cles_paquets.size() else "?"
		var n: Variant = _noeuds_faibles[i].get_ref()
		print("  noeud[%s] vivant=%s" % [cle, "OUI" if n != null else "non"])
	for j: int in range(_paquets_faibles.size()):
		var cle2: String = _cles_paquets[j] if j < _cles_paquets.size() else "?"
		var p: Variant = _paquets_faibles[j].get_ref()
		if p == null:
			print("  paquet[%s] vivant=non" % cle2)
			continue
		var pr: Resource = p as Resource
		print("  paquet[%s] vivant=OUI refs=%d chemin=%s"
			% [cle2, pr.get_reference_count(), pr.resource_path])


## DIAGNOSTIC UNIQUEMENT. Vider un conteneur juste avant la sortie ne corrige
## rien : cela attribue. Si le rapport de sortie perd ses objets apres avoir
## vide X, alors X les tenait.
func _ablation(liste: String) -> void:
	var tout: bool = liste.contains("tout")
	if tout or liste.contains("kit_scene"):
		print("  vide WorldV2PlaceKit._scene_cache (%d)" % WorldV2PlaceKit._scene_cache.size())
		WorldV2PlaceKit._scene_cache.clear()
	if tout or liste.contains("kit_material"):
		print("  vide WorldV2PlaceKit._material_cache (%d)" % WorldV2PlaceKit._material_cache.size())
		WorldV2PlaceKit._material_cache.clear()
	if tout or liste.contains("kit_index"):
		print("  vide WorldV2PlaceKit._index (%d)" % WorldV2PlaceKit._index.size())
		WorldV2PlaceKit._index.clear()
	if tout or liste.contains("registry_model"):
		print("  vide AssetRegistry._model_cache (%d)" % AssetRegistry._model_cache.size())
		AssetRegistry._model_cache.clear()
	if tout or liste.contains("registry_index"):
		print("  vide AssetRegistry._model_index (%d)" % AssetRegistry._model_index.size())
		AssetRegistry._model_index.clear()


func _arg(prefixe: String, defaut: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefixe):
			return arg.trim_prefix(prefixe)
	return defaut


## Copie fidele de `tools/godot/test_runner.gd` : un `--script` remplace la
## `SceneTree` par defaut et Godot n'y installe PAS les autoloads. Sans eux le
## temoin ne serait pas comparable au runner.
func _install_autoloads() -> void:
	var installed: Array[String] = []
	for setting: Dictionary in ProjectSettings.get_property_list():
		var key: String = String(setting.get("name", ""))
		if not key.begins_with("autoload/"):
			continue
		var autoload_name: String = key.trim_prefix("autoload/")
		var value: String = String(ProjectSettings.get_setting(key, ""))
		if value == "" or not value.begins_with("*"):
			continue
		var path: String = value.substr(1)
		if root.has_node(NodePath(autoload_name)):
			continue
		var script: Script = load(path) as Script
		if script == null or not script.can_instantiate():
			continue
		var node: Node = script.new() as Node
		if node == null:
			continue
		node.name = autoload_name
		root.add_child(node)
		installed.append(autoload_name)
	if not installed.is_empty():
		print("autoloads installes: %s" % ", ".join(installed))
