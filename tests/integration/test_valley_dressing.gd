## Habillage V4.2 — eau, chemins, prairie partitionnée, montagnes habillées.
##
## Mesuré, pas décoratif : le ruban d'eau reste DANS le lit et sans collision
## (pas de nage cachée), la prairie est réellement partitionnée (§7.5) et posée
## sur la crête, les chemins sont visuels, les contreforts des montagnes
## portent une vraie collision `unclimbable` — aucun décor plat ne masque un
## vide accessible.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


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
	await _settle(2)


func test_the_river_ribbon_snakes_inside_the_bed_without_collision() -> void:
	## Réf. 01 : rivière turquoise en S. Chaque segment reste dans la bande du
	## lit, sous le niveau des gués, et AUCUN ne porte de collision — l'eau
	## V4.2 est un visuel assumé, pas une nage cachée.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var ribbons: Array[Node] = valley.find_children("WaterRibbon*", "MeshInstance3D",
		true, false)
	check(ribbons.size() >= 40, "le ruban couvre le lit (%d segments)" % ribbons.size())
	var meander_seen: bool = false
	for ribbon: Node in ribbons:
		var node: MeshInstance3D = ribbon as MeshInstance3D
		var z: float = node.global_position.z
		check(absf(z - 10.0) < 9.0,
			"segment DANS la bande du lit (z = %.1f)" % z)
		check(node.global_position.y < 0.0, "surface sous le niveau des gués")
		if absf(z - 10.0) > 2.0:
			meander_seen = true
		check(not (node.get_parent() is StaticBody3D) and
			node.find_children("*", "StaticBody3D", true, false).is_empty(),
			"aucune collision sur l'eau")
	check(meander_seen, "le ruban SERPENTE (des segments s'écartent de l'axe)")
	await _cleanup(valley)


func test_the_crest_meadow_is_partitioned_and_sits_on_the_ridge() -> void:
	## §7.5 : « ne jamais regrouper toute la vallée dans un MultiMesh unique »
	## — au moins deux cellules de brins + les fleurs, instances mesurées SUR
	## la crête (x ±50, z 148-205, y 32 depuis H-5), teintes variées par instance.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var meadow: Node3D = valley.find_children("CrestMeadow", "Node3D", true, false)[0] \
		as Node3D
	var cells: Array[Node] = meadow.find_children("Cell*", "MultiMeshInstance3D",
		false, false)
	check(cells.size() >= 2, "prairie PARTITIONNÉE : %d cellules" % cells.size())
	for cell: Node in cells:
		var multimesh: MultiMesh = (cell as MultiMeshInstance3D).multimesh
		check(multimesh.instance_count >= 300,
			"cellule dense (%d instances)" % multimesh.instance_count)
		# Headless : le RenderingServer factice ne relit pas les tampons
		# MultiMesh (identité mesurée) — le seam `origins`/`tints` est écrit
		# par la MÊME boucle qui remplit le tampon, et sa taille doit
		# correspondre exactement au tampon réel.
		var origins: PackedVector3Array = cell.get_meta(&"origins")
		var tints: PackedColorArray = cell.get_meta(&"tints")
		check_equal(origins.size(), multimesh.instance_count,
			"le seam couvre le tampon entier")
		for i: int in [0, origins.size() / 2, origins.size() - 1]:
			var origin: Vector3 = origins[i]
			check(absf(origin.x) < 50.0 and origin.z > 143.0 and origin.z < 172.0
				and absf(origin.y - 32.27) < 1.0,
				"brin %d posé sur la bande AVANT de la crête (%.0f, %.1f, %.0f)"
				% [i, origin.x, origin.y, origin.z])
		check(tints[0] != tints[tints.size() - 1] or tints[0] != tints[tints.size() / 2],
			"teinte variée par instance, pas un aplat")
	var flowers: MultiMeshInstance3D = meadow.get_node("Flowers") as MultiMeshInstance3D
	check(flowers.multimesh.instance_count >= 100,
		"fleurs présentes (%d)" % flowers.multimesh.instance_count)
	await _cleanup(valley)


