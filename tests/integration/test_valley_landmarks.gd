## LIEUX NATURELS MÉMORABLES — preuve des cinq repères de la vallée.
##
## Ce qu'un test de comptage ne prouverait PAS, et que celui-ci vérifie :
##
##   §2 — un lieu n'est un lieu que s'il se DÉCLARE : cinq points d'intérêt aux
##        identifiants §19.3 DISTINCTS, enregistrés dans un journal neuf, et
##        qui ne récompensent qu'une fois.
##   §4 — « plusieurs destinations perceptibles depuis chaque point élevé » :
##        les cinq repères sont RÉPARTIS, jamais deux dans le même regard, et
##        aucun ne mord sur l'emprise du village de la rivière.
##   §7.5 — le champ de fleurs est une MASSE, donc un MultiMesh partitionné :
##        des centaines de nœuds séparés passeraient un test de densité et
##        couleraient la frame. On compte les instances ET les nœuds.
##   Le point dur — une grande masse de pierre qui ne porte pas de collision
##        est un décor. On fait donc POSER un corps physique sur le tablier du
##        pont naturel et sur le sommet du belvédère, on le fait TRAVERSER le
##        lit de la rivière par-dessus, et on mesure le tirant d'air dessous.
extends GateTestCase

## Gabarit du héros (§8.2) : c'est cette capsule-là qui doit tenir, pas une
## sphère de complaisance.
const BODY_RADIUS: float = 0.35
const BODY_HEIGHT: float = 1.7
## Moitié de la capsule : hauteur du CENTRE au repos au-dessus du sol touché.
const BODY_RISE: float = 0.85
const GRAVITY: float = 24.0
const STEP: float = 1.0 / 60.0

## Emprise du village de la rivière, que les repères doivent laisser libre.
const VILLAGE_RADIUS: float = 23.0
## Écart minimal entre deux repères : en deçà, ils se lisent comme un seul lieu.
const MIN_LANDMARK_GAP: float = 40.0


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open() -> ValleyLandmarks:
	var landmarks: ValleyLandmarks = ValleyLandmarks.new()
	_tree().root.add_child(landmarks)
	await _settle(6)
	return landmarks


func _close(landmarks: Node) -> void:
	landmarks.get_parent().remove_child(landmarks)
	landmarks.queue_free()
	await _settle(2)


func _spawn_body(at: Vector3) -> CharacterBody3D:
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


## Chute libre jusqu'au premier contact. Sans sol, la boucle va au bout et
## `is_on_floor()` reste faux — c'est exactement le verdict recherché.
func _drop(body: CharacterBody3D) -> void:
	for i: int in range(120):
		body.velocity.y -= GRAVITY * STEP
		body.move_and_slide()
		await _tree().physics_frame
		if body.is_on_floor():
			break


func _despawn(body: Node) -> void:
	body.get_parent().remove_child(body)
	body.queue_free()


## Distance au sol (plan XZ) : deux repères séparés de 40 m en horizontal ne
## sont pas « proches » parce que l'un est 20 m plus haut.
func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Boîte du volume d'approche d'un point d'intérêt.
func _poi_extent(poi: PointOfInterest) -> Vector3:
	for child: Node in poi.get_children():
		var shape: CollisionShape3D = child as CollisionShape3D
		if shape == null:
			continue
		var box: BoxShape3D = shape.shape as BoxShape3D
		if box != null:
			return box.size
	return Vector3.ZERO


## Cellules de MultiMesh d'un lieu, par préfixe de nom.
func _cells(place: Node3D, prefix: String) -> Array[MultiMeshInstance3D]:
	var found: Array[MultiMeshInstance3D] = []
	for child: Node in place.get_children():
		var cell: MultiMeshInstance3D = child as MultiMeshInstance3D
		if cell == null:
			continue
		if String(cell.name).begins_with(prefix):
			found.append(cell)
	return found


