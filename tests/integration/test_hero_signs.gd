## Passe V3 (ROADMAP Cycle 3) — les CINQ SIGNES du héros (bible §13.1) :
## reconnu DE DOS par (1) mantelet turquoise court à deux pointes
## INÉGALES, (2) épaulière unique ivoire/bronze du côté OPPOSÉ au
## Bracelet, (3) Bracelet de Résonance à l'avant-bras GAUCHE, (4-5)
## diagonale arc/carquois en X incomplet. Fail-first : écrit avant
## l'implémentation.
##
## Les signes sont des volumes graybox attachés aux OS (`HeroSigns`,
## réutilisable par le jeu quand Player recevra le modèle). Les contrats
## vérifient : présence et os porteurs, latéralité §13.1 (Bracelet à
## gauche, épaulière à droite), langage couleur §1.4 (turquoise héros ≠
## cyan électrique, émission du Bracelet DISCRÈTE), et la promesse de
## silhouette (X dans le dos, pointes inégales). Le test de silhouette
## §30.3 complet (aplats à 3/10/25 m) reste machine utilisateur.
extends GateTestCase

const LAB: String = "res://scenes/lookdev/HeroShotLab.tscn"
## Turquoise héros §1.4 : #168F9B.
const TURQUOISE: Color = Color(0.086, 0.561, 0.608)
## Cyan électrique §1.4 : #22D9EC — le mantelet ne doit PAS être lui.
const ELECTRIC: Color = Color(0.133, 0.851, 0.925)

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	await _settle(3)


func _open_skeleton() -> Skeleton3D:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var lab: Node3D = (load(LAB) as PackedScene).instantiate() as Node3D
	_root.add_child(lab)
	await _settle(6)
	var hero: Node3D = lab.get_node_or_null("Hero") as Node3D
	if hero == null:
		return null
	for node: Node in hero.find_children("*", "Skeleton3D", true, false):
		return node as Skeleton3D
	return null


## `Color` n'a pas de `distance_to` (vérifié 4.7.1) : écart RGB manuel.
func _color_gap(a: Color, b: Color) -> float:
	return Vector3(a.r, a.g, a.b).distance_to(Vector3(b.r, b.g, b.b))


func _sign(skeleton: Skeleton3D, sign_name: String) -> BoneAttachment3D:
	if skeleton == null:
		return null
	return skeleton.get_node_or_null(sign_name) as BoneAttachment3D


func test_the_five_signs_exist_on_their_bones() -> void:
	var skeleton: Skeleton3D = await _open_skeleton()
	check(skeleton != null, "le héros du lab a un squelette")
	var expected: Dictionary = {
		"Mantelet": "spine_03",
		"Epauliere": "clavicle_r",
		"BraceletResonance": "lowerarm_l",
		"ArcDos": "spine_02",
		"Carquois": "spine_02",
	}
	for sign_name: String in expected:
		var attachment: BoneAttachment3D = _sign(skeleton, sign_name)
		check(attachment != null, "le signe %s existe" % sign_name)
		if attachment == null:
			continue
		check(attachment.bone_name == String(expected[sign_name]),
			"%s porté par l'os %s (obtenu %s)"
			% [sign_name, expected[sign_name], attachment.bone_name])
		check(attachment.get_child_count() >= 1,
			"%s a un volume visible" % sign_name)
	await _teardown()


func test_the_laterality_matches_the_bible() -> void:
	## §13.1 : Bracelet à l'avant-bras GAUCHE, épaulière du côté OPPOSÉ.
	var skeleton: Skeleton3D = await _open_skeleton()
	var bracelet: BoneAttachment3D = _sign(skeleton, "BraceletResonance")
	var pauldron: BoneAttachment3D = _sign(skeleton, "Epauliere")
	check(bracelet != null and pauldron != null, "les deux signes existent")
	if bracelet == null or pauldron == null:
		await _teardown()
		return
	check(bracelet.bone_name.ends_with("_l"),
		"le Bracelet est à GAUCHE (%s)" % bracelet.bone_name)
	check(pauldron.bone_name.ends_with("_r"),
		"l'épaulière est du côté OPPOSÉ (%s)" % pauldron.bone_name)
	await _teardown()


