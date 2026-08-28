## ISS-074 — LE PORTAIL DU PEUPLEMENT, RENFORCÉ, ÉCRIT ROUGE D'ABORD.
##
## World V2 est un monde d'action-aventure sans UN SEUL adversaire. Ce fichier
## est la définition EXÉCUTABLE de « la garnison du camp braise existe », et il
## est écrit AVANT la première ligne de production — comme le portail ISS-073
## l'a été pour la boucle. Il est ROUGE aujourd'hui, VOLONTAIREMENT, et ce
## rouge ne vit que sur cette branche : la candidate de lundi n'en porte rien.
##
## La première version de ce portail exigeait « au moins un adversaire ». La
## décision lead du 2026-08-28 l'a jugée trop faible, et elle avait raison :
## un seul ennemi posé n'importe où l'aurait verdie. Les neuf exigences
## ci-dessous sont celles de cette décision, chacune reliée à une grandeur
## RÉELLE et observable du code, jamais à un proxy :
##
##   1. exactement 3 `raider_red` et 1 `raider_blue` ;
##   2. quatre identifiants stables et uniques ;
##   3. les quatre ATTEIGNABLES par la navigation depuis le spawn ;
##   4. exactement un `CombatCoordinator` ;
##   5. les quatre le résolvent — c'est cela, « enregistrés auprès de lui » ;
##   6. territoires bornés ;
##   7. aucune perception débordant sur les zones calmes ou les checkpoints ;
##   8. aucune duplication après démontage/remontage ;
##   9. persistance INDIVIDUELLE des morts.
##
## DEUX CHOSES QUE CE FICHIER REFUSE DE FAIRE, et qui sont la moitié de son
## intérêt :
##
## a) Il ne compte JAMAIS par `get_nodes_in_group()`. Ce groupe est global à
##    l'arbre : une suite précédente qui aurait laissé un monde monté, ou V1 et
##    V2 coexistant, feraient dépasser le compte sans que la garnison soit en
##    faute. Tout se compte dans le SOUS-ARBRE du monde monté, par
##    `find_children(..., owned = false)` — le quatrième argument est
##    obligatoire : un `CombatCoordinator` créé par `.new()` n'a aucun `owner`
##    et resterait invisible avec le défaut `true`.
##
## b) Il n'accepte aucune assertion qui puisse passer À VIDE. Le compte exact
##    des quatre est vérifié EN PREMIER, et les cas qui suivent sortent
##    bruyamment si la garnison n'est pas au complet — sans quoi « aucun
##    poursuivant infini » serait vrai d'un monde vide, et le portail
##    verdirait en n'ayant rien prouvé (le mode de panne d'ISS-018).
##
## LA PERCEPTION ET LES ZONES CALMES — la règle, et son unique exception.
## `WORLD_V2_MASTERPLAN` §8 exige que la perception ennemie ne déborde ni sur
## une zone calme ni sur un checkpoint. La règle exécutable retenue ici est
## PLUS STRICTE et ne demande aucune liste à maintenir à la main : le disque de
## VISION et le disque de POURSUITE de chaque ennemi doivent tenir ENTIÈREMENT
## dans les bornes de sa propre région `r05_terrasse_du_camp`. Toute zone calme
## du monde étant hors de r05, aucune ne peut être atteinte.
##
## L'exception est nommée, unique, et justifiée : le checkpoint `camp`, à
## (45, 6, 65), est DANS r05. Le layout en fait la fonction même de la région —
## « première rencontre 3 approches, cuisine, checkpoint camp » — et sa ligne
## `encounters` dit « garnison braise du camp ». Ce checkpoint est l'OBJECTIF
## de la rencontre, pas un sanctuaire ; exiger qu'aucun garde ne le voie
## rendrait la région impossible à peupler et contredirait le layout. Il est
## donc exclu **par identifiant**, une fois, ici, pour qu'aucune autre
## exclusion ne puisse se glisser en silence.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const LAYOUT: String = "res://resources/world_v2/world_v2_layout.json"
const REGION_ID: String = "r05_terrasse_du_camp"
const SLOT: String = "slot0"

## Le bout du chemin doit finir près de la cible : un chemin qui s'arrête à une
## lèvre de navmesh laisse un ennemi décoratif.
const PORTEE_ATTEIGNABLE_M: float = 4.0
const ATTENDU_ROUGE: int = 3
const ATTENDU_AZUR: int = 1
const ATTENDU_TOTAL: int = 4
## La seule exclusion de la règle des calmes, par identifiant.
const CHECKPOINT_OBJECTIF: String = "camp"
## Champ de sauvegarde ADDITIF : la liste des identifiants de garnison tombés.
const CHAMP_MORTS: String = "enemies_slain"

