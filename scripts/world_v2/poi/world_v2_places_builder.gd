## Bâtisseur des LIEUX du monde V2 (V2.3) — la couche de chair au-dessus
## des marqueurs.
##
## Les marqueurs V2.2 restent la couche d'IDENTITÉ, intacte et épinglée
## (`test_world_v2_anchors.gd`). Ce bâtisseur pose une couche SÉPARÉE :
## une `PackedScene` autonome par lieu du registre, instanciée sous
## `$Places`, groupe `world_v2_places`, meta `place_id` — jamais dans les
## groupes de marqueurs, jamais de coordonnée codée en dur : la position
## vient EXCLUSIVEMENT du layout (`pois[].v2_site`,
## `systemic_sites[].v2_site`, `checkpoints[].pos`, `spec_anchors`).
##
## Un lieu absent du registre garde son simple marqueur — aucun faux lieu
## pour verdir une suite (directive V2.3 §5). Le filet
## `test_world_v2_places_contract.gd` rougit tant que le lot pilote n'est
## pas réellement construit.
class_name WorldV2PlacesBuilder
extends RefCounted

## place_id → chemin de PackedScene. REMPLI par V2.3-A (lot pilote), une
## entrée par scène réellement livrée — jamais de chemin d'avance : un
## chemin mort produirait une erreur à chaque montage du monde.
## Clés admises : IDs canoniques de POI, IDs de sites systémiques,
## "camp" (checkpoint du layout) et "pylon" (ancre §3.3).
const REGISTRY: Dictionary = {}

var _heightmap: WorldV2Heightmap = null
var _layout: Dictionary = {}


func _init(heightmap: WorldV2Heightmap, layout: Dictionary) -> void:
	_heightmap = heightmap
	_layout = layout


## Instancie chaque lieu du registre à son site de layout, ancré au sol.
## Rend le nombre de lieux réellement posés.
func build(places_root: Node3D) -> int:
	var placed: int = 0
	for place_id: StringName in REGISTRY.keys():
		var site: Vector3 = _site_of(place_id)
		if site == Vector3.INF:
			push_error("[world_v2] lieu %s : aucun site dans le layout" % place_id)
			continue
		var packed: PackedScene = load(String(REGISTRY[place_id])) as PackedScene
		if packed == null:
			push_error("[world_v2] lieu %s : scène introuvable %s"
				% [place_id, REGISTRY[place_id]])
			continue
		var place: Node3D = packed.instantiate() as Node3D
		place.name = "place_" + String(place_id).replace(".", "_")
		place.set_meta(&"place_id", place_id)
		place.add_to_group(&"world_v2_places", true)
		place.position = Vector3(site.x,
			_heightmap.height_at(site.x, site.z), site.z)
		places_root.add_child(place)
		placed += 1
	if placed > 0:
		_furnish_rewards(places_root)
	return placed


## Raccorde les récompenses CANONIQUES aux ancres exposées par les lieux,
## par la table et la convention d'IDs existantes (`DiscoveryRewards`),
## puis lie chaque `PointOfInterest` à un journal de découverte réel.
func _furnish_rewards(places_root: Node3D) -> void:
	var rewards: DiscoveryRewards = DiscoveryRewards.new()
	rewards.name = "Recompenses"
	places_root.add_child(rewards)
	var placed: int = rewards.furnish(places_root)
	var log: DiscoveryLog = DiscoveryLog.new()
	for poi: PointOfInterest in places_root.find_children(
			"*", "PointOfInterest", true, false):
		poi.bind(log)
	places_root.set_meta(&"rewards_placed", placed)
	places_root.set_meta(&"discovery_log", log)


## Site d'un lieu, lu dans le layout — la SEULE source de position.
func _site_of(place_id: StringName) -> Vector3:
	if place_id == &"pylon":
		var anchors: Dictionary = _layout.get("spec_anchors", {}) as Dictionary
		return _as_vec3(anchors.get("pylon", null))
	if place_id == &"camp":
		for checkpoint: Dictionary in _layout.get("checkpoints", []) as Array:
			if StringName(checkpoint.get("id", "")) == &"camp":
				return _as_vec3(checkpoint.get("pos", null))
		return Vector3.INF
	for poi: Dictionary in _layout.get("pois", []) as Array:
		if StringName(poi.get("id", "")) == place_id:
			return _as_vec3(poi.get("v2_site", null))
	for site: Dictionary in _layout.get("systemic_sites", []) as Array:
		if StringName(site.get("id", "")) == place_id:
			return _as_vec3(site.get("v2_site", null))
	return Vector3.INF


func _as_vec3(value: Variant) -> Vector3:
	if value is Array and (value as Array).size() == 3:
		var raw: Array = value as Array
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.INF
