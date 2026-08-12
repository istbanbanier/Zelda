## LA CITADELLE N'EST PLUS UN EMPILEMENT DE BOÎTES — les trois propriétés
## qui se vérifient à la machine.
##
## POURQUOI CE TEST. L'audit du 2026-08-11 classe V-002 en P0 : « citadelle
## lue comme empilement de boîtes ». §2.4 demande « 10 % vides, arches et
## ruptures » et des silhouettes asymétriques. Or TOUTES les masses du
## `CitadelProxy` étaient des `_box_in` axés sur les axes du monde : zéro
## ouverture, zéro masse déviée, sommets plats en escalier. Un juge humain
## tranchera l'image ; ce test verrouille la STRUCTURE qui la rend possible :
##
##   1. des VIDES existent — au moins trois panneaux d'arche en retrait,
##      nettement plus sombres que la pierre de façade (la recette du
##      GateRecess : le vide se lit par la valeur) ;
##   2. l'ASYMÉTRIE existe — au moins trois masses d'échelle MURAILLE
##      (seuil mesuré sous « BIG_MASS_MIN_HEIGHT ») déviées d'au moins 8°
##      du quadrillage monde ;
##   3. les terrasses ne sont plus des BOÎTES — la grande masse frontale est
##      un tronc de pyramide (faces talutées), pas un rectangle extrudé.
##
## CE QUI EST INTERDIT D'OFFICE, et que ce test vérifie aussi : aucune des
## pièces nouvelles ne porte de collision. La leçon PT-D1-09 est gravée dans
## le code — une façade pivotée AVEC collision a déjà rendu l'anneau
## montagneux franchissable pour la sonde de bordure. Le décor tourne, le
## porteur jamais.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
## Hauteur en deçà de laquelle une masse déviée ne compte pas. Mesuré sur la
## scène AVANT correction : les toits pivotés des tours culminent à 10,7 m
## (TowerRoof2) — ce sont des chapeaux, pas les « grandes formes » de §2.4.
## Le seuil est posé JUSTE AU-DESSUS d'eux pour que le test exige des masses
## d'échelle muraille, pas un chapeau de plus.
const BIG_MASS_MIN_HEIGHT: float = 12.0


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _cleanup(world: Node) -> void:
	_tree().root.remove_child(world)
	world.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	var audio: Node = _tree().root.get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("stop_ambience"):
		audio.call("stop_ambience")
	await _tree().physics_frame


func _albedo(mesh: MeshInstance3D) -> Color:
	## Même précaution que `test_phase_h_silhouettes` : la recette painterly
	## convertit les matériaux au démarrage — lire le ShaderMaterial rendu,
	## et retomber sur le StandardMaterial3D si la pièce y a échappé.
	var material: Material = mesh.material_override
	if material == null:
		material = mesh.get_active_material(0)
	var shaded: ShaderMaterial = material as ShaderMaterial
	if shaded != null:
		var value: Variant = shaded.get_shader_parameter("albedo_color")
		if value is Color:
			return value as Color
	var standard: StandardMaterial3D = material as StandardMaterial3D
	if standard != null:
		return standard.albedo_color
	return Color(-1, -1, -1)


func test_the_citadel_has_arch_voids_darker_than_its_stone() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var citadel: Node3D = valley.get_node_or_null("Terrain/CitadelProxy") as Node3D
	check_not_null(citadel, "le proxy de citadelle existe")
	if citadel == null:
		await _cleanup(valley)
		return
	var keep: MeshInstance3D = citadel.get_node_or_null("Keep/KeepMesh") \
		as MeshInstance3D
	check_not_null(keep, "la pierre de façade témoin existe")
	var stone_luma: float = _albedo(keep).get_luminance() if keep != null else 1.0
	# « CitadelArch? » : UN caractère — le motif étoile attrapait aussi les
	# linteaux « CitadelArchCap0 », qui sont de la pierre, pas des vides.
	var arches: Array[Node] = citadel.find_children("CitadelArch?",
		"MeshInstance3D", true, false)
	check(arches.size() >= 3,
		"au moins trois vides d'arche (%d trouvés)" % arches.size())
	for arch: Node in arches:
		var luma: float = _albedo(arch as MeshInstance3D).get_luminance()
		check(luma < stone_luma * 0.5,
			"« %s » se lit comme un VIDE : luma %.3f < moitié de la pierre (%.3f)"
				% [arch.name, luma, stone_luma])
		check((arch as Node3D).find_children("*", "PhysicsBody3D", true, false)
			.is_empty() and not (arch.get_parent() is PhysicsBody3D),
			"« %s » est un décor sans collision" % arch.name)
	await _cleanup(valley)


func test_the_citadel_carries_big_masses_off_the_world_grid() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var citadel: Node3D = valley.get_node_or_null("Terrain/CitadelProxy") as Node3D
	check_not_null(citadel, "le proxy de citadelle existe")
	var deviated: Array[String] = []
	if citadel != null:
		for node: Node in citadel.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			var height: float = (mesh.get_aabb().size * mesh.scale).y
			if height < BIG_MASS_MIN_HEIGHT:
				continue
			var yaw: float = absf(wrapf(mesh.global_rotation.y, -PI, PI))
			# À 8° du quadrillage — et pas non plus à 90° pile, qui est
			# encore le quadrillage.
			var off_grid: float = minf(yaw, absf(yaw - PI * 0.5))
			if off_grid >= deg_to_rad(8.0):
				deviated.append(String(mesh.name))
				check(not (mesh.get_parent() is PhysicsBody3D),
					"la masse déviée « %s » ne porte PAS de collision (PT-D1-09)"
						% mesh.name)
	check(deviated.size() >= 3,
		"au moins trois grandes masses hors quadrillage (%d : %s)"
			% [deviated.size(), ", ".join(deviated) if not deviated.is_empty()
				else "aucune"])
	await _cleanup(valley)


func test_the_terraces_are_battered_frustums_not_boxes() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var citadel: Node3D = valley.get_node_or_null("Terrain/CitadelProxy") as Node3D
	check_not_null(citadel, "le proxy de citadelle existe")
	if citadel != null:
		for terrace_name: String in ["TerraceBase", "TerraceMid", "TerraceHigh"]:
			var terrace: MeshInstance3D = citadel.get_node_or_null(
				NodePath(terrace_name)) as MeshInstance3D
			check_not_null(terrace, "« %s » existe" % terrace_name)
			if terrace != null:
				check(not (terrace.mesh is BoxMesh),
					"« %s » n'est plus une boîte : faces talutées (%s)"
						% [terrace_name, terrace.mesh.get_class()])
	await _cleanup(valley)
