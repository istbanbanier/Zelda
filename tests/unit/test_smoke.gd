## Test de fumée Phase 0 : prouve que le moteur exécuté est bien Godot 4.7.1-stable
## et que les réglages critiques du projet sont ceux attendus.
## Ne teste aucun système de jeu — ceux-ci arrivent avec leurs phases.
extends GateTestCase


func test_engine_version_is_4_7_1_stable() -> void:
	var v: Dictionary = Engine.get_version_info()
	check_equal(int(v.get("major", 0)), 4, "version majeure")
	check_equal(int(v.get("minor", 0)), 7, "version mineure")
	check_equal(int(v.get("patch", -1)), 1, "version patch")
	check_equal(String(v.get("status", "")), "stable", "statut de version")


func test_physics_engine_is_jolt() -> void:
	check_equal(String(ProjectSettings.get_setting("physics/3d/physics_engine", "")),
		"Jolt Physics", "physics/3d/physics_engine")


func test_renderer_is_forward_plus() -> void:
	check_equal(String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")),
		"forward_plus", "rendering/renderer/rendering_method")


func test_physics_tick_is_60hz() -> void:
	check_equal(int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 0)),
		60, "physics/common/physics_ticks_per_second")


func test_metre_scale_convention() -> void:
	# 1 unité = 1 m, Y vertical.
	check_approx(Vector3.UP.length(), 1.0, 0.0001, "norme de Vector3.UP")
	check_approx(Vector3.UP.y, 1.0, 0.0001, "composante verticale de Vector3.UP")
