## LE CAMP BRAISE DEVIENT LE PREMIER POI COMPLET — contrat exécutable.
##
## Contrat de prose : `docs/contrats/camp_libere_world_v2.md`.
## Données : `resources/world_v2/world_v2_camp_liberation.json`.
##
## DE QUEL CAMP ON PARLE. Le dépôt en contient deux, à 70 m l'un de l'autre.
## Le sujet est `r05_terrasse_du_camp` — le checkpoint `camp` à (45, 6, 65),
## là où vivent les quatre gardes d'ISS-074. L'autre, `ember_raider_camps.01`
## en r06, a un foyer MORT verrouillé par `test_world_v2_r2b_camps.gd` : il
## n'est pas touché, et aucun cas d'ici ne le regarde.
##
## LES HUIT EXIGENCES, ET CE QUI LES REND VÉRIFIABLES :
##
##   C1 victoire signalée          → une notification part sur EventBus
##   C2 récompense fixe et utile   → un Chest porte l'arme NOMMÉE dans la donnée
##   C3 disponible si on part      → remontage libéré+non pillé : coffre REPOSÉ
##   C4 jamais duplicable          → remontage pillé : coffre ouvert, sans butin
##   C5 état persistant            → champ additif écrit dans le slot
##   C6 transformation visible     → foyer masqué tant que la garnison tient
##   C7 aucun fichier gelé modifié → `tools/gel_verifier.sh` (hors de ce test)
##   C8 aucun texte codé en dur    → le texte notifié vient du JSON, comparé ici
##
## POURQUOI LES DEUX SENS. Un camp qui ne se libère jamais satisferait C3, C4
## et C6 sans rien prouver. Chaque cas « après » a donc son « avant ».
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const DONNEES: String = "res://resources/world_v2/world_v2_camp_liberation.json"
const SLOT: String = "slot0"
const CAMP_ID: String = "camp.ember_terrace"
const GARNISON: String = "garrison.ember_camp"
const CHAMP_MORTS: String = "enemies_slain"

var _world: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _donnees() -> Dictionary:
	var brut: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(DONNEES))
	if not (brut is Dictionary):
		return {}
	for entree: Variant in ((brut as Dictionary).get("camps", []) as Array):
		var camp: Dictionary = entree as Dictionary
		if String(camp.get("id", "")) == CAMP_ID:
			return camp
	return {}


func _save_system() -> Node:
	return _tree().root.get_node_or_null("/root/SaveSystem")


## Sème un slot LISIBLE — la garde d'ISS-082 refuse d'écrire dans un slot
## illisible, et un cas qui l'ignorerait mesurerait ce refus au lieu du camp.
func _semer(payload: Dictionary) -> void:
	var base: Dictionary = {"schema": 4, "world_version": "neris_v2",
		"checkpoint": "world_v2.valley"}
	base.merge(payload, true)
	_save_system().call("save_slot", SLOT, base)


func _lire_slot() -> Dictionary:
	return _save_system().call("load_slot", SLOT) as Dictionary


func _tous_les_morts() -> Array:
	var ids: Array = []
	for suffixe: String in ["red.01", "red.02", "red.03", "blue.01"]:
		ids.append("%s.%s" % [GARNISON, suffixe])
	return ids


func _monter() -> void:
	var gs: Node = _tree().root.get_node_or_null("GameState")
	if gs != null:
		gs.call("consume_pending_spawn")
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_world)
	await _tree().process_frame
	await _tree().physics_frame
	# Le bâtisseur de garnisons ET celui de la libération bâtissent en différé :
	# il faut laisser passer les deux vidages de file.
	await _tree().physics_frame
	await _tree().process_frame
	await _tree().physics_frame
	await _tree().process_frame
	await _tree().physics_frame


func _demonter() -> void:
	_world = null
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())


func _foyer() -> Node3D:
	if _world == null:
		return null
	var chemin: String = String(_donnees().get("foyer_visuel", ""))
	return _world.get_node_or_null(chemin) as Node3D


func _coffre() -> Node:
	if _world == null:
		return null
	var vise: String = String((_donnees().get("recompense", {}) as Dictionary)
		.get("coffre_id", ""))
	for n: Node in _world.find_children("*", "Chest", true, false):
		if String(n.get("chest_id")) == vise:
			return n
	return null


func _vivants() -> int:
	if _world == null:
		return -1
	var n: int = 0
	for e: Node in _world.find_children("*", "EnemyBase", true, false):
		var sante: Node = e.call("health") as Node
		if sante != null and not bool(sante.call("is_dead")):
			n += 1
	return n


