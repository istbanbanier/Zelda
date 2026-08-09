## PARCOURS PHYSIQUE — le héros MARCHE, et ne triche pas.
##
## Exigé par l'audit indépendant du 2026-08-09. `test_flow_wiring_path.gd`
## prouve que les fils sont branchés ; celui-ci prouve qu'un joueur peut s'en
## servir. Les deux sont nécessaires et ne se remplacent pas.
##
## CE QUE CE FICHIER S'INTERDIT, et qui rendrait sa preuve fausse :
##   - écrire `global_position` pour avancer ;
##   - appeler `Chest.interact()`, `SceneDoor.interact()`, `take_damage()` ou
##     `try_pulse()` — c'est-à-dire appeler la méthode finale de la cible ;
##   - retirer un ennemi de la route pour la dégager.
##
## Tout passe par `InputIntent` et le `PlayerController` : `move` pour marcher,
## `interact_pressed` pour ouvrir, `attack_pressed` pour frapper,
## `pulse_pressed` pour la Résonance. C'est la même porte d'entrée qu'un clavier
## ou une manette (D-013) : le gameplay ne peut pas savoir que c'est un test.
##
## Les JALONS DE ROUTE sont autorisés — un joueur choisit son chemin, un pilote
## a besoin qu'on le lui donne. Ils viennent de deux tests qui les ont déjà
## éprouvés séparément : `test_valley_world.gd` pour la descente de crête
## (ISS-032) et `test_bestiary_gate.gd` pour la route du donjon. Ce parcours-ci
## est le premier à les ENCHAÎNER, sans la téléportation qui séparait les deux
## moitiés — c'est précisément le trou que l'audit a nommé.
##
## Toutes les bornes sont en TEMPS DE JEU (ISS-038). Une borne épuisée fait
## ÉCHOUER, elle ne fait jamais pendre.
extends GateTestCase

const BOOT: String = "res://scenes/boot/Boot.tscn"
const BELOW_WORLD: float = -5.0

## Descente de la crête vers la plaine nord. Éprouvés par
## `test_valley_world.gd::test_the_route_from_ridge_to_north_plain_is_walkable`.
const ROUTE_RIDGE: Array[Vector2] = [
	Vector2(14, 152), Vector2(26, 134), Vector2(36, 112), Vector2(27, 94),
	Vector2(18, 79), Vector2(28, 70), Vector2(40, 60), Vector2(40, 38),
	Vector2(36, 22), Vector2(20, 10), Vector2(12, -8),
]

## Plaine nord vers le seuil de la citadelle. Éprouvés par
## `test_bestiary_gate.gd::test_the_north_road_to_the_citadel_stays_walkable…`,
## qui y TÉLÉPORTAIT le joueur. Ici on y arrive à pied.
const ROUTE_CITADEL: Array[Vector2] = [
	Vector2(20, -34), Vector2(20, -72), Vector2(4, -100),
	Vector2(0, -132), Vector2(0, -162),
]

## Portée d'interaction du contrôleur : 2,2 m. On s'arrête franchement dedans,
## sans coller à l'objet — un joueur ne s'arrête jamais au millimètre.
const INTERACT_STOP: float = 1.8
const ATTACK_STOP: float = 1.5
const PULSE_STOP: float = 6.0
## Au-delà, un déplacement en un seul tick physique n'est plus de la locomotion :
## c'est un secours, un respawn ou une téléportation. Marge large et assumée.
const DISCONTINUITY_M: float = 3.0


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _wait_until(probe: Callable, budget_s: float = 20.0) -> bool:
	var elapsed: float = 0.0
	while elapsed <= budget_s:
		if bool(probe.call()):
			return true
		await _tree().process_frame
		elapsed += _tree().root.get_process_delta_time()
	return false


func _find(wanted: String) -> Node:
	var by_class: Array[Node] = _tree().root.find_children("*", wanted, true, false)
	if not by_class.is_empty():
		return by_class[0]
	var by_name: Array[Node] = _tree().root.find_children(wanted, "", true, false)
	return by_name[0] if not by_name.is_empty() else null


