## Prouve que Jolt **simule** réellement (MASTER_SPEC §5.3).
##
## `test_smoke.gd` vérifie que `physics/3d/physics_engine` vaut « Jolt Physics ».
## C'est un réglage lu dans un fichier : il ne dit rien de ce qui tourne. Un
## serveur mal enregistré, un module absent du build ou une gravité à zéro
## passeraient ce contrôle sans qu'aucune bille ne tombe jamais.
##
## Ces tests sont **asynchrones** : ils font avancer de vraies frames physiques.
extends GateTestCase

const SANDBOX: String = "res://scenes/tests/PhysicsSandbox.tscn"

## Assez de frames pour une chute de 4 m à 9,8 m/s², avec de la marge.
const SETTLE_FRAMES: int = 180


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func test_jolt_module_is_present_in_the_build() -> void:
	## LIMITE CONNUE : GDScript n'expose pas la classe de l'implémentation
	## réellement instanciée — `PhysicsServer3D.get_class()` renvoie toujours
	## « PhysicsServer3D », le nom du singleton (vérifié par sonde sur 4.7.1).
	## On ne peut donc pas affirmer « Jolt tourne » par introspection directe.
	##
	## Ce qui est vérifiable, et vérifié ici :
	##   1. le module Jolt est bien compilé dans ce binaire — il enregistre ses
	##      propres réglages projet, absents d'un build qui ne l'aurait pas ;
	##   2. le projet demande Jolt (`test_smoke.gd`) ;
	##   3. une simulation a réellement lieu (test suivant).
	## Les trois ensemble suffisent en pratique ; aucun ne suffit seul.
	var jolt_settings: int = 0
	for setting: Dictionary in ProjectSettings.get_property_list():
		if String(setting.get("name", "")).begins_with("physics/jolt_physics_3d/"):
			jolt_settings += 1
	check(jolt_settings > 0,
		"aucun réglage « physics/jolt_physics_3d/ » : le module Jolt n'est pas dans ce build")


func test_a_body_actually_falls_and_settles_on_the_floor() -> void:
	var tree: SceneTree = _tree()
	check_not_null(tree, "SceneTree")
	if tree == null:
		return

	var packed: PackedScene = load(SANDBOX) as PackedScene
	check_not_null(packed, "scène de bac à sable")
	if packed == null:
		return

	var root_node: Node = packed.instantiate()
	tree.root.add_child(root_node)

	var ball: RigidBody3D = root_node.get_node("FallingBall") as RigidBody3D
	check_not_null(ball, "FallingBall")
	if ball == null:
		root_node.queue_free()
		return

	var start_y: float = ball.global_position.y
	check_approx(start_y, 4.0, 0.05, "hauteur de départ de la bille")

	for i: int in range(SETTLE_FRAMES):
		await tree.physics_frame

	var end_y: float = ball.global_position.y

	# 1. La gravité s'applique : sans simulation, la bille resterait à 4 m.
	check(end_y < start_y - 1.0,
		"la bille n'est pas tombée : départ %.3f m, arrivée %.3f m — la physique ne simule pas"
		% [start_y, end_y])

	# 2. La collision arrête la chute : sans collision, elle traverserait le sol.
	#    Sol à Y=0, rayon 0,5 -> centre au repos attendu vers 0,5 m.
	check_approx(end_y, 0.5, 0.15,
		"la bille ne repose pas sur le sol (centre attendu ~0,5 m)")

	# 3. Elle est bien au repos, pas en chute libre ni en rebond perpétuel.
	check(absf(ball.linear_velocity.y) < 0.5,
		"la bille n'est pas stabilisée : vitesse verticale %.3f m/s" % ball.linear_velocity.y)

	root_node.queue_free()


func test_physics_tick_matches_project_setting() -> void:
	## §5.3 : tick 60 Hz. Un écart change toutes les fenêtres d'action du combat.
	var configured: int = int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 0))
	check_equal(Engine.physics_ticks_per_second, configured,
		"le tick physique actif doit correspondre au réglage projet")
	check_equal(configured, 60, "tick physique attendu à 60 Hz")
