## T1 — LA PERSISTANCE DE WORLD V2, ÉCRITE ROUGE D'ABORD.
##
## ISS-073 vient de rendre la boucle ATTEIGNABLE : le menu ouvre World V2, une
## porte mène au donjon, le retour replace le héros devant elle. Le défaut
## suivant sur le chemin critique est qu'elle ne se REPREND pas. `WorldV2Root`
## ne lit ni n'écrit une seule ligne de sauvegarde : « Continuer » rouvre bien
## le monde, mais au point de départ, quelle qu'ait été la partie.
##
## Ce n'est pas une déduction. Le code le DIT, aux deux bouts :
##	 - `world_v2_root.gd` énumère trois provenances et en écarte une —
##	   « une position sauvegardée — hors périmètre de cette corrective » ;
##	 - `main_menu.gd::_on_continue()` charge la sauvegarde, vérifie qu'elle est
##	   lisible, puis appelle `_enter_world()` sans jamais la regarder —
##	   « le checkpoint World V2 repart de son spawn canonique ».
##
## LE PIÈGE QUE CE FICHIER REFUSE. Le portail ISS-073 a mis trois erreurs au
## jour, toutes du même genre : mesurer une grandeur VOISINE de celle qui
## compte. L'équivalent ici serait de tester `SaveSystem.save_slot()` puis
## `load_slot()` — la comptabilité du dictionnaire — et de conclure que la
## reprise fonctionne. Elle ne prouverait rien : `SaveSystem` marche déjà, et
## c'est World V2 qui ne s'en sert pas.
##
## Un contrat n'est donc vert ici que s'il a MONTÉ le monde, écrit, DÉMONTÉ,
## REMONTÉ, et mesuré la position réellement obtenue.
##
## LES DEUX MOITIÉS SONT ASSERTÉES SÉPARÉMENT. Écrire et relire sont deux
## défauts distincts : un monde qui sauvegarde sans relire, ou qui relit ce
## que personne n'écrit, échouerait sur une seule moitié. Chaque cas vérifie
## donc l'écriture par la méthode du monde ET la lecture depuis un slot posé
## à la main par le chemin pavé.
##
## L'AUTORITÉ N'EST PAS CE FICHIER. `docs/WORLD_V2_SAVE_MIGRATION.md` est un
## contrat écrit dès V2.0, et il tranche déjà trois questions que ces cas
## auraient sinon tranchées seuls, mal :
##   §1-2 une position n'appartient à un monde que si `world_version` le dit,
##        et l'ABSENCE du champ signifie le monde V1 ;
##   §4   une position dont le monde ne correspond pas est IGNORÉE d'office —
##        « pas bornée : ignorée » — parce qu'une position V1 peut être
##        parfaitement dans les bornes V2 et pourtant au fond d'un lac V2 ;
##   §6   aucun champ existant du schéma 4 ne change de nom ni de type.
## Les cas ci-dessous mesurent ce contrat-là. Le champ `resume_scene` que
## j'avais d'abord inventé pour C3 a été retiré pour la même raison : le donjon
## écrit DÉJÀ son lieu dans `checkpoint`, et poser une seconde source de vérité
## à côté d'une qui existe est la façon la plus sûre de les faire diverger.
##
## CE QUE T1 DEVRA LEVER, et ce n'est pas un détail à découvrir plus tard :
## `test_world_v2_skeleton.gd` exige aujourd'hui que `slot0` soit « identique
## à l'octet près après le passage en V2 ». Ce contrat datait du squelette,
## quand V2 ne devait pas déranger le jeu V1 ; V2 EST le jeu depuis que le
## menu l'ouvre. Sa levée appartient à la passe de production, documentée
## dans `DECISIONS.md` — pas à ce fichier, qui se contente de la nommer.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const VESTIBULE_SCENE: String = "res://scenes/world/citadel/CitadelVestibule.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"
const SLOT: String = "slot0"

