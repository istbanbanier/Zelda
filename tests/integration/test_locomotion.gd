## Locomotion du joueur (MASTER_SPEC §8.2) — mesurée, pas supposée.
##
## Ces tests pilotent le contrôleur par `InputIntent` injectée : **aucune touche
## n'est simulée**, aucun périphérique n'est requis. C'est le bénéfice direct de
## D-013 — la locomotion est vérifiable en headless, et le sera à l'identique
## quand la manette entrera en jeu.
##
## Ce qu'ils ne prouvent PAS : le ressenti. §10.6 exige des mesures de latence et
## un essai humain ; ils viendront avec le Gate B et n'ont pas d'équivalent
## automatique.
extends GateTestCase

const SANDBOX: String = "res://scenes/tests/TraversalSandbox.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"

## 60 ticks = 1 s à 60 Hz.
const TICK: float = 1.0 / 60.0

var _world: Node = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Monte le bac à sable et y place le joueur à `spawn`, puis laisse la physique
## le poser au sol.
func _setup(spawn: Vector3) -> bool:
	var tree: SceneTree = _tree()
	if tree == null:
		check(false, "SceneTree indisponible")
		return false

	var world_scene: PackedScene = load(SANDBOX) as PackedScene
	var player_scene: PackedScene = load(PLAYER) as PackedScene
	if world_scene == null or player_scene == null:
		check(false, "scènes de test introuvables")
		return false

	_world = world_scene.instantiate()
	tree.root.add_child(_world)

	_player = player_scene.instantiate() as PlayerController
	_world.add_child(_player)
	_player.global_position = spawn

	_intent = InputIntent.new()
	_player.set_intent_source(_intent)

	await _settle(30)
	return true


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	_intent = null


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func test_player_falls_and_rests_on_the_floor() -> void:
	if not await _setup(Vector3(0, 3, 0)):
		return
	await _settle(120)
	check(_player.is_on_floor(), "le joueur doit reposer sur le sol")
	check_approx(_player.global_position.y, 0.0, 0.1, "altitude au repos (pieds au sol)")
	check(absf(_player.velocity.y) < 0.5, "vitesse verticale au repos")
	_teardown()


func test_run_speed_matches_tuning() -> void:
	## Le clavier produit toujours une amplitude de 1.0 : il court.
	if not await _setup(Vector3(0, 1, 0)):
		return
	_intent.move = Vector2(1.0, 0.0)
	await _settle(90)
	check_approx(_player.horizontal_speed(), _player.tuning.run_speed, 0.3,
		"vitesse de course atteinte")
	_teardown()


func test_partial_stick_walks_instead_of_running() -> void:
	## Nuance que seule la manette apporte. Le contrôleur n'a aucune branche par
	## périphérique : c'est l'amplitude qui décide (D-013).
	if not await _setup(Vector3(0, 1, 0)):
		return
	_intent.move = Vector2(0.4, 0.0)
	await _settle(90)
	check_approx(_player.horizontal_speed(), _player.tuning.walk_speed, 0.3,
		"faible inclinaison -> marche")
	_teardown()


func test_sprint_is_faster_than_running() -> void:
	if not await _setup(Vector3(0, 1, 0)):
		return
	_intent.move = Vector2(1.0, 0.0)
	_intent.sprint_held = true
	await _settle(120)
	check_approx(_player.horizontal_speed(), _player.tuning.sprint_speed, 0.4,
		"vitesse de sprint atteinte")
	check(_player.tuning.sprint_speed > _player.tuning.run_speed,
		"le sprint doit dépasser la course")
	_teardown()


func test_release_decelerates_to_a_stop() -> void:
	## §10.6 : « relâcher le stick réduit rapidement la vitesse sans arrêt
	## robotique ». On vérifie l'arrêt ; le caractère non robotique est un ressenti.
	if not await _setup(Vector3(0, 1, 0)):
		return
	_intent.move = Vector2(1.0, 0.0)
	await _settle(90)
	check(_player.horizontal_speed() > 4.0, "le joueur doit d'abord se déplacer")

	_intent.move = Vector2.ZERO
	await _settle(45)
	check(_player.horizontal_speed() < 0.2,
		"vitesse résiduelle après relâchement : %.3f m/s" % _player.horizontal_speed())
	_teardown()


