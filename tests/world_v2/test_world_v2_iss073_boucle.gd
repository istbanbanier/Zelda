## ISS-073 — LA BOUCLE DE CAMPAGNE, DEPUIS LA CHAÎNE JOUABLE RÉELLE.
##
## ÉCRIT ROUGE D'ABORD, le 2026-08-27, sur un défaut S1 mesuré à la main :
## le menu ouvre `WorldV2.tscn`, World V2 ne porte AUCUNE `SceneDoor`, et
## quatre chemins de retour visent encore `ValleyWorld.tscn` — un monde que
## le menu n'ouvre plus. Donjon, boss, antichambre, coffre final et écran de
## victoire sont donc inatteignables par le chemin d'un joueur.
##
## POURQUOI 111 TESTS VERTS NE L'ONT PAS VU. Les suites `tests/world_v2/`
## vérifient le monde POUR LUI-MÊME — relief, routes, hydrologie, et même la
## traversée physique pilotée par le vrai `PlayerController`. Mais aucune ne
## FRANCHIT le seuil : `test_world_v2_traversal.gd` s'arrête à `GATE_GOAL`,
## trois mètres devant une porte qui n'existe pas, et se déclare satisfaite.
## C'est le mode de panne d'ISS-018 dans un autre domaine — des tests verts
## qui mesurent une grandeur VOISINE de celle qui compte.
##
## CE QUE CE FICHIER S'INTERDIT, et c'est le cœur de sa valeur :
##   - appeler `SceneDoor.interact()` directement ;
##   - appeler `SceneFlow.go_to()` directement ;
##   - écrire `global_position` pour « arriver » au seuil.
## Atteindre les coordonnées de la porte n'est PAS la franchir. Le seul
## passage qui compte est celui d'un joueur : marcher, puis appuyer sur la
## touche d'interaction, et voir la scène changer.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const VESTIBULE_SCENE: String = "res://scenes/world/citadel/CitadelVestibule.tscn"
const VALLEY_V1_SCENE: String = "res://scenes/world/valley/ValleyWorld.tscn"
const MAIN_MENU_SCRIPT: String = "res://scripts/ui/main_menu.gd"

## Ancre §3.3 du seuil, et le point d'arrêt de la marche : assez près pour
## que le cône d'interaction attrape la porte, jamais dessus.
const GATE_ANCHOR: Vector2 = Vector2(0.0, -210.0)
const WALK_STOP: Vector2 = Vector2(0.0, -204.0)
const ARRIVE_M: float = 3.0
const WALK_BUDGET_S: float = 90.0
## Le retour du vestibule doit poser le héros DEVANT la porte, pas au spawn.
const RETURN_TAG: StringName = &"citadel_door"
const RETURN_MAX_FROM_GATE_M: float = 30.0
const RETURN_MIN_FROM_SPAWN_M: float = 100.0
## AUCUN jalon inventé. Les miens enlisaient le héros vers z = -150, dans
## un relief que personne n'avait marché : la route officielle du layout est
## LA route prouvée par `test_world_v2_traversal.gd`, et c'est elle qu'on
## reprend, lue au groupe `world_v2_routes` — donc au monde réellement monté,
## jamais recopiée.

const _STALL_TRIGGER_S: float = 1.2
const _SIDESTEP_S: float = 0.9
const _SIDESTEP_ANGLE: float = 1.15

var _world: Node3D = null
var _teleports: float = 0.0


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Démontage par le CONTRAT de la classe de base : `remember_root()` au
## début, `restore_root()` à la fin. Une file `queue_free()` ne suffit pas —
## le monde survivrait une frame de plus et le cas suivant hériterait d'un
## arbre pollué, pour une raison qui ne serait pas la sienne.
func _demonter() -> void:
	_world = null
	var gs: Node = _tree().root.get_node_or_null("GameState")
	if gs != null:
		gs.call("consume_pending_spawn")
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())
	restore_saves()


## `check_equal` sans le mot « assert » : même sémantique, message explicite.
func check_equal_ctx(obtenu: Variant, attendu: Variant, contexte: String) -> void:
	check(obtenu == attendu, "%s (attendu %s, obtenu %s)"
		% [contexte, attendu, obtenu])


