## Bâtisseur des MARQUEURS whitebox V2.1 — ancres nommées, jamais du contenu.
##
## Chaque lieu du layout devient un Node3D nommé par son identifiant §19.3,
## posé SUR LE SOL réel (fonction de hauteur), avec le site planifié en
## métadonnée. Ce ne sont ni des `PointOfInterest`, ni des coffres, ni des
## récompenses : le contenu fonctionnel appartient aux phases ultérieures —
## ici, seule la VÉRITÉ SPATIALE est posée et inspectable.
##
## Les régions deviennent des nœuds inspectables sous `Biomes`, les routes
## des nœuds porteurs de leurs waypoints sous `Routes`.
class_name WorldV2MarkersBuilder
extends RefCounted

## Pilier de diagnostic optionnel, INVISIBLE par défaut.
const PILLAR_HEIGHT: float = 4.0

var _heightmap: WorldV2Heightmap = null
var _layout: Dictionary = {}


func _init(heightmap: WorldV2Heightmap, layout: Dictionary) -> void:
	_heightmap = heightmap
	_layout = layout


func build(pois_parent: Node3D, landmarks_parent: Node3D, biomes_parent: Node3D,
		routes_parent: Node3D) -> void:
	for entry: Variant in _layout.get("pois", []) as Array:
		pois_parent.add_child(_place_marker(entry as Dictionary,
			&"world_v2_poi_markers"))
	for entry: Variant in _layout.get("systemic_sites", []) as Array:
		landmarks_parent.add_child(_place_marker(entry as Dictionary,
			&"world_v2_site_markers"))
	for entry: Variant in _layout.get("cave_entrances", []) as Array:
		var cave: Dictionary = entry as Dictionary
		var poi_id: String = String(cave.get("poi", ""))
		var site: Array = _poi_site(poi_id)
		if site.size() != 3:
			continue
		var marker: Node3D = _grounded_node("cave." + poi_id,
			float(site[0]), float(site[2]), &"world_v2_cave_markers")
		marker.set_meta(&"threshold", cave.get("threshold", ""))
		landmarks_parent.add_child(marker)
	for entry: Variant in _layout.get("checkpoints", []) as Array:
		var checkpoint: Dictionary = entry as Dictionary
		if checkpoint.get("pos") == null:
			continue
		var pos: Array = checkpoint["pos"] as Array
		var marker: Node3D = _grounded_node(
			"checkpoint." + String(checkpoint.get("id", "?")),
			float(pos[0]), float(pos[2]), &"world_v2_checkpoints")
		landmarks_parent.add_child(marker)
	# Accès au donjon : la porte §3.3, marqueur dédié.
	var anchors: Dictionary = _layout.get("spec_anchors", {}) as Dictionary
	if anchors.has("dungeon_gate"):
		var gate: Array = anchors["dungeon_gate"] as Array
		landmarks_parent.add_child(_grounded_node("dungeon_gate_access",
			float(gate[0]), float(gate[2]), &"world_v2_dungeon_access"))

	for entry: Variant in _layout.get("regions", []) as Array:
		var region: Dictionary = entry as Dictionary
		var node: Node3D = Node3D.new()
		node.name = String(region.get("id", "region"))
		node.add_to_group(&"world_v2_regions")
		node.set_meta(&"display_name", region.get("name", ""))
		node.set_meta(&"bounds", region.get("bounds", []))
		node.set_meta(&"altitude_m", region.get("altitude_m", []))
		var anchor: Variant = region.get("save_anchor")
		if anchor != null and (anchor as Dictionary).get("pos") != null:
			var anchor_pos: Array = (anchor as Dictionary)["pos"] as Array
			node.position = Vector3(float(anchor_pos[0]), float(anchor_pos[1]),
				float(anchor_pos[2]))
		biomes_parent.add_child(node)

	var routes: Dictionary = _layout.get("routes", {}) as Dictionary
	for route_name: String in ["main_path", "river_route", "heights_route", "ruins_route"]:
		var route: Dictionary = routes.get(route_name, {}) as Dictionary
		var node: Node = Node.new()
		node.name = route_name
		node.add_to_group(&"world_v2_routes")
		node.set_meta(&"waypoints_xz", route.get("waypoints_xz", []))
		routes_parent.add_child(node)
	for entry: Variant in routes.get("shortcuts", []) as Array:
		var shortcut: Dictionary = entry as Dictionary
		var node: Node = Node.new()
		node.name = String(shortcut.get("id", "shortcut"))
		node.add_to_group(&"world_v2_shortcuts")
		node.set_meta(&"links", shortcut.get("links", []))
		routes_parent.add_child(node)


func _place_marker(place: Dictionary, group: StringName) -> Node3D:
	var site: Array = place.get("v2_site", []) as Array
	var place_id: String = String(place.get("id", "place"))
	var marker: Node3D = _grounded_node(place_id, float(site[0]), float(site[2]), group)
	# Godot ASSAINIT les points des noms de nœuds (« valley.poi.x.01 » devient
	# « valley_poi_x_01 ») : l'identifiant persistant EXACT vit en métadonnée.
	marker.set_meta(&"place_id", place_id)
	marker.set_meta(&"planned_site", site)
	marker.set_meta(&"display_name", place.get("name", ""))
	marker.set_meta(&"region", place.get("region", ""))
	return marker


## Un nœud posé sur le SOL RÉEL (fonction de hauteur), avec un petit pilier
## de diagnostic masqué par défaut (activable pour les captures).
func _grounded_node(node_name: String, x: float, z: float,
		group: StringName) -> Node3D:
	var node: Node3D = Node3D.new()
	node.name = node_name
	node.add_to_group(group)
	node.add_to_group(&"world_v2_markers")
	node.position = Vector3(x, _heightmap.height_at(x, z), z)
	var pillar: MeshInstance3D = MeshInstance3D.new()
	pillar.name = "DiagnosticPillar"
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.6, PILLAR_HEIGHT, 0.6)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.85, 0.4)
	mesh.material = material
	pillar.mesh = mesh
	pillar.position = Vector3(0.0, PILLAR_HEIGHT * 0.5, 0.0)
	pillar.visible = false
	node.add_child(pillar)
	return node


func _poi_site(poi_id: String) -> Array:
	for entry: Variant in _layout.get("pois", []) as Array:
		var poi: Dictionary = entry as Dictionary
		if String(poi.get("id", "")) == poi_id:
			return poi.get("v2_site", []) as Array
	return []
