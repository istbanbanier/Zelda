## World V2, phase V2.0 — la CARTE DIRECTRICE est un contrat, pas une intention.
##
## POURQUOI CE FICHIER EXISTE : la reconstruction V2.1+ sera bâtie sur
## `resources/world_v2/world_v2_layout.json`. Une carte qui perdrait un des 31
## lieux, dupliquerait un identifiant persistant §19.3 ou poserait un site hors
## du monde jouable coûterait une session entière au moment où on le
## découvrirait — ces tests le disent en secondes (PROMPT4 §0).
##
## Le validateur (`WorldV2Layout.validate`) est PUR : le contrôle négatif de ce
## fichier lui donne des cartes sciemment corrompues et exige un refus. Un
## validateur qui n'a jamais rougi ne prouve rien.
extends GateTestCase


func test_la_carte_directrice_est_valide() -> void:
	var layout: Dictionary = WorldV2Layout.load_layout()
	check(not layout.is_empty(),
		"la carte %s se charge et se parse" % WorldV2Layout.LAYOUT_PATH)
	var problems: Array[String] = WorldV2Layout.validate(layout)
	check(problems.is_empty(),
		"la carte est valide — problèmes : %s" % " | ".join(problems))
	# Les 31 lieux exactement, pas « au moins » : un 32e lieu entré par
	# accident dans la liste canonique serait aussi une dérive.
	check_equal((layout.get("pois", []) as Array).size(),
		WorldV2Layout.CANONICAL_POI_IDS.size(),
		"le manifeste porte exactement les lieux canoniques")


## CONTRÔLE NÉGATIF — chaque corruption plausible doit être REFUSÉE. Si l'une
## d'elles passe, le validateur est décoratif et la carte n'est pas protégée.
func test_le_validateur_sait_dire_non() -> void:
	var layout: Dictionary = WorldV2Layout.load_layout()
	check(not layout.is_empty(), "préalable : la carte réelle se charge")

	var wrong_world: Dictionary = layout.duplicate(true)
	wrong_world["world_id"] = "neris_v1"
	check(not WorldV2Layout.validate(wrong_world).is_empty(),
		"un world_id V1 sur la carte V2 est refusé")

	var missing_poi: Dictionary = layout.duplicate(true)
	var pois: Array = missing_poi["pois"] as Array
	pois.remove_at(0)
	check(not WorldV2Layout.validate(missing_poi).is_empty(),
		"un lieu canonique MANQUANT est refusé — aucun des 31 ne disparaît")

	var duplicated_poi: Dictionary = layout.duplicate(true)
	var dup_list: Array = duplicated_poi["pois"] as Array
	dup_list.append((dup_list[0] as Dictionary).duplicate(true))
	check(not WorldV2Layout.validate(duplicated_poi).is_empty(),
		"un identifiant persistant DUPLIQUÉ est refusé (§19.3)")

	var out_of_bounds: Dictionary = layout.duplicate(true)
	var far_poi: Dictionary = (out_of_bounds["pois"] as Array)[0] as Dictionary
	far_poi["v2_site"] = [500.0, 2.0, 500.0]
	check(not WorldV2Layout.validate(out_of_bounds).is_empty(),
		"un site hors du rayon jouable est refusé")

	var lost_reward: Dictionary = layout.duplicate(true)
	var poor_poi: Dictionary = (lost_reward["pois"] as Array)[0] as Dictionary
	poor_poi["reward"] = ""
	check(not WorldV2Layout.validate(lost_reward).is_empty(),
		"un lieu qui perd sa récompense est refusé")

	var lost_checkpoint: Dictionary = layout.duplicate(true)
	var kept: Array = []
	for entry: Variant in lost_checkpoint["checkpoints"] as Array:
		if String((entry as Dictionary).get("id", "")) != "camp":
			kept.append(entry)
	lost_checkpoint["checkpoints"] = kept
	check(not WorldV2Layout.validate(lost_checkpoint).is_empty(),
		"la disparition du checkpoint camp est refusée")

	var empty_map: Dictionary = {}
	check(not WorldV2Layout.validate(empty_map).is_empty(),
		"une carte vide est refusée")


