## RUINES DE LA VALLÉE — ce que quatre tas de pierres doivent prouver.
##
## Compter des murs ne prouve rien : un décor de façades passerait le test le
## plus flatteur. Les points durs sont ailleurs.
##
##   - les quatre ruines existent et portent leurs nœuds nommés ;
##   - chacune se DÉCLARE sous un identifiant §19.3 qui n'est celui d'aucune
##     autre — sinon une ruine se marquerait découverte à la place d'une voisine ;
##   - chacune donne une RAISON d'y marcher : belvédère, traversée, abri et
##     ingrédients, arme du garde ;
##   - §1 : la ferme est un VRAI abri. On y fait entrer un corps physique, il
##     tient debout dedans, les murs le retiennent — et la baie, qui PARAÎT
##     ouverte, le laisse effectivement sortir ;
##   - la travée tombée de l'aqueduc porte réellement : on marche dessus ;
##   - aucune ruine ne vient s'asseoir sur le village de la rivière.
extends GateTestCase

## Emprise du bourg autour de `RiversideVillage.SITE` : rayon d'environ 23 m,
## mesuré sur ses quartiers les plus excentrés.
const VILLAGE_RADIUS: float = 23.0
## Emprise généreuse d'une ruine autour de son site — la ferme est la plus
## étalée (clôture, champ et arbres jusqu'à ~20 m).
const RUIN_RADIUS: float = 24.0
## Gravité de §8.2, appliquée à la main : ces corps de test ne passent pas par
## le contrôleur du joueur.
const GRAVITY: float = 24.0
const TICK: float = 1.0 / 60.0
## Capsule du joueur (§6.2).
const BODY_RADIUS: float = 0.35
const BODY_HEIGHT: float = 1.7


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open() -> ValleyRuins:
	var ruins: ValleyRuins = ValleyRuins.new()
	_tree().root.add_child(ruins)
	await _settle(6)
	return ruins


