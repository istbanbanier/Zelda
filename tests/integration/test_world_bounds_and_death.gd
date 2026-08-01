## Limites du monde, mort, structures accessibles — régressions PT-D1-04/-09/-10.
##
## Le périmètre se prouve par SONDES physiques (16 rayons vers l'extérieur), le
## secours par une vraie chute, la mort par le panneau et sa cible de retry, la
## citadelle par la chaîne complète : porte de la vallée → vestibule → porte de
## sortie → retour DEVANT la porte (tags d'apparition réellement consommés).
## Les transitions vivantes ne s'exécutent pas dans le runner (elles
## remplaceraient sa scène) : chaque maillon est prouvé séparément, la chaîne
## humaine se joue sur poste.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const VESTIBULE: String = "res://scenes/world/citadel/CitadelVestibule.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _cleanup(world: Node) -> void:
	if _tree().paused:
		_tree().paused = false
	_tree().root.remove_child(world)
	world.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


func test_the_mountain_ring_is_continuous_and_unclimbable() -> void:
	## PT-D1-09 : seize rayons horizontaux tirés vers l'extérieur depuis un
	## anneau intérieur (r = 200, y = 50) — chacun doit rencontrer de la matière
	## avant 150 m. Un seul trou dans la chaîne ferait rougir sa direction.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)
	var space: PhysicsDirectSpaceState3D = valley.player().get_world_3d().direct_space_state

	var holes: Array[String] = []
	for i: int in range(16):
		var angle: float = TAU * float(i) / 16.0
		var direction: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var from: Vector3 = direction * 200.0 + Vector3(0, 50, 0)
		# 200 m : aux diagonales, la face interne du coin est à ~154 m de
		# l'anneau de sonde (250·√2 − 200) — un rayon de 150 m la manquait.
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			from, from + direction * 200.0, 1)
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			holes.append("%.0f°" % rad_to_deg(angle))
		else:
			var collider: Node = hit.get("collider") as Node
			if collider != null and not collider.is_in_group("unclimbable"):
				holes.append("%.0f° (franchissable !)" % rad_to_deg(angle))
	check(holes.is_empty(),
		"chaîne montagneuse continue et infranchissable — trous : %s" % str(holes))
	await _cleanup(valley)


func test_a_fall_is_rescued_early_to_the_last_safe_point() -> void:
	## PT-D1-09 : le filet intervient TÔT (-6, cadence 0,25 s) et ramène au
	## DERNIER POINT SÛR — ici, la crête de départ où le joueur vient de marcher.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var player: PlayerController = valley.player()
	for i: int in range(120):
		if player.is_on_floor():
			break
		await _tree().physics_frame
	# Laisser le point sûr s'enregistrer (cadence 2 s), puis précipiter le
	# joueur dans une chute impossible.
	await _settle(140)
	var safe: Vector3 = valley.last_safe_point()
	check((safe - player.global_position).length() < 2.0,
		"le point sûr suit le joueur au sol")
	player.global_position = Vector3(0, -8.0, 300)
	player.reset_physics_interpolation()

	var rescued: bool = false
	for i: int in range(400):
		await _tree().process_frame
		if (player.global_position - safe).length() < 2.0:
			rescued = true
			break
	check(rescued, "repêché au dernier point sûr, sans longue chute visible")
	check(player.velocity.length() < 0.5, "vitesse remise à zéro au repêchage")
	await _cleanup(valley)


func test_death_offers_retry_toward_the_checkpoint_world() -> void:
	## PT-D1-04 : mourir n'exige plus de relancer le projet — le panneau
	## apparaît, « Réessayer » vise le monde-checkpoint et pose le tag de reprise.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)
	var player: PlayerController = valley.player()
	var shell: GameplayShell = valley.get_node("GameplayShell") as GameplayShell
	check(not shell.is_death_panel_open(), "préalable : pas de panneau en vie")

	var blow: DamageEvent = DamageEvent.new()
	blow.amount = 999.0
	blow.attack_id = HitboxComponent.next_attack_id()
	(player.get_node("Hurtbox") as HurtboxComponent).receive_hit(blow)
	check(player.health().is_dead(), "préalable : mort")

	var opened: bool = false
	for i: int in range(300):   # délai d'1,2 s + marge
		await _tree().process_frame
		if shell.is_death_panel_open():
			opened = true
			break
	check(opened, "le panneau de mort apparaît")
	check_equal(shell.retry_target(), VALLEY,
		"« Réessayer » vise le monde-checkpoint")
	await _cleanup(valley)


