## LE CAMP EST COMPOSÉ EN TRIANGLE — repos / cuisine-stockage / garde-armes.
##
## POURQUOI CE TEST. Passe 3 (2026-08-12), défaut n°4 de la revue Codex :
## « recompose le camp en triangle repos/cuisine/garde avec des groupes
## d'activité, des vides intentionnels et une silhouette lisible ».
## VISUAL_ASSET_BIBLE §10.1 : « Trois groupes fonctionnels forment un
## triangle : repos/auvent, stockage/cuisine, garde/armes », camp lisible à
## 70-110 m par la flamme, DEUX bannières et les silhouettes.
##
## MESURÉ AVANT correction : le râtelier d'armes vivait au nord (43,5 ; 70),
## l'enclume à l'ouest (41 ; 58), la charrette au sud (40 ; 50,5) et la
## clôture à z 79 — le « groupe garde » s'étalait sur 15 m ; le côté
## cuisine-garde du triangle faisait 8,7 m (les pôles se touchaient) ; une
## seule tente vivait près du coin repos ; une seule bannière au camp.
##
## Ce que la machine vérifie — le verdict d'image appartient à la revue :
##   1. chaque groupe d'activité est SERRÉ (≤ 8 m de son centroïde) ;
##   2. les trois pôles forment un vrai triangle (côtés ≥ 13 m) ;
##   3. les tentes dorment au pôle repos (≥ 2 à moins de 9 m) ;
##   4. la silhouette porte au moins DEUX bannières (§10.1) ;
##   5. le centre du triangle reste un VIDE intentionnel (aucun prop
##      à moins de 4,5 m) — la respiration, pas un dépotoir.
##
## La classification passe par les NOMS de modèles : un prop non listé
## (clôture de limite, galets du foyer) n'appartient à aucun pôle et
## n'entre pas dans les mesures 1-2 — mais compte pour le vide (5).
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const MAX_GROUP_SPREAD_M: float = 8.0
const MIN_TRIANGLE_SIDE_M: float = 13.0
const CENTER_VOID_RADIUS_M: float = 4.5

## Préfixes de modèles par pôle. Un nom de nœud CampLife est « Modèle_N ».
const KITCHEN_PREFIXES: Array[String] = ["Cauldron", "Table_Large", "Bench",
	"Stool", "Pot_1", "Mug", "Bottle_1", "Carrot", "Bucket_Wooden",
	"Barrel_Apples", "FarmCrate", "Bag", "Pouch_Large"]
const REST_PREFIXES: Array[String] = ["Roof_Wooden", "Bed_Twin", "CandleStick"]
const GUARD_PREFIXES: Array[String] = ["WeaponStand", "Sword_Bronze",
	"Shield_Wooden", "Stall_Cart", "Banner_", "Anvil", "Axe_Bronze",
	"Whetstone", "Rope_1"]


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _cleanup(world: Node) -> void:
	_tree().root.remove_child(world)
	world.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	var audio: Node = _tree().root.get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("stop_ambience"):
		audio.call("stop_ambience")
	await _tree().physics_frame


func _pole_of(node_name: String) -> String:
	for prefix: String in KITCHEN_PREFIXES:
		if node_name.begins_with(prefix):
			return "cuisine"
	for prefix: String in REST_PREFIXES:
		if node_name.begins_with(prefix):
			return "repos"
	for prefix: String in GUARD_PREFIXES:
		if node_name.begins_with(prefix):
			return "garde"
	return ""


func test_the_camp_composes_three_tight_separated_poles() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var life: Node3D = valley.find_child("CampLife", true, false) as Node3D
	check_not_null(life, "la vie du camp existe")
	if life == null:
		await _cleanup(valley)
		return
	var members: Dictionary = {"cuisine": [], "repos": [], "garde": []}
	var banners: int = 0
	for child: Node in life.get_children():
		var pole: String = _pole_of(String(child.name))
		if String(child.name).begins_with("Banner_"):
			banners += 1
		if pole.is_empty():
			continue
		var at: Vector3 = (child as Node3D).global_position
		(members[pole] as Array).append(Vector2(at.x, at.z))
	# 4. Silhouette : deux bannières (§10.1).
	check(banners >= 2, "le camp porte au moins deux bannières (%d)" % banners)
	# 1. Groupes serrés autour de leur centroïde.
	var centroids: Dictionary = {}
	for pole: String in members:
		var points: Array = members[pole] as Array
		check(points.size() >= 3, "le pôle %s a au moins 3 props (%d)"
			% [pole, points.size()])
		if points.is_empty():
			continue
		var sum: Vector2 = Vector2.ZERO
		for point: Vector2 in points:
			sum += point
		var centroid: Vector2 = sum / float(points.size())
		centroids[pole] = centroid
		var worst: float = 0.0
		for point: Vector2 in points:
			worst = maxf(worst, centroid.distance_to(point))
		check(worst <= MAX_GROUP_SPREAD_M,
			"le pôle %s est serré : pire écart %.1f m ≤ %.0f"
				% [pole, worst, MAX_GROUP_SPREAD_M])
	# 2. Les pôles forment un triangle, pas un tas.
	if centroids.size() == 3:
		var sides: Array[Array] = [["cuisine", "repos"], ["cuisine", "garde"],
			["repos", "garde"]]
		for side: Array in sides:
			var span: float = (centroids[side[0]] as Vector2).distance_to(
				centroids[side[1]] as Vector2)
			check(span >= MIN_TRIANGLE_SIDE_M,
				"côté %s-%s : %.1f m ≥ %.0f" % [side[0], side[1], span,
					MIN_TRIANGLE_SIDE_M])
		# 3. Les tentes dorment au pôle repos.
		var rest: Vector2 = centroids["repos"] as Vector2
		var sheltered: int = 0
		for tent: Node in valley.find_children("Tent?", "StaticBody3D",
				true, false):
			var at: Vector3 = (tent as StaticBody3D).global_position
			if rest.distance_to(Vector2(at.x, at.z)) <= 9.0:
				sheltered += 1
		check(sheltered >= 2,
			"au moins deux tentes au pôle repos (%d)" % sheltered)
		# 5. Le centre du triangle est un VIDE intentionnel.
		var center: Vector2 = ((centroids["cuisine"] as Vector2)
			+ (centroids["repos"] as Vector2)
			+ (centroids["garde"] as Vector2)) / 3.0
		var intruders: Array[String] = []
		var camp: Node3D = valley.find_child("CampDressing", true, false) as Node3D
		var candidates: Array[Node] = life.get_children()
		if camp != null:
			for child: Node in camp.get_children():
				if String(child.name).begins_with("CampProp_") \
						or String(child.name).begins_with("Tent"):
					candidates.append(child)
		for child: Node in candidates:
			if child is Node3D:
				var at: Vector3 = (child as Node3D).global_position
				if center.distance_to(Vector2(at.x, at.z)) < CENTER_VOID_RADIUS_M:
					intruders.append(String(child.name))
		check(intruders.is_empty(),
			"le centre du triangle (%.0f ; %.0f) reste un vide (intrus : %s)"
				% [center.x, center.y,
					", ".join(intruders) if not intruders.is_empty() else "aucun"])
	await _cleanup(valley)
