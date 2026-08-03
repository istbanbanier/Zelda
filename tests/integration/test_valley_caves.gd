## GROTTES DE LA VALLÉE (ordre d'extension §2).
##
## Le point dur n'est pas « il y a trois grottes » — c'est la règle centrale de
## l'ordre : « les grottes doivent être de véritables espaces explorables, pas
## de simples trous décoratifs ». Un décor de bouches noires passerait
## n'importe quel comptage de nœuds.
##
## On fait donc, pour CHAQUE grotte, ce que le village fait pour son auberge :
## on pose un corps physique — la capsule du joueur, rayon 0,35, hauteur 1,7 —
## au point intérieur, on applique la gravité et on exige `is_on_floor()`. Un
## trou décoratif laisse tomber le corps ; un volume le porte.
##
## Trois preuves complémentaires ferment les échappatoires :
##   - un plafond au-dessus de la tête (rayon vertical), sinon c'est un enclos ;
##   - un seuil réellement franchissable (le corps entre depuis l'extérieur) ;
##   - trois identifiants §19.3 distincts au journal des découvertes.
extends GateTestCase


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open() -> ValleyCaves:
	var caves: ValleyCaves = ValleyCaves.new()
	_tree().root.add_child(caves)
	await _settle(6)
	return caves


func _close(caves: Node) -> void:
	caves.get_parent().remove_child(caves)
	caves.queue_free()
	await _settle(2)


## Capsule du joueur, montée à la main : le test ne doit rien devoir au
## contrôleur, seulement à la géométrie des grottes.
func _spawn_body(at: Vector3) -> CharacterBody3D:
	var body: CharacterBody3D = CharacterBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = ValleyCaves.PLAYER_RADIUS
	capsule.height = ValleyCaves.PLAYER_HEIGHT
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
func _caves_under_test() -> Array[StringName]:
	var keys: Array[StringName] = [ValleyCaves.CAVE_WATERFALL,
		ValleyCaves.CAVE_MINE, ValleyCaves.CAVE_CRYPT]
	return keys


# --- Existence --------------------------------------------------------------

func test_the_valley_holds_three_named_caves() -> void:
	var caves: ValleyCaves = await _open()
	for node_name: String in ["GrotteCascade", "MineAbandonnee", "CrypteOubliee"]:
		check_not_null(caves.get_node_or_null(node_name),
			"la vallée porte la grotte « %s » (§2)" % node_name)
	check_equal(caves.cave_keys().size(), 3,
		"trois grottes déclarées, pas une de moins")
	check(caves.piece_count() >= 100,
		"%d volumes et modèles posés — des espaces bâtis, pas des trous"
		% caves.piece_count())
	await _close(caves)


## §19.3 : chaque lieu a un identifiant stable, et deux lieux ne le partagent
## jamais — un doublon ferait se marquer découverts deux endroits à la fois.
func test_each_cave_declares_a_distinct_identifier() -> void:
	var caves: ValleyCaves = await _open()
	var journal: DiscoveryLog = DiscoveryLog.new()
	caves.bind_all(journal)
	var expected: Array[StringName] = [
		&"valley.poi.waterfall_cave.01",
		&"valley.poi.abandoned_mine.01",
		&"valley.poi.hollow_crypt.01",
	]
	for poi_id: StringName in expected:
		check(journal.is_registered(poi_id),
			"« %s » est déclaré au journal" % poi_id)
		check(not journal.display_name_of(poi_id).is_empty(),
			"…avec un nom affiché (obtenu « %s »)"
			% journal.display_name_of(poi_id))
	check_equal(journal.registered_count(), 3,
		"trois identifiants DISTINCTS — un doublon aurait été refusé")
	for key: StringName in _caves_under_test():
		var poi: PointOfInterest = caves.cave_poi(key)
		check_not_null(poi, "la grotte « %s » porte un point d'intérêt" % key)
		if poi != null:
			check(not String(poi.region).is_empty(),
				"…rattaché à une région (grotte « %s »)" % key)
	check_equal(journal.discovered_count(), 0,
		"rien n'est découvert avant d'y être allé")
	await _close(caves)


# --- LA preuve : un véritable espace explorable ------------------------------

## Cœur du gate. Le corps est lâché au point intérieur : s'il tombe, il n'y a
## pas de sol et la « grotte » est un trou décoratif.
func _assert_standing_room(caves: ValleyCaves, key: StringName,
		label: String) -> void:
	var inside: Vector3 = caves.interior_point(key)
	var floor_y: float = caves.floor_level(key)
	var body: CharacterBody3D = _spawn_body(inside)
	await _drop(body)
	check(body.is_on_floor(),
		"%s : le corps se pose sur un SOL porteur (y = %.2f)"
		% [label, body.global_position.y])
	check(body.global_position.y > floor_y - 0.6,
		"%s : …au niveau de la salle et non au fond du monde (sol y = %.2f)"
		% [label, floor_y])
	# Le corps est-il DEDANS ? Un rayon tiré vers le haut doit frapper un
	# plafond : sans lui, la « grotte » n'est qu'un enclos à ciel ouvert.
	var space: PhysicsDirectSpaceState3D = caves.get_world_3d().direct_space_state
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
		check(ceiling.y - body.global_position.y > ValleyCaves.MIN_CLEARANCE - 0.9,
			"%s : …assez haut pour s'y tenir debout (%.2f m de dégagement)"
			% [label, ceiling.y - body.global_position.y])
	_despawn(body)
	await _settle(1)


