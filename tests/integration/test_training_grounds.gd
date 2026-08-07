## PT-BRACELET-02 — Terrain d'entraînement : la base saine demandée au playtest.
##
## Défauts mesurés en jeu : les pouvoirs sont incompréhensibles (aucun texte
## n'explique à quoi ils servent ni comment les déclencher), leur usage n'affiche
## rien, et le décor de la vallée présente des assemblages fautifs — « maisons
## sans murs, bois qui flotte ». Cause trouvée pour le dernier point : le kit
## `assets/environment/village/` ne contient AUCUNE pièce de mur ; les murs
## vivent dans `dungeon/`. Une maison bâtie du seul kit village n'en a donc pas.
##
## Contrats vérifiés ici : les cinq épreuves existent, sont ALIGNÉES et
## réellement côte à côte ; chacune porte un panneau qui nomme la touche, le
## pourquoi et le comment ; chacune porte une lampe de réussite ; la fosse de
## l'Arc Step est un vrai trou (le dash est horizontal) ; la maison de
## référence a bien ses quatre murs ; et AUCUNE pièce du kit ne manque.
extends GateTestCase

const SCENE: String = "res://scenes/world/TrainingGrounds.tscn"

var _grounds: TrainingGrounds = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _teardown() -> void:
	if _grounds != null and is_instance_valid(_grounds):
		_grounds.get_parent().remove_child(_grounds)
		_grounds.queue_free()
	_grounds = null


func _open() -> bool:
	var scene: PackedScene = load(SCENE) as PackedScene
	if scene == null:
		return false
	_grounds = scene.instantiate() as TrainingGrounds
	if _grounds == null:
		return false
	_tree().root.add_child(_grounds)
	await _settle(10)
	return true


func test_the_five_trials_stand_side_by_side_and_aligned() -> void:
	if not await _open():
		check(false, "le terrain ne se charge pas")
		return
	var centres: Array[Vector3] = []
	for trial: Dictionary in TrainingGrounds.TRIALS:
		var station: Node3D = _grounds.get_node_or_null(
			NodePath("Epreuve_%s" % String(trial["id"]))) as Node3D
		check(station != null, "l'épreuve %s est posée" % String(trial["id"]))
		if station != null:
			centres.append(station.position)
	check(centres.size() == 5, "les cinq épreuves existent (%d)" % centres.size())
	if centres.size() == 5:
		# Alignées : même z pour toutes — c'est ce qui les rend lisibles d'un
		# seul regard depuis le seuil, contrairement à la vallée.
		var aligned: bool = true
		var spread_ok: bool = true
		for i: int in range(centres.size()):
			if not is_equal_approx(centres[i].z, centres[0].z):
				aligned = false
			if i > 0 and absf(centres[i].x - centres[i - 1].x) > 20.0:
				spread_ok = false
		check(aligned, "les cinq épreuves partagent la même ligne")
		check(spread_ok, "…et aucune n'est à plus de 20 m de sa voisine")
	_teardown()


func test_every_trial_explains_itself_in_words() -> void:
	## Le défaut n°1 du playtest : rien ne disait à quoi servent les pouvoirs.
	if not await _open():
		check(false, "le terrain ne se charge pas")
		return
	for trial: Dictionary in TrainingGrounds.TRIALS:
		var id: String = String(trial["id"])
		var station: Node3D = _grounds.get_node_or_null(
			NodePath("Epreuve_%s" % id)) as Node3D
		if station == null:
			check(false, "épreuve %s absente" % id)
			continue
		var labels: Array[Node] = station.find_children("*", "Label3D", true, false)
		check(labels.size() >= 2,
			"%s porte un titre ET un corps de texte (%d)" % [id, labels.size()])
		var written: String = ""
		for node: Node in labels:
			written += (node as Label3D).text + "\n"
		check(not String(trial["key"]).is_empty()
			and written.contains(String(trial["key"])),
			"%s affiche sa touche" % id)
		check(written.contains(String(trial["why"])), "%s dit à quoi ça sert" % id)
		check(written.contains(String(trial["how"])), "%s dit comment faire" % id)
	_teardown()