## §7.2 : la densité de la prairie est une EXIGENCE CHIFFRÉE — 7 à 14
## touffes/m² en zone héroïque, 4 à 8 au-delà. Elle tournait à 0,6, vingt
## fois sous la bande, et rien ne le voyait : le test précédent demandait
## « au moins 300 instances » par cellule, ce qu'une prairie vide de sens
## satisfait tant qu'elle est assez large. Une densité se mesure par unité
## de SURFACE, sinon elle ne mesure rien.
func test_the_meadow_reaches_the_density_the_bible_asks_for() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var meadow: Node3D = valley.find_children("CrestMeadow", "Node3D", true, false)[0] \
		as Node3D
	var cells: Array[Node] = meadow.find_children("Cell*", "MultiMeshInstance3D",
		false, false)
	var cell_width: float = (ValleyTerrain.MEADOW_X.y - ValleyTerrain.MEADOW_X.x) \
		/ float(ValleyTerrain.MEADOW_CELLS)
	var cell_area: float = cell_width * (ValleyTerrain.MEADOW_Z.y - ValleyTerrain.MEADOW_Z.x)
	check(cell_width >= 24.0 - 2.0 and cell_width <= 48.0,
		"cellules de %.0f m — §7.5 demande 24 à 48 m" % cell_width)
	var total: int = 0
	var hero_cells: int = 0
	for cell: Node in cells:
		var multimesh: MultiMesh = (cell as MultiMeshInstance3D).multimesh
		var density: float = float(multimesh.instance_count) / cell_area
		total += multimesh.instance_count
		check(density >= 4.0 and density <= 14.0,
			"%s : %.1f touffes/m² (bande §7.2 : 4 à 14)" % [cell.name, density])
		if density >= 7.0:
			hero_cells += 1
	check(hero_cells >= 2,
		"au moins deux cellules en zone HÉROÏQUE (7-14 touffes/m²) : %d"
		% hero_cells)
	check(total >= 10000,
		"la crête porte %d touffes — le premier plan de §3.2 n'est plus un aplat"
		% total)
	await _cleanup(valley)


func test_paths_guide_both_routes_as_pure_visuals() -> void:
	## Réf. 01 : les routes guident la descente et les DEUX itinéraires (§4.1).
	## Bandes visuelles seulement : rien à percuter, aucune tranche de dalle à
	## montrer, et le premier segment repose sur la crête réelle plutôt que sur
	## l'ancienne cote écrite à la main (ISS-039).
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var strips: Array[Node] = valley.find_children("PathStrip*", "MeshInstance3D",
		true, false)
	check(strips.size() >= 9, "les segments de route existent (%d)" % strips.size())
	var west_route: bool = false
	var east_route: bool = false
	for strip: Node in strips:
		var path_strip: MeshInstance3D = strip as MeshInstance3D
		var at: Vector3 = path_strip.global_position
		if at.z < -40.0:
			west_route = true   # ruines → donjon
		if at.x > 55.0:
			east_route = true   # route est → pylône
		check(path_strip.mesh is PlaneMesh,
			"%s est un plan sans tranche visible" % path_strip.name)
		check(path_strip.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			"%s ne projette pas l'ombre d'une dalle" % path_strip.name)
		check(path_strip.find_children("*", "StaticBody3D",
			true, false).is_empty(), "bande de chemin sans collision")
	# Le segment d'ouverture révélait la seconde moitié du défaut : sa cote
	# historique était 24,04 m alors que la crête actuelle culmine à 32,00 m.
	var crest_strip: MeshInstance3D = valley.find_child(
		"PathStrip00", true, false) as MeshInstance3D
	check_not_null(crest_strip, "le segment d'ouverture PathStrip00 existe")
	if crest_strip == null:
		await _cleanup(valley)
		return
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(crest_strip.global_position.x, 200.0, crest_strip.global_position.z),
		Vector3(crest_strip.global_position.x, -50.0, crest_strip.global_position.z), 1)
	var hit: Dictionary = valley.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty(), "le sol réel existe sous le chemin de la crête")
	if not hit.is_empty():
		var ground_y: float = (hit["position"] as Vector3).y
		check_approx(crest_strip.global_position.y, ground_y + 0.02, 0.05,
			"le chemin d'ouverture épouse le sol réel")
	check(west_route, "la route du donjon est tracée")
	check(east_route, "la route du pylône est tracée")
	await _cleanup(valley)