func test_the_waterfall_cave_is_a_room_you_can_stand_in() -> void:
	var caves: ValleyCaves = await _open()
	await _assert_standing_room(caves, ValleyCaves.CAVE_WATERFALL,
		"Grotte de la cascade")
	await _close(caves)


func test_the_abandoned_mine_is_a_room_you_can_stand_in() -> void:
	var caves: ValleyCaves = await _open()
	await _assert_standing_room(caves, ValleyCaves.CAVE_MINE,
		"Mine abandonnée")
	await _close(caves)


func test_the_forgotten_crypt_is_a_room_you_can_stand_in() -> void:
	var caves: ValleyCaves = await _open()
	await _assert_standing_room(caves, ValleyCaves.CAVE_CRYPT,
		"Crypte oubliée")
	await _close(caves)


# --- L'entrée est franchissable ---------------------------------------------

## Un volume creux dont on ne peut pas franchir le seuil resterait décoratif.
## Le corps est posé DEHORS, devant la bouche, puis poussé vers l'intérieur :
## il doit progresser d'au moins 3,5 m — de quoi traverser jambages et linteau —
## et rester debout.
func _assert_you_can_walk_in(caves: ValleyCaves, key: StringName,
		label: String) -> void:
	var outside: Vector3 = caves.entrance_point(key)
	var inward: Vector3 = -caves.door_normal(key)
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
	# GDScript ne concatène PAS deux littéraux adjacents comme Python : sans
	# le `+`, l'analyseur attend la parenthèse fermante et rejette le fichier.
	check(travelled >= 3.5,
		("%s : le corps ENTRE par le seuil (%.2f m franchis, seuil ≥ %.1f m "
		+ "de large et ≥ %.1f m de haut)")
		% [label, travelled, ValleyCaves.MIN_GAP, ValleyCaves.MIN_CLEARANCE])
	check(body.is_on_floor(),
		"%s : …et se tient toujours sur un sol une fois dedans" % label)
	_despawn(body)
	await _settle(1)


func test_every_cave_mouth_can_actually_be_walked_through() -> void:
	var caves: ValleyCaves = await _open()
	var labels: Dictionary = {
		ValleyCaves.CAVE_WATERFALL: "Grotte de la cascade",
		ValleyCaves.CAVE_MINE: "Mine abandonnée",
		ValleyCaves.CAVE_CRYPT: "Crypte oubliée",
	}
	for key: StringName in _caves_under_test():
		var label: String = labels[key]
		await _assert_you_can_walk_in(caves, key, label)
	await _close(caves)


# --- Implantation ------------------------------------------------------------

## Les grottes ne doivent chevaucher aucun lieu déjà bâti : le village de la
## rivière (−70, 2, 36), le camp (45, 6, 65), le pylône (115, 18, −25), le
## donjon (0, 34, −210) et la crête de départ (0, 24, 170).
func test_the_caves_stand_clear_of_the_existing_landmarks() -> void:
	var caves: ValleyCaves = await _open()
	var landmarks: Array[Array] = [
		["village de la rivière", Vector3(-70, 2, 36)],
		["camp ennemi", Vector3(45, 6, 65)],
		["pylône", Vector3(115, 18, -25)],
		["donjon", Vector3(0, 34, -210)],
		["crête de départ", Vector3(0, 24, 170)],
	]
	for key: StringName in _caves_under_test():
		var site: Vector3 = caves.interior_point(key)
		for landmark: Array in landmarks:
			var label: String = landmark[0]
			var at: Vector3 = landmark[1]
			var flat: float = Vector2(site.x - at.x, site.z - at.z).length()
			check(flat > 30.0,
				"la grotte « %s » reste à l'écart du %s (%.1f m)"
				% [key, label, flat])
	# Et dans les limites du monde : la chaîne frontalière est à ±250 m.
	for key: StringName in _caves_under_test():
		var site: Vector3 = caves.interior_point(key)
		check(absf(site.x) < 240.0 and absf(site.z) < 240.0,
			"la grotte « %s » tient dans la vallée jouable (%v)" % [key, site])
	await _close(caves)


## Une grotte sans raison d'y aller n'est qu'un couloir. Chacune contient au
## moins une récompense ou un indice repérable dans son arbre.
func test_each_cave_gives_a_reason_to_go_in() -> void:
	var caves: ValleyCaves = await _open()
	var rewards: Dictionary = {
		ValleyCaves.CAVE_WATERFALL: ["Chest_Wood", "Mushroom_Common"],
		ValleyCaves.CAVE_MINE: ["Chest_Wood", "Veine"],
		ValleyCaves.CAVE_CRYPT: ["Chest_Wood", "Trait"],
	}
	for key: StringName in _caves_under_test():
		var root: Node3D = caves.cave_root(key)
		check_not_null(root, "la grotte « %s » a une racine" % key)
		if root == null:
			continue
		var wanted: Array = rewards[key]
		for prefix: String in wanted:
			var found: Array[Node] = root.find_children("%s*" % prefix, "",
				true, false)
			check(found.size() > 0,
				"la grotte « %s » contient « %s » — une raison d'entrer"
				% [key, prefix])
	await _close(caves)
