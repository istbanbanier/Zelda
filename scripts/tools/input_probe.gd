## Sonde d'entrée — outil de validation manuelle, pas du contenu de jeu.
##
## RAISON D'ÊTRE : à la fin de la Phase A il n'existe ni joueur ni monde. Appuyer
## sur `Q` ne produit donc **rien de visible**, et le contrôle manuel exigé par
## §21.4 (« tester manette et AZERTY ») serait littéralement inexécutable.
## Cette scène rend l'InputMap observable : chaque action s'allume quand elle est
## active, et la disposition clavier réelle du système est affichée.
##
## L'affirmation « Q déplace à gauche » devient ainsi vérifiable **objectivement**,
## et pas seulement ressentie : `DisplayServer.keyboard_get_keycode_from_physical()`
## indique quelle étiquette la disposition courante donne à la position physique
## utilisée par `move_left`. Sur AZERTY, cette position doit s'appeler « Q ».
##
## Cette scène ne doit jamais être atteignable depuis le jeu : elle se lance
## explicitement (voir docs/MANUAL_VALIDATION.md).
extends Control

## Position physique liée à « gauche » (QWERTY-A). Doit s'afficher « Q » en AZERTY.
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

@onready var _layout_label: Label = %LayoutLabel
@onready var _verdict_label: Label = %VerdictLabel
@onready var _device_label: Label = %DeviceLabel
@onready var _last_input_label: Label = %LastInputLabel
@onready var _actions_grid: GridContainer = %ActionsGrid

var _action_labels: Dictionary = {}
var _last_device: String = "aucun"


func _ready() -> void:
	_build_action_rows()
	_refresh_layout_report()


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


## Interroge la disposition clavier réellement active dans le système, et non ce
## que le projet suppose. C'est le cœur de la preuve AZERTY.
func _refresh_layout_report() -> void:
	var layout_index: int = DisplayServer.keyboard_get_current_layout()
	var layout_name: String = DisplayServer.keyboard_get_layout_name(layout_index)

	# Étiquette que la disposition courante donne à la position physique liée à
	# « gauche ». AZERTY -> « Q ». QWERTY -> « A ».
	var mapped: Key = DisplayServer.keyboard_get_keycode_from_physical(LEFT_PHYSICAL_KEY)
	var mapped_name: String = OS.get_keycode_string(mapped)

	_layout_label.text = "Disposition système : %s (index %d)" % [layout_name, layout_index]

	if mapped_name == "Q":
		_verdict_label.text = "AZERTY détecté — la position liée à « gauche » s'appelle « Q ». ✔"
		_verdict_label.add_theme_color_override("font_color", COLOR_ACTIVE)
	elif mapped_name == "A":
		_verdict_label.text = ("QWERTY détecté — la position liée à « gauche » s'appelle « A ». "
			+ "Basculer le système en AZERTY pour le contrôle exigé par §21.4.")
		_verdict_label.add_theme_color_override("font_color", COLOR_IDLE)
	else:
		_verdict_label.text = ("Disposition inattendue : la position liée à « gauche » "
			+ "s'appelle « %s ». À consigner tel quel." % mapped_name)
		_verdict_label.add_theme_color_override("font_color", COLOR_IDLE)


func _process(_delta: float) -> void:
	for action: String in WATCHED_ACTIONS:
		var label: Label = _action_labels[action]
		var active: bool = InputMap.has_action(action) and Input.is_action_pressed(action)
		label.text = "ACTIF" if active else "—"
		label.add_theme_color_override("font_color", COLOR_ACTIVE if active else COLOR_IDLE)

	var pads: PackedInt32Array = Input.get_connected_joypads()
	if pads.is_empty():
		_device_label.text = "Manette : aucune détectée"
	else:
		var names: Array[String] = []
		for pad_id: int in pads:
			names.append("%d:%s" % [pad_id, Input.get_joy_name(pad_id)])
		_device_label.text = "Manette : %s" % ", ".join(names)


## Journalise la dernière entrée brute reçue : sans cela, une action qui ne
## s'allume pas laisse l'opérateur sans moyen de savoir si la touche est arrivée
## jusqu'au moteur.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event as InputEventKey
		_last_device = "clavier"
		_last_input_label.text = "Dernière touche : étiquette « %s », position physique « %s »" % [
			OS.get_keycode_string(key_event.keycode),
			OS.get_keycode_string(key_event.physical_keycode),
		]
	elif event is InputEventJoypadButton and event.pressed:
		_last_device = "manette"
		_last_input_label.text = "Dernier bouton manette : index %d" % (event as InputEventJoypadButton).button_index
	elif event is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
		if absf(motion.axis_value) > 0.5:
			_last_device = "manette"
			_last_input_label.text = "Dernier axe manette : %d = %.2f" % [motion.axis, motion.axis_value]
	elif event is InputEventMouseButton and event.pressed:
		_last_device = "souris"
		_last_input_label.text = "Dernier bouton souris : %d" % (event as InputEventMouseButton).button_index
