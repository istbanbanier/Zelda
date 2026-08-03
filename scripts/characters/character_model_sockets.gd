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
## Blanc = modèle tel que livré. Les variantes de pillard posent leur
## couleur de faction ici, dans leur .tscn.
@export var tint: Color = Color.WHITE
## Noms de matériaux à teinter — VIDE = tous. Le héros ne teinte que sa
## tenue (MI_Ranger) vers le turquoise de §7.11 : la peau reste la peau.
@export var tint_material_filter: PackedStringArray = PackedStringArray()
## Pièces modulaires UAL greffées au squelette (V4 lot 13) : maillages
## skinnés du MÊME squelette 65 os, re-parentés sous le Skeleton3D — la
## silhouette change réellement (§12 : « pas de simples recolorations »).
@export var modular_parts: Array[PackedScene] = []
## Substitution d'albédo par nom de matériau (V4 lot 13, héros) : la
## capuche est re-teinte DANS une texture dérivée committée — la peau et
## le cuir restent intacts, contrairement à une teinte globale.
@export var albedo_substitutions: Dictionary[String, Texture2D] = {}
## Matériaux RÉTRACTÉS le long des normales (grow négatif) : le corps de
## base porté SOUS la tenue ne doit jamais transpercer le tissu — un
## z-fighting peau/vêtement scintillerait en mouvement (§21.8).
@export var shrink_materials: PackedStringArray = PackedStringArray()

const SHRINK_AMOUNT: float = -0.008

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
	# Les greffes précèdent teinte et substitutions : les pièces reçoivent
	# le même traitement de matériaux que le costume de base.
	for part_scene: PackedScene in modular_parts:
		_graft_part(part_scene)
	# TOUJOURS : §5.4 — « deux exemplaires ne partagent jamais leur
	# matériau ». La duplication n'était déclenchée que par une teinte ou
	# une substitution ; les modèles de la Phase H portent leur couleur
	# dans leur propre matériau, donc plus de teinte, donc plus de
	# duplication — et le télégraphe de combat, qui écrit dans les
	# matériaux d'instance, n'avait soudain plus rien où écrire.
	_isolate_materials()


## Greffe les maillages skinnés d'une pièce modulaire sur le squelette du
## modèle. Les poses de bind sont identiques (squelette UAL 65 os partagé,
## vérifié au catalogue) : le Skin importé résout directement.
func _graft_part(part_scene: PackedScene) -> void:
	if part_scene == null or _skeleton == null:
		return
	var part_root: Node = part_scene.instantiate()
	for node: Node in part_root.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		mesh.owner = null   # l'owner mourrait avec la racine de la pièce
		mesh.get_parent().remove_child(mesh)
		mesh.name = "Part_%s_%d" % [mesh.name, _skeleton.get_child_count()]
		_skeleton.add_child(mesh)
		mesh.skeleton = NodePath("..")
	part_root.free()


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


## Chaque surface reçoit une COPIE de son matériau, en surcharge
## d'instance. C'est la condition de §5.4, et c'est aussi ce qui donne au
## télégraphe d'attaque et au flash de dégâts une surface où écrire sans
## repeindre tous les pillards de la scène.
func _isolate_materials() -> void:
	for node: Node in find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		for surface: int in range(mesh.mesh.get_surface_count()
				if mesh.mesh != null else 0):
			var material: BaseMaterial3D = \
				mesh.get_active_material(surface) as BaseMaterial3D
			if material == null:
				continue
			var substitution: Texture2D = \
				albedo_substitutions.get(material.resource_name) as Texture2D
			var wants_tint: bool = tint != Color.WHITE \
				and (tint_material_filter.is_empty()
					or tint_material_filter.has(material.resource_name))
			var wants_shrink: bool = \
				shrink_materials.has(material.resource_name)
			var tinted: BaseMaterial3D = material.duplicate() as BaseMaterial3D
			if substitution != null:
				tinted.albedo_texture = substitution
			if wants_tint:
				tinted.albedo_color = material.albedo_color * tint
			if wants_shrink:
				tinted.grow = true
				tinted.grow_amount = SHRINK_AMOUNT
			mesh.set_surface_override_material(surface, tinted)


## Socket par nom (`SOCKET_HAND_R`, `SOCKET_BACK`, `SOCKET_BOW`) — null si
## le squelette ou l'os manquent : l'appelant garde son repli.
func socket(socket_name: String) -> BoneAttachment3D:
	if _skeleton == null:
		return null
	return _skeleton.get_node_or_null(socket_name) as BoneAttachment3D
