## Phase H lot H.1 — le Gardien est un HERO ASSET, pas une capsule.
##
## L'ordre de la Phase H est explicite : « aucune capsule ni humanoïde
## générique comme personnage final », et VISUAL_ASSET_BIBLE §15.1 chiffre
## ce que le boss doit être. Ces tests mesurent le modèle RÉELLEMENT
## importé, jamais les constantes du script qui l'a produit.
##
## Le test le plus utile du lot est le dernier : une hurtbox doit se trouver
## DANS le corps qu'on voit. Un volume de combat qui flotte à côté du modèle
## est un mensonge que ni une capture ni une relecture n'attrapent — la
## géométrie, si.
extends GateTestCase

const VISUAL: String = "res://scenes/boss/GuardianVisual.tscn"
const GUARDIAN: String = "res://scenes/boss/StormGuardian.tscn"
const MODEL: String = "res://assets/characters/boss/SK_StormGuardian.glb"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open(path: String) -> Node3D:
	var scene: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(scene)
	await _settle(6)
	return scene


func _close(scene: Node) -> void:
	scene.get_parent().remove_child(scene)
	scene.queue_free()
	await _settle(2)


## Centre de la GÉOMÉTRIE d'un mesh, en monde. Après skinning, l'origine du
## nœud ne dit plus rien : c'est l'AABB qui porte la position réelle.
func _geometry_centre(mesh: MeshInstance3D) -> Vector3:
	if mesh == null or mesh.mesh == null:
		return Vector3.ZERO
	return (mesh.global_transform * mesh.get_aabb()).get_center()


## AABB de TOUS les meshes visibles, en coordonnées monde.
func _world_bounds(root: Node) -> AABB:
	var bounds: AABB = AABB()
	var first: bool = true
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var local: AABB = mesh.get_aabb()
		var world: AABB = mesh.global_transform * local
		if first:
			bounds = world
			first = false
		else:
			bounds = bounds.merge(world)
	return bounds


func test_the_model_is_delivered_and_imports_clean() -> void:
	check(ResourceLoader.exists(MODEL),
		"le .glb du Gardien est dans le dépôt")
	var visual: GuardianVisual = await _open(VISUAL) as GuardianVisual
	var meshes: Array[Node] = visual.find_children("*", "MeshInstance3D",
		true, false)
	check(meshes.size() >= 25,
		"%d meshes importés — la bête est découpée, pas monolithique"
		% meshes.size())
	# §7.15 : aucune caméra ni lumière exportée par accident.
	check(visual.find_children("*", "Camera3D", true, false).is_empty(),
		"aucune caméra dans le modèle")
	check(visual.find_children("*", "Light3D", true, false).is_empty(),
		"aucune lumière dans le modèle")
	check_not_null(AssetRegistry.resolve(&"char.boss_guardian"),
		"…et il est déclaré au registre d'assets")
	await _close(visual)


## VISUAL_ASSET_BIBLE §15.1 : « 8-10 m de long, 5,2-6 m de haut anneau
## fermé, largeur 5-7 m ». Mesuré sur la géométrie importée dans Godot,
## pas sur la sortie de Blender.
func test_the_guardian_matches_the_dimensions_the_bible_demands() -> void:
	var visual: GuardianVisual = await _open(VISUAL) as GuardianVisual
	var bounds: AABB = _world_bounds(visual)
	var length: float = bounds.size.z
	var width: float = bounds.size.x
	var height: float = bounds.size.y
	check(length >= 8.0 and length <= 10.0,
		"long %.2f m (bible §15.1 : 8-10)" % length)
	check(width >= 5.0 and width <= 7.0,
		"large %.2f m (bible §15.1 : 5-7)" % width)
	check(height >= 5.2 and height <= 6.0,
		"haut %.2f m (bible §15.1 : 5,2-6)" % height)
	# Règle assets §7.15 : bas de l'objet au sol.
	check(absf(bounds.position.y) < 0.15,
		"il POSE au sol : min Y = %.3f m" % bounds.position.y)
	await _close(visual)


## §15.1 de la bible : « six appuis », « queue segmentée », « anneau
## incomplet en trois segments », « noyau fendu ». Ces pièces existent par
## NOM, parce que le gameplay les manipule une par une.
func test_the_anatomy_the_bible_asks_for_is_actually_there() -> void:
	var visual: GuardianVisual = await _open(VISUAL) as GuardianVisual
	var names: Array[String] = visual.mesh_names()
	var joined: String = " ".join(names)
	for expected: String in ["Core", "CrystalA", "CrystalB",
			"GuardianHeadPlates", "GuardianShoulders", "GuardianTail",
			"GuardianTailFork", "GuardianCables"]:
		check(joined.contains(expected), "pièce « %s » présente" % expected)
	for i: int in range(3):
		check(joined.contains("GuardianRing%d" % i),
			"segment d'anneau %d présent (anneau INCOMPLET)" % i)
	for i: int in range(8):
		check(joined.contains("ArmourPlate%d" % i),
			"plaque d'armure %d détachable" % i)
	# Six appuis : deux antérieurs lourds, quatre porteurs.
	var legs: int = 0
	for name: String in names:
		if name.begins_with("Leg"):
			legs += 1
	check_equal(legs, 6, "six appuis (§15.1 : quatre pattes + deux membres)")
	await _close(visual)