## Nom de la méthode publique que T1 doit poser sur `WorldV2Root`. Un contrat
## fixe le nom : sans lui, chaque test devrait deviner.
const AUTOSAVE_METHOD: StringName = &"autosave"
## Le champ d'identité de monde du contrat de migration (§1-2). Il n'est pas
## inventé ici : `WorldIds` le déclare depuis V2.0, et le contrat lui donne
## déjà sa règle — l'ABSENCE du champ SIGNIFIE le monde V1.
const WORLD_FIELD: String = "world_version"
## Le tag de lieu narratif que le donjon écrit DÉJÀ
## (`antechamber.gd` : `data["checkpoint"] = "dungeon.antechamber"`). C'est
## par lui que la reprise doit router — inventer un `resume_scene` reviendrait
## à poser une seconde source de vérité à côté d'une qui existe.
const TAG_ANTICHAMBRE: String = "dungeon.antechamber"
const ANTICHAMBRE_SCENE: String = "res://scenes/dungeon/rooms/Antechamber.tscn"
## Une position V1 PLAUSIBLE et bien à l'intérieur des bornes V2 : c'est ce qui
## rend le filet C4 discriminant. Une position hors bornes serait rejetée par
## le simple contrôle de sûreté, et ne prouverait rien sur l'identité de monde.
const POSITION_V1_DANS_LES_BORNES_V2: Vector3 = Vector3(45.0, 6.0, 65.0)

## Tolérances de mesure. Le héros est reposé par la gravité après son
## replacement : on vérifie qu'il est AU MÊME ENDROIT, pas qu'il flotte au
## millimètre près.
const TOLERANCE_HORIZONTALE_M: float = 2.0
const TOLERANCE_VERTICALE_M: float = 3.5
## Et surtout : assez LOIN du spawn pour que « restauré » ne puisse pas être
## confondu avec « apparu ».
const ECART_MINIMAL_AU_SPAWN_M: float = 12.0
const SETTLE_FRAMES: int = 24

var _world: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Monte World V2 en repartant d'un flux PROPRE. Le tag d'apparition est
## consommé AVANT le montage : un `citadel_door` oublié par un cas précédent
## enverrait le héros à l'ancre de retour, et le cas suivant mesurerait une
## position juste pour une raison fausse.
func _monter() -> PlayerController:
	# UNE photo par montage. `restore_root()` VIDE sa photo en sortant : un
	# second appel sans nouvelle photo prend les autoloads pour des intrus et
	# les SUPPRIME. Mesuré au premier rouge de ce fichier — GameState, EventBus
	# et SaveSystem effacés au deuxième démontage d'un même cas.
	remember_root()
	var gs: Node = _tree().root.get_node_or_null("GameState")
	if gs != null:
		gs.call("consume_pending_spawn")
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_world)
	await _tree().process_frame
	await _tree().physics_frame
	var player: PlayerController = _world.get_node_or_null("Player") as PlayerController
	var frames: int = 0
	while player != null and not player.is_on_floor() and frames < 120:
		await _tree().physics_frame
		frames += 1
	return player


func _demonter() -> void:
	_world = null
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())


## Un point de sol RÉEL, à l'écart du spawn. Mesuré sur le monde monté, jamais
## recopié d'un document : une constante recopiée vieillit sans prévenir.
func _point_de_sol_ecarte(depuis: Vector3) -> Vector3:
	var space: PhysicsDirectSpaceState3D = \
		(_world as Node3D).get_world_3d().direct_space_state
	for essai: Vector2 in [Vector2(20.0, 18.0), Vector2(-18.0, 20.0),
			Vector2(16.0, -16.0), Vector2(-14.0, -14.0)]:
		var x: float = depuis.x + essai.x
		var z: float = depuis.z + essai.y
		var query := PhysicsRayQueryParameters3D.create(
			Vector3(x, depuis.y + 80.0, z), Vector3(x, depuis.y - 80.0, z), 1)
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			continue
		var sol: Vector3 = hit["position"] as Vector3
		if sol.distance_to(depuis) >= ECART_MINIMAL_AU_SPAWN_M:
			return sol + Vector3.UP * 1.2
	return Vector3.INF


