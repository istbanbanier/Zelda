## P2-4 — Autel de terre au sanctuaire forestier (bible §3.4 : POI
## Bracelet-dépendant, exercice SÛR de Ground avant le donjon — P2 §3.7).
## Fail-first : écrit avant l'implémentation.
##
## Contrats : le sanctuaire porte un cœur PRÉ-CHARGÉ (profil terre
## conductrice) ciblable par le Bracelet ; le mettre à la terre allume la
## stèle dormante (émission pilotée par l'état réel, patron ResonanceLab)
## et n'arrive qu'UNE fois par charge — le cœur se recharge lentement
## (décroissance inverse : la loi du composant), l'exercice se refait.
extends GateTestCase

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null


func test_the_shrine_carries_a_grounded_teachable_core() -> void:
	var tree: SceneTree = _tree()
	_root = Node3D.new()
	tree.root.add_child(_root)
	var relics: Node3D = ValleyRelics.new()
	_root.add_child(relics)
	await tree.physics_frame
	var shrine: Node3D = relics.get_node_or_null("SanctuaireForestier") as Node3D
	check(shrine != null, "le sanctuaire existe")
	if shrine == null:
		_teardown()
		return
	# Le cœur : état matière pré-chargé, ciblable par le Bracelet.
	var core_state: MaterialStateComponent = null
	for node: Node in shrine.find_children("*", "MaterialStateComponent", true, false):
		core_state = node as MaterialStateComponent
		break
	check(core_state != null, "un cœur à état matière est posé sur l'autel")
	if core_state == null:
		_teardown()
		return
	check(core_state.is_charged(), "le cœur est PRÉ-CHARGÉ (la raison de l'exercice)")
	check(core_state.profile != null and core_state.profile.has_tag(&"ground"),
		"profil terre conductrice (le langage de la mise à la terre)")
	var has_marker: bool = false
	for sibling: Node in core_state.get_parent().get_children():
		var target: ResonanceTargetComponent = sibling as ResonanceTargetComponent
		if target != null and target.kind == &"material":
			has_marker = true
	check(has_marker, "le cœur est ciblable par le Bracelet (marqueur material)")
	_teardown()


func test_grounding_the_core_lights_the_dormant_stele_once() -> void:
	var tree: SceneTree = _tree()
	_root = Node3D.new()
	tree.root.add_child(_root)
	# Sol porteur : le joueur doit être AU SOL pour une mise à la terre.
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 300.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(34.0, 1.5, 94.0)
	_root.add_child(floor_body)
	var relics: Node3D = ValleyRelics.new()
	_root.add_child(relics)
	await tree.physics_frame
	var shrine: Node3D = relics.get_node_or_null("SanctuaireForestier") as Node3D
	var core_state: MaterialStateComponent = null
	for node: Node in shrine.find_children("*", "MaterialStateComponent", true, false):
		core_state = node as MaterialStateComponent
		break
	var stele: MeshInstance3D = shrine.find_child("SteleDormante", true, false) \
		as MeshInstance3D
	check(stele != null, "la stèle dormante existe")
	if stele == null or core_state == null:
		_teardown()
		return
	var material: StandardMaterial3D = stele.material_override as StandardMaterial3D
	check(material != null and material.emission_energy_multiplier == 0.0,
		"éteinte au départ (dormante)")
	# Le joueur se poste près du cœur et le met à la terre.
	var player_scene: PackedScene = load("res://scenes/player/Player.tscn") as PackedScene
	var player: PlayerController = player_scene.instantiate() as PlayerController
	_root.add_child(player)
	var core_at: Vector3 = (core_state.get_parent() as Node3D).global_position
	player.global_position = core_at + Vector3(1.2, 0.6, 0.0)
	# Le spawn est ~1,7 m au-dessus du plancher : laisser la chute se poser
	# (Ground exige un appui réel — pas_au_sol sinon).
	for i: int in range(45):
		await tree.physics_frame
	var resonance: ResonanceController = \
		player.get_node("Components/ResonanceController") as ResonanceController
	var verdict: StringName = resonance.try_ground(player, core_state)
	check(verdict == &"grounding", "mise à la terre engagée (obtenu %s)" % verdict)
	for i: int in range(40):
		await tree.physics_frame
	check(not core_state.is_charged(), "le cœur est drainé")
	check(material.emission_energy_multiplier > 0.0,
		"la stèle S'ALLUME — la conséquence se voit (P2 §9.1 : conséquence visible)")
	_teardown()
