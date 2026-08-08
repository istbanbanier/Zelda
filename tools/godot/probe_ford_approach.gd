## Sonde d'approche du gué ouest (ISS-032) — outil de diagnostic, sans verdict.
##
## Usage :
##   godot --headless --path . --script tools/godot/probe_ford_approach.gd
##
## Le test `test_the_route_from_ridge_to_north_plain_is_walkable` casse au
## 10ᵉ jalon : le joueur passe sous y = −0,5. Cette sonde répond à la seule
## question qui tranche — le sol EXISTE-T-IL, et à quelle hauteur, le long des
## deux approches possibles du gué :
##
##   A) la diagonale du test, de (36, 22) vers (20, 10) ;
##   B) une approche ALIGNÉE, x = 20 constant, de z = 22 vers z = 0.
##
## Rayon vertical depuis y = +40 vers le bas, sur la couche du monde statique.
extends SceneTree

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
## Le lit de la rivière est à −1,5 ; le test refuse de descendre sous −0,5.
const FLOOR_LIMIT: float = -0.5


func _initialize() -> void:
	var valley: Node3D = (load(VALLEY) as PackedScene).instantiate() as Node3D
	root.add_child(valley)
	for i: int in range(12):
		await process_frame

	var space: PhysicsDirectSpaceState3D = valley.get_world_3d().direct_space_state
	print("[gue] rappel : Riverbed y=-1.5 (z 4..16) ; FordWest dalle y=2.0 "
		+ "centree (20,10) taille 12x12 -> x 14..26, z 4..16")
	print("")
	print("  GRILLE au bord EST du gue — la ou le pilote tombe (26.4, 13.0)")
	print("        z=18   z=16   z=15   z=14   z=13   z=12   z=10")
	for xi: int in range(12):
		var x: float = 24.0 + float(xi) * 0.5
		var row: String = "  x %5.1f" % x
		for z: float in [18.0, 16.0, 15.0, 14.0, 13.0, 12.0, 10.0]:
			var h: float = _ground_at(space, Vector2(x, z))
			row += ("  %5.2f" % h) if h > -900.0 else "    VIDE"
		print(row)

	quit(0)


func _walk(space: PhysicsDirectSpaceState3D, from: Vector2, to: Vector2,
		samples: int) -> void:
	var worst: float = 100.0
	for i: int in range(samples):
		var t: float = float(i) / float(samples - 1)
		var p: Vector2 = from.lerp(to, t)
		var h: float = _ground_at(space, p)
		worst = minf(worst, h)
		var flag: String = ""
		if h <= -900.0:
			flag = "  <-- AUCUN SOL"
		elif h < FLOOR_LIMIT:
			flag = "  <-- SOUS LA LIMITE %.1f" % FLOOR_LIMIT
		print("    x %6.1f  z %6.1f   sol y = %s%s"
			% [p.x, p.y, ("%.2f" % h) if h > -900.0 else "  —", flag])
	print("    plus bas rencontre : %.2f" % worst)


## Hauteur du sol sous un point, ou -999 si le rayon ne touche rien.
func _ground_at(space: PhysicsDirectSpaceState3D, p: Vector2) -> float:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(p.x, 40.0, p.y), Vector3(p.x, -20.0, p.y))
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return -999.0
	return (hit["position"] as Vector3).y
