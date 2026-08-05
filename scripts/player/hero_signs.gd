## Les CINQ SIGNES du héros (bible §13.1) en volumes graybox attachés aux
## os — reconnu DE DOS par : mantelet turquoise court à deux pointes
## INÉGALES, épaulière unique ivoire/bronze du côté opposé au Bracelet,
## Bracelet de Résonance à l'avant-bras gauche, diagonale arc/carquois en
## X incomplet. Réutilisable : le lab l'utilise aujourd'hui, `Player`
## l'utilisera quand il recevra le modèle (Phase H).
##
## §1.4 : le turquoise HÉROS (#168F9B, désaturé) n'est jamais le cyan
## électrique (#22D9EC) ; le canal du Bracelet respire à peine au repos
## (§13.5). La passe matériaux remplacera les volumes, pas les os
## porteurs ni le langage.
class_name HeroSigns
extends Object

const TURQUOISE: Color = Color(0.10, 0.52, 0.56)
const IVORY: Color = Color(0.847, 0.784, 0.631)
const BRONZE: Color = Color(0.42, 0.30, 0.18)
const LEATHER: Color = Color(0.24, 0.16, 0.11)
const WOOD: Color = Color(0.35, 0.22, 0.13)
const CYAN: Color = Color(0.133, 0.851, 0.925)


## Attache les cinq signes au squelette. `hero` donne le repère du
## personnage (son dos = −Z modèle) pour placer en GLOBAL — les axes
## locaux des os d'un rig importé ne sont pas un repère fiable.
static func attach(skeleton: Skeleton3D, hero: Node3D) -> void:
	if skeleton == null or hero == null:
		return
	var back: Vector3 = -hero.global_transform.basis.z
	var right: Vector3 = hero.global_transform.basis.x
	var up: Vector3 = Vector3.UP

	# 1. Mantelet : plaque d'épaules + DEUX pointes inégales (§13.1).
	var mantle: BoneAttachment3D = _attachment(skeleton, "Mantelet",
		"spine_03")
	var mantle_plate: MeshInstance3D = _box("Plaque", Vector3(0.54, 0.30, 0.12),
		TURQUOISE)
	mantle.add_child(mantle_plate)
	# La plaque COUVRE les épaules et épouse le dos (leçon capture v4 :
	# trop basse et décollée, elle lisait « sac à dos »).
	mantle_plate.global_position = mantle.global_position + up * 0.24 \
		+ back * 0.10
	var point_long: MeshInstance3D = _box("PointeLongue",
		Vector3(0.17, 0.38, 0.10), TURQUOISE)
	mantle.add_child(point_long)
	point_long.global_position = mantle.global_position - right * 0.11 \
		- up * 0.02 + back * 0.13
	var point_short: MeshInstance3D = _box("PointeCourte",
		Vector3(0.15, 0.24, 0.10), TURQUOISE)
	mantle.add_child(point_short)
	point_short.global_position = mantle.global_position + right * 0.12 \
		+ up * 0.05 + back * 0.13

	# 2. Épaulière unique, côté OPPOSÉ au Bracelet (§13.1).
	var pauldron: BoneAttachment3D = _attachment(skeleton, "Epauliere",
		"clavicle_r")
	var pauldron_plate: MeshInstance3D = _box("Coque",
		Vector3(0.27, 0.11, 0.25), IVORY)
	pauldron.add_child(pauldron_plate)
	pauldron_plate.global_position = pauldron.global_position \
		+ right * 0.12 + up * 0.12
	var pauldron_trim: MeshInstance3D = _box("Liseret",
		Vector3(0.29, 0.035, 0.27), BRONZE)
	pauldron.add_child(pauldron_trim)
	pauldron_trim.global_position = pauldron_plate.global_position \
		- up * 0.07

	# 3. Bracelet de Résonance, avant-bras GAUCHE (§13.5).
	var bracelet: BoneAttachment3D = _attachment(skeleton,
		"BraceletResonance", "lowerarm_l")
	var cuff: MeshInstance3D = _box("Manchon", Vector3(0.13, 0.15, 0.13),
		LEATHER)
	bracelet.add_child(cuff)
	cuff.global_position = bracelet.global_position - right * 0.13
	var plate: MeshInstance3D = _box("PlaqueIvoire",
		Vector3(0.145, 0.10, 0.145), IVORY)
	bracelet.add_child(plate)
	plate.global_position = cuff.global_position + up * 0.01
	var channel: MeshInstance3D = _box("Canal", Vector3(0.15, 0.025, 0.05),
		CYAN)
	var channel_material: StandardMaterial3D = channel.material_override \
		as StandardMaterial3D
	channel_material.emission_enabled = true
	channel_material.emission = CYAN
	# §13.5 : au repos, respiration PRESQUE imperceptible.
	channel_material.emission_energy_multiplier = 0.8
	bracelet.add_child(channel)
	channel.global_position = cuff.global_position + up * 0.05

	# 4-5. La diagonale arc/carquois : le X incomplet du dos (§13.1).
	var bow: BoneAttachment3D = _attachment(skeleton, "ArcDos", "spine_02")
	var bow_stave: MeshInstance3D = _box("Fut", Vector3(0.055, 1.42, 0.055),
		WOOD)
	bow.add_child(bow_stave)
	bow_stave.global_position = bow.global_position + back * 0.22 \
		- right * 0.06 + up * 0.10
	bow_stave.rotation_degrees = Vector3(0.0, 0.0, 28.0)
	var quiver: BoneAttachment3D = _attachment(skeleton, "Carquois",
		"spine_02")
	var tube: MeshInstance3D = _box("Tube", Vector3(0.13, 0.52, 0.13),
		LEATHER)
	quiver.add_child(tube)
	tube.global_position = quiver.global_position + back * 0.19 \
		+ right * 0.13 + up * 0.05
	tube.rotation_degrees = Vector3(0.0, 0.0, -20.0)
	var fletching: MeshInstance3D = _box("Empennes",
		Vector3(0.10, 0.14, 0.10), IVORY)
	quiver.add_child(fletching)
	fletching.global_position = tube.global_position + up * 0.33 \
		+ right * 0.12


static func _attachment(skeleton: Skeleton3D, sign_name: String,
		bone: String) -> BoneAttachment3D:
	var attachment: BoneAttachment3D = BoneAttachment3D.new()
	attachment.name = sign_name
	skeleton.add_child(attachment)
	attachment.bone_name = bone
	return attachment


static func _box(box_name: String, size: Vector3,
		colour: Color) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = box_name
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.82
	mesh.material_override = material
	return mesh
