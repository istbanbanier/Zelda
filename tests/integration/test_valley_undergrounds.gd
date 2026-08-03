## SOUTERRAINS DE LA VALLÉE — passage dérobé et cavité de cristal.
##
## Le point dur n'est pas « il y a deux souterrains de plus » : c'est la règle
## centrale de l'ordre, « les grottes doivent être de véritables espaces
## explorables, pas de simples trous décoratifs ». Un décor de bouches noires
## passerait n'importe quel comptage de nœuds.
##
## On fait donc, pour CHAQUE lieu, ce que le village fait pour son auberge : on
## pose un corps physique — la capsule du joueur, rayon 0,35, hauteur 1,7 — au
## point intérieur, on applique la gravité et on exige `is_on_floor()`. Un trou
## décoratif laisse tomber le corps ; un volume le porte.
##
## Le passage dérobé porte en plus une exigence propre : c'est un RACCOURCI. Un
## boyau qui monte de neuf mètres et s'arrête dans la roche n'est pas un
## raccourci, c'est un cul-de-sac. Trois preuves le vérifient :
##   - le corps ENTRE par la bouche basse, la traverse et RESSORT neuf mètres
##     plus haut, sans téléportation ni assistance ;
##   - il redescend par le même boyau — les deux extrémités se franchissent
##     dans les deux sens ;
##   - la roche à côté du boyau est PLEINE : sans le passage, il faudrait
##     contourner l'éperon. Un raccourci qui longe un terrain vide n'en est pas
##     un.
extends GateTestCase


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open() -> ValleyUndergrounds:
	var places: ValleyUndergrounds = ValleyUndergrounds.new()
	_tree().root.add_child(places)
	await _settle(6)
	return places


func _close(places: Node) -> void:
	places.get_parent().remove_child(places)
	places.queue_free()
	await _settle(2)


## Capsule du joueur, montée à la main : le test ne doit rien devoir au
## contrôleur, seulement à la géométrie des souterrains.
func _spawn_body(at: Vector3) -> CharacterBody3D:
	var body: CharacterBody3D = CharacterBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = ValleyUndergrounds.PLAYER_RADIUS
	capsule.height = ValleyUndergrounds.PLAYER_HEIGHT
	shape.shape = capsule
	body.add_child(shape)
	_tree().root.add_child(body)
	body.global_position = at
	return body


func _drop(body: CharacterBody3D, frames: int = 120) -> void:
	for i: int in range(frames):
		body.velocity.y -= 24.0 * (1.0 / 60.0)
		body.move_and_slide()
		await _tree().physics_frame
		if body.is_on_floor():
			return


func _despawn(body: Node) -> void:
	body.get_parent().remove_child(body)
	body.queue_free()


## Liste TYPÉE : un littéral non typé ne s'affecte pas à un `Array[StringName]`.
func _places_under_test() -> Array[StringName]:
	var keys: Array[StringName] = [ValleyUndergrounds.UNDER_PASSAGE,
		ValleyUndergrounds.UNDER_CRYSTAL]
	return keys


# --- Existence --------------------------------------------------------------

func test_the_valley_holds_two_underground_places() -> void:
	var places: ValleyUndergrounds = await _open()
	for node_name: String in ["PassageDerobe", "CaviteCristalline"]:
		check_not_null(places.get_node_or_null(node_name),
			"la vallée porte le souterrain « %s »" % node_name)
	# La galerie inclinée est la pièce maîtresse du raccourci : sans elle, les
	# deux bouches ne seraient reliées par rien.
	check_not_null(places.get_node_or_null("PassageDerobe/GalerieInclinee"),
		"le passage possède sa galerie inclinée")
	check_equal(places.site_keys().size(), 2,
		"deux souterrains déclarés, pas un de moins")
	check(places.piece_count() >= 140,
		"%d volumes et modèles posés — des espaces bâtis, pas des trous"
		% places.piece_count())
	await _close(places)


## §19.3 : chaque lieu a un identifiant stable, et deux lieux ne le partagent
## jamais — un doublon ferait se marquer découverts deux endroits à la fois.
func test_each_underground_declares_a_distinct_identifier() -> void:
	var places: ValleyUndergrounds = await _open()
	var journal: DiscoveryLog = DiscoveryLog.new()
	places.bind_all(journal)
	var expected: Array[StringName] = [
		&"valley.poi.hidden_passage.01",
		&"valley.poi.crystal_hollow.01",
	]
	for poi_id: StringName in expected:
		check(journal.is_registered(poi_id),
			"« %s » est déclaré au journal" % poi_id)
		check(not journal.display_name_of(poi_id).is_empty(),
			"…avec un nom affiché (obtenu « %s »)"
			% journal.display_name_of(poi_id))
	check_equal(journal.registered_count(), 2,
		"deux identifiants DISTINCTS — un doublon aurait été refusé")
	for key: StringName in _places_under_test():
		var poi: PointOfInterest = places.site_poi(key)
		check_not_null(poi, "le souterrain « %s » porte un point d'intérêt" % key)
		if poi != null:
			check(not String(poi.region).is_empty(),
				"…rattaché à une région (souterrain « %s »)" % key)
	check_equal(journal.discovered_count(), 0,
		"rien n'est découvert avant d'y être allé")
	await _close(places)


