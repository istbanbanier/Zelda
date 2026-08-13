## V2.1 — l'HYDROLOGIE est physique : lit sous les berges, gués praticables,
## lac en bol, pont qui enjambe vraiment l'eau.
##
## Ce que chaque garde empêche :
##   - un lit au niveau des berges = une « rivière » peinte sur du plat ;
##   - un gué à falaise de bord = ISS-032 (le tablier de 12 m dont le sol
##     passait de 2,00 à -0,63 en 50 cm : la largeur utile n'est PAS la
##     largeur visuelle — contrôle par SONDAGE en diagonale, jamais à l'œil) ;
##   - un lac plat = un disque bleu posé sur le sol ;
##   - un pont posé sur la terre sèche = une traversée qui ne prouve rien.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
## Contenance : de chaque côté du cours, une berge doit REMONTER au-dessus de
## la surface avant cette distance — sinon l'eau s'étalerait sans limite.
const BANK_SEARCH_MAX_M: float = 21.0
const BANK_ABOVE_SURFACE_M: float = 0.15
## Au-delà de cette pente de surface, la section est une CASCADE : elle
## déverse vers l'aval par nature, la contenance latérale n'y a pas de sens.
const CASCADE_SURFACE_SLOPE: float = 0.08
## Gué praticable (ISS-032) : profondeur de marche et épaulement borné.
const FORD_MAX_WADE_DEPTH_M: float = 0.65
const FORD_PROBE_RADIUS_M: int = 12
## La pente de MARCHE contractuelle (§8.2 : ~46°) — le critère est celui du
## jeu, pas un nombre rond : ISS-032 était une falaise à 5,2 m/m, et le
## parcours réel du trajet principal traverse ce gué à pied (suite verte).
const FORD_MAX_STEP_PER_M: float = 1.0355

var _world: Node3D = null


func _mount() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame


func test_l_eau_coule_dans_un_lit_qui_la_contient() -> void:
	remember_saves()
	remember_root()
	await _mount()
	var heightmap: WorldV2Heightmap = _world.call("heightmap") as WorldV2Heightmap

	var faults: Array[String] = []
	for line: PackedVector2Array in [heightmap.river_main_polyline(),
			heightmap.river_trib_polyline()]:
		for i: int in range(line.size() - 1):
			var a: Vector2 = line[i]
			var direction: Vector2 = (line[i + 1] - a).normalized()
			var perp: Vector2 = Vector2(-direction.y, direction.x)
			# L'eau existe au centre du cours (lit sous la surface)…
			if not heightmap.is_in_water(a.x, a.y):
				faults.append("cours à sec en (%.0f, %.0f)" % [a.x, a.y])
				continue
			# Les sections de CASCADE (source, ressaut de l'affluent) déversent
			# vers l'aval par nature — jugé sur la pente de SURFACE observable,
			# jamais sur une constante du générateur.
			var surface: float = heightmap.water_surface_at(a.x, a.y)
			var next_surface: float = heightmap.water_surface_at(
				line[i + 1].x, line[i + 1].y)
			var seg_len: float = a.distance_to(line[i + 1])
			if absf(next_surface - surface) / maxf(seg_len, 0.001) > CASCADE_SURFACE_SLOPE:
				continue
			# …et de chaque côté, une berge REMONTE au-dessus de la surface
			# avant BANK_SEARCH_MAX_M : l'eau est contenue.
			for side: float in [1.0, -1.0]:
				var contained: bool = false
				var probe_m: float = 5.0
				while probe_m <= BANK_SEARCH_MAX_M:
					var shoulder: Vector2 = a + perp * side * probe_m
					if heightmap.height_at(shoulder.x, shoulder.y) \
							>= surface + BANK_ABOVE_SURFACE_M:
						contained = true
						break
					probe_m += 2.0
				if not contained:
					faults.append("eau non contenue côté %+.0f en (%.0f, %.0f)"
						% [side, a.x, a.y])
	check(faults.is_empty(), "chaque section calme est contenue par ses berges — %s"
		% " ; ".join(faults))

	var clean: bool = await restore_root()
	check(clean, "démontage propre — %s" % restore_root_reason())
	restore_saves()


