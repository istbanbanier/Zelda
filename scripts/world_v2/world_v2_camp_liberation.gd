## LE CAMP BRAISE DEVIENT LE PREMIER POI COMPLET DE WORLD V2.
##
## Contrat : `docs/contrats/camp_libere_world_v2.md`.
## Données : `resources/world_v2/world_v2_camp_liberation.json` — ce script ne
## connaît ni identifiant de garnison, ni récompense, ni texte affiché.
## Preuve  : `tests/world_v2/test_world_v2_camp_libere.gd`.
##
## DE QUEL CAMP IL S'AGIT. `r05_terrasse_du_camp` — le checkpoint `camp`, la
## première rencontre du jeu. Les pillards occupent la terrasse qui doit
## devenir le camp du joueur ; la libérer, c'est rallumer son feu. L'autre
## « camp braise », `ember_raider_camps.01` en r06, est un lieu décoratif dont
## le foyer mort est verrouillé par un test : il n'est pas touché.
##
## POURQUOI CE SCRIPT EXISTE PLUTÔT QU'UNE MODIFICATION DU BÂTISSEUR.
## `world_v2_encounters_builder.gd`, `world_v2_root.gd` et le lieu
## `camp_checkpoint_place.gd` sont GELÉS. Ce nœud est un conteneur FRÈRE
## d'`Encounters` : il observe, il n'édite rien. `REQUIRED_CONTAINERS` ne
## vérifie que des présences, donc un conteneur de plus n'est pas refusé.
##
## TROIS PIÈGES, TOUS MESURÉS, TOUS ÉVITÉS ICI :
##
##   1. un ennemi déjà tombé n'est JAMAIS instancié au rechargement. « Zéro
##      ennemi sous l'hôte » ne distingue donc pas *camp jamais visité* de
##      *camp libéré* : l'effectif ATTENDU se lit dans les données de garnison,
##      et les morts dans la sauvegarde ;
##   2. `_on_died()` ne libère pas le nœud — compter les vivants exige
##      `health().is_dead()`, jamais une simple présence dans l'arbre ;
##   3. les ennemis sont créés au runtime, donc sans owner : `find_children`
##      exige `owned = false`, sans quoi il n'en trouve aucun.
class_name WorldV2CampLiberation
extends Node3D

const DONNEES: String = "res://resources/world_v2/world_v2_camp_liberation.json"
const GARNISONS: String = "res://resources/world_v2/world_v2_garrisons.json"
const COFFRE_SCENE: String = "res://scenes/interactables/Chest.tscn"
const SAVE_SLOT: String = "slot0"
const CHAMP_MORTS: String = "enemies_slain"

## Un camp suivi : sa donnée, ses ennemis encore debout, et ce qu'il a déjà fait.
var _suivis: Array[Dictionary] = []


func _ready() -> void:
	# Différé comme le bâtisseur de garnisons : sa file est vidée avant la
	# nôtre, donc la garnison est déjà posée quand on regarde.
	call_deferred("_build")


func _build() -> void:
	for camp: Dictionary in _camps():
		_installer(camp)


func _camps() -> Array[Dictionary]:
	var sortie: Array[Dictionary] = []
	var brut: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(DONNEES))
	if not (brut is Dictionary):
		push_warning("[camp] données de libération illisibles : %s" % DONNEES)
		return sortie
	for entree: Variant in ((brut as Dictionary).get("camps", []) as Array):
		sortie.append(entree as Dictionary)
	return sortie


## Effectif ATTENDU d'une garnison, lu dans SA source — jamais compté dans
## l'arbre, où les morts persistés n'apparaissent pas (piège 1).
func _effectif_attendu(garnison: String) -> Array[String]:
	var ids: Array[String] = []
	var brut: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(GARNISONS))
	if not (brut is Dictionary):
		return ids
	for entree: Variant in ((brut as Dictionary).get("garrisons", []) as Array):
		var g: Dictionary = entree as Dictionary
		if String(g.get("id", "")) != garnison:
			continue
		for fiche: Variant in (g.get("enemies", []) as Array):
			ids.append(String((fiche as Dictionary).get("id", "")))
	return ids


