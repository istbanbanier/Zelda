## SECONDE VAGUE DE LIEUX NATURELS — `ValleyWonders`.
##
## Le point dur n'est pas « cinq nœuds existent ». Un décor qui compte juste
## passerait n'importe quel test de comptage. Ce qui est vérifié ici, ce sont
## les promesses que la composition fait au joueur :
##
##   - la GORGE est un passage, donc un corps doit la TRAVERSER de bout en
##     bout sans rester coincé, et sans sortir du couloir ;
##   - l'ABRI derrière la cascade est un volume, donc on doit pouvoir s'y tenir
##     debout — le rideau d'eau se traverse, la roche non ;
##   - le CERCLE est un monument, donc ses pierres sont sur un cercle et son
##     entrée est réellement vide ;
##   - le BOIS COURBÉ est un indice, donc TOUS ses arbres penchent du même
##     côté — une inclinaison au hasard ne dirait rien ;
##   - l'ARBRE FOUDROYÉ montre du charbon et du bois nu, pas une lueur.
##
## Enfin, deux gardes de production : les cinq lieux ne s'écrasent sur aucun
## lieu déjà implanté, et aucun matériau posé ici n'allume de néon cyan — la
## bible réserve cette couleur à l'énergie de Résonance.
extends GateTestCase

## Lieux DÉJÀ implantés dans la vallée, et repères du terrain. Recopiés ici
## volontairement plutôt qu'importés : ce test doit rester exécutable même
## pendant qu'un autre fichier de monde est en cours de modification, et une
## coordonnée fausse se verrait immédiatement à l'échec de la séparation.
const CLEARANCE: float = 30.0


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open() -> ValleyWonders:
	var wonders: ValleyWonders = ValleyWonders.new()
	_tree().root.add_child(wonders)
	await _settle(6)
	return wonders


func _close(wonders: Node) -> void:
	wonders.get_parent().remove_child(wonders)
	wonders.queue_free()
	await _settle(2)


## Capsule de la taille du héros (1,78 m), la seule qui prouve un passage.
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


func _drop(body: CharacterBody3D, ticks: int) -> void:
	for i: int in range(ticks):
		body.velocity.y -= 24.0 * (1.0 / 60.0)
		body.move_and_slide()
		await _tree().physics_frame
		if body.is_on_floor():
			break