func _poser_le_heros(player: PlayerController, ou: Vector3) -> void:
	player.velocity = Vector3.ZERO
	player.global_position = ou
	player.reset_physics_interpolation()
	var frames: int = 0
	while frames < SETTLE_FRAMES:
		await _tree().physics_frame
		frames += 1


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


## La forme minimale d'une sauvegarde d'AVANT T1 : exactement ce que le menu
## écrit pour une partie neuve, plus ce que le schéma 4 sait déjà porter.
## Une sauvegarde qui se réclame de World V2 — la seule dont la position ait
## le droit d'être réappliquée ici (§2 et §4 du contrat de migration).
func _slot_de_reprise_v2() -> Dictionary:
	var slot: Dictionary = _slot_d_avant_t1()
	slot[WORLD_FIELD] = String(WorldIds.V2_WORLD_ID)
	return slot


func _slot_d_avant_t1() -> Dictionary:
	return {
		"schema": 4,
		"checkpoint": "world_v2.spawn",
		"playtime_seconds": 12.0,
		"boss_defeated": false,
	}


func _distance_horizontale(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# --------------------------------------------------------------------------
# C1 — « Continuer » doit rendre L'ENDROIT, pas seulement le monde.
# --------------------------------------------------------------------------
func test_c1_la_position_du_heros_survit_a_un_demontage_remontage() -> void:
	remember_saves()

	var player: PlayerController = await _monter()
	check_not_null(player, "le joueur est monté avec World V2")
	if player == null:
		await _demonter()
		restore_saves()
		return
	var spawn: Vector3 = (_world.call("spawn_position") as Vector3)
	var cible: Vector3 = _point_de_sol_ecarte(spawn)
	check(cible != Vector3.INF,
		"un point de sol à plus de %.0f m du spawn est mesurable"
			% ECART_MINIMAL_AU_SPAWN_M)
	if cible == Vector3.INF:
		await _demonter()
		restore_saves()
		return
	await _poser_le_heros(player, cible)
	var atteint: Vector3 = player.last_grounded_position()

	# --- MOITIÉ 1 : le monde écrit-il seulement ce qu'il faut ?
	var sait_sauvegarder: bool = _world.has_method(AUTOSAVE_METHOD)
	check(sait_sauvegarder,
		"World V2 doit exposer `%s()` — sans elle, aucune partie ne peut être "
			% AUTOSAVE_METHOD
		+ "reprise à l'endroit où elle s'est arrêtée (T1)")
	if sait_sauvegarder:
		_world.call(AUTOSAVE_METHOD)
		var ecrit: Dictionary = _lire_slot()
		check(ecrit.has("player_position"),
			"l'autosave de World V2 doit poser `player_position` — la clé que "
			+ "le schéma 4 porte déjà, sans migration")
		# §2 du contrat de migration : une position n'appartient à un monde que
		# si la sauvegarde le DIT. Sans ce champ, la position écrite ici serait
		# indiscernable d'une position V1 au prochain chargement.
		check_equal(String(ecrit.get(WORLD_FIELD, "")),
			String(WorldIds.V2_WORLD_ID),
			"l'autosave signe le monde dont vient la position")
		if ecrit.has("player_position") and ecrit["player_position"] is Dictionary:
			var pos: Dictionary = ecrit["player_position"] as Dictionary
			var relu := Vector3(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)),
				float(pos.get("z", 0.0)))
			check(_distance_horizontale(relu, atteint) <= TOLERANCE_HORIZONTALE_M,
				"la position écrite est celle du héros (écrit %s, mesuré %s)"
					% [relu, atteint])

	# --- MOITIÉ 2 : le monde RELIT-il une position posée par le chemin pavé ?
	# Indépendante de la moitié 1 : un monde qui saurait écrire sans relire
	# échouerait ici, et c'est exactement ce qu'il faut voir.
	await _demonter()
	var slot: Dictionary = _slot_de_reprise_v2()
	slot["player_position"] = {"x": atteint.x, "y": atteint.y, "z": atteint.z}
	check(_ecrire_slot(slot), "sauvegarde de reprise écrite par SaveSystem")

	var reprise: PlayerController = await _monter()
	check_not_null(reprise, "le joueur est monté à la reprise")
	if reprise != null:
		var obtenu: Vector3 = reprise.global_position
		var spawn2: Vector3 = (_world.call("spawn_position") as Vector3)
		check(_distance_horizontale(obtenu, atteint) <= TOLERANCE_HORIZONTALE_M,
			"la reprise replace le héros où il s'était arrêté "
			+ "(attendu %s, obtenu %s)" % [atteint, obtenu])
		check(absf(obtenu.y - atteint.y) <= TOLERANCE_VERTICALE_M,
			"la reprise respecte l'altitude (attendu %.2f, obtenu %.2f)"
				% [atteint.y, obtenu.y])
		check(_distance_horizontale(obtenu, spawn2) >= ECART_MINIMAL_AU_SPAWN_M,
			"la reprise n'est PAS le point d'apparition — c'est tout le défaut "
			+ "(distance au spawn : %.1f m)" % _distance_horizontale(obtenu, spawn2))
	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# C2 — l'ORIENTATION aussi. Reprendre dos au chemin est une reprise ratée.
