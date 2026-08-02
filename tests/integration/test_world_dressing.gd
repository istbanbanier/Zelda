## V4 lot 4 — habillage des zones A/B/C (§11) : compositions réelles sur la
## topologie intacte. Mesuré : chaque zone monte ses modèles promus, les
## obstacles ont leur collision, et le COULOIR DE LA VISTA (x −12..12 vers
## la citadelle) ne contient AUCUNE silhouette haute — la règle de §11.A.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"

var _valley: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _load_valley() -> void:
	_valley = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_valley)
	await _settle(5)


func _unload_valley() -> void:
	_valley.get_parent().remove_child(_valley)
	_valley.queue_free()
	_valley = null
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


func _zone(zone_name: String) -> Node3D:
	return _valley.find_children(zone_name, "Node3D", true, false)[0] as Node3D


func test_the_three_zones_mount_their_compositions() -> void:
	## Chaque zone monte ses placements (les modèles SONT promus — un vide
	## ici serait une promotion manquante, pas un choix).
	await _load_valley()
	for expected: Array in [["DressZoneCrest", 21], ["DressZoneDescent", 12],
			["DressZonePrairie", 18], ["DressZoneForest", 26],
			["DressZoneRiver", 15], ["DressZoneCliff", 12],
			["DressZonePylon", 12], ["DressZoneCitadel", 24]]:
		var zone: Node3D = _zone(String(expected[0]))
		check_equal(zone.get_child_count(), int(expected[1]),
			"%s : tous les placements montés" % String(expected[0]))
		var real: int = 0
		for prop: Node in zone.get_children():
			for mesh: Node in prop.find_children("*", "MeshInstance3D", true, false):
				if (mesh as MeshInstance3D).mesh != null:
					real += 1
					break
		check_equal(real, zone.get_child_count(),
			"%s : chaque placement a un maillage réel" % String(expected[0]))
	await _unload_valley()


func test_the_vista_corridor_stays_clear_of_tall_silhouettes() -> void:
	## §11.A : « aucune végétation devant la citadelle » — dans le couloir
	## x −12..12 de la crête, rien au-dessus de 1 m (fleurs et herbes
	## seulement). Revue V4 lot 16 : le balayage couvre TOUS les nœuds
	## montés sur la crête (zones, phrases de nature, tout parent) — le
	## contre-exemple était un buisson des phrases, hors du périmètre de
	## l'ancienne version qui n'auditait que DressZoneCrest.
	await _load_valley()
	var terrain: Node3D = _valley.find_children("*", "ValleyTerrain", true,
		false)[0] as Node3D
	var swept: int = 0
	for node: Node in terrain.find_children("*", "Node3D", true, false):
		var prop: Node3D = node as Node3D
		var at: Vector3 = prop.global_position
		# Couloir : bande centrale de la crête, du spawn au bord (y ~24).
		if absf(at.x) >= 12.0 or at.y < 20.0 or at.z < 148.0 or at.z > 176.0:
			continue
		swept += 1
		var name_low: String = String(prop.name).to_lower()
		check(not ("tree" in name_low or "pine" in name_low or "bush" in name_low
			or "rock_medium" in name_low),
			"couloir de vista : %s est BAS (fleur/herbe), pas une silhouette"
			% prop.name)
	check(swept >= 8, "le balayage a réellement couvert le couloir (%d)" % swept)
	# Les obstacles francs des zones portent leur collision.
	var collisions: int = 0
	for zone_name: String in ["DressZoneCrest", "DressZoneDescent",
			"DressZonePrairie"]:
		for prop: Node in _zone(zone_name).get_children():
			if not prop.find_children("*", "CollisionShape3D", true, false) \
					.is_empty():
				collisions += 1
	check(collisions >= 10, "au moins dix obstacles réels (%d)" % collisions)
	await _unload_valley()


