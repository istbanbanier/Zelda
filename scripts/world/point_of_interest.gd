## Point d'INTÉRÊT du monde — le lieu qui se découvre en y arrivant.
##
## Volume d'approche posé sur un lieu nommé : village, ruine, grotte,
## panorama, cercle de pierres. Quand le joueur entre, le lieu demande au
## `DiscoveryLog` s'il est neuf ; lui-même ne retient rien. C'est ce qui rend
## la règle « aucune seconde récompense après rechargement » vraie par
## construction : un lieu ne peut pas se déclarer neuf tout seul.
##
## Il ne porte AUCUN gameplay : la récompense éventuelle écoute `first_visit`.
## Un point d'intérêt n'est donc jamais un coffre déguisé.
class_name PointOfInterest
extends Area3D

## Émis à la PREMIÈRE arrivée seulement.
signal first_visit(poi_id: StringName, display_name: String)
## Émis à chaque arrivée, `was_new` disant si c'était la première.
signal arrived(poi_id: StringName, display_name: String, was_new: bool)

## §19.3 : `zone.category.name.index`, par exemple
## `valley.poi.riverside_village.01`.
@export var poi_id: StringName = &""
## Nom affiché à la découverte. Passe par une clé de localisation le jour où
## le jeu en aura une (§2 : les noms affichés vivent dans des ressources).
@export var display_name: String = ""
## Région d'appartenance, pour regrouper dans une carte ou un journal.
@export var region: StringName = &""

var _log: DiscoveryLog = null


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)


## Injection explicite plutôt qu'un singleton attrapé au vol : les tests
## montent un journal neuf, et deux mondes chargés en même temps ne se
## marchent pas dessus.
func bind(discovery_log: DiscoveryLog) -> void:
	_log = discovery_log
	if _log == null:
		return
	if String(poi_id).is_empty():
		push_warning("[lieu] %s n'a pas d'identifiant — §19.3" % name)
		return
	_log.register(poi_id, display_name, region)


func is_bound() -> bool:
	return _log != null


func _on_body_entered(body: Node3D) -> void:
	if _log == null:
		return
	if not body.is_in_group(&"player"):
		return
	var was_new: bool = _log.visit(poi_id)
	if was_new:
		first_visit.emit(poi_id, display_name)
	arrived.emit(poi_id, display_name, was_new)