# --------------------------------------------------------------------------
# AVANT — la garnison tient le camp
# --------------------------------------------------------------------------
func test_tant_que_la_garnison_tient_le_foyer_est_eteint_et_sans_coffre() -> void:
	remember_saves()
	remember_root()
	_semer({})
	await _monter()

	check_equal(_vivants(), 4, "préalable : les quatre gardes tiennent le camp")
	var foyer: Node3D = _foyer()
	check_not_null(foyer, "le foyer du camp existe (lieu gelé, jamais modifié)")
	if foyer != null:
		check(not foyer.visible,
			"C6 — le foyer est ÉTEINT tant que les pillards tiennent la "
			+ "terrasse : c'est la transformation qui rend la victoire visible")
	check(_coffre() == null,
		"C2/C3 — aucune récompense avant la victoire")
	check(not (_lire_slot().get("camps_liberes", []) as Array).has(CAMP_ID),
		"C5 — rien n'est écrit tant que le camp n'est pas libéré")

	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# APRÈS — le camp est libéré (les quatre morts sont déjà dans le slot)
# --------------------------------------------------------------------------
func test_un_camp_libere_rallume_son_foyer_et_pose_sa_recompense() -> void:
	remember_saves()
	remember_root()
	_semer({CHAMP_MORTS: _tous_les_morts()})
	await _monter()

	check_equal(_vivants(), 0,
		"préalable : les quatre morts persistées ne reviennent pas")
	var foyer: Node3D = _foyer()
	check_not_null(foyer, "le foyer existe toujours")
	if foyer != null:
		check(foyer.visible, "C6 — le camp libéré a rallumé son feu")

	var coffre: Node = _coffre()
	check_not_null(coffre,
		"C2 — la récompense du camp libéré est posée")
	if coffre != null:
		var recompense: Dictionary = _donnees().get("recompense", {}) as Dictionary
		var arme: Resource = coffre.get("weapon_loot") as Resource
		check_not_null(arme, "le coffre porte bien une arme")
		if arme != null:
			check_equal(String(arme.get("id")),
				String(recompense.get("arme", "")),
				"C2 — l'arme est celle NOMMÉE DANS LA DONNÉE, pas un tirage")
		check_equal(int(coffre.get("arrows_loot")),
			int(recompense.get("fleches", -1)),
			"C2 — le nombre de flèches vient aussi de la donnée")
		check(not bool(coffre.call("is_opened")),
			"C3 — il est FERMÉ : le joueur qui revient peut encore le prendre")

	check((_lire_slot().get("camps_liberes", []) as Array).has(CAMP_ID),
		"C5 — « camp libéré » est persisté dans le slot")

	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# C4 — la récompense n'est JAMAIS duplicable
# --------------------------------------------------------------------------
func test_un_coffre_deja_pris_ne_se_repose_pas_plein() -> void:
	remember_saves()
	remember_root()
	var recompense: Dictionary = _donnees().get("recompense", {}) as Dictionary
	var coffre_id: String = String(recompense.get("coffre_id", ""))
	_semer({
		CHAMP_MORTS: _tous_les_morts(),
		"camps_liberes": [CAMP_ID],
		"opened_chests": [coffre_id],
	})
	await _monter()

	var coffre: Node = _coffre()
	check_not_null(coffre,
		"le coffre reste PRÉSENT — on ne fait pas disparaître un meuble")
	if coffre != null:
		check(bool(coffre.call("is_opened")),
			"C4 — il est déjà ouvert : rouvrir la partie ne redonne pas l'arme")

	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# C1 + C8 — la victoire se dit, et son texte vient de la donnée
# --------------------------------------------------------------------------
func test_la_victoire_est_annoncee_avec_le_texte_de_la_donnee() -> void:
	remember_saves()
	remember_root()
	_semer({})
	await _monter()
	check_equal(_vivants(), 4, "préalable : le camp est tenu")

	var bus: Node = _tree().root.get_node_or_null("/root/EventBus")
	check_not_null(bus, "EventBus est monté — c'est le seul chemin du HUD")
	var recus: Array[String] = []
	if bus != null:
		bus.connect("gameplay_notification",
			func(texte: String) -> void: recus.append(texte))

	# On tue les quatre gardes POUR DE VRAI, par leur hurtbox : c'est la porte
	# que le jeu emprunte, et `health().take_damage()` ne la remplace pas.
	for e: Node in _world.find_children("*", "EnemyBase", true, false):
		var evenement: DamageEvent = DamageEvent.new()
		evenement.amount = 9999.0
		var boites: Array[Node] = e.find_children(
			"Hurtbox", "HurtboxComponent", true, false)
		if not boites.is_empty():
			(boites[0] as HurtboxComponent).receive_hit(evenement)
	for _i: int in range(12):
		await _tree().physics_frame

	check_equal(_vivants(), 0, "les quatre gardes sont tombés")
	var attendu: String = String((_donnees().get("textes", {}) as Dictionary)
		.get("victoire", ""))
	check(attendu != "",
		"préalable NON VACUITÉ : la donnée porte bien un texte de victoire — "
		+ "sans lui, la comparaison ci-dessous serait vide contre vide")
	check(recus.has(attendu),
		"C1+C8 — la victoire est annoncée, et MOT POUR MOT avec le texte du "
		+ "JSON : reçu %s" % [recus])

	var foyer: Node3D = _foyer()
	if foyer != null:
		check(foyer.visible,
			"C6 — le feu se rallume au moment de la victoire, pas seulement "
			+ "au rechargement")
	check(_coffre() != null,
		"C2 — la récompense apparaît à la victoire")
	check((_lire_slot().get("camps_liberes", []) as Array).has(CAMP_ID),
		"C5 — et l'état est écrit tout de suite")

	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# C8 — la garde qui empêche de tricher : AUCUN littéral affichable dans le .gd
