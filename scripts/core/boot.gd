## Scène d'amorce (MASTER_SPEC §6.1).
##
## Rôle : vérifier que la fondation est réellement en place, journaliser
## l'environnement d'exécution vérifié, puis passer la main au flux.
##
## `FadeLayer` n'est pas ici mais dans l'autoload `SceneFlow` : une couche de
## fondu placée dans cette scène serait libérée au premier changement de scène,
## c'est-à-dire au moment exact où elle sert (DECISIONS D-007).
##
## `LoadingUI` n'existe pas encore : aucune scène n'est assez lourde pour en
## justifier une, et rien ne permettrait de mesurer si elle aide. Elle arrive en
## Phase I avec le chargement en arrière-plan (§20.10).
##
## ÉTAT PHASE A : Boot enchaîne sur le menu principal via `SceneFlow`. Il n'y a
## en revanche **aucun monde** derrière le menu ; celui-ci le dit lui-même plutôt
## que de simuler une transition vers une scène inexistante.
extends Node

## Autoloads dont l'absence est une erreur de fondation, pas un détail.
const REQUIRED_AUTOLOADS: Array[String] = [
	"GameState", "EventBus", "SaveSystem", "AudioManager", "SceneFlow",
]

const MAIN_MENU: String = "res://scenes/ui/MainMenu.tscn"
const AUTOQUIT_FRAMES: int = 3

var _frames: int = 0
var _autoquit: bool = false


func _ready() -> void:
	_autoquit = "--autoquit" in OS.get_cmdline_user_args()

	var version: Dictionary = Engine.get_version_info()
	print("[boot] Godot            : %s" % version.get("string", "?"))
	print("[boot] renderer         : %s" % ProjectSettings.get_setting("rendering/renderer/rendering_method", "?"))
	print("[boot] physique 3D      : %s" % ProjectSettings.get_setting("physics/3d/physics_engine", "?"))
	print("[boot] tick physique    : %s Hz" % ProjectSettings.get_setting("physics/common/physics_ticks_per_second", "?"))
	print("[boot] pilote de rendu  : %s" % DisplayServer.get_name())

	if not _verify_autoloads():
		return

	print("[boot] autoloads        : %s" % ", ".join(REQUIRED_AUTOLOADS))
	# Résolution par le nœud plutôt que par l'identifiant global `GameState` :
	# `--check-only` n'enregistre pas les singletons d'autoload et rejetterait ce
	# fichier, alors que le code serait correct à l'exécution. Passer par l'arbre
	# garde le script vérifiable par le niveau 1b de validate_fast.sh.
	var state: Node = get_node_or_null("/root/GameState")
	if state != null:
		print("[boot] flux             : %s" % state.call("flow_name", state.call("get_flow")))
	print("[boot] fondation vérifiée — Phase A.")
	_go_to_main_menu()


## L'enchaînement passe par `SceneFlow` et non par `change_scene_to_file()` :
## c'est le seul chemin qui coupe les entrées, gère le fondu et garantit qu'aucun
## ancien nœud ne reste actif (§6.1).
func _go_to_main_menu() -> void:
	if _autoquit:
		# En capture automatisée, on veut observer Boot lui-même, pas le menu.
		print("[boot] --autoquit : transition vers le menu principal ignorée.")
		return
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow == null:
		push_error("[boot] SceneFlow absent : impossible d'enchaîner sur le menu.")
		return
	if not bool(flow.call("can_go_to", MAIN_MENU)):
		push_error("[boot] menu principal introuvable : %s" % MAIN_MENU)
		return
	var state: Node = get_node_or_null("/root/GameState")
	if state != null:
		state.call("set_flow", 1)  # GameState.Flow.MAIN_MENU
	print("[boot] transition vers le menu principal.")
	flow.call("go_to", MAIN_MENU)


## Un autoload manquant doit arrêter le démarrage bruyamment. Le laisser passer
## produirait des « Nonexistent function » disséminés bien plus loin, dans des
## systèmes qui n'y sont pour rien.
func _verify_autoloads() -> bool:
	var missing: Array[String] = []
	for autoload_name: String in REQUIRED_AUTOLOADS:
		if get_node_or_null("/root/%s" % autoload_name) == null:
			missing.append(autoload_name)
	if missing.is_empty():
		return true
	push_error("[boot] autoload(s) absent(s) : %s — relancer tools/godot/setup_project.gd"
		% ", ".join(missing))
	return false


func _process(_delta: float) -> void:
	if not _autoquit:
		return
	_frames += 1
	if _frames >= AUTOQUIT_FRAMES:
		print("[boot] auto-quit après %d frames rendues." % _frames)
		get_tree().quit(0)