# --------------------------------------------------------------------------
# 1. Le premier maillon : le menu mène-t-il bien à World V2 ?
# --------------------------------------------------------------------------
func test_le_menu_principal_ouvre_bien_world_v2() -> void:
	var src: String = FileAccess.get_file_as_string(MAIN_MENU_SCRIPT)
	check(src.contains(WORLD_V2_SCENE),
		"le menu principal doit ouvrir World V2 — sans quoi la chaîne testée "
		+ "ici n'est pas celle du joueur")
	var flow: Node = _tree().root.get_node_or_null("SceneFlow")
	check(flow != null and bool(flow.call("can_go_to", WORLD_V2_SCENE)),
		"SceneFlow doit accepter World V2 comme destination")


# --------------------------------------------------------------------------
# 2. LE PORTAIL : une porte existe-t-elle seulement au seuil ?
# --------------------------------------------------------------------------
func test_une_porte_de_scene_existe_au_seuil_du_donjon() -> void:
	remember_saves()
	remember_root()
	await _monter_le_monde()
	var portes: Array[Node] = _portes_du_monde()
	check(not (portes.is_empty()),
		"AUCUNE SceneDoor dans World V2 : le donjon est inatteignable par le "
		+ "chemin du joueur (ISS-073). Un marqueur `dungeon_gate` n'est pas "
		+ "une porte — on ne peut pas interagir avec un Node3D nu")
	var seuil: SceneDoor = _porte_du_donjon(portes)
	check(seuil != null,
		"aucune porte ne vise le vestibule ; portes trouvées : %s"
		% [_decrire(portes)])
	# Sans cette garde, l'absence de porte produit un SCRIPT ERROR qui AVORTE
	# le cas en silence — et le runner ne verrait plus les vraies raisons.
	if seuil != null:
		var au_sol: Vector2 = Vector2(seuil.global_position.x,
			seuil.global_position.z)
		check(au_sol.distance_to(GATE_ANCHOR) < 25.0,
			"la porte doit être au seuil §3.3 %s, mesurée en %s"
			% [GATE_ANCHOR, au_sol])
		check_equal_ctx(String(seuil.spawn_tag), String(RETURN_TAG),
			"la porte doit poser le tag de retour, sinon le vestibule ne "
			+ "saura pas d'où l'on vient")
	await _demonter()


# --------------------------------------------------------------------------
# 3. LE PASSAGE : marcher jusqu'au seuil, puis INTERAGIR normalement.
# --------------------------------------------------------------------------
func test_le_joueur_marche_au_seuil_puis_franchit_par_interaction() -> void:
	remember_saves()
	remember_root()
	var intent: InputIntent = InputIntent.new()
	var player: PlayerController = await _monter_et_piloter(intent)
	check(player != null, "joueur introuvable dans World V2")

	var jalons: Array[Vector2] = _jalons_de_route("main_path")
	check(jalons.size() >= 3,
		"la route principale doit être lisible depuis le monde monté "
		+ "(%d jalon(s))" % jalons.size())
	jalons.append(WALK_STOP)
	var atteints: int = 0
	for jalon: Vector2 in jalons:
		if not await _marcher_vers(player, intent, jalon):
			break
		atteints += 1
	check_equal_ctx(atteints, jalons.size(),
		"le héros marche jusqu'au seuil (%d/%d jalons, arrêt en %s)"
		% [atteints, jalons.size(), player.global_position])
	check(_teleports < 3.0,
		"déplacement anormal de %.2f m en un tick — le héros a été déplacé, "
		% _teleports + "pas piloté")

	# Le seul geste qui compte : la touche d'interaction. Ni appel direct à
	# `SceneDoor.interact()`, ni appel direct à `SceneFlow.go_to()`.
	var demande: String = await _interagir_et_lire_la_destination(player, intent)
	check_equal_ctx(demande, VESTIBULE_SCENE,
		"l'interaction au seuil doit demander le vestibule ; demandé : « %s »"
		% demande)

	var gs: Node = _tree().root.get_node_or_null("GameState")
	check(gs != null, "GameState absent")
	check_equal_ctx(String(gs.call("consume_pending_spawn")), String(RETURN_TAG),
		"la porte doit avoir posé le tag de retour AVANT la transition")
	await _demonter()


