## Coquille de gameplay — capture souris, pause, réglages (PT-D1-01/-11).
##
## Instanciée dans chaque scène JOUABLE (vallée, intérieurs) : elle capture la
## souris à l'entrée, ouvre le menu pause sur l'action `pause`, et porte le
## réglage de sensibilité persisté (`UserSettings`).
##
## `process_mode = ALWAYS` : la coquille reste vivante quand l'arbre est en
## pause — c'est elle qui suspend et reprend le monde. Le gameplay, lui, est
## `PAUSABLE` par défaut et gèle réellement.
##
## LIMITE MESURÉE : en headless, le serveur d'affichage refuse
## `MOUSE_MODE_CAPTURED` (relu : VISIBLE). L'état VOULU est donc exposé
## (`wants_mouse_captured()`) et testé ; la capture effective se vérifie sur un
## poste avec écran — c'est l'objet du playtest.
class_name GameplayShell
extends CanvasLayer

signal pause_toggled(paused: bool)

@onready var _pause_panel: Control = %PausePanel
@onready var _resume_button: Button = %ResumeButton
@onready var _sensitivity_slider: HSlider = %SensitivitySlider
@onready var _sensitivity_value: Label = %SensitivityValue
@onready var _quit_button: Button = %QuitButton

var _mouse_captured_wanted: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_panel.visible = false
	_resume_button.pressed.connect(_on_resume)
	_quit_button.pressed.connect(_on_quit_to_menu)
	_sensitivity_slider.min_value = UserSettings.MIN_MOUSE_SENSITIVITY
	_sensitivity_slider.max_value = UserSettings.MAX_MOUSE_SENSITIVITY
	_sensitivity_slider.step = 0.0001
	_sensitivity_slider.value = UserSettings.load_mouse_sensitivity()
	_sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	_refresh_sensitivity_label(_sensitivity_slider.value)
	_set_mouse_captured(true)


func _notification(what: int) -> void:
	# Reprise de focus : ré-appliquer l'état voulu — perdre puis reprendre le
	# focus ne doit jamais laisser une caméra morte (PT-D1-02).
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_apply_mouse_mode()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause", false, true):
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	# Clic dans la fenêtre pendant le jeu : recapture (curseur échappé par
	# alt-tab, par exemple).
	if not is_paused() and _mouse_captured_wanted \
			and event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_apply_mouse_mode()


## ---------------------------------------------------------------------------
## Pause
## ---------------------------------------------------------------------------

func toggle_pause() -> void:
	if is_paused():
		_on_resume()
	else:
		_open_pause()


func is_paused() -> bool:
	return get_tree().paused


func _open_pause() -> void:
	get_tree().paused = true
	_pause_panel.visible = true
	_set_mouse_captured(false)
	_resume_button.grab_focus()
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_paused", true)
	pause_toggled.emit(true)


func _on_resume() -> void:
	get_tree().paused = false
	_pause_panel.visible = false
	_set_mouse_captured(true)
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_paused", false)
	pause_toggled.emit(false)


func _on_quit_to_menu() -> void:
	# Dépauser AVANT la transition : SceneFlow gère sa propre pause de fondu.
	get_tree().paused = false
	_set_mouse_captured(false)
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow != null and bool(flow.call("can_go_to", "res://scenes/ui/MainMenu.tscn")):
		flow.call("go_to", "res://scenes/ui/MainMenu.tscn")


## ---------------------------------------------------------------------------
## Souris et sensibilité
## ---------------------------------------------------------------------------

func wants_mouse_captured() -> bool:
	return _mouse_captured_wanted


func _set_mouse_captured(captured: bool) -> void:
	_mouse_captured_wanted = captured
	_apply_mouse_mode()


func _apply_mouse_mode() -> void:
	if _mouse_captured_wanted and not get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_sensitivity_changed(value: float) -> void:
	UserSettings.save_mouse_sensitivity(value)
	_refresh_sensitivity_label(value)
	for node: Node in get_tree().get_nodes_in_group("player"):
		var player: PlayerController = node as PlayerController
		if player != null:
			var reader: PlayerInputReader = \
				player.get_node_or_null("Components/PlayerInputReader") as PlayerInputReader
			if reader != null:
				reader.set_mouse_sensitivity(value)


func _refresh_sensitivity_label(value: float) -> void:
	_sensitivity_value.text = "%.4f rad/px" % value


## Seam de test : applique une valeur comme si le curseur avait bougé.
func set_sensitivity(value: float) -> void:
	_sensitivity_slider.value = UserSettings.clamp_sensitivity(value)
