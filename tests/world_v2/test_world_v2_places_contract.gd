## V2.3 — FILET des LIEUX : le lot pilote est fait de VRAIES scènes posées
## par le layout, assises sur le terrain GELÉ, sans acteur ni blocage.
##
## Écrit ROUGE d'abord (2026-08-14, directive V2.3 §6) : au moment de son
## écriture, AUCUN lieu n'existe — les neuf sujets du lot pilote sont de
## simples marqueurs (`WorldV2MarkersBuilder`), et le registre du
## bâtisseur de lieux est vide. Chaque écart est nommé. Vert seulement
## quand V2.3-A a livré des scènes autonomes, enregistrées, ancrées sur le
## terrain et sûres pour les routes contractuelles.
##
## Ce que ce filet attrape (directive §6) : POI resté marqueur · scène non
## autonome · ID inconnu ou dupliqué · placement divergent du layout ·
## bâti flottant ou enterré · collision sur une route · acteur prématuré.
##
## V2.3-B lot 1 (2026-08-21) : le même filet couvre désormais SIX sujets de
## plus (`LOT1_PLACES`). Les assertions partagées s'appliquent à l'union des
## deux lots — un lot qui n'y entrerait pas pourrait rester marqueur sans
## qu'un seul test rougisse. S'y ajoute
## `test_le_lot_1_ne_gene_ni_l_eau_ni_les_fenetres`, qui couvre trois écarts
## qu'aucun autre filet n'attrape : chemin de scène mort, collider dans une
## bande creusée d'eau, et fenêtre gelée bouchée AVEC le nom du coupable.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"

## Le LOT PILOTE (directive V2.3 §5) — neuf sujets, jamais moins.
const PILOT_PLACES: Array[StringName] = [
	&"camp",
	&"valley.poi.riverside_village.01",
	&"valley.poi.abandoned_farm.01",
	&"valley.poi.stone_bridge.01",
	&"valley.poi.waterfall_cave.01",
	&"valley.poi.thunderstruck_tree.01",
	&"valley.poi.ember_raider_camps.01",
	&"valley.poi.conductive_basin.01",
	&"pylon",
]

## LE LOT 1 de V2.3-B (docs/V2_3_B_LOT1_CONTRAT.md §1) — six sujets, jamais
## moins.
##
## ÉCRIT ROUGE D'ABORD (2026-08-21, voie A). Au moment de son écriture, les
## six sujets sont de simples marqueurs `WorldV2MarkersBuilder` et le
## registre du bâtisseur ne les connaît pas : chacune des assertions
## ci-dessous nomme un écart réel, aucune n'est décorative. Vert seulement
## quand la voie B aura livré six scènes autonomes, enregistrées, assises sur
## le terrain gelé et sûres pour les routes et les six fenêtres.
const LOT1_PLACES: Array[StringName] = [
	&"valley.poi.watchtower_ruin.01",
	&"valley.poi.overlook_summit.01",
	&"valley.poi.turquoise_spring.01",
	&"valley.poi.forest_shrine.01",
	&"valley.poi.barrow_cemetery.01",
	&"valley.poi.flower_field.01",
]

## La visée doit rester libre sur cette fraction du trajet caméra → cible.
## MÊME valeur que `test_world_v2_cameras.gd` : ce filet-ci ne dit pas si la
## fenêtre est bouchée — l'autre le fait déjà — il dit PAR QUI, ce qu'un
## verdict global ne donne pas.
const CLEAR_SIGHT_FRACTION: float = 0.6
## Assise : écart maximal entre un point de support DÉCLARÉ et le sol gelé.
const SUPPORT_TOLERANCE_M: float = 0.65
## La racine d'un lieu est ancrée au sol par le bâtisseur.
const ROOT_GROUND_TOLERANCE_M: float = 1.0
## Écart XZ maximal entre la racine et le site du layout.
const SITE_XZ_TOLERANCE_M: float = 0.5
## Aucun collider de lieu à moins de ce rayon d'un échantillon de route
## (le corps des tests de traversée fait 0,35 m de rayon).
const ROUTE_CLEAR_M: float = 1.2
## Un lieu entier plus haut que ça au-dessus du sol flotte ; plus bas que
## ça sous le sol, il est enterré.
const FLOATING_LIMIT_M: float = 1.0
const BURIED_LIMIT_M: float = 6.0

