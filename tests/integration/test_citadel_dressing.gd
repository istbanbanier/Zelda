## ART-Q5 — architecture pénétrable : le vestibule porte des colonnes
## MODULAIRES réelles (trois segments empilés) sur ses collisions intactes,
## le seuil scellé et la porte de la vallée sont encadrés du même portail
## de pierre, et le SYSTÈME de scène (SceneDoor aller/retour) n'a pas
## bougé — mesuré sur les vraies scènes.
extends GateTestCase

const VESTIBULE: String = "res://scenes/world/citadel/CitadelVestibule.tscn"
const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _cleanup(scene: Node) -> void:
	scene.get_parent().remove_child(scene)
	scene.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


func test_the_vestibule_columns_are_modular_stacks_on_intact_collisions() -> void:
	## Six colonnes : graybox masqué, TROIS segments de pilier réels empilés
	## sur ~9 m, et la collision boîte toujours en place — la géométrie
	## jouable n'a pas changé d'un centimètre.
	var vestibule: Node3D = (load(VESTIBULE) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(vestibule)
	await _settle(4)
	for i: int in range(6):
		var stack: Node3D = vestibule.get_node_or_null("ColumnStack%d" % i) as Node3D
		check(stack != null, "colonne %d : pile modulaire présente" % i)
		if stack == null:
			continue
		check_equal(stack.get_child_count(), 3, "…trois segments empilés")
		var top: Node3D = stack.get_node("Segment2") as Node3D
		check_approx(top.position.y, 6.08, 0.01, "…le 3e segment culmine à 6,08 m")
		var real: bool = false
		for mesh: Node in stack.find_children("*", "MeshInstance3D", true, false):
			if (mesh as MeshInstance3D).mesh != null:
				real = true
		check(real, "…maillages réels")
		var body: StaticBody3D = vestibule.get_node("Column%d" % i) as StaticBody3D
		check(not body.find_children("*", "CollisionShape3D", true, false)
			.is_empty(), "…collision graybox INTACTE")
		for child: Node in body.get_children():
			if child is MeshInstance3D:
				check(not (child as MeshInstance3D).visible,
					"…graybox de colonne masqué")
	check(vestibule.get_node_or_null("SealedDoorFrame") != null,
		"le seuil scellé est encadré du portail de pierre")
	check(vestibule.get_node_or_null("ExitDoor") != null,
		"la porte de sortie (système de scène) est toujours là")
	await _cleanup(vestibule)


func test_the_valley_gate_wears_the_same_stone_language() -> void:
	## La façade de la vallée porte l'arche de production et ses piliers de
	## flanc — même module que le vestibule (continuité) — et la SceneDoor
	## d'entrée garde son volume d'interaction.
	var valley: Node3D = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(valley)
	await _settle(5)
	var citadel: Node3D = valley.find_children("CitadelProxy", "Node3D", true,
		false)[0] as Node3D
	var arch: Node3D = citadel.get_node_or_null("GateStoneArch") as Node3D
	check(arch != null, "l'arche de pierre habille le seuil")
	if arch != null:
		var real: bool = false
		for mesh: Node in arch.find_children("*", "MeshInstance3D", true, false):
			if (mesh as MeshInstance3D).mesh != null:
				real = true
		check(real, "…avec un maillage réel")
	check(citadel.get_node_or_null("GateFlankPillar0") != null
		and citadel.get_node_or_null("GateFlankPillar1") != null,
		"deux piliers de flanc au pied des marches")
	var door: Node = citadel.get_node_or_null("CitadelDoor")
	check(door != null, "la SceneDoor d'entrée existe toujours")
	if door != null:
		check(not door.find_children("*", "CollisionShape3D", true, false)
			.is_empty(), "…avec son volume d'interaction intact")
	await _cleanup(valley)
