## ISS-073 — LA CHAÎNE COMBINÉE, pas une collection de scènes isolées.
##
## Le portail `test_world_v2_iss073_boucle.gd` prouve l'ENTRÉE : le héros marche
## jusqu'au seuil de World V2 et franchit la porte par la touche d'interaction.
## Ce fichier prouve ce qui vient APRÈS, et surtout les deux RETOURS — les seuls
## endroits où ISS-073 déposait le joueur dans un monde qu'il n'avait jamais
## traversé.
##
## DEUX NIVEAUX DE PREUVE, séparés parce qu'ils ne valent pas la même chose.
## Le projet a déjà payé cette leçon : `test_golden_path.gd` a été renommé
## `test_flow_wiring_path.gd` le 2026-08-09 parce qu'appeler « parcours doré »
## une suite d'appels directs annonçait une couverture qui n'existait pas.
##
##   NIVEAU A — JOUÉ. Les deux retours vers World V2 passent par le geste réel :
##     - la sortie du vestibule est franchie en MARCHANT jusqu'à elle puis en
##       appuyant sur la touche d'interaction ; ni `SceneDoor.interact()`, ni
##       `SceneFlow.go_to()` ne sont appelés à la main ;
##     - « Continuer l'exploration » est déclenché par le signal `pressed` du
##       vrai bouton de l'écran de victoire.
##
##   NIVEAU B — CÂBLAGE. L'intérieur du donjon est vérifié en MONTANT chaque
##     scène et en énumérant les `SceneDoor` qu'elle construit réellement. Cela
##     prouve que le graphe se referme ; cela ne prouve PAS qu'un joueur
##     atteigne chaque porte, et aucun verdict de ce fichier ne doit le laisser
##     croire. La marche réelle de bout en bout appartient à la build exportée
##     (§4 de la directive), pas à ce conteneur.
extends GateTestCase

const WORLD_V2: String = "res://scenes/world_v2/WorldV2.tscn"
const VALLEY_V1: String = "res://scenes/world/valley/ValleyWorld.tscn"
const VESTIBULE: String = "res://scenes/world/citadel/CitadelVestibule.tscn"
const VICTORY: String = "res://scenes/ui/VictoryScreen.tscn"
const ROOM1: String = "res://scenes/dungeon/rooms/Room1Initiation.tscn"
const HALL: String = "res://scenes/dungeon/rooms/CentralHall.tscn"
const ANTECHAMBER: String = "res://scenes/dungeon/rooms/Antechamber.tscn"
const ARENA: String = "res://scenes/boss/BossArena.tscn"

const RETURN_TAG: StringName = &"citadel_door"

var _monde: Node = null
var _tag_pose: StringName = &""


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func check_equal_ctx(obtenu: Variant, attendu: Variant, contexte: String) -> void:
	check(obtenu == attendu,
		"%s (attendu %s, obtenu %s)" % [contexte, str(attendu), str(obtenu)])


func _monter(chemin: String) -> Node:
	_monde = (load(chemin) as PackedScene).instantiate()
	_tree().root.add_child(_monde)
	await _tree().process_frame
	await _tree().physics_frame
	return _monde


func _demonter() -> void:
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())
	restore_saves()
	_monde = null


## Les `SceneDoor` réellement CONSTRUITES par une scène montée, avec leur cible.
func _portes(scene: Node) -> Dictionary:
	var trouvees: Dictionary = {}
	for node: Node in scene.find_children("*", "SceneDoor", true, false):
		trouvees[String(node.name)] = (node as SceneDoor).target_scene
	return trouvees


