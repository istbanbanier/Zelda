## V2.1 — les SIX FENÊTRES de composition existent et VOIENT leur cible.
##
## À ce stade les caméras ne prouvent que des relations SPATIALES : posées
## au-dessus du sol réel, rien devant l'objectif, ligne de visée dégagée sur
## la première portion du trajet vers la cible. Jamais un jugement artistique
## (interdit du prompt V2.1 : aucune appréciation esthétique ici).
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const EXPECTED_NAMES: Array[String] = ["cam01_spawn_vista", "cam02_camp_pylone",
	"cam03_pylone_marche", "cam04_falaise_cuvette", "cam05_belvedere_crete",
	"cam06_plateau_vallee"]
## La visée doit être LIBRE sur cette fraction du trajet caméra → cible
## (au-delà, le relief a le droit d'occuper le fond du cadre).
const CLEAR_SIGHT_FRACTION: float = 0.6

var _world: Node3D = null


func test_les_six_fenetres_sont_posees_et_degagees() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame
	var heightmap: WorldV2Heightmap = _world.call("heightmap") as WorldV2Heightmap
	var space: PhysicsDirectSpaceState3D = _world.get_world_3d().direct_space_state

	var cameras: Dictionary = {}
	for node: Node in loop.get_nodes_in_group(&"world_v2_capture_cameras"):
		cameras[String(node.name)] = node
	check_equal(cameras.size(), EXPECTED_NAMES.size(),
		"six caméras de composition")
	var faults: Array[String] = []
	for wanted: String in EXPECTED_NAMES:
		if not cameras.has(wanted):
			faults.append("fenêtre absente : %s" % wanted)
			continue
		var camera: Camera3D = cameras[wanted] as Camera3D
		var position: Vector3 = camera.global_position
		var ground: float = heightmap.height_at(position.x, position.z)
		# Ni enterrée, ni en vol : l'œil tient dans une bande humaine.
		if position.y < ground + 1.0 or position.y > ground + 6.0:
			faults.append("%s à %.1f m du sol" % [wanted, position.y - ground])
		if String(camera.get_meta(&"proves", "")).is_empty():
			faults.append("%s ne dit pas ce qu'elle prouve" % wanted)
		var target: Vector3 = camera.get_meta(&"target", Vector3.ZERO) as Vector3
		if target == Vector3.ZERO:
			faults.append("%s sans cible" % wanted)
			continue
		# La visée est libre sur la première portion du trajet.
		var sight_end: Vector3 = position.lerp(target, CLEAR_SIGHT_FRACTION)
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			position, sight_end, 1)
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			var blocker: Node = hit["collider"] as Node
			var at: Vector3 = hit["position"] as Vector3
			faults.append("%s bouchée par %s à %.0f m (en %.0f, %.0f)"
				% [wanted, blocker.name, position.distance_to(at), at.x, at.z])
	check(faults.is_empty(), "chaque fenêtre voit sa cible — %s"
		% " ; ".join(faults))

	var clean: bool = await restore_root()
	check(clean, "démontage propre — %s" % restore_root_reason())
	restore_saves()