var _world: Node3D = null
var _heightmap: RefCounted = null


## Tout ce qui DOIT être un lieu réel à ce stade du projet. Les assertions
## partagées ci-dessous s'appliquent au lot pilote ET au lot 1 : un lot qui
## n'entrerait pas ici pourrait rester marqueur sans qu'un seul test rougisse.
static func _lot_attendu() -> Array[StringName]:
	var tout: Array[StringName] = []
	tout.append_array(PILOT_PLACES)
	tout.append_array(LOT1_PLACES)
	return tout


func test_le_lot_pilote_est_fait_de_lieux_reels() -> void:
	await _mount()
	var faults: Array[String] = []

	# Le registre ne connaît que des IDs légitimes, et couvre les deux lots.
	var layout: Dictionary = WorldV2Layout.load_layout()
	var known: Dictionary = {}
	for poi: Dictionary in layout.get("pois", []) as Array:
		known[StringName(poi.get("id", ""))] = true
	for site: Dictionary in layout.get("systemic_sites", []) as Array:
		known[StringName(site.get("id", ""))] = true
	known[&"camp"] = true
	known[&"pylon"] = true
	for registered: StringName in WorldV2PlacesBuilder.REGISTRY.keys():
		if not known.has(registered):
			faults.append("registre : ID inconnu du layout — %s" % registered)
	for attendu: StringName in _lot_attendu():
		if not WorldV2PlacesBuilder.REGISTRY.has(attendu):
			faults.append("%s : RESTÉ SIMPLE MARQUEUR (absent du registre)" % attendu)

	# Chaque lieu monté : une vraie PackedScene, identifiée, posée au site
	# du layout, ancrée au sol gelé.
	var by_id: Dictionary = {}
	for node: Node in _world.get_tree().get_nodes_in_group(&"world_v2_places"):
		var place: Node3D = node as Node3D
		var place_id: StringName = place.get_meta(&"place_id", &"") as StringName
		if place_id == &"":
			faults.append("%s : lieu sans meta place_id" % place.name)
			continue
		if by_id.has(place_id):
			faults.append("%s : place_id DUPLIQUÉ" % place_id)
			continue
		by_id[place_id] = place
		if place.scene_file_path.is_empty():
			faults.append("%s : pas une PackedScene autonome" % place_id)
		var site: Vector3 = _layout_site(layout, place_id)
		if site == Vector3.INF:
			faults.append("%s : aucun site dans le layout" % place_id)
		else:
			var dx: float = absf(place.global_position.x - site.x)
			var dz: float = absf(place.global_position.z - site.z)
			if dx > SITE_XZ_TOLERANCE_M or dz > SITE_XZ_TOLERANCE_M:
				faults.append("%s : posé à (%.1f, %.1f), layout (%.1f, %.1f)"
					% [place_id, place.global_position.x, place.global_position.z,
						site.x, site.z])
			var ground: float = float(_heightmap.call("height_at",
				place.global_position.x, place.global_position.z))
			if absf(place.global_position.y - ground) > ROOT_GROUND_TOLERANCE_M:
				faults.append("%s : racine à y=%.2f, sol à %.2f"
					% [place_id, place.global_position.y, ground])
	for attendu: StringName in _lot_attendu():
		if not by_id.has(attendu) \
				and WorldV2PlacesBuilder.REGISTRY.has(attendu):
			faults.append("%s : enregistré mais ABSENT du monde monté" % attendu)

	var shown: Array[String] = faults.slice(0, 6)
	if faults.size() > 6:
		shown.append("… et %d autres" % (faults.size() - 6))
	check(faults.is_empty(),
		"les lots pilote et 1 sont faits de lieux réels (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(shown)])
	await _unmount()


func test_chaque_scene_du_registre_est_autonome() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_root()
	var faults: Array[String] = []
	for place_id: StringName in WorldV2PlacesBuilder.REGISTRY.keys():
		var path: String = String(WorldV2PlacesBuilder.REGISTRY[place_id])
		if not ResourceLoader.exists(path):
			faults.append("%s : scène inexistante %s" % [place_id, path])
			continue
		var packed: PackedScene = load(path) as PackedScene
		var place: Node3D = packed.instantiate() as Node3D
		if place == null:
			faults.append("%s : la scène ne s'instancie pas seule" % place_id)
			continue
		loop.root.add_child(place)
		await loop.process_frame
		var supports: Variant = place.get_meta(&"support_points", null)
		if not (supports is PackedVector3Array) \
				or (supports as PackedVector3Array).is_empty():
			faults.append("%s : aucun point de support déclaré (fondations)"
				% place_id)
		place.queue_free()
		await loop.process_frame
	# ROUGE tant que le lot pilote n'est pas couvert : un registre vide ne
	# peut pas verdir ce filet par absence de sujets.
	check(WorldV2PlacesBuilder.REGISTRY.size() >= _lot_attendu().size(),
		"le registre couvre les lots pilote et 1 (%d/%d)"
		% [WorldV2PlacesBuilder.REGISTRY.size(), _lot_attendu().size()])
	check(faults.is_empty(),
		"chaque scène du registre est autonome (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(faults.slice(0, 5))])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (scènes autonomes) — %s"
		% restore_root_reason())


func test_les_fondations_epousent_le_terrain_gele() -> void:
	await _mount()
	var places: Array[Node] = _world.get_tree().get_nodes_in_group(
		&"world_v2_places")
	var faults: Array[String] = []
	if places.size() < _lot_attendu().size():
		faults.append("seulement %d lieu(x) monté(s) sur %d attendus"
			% [places.size(), _lot_attendu().size()])
	for node: Node in places:
		var place: Node3D = node as Node3D
		var place_id: StringName = place.get_meta(&"place_id", &"?") as StringName
		# a. Chaque point de support déclaré touche le sol gelé.
		var supports: Variant = place.get_meta(&"support_points", null)
		if not (supports is PackedVector3Array) \
				or (supports as PackedVector3Array).is_empty():
			faults.append("%s : aucun point de support déclaré" % place_id)
		else:
			for local_point: Vector3 in supports as PackedVector3Array:
				var world_point: Vector3 = place.to_global(local_point)
				var ground: float = float(_heightmap.call("height_at",
					world_point.x, world_point.z))
				if absf(world_point.y - ground) > SUPPORT_TOLERANCE_M:
					faults.append("%s : support (%.1f, %.1f) à %.2f m du sol"
						% [place_id, world_point.x, world_point.z,
							world_point.y - ground])
		# b. Le lieu entier n'est ni flottant ni enterré.
		var bounds: AABB = _visual_bounds(place)
		if bounds.size == Vector3.ZERO:
			faults.append("%s : aucun maillage visuel" % place_id)
			continue
		var center_ground: float = float(_heightmap.call("height_at",
			place.global_position.x, place.global_position.z))
		if bounds.position.y - center_ground > FLOATING_LIMIT_M:
			faults.append("%s : FLOTTE à %.2f m au-dessus du sol"
				% [place_id, bounds.position.y - center_ground])
		if center_ground - bounds.position.y > BURIED_LIMIT_M:
			faults.append("%s : ENTERRÉ de %.2f m"
				% [place_id, center_ground - bounds.position.y])
	var shown: Array[String] = faults.slice(0, 6)
	if faults.size() > 6:
		shown.append("… et %d autres" % (faults.size() - 6))
	check(faults.is_empty(),
		"les fondations épousent le terrain gelé (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(shown)])
	await _unmount()


func test_aucun_acteur_et_les_routes_restent_libres() -> void:
	await _mount()
	var faults: Array[String] = []
	# a. LE CONTRAT DE BUDGET (ISS-074 §3) — il REMPLACE, ce jour, le contrat
	# « acteur prématuré » qui exigeait `= 0` partout. La directive V2.3 §2
	# interdisait les acteurs tant que le peuplement n'était pas conçu ; il
	# l'est désormais, et un monde d'action-aventure durablement vide serait
	# le vrai défaut. Ce qui reste interdit, c'est le peuplement SANS
	# gouvernance :
	#   1. plafond d'agents — celui du `CombatCoordinator`, jamais une copie ;
	#   2. un seul coordinateur ;
	#   3. territoire borné pour chacun ;
	#   4. aucun acteur sous `Places` — les lieux restent du DÉCOR, le
	#      peuplement vit sous `Encounters`.
	# Le détail par ennemi (composition, identifiants, atteignabilité, calmes,
	# non-duplication, morts persistées) est le portail
	# `test_world_v2_iss074_portail.gd` ; ici on tient le budget, pas la
	# rencontre.
	var acteurs: Array[Node] = _world.find_children("*", "EnemyBase", true,
		false)
	var coordinateurs: Array[Node] = _world.find_children("*",
		"CombatCoordinator", true, false)
	check(acteurs.size() <= CombatCoordinator.MAX_ACTIVE_AI,
		"plafond d'agents respecté : %d acteur(s) pour un maximum de %d "
			% [acteurs.size(), CombatCoordinator.MAX_ACTIVE_AI]
		+ "(§12.9, lu SUR le coordinateur — une seconde constante diverge)")
	if not acteurs.is_empty():
		check_equal(coordinateurs.size(), 1,
			"un monde peuplé porte exactement un `CombatCoordinator` — sans "
			+ "lui les tokens sont accordés d'office et §12.8 meurt en silence")
		var infinis: Array[String] = []
		for acteur: Node in acteurs:
			var tuning: Variant = acteur.get("tuning")
			if tuning == null \
					or float(tuning.get("max_pursuit_distance")) <= 0.0:
				infinis.append(String(acteur.name))
		check(infinis.is_empty(),
			"chaque acteur a un territoire borné — poursuivants infinis : %s"
				% ", ".join(infinis))
	var places_root: Node3D = _world.get_node("Places") as Node3D
	for node: Node in places_root.find_children("*", "", true, false):
		var script: Script = node.get_script() as Script
		if script == null:
			continue
		var path: String = script.resource_path
		if path.contains("/enemies/") or path.contains("/ai/"):
			faults.append("acteur prématuré : %s porte %s" % [node.name, path])
	# b. Aucun collider de lieu sur les routes contractuelles.
	var footprints: Array[AABB] = []
	var owners: Array[StringName] = []
	for body: Node in places_root.find_children("*", "StaticBody3D", true, false):
		for shape_node: Node in (body as StaticBody3D).find_children(
				"*", "CollisionShape3D", false, false):
			var shape_box: AABB = _shape_bounds(shape_node as CollisionShape3D)
			if shape_box.size != Vector3.ZERO:
				footprints.append(shape_box)
				var place: Node = body
				while place != null and not place.has_meta(&"place_id"):
					place = place.get_parent()
				owners.append(place.get_meta(&"place_id", &"?") as StringName
					if place != null else &"?")
	var route_faults: int = 0
	for route: Node in _world.get_tree().get_nodes_in_group(&"world_v2_routes"):
		var waypoints: Array = route.get_meta(&"waypoints_xz", []) as Array
		for i: int in range(waypoints.size() - 1):
			var a: Vector2 = Vector2(float((waypoints[i] as Array)[0]),
				float((waypoints[i] as Array)[1]))
			var b: Vector2 = Vector2(float((waypoints[i + 1] as Array)[0]),
				float((waypoints[i + 1] as Array)[1]))
			var length: float = a.distance_to(b)
			var steps: int = maxi(1, int(length))
			for s: int in range(steps + 1):
				var p: Vector2 = a.lerp(b, float(s) / float(steps))
				for f: int in range(footprints.size()):
					var box: AABB = footprints[f]
					if p.x > box.position.x - ROUTE_CLEAR_M \
							and p.x < box.end.x + ROUTE_CLEAR_M \
							and p.y > box.position.z - ROUTE_CLEAR_M \
							and p.y < box.end.z + ROUTE_CLEAR_M:
						route_faults += 1
						if route_faults <= 3:
							faults.append("%s bloque %s vers (%.0f, %.0f)"
								% [owners[f], route.name, p.x, p.y])
	if route_faults > 3:
		faults.append("… %d empiétement(s) de route au total" % route_faults)
	check(faults.is_empty(),
		"aucun acteur ni blocage de route (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(faults.slice(0, 6))])
	await _unmount()


## LOT 1 — ce que les assertions partagées ci-dessus ne disent PAS.
##
## Trois écarts nommés, choisis parce qu'aucun autre filet ne les attrape :
##
##  1. **chemin de scène mort** — une entrée de `REGISTRY` qui pointe vers un
##     `.tscn` inexistant produit un `push_error` à CHAQUE montage du monde,
##     dans toutes les suites, sans qu'aucun test ne désigne le coupable ;
##  2. **collider dans une bande creusée** — les demi-largeurs de creusement
##     de `WorldV2Heightmap` sont interdites à un lieu (contrat du lot §2.4).
##     Le filet des fondations mesure la RACINE ; il ne dit rien d'une jetée,
##     d'un contrefort ou d'un éboulis qui s'avance vers le lit ;
##  3. **fenêtre gelée bouchée, et PAR QUI** — `test_world_v2_cameras.gd`
##     rougit déjà si un rayon est coupé, mais son verdict porte sur la
##     caméra. Ici on remonte au `place_id` propriétaire : c'est la
##     différence entre « cam05 est bouchée » et « le belvédère la bouche ».
func test_le_lot_1_ne_gene_ni_l_eau_ni_les_fenetres() -> void:
	await _mount()
	var faults: Array[String] = []

	# 1. Registre vivant.
	for wanted: StringName in LOT1_PLACES:
		if not WorldV2PlacesBuilder.REGISTRY.has(wanted):
			faults.append("%s : absent du registre du bâtisseur de lieux" % wanted)
			continue
		var path: String = String(WorldV2PlacesBuilder.REGISTRY[wanted])
		if not ResourceLoader.exists(path):
			faults.append("%s : CHEMIN DE SCÈNE MORT (%s) — erreur à chaque montage"
				% [wanted, path])

	# Les lieux du lot 1 réellement montés, et leurs colliders.
	var mounted: Dictionary = {}
	for node: Node in _world.get_tree().get_nodes_in_group(&"world_v2_places"):
		var place: Node3D = node as Node3D
		var place_id: StringName = place.get_meta(&"place_id", &"") as StringName
		if LOT1_PLACES.has(place_id):
			mounted[place_id] = place
	# PLANCHER : sans lui, ce test verdirait sur un monde où aucun sujet du
	# lot 1 n'existe — le piège de l'assertion sautée (tests/CLAUDE.md).
	check_equal(mounted.size(), LOT1_PLACES.size(),
		"les six sujets du lot 1 sont montés dans le monde")

	# 2. Aucun collider du lot 1 dans une bande creusée d'eau.
	var main_course: PackedVector2Array = _heightmap.call(
		"river_main_polyline") as PackedVector2Array
	var tributary: PackedVector2Array = _heightmap.call(
		"river_trib_polyline") as PackedVector2Array
	var lake_center: Vector2 = _heightmap.call("lake_center") as Vector2
	var lake_radius: float = float(_heightmap.call("lake_radius"))
	var main_band: float = WorldV2Heightmap.RIVER_BED_HALF_W \
		+ WorldV2Heightmap.RIVER_BANK_W
	var trib_band: float = WorldV2Heightmap.TRIB_BED_HALF_W \
		+ WorldV2Heightmap.TRIB_BANK_W
	var lake_band: float = lake_radius + 2.0
	for place_id: StringName in mounted.keys():
		var place: Node3D = mounted[place_id] as Node3D
		for body: Node in place.find_children("*", "StaticBody3D", true, false):
			for shape_node: Node in (body as StaticBody3D).find_children(
					"*", "CollisionShape3D", false, false):
				var box: AABB = _shape_bounds(shape_node as CollisionShape3D)
				if box.size == Vector3.ZERO:
					continue
				var d_main: float = _distance_box_polyline(box, main_course)
				if d_main < main_band:
					faults.append("%s/%s à %.2f m du cours principal (bande %.1f m)"
						% [place_id, body.name, d_main, main_band])
				var d_trib: float = _distance_box_polyline(box, tributary)
				if d_trib < trib_band:
					faults.append("%s/%s à %.2f m de l'affluent (bande %.1f m)"
						% [place_id, body.name, d_trib, trib_band])
				var d_lake: float = _distance_box_point(box, lake_center)
				if d_lake < lake_band:
					faults.append("%s/%s à %.2f m du centre du lac (bande %.1f m)"
						% [place_id, body.name, d_lake, lake_band])

	# 3. Les six fenêtres gelées, et le NOM du lieu qui les bouche.
	var space: PhysicsDirectSpaceState3D = _world.get_world_3d().direct_space_state
	var windows: int = 0
	for node: Node in _world.get_tree().get_nodes_in_group(
			&"world_v2_capture_cameras"):
		var camera: Camera3D = node as Camera3D
		if camera == null:
			continue
		windows += 1
		var target: Vector3 = camera.get_meta(&"target", Vector3.ZERO) as Vector3
		if target == Vector3.ZERO:
			continue
		var eye: Vector3 = camera.global_position
		var sight_end: Vector3 = eye.lerp(target, CLEAR_SIGHT_FRACTION)
		var query: PhysicsRayQueryParameters3D = \
			PhysicsRayQueryParameters3D.create(eye, sight_end, 1)
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			continue
		var owner_id: StringName = _owning_place(hit["collider"] as Node)
		if not LOT1_PLACES.has(owner_id):
			continue
		var at: Vector3 = hit["position"] as Vector3
		faults.append("%s bouche %s à %.0f m (en %.0f, %.0f)"
			% [owner_id, camera.name, eye.distance_to(at), at.x, at.z])
	# Second plancher : un monde sans caméra ne prouve rien sur les fenêtres.
	check_equal(windows, 6, "les six fenêtres gelées sont là pour être éprouvées")

	var shown: Array[String] = faults.slice(0, 6)
	if faults.size() > 6:
		shown.append("… et %d autres" % (faults.size() - 6))
	check(faults.is_empty(),
		"le lot 1 laisse l'eau et les fenêtres libres (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(shown)])
	await _unmount()


## -- outillage ----------------------------------------------------------------

func _mount() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame
	_heightmap = _world.get("_heightmap") as RefCounted


func _unmount() -> void:
	var clean: bool = await restore_root()
	check(clean, "démontage propre (lieux) — %s" % restore_root_reason())
	restore_saves()


func _layout_site(layout: Dictionary, place_id: StringName) -> Vector3:
	if place_id == &"pylon":
		return _as_vec3((layout.get("spec_anchors", {}) as Dictionary).get(
			"pylon", null))
	if place_id == &"camp":
		for checkpoint: Dictionary in layout.get("checkpoints", []) as Array:
			if StringName(checkpoint.get("id", "")) == &"camp":
				return _as_vec3(checkpoint.get("pos", null))
		return Vector3.INF
	for poi: Dictionary in layout.get("pois", []) as Array:
		if StringName(poi.get("id", "")) == place_id:
			return _as_vec3(poi.get("v2_site", null))
	for site: Dictionary in layout.get("systemic_sites", []) as Array:
		if StringName(site.get("id", "")) == place_id:
			return _as_vec3(site.get("v2_site", null))
	return Vector3.INF


func _as_vec3(value: Variant) -> Vector3:
	if value is Array and (value as Array).size() == 3:
		var raw: Array = value as Array
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.INF


## AABB monde fusionnée des maillages visibles d'un lieu.
func _visual_bounds(place: Node3D) -> AABB:
	var merged: AABB = AABB()
	var first: bool = true
	for mesh_node: Node in place.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = mesh_node as MeshInstance3D
		if instance.mesh == null:
			continue
		var box: AABB = instance.global_transform * instance.mesh.get_aabb()
		if first:
			merged = box
			first = false
		else:
			merged = merged.merge(box)
	return merged


## AABB monde approchée d'une forme de collision (boîte englobante locale
## transformée) — suffisante pour un test de couloir.
func _shape_bounds(shape_node: CollisionShape3D) -> AABB:
	var shape: Shape3D = shape_node.shape
	if shape == null:
		return AABB()
	var local: AABB = AABB()
	if shape is BoxShape3D:
		var size: Vector3 = (shape as BoxShape3D).size
		local = AABB(-size * 0.5, size)
	elif shape is SphereShape3D:
		var r: float = (shape as SphereShape3D).radius
		local = AABB(Vector3(-r, -r, -r), Vector3(r * 2.0, r * 2.0, r * 2.0))
	elif shape is CylinderShape3D:
		var cyl: CylinderShape3D = shape as CylinderShape3D
		local = AABB(Vector3(-cyl.radius, -cyl.height * 0.5, -cyl.radius),
			Vector3(cyl.radius * 2.0, cyl.height, cyl.radius * 2.0))
	elif shape is CapsuleShape3D:
		var cap: CapsuleShape3D = shape as CapsuleShape3D
		local = AABB(Vector3(-cap.radius, -cap.height * 0.5, -cap.radius),
			Vector3(cap.radius * 2.0, cap.height, cap.radius * 2.0))
	elif shape is ConvexPolygonShape3D:
		var points: PackedVector3Array = (shape as ConvexPolygonShape3D).points
		if points.is_empty():
			return AABB()
		local = AABB(points[0], Vector3.ZERO)
		for p: Vector3 in points:
			local = local.expand(p)
	elif shape is ConcavePolygonShape3D:
		var faces: PackedVector3Array = (shape as ConcavePolygonShape3D).get_faces()
		if faces.is_empty():
			return AABB()
		local = AABB(faces[0], Vector3.ZERO)
		for p: Vector3 in faces:
			local = local.expand(p)
	else:
		return AABB()
	return shape_node.global_transform * local


## Distance XZ minimale entre le rectangle d'une boîte et une polyligne.
## Échantillonnage métrique le long de chaque segment : c'est la même
## granularité que le contrôle de route ci-dessus, et un lit de rivière ne
## change pas de côté en moins d'un mètre.
func _distance_box_polyline(box: AABB, line: PackedVector2Array) -> float:
	if line.size() < 2:
		return INF
	var best: float = INF
	for i: int in range(line.size() - 1):
		var a: Vector2 = line[i]
		var b: Vector2 = line[i + 1]
		var steps: int = maxi(1, int(a.distance_to(b)))
		for s: int in range(steps + 1):
			best = minf(best, _distance_box_point(box,
				a.lerp(b, float(s) / float(steps))))
	return best


## Distance XZ d'un point au rectangle d'une boîte (0 s'il est dedans).
func _distance_box_point(box: AABB, p: Vector2) -> float:
	var dx: float = maxf(maxf(box.position.x - p.x, p.x - box.end.x), 0.0)
	var dz: float = maxf(maxf(box.position.z - p.y, p.y - box.end.z), 0.0)
	return sqrt(dx * dx + dz * dz)


## Remonte au `place_id` du lieu propriétaire d'un nœud, &"" si aucun.
func _owning_place(node: Node) -> StringName:
	var current: Node = node
	while current != null:
		if current.has_meta(&"place_id"):
			return current.get_meta(&"place_id", &"") as StringName
		current = current.get_parent()
	return &""