# ---------------------------------------------------------------------------
# 1. Les cinq lieux existent, à leur place, réellement bâtis
# ---------------------------------------------------------------------------

func test_the_five_landmarks_stand_where_the_map_says() -> void:
	var landmarks: ValleyLandmarks = await _open()

	var sites: Array[Array] = [
		["ArbreDoyen", ValleyLandmarks.SITE_ANCIENT_TREE],
		["SourceAuxReflets", ValleyLandmarks.SITE_SPRING],
		["ChampDeFleurs", ValleyLandmarks.SITE_FLOWER_FIELD],
		["ArcheDePierre", ValleyLandmarks.SITE_STONE_BRIDGE],
		["BelvedereDuGuetteur", ValleyLandmarks.SITE_OVERLOOK],
	]
	for entry: Array in sites:
		var place_name: String = entry[0]
		var site: Vector3 = entry[1]
		var place: Node3D = landmarks.get_node_or_null(place_name) as Node3D
		check_not_null(place, "le lieu « %s » est bâti" % place_name)
		if place == null:
			continue
		check(place.position.is_equal_approx(site),
			"…à son implantation %v (obtenu %v)" % [site, place.position])

	# Les pièces nommées de chaque lieu : ce sont elles qui portent la
	# collision et la silhouette, pas le nœud parent.
	var parts: Array[Array] = [
		["ArbreDoyen", "TroncDoyen"],
		["ArbreDoyen", "Racine0"],
		["ArbreDoyen", "Racine3"],
		["ArbreDoyen", "CampementAbandonne"],
		["SourceAuxReflets", "FondDuBassin"],
		["SourceAuxReflets", "NappeDEau"],
		["SourceAuxReflets", "Margelle0"],
		["SourceAuxReflets", "Margelle9"],
		["SourceAuxReflets", "Vasque2"],
		["ChampDeFleurs", "TroncSolitaire"],
		["ArcheDePierre", "Tablier"],
		["ArcheDePierre", "CuleeNord"],
		["ArcheDePierre", "CuleeSud"],
		["ArcheDePierre", "RampeNord"],
		["ArcheDePierre", "RampeSud"],
		["ArcheDePierre", "RampeDeRive"],
		["BelvedereDuGuetteur", "MasseSommet"],
		["BelvedereDuGuetteur", "Echine"],
		["BelvedereDuGuetteur", "EpauleEst"],
		["BelvedereDuGuetteur", "Contrefort3"],
		["BelvedereDuGuetteur", "PosteDeGuet"],
		["BelvedereDuGuetteur", "PosteDeGuet/Cairn"],
	]
	for entry: Array in parts:
		var path: String = "%s/%s" % [entry[0], entry[1]]
		check_not_null(landmarks.get_node_or_null(path),
			"le lieu porte sa pièce « %s »" % path)

	check(landmarks.piece_count() >= 120,
		"%d modèles du kit réellement posés — les lieux sont habités"
		% landmarks.piece_count())
	await _close(landmarks)


# ---------------------------------------------------------------------------
# 2. Chaque lieu se déclare, sous un identifiant qui n'appartient qu'à lui
# ---------------------------------------------------------------------------

