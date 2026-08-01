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
	## la crête (x ±50, z 148-205, y 24), teintes variées par instance.
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
				and absf(origin.y - 24.27) < 1.0,
				"brin %d posé sur la bande AVANT de la crête (%.0f, %.1f, %.0f)"
				% [i, origin.x, origin.y, origin.z])
		check(tints[0] != tints[tints.size() - 1] or tints[0] != tints[tints.size() / 2],
			"teinte variée par instance, pas un aplat")
	var flowers: MultiMeshInstance3D = meadow.get_node("Flowers") as MultiMeshInstance3D
	check(flowers.multimesh.instance_count >= 100,
		"fleurs présentes (%d)" % flowers.multimesh.instance_count)
	await _cleanup(valley)


func test_paths_guide_both_routes_as_pure_visuals() -> void:
	## Réf. 01 : les routes guident la descente et les DEUX itinéraires (§4.1).
	## Bandes visuelles seulement : rien à percuter sur le chemin.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var strips: Array[Node] = valley.find_children("PathStrip*", "MeshInstance3D",
		true, false)
	check(strips.size() >= 9, "les segments de route existent (%d)" % strips.size())
	var west_route: bool = false
	var east_route: bool = false
	for strip: Node in strips:
		var at: Vector3 = (strip as MeshInstance3D).global_position
		if at.z < -40.0:
			west_route = true   # ruines → donjon
		if at.x > 55.0:
			east_route = true   # route est → pylône
		check((strip as MeshInstance3D).find_children("*", "StaticBody3D",
			true, false).is_empty(), "bande de chemin sans collision")
	check(west_route, "la route du donjon est tracée")
	check(east_route, "la route du pylône est tracée")
	await _cleanup(valley)


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