# --- LA preuve : un véritable espace explorable ------------------------------

## Cœur du gate. Le corps est lâché au point donné : s'il tombe, il n'y a pas
## de sol et la « salle » est un trou décoratif. Un rayon vertical exige en
## plus un plafond — sans lui, ce ne serait qu'un enclos à ciel ouvert.
func _assert_standing_room(places: ValleyUndergrounds, inside: Vector3,
		floor_y: float, label: String) -> void:
	var body: CharacterBody3D = _spawn_body(inside)
	await _drop(body)
	check(body.is_on_floor(),
		"%s : le corps se pose sur un SOL porteur (y = %.2f)"
		% [label, body.global_position.y])
	check(body.global_position.y > floor_y - 0.6,
		"%s : …au niveau de la salle et non au fond du monde (sol y = %.2f)"
		% [label, floor_y])
	var space: PhysicsDirectSpaceState3D = places.get_world_3d().direct_space_state
	var origin: Vector3 = body.global_position + Vector3(0, 0.2, 0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin, origin + Vector3(0, 6.0, 0), 1)
	# Le corps lui-même est exclu : on cherche la roche, pas la capsule.
	var excluded: Array[RID] = [body.get_rid()]
	query.exclude = excluded
	var hit: Dictionary = space.intersect_ray(query)
	check(not hit.is_empty(),
		"%s : un PLAFOND couvre le point de station" % label)
	if not hit.is_empty():
		var ceiling: Vector3 = hit.get("position")
		check(ceiling.y - body.global_position.y
				> ValleyUndergrounds.MIN_CLEARANCE - 0.9,
			"%s : …assez haut pour s'y tenir debout (%.2f m de dégagement)"
			% [label, ceiling.y - body.global_position.y])
	_despawn(body)
	await _settle(1)


func test_the_hidden_passage_is_a_room_you_can_stand_in() -> void:
	var places: ValleyUndergrounds = await _open()
	var key: StringName = ValleyUndergrounds.UNDER_PASSAGE
	await _assert_standing_room(places, places.interior_point(key),
		places.floor_level(key), "Passage dérobé — vestibule")
	# La chambre haute est un volume à part entière, pas un simple débouché.
	await _assert_standing_room(places, places.second_room_point(key),
		places.exit_floor_level(key), "Passage dérobé — chambre haute")
	await _close(places)


func test_the_crystal_hollow_is_a_room_you_can_stand_in() -> void:
	var places: ValleyUndergrounds = await _open()
	var key: StringName = ValleyUndergrounds.UNDER_CRYSTAL
	await _assert_standing_room(places, places.interior_point(key),
		places.floor_level(key), "Cavité de cristal — salle")
	await _assert_standing_room(places, places.second_room_point(key),
		places.floor_level(key), "Cavité de cristal — galerie d'entrée")
	await _close(places)


# --- Les bouches sont franchissables ----------------------------------------

## Un volume creux dont on ne peut pas franchir le seuil resterait décoratif.
## Le corps est posé DEHORS, devant la bouche, puis poussé vers l'intérieur :
## il doit progresser d'au moins 3,5 m — de quoi traverser jambages et linteau
## — et rester debout.
func _assert_you_can_walk_in(outside: Vector3, inward: Vector3,
		label: String) -> void:
	var body: CharacterBody3D = _spawn_body(outside)
	await _drop(body, 60)
	check(body.is_on_floor(),
		"%s : le seuil est de plain-pied, on tient devant la bouche" % label)
	var start: Vector3 = body.global_position
	var travelled: float = 0.0
	for i: int in range(180):
		body.velocity = inward * 5.0
		body.velocity.y = -6.0
		body.move_and_slide()
		await _tree().physics_frame
		travelled = (body.global_position - start).dot(inward)
		if travelled >= 4.0:
			break
	# GDScript ne concatène PAS deux littéraux adjacents comme Python : sans le
	# `+`, l'analyseur attend la parenthèse fermante et rejette le fichier.
	check(travelled >= 3.5,
		("%s : le corps ENTRE par le seuil (%.2f m franchis, seuil ≥ %.1f m "
		+ "de large et ≥ %.1f m de haut)")
		% [label, travelled, ValleyUndergrounds.MIN_GAP,
			ValleyUndergrounds.MIN_CLEARANCE])
	check(body.is_on_floor(),
		"%s : …et se tient toujours sur un sol une fois dedans" % label)
	_despawn(body)
	await _settle(1)