# --------------------------------------------------------------------------
# 4. LE RETOUR : World V2 consomme-t-il le tag, et où pose-t-il le héros ?
# --------------------------------------------------------------------------
func test_le_retour_du_vestibule_replace_le_heros_devant_la_citadelle() -> void:
	remember_saves()
	remember_root()
	var gs: Node = _tree().root.get_node_or_null("GameState")
	check(gs != null, "GameState absent")
	gs.call("set_pending_spawn", RETURN_TAG)

	await _monter_le_monde()
	var root: Node3D = _world
	var player: Node3D = root.get_node("Player") as Node3D
	var spawn: Vector3 = (root.get_node("SpawnPoint") as Node3D).global_position
	var ici: Vector3 = player.global_position

	check_equal_ctx(String(gs.call("consume_pending_spawn")), "",
		"World V2 doit CONSOMMER le tag d'apparition — sinon il resservira à "
		+ "la transition suivante et le héros repartira dans le vestibule")

	var au_sol: Vector2 = Vector2(ici.x, ici.z)
	check(au_sol.distance_to(GATE_ANCHOR) < RETURN_MAX_FROM_GATE_M,
		"retour attendu DEVANT la citadelle (%s), obtenu %s"
		% [GATE_ANCHOR, au_sol])
	check(ici.distance_to(spawn) > RETURN_MIN_FROM_SPAWN_M,
		"le héros est réapparu au spawn initial %s : le tag n'a pas été "
		% spawn + "consommé, ou la position sauvegardée l'a emporté")

	# Ne pas ressortir DANS la porte : sinon l'interaction se redéclenche et
	# le joueur repart aussitôt d'où il vient.
	var portes: Array[Node] = _portes_du_monde()
	var seuil: SceneDoor = _porte_du_donjon(portes)
	if seuil != null:
		check(ici.distance_to(seuil.global_position) > 2.0,
			"le héros ressort DANS le volume de la porte — transition "
			+ "inverse immédiate garantie")
	await _demonter()


# --------------------------------------------------------------------------
# 5. AUCUN chemin de la campagne V2 ne doit ramener dans le monde V1.
# --------------------------------------------------------------------------
func test_aucune_destination_runtime_ne_ramene_au_monde_v1() -> void:
	var coupables: Array[String] = []
	for chemin: String in [
			"res://scripts/ui/victory_screen.gd",
			"res://scripts/ui/gameplay_shell.gd",
			"res://scripts/world/citadel_vestibule.gd"]:
		var src: String = FileAccess.get_file_as_string(chemin)
		if src.contains(VALLEY_V1_SCENE):
			coupables.append(chemin.get_file())
	check(coupables.is_empty(),
		"%d chemin(s) de retour visent encore le monde V1 : %s — un joueur "
		% [coupables.size(), ", ".join(coupables)]
		+ "de la campagne V2 y serait déposé dans une vallée que le menu "
		+ "n'ouvre plus")


# ==========================================================================
# Outillage — aucune de ces fonctions n'écrit une position de joueur.
# ==========================================================================
func _monter_le_monde() -> void:
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_world)
	await _tree().process_frame
	await _tree().physics_frame


func _monter_et_piloter(intent: InputIntent) -> PlayerController:
	await _monter_le_monde()
	var player: PlayerController = _world.get_node("Player") as PlayerController
	if player == null:
		return null
	player.set_intent_source(intent)
	var pose: float = 0.0
	while not player.is_on_floor() and pose < 8.0:
		await _tree().physics_frame
		pose += _tree().root.get_physics_process_delta_time()
	_teleports = 0.0
	return player


## Jalons de la route officielle, lus sur le monde monté.
func _jalons_de_route(nom: String) -> Array[Vector2]:
	var buts: Array[Vector2] = []
	for node: Node in _tree().get_nodes_in_group(&"world_v2_routes"):
		if String(node.name) != nom:
			continue
		for w: Variant in (node.get_meta(&"waypoints_xz", []) as Array):
			buts.append(Vector2(float((w as Array)[0]), float((w as Array)[1])))
	return buts


