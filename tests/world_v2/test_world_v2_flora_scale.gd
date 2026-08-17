## ÉCHELLE FLORALE DE WORLD V2 — la régression V2.2, rendue rougissante.
##
## ORIGINE, mesurée et non déduite. Revue R2a-3.3 du lead : « les fleurs
## géantes masquent l'entrée » de la Grotte du Couchant. Le diagnostic
## `evidence/world_v2/v2_3_r2a/grotte/masses_jaunes/MASSES_JAUNES.md` a
## nommé les coupables par masquage à caméra identique : des
## `Flower_4_Group` des cellules `veg_c4r8` et `veg_c4r7`, à 2,10-2,30 m
## de hauteur apparente.
##
## Mesure à la source, hors moteur, dans ce dépôt :
##
##     python3 tools/gltf_inspect.py assets/environment/foliage/Flower_4_Group.gltf
##     dimensions_m : [1.7805, 2.4868, 1.3675]
##     python3 tools/gltf_inspect.py assets/environment/foliage/Flower_3_Group.gltf
##     dimensions_m : [1.4885, 2.0548, 1.5911]
##
## `VISUAL_ASSET_BIBLE` §3 borne les fleurs à 0,18-0,55 m. Le projet possède
## déjà la correction en un point unique — `scripts/world/kit_scale.gd` — et
## TOUS les modules la consultent, sauf un : le bâtisseur de végétation
## cellulaire V2.2, qui posait ses grappes à la taille NATIVE multipliée par
## une simple variation.
##
## POURQUOI CE TEST N'EXISTAIT PAS. `tests/integration/test_kit_scale.gd`
## couvre déjà « aucune pièce végétale plantée ne dépasse son plafond » —
## mais il monte `ValleyWorld.tscn` (le monde V1) et énumère des
## `MeshInstance3D`. World V2 n'est pas cette scène, et sa végétation est en
## `MultiMeshInstance3D`. C'est le piège nommé mot pour mot dans
## `tools/CLAUDE.md` : « une sonde qui ne collecte que des MeshInstance3D la
## déclare absente — silencieusement ». D'où ce second test, ciblé V2.
##
## LIMITE MESURÉE DU HEADLESS (source 4.7.1) : le renderer dummy de
## `--script` jette les données d'instance MultiMesh (set = no-op, get =
## identité — dummy/storage/mesh_storage.h:191,202). On lit donc le PLAN DE
## PLANTATION que le bâtisseur écrit en méta (`instance_scales`), depuis les
## mêmes valeurs et la même boucle que l'écriture moteur. La méta est
## VÉRIFIÉE présente et non vide : la supposer, ce serait absoudre par un
## tableau absent.
##
## LES SEUILS VIENNENT DE LA BIBLE, JAMAIS DE `KitScale`. Lire
## `KitScale.target_height()` pour en déduire ce qu'on attend ferait suivre
## l'erreur au test au lieu de la dénoncer (PROMPT4 §2, `tests/CLAUDE.md`
## « l'auto-comparaison »). 0,55 et 0,18 sont recopiés de la bible §3.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const VEGETATION_GROUP: StringName = &"world_v2_vegetation"

## `VISUAL_ASSET_BIBLE` §3, tableau des dimensions : « Fleurs 0,18-0,55 m ».
const FLOWER_CEILING_M: float = 0.55
const FLOWER_FLOOR_M: float = 0.18
## Une hauteur corrigée est un produit de flottants (natif x cible/natif x
## variation) : le haut de bande retombe sur 0,5499999 ou 0,5500001 selon
## l'arrondi. Un millimètre de tolérance supprime l'intermittence sans rien
## absoudre — le défaut réel valait 2,86 m, soit 2 300 fois cette marge.
const BORDER_TOLERANCE_M: float = 0.001

## Planchers d'ARCHITECTURE : sous ces nombres, le test ne regarde rien et
## passerait à vide. Ce ne sont pas des cibles de qualité.
const MIN_FLOWER_LAYERS: int = 20
const MIN_FLOWER_INSTANCES: int = 200

