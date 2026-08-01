## Génère InputMap, couches de collision et autoloads dans `project.godot`
## (MASTER_SPEC §8.5, §5.7, §5.6).
##
## Usage :
##   godot --headless --path . --script tools/godot/setup_project.gd
##
## Pourquoi un générateur plutôt qu'une édition à la main : la section `[input]`
## de `project.godot` contient des `Object(InputEventKey, …)` sérialisés. Écrire ce
## format à la main revient à supposer une sérialisation ; ici c'est Godot qui
## sérialise, donc le fichier est correct par construction. Le script est
## idempotent et reste la source de vérité du mapping.
##
## CHOIX CENTRAL — `physical_keycode` et non `keycode` :
## un `physical_keycode` désigne la POSITION physique de la touche, exprimée par
## son étiquette sur un clavier QWERTY. La position de `A` (QWERTY) porte
## l'étiquette `Q` sur un clavier AZERTY. Une seule liaison sert donc les deux
## dispositions, et l'invariant « AZERTY prioritaire, Q = gauche » est satisfait
## sans mapping concurrent — c'est exactement la table de §8.5.
extends SceneTree

# Valeurs relevées dans /opt/src/godot/core/os/keyboard.h et input_enums.h
# du tag 4.7.1-stable — jamais supposées.
const KEY_SPECIAL: int = 1 << 22
const KEY_ESCAPE: int = KEY_SPECIAL | 0x01
const KEY_TAB: int = KEY_SPECIAL | 0x02
const KEY_SHIFT: int = KEY_SPECIAL | 0x15
const KEY_CTRL: int = KEY_SPECIAL | 0x16
const KEY_SPACE: int = 0x20
const KEY_A: int = 0x41
const KEY_C: int = 0x43
const KEY_D: int = 0x44
const KEY_E: int = 0x45
const KEY_F: int = 0x46
const KEY_R: int = 0x52
const KEY_S: int = 0x53
const KEY_V: int = 0x56
const KEY_W: int = 0x57
const KEY_X: int = 0x58

const MOUSE_LEFT: int = 1
const MOUSE_RIGHT: int = 2
const MOUSE_MIDDLE: int = 3
const MOUSE_WHEEL_UP: int = 4
const MOUSE_WHEEL_DOWN: int = 5

const JOY_A: int = 0
const JOY_B: int = 1
const JOY_X: int = 2
const JOY_Y: int = 3
const JOY_START: int = 6
const JOY_LEFT_STICK: int = 7
const JOY_RIGHT_STICK: int = 8
const JOY_RIGHT_SHOULDER: int = 10
const JOY_DPAD_DOWN: int = 12

const AXIS_LEFT_X: int = 0
const AXIS_LEFT_Y: int = 1
const AXIS_RIGHT_X: int = 2
const AXIS_RIGHT_Y: int = 3
const AXIS_TRIGGER_LEFT: int = 4
const AXIS_TRIGGER_RIGHT: int = 5

const DEADZONE: float = 0.2

## Couches de collision nommées (§5.7). L'index est la couche Godot (1-based).
const COLLISION_LAYERS: Array[String] = [
	"World Static",        # 1
	"Player",              # 2
	"Enemy",               # 3
	"Player Hitbox",       # 4
	"Enemy Hitbox",        # 5
	"Hurtbox",             # 6
	"Projectile",          # 7
	"Physics Prop",        # 8
	"Interactable",        # 9
	"Climb Probe",         # 10
	"Conductive",          # 11
	"Water Danger",        # 12
	"Navigation Obstacle", # 13
	"Camera Collision",    # 14
]


## Autoloads (§5.6). L'ordre compte : `GameState` et `EventBus` ne dépendent de
## rien ; `SceneFlow` manipule l'arbre et vient donc après.
const AUTOLOADS: Array = [
	["GameState", "res://scripts/core/game_state.gd"],
	["EventBus", "res://scripts/core/event_bus.gd"],
	["SaveSystem", "res://scripts/save/save_system.gd"],
	["AudioManager", "res://scripts/core/audio_manager.gd"],
	["SceneFlow", "res://scripts/core/scene_flow.gd"],
]


func _initialize() -> void:
	_write_input_map()
	_prune_unknown_actions()
	_write_collision_layers()
	_write_autoloads()
	var err: Error = ProjectSettings.save()
	if err != OK:
		printerr("[setup_project] ÉCHEC: écriture de project.godot impossible (%d)" % err)
		quit(1)
		return
	print("[setup_project] project.godot mis à jour.")
	quit(0)


func _key(physical: int) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	# `physical_keycode` : position physique, indépendante de la disposition.
	e.physical_keycode = physical
	return e


func _mouse(button: int) -> InputEventMouseButton:
	var e: InputEventMouseButton = InputEventMouseButton.new()
	e.button_index = button
	return e


func _button(index: int) -> InputEventJoypadButton:
	var e: InputEventJoypadButton = InputEventJoypadButton.new()
	e.button_index = index
	return e


func _axis(axis: int, value: float) -> InputEventJoypadMotion:
	var e: InputEventJoypadMotion = InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e


## Actions réellement déclarées par ce générateur, tenues à jour par `_set_action`.
var _declared_actions: Array[String] = []