var _world: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _monter() -> void:
	var gs: Node = _tree().root.get_node_or_null("GameState")
	if gs != null:
		gs.call("consume_pending_spawn")
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_world)
	await _tree().process_frame
	await _tree().physics_frame
	# La carte de navigation se synchronise après le premier tick physique ;
	# la garnison est bâtie en différé pour que le monde entier existe d'abord.
	await _tree().physics_frame
	await _tree().process_frame
	await _tree().physics_frame


func _demonter() -> void:
	_world = null
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())


## Le sous-arbre du monde monté, jamais le groupe global.
func _ennemis() -> Array[Node]:
	if _world == null:
		return []
	return _world.find_children("*", "EnemyBase", true, false)


func _coordinateurs() -> Array[Node]:
	if _world == null:
		return []
	return _world.find_children("*", "CombatCoordinator", true, false)


func _identifiant(ennemi: Node) -> String:
	return String(ennemi.get_meta(&"encounter_id", &""))


func _identifiants(ennemis: Array[Node]) -> Array[String]:
	var ids: Array[String] = []
	for e: Node in ennemis:
		ids.append(_identifiant(e))
	ids.sort()
	return ids


func _bornes_region() -> Dictionary:
	var layout: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(LAYOUT)) as Dictionary
	for entree: Variant in (layout.get("regions", []) as Array):
		var region: Dictionary = entree as Dictionary
		if String(region.get("id", "")) == REGION_ID:
			var bornes: Dictionary = (region["bounds"] as Array)[0] as Dictionary
			return {
				"x": bornes["x"] as Array,
				"z": bornes["z"] as Array,
				"encounters": String(region.get("encounters", "")),
			}
	return {}


func _checkpoints_hors_objectif() -> Array[Dictionary]:
	var layout: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(LAYOUT)) as Dictionary
	var sortie: Array[Dictionary] = []
	for entree: Variant in (layout.get("checkpoints", []) as Array):
		var cp: Dictionary = entree as Dictionary
		if String(cp.get("id", "")) == CHECKPOINT_OBJECTIF:
			continue
		var pos: Variant = cp.get("pos")
		if pos == null:
			continue      # intérieur donjon : hors du monde ouvert
		var p: Array = pos as Array
		sortie.append({
			"id": String(cp.get("id", "")),
			"pos": Vector3(float(p[0]), float(p[1]), float(p[2])),
		})
	return sortie


## Les ancres de sauvegarde de toutes les régions SAUF celle de la garnison.
func _ancres_des_autres_regions() -> Array[Dictionary]:
	var layout: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(LAYOUT)) as Dictionary
	var sortie: Array[Dictionary] = []
	for entree: Variant in (layout.get("regions", []) as Array):
		var region: Dictionary = entree as Dictionary
		if String(region.get("id", "")) == REGION_ID:
			continue
		var ancre: Variant = region.get("save_anchor")
		if ancre == null:
			continue
		var pos: Array = (ancre as Dictionary).get("pos", []) as Array
		if pos.size() < 3:
			continue
		sortie.append({
			"id": String((ancre as Dictionary).get("id", "?")),
			"pos": Vector3(float(pos[0]), float(pos[1]), float(pos[2])),
		})
	return sortie


func _save_system() -> Node:
	return _tree().root.get_node_or_null("SaveSystem")


func _lire_slot() -> Dictionary:
	var system: Node = _save_system()
	if system == null or not bool(system.call("has_save", SLOT)):
		return {}
	return system.call("load_slot", SLOT) as Dictionary


func _ecrire_slot(payload: Dictionary) -> bool:
	var system: Node = _save_system()
	if system == null:
		return false
	return bool(system.call("save_slot", SLOT, payload))


## Une partie EN COURS, c'est-à-dire une sauvegarde qui existe. Le bâtisseur
## refuse délibérément d'en fabriquer une pour y inscrire une mort — allumer
## « Continuer » sur un état que le joueur n'a pas demandé de garder serait
## pire que d'oublier la mort. Le cas 9 se place donc dans le seul contexte où
## la persistance a un sens.
func _slot_de_partie_en_cours() -> Dictionary:
	return {
		"schema": 4,
		"world_version": String(WorldIds.V2_WORLD_ID),
		"checkpoint": "world_v2.valley",
		"playtime_seconds": 120.0,
		"boss_defeated": false,
	}


