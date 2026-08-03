## RÉCOMPENSES des découvertes (ordre d'extension §3).
##
## §3 exige que chaque point d'intérêt offre au moins un élément parmi
## coffre, arme, ingrédients, ressource rare… Les huit familles de lieux
## posent des ANCRAGES — des `Marker3D` vides — mais aucun gameplay : elles
## sont volontairement du décor, pour rester testables isolément.
##
## Ce script fait la jonction. Il parcourt les lieux déclarés, trouve leur
## ancrage, et y pose un vrai `Chest` du jeu. Conséquences voulues :
##
##  - l'identifiant du coffre DÉRIVE de celui du lieu, donc il est unique et
##    stable sans table à tenir à jour (§19.3) ;
##  - le coffre passe par la persistance existante de la vallée — ouvert une
##    fois, il le reste après rechargement, et son butin ne réapparaît pas ;
##  - un lieu sans ancrage ne reçoit rien plutôt que de recevoir un coffre
##    posé au hasard : mieux vaut un manque visible qu'un coffre flottant.
class_name DiscoveryRewards
extends Node3D

const CHEST_SCENE: String = "res://scenes/interactables/Chest.tscn"

## Noms d'ancrage acceptés. Les agents qui ont bâti les lieux n'ont pas tous
## choisi le même mot ; plutôt que de réécrire huit fichiers, on accepte
## leurs conventions.
const ANCHOR_NAMES: Array[String] = [
	"AncrageRecompense", "AncrageDeRecompense", "Recompense", "RewardAnchor",
]

## Butin par région : une région dangereuse rend une arme, une région
## paisible rend des flèches. Rien d'aléatoire — §11.4 veut un butin
## reproductible.
const WEAPON_BY_REGION: Dictionary = {
	&"falaise": "res://resources/weapons/spear.tres",
	&"hauteurs": "res://resources/weapons/simple_bow.tres",
	&"route_du_donjon": "res://resources/weapons/heavy_axe.tres",
	&"ruines": "res://resources/weapons/worn_sword.tres",
	&"foret": "res://resources/weapons/wood_club.tres",
}

var _placed: int = 0
var _skipped: Array[StringName] = []
var _fallback: Array[StringName] = []


func placed_count() -> int:
	return _placed


## Lieux qui n'ont pas reçu de récompense, faute d'ancrage. Exposé pour que
## le test puisse NOMMER les manques au lieu de les taire.
func skipped_places() -> Array[StringName]:
	return _skipped.duplicate()


## Lieux servis par le REPLI, donc dont la pose du coffre n'a pas été
## choisie par le bâtisseur du lieu. À revoir sur capture.
func fallback_places() -> Array[StringName]:
	return _fallback.duplicate()


## Pose une récompense sur chaque lieu du monde `world` qui porte un ancrage.
func furnish(world: Node) -> int:
	var packed: PackedScene = load(CHEST_SCENE) as PackedScene
	if packed == null:
		push_warning("[récompenses] scène de coffre introuvable")
		return 0
	for node: Node in world.find_children("*", "PointOfInterest", true, false):
		var poi: PointOfInterest = node as PointOfInterest
		if String(poi.poi_id).is_empty():
			continue
		var anchor: Node3D = _anchor_near(poi)
		if anchor == null:
			# Repli sur le point d'intérêt lui-même. Seuls deux des huit
			# agents ont posé un `AncrageRecompense` : sans ce repli, 23 des
			# 31 lieux resteraient sans récompense et §3 ne serait pas tenu.
			# Le volume du lieu est centré sur lui, c'est donc un point
			# plausible — mais NON vérifié à l'œil, d'où le compte séparé.
			_fallback.append(poi.poi_id)
			_place_chest(packed, poi, poi)
			continue
		_place_chest(packed, poi, anchor)
	return _placed


## Cherche l'ancrage dans le lieu qui PORTE ce point d'intérêt — c'est-à-dire
## chez son parent, puisque le `PointOfInterest` est un volume frère du décor.
func _anchor_near(poi: PointOfInterest) -> Node3D:
	var host: Node = poi.get_parent()
	if host == null:
		return null
	for wanted: String in ANCHOR_NAMES:
		var found: Array[Node] = host.find_children("%s*" % wanted, "Node3D",
			true, false)
		if not found.is_empty():
			return found[0] as Node3D
	return null


func _place_chest(packed: PackedScene, poi: PointOfInterest,
		anchor: Node3D) -> void:
	var chest: Chest = packed.instantiate() as Chest
	# `valley.poi.watchtower_ruin.01` -> `valley.chest.watchtower_ruin.01`.
	# L'unicité du coffre découle de celle du lieu : aucune table à tenir.
	chest.chest_id = StringName(String(poi.poi_id).replace(".poi.", ".chest."))
	var weapon_path: String = String(WEAPON_BY_REGION.get(poi.region, ""))
	if weapon_path.is_empty():
		chest.arrows_loot = 5
	else:
		var weapon: WeaponDefinition = load(weapon_path) as WeaponDefinition
		if weapon == null:
			chest.arrows_loot = 5
		else:
			chest.weapon_loot = weapon
	add_child(chest)
	chest.global_position = anchor.global_position
	_placed += 1
