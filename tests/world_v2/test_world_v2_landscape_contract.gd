## V2.2 — CONTRAT DU PAYSAGE : ce que la fondation artistique doit respecter.
##
## Écrit AVANT l'habillage (fail-first) : à sa création, les tests de matériau
## et de végétation ROUGISSENT sur la vallée whitebox V2.1 — le journal rouge
## est archivé dans `evidence/world_v2/v2_2/`. Deux tests sont au contraire des
## FILS DE DÉTENTE écrits verts contre l'état gelé V2.1 (caméras §16 de la
## directive, diagnostics cachés §11) : leur capacité à rougir est prouvée par
## les contrôles négatifs de la phase (D : transform de caméra modifiée).
##
## Littéraux copiés du manifeste V2.1 (`evidence/world_v2/v2_1/`, commit
## 38c87b1), JAMAIS des scripts surveillés (PROMPT4 §4 : un test qui lit la
## constante qu'il surveille suit l'erreur au lieu de la dénoncer).
##
## CONTRAT DE GROUPES que l'habillage doit remplir :
## - `world_v2_vegetation` : chaque cellule végétale est un MultiMeshInstance3D
##   d'emprise X/Z ≤ 48 m (directive §12 : cellules 24-48 m, jamais un
##   MultiMesh sur toute la vallée) ;
## - `world_v2_vegetation_colliders` : les corps de collision SIMPLES des
##   troncs et rochers (les seules collisions nouvelles permises §7).
## L'herbe de premier plan est VOULUE près des caméras (North Star §1.1) :
## l'exclusion de 4 m autour des objectifs ne s'applique qu'aux COLLIDERS
## (troncs/rochers — ce qui bloque un cadre), pas aux brins.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"

## Six fenêtres GELÉES (directive V2.2 §16) — nom, x, z, cible.
const FROZEN_WINDOWS: Array[Array] = [
	["cam01_spawn_vista", 0.8, 153.4, Vector3(0, 26, -210)],
	["cam02_camp_pylone", 36.0, 76.0, Vector3(115, 20, -25)],
	["cam03_pylone_marche", 112.0, -14.0, Vector3(0, 22, -160)],
	["cam04_falaise_cuvette", -118.0, 64.0, Vector3(10, 6, 92)],
	["cam05_belvedere_crete", 166.0, 54.0, Vector3(0, 26, 170)],
	["cam06_plateau_vallee", 0.0, -168.0, Vector3(0, 6, 60)],
]
const FROZEN_FOV: float = 60.0
const FROZEN_EYE_HEIGHT_M: float = 2.4

## Le matériau de paysage vit dans le périmètre d'écriture de la phase.
const LANDSCAPE_SHADER_DIR: String = "res://shaders/world_v2/"

const VEGETATION_GROUP: StringName = &"world_v2_vegetation"
const VEGETATION_COLLIDER_GROUP: StringName = &"world_v2_vegetation_colliders"
const CELL_MAX_EXTENT_M: float = 48.0
## Planchers d'ARCHITECTURE (le paysage existe à une échelle significative),
## jamais des cibles de qualité — la qualité se juge en capture.
const MIN_CELLS: int = 24
const MIN_INSTANCES: int = 2000
## Régions dont l'identité du masterplan §4 est végétale — la végétation doit
## y être PRÉSENTE (la steppe et la marche de l'orage, raréfiées, sont un
## choix d'identité, pas une obligation).
const REQUIRED_VEGETATED_REGIONS: Array[StringName] = [
	&"r01_crete_de_l_aube", &"r02_prairie_mille_fleurs",
	&"r03_val_de_neris", &"r06_bois_du_levant",
]

## Couloirs à garder dégagés (directive §12).
const ROUTE_CLEAR_M: float = 2.0
const FORD_CLEAR_M: float = 5.0
const CHECKPOINT_CLEAR_M: float = 4.0
const CAMERA_CLEAR_M: float = 4.0
## Fenêtre d'ancrage au sol : un pied d'arbre s'enfonce, il ne flotte pas.
const ANCHOR_MIN_SINK_M: float = -1.5
const ANCHOR_MAX_FLOAT_M: float = 0.6
## L'échantillon par cellule INCLUT TOUJOURS l'instance 0 (le contrôle négatif
## B soulève une instance — elle doit être vue par le test).
const MAX_SAMPLES_PER_CELL: int = 60