## Les DEUX extrémités du passage se franchissent — celle du bas comme celle
## du haut. Une sortie qu'on ne peut pas emprunter en sens inverse ferait du
## raccourci une porte à sens unique.
func test_both_mouths_of_the_hidden_passage_can_be_walked_through() -> void:
	var places: ValleyUndergrounds = await _open()
	var key: StringName = ValleyUndergrounds.UNDER_PASSAGE
	await _assert_you_can_walk_in(places.entrance_point(key),
		-places.door_normal(key), "Passage dérobé — bouche basse")
	await _assert_you_can_walk_in(places.exit_point(key),
		-places.exit_normal(key), "Passage dérobé — bouche haute")
	await _close(places)


func test_the_crystal_hollow_mouth_can_be_walked_through() -> void:
	var places: ValleyUndergrounds = await _open()
	var key: StringName = ValleyUndergrounds.UNDER_CRYSTAL
	await _assert_you_can_walk_in(places.entrance_point(key),
		-places.door_normal(key), "Cavité de cristal")
	# Une seule bouche : le lieu ne prétend PAS traverser.
	check(not places.is_through_passage(key),
		"la cavité annonce honnêtement sa bouche unique")
	await _close(places)


# --- LA preuve du raccourci : le boyau débouche ------------------------------

## Un raccourci qui ne mène nulle part n'est pas un raccourci. Le corps entre
## par la bouche basse et est poussé sans interruption vers le fond : il doit
## GAGNER de l'altitude — la galerie monte — et finir au niveau de la chambre
## haute, celle qui ouvre sur la terrasse du sommet.
func test_the_hidden_passage_really_comes_out_at_the_other_end() -> void:
	var places: ValleyUndergrounds = await _open()
	var key: StringName = ValleyUndergrounds.UNDER_PASSAGE
	check(places.is_through_passage(key),
		"le passage se déclare traversant")
	var gain_declared: float = places.elevation_gain(key)
	check(gain_declared >= 8.0,
		"les deux bouches sont à des HAUTEURS différentes (%.2f m d'écart)"
		% gain_declared)

	var inward: Vector3 = -places.door_normal(key)
	var body: CharacterBody3D = _spawn_body(places.entrance_point(key))
	await _drop(body, 60)
	var start_y: float = body.global_position.y
	var climbed: float = 0.0
	for i: int in range(600):
		body.velocity = inward * 8.0
		body.velocity.y = -1.5
		body.move_and_slide()
		await _tree().physics_frame
		climbed = body.global_position.y - start_y
		if climbed >= 8.0:
			break
	check(climbed >= 7.0,
		("le corps traverse le boyau et RESSORT en hauteur (%.2f m gagnés "
		+ "sans saut ni téléportation)") % climbed)
	# …et il ressort bien au niveau du haut, pas coincé à mi-pente.
	var exit_floor: float = places.exit_floor_level(key)
	check(body.global_position.y > exit_floor - 1.2,
		"il atteint le niveau de la sortie (y = %.2f, sol haut y = %.2f)"
		% [body.global_position.y, exit_floor])
	check(body.is_on_floor(),
		"…debout sur la roche, pas suspendu dans le vide")
	_despawn(body)
	await _settle(1)
	await _close(places)


## Dans l'autre sens : depuis la chambre haute, le même boyau ramène en bas.
## Un passage à sens unique piégerait le joueur en cas de demi-tour.
func test_the_hidden_passage_can_be_walked_back_down() -> void:
	var places: ValleyUndergrounds = await _open()
	var key: StringName = ValleyUndergrounds.UNDER_PASSAGE
	# La descente suit la normale sortante de la bouche BASSE : depuis le haut,
	# c'est la direction qui redescend vers le vestibule puis vers la plaine.
	var downward: Vector3 = places.door_normal(key)
	var body: CharacterBody3D = _spawn_body(places.second_room_point(key))
	await _drop(body, 90)
	var start_y: float = body.global_position.y
	var dropped: float = 0.0
	for i: int in range(600):
		body.velocity = downward * 8.0
		body.velocity.y = -4.0
		body.move_and_slide()
		await _tree().physics_frame
		dropped = start_y - body.global_position.y
		if dropped >= 8.0:
			break
	check(dropped >= 7.0,
		"le boyau se redescend aussi (%.2f m perdus vers le vestibule)"
		% dropped)
	check(body.global_position.y < places.floor_level(key) + 1.5,
		"…et ramène au niveau de la plaine (y = %.2f, sol bas y = %.2f)"
		% [body.global_position.y, places.floor_level(key)])
	_despawn(body)
	await _settle(1)
	await _close(places)