func test_each_landmark_declares_a_distinct_point_of_interest() -> void:
	var landmarks: ValleyLandmarks = await _open()

	check_equal(landmarks.pois.size(), 5, "cinq points d'intérêt portés")
	var ids: Array[StringName] = landmarks.poi_ids()
	var unique: Dictionary = {}
	for id: StringName in ids:
		unique[id] = true
	check_equal(unique.size(), 5,
		"cinq identifiants DISTINCTS (§19.3) — aucun doublon")

	var expected: Dictionary = {
		ValleyLandmarks.POI_ANCIENT_TREE: "L'Arbre doyen",
		ValleyLandmarks.POI_SPRING: "La Source aux reflets",
		ValleyLandmarks.POI_FLOWER_FIELD: "Le Champ des mille fleurs",
		ValleyLandmarks.POI_STONE_BRIDGE: "L'Arche de pierre",
		ValleyLandmarks.POI_OVERLOOK: "Le Belvédère du guetteur",
	}
	var journal: DiscoveryLog = DiscoveryLog.new()
	for poi: PointOfInterest in landmarks.pois:
		poi.bind(journal)
	check_equal(journal.registered_count(), 5,
		"les cinq lieux entrent au journal des découvertes")

	var first_pass: bool = true
	var second_pass: bool = true
	for id: StringName in expected:
		check(journal.is_registered(id), "« %s » est déclaré" % id)
		check_equal(journal.display_name_of(id), String(expected[id]),
			"…avec son nom affiché")
		# La récompense n'est due qu'une fois : c'est la règle « aucune seconde
		# récompense après rechargement », vérifiée ici lieu par lieu.
		if not journal.visit(id):
			first_pass = false
		if journal.visit(id):
			second_pass = false
	check(first_pass, "chaque lieu se découvre à la PREMIÈRE arrivée")
	check(second_pass, "…et jamais une seconde fois")

	# Cinq régions différentes : le journal ne regroupe pas tout en un tas.
	var regions: Dictionary = journal.by_region()
	check_equal(regions.size(), 5,
		"cinq régions distinctes — l'exploration a un rythme")
	await _close(landmarks)


# ---------------------------------------------------------------------------
# 3. Le champ de fleurs est un MultiMesh partitionné, pas mille nœuds
# ---------------------------------------------------------------------------

func test_the_flower_field_is_a_multimesh_not_a_thousand_nodes() -> void:
	var landmarks: ValleyLandmarks = await _open()
	var field: Node3D = landmarks.get_node_or_null("ChampDeFleurs") as Node3D
	check_not_null(field, "le champ de fleurs est bâti")
	if field == null:
		await _close(landmarks)
		return

	var expected_cells: int = ValleyLandmarks.FIELD_CELLS * ValleyLandmarks.FIELD_CELLS
	var stems: Array[MultiMeshInstance3D] = _cells(field, "Tiges")
	var blooms: Array[MultiMeshInstance3D] = _cells(field, "Corolles")
	check_equal(stems.size(), expected_cells,
		"tiges PARTITIONNÉES (§7.5 interdit un MultiMesh unique)")
	check_equal(blooms.size(), expected_cells, "corolles partitionnées de même")

	var total: int = 0
	var thin_cell: String = ""
	for cell: MultiMeshInstance3D in blooms:
		var count: int = cell.multimesh.instance_count
		total += count
		if count < 300:
			thin_cell = "%s (%d)" % [cell.name, count]
	check(thin_cell == "",
		"chaque cellule porte une vraie masse de corolles ; maigre : %s"
		% ("aucune" if thin_cell == "" else thin_cell))
	check(total >= 1200,
		"%d corolles au total — une TACHE de couleur lisible depuis la crête"
		% total)
	check_equal(landmarks.bloom_count(), total,
		"le compteur du lieu correspond aux tampons réellement écrits")

	# La densité annoncée par la constante est-elle tenue ? Un champ deux fois
	# plus grand et deux fois plus creux passerait le seul comptage brut.
	var side: float = float(ValleyLandmarks.FIELD_CELLS) \
		* ValleyLandmarks.FIELD_CELL_SIZE
	var density: float = float(total) / (side * side)
	check(density >= ValleyLandmarks.FIELD_DENSITY * 0.85,
		"%.2f corolle/m² pour %.2f annoncée" % [density, ValleyLandmarks.FIELD_DENSITY])

	# LE point de §7.5 : la masse coûte des INSTANCES, pas des nœuds. Un semis
	# à un nœud par fleur ferait exploser ce compte.
	check(field.get_child_count() < 80,
		"%d nœuds directs pour %d corolles — la masse est instanciée, pas posée"
		% [field.get_child_count(), total])

	# Tiges et corolles vont par paires : une corolle sans tige flotte.
	var paired: bool = true
	for i: int in range(mini(stems.size(), blooms.size())):
		if stems[i].multimesh.instance_count != blooms[i].multimesh.instance_count:
			paired = false
	check(paired, "chaque corolle a sa tige (tampons de tailles égales)")
	await _close(landmarks)


