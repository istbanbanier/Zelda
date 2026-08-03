## Un shell sert le joueur de SA scène (régression F.6).
##
## Défaut mesuré : `GameplayShell._bind_player()` prenait le premier nœud
## du groupe `player`. Dès que deux mondes coexistent — transition de
## scène, monde préchargé, suite de tests — le shell d'une scène servait
## le joueur d'une AUTRE. Symptôme observé dans la suite complète : la
## MORT MANQUÉE, panneau de mort jamais affiché, parce que le shell
## écoutait la santé d'un joueur qui ne mourait pas. Trois tests
## échouaient sans qu'aucune ligne de leur code n'ait changé.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const ROOM: String = "res://scenes/dungeon/rooms/Room1Initiation.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open(path: String) -> Node3D:
	var scene: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(scene)
	await _settle(10)
	return scene


func _close(scene: Node) -> void:
	scene.get_parent().remove_child(scene)
	scene.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(3)


func test_each_shell_binds_the_player_of_its_own_scene() -> void:
	## Deux mondes chargés en même temps : chaque shell doit suivre SON
	## joueur, pas celui du voisin.
	var valley: Node3D = await _open(VALLEY)
	var room: Node3D = await _open(ROOM)
	var valley_shell: GameplayShell = valley.get_node("GameplayShell") \
		as GameplayShell
	var room_shell: GameplayShell = room.get_node("GameplayShell") \
		as GameplayShell
	var valley_player: PlayerController = valley.call("player") \
		as PlayerController
	var room_player: PlayerController = room.call("player") as PlayerController
	check(valley_player != room_player, "deux joueurs distincts sont chargés")
	check(valley_shell.bound_player() == valley_player,
		"le shell de la vallée suit le joueur de la vallée")
	check(room_shell.bound_player() == room_player,
		"le shell de la salle suit le joueur de la salle")
	await _close(room)
	await _close(valley)


func test_the_death_panel_follows_the_player_that_actually_dies() -> void:
	## La conséquence qui comptait : tuer le joueur d'un monde n'ouvre le
	## panneau QUE dans ce monde-là.
	var valley: Node3D = await _open(VALLEY)
	var room: Node3D = await _open(ROOM)
	var valley_shell: GameplayShell = valley.get_node("GameplayShell") \
		as GameplayShell
	var room_shell: GameplayShell = room.get_node("GameplayShell") \
		as GameplayShell
	var room_player: PlayerController = room.call("player") as PlayerController
	var blow: DamageEvent = DamageEvent.new()
	blow.amount = 999.0
	blow.attack_id = HitboxComponent.next_attack_id()
	(room_player.get_node("Hurtbox") as HurtboxComponent).receive_hit(blow)
	check(room_player.health().is_dead(), "le joueur de la salle est mort")
	# Le panneau part sur un `Timer` de 1,2 s : on attend du TEMPS, pas des
	# images — la cadence de `process_frame` varie en headless.
	var opened: bool = false
	var deadline: int = Time.get_ticks_msec() + 4000
	while Time.get_ticks_msec() < deadline:
		await _tree().process_frame
		if room_shell.is_death_panel_open():
			opened = true
			break
	check(opened, "le panneau s'ouvre DANS la salle")
	check(not valley_shell.is_death_panel_open(),
		"…et pas dans la vallée, dont le joueur est vivant")
	await _close(room)
	await _close(valley)