## Les deux seules variantes florales que le bâtisseur V2 sème
## (`WorldV2VegetationBuilder.FLOWER_MODELS`). Épinglé en littéral : une
## troisième espèce ajoutée demain doit faire ROUGIR ce test, pas se glisser
## dans une liste lue depuis le code surveillé.
const EXPECTED_FLOWER_MODELS: Array[String] = ["Flower_3_Group", "Flower_4_Group"]

## TÉMOIN D'INVARIANCE — empreinte des couches NON FLORALES, mesurée sur le
## monde AVANT la correction d'échelle (commit 59e0adb, journal rouge dans
## `evidence/world_v2/v2_3_r2a/flore/`).
##
## Cinq nombres par catégorie : nombre d'instances, puis les sommes des X, Y,
## Z d'origine et des facteurs d'échelle, publiées au dix-millième. Une
## seule instance déplacée d'un millimètre change une somme de 0,001, soit
## le double de la tolérance de comparaison — le témoin voit donc un défaut
## d'une instance sur des milliers.
##
## MESURÉ, pas supposé : perturber ici la somme X des roseaux de 0,001 —
## l'équivalent d'un seul roseau déplacé d'un millimètre — fait bien
## ÉCHOUER ce test, en nommant la catégorie et le champ
## (`evidence/world_v2/v2_3_r2a/flore/controle_negatif_temoin.log`).
##
## Ces littéraux sont MESURÉS, jamais recopiés d'une constante du bâtisseur :
## un test qui lit la valeur qu'il surveille suit l'erreur (PROMPT4 §2). Deux
## passages successifs du monde non corrigé ont rendu exactement ces nombres —
## le témoin épingle un état reproduit, pas une capture unique.
const WITNESS_NON_FLORAL: Dictionary = {
	# catégorie : [instances, somme X, somme Y, somme Z, somme échelles]
	"grass": [12570, 20004.2914, 128604.1517, 816381.5592, 13513.6401],
	"tall":  [1985, -87.4601, 40697.9946, 334611.8255, 2128.5345],
	"reeds": [7, -588.1430, 13.4484, 135.7969, 7.5395],
	"tree":  [197, 14889.9664, 1900.7008, 9588.2803, 218.0460],
	"rock":  [698, 1788.8191, 9815.9115, -6175.0403, 800.5724],
}

## TÉMOIN DE PLACEMENT FLORAL — nombre d'instances et sommes des origines,
## SANS la somme des échelles. La correction change les échelles des fleurs
## et rien d'autre : leurs positions, leur nombre et donc les densités et
## les graines doivent survivre à l'identique. Épingler ici la somme des
## échelles reviendrait à interdire la correction elle-même.
##
## Pour mémoire, la somme des échelles florales AVANT correction valait
## 1162,5143 pour ces mêmes 1 194 fleurs, soit une moyenne de 0,9737 appliquée
## à des modèles de 2,05 et 2,49 m. Elle n'est pas épinglée : c'est la seule
## grandeur que la correction a le droit de changer.
const WITNESS_FLORAL_PLACEMENT: Array = [
	# [instances, somme X, somme Y, somme Z]
	1194, -22648.5969, 13960.9344, 130360.7182,
]

## Tolérance de comparaison du témoin. Trois échelles la séparent de ses
## voisines, et c'est délibéré : le bruit d'arrondi des littéraux (publiés au
## dix-millième) plafonne à 0,00005 ; le seuil retenu vaut 0,0005 ; une seule
## instance déplacée d'un millimètre décale une somme de 0,001. Détection
## deux fois plus fine que le plus petit défaut réel, dix fois plus grossière
## que le bruit — la tolérance ne peut donc ni clignoter, ni absoudre.
const WITNESS_TOLERANCE: float = 0.0005

var _world: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _mount_world() -> Node3D:
	var loop: SceneTree = _tree()
	var world: Node3D = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(world)
	await loop.process_frame
	await loop.physics_frame
	return world


func _teardown(context: String) -> void:
	var clean: bool = await restore_root()
	check(clean, "%s — %s" % [context, restore_root_reason()])
	restore_saves()
	_world = null