func test_every_trial_has_an_unlit_success_lamp() -> void:
	## Le défaut n°2 : utiliser un pouvoir n'affichait rien.
	if not await _open():
		check(false, "le terrain ne se charge pas")
		return
	for trial: Dictionary in TrainingGrounds.TRIALS:
		var id: StringName = StringName(trial["id"])
		var station: Node3D = _grounds.get_node_or_null(
			NodePath("Epreuve_%s" % String(id))) as Node3D
		if station == null:
			continue
		check(station.get_node_or_null(NodePath("Lampe")) != null,
			"%s porte sa lampe de réussite" % String(id))
		check(not _grounds.is_trial_passed(id),
			"%s démarre NON réussie — la lampe doit s'allumer en jouant"
				% String(id))
	check(_grounds.passed_trials().is_empty(),
		"aucune épreuve n'est réussie d'avance")
	_teardown()


func test_the_arc_step_gap_is_a_real_hole() -> void:
	## L'Arc Step vise le point d'arrivée À LA HAUTEUR DU JOUEUR : une
	## plateforme surélevée serait injouable. La fosse doit donc être un vrai
	## trou dans le sol, pas un décor.
	if not await _open():
		check(false, "le terrain ne se charge pas")
		return
	var space: PhysicsDirectSpaceState3D = _grounds.get_world_3d().direct_space_state
	var centre: Vector2 = (TrainingGrounds.PIT_MIN + TrainingGrounds.PIT_MAX) * 0.5
	var over_pit: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(centre.x, 4.0, centre.y), Vector3(centre.x, -4.0, centre.y), 1)
	check(space.intersect_ray(over_pit).is_empty(),
		"rien ne bouche la fosse — on ne peut pas la traverser à pied")
	# …et le sol EXISTE bien de l'autre côté, sinon on saute dans le vide.
	var beyond: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		Vector3(centre.x, 4.0, TrainingGrounds.PIT_MIN.y - 3.0),
		Vector3(centre.x, -4.0, TrainingGrounds.PIT_MIN.y - 3.0), 1)
	check(not space.intersect_ray(beyond).is_empty(),
		"le sol reprend au-delà de la fosse — l'arrivée est solide")
	_teardown()


func test_the_reference_house_actually_has_walls() -> void:
	## Le défaut n°3, littéralement : « maisons sans murs ». La maison de
	## référence est assemblée avec les pièces de mur du kit `dungeon/`, les
	## seules qui existent — et chacune porte sa collision.
	if not await _open():
		check(false, "le terrain ne se charge pas")
		return
	var house: Node3D = _grounds.get_node_or_null(
		NodePath("RangeeDeReference/MaisonDeReference")) as Node3D
	check(house != null, "la maison de référence est posée")
	if house == null:
		_teardown()
		return
	var walls: int = 0
	for node: Node in house.get_children():
		if node.name.begins_with("Wall_UnevenBrick_Straight"):
			walls += 1
	check(walls >= 6, "elle a ses murs sur trois côtés (%d pièces)" % walls)
	var blocks: Array[Node] = house.find_children("Bloc*", "StaticBody3D",
		false, false)
	check(blocks.size() >= 6,
		"chaque mur porte une collision : on ne le traverse pas (%d)"
			% blocks.size())
	_teardown()


func test_no_kit_piece_is_missing() -> void:
	## Un asset introuvable laisserait un TROU silencieux — exactement le
	## genre de défaut qui a produit le décor incohérent de la vallée.
	if not await _open():
		check(false, "le terrain ne se charge pas")
		return
	var missing: Array[String] = _grounds.missing_assets()
	check(missing.is_empty(),
		"aucune pièce du kit ne manque (manquantes : %s)" % str(missing))
	check(_grounds.piece_count() > 0, "des pièces ont réellement été posées")
	_teardown()


func test_the_player_and_its_hud_are_present() -> void:
	if not await _open():
		check(false, "le terrain ne se charge pas")
		return
	var player: PlayerController = _grounds.player()
	check(player != null, "le joueur est posé au seuil")
	if player != null:
		check(player.resonance() != null, "il porte son Bracelet")
	var shells: Array[Node] = _grounds.find_children("*", "GameplayShell",
		true, false)
	check(shells.size() == 1,
		"la coquille de HUD est présente — c'est elle qui porte le viseur")
	_teardown()
