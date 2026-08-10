## Le décor des dix premières minutes REPOSE sur le sol qu'il habille.
##
## L'INCIDENT QUE CE TEST EMPÊCHE DE REVENIR. `PROGRESS.md` (2026-08-07) l'a
## déjà consigné pour les ramassables : « les deux fruits de la crête étaient
## ENTERRÉS de 8,00 m — sondé : sol à y = 32,00, pose à y = 24,00, la cote du
## spawn de MASTER_SPEC §3.3, jamais mise à jour quand le relief a été bâti ».
## Le correctif d'alors n'a touché QUE les ramassables
## (`ValleyWorld._drop_pickups_to_ground`). Le DÉCOR, lui, est resté posé à sa
## cote écrite à la main : `ValleyTerrain._dress_zone()` pose chaque pièce au
## `Vector3` littéral de sa table, sans jamais sonder le terrain.
##
## Conséquence exacte : fleurs, trèfle, fougères, touffes et galets de la crête
## — c'est-à-dire le TOUT PREMIER plan que le joueur voit — sont avalés par la
## colline et n'existent pour personne.
##
## POURQUOI LA SONDE EXISTANTE NE SUFFISAIT PAS. `probe_world_boxes.gd` tire
## son rayon depuis 40 cm sous la pièce : pour une pièce ENTERRÉE, ce départ est
## à l'intérieur du terrain, le rayon en sort sans le voir et rapporte la plaine
## du dessous. Elle annonce donc « flotte à 22 m » là où la vérité est
## « enterrée de 8 m » — le signe est inversé, et le joueur lui-même est
## signalé flottant. Ici le rayon part de TRÈS HAUT, seule façon de trouver la
## SURFACE plutôt qu'une face intérieure.
##
## Ce test ne juge aucune beauté. Il vérifie une relation géométrique : le
## dessous d'une pièce de décor de terrain touche le terrain.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"

## Zones dont TOUTES les pièces sont du semis de terrain. `DressZoneCitadel`
## est volontairement exclue : ses bannières et ses torches sont accrochées à
## des murs, et les inclure ferait de ce test un menteur.
const TERRAIN_ZONES: Array[String] = ["DressZoneCrest", "DressZoneDescent"]

## Tolérance verticale. Une pièce de semis peut mordre un peu le sol ou le
## survoler d'un cheveu sans que personne ne le voie ; au-delà, elle décolle ou
## elle s'enterre. 0,50 m est large exprès — le défaut cherché se compte en
## mètres, et un seuil serré rendrait le test bavard sur du bruit de relief.
const TOLERANCE_M: float = 0.50

## Départ du rayon, bien au-dessus du plus haut relief habillé (crête ≈ 32 m).
const RAY_START_Y: float = 200.0
const RAY_END_Y: float = -50.0

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	await _settle(3)


func _open_valley() -> Node3D:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var valley: Node3D = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_root.add_child(valley)
	await _settle(12)
	return valley


## Boîte englobante MONDE d'un sous-arbre visuel, ou une boîte vide si la pièce
## ne porte aucune géométrie lisible.
func _world_box(root: Node3D) -> AABB:
	var merged: AABB = AABB()
	var first: bool = true
	for node: Node in root.find_children("*", "VisualInstance3D", true, false):
		var visual: VisualInstance3D = node as VisualInstance3D
		if visual == null or not visual.is_inside_tree():
			continue
		if visual is MeshInstance3D and (visual as MeshInstance3D).mesh == null:
			continue
		var world: AABB = visual.global_transform * visual.get_aabb()
		if first:
			merged = world
			first = false
		else:
			merged = merged.merge(world)
	return merged


## RIDs de tous les corps portés par le décor lui-même. Sans cette exclusion,
## le rayon venu du ciel heurterait le tronc de l'arbre qu'il est censé
## mesurer, et conclurait que l'arbre repose parfaitement sur lui-même.
func _dressing_body_rids(zones: Array[Node3D]) -> Array[RID]:
	var rids: Array[RID] = []
	for zone: Node3D in zones:
		for node: Node in zone.find_children("*", "PhysicsBody3D", true, false):
			var body: PhysicsBody3D = node as PhysicsBody3D
			if body != null:
				rids.append(body.get_rid())
	return rids


func test_the_opening_dressing_is_neither_buried_nor_floating() -> void:
	var valley: Node3D = await _open_valley()
	var zones: Array[Node3D] = []
	for zone_name: String in TERRAIN_ZONES:
		var found: Array[Node] = valley.find_children(zone_name, "Node3D", true, false)
		check(not found.is_empty(), "zone de décor « %s » présente" % zone_name)
		if not found.is_empty():
			zones.append(found[0] as Node3D)

	var excluded: Array[RID] = _dressing_body_rids(zones)
	var space: PhysicsDirectSpaceState3D = \
		valley.get_world_3d().direct_space_state
	var offenders: Array[String] = []
	var measured: int = 0

	for zone: Node3D in zones:
		for child: Node in zone.get_children():
			var piece: Node3D = child as Node3D
			if piece == null:
				continue
			var box: AABB = _world_box(piece)
			if box.size == Vector3.ZERO:
				continue
			var centre: Vector3 = box.get_center()
			var query: PhysicsRayQueryParameters3D = \
				PhysicsRayQueryParameters3D.create(
					Vector3(centre.x, RAY_START_Y, centre.z),
					Vector3(centre.x, RAY_END_Y, centre.z), 1)
			query.exclude = excluded
			var hit: Dictionary = space.intersect_ray(query)
			if hit.is_empty():
				offenders.append("%s : aucun sol trouvé sous (%.1f, %.1f)"
					% [piece.name, centre.x, centre.z])
				continue
			var surface: float = (hit["position"] as Vector3).y
			var gap: float = box.position.y - surface
			measured += 1
			if absf(gap) > TOLERANCE_M:
				var verb: String = "ENTERRÉE de" if gap < 0.0 else "flotte à"
				offenders.append("%s : %s %.2f m (dessous %.2f, sol %.2f)"
					% [piece.name, verb, absf(gap), box.position.y, surface])

	check(measured > 0, "au moins une pièce de décor a été mesurée")
	check(offenders.is_empty(),
		"les %d pièces de décor de la crête et de la descente touchent le sol ; "
		% measured + "écarts : %s" % "; ".join(offenders))
	await _teardown()
