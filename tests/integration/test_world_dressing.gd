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
			["DressZonePrairie", 18]]:
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
	## seulement). Les arbres et rochers du cadre sont TOUS hors couloir.
	await _load_valley()
	var crest: Node3D = _zone("DressZoneCrest")
	for prop: Node in crest.get_children():
		var node: Node3D = prop as Node3D
		if absf(node.position.x) >= 12.0:
			continue
		var name_low: String = String(node.name).to_lower()
		check(not ("tree" in name_low or "pine" in name_low
			or "rock_medium" in name_low),
			"couloir de vista : %s est BAS (fleur/herbe), pas une silhouette"
			% node.name)
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
