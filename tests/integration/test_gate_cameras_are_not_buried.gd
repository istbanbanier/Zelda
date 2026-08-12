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
##
## SECONDE FAMILLE DU MÊME INCIDENT (passe 3, 2026-08-12) : une caméra peut
## être dans l'air ET contre un mur. `GateCamera_NorthRoad` vivait à 2,6 m à
## l'EST de `RuinWall03` (mur de ruine de 2,6 m, sommet 0,9 m au-dessus de
## l'œil) : la moitié gauche de son cadre était un coin gris sans matière —
## l'obstruction relevée par la revue indépendante. La sonde d'emprise ne l'a
## pas désignée (l'AABB du mur est fine) ; c'est le picking par rayon qui a
## tranché. Le test tire donc des rayons à travers la moitié HAUTE du cadre :
## aucune collision statique à moins de `WALL_DISTANCE_M` — le bas du cadre
## a le droit de montrer le sol proche, le haut n'a pas le droit de montrer
## un mur collé à l'objectif.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
## En deçà : la masse remplit le cadre sans pouvoir se lire comme matière.
## RuinWall03 était touché entre 2,3 et 4,3 m selon la colonne ; les décors
## légitimes les plus proches d'une caméra de gate (tentes du camp, murs de
## l'avant-poste) restent au-delà de 10 m dans la moitié haute.
const WALL_DISTANCE_M: float = 4.5


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func test_no_gate_camera_has_a_static_wall_against_its_lens() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	await _tree().physics_frame
	var space: PhysicsDirectSpaceState3D = valley.player().get_world_3d() \
		.direct_space_state
	var walled: Array[String] = []
	for camera_name: String in ValleyWorld.GATE_CAMERA_NAMES:
		var camera: Camera3D = valley.find_child(camera_name, true, false) as Camera3D
		check_not_null(camera, "la caméra de gate « %s » existe" % camera_name)
		if camera == null:
			continue
		# Rayons calculés depuis fov/aspect, PAS depuis project_ray_* : en
		# headless la fenêtre n'a pas le rapport 16:9 des captures de gate,
		# et le test doit sonder le cadre que les preuves montrent.
		# `Camera3D.fov` est VERTICAL (KEEP_HEIGHT, VISUAL_ASSET_BIBLE §3.1).
		var tan_v: float = tan(deg_to_rad(camera.fov) * 0.5)
		var tan_h: float = tan_v * (16.0 / 9.0)
		var eye: Vector3 = camera.global_position
		for v: float in [0.10, 0.55]:   # moitié HAUTE du cadre seulement
			for u: float in [-0.9, -0.55, -0.2, 0.2, 0.55, 0.9]:
				var direction: Vector3 = (camera.global_transform.basis
					* Vector3(u * tan_h, v * tan_v, -1.0)).normalized()
				var ray: PhysicsRayQueryParameters3D = \
					PhysicsRayQueryParameters3D.create(eye,
						eye + direction * WALL_DISTANCE_M, 1)
				var hit: Dictionary = space.intersect_ray(ray)
				if not hit.is_empty():
					walled.append("%s (u %.2f, v %.2f) -> %s à %.1f m"
						% [camera_name, u, v, (hit["collider"] as Node).name,
							eye.distance_to(hit["position"] as Vector3)])
	check(walled.is_empty(),
		"aucune caméra de gate n'a de mur à moins de %.1f m dans sa moitié haute"
			% WALL_DISTANCE_M + (" (fautives : %s)" % "; ".join(walled)
			if not walled.is_empty() else ""))
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
