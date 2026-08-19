## V2.3 — FILET de COMPORTEMENT des lieux : la grotte se traverse, le
## bassin conducteur garde SON comportement, les récompenses canoniques
## sont raccordées par les interfaces existantes, le pylône est un repère.
##
## Écrit ROUGE d'abord (2026-08-14, directive V2.3 §6) : aucun lieu
## n'existe au moment de l'écriture — chaque test nomme l'absence. Vert
## seulement quand V2.3-A a livré le lot pilote raccordé.
##
## Ce que ce filet attrape (directive §6) : grotte sans issue sûre ou
## softlock · comportement du bassin modifié · récompense/découverte mal
## raccordée · pylône réduit à un accessoire.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"

## Pas d'échantillonnage du chemin de grotte, et marche maximale entre
## deux échantillons (un pas de 0,55 m se franchit, une falaise non).
const CAVE_STEP_M: float = 0.4
const CAVE_MAX_RISE_M: float = 0.55
## Hauteur libre exigée au-dessus du sol sur tout le chemin.
const CAVE_HEADROOM_M: float = 1.75
## Le plafond de la poche intérieure doit exister à moins de cette hauteur.
const CAVE_CEILING_MAX_M: float = 8.0
## Silhouette contractuelle du pylône (VISUAL_ASSET_BIBLE §11.2).
const PYLON_MIN_HEIGHT_M: float = 26.0
const PYLON_MAX_HEIGHT_M: float = 40.0

## Classe de récompense canonique attendue par lieu pilote — dérivée de la
## prose `reward` du layout, épinglée en littéral (un remplacement muet
## d'un coffre par un ramassage rougit ici).
const EXPECTED_REWARD_CLASS: Dictionary = {
	&"valley.poi.riverside_village.01": "WeaponPickup",
	&"valley.poi.abandoned_farm.01": "IngredientPickup",
	&"valley.poi.stone_bridge.01": "StoryFragment",
	&"valley.poi.waterfall_cave.01": "IngredientPickup",
	&"valley.poi.thunderstruck_tree.01": "IngredientPickup",
	&"valley.poi.ember_raider_camps.01": "Chest",
	&"valley.poi.conductive_basin.01": "Chest",
}

var _world: Node3D = null


