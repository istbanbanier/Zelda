## Menu principal (MASTER_SPEC §17.3).
##
## Exigences tenues ici : navigation complète clavier **et** manette, focus
## visible, **aucun piège de focus** (la liste boucle), et confirmation avant
## d'écraser une sauvegarde.
##
## CHECKPOINT WORLD V2 : « Continuer » et « Nouvelle partie » ouvrent désormais
## la reconstruction jouable. La vallée V1 reste dans le dépôt comme référence
## de régression, mais n'est plus la destination du joueur depuis le menu.
extends Control

const DEFAULT_SLOT: String = "slot0"
const INPUT_AUDIT_SCENE: String = "res://scenes/tests/InputAudit.tscn"
const WORLD_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
## Terrain d'entraînement (playtest) : les cinq épreuves du Bracelet côte à
## côte, avec leurs panneaux. Atteignable depuis le MENU — livré d'abord comme
## une scène à lancer en ligne de commande, donc invisible pour qui joue
## normalement.
const TRAINING_SCENE: String = "res://scenes/world/TrainingGrounds.tscn"

## T1 — OÙ ROUVRIR LA PARTIE. La chaîne compte six scènes jouables ; la
## sauvegarde disait déjà laquelle, et personne ne la lisait : `_on_continue()`
## chargeait le slot, vérifiait qu'il était lisible, puis ouvrait le monde
## ouvert quoi qu'il arrive. Un joueur arrêté dans l'antichambre du boss
## refaisait tout le donjon à chaque reprise.
##
## AUCUN CHAMP NOUVEAU. Le tag `checkpoint` existe depuis toujours et le donjon
## l'écrit déjà (`antechamber.gd` pose `dungeon.antechamber`) ; `boss_arena.gd`
## sait déjà que ce tag désigne cette scène. Poser un second champ « scène de
## reprise » à côté d'un champ qui existe est la façon la plus sûre de les
## faire diverger.
const REPRISE_PAR_CHECKPOINT: Dictionary = {
	"dungeon.antechamber": "res://scenes/dungeon/rooms/Antechamber.tscn",
}

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _training_button: Button = %TrainingButton
@onready var _debug_audit_button: Button = %DebugAuditButton

var _options_panel: OptionsPanel = null
var _options_layer: CanvasLayer = null
## Éléments du menu masqués pendant les options, restaurés à la fermeture.
var _hidden_behind: Array[CanvasItem] = []
@onready var _status_label: Label = %StatusLabel

var _save_system: Node = null
var _game_state: Node = null
var _confirming_overwrite: bool = false
var _ui_audio: AudioStreamPlayer = null


func _ready() -> void:
	_save_system = get_node_or_null("/root/SaveSystem")
	_game_state = get_node_or_null("/root/GameState")

	_continue_button.pressed.connect(_on_continue)
	_new_game_button.pressed.connect(_on_new_game)
	_options_button.pressed.connect(_on_options)
	_quit_button.pressed.connect(_on_quit)
	_training_button.pressed.connect(_on_training)
	_debug_audit_button.pressed.connect(_on_debug_audit)

	# §18.2 : la navigation s'entend — un tic au déplacement du focus, un clic
	# à la validation. Sons d'interface promus (Kenney, CC0) sur le bus UI,
	# jamais SFX : les curseurs de volume restent vrais. Le survol souris DONNE
	# le focus : un seul état « courant », identique au clavier et à la souris.
	_ui_audio = HudStyle.attach_ui_audio(self)
	for button: Button in [_continue_button, _new_game_button, _options_button,
			_training_button, _debug_audit_button, _quit_button]:
		HudStyle.style_button(button)
		HudStyle.wire_button_feedback(button, _ui_audio)

	_apply_style()
	_refresh()
	_wire_focus_cycle()
	_focus_first_available()


