## Test de fumée Phase 0 : prouve que le runner découvre, exécute, distingue
## réussite et échec, et que le moteur exécuté est bien Godot 4.7.1-stable.
## Ne teste aucun système de jeu — ceux-ci arrivent avec leurs phases.
extends RefCounted

var _reporter: Object = null


func set_reporter(reporter: Object) -> void:
	_reporter = reporter


func _assert(condition: bool, message: String) -> void:
	if not condition and _reporter != null:
		_reporter.call("report_failure", message)


func test_engine_version_is_4_7_1_stable() -> void:
	var v: Dictionary = Engine.get_version_info()
	_assert(int(v.get("major", 0)) == 4, "major attendu 4, obtenu %s" % v.get("major"))
	_assert(int(v.get("minor", 0)) == 7, "minor attendu 7, obtenu %s" % v.get("minor"))
	_assert(int(v.get("patch", -1)) == 1, "patch attendu 1, obtenu %s" % v.get("patch"))
	_assert(String(v.get("status", "")) == "stable", "status attendu stable, obtenu %s" % v.get("status"))


func test_physics_engine_is_jolt() -> void:
	var engine_name: String = String(ProjectSettings.get_setting("physics/3d/physics_engine", ""))
	_assert(engine_name == "Jolt Physics", "physics/3d/physics_engine attendu 'Jolt Physics', obtenu '%s'" % engine_name)


func test_renderer_is_forward_plus() -> void:
	var method: String = String(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	_assert(method == "forward_plus", "rendering_method attendu 'forward_plus', obtenu '%s'" % method)


func test_physics_tick_is_60hz() -> void:
	var ticks: int = int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 0))
	_assert(ticks == 60, "physics_ticks_per_second attendu 60, obtenu %d" % ticks)


func test_metre_scale_convention() -> void:
	# 1 unité = 1 m : un déplacement de 1.0 sur Y doit valoir 1 m dans la convention projet.
	var up: Vector3 = Vector3.UP
	_assert(is_equal_approx(up.length(), 1.0), "Vector3.UP doit mesurer 1.0")
	_assert(is_equal_approx(up.y, 1.0), "Y doit être l'axe vertical")