func _morts_enregistrees() -> Array[String]:
	var morts: Array[String] = []
	for entree: Variant in (_lire_slot().get(CHAMP_MORTS, []) as Array):
		morts.append(String(entree))
	morts.sort()
	return morts


# --------------------------------------------------------------------------
# 1, 2 — la composition exacte, et quatre identifiants stables et uniques
# --------------------------------------------------------------------------
func test_la_garnison_compte_trois_braise_un_azur_et_quatre_identifiants() -> void:
	remember_saves()
	remember_root()
	await _monter()

	var bornes: Dictionary = _bornes_region()
	check(not bornes.is_empty(),
		"la région %s existe dans le layout" % REGION_ID)
	check(String(bornes.get("encounters", "")).contains("garnison"),
		"la ligne `encounters` du layout reste NORMATIVE et annonce une "
		+ "garnison — obtenu : « %s »" % String(bornes.get("encounters", "")))

	var ennemis: Array[Node] = _ennemis()
	check_equal(ennemis.size(), ATTENDU_TOTAL,
		"la garnison compte exactement %d adversaires dans le monde monté — "
			% ATTENDU_TOTAL
		+ "aujourd'hui World V2 n'en porte AUCUN (ISS-074), et ce rouge est la "
		+ "définition exécutable du travail à faire")

	var rouges: int = 0
	var azurs: int = 0
	for e: Node in ennemis:
		if e is RaiderRed:
			rouges += 1
		elif e is RaiderBlue:
			azurs += 1
	check_equal(rouges, ATTENDU_ROUGE,
		"exactement %d pillards braise" % ATTENDU_ROUGE)
	check_equal(azurs, ATTENDU_AZUR,
		"exactement %d pillard azur au guet" % ATTENDU_AZUR)

	var ids: Array[String] = _identifiants(ennemis)
	var vides: int = 0
	for id: String in ids:
		if id.is_empty():
			vides += 1
	check_equal(vides, 0,
		"chaque adversaire porte un identifiant `encounter_id` non vide — "
		+ "sans lui, une mort ne peut pas être persistée individuellement")
	var uniques: Dictionary = {}
	for id: String in ids:
		uniques[id] = true
	check_equal(uniques.size(), ids.size(),
		"les identifiants sont UNIQUES — obtenus : %s" % ", ".join(ids))

	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# 4, 5 — un seul coordinateur, et les quatre le résolvent réellement
# --------------------------------------------------------------------------
func test_un_seul_coordinateur_gouverne_et_les_quatre_le_resolvent() -> void:
	remember_saves()
	remember_root()
	await _monter()

	var coordinateurs: Array[Node] = _coordinateurs()
	check_equal(coordinateurs.size(), 1,
		"exactement un `CombatCoordinator` dans le monde monté — sans lui "
		+ "`_request_attack_token()` rend `true` d'office et §12.8 meurt EN "
		+ "SILENCE ; deux le feraient diverger")

	var ennemis: Array[Node] = _ennemis()
	check_equal(ennemis.size(), ATTENDU_TOTAL,
		"la garnison est au complet avant de juger sa gouvernance")
	if coordinateurs.size() == 1 and ennemis.size() == ATTENDU_TOTAL:
		var attendu: Node = coordinateurs[0]
		var orphelins: Array[String] = []
		for e: Node in ennemis:
			# `_find_coordinator()` est la fonction que le JEU appelle pour
			# demander un token : la seule preuve honnête d'« enregistré
			# auprès de lui » est qu'elle rende CE coordinateur-là.
			var resolu: Variant = e.call("_find_coordinator")
			if resolu != attendu:
				orphelins.append(_identifiant(e))
		check(orphelins.is_empty(),
			"les %d adversaires résolvent LE coordinateur du monde — "
				% ATTENDU_TOTAL
			+ "orphelins : %s" % ", ".join(orphelins))

	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# 3 — les quatre sont ATTEIGNABLES : un ennemi hors navmesh est un décor
