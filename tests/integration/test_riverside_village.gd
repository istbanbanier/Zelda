## VILLAGE DE LA RIVIÈRE (ordre d'extension §1, §2, §3).
##
## Le point dur n'est pas « le village existe » — c'est §1 : une structure
## dont la porte est visible doit avoir un VRAI intérieur. Un décor de
## façades passerait n'importe quel test de comptage. On fait donc entrer un
## corps physique par la baie et on vérifie qu'il tient debout DEDANS, sur un
## plancher, entouré de murs.
extends GateTestCase


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open() -> RiversideVillage:
	var village: RiversideVillage = RiversideVillage.new()
	_tree().root.add_child(village)
	await _settle(6)
	return village


func _close(village: Node) -> void:
	village.get_parent().remove_child(village)
	village.queue_free()
	await _settle(2)


func test_the_village_is_built_from_the_promoted_kit() -> void:
	var village: RiversideVillage = await _open()
	check(village.piece_count() >= 40,
		"%d pièces posées — le bourg n'est pas une maquette"
		% village.piece_count())
	for quarter: String in ["Auberge", "Forge", "Moulin", "Sanctuaire",
			"Habitations", "PlaceEtQuai"]:
		check_not_null(village.get_node_or_null(quarter),
			"le village a son quartier « %s » (§2)" % quarter)
	await _close(village)


## §2 : le village se DÉCLARE, avec un identifiant stable.
func test_the_village_declares_itself_to_the_discovery_log() -> void:
	var village: RiversideVillage = await _open()
	var journal: DiscoveryLog = DiscoveryLog.new()
	check_not_null(village.poi, "le village porte un point d'intérêt")
	village.poi.bind(journal)
	check(journal.is_registered(&"valley.poi.riverside_village.01"),
		"…déclaré sous son identifiant §19.3")
	check_equal(journal.display_name_of(&"valley.poi.riverside_village.01"),
		"Village de la rivière", "…avec son nom affiché")
	await _close(village)


## LE test de §1 : l'auberge est CREUSE et on y entre par la porte.
##
## Le corps est posé au-dessus du plancher intérieur ; s'il tombe, il n'y a
## pas de sol et l'« intérieur » est un mensonge. On le pousse ensuite contre
## chaque mur : s'il sort, la pièce n'est pas fermée.
func test_the_inn_has_a_real_interior_you_can_stand_in() -> void:
	var village: RiversideVillage = await _open()
	var inn: Node3D = village.get_node("Auberge") as Node3D
	var body: CharacterBody3D = CharacterBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	shape.shape = capsule
	body.add_child(shape)
	_tree().root.add_child(body)
	body.global_position = inn.global_position + Vector3(0, 1.4, 0)

	for i: int in range(90):
		body.velocity.y -= 24.0 * (1.0 / 60.0)
		body.move_and_slide()
		await _tree().physics_frame
		if body.is_on_floor():
			break
	check(body.is_on_floor(),
		"le corps se pose sur un PLANCHER dans l'auberge (y = %.2f)"
		% body.global_position.y)
	check(body.global_position.y > village.interior_floor_y - 0.6,
		"…et non au fond du monde (plancher attendu y = %.2f)"
		% village.interior_floor_y)

	# Les murs tiennent : poussé vers chaque côté, le corps reste dedans.
	var inside: Vector3 = body.global_position
	for direction: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD]:
		body.global_position = inside
		await _settle(1)
		for i: int in range(40):
			body.velocity = direction * 6.0
			body.velocity.y = -2.0
			body.move_and_slide()
			await _tree().physics_frame
		var drift: Vector3 = body.global_position - inn.global_position
		check(absf(drift.x) < 4.2 and absf(drift.z) < 4.2,
			"poussé vers %v, le corps reste dans la pièce (écart %.1f, %.1f)"
			% [direction, drift.x, drift.z])

	body.get_parent().remove_child(body)
	body.queue_free()
	await _close(village)


## §1 encore : le village doit être ATTEIGNABLE depuis la plaine, pas
## enfermé. On lâche un corps au-dessus de la place et il doit se poser.
func test_the_village_square_is_reachable_from_the_plain() -> void:
	var village: RiversideVillage = await _open()
	# Sol de la plaine sud sous le village : le test porte sur le fait que
	# rien du bourg ne bouche l'accès, pas sur le terrain lui-même.
	var ground: StaticBody3D = StaticBody3D.new()
	ground.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	shape.shape = box
	ground.add_child(shape)
	ground.position = RiversideVillage.SITE + Vector3(0, -0.5, 0)
	_tree().root.add_child(ground)

	var body: CharacterBody3D = CharacterBody3D.new()
	var shape2: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	shape2.shape = capsule
	body.add_child(shape2)
	_tree().root.add_child(body)
	# Sur la place, entre l'auberge et le marché.
	body.global_position = RiversideVillage.SITE + Vector3(4, 2.0, 8)
	for i: int in range(90):
		body.velocity.y -= 24.0 * (1.0 / 60.0)
		body.move_and_slide()
		await _tree().physics_frame
		if body.is_on_floor():
			break
	check(body.is_on_floor(), "on peut se tenir sur la place du village")

	for node: Node in [body, ground]:
		node.get_parent().remove_child(node)
		node.queue_free()
	await _close(village)