func test_the_death_panel_is_modal_no_pause_inventory_or_mouse_grab() -> void:
	## QA-D1R-03 (revue contradictoire) : mort → Échap → Reprendre recapturait la
	## souris SOUS l'écran de mort (curseur avalé au-dessus d'une UI à cliquer),
	## et Tab ouvrait l'inventaire par-dessus. L'écran de mort est maintenant
	## modal : mesuré sur l'état voulu de la souris et sur les panneaux.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)
	var player: PlayerController = valley.player()
	var shell: GameplayShell = valley.get_node("GameplayShell") as GameplayShell

	var blow: DamageEvent = DamageEvent.new()
	blow.amount = 999.0
	blow.attack_id = HitboxComponent.next_attack_id()
	(player.get_node("Hurtbox") as HurtboxComponent).receive_hit(blow)
	for i: int in range(300):
		await _tree().process_frame
		if shell.is_death_panel_open():
			break
	check(shell.is_death_panel_open(), "préalable : écran de mort affiché")
	check(not shell.wants_mouse_captured(), "préalable : souris rendue au curseur")

	# Le scénario malheureux exact de la revue : pause puis reprise.
	shell.toggle_pause()
	check(not _tree().paused, "Échap ne met PAS en pause par-dessus la mort")
	shell.toggle_pause()
	check(not shell.wants_mouse_captured(),
		"…et aucun aller-retour ne recapture la souris sous l'écran de mort")
	shell.toggle_inventory()
	check(not shell.is_inventory_open(),
		"Tab n'ouvre pas l'inventaire par-dessus l'écran de mort")
	check(shell.is_death_panel_open(), "l'écran de mort est resté seul maître")
	await _cleanup(valley)


func test_the_citadel_door_leads_to_the_vestibule() -> void:
	## PT-D1-10, maillon 1 : la porte existe sur le plateau, invite « Entrer »,
	## et vise le vestibule — une structure-promesse enfin accessible.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)
	var door: SceneDoor = valley.find_children("CitadelDoor", "SceneDoor", true, false)[0] \
		as SceneDoor
	check_not_null(door, "la porte de la citadelle existe")
	check_equal(door.prompt_verb(), "Entrer", "…et invite à entrer")
	check_equal(door.target_scene, VESTIBULE, "…vers le vestibule graybox")
	var flow: Node = _tree().root.get_node_or_null("/root/SceneFlow")
	check(bool(flow.call("can_go_to", VESTIBULE)),
		"SceneFlow accepte réellement la scène du vestibule")
	await _cleanup(valley)


func test_the_vestibule_is_explorable_and_its_exit_returns_before_the_door() -> void:
	## PT-D1-10, maillons 2 et 3 : le vestibule tient debout (le joueur atterrit
	## sur son sol, éclairé, murs fermés), sa sortie vise la vallée avec le tag
	## `citadel_door` — et la vallée qui consomme ce tag place le joueur DEVANT
	## la porte, PAS au spawn de la crête.
	var vestibule: CitadelVestibule = (load(VESTIBULE) as PackedScene) \
		.instantiate() as CitadelVestibule
	_tree().root.add_child(vestibule)
	await _settle(5)
	var player: PlayerController = vestibule.player()
	var grounded: bool = false
	for i: int in range(120):
		if player.is_on_floor():
			grounded = true
			break
		await _tree().physics_frame
	check(grounded, "le joueur tient sur le sol du vestibule")
	check(vestibule.find_children("CyanLight*", "OmniLight3D", true, false).size() >= 2,
		"éclairé — aucun couloir noir (§7.8)")
	var exit_door: SceneDoor = vestibule.get_node("ExitDoor") as SceneDoor
	check_equal(exit_door.prompt_verb(), "Sortir", "la sortie invite")
	check_equal(exit_door.target_scene, VALLEY, "…vers la vallée")
	check_equal(String(exit_door.spawn_tag), "citadel_door", "…devant la porte")
	await _cleanup(vestibule)

	# Maillon 3 : la vallée honore le tag — apparition devant la porte.
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	game_state.call("set_pending_spawn", &"citadel_door")
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var returned: PlayerController = valley.player()
	check(returned.global_position.z < -180.0,
		"le retour place le joueur DEVANT la porte (z = %.0f), pas au spawn (z = 150)"
		% returned.global_position.z)
	check(absf(returned.global_position.y - 34.3) < 1.5,
		"…sur le plateau (y = %.2f)" % returned.global_position.y)
	await _cleanup(valley)
