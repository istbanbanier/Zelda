## Lot 3 — contrat du dolly de stabilité (§30.1). Fail-first : écrit
## avant l'implémentation. La VIDÉO se juge à l'œil ; ce test garantit
## que l'outil qui la produit respecte le protocole : timeline 10-20 s,
## marche PUIS sprint (vitesses §8.2 : 3,5 et 9 m/s), rotation caméra,
## et un déplacement réel de la caméra du lab.
extends GateTestCase

const DOLLY_SCENE: String = "res://scenes/lookdev/StabilityDolly.tscn"
const DOLLY_SCRIPT: String = "res://scripts/lookdev/stability_dolly.gd"

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().process_frame


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	await _settle(3)


func test_the_dolly_respects_the_protocol_timeline() -> void:
	check(ResourceLoader.exists(DOLLY_SCENE),
		"la scène du dolly existe — l'outil vidéo §30.1 jamais produit")
	var script: GDScript = load(DOLLY_SCRIPT) as GDScript
	check(script != null, "…et son script se charge")
	if script == null:
		await _settle(1)
		return
	var total: float = float(script.get_script_constant_map()["TOTAL"])
	var walk_end: float = float(script.get_script_constant_map()["WALK_END"])
	var sprint_end: float = \
		float(script.get_script_constant_map()["SPRINT_END"])
	var walk: float = float(script.get_script_constant_map()["WALK_SPEED"])
	var sprint: float = \
		float(script.get_script_constant_map()["SPRINT_SPEED"])
	check(total >= 10.0 and total <= 20.0,
		"durée 10-20 s (§30.1) : %.1f s" % total)
	check(walk_end < sprint_end and sprint_end < total,
		"marche PUIS sprint PUIS rotation — trois phases ordonnées")
	check(absf(walk - 3.5) < 0.01 and absf(sprint - 9.0) < 0.01,
		"vitesses du CONTRAT de locomotion §8.2 (3,5 et 9 m/s)")
	await _settle(1)


func test_the_dolly_really_moves_the_lab_camera() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var dolly: Node3D = (load(DOLLY_SCENE) as PackedScene).instantiate() \
		as Node3D
	_root.add_child(dolly)
	await _settle(4)
	var camera: Camera3D = null
	for node: Node in dolly.find_children("*", "Camera3D", true, false):
		camera = node as Camera3D
		break
	check(camera != null, "le dolly monte le lab et trouve sa caméra")
	if camera == null:
		await _teardown()
		return
	var z_before: float = camera.position.z
	var yaw_before: float = camera.rotation_degrees.y
	await _settle(8)
	check(camera.position.z < z_before - 0.01,
		"la caméra AVANCE réellement (marche vers −Z : %.3f → %.3f)"
		% [z_before, camera.position.z])
	check(absf(camera.rotation_degrees.y - yaw_before) < 0.001,
		"pas de rotation pendant la phase de marche (elle vient en 3e)")
	# La hauteur d'œil suit la pente continue du lab, pas un plan fixe.
	var expected_y: float = camera.position.z * HeroShotLab.SLOPE_TAN
	check(camera.position.y > expected_y + 0.5
		and camera.position.y < expected_y + 3.5,
		"hauteur d'œil tenue AU-DESSUS de la pente (y=%.2f, sol=%.2f)"
		% [camera.position.y, expected_y])
	await _teardown()
