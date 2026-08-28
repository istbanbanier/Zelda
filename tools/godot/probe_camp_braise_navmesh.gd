## ISS-074 — MESURE DU NAVMESH RÉEL DU CAMP BRAISE, avant tout placement.
##
## Usage :
##   tools/lancer_godot.sh --path . --script tools/godot/probe_camp_braise_navmesh.gd
##
## Poser un ennemi à une coordonnée choisie sur une carte est un pari. Cette
## sonde remplace le pari par une mesure : pour chaque point d'une grille
## couvrant la région `r05_terrasse_du_camp` du layout, elle demande à la
## navigation RÉELLE du monde monté (a) où se trouve le point navigable le
## plus proche, et (b) s'il existe un chemin depuis le spawn du héros.
##
## Le piège qu'elle referme est celui du portail ISS-074 lui-même : un ennemi
## posé hors navmesh est un décor, pas un adversaire — il ne rejoindra jamais
## le joueur, et rien à l'écran ne le dira.
##
## Elle n'écrit RIEN et ne modifie RIEN : elle imprime un tableau.
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"
## Bornes de `r05_terrasse_du_camp` — recopiées du layout, et RELUES depuis
## lui au démarrage pour qu'une dérive du layout fasse échouer la sonde
## plutôt que de la laisser mesurer une région qui a bougé.
const LAYOUT: String = "res://resources/world_v2/world_v2_layout.json"
const REGION_ID: String = "r05_terrasse_du_camp"
const PAS_M: float = 4.0
## Au-delà, le point demandé n'est pas sur le navmesh : le « plus proche »
## renvoyé décrit une autre surface, souvent plusieurs mètres plus bas.
const TOLERANCE_NAV_M: float = 1.5
## Le bout de chemin doit finir près de la cible, sinon la navigation a rendu
## un chemin qui s'arrête à une lèvre — c'est le critère du portail.
const PORTEE_ATTEIGNABLE_M: float = 4.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var texte: String = FileAccess.get_file_as_string(LAYOUT)
	var layout: Dictionary = JSON.parse_string(texte) as Dictionary
	if layout.is_empty():
		push_error("[camp] layout illisible : %s" % LAYOUT)
		quit(3)
		return
	var region: Dictionary = {}
	for entree: Variant in (layout.get("regions", []) as Array):
		if String((entree as Dictionary).get("id", "")) == REGION_ID:
			region = entree as Dictionary
			break
	if region.is_empty():
		push_error("[camp] région %s absente du layout" % REGION_ID)
		quit(3)
		return
	var bornes: Dictionary = (region["bounds"] as Array)[0] as Dictionary
	var xs: Array = bornes["x"] as Array
	var zs: Array = bornes["z"] as Array
	print("[camp] région %s : x[%s, %s] z[%s, %s]"
		% [REGION_ID, xs[0], xs[1], zs[0], zs[1]])
	print("[camp] encounters (normatif) : %s" % String(region.get("encounters", "")))

	var world: Node3D = (load(WORLD) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	await process_frame
	await physics_frame
	await physics_frame

	var carte: RID = world.get_world_3d().navigation_map
	NavigationServer3D.map_force_update(carte)
	await physics_frame

	var spawn: Vector3 = world.call("spawn_position") as Vector3
	print("[camp] spawn du héros : (%.1f, %.1f, %.1f)" % [spawn.x, spawn.y, spawn.z])

	var sur_navmesh: int = 0
	var atteignables: int = 0
	var total: int = 0
	var meilleurs: Array[Dictionary] = []

	var x: float = float(xs[0])
	while x <= float(xs[1]):
		var z: float = float(zs[0])
		while z <= float(zs[1]):
			total += 1
			var demande: Vector3 = Vector3(x, 6.0, z)
			var proche: Vector3 = NavigationServer3D.map_get_closest_point(
				carte, demande)
			var ecart_h: float = Vector2(proche.x - demande.x,
				proche.z - demande.z).length()
			var pose: bool = ecart_h <= TOLERANCE_NAV_M
			if pose:
				sur_navmesh += 1
			var bout: float = INF
			if pose:
				var chemin: PackedVector3Array = NavigationServer3D.map_get_path(
					carte, spawn, proche, true)
				if chemin.size() >= 2:
					bout = chemin[chemin.size() - 1].distance_to(proche)
					if bout <= PORTEE_ATTEIGNABLE_M:
						atteignables += 1
						meilleurs.append({
							"x": proche.x, "y": proche.y, "z": proche.z,
							"ecart": ecart_h, "bout": bout,
						})
			print("[camp] (%6.1f, %6.1f) -> nav (%6.1f, %5.2f, %6.1f) "
				% [x, z, proche.x, proche.y, proche.z]
				+ "ecart_h=%5.2f %s bout=%s"
					% [ecart_h, "POSABLE" if pose else "HORS-NAV",
						("%.2f" % bout) if bout < INF else "aucun chemin"])
			z += PAS_M
		x += PAS_M

	print("[camp] ---------------------------------------------")
	print("[camp] %d points sondés, %d sur navmesh, %d ATTEIGNABLES depuis le spawn"
		% [total, sur_navmesh, atteignables])
	if atteignables == 0:
		push_error("[camp] AUCUN point atteignable — placer un ennemi ici "
			+ "produirait un décor, pas un adversaire.")
		quit(1)
		return
	# Les quatre meilleurs candidats, du plus franchement posé au moins franc.
	meilleurs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["ecart"]) < float(b["ecart"]))
	print("[camp] dix meilleurs candidats (écart au navmesh croissant) :")
	for i: int in range(mini(10, meilleurs.size())):
		var c: Dictionary = meilleurs[i]
		print("[camp]   (%.2f, %.2f, %.2f)  ecart_h=%.3f  bout=%.2f"
			% [c["x"], c["y"], c["z"], c["ecart"], c["bout"]])
	print("[camp] FIN NOMINALE")
	quit(0)
