## `E` NE RESTE JAMAIS SANS RÉPONSE, ET LES RAMASSABLES SONT SUR LE SOL.
##
## Ce sont les deux moitiés du défaut nº1 du playtest du 2026-08-07.
##
## Ce que l'enquête a établi, contre les deux hypothèses de départ : la chaîne
## d'interaction N'EST PAS cassée. `tools/godot/diagnose_interaction.gd` la
## mesure sur la vraie vallée et trouve 53 des 55 interactables atteignables,
## feu de cuisine compris, invite du HUD comprise. La liaison différée du shell
## a réussi elle aussi — le joueur voyait sa vie, son endurance, ses flèches et
## son verrouillage, tous branchés par le MÊME appel.
##
## Ce qui a réellement échoué, c'est le SILENCE. Le joueur a appuyé sur `E`
## devant une enclume, un cadavre, un objet orange et un foyer décoratif —
## quatre décors — sans obtenir ni son, ni message, ni refus. Il en a conclu
## que la touche était morte et a cessé d'essayer : 0 coffre ouvert sur 74
## minutes, alors que 55 objets répondaient.
##
## Et les deux PREMIERS ramassables de la partie, sur la crête de spawn,
## étaient enterrés de 8,00 m sous le relief (mesuré à la sonde : sol y=32,00
## pour une pose à y=24,00).
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"

var _valley: Node3D = null
var _player: PlayerController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _load() -> void:
	_valley = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_valley)
	await _settle(8)
	_player = _valley.call("player") as PlayerController


func _unload() -> void:
	_tree().paused = false
	_valley.get_parent().remove_child(_valley)
	_valley.queue_free()
	_valley = null
	_player = null
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


## Le geste du joueur devant un décor : `E`, et une réponse.
func test_pressing_the_key_with_nothing_in_reach_still_answers() -> void:
	await _load()
	var shell: GameplayShell = _valley.get_node("GameplayShell") as GameplayShell
	# Loin de tout : le vide au-dessus de la plaine sud, aucun interactable.
	# Plaine sud (dalle `PlainSouth`, sommet y = 2,00), loin de tout objet.
	# Posé JUSTE au-dessus : lâché de 40 m il serait encore en chute libre au
	# moment du test, et `_try_interact` exige `is_on_floor()`.
	_player.global_position = Vector3(-180.0, 3.0, 200.0)
	_player.velocity = Vector3.ZERO
	await _settle(40)
	check(_player.is_on_floor(), "préalable : le héros a les pieds au sol")
	check(_player.current_interact_target() == null,
		"préalable : rien à portée ici")
	var before: int = shell.notification_texts().size()

	# On passe par le VRAI chemin d'entrée : l'action, pas un appel interne.
	var press: InputEventAction = InputEventAction.new()
	press.action = &"interact"
	press.pressed = true
	Input.parse_input_event(press)
	await _settle(6)

	var after: Array[String] = shell.notification_texts()
	check(after.size() > before,
		"un refus est ANNONCÉ (%d → %d notifications)" % [before, after.size()])
	if after.size() > before:
		check(after[after.size() - 1].contains("portée"),
			"…et il dit pourquoi : « %s »" % after[after.size() - 1])
	await _unload()


## …sans transformer un martèlement de touche en tapis de messages.
func test_hammering_the_key_does_not_flood_the_screen() -> void:
	await _load()
	var shell: GameplayShell = _valley.get_node("GameplayShell") as GameplayShell
	# Plaine sud (dalle `PlainSouth`, sommet y = 2,00), loin de tout objet.
	# Posé JUSTE au-dessus : lâché de 40 m il serait encore en chute libre au
	# moment du test, et `_try_interact` exige `is_on_floor()`.
	_player.global_position = Vector3(-180.0, 3.0, 200.0)
	_player.velocity = Vector3.ZERO
	await _settle(40)
	check(_player.is_on_floor(), "préalable : le héros a les pieds au sol")
	var before: int = shell.notification_texts().size()
	for i: int in range(8):
		var press: InputEventAction = InputEventAction.new()
		press.action = &"interact"
		press.pressed = true
		Input.parse_input_event(press)
		await _settle(2)
	var added: int = shell.notification_texts().size() - before
	check(added >= 1, "au moins un refus annoncé (%d)" % added)
	check(added <= 3,
		"huit appuis ne produisent pas huit messages (%d)" % added)
	await _unload()


## AUCUN INGRÉDIENT N'EST HORS D'ATTEINTE.
##
## Le critère est la PORTÉE, pas la géométrie : un fruit posé dans une cabane
## chevauche légitimement le plancher, et une sonde de solide le déclarerait
## enterré à tort — c'est l'erreur que ce cas commettait avant d'être corrigé.
## La seule question qui compte pour le joueur est : puis-je l'atteindre ?
## Les deux fruits de la crête, eux, étaient 8,00 m sous le relief et
## échouaient donc bien ici.
func test_every_ingredient_can_be_reached_by_a_standing_player() -> void:
	await _load()
	var unreachable: Array[String] = []
	var checked: int = 0
	for node: Node in _valley.find_children("*", "IngredientPickup", true, false):
		var pickup: Node3D = node as Node3D
		if pickup == null:
			continue
		checked += 1
		var reached: bool = false
		for axis: Vector3 in [Vector3.FORWARD, Vector3.BACK,
				Vector3.LEFT, Vector3.RIGHT]:
			_player.velocity = Vector3.ZERO
			_player.global_position = pickup.global_position \
				+ axis * 1.4 + Vector3.UP * 0.8
			await _settle(4)
			var visual: Node3D = _player.get_node("VisualRoot") as Node3D
			var to_target: Vector3 = pickup.global_position \
				- _player.global_position
			visual.rotation.y = atan2(to_target.x, to_target.z)
			await _settle(10)
			if _player.current_interact_target() == pickup:
				reached = true
				break
		if not reached:
			unreachable.append(pickup.name)
	check(checked > 0, "des ingrédients existent dans la vallée (%d)" % checked)
	check(unreachable.is_empty(),
		"tous atteignables ; hors d'atteinte : %s"
			% ("aucun" if unreachable.is_empty() else ", ".join(unreachable)))
	await _unload()


## Et ils sont réellement ramassables depuis la position d'un joueur — la
## mesure qui manquait partout ailleurs.
func test_the_first_ingredients_can_actually_be_reached() -> void:
	await _load()
	var wanted: Array[String] = [
		"valley_ingredient_crest_fruit_01",
		"valley_ingredient_crest_fruit_02",
	]
	var reached: int = 0
	for name_wanted: String in wanted:
		var found: Array[Node] = _valley.find_children(
			name_wanted, "", true, false)
		if found.is_empty():
			continue
		var target: Node3D = found[0] as Node3D
		for axis: Vector3 in [Vector3.FORWARD, Vector3.BACK,
				Vector3.LEFT, Vector3.RIGHT]:
			_player.velocity = Vector3.ZERO
			_player.global_position = target.global_position \
				+ axis * 1.4 + Vector3.UP * 0.8
			await _settle(4)
			var visual: Node3D = _player.get_node("VisualRoot") as Node3D
			var to_target: Vector3 = target.global_position \
				- _player.global_position
			visual.rotation.y = atan2(to_target.x, to_target.z)
			await _settle(12)
			if _player.current_interact_target() == target:
				reached += 1
				break
	check_equal(reached, wanted.size(),
		"les deux fruits de la crête sont atteignables (%d/%d)"
			% [reached, wanted.size()])
	await _unload()
