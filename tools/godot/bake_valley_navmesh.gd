## Bake du navmesh de la Vallée de Néris (MASTER_SPEC §12.7, §20.10, D-022).
##
## Usage :
##   godot --headless --path . --script tools/godot/bake_valley_navmesh.gd
##
## §20.10 : « baker depuis collisions/formes simples, pas depuis les meshes
## visuels ». Le blockout D.1 étant fait de StaticBody3D aux formes primitives,
## la géométrie parsée est exactement la géométrie de collision. Le résultat est
## VERSIONNÉ (`valley_navmesh.tres`) : pas de bake au chargement, pas de coût
## runtime — relancer CET outil après toute modification du relief.
##
## Sort en code non nul si le bake produit un maillage vide : un navmesh vide
## silencieux ferait retomber tous les pillards en pilotage direct sans que
## personne ne le voie.
extends SceneTree

const WORLD: String = "res://scenes/world/valley/ValleyWorld.tscn"
const OUT: String = "res://scenes/world/valley/valley_navmesh.tres"

## Le pillard : capsule r 0,4 — rayon d'agent 0,5 pour une marge aux murs.
## Pente max 44° : couvre les rampes les plus raides du blockout (35°) en
## restant sous la pente de marche du joueur (46°, §8.2).
const CELL_SIZE: float = 0.5
const AGENT_RADIUS: float = 0.7
const AGENT_HEIGHT: float = 1.8
const AGENT_MAX_CLIMB: float = 0.4
const AGENT_MAX_SLOPE_DEG: float = 44.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[bake] chargement de %s" % WORLD)
	var world: Node3D = (load(WORLD) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	# Le relief est construit par les _ready ; deux frames par prudence.
	await process_frame
	await process_frame

	var nav_mesh: NavigationMesh = NavigationMesh.new()
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_collision_mask = 1
	nav_mesh.cell_size = CELL_SIZE
	nav_mesh.cell_height = 0.25
	nav_mesh.agent_radius = AGENT_RADIUS
	nav_mesh.agent_height = AGENT_HEIGHT
	nav_mesh.agent_max_climb = AGENT_MAX_CLIMB
	nav_mesh.agent_max_slope = deg_to_rad(AGENT_MAX_SLOPE_DEG)

	var source: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nav_mesh, source, world)
	if not source.has_data():
		push_error("[bake] aucune géometrie source parsée — rien à baker.")
		quit(1)
		return
	print("[bake] géométrie parsée, bake en cours…")
	NavigationServer3D.bake_from_source_geometry_data(nav_mesh, source)

	var polygons: int = nav_mesh.get_polygon_count()
	print("[bake] polygones : %d" % polygons)
	if polygons <= 0:
		push_error("[bake] navmesh VIDE — échec.")
		quit(1)
		return
	var err: Error = ResourceSaver.save(nav_mesh, OUT)
	if err != OK:
		push_error("[bake] échec d'écriture de %s (%d)" % [OUT, err])
		quit(1)
		return
	print("[bake] écrit : %s" % OUT)
	quit(0)
