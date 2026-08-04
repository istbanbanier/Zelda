## ÉCHELLE DU KIT VÉGÉTAL — la vallée respecte-t-elle « 1 unité = 1 m » ?
##
## Origine : premier playtest en boîte noire (`decouverte_A_20260804_021956`,
## capture `pas_0036_act.png`). Le joueur avance sur le sentier ; une fleur
## jaune occupe un quart de l'écran et dépasse la poitrine d'un héros d'1,78 m.
##
## Mesure hors moteur : `Flower_4_Group` fait 2,49 m de haut. La bible visuelle
## §3 borne les fleurs à 0,18–0,55 m. Le kit entier avait été importé sans
## normalisation et posé à l'échelle native par sept modules.
##
## Deux tests, volontairement complémentaires :
##
##   1. **À la source** — tout `.gltf` de `assets/environment/foliage/` dont la
##      hauteur native dépasse le plafond de sa famille DOIT avoir une entrée
##      dans `KitScale`. Ce test attrape un asset ajouté demain sans échelle,
##      même s'il n'est encore posé nulle part.
##   2. **Dans le monde** — aucune pièce du kit végétal réellement montée dans
##      la vallée ne dépasse son plafond, hauteur mesurée en espace MONDE,
##      donc échelle des parents comprise.
##
## Le premier seul ne prouverait rien : une table correcte non appliquée
## laisserait les fleurs géantes. Le second seul ne prouverait rien non plus :
## un asset non encore posé passerait inaperçu jusqu'au jour de son placement.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const FOLIAGE_DIR: String = "res://assets/environment/foliage"
## Tolérance : la variation de placement va jusqu'à 1,3 dans les modules
## existants, et c'est voulu — deux touffes identiques se voient. On borne donc
## au plafond de famille MULTIPLIÉ par cette variation maximale légitime.
const VARIATION_MAX: float = 1.3

var _valley: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


## Hauteur native d'un `.gltf` du kit, mesurée en instanciant la scène
## importée et en réunissant les AABB de ses maillages. C'est la même mesure
## que `tools/gltf_inspect.py`, faite ici par le moteur pour qu'un écart entre
## la source et l'import ne passe pas inaperçu.
func _native_height(path: String) -> float:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return -1.0
	var node: Node3D = packed.instantiate() as Node3D
	if node == null:
		return -1.0
	_tree().root.add_child(node)
	var box: AABB = AABB()
	var first: bool = true
	for mesh: Node in node.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = mesh as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var local: AABB = instance.mesh.get_aabb()
		var world: AABB = instance.global_transform * local
		box = world if first else box.merge(world)
		first = false
	node.get_parent().remove_child(node)
	node.queue_free()
	return -1.0 if first else box.size.y


func test_every_oversized_kit_asset_has_a_measured_correction() -> void:
	## À LA SOURCE. Un asset du kit dont la hauteur native dépasse le plafond
	## de sa famille doit figurer dans `KitScale.MEASURED`, avec une cible qui
	## le ramène réellement sous ce plafond. Une table qui « existe » sans
	## corriger ne vaut rien.
	var directory: DirAccess = DirAccess.open(FOLIAGE_DIR)
	check_not_null(directory, "dossier du kit végétal")
	if directory == null:
		return
	var inspected: int = 0
	var corrected: int = 0
	for file_name: String in directory.get_files():
		if not file_name.ends_with(".gltf"):
			continue
		var asset: String = file_name.get_basename()
		var family: StringName = KitScale.family(asset)
		if family == &"":
			continue
		var ceiling: float = float(KitScale.FAMILY_CEILING[family])
		var native: float = _native_height("%s/%s" % [FOLIAGE_DIR, file_name])
		if native <= 0.0:
			continue
		inspected += 1
		if native <= ceiling:
			continue
		# Trop grand nativement : la correction est OBLIGATOIRE.
		corrected += 1
		var factor: float = KitScale.factor(asset)
		check(factor < 1.0,
			"%s mesure %.2f m (famille %s, plafond %.2f) : il lui faut une " \
			% [asset, native, family, ceiling] \
			+ "entrée dans KitScale, or son facteur vaut %.3f" % factor)
		check(native * factor <= ceiling,
			"%s corrigé donne %.2f m, encore au-dessus du plafond %.2f m" \
			% [asset, native * factor, ceiling])
	check(inspected >= 10,
		"au moins dix pièces du kit inspectées (obtenu %d) — sinon ce test " \
		% inspected + "passerait à vide")
	check(corrected >= 5,
		"au moins cinq pièces nécessitaient une correction (obtenu %d) : si " \
		% corrected + "ce nombre tombe à zéro, le test ne prouve plus rien")


func test_no_planted_foliage_towers_over_the_hero() -> void:
	## DANS LE MONDE. On monte la vraie vallée et on mesure la hauteur en
	## espace monde de chaque pièce végétale du kit. Une fleur de 2,49 m posée
	## au bord du sentier casse la lecture d'échelle de toute la composition.
	await _load_valley()
	var checked: int = 0
	var worst_name: String = ""
	var worst_excess: float = 0.0
	var worst_height: float = 0.0
	var worst_ceiling: float = 0.0
	for node: Node in _valley.find_children("*", "Node3D", true, false):
		var asset: String = String(node.name)
		# Les modules suffixent d'un compteur unique (`Flower_4_Group_017`).
		var base: String = asset
		var parts: PackedStringArray = asset.split("_")
		if parts.size() > 1 and parts[parts.size() - 1].is_valid_int():
			base = "_".join(parts.slice(0, parts.size() - 1))
		var family: StringName = KitScale.family(base)
		if family == &"":
			continue
		var spatial: Node3D = node as Node3D
		if spatial == null or not spatial.is_inside_tree():
			continue
		var box: AABB = AABB()
		var first: bool = true
		for mesh: Node in spatial.find_children("*", "MeshInstance3D", true, false):
			var instance: MeshInstance3D = mesh as MeshInstance3D
			if instance == null or instance.mesh == null:
				continue
			var world: AABB = instance.global_transform * instance.mesh.get_aabb()
			box = world if first else box.merge(world)
			first = false
		if first:
			continue
		checked += 1
		var ceiling: float = float(KitScale.FAMILY_CEILING[family]) * VARIATION_MAX
		if box.size.y - ceiling > worst_excess:
			worst_excess = box.size.y - ceiling
			worst_name = asset
			worst_height = box.size.y
			worst_ceiling = ceiling
	check(checked >= 20,
		"au moins vingt pièces végétales du kit montées dans la vallée " \
		+ "(obtenu %d) — sous ce seuil, le test ne regarde rien" % checked)
	check(worst_excess <= 0.0,
		"la plus grande pièce végétale est %s à %.2f m, plafond %.2f m " \
		% [worst_name, worst_height, worst_ceiling] \
		+ "(un héros mesure 1,78 m)" if worst_name != "" \
		else "aucune pièce végétale ne dépasse son plafond")
	await _unload_valley()


func _load_valley() -> void:
	_valley = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_valley)
	await _settle(5)


func _unload_valley() -> void:
	if _valley == null:
		return
	_valley.get_parent().remove_child(_valley)
	_valley.queue_free()
	_valley = null
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)
