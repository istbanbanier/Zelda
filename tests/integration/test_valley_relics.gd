## VESTIGES DE LA VALLÉE (ordre d'extension §2, et §1 pour la règle dure).
##
## Trois points durs, pas un seul :
##
##   1. §2 — QUATRE ruines réellement bâties, chacune avec ses ensembles
##      nommés, et quatre identifiants §19.3 DISTINCTS entre eux et distincts
##      des quinze déjà déclarés ailleurs dans la vallée. Un doublon ferait
##      qu'un lieu se marquerait découvert à la place d'un autre.
##   2. Chaque vestige doit être POSÉ à l'écart : un lieu qui chevauche un
##      village ou un camp n'ajoute rien au monde, il l'abîme. La séparation se
##      mesure, elle ne se promet pas.
##   3. §1 — ce qui paraît praticable doit l'être, et ce qui paraît fermé doit
##      fermer. On fait donc monter un corps physique sur la plateforme de
##      l'observatoire puis sur le chemin de ronde de la courtine, et on le
##      pousse à travers la brèche — puis contre le tronçon intact, qui doit
##      l'arrêter. Un comptage de pièces ne prouverait rien de tout cela.
extends GateTestCase


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open() -> ValleyRelics:
	var relics: ValleyRelics = ValleyRelics.new()
	_tree().root.add_child(relics)
	await _settle(6)
	return relics


func _close(relics: Node) -> void:
	relics.get_parent().remove_child(relics)
	relics.queue_free()
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


## Un sol d'appoint : le terrain de la vallée n'est pas chargé ici, et les
## tests de traversée ne portent pas sur lui.
func _make_ground(centre: Vector3) -> StaticBody3D:
	var ground: StaticBody3D = StaticBody3D.new()
	ground.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(140, 1, 140)
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


func _push(body: CharacterBody3D, direction: Vector3, ticks: int) -> void:
	for i: int in range(ticks):
		body.velocity = direction * 6.0
		body.velocity.y = -2.0
		body.move_and_slide()
		await _tree().physics_frame


func _discard(nodes: Array[Node]) -> void:
	for node: Node in nodes:
		node.get_parent().remove_child(node)
		node.queue_free()
	await _settle(2)


## §2 : quatre vestiges bâtis du kit promu, chacun avec ses ensembles nommés.
func test_the_four_relics_are_built_from_the_promoted_kit() -> void:
	var relics: ValleyRelics = await _open()
	check(relics.piece_count() >= 200,
		"%d pièces posées pour les quatre vestiges — ce ne sont pas des maquettes"
		% relics.piece_count())
	for node_name: String in ValleyRelics.RELIC_NODES:
		check_not_null(relics.relic(node_name),
			"le vestige « %s » existe (§2)" % node_name)
	var parts: Dictionary = {
		"ObservatoireEnRuine": ["Tambour", "Plateforme", "Escalier",
			"InstrumentBrise"],
		"CimetiereDuTertre": ["Tombeau", "Rangees", "Enclos"],
		"FortificationAncienne": ["Courtine", "CheminDeRonde", "Escalier",
			"Breche", "TourDAngle", "PorteDisparue"],
		"SanctuaireForestier": ["Edifice", "Autel", "Sentier", "Cairns",
			"Clairiere"],
	}
	for relic_name: String in parts:
		for part: String in parts[relic_name] as Array:
			check_not_null(
				relics.get_node_or_null("%s/%s" % [relic_name, part]),
				"« %s » porte son ensemble « %s »" % [relic_name, part])
	await _close(relics)


