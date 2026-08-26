## Registre CENTRAL des assets de production (ordre de nuit §7 : « ne laisse
## pas les chemins d'assets dispersés dans plusieurs contrôleurs »).
##
## Un identifiant stable par asset ; les consommateurs demandent `resolve()`
## et REPLIENT sur leur graybox si la ressource n'existe pas encore — le
## branchement d'un pack (Quaternius ou création projet) se fait en déposant
## la scène au chemin réservé, sans toucher un seul contrôleur.
##
## Statique, sans autoload : aucun état, aucune dépendance de chargement.
class_name AssetRegistry
extends RefCounted

## id stable → chemin réservé. Un chemin ABSENT n'est pas une erreur : c'est
## un asset pas encore livré (voir docs/assets/QUATERNIUS_INBOX.md).
const CATALOG: Dictionary = {
	# Production livrée (ART-P0R).
	&"weapon.worn_sword": "res://scenes/weapons/WornSword.tscn",
	# Personnages — LIVRÉS : héros animé (ART-Q1), pillard animé + variantes
	# de faction azur/obsidienne prêtes pour la Phase D (ART-Q2).
	&"char.hero": "res://scenes/characters/HeroVisual.tscn",
	&"char.raider_red": "res://scenes/characters/RaiderRedVisual.tscn",
	&"char.raider_blue": "res://scenes/characters/RaiderBlueVisual.tscn",
	&"char.raider_black": "res://scenes/characters/RaiderBlackVisual.tscn",
	# Boss — LIVRÉ (Phase H lot H.1) : hero asset ORIGINAL du projet, produit
	# par `tools/blender/make_storm_guardian.py`. Pas un pack externe.
	&"char.boss_guardian": "res://scenes/boss/GuardianVisual.tscn",
	# Créatures — LIVRÉES (lots H.3 et H.4), créations originales elles aussi.
	&"char.ravine_troll": "res://scenes/characters/RavineTrollVisual.tscn",
	&"char.centaur_hunter": "res://scenes/characters/CentaurHunterVisual.tscn",
	# Environnement — LIVRÉ (ART-Q0, packs Quaternius CC0, ATTRIBUTIONS.md).
	&"env.tree.large": "res://scenes/environment/TreeLarge.tscn",
	&"env.tree.medium": "res://scenes/environment/TreeMedium.tscn",
	&"env.rock.large": "res://scenes/environment/RockLarge.tscn",
	&"env.rock.medium": "res://scenes/environment/RockMedium.tscn",
	&"env.plant.bush": "res://scenes/environment/Bush.tscn",
	&"env.rock.pebble_a": "res://scenes/environment/PebbleA.tscn",
	&"env.rock.pebble_b": "res://scenes/environment/PebbleB.tscn",
	&"env.rock.pebble_c": "res://scenes/environment/PebbleC.tscn",
	# Camp : chest/crate/barrel LIVRÉS (ART-Q0) ; tent et campfire ABSENTS
	# des sept packs (vérifié) — repli graybox conservé, voir QUATERNIUS_INBOX.
	&"prop.tent": "res://scenes/environment/Tent.tscn",
	&"prop.campfire": "res://scenes/environment/Campfire.tscn",
	&"prop.chest": "res://scenes/environment/ChestModel.tscn",
	&"prop.crate": "res://scenes/environment/Crate.tscn",
	&"prop.barrel": "res://scenes/environment/Barrel.tscn",
	# Architecture — LIVRÉ (ART-Q0) ; harmonisation matière citadelle = ART-Q6.
	&"arch.gate.module": "res://scenes/environment/GateModule.tscn",
	&"arch.wall.module": "res://scenes/environment/WallModule.tscn",
	&"arch.column.module": "res://scenes/environment/ColumnModule.tscn",
}


## V4 lot 3 — dossiers scannés par l'index de modèles directs.
const MODEL_DIRS: Array[String] = [
	"res://assets/environment/foliage", "res://assets/environment/rocks",
	"res://assets/environment/props", "res://assets/environment/dungeon",
	"res://assets/characters/hero", "res://assets/characters/enemies",
]
static var _model_index: Dictionary = {}
## Rétention des `PackedScene` déjà résolus — voir `model()`.
static var _model_cache: Dictionary = {}
## Plafond de rétention. Assez large pour couvrir la répétition d'une famille
## d'objets pendant une construction, assez bas pour que la mémoire reste
## bornée quoi qu'il arrive.
const MODEL_CACHE_MAX: int = 48


