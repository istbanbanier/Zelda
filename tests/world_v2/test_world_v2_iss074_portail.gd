## ISS-074 — LE PORTAIL DU PEUPLEMENT, ÉCRIT ROUGE D'ABORD.
##
## World V2 est un monde d'action-aventure sans UN SEUL adversaire. Ce
## fichier est la définition EXÉCUTABLE de « ISS-074 fermée », écrite avant
## toute ligne de production — comme le portail ISS-073 l'a été pour la
## boucle. Il est ROUGE aujourd'hui, sur cette branche, VOLONTAIREMENT :
## la suite de `claude/world-v2-iss074-population-contract` porte ce rouge
## assumé tant que la garnison n'existe pas. La candidate de lundi n'en
## porte aucun — cette branche n'y est pas fusionnée.
##
## Ce que « fermée » veut dire, et que ce portail exige :
##	 1. un adversaire du groupe `enemies` EXISTE dans le monde monté ;
##	 2. il est ATTEIGNABLE : la navigation rend un chemin non vide du spawn
##		jusqu'à moins de 4 m de lui — un ennemi posé hors navmesh est un
##		décor, pas un adversaire ;
##	 3. un `CombatCoordinator` gouverne le monde — sans lui, les tokens
##		sont accordés d'office et §12.8 meurt en silence ;
##	 4. chaque ennemi posé a un territoire borné (`max_pursuit_distance`
##		> 0 via son tuning) — aucun poursuivant infini.
##
## Le contrat qu'il REMPLACERA le jour du vert —
## `test_world_v2_places_contract.gd::test_aucun_acteur_et_les_routes_restent_libres`
## — reste en vigueur sur la candidate ; le remplacement (un BUDGET, pas une
## interdiction) est écrit dans docs/contrats/iss074_peuplement_world_v2.md §3.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const PORTEE_ATTEIGNABLE_M: float = 4.0

var _world: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func test_un_adversaire_atteignable_existe_dans_world_v2() -> void:
	remember_saves()
	remember_root()
	var gs: Node = _tree().root.get_node_or_null("GameState")
	if gs != null:
		gs.call("consume_pending_spawn")
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_world)
	await _tree().process_frame
	await _tree().physics_frame
	# La carte de navigation se synchronise après le premier tick physique.
	await _tree().physics_frame

	# --- 1. Un adversaire existe.
	var ennemis: Array[Node] = _tree().get_nodes_in_group(&"enemies")
	check(not ennemis.is_empty(),
		"au moins un adversaire vit dans World V2 — aujourd'hui le monde "
		+ "n'en porte AUCUN (ISS-074), et ce rouge est la définition "
		+ "exécutable du travail à faire")

	# --- 2. Il gouverne par un coordinateur.
	var coordinateurs: Array[Node] = _tree().get_nodes_in_group(
		&"combat_coordinator")
	check_equal(coordinateurs.size(), 1,
		"exactement un CombatCoordinator gouverne le monde — sans lui les "
		+ "tokens sont accordés d'office (§12.8)")

	# --- 3. Le plus proche est ATTEIGNABLE depuis le spawn.
	if not ennemis.is_empty():
		var spawn: Vector3 = _world.call("spawn_position") as Vector3
		var carte: RID = (_world as Node3D).get_world_3d().navigation_map
		var atteignable: bool = false
		var meilleur: float = INF
		for ennemi: Node in ennemis:
			var cible: Vector3 = (ennemi as Node3D).global_position
			var chemin: PackedVector3Array = NavigationServer3D.map_get_path(
				carte, spawn, cible, true)
			if chemin.size() < 2:
				continue
			var bout: float = chemin[chemin.size() - 1].distance_to(cible)
			meilleur = minf(meilleur, bout)
			if bout <= PORTEE_ATTEIGNABLE_M:
				atteignable = true
				break
		check(atteignable,
			"un adversaire est atteignable par la navigation (meilleur "
			+ "écart chemin→ennemi : %s m, exigé ≤ %.1f)"
				% [("%.1f" % meilleur) if meilleur < INF else "aucun chemin",
					PORTEE_ATTEIGNABLE_M])

	# --- 4. Territoire borné pour chacun.
	var infinis: Array[String] = []
	for ennemi: Node in ennemis:
		var tuning: Variant = ennemi.get("tuning")
		if tuning == null or float(tuning.get("max_pursuit_distance")) <= 0.0:
			infinis.append(String(ennemi.name))
	check(infinis.is_empty(),
		"chaque adversaire a un territoire borné — poursuivants infinis : %s"
			% ", ".join(infinis))

	_world = null
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())
	restore_saves()