## Le raccourci ne vaut que si l'éperon est un VRAI obstacle. Un rayon tiré à
## hauteur d'homme le long du flanc, à neuf mètres de l'axe du boyau, doit
## rencontrer la roche : sans le passage, il faut contourner le massif.
func test_the_spur_makes_the_passage_worth_taking() -> void:
	var places: ValleyUndergrounds = await _open()
	var key: StringName = ValleyUndergrounds.UNDER_PASSAGE
	var root: Node3D = places.site_root(key)
	check_not_null(root, "le passage a une racine")
	if root != null:
		var from: Vector3 = root.to_global(Vector3(9.0, 1.5, 14.0))
		var to: Vector3 = root.to_global(Vector3(9.0, 1.5, -40.0))
		var space: PhysicsDirectSpaceState3D = \
			places.get_world_3d().direct_space_state
		var query: PhysicsRayQueryParameters3D = \
			PhysicsRayQueryParameters3D.create(from, to, 1)
		var hit: Dictionary = space.intersect_ray(query)
		check(not hit.is_empty(),
			"le flanc de l'éperon est une masse PLEINE — on ne le traverse pas")
		if not hit.is_empty():
			var at: Vector3 = hit.get("position")
			check(from.distance_to(at) < 20.0,
				("la roche barre la route dès %.1f m — le détour est réel, "
				+ "le boyau fait gagner du chemin") % from.distance_to(at))
	# Les deux bouches sont franchement éloignées : ce n'est pas un trou de
	# souris percé dans un talus d'un mètre.
	var span: Vector3 = places.exit_point(key) - places.entrance_point(key)
	var flat: float = Vector2(span.x, span.z).length()
	check(flat >= 40.0,
		"les deux bouches sont à %.1f m l'une de l'autre à plat" % flat)
	await _close(places)


# --- Implantation ------------------------------------------------------------

## Les souterrains ne doivent chevaucher aucun lieu déjà bâti, ni les trois
## grottes de `ValleyCaves`.
func test_the_undergrounds_stand_clear_of_the_existing_landmarks() -> void:
	var places: ValleyUndergrounds = await _open()
	var landmarks: Array[Array] = [
		["village de la rivière", Vector3(-70, 2, 36)],
		["hameau des bûcherons", Vector3(110, 2, 40)],
		["poste minier", Vector3(-68, 2, 86)],
		["camp ennemi", Vector3(45, 6, 65)],
		["pylône", Vector3(115, 18, -25)],
		["donjon", Vector3(0, 34, -210)],
		["crête de départ", Vector3(0, 24, 170)],
		["ruine de guet", Vector3(-128, 14, 82)],
		["arbre ancien", Vector3(-96, 2, -62)],
		["caravane d'orage", Vector3(-38, 2, -120)],
		["grotte de la cascade", Vector3(-118, 2, 26)],
		["mine abandonnée", Vector3(160, 2, -70)],
		["crypte oubliée", Vector3(-60, 2, -90)],
	]
	for key: StringName in _places_under_test():
		var site: Vector3 = places.interior_point(key)
		for landmark: Array in landmarks:
			var label: String = landmark[0]
			var at: Vector3 = landmark[1]
			var flat: float = Vector2(site.x - at.x, site.z - at.z).length()
			check(flat > 30.0,
				"le souterrain « %s » reste à l'écart du %s (%.1f m)"
				% [key, label, flat])
	# Et dans les limites du monde : la chaîne frontalière est à ±250 m.
	for key: StringName in _places_under_test():
		var site: Vector3 = places.interior_point(key)
		check(absf(site.x) < 240.0 and absf(site.z) < 240.0,
			"le souterrain « %s » tient dans la vallée jouable (%v)"
			% [key, site])
	await _close(places)


## Un souterrain sans raison d'y aller n'est qu'un couloir. Chacun contient au
## moins une récompense et un indice repérables dans son arbre.
func test_each_underground_gives_a_reason_to_go_in() -> void:
	var places: ValleyUndergrounds = await _open()
	var rewards: Dictionary = {
		ValleyUndergrounds.UNDER_PASSAGE: ["Chest_Wood", "Chevron"],
		ValleyUndergrounds.UNDER_CRYSTAL: ["Chest_Wood", "AmasCristal", "Eclat"],
	}
	for key: StringName in _places_under_test():
		var root: Node3D = places.site_root(key)
		check_not_null(root, "le souterrain « %s » a une racine" % key)
		if root == null:
			continue
		var wanted: Array = rewards[key]
		for prefix: String in wanted:
			var found: Array[Node] = root.find_children("%s*" % prefix, "",
				true, false)
			check(found.size() > 0,
				"le souterrain « %s » contient « %s » — une raison d'entrer"
				% [key, prefix])
	await _close(places)
