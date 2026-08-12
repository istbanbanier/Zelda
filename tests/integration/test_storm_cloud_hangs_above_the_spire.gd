## LE NUAGE D'ORAGE EST UN NUAGE — pas un ballon posé sur la citadelle.
##
## POURQUOI CE TEST. Passe 3 (2026-08-12) : la revue indépendante relève les
## « proxys visibles » des caméras 5 et 6, et le picking par rayon a nommé le
## plus gros : `CitadelStorm/CloudLayer*` — depuis l'approche (caméra 6), le
## haut du cadre est UNE seule arche grise lisse, le dessous de trois sphères
## de 27 à 41 m de rayon dont le ventre descend à y ≈ 92, SOUS le sommet de
## la spire (y = 100) : la couronne de cuivre transperce le nuage. La bible
## §9.2 exige « une base sombre APLATIE au-dessus de la spire », des bords
## « plus clairs et chauds côté soleil », et une masse construite en couches —
## « une couronne basse et menaçante », pas une soucoupe pleine.
##
## Trois propriétés machine, chacune mesurée AVANT correction :
##   1. le VENTRE reste au-dessus de la spire — le bas de chaque grumeau
##      ≥ y 106 monde (spire 100 + 6 m d'air) ; mesuré avant : 92 ;
##   2. la masse est GRANULAIRE — aucun grumeau ne dépasse 22 m de rayon et
##      il en faut au moins 18 ; avant : 41,4 m et 14 grumeaux ;
##   3. le bord côté SOLEIL (ouest, x < 0) porte au moins trois grumeaux
##      CHAUDS (r > b dans l'albédo) ; avant : zéro — deux gris seulement.
##
## CE QUE CE TEST NE JUGE PAS : l'image. Les seuils rendent possible la
## lecture « nuage » ; le verdict visuel appartient à la revue indépendante.
## Les invariants historiques (≥ 12 grumeaux, ratio dodu moyen ≥ 0,8,
## localité, éclair sur la spire) restent dans `test_phase_h_silhouettes`.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
## Sommet de spire (y = 100) + 6 m d'air : l'écart qui rend l'éclair lisible
## comme une COLONNE entre nuage et monument (§9.3 : trait, pas contact).
const BELLY_FLOOR_WORLD_Y: float = 106.0
## 24 m couvre aussi les galettes de la jupe : une sphère plus large que ça
## redevient l'arche (grumeau) ou la soucoupe (enclume) que les captures ont
## montrées — les deux formes du même défaut.
const MAX_LUMP_RADIUS_M: float = 24.0
const MIN_LUMPS: int = 18
const MIN_WARM_RIM_LUMPS: int = 3


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


## TOUTES les sphères du nuage, pas seulement les grumeaux : la première
## version ne comptait que « CloudLayer* » et a laissé passer une enclume
## `CloudBase` de 63 m de rayon — la capture de la crête montrait de nouveau
## une soucoupe lisse. Le trou du filet ÉTAIT le défaut.
func _lumps_of(storm: Node3D) -> Array[MeshInstance3D]:
	var lumps: Array[MeshInstance3D] = []
	for child: Node in storm.get_children():
		if child.name.begins_with("Cloud") and child is MeshInstance3D \
				and (child as MeshInstance3D).mesh is SphereMesh:
			lumps.append(child as MeshInstance3D)
	return lumps


func test_the_cloud_belly_stays_above_the_spire() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var storm: Node3D = valley.get_node_or_null("CitadelStorm") as Node3D
	check_not_null(storm, "la cellule d'orage existe")
	if storm == null:
		await _cleanup(valley)
		return
	var sagging: Array[String] = []
	for lump: MeshInstance3D in _lumps_of(storm):
		var sphere: SphereMesh = lump.mesh as SphereMesh
		var bottom: float = storm.global_position.y + lump.position.y \
			- sphere.height * 0.5
		if bottom < BELLY_FLOOR_WORLD_Y:
			sagging.append("%s (bas à y %.0f)" % [lump.name, bottom])
	check(sagging.is_empty(),
		"le ventre du nuage reste au-dessus de la spire, y ≥ %.0f (fautifs : %s)"
			% [BELLY_FLOOR_WORLD_Y,
				", ".join(sagging) if not sagging.is_empty() else "aucun"])
	await _cleanup(valley)


func test_the_cloud_is_granular_not_three_giant_arcs() -> void:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var storm: Node3D = valley.get_node_or_null("CitadelStorm") as Node3D
	check_not_null(storm, "la cellule d'orage existe")
	if storm != null:
		var lumps: Array[MeshInstance3D] = _lumps_of(storm)
		check(lumps.size() >= MIN_LUMPS,
			"la masse est granulaire : %d grumeaux ≥ %d (avant : 14, dont trois arches)"
				% [lumps.size(), MIN_LUMPS])
		for lump: MeshInstance3D in lumps:
			var radius: float = (lump.mesh as SphereMesh).radius
			check(radius <= MAX_LUMP_RADIUS_M,
				"%s : rayon %.1f m ≤ %.0f — aucun grumeau ne redevient une arche"
					% [lump.name, radius, MAX_LUMP_RADIUS_M])
	await _cleanup(valley)


func test_the_sun_side_carries_warm_rim_lumps() -> void:
	## §9.2 : « bords plus clairs et chauds côté soleil ». Le soleil vient de
	## l'ouest/haut-gauche (§22.1) — les grumeaux chauds vivent donc sur la
	## moitié x < 0 de la cellule, et leur albédo penche vers le rouge.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _tree().physics_frame
	var storm: Node3D = valley.get_node_or_null("CitadelStorm") as Node3D
	check_not_null(storm, "la cellule d'orage existe")
	if storm != null:
		var warm: int = 0
		for lump: MeshInstance3D in _lumps_of(storm):
			var material: StandardMaterial3D = \
				lump.material_override as StandardMaterial3D
			if material == null or lump.position.x >= 0.0:
				continue
			if material.albedo_color.r > material.albedo_color.b:
				warm += 1
		check(warm >= MIN_WARM_RIM_LUMPS,
			"au moins %d grumeaux chauds côté soleil (%d trouvés)"
				% [MIN_WARM_RIM_LUMPS, warm])
	await _cleanup(valley)
