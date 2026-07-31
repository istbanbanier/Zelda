## Amorce minimale de Phase 0.
##
## Rôle actuel : prouver que le projet se charge et s'exécute réellement, et
## journaliser l'environnement d'exécution vérifié (version, renderer, physique).
##
## Phase A remplacera ce nœud par le vrai Boot décrit dans MASTER_SPEC §6.1
## (SceneFlow, FadeLayer, LoadingUI, overlay debug désactivé en build final).
extends Node

## Nombre de frames à laisser passer avant l'auto-quit en mode non interactif.
const AUTOQUIT_FRAMES: int = 3

var _frames: int = 0
var _autoquit: bool = false


func _ready() -> void:
	_autoquit = "--autoquit" in OS.get_cmdline_user_args()

	var v: Dictionary = Engine.get_version_info()
	print("[boot] Godot            : %s" % v.get("string", "?"))
	print("[boot] renderer         : %s" % ProjectSettings.get_setting("rendering/renderer/rendering_method", "?"))
	print("[boot] physique 3D      : %s" % ProjectSettings.get_setting("physics/3d/physics_engine", "?"))
	print("[boot] tick physique    : %s Hz" % ProjectSettings.get_setting("physics/common/physics_ticks_per_second", "?"))
	print("[boot] pilote de rendu  : %s" % DisplayServer.get_name())
	print("[boot] scène principale chargée — Phase 0, aucun gameplay attendu ici.")


func _process(_delta: float) -> void:
	if not _autoquit:
		return
	_frames += 1
	if _frames >= AUTOQUIT_FRAMES:
		print("[boot] auto-quit après %d frames rendues." % _frames)
		get_tree().quit(0)