func _installer(camp: Dictionary) -> void:
	var id: String = String(camp.get("id", ""))
	var garnison: String = String(camp.get("garrison", ""))
	if id == "" or garnison == "":
		return

	var attendus: Array[String] = _effectif_attendu(garnison)
	var payload: Dictionary = _slot()
	var morts: Array = payload.get(CHAMP_MORTS, []) as Array
	var liberes: Array = payload.get(_champ_camps(camp), []) as Array

	var deja_libere: bool = liberes.has(id)
	if not deja_libere and not attendus.is_empty():
		deja_libere = true
		for attendu: String in attendus:
			if not morts.has(attendu):
				deja_libere = false
				break

	if deja_libere:
		_liberer(camp, false)
		return

	# Le camp est TENU : le foyer s'éteint, et l'on écoute chaque garde.
	_eteindre_le_foyer(camp)
	var vivants: Array[Node] = _gardes_vivants(garnison)
	if vivants.is_empty():
		# ÉTAT IMPOSSIBLE, ET C'EST BIEN POUR ÇA QU'IL CRIE. Zéro garde debout
		# alors que le camp n'est pas libéré ne peut venir que d'une erreur de
		# CONFIGURATION — un id de garnison qui a divergé, un bâtisseur qui
		# n'a rien posé. La conséquence, elle, est une vraie panne de jeu :
		# aucun signal n'est connecté, donc le foyer reste éteint et la
		# récompense n'arrive JAMAIS. Sans ce message, elle est parfaitement
		# silencieuse et définitive. `test_world_v2_camp_libere.gd` épingle
		# par ailleurs l'hypothèse qui la rend possible.
		push_warning("[camp] « %s » n'est pas libéré, et pourtant AUCUN "
			% id + "garde de « %s » n'est debout — le camp resterait éteint "
			% garnison + "à jamais. Vérifier que les ids d'ennemis commencent "
			+ "bien par l'id de leur garnison.")
		return
	var suivi: Dictionary = {"camp": camp, "restants": vivants.size()}
	_suivis.append(suivi)
	for garde: Node in vivants:
		garde.connect("died", _sur_mort.bind(suivi))


func _gardes_vivants(garnison: String) -> Array[Node]:
	var sortie: Array[Node] = []
	var racine: Node = get_parent()
	if racine == null:
		return sortie
	# `owned = false` : les ennemis sont créés au runtime (piège 3).
	# `garnison + "."` et non `garnison` nu : un préfixe nu capturerait une
	# future « garrison.ember_camp_nord » dans le camp de « garrison.ember_camp ».
	# Les ids réels sont « <garnison>.<famille>.<n> » — le point est leur
	# séparateur, et `test_world_v2_camp_libere.gd` épingle cette forme.
	var prefixe: String = garnison + "."
	for e: Node in racine.find_children("*", "EnemyBase", true, false):
		var meta: String = String(e.get_meta(&"encounter_id", ""))
		if meta != garnison and not meta.begins_with(prefixe):
			continue
		var sante: Node = e.call("health") as Node
		# `_on_died()` laisse le cadavre dans l'arbre (piège 2).
		if sante != null and not bool(sante.call("is_dead")):
			sortie.append(e)
	return sortie


func _sur_mort(suivi: Dictionary) -> void:
	suivi["restants"] = int(suivi["restants"]) - 1
	if int(suivi["restants"]) > 0:
		return
	_liberer(suivi["camp"] as Dictionary, true)


## `annoncer` distingue les deux chemins : la VICTOIRE se dit au joueur, la
## simple reprise d'un camp déjà libéré ne le félicite pas une seconde fois.
func _liberer(camp: Dictionary, annoncer: bool) -> void:
	_rallumer_le_foyer(camp)
	_poser_la_recompense(camp, annoncer)
	_persister_camp(camp)
	if annoncer:
		_annoncer(camp, "victoire")


# ---------------------------------------------------------------- le foyer --
## On ne fait que basculer une VISIBILITÉ. Démonter le foyer, le déplacer, ou
## toucher `FeuDeCuisine` casserait le contrat de checkpoint, qui exige un
## `Campfire` dans le groupe `interactable`.
func _foyer(camp: Dictionary) -> Node3D:
	var racine: Node = get_parent()
	var chemin: String = String(camp.get("foyer_visuel", ""))
	if racine == null or chemin == "":
		return null
	return racine.get_node_or_null(chemin) as Node3D


func _eteindre_le_foyer(camp: Dictionary) -> void:
	var foyer: Node3D = _foyer(camp)
	if foyer != null:
		foyer.visible = false


func _rallumer_le_foyer(camp: Dictionary) -> void:
	var foyer: Node3D = _foyer(camp)
	if foyer != null:
		foyer.visible = true