# --------------------------------------------------------------------------
# NIVEAU A — la sortie du vestibule, FRANCHIE PAR LA TOUCHE
# --------------------------------------------------------------------------
func test_la_sortie_du_vestibule_est_franchie_a_pied_et_ramene_dans_world_v2() -> void:
	remember_saves()
	remember_root()
	var vestibule: Node = await _monter(VESTIBULE)
	var joueur: PlayerController = vestibule.get_node_or_null("Player") as PlayerController
	check(joueur != null, "le vestibule porte le vrai joueur")
	if joueur == null:
		await _demonter()
		return
	var intent: InputIntent = InputIntent.new()
	joueur.set_intent_source(intent)
	var sortie: SceneDoor = vestibule.get_node_or_null("ExitDoor") as SceneDoor
	check(sortie != null, "le vestibule construit bien une porte de sortie")
	if sortie == null:
		await _demonter()
		return
	check_equal_ctx(sortie.target_scene, WORLD_V2,
		"la sortie du vestibule doit rendre au monde de la CAMPAGNE")

	# LE HÉROS ENTRE DOS À LA SORTIE (`VisualRoot` tourné de 180° dans la
	# scène : il regarde le fond du vestibule). Le cône d'interaction suit ce
	# visuel — il doit donc VRAIMENT se retourner, en marchant. C'est ce
	# demi-tour que le test paie, et c'est le geste du joueur.
	var but: Vector2 = Vector2(sortie.global_position.x, sortie.global_position.z)
	var atteint: bool = await _marcher_vers(joueur, intent, but, 1.5, 25.0)
	check(atteint, "le héros atteint la sortie à pied (arrêt en %s, but %s)"
		% [joueur.global_position, but])

	var recu: Array[String] = []
	var flow: Node = _tree().root.get_node_or_null("SceneFlow")
	var gs: Node = _tree().root.get_node_or_null("GameState")
	if flow != null and flow.has_signal("transition_started"):
		flow.connect("transition_started", func(p: String) -> void:
			recu.append(p)
			# Le tag est posé JUSTE AVANT `go_to()` et consommé par World V2
			# dès son `_ready()` : le relever ailleurs serait une course.
			if gs != null:
				_tag_pose = StringName(String(gs.get("_pending_spawn"))))
	for _i: int in range(12):
		intent.interact_pressed = true
		await _tree().physics_frame
		intent.interact_pressed = false
		await _tree().physics_frame
		if not recu.is_empty():
			break
	check_equal_ctx("" if recu.is_empty() else recu[0], WORLD_V2,
		"l'interaction sur la sortie doit demander World V2")
	check_equal_ctx(String(_tag_pose), String(RETURN_TAG),
		"la sortie doit poser le tag que World V2 consomme")
	await _demonter()


# --------------------------------------------------------------------------
# NIVEAU A — « Continuer l'exploration », par le VRAI bouton
# --------------------------------------------------------------------------
func test_le_bouton_continuer_de_l_ecran_de_victoire_renvoie_dans_world_v2() -> void:
	remember_saves()
	remember_root()
	var ecran: Node = await _monter(VICTORY)
	# `auto_navigate` coupé : `SceneFlow.go_to()` remplacerait la scène du
	# runner. Ce qui est prouvé reste ce qui compte — VERS QUOI part le bouton.
	ecran.set("auto_navigate", false)
	var boutons: Array = ecran.call("buttons") as Array
	check(boutons.size() == 3,
		"§16.8 exige trois issues, %d trouvée(s)" % boutons.size())
	var continuer: Button = boutons[0] as Button
	check(continuer != null and not continuer.disabled,
		"le bouton « continuer » doit être activable")
	if continuer == null:
		await _demonter()
		return
	continuer.pressed.emit()
	await _tree().process_frame
	check_equal_ctx(String(ecran.call("last_target")), WORLD_V2,
		"« Continuer l'exploration » doit ramener dans le monde de la campagne")
	# Le bouton « Recommencer » repart du même monde : une partie neuve ne doit
	# pas non plus atterrir dans la vallée V1.
	var recommencer: Button = boutons[1] as Button
	recommencer.pressed.emit()   # 1er appui : demande de confirmation (§17.3)
	await _tree().process_frame
	recommencer.pressed.emit()   # 2e appui : confirmé
	await _tree().process_frame
	check_equal_ctx(String(ecran.call("last_target")), WORLD_V2,
		"« Recommencer » doit repartir dans le monde de la campagne")
	await _demonter()


# --------------------------------------------------------------------------
# NIVEAU B — le graphe du donjon se referme, mesuré sur les scènes MONTÉES
# --------------------------------------------------------------------------
## CE TEST NE PROUVE PAS QU'UN JOUEUR ATTEINT CES PORTES. Il prouve que les
## scènes construisent bien les portes qui relient vestibule → salle 1 → hall
## → antichambre → arène, et que l'arène déclare l'écran de victoire. Une
## rupture ici casse la campagne ; une réussite ici ne la valide pas.
func test_le_graphe_du_donjon_relie_le_vestibule_a_l_arene() -> void:
	remember_saves()
	remember_root()
	var attendus: Array[Array] = [
		[VESTIBULE, ROOM1, "le vestibule doit ouvrir la salle 1"],
		[ROOM1, HALL, "la salle 1 doit ouvrir la salle centrale"],
		[HALL, ANTECHAMBER, "la salle centrale doit ouvrir l'antichambre"],
		[ANTECHAMBER, ARENA, "l'antichambre doit ouvrir l'arène"],
	]
	for etape: Array in attendus:
		var scene: Node = await _monter(String(etape[0]))
		var portes: Dictionary = _portes(scene)
		check(portes.values().has(String(etape[1])),
			"%s — portes construites : %s" % [String(etape[2]), portes])
		await _demonter()
		remember_saves()
		remember_root()

	# L'arène ne pose pas de `SceneDoor` vers la victoire : elle la demande au
	# `SceneFlow` quand le Gardien tombe. On épingle donc la destination
	# qu'elle EXPOSE, et l'existence de la scène visée.
	var arene: Node = await _monter(ARENA)
	check_equal_ctx(String(arene.call("victory_target")), VICTORY,
		"l'arène doit conduire à l'écran de victoire")
	check(ResourceLoader.exists(VICTORY), "l'écran de victoire doit exister")
	await _demonter()


