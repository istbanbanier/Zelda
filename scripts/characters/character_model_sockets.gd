## Racine d'un modèle de personnage de production (ART-Q1/Q2) — héros et
## pillards partagent le même squelette UAL (65 os), donc le même script.
##
## 1. Crée les TROIS sockets d'équipement exigés (main d'arme, dos, arc) en
##    `BoneAttachment3D` sur le squelette monté. En code et non dans le
##    .tscn : les attachements doivent être des enfants directs du
##    `Skeleton3D`, qui vit DANS la sous-scène instanciée.
## 2. Applique la TEINTE de variante (§12 : pillard braise/azur/obsidienne —
##    « pas de simples recolorations » vaut pour silhouette et comportement ;
##    la teinte reste le marqueur de faction lisible). Matériaux DUPLIQUÉS
##    par instance : deux pillards ne partagent jamais leur matériau (§5.4).
##
## Le modèle ne porte AUCUNE logique : ni collision, ni état. La capsule du
## contrôleur reste l'autorité de gameplay (ordre ART-Q1).
class_name CharacterModelSockets
extends Node3D

## nom de socket → os porteur (squelette 65 os, noms style UE — vérifiés
## identiques entre les modèles et les bibliothèques UAL).
const SOCKETS: Dictionary = {
	"SOCKET_HAND_R": "hand_r",
	"SOCKET_BACK": "spine_03",
	"SOCKET_BOW": "hand_l",
}

## Teinte de variante multipliée sur l'albédo des matériaux du costume.
## Blanc = modèle tel que livré (le héros). Les variantes de pillard posent
## leur couleur de faction ici, dans leur .tscn.
@export var tint: Color = Color.WHITE

var _skeleton: Skeleton3D = null


func _ready() -> void:
	var skeletons: Array[Node] = find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_warning("[model] aucun Skeleton3D — sockets impossibles.")
		return
	_skeleton = skeletons[0] as Skeleton3D
	for socket_name: String in SOCKETS:
		var bone: String = String(SOCKETS[socket_name])
		if _skeleton.find_bone(bone) < 0:
			push_warning("[model] os absent pour %s : %s" % [socket_name, bone])
			continue
		var attachment: BoneAttachment3D = BoneAttachment3D.new()
		attachment.name = socket_name
		_skeleton.add_child(attachment)
		attachment.bone_name = bone
	if tint != Color.WHITE:
		_apply_tint()


func _notification(what: int) -> void:
	# À la sortie de l'arbre, les surcharges teintées sont RETIRÉES avant que
	# leurs matériaux (portés par ce nœud) ne meurent : la mise à jour
	# différée du RenderingServer citerait sinon un RID déjà libéré —
	# « material is null » côté serveur headless, erreur réelle mesurée.
	if what == NOTIFICATION_EXIT_TREE:
		for node: Node in find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			var surfaces: int = mesh.mesh.get_surface_count() \
				if mesh.mesh != null else 0
			for surface: int in range(surfaces):
				if mesh.get_surface_override_material(surface) != null:
					mesh.set_surface_override_material(surface, null)


func _apply_tint() -> void:
	for node: Node in find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		for surface: int in range(mesh.mesh.get_surface_count()
				if mesh.mesh != null else 0):
			var material: BaseMaterial3D = \
				mesh.get_active_material(surface) as BaseMaterial3D
			if material == null:
				continue
			var tinted: BaseMaterial3D = material.duplicate() as BaseMaterial3D
			tinted.albedo_color = material.albedo_color * tint
			mesh.set_surface_override_material(surface, tinted)


## Socket par nom (`SOCKET_HAND_R`, `SOCKET_BACK`, `SOCKET_BOW`) — null si
## le squelette ou l'os manquent : l'appelant garde son repli.
func socket(socket_name: String) -> BoneAttachment3D:
	if _skeleton == null:
		return null
	return _skeleton.get_node_or_null(socket_name) as BoneAttachment3D
