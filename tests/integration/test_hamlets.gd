## HAMEAUX DE LA VALLÉE (ordre d'extension §2, et §1 pour la règle dure).
##
## Deux points durs, pas un seul :
##
##   1. §1 — une porte visible ouvre sur un VRAI intérieur, ou elle est
##      visiblement condamnée. Un décor de façades passerait n'importe quel
##      test de comptage. On fait donc entrer un corps physique dans la cabane
##      des bûcherons puis dans le corps de garde, et on vérifie qu'il tient
##      debout DEDANS, sur un plancher, entouré de murs. Réciproquement, on
##      pousse un corps contre la galerie de mine : la grille doit l'arrêter,
##      sinon la « condamnation » n'est qu'une image.
##   2. §2 — deux hameaux, pas deux copies. Chacun porte ses propres quartiers
##      et son propre identifiant §19.3 ; le journal des découvertes doit en
##      compter DEUX, distincts, et distincts de celui du village.
extends GateTestCase


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open() -> Hamlets:
	var hamlets: Hamlets = Hamlets.new()
	_tree().root.add_child(hamlets)
	await _settle(6)
	return hamlets


func _close(hamlets: Node) -> void:
	hamlets.get_parent().remove_child(hamlets)
	hamlets.queue_free()
	await _settle(2)


## Un corps d'essai à taille humaine, déjà dans l'arbre.
func _make_body() -> CharacterBody3D:
	var body: CharacterBody3D = CharacterBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	shape.shape = capsule
	body.add_child(shape)
	_tree().root.add_child(body)
	return body


## Un sol d'appoint : le terrain de la vallée n'est pas chargé ici, et le test
## ne porte pas sur lui.
func _make_ground(centre: Vector3) -> StaticBody3D:
	var ground: StaticBody3D = StaticBody3D.new()
	ground.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	shape.shape = box
	ground.add_child(shape)
	ground.position = centre + Vector3(0, -0.5, 0)
	_tree().root.add_child(ground)
	return ground


func _drop_until_floor(body: CharacterBody3D) -> void:
	for i: int in range(90):
		body.velocity.y -= 24.0 * (1.0 / 60.0)
		body.move_and_slide()
		await _tree().physics_frame
		if body.is_on_floor():
			break


func _discard(nodes: Array[Node]) -> void:
	for node: Node in nodes:
		node.get_parent().remove_child(node)
		node.queue_free()
	await _settle(2)


## §2 : deux hameaux réellement bâtis, chacun avec ses quartiers nommés.
func test_the_two_hamlets_are_built_from_the_promoted_kit() -> void:
	var hamlets: Hamlets = await _open()
	check(hamlets.piece_count() >= 80,
		"%d pièces posées pour les deux hameaux — ce ne sont pas des maquettes"
		% hamlets.piece_count())
	check_not_null(hamlets.get_node_or_null("HameauDesBucherons"),
		"le hameau des bûcherons existe")
	check_not_null(hamlets.get_node_or_null("PosteMinier"),
		"le poste minier existe")
	for quarter: String in ["CabaneDesBucherons", "Scierie", "PileDeTroncs",
			"Charretterie", "Lisiere"]:
		check_not_null(
			hamlets.get_node_or_null("HameauDesBucherons/%s" % quarter),
			"les bûcherons ont leur quartier « %s » (§2)" % quarter)
	for quarter: String in ["CorpsDeGarde", "GalerieDeMine", "Sechoir",
			"CourDeMinerai", "Palissade"]:
		check_not_null(hamlets.get_node_or_null("PosteMinier/%s" % quarter),
			"les mineurs ont leur quartier « %s » (§2)" % quarter)
	check(hamlets.logging_piece_count() >= 30
			and hamlets.mining_piece_count() >= 30,
		"aucun des deux n'est un figurant (bûcherons %d, mineurs %d)"
		% [hamlets.logging_piece_count(), hamlets.mining_piece_count()])
	await _close(hamlets)