# --------------------------------------------------------------------------
# NIVEAU B — aucune scène de la chaîne ne renvoie dans le monde V1
# --------------------------------------------------------------------------
## Épinglé sur les scènes MONTÉES, pas sur une recherche de texte : un chemin
## calculé à l'exécution échapperait à `grep`.
func test_aucune_porte_de_la_chaine_ne_renvoie_dans_le_monde_v1() -> void:
	var coupables: Array[String] = []
	for chemin: String in [VESTIBULE, ROOM1, HALL, ANTECHAMBER, ARENA]:
		remember_saves()
		remember_root()
		var scene: Node = await _monter(chemin)
		for nom: String in _portes(scene).keys():
			if String(_portes(scene)[nom]) == VALLEY_V1:
				coupables.append("%s::%s" % [chemin.get_file(), nom])
		await _demonter()
	check(coupables.is_empty(),
		"%d porte(s) de la chaîne déposent le joueur dans la vallée V1 : %s"
		% [coupables.size(), ", ".join(coupables)])


## UNE PORTE N'EST PAS LE SEUL CHEMIN DE RETOUR. « Réessayer », après une mort,
## recharge `GameplayShell.world_scene_path` — un `@export` dont la valeur PAR
## DÉFAUT est la vallée V1. Chaque scène de la campagne doit donc la surcharger,
## comme le font déjà les six salles du donjon et l'arène.
##
## Ce trou m'a échappé au premier jet : mon test ne regardait que les
## `SceneDoor`. Le vestibule, lui, ne surchargeait rien — mourir dedans
## déposait le joueur dans un monde qu'il n'a jamais traversé, exactement le
## défaut d'ISS-073 par une autre porte.
func test_aucun_ecran_de_mort_de_la_chaine_ne_recharge_le_monde_v1() -> void:
	var coupables: Array[String] = []
	for chemin: String in [WORLD_V2, VESTIBULE, ROOM1, HALL, ANTECHAMBER, ARENA]:
		remember_saves()
		remember_root()
		var scene: Node = await _monter(chemin)
		for node: Node in scene.find_children("*", "CanvasLayer", true, false):
			if not node.has_method("retry_target"):
				continue
			var cible: String = String(node.call("retry_target"))
			if cible == VALLEY_V1:
				coupables.append("%s::%s" % [chemin.get_file(), node.name])
		await _demonter()
	check(coupables.is_empty(),
		"%d « Réessayer » de la chaîne rechargent la vallée V1 : %s"
		% [coupables.size(), ", ".join(coupables)])


# --------------------------------------------------------------------------
# Marche réelle — copiée du portail, mêmes garde-fous
# --------------------------------------------------------------------------
func _camera_relative(joueur: PlayerController, monde: Vector3) -> Vector2:
	var yaw: Basis = joueur.camera_rig().get_yaw_basis()
	var avant: Vector3 = -yaw.z
	var droite: Vector3 = yaw.x
	avant.y = 0.0
	droite.y = 0.0
	var v: Vector3 = monde
	v.y = 0.0
	if v.length_squared() < 0.000001:
		return Vector2.ZERO
	v = v.normalized()
	return Vector2(v.dot(droite.normalized()), v.dot(avant.normalized())).normalized()


func _marcher_vers(joueur: PlayerController, intent: InputIntent, but: Vector2,
		arrive: float, budget: float) -> bool:
	var ecoule: float = 0.0
	while ecoule <= budget:
		var dt: float = _tree().root.get_physics_process_delta_time()
		var ici: Vector2 = Vector2(joueur.global_position.x, joueur.global_position.z)
		var reste: Vector2 = but - ici
		if reste.length() <= arrive:
			intent.move = Vector2.ZERO
			# Quelques ticks pour que le VISUEL finisse de pivoter : le cône
			# d'interaction le suit, et il converge en temps réel (§8.3).
			for _i: int in range(20):
				await _tree().physics_frame
			return true
		var souhait: Vector2 = reste.normalized()
		intent.move = _camera_relative(joueur, Vector3(souhait.x, 0.0, souhait.y))
		await _tree().physics_frame
		ecoule += dt
	intent.move = Vector2.ZERO
	return false
