## AUCUNE CAMÉRA DE GATE N'EST DANS LE SOL, UN MUR OU UN PROXY.
##
## L'INCIDENT QUE CE TEST EMPÊCHE DE REVENIR, mesuré le 2026-08-11.
##
## `DescentCamera_01` était posée à (14 ; 27 ; 152). Or `SpawnRidge` couvre
## x −50..50, z 144..208, sommet à **y = 32** : la caméra vivait CINQ MÈTRES
## SOUS le sol de la crête, à l'intérieur du volume. Sa capture de gate était
## un aplat vert d'un bord à l'autre — et l'était déjà au commit audité.
## Personne ne l'avait regardée : l'image existait, donc elle passait pour
## une preuve (le piège exact que PROMPT4 §12 nomme — l'existence d'un
## fichier ne prouve pas qu'il a été regardé).
##
## Le contrat du prompt de reprise est explicite : « une caméra posée dans un
## mur, sous le terrain ou derrière un proxy doit être corrigée et
## recapturée ». Ce test rend la moitié machine-vérifiable : l'œil de chaque
## caméra de gate doit être DANS L'AIR — un rayon tiré vers le bas depuis la
## caméra doit toucher un sol SOUS elle, à une distance non nulle.
##
## CE QU'IL NE VÉRIFIE PAS : qu'une caméra cadre bien, ni qu'elle n'est pas
## masquée par un décor SANS collision. Le verdict d'image reste à l'œil.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func test_every_gate_camera_eye_sits_in_open_air() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	await _tree().physics_frame
	var space: PhysicsDirectSpaceState3D = valley.player().get_world_3d() \
		.direct_space_state
	for camera_name: String in ValleyWorld.GATE_CAMERA_NAMES:
		var camera: Camera3D = valley.find_child(camera_name, true, false) as Camera3D
		check_not_null(camera, "la caméra de gate « %s » existe" % camera_name)
		if camera == null:
			continue
		var eye: Vector3 = camera.global_position
		# 1. Un rayon DESCENDANT depuis l'œil touche un sol SOUS l'œil : si la
		#    caméra est à l'intérieur d'un volume plein, le rayon part de
		#    l'intérieur et ne rencontre la face qu'en la traversant — la
		#    distance au point d'impact révèle le cas (< 0,3 m = enterrée, ou
		#    aucun impact = sous le monde).
		var down: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			eye, eye + Vector3.DOWN * 200.0, 1)
		var floor_hit: Dictionary = space.intersect_ray(down)
		check(not floor_hit.is_empty(),
			"« %s » a un sol sous elle" % camera_name)
		if not floor_hit.is_empty():
			var drop: float = eye.y - (floor_hit["position"] as Vector3).y
			check(drop > 0.3,
				"« %s » est %.1f m AU-DESSUS du sol, pas dedans (l'incident : −5 m)"
					% [camera_name, drop])
		# 2. L'œil lui-même n'est dans aucun volume de collision : une sonde
		#    ponctuelle par petite sphère au point exact de l'œil.
		var probe: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		var ball: SphereShape3D = SphereShape3D.new()
		ball.radius = 0.05
		probe.shape = ball
		probe.transform = Transform3D(Basis.IDENTITY, eye)
		probe.collision_mask = 1
		var overlaps: Array[Dictionary] = space.intersect_shape(probe, 4)
		check(overlaps.is_empty(),
			"l'œil de « %s » est dans l'air, pas dans %d volume(s)"
				% [camera_name, overlaps.size()])
	_tree().root.remove_child(valley)
	valley.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	var audio: Node = _tree().root.get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("stop_ambience"):
		audio.call("stop_ambience")
	await _tree().physics_frame
