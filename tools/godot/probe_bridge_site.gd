## SONDE du site du pont magnétique (P2-4c).
##
## Leçon des jupes (H-2) et des ancres de récompense : une position ne se
## devine pas, elle se mesure. Ce script monte la vallée réelle puis éprouve
## des rectangles candidats de 20 × 6 m (l'emprise du diorama du pont) sur la
## route des ruines : grille de rayons verticaux — sol trouvé partout, écart
## de cote maximal dans l'emprise, et cote moyenne à coller dans le bâtisseur.
##
##   godot --headless --path . --script tools/godot/probe_bridge_site.gd
extends SceneTree

const WORLD: String = "res://scenes/world/valley/ValleyWorld.tscn"
const PROBE_UP: float = 30.0
const PROBE_DOWN: float = 60.0

## Candidats (centre, lacet en degrés) le long de la route des ruines —
## entre l'aqueduc (−12, 10), la ferme (−16, 78) et la caravane (−38, −120),
## à > 20 m de tout site déjà bâti.
const CANDIDATES: Array = [
	[Vector3(-34.0, 0.0, 44.0), 0.0],
	[Vector3(-34.0, 0.0, 44.0), 90.0],
	[Vector3(-48.0, 0.0, 28.0), 0.0],
	[Vector3(-48.0, 0.0, 28.0), 90.0],
	[Vector3(-30.0, 0.0, -24.0), 0.0],
	[Vector3(-30.0, 0.0, -24.0), 90.0],
	[Vector3(-56.0, 0.0, -60.0), 0.0],
	[Vector3(-56.0, 0.0, -60.0), 90.0],
]


func _initialize() -> void:
	var scene: PackedScene = load(WORLD) as PackedScene
	var world: Node = scene.instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	var space: PhysicsDirectSpaceState3D = \
		(world as Node3D).get_world_3d().direct_space_state
	print("=== SONDE DU SITE DU PONT (emprise 20 × 6 m) ===")
	for candidate: Array in CANDIDATES:
		var centre: Vector3 = candidate[0] as Vector3
		var yaw: float = deg_to_rad(candidate[1] as float)
		var heights: Array[float] = []
		var misses: int = 0
		for ix: int in range(5):
			for iz: int in range(3):
				var local: Vector3 = Vector3(-10.0 + 5.0 * ix, 0.0,
					-3.0 + 3.0 * iz)
				var at: Vector3 = centre + local.rotated(Vector3.UP, yaw)
				var query: PhysicsRayQueryParameters3D = \
					PhysicsRayQueryParameters3D.create(
						at + Vector3.UP * PROBE_UP,
						at + Vector3.DOWN * PROBE_DOWN, 1)
				var hit: Dictionary = space.intersect_ray(query)
				if hit.is_empty():
					misses += 1
				else:
					heights.append((hit["position"] as Vector3).y)
		if misses > 0 or heights.is_empty():
			print("  (%.0f, %.0f) lacet %.0f° : REJET — %d rayon(s) sans sol"
				% [centre.x, centre.z, rad_to_deg(yaw), misses])
			continue
		var lowest: float = heights.min()
		var highest: float = heights.max()
		var mean: float = 0.0
		for h: float in heights:
			mean += h
		mean /= heights.size()
		print("  (%.0f, %.0f) lacet %.0f° : sol %.2f..%.2f (écart %.2f), moyenne %.2f %s"
			% [centre.x, centre.z, rad_to_deg(yaw), lowest, highest,
				highest - lowest, mean,
				"← PLAT" if highest - lowest <= 0.4 else ""])
	quit(0)
