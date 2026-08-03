## FRAGMENT D'HISTOIRE — une récompense qui ne se met pas dans les poches.
##
## L'ordre d'extension §3 demande que chaque lieu offre « au moins un élément »
## et cite, à côté du coffre et de l'arme, le « fragment d'histoire » et la
## « découverte enregistrée ». Poser 31 coffres identiques aurait satisfait la
## lettre en trahissant l'intention : un lieu qui raconte quelque chose n'a pas
## besoin de rendre une arme de plus.
##
## Ce qu'un fragment donne réellement :
##
##  - un texte court, lu sur place, écrit pour CE lieu ;
##  - une entrée définitive dans le journal des découvertes ;
##  - et rien d'autre. Aucune statistique, aucun objet.
##
## Il se lit une seule fois de façon « neuve » : relu, il redonne son texte
## mais ne réémet pas sa découverte, et le rechargement ne le rend pas neuf —
## la persistance passe par le même chemin que les pickups (§19.1).
class_name StoryFragment
extends Node3D

## Émis à la PREMIÈRE lecture seulement. La vallée s'en sert pour prendre son
## instantané, comme pour un coffre ouvert.
signal read_first_time(fragment_id: StringName)

## Identifiant persistant (§19.3, `zone.category.name.index`). Sans lui, le
## fragment redeviendrait neuf à chaque reprise.
@export var fragment_id: StringName = &""
## Titre court, affiché en tête de la notification.
@export var title: String = ""
## Le texte lui-même. Court : il se lit debout, sans menu.
@export_multiline var text: String = ""

var _read: bool = false


func _ready() -> void:
	add_to_group("interactable")
	_build_stele()
	if String(fragment_id).is_empty():
		push_warning("[fragment] sans identifiant — il redeviendra neuf au "
			+ "rechargement.")
	if text.strip_edges().is_empty():
		push_warning("[fragment] %s sans texte — rien à lire." % fragment_id)


## Une petite stèle inclinée, pour que le fragment SE VOIE. Sans collision :
## un objet qu'on lit ne doit pas devenir un obstacle, et surtout pas boucher
## le passage d'un lieu étroit (§15.11, anti-softlock).
func _build_stele() -> void:
	var slab: MeshInstance3D = MeshInstance3D.new()
	slab.name = "Stele"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.62, 0.94, 0.16)
	slab.mesh = box
	var stone: StandardMaterial3D = StandardMaterial3D.new()
	stone.albedo_color = Color(0.72, 0.68, 0.58)   # céramique ivoire, §1.4
	stone.roughness = 0.78
	slab.material_override = stone
	slab.position = Vector3(0, 0.47, 0)
	slab.rotation_degrees = Vector3(-8.0, 0.0, 2.5)
	add_child(slab)


func is_read() -> bool:
	return _read


## Restauration depuis la sauvegarde : marque lu sans rien émettre ni notifier.
func mark_read_silently() -> void:
	_read = true


func prompt_verb() -> String:
	return "Lire"


## Contrat des interactables : `false` = refusé. Un fragment ne refuse jamais —
## il n'occupe pas d'inventaire, donc il ne peut pas être « plein ».
func interact(player: PlayerController) -> bool:
	if player == null or text.strip_edges().is_empty():
		return false
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null:
		var heading: String = title if not title.is_empty() else "Fragment"
		bus.call("notify", "%s — %s" % [heading, text])
	if not _read:
		_read = true
		read_first_time.emit(fragment_id)
	return true
