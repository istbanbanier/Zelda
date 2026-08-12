## Amorce du monde World V2 — L'ENTRÉE DÉVELOPPEUR EXPLICITE (phase V2.0).
##
## Le flux normal du jeu ne mène JAMAIS ici : `project.godot` démarre sur
## `Boot.tscn`, qui enchaîne sur le menu, qui mène à la vallée V1. Ce
## bootstrap n'est atteignable que si on le demande NOMMÉMENT :
##
##   godot --path . res://scenes/world_v2/WorldV2Bootstrap.tscn
##
## (ou par les tests, ou par l'outil de capture avec `--scene=`). C'est le
## contrat « V2 accessible uniquement par une entrée de test ou un argument
## développeur explicite » — tenu par construction : aucun script V1 ne
## référence ce fichier, et `tests/world_v2/` le vérifie par balayage.
##
## Comme `Boot`, il vérifie la fondation avant de passer la main : autoloads
## présents, carte directrice lisible ET valide. Une carte corrompue arrête le
## démarrage bruyamment — bâtir un monde sur un plan faux coûte une session.
extends Node

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"

## Les mêmes autoloads que le flux normal : le squelette consomme les systèmes
## protégés, il ne les remplace pas.
const REQUIRED_AUTOLOADS: Array[String] = [
	"GameState", "EventBus", "SaveSystem", "AudioManager", "SceneFlow",
]

const AUTOQUIT_FRAMES: int = 3

var _frames: int = 0
var _autoquit: bool = false


func _ready() -> void:
	_autoquit = "--autoquit" in OS.get_cmdline_user_args()

	print("[world_v2] bootstrap    : squelette V2.0 — entrée développeur explicite")
	print("[world_v2] Godot        : %s" % Engine.get_version_info().get("string", "?"))

	if not _verify_autoloads():
		return

	var layout: Dictionary = WorldV2Layout.load_layout()
	var problems: Array[String] = WorldV2Layout.validate(layout)
	if not problems.is_empty():
		push_error("[world_v2] carte directrice REFUSÉE (%d problème(s)) : %s"
			% [problems.size(), " | ".join(problems.slice(0, 3))])
		return
	print("[world_v2] carte        : valide (%s)" % WorldIds.V2_WORLD_ID)

	if _autoquit:
		# Capture/contrôle automatisé du bootstrap lui-même : ne pas enchaîner.
		print("[world_v2] --autoquit : transition vers le monde V2 ignorée.")
		return

	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow == null:
		push_error("[world_v2] SceneFlow absent : impossible de charger le monde V2.")
		return
	if not bool(flow.call("can_go_to", WORLD_V2_SCENE)):
		push_error("[world_v2] scène du monde V2 introuvable : %s" % WORLD_V2_SCENE)
		return
	print("[world_v2] transition vers le monde V2.")
	flow.call("go_to", WORLD_V2_SCENE)


func _verify_autoloads() -> bool:
	var missing: Array[String] = []
	for autoload_name: String in REQUIRED_AUTOLOADS:
		if get_node_or_null("/root/%s" % autoload_name) == null:
			missing.append(autoload_name)
	if missing.is_empty():
		return true
	push_error("[world_v2] autoload(s) absent(s) : %s — lancer depuis le projet, pas hors contexte"
		% ", ".join(missing))
	return false


func _process(_delta: float) -> void:
	if not _autoquit:
		return
	_frames += 1
	if _frames >= AUTOQUIT_FRAMES:
		print("[world_v2] auto-quit après %d frames rendues." % _frames)
		get_tree().quit(0)
