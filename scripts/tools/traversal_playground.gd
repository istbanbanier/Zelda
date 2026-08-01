## Terrain d'essai manuel du traversal (Gate B, MASTER_SPEC §21.4).
##
## Outillage de développement, pas une scène de jeu : ce script capture la souris,
## affiche l'état que l'opérateur ne peut pas deviner — endurance, mode, vitesse —
## et rien d'autre. Le HUD réel de §17.2 viendra avec son identité visuelle ; un
## panneau de debug qui prétendrait en tenir lieu serait un placeholder déguisé.
##
## Lancement (poste avec écran) :
##   godot --path . scenes/tests/TraversalPlayground.tscn
##   godot --path . --debug-collisions scenes/tests/TraversalPlayground.tscn
## Le second affiche les formes de collision : indispensable, le bac à sable n'a
## aucun mesh — c'est un décor d'épreuves, pas un décor.
extends Node3D

@onready var _player: PlayerController = $Player
@onready var _readout: Label = $DebugUI/Readout

var _events: Array[String] = []


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Les signaux du contrôleur, journalisés : l'opérateur de §21.4 doit pouvoir
	# dire « l'accroche a eu lieu » sans interpréter une silhouette grise.
	_player.grabbed_wall.connect(func(_n: Vector3) -> void: _log("accroche paroi"))
	_player.released_wall.connect(func(r: StringName) -> void: _log("lâcher (%s)" % r))
	_player.mantle_started.connect(func(_t: Vector3) -> void: _log("franchissement…"))
	_player.mantle_finished.connect(func() -> void: _log("franchissement terminé"))
	_player.mantle_refused.connect(func(r: StringName) -> void: _log("mantle refusé (%s)" % r))
	_player.stepped_up.connect(func(h: float) -> void: _log("marche franchie (y=%.2f)" % h))
	_player.stamina().exhausted.connect(func() -> void: _log("ÉPUISÉ"))
	_player.stamina().recovered.connect(func() -> void: _log("récupéré"))
	print("[playground] Échap : rendre/reprendre la souris. Protocole : docs/MANUAL_VALIDATION.md, section Gate B.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _log(message: String) -> void:
	_events.append(message)
	if _events.size() > 6:
		_events.pop_front()


## Lecture seule d'état pour l'affichage : aucun transform de gameplay n'est écrit
## depuis `_process()` (§20.9).
func _process(_delta: float) -> void:
	var stamina: StaminaComponent = _player.stamina()
	var mode: String = "locomotion"
	if _player.is_climbing():
		mode = "ESCALADE"
	elif _player.is_mantling():
		mode = "FRANCHISSEMENT"
	_readout.text = "endurance %5.1f / %.0f%s\nmode %s\nvitesse %.2f m/s\n— derniers événements —\n%s" % [
		stamina.current(), stamina.maximum(),
		"  [ÉPUISÉ]" if stamina.is_exhausted() else "",
		mode, _player.horizontal_speed(), "\n".join(_events)]
