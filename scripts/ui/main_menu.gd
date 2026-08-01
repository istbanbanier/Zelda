## Menu principal (MASTER_SPEC §17.3).
##
## Exigences tenues ici : navigation complète clavier **et** manette, focus
## visible, **aucun piège de focus** (la liste boucle), et confirmation avant
## d'écraser une sauvegarde.
##
## ÉTAT PHASE A, dit sans détour : il n'existe aucun monde à charger. « Continuer »
## et « Nouvelle partie » agissent donc réellement sur la sauvegarde et sur l'état
## de jeu, puis affichent que la vallée arrive en Phase D. Le menu ne simule pas
## une transition vers une scène qui n'existe pas — ce serait un faux progrès.
extends Control

const DEFAULT_SLOT: String = "slot0"
const INPUT_AUDIT_SCENE: String = "res://scenes/tests/InputAudit.tscn"

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _debug_audit_button: Button = %DebugAuditButton
@onready var _status_label: Label = %StatusLabel

var _save_system: Node = null
var _game_state: Node = null
var _confirming_overwrite: bool = false


func _ready() -> void:
	_save_system = get_node_or_null("/root/SaveSystem")
	_game_state = get_node_or_null("/root/GameState")

	_continue_button.pressed.connect(_on_continue)
	_new_game_button.pressed.connect(_on_new_game)
	_options_button.pressed.connect(_on_options)
	_quit_button.pressed.connect(_on_quit)
	_debug_audit_button.pressed.connect(_on_debug_audit)

	_refresh()
	_wire_focus_cycle()
	_focus_first_available()


## Recalcule ce qui est réellement disponible. Appelé aussi après une sauvegarde
## pour que « Continuer » cesse d'être grisé sans recharger la scène.
func _refresh() -> void:
	var has_save: bool = _save_system != null and bool(_save_system.call("has_save", DEFAULT_SLOT))
	_continue_button.disabled = not has_save
	if not has_save:
		_continue_button.tooltip_text = "Aucune sauvegarde"

	# §0.2 : ne pas présenter comme disponible ce qui ne l'est pas.
	_options_button.disabled = true
	_options_button.tooltip_text = "Options : Phase I"

	# §6.1 : l'outillage de debug est absent du build final. `OS.is_debug_build()`
	# est faux dans un export release ; l'entrée disparaît alors entièrement de
	# l'arbre de focus, elle n'est pas seulement grisée.
	var debug_build: bool = OS.is_debug_build()
	_debug_audit_button.visible = debug_build
	_debug_audit_button.disabled = not debug_build


## §17.3 : « pas de piège de focus ». Les voisins sont câblés explicitement en
## cycle plutôt que laissés à la détection géométrique, qui saute les boutons
## désactivés et peut laisser le focus sans issue.
func _wire_focus_cycle() -> void:
	var order: Array[Button] = [
		_continue_button, _new_game_button, _options_button,
		_debug_audit_button, _quit_button,
	]
	var usable: Array[Button] = []
	for button: Button in order:
		var reachable: bool = not button.disabled and button.visible
		button.focus_mode = Control.FOCUS_ALL if reachable else Control.FOCUS_NONE
		if reachable:
			usable.append(button)
	for i: int in range(usable.size()):
		var current: Button = usable[i]
		var previous: Button = usable[(i - 1 + usable.size()) % usable.size()]
		var next: Button = usable[(i + 1) % usable.size()]
		current.focus_neighbor_top = current.get_path_to(previous)
		current.focus_neighbor_bottom = current.get_path_to(next)
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(next)


func _focus_first_available() -> void:
	for button: Button in [_continue_button, _new_game_button, _options_button,
			_debug_audit_button, _quit_button]:
		if not button.disabled and button.visible:
			button.grab_focus()
			return


func _on_continue() -> void:
	if _save_system == null:
		return
	var data: Dictionary = _save_system.call("load_slot", DEFAULT_SLOT)
	if data.is_empty():
		_status_label.text = "Sauvegarde illisible — voir le journal."
		return
	_status_label.text = "Sauvegarde chargée. Le monde à charger arrive en Phase D."


## §17.3 : confirmation avant écrasement d'une sauvegarde. Deux appuis successifs
## plutôt qu'une boîte de dialogue, qui viendra avec le thème complet.
func _on_new_game() -> void:
	if _save_system == null:
		return
	var has_save: bool = bool(_save_system.call("has_save", DEFAULT_SLOT))
	if has_save and not _confirming_overwrite:
		_confirming_overwrite = true
		_new_game_button.text = "Écraser la sauvegarde ?"
		_status_label.text = "Appuyer à nouveau pour confirmer."
		return

	_confirming_overwrite = false
	_new_game_button.text = "Nouvelle partie"
	var created: bool = bool(_save_system.call("save_slot", DEFAULT_SLOT, _new_game_payload()))
	if not created:
		_status_label.text = "Échec de création de la sauvegarde — voir le journal."
		return
	if _game_state != null:
		_game_state.call("set_difficulty", 1)  # Difficulty.STANDARD
	_refresh()
	_wire_focus_cycle()
	_status_label.text = "Nouvelle partie créée. La vallée arrive en Phase D."


## Contenu minimal et honnête d'une partie neuve : ce que la Phase A sait déjà
## représenter. Le schéma complet (§19.1) arrive avec les systèmes concernés.
func _new_game_payload() -> Dictionary:
	return {
		"checkpoint": "valley.camp.start",
		"playtime_seconds": 0.0,
		"boss_defeated": false,
	}


func _on_options() -> void:
	_status_label.text = "Options : Phase I."


## Entrée de debug (§6.1). Refuse d'agir hors build de développement, même si le
## bouton était rendu visible par erreur : la garde est dans le comportement, pas
## seulement dans l'affichage.
func _on_debug_audit() -> void:
	if not OS.is_debug_build():
		return
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow == null or not bool(flow.call("can_go_to", INPUT_AUDIT_SCENE)):
		_status_label.text = "Scène d'audit indisponible."
		return
	flow.call("go_to", INPUT_AUDIT_SCENE)


func _on_quit() -> void:
	get_tree().quit(0)
