## LE CHEMIN APPARTIENT AU SOL — il n'est plus une bande posée sur l'herbe.
##
## POURQUOI CE TEST. V-005, P0 de l'audit du 2026-08-11 : « rampes et bandes
## vertes posées sur le sol », et le gate de la tranche échoue si un « chemin
## [est] lu comme une bande posée sur l'herbe ». La mesure d'emprise écran
## chiffrait le défaut : `PathStrip00` = 22,2 % du cadre d'ouverture pour UN
## rectangle rectiligne de largeur constante, sans épaisseur, flottant à
## 2 cm du sol d'un seul tenant.
##
## Ce qu'une bande a et qu'un chemin n'a pas — trois propriétés machine :
##   1. la PIÈCE UNIQUE : un vrai sentier est fait de courts tronçons qui se
##      chevauchent — aucune pièce ne dépasse 12 m ;
##   2. la LARGEUR CONSTANTE : un sentier respire — sur chaque segment, la
##      largeur varie réellement ;
##   3. la LIGNE PARFAITE : un sentier dévie — sur chaque segment, au moins
##      deux orientations distinctes.
## Et ce qu'un chemin doit GARDER de la correction ISS-039 : chaque tronçon
## épouse le sol RÉEL sous lui (le contrôle n'existait que pour PathStrip00 ;
## il couvre désormais toutes les pièces — c'est lui qui fait des paliers de
## la descente de vraies ruptures de niveau suivies par le chemin).
##
## Les ÉPAULEMENTS (herbe compressée sous les bords) et les pierres de bord
## vivent dans leur propre zone `PathEdges`, plaquée plus bas que les quads
## de terre pour que les deux couches ne se battent jamais.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const MAX_PIECE_LENGTH_M: float = 12.0


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


## Numéro de segment depuis le nom : « PathStrip03_02 » → 3, « PathStrip00 » → 0.
func _segment_of(piece_name: String) -> int:
	return piece_name.trim_prefix("PathStrip").substr(0, 2).to_int()


func test_no_path_piece_is_a_long_uniform_band() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var pieces: Array[Node] = valley.find_children("PathStrip*", "MeshInstance3D",
		true, false)
	check(pieces.size() >= 30,
		"le chemin est fait de courts tronçons (%d pièces)" % pieces.size())
	var widths: Dictionary[int, Vector2] = {}
	var yaws: Dictionary[int, Dictionary] = {}
	for piece: Node in pieces:
		var quad: MeshInstance3D = piece as MeshInstance3D
		var plane: PlaneMesh = quad.mesh as PlaneMesh
		check_not_null(plane, "%s reste un plan sans tranche" % quad.name)
		if plane == null:
			continue
		check(plane.size.x <= MAX_PIECE_LENGTH_M,
			"%s fait %.1f m ≤ 12 (la bande d'un seul tenant faisait 43 m)"
				% [quad.name, plane.size.x])
		var segment: int = _segment_of(String(quad.name))
		var seen: Vector2 = widths.get(segment, Vector2(INF, -INF))
		widths[segment] = Vector2(minf(seen.x, plane.size.y),
			maxf(seen.y, plane.size.y))
		var segment_yaws: Dictionary = yaws.get(segment, {})
		segment_yaws[snappedf(quad.rotation.y, 0.017)] = true   # classes de ~1°
		yaws[segment] = segment_yaws
	for segment: int in widths:
		check(widths[segment].y - widths[segment].x >= 0.4,
			"segment %02d : la largeur respire (%.1f à %.1f m)"
				% [segment, widths[segment].x, widths[segment].y])
	for segment: int in yaws:
		check((yaws[segment] as Dictionary).size() >= 2,
			"segment %02d : au moins deux orientations (%d)"
				% [segment, (yaws[segment] as Dictionary).size()])
	await _cleanup(valley)


func test_every_path_piece_hugs_the_real_ground_under_it() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	await _tree().physics_frame
	var space: PhysicsDirectSpaceState3D = valley.player().get_world_3d() \
		.direct_space_state
	var floating: Array[String] = []
	for piece: Node in valley.find_children("PathStrip*", "MeshInstance3D",
			true, false):
		var quad: MeshInstance3D = piece as MeshInstance3D
		var at: Vector3 = quad.global_position
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			Vector3(at.x, at.y + 60.0, at.z), Vector3(at.x, at.y - 80.0, at.z), 1)
		var hit: Dictionary = space.intersect_ray(ray)
		if hit.is_empty():
			floating.append("%s (aucun sol)" % quad.name)
			continue
		var gap: float = at.y - (hit["position"] as Vector3).y
		if gap < 0.005 or gap > 0.08:
			floating.append("%s (%.3f m)" % [quad.name, gap])
	check(floating.is_empty(),
		"chaque tronçon épouse le sol réel (fautifs : %s)"
			% (", ".join(floating) if not floating.is_empty() else "aucun"))
	await _cleanup(valley)


func test_the_path_has_shoulders_and_stones_of_its_own() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var edges_zone: Node3D = valley.find_child("PathEdges", true, false) as Node3D
	check_not_null(edges_zone, "la zone des épaulements existe")
	if edges_zone != null:
		var shoulders: Array[Node] = edges_zone.find_children("PathEdge*",
			"MeshInstance3D", false, false)
		var stones: Array[Node] = edges_zone.find_children("PathStone*",
			"MeshInstance3D", false, false)
		var tongues: Array[Node] = edges_zone.find_children("PathGrass*",
			"MeshInstance3D", false, false)
		check(shoulders.size() >= 20,
			"l'herbe compressée borde le chemin (%d épaulements)" % shoulders.size())
		check(stones.size() >= 12,
			"des pierres jalonnent les bords (%d)" % stones.size())
		# Correction 7 : le CONTOUR du chemin doit se casser — la prairie mord
		# sur la terre par endroits, pas seulement à côté d'elle.
		check(tongues.size() >= 15,
			"la prairie reprend le chemin par endroits (%d langues)" % tongues.size())
		for node: Node in shoulders + stones:
			check_equal((node as MeshInstance3D).cast_shadow,
				GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
				"%s ne projette pas l'ombre d'une dalle" % node.name)
		check(edges_zone.find_children("*", "PhysicsBody3D", true, false).is_empty(),
			"les épaulements sont un décor sans collision")
	await _cleanup(valley)