var _world: Node3D = null


func _mount_world() -> Node3D:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	var world: Node3D = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(world)
	await loop.process_frame
	await loop.physics_frame
	return world


func _teardown(clean_message: String) -> void:
	var clean: bool = await restore_root()
	check(clean, "%s — %s" % [clean_message, restore_root_reason()])
	restore_saves()


## -- 1. Caméras gelées (fil de détente, contrôle négatif D) -------------------

func test_les_six_cameras_v2_1_sont_gelees_par_litteraux() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = await _mount_world()
	var heightmap: WorldV2Heightmap = _world.call("heightmap") as WorldV2Heightmap

	var cameras: Dictionary = {}
	for node: Node in loop.get_nodes_in_group(&"world_v2_capture_cameras"):
		cameras[String(node.name)] = node
	check_equal(cameras.size(), FROZEN_WINDOWS.size(),
		"exactement six fenêtres gelées")
	var faults: Array[String] = []
	for window: Array in FROZEN_WINDOWS:
		var wanted: String = String(window[0])
		if not cameras.has(wanted):
			faults.append("fenêtre absente : %s" % wanted)
			continue
		var camera: Camera3D = cameras[wanted] as Camera3D
		var x: float = float(window[1])
		var z: float = float(window[2])
		var target: Vector3 = window[3] as Vector3
		var p: Vector3 = camera.global_position
		if absf(p.x - x) > 0.01 or absf(p.z - z) > 0.01:
			faults.append("%s déplacée : (%.2f, %.2f) au lieu de (%.2f, %.2f)"
				% [wanted, p.x, p.z, x, z])
		var eye: float = heightmap.height_at(x, z) + FROZEN_EYE_HEIGHT_M
		if absf(p.y - eye) > 0.05:
			faults.append("%s : œil à %.2f au lieu de %.2f" % [wanted, p.y, eye])
		if absf(camera.fov - FROZEN_FOV) > 0.01:
			faults.append("%s : FOV %.1f au lieu de %.1f"
				% [wanted, camera.fov, FROZEN_FOV])
		var declared: Vector3 = camera.get_meta(&"target", Vector3.ZERO) as Vector3
		if not declared.is_equal_approx(target):
			faults.append("%s : cible %s au lieu de %s" % [wanted, declared, target])
		# L'ORIENTATION fait partie du gel : l'axe -Z regarde la cible.
		var forward: Vector3 = -camera.global_transform.basis.z
		var to_target: Vector3 = (target - p).normalized()
		if forward.dot(to_target) < 0.999:
			faults.append("%s : orientation déviée de la cible (%.4f)"
				% [wanted, forward.dot(to_target)])
	check(faults.is_empty(), "les six transforms V2.1 sont intactes — %s"
		% " ; ".join(faults))
	await _teardown("démontage propre (caméras)")


## -- 2. Matériau de paysage par chunk (ROUGE sur le whitebox, contrôle A) -----