func test_movement_is_camera_relative() -> void:
	## §8.2 : « avant » désigne l'écran, pas l'axe -Z du monde. On fait pivoter la
	## caméra d'un quart de tour et la même intention doit produire un déplacement
	## dans une direction du monde différente.
	if not await _setup(Vector3(0, 1, 0)):
		return
	var rig: CameraRig = _player.get_node("CameraRig") as CameraRig
	check_not_null(rig, "CameraRig")
	if rig == null:
		_teardown()
		return

	_intent.move = Vector2(1.0, 0.0)
	await _settle(60)
	var start: Vector3 = _player.global_position
	await _settle(30)
	var dir_default: Vector3 = (_player.global_position - start).normalized()

	# Quart de tour de la caméra vers la gauche.
	rig.apply_look(Vector2(PI / 2.0 / (rig.tuning.camera_stick_speed * TICK), 0.0), Vector2.ZERO, TICK)
	await _settle(60)
	var start2: Vector3 = _player.global_position
	await _settle(30)
	var dir_rotated: Vector3 = (_player.global_position - start2).normalized()

	var angle: float = rad_to_deg(dir_default.angle_to(dir_rotated))
	check(angle > 60.0,
		"la direction doit suivre la caméra : écart mesuré %.1f° (attendu ~90°)" % angle)
	_teardown()


func test_jump_reaches_expected_apex() -> void:
	## §8.2 : 8,2 m/s sous 24 m/s² -> apex d'environ 1,40 m.
	if not await _setup(Vector3(0, 1, 0)):
		return
	var ground: float = _player.global_position.y
	_intent.jump_pressed = true

	var apex: float = ground
	for i: int in range(90):
		await _tree().physics_frame
		apex = maxf(apex, _player.global_position.y)
	var height: float = apex - ground
	check_approx(height, 1.4, 0.2, "hauteur de saut (m)")
	_teardown()


func test_coyote_time_allows_a_late_jump() -> void:
	## §8.2 : saut encore accepté 0,12 s après avoir quitté le sol.
	if not await _setup(Vector3(0, 1.0, 20)):
		return
	# Marcher hors de la marche pour quitter le sol sans sauter.
	_intent.move = Vector2(1.0, 0.0)
	var left_ground: bool = false
	for i: int in range(120):
		await _tree().physics_frame
		if not _player.is_on_floor():
			left_ground = true
			break
	check(left_ground, "le joueur doit avoir quitté le sol")
	if not left_ground:
		_teardown()
		return

	# Deux ticks après la perte de contact : dans la fenêtre de coyote.
	await _settle(2)
	_intent.move = Vector2.ZERO
	_intent.jump_pressed = true
	await _settle(2)
	check(_player.velocity.y > 3.0,
		"le saut doit être accepté pendant le coyote time (vy = %.2f)" % _player.velocity.y)
	_teardown()


func test_jump_buffer_survives_an_early_press() -> void:
	## §8.2 : saut demandé avant l'atterrissage, honoré à la reprise de contact.
	if not await _setup(Vector3(0, 1, 0)):
		return
	# Sauter une première fois pour être en l'air.
	_intent.jump_pressed = true
	await _settle(20)
	check(not _player.is_on_floor(), "le joueur doit être en l'air")

	# Demander le second saut pendant la descente, dans la fenêtre de buffer.
	var landed_once: bool = false
	for i: int in range(180):
		await _tree().physics_frame
		if not landed_once and _player.velocity.y < 0.0 and _player.global_position.y < 0.4:
			_intent.jump_pressed = true
			landed_once = true
		if landed_once and _player.velocity.y > 3.0:
			break
	check(landed_once, "la fenêtre de demande anticipée doit être atteinte")
	check(_player.velocity.y > 3.0,
		"le saut bufferisé doit partir à l'atterrissage (vy = %.2f)" % _player.velocity.y)
	_teardown()


func test_gentle_slope_is_climbable() -> void:
	## Pente à 40°, sous le seuil de 46° de §8.2. Le prisme monte de 4,20 m puis
	## débouche sur un plateau : après deux secondes le joueur doit s'y tenir.
	if not await _setup(Vector3(-20, 1.5, 4.5)):
		return
	await _settle(60)
	var start_y: float = _player.global_position.y
	# move.y = +1 signifie « avant », soit -Z avec la caméra au repos : c'est bien
	# la direction du pied de la rampe, situé à z = 3.
	_intent.move = Vector2(0.0, 1.0)
	await _settle(120)
	check(_player.global_position.y > start_y + 3.0,
		"une pente à 40° doit être gravie : Y %.2f -> %.2f" % [start_y, _player.global_position.y])
	check(_player.is_on_floor(),
		"le joueur doit se tenir sur le plateau, pas flotter ni retomber")
	_teardown()