# --------------------------------------------------------------------------
func test_les_quatre_sont_atteignables_par_la_navigation() -> void:
	remember_saves()
	remember_root()
	await _monter()

	var ennemis: Array[Node] = _ennemis()
	check_equal(ennemis.size(), ATTENDU_TOTAL,
		"la garnison est au complet avant de juger sa navigation")
	if ennemis.size() == ATTENDU_TOTAL:
		var spawn: Vector3 = _world.call("spawn_position") as Vector3
		var carte: RID = _world.get_world_3d().navigation_map
		NavigationServer3D.map_force_update(carte)
		var injoignables: Array[String] = []
		for e: Node in ennemis:
			var cible: Vector3 = (e as Node3D).global_position
			var chemin: PackedVector3Array = NavigationServer3D.map_get_path(
				carte, spawn, cible, true)
			var bout: float = INF
			if chemin.size() >= 2:
				bout = chemin[chemin.size() - 1].distance_to(cible)
			if bout > PORTEE_ATTEIGNABLE_M:
				injoignables.append("%s (%s)" % [_identifiant(e),
					("%.1f m" % bout) if bout < INF else "aucun chemin"])
		check(injoignables.is_empty(),
			"les %d adversaires sont atteignables depuis le spawn (écart "
				% ATTENDU_TOTAL
			+ "chemin→ennemi ≤ %.1f m) — injoignables : %s"
				% [PORTEE_ATTEIGNABLE_M, ", ".join(injoignables)])

	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# 6, 7 — territoire borné, et perception qui ne déborde ni sur un calme ni
#        sur un checkpoint autre que l'objectif nommé
# --------------------------------------------------------------------------
func test_territoires_bornes_et_calmes_preserves() -> void:
	remember_saves()
	remember_root()
	await _monter()

	var bornes: Dictionary = _bornes_region()
	var ennemis: Array[Node] = _ennemis()
	check_equal(ennemis.size(), ATTENDU_TOTAL,
		"la garnison est au complet avant de juger ses territoires")
	if ennemis.size() != ATTENDU_TOTAL or bornes.is_empty():
		await _demonter()
		restore_saves()
		return

	var xs: Array = bornes["x"] as Array
	var zs: Array = bornes["z"] as Array
	var x_min: float = float(xs[0])
	var x_max: float = float(xs[1])
	var z_min: float = float(zs[0])
	var z_max: float = float(zs[1])

	var infinis: Array[String] = []
	var debordements: Array[String] = []
	for e: Node in ennemis:
		var id: String = _identifiant(e)
		var tuning: Variant = e.get("tuning")
		if tuning == null:
			infinis.append("%s (aucun tuning)" % id)
			continue
		var poursuite: float = float(tuning.get("max_pursuit_distance"))
		var vision: float = float(tuning.get("vision_range"))
		if poursuite <= 0.0:
			infinis.append("%s (poursuite %.1f)" % [id, poursuite])
		# Le territoire est ancré à l'origine capturée au `_ready()`, pas à la
		# position courante : c'est bien ce disque-là que le jeu utilise.
		var origine: Vector3 = e.call("territory_origin") as Vector3
		var ici: Vector3 = (e as Node3D).global_position
		# TROIS disques, pas deux. L'ouïe est la porte dérobée : `hear_noise()`,
		# `receive_alert()` et `witness_ally_death()` réveillent un ennemi sans
		# jamais consulter `max_pursuit_distance`. Un territoire gardé sur la
		# seule vision laisse donc un ennemi entendre — puis poursuivre — bien
		# au-delà de sa région.
		var ouie: float = float(tuning.get("hearing_range"))
		# LES POINTS DE RONDE COMPTENT AUTANT QUE LE POINT DE POSE. Un garde
		# en patrouille EST à son offset, et sa vision comme son ouïe y
		# portent. Vérifier la seule position de montage laisserait un offset
		# de 30 m dans la donnée passer au vert — la revue de complétude l'a
		# nommé avant qu'il ne coûte quoi que ce soit.
		var postes: Array[Vector3] = [ici]
		for decalage: Variant in (e.get("patrol_offsets") as Array):
			postes.append(origine + (decalage as Vector3))
		var couples: Array = [[origine, poursuite, "poursuite"]]
		for poste: Vector3 in postes:
			couples.append([poste, vision, "vision"])
			couples.append([poste, ouie, "ouïe"])
		for couple: Array in couples:
			var centre: Vector3 = couple[0] as Vector3
			var rayon: float = couple[1] as float
			var quoi: String = couple[2] as String
			if centre.x - rayon < x_min or centre.x + rayon > x_max \
					or centre.z - rayon < z_min or centre.z + rayon > z_max:
				debordements.append("%s : %s r=%.1f depuis (%.1f, %.1f) sort de "
					% [id, quoi, rayon, centre.x, centre.z]
					+ "x[%.0f, %.0f] z[%.0f, %.0f]"
						% [x_min, x_max, z_min, z_max])
	check(infinis.is_empty(),
		"chaque adversaire a un territoire borné — poursuivants infinis : %s"
			% ", ".join(infinis))
	check(debordements.is_empty(),
		"vision ET poursuite tiennent dans %s : aucune zone calme du monde "
			% REGION_ID
		+ "n'est hors de portée par construction — débordements : %s"
			% ", ".join(debordements))

	# Et, explicitement, aucun checkpoint ni aucune ancre de sauvegarde d'une
	# AUTRE région sous perception. Les ancres comptent autant que les
	# checkpoints : ce sont les points de reprise du masterplan, et elles sont
	# assez proches pour que cette clause puisse réellement rougir — le seul
	# checkpoint restant, `dungeon_gate`, est à ~260 m et rendrait la clause
	# vraie de tout placement concevable.
	var vus: Array[String] = []
	for cp: Dictionary in _checkpoints_hors_objectif() + _ancres_des_autres_regions():
		for e: Node in ennemis:
			var tuning: Variant = e.get("tuning")
			if tuning == null:
				continue
			var vision: float = float(tuning.get("vision_range"))
			var d: float = (e as Node3D).global_position.distance_to(
				cp["pos"] as Vector3)
			if d <= vision:
				vus.append("%s voit le checkpoint « %s » à %.1f m"
					% [_identifiant(e), String(cp["id"]), d])
	check(vus.is_empty(),
		"aucun checkpoint hors de l'objectif « %s » n'est sous perception — %s"
			% [CHECKPOINT_OBJECTIF, ", ".join(vus)])

	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# 8 — aucune duplication après démontage/remontage