func test_the_colors_speak_the_anchor_palette() -> void:
	## §1.4 : turquoise héros #168F9B — et JAMAIS le cyan électrique
	## #22D9EC ; épaulière ivoire ; émission du Bracelet discrète.
	var skeleton: Skeleton3D = await _open_skeleton()
	var mantle: BoneAttachment3D = _sign(skeleton, "Mantelet")
	check(mantle != null, "mantelet présent")
	if mantle == null:
		await _teardown()
		return
	var mantle_mesh: MeshInstance3D = null
	for child: Node in mantle.find_children("*", "MeshInstance3D", true, false):
		mantle_mesh = child as MeshInstance3D
		break
	var mantle_color: Color = (mantle_mesh.material_override
		as StandardMaterial3D).albedo_color
	check(_color_gap(mantle_color, TURQUOISE) < 0.22,
		"le mantelet est turquoise héros (écart %.2f)"
		% _color_gap(mantle_color, TURQUOISE))
	check(_color_gap(mantle_color, ELECTRIC) > 0.3,
		"…et n'est PAS le cyan électrique (écart %.2f)"
		% _color_gap(mantle_color, ELECTRIC))
	var bracelet: BoneAttachment3D = _sign(skeleton, "BraceletResonance")
	var glow_energy: float = -1.0
	for child: Node in bracelet.find_children("*", "MeshInstance3D", true, false):
		var material: StandardMaterial3D = (child as MeshInstance3D) \
			.material_override as StandardMaterial3D
		if material != null and material.emission_enabled:
			glow_energy = material.emission_energy_multiplier
	check(glow_energy > 0.0 and glow_energy <= 1.2,
		"le canal du Bracelet émet DISCRÈTEMENT (%.2f ≤ 1,2 — §13.5 : "
		% glow_energy + "au repos, respiration presque imperceptible)")
	await _teardown()


func test_the_back_promises_the_x_and_unequal_points() -> void:
	## §13.1 : arc et carquois en DIAGONALES OPPOSÉES (le X incomplet) ;
	## mantelet à deux pointes INÉGALES.
	var skeleton: Skeleton3D = await _open_skeleton()
	var bow: BoneAttachment3D = _sign(skeleton, "ArcDos")
	var quiver: BoneAttachment3D = _sign(skeleton, "Carquois")
	check(bow != null and quiver != null, "arc et carquois présents")
	if bow == null or quiver == null:
		await _teardown()
		return
	# L'élément le PLUS diagonal de chaque signe (le carquois porte aussi
	# un empennage droit — c'est le tube qui fait la diagonale).
	var bow_roll: float = 0.0
	var quiver_roll: float = 0.0
	for child: Node in bow.get_children():
		if absf((child as Node3D).rotation_degrees.z) > absf(bow_roll):
			bow_roll = (child as Node3D).rotation_degrees.z
	for child: Node in quiver.get_children():
		if absf((child as Node3D).rotation_degrees.z) > absf(quiver_roll):
			quiver_roll = (child as Node3D).rotation_degrees.z
	check(absf(bow_roll) > 8.0 and absf(quiver_roll) > 8.0,
		"les deux sont en DIAGONALE (%.0f° / %.0f°)"
		% [bow_roll, quiver_roll])
	check(signf(bow_roll) != signf(quiver_roll),
		"…et en diagonales OPPOSÉES : le X du dos")
	var mantle: BoneAttachment3D = _sign(skeleton, "Mantelet")
	var points: Array[float] = []
	for child: Node in mantle.find_children("Pointe*", "MeshInstance3D",
			true, false):
		var mesh: MeshInstance3D = child as MeshInstance3D
		points.append((mesh.mesh as BoxMesh).size.y)
	check(points.size() == 2, "le mantelet a DEUX pointes (%d)" % points.size())
	if points.size() == 2:
		check(absf(points[0] - points[1]) > 0.05,
			"…de longueurs INÉGALES (%.2f / %.2f)" % [points[0], points[1]])
	await _teardown()