func _close(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.queue_free()
	await _settle(2)


## Une pièce du kit, retrouvée par son asset. `_spawn` suffixe chaque nom d'un
## compteur (`Sword_Bronze_231`) : on cherche donc un motif, pas un nom exact.
func _find_piece(root: Node, asset: String) -> Node:
	return root.find_child(asset + "_*", true, false)


## Un corps de joueur nu, posé dans l'arbre à la position demandée.
func _body(at: Vector3) -> CharacterBody3D:
	var body: CharacterBody3D = CharacterBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	shape.shape = capsule
	body.add_child(shape)
	_tree().root.add_child(body)
	body.global_position = at
	return body


## Laisse tomber, jusqu'au sol ou jusqu'à épuisement des ticks.
func _fall(body: CharacterBody3D, ticks: int) -> void:
	for i: int in range(ticks):
		body.velocity.y -= GRAVITY * TICK
		body.move_and_slide()
		await _tree().physics_frame
		if body.is_on_floor():
			break


## Pousse dans une direction, plaqué au sol : c'est ainsi qu'on démontre qu'un
## mur retient — ou qu'une baie laisse passer.
func _shove(body: CharacterBody3D, direction: Vector3, ticks: int) -> void:
	for i: int in range(ticks):
		body.velocity = direction * 6.0
		body.velocity.y = -2.0
		body.move_and_slide()
		await _tree().physics_frame


func _drop_node(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.queue_free()


## Les quatre ruines sont là, chacune sur son site, avec ses nœuds nommés.
func test_the_four_ruins_stand_on_their_own_sites() -> void:
	var ruins: ValleyRuins = await _open()

	check_equal(ValleyRuins.RUIN_NODES.size(), 4,
		"le script annonce bien QUATRE ruines")
	var sites: Array[Vector3] = [
		ValleyRuins.SITE_WATCHTOWER, ValleyRuins.SITE_AQUEDUCT,
		ValleyRuins.SITE_FARM, ValleyRuins.SITE_CARAVAN,
	]
	for i: int in range(ValleyRuins.RUIN_NODES.size()):
		var node_name: String = ValleyRuins.RUIN_NODES[i]
		var site: Node3D = ruins.ruin(node_name)
		check_not_null(site, "la vallée porte la ruine « %s »" % node_name)
		if site == null:
			continue
		check(site.global_position.distance_to(sites[i]) < 0.01,
			"« %s » est posée sur son site %v (obtenu %v)"
			% [node_name, sites[i], site.global_position])
		check_not_null(site.get_node_or_null("PointDInteret"),
			"« %s » porte son point d'intérêt" % node_name)

	# La ferme est un hameau à elle seule : maison, grange, puits, clôture,
	# champ. Sans ces corps distincts, ce serait un seul bloc de décor.
	var farm: Node3D = ruins.ruin("FermeAbandonnee")
	if farm != null:
		for part: String in ["Maison", "Grange", "Puits", "Cloture", "Champ"]:
			check_not_null(farm.get_node_or_null(part),
				"la ferme a son « %s » (§2)" % part)

	# Plancher : le kit se résout réellement. Le compte réel avoisine 420 ;
	# passer sous 250 signifierait que des assets manquent en silence.
	check(ruins.piece_count() >= 250,
		"%d pièces du kit posées — les quatre ruines ne sont pas des maquettes"
		% ruins.piece_count())

	await _close(ruins)


## §2 et §19.3 : quatre lieux, quatre identifiants DISTINCTS. Un doublon ferait
## qu'une ruine se déclarerait découverte à la place d'une autre.
func test_the_ruins_declare_themselves_with_four_distinct_ids() -> void:
	var ruins: ValleyRuins = await _open()
	var journal: DiscoveryLog = DiscoveryLog.new()

	check_equal(ruins.bind_all(journal), 4,
		"les quatre ruines se lient au journal des découvertes")
	var ids: Array[StringName] = ruins.poi_ids()
	check_equal(ids.size(), 4, "quatre points d'intérêt exposés")
	var unique: Dictionary = {}
	for poi_id: StringName in ids:
		unique[poi_id] = true
	check_equal(unique.size(), 4,
		"…et quatre identifiants DISTINCTS (aucun doublon)")
	check_equal(journal.registered_count(), 4,
		"le journal a bien enregistré quatre lieux")

	var expected: Array[StringName] = [
		ValleyRuins.POI_WATCHTOWER, ValleyRuins.POI_AQUEDUCT,
		ValleyRuins.POI_FARM, ValleyRuins.POI_CARAVAN,
	]
	var names: Array[String] = [
		"Tour de guet effondrée", "Aqueduc ancien", "Ferme abandonnée",
		"Caravane foudroyée",
	]
	var regions: Array[StringName] = [
		&"falaise", &"riviere", &"plaine_sud", &"route_du_donjon",
	]
	for i: int in range(expected.size()):
		check(journal.is_registered(expected[i]),
			"« %s » est déclaré sous %s" % [names[i], expected[i]])
		check_equal(journal.display_name_of(expected[i]), names[i],
			"…avec son nom affiché")
		check_equal(journal.region_of(expected[i]), regions[i],
			"…et sa région")

	check_equal(journal.discovered_count(), 0,
		"rien n'est découvert avant d'y être allé")
	# La preuve que les identifiants ne s'aliasent pas : visiter la ferme ne
	# découvre QUE la ferme.
	journal.visit(ValleyRuins.POI_FARM)
	check_equal(journal.discovered_count(), 1,
		"visiter la ferme ne découvre pas les trois autres ruines")
	check(journal.is_discovered(ValleyRuins.POI_FARM),
		"…et c'est bien la ferme qui est marquée")

	await _close(ruins)


## Une ruine sans raison d'y aller est un décor. Chacune doit offrir quelque
## chose que le joueur ne trouve pas ailleurs.
func test_each_ruin_gives_a_reason_to_walk_there() -> void:
	var ruins: ValleyRuins = await _open()

	# 1. LA TOUR : un belvédère, au-dessus des deux façades restées debout.
	var tower: Node3D = ruins.ruin("TourDeGuet")
	check_not_null(tower, "la tour de guet est là")
	if tower != null:
		var lookout: Marker3D = tower.get_node_or_null("Belvedere") as Marker3D
		check_not_null(lookout, "la tour offre un belvédère")
		check(ruins.watchtower_lookout_y > ValleyRuins.SITE_WATCHTOWER.y + 2.0,
			"…qui domine réellement le site (y = %.2f contre %.2f au sol)"
			% [ruins.watchtower_lookout_y, ValleyRuins.SITE_WATCHTOWER.y])
		if lookout != null:
			check_approx(lookout.global_position.y, ruins.watchtower_lookout_y,
				0.3, "le repère du belvédère est à la cote annoncée")

	# 2. L'AQUEDUC : la travée tombée est une traversée, et l'échafaudage
	# abandonné (établi + pioche) est l'indice qui date la ruine.
	var aqueduct: Node3D = ruins.ruin("Aqueduc")
	check_not_null(aqueduct, "l'aqueduc est là")
	if aqueduct != null:
		var crossing: Marker3D = aqueduct.get_node_or_null(
			"PassageDeLArche") as Marker3D
		check_not_null(crossing, "l'aqueduc offre un passage")
		check_approx(ruins.aqueduct_crossing_y, ValleyRuins.SITE_AQUEDUCT.y,
			0.05, "le tablier affleure les deux rives")
		check_not_null(_find_piece(aqueduct, "Workbench"),
			"la réparation abandonnée a laissé son établi (indice)")
		check_not_null(_find_piece(aqueduct, "Pickaxe_Bronze"),
			"…et sa pioche")

	# 3. LA FERME : un abri, et de quoi manger. La preuve physique de l'abri
	# est faite dans le test suivant ; ici on vérifie les ingrédients.
	var farm: Node3D = ruins.ruin("FermeAbandonnee")
	check_not_null(farm, "la ferme est là")
	if farm != null:
		check_not_null(farm.get_node_or_null("Maison"),
			"la ferme a une maison — l'abri")
		for edible: String in ["Mushroom_Common", "Carrot", "FarmCrate_Apple"]:
			check_not_null(_find_piece(farm, edible),
				"la ferme a gardé de quoi récolter : %s" % edible)

	# 4. LA CARAVANE : l'arme du garde, restée là où l'homme est tombé.
	var wreck: Node3D = ruins.ruin("CaravaneFoudroyee")
	check_not_null(wreck, "la caravane foudroyée est là")
	if wreck != null:
		check_not_null(_find_piece(wreck, "Sword_Bronze"),
			"l'arme du garde est restée sur place")
		check_not_null(_find_piece(wreck, "Shield_Wooden"),
			"…avec son bouclier")

	# Et les quatre exposent un ancrage de récompense que le monde peut habiller.
	for node_name: String in ValleyRuins.RUIN_NODES:
		var site: Node3D = ruins.ruin(node_name)
		if site == null:
			continue
		check_not_null(site.find_child("AncrageRecompense", true, false),
			"« %s » expose un ancrage de récompense" % node_name)

	await _close(ruins)


## LE test de §1 : la ferme est un VRAI abri.
##
## Le corps est posé au-dessus du plancher intérieur ; s'il tombe, il n'y a pas
## de sol et l'« intérieur » est un mensonge. On le pousse ensuite contre les
## trois faces closes — s'il sort, la maison est une façade. Puis on le pousse
## dans la baie de l'est : là, il DOIT sortir. Ce qui paraît fermé l'est, ce
## qui paraît ouvert l'est aussi.
func test_the_farmhouse_is_a_shelter_you_can_stand_inside() -> void:
	var ruins: ValleyRuins = await _open()
	var house: Node3D = ruins.ruin("FermeAbandonnee").get_node("Maison") as Node3D
	# Coin dégagé de la pièce : ni la table (x ≤ 0,35) ni le lit (z ≥ 0,8),
	# et aligné sur la baie pour la sortie.
	var spot: Vector3 = house.global_position + Vector3(1.5, 1.4, 0.0)
	var body: CharacterBody3D = _body(spot)
	await _fall(body, 90)

	check(body.is_on_floor(),
		"le corps se pose sur un PLANCHER dans la ferme (y = %.2f)"
		% body.global_position.y)
	check_approx(body.global_position.y - BODY_HEIGHT * 0.5,
		ruins.farmhouse_floor_y, 0.2,
		"…à la cote du plancher intérieur, pas au fond du monde")

	# Les trois faces closes tiennent.
	var inside: Vector3 = body.global_position
	for direction: Vector3 in [Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		body.global_position = inside
		await _settle(1)
		await _shove(body, direction, 40)
		var drift: Vector3 = body.global_position - house.global_position
		check(absf(drift.x) < 3.0 and absf(drift.z) < 3.0,
			"poussé vers %v, le corps reste dans la maison (écart %.1f, %.1f)"
			% [direction, drift.x, drift.z])

	# La baie de l'est, elle, laisse passer : le vantail est dehors, dans la cour.
	body.global_position = inside
	await _settle(1)
	await _shove(body, Vector3.RIGHT, 40)
	var escaped_x: float = body.global_position.x - house.global_position.x
	check(escaped_x > 3.2,
		"par la baie arrachée, on SORT de la maison (x local %.1f)" % escaped_x)

	_drop_node(body)
	await _close(ruins)


## §1 encore, côté rivière : la travée tombée sert de pont. Elle ne le fait que
## si elle porte — un décor de pierres posées ne traverse rien.
func test_the_fallen_span_carries_you_across_the_river() -> void:
	var ruins: ValleyRuins = await _open()
	var aqueduct: Node3D = ruins.ruin("Aqueduc")
	var crossing: Marker3D = aqueduct.get_node("PassageDeLArche") as Marker3D
	var body: CharacterBody3D = _body(
		crossing.global_position + Vector3(0.0, 1.4, 0.0))
	await _fall(body, 90)

	check(body.is_on_floor(),
		"le tablier de la travée tombée porte un corps (y = %.2f)"
		% body.global_position.y)
	check_approx(body.global_position.y - BODY_HEIGHT * 0.5,
		ruins.aqueduct_crossing_y, 0.25,
		"…au niveau des deux rives, comme un pont de plain-pied")

	# On traverse : le tablier fait toute la largeur du lit, pas une dalle.
	var start_z: float = body.global_position.z
	await _shove(body, Vector3.BACK, 40)
	check(body.is_on_floor(),
		"on marche sur le tablier sans tomber dans le lit")
	check(absf(body.global_position.z - start_z) > 1.5,
		"…et on avance vraiment (%.1f m parcourus)"
		% absf(body.global_position.z - start_z))

	_drop_node(body)
	await _close(ruins)


## Deux lieux qui se chevauchent, ce sont deux volumes de découverte qui se
## déclenchent ensemble et un joueur qui ne sait plus où il est. Le village de
## la rivière est à `RiversideVillage.SITE`, sur un rayon d'environ 23 m.
func test_the_ruins_stay_clear_of_the_riverside_village() -> void:
	var ruins: ValleyRuins = await _open()
	var village: Vector3 = RiversideVillage.SITE
	var flat_village: Vector2 = Vector2(village.x, village.z)

	# 1. Les sites eux-mêmes, emprise contre emprise.
	var sites: Array[Vector3] = [
		ValleyRuins.SITE_WATCHTOWER, ValleyRuins.SITE_AQUEDUCT,
		ValleyRuins.SITE_FARM, ValleyRuins.SITE_CARAVAN,
	]
	for i: int in range(sites.size()):
		var site: Vector3 = sites[i]
		var gap: float = flat_village.distance_to(Vector2(site.x, site.z))
		check(gap > VILLAGE_RADIUS + RUIN_RADIUS,
			"« %s » est à %.1f m du village — au-delà des deux emprises (%.1f m)"
			% [ValleyRuins.RUIN_NODES[i], gap, VILLAGE_RADIUS + RUIN_RADIUS])

	# 2. Les volumes d'approche : aucun ne doit mordre sur le bourg, sinon on
	# découvrirait une ruine en traversant le village.
	check_equal(ruins.pois.size(), 4, "quatre volumes d'approche à vérifier")
	for place: PointOfInterest in ruins.pois:
		var shape: CollisionShape3D = place.get_child(0) as CollisionShape3D
		check_not_null(shape, "%s a une forme d'approche" % place.poi_id)
		if shape == null:
			continue
		var box: BoxShape3D = shape.shape as BoxShape3D
		check_not_null(box, "%s approche par une boîte" % place.poi_id)
		if box == null:
			continue
		var half: Vector3 = box.size * 0.5
		var centre: Vector3 = place.global_position
		# Point du volume le plus proche du bourg, en plan.
		var closest: Vector2 = Vector2(
			clampf(flat_village.x, centre.x - half.x, centre.x + half.x),
			clampf(flat_village.y, centre.z - half.z, centre.z + half.z))
		var gap: float = flat_village.distance_to(closest)
		check(gap > VILLAGE_RADIUS,
			"le volume de %s reste à %.1f m du village (rayon %.1f m)"
			% [place.poi_id, gap, VILLAGE_RADIUS])

	await _close(ruins)