# --------------------------------------------------------------------------
func test_c2_l_orientation_du_heros_survit_a_un_demontage_remontage() -> void:
	remember_saves()

	var player: PlayerController = await _monter()
	check_not_null(player, "le joueur est monté avec World V2")
	if player == null:
		await _demonter()
		restore_saves()
		return
	# Le corps ne tourne jamais (PlayerController._ready) : le lacet vit sur
	# VisualRoot. Mesurer la rotation du CORPS donnerait 0 quoi qu'il arrive —
	# exactement l'erreur de grandeur voisine qu'ISS-073 a coûtée.
	var visual: Node3D = player.get_node_or_null("VisualRoot") as Node3D
	check_not_null(visual, "le héros porte un VisualRoot — c'est lui qui tourne")
	if visual == null:
		await _demonter()
		restore_saves()
		return
	var lacet: float = 1.9
	visual.rotation.y = lacet
	await _tree().physics_frame

	var sait_sauvegarder: bool = _world.has_method(AUTOSAVE_METHOD)
	check(sait_sauvegarder,
		"World V2 doit exposer `%s()` pour écrire aussi le lacet" % AUTOSAVE_METHOD)
	if sait_sauvegarder:
		_world.call(AUTOSAVE_METHOD)
		var ecrit: Dictionary = _lire_slot()
		check(ecrit.has("player_yaw"),
			"l'autosave de World V2 doit poser `player_yaw`")
		if ecrit.has("player_yaw") and (ecrit["player_yaw"] is float):
			check(absf(wrapf(float(ecrit["player_yaw"]) - lacet, -PI, PI)) <= 0.2,
				"le lacet écrit est celui du héros (attendu %.3f, écrit %s)"
					% [lacet, ecrit["player_yaw"]])

	await _demonter()
	var slot: Dictionary = _slot_de_reprise_v2()
	slot["player_yaw"] = lacet
	check(_ecrire_slot(slot), "sauvegarde d'orientation écrite par SaveSystem")

	var reprise: PlayerController = await _monter()
	check_not_null(reprise, "le joueur est monté à la reprise")
	if reprise != null:
		var visual2: Node3D = reprise.get_node_or_null("VisualRoot") as Node3D
		check_not_null(visual2, "le héros repris porte un VisualRoot")
		if visual2 != null:
			check(absf(wrapf(visual2.rotation.y - lacet, -PI, PI)) <= 0.2,
				"la reprise restaure l'orientation (attendu %.3f, obtenu %.3f)"
					% [lacet, visual2.rotation.y])
	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# C3 — la reprise doit rouvrir LA SCÈNE où l'on s'est arrêté.