## Convertit une direction MONDE en `InputIntent.move`, repère caméra.
##
## §8.2 : le déplacement est relatif à la caméra. Projeter dans le repère du
## lacet n'est pas une précaution de style — sans elle, le pilote marche à
## l'envers (mesuré ailleurs : 0 jalon, 217 m d'écart).
func _camera_relative(player: PlayerController, world_dir: Vector3) -> Vector2:
	var yaw: Basis = player.camera_rig().get_yaw_basis()
	var forward: Vector3 = -yaw.z
	var right: Vector3 = yaw.x
	forward.y = 0.0
	right.y = 0.0
	var wish: Vector3 = world_dir
	wish.y = 0.0
	if wish.length_squared() < 0.000001:
		return Vector2.ZERO
	wish = wish.normalized()
	return Vector2(wish.dot(right.normalized()),
		wish.dot(forward.normalized())).normalized()


## Dernier compte rendu de marche — pour que l'échec DISE où le héros est resté,
## et non seulement qu'il n'est pas arrivé. Un « 4/11 jalons » sans coordonnée
## envoie chercher la panne au mauvais endroit.
var _walk_report: String = ""

## ---------------------------------------------------------------------------
## « JAMAIS SOUS LE MONDE » DOIT ÊTRE MESURÉ, PAS AFFIRMÉ
## ---------------------------------------------------------------------------
##
## La première version relevait `player.global_position.y` UNE FOIS par jalon —
## donc onze échantillons pour plus de cent mètres. Un héros qui traverse le sol
## et qu'un filet de sécurité remonte entre deux jalons passait inaperçu, et le
## test affirmait « jamais » sur la foi de onze photos. Une affirmation « jamais »
## qui n'est pas échantillonnée à chaque frame n'a pas le droit d'être écrite
## (audit du 2026-08-09, deuxième passe).
##
## On relève donc à CHAQUE tick physique, sur toute la durée du parcours, et on
## garde aussi le plus grand saut de position d'une frame à l'autre : un secours
## ou un respawn déplace le héros de plusieurs mètres en un tick, ce qu'aucune
## locomotion légitime ne fait (sprint 9 m/s → 0,15 m ; Arc Step 18 m/s → 0,30 m).
var _lowest_y: float = INF
var _frames_sampled: int = 0
var _max_jump: float = 0.0
var _jump_at: Vector3 = Vector3.ZERO


## Un échantillon de sécurité, appelé à chaque tick de marche.
func _sample_safety(player: PlayerController, previous: Vector3) -> void:
	var here: Vector3 = player.global_position
	_lowest_y = minf(_lowest_y, here.y)
	_frames_sampled += 1
	var jump: float = previous.distance_to(here)
	if jump > _max_jump:
		_max_jump = jump
		_jump_at = here


## Marche jusqu'à `goal` (XZ) et rend vrai si le héros y arrive dans le budget.
## Aucune écriture de position : on ne fait que pousser une direction.
## Un joueur bloqué CONTOURNE. Un pilote qui pousse tout droit contre un rocher
## est un plus mauvais joueur qu'un humain, et son échec accuse le terrain d'un
## défaut qui n'existe pas. Quand la distance cesse de baisser, on essaie donc ce
## qu'une personne essaie : obliquer d'un côté, puis de l'autre, en sautant.
## Cela reste de la POUSSÉE D'INTENTION — aucune position n'est écrite.
const _STALL_TRIGGER_S: float = 1.2
const _SIDESTEP_S: float = 0.9
const _SIDESTEP_ANGLE: float = 1.15   # ~66°