# ----------------------------------------------------------- la récompense --
## `annoncer` remonte jusqu'ici, et ce n'est pas cosmétique : sans lui, « les
## pillards ont laissé une caisse » repartait à CHAQUE remontage d'un camp
## libéré non pillé — au `_build` différé, HUD à peine monté, sans qu'aucun
## événement de jeu ne l'ait mérité. Un message qui se répète tout seul cesse
## d'être lu, et emporte les autres avec lui.
func _poser_la_recompense(camp: Dictionary, annoncer: bool) -> void:
	var recompense: Dictionary = camp.get("recompense", {}) as Dictionary
	var coffre_id: String = String(recompense.get("coffre_id", ""))
	if coffre_id == "" or _coffre_existant(coffre_id) != null:
		return

	var coffre: Chest = (load(COFFRE_SCENE) as PackedScene).instantiate() as Chest
	coffre.name = coffre_id.replace(".", "_")
	coffre.chest_id = StringName(coffre_id)
	var arme: String = String(recompense.get("arme", ""))
	if arme != "":
		var chemin: String = "res://resources/weapons/%s.tres" % arme
		if ResourceLoader.exists(chemin):
			coffre.weapon_loot = load(chemin) as WeaponDefinition
		else:
			push_warning("[camp] arme de récompense inconnue : %s" % chemin)
	coffre.arrows_loot = int(recompense.get("fleches", 0))
	var pos: Array = recompense.get("position", []) as Array
	if pos.size() == 3:
		# AVANT `add_child` : la position d'un corps posée après l'entrée dans
		# l'arbre arrive un tick trop tard pour tout ce qui la lit au `_ready`.
		coffre.position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	add_child(coffre)

	# C4 — un coffre déjà pillé revient VIDE et OUVERT. On ne le fait pas
	# disparaître : un meuble qu'on a ouvert reste là où on l'a laissé.
	var pilles: Array = _slot().get(_champ_coffres(camp), []) as Array
	if pilles.has(coffre_id):
		coffre.mark_opened_silently()
	else:
		coffre.opened.connect(_sur_coffre_ouvert.bind(camp))
		if annoncer:
			_annoncer(camp, "recompense_posee")


func _coffre_existant(coffre_id: String) -> Node:
	for n: Node in find_children("*", "Chest", true, false):
		if String((n as Chest).chest_id) == coffre_id:
			return n
	return null


func _sur_coffre_ouvert(_id: StringName, camp: Dictionary) -> void:
	var recompense: Dictionary = camp.get("recompense", {}) as Dictionary
	_ajouter_au_slot(_champ_coffres(camp),
		String(recompense.get("coffre_id", "")))


# ---------------------------------------------------------- la persistance --
func _champ_camps(camp: Dictionary) -> String:
	return String((camp.get("sauvegarde", {}) as Dictionary)
		.get("champ_camps", "camps_liberes"))


func _champ_coffres(camp: Dictionary) -> String:
	return String((camp.get("sauvegarde", {}) as Dictionary)
		.get("champ_coffres", "opened_chests"))


func _save_system() -> Node:
	return get_node_or_null("/root/SaveSystem")


func _slot() -> Dictionary:
	var systeme: Node = _save_system()
	if systeme == null or not bool(systeme.call("has_save", SAVE_SLOT)):
		return {}
	return systeme.call("load_slot", SAVE_SLOT) as Dictionary


func _persister_camp(camp: Dictionary) -> void:
	_ajouter_au_slot(_champ_camps(camp), String(camp.get("id", "")))


## Champ ADDITIF, écrit par la garde d'ISS-082 : un slot présent mais illisible
## — corrompu ou d'un schéma plus récent — n'est pas le nôtre à réécrire.
## Libérer le camp ne doit pas détruire la sauvegarde d'un build futur.
func _ajouter_au_slot(champ: String, valeur: String) -> void:
	if champ == "" or valeur == "":
		return
	var systeme: Node = _save_system()
	if systeme == null or not bool(systeme.call("has_save", SAVE_SLOT)):
		return
	var base: Variant = SaveMergeGuard.base_de_fusion(
		systeme, SAVE_SLOT, "camp libéré")
	if base == null:
		return
	var payload: Dictionary = base as Dictionary
	var liste: Array = payload.get(champ, []) as Array
	if liste.has(valeur):
		return
	liste.append(valeur)
	payload[champ] = liste
	systeme.call("save_slot", SAVE_SLOT, payload)


# ---------------------------------------------------------------- le texte --
## AUCUN texte joueur ne vit dans ce fichier. Il n'existe pas de table de
## localisation dans ce dépôt ; le motif établi — et déjà verrouillé par des
## tests — est « le texte affiché vit dans la donnée ». Le jour où une
## localisation arrive, c'est le JSON qu'elle remplace, pas cette ligne.
func _annoncer(camp: Dictionary, cle: String) -> void:
	var texte: String = String((camp.get("textes", {}) as Dictionary)
		.get(cle, ""))
	if texte == "":
		return
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.call("notify", texte)
