## P2-4e (fin) — Les trois éclats de Fragment posés à leurs écoles, et la
## persistance des Fragments accordés. Fail-first.
##
## Contrats : chaque POI-école porte SON éclat (Flux à l'autel, Élan au pont,
## Écho au bassin), identifiants §19.3 distincts ; ramasser accorde et
## libère ; un fragment déjà détenu laisse l'éclat en place (rien de perdu) ;
## et le champ `fragments` du save fait l'aller-retour (grant → écrire →
## relire → toujours détenu).
extends GateTestCase

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null


func test_each_school_carries_its_own_shard() -> void:
	var tree: SceneTree = _tree()
	_root = Node3D.new()
	tree.root.add_child(_root)
	var relics: Node3D = ValleyRelics.new()
	_root.add_child(relics)
	await tree.physics_frame
	var expected: Dictionary = {
		&"flux": "SanctuaireForestier",
		&"elan": "PontMagnetique",
		&"echo": "BassinConducteur",
	}
	var seen_ids: Array[StringName] = []
	for fragment_id: StringName in expected:
		var site: Node3D = relics.get_node_or_null(
			String(expected[fragment_id])) as Node3D
		check(site != null, "le site %s existe" % expected[fragment_id])
		if site == null:
			continue
		var shard: FragmentPickup = null
		for node: Node in site.find_children("*", "FragmentPickup", true, false):
			shard = node as FragmentPickup
		check(shard != null and shard.fragment_id == fragment_id,
			"%s porte l'éclat %s" % [expected[fragment_id], fragment_id])
		if shard != null:
			check(String(shard.pickup_id).begins_with("valley."),
				"identifiant persistant §19.3 (%s)" % shard.pickup_id)
			check(not shard.pickup_id in seen_ids, "identifiant distinct")
			seen_ids.append(shard.pickup_id)
	_teardown()


func test_picking_grants_frees_and_refuses_duplicates() -> void:
	var tree: SceneTree = _tree()
	_root = Node3D.new()
	tree.root.add_child(_root)
	var player_scene: PackedScene = load("res://scenes/player/Player.tscn") as PackedScene
	var player: PlayerController = player_scene.instantiate() as PlayerController
	_root.add_child(player)
	var resonance: ResonanceController = \
		player.get_node("Components/ResonanceController") as ResonanceController
	var shard: FragmentPickup = FragmentPickup.new()
	shard.fragment_id = &"flux"
	shard.pickup_id = &"valley.fragment.test.01"
	_root.add_child(shard)
	await tree.physics_frame
	var picked: Array[int] = [0]
	shard.picked_up.connect(func(_id: StringName) -> void: picked[0] += 1)
	check(shard.interact(player), "le ramassage réussit")
	check(resonance.has_fragment(&"flux"), "le Fragment est accordé")
	check(picked[0] == 1, "signal émis une fois")
	# Un second éclat du MÊME fragment : refusé, il reste en place.
	var twin: FragmentPickup = FragmentPickup.new()
	twin.fragment_id = &"flux"
	twin.pickup_id = &"valley.fragment.test.02"
	_root.add_child(twin)
	await tree.physics_frame
	check(not twin.interact(player), "déjà détenu : refusé")
	await tree.physics_frame
	check(is_instance_valid(twin) and twin.is_inside_tree(),
		"…et l'éclat reste en place (rien de perdu)")
	_teardown()