func test_la_grotte_a_un_seuil_et_un_interieur_praticables() -> void:
	await _mount()
	var faults: Array[String] = []
	var cave: Node3D = _place(&"valley.poi.waterfall_cave.01")
	if cave == null:
		faults.append("waterfall_cave : lieu ABSENT (resté marqueur)")
	else:
		var threshold: Variant = cave.get_meta(&"cave_threshold", null)
		var interior: Variant = cave.get_meta(&"cave_interior", null)
		if not (threshold is Vector3) or not (interior is Vector3):
			faults.append("waterfall_cave : metas cave_threshold/cave_interior absentes")
		else:
			var from_p: Vector3 = cave.to_global(threshold as Vector3)
			var to_p: Vector3 = cave.to_global(interior as Vector3)
			# Depuis GM4, le lieu publie sa route canonique COURBE : la
			# marcher jambe par jambe. Sans meta (fallback R2a-3.4), la
			# corde droite reste le contrat.
			var jalons: Array[Vector3] = [from_p]
			var route: Variant = cave.get_meta(&"cave_route", null)
			if route is Array:
				for etape: Variant in (route as Array):
					if etape is Vector3:
						jalons.append(cave.to_global(etape as Vector3))
			jalons.append(to_p)
			for i: int in range(jalons.size() - 1):
				faults.append_array(_walk_faults(jalons[i], jalons[i + 1],
					"seuil→intérieur (jambe %d)" % i))
			for i: int in range(jalons.size() - 1, 0, -1):
				faults.append_array(_walk_faults(jalons[i], jalons[i - 1],
					"intérieur→seuil (jambe %d)" % i))
			# La poche est COUVERTE : un rayon vertical depuis l'intérieur
			# touche un plafond proche — sinon ce n'est qu'une tranchée.
			var interior_ground: float = _ground_at(to_p)
			if interior_ground > -1e8:
				var ceiling: Dictionary = _ray(
					Vector3(to_p.x, interior_ground + 0.4, to_p.z),
					Vector3(to_p.x, interior_ground + CAVE_CEILING_MAX_M, to_p.z))
				if ceiling.is_empty():
					faults.append("waterfall_cave : aucun plafond à moins de %.0f m — pas une poche intérieure"
						% CAVE_CEILING_MAX_M)
	check(faults.is_empty(),
		"la grotte a un seuil et un intérieur praticables (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(faults.slice(0, 5))])
	await _unmount()


func test_le_bassin_conducteur_garde_son_comportement() -> void:
	await _mount()
	var faults: Array[String] = []
	var place: Node3D = _place(&"valley.poi.conductive_basin.01")
	if place == null:
		faults.append("conductive_basin : lieu ABSENT (resté marqueur)")
	else:
		var basins: Array[Node] = place.find_children("*", "ConductiveBasin",
			true, false)
		if basins.is_empty():
			faults.append("conductive_basin : aucun ConductiveBasin (le comportement canonique) dans le lieu")
		else:
			var basin: ConductiveBasin = basins[0] as ConductiveBasin
			if basin.source() == null or basin.water() == null \
					or basin.receiver() == null:
				faults.append("conductive_basin : source/eau/récepteur incomplets")
			var graphs: Array[Node] = basin.find_children("*", "ElectricGraph",
				false, false)
			if graphs.is_empty():
				faults.append("conductive_basin : le graphe électrique n'est pas ENFANT du bassin")
			elif basin.receiver() != null:
				(graphs[0] as ElectricGraph).recompute()
				if basin.receiver().is_powered():
					faults.append("conductive_basin : le récepteur est alimenté SANS lien — le circuit n'attend plus")
	check(faults.is_empty(),
		"le bassin conducteur garde son comportement (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(faults.slice(0, 5))])
	await _unmount()


func test_les_recompenses_canoniques_sont_raccordees() -> void:
	await _mount()
	var faults: Array[String] = []
	for place_id: StringName in EXPECTED_REWARD_CLASS.keys():
		var place: Node3D = _place(place_id)
		if place == null:
			faults.append("%s : lieu ABSENT" % place_id)
			continue
		var anchors: Array[Node] = place.find_children("AncrageRecompense",
			"RewardAnchor", true, false)
		if anchors.is_empty():
			faults.append("%s : aucune AncrageRecompense" % place_id)
			continue
		var expected: String = EXPECTED_REWARD_CLASS[place_id] as String
		var found: bool = false
		var wrong: String = ""
		for anchor: Node in anchors:
			for child: Node in anchor.get_children():
				if child.is_class("Node3D") or child is Node3D:
					var reward_class: String = _reward_class_of(child)
					if reward_class == expected:
						found = true
					elif reward_class != "":
						wrong = reward_class
		if not found:
			faults.append("%s : récompense %s absente%s" % [place_id, expected,
				" (trouvé %s)" % wrong if wrong != "" else ""])
		var pois: Array[Node] = place.find_children("*", "PointOfInterest",
			true, false)
		if pois.is_empty():
			faults.append("%s : aucun PointOfInterest (découverte)" % place_id)
	# Le camp n'a pas de récompense de POI, mais son feu de cuisine est
	# l'interactable canonique du checkpoint.
	var camp: Node3D = _place(&"camp")
	if camp == null:
		faults.append("camp : lieu ABSENT")
	else:
		var fires: Array[Node] = camp.find_children("*", "Campfire", true, false)
		if fires.is_empty():
			faults.append("camp : aucun Campfire")
		elif not (fires[0] as Node).is_in_group("interactable"):
			faults.append("camp : le feu n'est pas interactable")
	var shown: Array[String] = faults.slice(0, 6)
	if faults.size() > 6:
		shown.append("… et %d autres" % (faults.size() - 6))
	check(faults.is_empty(),
		"les récompenses canoniques sont raccordées (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(shown)])
	await _unmount()


func test_le_pylone_est_un_repere_majeur() -> void:
	await _mount()
	var faults: Array[String] = []
	var pylon: Node3D = _place(&"pylon")
	if pylon == null:
		faults.append("pylon : lieu ABSENT (resté marqueur)")
	else:
		var bounds: AABB = _visual_bounds(pylon)
		var height: float = bounds.size.y
		if height < PYLON_MIN_HEIGHT_M or height > PYLON_MAX_HEIGHT_M:
			faults.append("pylon : %.1f m de haut, contrat [%.0f, %.0f]"
				% [height, PYLON_MIN_HEIGHT_M, PYLON_MAX_HEIGHT_M])
		var mesh_count: int = pylon.find_children("*", "MeshInstance3D",
			true, false).size()
		if mesh_count < 8:
			faults.append("pylon : %d maillage(s) — pas une architecture (base, contreforts, fût, anneau, couronne)"
				% mesh_count)
	check(faults.is_empty(),
		"le pylône est un repère majeur (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(faults.slice(0, 5))])
	await _unmount()


## -- outillage ----------------------------------------------------------------

func _mount() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame


func _unmount() -> void:
	var clean: bool = await restore_root()
	check(clean, "démontage propre (comportement des lieux) — %s"
		% restore_root_reason())
	restore_saves()


func _place(place_id: StringName) -> Node3D:
	for node: Node in _world.get_tree().get_nodes_in_group(&"world_v2_places"):
		if node.get_meta(&"place_id", &"") as StringName == place_id:
			return node as Node3D
	return null


func _reward_class_of(node: Node) -> String:
	if node is Chest:
		return "Chest"
	if node is WeaponPickup:
		return "WeaponPickup"
	if node is IngredientPickup:
		return "IngredientPickup"
	if node is StoryFragment:
		return "StoryFragment"
	return ""


## Chemin praticable : sol continu (marches ≤ 0,55 m) et hauteur libre
## ≥ 1,75 m sur des échantillons de 0,4 m entre deux points.
func _walk_faults(from_p: Vector3, to_p: Vector3, label: String) -> Array[String]:
	var faults: Array[String] = []
	var flat: Vector2 = Vector2(to_p.x - from_p.x, to_p.z - from_p.z)
	var total: float = flat.length()
	if total < 0.5:
		return ["grotte %s : trajet trop court (%.1f m)" % [label, total]]
	var previous_ground: float = 1e9
	var walk: float = 0.0
	while walk <= total:
		var t: float = walk / total
		var p: Vector3 = from_p.lerp(to_p, t)
		# SONDE CONSCIENTE DES SURPLOMBS (GM4). Une grotte a un toit : une
		# sonde qui part de p.y + 3 traverse la visière du porche et lit
		# SON toit comme « sol » — mesuré à la promotion R2a-3.5.8 (faux
		# ressaut de +3,57 m au seuil, alors que le joueur y marche sous
		# 2 m de roche). Le sol d'un marcheur est le plancher CONTINU avec
		# son appui : premier échantillon depuis la hauteur d'intention du
		# méta (+1,0 m), les suivants depuis sol_précédent + marche_max +
		# 0,9 — toujours SOUS un plafond légal (headroom exigé 1,75 m) et
		# AU-DESSUS d'une marche légale (0,55 m).
		var origine_y: float = (p.y + 1.0) if previous_ground > 1e8 \
			else previous_ground + CAVE_MAX_RISE_M + 0.9
		var sonde: Dictionary = _ray(Vector3(p.x, origine_y, p.z),
			Vector3(p.x, origine_y - 8.0, p.z))
		var ground: float = (sonde["position"] as Vector3).y \
			if not sonde.is_empty() else -1e9
		if ground < -1e8:
			faults.append("grotte %s : AUCUN SOL vers (%.1f, %.1f)"
				% [label, p.x, p.z])
			return faults
		if previous_ground < 1e8 and ground - previous_ground > CAVE_MAX_RISE_M:
			faults.append("grotte %s : marche de %.2f m vers (%.1f, %.1f)"
				% [label, ground - previous_ground, p.x, p.z])
			return faults
		var headroom: Dictionary = _ray(
			Vector3(p.x, ground + 0.15, p.z),
			Vector3(p.x, ground + 0.15 + CAVE_HEADROOM_M, p.z))
		if not headroom.is_empty():
			faults.append("grotte %s : plafond à moins de %.2f m vers (%.1f, %.1f)"
				% [label, CAVE_HEADROOM_M, p.x, p.z])
			return faults
		previous_ground = ground
		walk += CAVE_STEP_M
	return faults


## Hauteur du premier sol physique sous un point (mask 1), ou -1e9.
func _ground_at(p: Vector3) -> float:
	var hit: Dictionary = _ray(Vector3(p.x, p.y + 3.0, p.z),
		Vector3(p.x, p.y - 8.0, p.z))
	if hit.is_empty():
		return -1e9
	return (hit["position"] as Vector3).y


func _ray(from_p: Vector3, to_p: Vector3) -> Dictionary:
	var space: PhysicsDirectSpaceState3D = _world.get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from_p, to_p, 1)
	return space.intersect_ray(query)


func _visual_bounds(place: Node3D) -> AABB:
	var merged: AABB = AABB()
	var first: bool = true
	for mesh_node: Node in place.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = mesh_node as MeshInstance3D
		if instance.mesh == null:
			continue
		var box: AABB = instance.global_transform * instance.mesh.get_aabb()
		if first:
			merged = box
			first = false
		else:
			merged = merged.merge(box)
	return merged