func test_steep_slope_is_rejected() -> void:
	## Contre-épreuve du test précédent : sans elle, un contrôleur qui gravirait
	## n'importe quelle paroi passerait pour conforme. 60° dépasse le seuil de 46°
	## de §8.2 — la surface doit compter comme un mur, pas comme un sol.
	if not await _setup(Vector3(-30, 1.5, 4.5)):
		return
	await _settle(60)
	var start_y: float = _player.global_position.y
	_intent.move = Vector2(0.0, 1.0)
	await _settle(120)
	check(_player.global_position.y < start_y + 0.6,
		"une pente à 60° ne doit pas être gravie : Y %.2f -> %.2f"
		% [start_y, _player.global_position.y])
	check(_player.horizontal_speed() < 1.0,
		"le joueur doit être arrêté par la pente (%.2f m/s)" % _player.horizontal_speed())
	_teardown()


func test_sprint_drains_stamina() -> void:
	## §9.1 : 12/s. Ici la mesure passe par le contrôleur réel, pas par le composant
	## isolé : c'est le câblage qu'on vérifie, pas l'arithmétique.
	if not await _setup(Vector3(0, 1, 0)):
		return
	var stamina: StaminaComponent = _player.stamina()
	check_not_null(stamina, "StaminaComponent")
	if stamina == null:
		_teardown()
		return
	var before: float = stamina.current()
	_intent.move = Vector2(1.0, 0.0)
	_intent.sprint_held = true
	await _settle(60)
	var spent: float = before - stamina.current()
	check_approx(spent, stamina.tuning.sprint_drain, 1.5,
		"endurance consommée par 1 s de sprint")
	_teardown()


func test_running_without_sprinting_costs_nothing() -> void:
	## Seul le sprint consomme en B.2 ; la course est gratuite (§9.1).
	if not await _setup(Vector3(0, 1, 0)):
		return
	var stamina: StaminaComponent = _player.stamina()
	var before: float = stamina.current()
	_intent.move = Vector2(1.0, 0.0)
	await _settle(60)
	check_approx(stamina.current(), before, 0.001, "endurance après 1 s de course")
	_teardown()


func test_holding_sprint_while_standing_still_costs_nothing() -> void:
	## Le sprint est un état de locomotion, pas une posture : maintenir la touche à
	## l'arrêt ne doit rien coûter, sinon le joueur se vide sans avancer.
	if not await _setup(Vector3(0, 1, 0)):
		return
	var stamina: StaminaComponent = _player.stamina()
	var before: float = stamina.current()
	_intent.sprint_held = true
	await _settle(60)
	check_approx(stamina.current(), before, 0.001,
		"endurance après 1 s de sprint immobile")
	_teardown()


func test_exhaustion_drops_the_sprint_back_to_running() -> void:
	## §9.1 : « à zéro : sprint → course ». C'est le comportement observable qui
	## compte, pas la valeur de la jauge — on mesure donc la **vitesse**.
	if not await _setup(Vector3(0, 1, 0)):
		return
	var stamina: StaminaComponent = _player.stamina()
	# Réserve amorcée basse plutôt que vidée par un sprint complet : à 12/s il
	# faudrait 8,3 s, soit près de 75 m à la vitesse de sprint — le joueur
	# quitterait le sol du bac à sable et la mesure porterait sur une chute.
	# Ce qu'on vérifie ici est la bascule, pas la durée qu'il faut pour l'atteindre
	# (celle-ci est mesurée dans `test_stamina.gd`).
	stamina.set_current(6.0)
	_intent.move = Vector2(1.0, 0.0)
	_intent.sprint_held = true

	await _settle(90)
	check(stamina.is_exhausted(),
		"préalable : la réserve doit être vidée (%.1f)" % stamina.current())
	check_approx(_player.horizontal_speed(), _player.tuning.run_speed, 0.3,
		"vitesse une fois épuisé — le sprint doit être retombé en course")
	check(_player.tuning.run_speed < _player.tuning.sprint_speed,
		"préalable de lecture : la course est bien plus lente que le sprint")
	_teardown()