## Cellules de végétation triées par nom : l'ordre de parcours doit être
## déterministe, sinon les sommes du témoin dériveraient d'un montage à
## l'autre pour une raison qui n'est pas un défaut.
func _sorted_vegetation_layers() -> Array[MultiMeshInstance3D]:
	var by_name: Dictionary = {}
	var names: Array[String] = []
	for node: Node in _tree().get_nodes_in_group(VEGETATION_GROUP):
		var layer: MultiMeshInstance3D = node as MultiMeshInstance3D
		if layer == null:
			continue
		names.append(String(layer.name))
		by_name[String(layer.name)] = layer
	names.sort()
	var sorted: Array[MultiMeshInstance3D] = []
	for layer_name: String in names:
		sorted.append(by_name[layer_name] as MultiMeshInstance3D)
	return sorted


## `veg_c4r8_flowers_Flower_4_Group` -> ["c4r8", "flowers_Flower_4_Group"].
## Le bâtisseur nomme `"%s_%s" % [cell_root.name, layer]`, et le nom de
## cellule est lui-même `veg_c%dr%d` : deux coupes suffisent, et le nom de
## modèle garde ses propres soulignés.
func _split_layer_name(layer_name: String) -> Array[String]:
	var parts: PackedStringArray = layer_name.split("_", true, 2)
	if parts.size() < 3:
		return ["", ""]
	return [parts[1], parts[2]]


## Hauteur native du modèle, en mètres, mesurée par le MOTEUR.
##
## Chemin principal : l'AABB du maillage porté par le MultiMesh — c'est
## exactement la géométrie posée. Repli : instancier l'asset et réunir les
## AABB de ses maillages, la méthode déjà éprouvée en headless par
## `tests/integration/test_kit_scale.gd::_native_height`. Rend -1 si aucune
## des deux ne donne une hauteur positive, pour que l'appelant ÉCHOUE au
## lieu de comparer des zéros.
func _native_height(layer: MultiMeshInstance3D, model: String) -> float:
	if layer.multimesh != null and layer.multimesh.mesh != null:
		var box: AABB = layer.multimesh.mesh.get_aabb()
		if box.size.y > 0.0:
			return box.size.y
	var packed: PackedScene = AssetRegistry.model(StringName(model))
	if packed == null:
		return -1.0
	var node: Node3D = packed.instantiate() as Node3D
	if node == null:
		return -1.0
	_tree().root.add_child(node)
	var merged: AABB = AABB()
	var first: bool = true
	for mesh_node: Node in node.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = mesh_node as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var world: AABB = instance.global_transform * instance.mesh.get_aabb()
		merged = world if first else merged.merge(world)
		first = false
	node.get_parent().remove_child(node)
	node.queue_free()
	return -1.0 if first else merged.size.y


## Le facteur d'échelle apporté par les PARENTS. La hauteur monde est le
## produit natif x instance x ancêtres : mesurer les deux premiers et
## supposer le troisième laisserait passer une échelle posée sur `$Vegetation`.
func _ancestor_scale_y(layer: MultiMeshInstance3D) -> float:
	return layer.global_transform.basis.get_scale().y


func _capped(faults: Array[String], keep: int = 6) -> String:
	if faults.size() <= keep:
		return " ; ".join(faults)
	return " ; ".join(faults.slice(0, keep)) \
		+ " ; (+%d autres)" % (faults.size() - keep)


## -- 1. Aucune fleur plantée ne dépasse le plafond de la bible ---------------