## ---------------------------------------------------------------------------
## ISS-071 — LA RÈGLE DE NORMALISATION, PARTAGÉE PAR LES DEUX RÉSOLVEURS.
##
## LE DÉFAUT QU'ELLE EMPÊCHE DE REVENIR. Dans une build exportée, le fichier
## source n'est PAS empaqueté : seul son fichier de métadonnées
## `<nom>.gltf.import` entre dans le PCK, le maillage vivant sous
## `res://.godot/imported/<nom>.gltf-<md5>.scn`. `DirAccess.get_files()` ne rend
## donc que les `.import`, tandis que `load()` sur le chemin SOURCE explicite
## réussit dans les DEUX environnements — la redirection est transparente pour
## un chemin, pas pour un listage. Les deux résolveurs testaient le suffixe
## `.glb`/`.gltf` sur le nom LISTÉ : leur index sortait vide en build, 1 094
## appels de placement échouaient et 110 modèles manquaient à l'écran sans que
## le jeu plante. Mesuré au laboratoire, ISS-071.
##
## POURQUOI ICI. Une copie par résolveur divergerait — c'est exactement ainsi
## qu'ISS-071 a survécu, chacun servant de recours à l'autre avec le même
## défaut. Le point unique vit dans le noyau ; `WorldV2PlaceKit` l'appelle,
## comme il appelle déjà `model()`, et le noyau ne connaît toujours aucun
## porteur.
const EXTENSIONS_MODELE: Array[String] = ["gltf", "glb"]
const SUFFIXE_IMPORT: String = ".import"


## Rend `[nom_canonique, fichier_source]` pour une entrée de répertoire, ou un
## tableau VIDE si l'entrée n'est pas une scène glTF.
##
## L'ORDRE des deux opérations EST le contrat : on retire EXACTEMENT une fois le
## suffixe `.import` final, PUIS on vérifie l'extension du nom reconstruit.
## L'inverse laisserait entrer `Foo.bin.import` et `Foo.tres.import` — des
## ressources qui ne sont pas des scènes — dans un index de `PackedScene`.
##
## La casse d'origine est PRÉSERVÉE dans le nom rendu : la comparaison se fait
## en minuscules, le chemin reconstruit garde les octets du disque, car un
## système de fichiers Linux distingue `Foo.GLB` de `Foo.glb`.
static func normaliser_entree_modele(fichier: String) -> PackedStringArray:
	var source: String = fichier
	if source.to_lower().ends_with(SUFFIXE_IMPORT):
		source = source.substr(0, source.length() - SUFFIXE_IMPORT.length())
	if not EXTENSIONS_MODELE.has(source.get_extension().to_lower()):
		return PackedStringArray()
	return PackedStringArray([source.get_basename(), source])


## ---------------------------------------------------------------------------
## ISS-071 — APPAREIL DE MESURE, PAS DE COMPORTEMENT.
## Même contrat que dans `WorldV2PlaceKit` : ces tables enregistrent ce qui a
## été demandé, résolu et manqué, pour rendre la parité éditeur/export
## MESURABLE. Elles ne portent ni Resource ni Node, et restent volontairement
## hors de `liberer_caches()` — dont la valeur de retour est épinglée par les
## tests d'ISS-059.
static var _diag_demandes: Dictionary = {}
static var _diag_resolus: Dictionary = {}
static var _diag_manques: Dictionary = {}
static var _diag_collisions: Array[Dictionary] = []


static func _diag_compter(table: Dictionary, cle: StringName) -> void:
	table[cle] = int(table.get(cle, 0)) + 1


## Remet les compteurs de diagnostic à zéro. N'efface AUCUN cache de ressource.
static func reinitialiser_diagnostic() -> void:
	_diag_demandes.clear()
	_diag_resolus.clear()
	_diag_manques.clear()
	_diag_collisions.clear()


## Manifeste ISS-071 du registre d'assets : index nom -> chemin, collisions
## observées à la construction de l'index, et compteurs de résolution.
static func manifeste_iss071() -> Dictionary:
	model(&"")   # force la construction de l'index
	var index: Dictionary = {}
	for cle: Variant in _model_index.keys():
		index[String(cle)] = String(_model_index[cle])
	var demandes: Dictionary = {}
	for cle: Variant in _diag_demandes.keys():
		demandes[String(cle)] = int(_diag_demandes[cle])
	var resolus: Dictionary = {}
	for cle: Variant in _diag_resolus.keys():
		resolus[String(cle)] = int(_diag_resolus[cle])
	var manques: Dictionary = {}
	for cle: Variant in _diag_manques.keys():
		manques[String(cle)] = int(_diag_manques[cle])
	return {
		"resolveur": "AssetRegistry",
		"repertoires": MODEL_DIRS.duplicate(),
		"index": index,
		"collisions": _diag_collisions.duplicate(true),
		"demandes": demandes,
		"resolus": resolus,
		"manques": manques,
	}