## §2 et §19.3 : chaque vestige se DÉCLARE, sous SON identifiant.
func test_each_relic_declares_itself_with_its_own_identifier() -> void:
	var relics: ValleyRelics = await _open()
	var journal: DiscoveryLog = DiscoveryLog.new()
	# Six depuis P2-4d : pont magnétique puis bassin conducteur.
	check_equal(relics.pois.size(), 6, "six lieux déclarables")
	check_equal(relics.bind_all(journal), 6, "les six se lient au journal")
	check_equal(journal.registered_count(), 6,
		"six identifiants DISTINCTS entrent au journal")

	var expected: Dictionary = {
		ValleyRelics.POI_OBSERVATORY: "Observatoire en ruine",
		ValleyRelics.POI_CEMETERY: "Cimetière du tertre",
		ValleyRelics.POI_RAMPART: "Courtine effondrée",
		ValleyRelics.POI_SHRINE: "Sanctuaire forestier",
		ValleyRelics.POI_BRIDGE: "Pont magnétique",
		ValleyRelics.POI_BASIN: "Bassin conducteur",
	}
	for poi_id: StringName in expected:
		check(journal.is_registered(poi_id),
			"…déclaré sous %s" % poi_id)
		check_equal(journal.display_name_of(poi_id),
			String(expected[poi_id]), "nom affiché de %s" % poi_id)
		check(String(journal.region_of(poi_id)) != "",
			"…et %s appartient à une région" % poi_id)

	# Aucun des quatre ne réutilise un identifiant déjà posé dans la vallée.
	var taken: Array[StringName] = [
		&"valley.poi.riverside_village.01", &"valley.poi.logging_hamlet.01",
		&"valley.poi.mining_post.01", &"valley.poi.abandoned_farm.01",
		&"valley.poi.ancient_aqueduct.01", &"valley.poi.storm_caravan.01",
		&"valley.poi.watchtower_ruin.01", &"valley.poi.abandoned_mine.01",
		&"valley.poi.hollow_crypt.01", &"valley.poi.waterfall_cave.01",
		&"valley.poi.ancient_tree.01", &"valley.poi.flower_field.01",
		&"valley.poi.overlook_summit.01", &"valley.poi.stone_bridge.01",
		&"valley.poi.turquoise_spring.01",
	]
	var clashes: Array[String] = []
	for poi_id: StringName in relics.poi_ids():
		if taken.has(poi_id):
			clashes.append(String(poi_id))
	check(clashes.is_empty(),
		"aucun identifiant déjà pris ailleurs (%s)" % ", ".join(clashes))
	check_equal(journal.discovered_count(), 0, "déclarer n'est pas découvrir")
	await _close(relics)


## Un vestige posé sur un lieu existant n'ajoute rien au monde : il l'abîme.
## La séparation se MESURE, sur le plan horizontal (le relief ne sépare pas).
func test_the_relics_stand_clear_of_the_places_already_settled() -> void:
	var relics: ValleyRelics = await _open()
	# Lieux déjà posés dans la vallée, en coordonnées monde. Recopiés ici
	# volontairement : le test doit échouer si un vestige DÉMÉNAGE sur eux,
	# pas suivre silencieusement une constante déplacée ailleurs.
	var settled: Dictionary = {
		"village de la rivière": Vector3(-70, 2, 36),
		"hameau des bûcherons": Vector3(110, 2, 40),
		"poste minier": Vector3(-68, 2, 86),
		"camp ennemi": Vector3(45, 6, 65),
		"pylône": Vector3(115, 18, -25),
		"donjon": Vector3(0, 34, -210),
		"crête de départ": Vector3(0, 24, 170),
		"arbre ancien": Vector3(-96, 2, -62),
		"source turquoise": Vector3(-72, 2, 78),
		"champ de fleurs": Vector3(-34, 2, 112),
		"pont de pierre": Vector3(-14, 0, 10),
		"belvédère": Vector3(168, 0, 40),
		"grotte de la cascade": Vector3(-118, 2, 26),
		"mine abandonnée": Vector3(160, 2, -70),
		"crypte oubliée": Vector3(-60, 2, -90),
		"tour de guet": Vector3(-128, 14, 82),
		"aqueduc ancien": Vector3(-12, 2, 10),
		"ferme abandonnée": Vector3(-16, 2, 78),
		"caravane foudroyée": Vector3(-38, 2, -120),
	}
	var places: Array[Vector3] = relics.sites()
	for index: int in range(places.size()):
		var here: Vector2 = Vector2(places[index].x, places[index].z)
		var closest: float = 1.0e9
		var culprit: String = ""
		for label: String in settled:
			var other: Vector3 = settled[label] as Vector3
			var span: float = here.distance_to(Vector2(other.x, other.z))
			if span < closest:
				closest = span
				culprit = label
		check(closest > 30.0,
			"« %s » reste à l'écart : %.1f m du lieu le plus proche (%s)"
			% [ValleyRelics.RELIC_NODES[index], closest, culprit])

	# …et les quatre ne se marchent pas dessus non plus.
	for a: int in range(places.size()):
		for b: int in range(a + 1, places.size()):
			var span: float = Vector2(places[a].x, places[a].z).distance_to(
				Vector2(places[b].x, places[b].z))
			check(span > 30.0,
				"« %s » et « %s » sont séparés (%.1f m)"
				% [ValleyRelics.RELIC_NODES[a], ValleyRelics.RELIC_NODES[b],
					span])
	await _close(relics)