# ---------------------------------------------------------------------------
# 4. Les vides du champ sont VOULUS — c'est ce qui fait lire la masse
# ---------------------------------------------------------------------------

func test_the_flower_field_keeps_the_gaps_that_make_it_readable() -> void:
	var landmarks: ValleyLandmarks = await _open()
	var field: Node3D = landmarks.get_node_or_null("ChampDeFleurs") as Node3D
	check_not_null(field, "le champ de fleurs est bâti")
	if field == null:
		await _close(landmarks)
		return

	var half: float = ValleyLandmarks.FIELD_CELL_SIZE * 0.5
	var checked: int = 0
	var in_tree_clearing: int = 0
	var on_path: int = 0
	var out_of_cell: int = 0
	var tints_seen: Dictionary = {}

	for cell: MultiMeshInstance3D in _cells(field, "Corolles"):
		# Sans fenêtre, le RenderingServer ne relit pas les tampons d'instance :
		# le lieu consigne origines et teintes en métadonnées, écrites par la
		# MÊME boucle que le tampon. On lit donc ce qui a été écrit.
		check(cell.has_meta(&"origins") and cell.has_meta(&"tints"),
			"%s expose son semis pour vérification" % cell.name)
		if not cell.has_meta(&"origins"):
			continue
		var origins: PackedVector3Array = cell.get_meta(&"origins")
		var tints: PackedColorArray = cell.get_meta(&"tints")
		check_equal(origins.size(), cell.multimesh.instance_count,
			"%s : le relevé couvre le tampon entier" % cell.name)

		# Centre de la cellule déduit de son nom (« Corolles » + ix + iz) :
		# une cellule dont les fleurs débordent n'est plus une partition.
		var suffix: String = String(cell.name).substr(len("Corolles"))
		var centre: Vector3 = Vector3.ZERO
		if suffix.length() == 2 and suffix.is_valid_int():
			centre = Vector3(
				(float(suffix.substr(0, 1).to_int()) - 0.5) * ValleyLandmarks.FIELD_CELL_SIZE,
				0.0,
				(float(suffix.substr(1, 1).to_int()) - 0.5) * ValleyLandmarks.FIELD_CELL_SIZE)

		for i: int in range(origins.size()):
			var spot: Vector3 = origins[i]
			checked += 1
			if spot.distance_to(ValleyLandmarks.FIELD_TREE_LOCAL) \
					< ValleyLandmarks.FIELD_TREE_CLEAR:
				in_tree_clearing += 1
			if absf(spot.z) <= ValleyLandmarks.FIELD_PATH_HALF:
				on_path += 1
			# 1,15 m : dispersion d'une grappe autour de son centre.
			if absf(spot.x - centre.x) > half + 1.2 \
					or absf(spot.z - centre.z) > half + 1.2:
				out_of_cell += 1
		for tint: Color in tints:
			tints_seen[tint] = true

	check(checked >= 1200, "%d corolles relevées" % checked)
	check_equal(in_tree_clearing, 0,
		"la clairière de l'arbre focal reste VIDE — c'est elle qui donne la silhouette")
	check_equal(on_path, 0, "le sentier traverse la masse sans être noyé")
	check_equal(out_of_cell, 0,
		"chaque cellule tient dans son emprise — la partition est réelle")
	check(tints_seen.size() >= ValleyLandmarks.COL_PETALS.size(),
		"%d teintes distinctes : blanches, jaunes ET bleues (§7.5)"
		% tints_seen.size())
	await _close(landmarks)