func test_aucune_fleur_plantee_ne_depasse_le_plafond_de_la_bible() -> void:
	remember_saves()
	remember_root()
	_world = await _mount_world()

	var layers: Array[MultiMeshInstance3D] = _sorted_vegetation_layers()
	check(not layers.is_empty(),
		"la végétation cellulaire V2 est montée (groupe %s)" % VEGETATION_GROUP)

	var flower_layers: int = 0
	var flower_instances: int = 0
	var models_seen: Array[String] = []
	var faults: Array[String] = []
	var missing_meta: Array[String] = []
	var tallest_name: String = ""
	var tallest_h: float = 0.0
	var shortest_h: float = 1e9

	for layer: MultiMeshInstance3D in layers:
		var split: Array[String] = _split_layer_name(String(layer.name))
		var cell: String = split[0]
		var kind: String = split[1]
		if not kind.begins_with("flowers_"):
			continue
		flower_layers += 1
		var model: String = kind.substr("flowers_".length())
		if not models_seen.has(model):
			models_seen.append(model)

		# La méta est le PLAN DE PLANTATION : sans elle, rien à mesurer, et
		# surtout rien à absoudre.
		if not layer.has_meta(&"instance_scales"):
			missing_meta.append("%s (méta instance_scales absente)" % layer.name)
			continue
		var scales: PackedFloat32Array = layer.get_meta(
			&"instance_scales") as PackedFloat32Array
		if scales.is_empty():
			missing_meta.append("%s (plan de plantation vide)" % layer.name)
			continue

		var native: float = _native_height(layer, model)
		if native <= 0.0:
			missing_meta.append("%s (hauteur native illisible)" % layer.name)
			continue
		var ancestors: float = _ancestor_scale_y(layer)
		if absf(ancestors - 1.0) > 0.001:
			faults.append("%s : un ANCÊTRE porte une échelle %.4f — la hauteur " \
				% [layer.name, ancestors] + "monde n'est plus le produit attendu")

		flower_instances += scales.size()
		for i: int in range(scales.size()):
			var height: float = native * scales[i] * ancestors
			if height > tallest_h:
				tallest_h = height
				tallest_name = "%s dans %s (natif %.4f m x instance %.4f)" \
					% [model, cell, native, scales[i]]
			shortest_h = minf(shortest_h, height)
			if height > FLOWER_CEILING_M + BORDER_TOLERANCE_M:
				faults.append("%s dans %s : %.3f m (natif %.4f x instance %.4f)" \
					% [model, cell, height, native, scales[i]])
				break  # une par couche suffit à la nommer ; le pire est gardé à part

	# --- garde-fous : ce test ne doit JAMAIS passer à vide ---
	check(missing_meta.is_empty(),
		"chaque couche florale expose un plan de plantation lisible — %s"
		% _capped(missing_meta))
	check(flower_layers >= MIN_FLOWER_LAYERS,
		"au moins %d couches florales trouvées dans World V2 (obtenu %d) — " \
		% [MIN_FLOWER_LAYERS, flower_layers] \
		+ "sous ce seuil, le test ne regarde rien")
	check(flower_instances >= MIN_FLOWER_INSTANCES,
		"au moins %d fleurs plantées mesurées (obtenu %d)"
		% [MIN_FLOWER_INSTANCES, flower_instances])
	models_seen.sort()
	check_equal(models_seen, EXPECTED_FLOWER_MODELS,
		"les variantes florales semées par World V2 sont exactement celles " \
		+ "attendues (une espèce ajoutée doit être mesurée, pas héritée)")

	# --- le contrat de la bible §3, dans les deux sens ---
	check(faults.is_empty(),
		"aucune fleur plantée ne dépasse %.2f m (bible §3) — la plus haute est " \
		% FLOWER_CEILING_M + "%s à %.3f m. Dépassements : %s" \
		% [tallest_name, tallest_h, _capped(faults)])
	check(shortest_h >= FLOWER_FLOOR_M - BORDER_TOLERANCE_M,
		"aucune fleur n'est écrasée sous %.2f m (bible §3) : la plus petite " \
		% FLOWER_FLOOR_M + "mesure %.3f m — une sur-correction est un défaut " \
		% shortest_h + "au même titre qu'une sous-correction")

	await _teardown("démontage propre (échelle florale)")


## -- 2. Témoin d'invariance : rien d'autre n'a bougé -------------------------