# --------------------------------------------------------------------------
func test_un_remontage_ne_duplique_pas_la_garnison() -> void:
	remember_saves()
	remember_root()
	await _monter()
	var premiers: Array[String] = _identifiants(_ennemis())
	check_equal(premiers.size(), ATTENDU_TOTAL,
		"premier montage : %d adversaires" % ATTENDU_TOTAL)
	_world = null
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())

	remember_root()
	await _monter()
	var seconds: Array[String] = _identifiants(_ennemis())
	check_equal(seconds.size(), ATTENDU_TOTAL,
		"second montage : %d adversaires, pas %d — une garnison qui double à "
			% [ATTENDU_TOTAL, ATTENDU_TOTAL * 2]
		+ "chaque remontage rendrait le « Réessayer » injouable")
	check(seconds == premiers,
		"les identifiants sont STABLES entre deux montages — premiers : %s ; "
			% ", ".join(premiers)
		+ "seconds : %s" % ", ".join(seconds))
	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# 9 — la mort est persistée INDIVIDUELLEMENT : une garnison tombée reste tombée
# --------------------------------------------------------------------------
func test_une_mort_est_persistee_individuellement() -> void:
	remember_saves()
	check(_ecrire_slot(_slot_de_partie_en_cours()),
		"une partie en cours existe — c'est le seul contexte où « rester "
		+ "tombé » veut dire quelque chose")
	remember_root()
	await _monter()

	var ennemis: Array[Node] = _ennemis()
	check_equal(ennemis.size(), ATTENDU_TOTAL,
		"la garnison est au complet avant d'en abattre un")
	if ennemis.size() != ATTENDU_TOTAL:
		await _demonter()
		restore_saves()
		return

	var victime: Node = ennemis[0]
	var id_victime: String = _identifiant(victime)
	var coup: DamageEvent = DamageEvent.new()
	coup.amount = 9999.0
	(victime.call("health") as HealthComponent).take_damage(coup)
	for _i: int in range(8):
		await _tree().physics_frame
	check(bool((victime.call("health") as HealthComponent).is_dead()),
		"la victime « %s » est bien morte" % id_victime)

	var morts: Array[String] = _morts_enregistrees()
	check(morts.has(id_victime),
		"la mort de « %s » est écrite dans `%s` — enregistrées : %s"
			% [id_victime, CHAMP_MORTS,
				("aucune" if morts.is_empty() else ", ".join(morts))])
	check_equal(morts.size(), 1,
		"UNE seule mort enregistrée, pas la garnison entière — c'est le mot "
		+ "« individuellement » du contrat")

	_world = null
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())

	remember_root()
	await _monter()
	var restants: Array[String] = _identifiants(_ennemis())
	check_equal(restants.size(), ATTENDU_TOTAL - 1,
		"au remontage il reste %d adversaires : une garnison tombée reste "
			% (ATTENDU_TOTAL - 1)
		+ "tombée — obtenu %d" % restants.size())
	check(not restants.has(id_victime),
		"« %s » ne ressuscite pas — restants : %s"
			% [id_victime, ", ".join(restants)])
	await _demonter()
	restore_saves()
