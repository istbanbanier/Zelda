## Lot 13 — la rive prend vie : saules, souches moussues, troncs
## (Quaternius Ultimate Nature CC0, déposé par le propriétaire).
## Fail-first : écrit avant l'implémentation.
##
## Deux difficultés réelles, contractualisées ici : le format OBJ
## s'importe en **Mesh** et non en scène (vérifié dans le `.import`
## généré), et le kit est autoré à une échelle qui n'est pas la nôtre
## (un saule fait 2,85 m natif contre 5-12 m pour un arbre, bible §3).
extends GateTestCase

const RIVERSIDE: String = "res://assets/environment/riverside/"
const MODELS: Array[String] = [
	"Willow_1", "Willow_3", "Willow_5", "Rock_Moss_2", "Rock_Moss_5",
	"TreeStump_Moss", "WoodLog_Moss", "BushBerries_1",
]
const LAB: String = "res://scenes/lookdev/HeroShotLab.tscn"
const PAINTERLY: String = \
	"res://shaders/characters/SH_CharacterPainterly.gdshader"
const PAINTERLY_CUTOUT: String = \
	"res://shaders/characters/SH_CharacterPainterlyCutout.gdshader"

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


func test_the_models_load_as_meshes_and_are_attributed() -> void:
	for model: String in MODELS:
		var path: String = RIVERSIDE + model + ".obj"
		check(ResourceLoader.exists(path), "%s présent" % model)
		# Le contrat de FORMAT : un .obj donne un Mesh, pas une scène.
		# Le chargeur du lab doit donc gérer les deux — le supposer
		# aurait donné un habillage vide en silence.
		var resource: Resource = load(path)
		check(resource is Mesh,
			"%s se charge en Mesh (contrat du format OBJ)" % model)
	var file: FileAccess = FileAccess.open("res://ATTRIBUTIONS.md",
		FileAccess.READ)
	if file != null:
		var text: String = file.get_as_text()
		file.close()
		check("assets/environment/riverside" in text,
			"le dossier cible est inscrit dans ATTRIBUTIONS")
		check("Quaternius" in text and "CC0" in text,
			"l'auteur et la licence sont nommés AVANT le build")
	await _settle(1)


func test_the_willows_reach_a_real_tree_height() -> void:
	for willow: String in ["Willow_1", "Willow_3", "Willow_5"]:
		var factor: float = KitScale.factor(willow)
		check(factor > 1.5,
			"%s est agrandi vers un vrai arbre (facteur %.2f)"
			% [willow, factor])
		var mesh: Mesh = load(RIVERSIDE + willow + ".obj") as Mesh
		if mesh == null:
			continue
		var height: float = mesh.get_aabb().size.y * factor
		# Bible §3 : arbre 5-12 m (spécimens héros jusqu'à 17 m).
		check(height >= 5.0 and height <= 12.0,
			"%s : %.1f m, dans la bande arbre 5-12 m" % [willow, height])
	# Un caillou ne devient pas un arbre.
	check(KitScale.factor("Rock_Moss_2") < 2.0,
		"les rochers moussus gardent leur taille (%.2f)"
		% KitScale.factor("Rock_Moss_2"))
	await _settle(1)


func test_the_riverside_is_planted_and_painted() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var lab: HeroShotLab = (load(LAB) as PackedScene).instantiate() \
		as HeroShotLab
	_root.add_child(lab)
	await _settle(6)
	var riverside: Node3D = lab.get_node_or_null("Riverside") as Node3D
	check(riverside != null, "le nœud Riverside existe")
	if riverside == null:
		await _teardown()
		return
	var willows: int = 0
	var painted: int = 0
	var bare: Array[String] = []
	for child: Node in riverside.get_children():
		if String(child.name).contains("Willow"):
			willows += 1
	check(willows >= 3, "au moins trois saules plantés (%d)" % willows)
	for node: Node in riverside.find_children("*", "MeshInstance3D",
			true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null:
			continue
		for s: int in range(mesh.mesh.get_surface_count()):
			var material: ShaderMaterial = \
				mesh.get_surface_override_material(s) as ShaderMaterial
			if material != null and material.shader != null \
					and material.shader.resource_path in \
						[PAINTERLY, PAINTERLY_CUTOUT]:
				painted += 1
			else:
				bare.append("%s/s%d" % [mesh.name, s])
	check(bare.is_empty(),
		"toute la rive est peinte — nues : %s" % ", ".join(bare.slice(0, 6)))
	check(painted >= 6, "la peinture couvre la rive (%d surfaces)" % painted)
	await _teardown()


func test_the_riverside_stays_near_the_water_and_out_of_the_windows() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var lab: HeroShotLab = (load(LAB) as PackedScene).instantiate() \
		as HeroShotLab
	_root.add_child(lab)
	await _settle(6)
	var riverside: Node3D = lab.get_node_or_null("Riverside") as Node3D
	var camera: Camera3D = lab.vista_camera()
	if riverside == null or camera == null:
		check(false, "rive ou caméra absente")
		await _teardown()
		return
	# Une rive, ça vit PRÈS de l'eau : chaque élément est à moins de
	# 22 m du tracé de la rivière — sinon ce ne sont que des arbres.
	var river: Array[Vector3] = lab.river_points()
	var far: Array[String] = []
	for child: Node in riverside.get_children():
		var item: Node3D = child as Node3D
		if item == null:
			continue
		var best: float = 1e9
		for point: Vector3 in river:
			best = minf(best, item.global_position.distance_to(point))
		if best > 22.0:
			far.append("%s (%.0f m)" % [item.name, best])
	check(far.is_empty(),
		"tout vit près de l'eau — trop loin : %s" % ", ".join(far.slice(0, 5)))
	# Et rien ne bouche les focales protégées §1.1.
	var guarded: Array[Array] = [
		[36.0, 46.0, 5.5], [59.0, 68.0, 88.0],
		[73.0, 81.0, 130.0], [46.0, 55.0, 315.0],
	]
	var blocking: Array[String] = []
	for child: Node in riverside.get_children():
		var item: Node3D = child as Node3D
		if item == null or camera.is_position_behind(
				item.global_position + Vector3(0, 2.0, 0)):
			continue
		var world: Vector3 = item.global_position + Vector3(0, 2.0, 0)
		var screen: Vector2 = camera.unproject_position(world)
		var size: Vector2 = camera.get_viewport().get_visible_rect().size
		var x_pct: float = screen.x / size.x * 100.0
		var depth: float = camera.global_position.distance_to(world)
		for window: Array in guarded:
			if x_pct > float(window[0]) and x_pct < float(window[1]) \
					and depth < float(window[2]):
				blocking.append("%s (X %.0f %%)" % [item.name, x_pct])
	check(blocking.is_empty(),
		"aucune focale §1.1 bouchée — en faute : %s"
		% ", ".join(blocking.slice(0, 5)))
	await _teardown()
