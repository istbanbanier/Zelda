## Modèle héros de production (ART-Q1) — racine de `HeroVisual.tscn`.
##
## Crée les TROIS sockets d'équipement exigés (main d'arme, dos, arc) en
## `BoneAttachment3D` sur le squelette du modèle monté. En code et non dans
## le .tscn : les attachements doivent être des enfants directs du
## `Skeleton3D`, qui vit DANS la sous-scène instanciée — un nœud déclaré
## ici ne pourrait pas s'y greffer sans instance éditable fragile.
##
## Le modèle ne porte AUCUNE logique : ni collision, ni état. La capsule du
## contrôleur reste l'autorité de gameplay (ordre ART-Q1).
class_name HeroVisualModel
extends Node3D

## nom de socket → os porteur (squelette 65 os, noms style UE — vérifiés
## identiques entre le modèle et les bibliothèques UAL).
const SOCKETS: Dictionary = {
	"SOCKET_HAND_R": "hand_r",
	"SOCKET_BACK": "spine_03",
	"SOCKET_BOW": "hand_l",
}

var _skeleton: Skeleton3D = null


func _ready() -> void:
	var skeletons: Array[Node] = find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_warning("[hero] aucun Skeleton3D — sockets impossibles.")
		return
	_skeleton = skeletons[0] as Skeleton3D
	for socket_name: String in SOCKETS:
		var bone: String = String(SOCKETS[socket_name])
		if _skeleton.find_bone(bone) < 0:
			push_warning("[hero] os absent pour %s : %s" % [socket_name, bone])
			continue
		var attachment: BoneAttachment3D = BoneAttachment3D.new()
		attachment.name = socket_name
		_skeleton.add_child(attachment)
		attachment.bone_name = bone


## Socket par nom (`SOCKET_HAND_R`, `SOCKET_BACK`, `SOCKET_BOW`) — null si
## le squelette ou l'os manquent : l'appelant garde son repli.
func socket(socket_name: String) -> BoneAttachment3D:
	if _skeleton == null:
		return null
	return _skeleton.get_node_or_null(socket_name) as BoneAttachment3D
