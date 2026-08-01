## Lecteur d'entrée — **le seul** endroit du gameplay qui consulte l'InputMap.
##
## D-013 : tout le reste consomme une `InputIntent`, sans savoir d'où elle vient.
## Cette contrainte est vérifiée par `test_input_layer_isolation.gd`, qui échoue si
## un script de gameplay lit une touche ou une constante `KEY_*`.
##
## Ce lecteur n'interroge que des **actions**, jamais des touches. Il ne contient
## donc aucun raccourci clavier codé en dur, et la même ligne de code sert le
## clavier et la manette : `Input.get_vector()` combine les deux, en appliquant la
## zone morte déclarée dans l'InputMap.
##
## CONTROLLER-001 : ce fichier est écrit pour la manette autant que pour le
## clavier, mais **rien ici ne prouve** qu'une manette réelle fonctionne. Seul un
## essai humain le prouvera (§4.3 de `docs/MANUAL_GATE_A.md`).
class_name PlayerInputReader
extends Node

## Sensibilité du regard à la souris, en radians par pixel.
const MOUSE_LOOK_SCALE: float = 0.0022

var _intent: InputIntent = InputIntent.new()
var _mouse_delta: Vector2 = Vector2.ZERO
## Neutralise la lecture des périphériques : les tests injectent alors l'intention
## directement, sans dépendre d'aucun matériel.
var _capture_enabled: bool = true


func set_capture_enabled(enabled: bool) -> void:
	_capture_enabled = enabled
	if not enabled:
		_intent.clear()


func get_intent() -> InputIntent:
	return _intent


## Appelé par le contrôleur en fin de tick physique, après consommation.
func clear_edges() -> void:
	_intent.consume_edges()


func _ready() -> void:
	# Les fronts sont détectés dans `_input`, mais les états maintenus sont relus
	# au rythme physique : c'est là que la logique de mouvement les consomme
	# (§20.9 — aucune écriture de transform gameplay depuis `_process`).
	set_process_input(true)
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if not _capture_enabled:
		return
	# `get_vector` applique la zone morte de l'InputMap et combine clavier et
	# manette sans que ce code ait à les distinguer. y positif = avant.
	_intent.move = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	_intent.sprint_held = Input.is_action_pressed("sprint")
	_intent.aim_held = Input.is_action_pressed("aim")

	# Le regard au stick droit est un axe continu, celui de la souris un delta
	# d'événements : les deux sont ramenés ici à la même unité.
	var stick: Vector2 = Input.get_vector("look_left", "look_right", "look_down", "look_up")
	_intent.look = stick + _mouse_delta
	_mouse_delta = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if not _capture_enabled:
		return
	# Fronts montants : détectés à l'événement pour ne jamais être perdus entre
	# deux ticks physiques (§10.6 — une action demandée dans une fenêtre valide
	# ne doit pas être avalée).
	if event.is_action_pressed("jump", false, true):
		_intent.jump_pressed = true
	elif event.is_action_pressed("dodge", false, true):
		_intent.dodge_pressed = true
	elif event.is_action_pressed("interact", false, true):
		_intent.interact_pressed = true
	elif event.is_action_pressed("attack_light", false, true):
		_intent.attack_pressed = true
	elif event is InputEventMouseMotion:
		_mouse_delta += (event as InputEventMouseMotion).relative * MOUSE_LOOK_SCALE