# --------------------------------------------------------------------------
## La chaîne d'ISS-073 compte six scènes jouables. Un joueur qui sauvegarde
## dans l'antichambre du boss et reprend le lendemain doit y revenir ; aujourd'hui
## « Continuer » rouvre World V2 quoi qu'il arrive, et toute la progression de
## donjon est à refaire à chaque reprise.
##
## AUCUN CHAMP N'EST INVENTÉ ICI. Le donjon écrit déjà son lieu — `antechamber.gd`
## pose `checkpoint = "dungeon.antechamber"` — et `boss_arena.gd` sait déjà que ce
## tag désigne `Antechamber.tscn`. Ce qui manque n'est pas une donnée : c'est que
## le menu la LISE. `_on_continue()` charge la sauvegarde, vérifie qu'elle est
## lisible, puis appelle `_enter_world()` sans jamais la regarder.
##
## MESURÉ SUR LA VRAIE CHAÎNE : on presse le bouton comme un joueur et on lit la
## destination que SceneFlow annonce. Aucun appel direct à `_on_continue()` ni à
## `go_to()` — la leçon d'ISS-073.
func test_c3_la_reprise_rouvre_la_scene_ou_l_on_s_est_arrete() -> void:
	remember_saves()
	var slot: Dictionary = _slot_de_reprise_v2()
	slot["checkpoint"] = TAG_ANTICHAMBRE
	check(_ecrire_slot(slot), "sauvegarde « arrêté dans l'antichambre » écrite")

	remember_root()
	var menu: Node = (load(MAIN_MENU_SCENE) as PackedScene).instantiate()
	_tree().root.add_child(menu)
	await _tree().process_frame
	var flow: Node = _tree().root.get_node_or_null("SceneFlow")
	check_not_null(flow, "SceneFlow présent")
	var destinations: Array[String] = []
	if flow != null:
		flow.connect("transition_started",
			func(chemin: String) -> void: destinations.append(chemin))
	var bouton: Button = menu.get_node_or_null("%ContinueButton") as Button
	check_not_null(bouton, "le menu porte son bouton « Continuer »")
	if bouton != null:
		check(not bouton.disabled,
			"« Continuer » est actif quand une sauvegarde existe")
		bouton.emit_signal("pressed")
		await _tree().process_frame
		await _tree().process_frame
	check_equal(destinations.size(), 1,
		"un seul départ de transition après l'appui")
	if destinations.size() == 1:
		check(destinations[0] != WORLD_V2_SCENE,
			"« Continuer » ne renvoie PAS au monde ouvert un joueur arrêté dans "
			+ "le donjon — c'est le défaut, et il coûte tout le donjon")
		check_equal(destinations[0], ANTICHAMBRE_SCENE,
			"« Continuer » rouvre la scène que le tag `%s` désigne déjà"
				% TAG_ANTICHAMBRE)
	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# C4 — FILET : une position V1 n'est JAMAIS réappliquée dans World V2.
