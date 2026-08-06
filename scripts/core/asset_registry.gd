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
		# Le coût est borné et connu : au plus un `PackedScene` par modèle du
		# dépôt, chargé une seule fois.
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
