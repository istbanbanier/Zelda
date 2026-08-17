## Base commune des LIEUX V2.3 — une scène autonome qui s'adapte au
## terrain GELÉ, jamais l'inverse.
##
## Contrat (docs/WORLD_V2_POI_CONTRACTS.md §5-§6) :
##  - la scène se construit seule (`_build()` dans `_ready()`), à plat si
##    aucun terrain n'est lié — l'autonomie est testée ainsi ;
##  - le bâtisseur (`WorldV2PlacesBuilder`) l'ancre au site du layout puis
##    lui LIE la fonction de hauteur via `bind_terrain()` AVANT l'entrée
##    en arbre : chaque module s'assied alors sur le sol réel ;
##  - chaque appui structurel est DÉCLARÉ (`declare_support`) — le filet
##    des fondations vérifie que ces points touchent le sol gelé ;
##  - l'identité vient du meta `place_id` posé par le bâtisseur ; hors
##    monde, `default_place_id()` la fournit (une constante, jamais une
##    position).
class_name WorldV2Place
extends Node3D

var _ground: Callable = Callable()
var _support_points: PackedVector3Array = PackedVector3Array()


func bind_terrain(ground: Callable) -> void:
	_ground = ground


func _ready() -> void:
	_build()
	set_meta(&"support_points", _support_points)


## Construit le lieu. Implémentée par chaque scène concrète.
func _build() -> void:
	pass


func place_id() -> StringName:
	return get_meta(&"place_id", default_place_id()) as StringName


func default_place_id() -> StringName:
	return &""


## Hauteur LOCALE du sol gelé sous un point local du lieu (0 hors monde :
## la scène autonome se construit à plat).
func ground_local_y(local_x: float, local_z: float) -> float:
	if _ground.is_valid() and is_inside_tree():
		var world: Vector3 = to_global(Vector3(local_x, 0.0, local_z))
		return float(_ground.call(world.x, world.z)) - global_position.y
	return 0.0


## Déclare un point d'appui structurel (coordonnées locales, au sol).
func declare_support(local_point: Vector3) -> void:
	_support_points.append(local_point)