func test_the_graybox_materials_are_shared_by_key() -> void:
	## V4 lot 15 : les volumes graybox de même (couleur, émission) partagent
	## UNE ressource matériau — et les personnalisations (braises, runes)
	## sont des DUPLICATAS, jamais une mutation du matériau partagé.
	await _load_valley()
	var terrain: Node3D = _valley.find_children("*", "ValleyTerrain", true,
		false)[0] as Node3D
	var south: MeshInstance3D = terrain.get_node("PlainSouth/PlainSouthMesh") \
		as MeshInstance3D
	var ridge: MeshInstance3D = terrain.get_node("SpawnRidge/SpawnRidgeMesh") \
		as MeshInstance3D
	check(south.material_override == ridge.material_override,
		"deux dalles d'herbe partagent LE même matériau")
	var coals: MeshInstance3D = terrain.find_children("FireCoals",
		"MeshInstance3D", true, false)[0] as MeshInstance3D
	var coal_material: StandardMaterial3D = \
		coals.material_override as StandardMaterial3D
	check(coal_material.emission_enabled,
		"les braises gardent leur émission personnalisée")
	var runes: MeshInstance3D = terrain.get_node("PylonRunes") as MeshInstance3D
	var head: MeshInstance3D = terrain.get_node("PylonHead") as MeshInstance3D
	check(runes.material_override != head.material_override,
		"la personnalisation des runes est un duplicata, pas le partagé")
	check((head.material_override as StandardMaterial3D).emission_enabled,
		"…et l'orbe cyan émissif du pylône n'a pas été dépossédé")
	await _unload_valley()


func test_the_secondary_structures_are_penetrable_with_rewards() -> void:
	## V4 lot 12 : quatre abris complets (coquille 4×6 : 6 dalles, 10 murs,
	## 4 angles, toit, lanterne + lumière motivée), la PORTE jamais barrée
	## (flancs |x| ≥ 0,6, linteau ≥ 2,3 m — l'arche reste franche), et une
	## récompense À L'INTÉRIEUR de chacun (l'épice existante pour le
	## sanctuaire) — entrer paye toujours.
	await _load_valley()
	var holder: Node3D = _valley.find_children("SecondaryStructures", "Node3D",
		true, false)[0] as Node3D
	for shelter_name: String in ["OutpostNorthRoad", "RiverShelter",
			"CliffSanctuary", "CitadelGuardPost"]:
		var shelter: Node3D = holder.get_node(shelter_name) as Node3D
		var walls: int = 0
		var floors: int = 0
		var corners: int = 0
		var roofs: int = 0
		var door: Node3D = null
		for child: Node in shelter.get_children():
			var child_name: String = String(child.name)
			if child_name.begins_with("Wall_"):
				walls += 1
			if child_name.begins_with("Floor_"):
				floors += 1
			if child_name.begins_with("Corner_"):
				corners += 1
			if child_name.begins_with("Roof_"):
				roofs += 1
			if "Door_Round" in child_name:
				door = child as Node3D
		check_equal(walls, 10, "%s : dix murs" % shelter_name)
		check_equal(floors, 6, "%s : six dalles" % shelter_name)
		check_equal(corners, 4, "%s : quatre angles" % shelter_name)
		check_equal(roofs, 1, "%s : un toit" % shelter_name)
		check(shelter.get_node_or_null("ShelterLight") != null,
			"%s : lumière intérieure motivée" % shelter_name)
		check(door != null, "%s : un module de porte" % shelter_name)
		if door != null:
			var shapes: Array[Node] = door.find_children("*", "CollisionShape3D",
				true, false)
			check_equal(shapes.size(), 3,
				"%s : porte = deux flancs + linteau" % shelter_name)
			for shape: Node in shapes:
				var local: Vector3 = (shape as CollisionShape3D).position
				check(absf(local.x) >= 0.6 or local.y >= 2.3,
					"%s : aucune collision ne barre l'arche (%.2f, %.2f)"
					% [shelter_name, local.x, local.y])
	# Chaque récompense est bien DANS son abri (≤ 3,2 m du centre, hauteur
	# de plain-pied) — la promesse « entrer paye » est mesurée, pas déclarée.
	for reward: Array in [
			["OutpostNorthRoad", "valley_ingredient_outpost_meat_01"],
			["RiverShelter", "valley_ingredient_shelter_fruit_01"],
			["CliffSanctuary", "valley_ingredient_cliff_spice_01"],
			["CitadelGuardPost", "valley_ingredient_guardpost_berry_01"]]:
		var shelter: Node3D = holder.get_node(String(reward[0])) as Node3D
		var pickup: Node3D = _valley.find_children(String(reward[1]),
			"", true, false)[0] as Node3D
		var offset: Vector3 = pickup.global_position - shelter.global_position
		check(Vector2(offset.x, offset.z).length() <= 3.2,
			"%s : la récompense est dans l'abri (%.1f m)"
			% [String(reward[0]), Vector2(offset.x, offset.z).length()])
		check(offset.y >= -0.5 and offset.y <= 1.0,
			"%s : …de plain-pied" % String(reward[0]))
	await _unload_valley()