# ---------------------------------------------------------------------------
# 5. L'arche de pierre se franchit PAR-DESSUS
# ---------------------------------------------------------------------------

func test_you_can_walk_over_the_stone_bridge() -> void:
	var landmarks: ValleyLandmarks = await _open()
	var deck_top: float = ValleyLandmarks.SITE_STONE_BRIDGE.y \
		+ ValleyLandmarks.BRIDGE_DECK_Y
	var start: Vector3 = Vector3(ValleyLandmarks.SITE_STONE_BRIDGE.x,
		deck_top + 2.8, ValleyLandmarks.SITE_STONE_BRIDGE.z)
	var body: CharacterBody3D = _spawn_body(start)
	await _drop(body)

	check(body.is_on_floor(),
		"le corps se pose sur le TABLIER (y = %.2f)" % body.global_position.y)
	check(body.global_position.y > deck_top + 0.5
		and body.global_position.y < deck_top + 1.4,
		"…au niveau du tablier (attendu %.2f, obtenu %.2f)"
		% [deck_top + BODY_RISE, body.global_position.y])

	# Le pont est-il une TRAVERSÉE ou un socle ? On marche vers le nord, le
	# long de la portée, au-dessus du lit de la rivière.
	var from_z: float = body.global_position.z
	for i: int in range(90):
		body.velocity = Vector3(0.0, -2.0, 4.0)
		body.move_and_slide()
		await _tree().physics_frame
	check(body.is_on_floor(),
		"…et la marche reste PORTÉE sur toute la portée (y = %.2f)"
		% body.global_position.y)
	check(body.global_position.z - from_z > 3.0,
		"le lit de la rivière se franchit (%.1f m parcourus)"
		% (body.global_position.z - from_z))

	_despawn(body)
	await _close(landmarks)


# ---------------------------------------------------------------------------
# 6. …et se visite PAR-DESSOUS
# ---------------------------------------------------------------------------

func test_you_can_stand_under_the_stone_bridge() -> void:
	var landmarks: ValleyLandmarks = await _open()
	var space: PhysicsDirectSpaceState3D = landmarks.get_world_3d().direct_space_state
	# Centre de la travée, à hauteur d'homme : pieds à 0,15 m, tête à 1,85 m.
	var under: Vector3 = ValleyLandmarks.SITE_STONE_BRIDGE + Vector3(0.0, 1.0, 0.0)

	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.transform = Transform3D(Basis.IDENTITY, under)
	var blocked: Array[Dictionary] = space.intersect_shape(query, 4)
	check(blocked.is_empty(),
		"la travée est LIBRE sous le tablier (%d obstacle(s))" % blocked.size())

	# Un espace libre en plein air n'est pas un dessous de pont : il faut que
	# quelque chose passe AU-DESSUS.
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		under, under + Vector3(0.0, 6.0, 0.0), 1)
	var hit: Dictionary = space.intersect_ray(ray)
	check(not hit.is_empty(), "le tablier passe bien AU-DESSUS de ce point")
	if not hit.is_empty():
		var contact: Vector3 = hit.get("position")
		var clearance: float = contact.y - (under.y - BODY_RISE)
		check(clearance > 1.9,
			"%.2f m de tirant d'air — on passe dessous debout" % clearance)
	await _close(landmarks)


# ---------------------------------------------------------------------------
# 7. Le belvédère est un point élevé où l'on se TIENT
# ---------------------------------------------------------------------------

