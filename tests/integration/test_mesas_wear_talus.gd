## LES MESAS NE SONT PLUS DES DALLES À BORDS NETS — ET LA PAROI D'ESCALADE
## RESTE NUE.
##
## POURQUOI CE TEST. Lot E (étape 7) : les captures de gate 1, 2 et 5 montrent
## encore deux grandes dalles de roche aux faces verticales lisses — la
## terrasse du pylône (rebord y = 18) et la falaise d'apprentissage
## (rebord y = 14). La face sud du plateau du donjon a reçu sa falaise au
## lot B ; ces deux-là ont gardé leurs murs de dalle. Même recette : des
## rangs de prismes qui se chevauchent, décor sans collision.
##
## LA CONTRAINTE QUI PRIME SUR L'IMAGE : la face EST de la falaise
## d'apprentissage (x = −80) est LA paroi d'escalade de §9.3 — deux
## corniches de repos y vivent (`CliffLedgeLow/High` à x = −79,5). Un talus
## posé là transformerait la leçon d'escalade en éboulis inescaladable.
## Ce test vérifie donc autant l'ABSENCE de talus sur cette face que sa
## présence ailleurs.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _cleanup(world: Node) -> void:
	_tree().root.remove_child(world)
	world.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	var audio: Node = _tree().root.get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("stop_ambience"):
		audio.call("stop_ambience")
	await _tree().physics_frame


func test_the_two_mesas_wear_overlapping_talus_below_their_rims() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var skirts: Node3D = valley.find_child("MesaSkirts", true, false) as Node3D
	check_not_null(skirts, "la zone des talus de mesas existe")
	if skirts == null:
		await _cleanup(valley)
		return
	# [préfixe, rebord de la mesa]
	for face: Array in [["PylonMesaS", 18.0], ["PylonMesaE", 18.0],
			["LearnMesaS", 14.0]]:
		var prefix: String = face[0]
		var rim: float = face[1]
		var pieces: Array[Node] = skirts.find_children("%s*" % prefix,
			"MeshInstance3D", false, false)
		check(pieces.size() >= 4,
			"la face %s porte un rang de talus (%d prismes)"
				% [prefix, pieces.size()])
		for piece: Node in pieces:
			var mesh: MeshInstance3D = piece as MeshInstance3D
			var top: float = (mesh.global_transform * mesh.get_aabb()) \
				.get_support(Vector3.UP).y
			check(top < rim - 0.3,
				"%s culmine à %.1f m, SOUS le rebord %.0f — la mesa domine"
					% [mesh.name, top, rim])
	check(skirts.find_children("*", "PhysicsBody3D", true, false).is_empty(),
		"les talus sont un décor sans collision — rien ne devient escaladable")
	await _cleanup(valley)


func test_the_climbing_wall_stays_bare_of_talus() -> void:
	## La paroi d'escalade : face est de LearningCliff, plan x = −80,
	## z 40..90. AUCUNE pièce de talus à moins de 4 m devant elle — sinon la
	## leçon d'escalade de §9.3 bute sur un éboulis décoratif.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var skirts: Node3D = valley.find_child("MesaSkirts", true, false) as Node3D
	check_not_null(skirts, "la zone des talus existe")
	var intruders: Array[String] = []
	if skirts != null:
		for piece: Node in skirts.find_children("*", "MeshInstance3D", false, false):
			var at: Vector3 = (piece as Node3D).global_position
			if at.x > -84.0 and at.x < -70.0 and at.z > 38.0 and at.z < 92.0:
				intruders.append(String(piece.name))
	check(intruders.is_empty(),
		"aucun talus devant la paroi d'escalade (intrus : %s)"
			% (", ".join(intruders) if not intruders.is_empty() else "aucun"))
	# Les corniches de repos, elles, doivent toujours exister.
	check(valley.find_child("CliffLedgeLow", true, false) != null
		and valley.find_child("CliffLedgeHigh", true, false) != null,
		"les corniches de repos de §9.3 sont intactes")
	await _cleanup(valley)
