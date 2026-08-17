## Chargeur et VALIDATEUR de la carte directrice World V2 (phase V2.0).
##
## `resources/world_v2/world_v2_layout.json` fait foi sur les nombres du
## masterplan (`docs/WORLD_V2_MASTERPLAN.md` explique les relations). Ce script
## est le seul chemin d'accès au fichier : le squelette, les outils de
## construction V2.1+ et les tests passent tous par ici, pour qu'une carte
## invalide soit refusée AVANT de bâtir quoi que ce soit dessus.
##
## `validate()` est une fonction PURE (dictionnaire → liste de problèmes) :
## c'est ce qui permet au contrôle négatif de la suite de lui donner une carte
## sciemment corrompue et d'exiger un refus — un validateur qui ne sait pas
## dire non ne protège rien.
class_name WorldV2Layout
extends RefCounted

const LAYOUT_PATH: String = "res://resources/world_v2/world_v2_layout.json"

## Les 31 lieux canoniques de `docs/POI_MAP.md` — identifiants §19.3, ÉPINGLÉS
## en littéraux (méthode PROMPT4 §2 : un test qui lirait la liste depuis le
## monde suivrait l'erreur au lieu de la dénoncer). Aucun lieu ne disparaît
## sans autorisation explicite du propriétaire.
const CANONICAL_POI_IDS: Array[StringName] = [
	&"valley.poi.riverside_village.01",
	&"valley.poi.logging_hamlet.01",
	&"valley.poi.mining_post.01",
	&"valley.poi.watchtower_ruin.01",
	&"valley.poi.ancient_aqueduct.01",
	&"valley.poi.abandoned_farm.01",
	&"valley.poi.storm_caravan.01",
	&"valley.poi.ruined_observatory.01",
	&"valley.poi.barrow_cemetery.01",
	&"valley.poi.old_rampart.01",
	&"valley.poi.forest_shrine.01",
	&"valley.poi.waterfall_cave.01",
	&"valley.poi.abandoned_mine.01",
	&"valley.poi.hollow_crypt.01",
	&"valley.poi.hidden_passage.01",
	&"valley.poi.crystal_hollow.01",
	&"valley.poi.ancient_tree.01",
	&"valley.poi.turquoise_spring.01",
	&"valley.poi.flower_field.01",
	&"valley.poi.stone_bridge.01",
	&"valley.poi.overlook_summit.01",
	&"valley.poi.veil_falls.01",
	&"valley.poi.watchers_circle.01",
	&"valley.poi.wind_gorge.01",
	&"valley.poi.storm_grove.01",
	&"valley.poi.thunderstruck_tree.01",
	&"valley.poi.ember_raider_camps.01",
	&"valley.poi.azure_patrol_run.01",
	&"valley.poi.obsidian_bastion.01",
	&"valley.poi.colossus_lair.01",
	&"valley.poi.hunter_range.01",
]

## Les sites systémiques du Bracelet (P2-4) : hors des 31, même contrat de
## préservation. `earth_altar` n'a pas d'identifiant §19.3 en V1 (l'autel vit
## dans les bâtisseurs sans POI propre) — V2 lui en donnera un en V2.1+.
const SYSTEMIC_SITE_IDS: Array[StringName] = [
	&"valley.poi.magnetic_bridge.01",
	&"valley.poi.conductive_basin.01",
	&"earth_altar",
]

## Les 8 espaces du donjon dont l'enveloppe sera reconstruite (logique intacte).
const DUNGEON_SPACE_IDS: Array[StringName] = [
	&"vestibule",
	&"room1_initiation",
	&"central_hall",
	&"room2_vertical",
	&"room3_relays",
	&"room4_battery",
	&"antechamber",
	&"boss_arena",
]

## Checkpoints que la migration de sauvegarde a le droit de cibler en vallée.
const REQUIRED_CHECKPOINT_IDS: Array[StringName] = [&"camp", &"dungeon_gate"]