func _walk_to(player: PlayerController, intent: InputIntent, goal: Vector2,
		arrive: float, budget_s: float, sprint: bool = true) -> bool:
	var elapsed: float = 0.0
	var progress: float = INF
	var stalled: float = 0.0
	var sidestep_left: float = 0.0
	var sidestep_sign: float = 1.0
	while elapsed <= budget_s:
		var step: float = _tree().root.get_physics_process_delta_time()
		var here: Vector2 = Vector2(player.global_position.x, player.global_position.z)
		var to_goal: Vector2 = goal - here
		var span: float = to_goal.length()
		if span <= arrive:
			_walk_report = ""
			return true
		# Détection d'enlisement : si la distance ne baisse plus, inutile de
		# consommer tout le budget — on le dit tout de suite, avec l'endroit.
		if span < progress - 0.05:
			progress = span
			stalled = 0.0
		else:
			stalled += step
		var wish: Vector2 = to_goal.normalized()
		if sidestep_left > 0.0:
			sidestep_left -= step
			wish = wish.rotated(_SIDESTEP_ANGLE * sidestep_sign)
		elif stalled > _STALL_TRIGGER_S:
			sidestep_left = _SIDESTEP_S
			sidestep_sign = -sidestep_sign
			stalled = 0.0
			intent.jump_pressed = true   # une marche, une racine, un rebord
		intent.move = _camera_relative(player,
			Vector3(wish.x, 0.0, wish.y))
		intent.sprint_held = sprint
		var was: Vector3 = player.global_position
		await _tree().physics_frame
		_sample_safety(player, was)
		elapsed += step
	var stop: Vector3 = player.global_position
	_walk_report = "arrêté en (%.0f, %.1f, %.0f) à %.1f m du but, %s, sol=%s, %.1f s sans progrès" \
		% [stop.x, stop.y, stop.z,
			Vector2(stop.x, stop.z).distance_to(goal),
			"mode=%s" % str(player.get("_mode")),
			str(player.is_on_floor()), stalled]
	return false


## Poursuit une cible MOBILE : le but est relu à chaque tick.
##
## `_walk_to()` vise un point figé, ce qui suffit pour du terrain. Un ennemi
## vivant recule, contourne et frappe : viser sa position d'il y a huit secondes
## revient à courir après un fantôme. Mesuré : quatre attaques engagées, zéro
## touche, l'ennemi à 5,5 m.
func _close_on(player: PlayerController, intent: InputIntent, target: Node3D,
		arrive: float, budget_s: float) -> bool:
	var elapsed: float = 0.0
	while elapsed <= budget_s:
		if not is_instance_valid(target):
			return false
		var to_target: Vector3 = target.global_position - player.global_position
		to_target.y = 0.0
		if to_target.length() <= arrive:
			return true
		intent.move = _camera_relative(player, to_target)
		var was: Vector3 = player.global_position
		await _tree().physics_frame
		_sample_safety(player, was)
		elapsed += _tree().root.get_physics_process_delta_time()
	return false


## Appuie sur `interact` EN FAISANT FACE à la cible.
##
## La rotation visuelle ne tourne QUE si le corps bouge : `_orient_visual()`
## sort quand la vitesse horizontale est sous 0,2 m/s. Un héros arrêté ne fait
## donc face à rien, `_select_interactable()` refuse sur le cône, et l'échec
## accuse la portée alors que le défaut est une pose. On pousse la direction
## quelques ticks pour finir le virage, puis on appuie sans lâcher la direction.
var _press_report: String = ""


func _press_interact_facing(player: PlayerController, intent: InputIntent,
		target: Node3D) -> void:
	for i: int in range(10):
		var toward: Vector3 = target.global_position - player.global_position
		intent.move = _camera_relative(player, toward)
		await _tree().physics_frame
	intent.move = _camera_relative(player,
		target.global_position - player.global_position)
	intent.interact_pressed = true
	_press_report = "mode=%d, sol=%s%s" % [int(player.get("_mode")),
		str(player.is_on_floor()), _facing_report(player, target)]
	await _tree().physics_frame
	intent.move = Vector2.ZERO


## Ce que le contrôleur voit vraiment de la cible : distance, cône, sélection.
## Sans ces trois nombres, un refus d'interaction envoie chercher la panne au
## hasard.
func _facing_report(player: PlayerController, target: Node3D) -> String:
	var to_target: Vector3 = target.global_position - player.global_position
	to_target.y = 0.0
	var visual: Node3D = player.get_node_or_null("VisualRoot") as Node3D
	var facing: Vector3 = visual.global_transform.basis.z if visual != null else Vector3.ZERO
	facing.y = 0.0
	var dot: float = to_target.normalized().dot(facing.normalized()) \
		if to_target.length() > 0.01 and facing.length() > 0.01 else -9.0
	var picked: Variant = player.call("_select_interactable")
	# Rejouer la ligne de vue du contrôleur (`_has_interact_los`) et NOMMER ce
	# qui la coupe : « choisi=aucun » avec une distance et un cône corrects ne
	# dit pas si l'objet est hors groupe ou masqué par du décor.
	var exclude: Array[RID] = [player.get_rid()]
	var body: CollisionObject3D = target as CollisionObject3D
	if body != null:
		exclude.append(body.get_rid())
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		player.global_position + Vector3.UP * 1.2,
		target.global_position + Vector3.UP * 0.5, 1, exclude)
	var blocked: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	var blocker: String = "libre"
	if not blocked.is_empty():
		var who: Object = blocked.get("collider")
		blocker = (who as Node).name if who is Node else str(who)
	return " [d=%.2f m (max 2,20) · cos=%.2f (min 0,25) · groupe=%s · vue=%s · choisi=%s]" \
		% [to_target.length(), dot,
			str(target.is_in_group("interactable")), blocker,
			(picked as Node).name if picked != null else "aucun"]


