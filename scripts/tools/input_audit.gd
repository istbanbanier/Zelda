## Audit d'entrée — outil de validation manuelle, jamais du contenu de jeu.
##
## RAISON D'ÊTRE : à la fin de la Phase A il n'existe ni joueur ni monde. Appuyer
## sur `Q` ne produit donc **rien de visible**, et le contrôle manuel exigé par
## §21.4 (« tester manette et AZERTY ») serait littéralement inexécutable.
##
## Cette scène rend l'InputMap observable et rend l'invariant central **objectif
## plutôt que ressenti** : `DisplayServer.keyboard_get_keycode_from_physical()`
## indique quelle étiquette la disposition **système** donne à la position physique
## liée à `move_left`. Sur AZERTY, cette position doit s'appeler « Q ».
##
## Deux verdicts sont **verrouillés** dès qu'ils sont observés, pour qu'une simple
## capture d'écran suffise comme preuve :
##   1. « Q » déclenche bien `move_left` ;
##   2. « Q » ne déclenche **jamais** `lock_on` (interdit explicite de §8.5). Ce
##      second verdict est irréversible en cas d'échec : une fois violé il reste
##      affiché en échec jusqu'à la fermeture, pour qu'un appui malheureux ne
##      puisse pas être effacé par un appui suivant.
##
## §6.1 : outil de développement. Atteignable seulement par l'entrée debug du
## menu, elle-même absente d'un build final (`OS.is_debug_build()`).
extends Control

## Position physique liée à « gauche » (QWERTY-A). S'affiche « Q » en AZERTY.
const LEFT_PHYSICAL_KEY: Key = KEY_A

const WATCHED_ACTIONS: Array[String] = [
	"move_forward", "move_left", "move_back", "move_right",
	"jump", "sprint", "interact",
	"attack_light", "attack_heavy", "aim", "shoot", "dodge",
	"lock_on", "target_prev", "target_next",
	"inventory", "quick_meal", "pause",
]

const COLOR_IDLE: Color = Color(0.62, 0.66, 0.72)
const COLOR_ACTIVE: Color = Color(0.13, 0.85, 0.92)
const COLOR_PASS: Color = Color(0.40, 0.85, 0.45)
const COLOR_FAIL: Color = Color(0.95, 0.35, 0.35)

@onready var _layout_label: Label = %LayoutLabel
@onready var _verdict_label: Label = %VerdictLabel
@onready var _device_label: Label = %DeviceLabel
@onready var _last_input_label: Label = %LastInputLabel
@onready var _q_left_label: Label = %QLeftLabel
@onready var _q_lock_label: Label = %QLockLabel
@onready var _actions_grid: GridContainer = %ActionsGrid

var _action_labels: Dictionary = {}
var _active_device: String = "aucun"

var _q_triggered_move_left: bool = false
var _q_ever_triggered_lock_on: bool = false
var _q_currently_held: bool = false


func _ready() -> void:
	_build_action_rows()
	_report_layout()
	_refresh_verdicts()


func _build_action_rows() -> void:
	for action: String in WATCHED_ACTIONS:
		var name_label: Label = Label.new()
		name_label.text = action
		_actions_grid.add_child(name_label)

		var state_label: Label = Label.new()
		state_label.text = "—"
		state_label.add_theme_color_override("font_color", COLOR_IDLE)
		_actions_grid.add_child(state_label)
		_action_labels[action] = state_label


## Interroge la disposition réellement active dans le système, et non ce que le
## projet suppose. C'est le cœur de la preuve AZERTY.
func _report_layout() -> void:
	var index: int = DisplayServer.keyboard_get_current_layout()
	var layout_name: String = DisplayServer.keyboard_get_layout_name(index)
	var mapped: Key = DisplayServer.keyboard_get_keycode_from_physical(LEFT_PHYSICAL_KEY)
	var mapped_name: String = OS.get_keycode_string(mapped)

	_layout_label.text = "Disposition système : %s   |   position de « gauche » = touche « %s »" % [
		layout_name, mapped_name,
	]

	if mapped_name == "Q":
		_verdict_label.text = "AZERTY confirmé : la position liée à « gauche » porte l'étiquette « Q »."
		_verdict_label.add_theme_color_override("font_color", COLOR_PASS)
	elif mapped_name == "A":
		_verdict_label.text = ("QWERTY détecté : cette position porte « A ». Basculer le système "
			+ "en AZERTY (français) avant le contrôle exigé par §21.4.")
		_verdict_label.add_theme_color_override("font_color", COLOR_FAIL)
	else:
		_verdict_label.text = ("Disposition inattendue : cette position porte « %s ». "
			% mapped_name + "À consigner tel quel dans le rapport.")
		_verdict_label.add_theme_color_override("font_color", COLOR_FAIL)


