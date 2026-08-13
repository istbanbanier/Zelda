## V2.1 — COHÉRENCE EN DONNÉES PURES entre routes, hydrologie et lieux.
##
## POURQUOI CE FICHIER EXISTE : une route qui traverse la rivière hors d'un
## gué, un gué posé à côté de son cours, ou un lieu noyé dans l'emprise du
## lac sont des mensonges spatiaux — invisibles dans un JSON, immédiats
## en jeu. Ces contrôles sont PURS (géométrie 2D sur les polylignes du
## layout) : ils jugent la carte directrice elle-même, avant tout terrain.
##
## HISTOIRE : au premier passage (2026-08-13), ce fichier a rougi sur le
## layout V2.0 committé — traversées hors gué sur les quatre routes, gué est
## posé loin de son cours, un lieu dans l'emprise du lac, des sites de berge
## dans la bande creusée. La correction de la carte directrice qui a suivi
## est documentée dans evidence/world_v2/v2_1/ ; ce test est le garde qui
## empêche ces défauts de revenir.
extends GateTestCase

## Une traversée de cours d'eau est LÉGALE si elle passe par un gué (rayon
## d'influence du profil doux) ou par le tablier du pont magnétique.
const FORD_CROSSING_RADIUS_M: float = 24.0
## Demi-longueur du tablier (28 m) + 2 m de tolérance, mesurée depuis le
## CENTRE du tablier (site + 13 m à l'est — géométrie déclarée du bâtisseur
## d'hydrologie). Revue contradictoire D2 : l'ancien maxf(24, 12) rendait la
## branche du pont morte et « légalisait » une traversée à 24 m du site.
const BRIDGE_CROSSING_RADIUS_M: float = 16.0
const BRIDGE_DECK_CENTER_EAST_M: float = 13.0
## Un gué doit être posé SUR son cours (sinon le profil doux adoucit un champ).
const FORD_ON_COURSE_MAX_M: float = 3.0
## Bande creusée par le cours principal (lit + berge) : aucun site n'y vit.
const MAIN_CARVE_HALF_W: float = 9.5
const TRIB_CARVE_HALF_W: float = 6.3
## Marge autour du lac : un lieu « au bord du lac » n'est pas DANS le lac.
const LAKE_CLEARANCE_M: float = 2.0

var _layout: Dictionary = {}


func _load() -> Dictionary:
	if _layout.is_empty():
		_layout = WorldV2Layout.load_layout()
	return _layout


func test_chaque_traversee_de_riviere_passe_par_un_gue_ou_le_pont() -> void:
	var layout: Dictionary = _load()
	check(not layout.is_empty(), "la carte directrice se charge")
	var courses: Array[PackedVector2Array] = _courses(layout)
	var legal_points: Array[Vector2] = _legal_crossings(layout)
	check(legal_points.size() >= 4, "gués + pont déclarés (trouvés : %d)" % legal_points.size())

	var offenders: Array[String] = []
	var routes: Dictionary = layout.get("routes", {}) as Dictionary
	for route_name: String in ["main_path", "river_route", "heights_route", "ruins_route"]:
		var route: Dictionary = routes.get(route_name, {}) as Dictionary
		var waypoints: Array = route.get("waypoints_xz", []) as Array
		check(waypoints.size() >= 2, "%s possède un tracé" % route_name)
		for i: int in range(waypoints.size() - 1):
			var a: Vector2 = _v2(waypoints[i] as Array)
			var b: Vector2 = _v2(waypoints[i + 1] as Array)
			for course: PackedVector2Array in courses:
				for j: int in range(course.size() - 1):
					var hit: Variant = Geometry2D.segment_intersects_segment(
						a, b, course[j], course[j + 1])
					if hit == null:
						continue
					var crossing: Vector2 = hit as Vector2
					if not _is_legal_crossing(crossing, legal_points):
						offenders.append("%s traverse l'eau HORS GUÉ en (%.0f, %.0f)"
							% [route_name, crossing.x, crossing.y])
	check(offenders.is_empty(),
		"aucune route ne traverse un cours d'eau hors d'un gué ou du pont — %s"
			% " ; ".join(offenders))