## §16.4 : les cristaux n'existent visuellement qu'en phase 2.
func test_the_crystals_start_hidden_on_the_real_model() -> void:
	var visual: GuardianVisual = await _open(VISUAL) as GuardianVisual
	for name: String in ["CrystalA", "CrystalB"]:
		var crystal: MeshInstance3D = visual.mesh(name)
		check_not_null(crystal, "%s est dans le modèle" % name)
		check(not crystal.visible, "…et %s est caché au repos" % name)
	visual.set_crystal_visible("CrystalA", true)
	check(visual.mesh("CrystalA").visible, "…et il sort quand on le demande")
	await _close(visual)


## LE test du lot : les volumes de combat sont DANS le corps visible.
## Une hurtbox qui flotte à côté du modèle laisse le joueur frapper le vide
## — ou pire, être touché par rien.
func test_the_combat_volumes_sit_inside_the_body_you_can_see() -> void:
	var boss: StormGuardian = await _open(GUARDIAN) as StormGuardian
	var visual: GuardianVisual = boss.get_node("Pivot/GuardianVisual") \
		as GuardianVisual
	check_not_null(visual, "le Gardien porte bien le hero asset")
	var body_bounds: AABB = _world_bounds(visual)
	# Marge : le modèle a des creux, une boîte de collision ne les suit pas.
	var grown: AABB = body_bounds.grow(0.35)

	for path: String in ["Pivot/BodyHurtbox", "Pivot/CoreHurtbox",
			"Pivot/CrystalA", "Pivot/CrystalB"]:
		var area: Area3D = boss.get_node(path) as Area3D
		check(grown.has_point(area.global_position),
			"%s est dans le corps visible (%s)"
			% [path, area.global_position])

	# Le noyau doit être au STERNUM, pas au hasard dans la masse : on le
	# compare au mesh `Core` du modèle. On vise le CENTRE DE SA GÉOMÉTRIE,
	# pas l'origine du nœud : après skinning, tous les MeshInstance3D sont
	# à (0, 0, 0) et la forme vit dans leurs sommets. Comparer les origines
	# reviendrait à comparer sept fois le même point.
	check(_geometry_centre(visual.mesh("Core")).distance_to(
			(boss.get_node("Pivot/CoreHurtbox") as Area3D).global_position)
		< 1.0,
		"la hurtbox de noyau est à %.2f m du noyau MODÉLISÉ"
		% _geometry_centre(visual.mesh("Core")).distance_to(
			(boss.get_node("Pivot/CoreHurtbox") as Area3D).global_position))

	# Et les cristaux sur les cristaux.
	for name: String in ["CrystalA", "CrystalB"]:
		var area: Area3D = boss.get_node("Pivot/%s" % name) as Area3D
		var distance: float = _geometry_centre(visual.mesh(name)).distance_to(
			area.global_position)
		check(distance < 1.2,
			"la hurtbox %s est à %.2f m de son cristal" % [name, distance])

	# La collision ne doit couvrir que la masse centrale : ni la tête ni la
	# queue, sinon le joueur ne peut plus contourner la bête.
	var shape: CollisionShape3D = boss.get_node("CollisionShape3D") \
		as CollisionShape3D
	var box: BoxShape3D = shape.shape as BoxShape3D
	check(box.size.z < body_bounds.size.z * 0.75,
		"la collision (%.1f m) est plus courte que la bête (%.1f m) : on la contourne"
		% [box.size.z, body_bounds.size.z])
	await _close(boss)


## §16.3 : le noyau s'allume quand il est frappable. Sans ce retour, la
## fenêtre de mise à la terre serait invisible.
func test_the_core_lights_up_when_the_armour_opens() -> void:
	var boss: StormGuardian = await _open(GUARDIAN) as StormGuardian
	var visual: GuardianVisual = boss.get_node("Pivot/GuardianVisual") \
		as GuardianVisual
	var core: MeshInstance3D = visual.mesh("Core")
	var material: StandardMaterial3D = core.material_override \
		as StandardMaterial3D
	check_not_null(material,
		"le noyau a son PROPRE matériau (jamais partagé, §5.4)")
	var dim: float = material.emission_energy_multiplier
	boss.call("_apply_armour", false)
	await _settle(2)
	check(material.emission_energy_multiplier > dim,
		"armure ouverte : le noyau s'allume (%.1f → %.1f)"
		% [dim, material.emission_energy_multiplier])
	boss.call("_apply_armour", true)
	await _settle(2)
	check_approx(material.emission_energy_multiplier, dim, 0.01,
		"armure refermée : il se rassombrit")
	await _close(boss)
