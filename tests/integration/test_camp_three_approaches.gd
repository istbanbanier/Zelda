## P2-3 — Le camp à TROIS approches (P2 §5.6/§7.7 : « trois plans viables »).
## Fail-first : écrit avant l'affordance d'environnement.
##
## 1. FRONTAL — entrer et se battre : prouvé par les suites de combat et le
##    golden path ; ici, l'ancrage existe (feu + campements).
## 2. INFILTRATION — le bruit DÉTOURNE : un Pulse tiré depuis un couvert fait
##    quitter son poste à un garde (SUSPICIOUS/INVESTIGATE vers le bruit),
##    sans qu'il ait jamais VU le joueur — chaîne systémique P2-2 × §12.7.
## 3. ENVIRONNEMENT — chaque campement braise porte une caisse métallique
##    chargeable : cible légitime de Polarité/Ground (P2 §2.3 : le camp se
##    joue aussi par les lois du monde).
extends GateTestCase

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null


func test_a_pulse_from_cover_diverts_the_guard_without_being_seen() -> void:
	var tree: SceneTree = _tree()
	_root = Node3D.new()
	tree.root.add_child(_root)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(60.0, 1.0, 60.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	_root.add_child(floor_body)
	# Couvert plein entre le joueur et le garde : jamais de ligne de vue.
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = 1
	var wall_shape: CollisionShape3D = CollisionShape3D.new()
	var wall_box: BoxShape3D = BoxShape3D.new()
	wall_box.size = Vector3(6.0, 4.0, 0.5)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	wall.position = Vector3(0.0, 2.0, -3.0)
	_root.add_child(wall)
	var player_scene: PackedScene = load("res://scenes/player/Player.tscn") as PackedScene
	var player: PlayerController = player_scene.instantiate() as PlayerController
	_root.add_child(player)
	player.global_position = Vector3(0.0, 0.1, 0.0)
	var red_scene: PackedScene = load("res://scenes/enemies/RaiderRed.tscn") as PackedScene
	var guard: EnemyBase = red_scene.instantiate() as EnemyBase
	_root.add_child(guard)
	# Au poste à −Z du mur, dans le rayon du bruit (9 m), dos au joueur.
	guard.global_position = Vector3(0.0, 0.1, -7.0)
	var post: Vector3 = guard.global_position
	for i: int in range(20):
		await tree.physics_frame
	check(guard.state_name() in [&"idle", &"patrol"],
		"préalable : le garde est à son poste, joueur jamais vu (%s)" % guard.state_name())
	# Le Pulse depuis le couvert — l'onde S'ENTEND (P2 §3.2).
	var resonance: ResonanceController = \
		player.get_node("Components/ResonanceController") as ResonanceController
	check(resonance.try_pulse(player) == &"fired", "Pulse tiré")
	var diverted: bool = false
	for i: int in range(180):
		await tree.physics_frame
		if guard.state_name() in [&"suspicious", &"investigate"]:
			diverted = true
			break
	check(diverted, "le garde est DÉTOURNÉ (suspicious/investigate — %s)" \
		% guard.state_name())
	# Il va VOIR : il quitte réellement son poste, sans jamais passer ALERT
	# (il n'a pas vu le joueur — le mur est plein).
	var left_post: bool = false
	for i: int in range(240):
		await tree.physics_frame
		if guard.state_name() in [&"alert", &"chase", &"attack"]:
			break
		if guard.global_position.distance_to(post) > 1.5:
			left_post = true
			break
	check(left_post, "il quitte son poste vers le bruit (%.1f m)" \
		% guard.global_position.distance_to(post))
	check(not guard.state_name() in [&"alert", &"chase", &"attack"],
		"jamais ALERT : il n'a rien VU (§12.7 — pas d'omniscience)")
	_teardown()


func test_every_braise_camp_carries_a_chargeable_metal_crate() -> void:
	var tree: SceneTree = _tree()
	_root = Node3D.new()
	tree.root.add_child(_root)
	var territories: Node3D = ValleyTerritories.new()
	_root.add_child(territories)
	await tree.physics_frame
	var camps: Node3D = territories.get_node_or_null("CampsDePillardsBraise") as Node3D
	check(camps != null, "les campements braise existent (ancrage frontal)")
	if camps == null:
		_teardown()
		return
	var crates: int = 0
	for camp: Node in camps.get_children():
		if not camp.name.begins_with("Campement"):
			continue
		var found: bool = false
		for node: Node in camp.find_children("*", "MaterialStateComponent", true, false):
			var state: MaterialStateComponent = node as MaterialStateComponent
			if state == null or state.profile == null:
				continue
			if state.profile.has_tag(&"metal") and state.profile.charge_capacity > 0.0 \
					and node.get_parent() is RigidBody3D:
				var marker: bool = false
				for sibling: Node in node.get_parent().get_children():
					var target: ResonanceTargetComponent = \
						sibling as ResonanceTargetComponent
					if target != null and target.kind == &"polarity":
						marker = true
				if marker:
					found = true
		if found:
			crates += 1
		check(found, "%s : une caisse métallique chargeable (Polarité/Ground)" \
			% camp.name)
	check(crates >= 3, "les trois campements sont équipés (%d/3)" % crates)
	_teardown()