## L'ANCRE de la cible de Résonance la plus proche.
##
## `ResonanceTargetComponent extends Node` — pas Node3D. C'est son PARENT qui
## porte la position. Une recherche qui caste le composant en Node3D obtient
## null pour toutes les cibles et conclut « aucune cible dans le monde » : c'est
## exactement ce que faisait la première version de ce fichier.
func _nearest_resonance_anchor(player: PlayerController) -> Node3D:
	var best: Node3D = null
	var best_distance: float = INF
	for node: Node in _tree().get_nodes_in_group("resonance_targets"):
		if not node.has_method("anchor"):
			continue
		var anchor: Node3D = node.call("anchor") as Node3D
		if anchor == null:
			continue
		var d: float = player.global_position.distance_to(anchor.global_position)
		if d < best_distance:
			best_distance = d
			best = anchor
	return best


## Le nœud du groupe `group` le plus proche du héros, ou null.
func _nearest_in_group(player: PlayerController, group: String,
		predicate: Callable = Callable()) -> Node3D:
	var best: Node3D = null
	var best_distance: float = INF
	for node: Node in _tree().get_nodes_in_group(group):
		var as_3d: Node3D = node as Node3D
		if as_3d == null:
			continue
		if predicate.is_valid() and not bool(predicate.call(node)):
			continue
		var d: float = player.global_position.distance_to(as_3d.global_position)
		if d < best_distance:
			best_distance = d
			best = as_3d
	return best


func _teardown() -> void:
	var clean: bool = await restore_root()
	check(clean, "P10 — la racine est rendue telle qu'elle était (%s)"
		% ("SceneFlow au repos, aucune scène tardive" if clean
			else restore_root_reason()))
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	# L'AMBIANCE SURVIT AU MONDE. `ValleyWorld._ready()` demande
	# `AudioManager.play_ambience(&"amb_valley")`, et `AudioManager` est un
	# autoload : son lecteur et le WAV restent référencés après la disparition
	# de la vallée. En fin de processus, Godot le signale — « 2 ObjectDB
	# instances were leaked », « Resource still in use: amb_valley.wav ». Ce
	# n'est pas une fuite de gameplay ; c'est un test qui ne rend pas le
	# processus tel qu'il l'a trouvé. On le rend.
	var audio: Node = _tree().root.get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("stop_ambience"):
		audio.call("stop_ambience")
	await _settle(4)
	restore_saves()