func _process(_delta: float) -> void:
	for action: String in WATCHED_ACTIONS:
		var label: Label = _action_labels[action]
		var active: bool = InputMap.has_action(action) and Input.is_action_pressed(action)
		label.text = "ACTIF" if active else "—"
		label.add_theme_color_override("font_color", COLOR_ACTIVE if active else COLOR_IDLE)

	# Corrélation faite pendant que la touche est maintenue : c'est le seul moment
	# où l'on peut affirmer que c'est bien « Q » qui déclenche l'action observée.
	if _q_currently_held:
		if Input.is_action_pressed("move_left"):
			_q_triggered_move_left = true
		if Input.is_action_pressed("lock_on"):
			_q_ever_triggered_lock_on = true
		_refresh_verdicts()

	var pads: PackedInt32Array = Input.get_connected_joypads()
	if pads.is_empty():
		_device_label.text = "Périphérique actif : %s   |   Manette : aucune détectée" % _active_device
	else:
		var names: Array[String] = []
		for pad_id: int in pads:
			names.append("%d:%s" % [pad_id, Input.get_joy_name(pad_id)])
		_device_label.text = "Périphérique actif : %s   |   Manette : %s" % [
			_active_device, ", ".join(names),
		]


func _refresh_verdicts() -> void:
	if _q_triggered_move_left:
		_q_left_label.text = "1. « Q » déclenche move_left : CONFIRMÉ"
		_q_left_label.add_theme_color_override("font_color", COLOR_PASS)
	else:
		_q_left_label.text = "1. « Q » déclenche move_left : en attente — maintenir « Q »"
		_q_left_label.add_theme_color_override("font_color", COLOR_IDLE)

	if _q_ever_triggered_lock_on:
		_q_lock_label.text = "2. « Q » n'active jamais lock_on : ÉCHEC — violation observée"
		_q_lock_label.add_theme_color_override("font_color", COLOR_FAIL)
	elif _q_triggered_move_left:
		_q_lock_label.text = "2. « Q » n'active jamais lock_on : CONFIRMÉ sur les appuis observés"
		_q_lock_label.add_theme_color_override("font_color", COLOR_PASS)
	else:
		_q_lock_label.text = "2. « Q » n'active jamais lock_on : en attente d'un appui sur « Q »"
		_q_lock_label.add_theme_color_override("font_color", COLOR_IDLE)


## Journalise l'entrée brute : sans cela, une action qui ne s'allume pas laisse
## l'opérateur sans moyen de savoir si la touche est arrivée jusqu'au moteur.
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		var label_name: String = OS.get_keycode_string(
			DisplayServer.keyboard_get_keycode_from_physical(key_event.physical_keycode))

		# « Q » est identifié par l'étiquette que lui donne la disposition
		# courante, jamais par un code en dur : c'est bien la touche marquée Q
		# sous les doigts de l'opérateur qui compte.
		if label_name == "Q":
			_q_currently_held = key_event.pressed

		if key_event.pressed and not key_event.echo:
			_active_device = "clavier"
			_last_input_label.text = ("Dernière touche — position physique : « %s »   |   "
				% OS.get_keycode_string(key_event.physical_keycode)
				+ "étiquette dans cette disposition : « %s »   |   keycode brut : %d"
				% [label_name, key_event.keycode])
	elif event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed:
		_active_device = "manette"
		_last_input_label.text = ("Dernier bouton manette : index %d"
			% (event as InputEventJoypadButton).button_index)
	elif event is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
		if absf(motion.axis_value) > 0.5:
			_active_device = "manette"
			_last_input_label.text = "Dernier axe manette : axe %d = %.2f" % [motion.axis, motion.axis_value]
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_active_device = "souris"
		_last_input_label.text = ("Dernier bouton souris : index %d"
			% (event as InputEventMouseButton).button_index)


## Retour au menu par Échap. On utilise `ui_cancel` et non l'action `pause` :
## celle-ci fait partie des liaisons à tester, elle ne doit pas fermer la scène.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var flow: Node = get_node_or_null("/root/SceneFlow")
		if flow != null:
			flow.call("go_to", "res://scenes/ui/MainMenu.tscn")
		get_viewport().set_input_as_handled()
