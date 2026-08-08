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
	# V5 — l'os qui portait le vide. Voir `head_part` ci-dessous.
	"SOCKET_HEAD": "Head",
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

## TÊTE portée par l'os `Head` (V5).
##
## Défaut mesuré au playtest humain du 2026-08-07 : « NI le héros NI les
## ennemis n'ont de tête. Le capuchon du héros est CREUX et VIDE. » Vérifié
## dans les sources : `Male_Ranger.gltf` ne livre que la CAPUCHE
## (`Male_Ranger_Head_Hood`) et `Male_Peasant.gltf` ne livre rien du tout
## au-dessus du cou. Le défaut est visible de profil, donc en permanence —
## verbatim du testeur : « je ne regardais plus un jeu, je regardais un
## chantier ».
##
## La tête est un maillage STATIQUE exprimé dans le repère de l'os `Head`
## (`tools/extract_head.py`), donc portée par un `BoneAttachment3D` et non
## greffée comme `modular_parts`, qui n'accepte que des maillages skinnés.
## Un crâne ne se déforme pas : l'attachement suffit et coûte moins qu'un skin.
@export var head_part: PackedScene = null
## Albédo de la tête — la teinte de peau appartient à la variante, pas au
## maillage : le même crâne sert au héros et aux trois pillards.
@export var head_texture: Texture2D = null
## Teinte multipliée sur la tête. Sert aux variantes de pillard, dont la
## carnation doit se distinguer de celle du héros sans dupliquer le maillage.
@export var head_tint: Color = Color.WHITE
## Retouche d'artiste sur la taille de la tête. 1.0 = taille déduite du
## squelette, ce qui est le cas voulu ; ce curseur n'existe que pour un
## ajustement de goût, jamais pour rattraper une erreur de montage.
@export var head_scale: float = 1.0
## Décalage de la tête le long de l'os, en unités LOCALES.
##
## Zéro pour le héros, ≈ −0,11 pour les pillards, et ce n'est pas un réglage
## de goût : les deux familles ne posent pas leur os `Head` au même endroit.
## Le rig du héros (Quaternius) place l'os à la BASE du crâne, qui s'élève donc
## entièrement au-dessus. Le générateur des pillards
## (`tools/blender/make_raiders.py`) centre au contraire son moignon SUR l'os,
## qui déborde autant en dessous qu'au-dessus.
##
## Sans ce décalage, le crâne monte d'une demi-tête trop haut : le pillard
## braise passait de 1,42 m à 1,61 m et sortait de la fourchette 1,40-1,52 de
## la bible §14.1 — mesuré par `test_raider_visual`, qui a eu raison de le
## refuser. Avec, le crâne occupe EXACTEMENT le volume du moignon qu'il
## remplace, et la silhouette des trois familles est celle d'avant.
@export var head_offset: float = 0.0

## Hauteur de l'os `Head` du HÉROS, au repos, dans le modèle de référence
## (`Male_Ranger.gltf`) — c'est la stature pour laquelle la tête extraite a été
## découpée. Les pillards sont plus petits ou plus grands : leur squelette
## porte la mesure, et le rapport donne l'échelle. Rien n'est saisi à la main,
## donc rien ne peut dériver quand un modèle change.
const HEAD_REFERENCE_HEIGHT: float = 1.5986

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
	_mount_head()
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


## Pose la tête sur le socket `SOCKET_HEAD`.
##
## Le maillage est exprimé dans le repère de l'os : il se pose donc à
## l'identité, sans décalage à régler à la main. Toute correction ici
## trahirait une erreur d'extraction — c'est délibérément rigide.
func _mount_head() -> void:
	if head_part == null:
		return
	var mount: BoneAttachment3D = socket("SOCKET_HEAD")
	if mount == null:
		push_warning("[model] pas de socket de tête : os `Head` absent.")
		return
	var head: Node3D = head_part.instantiate() as Node3D
	head.name = "Head"
	mount.add_child(head)
	# Mise à l'échelle DÉDUITE de la stature du porteur (voir la constante) :
	# 0,82 pour le pillard braise, 1,10 pour le briseur, 1,00 pour le héros.
	var bone: int = _skeleton.find_bone("Head")
	if bone >= 0:
		var rest_height: float = _skeleton.get_bone_global_rest(bone).origin.y
		if rest_height > 0.01:
			head.scale = Vector3.ONE \
				* (rest_height / HEAD_REFERENCE_HEIGHT) * head_scale
	head.position = Vector3(0.0, head_offset, 0.0)
	if head_texture == null and head_tint == Color.WHITE:
		return
	for node: Node in head.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		for surface: int in range(mesh.mesh.get_surface_count()
				if mesh.mesh != null else 0):
			var material: BaseMaterial3D = \
				mesh.get_active_material(surface) as BaseMaterial3D
			if material == null:
				continue
			# Comme partout ici (§5.4) : une COPIE par exemplaire, jamais la
			# ressource partagée — deux pillards ne se repeignent pas l'un
			# l'autre.
			var own: BaseMaterial3D = material.duplicate() as BaseMaterial3D
			if head_texture != null:
				own.albedo_texture = head_texture
			own.albedo_color = material.albedo_color * head_tint
			mesh.set_surface_override_material(surface, own)


## Encombrement MONDIAL de la tête montée — boîte vide si aucune.
##
## C'est la mesure qui dit « un crâne de la taille d'un crâne », et elle vaut
## quelle que soit la façon dont il est posé sur l'os. La hauteur au-dessus du
## socket, elle, ne vaut rien : le héros porte son crâne entièrement au-dessus
## de l'os, les pillards à cheval dessus (voir `head_offset`) — deux tests de
## cette session ont conclu à tort avec cette mesure-là.
func head_bounds() -> AABB:
	var mount: BoneAttachment3D = socket("SOCKET_HEAD")
	if mount == null:
		return AABB()
	var head: Node = mount.get_node_or_null("Head")
	if head == null:
		return AABB()
	var bounds: AABB = AABB()
	var started: bool = false
	for node: Node in head.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var world: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = world if not started else bounds.merge(world)
		started = true
	return bounds


## Position mondiale du sommet du crâne — lue par les tests : c'est la seule
## mesure qui distingue « une tête existe » de « une tête est au bon endroit ».
## Retourne un vecteur nul si aucune tête n'est montée.
func head_top() -> Vector3:
	var mount: BoneAttachment3D = socket("SOCKET_HEAD")
	if mount == null:
		return Vector3.ZERO
	var head: Node = mount.get_node_or_null("Head")
	if head == null:
		return Vector3.ZERO
	var top: float = -INF
	var found: bool = false
	for node: Node in head.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var box: AABB = mesh.get_aabb()
		var corner: Vector3 = mesh.global_transform \
			* (box.position + Vector3(box.size.x * 0.5, box.size.y, box.size.z * 0.5))
		found = true
		top = maxf(top, corner.y)
	return Vector3(0.0, top, 0.0) if found else Vector3.ZERO


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