## §2 et §19.3 : chaque hameau se DÉCLARE, sous SON identifiant.
func test_each_hamlet_declares_itself_with_its_own_identifier() -> void:
	var hamlets: Hamlets = await _open()
	var journal: DiscoveryLog = DiscoveryLog.new()
	check_not_null(hamlets.logging_poi,
		"le hameau des bûcherons porte un point d'intérêt")
	check_not_null(hamlets.mining_poi,
		"le poste minier porte un point d'intérêt")
	check_equal(hamlets.pois().size(), 2, "deux lieux déclarables")
	for poi: PointOfInterest in hamlets.pois():
		poi.bind(journal)

	check(journal.is_registered(Hamlets.LOGGING_POI_ID),
		"…les bûcherons sont déclarés sous %s" % Hamlets.LOGGING_POI_ID)
	check(journal.is_registered(Hamlets.MINING_POI_ID),
		"…les mineurs sont déclarés sous %s" % Hamlets.MINING_POI_ID)
	check_equal(journal.registered_count(), 2,
		"deux identifiants DISTINCTS entrent au journal")
	check(Hamlets.LOGGING_POI_ID != Hamlets.MINING_POI_ID
			and Hamlets.LOGGING_POI_ID != &"valley.poi.riverside_village.01"
			and Hamlets.MINING_POI_ID != &"valley.poi.riverside_village.01",
		"…et aucun ne réutilise l'identifiant du village de la rivière")
	check_equal(journal.display_name_of(Hamlets.LOGGING_POI_ID),
		"Hameau des bûcherons", "nom affiché des bûcherons")
	check_equal(journal.display_name_of(Hamlets.MINING_POI_ID),
		"Poste minier de la falaise", "nom affiché des mineurs")
	check(String(journal.region_of(Hamlets.LOGGING_POI_ID)) != ""
			and journal.region_of(Hamlets.LOGGING_POI_ID)
				!= journal.region_of(Hamlets.MINING_POI_ID),
		"…et chacun appartient à sa propre région")
	check_equal(journal.discovered_count(), 0,
		"déclarer n'est pas découvrir")
	await _close(hamlets)


