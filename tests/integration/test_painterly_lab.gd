## Lot 4 — extension du painterly à TOUT le lab (AD-004, étape 1 du
## reste consigné). Fail-first : écrit avant l'implémentation.
##
## Contrat : toute surface du HeroShotLab porte la peinture (personnage
## ou feuillage venté), SAUF les émissives justifiées (rivière-guide,
## flamme du camp, couronne cyan du pylône) qui restent des
## StandardMaterial à émission RÉELLEMENT active — aucune surface mate
## ne peut se cacher dans l'exception. Le nuage d'orage (StormCell,
## partagé avec la vallée) et les signes du héros sont hors périmètre.
extends GateTestCase

const PAINTERLY: String = \
	"res://shaders/characters/SH_CharacterPainterly.gdshader"
const PAINTERLY_CUTOUT: String = \
	"res://shaders/characters/SH_CharacterPainterlyCutout.gdshader"
const FOLIAGE: String = \
	"res://shaders/foliage/SH_FoliageWindPainterly.gdshader"
const LAB: String = "res://scenes/lookdev/HeroShotLab.tscn"

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


func _is_painted(material: Material) -> bool:
	var shader_material: ShaderMaterial = material as ShaderMaterial
	if shader_material == null or shader_material.shader == null:
		return false
	var path: String = shader_material.shader.resource_path
	return path == PAINTERLY or path == FOLIAGE \
		or path == PAINTERLY_CUTOUT


func _out_of_scope(node: Node, lab: Node) -> bool:
	var walker: Node = node
	while walker != null and walker != lab:
		if walker.name == "Hero" or walker.name == "Storm":
			return true
		if walker is BoneAttachment3D:
			return true
		walker = walker.get_parent()
	return false


func test_every_matte_surface_of_the_lab_is_painted() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var lab: Node3D = (load(LAB) as PackedScene).instantiate() as Node3D
	_root.add_child(lab)
	await _settle(6)
	var painted: int = 0
	var emissive: int = 0
	var naked: Array[String] = []
	for node: Node in lab.find_children("*", "VisualInstance3D", true, false):
		if _out_of_scope(node, lab):
			continue
		# Revue contradictoire : examiner CHAQUE surface (un matériau
		# logé dans la ressource Mesh ou sur la surface 1 passait
		# invisible — c'était le cas réel de la peau des bras du héros).
		var materials: Array[Material] = []
		if node is MeshInstance3D:
			var mesh: MeshInstance3D = node as MeshInstance3D
			if mesh.material_override != null:
				materials.append(mesh.material_override)
			elif mesh.mesh != null:
				for s: int in range(mesh.mesh.get_surface_count()):
					var override: Material = \
						mesh.get_surface_override_material(s)
					if override != null:
						materials.append(override)
					else:
						materials.append(mesh.mesh.surface_get_material(s))
		elif node is MultiMeshInstance3D:
			var multi: MultiMeshInstance3D = node as MultiMeshInstance3D
			if multi.material_override != null:
				materials.append(multi.material_override)
			elif multi.multimesh != null and multi.multimesh.mesh != null:
				for s: int in range(multi.multimesh.mesh.get_surface_count()):
					materials.append(
						multi.multimesh.mesh.surface_get_material(s))
		else:
			continue   # lumières, particules : pas des surfaces à peindre
		for material: Material in materials:
			if material == null:
				continue   # surface sans matière assignée (sondes, débug)
			if _is_painted(material):
				painted += 1
				continue
			var standard: StandardMaterial3D = material as StandardMaterial3D
			# Revue : le seul FLAG ne suffit pas — une surface quasi mate
			# se cachait dans l'exception. Elle doit émettre VRAIMENT.
			if standard != null and standard.emission_enabled \
					and standard.emission_energy_multiplier \
					* maxf(standard.emission.r,
						maxf(standard.emission.g, standard.emission.b)) \
					>= 0.5:
				emissive += 1
				continue
			naked.append(String(node.name))
	check(naked.is_empty(),
		"aucune surface mate sans peinture — restent : %s"
		% ", ".join(naked.slice(0, 12)))
	check(painted >= 30,
		"le lab est massivement peint (%d surfaces painterly)" % painted)
	check(emissive >= 2 and emissive <= 12,
		"les exceptions émissives restent RARES (%d — rivière, flamme, "
		% emissive + "couronne)")
	await _teardown()
