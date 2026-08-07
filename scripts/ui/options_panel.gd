## ÉCRAN D'OPTIONS — construit après un playtest en boîte noire.
##
## Verbatim du joueur qui découvrait le jeu, devant le menu principal :
## « Options est grisé, donc je n'ai ni sensibilité souris, ni volume, ni
## rappel des touches : je pars à l'aveugle ». §12.3 les exige, et elles se
## règlent AVANT de jouer.
##
## Ce panneau ne promet que ce qu'il tient. Il expose quatre réglages qui ont
## un effet réel et vérifiable, plus le rappel des commandes :
##
##   * sensibilité de la souris — lue par `PlayerInputReader` ;
##   * inversion de l'axe vertical — lue par `CameraRig` ;
##   * volumes général, musique et effets — appliqués par `AudioManager` ;
##   * la table des commandes, que le joueur n'avait nulle part.
##
## Ce qu'il n'expose PAS, et pourquoi : le remappage complet, l'aide à la
## visée, les curseurs de flash et de secousse, les modes daltoniens. Ces
## réglages n'ont pas encore de système derrière eux ; les afficher grisés
## reproduirait exactement le défaut qu'on corrige — présenter comme
## disponible ce qui ne l'est pas (§0.2).
##
## Tout est construit en code : une scène `.tscn` de plus rendrait la revue
## plus difficile, et ce panneau n'a pas de mise en page à préserver.
class_name OptionsPanel
extends Control

signal closed

const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"

## Rappel des commandes. AZERTY d'abord : `Q` est à gauche, jamais le
## verrouillage (invariant du projet).
const CONTROLS: Array[Array] = [
	["Se déplacer", "Z Q S D"],
	["Sauter", "Espace"],
	["Sprinter", "Maj gauche"],
	["Interagir", "E"],
	["Attaque légère", "Clic gauche"],
	["Attaque lourde", "R"],
	["Viser puis tirer", "Clic droit, puis clic gauche"],
	["Esquiver", "Ctrl gauche"],
	["Verrouiller une cible", "C ou clic molette"],
	["Inventaire", "Tab"],
	["Plat rapide", "F"],
	# Le Bracelet de Résonance est la mécanique SIGNATURE du jeu, et ses
	# touches n'étaient listées nulle part : ni ici, ni dans une notification,
	# ni dans un tutoriel. Les actions sont câblées et fonctionnelles depuis
	# longtemps (`player_controller.gd`) — un joueur ne pouvait simplement pas
	# apprendre qu'elles existent, donc arrivait au donjon sans savoir qu'il
	# possède la moitié de son propre jeu.
	["Bracelet — onde de détection", "A"],
	["Bracelet — viser une cible", "G (maintenu)"],
	["Bracelet — agir sur la cible visée", "G + clic gauche"],
	["Bracelet — repousser au lieu d'attirer", "G + Maj + clic gauche"],
	["Bracelet — mise à la terre", "T"],
	["Cible précédente / suivante", "X / V"],
	["Pause", "Échap"],
]

var _sensitivity: HSlider = null
var _invert: CheckBox = null
var _volumes: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	_load_values()


func _build() -> void:
	var backdrop: ColorRect = ColorRect.new()
	# OPAQUE. À 0,88, le menu principal transparaissait par les 12 % restants et
	# ses libellés se superposaient à la table des commandes — vu sur capture.
	backdrop.color = Color(0.05, 0.06, 0.09, 1.0)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 48)
	add_child(margin)

	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 48)
	margin.add_child(columns)

	var settings: VBoxContainer = VBoxContainer.new()
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.add_theme_constant_override("separation", 14)
	columns.add_child(settings)
	settings.add_child(_title("Options"))

	settings.add_child(_label("Sensibilité de la souris"))
	_sensitivity = HSlider.new()
	_sensitivity.min_value = UserSettings.MIN_MOUSE_SENSITIVITY
	_sensitivity.max_value = UserSettings.MAX_MOUSE_SENSITIVITY
	_sensitivity.step = 0.0001
	_sensitivity.custom_minimum_size = Vector2(320, 24)
	_sensitivity.value_changed.connect(_on_sensitivity)
	settings.add_child(_sensitivity)

	_invert = CheckBox.new()
	_invert.text = "Inverser l'axe vertical du regard"
	_invert.toggled.connect(_on_invert)
	settings.add_child(_invert)

	for entry: Array in [["Volume général", BUS_MASTER],
			["Musique", BUS_MUSIC], ["Effets", BUS_SFX]]:
		settings.add_child(_label(String(entry[0])))
		var slider: HSlider = HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.custom_minimum_size = Vector2(320, 24)
		var bus: String = String(entry[1])
		slider.value_changed.connect(func(value: float) -> void:
			_on_volume(bus, value))
		settings.add_child(slider)
		_volumes[bus] = slider

	var close: Button = Button.new()
	close.text = "Retour"
	close.custom_minimum_size = Vector2(160, 40)
	close.pressed.connect(func() -> void: closed.emit())
	settings.add_child(close)
	close.grab_focus()

	var keys: VBoxContainer = VBoxContainer.new()
	keys.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keys.add_theme_constant_override("separation", 6)
	columns.add_child(keys)
	keys.add_child(_title("Commandes (AZERTY)"))
	for row: Array in CONTROLS:
		var line: HBoxContainer = HBoxContainer.new()
		var what: Label = _label(String(row[0]))
		what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(what)
		line.add_child(_label(String(row[1])))
		keys.add_child(line)
	keys.add_child(_label(""))
	keys.add_child(_label("Manette prise en charge."))


func _title(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	return label


func _label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	return label


func _load_values() -> void:
	_sensitivity.set_value_no_signal(UserSettings.load_mouse_sensitivity())
	_invert.set_pressed_no_signal(UserSettings.load_invert_look_y())
	for bus: String in _volumes:
		var slider: HSlider = _volumes[bus]
		slider.set_value_no_signal(UserSettings.load_volume(bus))


func _on_sensitivity(value: float) -> void:
	UserSettings.save_mouse_sensitivity(value)
	# Effet IMMÉDIAT si une partie est en cours : un réglage qui n'agit qu'au
	# prochain lancement se règle à l'aveugle.
	for node: Node in get_tree().get_nodes_in_group("player"):
		var reader: Node = node.get_node_or_null("PlayerInputReader")
		if reader != null and reader.has_method("set_mouse_sensitivity"):
			reader.call("set_mouse_sensitivity", value)


func _on_invert(pressed: bool) -> void:
	UserSettings.save_invert_look_y(pressed)
	for node: Node in get_tree().get_nodes_in_group("player"):
		var rig: Node = node.find_child("CameraRig", true, false)
		if rig != null:
			rig.set("invert_look_y", pressed)


func _on_volume(bus: String, value: float) -> void:
	UserSettings.save_volume(bus, value)
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("set_volume"):
		audio.call("set_volume", bus, value)
