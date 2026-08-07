## Lot 12 — la falaise gauche cesse de BOUCHER et se met à GUIDER,
## avec de vrais modèles de falaise (Kenney Nature Kit CC0, déposé par
## le propriétaire). Fail-first : écrit avant l'implémentation.
##
## Le défaut est nommé depuis l'éval v5 : « la falaise gauche bouche
## sans guider (deux blocs plats) ». Contrats : les modèles existent et
## sont attribués ; leur échelle « tuile » (1 m natif) est CORRIGÉE par
## le point unique du projet (`KitScale`) vers les 6-28 m d'un module de
## falaise (bible §3) ; la formation descend en escalier vers la
## vallée ; et elle porte la peinture.
extends GateTestCase

const CLIFFS: String = "res://assets/environment/cliffs/"
const MODELS: Array[String] = [
	"cliff_large_rock", "cliff_blockSlope_rock", "cliff_half_rock",
	"cliff_corner_rock", "cliff_cornerLarge_rock",
	"rock_largeA", "rock_largeC", "rock_smallB",
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


func test_the_cliff_models_exist_and_are_attributed() -> void:
	for model: String in MODELS:
		check(ResourceLoader.exists(CLIFFS + model + ".glb"),
			"%s présent" % model)
	var file: FileAccess = FileAccess.open("res://ATTRIBUTIONS.md",
		FileAccess.READ)
	check(file != null, "ATTRIBUTIONS.md lisible")
	if file != null:
		var text: String = file.get_as_text()
		file.close()
		check("Kenney" in text and "CC0" in text,
			"Kenney et sa licence CC0 sont inscrits AVANT le build")
		check("assets/environment/cliffs" in text,
			"le dossier cible est nommé dans ATTRIBUTIONS")
	await _settle(1)


func test_the_tile_scale_is_corrected_in_one_place() -> void:
	# Le kit Kenney est autoré à l'échelle « tuile » : un bloc de
	# falaise mesure 1 m de haut. Posé tel quel, il ferait un caillou
	# devant un héros d'1,78 m. La correction vit dans KitScale — le
	# point UNIQUE du projet — jamais recopiée sur chaque site d'appel.
	for model: String in ["cliff_large_rock", "cliff_blockSlope_rock"]:
		var factor: float = KitScale.factor(model)
		check(factor > 3.0,
			"%s est agrandi (facteur %.2f > 3)" % [model, factor])
	check(KitScale.factor("rock_smallB") < 6.0,
		"un petit rocher ne devient PAS une falaise (%.2f)"
		% KitScale.factor("rock_smallB"))
	await _settle(1)


func test_the_left_cliff_is_a_real_stepped_formation() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var lab: HeroShotLab = (load(LAB) as PackedScene).instantiate() \
		as HeroShotLab
	_root.add_child(lab)
	await _settle(6)
	var formation: Node3D = lab.get_node_or_null("CliffFormation") as Node3D
	check(formation != null, "la formation de falaise existe")
	if formation == null:
		await _teardown()
		return
	var steps: Array[Node3D] = []
	for child: Node in formation.get_children():
		var item: Node3D = child as Node3D
		if item != null:
			steps.append(item)
	check(steps.size() >= 4,
		"au moins quatre modules composent la formation (%d)" % steps.size())
	# Elle DESCEND vers la vallée : plus on s'éloigne (z décroissant),
	# plus le sommet du module est bas par rapport à la pente.
	var heights: Array[float] = []
	for step: Node3D in steps:
		var aabb: AABB = _bounds(step)
		if aabb.size == Vector3.ZERO:
			continue
		var top: float = step.position.y + aabb.end.y * step.scale.y
		heights.append(top)
		# Bible §3, DEUX bandes distinctes : un module de falaise fait
		# 6-28 m, un rocher proche 0,15-4 m. Une bande unique était un
		# défaut de CE test (il refusait des rochers légitimes).
		var height_m: float = aabb.size.y * step.scale.y
		var is_rock: bool = String(step.name).to_lower().contains("rock") \
			and not String(step.name).to_lower().contains("cliff")
		var low: float = 0.15 if is_rock else 2.0
		var high: float = 4.0 if is_rock else 28.0
		check(height_m >= low and height_m <= high,
			"%s : hauteur crédible %.1f m (%s : %.2f-%.0f)"
			% [step.name, height_m, "rocher" if is_rock else "falaise",
				low, high])
	check(heights.size() >= 4, "les modules ont une géométrie mesurable")
	await _teardown()


func test_the_formation_is_painted() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var lab: HeroShotLab = (load(LAB) as PackedScene).instantiate() \
		as HeroShotLab
	_root.add_child(lab)
	await _settle(6)
	var formation: Node3D = lab.get_node_or_null("CliffFormation") as Node3D
	if formation == null:
		check(false, "pas de formation")
		await _teardown()
		return
	var painted: int = 0
	var bare: Array[String] = []
	for node: Node in formation.find_children("*", "MeshInstance3D",
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
		"toute la formation est peinte — nues : %s"
		% ", ".join(bare.slice(0, 6)))
	check(painted >= 4, "la peinture couvre la formation (%d surfaces)"
		% painted)
	await _teardown()


func _bounds(node: Node3D) -> AABB:
	var total: AABB = AABB()
	var first: bool = true
	for child: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = child as MeshInstance3D
		if mesh.mesh == null:
			continue
		var box: AABB = mesh.mesh.get_aabb()
		if first:
			total = box
			first = false
		else:
			total = total.merge(box)
	return total