## Charge la carte depuis `LAYOUT_PATH`. Dictionnaire vide en cas d'échec —
## l'appelant décide si c'est bloquant ; le bootstrap, lui, refuse de démarrer.
static func load_layout() -> Dictionary:
	var file: FileAccess = FileAccess.open(LAYOUT_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return {}
	if not (json.data is Dictionary):
		return {}
	return json.data as Dictionary


## Valide une carte et rend la liste des problèmes — vide si la carte est saine.
## PURE : aucune lecture disque, aucun état ; le contrôle négatif en dépend.
static func validate(layout: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	if layout.is_empty():
		problems.append("carte vide ou illisible")
		return problems

	if StringName(String(layout.get("world_id", ""))) != WorldIds.V2_WORLD_ID:
		problems.append("world_id « %s » != « %s »"
			% [layout.get("world_id", ""), WorldIds.V2_WORLD_ID])

	var radius_max: float = 0.0
	var bounds: Dictionary = layout.get("bounds", {}) as Dictionary
	if bounds.has("playable_radius_max_m"):
		radius_max = float(bounds["playable_radius_max_m"])
	else:
		problems.append("bounds.playable_radius_max_m absent")

	# --- régions : identifiants uniques, ancrage de sauvegarde dans les bornes.
	var region_ids: Dictionary = {}
	var regions: Array = layout.get("regions", []) as Array
	if regions.is_empty():
		problems.append("aucune région déclarée")
	for entry: Variant in regions:
		var region: Dictionary = entry as Dictionary
		var region_id: String = String(region.get("id", ""))
		if region_id.is_empty():
			problems.append("région sans identifiant")
			continue
		if region_ids.has(region_id):
			problems.append("région EN DOUBLE : %s" % region_id)
		region_ids[region_id] = true
		var anchor: Variant = region.get("save_anchor")
		if anchor == null:
			continue  # l'anneau frontalier, non jouable, n'a pas d'ancrage.
		var anchor_pos: Array = (anchor as Dictionary).get("pos", []) as Array
		if anchor_pos.size() != 3:
			problems.append("ancrage de %s sans position [x,y,z]" % region_id)
		elif radius_max > 0.0 and Vector2(float(anchor_pos[0]),
				float(anchor_pos[2])).length() > radius_max:
			problems.append("ancrage de %s hors du rayon jouable" % region_id)

	# --- les 31 lieux : exactement la liste canonique, uniques, dans les bornes.
	var seen_pois: Dictionary = {}
	var pois: Array = layout.get("pois", []) as Array
	for entry: Variant in pois:
		var poi: Dictionary = entry as Dictionary
		var poi_id: StringName = StringName(String(poi.get("id", "")))
		if seen_pois.has(poi_id):
			problems.append("lieu EN DOUBLE : %s" % poi_id)
			continue
		seen_pois[poi_id] = true
		if not CANONICAL_POI_IDS.has(poi_id):
			problems.append("lieu INCONNU (hors des 31 canoniques) : %s" % poi_id)
		var site: Array = poi.get("v2_site", []) as Array
		if site.size() != 3:
			problems.append("%s : v2_site n'est pas [x,y,z]" % poi_id)
		elif radius_max > 0.0 and Vector2(float(site[0]),
				float(site[2])).length() > radius_max:
			problems.append("%s : v2_site hors du rayon jouable" % poi_id)
		if String(poi.get("name", "")).is_empty():
			problems.append("%s : nom affiché vide" % poi_id)
		if String(poi.get("reward", "")).is_empty():
			problems.append("%s : récompense vide — un lieu ne perd pas sa récompense sans autorisation" % poi_id)
		var poi_region: String = String(poi.get("region", ""))
		if not region_ids.has(poi_region):
			problems.append("%s : région inconnue « %s »" % [poi_id, poi_region])
	for wanted: StringName in CANONICAL_POI_IDS:
		if not seen_pois.has(wanted):
			problems.append("lieu MANQUANT : %s — aucun des 31 ne disparaît" % wanted)

	# --- sites systémiques du Bracelet.
	var systemic_seen: Dictionary = {}
	for entry: Variant in layout.get("systemic_sites", []) as Array:
		systemic_seen[StringName(String((entry as Dictionary).get("id", "")))] = true
	for wanted: StringName in SYSTEMIC_SITE_IDS:
		if not systemic_seen.has(wanted):
			problems.append("site systémique MANQUANT : %s" % wanted)

	# --- checkpoints de vallée que la migration cible.
	var checkpoint_seen: Dictionary = {}
	for entry: Variant in layout.get("checkpoints", []) as Array:
		checkpoint_seen[StringName(String((entry as Dictionary).get("id", "")))] = true
	for wanted: StringName in REQUIRED_CHECKPOINT_IDS:
		if not checkpoint_seen.has(wanted):
			problems.append("checkpoint MANQUANT : %s" % wanted)

	# --- enveloppe du donjon : les 8 espaces planifiés.
	var space_seen: Dictionary = {}
	for entry: Variant in layout.get("dungeon_spaces", []) as Array:
		space_seen[StringName(String((entry as Dictionary).get("id", "")))] = true
	for wanted: StringName in DUNGEON_SPACE_IDS:
		if not space_seen.has(wanted):
			problems.append("espace de donjon MANQUANT : %s" % wanted)

	return problems


## Tous les identifiants de lieu couverts par la carte (31 canoniques + sites
## systémiques) — la référence contre laquelle on vérifie qu'aucun lieu déclaré
## par les bâtisseurs V1 n'a été oublié.
static func covered_place_ids(layout: Dictionary) -> Dictionary:
	var covered: Dictionary = {}
	for entry: Variant in layout.get("pois", []) as Array:
		covered[StringName(String((entry as Dictionary).get("id", "")))] = true
	for entry: Variant in layout.get("systemic_sites", []) as Array:
		covered[StringName(String((entry as Dictionary).get("id", "")))] = true
	return covered
