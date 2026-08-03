## Journal des DÉCOUVERTES — registre des points d'intérêt du monde.
##
## L'ordre d'extension demande, pour chaque lieu : un nom affiché à la
## première visite, une découverte sauvegardée par identifiant unique, une
## notification discrète, et **aucune seconde récompense après rechargement**.
##
## Le registre est volontairement séparé des lieux eux-mêmes : un `PointOfInterest`
## ne sait pas s'il a déjà été vu, il le DEMANDE. C'est ce qui rend la règle
## « pas de seconde récompense » vraie par construction plutôt que par
## discipline — un lieu ne peut pas se déclarer neuf tout seul.
##
## Les identifiants suivent §19.3 : `zone.category.name.index`, par exemple
## `valley.poi.riverside_village.01`.
class_name DiscoveryLog
extends RefCounted

## Émis UNE SEULE fois par lieu et par partie.
signal discovered(poi_id: StringName, display_name: String)

## Émis même quand le lieu était déjà connu — l'interface peut vouloir
## réafficher le nom sans re-récompenser.
signal visited(poi_id: StringName, display_name: String, was_new: bool)

## Lieux déclarés dans le monde : id -> métadonnées.
var _registered: Dictionary = {}
## Lieux déjà découverts dans la partie courante.
var _discovered: Dictionary = {}


## Déclare un lieu. Deux lieux ne peuvent pas partager un identifiant : le
## validateur d'IDs de §19.3 échoue sur un doublon, et un doublon ici
## signifierait deux endroits qui se marquent découverts l'un l'autre.
func register(poi_id: StringName, display_name: String,
		region: StringName = &"") -> bool:
	# Refus signalés en AVERTISSEMENT, pas en erreur moteur : ce sont des
	# résultats que l'appelant lit dans la valeur de retour, et `validate_fast`
	# traite — à raison — tout « ERROR: » du journal comme un échec de suite.
	# L'unicité dure des identifiants reste vérifiée par le test dédié.
	if String(poi_id).is_empty():
		push_warning("[découvertes] identifiant vide — §19.3 l'interdit")
		return false
	if _registered.has(poi_id):
		push_warning("[découvertes] identifiant EN DOUBLE : %s" % poi_id)
		return false
	_registered[poi_id] = {
		"display_name": display_name,
		"region": region,
	}
	return true


func is_registered(poi_id: StringName) -> bool:
	return _registered.has(poi_id)


func registered_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key: StringName in _registered:
		ids.append(key)
	ids.sort()
	return ids


func display_name_of(poi_id: StringName) -> String:
	if not _registered.has(poi_id):
		return ""
	return String((_registered[poi_id] as Dictionary)["display_name"])


func region_of(poi_id: StringName) -> StringName:
	if not _registered.has(poi_id):
		return &""
	return (_registered[poi_id] as Dictionary)["region"]


func is_discovered(poi_id: StringName) -> bool:
	return _discovered.has(poi_id)


func discovered_count() -> int:
	return _discovered.size()


func registered_count() -> int:
	return _registered.size()


## Marque un lieu visité. Renvoie `true` seulement à la PREMIÈRE fois —
## c'est cette valeur de retour qui autorise une récompense.
func visit(poi_id: StringName) -> bool:
	if not _registered.has(poi_id):
		push_warning("[découvertes] lieu non déclaré : %s" % poi_id)
		return false
	var name: String = display_name_of(poi_id)
	if _discovered.has(poi_id):
		visited.emit(poi_id, name, false)
		return false
	_discovered[poi_id] = true
	discovered.emit(poi_id, name)
	visited.emit(poi_id, name, true)
	return true


## Découvertes de chaque région, pour une carte ou un journal.
func by_region() -> Dictionary:
	var grouped: Dictionary = {}
	for poi_id: StringName in _registered:
		var region: StringName = region_of(poi_id)
		if not grouped.has(region):
			grouped[region] = {"total": 0, "found": 0}
		var bucket: Dictionary = grouped[region]
		bucket["total"] = int(bucket["total"]) + 1
		if _discovered.has(poi_id):
			bucket["found"] = int(bucket["found"]) + 1
	return grouped


# --- Sauvegarde -------------------------------------------------------------

## Seuls les IDENTIFIANTS sont sérialisés : ni nœud, ni ressource, ni index
## de tableau (§19.2). Un lieu retiré du monde laisse un identifiant inconnu
## au chargement, qui est journalisé puis ignoré — pas un plantage.
func collect_state() -> Dictionary:
	var ids: Array[String] = []
	for poi_id: StringName in _discovered:
		ids.append(String(poi_id))
	ids.sort()
	return {"discovered": ids}


func apply_state(state: Dictionary) -> void:
	_discovered.clear()
	var ids: Variant = state.get("discovered", [])
	if not (ids is Array):
		push_warning("[découvertes] état illisible — journal laissé vide")
		return
	for entry: Variant in ids as Array:
		if not (entry is String) or String(entry).is_empty():
			continue
		var poi_id: StringName = StringName(entry)
		if not _registered.has(poi_id):
			# Un lieu supprimé par une mise à jour ne doit pas casser la
			# reprise (§19.4) : on le note et on continue.
			push_warning("[découvertes] lieu inconnu ignoré : %s" % poi_id)
			continue
		_discovered[poi_id] = true


func clear() -> void:
	_discovered.clear()