## §1, premier point dur : l'escalier de l'observatoire mène à une PLATEFORME.
## Le corps est lâché au-dessus du belvédère ; s'il tombe, la plateforme est
## une image et le vestige ment.
func test_the_observatory_platform_carries_a_body() -> void:
	var relics: ValleyRelics = await _open()
	var lookout: Marker3D = relics.get_node_or_null(
		"ObservatoireEnRuine/Belvedere") as Marker3D
	check_not_null(lookout, "l'observatoire porte son repère de belvédère")
	if lookout == null:
		await _close(relics)
		return
	var body: CharacterBody3D = _make_body()
	body.global_position = lookout.global_position + Vector3(0, 1.2, 0)
	await _drop_until_floor(body)
	check(body.is_on_floor(),
		"le corps se pose sur la plateforme (y = %.2f)"
		% body.global_position.y)
	check(body.global_position.y > relics.observatory_platform_y - 0.4,
		"…et non six mètres plus bas, dans la salle basse (plateforme y = %.2f)"
		% relics.observatory_platform_y)

	# La plateforme est une SURFACE, pas une dalle isolée : on y marche. Vers
	# le nord, du côté ouvert — sans jamais s'approcher du bord sud.
	var start: Vector3 = body.global_position
	await _push(body, Vector3(0, 0, -1), 18)
	check(body.is_on_floor(),
		"…et l'on y marche sans tomber (parcouru %.1f m)"
		% start.distance_to(body.global_position))

	var trash: Array[Node] = []
	trash.append(body)
	await _discard(trash)
	await _close(relics)


## §1, deuxième point dur : le chemin de ronde est PRATICABLE. Ce n'est pas un
## décor posé sur la courtine — on s'y tient debout et on l'arpente.
func test_the_rampart_wall_walk_is_walkable() -> void:
	var relics: ValleyRelics = await _open()
	var post: Marker3D = relics.get_node_or_null(
		"FortificationAncienne/PosteDeGuet") as Marker3D
	check_not_null(post, "la courtine porte son repère de poste de guet")
	if post == null:
		await _close(relics)
		return
	var body: CharacterBody3D = _make_body()
	body.global_position = post.global_position + Vector3(0, 1.2, 0)
	await _drop_until_floor(body)
	check(body.is_on_floor(),
		"le corps se tient sur le chemin de ronde (y = %.2f)"
		% body.global_position.y)
	check(body.global_position.y > relics.rampart_walk_y - 0.4,
		"…à la hauteur du chemin, pas dans la cour (chemin y = %.2f)"
		% relics.rampart_walk_y)

	# On l'arpente vers le nord : le dallage est continu jusqu'à la tour.
	var start: Vector3 = body.global_position
	await _push(body, Vector3(0, 0, 1), 25)
	var walked: float = absf(body.global_position.z - start.z)
	check(body.is_on_floor() and walked > 1.2,
		"…et on l'arpente sur %.1f m sans trou (encore au sol : %s)"
		% [walked, body.is_on_floor()])
	check(body.global_position.y > relics.rampart_walk_y - 0.4,
		"…toujours à la hauteur du chemin après la marche (y = %.2f)"
		% body.global_position.y)

	var trash: Array[Node] = []
	trash.append(body)
	await _discard(trash)
	await _close(relics)