func test_the_camp_reads_as_inhabited_with_tents_and_fire() -> void:
	## V4.3, réf. 01 : le camp se lit depuis la crête — tentes SOLIDES (on ne
	## marche pas au travers) sur la terrasse, foyer émissif, lumière chaude.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var tents: Array[Node] = valley.find_children("Tent?", "StaticBody3D", true, false)
	check(tents.size() >= 3, "au moins trois tentes physiques (%d)" % tents.size())
	for tent: Node in tents:
		var at: Vector3 = (tent as StaticBody3D).global_position
		check(at.x > 26.0 and at.x < 64.0 and at.z > 46.0 and at.z < 82.0
			and absf(at.y - 6.0) < 1.5,
			"tente SUR la terrasse du camp (%.0f, %.1f, %.0f)" % [at.x, at.y, at.z])
	var fire: OmniLight3D = valley.find_children("CampFireLight", "OmniLight3D",
		true, false)[0] as OmniLight3D
	check(fire.light_color.r > fire.light_color.b + 0.3,
		"lumière de feu CHAUDE (r %.2f / b %.2f)" % [fire.light_color.r,
			fire.light_color.b])
	var coals: MeshInstance3D = valley.find_children("FireCoals", "MeshInstance3D",
		true, false)[0] as MeshInstance3D
	check((coals.material_override as StandardMaterial3D).emission_enabled,
		"la braise du foyer émet")
	await _cleanup(valley)


func test_the_pylon_is_dressed_and_its_runes_glow() -> void:
	## V4.3, réf. 01 : socle de pierre, anneaux de bronze, bande runique cyan
	## ÉMISSIVE — l'ancre verticale du tiers droit n'est plus un simple fût.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	check(valley.find_children("PylonPlinth", "StaticBody3D", true, false).size() == 1,
		"socle physique")
	check(valley.find_children("PylonRing*", "MeshInstance3D", true, false).size() >= 2,
		"anneaux de bronze")
	var runes: MeshInstance3D = valley.find_children("PylonRunes", "MeshInstance3D",
		true, false)[0] as MeshInstance3D
	var rune_material: StandardMaterial3D = runes.material_override as StandardMaterial3D
	check(rune_material.emission_enabled, "la bande runique émet en cyan")
	check(rune_material.emission.b > rune_material.emission.r,
		"…et c'est bien du cyan, pas un feu")
	await _cleanup(valley)


func test_the_citadel_gate_is_monumental_and_still_enterable() -> void:
	## V4.3, réf. 02 : piliers + conduits cyan + linteau + braseros + marches
	## basses (≤ 0,30 m : franchissables §8.2) — et la porte reste la VRAIE
	## entrée du vestibule. Les marches sont mesurées par rayon physique.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	check(valley.find_children("GatePillar?", "StaticBody3D", true, false).size() >= 2,
		"deux piliers porteurs")
	var conduits: Array[Node] = valley.find_children("GateConduit?", "MeshInstance3D",
		true, false)
	check(conduits.size() >= 2, "conduits d'énergie sur les piliers")
	for conduit: Node in conduits:
		check(((conduit as MeshInstance3D).material_override as StandardMaterial3D)
			.emission_enabled, "conduit émissif")
	check(valley.find_children("GateBrazierLight?", "OmniLight3D", true, false).size() >= 2,
		"braseros de seuil")
	var space: PhysicsDirectSpaceState3D = valley.player().get_world_3d().direct_space_state
	var previous_top: float = 34.0
	for step_data: Array in [["GateStepLow", -192.0], ["GateStepMid", -194.2],
			["GateStepHigh", -196.2]]:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			Vector3(0, 40, float(step_data[1])), Vector3(0, 30, float(step_data[1])), 1)
		var hit: Dictionary = space.intersect_ray(query)
		check(not hit.is_empty(), "la marche %s porte" % String(step_data[0]))
		var top: float = (hit.get("position") as Vector3).y
		check(top - previous_top > 0.05 and top - previous_top <= 0.31,
			"emmarchement %.2f m franchissable (§8.2 step height)" % (top - previous_top))
		previous_top = top
	var door: SceneDoor = valley.find_children("CitadelDoor", "SceneDoor", true, false)[0] \
		as SceneDoor
	check_equal(door.prompt_verb(), "Entrer", "la porte reste la vraie entrée")
	await _cleanup(valley)