func test_stamina_recovers_after_releasing_sprint() -> void:
	if not await _setup(Vector3(0, 1, 0)):
		return
	var stamina: StaminaComponent = _player.stamina()
	_intent.move = Vector2(1.0, 0.0)
	_intent.sprint_held = true
	await _settle(120)
	var low: float = stamina.current()
	check(low < stamina.maximum(), "préalable : la réserve doit avoir baissé")

	_intent.sprint_held = false
	_intent.move = Vector2.ZERO
	await _settle(180)
	check(stamina.current() > low,
		"la réserve doit remonter au repos (%.1f -> %.1f)" % [low, stamina.current()])
	_teardown()


func test_a_low_step_is_climbed_by_walking() -> void:
	## §8.2 : marche de 0,30–0,38 m franchie sans saut.
	##
	## Mesuré avant d'implémenter quoi que ce soit : `move_and_slide()` n'en monte
	## **aucune**. Une marche de 0,32 m arrêtait le personnage net — `is_on_wall()`
	## vrai, position figée pendant trois secondes, aucune erreur. Le franchissement
	## est un shape cast explicite, pas un effet de bord du moteur.
	##
	## HISTORIQUE : le déclencheur a changé deux fois, et la mesure qui avait
	## écarté `is_on_wall()` était un artefact — le joueur avait saisi le mur
	## (mode escalade, aucun contact), voir D-020 amendée. Le déclencheur actuel
	## écoute les collisions de glissement ; le cas diagonal, plus bas, est le
	## test qui départage réellement les variantes.
	if not await _setup(Vector3(0, 1.0, 14)):
		return
	var heights: Array[float] = []
	_player.stepped_up.connect(func(h: float) -> void: heights.append(h))

	# La marche du bac à sable occupe z de 16 à 24, dessus à y = 0,32. On l'aborde
	# donc vers +Z, soit `move.y = -1`.
	_intent.move = Vector2(0.0, -1.0)
	await _settle(90)

	check(heights.size() >= 1, "le franchissement de marche doit être signalé")
	check_approx(_player.global_position.y, 0.32, 0.05,
		"le joueur doit se tenir sur la marche")
	check(_player.global_position.z > 16.0,
		"le joueur doit avoir dépassé le bord de la marche (z = %.2f)"
		% _player.global_position.z)
	check(_player.is_on_floor(), "le joueur doit reposer sur la marche")
	_teardown()


func test_a_tall_wall_is_not_treated_as_a_step() -> void:
	## Contre-épreuve : sans elle, un franchissement trop permissif escaladerait
	## n'importe quel mur en marchant, et l'escalade de §9.2 n'aurait plus d'objet.
	##
	## CE QUE CE TEST NE DISCRIMINE PAS, mesuré et non supposé : aucune mutation de
	## `_try_step_up()` ne le fait rougir (contrôle négatif Q3). Deux couches l'en
	## empêchent, mesurées l'une après l'autre :
	##   1. en poussant vers ce mur — saisissable — le joueur l'AGRIPPE (§9.2) et
	##      passe en escalade avant tout contact : plus aucune collision de
	##      glissement, donc plus aucun déclencheur de marche ;
	##   2. même sans la saisie, la sonde descendante de `_try_step_up()` ne trouve
	##      aucun sol devant un mur plein et refuse avant ses autres contrôles.
	## Défense en profondeur réelle — mais ce test valide un comportement
	## observable, pas une ligne de code en particulier.
	if not await _setup(Vector3(26, 1.0, 0)):
		return
	var heights: Array[float] = []
	_player.stepped_up.connect(func(h: float) -> void: heights.append(h))

	# Le mur du bac à sable est en x = 30, haut de 6 m.
	_intent.move = Vector2(1.0, 0.0)
	await _settle(120)

	check_equal(heights.size(), 0, "un mur de 6 m ne doit jamais être franchi en marchant")
	check(_player.global_position.y < 0.4,
		"le joueur doit rester au sol (y = %.2f)" % _player.global_position.y)
	_teardown()


func test_a_step_under_a_low_ceiling_is_refused() -> void:
	## Premier des trois refus de `_try_step_up()` : se hisser exige d'abord la
	## place de le faire. Sous un plafond à 1,90 m, la capsule tient debout mais pas
	## surélevée d'une hauteur de marche — le franchissement doit être refusé plutôt
	## que d'encastrer le personnage.
	if not await _setup(Vector3(-36, 1.0, -28.0)):
		return
	var heights: Array[float] = []
	_player.stepped_up.connect(func(h: float) -> void: heights.append(h))

	_intent.move = Vector2(0.0, 1.0)
	await _settle(120)

	check_equal(heights.size(), 0,
		"aucun franchissement ne doit avoir lieu sous un plafond trop bas")
	check(_player.global_position.y < 0.2,
		"le joueur doit rester en contrebas (y = %.2f)" % _player.global_position.y)
	# Anti-softlock : bloqué n'est pas encastré.
	check(_player.global_position.z > -30.0,
		"le joueur ne doit pas s'être enfoncé dans la géométrie (z = %.2f)"
		% _player.global_position.z)
	_teardown()