func _dispose(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.queue_free()


## Les cinq nouveaux sites, avec leur nom affiché.
func _new_sites() -> Array[Array]:
	var sites: Array[Array] = [
		["La Chute du Voile", ValleyWonders.SITE_FALLS],
		["Le Cercle des Veilleurs", ValleyWonders.SITE_CIRCLE],
		["La Gorge du Vent", ValleyWonders.SITE_GORGE],
		["Le Bois Courbé", ValleyWonders.SITE_GROVE],
		["L'Arbre foudroyé", ValleyWonders.SITE_STRUCK],
	]
	return sites


## Tout ce qui occupe déjà la vallée : première vague de lieux, village,
## hameaux, ruines, grottes et les quatre repères de la boucle.
func _occupied() -> Array[Array]:
	var places: Array[Array] = [
		["arbre doyen", Vector3(-96.0, 2.0, -62.0)],
		["source aux reflets", Vector3(-72.0, 2.0, 78.0)],
		["champ de fleurs", Vector3(-34.0, 2.0, 112.0)],
		["arche de pierre", Vector3(-14.0, 0.0, 10.0)],
		["belvédère du guetteur", Vector3(168.0, 0.0, 40.0)],
		["village de la rivière", Vector3(-70.0, 2.0, 36.0)],
		["hameau des bûcherons", Vector3(110.0, 2.0, 40.0)],
		["poste minier", Vector3(-68.0, 2.0, 86.0)],
		["ruine du guet", Vector3(-128.0, 14.0, 82.0)],
		["aqueduc ancien", Vector3(-12.0, 2.0, 10.0)],
		["ferme abandonnée", Vector3(-16.0, 2.0, 78.0)],
		["caravane de l'orage", Vector3(-38.0, 2.0, -120.0)],
		["grotte de la cascade", Vector3(-118.0, 2.0, 26.0)],
		["mine abandonnée", Vector3(160.0, 2.0, -70.0)],
		["crypte oubliée", Vector3(-60.0, 2.0, -90.0)],
		["camp", Vector3(45.0, 6.0, 65.0)],
		["pylône", Vector3(115.0, 18.0, -25.0)],
		["donjon", Vector3(0.0, 34.0, -210.0)],
		["crête de départ", Vector3(0.0, 24.0, 170.0)],
	]
	return places


## Identifiants §19.3 déjà attribués ailleurs dans le monde.
func _taken_ids() -> Array[StringName]:
	var ids: Array[StringName] = [
		&"valley.poi.riverside_village.01",
		&"valley.poi.logging_hamlet.01",
		&"valley.poi.mining_post.01",
		&"valley.poi.abandoned_farm.01",
		&"valley.poi.ancient_aqueduct.01",
		&"valley.poi.storm_caravan.01",
		&"valley.poi.watchtower_ruin.01",
		&"valley.poi.abandoned_mine.01",
		&"valley.poi.hollow_crypt.01",
		&"valley.poi.waterfall_cave.01",
		&"valley.poi.ancient_tree.01",
		&"valley.poi.flower_field.01",
		&"valley.poi.overlook_summit.01",
		&"valley.poi.stone_bridge.01",
		&"valley.poi.turquoise_spring.01",
	]
	return ids


# ---------------------------------------------------------------------------


## Les cinq lieux sont bâtis, et bâtis avec de la MATIÈRE : un lieu mémorable
## qui poserait douze modèles serait une maquette.
func test_the_second_wave_builds_five_places() -> void:
	var wonders: ValleyWonders = await _open()
	var expected: Array[String] = ["ChuteDuVoile", "CercleDesVeilleurs",
		"GorgeDuVent", "BoisCourbe", "ArbreFoudroye"]
	for place_name: String in expected:
		check_not_null(wonders.get_node_or_null(NodePath(place_name)),
			"la seconde vague porte son lieu « %s »" % place_name)
	check(wonders.piece_count() >= 180,
		"%d modèles posés — les cinq lieux ont de la matière"
		% wonders.piece_count())
	# §7.5 : la végétation dense passe par des MultiMesh PARTITIONNÉS, jamais
	# par un tampon unique. Chaque cellule est un nœud distinct.
	check(wonders.cover_count() >= 900,
		"%d touffes écrites dans les cellules de couvre-sol"
		% wonders.cover_count())
	var cells: int = 0
	var stack: Array[Node] = [wonders]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is MultiMeshInstance3D:
			cells += 1
		for child: Node in current.get_children():
			stack.append(child)
	check(cells >= 6,
		"%d cellules de MultiMesh — la végétation est partitionnée (§7.5)" % cells)
	await _close(wonders)


## Chaque lieu se DÉCLARE, sous un identifiant §19.3 qui lui appartient : ni
## deux fois le même, ni celui d'un lieu déjà implanté.
func test_each_place_declares_a_distinct_new_identifier() -> void:
	var wonders: ValleyWonders = await _open()
	var ids: Array[StringName] = wonders.poi_ids()
	check_equal(ids.size(), 5, "les cinq lieux portent un point d'intérêt")

	var seen: Dictionary = {}
	for poi_id: StringName in ids:
		seen[poi_id] = true
	check_equal(seen.size(), 5, "les cinq identifiants sont DISTINCTS")

	var taken: Array[StringName] = _taken_ids()
	var collisions: Array[String] = []
	for poi_id: StringName in ids:
		if taken.has(poi_id):
			collisions.append(String(poi_id))
	check(collisions.is_empty(),
		"aucun identifiant déjà attribué ailleurs (%s)" % ", ".join(collisions))

	# Un journal neuf : la déclaration doit passer par lui, pas par le lieu.
	var journal: DiscoveryLog = DiscoveryLog.new()
	for poi: PointOfInterest in wonders.pois:
		poi.bind(journal)
		check(journal.is_registered(poi.poi_id),
			"« %s » est enregistré au journal" % poi.display_name)
		check(not poi.display_name.is_empty(),
			"…et porte un nom affiché en français (%s)" % poi.display_name)
	check_equal(journal.discovered_count(), 0,
		"rien n'est découvert avant d'y être allé")
	await _close(wonders)


## Un lieu posé sur un autre n'ajoute pas une destination, il en abîme deux.
func test_the_five_places_keep_clear_of_the_existing_ones() -> void:
	var wonders: ValleyWonders = await _open()
	for entry: Array in _new_sites():
		var label: String = entry[0] as String
		var site: Vector3 = entry[1] as Vector3
		var nearest: String = ""
		var closest: float = 1.0e9
		for other: Array in _occupied():
			var at: Vector3 = other[1] as Vector3
			var gap: float = Vector2(site.x - at.x, site.z - at.z).length()
			if gap < closest:
				closest = gap
				nearest = other[0] as String
		check(closest >= CLEARANCE,
			"%s reste à %.1f m du plus proche lieu connu (%s), seuil %.0f m"
			% [label, closest, nearest, CLEARANCE])

	# …et les cinq nouveaux ne se marchent pas dessus entre eux.
	var sites: Array[Array] = _new_sites()
	for i: int in range(sites.size()):
		for j: int in range(i + 1, sites.size()):
			var a: Vector3 = sites[i][1] as Vector3
			var b: Vector3 = sites[j][1] as Vector3
			var gap: float = Vector2(a.x - b.x, a.z - b.z).length()
			check(gap >= CLEARANCE,
				"%s et %s sont séparés de %.1f m"
				% [sites[i][0], sites[j][0], gap])
	await _close(wonders)


## LE test de la gorge : c'est un PASSAGE. Un corps entre par la bouche sud et
## doit ressortir au nord. S'il reste coincé, la gorge est un décor ; s'il sort
## latéralement, ce n'est pas un couloir.
##
## Le pilotage suit l'axe LOCAL de la gorge (elle n'est pas alignée sur la
## grille du monde) : pousser vers −Z monde raterait la sortie de 10 m.
func test_the_gorge_can_be_walked_from_end_to_end() -> void:
	var wonders: ValleyWonders = await _open()
	var gorge: Node3D = wonders.get_node_or_null("GorgeDuVent") as Node3D
	check_not_null(gorge, "la gorge est bâtie")

	var axis: Vector3 = -gorge.global_transform.basis.z
	axis.y = 0.0
	axis = axis.normalized()

	var body: CharacterBody3D = _make_body()
	body.global_position = gorge.to_global(
		ValleyWonders.GORGE_MOUTH_SOUTH + Vector3(0, 1.2, 0))
	await _settle(1)

	var exited: bool = false
	var drift: float = 0.0
	var lowest: float = body.global_position.y
	var reached: float = ValleyWonders.GORGE_MOUTH_SOUTH.z
	for i: int in range(480):
		body.velocity = axis * 8.0
		body.velocity.y = -12.0
		body.move_and_slide()
		await _tree().physics_frame
		var local: Vector3 = gorge.to_local(body.global_position)
		drift = maxf(drift, absf(local.x))
		lowest = minf(lowest, body.global_position.y)
		reached = minf(reached, local.z)
		if local.z <= ValleyWonders.GORGE_MOUTH_NORTH.z + 2.0:
			exited = true
			break

	check(exited,
		"le corps traverse la gorge et ressort au nord (atteint z local %.1f)"
		% reached)
	check(drift <= ValleyWonders.GORGE_HALF_WIDTH + 1.2,
		"…sans sortir du couloir (écart latéral maximal %.2f m)" % drift)
	check(lowest > ValleyWonders.SITE_GORGE.y - 2.0,
		"…et sans tomber au travers du sol (plancher %.2f m)" % lowest)

	_dispose(body)
	await _close(wonders)


## L'abri derrière la chute est un VOLUME : le rideau d'eau se traverse, la
## roche non, et il y a un sol dessous. Un corps lâché là doit se poser.
func test_one_can_stand_in_the_shelter_behind_the_falls() -> void:
	var wonders: ValleyWonders = await _open()
	var falls: Node3D = wonders.get_node_or_null("ChuteDuVoile") as Node3D
	check_not_null(falls.get_node_or_null("Abri/SolDeLAbri"),
		"l'abri porte un sol porteur explicite")
	# Le rideau et l'écume sont purement visuels : s'ils portaient une
	# collision, on ne pourrait pas entrer.
	for visual: String in ["Chute/RideauDEau", "Chute/VeineDEcume"]:
		var node: Node = falls.get_node_or_null(NodePath(visual))
		check_not_null(node, "« %s » est en place" % visual)
		check(not (node is CollisionObject3D),
			"…et se traverse : %s n'a pas de collision" % visual)

	var body: CharacterBody3D = _make_body()
	body.global_position = falls.to_global(
		ValleyWonders.FALLS_SHELTER + Vector3(0, 4.0, 0))
	await _drop(body, 120)
	check(body.is_on_floor(),
		"on se tient debout derrière la chute (y = %.2f)"
		% body.global_position.y)
	check(body.global_position.y > ValleyWonders.SITE_FALLS.y - 0.5,
		"…sur le sol de l'abri, pas au fond du monde")
	# Et l'abri est bien FERMÉ au fond : poussé vers la paroi, on reste dedans.
	var inside: Vector3 = body.global_position
	body.global_position = inside
	for i: int in range(40):
		body.velocity = -falls.global_transform.basis.z * 6.0
		body.velocity.y = -2.0
		body.move_and_slide()
		await _tree().physics_frame
	var local: Vector3 = falls.to_local(body.global_position)
	check(local.z > -17.0,
		"la niche a un fond : poussé dedans, le corps s'arrête (z local %.1f)"
		% local.z)

	_dispose(body)
	await _close(wonders)


## Un tas de cailloux n'est pas un monument. Le cercle est vérifié comme une
## INTENTION : pierres sur un cercle, une position laissée vide au nord, un
## trilithe qui l'encadre, et un autel sur lequel on monte.
func test_the_stone_circle_is_a_deliberate_monument() -> void:
	var wonders: ValleyWonders = await _open()
	var circle: Node3D = wonders.get_node_or_null("CercleDesVeilleurs") as Node3D
	var stones: Node3D = circle.get_node_or_null("Menhirs") as Node3D
	check_not_null(stones, "le cercle porte ses menhirs")

	var placed: int = 0
	var off_circle: int = 0
	var north_gap: bool = true
	for child: Node in stones.get_children():
		var stone: StaticBody3D = child as StaticBody3D
		if stone == null or not String(stone.name).begins_with("Menhir"):
			continue
		placed += 1
		var at: Vector3 = stone.position
		var radial: float = Vector2(at.x, at.z).length()
		if absf(radial - ValleyWonders.CIRCLE_RADIUS) > 1.2:
			off_circle += 1
		# Repère : 0 rad regarde le nord (−Z), c'est-à-dire la citadelle.
		if absf(wrapf(atan2(at.x, -at.z), -PI, PI)) < 0.4:
			north_gap = false
	check(placed >= 9,
		"%d pierres dressées ou couchées — assez pour lire un cercle" % placed)
	check_equal(off_circle, 0, "toutes les pierres sont sur le MÊME cercle")
	check(north_gap,
		"la position nord est laissée VIDE — c'est l'entrée, et elle prouve "
		+ "l'intention")

	for part: String in ["Porte/MontantOuest", "Porte/MontantEst", "Porte/Linteau"]:
		check_not_null(circle.get_node_or_null(NodePath(part)),
			"le trilithe d'entrée a sa pièce « %s »" % part)

	# L'autel est une dalle sur laquelle on MONTE : c'est le seul point du
	# cercle d'où l'on voit par-dessus les pierres couchées.
	var altar: StaticBody3D = circle.get_node_or_null("Autel") as StaticBody3D
	check_not_null(altar, "le cercle a son autel central")
	var body: CharacterBody3D = _make_body()
	body.global_position = altar.global_position + Vector3(0, 3.2, 0)
	await _drop(body, 120)
	check(body.is_on_floor(),
		"on se tient debout sur l'autel (y = %.2f)" % body.global_position.y)
	check(body.global_position.y > ValleyWonders.SITE_CIRCLE.y
			+ ValleyWonders.CIRCLE_ALTAR_TOP,
		"…sur la dalle, et non au pied du monument")

	_dispose(body)
	await _close(wonders)


## Le bosquet est un INDICE : les arbres penchent tous du même côté parce que
## le vent descend de la citadelle. Une inclinaison au hasard ne dirait rien —
## c'est l'unanimité qui se lit.
func test_the_storm_grove_leans_away_from_the_citadel() -> void:
	var wonders: ValleyWonders = await _open()
	var grove: Node3D = wonders.get_node_or_null("BoisCourbe") as Node3D
	var leaning: Node3D = grove.get_node_or_null("ArbresPenches") as Node3D
	check_not_null(leaning, "le bosquet porte ses arbres penchés")

	var trees: int = 0
	var wrong_way: int = 0
	for child: Node in leaning.get_children():
		var node: Node3D = child as Node3D
		if node == null or node is StaticBody3D:
			continue   # les fûts de collision restent droits
		trees += 1
		# Rotation POSITIVE autour de X : la cime part vers +Z, donc au sud,
		# donc à l'opposé du donjon (0, 34, −210).
		if node.rotation.x < 0.15:
			wrong_way += 1
	check(trees >= 8, "%d arbres vivants dans le bosquet" % trees)
	check_equal(wrong_way, 0,
		"tous fuient la citadelle — aucun ne penche à contresens")

	var dead: Node3D = grove.get_node_or_null("BoisMort") as Node3D
	var stumps: int = 0
	for child: Node in dead.get_children():
		var node: Node3D = child as Node3D
		if node == null or node is StaticBody3D:
			continue
		stumps += 1
		check(node.rotation.x > ValleyWonders.GROVE_LEAN,
			"le bois mort penche PLUS fort que le vivant (%.2f rad)"
			% node.rotation.x)
	check(stumps >= 4, "%d bois morts sur la lisière exposée" % stumps)

	# Les troncs abattus portent une collision : on monte dessus.
	var fallen: Node3D = grove.get_node_or_null("TroncsAbattus") as Node3D
	var logs: int = 0
	for child: Node in fallen.get_children():
		if child is StaticBody3D:
			logs += 1
	check(logs >= 4, "%d troncs abattus praticables" % logs)
	check_not_null(grove.get_node_or_null("Clairiere/SolCalcine"),
		"la clairière rasée est au centre du bosquet")
	await _close(wonders)


## L'arbre foudroyé se lit par la MATIÈRE : du charbon, une fente de bois nu,
## et des repousses au pied. Pas une lueur.
func test_the_thunderstruck_tree_shows_charred_wood_and_a_pale_split() -> void:
	var wonders: ValleyWonders = await _open()
	var tree: Node3D = wonders.get_node_or_null("ArbreFoudroye") as Node3D
	var trunk: Node3D = tree.get_node_or_null("Tronc") as Node3D
	check_not_null(trunk, "l'arbre a son tronc")

	var west: StaticBody3D = trunk.get_node_or_null("DemiTroncOuest") as StaticBody3D
	var east: StaticBody3D = trunk.get_node_or_null("DemiTroncEst") as StaticBody3D
	check_not_null(west, "le demi-tronc ouest porte la collision")
	check_not_null(east, "le demi-tronc est porte la collision")

	var split: MeshInstance3D = trunk.get_node_or_null("FenteClaire") as MeshInstance3D
	check_not_null(split, "la fente de bois nu existe")
	var pale: StandardMaterial3D = split.material_override as StandardMaterial3D
	check_not_null(pale, "…et porte un matériau explicite")
	var bark: MeshInstance3D = west.get_node_or_null(
		"DemiTroncOuestMesh") as MeshInstance3D
	var charred: StandardMaterial3D = bark.material_override as StandardMaterial3D
	check_not_null(charred, "le tronc porte un matériau charbon")
	check(pale.albedo_color.v - charred.albedo_color.v > 0.4,
		"la fente est nettement plus claire que le bois brûlé (%.2f contre %.2f)"
		% [pale.albedo_color.v, charred.albedo_color.v])
	check(not pale.emission_enabled,
		"…et c'est du BOIS, pas une lueur : aucune émission")

	# Les repousses : la vie revient, et c'est ce contraste qui tient l'image.
	var regrowth: Node3D = tree.get_node_or_null("Repousses") as Node3D
	check(regrowth.get_child_count() >= 10,
		"%d repousses au pied de l'arbre" % regrowth.get_child_count())
	check_not_null(tree.get_node_or_null("CerneCalcine"),
		"le sol garde le cerne de la décharge")
	await _close(wonders)


## VISUAL_ASSET_BIBLE §3.4 : le cyan est RARE, réservé à l'énergie de
## Résonance. Une cascade reste de l'eau. Ce test refuse tout matériau POSÉ par
## ces cinq lieux qui émettrait, ou qui virerait au néon cyan saturé.
func test_no_place_lights_a_cyan_neon() -> void:
	var wonders: ValleyWonders = await _open()
	var audited: int = 0
	var glowing: Array[String] = []
	var neon: Array[String] = []
	var stack: Array[Node] = [wonders]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		var mesh: GeometryInstance3D = current as GeometryInstance3D
		if mesh != null:
			var material: StandardMaterial3D = \
				mesh.material_override as StandardMaterial3D
			if material != null:
				audited += 1
				if material.emission_enabled:
					glowing.append(String(mesh.name))
				var tint: Color = material.albedo_color
				# Néon cyan : rouge écrasé, vert et bleu poussés. L'eau de la
				# vallée (0,09 / 0,55 / 0,60) reste sous ce seuil, une énergie
				# de Résonance le franchirait immédiatement.
				if tint.r < 0.35 and tint.g > 0.60 and tint.b > 0.60:
					neon.append(String(mesh.name))
		for child: Node in current.get_children():
			stack.append(child)

	check(audited >= 20,
		"%d matériaux posés par les lieux ont été audités" % audited)
	check(glowing.is_empty(),
		"aucun matériau n'émet (%s)" % ", ".join(glowing))
	check(neon.is_empty(),
		"aucun matériau ne vire au cyan saturé (%s)" % ", ".join(neon))
	await _close(wonders)
