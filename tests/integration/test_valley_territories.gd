## TERRITOIRES ENNEMIS DE LA VALLÉE (ordre d'extension §2).
##
## Le point dur n'est pas « cinq nœuds existent ». C'est la règle centrale de
## l'ordre : « les ennemis ne doivent pas être dispersés aléatoirement ; chaque
## famille doit occuper un territoire COHÉRENT ». Un test de comptage laisserait
## passer cinq tas de props identiques posés au hasard. On vérifie donc :
##
##   1. que les cinq lieux existent, chacun réellement bâti — pas un figurant ;
##   2. que chacun se DÉCLARE sous son propre identifiant §19.3, distinct de
##      ceux des quinze lieux déjà implantés ;
##   3. qu'ils sont RÉELLEMENT ailleurs : à plus de 30 m de chaque lieu
##      existant et de chaque ancre du monde, hors du lit de rivière ;
##   4. que chaque territoire se LIT — désordre mesurable côté camps braise,
##      circuit fermé et balisé côté ronde azur, frontière signalée avant
##      l'entrée côté chasseur, traces de masse côté colosse ;
##   5. et, physiquement, qu'on se tient DANS le bastion et DANS la tanière,
##      que les murs du bastion arrêtent, que le portail laisse ressortir, et
##      que le fer à cheval de la tanière est fait de vrais blocs.
##
## Ce fichier ne teste PAS l'apparition des ennemis : le bestiaire vit dans
## `ValleyWorld._spawn_bestiary()`. Les territoires préparent les lieux.
extends GateTestCase


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open() -> ValleyTerritories:
	var lands: ValleyTerritories = ValleyTerritories.new()
	_tree().root.add_child(lands)
	await _settle(6)
	return lands


func _close(lands: Node) -> void:
	lands.get_parent().remove_child(lands)
	lands.queue_free()
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
## ne porte pas sur lui. Sa face supérieure affleure `centre.y`.
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


func _push(body: CharacterBody3D, direction: Vector3, frames: int) -> void:
	for i: int in range(frames):
		body.velocity = direction * 6.0
		body.velocity.y = -2.0
		body.move_and_slide()
		await _tree().physics_frame


func _discard(nodes: Array[Node]) -> void:
	for node: Node in nodes:
		node.get_parent().remove_child(node)
		node.queue_free()
	await _settle(2)


## Compte les corps statiques d'un sous-arbre : une plate-forme, une balise ou
## une enceinte sans collision ne serait qu'une image.
func _count_static_bodies(node: Node) -> int:
	var total: int = 0
	if node is StaticBody3D:
		total += 1
	for child: Node in node.get_children():
		total += _count_static_bodies(child)
	return total