# --------------------------------------------------------------------------
func test_le_script_de_liberation_ne_contient_aucun_texte_joueur() -> void:
	var source: String = FileAccess.get_file_as_string(
		"res://scripts/world_v2/world_v2_camp_liberation.gd")
	check(source != "", "le script de libération existe")
	var textes: Dictionary = _donnees().get("textes", {}) as Dictionary
	# NON VACUITÉ. Sans ce préalable, renommer le JSON ou changer l'id du camp
	# rendrait `_donnees()` vide : la boucle ne tournerait plus, et seul « le
	# script existe » resterait — VERT, en n'ayant rien vérifié. Le garde
	# contre le texte codé en dur aurait disparu sans un mot.
	check(textes.size() >= 2,
		"préalable : la donnée porte bien ses textes joueur — %d clé(s) "
		% textes.size() + "trouvée(s), sinon la boucle ci-dessous est vide")
	for cle: Variant in textes.keys():
		if String(cle) == "doc":
			continue
		var valeur: String = String(textes[cle])
		check(not source.contains(valeur),
			"C8 — « %s » ne doit exister QUE dans la donnée, jamais dans le "
			% valeur + "script : un texte codé en dur se recopie et diverge")


# --------------------------------------------------------------------------
# L'HYPOTHÈSE CACHÉE DU MÉCANISME : deux clés qui doivent rester d'accord
# --------------------------------------------------------------------------
## `world_v2_camp_liberation.gd` interroge la garnison par DEUX chemins qui ne
## se ressemblent pas :
##
##   `_effectif_attendu()`  lit les ids COMPLETS des fiches `enemies` et les
##                          compare à `enemies_slain` ;
##   `_gardes_vivants()`    retrouve les nœuds par `encounter_id` commençant
##                          par l'id de la GARNISON.
##
## Les deux ne s'accordent que parce que, aujourd'hui, chaque id de fiche
## commence par l'id de sa garnison. Le jour où ce n'est plus vrai, le camp ne
## trouve plus un seul garde, `restants` vaut zéro, aucun `died` n'arrive —
## et le camp reste ÉTEINT, sans récompense, POUR TOUJOURS. Aucun message,
## aucune exception : le joueur voit un feu mort et rien d'autre.
##
## Ce cas ne teste pas un comportement : il épingle l'hypothèse qui le rend
## possible, au seul endroit où elle est vérifiable sans jouer.
func test_les_ids_de_la_garnison_commencent_par_l_id_de_la_garnison() -> void:
	var brut: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/world_v2/world_v2_garrisons.json"))
	check(brut is Dictionary, "les données de garnison se lisent")
	if not (brut is Dictionary):
		return

	var fiches: Array = []
	for entree: Variant in ((brut as Dictionary).get("garrisons", []) as Array):
		var g: Dictionary = entree as Dictionary
		if String(g.get("id", "")) == GARNISON:
			fiches = g.get("enemies", []) as Array
			break

	# NON VACUITÉ : sans fiche, la boucle ci-dessous ne s'exécuterait pas et le
	# cas serait vert en n'ayant rien examiné.
	check(fiches.size() > 0,
		"préalable : la garnison « %s » porte des fiches d'ennemis — %d "
		% [GARNISON, fiches.size()] + "trouvée(s)")

	for fiche: Variant in fiches:
		var id: String = String((fiche as Dictionary).get("id", ""))
		check(id.begins_with(GARNISON),
			"« %s » commence par « %s » — sinon `_gardes_vivants()` ne "
			% [id, GARNISON] + "trouverait aucun garde et le camp resterait "
			+ "éteint sans que rien ne le signale")