## LE test de §1, côté bûcherons : la cabane est CREUSE et on y entre.
##
## Le corps est posé au-dessus du plancher intérieur ; s'il tombe, il n'y a pas
## de sol et l'« intérieur » est un mensonge. On le pousse ensuite contre les
## murs PLEINS — jamais vers la porte, à l'ouest, qui doit rester franchissable.
func test_the_loggers_cabin_has_a_real_interior_you_can_stand_in() -> void:
	var hamlets: Hamlets = await _open()
	var cabin: Node3D = hamlets.get_node(
		"HameauDesBucherons/CabaneDesBucherons") as Node3D
	var body: CharacterBody3D = _make_body()
	body.global_position = cabin.global_position + Vector3(0, 1.4, 0)
	await _drop_until_floor(body)
	check(body.is_on_floor(),
		"le corps se pose sur un PLANCHER dans la cabane (y = %.2f)"
		% body.global_position.y)
	check(body.global_position.y > hamlets.cabin_floor_y - 0.6,
		"…et non au fond du monde (plancher attendu y = %.2f)"
		% hamlets.cabin_floor_y)

	# Porte à l'OUEST : on pousse vers l'est, le nord et le sud.
	var inside: Vector3 = body.global_position
	for direction: Vector3 in [Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		body.global_position = inside
		await _settle(1)
		for i: int in range(40):
			body.velocity = direction * 6.0
			body.velocity.y = -2.0
			body.move_and_slide()
			await _tree().physics_frame
		var drift: Vector3 = body.global_position - cabin.global_position
		check(absf(drift.x) < 4.2 and absf(drift.z) < 4.2,
			"poussé vers %v, le corps reste dans la pièce (écart %.1f, %.1f)"
			% [direction, drift.x, drift.z])

	var trash: Array[Node] = []
	trash.append(body)
	await _discard(trash)
	await _close(hamlets)


## §1, côté mineurs : le corps de garde aussi est un VOLUME, pas une façade.
## Sa porte est à l'EST : on pousse vers l'ouest, le nord et le sud.
func test_the_mining_guardhouse_has_a_real_interior_you_can_stand_in() -> void:
	var hamlets: Hamlets = await _open()
	var house: Node3D = hamlets.get_node("PosteMinier/CorpsDeGarde") as Node3D
	var body: CharacterBody3D = _make_body()
	body.global_position = house.global_position + Vector3(0, 1.4, 0)
	await _drop_until_floor(body)
	check(body.is_on_floor(),
		"le corps se pose sur un PLANCHER dans le corps de garde (y = %.2f)"
		% body.global_position.y)
	check(body.global_position.y > hamlets.guardhouse_floor_y - 0.6,
		"…et non au fond du monde (plancher attendu y = %.2f)"
		% hamlets.guardhouse_floor_y)

	var inside: Vector3 = body.global_position
	for direction: Vector3 in [Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		body.global_position = inside
		await _settle(1)
		for i: int in range(40):
			body.velocity = direction * 6.0
			body.velocity.y = -2.0
			body.move_and_slide()
			await _tree().physics_frame
		var drift: Vector3 = body.global_position - house.global_position
		check(absf(drift.x) < 4.2 and absf(drift.z) < 4.2,
			"poussé vers %v, le corps reste dans la pièce (écart %.1f, %.1f)"
			% [direction, drift.x, drift.z])

	var trash: Array[Node] = []
	trash.append(body)
	await _discard(trash)
	await _close(hamlets)


## §1 dans l'autre sens : ce qui est visiblement condamné doit l'être POUR DE
## BON. On pousse un corps vers la bouche de la galerie ; la grille l'arrête.
func test_the_barred_gallery_is_really_closed() -> void:
	var hamlets: Hamlets = await _open()
	var gallery: Node3D = hamlets.get_node(
		"PosteMinier/GalerieDeMine") as Node3D
	var ground: StaticBody3D = _make_ground(Hamlets.SITE_MINING)
	var body: CharacterBody3D = _make_body()
	# Devant la bouche, à quatre mètres, à hauteur de sol.
	body.global_position = gallery.global_position + Vector3(4.0, 1.0, 0)
	await _drop_until_floor(body)
	for i: int in range(60):
		body.velocity = Vector3.LEFT * 6.0   # vers la falaise, plein ouest
		body.velocity.y = -2.0
		body.move_and_slide()
		await _tree().physics_frame
	check(body.global_position.x > gallery.global_position.x - 0.4,
		"la grille arrête le corps devant la galerie (x = %.2f, bouche à %.2f)"
		% [body.global_position.x, gallery.global_position.x])

	var trash: Array[Node] = []
	trash.append(body)
	trash.append(ground)
	await _discard(trash)
	await _close(hamlets)


## §1 : un hameau doit être ATTEIGNABLE, pas enfermé. On lâche un corps dans
## chaque cour, entre les bâtiments : il doit se poser sans rester coincé.
func test_both_yards_are_walkable() -> void:
	var hamlets: Hamlets = await _open()
	var spots: Array[Vector3] = [
		Hamlets.SITE_LOGGING + Vector3(6.0, 2.0, 4.0),    # entre cabane et scierie
		Hamlets.SITE_MINING + Vector3(8.0, 2.0, -6.0),    # cour, dans l'axe du portail
	]
	var names: Array[String] = ["hameau des bûcherons", "poste minier"]
	for index: int in range(spots.size()):
		var ground: StaticBody3D = _make_ground(spots[index]
			- Vector3(0, 2.0, 0))
		var body: CharacterBody3D = _make_body()
		body.global_position = spots[index]
		await _drop_until_floor(body)
		check(body.is_on_floor(),
			"on peut se tenir dans la cour du %s" % names[index])
		var trash: Array[Node] = []
		trash.append(body)
		trash.append(ground)
		await _discard(trash)
	await _close(hamlets)


## §2 : trois lieux, trois endroits. Deux hameaux posés l'un sur l'autre — ou
## sur le village — ne feraient qu'un seul lieu confus.
func test_the_hamlets_stand_apart_from_each_other_and_the_village() -> void:
	var hamlets: Hamlets = await _open()
	var logging_flat: Vector2 = Vector2(Hamlets.SITE_LOGGING.x,
		Hamlets.SITE_LOGGING.z)
	var mining_flat: Vector2 = Vector2(Hamlets.SITE_MINING.x,
		Hamlets.SITE_MINING.z)
	var village_flat: Vector2 = Vector2(RiversideVillage.SITE.x,
		RiversideVillage.SITE.z)
	check(logging_flat.distance_to(mining_flat) > 60.0,
		"les deux hameaux sont bien séparés (%.0f m)"
		% logging_flat.distance_to(mining_flat))
	check(logging_flat.distance_to(village_flat) > 40.0,
		"les bûcherons ne chevauchent pas le village (%.0f m)"
		% logging_flat.distance_to(village_flat))
	check(mining_flat.distance_to(village_flat) > 40.0,
		"les mineurs ne chevauchent pas le village (%.0f m)"
		% mining_flat.distance_to(village_flat))
	# Sur la plaine, pas dans la rivière (lit à z = 10) ni hors des bornes.
	for site: Vector3 in [Hamlets.SITE_LOGGING, Hamlets.SITE_MINING]:
		check(absf(site.z - 10.0) > 20.0,
			"le site %v se tient loin du lit de rivière" % site)
		check(absf(site.x) < 230.0 and absf(site.z) < 230.0,
			"le site %v reste dans les bornes du monde" % site)
	await _close(hamlets)
