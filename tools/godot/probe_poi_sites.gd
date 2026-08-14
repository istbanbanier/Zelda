## Sonde d'assise des sites de POI (V2.3) — diagnostic seul.
##
## Usage :
##   godot --headless --path . --script tools/godot/probe_poi_sites.gd \
##       [-- --sites=x,z;x,z;…]
##
## Le terrain V2.2 est GELÉ : un lieu s'adapte au sol par ses fondations.
## Cette sonde répond, pour chaque site, à la question qui gouverne la
## fondation : quelle est la hauteur au centre, la pente réelle dans un
## rayon de 6 et 12 m, et le site touche-t-il l'eau. Elle monte le monde
## UNE fois et imprime un tableau.
extends SceneTree

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"

## Sites par défaut : le lot pilote V2.3-A (layout + spec_anchors).
const DEFAULT_SITES: Array[Array] = [
	["camp_checkpoint", 45.0, 65.0],
	["riverside_village", -96.0, 30.0],
	["abandoned_farm", -52.0, 92.0],
	["stone_bridge", -10.0, 22.0],
	["waterfall_cave", -110.0, 6.0],
	["thunderstruck_tree", -92.0, 132.0],
	["ember_raider_camps", 96.0, 120.0],
	["conductive_basin", 26.0, 24.0],
	["pylon", 115.0, -25.0],
]


func _initialize() -> void:
	var world: Node3D = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i: int in range(12):
		await process_frame
	var heightmap: RefCounted = world.get("_heightmap") as RefCounted

	print("%-20s %8s %8s %8s %8s %8s %5s" % ["site", "h_centre",
		"min_r6", "max_r6", "min_r12", "max_r12", "eau"])
	for site: Array in DEFAULT_SITES:
		var label: String = site[0] as String
		var x: float = float(site[1])
		var z: float = float(site[2])
		var center_h: float = float(heightmap.call("height_at", x, z))
		var stats6: Array[float] = _ring_stats(heightmap, x, z, 6.0)
		var stats12: Array[float] = _ring_stats(heightmap, x, z, 12.0)
		var wet: bool = bool(heightmap.call("is_in_water", x, z))
		for a: float in [0.0, PI / 2.0, PI, 3.0 * PI / 2.0]:
			wet = wet or bool(heightmap.call("is_in_water",
				x + cos(a) * 8.0, z + sin(a) * 8.0))
		print("%-20s %8.2f %8.2f %8.2f %8.2f %8.2f %5s"
			% [label, center_h, stats6[0], stats6[1], stats12[0], stats12[1],
				"OUI" if wet else "non"])
	quit(0)


## [min, max] des hauteurs sur 16 points d'un cercle de rayon r.
func _ring_stats(heightmap: RefCounted, x: float, z: float,
		r: float) -> Array[float]:
	var lowest: float = 1e9
	var highest: float = -1e9
	for k: int in range(16):
		var a: float = TAU * float(k) / 16.0
		var h: float = float(heightmap.call("height_at",
			x + cos(a) * r, z + sin(a) * r))
		lowest = minf(lowest, h)
		highest = maxf(highest, h)
	return [lowest, highest]