## Le village est-il DANS le monde jouable, ou seulement dans sa scène de
## test ? Un lieu construit mais jamais posé ne compte pas.
func test_the_village_stands_in_the_playable_valley() -> void:
	var valley: ValleyWorld = (load("res://scenes/world/valley/ValleyWorld.tscn")
		as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(8)
	var village: Node = valley.get_node_or_null("RiversideVillage")
	check_not_null(village, "la vallée porte le village de la rivière")
	check(valley.discoveries.is_registered(&"valley.poi.riverside_village.01"),
		"…et il s'est déclaré au journal de la partie")
	check_equal(valley.discoveries.discovered_count(), 0,
		"rien n'est découvert avant d'y être allé")

	# Découvrir, puis vérifier que l'état part bien dans la sauvegarde.
	valley.discoveries.visit(&"valley.poi.riverside_village.01")
	var state: Dictionary = valley.discoveries.collect_state()
	check_equal((state["discovered"] as Array).size(), 1,
		"la découverte entre dans l'instantané de la vallée")

	valley.get_parent().remove_child(valley)
	valley.queue_free()
	await _settle(2)


## LE test du monde ouvert : les 31 lieux existent-ils DANS LA PARTIE ?
##
## Chaque famille a ses propres tests, qui montent sa classe isolément. Ils
## prouvent que les lieux sont bâtissables — pas qu'ils sont posés. Un lieu
## qui n'est jamais instancié n'existe que dans son test, et le joueur ne le
## verra jamais. C'est l'écart que ce test ferme.
func test_the_whole_open_world_is_declared_in_the_playable_valley() -> void:
	var valley: ValleyWorld = (load("res://scenes/world/valley/ValleyWorld.tscn")
		as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)

	for family: String in ["RiversideVillage", "Hamlets", "ValleyRuins",
			"ValleyRelics", "ValleyCaves", "ValleyUndergrounds",
			"ValleyLandmarks", "ValleyWonders", "ValleyTerritories"]:
		check_not_null(valley.get_node_or_null(family),
			"la vallée porte « %s »" % family)

	var ids: Array[StringName] = valley.discoveries.registered_ids()
	check(ids.size() >= 31,
		"%d lieux déclarés au journal de la partie (cible : 31)" % ids.size())
	# Unicité : deux lieux qui partagent un identifiant se marqueraient
	# découverts l'un l'autre, et le journal en refuserait un en silence.
	var seen: Dictionary = {}
	for poi_id: StringName in ids:
		seen[poi_id] = true
	check_equal(seen.size(), ids.size(),
		"les %d identifiants sont TOUS distincts" % ids.size())
	check_equal(valley.discoveries.discovered_count(), 0,
		"rien n'est découvert avant d'y être allé")
	# Les régions permettent une carte : plusieurs, pas une seule fourre-tout.
	check(valley.discoveries.by_region().size() >= 5,
		"%d régions distinctes" % valley.discoveries.by_region().size())

	valley.get_parent().remove_child(valley)
	valley.queue_free()
	await _settle(2)


## §3 : « chaque point d'intérêt doit offrir au moins un élément » — coffre,
## arme, ingrédients… Sans cela un lieu n'est qu'un nom sur une carte.
##
## Le test NOMME les lieux sans récompense au lieu de se contenter d'un
## total : un manque tu est un manque qui reste.
func test_the_places_hand_out_real_rewards() -> void:
	var valley: ValleyWorld = (load("res://scenes/world/valley/ValleyWorld.tscn")
		as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)

	check_not_null(valley.rewards, "la vallée pose des récompenses")
	var placed: int = valley.rewards.placed_count()
	var skipped: Array[StringName] = valley.rewards.skipped_places()
	check(placed >= 31,
		"%d récompense(s) posée(s) — une par lieu, §3 tenu" % placed)
	var names: Array[String] = []
	for poi_id: StringName in skipped:
		names.append(String(poi_id))
	check(skipped.is_empty(),
		"aucun lieu laissé sans récompense — manquants : %s" % ", ".join(names))

	# Les identifiants de coffre dérivent de ceux des lieux : uniques par
	# construction, et distincts des coffres déjà posés dans la vallée.
	var ids: Dictionary = {}
	for node: Node in valley.find_children("*", "Chest", true, false):
		var chest_id: StringName = (node as Chest).chest_id
		check(not ids.has(chest_id), "coffre %s unique" % chest_id)
		ids[chest_id] = true
	# La variété est vérifiée en détail par `test_reward_anchors.gd` ; ici on
	# refuse seulement le retour en arrière : 31 coffres identiques.
	check(ids.size() < placed,
		"%d coffres pour %d récompenses — toutes ne sont pas des coffres"
		% [ids.size(), placed])

	valley.get_parent().remove_child(valley)
	valley.queue_free()
	await _settle(2)