# --------------------------------------------------------------------------
## Vert aujourd'hui, et il doit le rester après T1 — c'est le §4 du contrat de
## migration, mot pour mot : une position dont le `world_version` ne correspond
## pas au monde qui charge est **ignorée d'office**, « pas bornée : ignorée —
## une position V1 peut être parfaitement dans les bornes V2 et pourtant au fond
## d'un lac V2 ».
##
## Le filet est DISCRIMINANT parce que la position choisie est plausible et bien
## à l'intérieur des bornes V2 : le contrôle de sûreté ne la rejetterait pas.
## Seule l'identité de monde peut la rejeter. Un T1 qui relirait `player_position`
## sans regarder `world_version` verdirait C1 et rougirait ICI — et c'est très
## exactement ce qu'on veut voir.
##
## Où atterrit le héros à la place, c'est l'affaire de la migration V1 → V2
## (§4 : checkpoint compatible, puis ancre de région, puis spawn). Elle n'est pas
## implémentée, et ce filet ne la préempte pas : il épingle l'invariant qui ne
## bougera jamais — le héros n'est PAS à la coordonnée V1, et il est posé sur un
## sol.
func test_c4_une_position_v1_n_est_jamais_reappliquee_en_v2() -> void:
	remember_saves()
	var slot: Dictionary = _slot_d_avant_t1()
	check(not slot.has(WORLD_FIELD),
		"une sauvegarde d'avant T1 ne porte AUCUN `%s` — son absence SIGNIFIE "
			% WORLD_FIELD + "le monde V1 (contrat de migration §1)")
	slot["player_position"] = {
		"x": POSITION_V1_DANS_LES_BORNES_V2.x,
		"y": POSITION_V1_DANS_LES_BORNES_V2.y,
		"z": POSITION_V1_DANS_LES_BORNES_V2.z,
	}
	check(_ecrire_slot(slot), "sauvegarde V1 avec position écrite")

	var player: PlayerController = await _monter()
	check_not_null(player, "le monde monte sur une sauvegarde d'avant T1")
	if player != null:
		var obtenu: Vector3 = player.global_position
		check(_distance_horizontale(obtenu, POSITION_V1_DANS_LES_BORNES_V2) > 5.0,
			"la position V1 %s n'est pas réappliquée (héros en %s)"
				% [POSITION_V1_DANS_LES_BORNES_V2, obtenu])
		check(player.is_on_floor(),
			"le héros est posé sur un sol, pas suspendu ni tombant")
		check(not String(_world.call("spawn_source")).is_empty(),
			"le monde déclare franchement d'où il a placé le héros (obtenu « %s »)"
				% _world.call("spawn_source"))
	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# C5 — FILET : une sauvegarde corrompue donne un départ propre, jamais un
# crash ni une téléportation hors monde.
# --------------------------------------------------------------------------
## Vert aujourd'hui pour une mauvaise raison — World V2 ne lit rien. Il doit
## rester vert quand il lira, et c'est là que le filet gagne son sens. Les
## formes viennent de `valley_world.gd`, qui traite déjà `player_position`
## comme une ENTRÉE NON FIABLE : le fichier est éditable à la main.
func test_c5_une_sauvegarde_corrompue_replie_sur_le_spawn() -> void:
	remember_saves()

	var formes: Array[Dictionary] = [
		{"nom": "position absente du dictionnaire",
			"valeur": {"y": 34.0, "z": 0.0}},
		{"nom": "composantes en chaînes de caractères",
			"valeur": {"x": "12", "y": "34", "z": "56"}},
		{"nom": "position très au-delà des bornes du monde",
			"valeur": {"x": 900000.0, "y": 34.0, "z": -900000.0}},
		{"nom": "position sous le filet de chute",
			"valeur": {"x": 0.0, "y": -4000.0, "z": 0.0}},
	]
	for forme: Dictionary in formes:
		var slot: Dictionary = _slot_d_avant_t1()
		slot["player_position"] = forme["valeur"]
		check(_ecrire_slot(slot), "slot corrompu écrit : %s" % forme["nom"])
		var player: PlayerController = await _monter()
		check_not_null(player, "le monde monte malgré : %s" % forme["nom"])
		if player != null:
			var spawn: Vector3 = (_world.call("spawn_position") as Vector3)
			check(_distance_horizontale(player.global_position, spawn) <= 3.0,
				"repli au point d'apparition malgré « %s » (distance %.2f m)"
					% [forme["nom"],
						_distance_horizontale(player.global_position, spawn)])
		await _demonter()

	# Et le cas que `SaveSystem` doit intercepter AVANT le monde : un fichier
	# tronqué. `load_slot` doit refuser, et le monde monter quand même.
	var system: Node = _save_system()
	check_not_null(system, "SaveSystem présent")
	if system != null:
		var chemin: String = String(system.call("slot_path", SLOT))
		var f: FileAccess = FileAccess.open(chemin, FileAccess.WRITE)
		check_not_null(f, "le fichier de sauvegarde est ouvrable en écriture")
		if f != null:
			f.store_string('{"schema_version": 4, "data": {"player_pos')
			f.close()
		check((system.call("load_slot", SLOT) as Dictionary).is_empty(),
			"un JSON tronqué est refusé, jamais appliqué à moitié")
		var player: PlayerController = await _monter()
		check_not_null(player, "le monde monte sur un fichier tronqué")
		if player != null:
			var spawn: Vector3 = (_world.call("spawn_position") as Vector3)
			check(_distance_horizontale(player.global_position, spawn) <= 3.0,
				"repli au point d'apparition sur fichier tronqué")
		await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# C6 — FILET : les identifiants persistants sont stables et uniques.
