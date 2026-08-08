## LA CAMÉRA RESTE DEHORS, ET AU-DESSUS DU SOL.
##
## Deux défauts mesurés au playtest du 2026-08-07 :
##   « "S" (reculer) colle la caméra dans le modèle du héros, plusieurs fois
##     -> écran illisible »
##   « la caméra passe sous le terrain près de la rivière »
##
## CAUSE DU PREMIER, lue dans le moteur installé — `SpringArm3D` ne connaît
## aucune distance minimale : `spring_arm_3d.cpp:196` pose son enfant à
## `origine + direction * (spring_length * motion_delta)`, et `motion_delta`
## vaut ZÉRO dès qu'un obstacle touche le pivot. La caméra atterrit alors
## exactement sur le pivot, c'est-à-dire à `camera_target_height` = 1,45 m,
## dans le torse du héros.
##
## CAUSE DU SECOND : le bras ne sonde QUE le segment pivot→caméra. Au bord
## d'une tranchée — le lit de la rivière en est une, 3,5 m de creux — ce
## segment survole le vide sans rien toucher et la caméra finit sous la berge.
##
## Les deux garde-fous vivent dans `camera_rig.gd` et sont mesurés ici sur la
## VRAIE vallée, pas sur une scène de laboratoire.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"

var _valley: Node3D = null
var _player: PlayerController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame
	# La correction vit dans `_process` (après le bras) : il faut donc aussi
	# laisser passer des frames de TRAITEMENT, pas seulement des ticks physiques.
	for i: int in range(3):
		await _tree().process_frame


func _load() -> void:
	# Un monde jouable AUTOSAUVEGARDE : on garde l'état d'avant pour le
	# rendre intact au cas suivant (voir `remember_saves`).
	remember_saves()
	_valley = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_valley)
	await _settle(5)
	_player = _valley.call("player") as PlayerController


func _unload() -> void:
	_tree().paused = false
	_valley.get_parent().remove_child(_valley)
	_valley.queue_free()
	_valley = null
	_player = null
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)
	restore_saves()


func _rig() -> CameraRig:
	return _player.get_node("CameraRig") as CameraRig


func _camera() -> Camera3D:
	return _rig().get_camera()


## Réduit la longueur VOULUE du bras à zéro, sur une copie du réglage.
func _collapse_the_arm(rig: CameraRig) -> void:
	var own: LocomotionTuning = rig.tuning.duplicate() as LocomotionTuning
	own.camera_distance = 0.0
	rig.tuning = own


func _restore_the_arm(rig: CameraRig) -> void:
	var own: LocomotionTuning = rig.tuning.duplicate() as LocomotionTuning
	own.camera_distance = 4.3
	rig.tuning = own


## Le héros dos au mur : c'est le geste exact du joueur qui reculait.
func test_backing_into_a_wall_never_puts_the_camera_inside_the_hero() -> void:
	await _load()
	var rig: CameraRig = _rig()
	var minimum: float = _player.tuning.camera_min_distance
	# On force le bras à la butée — ce que produit un mur collé au dos.
	#
	# Écrire `spring_length = 0` ne suffit PAS : `update_fov()` le réécrit à
	# `camera_distance` à CHAQUE tick physique, donc la consigne disparaissait
	# avant d'être lue. On agit donc sur la source, `camera_distance`, et sur
	# une COPIE du réglage : la ressource est partagée, la modifier en place
	# contaminerait tous les cas suivants (§5.4).
	_collapse_the_arm(rig)
	await _settle(6)
	var distance: float = _player.global_position.distance_to(
		_camera().global_position)
	check(distance >= minimum - 0.05,
		"caméra à %.2f m du héros, jamais moins de %.2f m"
			% [distance, minimum])
	# Et la preuve que ça se VOIT : sous le seuil, le héros s'efface.
	var visual: Node3D = _player.get_node("VisualRoot") as Node3D
	var opaque: bool = false
	for node: Node in visual.find_children("*", "GeometryInstance3D", true, false):
		var geometry: GeometryInstance3D = node as GeometryInstance3D
		if geometry.transparency < 0.5:
			opaque = true
	check(not opaque or not visual.visible,
		"à bout touchant le héros s'efface au lieu de boucher l'écran")
	await _unload()


## …et il redevient opaque dès que la caméra recule. Un effacement qui reste
## serait un second bug, pas une correction.
func test_the_hero_becomes_solid_again_when_the_camera_backs_off() -> void:
	await _load()
	var rig: CameraRig = _rig()
	_collapse_the_arm(rig)
	await _settle(6)
	_restore_the_arm(rig)
	# `camera_fov_speed` lisse la longueur : il faut laisser le bras se
	# rouvrir réellement, pas seulement demander qu'il se rouvre.
	await _settle(30)
	var visual: Node3D = _player.get_node("VisualRoot") as Node3D
	check(visual.visible, "le héros est de nouveau affiché")
	var faded: bool = false
	for node: Node in visual.find_children("*", "GeometryInstance3D", true, false):
		if (node as GeometryInstance3D).transparency > 0.05:
			faded = true
	check(not faded, "…et pleinement opaque")
	await _unload()


## Le lit de la rivière : la tranchée où le défaut a été vu.
func test_the_camera_stays_above_the_ground_along_the_river() -> void:
	await _load()
	# Gué ouest (valley_terrain.gd : « FordWest » en (20, ?, 10)), dans le lit.
	_player.global_position = Vector3(20.0, 4.0, 10.0)
	_player.velocity = Vector3.ZERO
	await _settle(30)
	var space: PhysicsDirectSpaceState3D = \
		_player.get_world_3d().direct_space_state
	var below: int = 0
	var sampled: int = 0
	# On tourne autour du héros : le défaut ne se produit que sous certains
	# angles, et un seul azimut ne prouverait rien.
	for step: int in range(12):
		# Par le VRAI chemin de regard : `_yaw` est cumulatif, un douzième de
		# tour par pas fait le tour complet.
		_rig().apply_look(Vector2.ZERO, Vector2(-TAU / 12.0, 0.0), 1.0 / 60.0)
		await _settle(3)
		var eye: Vector3 = _camera().global_position
		var query: PhysicsRayQueryParameters3D = \
			PhysicsRayQueryParameters3D.create(
				eye + Vector3.UP * 40.0, eye, 1)
		var hit: Dictionary = space.intersect_ray(query)
		sampled += 1
		# Un contact entre 40 m au-dessus et l'œil signifie que du décor plein
		# est passé par-dessus la caméra : elle est donc sous le terrain.
		if not hit.is_empty():
			below += 1
	check_equal(below, 0,
		"la caméra n'est sous le sol sur aucun azimut (%d/%d)"
			% [below, sampled])
	await _unload()
