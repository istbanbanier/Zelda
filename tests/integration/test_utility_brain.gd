## P2-3 — Sélection utilitaire explicable (P2 §8.1). Fail-first.
##
## Contrats : le meilleur score gagne ; l'égalité se départage par l'ordre de
## déclaration (priorité du propriétaire) ; la trace garde les trois meilleurs
## avec leurs raisons ; et l'azur — premier client réel — expose une décision
## de poursuite LISIBLE (« flanquer parce que mi-distance », « presser parce
## que loin ») à comportement inchangé.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null


func test_the_brain_picks_the_best_keeps_a_trace_and_breaks_ties_by_rank() -> void:
	var brain: UtilityBrain = UtilityBrain.new()
	check(brain.choose([]) == &"", "aucune option : aucun choix")
	check(brain.trace().is_empty(), "…et trace vide")
	var options: Array[Dictionary] = [
		{ "id": &"a", "score": 0.5, "reason": "faible" },
		{ "id": &"b", "score": 2.0, "reason": "fort" },
		{ "id": &"c", "score": 1.0, "reason": "moyen" },
		{ "id": &"d", "score": 0.1, "reason": "négligeable" },
	]
	check(brain.choose(options) == &"b", "le meilleur score gagne")
	var trace: Array[Dictionary] = brain.trace()
	check(trace.size() == 3, "trace bornée aux trois meilleurs")
	check(StringName(trace[0]["id"]) == &"b" and StringName(trace[1]["id"]) == &"c" \
		and StringName(trace[2]["id"]) == &"a", "trace triée b > c > a")
	check(String(trace[0]["reason"]) == "fort", "la raison voyage avec le choix")
	# Égalité : l'ordre de déclaration tranche.
	var tied: Array[Dictionary] = [
		{ "id": &"premier", "score": 1.0, "reason": "déclaré d'abord" },
		{ "id": &"second", "score": 1.0, "reason": "déclaré ensuite" },
	]
	check(brain.choose(tied) == &"premier",
		"égalité : la priorité de déclaration départage")


func test_the_blue_raider_explains_its_chase_decision() -> void:
	var tree: SceneTree = _tree()
	_root = Node3D.new()
	tree.root.add_child(_root)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(80.0, 1.0, 80.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	_root.add_child(floor_body)
	var player_scene: PackedScene = load(PLAYER) as PackedScene
	var player: PlayerController = player_scene.instantiate() as PlayerController
	_root.add_child(player)
	player.global_position = Vector3(0.0, 0.1, 0.0)
	var blue_scene: PackedScene = load("res://scenes/enemies/RaiderBlue.tscn") as PackedScene
	var blue: RaiderBlue = blue_scene.instantiate() as RaiderBlue
	_root.add_child(blue)
	# Le pivot par défaut regarde +Z : on place l'azur en -Z du joueur pour
	# que sa vision le trouve (leçon du test du Briseur).
	# LOIN (> 8 m de flanc max) : l'azur PRESSE, et le dit.
	blue.global_position = Vector3(0.0, 0.1, -14.0)
	for i: int in range(40):
		await tree.physics_frame
		if not blue.chase_trace().is_empty() \
				and StringName((blue.chase_trace()[0] as Dictionary)["id"]) == &"presser":
			break
	var far_trace: Array[Dictionary] = blue.chase_trace()
	check(not far_trace.is_empty(), "une décision de poursuite est tracée")
	if not far_trace.is_empty():
		check(StringName(far_trace[0]["id"]) == &"presser",
			"loin : presser (obtenu %s)" % String(far_trace[0]["id"]))
	# MI-DISTANCE (2,8-8 m) : il FLANQUE, et le dit.
	blue.global_position = Vector3(0.0, 0.1, -5.0)
	for i: int in range(40):
		await tree.physics_frame
		if not blue.chase_trace().is_empty() \
				and StringName((blue.chase_trace()[0] as Dictionary)["id"]) == &"flanquer":
			break
	var mid_trace: Array[Dictionary] = blue.chase_trace()
	check(not mid_trace.is_empty() \
		and StringName(mid_trace[0]["id"]) == &"flanquer",
		"mi-distance : flanquer (obtenu %s)" % (String(mid_trace[0]["id"]) \
			if not mid_trace.is_empty() else "rien"))
	check(mid_trace.size() >= 2 and String(mid_trace[0]["reason"]) != "",
		"la trace porte des raisons lisibles (P2 §8.1)")
	_teardown()
