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
const VALLEY_SCENE: String = "res://scenes/world/valley/ValleyWorld.tscn"

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _debug_audit_button: Button = %DebugAuditButton

var _options_panel: OptionsPanel = null
var _options_layer: CanvasLayer = null
## Éléments du menu masqués pendant les options, restaurés à la fermeture.
var _hidden_behind: Array[CanvasItem] = []
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

	# §18.2 : la navigation s'entend — un tic au déplacement du focus, un toc
	# à la validation. Bus UI, jamais SFX : les curseurs de volume restent vrais.
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio != null:
		for button: Button in [_continue_button, _new_game_button,
				_options_button, _quit_button, _debug_audit_button]:
			button.focus_entered.connect(
				func() -> void: audio.call("play_sfx", &"ui_move", "UI"))
			button.pressed.connect(
				func() -> void: audio.call("play_sfx", &"ui_accept", "UI"))

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

	# Les options EXISTENT désormais (§12.3) : sensibilité, inversion du regard,
	# trois volumes et le rappel des commandes. Le bouton cesse d'être grisé —
	# un playtest en boîte noire avait relevé qu'on partait jouer sans savoir
	# quelles touches existaient.
	_options_button.disabled = false
	_options_button.tooltip_text = "Sensibilité, regard, volumes, commandes"

	# §6.1 : l'outillage de debug est absent du build final. `OS.is_debug_build()`
	# est faux dans un export release ; l'entrée disparaît alors entièrement de
	# l'arbre de focus, elle n'est pas seulement grisée.
	# Une garde par `OS.is_debug_build()` NE SUFFIT PAS : le projet se livre en
	# archive à ouvrir dans Godot, donc le joueur lance un build de debug et
	# voyait « Debug — Audit d'entrée » dans son menu principal. Un playtest en
	# boîte noire l'a relevé comme premier signal de « ce n'est pas un jeu ».
	# L'entrée demande maintenant une intention EXPLICITE.
	var debug_build: bool = OS.is_debug_build() \
		and OS.get_environment("ECLATS_DEBUG_MENU") == "1"
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
	# D.1R.5 : la vallée applique elle-même la sauvegarde à son chargement —
	# inventaire, durabilités, arme équipée, flèches, coffres ouverts. Point de
	# reprise documenté : le spawn de la crête (checkpoints riches : Phase E).
	_enter_valley()


func _enter_valley() -> void:
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow == null or not bool(flow.call("can_go_to", VALLEY_SCENE)):
		_status_label.text = "Vallée indisponible — voir le journal."
		return
	flow.call("go_to", VALLEY_SCENE)


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
	# Rafraîchir AVANT de partir : si la transition échoue (flux occupé, scène
	# absente), le menu reste cohérent — « Continuer » reflète la sauvegarde.
	_refresh()
	_wire_focus_cycle()
	_enter_valley()


## Contenu minimal et honnête d'une partie neuve : ce que la Phase A sait déjà
## représenter. Le schéma complet (§19.1) arrive avec les systèmes concernés.
func _new_game_payload() -> Dictionary:
	return {
		"schema": 2,
		"checkpoint": "valley.camp.start",
		"playtime_seconds": 0.0,
		"boss_defeated": false,
	}


func _on_options() -> void:
	if _options_panel != null and is_instance_valid(_options_panel):
		return
	# Une COUCHE au-dessus, pas un simple enfant : la première pose laissait
	# les boutons du menu transparaître à travers le panneau, parce qu'ils
	# vivent dans un `CanvasLayer` qui gagne sur l'ordre d'arbre.
	# Le menu se RETIRE pendant les options. Une couche au-dessus ne suffisait
	# pas — vu sur capture, ses libellés se superposaient encore à la table des
	# commandes. Masquer ce qui n'est plus actif est de toute façon plus juste :
	# le menu ne doit pas rester navigable derrière un panneau modal.
	for child: Node in get_children():
		var visual: CanvasItem = child as CanvasItem
		if visual != null:
			_hidden_behind.append(visual)
			visual.visible = false
	_options_layer = CanvasLayer.new()
	_options_layer.name = "OptionsLayer"
	_options_layer.layer = 20
	add_child(_options_layer)
	_options_panel = OptionsPanel.new()
	_options_panel.name = "OptionsPanel"
	_options_panel.closed.connect(_on_options_closed)
	_options_layer.add_child(_options_panel)


func _on_options_closed() -> void:
	if _options_layer != null and is_instance_valid(_options_layer):
		_options_layer.queue_free()
	_options_layer = null
	for visual: CanvasItem in _hidden_behind:
		if is_instance_valid(visual):
			visual.visible = true
	_hidden_behind.clear()
	_options_panel = null
	_focus_first_available()


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