func test_les_trois_gues_sont_praticables_meme_en_diagonale() -> void:
	remember_saves()
	remember_root()
	await _mount()
	var heightmap: WorldV2Heightmap = _world.call("heightmap") as WorldV2Heightmap
	var space: PhysicsDirectSpaceState3D = _world.get_world_3d().direct_space_state

	var fords: Array[Vector2] = heightmap.fords()
	check_equal(fords.size(), 3, "trois gués dans la fonction de hauteur")
	var faults: Array[String] = []
	for ford: Vector2 in fords:
		# Profondeur de MARCHE au cœur du gué : un haut-fond, pas un trou.
		var depth: float = heightmap.water_surface_at(ford.x, ford.y) \
			- heightmap.height_at(ford.x, ford.y)
		if depth > FORD_MAX_WADE_DEPTH_M:
			faults.append("gué (%.0f, %.0f) profond de %.2f m"
				% [ford.x, ford.y, depth])
		# HUIT directions d'approche, sondées AU SOL PHYSIQUE mètre par mètre
		# (ISS-032 : l'approche en diagonale est celle qui tombait à côté).
		for eighth: int in range(8):
			var azimuth: float = TAU * float(eighth) / 8.0
			var direction: Vector2 = Vector2(cos(azimuth), sin(azimuth))
			var previous: float = _floor_y(space, ford)
			for metre: int in range(1, FORD_PROBE_RADIUS_M + 1):
				var p: Vector2 = ford + direction * float(metre)
				var floor_y: float = _floor_y(space, p)
				if floor_y <= -100.0:
					faults.append("gué (%.0f, %.0f) : PAS de sol physique en (%.0f, %.0f)"
						% [ford.x, ford.y, p.x, p.y])
					break
				if absf(floor_y - previous) > FORD_MAX_STEP_PER_M:
					faults.append("gué (%.0f, %.0f) : marche de %.2f m/m vers %.0f° en (%.0f, %.0f)"
						% [ford.x, ford.y, absf(floor_y - previous),
							rad_to_deg(azimuth), p.x, p.y])
					break
				# Nulle part une fosse de noyade sur l'approche.
				var surface: float = heightmap.water_surface_at(p.x, p.y)
				if surface > -1000.0 and surface - floor_y > FORD_MAX_WADE_DEPTH_M:
					faults.append("gué (%.0f, %.0f) : %.2f m d'eau en (%.0f, %.0f)"
						% [ford.x, ford.y, surface - floor_y, p.x, p.y])
					break
				previous = floor_y
	check(faults.is_empty(), "les gués sont praticables (ISS-032) — %s"
		% " ; ".join(faults))

	var clean: bool = await restore_root()
	check(clean, "démontage propre — %s" % restore_root_reason())
	restore_saves()


func test_le_lac_est_un_bol_sous_sa_surface() -> void:
	remember_saves()
	remember_root()
	await _mount()
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	var heightmap: WorldV2Heightmap = _world.call("heightmap") as WorldV2Heightmap

	# Sonde côté OUEST du centre : hors de l'emprise de la chaussée
	# processionnelle, le bol doit être franc.
	var center: Vector2 = heightmap.lake_center()
	var probe: Vector2 = center + Vector2(-7.0, 0.0)
	check(heightmap.height_at(probe.x, probe.y) < -2.0,
		"le fond du lac descend (%.2f m < -2)" % heightmap.height_at(probe.x, probe.y))
	check(heightmap.is_in_water(probe.x, probe.y), "le lac est en eau")
	# La rive ouest est sèche : le bol a un BORD, pas une inondation.
	var shore: Vector2 = center + Vector2(-27.0, 0.0)
	check(not heightmap.is_in_water(shore.x, shore.y), "la rive ouest est sèche")

	var water: Array[Node] = loop.get_nodes_in_group(&"world_v2_water")
	check_equal(water.size(), 3, "trois surfaces d'eau (cours, affluent, lac)")
	var lake_found: bool = false
	for node: Node in water:
		if node.name == "StormLakeWater":
			lake_found = true
	check(lake_found, "le disque du lac existe")

	var clean: bool = await restore_root()
	check(clean, "démontage propre — %s" % restore_root_reason())
	restore_saves()


func test_le_pont_magnetique_enjambe_l_eau() -> void:
	remember_saves()
	remember_root()
	await _mount()
	var heightmap: WorldV2Heightmap = _world.call("heightmap") as WorldV2Heightmap
	var space: PhysicsDirectSpaceState3D = _world.get_world_3d().direct_space_state

	# Au centre du tablier : le premier sol physique est la STRUCTURE whitebox,
	# posée AU-DESSUS d'un lit réellement en eau — un pont sur de la terre
	# sèche ne prouverait rien.
	var deck_center: Vector2 = Vector2(-31.0, -58.0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(deck_center.x, 50.0, deck_center.y),
		Vector3(deck_center.x, -20.0, deck_center.y), 1)
	var hit: Dictionary = space.intersect_ray(query)
	check(not hit.is_empty(), "un sol physique au centre du tablier")
	if not hit.is_empty():
		var collider: Node = hit["collider"] as Node
		check(collider.is_in_group(&"world_v2_whitebox"),
			"le premier sol est le tablier whitebox (%s)" % collider.name)
		check_approx((hit["position"] as Vector3).y, 2.6, 0.7,
			"le tablier porte à hauteur de berge")
	check(heightmap.is_in_water(deck_center.x, deck_center.y),
		"le bras nord coule bien SOUS le tablier")

	var clean: bool = await restore_root()
	check(clean, "démontage propre — %s" % restore_root_reason())
	restore_saves()


## Premier sol PHYSIQUE (masque 1) sous (x, z) — -1000 si aucun.
func _floor_y(space: PhysicsDirectSpaceState3D, p: Vector2) -> float:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(p.x, 200.0, p.y), Vector3(p.x, -60.0, p.y), 1)
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return -1000.0
	return (hit["position"] as Vector3).y
