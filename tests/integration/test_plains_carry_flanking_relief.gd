## LES PLAINES PORTENT UN RELIEF DE FLANC — des buttes marchables qui
## cassent les deux dalles, sans jamais porter la ligne parcourue.
##
## POURQUOI CE TEST. Passe 3 (2026-08-12), défaut n°3 de la revue Codex :
## « donne du relief au corridor des dix minutes, casse les grandes surfaces
## uniformes ». ISS-045 mesure le fond : 991 des 1 024 sondages sous 5° de
## pente, 815 sur deux dalles plates. Remodeler le SOL est le changement le
## plus risqué du dépôt (~4 000 objets posés en cotes absolues) et reste au
## backlog avec son filet à construire — le geste de cette passe est
## l'incrément SÛR : des buttes convexes AJOUTÉES sur les dalles, en flanc
## de route, à des emplacements prouvés vides.
##
## Trois contrats machine :
##   1. les buttes existent, sont MARCHABLES (dôme doux, pas un rocher) et
##      portent une vraie collision convexe — un décor traversable serait un
##      mensonge découvert au premier pas ;
##   2. elles FLANQUENT la route : aucune butte ne mord un tronçon du
##      chemin — le corridor joué reste plat, seul son horizon change ;
##   3. elles n'ENTERRENT rien : aucun nœud des groupes de gameplay
##      (interactable, saveable, enemies, lock_on_targets) dans l'emprise.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const MIN_MOUNDS: int = 8
## Une butte est un DÔME : au moins quatre fois plus large que haute.
const MIN_WIDTH_TO_HEIGHT: float = 4.0
const GAMEPLAY_GROUPS: Array[StringName] = [&"interactable", &"saveable",
	&"enemies", &"lock_on_targets"]


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


func _mounds_of(valley: ValleyWorld) -> Array[StaticBody3D]:
	var zone: Node3D = valley.find_child("PlainRelief", true, false) as Node3D
	var mounds: Array[StaticBody3D] = []
	if zone != null:
		for child: Node in zone.get_children():
			if child is StaticBody3D:
				mounds.append(child as StaticBody3D)
	return mounds


func _mound_aabb(mound: StaticBody3D) -> AABB:
	var mesh: MeshInstance3D = mound.find_children("*", "MeshInstance3D",
		false, false)[0] as MeshInstance3D
	return mound.global_transform * mesh.get_aabb()


func test_the_plains_carry_walkable_convex_mounds() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var mounds: Array[StaticBody3D] = _mounds_of(valley)
	check(mounds.size() >= MIN_MOUNDS,
		"les plaines portent au moins %d buttes (%d)" % [MIN_MOUNDS,
			mounds.size()])
	for mound: StaticBody3D in mounds:
		var aabb: AABB = _mound_aabb(mound)
		check(aabb.size.y >= 1.0 and aabb.size.y <= 3.0,
			"%s : une butte d'homme (%.1f m de haut)" % [mound.name, aabb.size.y])
		check(minf(aabb.size.x, aabb.size.z) >= aabb.size.y * MIN_WIDTH_TO_HEIGHT,
			"%s : un dôme marchable, %d fois plus large que haut (%.0f × %.0f)"
				% [mound.name, int(MIN_WIDTH_TO_HEIGHT), aabb.size.x, aabb.size.z])
		var shape: CollisionShape3D = mound.find_children("*", "CollisionShape3D",
			false, false)[0] as CollisionShape3D
		check(shape != null and shape.shape is ConvexPolygonShape3D,
			"%s : collision convexe réelle (un relief traversable mentirait)"
				% mound.name)
	await _cleanup(valley)


func test_the_mounds_flank_but_never_carry_the_walked_line() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var mounds: Array[StaticBody3D] = _mounds_of(valley)
	check(not mounds.is_empty(), "des buttes existent à mesurer")
	var pieces: Array[Node] = valley.find_children("PathStrip*", "MeshInstance3D",
		true, false)
	var offenders: Array[String] = []
	for mound: StaticBody3D in mounds:
		var aabb: AABB = _mound_aabb(mound)
		var at: Vector2 = Vector2(mound.global_position.x, mound.global_position.z)
		var reach: float = maxf(aabb.size.x, aabb.size.z) * 0.5 + 2.0
		for piece: Node in pieces:
			var p: Vector3 = (piece as Node3D).global_position
			if at.distance_to(Vector2(p.x, p.z)) < reach:
				offenders.append("%s mord %s" % [mound.name, piece.name])
	check(offenders.is_empty(),
		"aucune butte ne porte la ligne parcourue (fautives : %s)"
			% (", ".join(offenders) if not offenders.is_empty() else "aucune"))
	await _cleanup(valley)


func test_the_mounds_bury_no_gameplay_node() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	await _tree().physics_frame
	var mounds: Array[StaticBody3D] = _mounds_of(valley)
	check(not mounds.is_empty(), "des buttes existent à mesurer")
	var buried: Array[String] = []
	for group: StringName in GAMEPLAY_GROUPS:
		for node: Node in _tree().get_nodes_in_group(group):
			if not (node is Node3D):
				continue
			var at: Vector3 = (node as Node3D).global_position
			for mound: StaticBody3D in mounds:
				var aabb: AABB = _mound_aabb(mound)
				# L'emprise au sol, gonflée d'un mètre de marge.
				if at.x > aabb.position.x - 1.0 \
						and at.x < aabb.position.x + aabb.size.x + 1.0 \
						and at.z > aabb.position.z - 1.0 \
						and at.z < aabb.position.z + aabb.size.z + 1.0 \
						and at.y < aabb.position.y + aabb.size.y + 1.0:
					buried.append("%s (%s) sous %s" % [node.name, group,
						mound.name])
	check(buried.is_empty(),
		"aucune butte n'enterre un nœud de gameplay (fautifs : %s)"
			% (", ".join(buried) if not buried.is_empty() else "aucun"))
	await _cleanup(valley)