## §1, troisième point dur, dans les deux sens : la brèche est OUVERTE — on la
## traverse — et le tronçon intact ARRÊTE. Une courtine qu'on traverse partout
## n'est pas une courtine ; une brèche qu'on ne franchit pas n'est qu'un dessin.
func test_the_breach_is_open_and_the_curtain_still_blocks() -> void:
	var relics: ValleyRelics = await _open()
	var fort: Node3D = relics.relic("FortificationAncienne")
	check_not_null(fort, "la fortification est bâtie")
	if fort == null:
		await _close(relics)
		return
	var ground: StaticBody3D = _make_ground(fort.global_position)

	# 1. Par la brèche, plein est : on passe de l'autre côté.
	var crosser: CharacterBody3D = _make_body()
	crosser.global_position = fort.global_position + Vector3(-6.0, 1.2, 0.0)
	await _drop_until_floor(crosser)
	await _push(crosser, Vector3(1, 0, 0), 120)
	var crossed: float = crosser.global_position.x - fort.global_position.x
	check(crossed > 2.0,
		"la brèche laisse passer : le corps a franchi la courtine (x local %.1f)"
		% crossed)

	# 2. Contre le tronçon nord, intact : le mur tient.
	var blocked: CharacterBody3D = _make_body()
	blocked.global_position = fort.global_position + Vector3(-6.0, 1.2, 7.0)
	await _drop_until_floor(blocked)
	await _push(blocked, Vector3(1, 0, 0), 120)
	var reached: float = blocked.global_position.x - fort.global_position.x
	check(reached < -1.0,
		"…et le tronçon intact arrête (x local %.1f, parement à -1,2)"
		% reached)

	var trash: Array[Node] = []
	trash.append(crosser)
	trash.append(blocked)
	trash.append(ground)
	await _discard(trash)
	await _close(relics)


## Une ruine sans raison d'y aller n'est qu'un obstacle. Chacune expose au
## moins un ancrage nommé : coffre, belvédère, poste de guet ou indice.
func test_each_relic_gives_a_reason_to_come() -> void:
	var relics: ValleyRelics = await _open()
	for node_name: String in ValleyRelics.RELIC_NODES:
		check_not_null(
			relics.get_node_or_null("%s/AncrageRecompense" % node_name),
			"« %s » porte un ancrage de récompense" % node_name)
	var reasons: Array[String] = [
		"ObservatoireEnRuine/Belvedere",          # panorama
		"CimetiereDuTertre/DalleDescellee",       # le tombeau ouvert
		"FortificationAncienne/PosteDeGuet",      # panorama et raccourci
		"SanctuaireForestier/IndiceDuNord",       # l'indice de direction
	]
	for path: String in reasons:
		check_not_null(relics.get_node_or_null(path),
			"…et « %s » donne une seconde raison de venir" % path)

	# Les cotes exposées sont réelles : elles servent aux preuves physiques.
	check(relics.observatory_platform_y > ValleyRelics.SITE_OBSERVATORY.y + 5.0,
		"la plateforme domine son site de %.2f m"
		% (relics.observatory_platform_y - ValleyRelics.SITE_OBSERVATORY.y))
	check(relics.rampart_walk_y > ValleyRelics.SITE_RAMPART.y + 2.5,
		"le chemin de ronde domine la cour de %.2f m"
		% (relics.rampart_walk_y - ValleyRelics.SITE_RAMPART.y))
	check_approx(relics.tomb_floor_y, ValleyRelics.SITE_CEMETERY.y + 0.02, 0.05,
		"le sol du tombeau est à la cote du cimetière")
	check_approx(relics.shrine_floor_y, ValleyRelics.SITE_SHRINE.y + 0.02, 0.05,
		"le sol du sanctuaire est à la cote de la clairière")
	await _close(relics)