func _flat(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


## Les lieux DÉJÀ implantés dans la vallée, avec l'ancre dont ils viennent.
## Recopiés ici volontairement : ce test doit continuer à protéger la
## séparation même si un autre fichier est en cours de remaniement.
func _existing_places() -> Array[Array]:
	var places: Array[Array] = [
		["village de la rivière", Vector2(-70.0, 36.0)],
		["hameau des bûcherons", Vector2(110.0, 40.0)],
		["poste minier", Vector2(-68.0, 86.0)],
		["ferme abandonnée", Vector2(-16.0, 78.0)],
		["aqueduc ancien", Vector2(-12.0, 10.0)],
		["caravane d'orage", Vector2(-38.0, -120.0)],
		["ruine de la tour de guet", Vector2(-128.0, 82.0)],
		["mine abandonnée", Vector2(160.0, -70.0)],
		["crypte creuse", Vector2(-60.0, -90.0)],
		["grotte de la cascade", Vector2(-118.0, 26.0)],
		["arbre ancien", Vector2(-96.0, -62.0)],
		["champ de fleurs", Vector2(-34.0, 112.0)],
		["belvédère du sommet", Vector2(168.0, 40.0)],
		["pont de pierre", Vector2(-14.0, 10.0)],
		["source turquoise", Vector2(-72.0, 78.0)],
		["camp ennemi existant", Vector2(45.0, 65.0)],
		["pylône", Vector2(115.0, -25.0)],
		["donjon", Vector2(0.0, -210.0)],
		["crête de départ", Vector2(0.0, 170.0)],
	]
	return places


## Les quinze identifiants §19.3 déjà pris. Aucun territoire n'a le droit
## d'en réutiliser un : deux lieux sous le même identifiant se marqueraient
## découverts l'un l'autre.
func _taken_ids() -> Array[StringName]:
	var ids: Array[StringName] = [
		&"valley.poi.riverside_village.01", &"valley.poi.logging_hamlet.01",
		&"valley.poi.mining_post.01", &"valley.poi.abandoned_farm.01",
		&"valley.poi.ancient_aqueduct.01", &"valley.poi.storm_caravan.01",
		&"valley.poi.watchtower_ruin.01", &"valley.poi.abandoned_mine.01",
		&"valley.poi.hollow_crypt.01", &"valley.poi.waterfall_cave.01",
		&"valley.poi.ancient_tree.01", &"valley.poi.flower_field.01",
		&"valley.poi.overlook_summit.01", &"valley.poi.stone_bridge.01",
		&"valley.poi.turquoise_spring.01",
	]
	return ids


## §2 : cinq territoires, un par famille, chacun réellement bâti.
func test_the_five_territories_are_built() -> void:
	var lands: ValleyTerritories = await _open()
	for place: String in ["CampsDePillardsBraise", "ZoneDePatrouilleAzur",
			"BastionDesBriseurs", "TaniereDuColosse", "TerritoireDuChasseur"]:
		check_not_null(lands.get_node_or_null(place),
			"le territoire « %s » existe (§2)" % place)
	check_equal(lands.territories().size(), 5, "cinq territoires exposés")
	check(lands.piece_count() >= 220,
		"%d pièces posées pour les cinq territoires — ce ne sont pas des maquettes"
		% lands.piece_count())
	for key: StringName in lands.territory_keys():
		check(lands.piece_count_of(key) >= 35,
			"le territoire %s est réellement habillé (%d pièces)"
			% [key, lands.piece_count_of(key)])
	await _close(lands)


## §2 et §19.3 : chaque territoire se DÉCLARE, sous SON identifiant.
func test_each_territory_declares_its_own_identifier() -> void:
	var lands: ValleyTerritories = await _open()
	var journal: DiscoveryLog = DiscoveryLog.new()
	check_equal(lands.pois().size(), 5, "cinq lieux déclarables")
	for poi: PointOfInterest in lands.pois():
		poi.bind(journal)
	check_equal(journal.registered_count(), 5,
		"cinq identifiants DISTINCTS entrent au journal")

	var mine: Array[StringName] = [
		ValleyTerritories.POI_BRAISE, ValleyTerritories.POI_AZURE,
		ValleyTerritories.POI_BASTION, ValleyTerritories.POI_LAIR,
		ValleyTerritories.POI_HUNTER,
	]
	var taken: Array[StringName] = _taken_ids()
	for poi_id: StringName in mine:
		check(journal.is_registered(poi_id),
			"…%s est déclaré" % poi_id)
		check(not taken.has(poi_id),
			"…et %s ne réutilise aucun identifiant déjà pris" % poi_id)
		check(journal.display_name_of(poi_id).length() > 3,
			"…avec un nom affiché en français (« %s »)"
			% journal.display_name_of(poi_id))
		check(String(journal.region_of(poi_id)) != "",
			"…et une région (%s)" % journal.region_of(poi_id))
	check_equal(journal.display_name_of(ValleyTerritories.POI_BASTION),
		"Bastion des briseurs d'obsidienne", "nom affiché du bastion")
	check_equal(journal.discovered_count(), 0, "déclarer n'est pas découvrir")
	await _close(lands)


## §2 : « chaque famille occupe un territoire cohérent » suppose d'abord que
## les territoires soient AILLEURS — ni l'un sur l'autre, ni sur un lieu déjà
## implanté, ni dans la rivière, ni hors des bornes du monde.
func test_the_territories_stand_apart_from_the_existing_places() -> void:
	var lands: ValleyTerritories = await _open()
	# Garde-fou : si le village bougeait, la table recopiée ci-dessus mentirait.
	check(_flat(RiversideVillage.SITE).distance_to(Vector2(-70.0, 36.0)) < 1.0,
		"la table des lieux existants est toujours à jour pour le village")

	var sites: Array[Vector3] = lands.sites()
	check_equal(sites.size(), 5, "cinq sites implantés")
	for index: int in range(sites.size()):
		var here: Vector2 = _flat(sites[index])
		for other: int in range(index + 1, sites.size()):
			var gap: float = here.distance_to(_flat(sites[other]))
			check(gap > 50.0,
				"les territoires %d et %d ne se chevauchent pas (%.0f m)"
				% [index + 1, other + 1, gap])
		for place: Array in _existing_places():
			var label: String = place[0]
			var flat: Vector2 = place[1]
			check(here.distance_to(flat) > 30.0,
				"le site %v se tient à l'écart du lieu « %s » (%.0f m)"
				% [sites[index], label, here.distance_to(flat)])
		check(absf(sites[index].z - 10.0) > 20.0,
			"le site %v se tient loin du lit de rivière" % sites[index])
		check(absf(sites[index].x) < 230.0 and absf(sites[index].z) < 230.0,
			"le site %v reste dans les bornes du monde" % sites[index])
		check_approx(sites[index].y, 2.0, 0.01,
			"le site %v est posé sur la plaine" % sites[index])
	await _close(lands)


## §12.1 : le pillard braise est impulsif. Son territoire doit se lire comme
## PLUSIEURS petits camps sommaires, jamais comme une installation. Le désordre
## est ici mesurable : trois campements, trois orientations franchement
## différentes, aucun aligné sur un autre.
func test_the_braise_camps_are_several_and_disorderly() -> void:
	var lands: ValleyTerritories = await _open()
	var camps: Node3D = lands.get_node("CampsDePillardsBraise") as Node3D
	var yaws: Array[float] = lands.camp_yaws()
	check_equal(yaws.size(), ValleyTerritories.BRAISE_CAMPS,
		"plusieurs petits camps, pas un seul gros")
	for i: int in range(yaws.size()):
		var camp: Node3D = camps.get_node_or_null(
			"Campement%02d" % (i + 1)) as Node3D
		check_not_null(camp, "le campement %d existe" % (i + 1))
		if camp == null:
			continue
		check(camp.get_child_count() >= 15,
			"…et il est réellement dressé (%d nœuds : foyer, auvent, pieux, fourbi)"
			% camp.get_child_count())
		check(camp.position.length() < 22.0,
			"…dans l'emprise du territoire (%.0f m du centre)"
			% camp.position.length())
		for j: int in range(i + 1, yaws.size()):
			check(absf(yaws[i] - yaws[j]) > 20.0,
				"les campements %d et %d ne sont pas orientés pareil (%.0f° d'écart)"
				% [i + 1, j + 1, absf(yaws[i] - yaws[j])])
	# Les camps sont espacés : trois foyers collés seraient un seul camp.
	for i: int in range(yaws.size()):
		var a: Node3D = camps.get_node_or_null(
			"Campement%02d" % (i + 1)) as Node3D
		if a == null:
			continue
		for j: int in range(i + 1, yaws.size()):
			var b: Node3D = camps.get_node_or_null(
				"Campement%02d" % (j + 1)) as Node3D
			if b == null:
				continue
			check(a.position.distance_to(b.position) > 8.0,
				"les campements %d et %d sont distincts sur le terrain (%.0f m)"
				% [i + 1, j + 1, a.position.distance_to(b.position)])
	check_not_null(camps.get_node_or_null("Abords"),
		"les camps ont leurs abords piétinés")
	await _close(lands)


## §12.2 : le pillard azur se repositionne et alerte. Son territoire est une
## RONDE — une boucle fermée, balisée, tenue par deux postes de guet réels.
## C'est la lecture inverse du désordre braise, avec les mêmes objets.
func test_the_azure_patrol_reads_as_a_marked_circuit() -> void:
	var lands: ValleyTerritories = await _open()
	var zone: Node3D = lands.get_node("ZoneDePatrouilleAzur") as Node3D
	for quarter: String in ["Ronde", "PosteDeGuet01", "PosteDeGuet02",
			"RelaisDeGarde", "PosteDeControle"]:
		check_not_null(zone.get_node_or_null(quarter),
			"la zone azur a son quartier « %s »" % quarter)

	var route: Array[Vector3] = lands.patrol_route()
	check(route.size() >= 10,
		"la ronde est jalonnée (%d repères)" % route.size())
	var quadrants: Array[bool] = [false, false, false, false]
	for i: int in range(route.size()):
		var here: Vector2 = _flat(route[i])
		var next: Vector2 = _flat(route[(i + 1) % route.size()])
		check(here.distance_to(next) < 12.0,
			"le repère %d mène au suivant sans trou (%.1f m)"
			% [i + 1, here.distance_to(next)])
		var local: Vector2 = here - _flat(ValleyTerritories.SITE_AZURE)
		var index: int = 0
		if local.x < 0.0:
			index += 1
		if local.y < 0.0:
			index += 2
		quadrants[index] = true
	for q: int in range(4):
		check(quadrants[q],
			"la ronde passe par le quadrant %d — c'est une BOUCLE, pas une ligne"
			% (q + 1))

	# Les postes de guet sont de vraies plates-formes : plancher porteur et
	# poteaux. Un mirador décoratif ne serait qu'une image de plus.
	for post_name: String in ["PosteDeGuet01", "PosteDeGuet02"]:
		var post: Node3D = zone.get_node(post_name) as Node3D
		check(_count_static_bodies(post) >= 5,
			"le %s porte un plancher et des poteaux physiques (%d corps)"
			% [post_name, _count_static_bodies(post)])
	await _close(lands)


## §12.3 : le briseur tient l'espace. Son territoire est le seul BÂTI, et il
## doit l'être pour de bon : on se tient dans la cour, les murs arrêtent, et le
## portail laisse RESSORTIR — une enceinte sans sortie serait un piège (§15.11).
func test_the_obsidian_bastion_is_a_defended_court_you_can_stand_in() -> void:
	var lands: ValleyTerritories = await _open()
	var bastion: Node3D = lands.get_node("BastionDesBriseurs") as Node3D
	for quarter: String in ["CourInterieure", "Enceinte", "Portail",
			"Barricades", "CourArmee"]:
		check_not_null(bastion.get_node_or_null(quarter),
			"le bastion a son quartier « %s »" % quarter)

	var body: CharacterBody3D = _make_body()
	body.global_position = bastion.global_position + Vector3(0, 1.4, 0)
	await _drop_until_floor(body)
	check(body.is_on_floor(),
		"le corps se pose sur le SOL de la cour (y = %.2f)"
		% body.global_position.y)
	check(body.global_position.y > lands.bastion_court_y - 0.6,
		"…et non au fond du monde (cour attendue à y = %.2f)"
		% lands.bastion_court_y)

	# Les murs tiennent. Le portail est à l'EST : on pousse vers l'ouest, le
	# nord et le sud, jamais vers la baie. Quatre-vingt-dix pas à 6 m/s, soit
	# 9 m demandés dans une cour de 14 m : sans mur, le corps SORTIRAIT.
	var inside: Vector3 = body.global_position
	for direction: Vector3 in [Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		body.global_position = inside
		await _settle(1)
		await _push(body, direction, 90)
		var drift: Vector3 = body.global_position - bastion.global_position
		check(absf(drift.x) < 7.4 and absf(drift.z) < 7.4,
			"poussé vers %v, le corps reste dans l'enceinte (écart %.1f, %.1f)"
			% [direction, drift.x, drift.z])

	# …et on ressort par le portail : le bastion se défend, il n'emprisonne pas.
	var ground: StaticBody3D = _make_ground(ValleyTerritories.SITE_BASTION)
	body.global_position = inside
	await _settle(1)
	await _push(body, Vector3.RIGHT, 90)
	var escaped: float = body.global_position.x - bastion.global_position.x
	check(escaped > 7.4,
		"le portail laisse RESSORTIR (x = %.1f au-delà du centre)" % escaped)

	var trash: Array[Node] = []
	trash.append(body)
	trash.append(ground)
	await _discard(trash)
	await _close(lands)


## §12.4 : le colosse déplace la matière. Sa tanière ne se lit pas à ce qu'on y
## a posé mais à ce qui y a été DÉPLACÉ. On vérifie les traces, puis que le fer
## à cheval est fait de vrais blocs : on s'y tient, et il arrête.
func test_the_colossus_lair_bears_the_traces_of_its_mass() -> void:
	var lands: ValleyTerritories = await _open()
	var lair: Node3D = lands.get_node("TaniereDuColosse") as Node3D
	for trace: String in ["AntreDeRocaille", "SillonDeTraine", "ArbresBrises",
			"OssementsStylises", "CharretteBrisee"]:
		check_not_null(lair.get_node_or_null(trace),
			"la tanière porte la trace « %s »" % trace)
	var bones: Node3D = lair.get_node("OssementsStylises") as Node3D
	check(bones.get_child_count() >= 12,
		"les ossements stylisés sont plusieurs (%d formes pâles, aucune anatomie)"
		% bones.get_child_count())
	var trees: Node3D = lair.get_node("ArbresBrises") as Node3D
	check(trees.get_child_count() >= 8,
		"des arbres brisés jonchent l'antre (%d nœuds)" % trees.get_child_count())

	var body: CharacterBody3D = _make_body()
	body.global_position = lair.global_position + Vector3(0, 1.4, 0)
	await _drop_until_floor(body)
	check(body.is_on_floor(),
		"le corps se pose sur la terre tassée de l'antre (y = %.2f)"
		% body.global_position.y)
	check(body.global_position.y > lands.lair_floor_y - 0.6,
		"…et non au fond du monde (antre attendu à y = %.2f)"
		% lands.lair_floor_y)

	# Le fond de l'antre est fermé par les blocs ; l'ouverture regarde le sud.
	await _push(body, Vector3.FORWARD, 90)
	var drift: Vector3 = body.global_position - lair.global_position
	check(absf(drift.z) < 7.5,
		"les blocs déplacés ferment le fond de l'antre (écart %.1f m)" % drift.z)

	var trash: Array[Node] = []
	trash.append(body)
	await _discard(trash)
	await _close(lands)


## §12.5 : le chasseur est FACULTATIF. Cela n'a de sens que si son territoire
## se signale AVANT qu'on y entre. On vérifie que le balisage entoure vraiment
## le lieu, qu'il est physique, et qu'il ne déborde sur aucun voisin.
func test_the_hunter_range_is_marked_before_you_enter() -> void:
	var lands: ValleyTerritories = await _open()
	var range_node: Node3D = lands.get_node("TerritoireDuChasseur") as Node3D
	for quarter: String in ["FrontiereBalisee", "MonticuleDuChasseur",
			"TropheesPlantes", "SolLaboure"]:
		check_not_null(range_node.get_node_or_null(quarter),
			"le territoire du chasseur a son quartier « %s »" % quarter)

	var marks: Array[Vector3] = lands.frontier_marks()
	check(marks.size() >= 8,
		"la frontière est balisée sur tout son tour (%d balises)" % marks.size())
	var centre: Vector2 = _flat(ValleyTerritories.SITE_HUNTER)
	var quadrants: Array[bool] = [false, false, false, false]
	for i: int in range(marks.size()):
		var local: Vector2 = _flat(marks[i]) - centre
		check_approx(local.length(), lands.hunter_frontier_radius(), 0.5,
			"la balise %d est bien sur la frontière" % (i + 1))
		var index: int = 0
		if local.x < 0.0:
			index += 1
		if local.y < 0.0:
			index += 2
		quadrants[index] = true
	for q: int in range(4):
		check(quadrants[q],
			"le balisage ENTOURE le territoire (quadrant %d)" % (q + 1))

	# Chaque balise est physique : un avertissement qu'on traverse n'avertit
	# personne.
	var frontier: Node3D = range_node.get_node("FrontiereBalisee") as Node3D
	var solid_marks: int = 0
	for child: Node in frontier.get_children():
		if _count_static_bodies(child) > 0:
			solid_marks += 1
	check(solid_marks >= marks.size(),
		"les %d balises sont plantées pour de bon (%d avec collision)"
		% [marks.size(), solid_marks])

	# Le balisage reste chez lui : il ne doit pas venir avertir sur le seuil
	# d'un autre lieu.
	for place: Array in _existing_places():
		var label: String = place[0]
		var flat: Vector2 = place[1]
		check(centre.distance_to(flat) > lands.hunter_frontier_radius() + 30.0,
			"le balisage ne déborde pas sur « %s » (%.0f m)"
			% [label, centre.distance_to(flat)])
	check(lands.is_inside_hunter_frontier(ValleyTerritories.SITE_HUNTER),
		"le centre du territoire est bien à l'intérieur de la frontière")
	check(not lands.is_inside_hunter_frontier(
			ValleyTerritories.SITE_HUNTER + Vector3(0, 0, 40.0)),
		"…et un point à 40 m est bien à l'extérieur")
	await _close(lands)
