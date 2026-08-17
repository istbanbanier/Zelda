## V2.1 — les LIMITES ferment le monde : garde `unclimbable` sur chaque azimut.
##
## D-019 rend toute pente raide ESCALADABLE : l'anneau de relief seul ne
## retient personne. La fermeture réelle, c'est la ceinture de gardes
## `unclimbable`. Sondage du CIEL sur 72 azimuts (le double des 32 exigés,
## dont les joints entre segments) : le premier corps rencontré à l'aplomb du
## rayon des gardes doit être un garde — un trou dans la ceinture rougit ICI
## en nommant l'azimut (contrôle négatif C).
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const PROBE_AZIMUTHS: int = 72
const GUARD_PROBE_RADIUS: float = 246.0
## Un garde enterré ne barre rien : sa crête doit dominer le sol local.
const MIN_CREST_ABOVE_GROUND_M: float = 2.0

var _world: Node3D = null


func test_le_monde_est_ferme_sur_tous_les_azimuts() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame
	var heightmap: WorldV2Heightmap = _world.call("heightmap") as WorldV2Heightmap
	var space: PhysicsDirectSpaceState3D = _world.get_world_3d().direct_space_state

	var faults: Array[String] = []
	for i: int in range(PROBE_AZIMUTHS):
		var azimuth: float = TAU * float(i) / float(PROBE_AZIMUTHS)
		var x: float = cos(azimuth) * GUARD_PROBE_RADIUS
		var z: float = sin(azimuth) * GUARD_PROBE_RADIUS
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			Vector3(x, 400.0, z), Vector3(x, -60.0, z), 1)
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			faults.append("azimut %.0f° : AUCUN corps" % rad_to_deg(azimuth))
			continue
		var collider: Node = hit["collider"] as Node
		if not collider.is_in_group(&"unclimbable"):
			faults.append("azimut %.0f° : brèche — premier corps %s"
				% [rad_to_deg(azimuth), collider.name])
			continue
		var crest_y: float = (hit["position"] as Vector3).y
		var ground: float = heightmap.height_at(x, z)
		if crest_y < ground + MIN_CREST_ABOVE_GROUND_M:
			faults.append("azimut %.0f° : garde enterré (crête %.1f, sol %.1f)"
				% [rad_to_deg(azimuth), crest_y, ground])
	check(faults.is_empty(),
		"la ceinture est fermée sur %d azimuts — %s"
			% [PROBE_AZIMUTHS, " ; ".join(faults)])

	var clean: bool = await restore_root()
	check(clean, "démontage propre — %s" % restore_root_reason())
	restore_saves()


func test_les_gardes_sont_visibles_et_hors_de_la_zone_jouable() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame

	var guards: Array[Node] = loop.get_nodes_in_group(&"world_v2_border_guards")
	check_equal(guards.size(), 36, "trente-six segments de garde")
	var faults: Array[String] = []
	for guard: Node in guards:
		var body: StaticBody3D = guard as StaticBody3D
		if not body.is_in_group(&"unclimbable"):
			faults.append("%s n'est pas unclimbable" % body.name)
		# Jamais une paroi invisible : le mesh du garde est là et visible.
		var visual: MeshInstance3D = body.get_node_or_null("GuardMesh") as MeshInstance3D
		if visual == null or not visual.visible or visual.mesh == null:
			faults.append("%s serait un mur INVISIBLE" % body.name)
		# La ceinture ne mord pas la zone jouable (rayon 235).
		var radius: float = Vector2(body.position.x, body.position.z).length()
		if radius < WorldV2Heightmap.PLAYABLE_RADIUS_M + 5.0:
			faults.append("%s mord la zone jouable (r=%.0f)" % [body.name, radius])
	check(faults.is_empty(), "des gardes visibles, hors zone jouable — %s"
		% " ; ".join(faults))

	var clean: bool = await restore_root()
	check(clean, "démontage propre — %s" % restore_root_reason())
	restore_saves()