# --------------------------------------------------------------------------
## Ce que T1 va persister devra être CLÉ par ces identifiants. S'ils dépendent
## de l'ordre de construction ou du chemin de nœud, un lieu renommé perdra son
## état sans que rien ne rougisse. On monte donc le monde DEUX FOIS et on exige
## la même carte identifiant → position.
func test_c6_les_identifiants_de_lieux_sont_stables_entre_deux_montages() -> void:
	remember_saves()

	var releves: Array[Dictionary] = []
	for passage: int in range(2):
		var player: PlayerController = await _monter()
		check_not_null(player, "montage %d réussi" % (passage + 1))
		var carte: Dictionary = {}
		var doublons: Array[String] = []
		for lieu: Node in _tree().get_nodes_in_group(&"world_v2_places"):
			var id: String = String(lieu.get_meta(&"place_id", ""))
			check(not id.is_empty(),
				"chaque lieu porte un `place_id` non vide (nœud %s)" % lieu.name)
			if carte.has(id):
				doublons.append(id)
			var p: Vector3 = (lieu as Node3D).global_position
			carte[id] = Vector3(snappedf(p.x, 0.01), snappedf(p.y, 0.01),
				snappedf(p.z, 0.01))
		check(doublons.is_empty(),
			"aucun identifiant de lieu en double — fautifs : %s"
				% ", ".join(doublons))
		releves.append(carte)
		await _demonter()

	check_equal(releves.size(), 2, "deux relevés effectués")
	if releves.size() == 2:
		check(releves[0].size() >= 15,
			"les lieux du registre sont bien là (%d relevés)" % releves[0].size())
		check_equal(releves[1].size(), releves[0].size(),
			"le second montage produit autant de lieux que le premier")
		var derives: Array[String] = []
		for id: String in releves[0].keys():
			if not releves[1].has(id):
				derives.append("%s (disparu)" % id)
			elif releves[1][id] != releves[0][id]:
				derives.append("%s (%s -> %s)" % [id, releves[0][id], releves[1][id]])
		check(derives.is_empty(),
			"identifiants ET positions identiques d'un montage à l'autre — "
			+ "dérives : %s" % ", ".join(derives))
	restore_saves()


## Monte le monde APRÈS avoir posé un tag d'apparition, comme le fait une
## transition réelle. `_monter()` consomme le tag pour partir propre ; il faut
## donc un chemin explicite pour les cas qui veulent en éprouver un.
func _monter_avec_tag(tag: StringName) -> PlayerController:
	remember_root()
	var gs: Node = _tree().root.get_node_or_null("GameState")
	if gs != null:
		gs.call("consume_pending_spawn")
		gs.call("set_pending_spawn", tag)
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_world)
	await _tree().process_frame
	await _tree().physics_frame
	var player: PlayerController = _world.get_node_or_null("Player") as PlayerController
	var frames: int = 0
	while player != null and not player.is_on_floor() and frames < 120:
		await _tree().physics_frame
		frames += 1
	return player


