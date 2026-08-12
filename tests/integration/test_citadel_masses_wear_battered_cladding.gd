## LES GRANDES MASSES DE LA CITADELLE PORTENT UN HABILLAGE TALUTÉ — la
## silhouette cesse d'être des arêtes de boîtes.
##
## POURQUOI CE TEST. Passe 3 (2026-08-12), défaut n°1 de la revue Codex :
## « masses rectangulaires dominantes visibles depuis les six caméras ».
## L'étape 4 avait taluté les TERRASSES et percé des vides ; mais le Keep
## (34 × 46 × 28), les deux épaules (14 × 30 × 18), les quatre tours
## (8 × 40-58 × 8), les deux segments de spire et les quatre contreforts de
## base restaient des `BoxMesh` nus : arêtes verticales parfaites, silhouette
## de boîte, exactement ce que la revue relève.
##
## LA CONTRAINTE QUI GOUVERNE LA RECETTE : les cotes des boîtes PORTEUSES DE
## COLLISION sont testées ailleurs (H : `keep_box.size.x ≥ 30` ; PT-D1-09 :
## un porteur ne pivote jamais). On ne touche donc PAS aux porteurs — on les
## HABILLE de troncs de pyramide sans collision, axés monde, qui prennent en
## charge la silhouette : piliers d'angle battus sur le Keep, coques sur les
## épaules, manchons effilés sur les tours ; et les masses qui étaient déjà
## du décor pur (spire, contreforts) deviennent elles-mêmes des troncs.
##
## Ce test vérifie la STRUCTURE qui rend l'image possible ; le verdict
## d'image appartient à la revue indépendante.
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


func _citadel(valley: ValleyWorld) -> Node3D:
	return valley.get_node_or_null("Terrain/CitadelProxy") as Node3D


## Un habillage est un DÉCOR taluté : mesh présent, pas un BoxMesh, aucune
## collision portée ni héritée — la leçon PT-D1-09 s'applique à chaque pièce.
func _check_cladding(node: MeshInstance3D, label: String) -> void:
	check(not (node.mesh is BoxMesh),
		"%s n'est pas une boîte (%s)" % [label, node.mesh.get_class()])
	check(not (node.get_parent() is PhysicsBody3D)
		and node.find_children("*", "PhysicsBody3D", true, false).is_empty(),
		"%s est un décor sans collision" % label)


func test_the_keep_front_corners_carry_battered_piers() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var citadel: Node3D = _citadel(valley)
	check_not_null(citadel, "le proxy de citadelle existe")
	if citadel == null:
		await _cleanup(valley)
		return
	var piers: Array[Node] = citadel.find_children("KeepPier*", "MeshInstance3D",
		false, false)
	check(piers.size() >= 2,
		"les angles avant du Keep portent des piliers (%d)" % piers.size())
	# Les deux arêtes verticales AVANT du Keep (x ±17, z −198) sont ce que
	# la silhouette montre : chacune doit vivre DANS un pilier, du tiers
	# bas au couronnement.
	for corner_x: float in [-17.0, 17.0]:
		var carried: bool = false
		for pier: Node in piers:
			var mesh: MeshInstance3D = pier as MeshInstance3D
			var aabb: AABB = mesh.global_transform * mesh.get_aabb()
			if aabb.has_point(Vector3(corner_x, 45.0, -198.0)) \
					and aabb.has_point(Vector3(corner_x, 72.0, -198.0)):
				carried = true
		check(carried,
			"l'arête avant x = %.0f du Keep vit dans un pilier (y 45 et y 72)"
				% corner_x)
	for pier: Node in piers:
		_check_cladding(pier as MeshInstance3D, String(pier.name))
	await _cleanup(valley)


func test_the_shoulders_are_shrouded_in_battered_shells() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var citadel: Node3D = _citadel(valley)
	check_not_null(citadel, "le proxy de citadelle existe")
	if citadel != null:
		for i: int in range(2):
			var shell: MeshInstance3D = citadel.get_node_or_null(
				"ShoulderShell%d" % i) as MeshInstance3D
			check_not_null(shell, "la coque de l'épaule %d existe" % i)
			if shell == null:
				continue
			_check_cladding(shell, String(shell.name))
			var aabb: AABB = shell.global_transform * shell.get_aabb()
			check(aabb.size.x >= 18.0,
				"%s déborde l'épaule (largeur %.1f ≥ 18 — la boîte fait 14)"
					% [shell.name, aabb.size.x])
			check(aabb.size.y >= 22.0,
				"%s monte aux trois quarts de l'épaule (%.1f ≥ 22 sur 30)"
					% [shell.name, aabb.size.y])
	await _cleanup(valley)


func test_the_towers_wear_tapered_sleeves() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var citadel: Node3D = _citadel(valley)
	check_not_null(citadel, "le proxy de citadelle existe")
	if citadel != null:
		for i: int in range(4):
			var sleeve: MeshInstance3D = citadel.get_node_or_null(
				"TowerSleeve%d" % i) as MeshInstance3D
			check_not_null(sleeve, "le manchon de la tour %d existe" % i)
			var tower_mesh: MeshInstance3D = citadel.get_node_or_null(
				"Tower%d/Tower%dMesh" % [i, i]) as MeshInstance3D
			check_not_null(tower_mesh, "la tour %d existe" % i)
			if sleeve == null or tower_mesh == null:
				continue
			_check_cladding(sleeve, String(sleeve.name))
			var sleeve_aabb: AABB = sleeve.global_transform * sleeve.get_aabb()
			var tower_height: float = (tower_mesh.mesh as BoxMesh).size.y
			check(sleeve_aabb.size.x >= 10.0 and sleeve_aabb.size.z >= 10.0,
				"%s déborde la tour (%.1f × %.1f ≥ 10 — la tour fait 8)"
					% [sleeve.name, sleeve_aabb.size.x, sleeve_aabb.size.z])
			check(sleeve_aabb.size.y >= tower_height * 0.85,
				"%s couvre la tour (%.1f ≥ 85 %% de %.0f)"
					% [sleeve.name, sleeve_aabb.size.y, tower_height])
	await _cleanup(valley)


func test_the_spire_and_base_buttresses_taper() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var citadel: Node3D = _citadel(valley)
	check_not_null(citadel, "le proxy de citadelle existe")
	if citadel != null:
		for segment_name: String in ["SpireBase", "SpireMid"]:
			var segment: MeshInstance3D = citadel.get_node_or_null(
				NodePath(segment_name)) as MeshInstance3D
			check_not_null(segment, "« %s » existe" % segment_name)
			if segment != null:
				check(not (segment.mesh is BoxMesh),
					"« %s » est effilé, pas une boîte (%s)"
						% [segment_name, segment.mesh.get_class()])
		for i: int in range(4):
			var buttress: MeshInstance3D = citadel.get_node_or_null(
				"Buttress%d" % i) as MeshInstance3D
			check_not_null(buttress, "le contrefort %d existe" % i)
			if buttress != null:
				check(not (buttress.mesh is BoxMesh),
					"le contrefort %d est taluté, pas une boîte (%s)"
						% [i, buttress.mesh.get_class()])
	await _cleanup(valley)