func test_step_height_stays_within_the_spec_envelope() -> void:
	## §8.2 : « Step height 0,30–0,38 m ».
	var tuning: LocomotionTuning = load("res://resources/tuning/locomotion_default.tres")
	check_not_null(tuning, "locomotion_default.tres")
	if tuning == null:
		return
	check(tuning.step_height >= 0.30 and tuning.step_height <= 0.38,
		"hauteur de marche hors §8.2 (0,30–0,38 m) : %.2f" % tuning.step_height)
	# La sonde avant doit dépasser le rayon de la capsule (0,35 m), sinon elle
	# retombe sur la face verticale que l'on cherche à franchir.
	check(tuning.step_forward_probe > 0.35,
		"sonde avant trop courte (%.2f m) : elle heurterait la face de la marche"
		% tuning.step_forward_probe)


func test_locomotion_tuning_matches_the_spec() -> void:
	## §8.2 épinglé valeur par valeur, comme `test_declared_values_match_the_spec`
	## le fait pour l'endurance. Ajouté sur constat de la revue contradictoire du
	## Gate B : les tests de vitesse comparaient la mesure à `tuning.*` — une
	## dérive du `.tres` (course à 12 m/s, coyote à 5 s) laissait TOUTE la suite
	## verte. Comparaison circulaire ; celle-ci ne l'est pas.
	var t: LocomotionTuning = load("res://resources/tuning/locomotion_default.tres")
	check_not_null(t, "locomotion_default.tres")
	if t == null:
		return
	check_approx(t.walk_speed, 3.5, 0.001, "marche (§8.2)")
	check_approx(t.run_speed, 6.0, 0.001, "course (§8.2)")
	check_approx(t.sprint_speed, 9.0, 0.001, "sprint (§8.2)")
	check_approx(t.ground_acceleration, 24.0, 0.001, "accélération sol (§8.2)")
	check_approx(t.ground_deceleration, 30.0, 0.001, "décélération (§8.2)")
	check_approx(t.air_acceleration, 8.4, 0.001, "accélération air (§8.2)")
	check_approx(t.air_control, 0.35, 0.001, "contrôle aérien (§8.2)")
	check_approx(t.gravity, 24.0, 0.001, "gravité (§8.2)")
	check_approx(t.jump_velocity, 8.2, 0.001, "vitesse de saut (§8.2)")
	check_approx(t.coyote_time, 0.12, 0.001, "coyote time (§8.2)")
	check_approx(t.jump_buffer, 0.12, 0.001, "jump buffer (§8.2)")
	check_approx(t.max_floor_angle_deg, 46.0, 0.001, "pente praticable (§8.2)")


func test_a_jump_after_the_coyote_window_is_refused() -> void:
	## La moitié manquante du coyote time, exigée par la revue du Gate B : la
	## fenêtre doit aussi SE FERMER. Sans ce test, `coyote_time = 5.0` dans le
	## `.tres` laissait la suite verte — un saut accepté n'importe quand en l'air
	## passait pour un coyote time conforme.
	##
	## Le plateau de la rampe douce (dessus y ≈ 4,10, x ∈ [−23 ; −17]) fournit la
	## chute longue qu'une marche de 0,32 m ne donne pas : ~0,59 s, assez pour
	## laisser expirer 0,12 s de fenêtre avant d'appuyer.
	if not await _setup(Vector3(-20, 4.4, -10)):
		return
	await _settle(30)
	check(_player.is_on_floor(), "préalable : le joueur doit être posé sur le plateau")

	_intent.move = Vector2(1.0, 0.0)
	var left: bool = false
	for i: int in range(180):
		await _tree().physics_frame
		if not _player.is_on_floor():
			left = true
			break
	check(left, "le joueur doit avoir quitté le plateau")
	if not left:
		_teardown()
		return

	_intent.move = Vector2.ZERO
	# 15 ticks = 0,25 s : la fenêtre de 0,12 s est expirée, la chute continue.
	await _settle(15)
	check(not _player.is_on_floor(), "préalable : encore en l'air au moment de l'appui")
	_intent.jump_pressed = true
	await _settle(2)
	check(_player.velocity.y < 1.0,
		"un saut demandé après la fenêtre de coyote doit être refusé (vy = %.2f)"
		% _player.velocity.y)
	_teardown()


