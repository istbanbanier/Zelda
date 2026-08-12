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
##
## LOT 9 — DÉFAUT 720p CORRIGÉ : le contenu réclamait ≈ 775 px de haut pour
## 720 de fenêtre (la table des commandes débordait sous l'écran). Trois
## leviers de compaction (marges verticales 48 → 24, séparation 6 → 3, ligne
## vide supprimée) + un `ScrollContainer` en filet dur : même si un futur
## ajout regonfle la table, rien n'est jamais hors d'atteinte. La mesure vit
## dans `content_height()` — l'intégrateur la vérifie en capture 1280×720.
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

## Marges de l'écran. Le haut/bas est plus serré que les côtés : c'est la
## HAUTEUR qui débordait à 1280×720 (contenu ≈ 775 px pour 720 de fenêtre,
## défaut consigné au LOT 9) — mesure exposée par `content_height()`.
const MARGIN_X: int = 48
const MARGIN_Y: int = 24

var _sensitivity: HSlider = null
var _invert: CheckBox = null
var _volumes: Dictionary = {}
var _columns: HBoxContainer = null
var _ui_audio: AudioStreamPlayer = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_audio = HudStyle.attach_ui_audio(self)
	_build()
	_load_values()
	# Le panneau annonce sa propre ouverture — l'appelant n'a rien à jouer.
	HudStyle.play_ui(_ui_audio, &"open")


func _build() -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "Backdrop"
	# OPAQUE. À 0,88, le menu principal transparaissait par les 12 % restants et
	# ses libellés se superposaient à la table des commandes — vu sur capture.
	backdrop.color = HudStyle.BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", MARGIN_X)
	margin.add_theme_constant_override("margin_right", MARGIN_X)
	margin.add_theme_constant_override("margin_top", MARGIN_Y)
	margin.add_theme_constant_override("margin_bottom", MARGIN_Y)
	add_child(margin)

	# FILET DE SÉCURITÉ 720p (LOT 9) : quoi que pèse le contenu, rien n'est
	# jamais hors d'atteinte — le défilement vertical prend le relais. La
	# compaction ci-dessous vise à le rendre INUTILE à 1280×720 ; le scroll
	# couvre les fenêtres encore plus petites et les ajouts futurs.
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	_columns = HBoxContainer.new()
	_columns.name = "Columns"
	_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_columns.add_theme_constant_override("separation", 32)
	scroll.add_child(_columns)

	var settings: VBoxContainer = VBoxContainer.new()
	settings.name = "Settings"
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.add_theme_constant_override("separation", 12)
	_columns.add_child(settings)
	settings.add_child(_title("Options"))
	settings.add_child(_gold_rule())

	settings.add_child(_label("Sensibilité de la souris"))
	_sensitivity = HSlider.new()
	_sensitivity.name = "SensitivitySlider"
	_sensitivity.min_value = UserSettings.MIN_MOUSE_SENSITIVITY
	_sensitivity.max_value = UserSettings.MAX_MOUSE_SENSITIVITY
	_sensitivity.step = 0.0001
	_sensitivity.custom_minimum_size = Vector2(320, 24)
	_sensitivity.value_changed.connect(_on_sensitivity)
	settings.add_child(_sensitivity)

	_invert = CheckBox.new()
	_invert.name = "InvertLook"
	_invert.text = "Inverser l'axe vertical du regard"
	_invert.add_theme_font_size_override("font_size", 18)
	_invert.add_theme_color_override(&"font_color", HudStyle.IVORY)
	_invert.toggled.connect(_on_invert)
	_invert.toggled.connect(func(_pressed: bool) -> void:
		HudStyle.play_ui(_ui_audio, &"click"))
	settings.add_child(_invert)

	for entry: Array in [["Volume général", BUS_MASTER],
			["Musique", BUS_MUSIC], ["Effets", BUS_SFX]]:
		settings.add_child(_label(String(entry[0])))
		var slider: HSlider = HSlider.new()
		slider.name = "Volume%s" % String(entry[1])
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
	close.name = "CloseButton"
	close.text = "Retour"
	close.custom_minimum_size = Vector2(200, 42)
	HudStyle.style_button(close)
	HudStyle.wire_button_feedback(close, _ui_audio)
	close.pressed.connect(func() -> void:
		HudStyle.play_ui(_ui_audio, &"back")
		closed.emit())
	settings.add_child(close)
	close.grab_focus()

	var keys: VBoxContainer = VBoxContainer.new()
	keys.name = "Keys"
	keys.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 6 → 3 px : à dix-neuf lignes, chaque pixel de séparation pèse. C'est un
	# des trois leviers de la correction 720p (avec MARGIN_Y et la ligne vide
	# supprimée) — la table reste aérée par la hauteur propre des cartouches.
	keys.add_theme_constant_override("separation", 3)
	_columns.add_child(keys)
	keys.add_child(_title("Commandes (AZERTY)"))
	keys.add_child(_gold_rule())
	for row: Array in CONTROLS:
		var line: HBoxContainer = HBoxContainer.new()
		var what: Label = _label(String(row[0]))
		what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(what)
		line.add_child(_key_chip(String(row[1])))
		keys.add_child(line)
	var note: Label = _label("Manette prise en charge.")
	note.add_theme_color_override(&"font_color", HudStyle.IVORY_MUTED)
	keys.add_child(note)


func _title(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	HudStyle.style_heading(label, 28)
	return label


func _label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	return label


## Filet d'or sous un titre — la signature des plaques, sans image.
func _gold_rule() -> ColorRect:
	var rule: ColorRect = ColorRect.new()
	rule.color = Color(HudStyle.GOLD.r, HudStyle.GOLD.g, HudStyle.GOLD.b, 0.55)
	rule.custom_minimum_size = Vector2(0, 1)
	return rule


## Cartouche de touche : le même langage que l'invite « E — … » du HUD.
## Police 16 et marges réduites : dix-neuf cartouches doivent tenir sous 720 px.
func _key_chip(text: String) -> PanelContainer:
	var chip: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = HudStyle.chip()
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	chip.add_theme_stylebox_override(&"panel", style)
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	chip.add_child(label)
	return chip


## --- Seams de mesure (défaut 720p du LOT 9) --------------------------------

## Hauteur minimale réellement demandée par le contenu, marges comprises.
## C'est LA mesure du débordement : avant correction ≈ 775 px ; l'intégrateur
## la relit en capture à 1280×720 pour prouver `content_height() <= 720`.
func content_height() -> float:
	if _columns == null:
		return 0.0
	return _columns.get_combined_minimum_size().y + float(MARGIN_Y) * 2.0


func fits_height(viewport_height: float) -> bool:
	return content_height() <= viewport_height


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