func _set_action(action: String, events: Array) -> void:
	var typed: Array[InputEvent] = []
	for e: InputEvent in events:
		typed.append(e)
	ProjectSettings.set_setting("input/%s" % action, {
		"deadzone": DEADZONE,
		"events": typed,
	})
	if not _declared_actions.has(action):
		_declared_actions.append(action)


## Supprime toute action `input/` que ce générateur ne déclare pas.
##
## Sans cela le générateur n'était qu'additif : une action introduite à la main ou
## par un test survivait indéfiniment dans `project.godot`, sans propriétaire ni
## liaison manette. Constaté lors d'un contrôle négatif. Le générateur est la
## source de vérité de l'InputMap ; il doit donc aussi pouvoir retirer.
func _prune_unknown_actions() -> void:
	var to_remove: Array[String] = []
	for setting: Dictionary in ProjectSettings.get_property_list():
		var key: String = String(setting.get("name", ""))
		if not key.begins_with("input/"):
			continue
		var action: String = key.trim_prefix("input/")
		# Les actions `ui_*` appartiennent au moteur : ne jamais y toucher.
		if action.begins_with("ui_") or _declared_actions.has(action):
			continue
		to_remove.append(key)
	for key: String in to_remove:
		ProjectSettings.set_setting(key, null)
		print("[setup_project] action inconnue retirée : %s" % key)


func _write_input_map() -> void:
	# Déplacement — physical_keycode : W/A/S/D en QWERTY, Z/Q/S/D en AZERTY.
	_set_action("move_forward", [_key(KEY_W), _axis(AXIS_LEFT_Y, -1.0)])
	_set_action("move_left", [_key(KEY_A), _axis(AXIS_LEFT_X, -1.0)])
	_set_action("move_back", [_key(KEY_S), _axis(AXIS_LEFT_Y, 1.0)])
	_set_action("move_right", [_key(KEY_D), _axis(AXIS_LEFT_X, 1.0)])

	_set_action("jump", [_key(KEY_SPACE), _button(JOY_A)])
	_set_action("sprint", [_key(KEY_SHIFT), _button(JOY_LEFT_STICK)])
	_set_action("interact", [_key(KEY_E), _button(JOY_X)])

	_set_action("attack_light", [_mouse(MOUSE_LEFT), _button(JOY_RIGHT_SHOULDER)])
	_set_action("attack_heavy", [_key(KEY_R), _axis(AXIS_TRIGGER_RIGHT, 1.0)])
	_set_action("aim", [_mouse(MOUSE_RIGHT), _axis(AXIS_TRIGGER_LEFT, 1.0)])
	_set_action("shoot", [_mouse(MOUSE_LEFT), _axis(AXIS_TRIGGER_RIGHT, 1.0)])
	_set_action("dodge", [_key(KEY_CTRL), _button(JOY_B)])

	# INVARIANT : le lock-on ne doit JAMAIS occuper la position de `Q` (AZERTY),
	# c'est-à-dire `KEY_A` en physique — cette position est réservée à « gauche ».
	_set_action("lock_on", [_key(KEY_C), _mouse(MOUSE_MIDDLE), _button(JOY_RIGHT_STICK)])
	# §8.5 : « Cible préc./suiv. — stick D impulsion ». La bascule n'est honorée par
	# le code qu'en mode lock-on ; l'axe reste par ailleurs celui de la caméra.
	_set_action("target_prev", [_key(KEY_X), _mouse(MOUSE_WHEEL_DOWN), _axis(AXIS_RIGHT_X, -1.0)])
	_set_action("target_next", [_key(KEY_V), _mouse(MOUSE_WHEEL_UP), _axis(AXIS_RIGHT_X, 1.0)])

	# Caméra au stick droit. Le clavier n'a pas d'équivalent : la souris fournit un
	# delta d'événements, traité séparément par PlayerInputReader. Sans ces quatre
	# actions, la caméra ne serait pilotable qu'à la souris et l'architecture ne
	# serait pas réellement compatible manette (CONTROLLER-001).
	_set_action("look_left", [_axis(AXIS_RIGHT_X, -1.0)])
	_set_action("look_right", [_axis(AXIS_RIGHT_X, 1.0)])
	_set_action("look_up", [_axis(AXIS_RIGHT_Y, -1.0)])
	_set_action("look_down", [_axis(AXIS_RIGHT_Y, 1.0)])

	_set_action("inventory", [_key(KEY_TAB), _button(JOY_Y)])
	_set_action("quick_meal", [_key(KEY_F), _button(JOY_DPAD_DOWN)])
	_set_action("pause", [_key(KEY_ESCAPE), _button(JOY_START)])


func _write_collision_layers() -> void:
	for i: int in range(COLLISION_LAYERS.size()):
		ProjectSettings.set_setting(
			"layer_names/3d_physics/layer_%d" % (i + 1), COLLISION_LAYERS[i])


func _write_autoloads() -> void:
	for entry: Array in AUTOLOADS:
		var autoload_name: String = String(entry[0])
		var path: String = String(entry[1])
		if not FileAccess.file_exists(path):
			printerr("[setup_project] ÉCHEC: script d'autoload introuvable : %s" % path)
			continue
		# Le préfixe « * » active le singleton — sans lui l'autoload est déclaré
		# mais désactivé, et l'erreur ne se voit qu'à l'exécution.
		ProjectSettings.set_setting("autoload/%s" % autoload_name, "*%s" % path)