func test_les_elements_non_floraux_sont_inchanges() -> void:
	remember_saves()
	remember_root()
	_world = await _mount_world()

	var totals: Dictionary = {}
	for category: String in ["grass", "tall", "reeds", "tree", "rock", "flowers"]:
		totals[category] = [0, 0.0, 0.0, 0.0, 0.0]

	var unknown: Array[String] = []
	var missing_meta: Array[String] = []
	for layer: MultiMeshInstance3D in _sorted_vegetation_layers():
		var kind: String = _split_layer_name(String(layer.name))[1]
		var category: String = ""
		for candidate: String in ["grass", "tall", "reeds", "tree", "rock", "flowers"]:
			if kind == candidate or kind.begins_with(candidate + "_"):
				category = candidate
				break
		if category == "":
			unknown.append(String(layer.name))
			continue
		if not layer.has_meta(&"instance_origins") \
				or not layer.has_meta(&"instance_scales"):
			missing_meta.append(String(layer.name))
			continue
		var origins: PackedVector3Array = layer.get_meta(
			&"instance_origins") as PackedVector3Array
		var scales: PackedFloat32Array = layer.get_meta(
			&"instance_scales") as PackedFloat32Array
		var row: Array = totals[category] as Array
		row[0] = int(row[0]) + origins.size()
		for i: int in range(origins.size()):
			row[1] = float(row[1]) + origins[i].x
			row[2] = float(row[2]) + origins[i].y
			row[3] = float(row[3]) + origins[i].z
		for i: int in range(scales.size()):
			row[4] = float(row[4]) + scales[i]

	# Rendu lisible et repinnable : c'est cette table qu'on épingle.
	var measured: Array[String] = []
	for category: String in ["grass", "tall", "reeds", "tree", "rock", "flowers"]:
		var row: Array = totals[category] as Array
		measured.append("\"%s\": [%d, %.4f, %.4f, %.4f, %.4f]"
			% [category, int(row[0]), float(row[1]), float(row[2]),
				float(row[3]), float(row[4])])
	var table: String = "{" + ", ".join(measured) + "}"

	check(unknown.is_empty(),
		"toute couche végétale appartient à une catégorie connue — inconnues : %s"
		% _capped(unknown))
	check(missing_meta.is_empty(),
		"toute couche expose son plan de plantation — sans méta : %s"
		% _capped(missing_meta))

	if WITNESS_NON_FLORAL.is_empty() or WITNESS_FLORAL_PLACEMENT.is_empty():
		# Premier passage : le témoin n'est pas encore épinglé. On ÉCHOUE
		# bruyamment en publiant la mesure, plutôt que de se bénir soi-même
		# en écrivant un fichier que personne n'a relu.
		check(false,
			"TÉMOIN NON ÉPINGLÉ — mesure du monde courant à recopier dans " \
			+ "WITNESS_NON_FLORAL / WITNESS_FLORAL_PLACEMENT : %s" % table)
		await _teardown("démontage propre (témoin)")
		return

	var labels: Array[String] = ["instances", "somme X", "somme Y", "somme Z",
		"somme échelles"]
	var drift: Array[String] = []
	for category: Variant in WITNESS_NON_FLORAL.keys():
		var category_name: String = String(category)
		var expected: Array = WITNESS_NON_FLORAL[category] as Array
		var row: Array = totals.get(category_name, [0, 0.0, 0.0, 0.0, 0.0]) as Array
		for i: int in range(expected.size()):
			var want: float = float(expected[i])
			var got: float = float(row[i])
			if absf(got - want) > WITNESS_TOLERANCE:
				drift.append("%s / %s : attendu %.3f, obtenu %.3f"
					% [category_name, labels[i], want, got])
	check(drift.is_empty(),
		"la végétation NON FLORALE est strictement inchangée par la correction " \
		+ "d'échelle — dérives : %s. Mesure courante : %s"
		% [_capped(drift), table])

	# Les fleurs : mêmes nombres, mêmes positions. Seule leur ÉCHELLE change,
	# et c'est précisément ce que le test 1 mesure.
	var placement_drift: Array[String] = []
	var flowers: Array = totals["flowers"] as Array
	for i: int in range(WITNESS_FLORAL_PLACEMENT.size()):
		var want: float = float(WITNESS_FLORAL_PLACEMENT[i])
		var got: float = float(flowers[i])
		if absf(got - want) > WITNESS_TOLERANCE:
			placement_drift.append("fleurs / %s : attendu %.3f, obtenu %.3f"
				% [labels[i], want, got])
	check(placement_drift.is_empty(),
		"la correction d'échelle n'a déplacé, ajouté ni supprimé AUCUNE fleur " \
		+ "(positions, comptes, donc densités et graines intacts) — dérives : %s"
		% _capped(placement_drift))

	await _teardown("démontage propre (témoin)")