func test_a_player_walks_from_the_menu_to_the_first_dungeon_room() -> void:
	remember_saves()
	remember_root()

	# --- P1. Le flux normal, sans raccourci --------------------------------
	var boot: Node = (load(BOOT) as PackedScene).instantiate()
	_tree().root.add_child(boot)
	var reached_menu: bool = await _wait_until(
		func() -> bool: return _find("MainMenu") != null, 12.0)
	check(reached_menu, "P1 — Boot mène au menu")
	var menu: Node = _find("MainMenu")
	if menu == null:
		await _teardown()
		return
	var new_game: Button = menu.get_node_or_null("%NewGameButton") as Button
	if new_game == null:
		check(false, "P1b — pas de bouton « Nouvelle partie » : parcours NON VÉRIFIÉ")
		await _teardown()
		return
	new_game.emit_signal("pressed")
	await _settle(2)
	if is_instance_valid(new_game) and new_game.text != "Nouvelle partie":
		new_game.emit_signal("pressed")
	var in_valley: bool = await await_scene("ValleyWorld")
	check(in_valley, "P1b — la vallée s'ouvre par le bouton")
	var valley: Node = _find("ValleyWorld")
	if valley == null:
		await _teardown()
		return
	await _settle(12)
	var player: PlayerController = valley.call("player") as PlayerController
	if player == null:
		check(false, "P2 — aucun joueur : tout le parcours physique est NON VÉRIFIÉ")
		await _teardown()
		return

	var intent: InputIntent = InputIntent.new()
	player.set_intent_source(intent)
	var grounded: bool = await _wait_until(
		func() -> bool: return player.is_on_floor(), 8.0)
	check(grounded, "P2 — le héros se pose avant de partir")
	var start: Vector3 = player.global_position

	# --- P3. Il MARCHE, et le monde le porte -------------------------------
	_lowest_y = player.global_position.y
	var ridge_reached: int = 0
	for goal: Vector2 in ROUTE_RIDGE:
		if not await _walk_to(player, intent, goal, 2.5, 30.0):
			break
		ridge_reached += 1
	intent.move = Vector2.ZERO
	intent.sprint_held = false
	await _settle(6)
	check(ridge_reached == ROUTE_RIDGE.size(),
		"P3 — la descente de crête se MARCHE en entier (%d/%d jalons%s)"
			% [ridge_reached, ROUTE_RIDGE.size(),
				"" if _walk_report == "" else " — " + _walk_report])
	var travelled: float = Vector2(start.x, start.z).distance_to(
		Vector2(player.global_position.x, player.global_position.z))
	check(travelled > 100.0,
		"…soit %.0f m réellement parcourus depuis le spawn" % travelled)
	# Mesure, pas affirmation : ce minimum vient de CHAQUE tick physique de la
	# descente, pas d'une photo par jalon.
	check(_lowest_y > BELOW_WORLD,
		"…et le plus bas relevé sur %d ticks reste au-dessus du monde (min y = %.2f)"
			% [_frames_sampled, _lowest_y])

	# --- P4. Il rejoint un COFFRE et l'ouvre AVEC LA TOUCHE ----------------
	# Un VRAI coffre, choisi comme tel, et dont on exige l'effet d'inventaire.
	# La version précédente prenait « l'interactable le plus proche » et parlait
	# quand même d'ouverture : selon ce que le hasard du terrain plaçait là, elle
	# aurait pu prouver un ramassage d'ingrédient en le nommant coffre. L'audit
	# a demandé de trancher ; on tranche du côté fort.
	var target: Node3D = _nearest_in_group(player, "interactable",
		func(node: Node) -> bool:
			if not node.has_method("interact") or node is SceneDoor:
				return false
			return String(node.get_class()).contains("Chest") \
				or node.name.to_lower().contains("chest") \
				or node.name.to_lower().contains("coffre"))
	check(target != null, "P4 — un COFFRE existe près de la route")
	# PIÈGE GDSCRIPT : une lambda capture les locales PAR VALEUR. Écrire
	# `opened = true` depuis le rappel modifiait la copie de la lambda, et le
	# test lisait toujours `false` — il a accusé le coffre de ne pas s'ouvrir
	# alors que son propre état disait « déjà ouvert=true ». On passe donc par
	# un tableau, qui est une référence.
	var openings: Array[Node] = []
	if target != null:
		var here: Vector2 = Vector2(player.global_position.x, player.global_position.z)
		var goal: Vector2 = Vector2(target.global_position.x, target.global_position.z)
		var span: float = here.distance_to(goal)
		var walked: bool = await _walk_to(player, intent, goal, INTERACT_STOP, 30.0, false)
		check(walked, "…et le héros s'en approche à pied (%.0f m%s)"
			% [span, "" if _walk_report == "" else " — " + _walk_report])
		# On garde la direction une frame de plus : la rotation visuelle ne
		# tourne QUE si le corps bouge (`_orient_visual` exige v² ≥ 0,04). Un
		# héros arrêté ne fait donc face à rien, et l'interaction serait refusée
		# pour une raison qui n'a rien à voir avec la portée.
		var inv_before: Node = player.inventory()
		var weapons_before: int = int(inv_before.call("weapon_count")) \
			if inv_before != null and inv_before.has_method("weapon_count") else -1
		player.interacted.connect(func(who: Node3D) -> void: openings.append(who),
			CONNECT_ONE_SHOT)
		await _press_interact_facing(player, intent, target)
		await _settle(20)
		check(not openings.is_empty(),
			"…et `interact_pressed` OUVRE réellement le coffre « %s » (%s) "
				% [target.name, target.get_class()]
			+ "— à l'appui : %s" % _press_report)
		# L'ouverture ne suffit pas : un coffre qui s'anime sans rien donner
		# n'est pas un coffre. On exige l'effet, mesuré sur l'inventaire du
		# joueur, et on ÉCHOUE FERMÉ si l'inventaire ne sait pas compter.
		var inventory: Node = player.inventory()
		if inventory != null and inventory.has_method("weapon_count"):
			var after_open: int = int(inventory.call("weapon_count"))
			check(after_open > weapons_before,
				"…et l'inventaire du joueur en porte la trace (%d → %d armes)"
					% [weapons_before, after_open])
		else:
			check(false,
				"…mais l'effet est NON VÉRIFIÉ : l'inventaire n'expose pas "
				+ "`weapon_count` (obtenu : %s)" % str(inventory))

	# --- P5. Il frappe un ennemi PAR LE CONTRÔLEUR -------------------------
	var enemy: Node3D = _nearest_in_group(player, "enemies")
	check(enemy != null, "P5 — un ennemi est présent dans le monde parcouru")
	if enemy != null:
		var enemy_health: Node = null
		var found: Array[Node] = enemy.find_children("*", "HealthComponent", true, false)
		enemy_health = found[0] if not found.is_empty() else null
		var struck_by: Array[Node] = []
		if enemy_health != null:
			enemy_health.connect("damaged", func(event: DamageEvent) -> void:
				struck_by.append(event.instigator))
		var goal: Vector2 = Vector2(enemy.global_position.x, enemy.global_position.z)
		await _walk_to(player, intent, goal, 6.0, 30.0, false)
		var closed_in: bool = await _close_on(player, intent, enemy, ATTACK_STOP, 20.0)
		check(closed_in, "…et le héros va au contact à pied (%.1f m)"
			% (player.global_position.distance_to(enemy.global_position)
				if is_instance_valid(enemy) else -1.0))
		# Trois appuis espacés : une attaque a un startup et un recovery, et
		# l'ennemi bouge. Marteler la touche ne prouverait rien de plus.
		var swings_engaged: int = 0
		for swing: int in range(4):
			if not is_instance_valid(enemy):
				break
			# Se rapprocher à nouveau : un ennemi vivant recule, contourne et
			# frappe. Un pilote qui reste planté rate sa cible sans rien prouver.
			await _close_on(player, intent, enemy, ATTACK_STOP, 8.0)
			for i: int in range(6):
				intent.move = _camera_relative(player,
					enemy.global_position - player.global_position)
				await _tree().physics_frame
			intent.attack_pressed = true
			await _tree().physics_frame
			# `Mode { LOCOMOTION, CLIMBING, MANTLING, ATTACKING, … }` — ATTACKING
			# vaut 3. La première version comparait à 2 (MANTLING) et comptait
			# donc zéro essai engagé alors que l'attaque partait peut-être.
			if int(player.get("_mode")) == 3:
				swings_engaged += 1
			intent.move = Vector2.ZERO
			await _settle(45)
		check(not struck_by.is_empty(),
			"…et `attack_pressed` fait ENCAISSER l'ennemi (%d touche(s), %d essai(s) "
				% [struck_by.size(), swings_engaged]
			+ "engagé(s) par le contrôleur, ennemi à %.1f m, arme=%s)"
				% [player.global_position.distance_to(enemy.global_position)
					if is_instance_valid(enemy) else -1.0,
					str(player.inventory().equipped_weapon())
						if player.inventory() != null
						and player.inventory().has_method("equipped_weapon")
						else "inconnue"])
		var by_player: bool = false
		for who: Node in struck_by:
			if who == player:
				by_player = true
		check(by_player,
			"…et l'instigateur du dégât est le JOUEUR, pas un appel de test")

	# --- P6. Pulse par la touche, avec un effet OBSERVABLE ------------------
	# Le verdict « fired » ne suffit pas : il est rendu même quand rien n'est
	# révélé. On exige `revealed_count > 0`, c'est-à-dire une cible réellement
	# touchée par l'onde.
	# `ResonanceTargetComponent extends Node`, PAS Node3D : c'est son parent qui
	# porte la position (`anchor()`). La première version de ce test castait le
	# composant en Node3D, obtenait null pour toutes les cibles, et concluait
	# « aucune cible de Résonance dans le monde » — un test qui cherche mal
	# accuse le jeu à tort.
	var anchor: Node3D = _nearest_resonance_anchor(player)
	check(anchor != null, "P6 — une cible de Résonance existe dans le monde")
	if anchor != null:
		var goal: Vector2 = Vector2(anchor.global_position.x, anchor.global_position.z)
		var closed_in: bool = await _walk_to(player, intent, goal, PULSE_STOP, 40.0, false)
		check(closed_in, "…et le héros s'en approche à pied")
		var revealed: Array[int] = []
		var resonance: ResonanceController = player.resonance()
		if resonance != null:
			resonance.pulse_fired.connect(func(count: int) -> void:
				revealed.append(count), CONNECT_ONE_SHOT)
		intent.move = _camera_relative(player, anchor.global_position - player.global_position)
		await _settle(4)
		intent.move = Vector2.ZERO
		intent.pulse_pressed = true
		await _tree().physics_frame
		await _settle(10)
		check(not revealed.is_empty(),
			"…et `pulse_pressed` déclenche RÉELLEMENT le Bracelet")
		check(not revealed.is_empty() and revealed[0] > 0,
			"…avec un effet observable : %d cible(s) révélée(s), pas seulement « fired »"
				% (revealed[0] if not revealed.is_empty() else -1))

	# --- P7. Il parcourt la route du donjon --------------------------------
	var road_reached: int = 0
	for goal: Vector2 in ROUTE_CITADEL:
		if not await _walk_to(player, intent, goal, 4.0, 45.0):
			break
		road_reached += 1
	intent.move = Vector2.ZERO
	intent.sprint_held = false
	await _settle(6)
	check(road_reached == ROUTE_CITADEL.size(),
		"P7 — la route du donjon se MARCHE en entier (%d/%d jalons%s)"
			% [road_reached, ROUTE_CITADEL.size(),
				"" if _walk_report == "" else " — " + _walk_report])
	check(not player.health().is_dead(),
		"…et le héros y arrive VIVANT (%.0f PV)" % player.health().current())

	# --- P8. La porte de la citadelle, par la touche -----------------------
	var door: Node3D = _find("CitadelDoor") as Node3D
	check(door != null, "P8 — la porte de la citadelle est là")
	if door != null:
		var goal: Vector2 = Vector2(door.global_position.x, door.global_position.z)
		var at_door: bool = await _walk_to(player, intent, goal, INTERACT_STOP, 30.0, false)
		var span: float = Vector2(player.global_position.x,
			player.global_position.z).distance_to(goal)
		check(at_door,
			"…et le héros arrive à SON SEUIL à pied (%.1f m du battant)" % span)
		await _press_interact_facing(player, intent, door)
		var in_vestibule: bool = await await_scene("CitadelVestibule")
		check(in_vestibule,
			"P8b — `interact_pressed` DEVANT la porte ouvre le vestibule")

	# --- P9. Et la porte du donjon, à pied elle aussi ----------------------
	var vestibule: Node = _find("CitadelVestibule")
	if vestibule == null:
		check(false, "P9 — vestibule absent : la salle 1 reste NON VÉRIFIÉE à pied")
		await _teardown()
		return
	await _settle(20)
	var hero: PlayerController = vestibule.call("player") as PlayerController \
		if vestibule.has_method("player") else null
	check(hero != null, "P9 — le vestibule porte un joueur pilotable")
	if hero == null:
		await _teardown()
		return
	var hero_intent: InputIntent = InputIntent.new()
	hero.set_intent_source(hero_intent)
	await _wait_until(func() -> bool: return hero.is_on_floor(), 8.0)
	var dungeon_door: Node3D = _find("DungeonDoor") as Node3D
	check(dungeon_door != null, "…et une porte de donjon")
	if dungeon_door != null:
		var goal: Vector2 = Vector2(dungeon_door.global_position.x,
			dungeon_door.global_position.z)
		var at_door: bool = await _walk_to(hero, hero_intent, goal,
			INTERACT_STOP, 30.0, false)
		check(at_door, "…que le héros rejoint à pied dans le vestibule")

		# Premier appui AU CENTRE du battant — l'endroit où un joueur se place.
		await _press_interact_facing(hero, hero_intent, dungeon_door)
		var centre_report: String = _press_report
		var centre_selected: bool = centre_report.contains("choisi=DungeonDoor")
		var in_room1: bool = await await_scene("Room1Initiation")

		# Un joueur qui n'obtient rien FAIT UN PAS DE CÔTÉ et réessaie. Le pilote
		# l'imite : deux décalages latéraux, toujours par la même touche.
		# Le rayon d'arrivée doit être PLUS PETIT que le décalage, sinon le
		# pilote est déjà « arrivé » sans avoir bougé et le repositionnement est
		# une illusion : mesuré, deux essais et zéro pas de côté.
		var offsets: Array[float] = [1.5, -1.5]
		var attempts: Array[String] = []
		var index: int = 0
		while not in_room1 and index < offsets.size():
			var side: Vector2 = Vector2(goal.y - hero.global_position.z,
				hero.global_position.x - goal.x).normalized()
			# S'ÉCARTER PUIS REVENIR. Un héros collé au battant ne tourne plus :
			# `_orient_visual()` exige 0,2 m/s, et la porte le bloque. Sans ce
			# recul, le cône échoue (cos 0,18 mesuré) et l'échec accuserait le
			# jeu d'un défaut qui appartient au pilote.
			await _walk_to(hero, hero_intent,
				goal + side * offsets[index] * 2.2, 0.6, 12.0, false)
			await _walk_to(hero, hero_intent,
				goal + side * offsets[index], 0.5, 12.0, false)
			await _press_interact_facing(hero, hero_intent, dungeon_door)
			attempts.append("décalage %+.1f m → %s" % [offsets[index], _press_report])
			in_room1 = await await_scene("Room1Initiation")
			index += 1

		check(in_room1,
			"P9b — la SALLE 1 est atteinte À PIED depuis le menu principal "
			+ "(%d repositionnement(s)%s)"
				% [index, "" if attempts.is_empty() else " ; " + " | ".join(attempts)])
		# CRITÈRE DISTINCT, et c'est lui qui a trouvé quelque chose : au centre
		# du battant, portée et cône parfaits, l'invite ne répond pas. Le rayon
		# de ligne de vue de `_has_interact_los()` traverse `SealedSeam`, une
		# veine cyan décorative posée en `StaticBody3D` sur la COUCHE 1 à
		# z = −12,50, juste devant la porte à z = −12,75. Le décor coupe donc
		# l'interaction. Aucun test d'appel direct ne pouvait le voir.
		check(centre_selected,
			"P9c — l'invite répond DEVANT la porte, au centre du battant — "
			+ "à l'appui : %s" % centre_report)

	# --- P11. Ce que la marche entière a mesuré ----------------------------
	# Ces deux critères ne portent pas sur un jalon : ils portent sur CHAQUE tick
	# physique du parcours, du spawn à la salle 1.
	check(_lowest_y > BELOW_WORLD,
		"P11 — sur %d ticks physiques de marche, le héros n'est JAMAIS passé "
			% _frames_sampled
		+ "sous le monde (min y = %.2f, seuil %.1f)" % [_lowest_y, BELOW_WORLD])
	# Un secours, un respawn ou une remontée de filet déplacent le héros de
	# plusieurs mètres en un tick. Aucune locomotion légitime ne le fait :
	# sprint 9 m/s → 0,15 m ; Arc Step 18 m/s → 0,30 m.
	check(_max_jump < DISCONTINUITY_M,
		"…et aucune discontinuité de position : plus grand saut %.2f m en un "
			% _max_jump
		+ "tick (seuil %.1f), vers (%.0f, %.1f, %.0f)"
			% [DISCONTINUITY_M, _jump_at.x, _jump_at.y, _jump_at.z])

	await _teardown()
