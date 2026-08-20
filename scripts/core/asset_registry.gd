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


## Résolution DIRECTE par nom canonique de modèle promu (V4 lot 3) : les
## ~130 modèles Quaternius du dépôt n'ont pas chacun un id de CATALOG —
## l'index paresseux associe `Pine_1` → `res://assets/.../Pine_1.gltf`.
## `null` si absent : l'appelant garde son repli, jamais de ressource rose.
static func model(model_name: StringName) -> PackedScene:
	if _model_index.is_empty():
		for dir_path: String in MODEL_DIRS:
			var dir: DirAccess = DirAccess.open(dir_path)
			if dir == null:
				continue
			for file: String in dir.get_files():
				var lower: String = file.to_lower()
				if lower.ends_with(".gltf") or lower.ends_with(".glb"):
					_model_index[StringName(file.get_basename())] = \
						dir_path + "/" + file
	var cached: Variant = _model_cache.get(model_name)
	if cached != null:
		return cached as PackedScene
	var path: String = String(_model_index.get(model_name, ""))
	if path.is_empty() or not ResourceLoader.exists(path, "PackedScene"):
		return null
	var scene: PackedScene = load(path) as PackedScene
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
