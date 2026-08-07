## Pourquoi `E` ne fait rien — diagnostic, pas test.
##
## Le playtest du 2026-08-07 rapporte SEPT appuis sur `E` devant sept objets,
## zéro invite. La chaîne existe pourtant en entier. Ce script ne juge pas :
## il pose le héros devant chaque interactable de la vallée et imprime, étape
## par étape, LAQUELLE des conditions de `_select_interactable()` rejette.
##
##   godot --headless --path . --script tools/godot/diagnose_interaction.gd
extends SceneTree

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const APPROACH: float = 1.5


func _initialize() -> void:
	await process_frame
	var valley: Node3D = (load(VALLEY) as PackedScene).instantiate() as Node3D
	root.add_child(valley)
	for i: int in range(10):
		await physics_frame

	var player: PlayerController = valley.call("player") as PlayerController
	var shell: Node = valley.get_node_or_null("GameplayShell")
	print("=== ÉTAT DE LA CHAÎNE ===")
	print("  joueur .................. %s" % ("OK" if player != null else "ABSENT"))
	print("  coquille ................ %s" % ("OK" if shell != null else "ABSENTE"))
	if shell != null:
		# La liaison différée a-t-elle réussi ? La seule preuve qui compte est
		# que la coquille écoute réellement le signal du joueur.
		var listeners: int = player.get_signal_connection_list(
			"interact_focus_changed").size()
		print("  abonnés à interact_focus_changed : %d" % listeners)

	var group: Array[Node] = get_nodes_in_group("interactable")
	print("  membres du groupe `interactable` : %d" % group.size())
	print("")

	var range_m: float = PlayerController.INTERACT_RANGE
	var min_dot: float = PlayerController.INTERACT_MIN_DOT
	print("=== CHAQUE INTERACTABLE, VU DEPUIS 1,5 m ===")
	print("  (portée %.2f m, cône dot >= %.2f)" % [range_m, min_dot])
	var reachable: int = 0
	for node: Node in group:
		var target: Node3D = node as Node3D
		if target == null:
			continue
		var verdict: String = await _probe(player, target)
		if verdict == "OK":
			reachable += 1
		print("  %-34s %s" % [target.name, verdict])
	print("")
	print("=== BILAN : %d / %d atteignables ===" % [reachable, group.size()])
	quit(0)


## Pose le héros devant la cible, puis rejoue les filtres un par un.
func _probe(player: PlayerController, target: Node3D) -> String:
	var axes: Array[Vector3] = [Vector3.FORWARD, Vector3.BACK,
		Vector3.LEFT, Vector3.RIGHT]
	var reasons: Array[String] = []
	for axis: Vector3 in axes:
		player.velocity = Vector3.ZERO
		player.global_position = target.global_position + axis * APPROACH \
			+ Vector3.UP * 0.6
		for i: int in range(3):
			await physics_frame
		var visual: Node3D = player.get_node("VisualRoot") as Node3D
		var to_target: Vector3 = target.global_position - player.global_position
		visual.rotation.y = atan2(to_target.x, to_target.z)
		for i: int in range(8):
			await physics_frame

		if not target.has_method("interact"):
			return "PAS DE MÉTHODE interact()"
		var flat: Vector3 = to_target
		flat.y = 0.0
		var distance: float = flat.length()
		if distance > PlayerController.INTERACT_RANGE:
			reasons.append("hors portée (%.2f m)" % distance)
			continue
		var forward: Vector3 = visual.global_transform.basis.z
		forward.y = 0.0
		var dot: float = flat.normalized().dot(forward.normalized())
		if dot < PlayerController.INTERACT_MIN_DOT:
			reasons.append("hors cône (dot %.2f)" % dot)
			continue
		if player.current_interact_target() != target:
			reasons.append("rejeté par la ligne de vue ou l'invite")
			continue
		return "OK"
	return "ÉCHEC — " + "; ".join(reasons)
