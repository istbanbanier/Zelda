## Le point d'intérêt DANS le monde (ordre d'extension §3).
##
## Le registre est testé à part, en pur calcul. Ici on vérifie ce que le
## registre ne peut pas savoir : qu'un corps qui traverse réellement le
## volume déclenche la découverte, qu'un ennemi ne la déclenche PAS, et
## qu'après un rechargement le même passage ne redonne rien.
extends GateTestCase


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


## Un corps physique dans le groupe `player`, sans tout le contrôleur : ce
## test porte sur le volume de découverte, pas sur la locomotion.
func _walker() -> CharacterBody3D:
	var body: CharacterBody3D = CharacterBody3D.new()
	body.add_to_group(&"player")
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	body.add_child(shape)
	return body


func _place(poi_id: StringName, display_name: String) -> PointOfInterest:
	var poi: PointOfInterest = PointOfInterest.new()
	poi.poi_id = poi_id
	poi.display_name = display_name
	poi.region = &"riviere"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(8, 6, 8)
	shape.shape = box
	poi.add_child(shape)
	return poi


func test_walking_into_a_place_discovers_it_once() -> void:
	var world: Node3D = Node3D.new()
	_tree().root.add_child(world)
	var journal: DiscoveryLog = DiscoveryLog.new()
	var poi: PointOfInterest = _place(&"valley.poi.riverside_village.01",
		"Village de la rivière")
	world.add_child(poi)
	poi.bind(journal)
	check(poi.is_bound(), "le lieu est relié au journal")
	check(journal.is_registered(&"valley.poi.riverside_village.01"),
		"…et s'y est déclaré tout seul")

	# Les lambdas capturent par VALEUR : un tableau reçoit le résultat.
	var announced: Array = []
	poi.first_visit.connect(func(_id: StringName, display_name: String) -> void:
		announced.append(display_name))

	var walker: CharacterBody3D = _walker()
	walker.position = Vector3(0, 0, 30)
	world.add_child(walker)
	await _settle(2)
	check_equal(announced.size(), 0, "à 30 m, rien n'est découvert")

	walker.position = Vector3.ZERO
	await _settle(4)
	check_equal(announced.size(), 1, "entrer dans le lieu le découvre")
	check_equal(String(announced[0] as String), "Village de la rivière",
		"le nom affiché est celui du lieu")

	# Ressortir puis revenir : le nom peut se réafficher, la découverte non.
	walker.position = Vector3(0, 0, 30)
	await _settle(4)
	walker.position = Vector3.ZERO
	await _settle(4)
	check_equal(announced.size(), 1, "revenir ne redéclenche PAS la découverte")

	world.get_parent().remove_child(world)
	world.queue_free()
	await _settle(2)


func test_an_enemy_walking_through_discovers_nothing() -> void:
	var world: Node3D = Node3D.new()
	_tree().root.add_child(world)
	var journal: DiscoveryLog = DiscoveryLog.new()
	var poi: PointOfInterest = _place(&"valley.poi.watchtower_ruin.01",
		"Tour de guet effondrée")
	world.add_child(poi)
	poi.bind(journal)

	var raider: CharacterBody3D = CharacterBody3D.new()
	raider.add_to_group(&"enemies")
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.6
	shape.shape = capsule
	raider.add_child(shape)
	world.add_child(raider)
	raider.position = Vector3.ZERO
	await _settle(4)

	check_equal(journal.discovered_count(), 0,
		"un ennemi qui traverse le lieu ne le découvre pas")

	world.get_parent().remove_child(world)
	world.queue_free()
	await _settle(2)


## Le scénario complet de l'ordre : découvrir, sauvegarder, recharger,
## repasser — et ne RIEN recevoir la seconde fois.
func test_the_place_stays_discovered_across_a_save_and_reload() -> void:
	var world: Node3D = Node3D.new()
	_tree().root.add_child(world)
	var journal: DiscoveryLog = DiscoveryLog.new()
	var poi: PointOfInterest = _place(&"valley.poi.waterfall_cave.01",
		"Grotte de la cascade")
	world.add_child(poi)
	poi.bind(journal)
	var walker: CharacterBody3D = _walker()
	world.add_child(walker)
	walker.position = Vector3.ZERO
	await _settle(4)
	check(journal.is_discovered(&"valley.poi.waterfall_cave.01"),
		"la grotte est découverte")
	var saved: Dictionary = journal.collect_state()

	# Nouvelle partie : monde reconstruit, journal neuf, état rechargé.
	world.get_parent().remove_child(world)
	world.queue_free()
	await _settle(2)

	var world2: Node3D = Node3D.new()
	_tree().root.add_child(world2)
	var journal2: DiscoveryLog = DiscoveryLog.new()
	var poi2: PointOfInterest = _place(&"valley.poi.waterfall_cave.01",
		"Grotte de la cascade")
	world2.add_child(poi2)
	poi2.bind(journal2)
	journal2.apply_state(saved)
	var rewards: Array = []
	poi2.first_visit.connect(func(_id: StringName, _n: String) -> void:
		rewards.append(1))

	var walker2: CharacterBody3D = _walker()
	world2.add_child(walker2)
	walker2.position = Vector3.ZERO
	await _settle(4)
	check_equal(rewards.size(), 0,
		"après rechargement, repasser dans la grotte ne redonne RIEN")
	check(journal2.is_discovered(&"valley.poi.waterfall_cave.01"),
		"…et elle reste bien marquée découverte")

	world2.get_parent().remove_child(world2)
	world2.queue_free()
	await _settle(2)