# --------------------------------------------------------------------------
# C7 — ce que la contre-revue a trouvé, et que T1 doit tenir
# --------------------------------------------------------------------------
## Deux défauts d'un même geste, nommés par la contre-revue ISS-073 à contexte
## frais :
##
## 1. `retry_checkpoint` est posé par « Réessayer » (`gameplay_shell.gd`) et
##	  compris par AUCUNE scène : World V2 le traitait en tag inconnu. Le
##	  contrôle négatif a PRÉCISÉ le constat, et il faut le dire exactement —
##	  sans la constante `RETRY_TAG`, ce cas reste VERT. Le placement correct
##	  après un « Réessayer » vient de C1 : dès qu'une position sauvegardée
##	  existe, la reprise s'y fait. Ce que `RETRY_TAG` corrige est un
##	  avertissement FAUX (« tag d'apparition inconnu ») émis à chaque mort.
##	  La moitié discriminante de ce cas est donc la première, pas la seconde.
##
## 2. Et le crochet d'autosave de T1 se déclenche sur cette transition-là
##	  aussi. Sans garde, mourir inscrirait le lieu de sa mort comme point de
##	  reprise — le joueur ressusciterait là où il vient d'être tué. Le défaut
##	  naît AVEC le correctif : c'est exactement ce qu'une contre-revue doit
##	  attraper, et pourquoi elle passe après l'implémentation, pas avant.
func test_c7_la_mort_ne_deplace_pas_le_point_de_reprise() -> void:
	remember_saves()

	var player: PlayerController = await _monter()
	check_not_null(player, "le joueur est monté avec World V2")
	if player == null:
		await _demonter()
		restore_saves()
		return
	var spawn: Vector3 = (_world.call("spawn_position") as Vector3)
	var vivant: Vector3 = _point_de_sol_ecarte(spawn)
	check(vivant != Vector3.INF, "un point de sol écarté est mesurable")
	if vivant == Vector3.INF:
		await _demonter()
		restore_saves()
		return

	# --- Vivant : la sauvegarde suit le héros.
	await _poser_le_heros(player, vivant)
	var atteint: Vector3 = player.last_grounded_position()
	_world.call(AUTOSAVE_METHOD)
	var apres_vie: Dictionary = _lire_slot()
	check(apres_vie.has("player_position"),
		"vivant, l'autosave écrit bien une position")

	# --- Mort AILLEURS : la sauvegarde ne doit PAS suivre.
	var ailleurs := Vector3(spawn.x, spawn.y, spawn.z)
	await _poser_le_heros(player, ailleurs)
	var sante: Node = player.health()
	check_not_null(sante, "le héros porte un HealthComponent")
	if sante != null:
		var coup := DamageEvent.new()
		coup.amount = 9999.0
		coup.damage_type = &"test"
		sante.take_damage(coup)
		check(sante.is_dead(), "le héros est bien mort pour la mesure")
	_world.call(AUTOSAVE_METHOD)
	var apres_mort: Dictionary = _lire_slot()
	check_equal(apres_mort.get("player_position"),
		apres_vie.get("player_position"),
		"la mort n'a pas déplacé le point de reprise")
	await _demonter()

	# --- « Réessayer » pose `retry_checkpoint` : ce tag doit RENDRE la
	# sauvegarde, pas produire un tag inconnu et un dépôt au spawn.
	var slot: Dictionary = _slot_de_reprise_v2()
	slot["player_position"] = {"x": atteint.x, "y": atteint.y, "z": atteint.z}
	check(_ecrire_slot(slot), "sauvegarde de reprise écrite")
	var gs: Node = _tree().root.get_node_or_null("GameState")
	check_not_null(gs, "GameState présent")
	var reprise: PlayerController = await _monter_avec_tag(&"retry_checkpoint")
	check_not_null(reprise, "le monde monte après un « Réessayer »")
	if reprise != null:
		var obtenu: Vector3 = reprise.global_position
		var spawn2: Vector3 = (_world.call("spawn_position") as Vector3)
		check(_distance_horizontale(obtenu, atteint) <= TOLERANCE_HORIZONTALE_M,
			"« Réessayer » reprend au dernier état sauvegardé "
			+ "(attendu %s, obtenu %s)" % [atteint, obtenu])
		check(_distance_horizontale(obtenu, spawn2) >= ECART_MINIMAL_AU_SPAWN_M,
			"et pas au point d'apparition, à %.0f m de là"
				% _distance_horizontale(atteint, spawn2))
		check_equal(String(_world.call("spawn_source")), "sauvegarde",
			"le monde nomme franchement la provenance du placement")
	await _demonter()
	restore_saves()