func test_a_buffered_jump_expires_before_landing() -> void:
	## La moitié manquante du jump buffer : un appui trop tôt avant l'atterrissage
	## doit être OUBLIÉ, pas conservé indéfiniment. Sans ce test,
	## `jump_buffer = 5.0` laissait la suite verte. Même chute que ci-dessus :
	## appui à ~0,25 s après le départ, atterrissage à ~0,59 s — le tampon de
	## 0,12 s expire largement avant le contact.
	if not await _setup(Vector3(-20, 4.4, -10)):
		return
	await _settle(30)
	_intent.move = Vector2(1.0, 0.0)
	var left: bool = false
	for i: int in range(180):
		await _tree().physics_frame
		if not _player.is_on_floor():
			left = true
			break
	check(left, "le joueur doit avoir quitté le plateau")
	if not left:
		_teardown()
		return

	_intent.move = Vector2.ZERO
	await _settle(15)   # coyote expiré : l'appui ne peut pas partir immédiatement
	_intent.jump_pressed = true

	var landed: bool = false
	for i: int in range(180):
		await _tree().physics_frame
		if _player.is_on_floor():
			landed = true
			break
	check(landed, "le joueur doit finir par atterrir")
	await _settle(3)
	check(_player.is_on_floor(),
		"aucun rebond : le tampon expiré ne doit pas déclencher de saut à l'atterrissage")
	check(_player.velocity.y < 1.0,
		"vitesse verticale au sol après l'atterrissage (vy = %.2f)" % _player.velocity.y)
	_teardown()


func test_a_step_is_climbed_when_approached_diagonally() -> void:
	## Contre-exemple démontré par la revue du Gate B : poussée à 45° contre la
	## marche, le joueur GLISSAIT le long de la face sans jamais la franchir. Le
	## déclencheur comparait la distance parcourue à la distance demandée — or le
	## glissement diagonal en conserve ~71 %, au-dessus du seuil. Le déclencheur
	## écoute désormais la collision de glissement rapportée par move_and_slide()
	## — mesurée présente dans ce cas précis, normale (0 ; 0,12 ; −0,99) — quand
	## le joueur pousse dedans.
	if not await _setup(Vector3(-2, 1.0, 14)):
		return
	var heights: Array[float] = []
	_player.stepped_up.connect(func(h: float) -> void: heights.append(h))

	# Diagonale +X/+Z : `move.y = -1` pousse vers +Z (la face de la marche),
	# `move.x = 1` la longe vers +X. Normalisée comme le ferait un stick.
	# On relâche dès le franchissement : la marche ne fait que 8 m de côté, et la
	# poussée diagonale maintenue en ressortirait par le flanc est — la mesure
	# porterait alors sur une chute, pas sur le franchissement.
	_intent.move = Vector2(0.7071, -0.7071)
	for i: int in range(120):
		await _tree().physics_frame
		if heights.size() >= 1:
			break
	_intent.move = Vector2.ZERO
	await _settle(15)

	check(heights.size() >= 1,
		"la marche doit être franchie même abordée à 45° (glissement : %d franchissement(s))"
		% heights.size())
	check_approx(_player.global_position.y, 0.32, 0.06,
		"le joueur doit se tenir sur la marche")
	check(_player.is_on_floor(), "le joueur doit reposer sur la marche")
	_teardown()


func test_body_never_rotates() -> void:
	## Le `CameraRig` est enfant du corps : si le corps tournait, la caméra
	## tournerait avec le personnage et deviendrait incontrôlable.
	if not await _setup(Vector3(0, 1, 0)):
		return
	_intent.move = Vector2(1.0, 1.0)
	await _settle(60)
	check_approx(_player.rotation.y, 0.0, 0.001, "lacet du corps")
	check_approx(_player.rotation.x, 0.0, 0.001, "tangage du corps")

	var visual: Node3D = _player.get_node("VisualRoot") as Node3D
	check_not_null(visual, "VisualRoot")
	if visual != null:
		check(absf(visual.rotation.y) > 0.01,
			"la représentation visuelle, elle, doit s'orienter vers le déplacement")
	_teardown()