## Hiérarchie typographique du LOT 9 : le titre domine (or pâle), le sous-titre
## seconde (ivoire estompé), l'état parle en ivoire. Les tailles vivent dans la
## scène ; les couleurs viennent TOUTES de HudStyle — aucune valeur dupliquée.
func _apply_style() -> void:
	var title: Label = get_node_or_null("Layout/Column/Title") as Label
	if title != null:
		title.add_theme_color_override(&"font_color", HudStyle.GOLD)
	var subtitle: Label = get_node_or_null("Layout/Column/Subtitle") as Label
	if subtitle != null:
		subtitle.add_theme_color_override(&"font_color", HudStyle.IVORY_MUTED)
	_status_label.add_theme_color_override(&"font_color", HudStyle.IVORY)


## Un échec dit son nom ET se fait entendre — jamais la couleur seule (§17.4).
func _show_error(text: String) -> void:
	_status_label.text = text
	HudStyle.play_ui(_ui_audio, &"error")


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
	_options_button.tooltip_text = Textes.t("menu.options.sous_titre")

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
		_training_button, _debug_audit_button, _quit_button,
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
			_training_button,
			_debug_audit_button, _quit_button]:
		if not button.disabled and button.visible:
			button.grab_focus()
			return


func _on_continue() -> void:
	if _save_system == null:
		return
	var data: Dictionary = _save_system.call("load_slot", DEFAULT_SLOT)
	if data.is_empty():
		_show_error("Sauvegarde illisible — voir le journal.")
		return
	_enter_scene(_scene_de_reprise(data))


## La scène où reprendre, lue sur le tag `checkpoint`. Un tag absent, inconnu,
## ou hérité du monde V1 rend le monde ouvert : c'est le comportement
## historique, et il reste le bon défaut — on ne replace jamais un joueur dans
## une salle sur la foi d'un tag qu'on ne comprend pas.
func _scene_de_reprise(data: Dictionary) -> String:
	var tag: String = String(data.get("checkpoint", ""))
	return String(REPRISE_PAR_CHECKPOINT.get(tag, WORLD_SCENE))


func _enter_world() -> void:
	_enter_scene(WORLD_SCENE)


func _enter_scene(chemin: String) -> void:
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow == null or not bool(flow.call("can_go_to", chemin)):
		# Texte épinglé par test_main_menu — le son s'ajoute, le libellé ne bouge pas.
		_show_error("Monde indisponible — voir le journal.")
		return
	flow.call("go_to", chemin)


## §17.3 : confirmation avant écrasement d'une sauvegarde. Deux appuis successifs
## plutôt qu'une boîte de dialogue, qui viendra avec le thème complet.
func _on_new_game() -> void:
	if _save_system == null:
		return
	var has_save: bool = bool(_save_system.call("has_save", DEFAULT_SLOT))
	if has_save and not _confirming_overwrite:
		_confirming_overwrite = true
		_new_game_button.text = Textes.t("menu.sauvegarde.ecraser")
		_status_label.text = Textes.t("menu.sauvegarde.confirmer")
		return

	_confirming_overwrite = false
	_new_game_button.text = "Nouvelle partie"
	var created: bool = bool(_save_system.call("save_slot", DEFAULT_SLOT, _new_game_payload()))
	if not created:
		_show_error(Textes.t("menu.sauvegarde.echec"))
		return
	if _game_state != null:
		_game_state.call("set_difficulty", 1)  # Difficulty.STANDARD
	# Rafraîchir AVANT de partir : si la transition échoue (flux occupé, scène
	# absente), le menu reste cohérent — « Continuer » reflète la sauvegarde.
	_refresh()
	_wire_focus_cycle()
	_enter_world()


## Contenu minimal et honnête d'une partie neuve : ce que la Phase A sait déjà
## représenter. Le schéma complet (§19.1) arrive avec les systèmes concernés.
func _new_game_payload() -> Dictionary:
	return {
		"schema": 2,
		"checkpoint": "world_v2.spawn",
		"playtime_seconds": 0.0,
		"boss_defeated": false,
	}


func _on_training() -> void:
	get_tree().change_scene_to_file(TRAINING_SCENE)


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
		_show_error("Scène d'audit indisponible.")
		return
	flow.call("go_to", INPUT_AUDIT_SCENE)


func _on_quit() -> void:
	get_tree().quit(0)
