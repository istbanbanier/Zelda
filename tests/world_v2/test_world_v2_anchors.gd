## V2.1 — les ANCRES et les LIEUX ont un sol vrai, aux altitudes contractuelles.
##
## Les quatre ancres §3.3 sont épinglées en LITTÉRAUX indépendants du code de
## génération : si la fonction de hauteur dérive, ces nombres la dénoncent.
## Chaque lieu (31 POI + 3 sites systémiques + 5 grottes + checkpoints +
## accès donjon) doit avoir un marqueur nommé, posé sur un sol RÉEL (sonde
## physique), à l'altitude planifiée, sans doublon ni site hors du monde.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"

## Ancres §3.3 — LITTÉRAUX (jamais lus depuis le layout : un layout dérivé
## serait suivi au lieu d'être dénoncé).
const ANCHORS: Array[Array] = [
	["spawn", 0.0, 24.0, 170.0],
	["camp", 45.0, 6.0, 65.0],
	["pylone", 115.0, 18.0, -25.0],
	["porte_du_donjon", 0.0, 34.0, -210.0],
]
const ANCHOR_TOLERANCE_M: float = 0.5
const ANCHOR_MAX_SLOPE_DEG: float = 8.0
const SITE_ALTITUDE_TOLERANCE_M: float = 3.0
const SITE_GROUND_RADIUS_M: float = 3.0

var _world: Node3D = null


func test_les_ancres_immuables_ont_un_sol_conforme() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame

	var heightmap: WorldV2Heightmap = _world.call("heightmap") as WorldV2Heightmap
	check_not_null(heightmap, "la fonction de hauteur est exposée")
	var space: PhysicsDirectSpaceState3D = _world.get_world_3d().direct_space_state
	for anchor: Array in ANCHORS:
		var anchor_name: String = String(anchor[0])
		var x: float = float(anchor[1])
		var wanted_y: float = float(anchor[2])
		var z: float = float(anchor[3])
		var h: float = heightmap.height_at(x, z)
		check_approx(h, wanted_y, ANCHOR_TOLERANCE_M,
			"altitude de l'ancre %s" % anchor_name)
		check(heightmap.slope_deg_at(x, z) <= ANCHOR_MAX_SLOPE_DEG,
			"pente au %s compatible (%.1f° ≤ %.0f°)"
				% [anchor_name, heightmap.slope_deg_at(x, z), ANCHOR_MAX_SLOPE_DEG])
		var hit: Dictionary = _ray_down(space, x, z)
		check(not hit.is_empty(), "sol PHYSIQUE sous l'ancre %s" % anchor_name)
		if not hit.is_empty():
			check((hit["collider"] as Node).is_in_group(&"world_v2_terrain"),
				"le sol de %s est un chunk V2" % anchor_name)
			check_approx((hit["position"] as Vector3).y, wanted_y,
				ANCHOR_TOLERANCE_M + 0.2,
				"le sol physique de %s est à l'altitude contractuelle" % anchor_name)
		check(not heightmap.is_in_water(x, z),
			"aucune eau à l'ancre %s" % anchor_name)

	var clean: bool = await restore_root()
	check(clean, "démontage propre — %s" % restore_root_reason())
	restore_saves()


