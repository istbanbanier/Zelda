## L'ARC TIRE VRAIMENT, AU GESTE DÉCRIT DANS LE PANNEAU « COMMANDES ».
##
## Défaut mesuré au playtest humain du 2026-08-07 : « Clic droit = RIEN. Clic
## droit + clic gauche = RIEN, "Flèches : 8" ne bouge pas. » Le compteur est
## resté sur 8 pendant les 74 minutes de la partie. Conséquence en chaîne : les
## cristaux du boss sont à y = 3,90 m, hors de portée du corps à corps — sans
## arc, le boss était mathématiquement invincible.
##
## CAUSE : `attack_light` et `shoot` sont tous deux sur le clic GAUCHE
## (project.godot, button_index 1). La cascade de `player_input_reader.gd` est
## une suite de `elif` et testait `attack_light` en premier : le clic était
## toujours consommé par l'attaque, `shoot_pressed` restait faux.
##
## POURQUOI AUCUN TEST NE L'AVAIT VU : les tests d'entrée existants envoient des
## `InputEventAction`, qui ne portent QU'UNE action et ne peuvent donc pas
## reproduire la collision. Ce cas envoie de VRAIS `InputEventMouseButton` —
## c'est le seul événement qui réveille les deux actions à la fois, donc le seul
## qui reproduise ce que fait la main du joueur.
extends GateTestCase

const COURSE: String = "res://scenes/tests/TraversalCourse.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"

## project.godot : `aim` = clic droit, `attack_light` ET `shoot` = clic gauche.
const MOUSE_LEFT: int = MOUSE_BUTTON_LEFT
const MOUSE_RIGHT: int = MOUSE_BUTTON_RIGHT

var _world: Node = null
var _player: PlayerController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _spawn() -> bool:
	var course_scene: PackedScene = load(COURSE) as PackedScene
	var player_scene: PackedScene = load(PLAYER) as PackedScene
	if course_scene == null or player_scene == null:
		return false
	_world = course_scene.instantiate()
	_tree().root.add_child(_world)
	_player = player_scene.instantiate() as PlayerController
	_world.add_child(_player)
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	return true


func _teardown() -> void:
	# Ne jamais laisser un bouton enfoncé derrière soi : l'état d'`Input` est
	# global au processus et contaminerait les cas suivants.
	_mouse(MOUSE_LEFT, false)
	_mouse(MOUSE_RIGHT, false)
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null


func _mouse(button: int, pressed: bool) -> void:
	var ev: InputEventMouseButton = InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = pressed
	ev.position = Vector2.ZERO
	Input.parse_input_event(ev)


func _bow() -> BowComponent:
	return _player.get_node("Components/BowComponent") as BowComponent


## LE TEST QUI MANQUAIT : viser (clic droit tenu) puis tirer (clic gauche)
## doit consommer une flèche et en mettre une en vol.
func test_aiming_then_left_clicking_actually_looses_an_arrow() -> void:
	if not _spawn():
		check(false, "mise en scène impossible")
		return
	await _settle(20)
	check(_player.is_on_floor(), "préalable : le héros est posé au sol")
	var inventory: InventoryComponent = _player.inventory()
	check(inventory.has_arrows(), "préalable : le héros a des flèches")
	var before: int = inventory.arrows()

	# Le geste exact du panneau « Commandes » : clic D maintenu, puis clic G.
	_mouse(MOUSE_RIGHT, true)
	await _settle(4)
	check(_player.current_intent().aim_held, "la visée est bien tenue")
	_mouse(MOUSE_LEFT, true)
	await _settle(2)
	_mouse(MOUSE_LEFT, false)
	await _settle(6)

	check(inventory.arrows() == before - 1,
		"une flèche est consommée : %d → %d" % [before, inventory.arrows()])
	check(not _bow().active_arrows().is_empty(),
		"…et une flèche est réellement en vol")
	_mouse(MOUSE_RIGHT, false)
	_teardown()


## L'inverse doit rester vrai : sans visée, le clic gauche reste l'attaque.
## Une correction qui ferait tirer en permanence casserait le corps à corps.
func test_without_aiming_the_left_click_is_still_the_sword() -> void:
	if not _spawn():
		check(false, "mise en scène impossible")
		return
	await _settle(20)
	var inventory: InventoryComponent = _player.inventory()
	var before: int = inventory.arrows()

	_mouse(MOUSE_LEFT, true)
	await _settle(2)
	_mouse(MOUSE_LEFT, false)
	await _settle(6)

	check_equal(inventory.arrows(), before,
		"aucune flèche consommée hors visée")
	check(_bow().active_arrows().is_empty(),
		"aucune flèche en vol hors visée")
	_teardown()
