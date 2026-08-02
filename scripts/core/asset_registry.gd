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
	# Personnages — modèle héros IMPORTÉ (ART-Q0, préview calibration) ;
	# le câblage animé qui remplit ces .tscn est le lot ART-Q1/Q2.
	&"char.hero": "res://scenes/characters/HeroVisual.tscn",
	&"char.raider_red": "res://scenes/characters/RaiderRedVisual.tscn",
	# Environnement — LIVRÉ (ART-Q0, packs Quaternius CC0, ATTRIBUTIONS.md).
	&"env.tree.large": "res://scenes/environment/TreeLarge.tscn",
	&"env.tree.medium": "res://scenes/environment/TreeMedium.tscn",
	&"env.rock.large": "res://scenes/environment/RockLarge.tscn",
	&"env.rock.medium": "res://scenes/environment/RockMedium.tscn",
	&"env.plant.bush": "res://scenes/environment/Bush.tscn",
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