## Aucun lieu que la V1 déclare réellement (bâtisseurs de scripts/world/) ne
## doit être oublié par la carte V2. La source de vérité est le CODE V1, lu
## fichier par fichier — pas un document qui peut mentir (POI_MAP.md le dit
## lui-même : « en cas de désaccord, le jeu a raison »).
func test_aucun_lieu_declare_en_v1_nest_oublie() -> void:
	var declared: Dictionary = _poi_ids_declared_by_v1_builders()
	check(declared.size() >= WorldV2Layout.CANONICAL_POI_IDS.size(),
		"les bâtisseurs V1 déclarent au moins les 31 lieux canoniques (trouvés : %d)"
			% declared.size())

	var layout: Dictionary = WorldV2Layout.load_layout()
	var covered: Dictionary = WorldV2Layout.covered_place_ids(layout)
	var forgotten: Array[String] = []
	for poi_id: StringName in declared.keys():
		if not covered.has(poi_id):
			forgotten.append(String(poi_id))
	forgotten.sort()
	check(forgotten.is_empty(),
		"chaque lieu V1 est couvert par la carte V2 — oubliés : %s"
			% ", ".join(forgotten))

	# L'autre direction : chaque lieu canonique ÉPINGLÉ existe bien côté V1.
	# Si cette liste dérivait du code réel, le test suivrait l'erreur.
	var ghosts: Array[String] = []
	for wanted: StringName in WorldV2Layout.CANONICAL_POI_IDS:
		if not declared.has(wanted):
			ghosts.append(String(wanted))
	check(ghosts.is_empty(),
		"chaque lieu canonique épinglé est déclaré par un bâtisseur V1 — fantômes : %s"
			% ", ".join(ghosts))


func test_les_identifiants_de_monde_sont_distincts() -> void:
	check(not String(WorldIds.V1_WORLD_ID).is_empty(), "identifiant V1 non vide")
	check(not String(WorldIds.V2_WORLD_ID).is_empty(), "identifiant V2 non vide")
	check(WorldIds.V1_WORLD_ID != WorldIds.V2_WORLD_ID,
		"V1 et V2 ne partagent JAMAIS un identifiant de monde")
	var layout: Dictionary = WorldV2Layout.load_layout()
	check_equal(StringName(String(layout.get("world_id", ""))),
		WorldIds.V2_WORLD_ID, "la carte directrice se réclame du monde V2")


## Balaye les bâtisseurs V1 (`scripts/world/*.gd`) et collecte tout identifiant
## de lieu au format §19.3 `valley.poi.<nom>.<index>`.
func _poi_ids_declared_by_v1_builders() -> Dictionary:
	var found: Dictionary = {}
	var pattern: RegEx = RegEx.new()
	var compiled: Error = pattern.compile("valley\\.poi\\.[a-z0-9_]+\\.[0-9]+")
	if compiled != OK:
		return found
	var dir: DirAccess = DirAccess.open("res://scripts/world")
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".gd"):
			var file: FileAccess = FileAccess.open(
				"res://scripts/world/%s" % entry, FileAccess.READ)
			if file != null:
				var text: String = file.get_as_text()
				file.close()
				# Ligne par ligne, COMMENTAIRES EXCLUS : la doc de
				# discovery_rewards.gd:152 cite l'exemple « valley.poi.x.01 »,
				# qui n'est pas un lieu — un balayage naïf l'exigeait de la
				# carte (échec mesuré au premier passage de cette suite).
				for line: String in text.split("\n"):
					if line.strip_edges().begins_with("#"):
						continue
					for hit: RegExMatch in pattern.search_all(line):
						found[StringName(hit.get_string())] = true
		entry = dir.get_next()
	dir.list_dir_end()
	return found