func test_chaque_gue_est_pose_sur_son_cours() -> void:
	var layout: Dictionary = _load()
	var courses: Array[PackedVector2Array] = _courses(layout)
	var offenders: Array[String] = []
	for entry: Variant in (layout.get("river", {}) as Dictionary).get("fords", []) as Array:
		var ford: Dictionary = entry as Dictionary
		var pos: Vector2 = _v2(ford.get("pos_xz", [0, 0]) as Array)
		var d: float = _distance_to_courses(pos, courses)
		if d > FORD_ON_COURSE_MAX_M:
			offenders.append("%s à %.1f m de son cours" % [ford.get("id", "?"), d])
	check(offenders.is_empty(),
		"chaque gué est sur le lit qu'il traverse (max %.1f m) — %s"
			% [FORD_ON_COURSE_MAX_M, " ; ".join(offenders)])


func test_aucun_lieu_dans_l_eau() -> void:
	var layout: Dictionary = _load()
	var courses_main: PackedVector2Array = _polyline(
		(layout.get("river", {}) as Dictionary).get("main_course_xz", []) as Array)
	var courses_trib: PackedVector2Array = _polyline(
		(layout.get("river", {}) as Dictionary).get("west_tributary_xz", []) as Array)
	var mouth: Dictionary = (layout.get("river", {}) as Dictionary).get("mouth", {}) as Dictionary
	var lake_center: Vector2 = _v2(mouth.get("center_xz", [0, 0]) as Array)
	var lake_radius: float = float(mouth.get("radius_m", 0.0))
	check(lake_radius > 0.0, "le lac déclare un rayon")

	var offenders: Array[String] = []
	var everything: Array = []
	everything.append_array(layout.get("pois", []) as Array)
	everything.append_array(layout.get("systemic_sites", []) as Array)
	for entry: Variant in everything:
		var place: Dictionary = entry as Dictionary
		var site: Variant = place.get("v2_site")
		if site == null:
			continue
		var pos: Vector2 = Vector2(float((site as Array)[0]), float((site as Array)[2]))
		var place_id: String = String(place.get("id", "?"))
		if pos.distance_to(lake_center) < lake_radius + LAKE_CLEARANCE_M:
			offenders.append("%s dans l'emprise du lac" % place_id)
		var d_main: float = _distance_to_polyline(pos, courses_main)
		if d_main < MAIN_CARVE_HALF_W:
			offenders.append("%s dans la bande creusée du cours principal (%.1f m)"
				% [place_id, d_main])
		var d_trib: float = _distance_to_polyline(pos, courses_trib)
		if d_trib < TRIB_CARVE_HALF_W:
			offenders.append("%s dans la bande creusée de l'affluent (%.1f m)"
				% [place_id, d_trib])
	check(offenders.is_empty(),
		"aucun lieu dans une emprise d'eau — %s" % " ; ".join(offenders))


func test_les_checkpoints_et_ancres_sont_hors_d_eau() -> void:
	var layout: Dictionary = _load()
	var courses: Array[PackedVector2Array] = _courses(layout)
	var mouth: Dictionary = (layout.get("river", {}) as Dictionary).get("mouth", {}) as Dictionary
	var lake_center: Vector2 = _v2(mouth.get("center_xz", [0, 0]) as Array)
	var lake_radius: float = float(mouth.get("radius_m", 0.0))
	var offenders: Array[String] = []
	var spots: Array[Array] = []
	for entry: Variant in layout.get("checkpoints", []) as Array:
		var checkpoint: Dictionary = entry as Dictionary
		if checkpoint.get("pos") != null:
			spots.append([String(checkpoint.get("id", "?")), checkpoint["pos"] as Array])
	for entry: Variant in layout.get("regions", []) as Array:
		var anchor: Variant = (entry as Dictionary).get("save_anchor")
		if anchor != null and (anchor as Dictionary).get("pos") != null:
			spots.append([String((anchor as Dictionary).get("id", "?")),
				(anchor as Dictionary)["pos"] as Array])
	check(spots.size() >= 10, "checkpoints + ancres relevés (%d)" % spots.size())
	for spot: Array in spots:
		var pos: Vector2 = Vector2(float((spot[1] as Array)[0]), float((spot[1] as Array)[2]))
		if _distance_to_courses(pos, courses) < MAIN_CARVE_HALF_W \
				or pos.distance_to(lake_center) < lake_radius + LAKE_CLEARANCE_M:
			offenders.append(String(spot[0]))
	check(offenders.is_empty(),
		"aucun point de reprise dans une emprise d'eau — %s" % ", ".join(offenders))


