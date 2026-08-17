## Bake de la navigation World V2 (V2.1) — quatre quadrants VERSIONNÉS.
##
## Usage :
##   godot --headless --path . --script tools/godot/bake_world_v2_navmesh.gd
##
## §20.10 : baker depuis les COLLISIONS, pas les maillages visuels — comme le
## bake V1. Vérifié dans la source 4.7.1 : `StaticBody3D` parse nativement la
## `HeightMapShape3D` côté CPU (`static_body_3d.cpp`, navmesh_parse_source_
## geometry), alors que la lecture des ArrayMesh visuels passe par le
## RenderingServer et rend un parse INUTILISABLE en headless (mesuré : 2
## polygones — le seul tablier du pont — sur tout le monde). Les gardes de
## frontière (couche 1, r=246) produisent de minuscules îles sur leurs crêtes :
## hors zone jouable, déconnectées, assumées.
## Le monde est découpé en QUATRE quadrants par `filter_baking_aabb` : des
## régions plus petites se rechargent et se re-cuisent indépendamment
## (contrat V2.1 §10, navigation par région).
##
## Les paramètres d'agent REPRENNENT ceux de la vallée V1
## (`bake_valley_navmesh.gd`) : rayon 0,7, hauteur 1,8, climb 0,4, pente 44°.
## Le bake V1 n'est PAS touché.
##
## Sort en code non nul si un quadrant produit un maillage vide.
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"
const OUT_PATTERN: String = "res://resources/world_v2/nav/world_v2_navmesh_q%d.tres"

## 0,25 — au pas de 0,5, le filtre de corniche de Recast (montée par cellule
## bornée par cell_height 0,25) invalidait TOUTE pente au-delà de ~26° : la
## descente de crête (28°) n'était pas pavée et les chemins s'arrêtaient à sa
## lèvre (mesuré). 0,25 pave jusqu'à ~45°, juste au-dessus des 44° d'agent,
## et s'aligne sur le pas de cellule par défaut de la carte (coutures nettes).
const CELL_SIZE: float = 0.25
const AGENT_RADIUS: float = 0.7
const AGENT_HEIGHT: float = 1.8
const AGENT_MAX_CLIMB: float = 0.4
const AGENT_MAX_SLOPE_DEG: float = 44.0
## Quadrants : (x, z) dans {[-256..0], [0..256]}² — l'ordre est STABLE
## (q0 = sud-ouest en coordonnées grille, croissant en x puis en z).
const QUADRANT_EXTENT: float = 256.0
const BAKE_Y_MIN: float = -40.0
const BAKE_Y_SPAN: float = 200.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[bake_v2] chargement de %s" % WORLD)
	var world: Node3D = (load(WORLD) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	await process_frame
	await process_frame

	var probe: NavigationMesh = _make_mesh()
	var source: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(probe, source, world)
	if not source.has_data():
		push_error("[bake_v2] aucune géométrie source (colliders couche 1) — rien à baker.")
		quit(1)
		return
	print("[bake_v2] géométrie parsée (colliders couche 1), 4 quadrants…")

	DirAccess.make_dir_recursive_absolute("res://resources/world_v2/nav")
	for quadrant: int in range(4):
		var min_x: float = -QUADRANT_EXTENT + QUADRANT_EXTENT * float(quadrant % 2)
		var min_z: float = -QUADRANT_EXTENT + QUADRANT_EXTENT * float(quadrant / 2)
		var mesh: NavigationMesh = _make_mesh()
		mesh.filter_baking_aabb = AABB(
			Vector3(min_x, BAKE_Y_MIN, min_z),
			Vector3(QUADRANT_EXTENT, BAKE_Y_SPAN, QUADRANT_EXTENT))
		NavigationServer3D.bake_from_source_geometry_data(mesh, source)
		var polygons: int = mesh.get_polygon_count()
		print("[bake_v2] quadrant %d (x %+d, z %+d) : %d polygone(s)"
			% [quadrant, int(min_x), int(min_z), polygons])
		if polygons <= 0:
			push_error("[bake_v2] quadrant %d VIDE — échec." % quadrant)
			quit(1)
			return
		var path: String = OUT_PATTERN % quadrant
		var err: Error = ResourceSaver.save(mesh, path)
		if err != OK:
			push_error("[bake_v2] échec d'écriture de %s (%d)" % [path, err])
			quit(1)
			return
		print("[bake_v2] écrit : %s" % path)
	quit(0)


func _make_mesh() -> NavigationMesh:
	var nav_mesh: NavigationMesh = NavigationMesh.new()
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_collision_mask = 1
	nav_mesh.cell_size = CELL_SIZE
	nav_mesh.cell_height = 0.25
	nav_mesh.agent_radius = AGENT_RADIUS
	nav_mesh.agent_height = AGENT_HEIGHT
	nav_mesh.agent_max_climb = AGENT_MAX_CLIMB
	# EN DEGRÉS — source 4.7.1 : `float agent_max_slope = 45.0f`. Un
	# `deg_to_rad(44)` donnait 0,77° : seuls les plateaux de pads pavaient
	# (archipel mesuré à la sonde), et `bake_valley_navmesh.gd` (V1) porte le
	# MÊME défaut latent — hors périmètre V2.1, consigné pour la suite.
	nav_mesh.agent_max_slope = AGENT_MAX_SLOPE_DEG
	return nav_mesh