func test_the_vestibule_is_deep_and_warmly_lit() -> void:
	## V4.3, réf. 02 : profondeur jouable ≥ 24 m, braseros chauds contre veine
	## cyan, second seuil scellé au fond sous son linteau.
	var vestibule: CitadelVestibule = (load(
		"res://scenes/world/citadel/CitadelVestibule.tscn") as PackedScene) \
		.instantiate() as CitadelVestibule
	_tree().root.add_child(vestibule)
	await _settle(5)
	var north: StaticBody3D = vestibule.get_node("WallNorth") as StaticBody3D
	var south: StaticBody3D = vestibule.get_node("WallSouthTop") as StaticBody3D
	check(absf(south.position.z - north.position.z) >= 24.0,
		"profondeur jouable %.1f m (réf. 02 : 20-30 m)"
		% absf(south.position.z - north.position.z))
	var braziers: Array[Node] = vestibule.find_children("BrazierLight?",
		"OmniLight3D", true, false)
	check(braziers.size() >= 4, "quatre braseros (%d)" % braziers.size())
	for brazier: Node in braziers:
		var light: OmniLight3D = brazier as OmniLight3D
		check(light.light_color.r > light.light_color.b + 0.3, "flamme CHAUDE")
	# F.6 : ce second seuil n'est plus une masse SCELLÉE — il ouvre sur la
	# salle 1 du donjon. Le décor (linteau, portail de pierre) reste ; ce
	# qui change, c'est qu'on peut désormais le franchir.
	var threshold: SceneDoor = vestibule.get_node("DungeonDoor") as SceneDoor
	check_not_null(threshold, "le second seuil existe toujours")
	check(threshold.position.z < -12.0, "…et ferme le FOND de la salle")
	check_equal(String(threshold.target_scene),
		"res://scenes/dungeon/rooms/Room1Initiation.tscn",
		"…en menant au donjon, plus à une promesse")
	check_not_null(vestibule.get_node_or_null("SealedLintel"), "…sous son linteau")
	await _cleanup(vestibule)


func test_the_mountain_dressing_adds_depth_and_buttresses_really_block() -> void:
	## La 4e capture V4.1 montrait un rideau plat : l'anneau porte maintenant
	## des pics superposés (deux rangées, la lointaine bleuie) et des
	## contreforts PHYSIQUES `unclimbable` — mesuré par un rayon qui les frappe.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var peaks: Array[Node] = valley.find_children("Peak*", "MeshInstance3D", true, false)
	var far_peaks: Array[Node] = valley.find_children("FarPeak*", "MeshInstance3D",
		true, false)
	check(peaks.size() >= 30, "pics de première rangée (%d)" % peaks.size())
	check(far_peaks.size() >= 15, "rangée lointaine de superposition (%d)"
		% far_peaks.size())
	var buttresses: Array[Node] = valley.find_children("Buttress*", "StaticBody3D",
		true, false)
	check(buttresses.size() >= 8, "contreforts physiques (%d)" % buttresses.size())
	for buttress: Node in buttresses:
		check(buttress.is_in_group("unclimbable"), "contrefort infranchissable")
	# Un rayon horizontal tiré vers le contrefort sud-ouest le FRAPPE — décor
	# porteur, pas façade.
	var space: PhysicsDirectSpaceState3D = valley.player().get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(-120, 10, 200), Vector3(-120, 10, 260), 1)
	var hit: Dictionary = space.intersect_ray(query)
	check(not hit.is_empty() and (hit.get("collider") as Node).name.begins_with("Buttress"),
		"le contrefort sud arrête réellement un rayon (touché : %s)"
		% (String((hit.get("collider") as Node).name) if not hit.is_empty() else "rien"))
	await _cleanup(valley)