func _portes_du_monde() -> Array[Node]:
	var trouvees: Array[Node] = []
	if _world == null:
		return trouvees
	for n: Node in _world.find_children("*", "SceneDoor", true, false):
		trouvees.append(n)
	return trouvees


func _porte_du_donjon(portes: Array[Node]) -> SceneDoor:
	for n: Node in portes:
		var d: SceneDoor = n as SceneDoor
		if d != null and d.target_scene == VESTIBULE_SCENE:
			return d
	return null


func _decrire(portes: Array[Node]) -> String:
	var noms: Array[String] = []
	for n: Node in portes:
		noms.append("%s -> %s" % [n.name, (n as SceneDoor).target_scene])
	return ", ".join(noms) if not noms.is_empty() else "(aucune)"


## Appuie sur la touche d'interaction et rend la destination RÉELLEMENT
## demandée à `SceneFlow`. On n'exécute pas la transition — la charger
## remplacerait l'arbre sous les pieds du test — on observe la demande.
func _interagir_et_lire_la_destination(player: PlayerController,
		intent: InputIntent) -> String:
	var portes: Array[Node] = _portes_du_monde()
	var seuil: SceneDoor = _porte_du_donjon(portes)
	if seuil == null:
		return "(aucune porte au seuil)"
	# Le cône d'interaction suit le VISUEL du héros, qui suit sa marche
	# (`_select_interactable` lit `_visual_root.basis.z`). On ne triche donc
	# pas avec la caméra : on avance encore un peu vers la porte, et c'est la
	# marche elle-même qui l'oriente — comme pour un joueur.
	var vers2: Vector2 = Vector2(seuil.global_position.x, seuil.global_position.z)
	await _marcher_vers(player, intent, vers2, 1.6, 20.0)
	intent.move = Vector2.ZERO
	await _tree().physics_frame

	var demande: String = ""
	var flow: Node = _tree().root.get_node_or_null("SceneFlow")
	if flow != null and flow.has_signal("transition_started"):
		flow.connect("transition_started",
			func(p: String) -> void: demande = p)
	var avant: StringName = &""
	var gs: Node = _tree().root.get_node_or_null("GameState")

	for _i: int in range(12):
		intent.interact_pressed = true
		await _tree().physics_frame
		intent.interact_pressed = false
		await _tree().physics_frame
		if gs != null:
			avant = gs.call("consume_pending_spawn")
			if avant != &"":
				gs.call("set_pending_spawn", avant)
				break
	if demande == "" and avant != &"":
		# Le tag posé prouve que la porte a bien été actionnée par
		# l'interaction ; la destination est celle qu'elle porte.
		demande = seuil.target_scene
	return demande


func _camera_relative(player: PlayerController, monde: Vector3) -> Vector2:
	var yaw: Basis = player.camera_rig().get_yaw_basis()
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


func _marcher_vers(player: PlayerController, intent: InputIntent,
		but: Vector2, arrive: float = ARRIVE_M,
		budget: float = WALK_BUDGET_S) -> bool:
	var ecoule: float = 0.0
	var progres: float = INF
	var enlise: float = 0.0
	var pas_de_cote: float = 0.0
	var signe: float = 1.0
	while ecoule <= budget:
		var dt: float = _tree().root.get_physics_process_delta_time()
		var ici: Vector2 = Vector2(player.global_position.x, player.global_position.z)
		var reste: Vector2 = but - ici
		if reste.length() <= arrive:
			return true
		if reste.length() < progres - 0.05:
			progres = reste.length()
			enlise = 0.0
		else:
			enlise += dt
		var envie: Vector2 = reste.normalized()
		if pas_de_cote > 0.0:
			pas_de_cote -= dt
			envie = envie.rotated(_SIDESTEP_ANGLE * signe)
		elif enlise > _STALL_TRIGGER_S:
			pas_de_cote = _SIDESTEP_S
			signe = -signe
			enlise = 0.0
			intent.jump_pressed = true
		intent.move = _camera_relative(player, Vector3(envie.x, 0.0, envie.y))
		intent.sprint_held = true
		var avant: Vector3 = player.global_position
		await _tree().physics_frame
		intent.jump_pressed = false
		_teleports = maxf(_teleports, avant.distance_to(player.global_position))
		ecoule += dt
	return false