## Résolution DIRECTE par nom canonique de modèle promu (V4 lot 3) : les
## ~130 modèles Quaternius du dépôt n'ont pas chacun un id de CATALOG —
## l'index paresseux associe `Pine_1` → `res://assets/.../Pine_1.gltf`.
## `null` si absent : l'appelant garde son repli, jamais de ressource rose.
static func model(model_name: StringName) -> PackedScene:
	if _model_index.is_empty():
		# ISS-071 — chaque fichier SOURCE n'est vu QU'UNE FOIS. En éditeur le
		# répertoire porte `X.glb` ET `X.glb.import`, qui normalisent tous deux
		# vers le même chemin ; en build il ne porte que le second. Sans ce
		# garde, le balayage éditeur verrait chaque source DEUX fois et
		# publierait une éventuelle collision croisée en double, là où la build
		# la publierait une seule — les deux manifestes cesseraient d'être
		# comparables, ce que le contrat interdit (I3, I6).
		var vus: Dictionary = {}
		for dir_path: String in MODEL_DIRS:
			var dir: DirAccess = DirAccess.open(dir_path)
			if dir == null:
				continue
			for file: String in dir.get_files():
				var norme: PackedStringArray = normaliser_entree_modele(file)
				if norme.size() == 2:
					var cle: StringName = StringName(norme[0])
					var chemin: String = dir_path + "/" + norme[1]
					if vus.has(chemin):
						continue
					vus[chemin] = true
					if _model_index.has(cle) \
							and String(_model_index[cle]) != chemin:
						# ISS-071 : collision PUBLIÉE, priorité INCHANGÉE.
						# Ici le DERNIER écrase — c'est le comportement
						# historique de ce résolveur, et il n'est pas touché.
						_diag_collisions.append({
							"nom": String(cle),
							"remplace": String(_model_index[cle]),
							"par": chemin,
						})
					_model_index[cle] = chemin
	if not String(model_name).is_empty():
		_diag_compter(_diag_demandes, model_name)
	var cached: Variant = _model_cache.get(model_name)
	if cached != null:
		if not String(model_name).is_empty():
			_diag_compter(_diag_resolus, model_name)
		return cached as PackedScene
	var path: String = String(_model_index.get(model_name, ""))
	if path.is_empty() or not ResourceLoader.exists(path, "PackedScene"):
		if not String(model_name).is_empty():
			_diag_compter(_diag_manques, model_name)
		return null
	var scene: PackedScene = load(path) as PackedScene
	if not String(model_name).is_empty():
		_diag_compter(
			_diag_resolus if scene != null else _diag_manques, model_name)
	if scene != null:
		# On GARDE la référence. Sans elle, l'appelant instancie puis jette le
		# `PackedScene` ; son compteur tombe à zéro, la ressource se retire du
		# cache du moteur, et le placement suivant du MÊME modèle RELIT LE
		# DISQUE. La vallée place plusieurs centaines d'objets pour ~104
		# modèles distincts : le même fichier était rouvert des dizaines de
		# fois pendant la construction du monde, à l'intérieur d'une frame où
		# rien ne peut être dessiné — c'est le gel de l'écran de chargement.
		# BORNE — sans elle, la rétention est illimitée : le dépôt porte plus de
		# cent modèles dont certains pèsent des dizaines de mégaoctets, et une
		# suite qui monte des centaines de mondes finit par manquer de mémoire,
		# ce qui se manifeste par des erreurs incompréhensibles (« identifiant
		# non déclaré ») très loin de la vraie cause. Le cache sert à éviter de
		# RELIRE LE DISQUE pendant une même construction de monde ; passé le
		# plafond, on repart de zéro plutôt que de grossir sans fin.
		if _model_cache.size() >= MODEL_CACHE_MAX:
			_model_cache.clear()
		_model_cache[model_name] = scene
	return scene


static func known_models() -> Array[StringName]:
	model(&"")   # force l'index
	var names: Array[StringName] = []
	for key: Variant in _model_index.keys():
		names.append(key as StringName)
	names.sort()
	return names


## `null` si l'id est inconnu OU si la ressource n'est pas encore livrée —
## l'appelant garde son repli. Jamais d'exception, jamais de ressource rose.
static func resolve(id: StringName) -> PackedScene:
	if not CATALOG.has(id):
		push_warning("[assets] id inconnu du registre : %s" % String(id))
		return null
	var path: String = String(CATALOG[id])
	if not ResourceLoader.exists(path, "PackedScene"):
		return null
	return load(path) as PackedScene


static func available(id: StringName) -> bool:
	return CATALOG.has(id) \
		and ResourceLoader.exists(String(CATALOG[id]), "PackedScene")


static func known_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: Variant in CATALOG.keys():
		ids.append(id as StringName)
	return ids

## ISS-059 — fin de vie du cache statique. Inscrite au démarrage du
## script par `_static_init()`, appelée UNE fois à l'extinction du moteur
## par `SceneFlow._exit_tree()`. Sans elle, ces entrées vivent jusqu'à la
## mort du processus et sortent au rapport de fuite : mesure et ablation à
## variable unique, `evidence/…/v2_3_r2b3_1/iss059/CHAINE_CAUSALE.md`.
##
## Le sens de la dépendance est imposé : le porteur connaît le noyau, le
## noyau ne connaît aucun porteur (test_aucune_reference_croisee_interdite).
static func _static_init() -> void:
	StaticResourceCaches.enregistrer("AssetRegistry", liberer_caches)


static func liberer_caches() -> int:
	var n: int = _model_cache.size() + _model_index.size()
	_model_cache.clear()
	_model_index.clear()
	return n