func test_le_cours_n_a_pas_de_longue_ligne_droite() -> void:
	var layout: Dictionary = _load()
	var main_course: PackedVector2Array = _polyline(
		(layout.get("river", {}) as Dictionary).get("main_course_xz", []) as Array)
	check(main_course.size() >= 8, "le cours principal a assez de sommets")
	# Une « ligne droite » est une suite de segments quasi colinéaires : la
	# V1 avait une bande rectiligne (WORLD_ATLAS) — interdit de la refaire.
	var longest_straight: float = 0.0
	var current: float = 0.0
	for i: int in range(main_course.size() - 1):
		var seg_len: float = main_course[i].distance_to(main_course[i + 1])
		if i == 0:
			current = seg_len
			continue
		var prev_dir: Vector2 = (main_course[i] - main_course[i - 1]).normalized()
		var this_dir: Vector2 = (main_course[i + 1] - main_course[i]).normalized()
		# `angle_to` est SIGNÉ : sans absf, un virage à -30° passait pour une
		# ligne droite et la mesure gonflait (118 m puis 66 m lus au premier
		# passage pour des runs réels bien plus courts). Le SCÉNARIO était
		# faux, pas le seuil — le seuil n'a pas bougé.
		if absf(prev_dir.angle_to(this_dir)) < deg_to_rad(10.0):
			current += seg_len
		else:
			longest_straight = maxf(longest_straight, current)
			current = seg_len
	longest_straight = maxf(longest_straight, current)
	check(longest_straight <= 48.0,
		"aucune section quasi rectiligne de plus de 48 m (mesuré : %.0f m)" % longest_straight)


## -- outillage pur ------------------------------------------------------------

func _v2(pair: Array) -> Vector2:
	return Vector2(float(pair[0]), float(pair[1]))


func _polyline(points: Array) -> PackedVector2Array:
	var line: PackedVector2Array = PackedVector2Array()
	for point: Variant in points:
		line.append(_v2(point as Array))
	return line


func _courses(layout: Dictionary) -> Array[PackedVector2Array]:
	var river: Dictionary = layout.get("river", {}) as Dictionary
	var courses: Array[PackedVector2Array] = []
	courses.append(_polyline(river.get("main_course_xz", []) as Array))
	courses.append(_polyline(river.get("west_tributary_xz", []) as Array))
	return courses


func _legal_crossings(layout: Dictionary) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for entry: Variant in (layout.get("river", {}) as Dictionary).get("fords", []) as Array:
		points.append(_v2((entry as Dictionary).get("pos_xz", [0, 0]) as Array))
	for entry: Variant in layout.get("systemic_sites", []) as Array:
		var site_entry: Dictionary = entry as Dictionary
		if StringName(String(site_entry.get("id", ""))) == &"valley.poi.magnetic_bridge.01":
			var site: Array = site_entry.get("v2_site", []) as Array
			if site.size() == 3:
				# Le point légal est le CENTRE du tablier, pas la culée.
				points.append(Vector2(float(site[0]) + BRIDGE_DECK_CENTER_EAST_M,
					float(site[2])))
	return points


func _is_legal_crossing(crossing: Vector2, legal_points: Array[Vector2]) -> bool:
	for i: int in range(legal_points.size()):
		# Le dernier point est le pont magnétique : SON rayon, celui du
		# tablier — jamais élargi au rayon de gué (revue D2).
		var radius: float = BRIDGE_CROSSING_RADIUS_M \
			if i == legal_points.size() - 1 else FORD_CROSSING_RADIUS_M
		if crossing.distance_to(legal_points[i]) <= radius:
			return true
	return false


func _distance_to_polyline(p: Vector2, line: PackedVector2Array) -> float:
	if line.size() < 2:
		return INF
	var best: float = INF
	for i: int in range(line.size() - 1):
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(p, line[i], line[i + 1])
		best = minf(best, p.distance_to(closest))
	return best


func _distance_to_courses(p: Vector2, courses: Array[PackedVector2Array]) -> float:
	var best: float = INF
	for course: PackedVector2Array in courses:
		best = minf(best, _distance_to_polyline(p, course))
	return best
