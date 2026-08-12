## AUCUN PORTEUR DE SOL N'EST REPEINT PAR LA PASSE COSMÉTIQUE.
##
## L'INCIDENT QUE CE TEST EMPÊCHE DE REVENIR, mesuré le 2026-08-11.
##
## `ValleyWorld._paint_the_world()` exemptait les sols par une LISTE DE NOMS
## écrite à la main. Elle citait douze dalles et pas UNE rampe. La rampe
## processionnelle de la citadelle, `DungeonRamp`, était donc repeinte : de la
## pierre rendue en VERT VIF. Repeinture en couleur impossible puis recapture
## (la méthode de `tools/CLAUDE.md`) :
##
##     avec la peinture   pixel (450, 400) = 140, 218, 82   un tapis vert
##     sans la peinture   pixel (450, 400) = 221, 176, 126  de la pierre
##
## Et la sonde d'emprise écran dit ce que ça pesait : `DungeonRampMesh`
## occupait **55,5 %** du cadre de la caméra d'approche de la citadelle. Le
## défaut le plus visible de la tranche d'ouverture tenait dans un nom absent
## d'un tableau.
##
## POURQUOI CE TEST ET PAS UN NOM DE PLUS DANS LA LISTE. Une liste de noms
## vit loin du code qui crée les nœuds ; rien ne relie les deux, donc elle
## dérive à la prochaine rampe. L'exemption est passée dans un GROUPE posé par
## `_slab()` et `_ramp()` eux-mêmes. Ce test vérifie les deux moitiés du
## contrat : le groupe contient bien tous les porteurs, et la peinture les
## respecte.
##
## CE QU'IL NE VÉRIFIE PAS : que la teinte obtenue soit belle. Il vérifie
## qu'une pierre reste une pierre.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"

## Porteurs de sol dont l'absence serait une régression silencieuse. Ce sont
## les surfaces que le joueur FOULE sur les dix premières minutes ; une rampe
## repeinte s'y voit immédiatement.
const EXPECTED_CARRIERS: Array[String] = [
	"PlainSouth", "PlainNorth", "SpawnRidge", "SpawnSlope",
	"DescentA", "DescentB", "DescentC", "CampTerrace", "CampExit",
	"FordWest", "FordEast", "DungeonPlateau", "DungeonRamp", "PylonRamp",
]


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _cleanup(world: Node) -> void:
	_tree().root.remove_child(world)
	world.queue_free()
	var audio: Node = _tree().root.get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("stop_ambience"):
		audio.call("stop_ambience")
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _tree().physics_frame


func test_every_ramp_and_slab_is_declared_a_ground_carrier() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var carriers: Array[Node] = _tree().get_nodes_in_group(
		PainterlyRecipe.GROUND_CARRIER_GROUP)
	var names: Dictionary[String, bool] = {}
	for node: Node in carriers:
		names[String(node.name)] = true
	check(carriers.size() >= EXPECTED_CARRIERS.size(),
		"%d porteurs de sol déclarés" % carriers.size())
	for expected: String in EXPECTED_CARRIERS:
		check(names.has(expected),
			"« %s » porte le groupe des sols" % expected)
	await _cleanup(valley)


func test_no_ground_carrier_survives_the_painting_pass_as_a_shader() -> void:
	## LE TEST QUI ROUGISSAIT. Avant la correction, `DungeonRampMesh` portait
	## un `ShaderMaterial` de la recette painterly au lieu de son matériau
	## macro de roche — et c'est ce qui le rendait vert.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var painted_carriers: Array[String] = []
	var carriers: Array[Node] = _tree().get_nodes_in_group(
		PainterlyRecipe.GROUND_CARRIER_GROUP)
	# LE PIÈGE DU TEST QUI NE PEUT PAS ÉCHOUER (PROMPT4 §2), rencontré ici :
	# sans cette borne, retirer le groupe rendait la boucle VIDE et le test
	# passait au vert — mesuré sur le contrôle négatif, il était le seul des
	# trois à ne pas rougir alors que le défaut était présent.
	check(carriers.size() >= EXPECTED_CARRIERS.size(),
		"il y a des porteurs à inspecter (%d)" % carriers.size())
	for node: Node in carriers:
		for child: Node in node.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = child as MeshInstance3D
			if mesh.material_override is ShaderMaterial:
				painted_carriers.append(String(mesh.name))
				continue
			for surface: int in range(mesh.mesh.get_surface_count() if mesh.mesh != null else 0):
				if mesh.get_surface_override_material(surface) is ShaderMaterial:
					painted_carriers.append("%s[%d]" % [mesh.name, surface])
	check(painted_carriers.is_empty(),
		"aucun porteur de sol repeint (trouvés : %s)"
			% ("aucun" if painted_carriers.is_empty()
				else ", ".join(painted_carriers)))
	await _cleanup(valley)


func test_the_processional_ramp_keeps_a_rock_tint_not_a_grass_one() -> void:
	## Le symptôme, pas seulement sa cause : la rampe de la citadelle doit
	## rester une pierre. Un matériau de roche a le rouge DEVANT le vert ;
	## l'herbe l'inverse. C'est vrai de l'albédo comme de la texture macro,
	## et ça ne dépend d'aucune capture.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var mesh: MeshInstance3D = valley.find_child("DungeonRampMesh", true, false) \
		as MeshInstance3D
	check_not_null(mesh, "la rampe processionnelle existe")
	if mesh != null:
		var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		check_not_null(material,
			"…et porte encore un matériau standard, pas un shader de peinture")
		if material != null and material.albedo_texture is NoiseTexture2D:
			var image: Image = (material.albedo_texture as NoiseTexture2D).get_image()
			if image == null:
				await (material.albedo_texture as NoiseTexture2D).changed
				image = (material.albedo_texture as NoiseTexture2D).get_image()
			check_not_null(image, "…dont la texture macro est générée")
			if image != null:
				var sample: Color = image.get_pixel(
					image.get_width() / 2, image.get_height() / 2)
				check(sample.r > sample.g,
					"…de teinte ROCHE : r %.3f > v %.3f (l'herbe inverse)"
						% [sample.r, sample.g])
	await _cleanup(valley)
