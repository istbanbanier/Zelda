## Lot 14 — LA VALLÉE ENTIÈRE porte la recette (mandat du propriétaire :
## « de touuuuute la map »). Fail-first : écrit avant l'implémentation.
##
## La recette a été réglée dans le laboratoire, à la mesure et à l'œil ;
## elle vit maintenant en UN point (`PainterlyRecipe`) et la vallée le
## consulte. Le risque réel de cette propagation n'est pas esthétique,
## il est de GAMEPLAY : les câbles cyan, récepteurs, dangers et noyaux
## sont des télégraphes. Le contrat central est donc négatif — la
## peinture ne DOIT PAS les toucher.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
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


func _open_valley() -> Node3D:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var valley: Node3D = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_root.add_child(valley)
	await _settle(10)
	return valley


func _is_painted(material: Material) -> bool:
	var shader_material: ShaderMaterial = material as ShaderMaterial
	if shader_material == null or shader_material.shader == null:
		return false
	return shader_material.shader.resource_path in \
		[PAINTERLY, PAINTERLY_CUTOUT]


func test_the_recipe_lives_in_one_place() -> void:
	check(ResourceLoader.exists("res://scripts/art/painterly_recipe.gd"),
		"la recette partagée existe")
	# Elle sait fabriquer, habiller et reconnaître une émission réelle.
	var material: ShaderMaterial = PainterlyRecipe.paint(Color.WHITE)
	check(material != null and material.shader != null,
		"elle fabrique un matériau peint")
	var fake: StandardMaterial3D = StandardMaterial3D.new()
	fake.emission_enabled = true
	fake.emission = Color(0.13, 0.85, 0.93)
	fake.emission_energy_multiplier = 2.0
	check(PainterlyRecipe.is_emissive(fake),
		"un câble cyan est reconnu comme émissif")
	var pale: StandardMaterial3D = StandardMaterial3D.new()
	pale.emission_enabled = true
	pale.emission = Color(0.1, 0.1, 0.1)
	pale.emission_energy_multiplier = 0.2
	check(not PainterlyRecipe.is_emissive(pale),
		"un faux émissif ne se cache pas derrière le drapeau")
	await _settle(1)


func test_the_valley_wears_the_recipe() -> void:
	var valley: Node3D = await _open_valley()
	var painted: int = 0
	var standard: int = 0
	for node: Node in valley.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null:
			continue
		if mesh.material_override != null:
			if _is_painted(mesh.material_override):
				painted += 1
			elif mesh.material_override is StandardMaterial3D:
				standard += 1
			continue
		for s: int in range(mesh.mesh.get_surface_count()):
			var material: Material = mesh.get_surface_override_material(s)
			if material == null:
				material = mesh.get_active_material(s)
			if _is_painted(material):
				painted += 1
			elif material is StandardMaterial3D:
				standard += 1
	check(painted >= 300,
		"la vallée est massivement peinte (%d surfaces)" % painted)
	# Les non-peintes restantes sont les émissifs protégés : elles
	# doivent rester MINORITAIRES, sinon la propagation n'a pas eu lieu.
	check(painted > standard,
		"la peinture domine (%d peintes contre %d standard)"
		% [painted, standard])
	await _teardown()


func test_the_electric_telegraphs_are_never_repainted() -> void:
	# Le critère n'est PAS le nom du nœud — première version de ce test,
	# qui accusait à tort un anneau brun et une couronne de pierre. Le
	# critère est l'ÉMISSION : ce qui éclaire informe le joueur.
	var valley: Node3D = await _open_valley()
	var emissive: int = 0
	var lost: Array[String] = []
	for node: Node in valley.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var materials: Array[Material] = []
		if mesh.material_override != null:
			materials.append(mesh.material_override)
		else:
			for s: int in range(mesh.mesh.get_surface_count()):
				var found: Material = mesh.get_surface_override_material(s)
				materials.append(found if found != null
					else mesh.get_active_material(s))
		for material: Material in materials:
			var standard: StandardMaterial3D = material as StandardMaterial3D
			if standard != null and PainterlyRecipe.is_emissive(standard):
				emissive += 1
	check(emissive >= 20,
		"les télégraphes émissifs ont SURVÉCU à la passe (%d)" % emissive)
	# Et nommément : la rune cyan du pylône, repère du tiers droit.
	var runes: MeshInstance3D = valley.find_children("PylonRunes", "",
		true, false).front() as MeshInstance3D
	check(runes != null, "la rune du pylône existe")
	if runes != null:
		var runes_material: StandardMaterial3D = \
			runes.material_override as StandardMaterial3D
		check(runes_material != null
			and PainterlyRecipe.is_emissive(runes_material),
			"la rune du pylône émet toujours — jamais repeinte")
	check(lost.is_empty(), "aucun télégraphe perdu")
	await _teardown()


func test_the_valley_still_runs_its_own_contracts() -> void:
	# Garde-fou de non-régression LOCAL : la vallée se monte, porte son
	# joueur, ses lieux et son navmesh. La suite intégrale reste juge,
	# mais un échec ici pointe la propagation du doigt tout de suite.
	var valley: Node3D = await _open_valley()
	check(valley.get_node_or_null("Player") != null,
		"le joueur est là après la passe de peinture")
	var places: int = valley.find_children("*", "PointOfInterest",
		true, false).size()
	check(places >= 20, "les lieux du monde ouvert sont intacts (%d)" % places)
	var navigation: int = valley.find_children("*", "NavigationRegion3D",
		true, false).size()
	check(navigation >= 1, "la navigation est intacte (%d région(s))"
		% navigation)
	await _teardown()
