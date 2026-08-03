## Écran de victoire (MASTER_SPEC §16.8, §17.3).
##
## §16.8 exige trois issues : « recommencer, continuer/explorer ou menu ».
## Elles sont ici, et elles font réellement quelque chose :
##
## | Bouton | Ce qu'il fait vraiment |
## |---|---|
## | Continuer l'exploration | recharge la VALLÉE avec la sauvegarde intacte — `boss_defeated` reste vrai, le monde est ouvert |
## | Recommencer | efface le slot et repart du début : c'est explicite, et confirmé avant d'écraser (§17.3) |
## | Menu principal | rend la main au menu, sans rien toucher |
##
## §17.3 : navigation clavier ET manette, focus visible, aucun piège de
## focus — les voisins sont câblés en cycle, comme au menu principal, plutôt
## que laissés à la détection géométrique qui saute les boutons désactivés.
extends Control

const DEFAULT_SLOT: String = "slot0"
const VALLEY_SCENE: String = "res://scenes/world/valley/ValleyWorld.tscn"
const MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"

@onready var _explore_button: Button = %ExploreButton
@onready var _restart_button: Button = %RestartButton
@onready var _menu_button: Button = %MenuButton
@onready var _status_label: Label = %StatusLabel
@onready var _time_label: Label = %TimeLabel

## Vrai en jeu. Coupé par les tests, pour la même raison que l'arène :
## `SceneFlow.go_to()` met l'arbre en pause et appelle
## `change_scene_to_file()`, qui remplace la scène courante — celle du
## runner. Ce qui est prouvé à la place est ce qui compte : ce que chaque
## bouton ÉCRIT, et VERS QUOI il part (`last_target()`).
@export var auto_navigate: bool = true

var _save_system: Node = null
var _game_state: Node = null
var _confirming_restart: bool = false
var _last_target: String = ""


func _ready() -> void:
	_save_system = get_node_or_null("/root/SaveSystem")
	_game_state = get_node_or_null("/root/GameState")
	if _game_state != null:
		_game_state.call("set_flow", 5)  # GameState.Flow.VICTORY
	_explore_button.pressed.connect(_on_explore)
	_restart_button.pressed.connect(_on_restart)
	_menu_button.pressed.connect(_on_menu)
	_apply_style()
	_refresh()
	_wire_focus_cycle()
	_explore_button.grab_focus()


## La durée affichée vient de la SAUVEGARDE, pas d'un compteur d'écran :
## sans temps enregistré, on n'invente rien, on n'affiche rien.
func _refresh() -> void:
	_status_label.text = "La tempête s'est ouverte au-dessus de la Citadelle."
	_time_label.text = ""
	if _save_system == null or not bool(_save_system.call("has_save", DEFAULT_SLOT)):
		return
	var data: Dictionary = _save_system.call("load_slot", DEFAULT_SLOT) as Dictionary
	if not bool(data.get("boss_defeated", false)):
		# On peut atterrir ici par une transition de debug : le dire plutôt
		# que d'afficher une victoire qui n'a pas eu lieu.
		_status_label.text = "Aucune victoire enregistrée dans ce slot."
		return
	var seconds: float = float(data.get("playtime_seconds", 0.0))
	if seconds > 0.0:
		_time_label.text = "Temps de jeu : %d min %02d s" % [
			int(seconds / 60.0), int(seconds) % 60]


func _wire_focus_cycle() -> void:
	var order: Array[Button] = [_explore_button, _restart_button, _menu_button]
	for i: int in range(order.size()):
		var next: Button = order[(i + 1) % order.size()]
		var previous: Button = order[(i - 1 + order.size()) % order.size()]
		order[i].focus_neighbor_bottom = next.get_path()
		order[i].focus_next = next.get_path()
		order[i].focus_neighbor_top = previous.get_path()
		order[i].focus_previous = previous.get_path()


func _apply_style() -> void:
	for button: Button in [_explore_button, _restart_button, _menu_button]:
		HudStyle.style_button(button)
	_status_label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	_time_label.add_theme_color_override(&"font_color", HudStyle.GOLD)


func _on_explore() -> void:
	_go_to(VALLEY_SCENE)


## §17.3 : « confirmation avant écrasement d'une sauvegarde ». Recommencer
## efface une partie terminée — on le demande une fois.
func _on_restart() -> void:
	if _save_system != null and bool(_save_system.call("has_save", DEFAULT_SLOT)) \
			and not _confirming_restart:
		_confirming_restart = true
		_restart_button.text = "Confirmer : effacer et recommencer"
		_status_label.text = "Cela effacera la partie terminée."
		return
	_confirming_restart = false
	_restart_button.text = "Recommencer"
	# Même geste qu'au menu principal : on ÉCRIT une partie neuve plutôt
	# que de supprimer le fichier. Un slot absent et un slot vierge ne se
	# comportent pas pareil, et le joueur n'a pas à connaître la différence.
	if _save_system != null:
		var created: bool = bool(_save_system.call("save_slot", DEFAULT_SLOT, {
			"schema": 2,
			"checkpoint": "valley.camp.start",
			"playtime_seconds": 0.0,
			"boss_defeated": false,
		}))
		if not created:
			_status_label.text = "Échec d'écriture de la sauvegarde — voir le journal."
			return
	_go_to(VALLEY_SCENE)


func _on_menu() -> void:
	_go_to(MENU_SCENE)


func _go_to(target: String) -> void:
	_last_target = target
	if not auto_navigate:
		return
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow == null or not bool(flow.call("can_go_to", target)):
		_status_label.text = "Scène introuvable : %s" % target
		return
	flow.call("go_to", target)


## Seams de test — ce que l'écran propose RÉELLEMENT.
func status_text() -> String:
	return _status_label.text


func is_confirming_restart() -> bool:
	return _confirming_restart


func buttons() -> Array[Button]:
	return [_explore_button, _restart_button, _menu_button]


## Dernière destination demandée — la transition réelle s'exécute en jeu,
## le choix de la cible se prouve ici.
func last_target() -> String:
	return _last_target