func test_the_watcher_summit_carries_a_body() -> void:
	var landmarks: ValleyLandmarks = await _open()
	var site: Vector3 = ValleyLandmarks.SITE_OVERLOOK
	var summit: float = site.y + ValleyLandmarks.OVERLOOK_SUMMIT_Y

	# Plateforme sommitale : centrée sur (0, ·, −13) local, à l'écart du cairn.
	var body: CharacterBody3D = _spawn_body(
		Vector3(site.x, summit + 3.0, site.z - 13.0))
	await _drop(body)
	check(body.is_on_floor(),
		"le sommet PORTE un corps (y = %.2f)" % body.global_position.y)
	check(body.global_position.y > summit + 0.5
		and body.global_position.y < summit + 1.4,
		"…à la cote du belvédère (attendu %.2f, obtenu %.2f)"
		% [summit + BODY_RISE, body.global_position.y])
	_despawn(body)

	# §4 : un point élevé sans montée ne sert à rien. L'échine doit porter à
	# mi-pente — z local 12, soit la moitié des 20 m de dénivelé.
	var mid: CharacterBody3D = _spawn_body(Vector3(site.x, site.y + 16.0, site.z + 12.0))
	await _drop(mid)
	check(mid.is_on_floor(),
		"l'échine porte à mi-pente (y = %.2f)" % mid.global_position.y)
	check(absf(mid.global_position.y - (site.y + 12.0 + BODY_RISE)) < 1.6,
		"…à mi-hauteur exactement (attendu %.2f, obtenu %.2f) : la montée est continue"
		% [site.y + 12.0 + BODY_RISE, mid.global_position.y])
	_despawn(mid)
	await _close(landmarks)


# ---------------------------------------------------------------------------
# 8. Répartition : cinq lieux, cinq regards, et le village laissé tranquille
# ---------------------------------------------------------------------------

func test_the_landmarks_are_spread_and_clear_of_the_village() -> void:
	var landmarks: ValleyLandmarks = await _open()
	check_equal(landmarks.pois.size(), 5, "cinq lieux à situer")

	# Aucun couple de repères ne se lit comme un seul lieu.
	var closest: float = INF
	var closest_pair: String = ""
	for i: int in range(landmarks.pois.size()):
		for j: int in range(i + 1, landmarks.pois.size()):
			var a: PointOfInterest = landmarks.pois[i]
			var b: PointOfInterest = landmarks.pois[j]
			var gap: float = _flat_distance(a.global_position, b.global_position)
			if gap < closest:
				closest = gap
				closest_pair = "%s / %s" % [a.display_name, b.display_name]
	check(closest >= MIN_LANDMARK_GAP,
		"repères SÉPARÉS : le couple le plus proche (%s) est à %.0f m"
		% [closest_pair, closest])

	# …et ils couvrent la vallée au lieu de se serrer dans un quadrant.
	var min_x: float = INF
	var max_x: float = -INF
	var min_z: float = INF
	var max_z: float = -INF
	for poi: PointOfInterest in landmarks.pois:
		min_x = minf(min_x, poi.global_position.x)
		max_x = maxf(max_x, poi.global_position.x)
		min_z = minf(min_z, poi.global_position.z)
		max_z = maxf(max_z, poi.global_position.z)
	check(max_x - min_x > 150.0,
		"les repères s'étalent sur %.0f m d'est en ouest" % (max_x - min_x))
	check(max_z - min_z > 150.0,
		"…et sur %.0f m du nord au sud" % (max_z - min_z))

	# Le village de la rivière est un lieu bâti ailleurs : aucun repère naturel
	# ne doit pousser dans son emprise.
	var intruder: String = ""
	for poi: PointOfInterest in landmarks.pois:
		var extent: Vector3 = _poi_extent(poi)
		var reach: float = maxf(extent.x, extent.z) * 0.5
		var gap: float = _flat_distance(poi.global_position, RiversideVillage.SITE)
		if gap < VILLAGE_RADIUS + reach:
			intruder = "%s (%.0f m, portée %.0f m)" % [poi.display_name, gap, reach]
	check(intruder == "",
		"aucun repère ne mord sur le village de la rivière ; en cause : %s"
		% ("aucun" if intruder == "" else intruder))
	await _close(landmarks)