func test_chaque_chunk_porte_le_materiau_de_paysage() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = await _mount_world()

	var chunks: Array[Node] = loop.get_nodes_in_group(&"world_v2_terrain")
	check_equal(chunks.size(), 64, "64 chunks présents")
	var faults: Array[String] = []
	for chunk: Node in chunks:
		var mesh_instance: MeshInstance3D = \
			chunk.get_node_or_null("GroundMesh") as MeshInstance3D
		if mesh_instance == null:
			faults.append("%s sans GroundMesh" % chunk.name)
			continue
		var material: Material = _effective_material(mesh_instance)
		var shader_material: ShaderMaterial = material as ShaderMaterial
		if shader_material == null or shader_material.shader == null:
			faults.append("%s : matériau de diagnostic, pas de paysage" % chunk.name)
		elif not shader_material.shader.resource_path.begins_with(LANDSCAPE_SHADER_DIR):
			faults.append("%s : shader hors périmètre (%s)"
				% [chunk.name, shader_material.shader.resource_path])
	check(faults.is_empty(),
		"chaque chunk porte le matériau de paysage (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(_capped(faults))])
	await _teardown("démontage propre (matériaux)")


## Le matériau EFFECTIF, quelle que soit la voie d'application — la leçon du
## piège `tests/CLAUDE.md` : un cast aveugle accuse l'art d'un défaut inexistant.
func _effective_material(mesh_instance: MeshInstance3D) -> Material:
	if mesh_instance.material_override != null:
		return mesh_instance.material_override
	var override: Material = mesh_instance.get_surface_override_material(0)
	if override != null:
		return override
	if mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() > 0:
		return mesh_instance.mesh.surface_get_material(0)
	return null


## -- 3. Végétation cellulaire et bornée (ROUGE tant qu'elle n'existe pas) -----

func test_la_vegetation_est_cellulaire_et_presente_ou_le_masterplan_l_exige() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = await _mount_world()
	var builder: WorldV2TerrainBuilder = \
		_world.call("terrain_builder") as WorldV2TerrainBuilder

	var cells: Array[Node] = loop.get_nodes_in_group(VEGETATION_GROUP)
	var faults: Array[String] = []
	var total_instances: int = 0
	var regions_seen: Dictionary = {}
	for cell: Node in cells:
		var mm_instance: MultiMeshInstance3D = cell as MultiMeshInstance3D
		if mm_instance == null or mm_instance.multimesh == null:
			faults.append("%s : membre du groupe sans MultiMesh" % cell.name)
			continue
		var count: int = mm_instance.multimesh.instance_count
		if count < 1:
			faults.append("%s : cellule vide" % cell.name)
			continue
		total_instances += count
		# L'emprise mesurée dans le MONDE — le contrôle négatif C élargit une
		# cellule au-delà de 48 m et doit rougir ICI.
		var aabb: AABB = mm_instance.global_transform * mm_instance.get_aabb()
		if aabb.size.x > CELL_MAX_EXTENT_M or aabb.size.z > CELL_MAX_EXTENT_M:
			faults.append("%s : emprise %.0f × %.0f m (plafond %.0f)"
				% [cell.name, aabb.size.x, aabb.size.z, CELL_MAX_EXTENT_M])
		var center: Vector3 = aabb.get_center()
		regions_seen[builder.region_id_at(center.x, center.z)] = true
	check(cells.size() >= MIN_CELLS,
		"au moins %d cellules végétales (obtenu %d)" % [MIN_CELLS, cells.size()])
	check(total_instances >= MIN_INSTANCES,
		"au moins %d instances végétales (obtenu %d)"
		% [MIN_INSTANCES, total_instances])
	for region: StringName in REQUIRED_VEGETATED_REGIONS:
		check(regions_seen.has(region),
			"la végétation est présente dans %s (identité masterplan §4)" % region)
	check(faults.is_empty(), "cellules bornées et pleines (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(_capped(faults))])
	await _teardown("démontage propre (cellules)")


## -- 4. Ancrage au sol et couloirs dégagés (ROUGE sans végétation, contrôle B)

func test_la_vegetation_est_ancree_au_sol_et_hors_des_couloirs() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = await _mount_world()
	var heightmap: WorldV2Heightmap = _world.call("heightmap") as WorldV2Heightmap
	var layout: Dictionary = _world.call("layout") as Dictionary
	var route_segments: Array[Array] = _route_segments(layout)
	var fords: Array[Vector2] = _ford_centers(layout)
	var checkpoints: Array[Vector2] = _checkpoint_centers(layout)

	var faults: Array[String] = []
	var checked: int = 0
	for cell: Node in loop.get_nodes_in_group(VEGETATION_GROUP):
		var mm_instance: MultiMeshInstance3D = cell as MultiMeshInstance3D
		if mm_instance == null or mm_instance.multimesh == null:
			continue
		var count: int = mm_instance.multimesh.instance_count
		var stride: int = maxi(1, int(ceilf(float(count) / float(MAX_SAMPLES_PER_CELL))))
		var index: int = 0
		while index < count:
			var origin: Vector3 = mm_instance.global_transform \
				* mm_instance.multimesh.get_instance_transform(index).origin
			checked += 1
			_check_anchor_and_corridors(origin, String(cell.name), index,
				heightmap, route_segments, fords, checkpoints, faults)
			index += stride

	# Les colliders de troncs/rochers : TOUS vérifiés, plus l'exclusion caméra.
	var colliders: Array[Node] = loop.get_nodes_in_group(VEGETATION_COLLIDER_GROUP)
	for body: Node in colliders:
		var node: Node3D = body as Node3D
		if node == null:
			continue
		var origin: Vector3 = node.global_position
		checked += 1
		_check_anchor_and_corridors(origin, String(node.name), -1,
			heightmap, route_segments, fords, checkpoints, faults)
		for window: Array in FROZEN_WINDOWS:
			var eye: Vector2 = Vector2(float(window[1]), float(window[2]))
			if Vector2(origin.x, origin.z).distance_to(eye) < CAMERA_CLEAR_M:
				faults.append("%s à %.1f m de l'objectif %s"
					% [node.name, Vector2(origin.x, origin.z).distance_to(eye),
						String(window[0])])

	# Sans ce plancher, le test passerait VERT sur un monde sans végétation
	# (le piège de l'assertion sautée, tests/CLAUDE.md).
	check(checked >= MIN_CELLS,
		"assez d'instances échantillonnées pour juger (%d)" % checked)
	check(faults.is_empty(),
		"ancrage et couloirs tenus (%d écart(s) sur %d vérifiées) — %s"
		% [faults.size(), checked, " ; ".join(_capped(faults))])
	await _teardown("démontage propre (ancrage)")


func _check_anchor_and_corridors(origin: Vector3, cell_name: String, index: int,
		heightmap: WorldV2Heightmap, route_segments: Array[Array],
		fords: Array[Vector2], checkpoints: Array[Vector2],
		faults: Array[String]) -> void:
	var label: String = cell_name if index < 0 else "%s[%d]" % [cell_name, index]
	var offset: float = origin.y - heightmap.height_at(origin.x, origin.z)
	if offset < ANCHOR_MIN_SINK_M or offset > ANCHOR_MAX_FLOAT_M:
		faults.append("%s : %.2f m du sol (fenêtre %.1f à %.1f)"
			% [label, offset, ANCHOR_MIN_SINK_M, ANCHOR_MAX_FLOAT_M])
		return
	var p: Vector2 = Vector2(origin.x, origin.z)
	for segment: Array in route_segments:
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(
			p, segment[0] as Vector2, segment[1] as Vector2)
		if p.distance_to(closest) < ROUTE_CLEAR_M:
			faults.append("%s dans le couloir de route (%.1f m)"
				% [label, p.distance_to(closest)])
			return
	for ford: Vector2 in fords:
		if p.distance_to(ford) < FORD_CLEAR_M:
			faults.append("%s dans le gué (%.1f m)" % [label, p.distance_to(ford)])
			return
	for checkpoint: Vector2 in checkpoints:
		if p.distance_to(checkpoint) < CHECKPOINT_CLEAR_M:
			faults.append("%s sur le checkpoint (%.1f m)"
				% [label, p.distance_to(checkpoint)])
			return


func _route_segments(layout: Dictionary) -> Array[Array]:
	var segments: Array[Array] = []
	var routes: Dictionary = layout.get("routes", {}) as Dictionary
	for route_name: String in ["main_path", "river_route", "heights_route", "ruins_route"]:
		var waypoints: Array = (routes.get(route_name, {}) as Dictionary) \
			.get("waypoints_xz", []) as Array
		for i: int in range(waypoints.size() - 1):
			var a: Array = waypoints[i] as Array
			var b: Array = waypoints[i + 1] as Array
			segments.append([Vector2(float(a[0]), float(a[1])),
				Vector2(float(b[0]), float(b[1]))])
	return segments


func _ford_centers(layout: Dictionary) -> Array[Vector2]:
	var centers: Array[Vector2] = []
	for entry: Variant in (layout.get("river", {}) as Dictionary) \
			.get("fords", []) as Array:
		var pos: Array = (entry as Dictionary).get("pos_xz", []) as Array
		if pos.size() == 2:
			centers.append(Vector2(float(pos[0]), float(pos[1])))
	return centers


func _checkpoint_centers(layout: Dictionary) -> Array[Vector2]:
	var centers: Array[Vector2] = []
	for entry: Variant in layout.get("checkpoints", []) as Array:
		var pos: Variant = (entry as Dictionary).get("pos")
		if pos is Array and (pos as Array).size() == 3:
			centers.append(Vector2(float((pos as Array)[0]), float((pos as Array)[2])))
	return centers


## -- 5. Déterminisme : deux montages, le même paysage -------------------------

func test_le_paysage_se_reconstruit_a_l_identique() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	var world_a: Node3D = await _mount_world()
	var first: String = _vegetation_signature(loop)
	loop.root.remove_child(world_a)
	world_a.free()
	await loop.process_frame
	var world_b: Node3D = await _mount_world()
	var second: String = _vegetation_signature(loop)

	# Sans végétation, deux signatures vides seraient « égales » : le plancher
	# rend le vide ROUGE au lieu de vert par vacuité.
	check(not first.is_empty(),
		"le paysage a une signature à comparer (végétation présente)")
	check_equal(second, first,
		"deux montages successifs produisent la même végétation")
	await _teardown("démontage propre (déterminisme)")


## Signature déterministe : cellules triées par nom, jusqu'à 8 transforms
## échantillonnées chacune, arrondies au millimètre.
func _vegetation_signature(loop: SceneTree) -> String:
	var cells: Array[Node] = loop.get_nodes_in_group(VEGETATION_GROUP)
	if cells.is_empty():
		return ""
	var names: Array[String] = []
	var by_name: Dictionary = {}
	for cell: Node in cells:
		names.append(String(cell.name))
		by_name[String(cell.name)] = cell
	names.sort()
	var parts: Array[String] = []
	for cell_name: String in names:
		var mm_instance: MultiMeshInstance3D = by_name[cell_name] as MultiMeshInstance3D
		if mm_instance == null or mm_instance.multimesh == null:
			parts.append("%s:invalide" % cell_name)
			continue
		var count: int = mm_instance.multimesh.instance_count
		var stride: int = maxi(1, count / 8)
		var index: int = 0
		var samples: Array[String] = []
		while index < count and samples.size() < 8:
			var t: Transform3D = mm_instance.multimesh.get_instance_transform(index)
			samples.append("%.3f,%.3f,%.3f,%.3f" % [t.origin.x, t.origin.y,
				t.origin.z, t.basis.get_scale().x])
			index += stride
		parts.append("%s:%d:%s" % [cell_name, count, "|".join(samples)])
	return ";".join(parts)


## -- 6. Diagnostics cachés par défaut (fil de détente) ------------------------

func test_les_diagnostics_sont_caches_par_defaut() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = await _mount_world()

	var markers: Array[Node] = loop.get_nodes_in_group(&"world_v2_markers")
	check(markers.size() > 30, "les marqueurs whitebox existent toujours (%d)"
		% markers.size())
	var faults: Array[String] = []
	for marker: Node in markers:
		var pillar: MeshInstance3D = \
			marker.get_node_or_null("DiagnosticPillar") as MeshInstance3D
		if pillar != null and pillar.visible:
			faults.append("pilier visible : %s" % marker.name)
	check(faults.is_empty(), "aucun pilier de diagnostic visible par défaut — %s"
		% " ; ".join(_capped(faults)))
	await _teardown("démontage propre (diagnostics)")


func _capped(faults: Array[String]) -> Array[String]:
	if faults.size() <= 6:
		return faults
	var head: Array[String] = faults.slice(0, 6)
	head.append("… et %d autres" % (faults.size() - 6))
	return head