func test_chaque_lieu_a_son_marqueur_au_sol() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame

	var heightmap: WorldV2Heightmap = _world.call("heightmap") as WorldV2Heightmap
	var space: PhysicsDirectSpaceState3D = _world.get_world_3d().direct_space_state

	# --- 31 POI : un marqueur par identifiant canonique, sans doublon.
	var poi_markers: Array[Node] = loop.get_nodes_in_group(&"world_v2_poi_markers")
	check_equal(poi_markers.size(), WorldV2Layout.CANONICAL_POI_IDS.size(),
		"un marqueur par lieu canonique")
	var seen: Dictionary = {}
	var faults: Array[String] = []
	for marker: Node in poi_markers:
		# L'identifiant EXACT vit en métadonnée — le nom de nœud est assaini
		# par Godot (les points deviennent des tirets bas).
		var marker_id: StringName = StringName(String(marker.get_meta(&"place_id", "")))
		if seen.has(marker_id):
			faults.append("doublon %s" % marker_id)
			continue
		seen[marker_id] = true
		if not WorldV2Layout.CANONICAL_POI_IDS.has(marker_id):
			faults.append("marqueur inconnu %s" % marker_id)
			continue
		faults.append_array(_check_marker_site(marker as Node3D, heightmap, space))
	for wanted: StringName in WorldV2Layout.CANONICAL_POI_IDS:
		if not seen.has(wanted):
			faults.append("lieu SANS marqueur : %s" % wanted)
	check(faults.is_empty(), "les 31 lieux sont posés au sol — %s"
		% " ; ".join(faults))

	# --- Sites systémiques, grottes, checkpoints, accès donjon.
	check_equal(loop.get_nodes_in_group(&"world_v2_site_markers").size(),
		WorldV2Layout.SYSTEMIC_SITE_IDS.size(), "3 sites systémiques posés")
	var site_faults: Array[String] = []
	for marker: Node in loop.get_nodes_in_group(&"world_v2_site_markers"):
		site_faults.append_array(_check_marker_site(marker as Node3D, heightmap, space))
	check(site_faults.is_empty(), "les sites systémiques sont au sol — %s"
		% " ; ".join(site_faults))

	check_equal(loop.get_nodes_in_group(&"world_v2_cave_markers").size(), 5,
		"cinq entrées de grottes marquées")
	check(loop.get_nodes_in_group(&"world_v2_dungeon_access").size() >= 1,
		"l'accès au donjon est marqué")

	# --- Checkpoints : sol réel, pente douce, PAS d'eau.
	var checkpoints: Array[Node] = loop.get_nodes_in_group(&"world_v2_checkpoints")
	check(checkpoints.size() >= 2, "checkpoints camp + porte marqués (%d)"
		% checkpoints.size())
	for checkpoint: Node in checkpoints:
		var node: Node3D = checkpoint as Node3D
		var hit: Dictionary = _ray_down(space, node.global_position.x,
			node.global_position.z)
		check(not hit.is_empty(), "sol physique au %s" % node.name)
		check(heightmap.slope_deg_at(node.global_position.x,
			node.global_position.z) <= ANCHOR_MAX_SLOPE_DEG,
			"pente douce au %s" % node.name)
		check(not heightmap.is_in_water(node.global_position.x,
			node.global_position.z), "aucune eau au %s" % node.name)

	# --- Régions : les onze objets inspectables existent.
	check_equal(loop.get_nodes_in_group(&"world_v2_regions").size(), 11,
		"les onze régions sont des nœuds inspectables")
	check_equal(loop.get_nodes_in_group(&"world_v2_routes").size(), 4,
		"les quatre routes portent leurs waypoints en métadonnées")
	check_equal(loop.get_nodes_in_group(&"world_v2_ford_markers").size(), 3,
		"les trois gués sont marqués")

	var clean: bool = await restore_root()
	check(clean, "démontage propre — %s" % restore_root_reason())
	restore_saves()


## Un marqueur : posé sur le sol RÉEL, à l'altitude planifiée, avec un point
## de sol accessible dans SITE_GROUND_RADIUS_M (contrat V2.1 §6).
func _check_marker_site(marker: Node3D, heightmap: WorldV2Heightmap,
		space: PhysicsDirectSpaceState3D) -> Array[String]:
	var faults: Array[String] = []
	var marker_id: String = String(marker.get_meta(&"place_id", marker.name))
	var planned: Array = marker.get_meta(&"planned_site", []) as Array
	if planned.size() != 3:
		faults.append("%s sans site planifié" % marker_id)
		return faults
	var x: float = marker.global_position.x
	var z: float = marker.global_position.z
	if Vector2(x, z).length() > WorldV2Heightmap.PLAYABLE_RADIUS_M:
		faults.append("%s hors du monde jouable" % marker_id)
	var ground: float = heightmap.height_at(x, z)
	if absf(marker.global_position.y - ground) > 0.5:
		faults.append("%s flotte à %.1f m du sol" % [marker_id,
			absf(marker.global_position.y - ground)])
	if absf(ground - float(planned[1])) > SITE_ALTITUDE_TOLERANCE_M:
		faults.append("%s : terrain à %.1f, planifié %.1f" % [marker_id,
			ground, float(planned[1])])
	var hit: Dictionary = _ray_down(space, x, z)
	if hit.is_empty():
		# Un point de sol PHYSIQUE dans le rayon d'accessibilité.
		var found: bool = false
		for offset: Vector2 in [Vector2(SITE_GROUND_RADIUS_M, 0),
				Vector2(-SITE_GROUND_RADIUS_M, 0), Vector2(0, SITE_GROUND_RADIUS_M),
				Vector2(0, -SITE_GROUND_RADIUS_M)]:
			if not _ray_down(space, x + offset.x, z + offset.y).is_empty():
				found = true
				break
		if not found:
			faults.append("%s sans sol physique à moins de %.0f m"
				% [marker_id, SITE_GROUND_RADIUS_M])
	return faults


func _ray_down(space: PhysicsDirectSpaceState3D, x: float, z: float) -> Dictionary:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(x, 200.0, z), Vector3(x, -60.0, z), 1)
	return space.intersect_ray(query)
