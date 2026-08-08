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

## Sensibilité du regard à la souris, en radians par pixel. Valeur par défaut
## et bornes : `UserSettings` — modifiable dans le menu pause, persistée.
var mouse_sensitivity: float = UserSettings.DEFAULT_MOUSE_SENSITIVITY

var _intent: InputIntent = InputIntent.new()
var _mouse_delta: Vector2 = Vector2.ZERO
## Sonde de latence P2-1 : réception marquée ici (front d'événement),
## consommation marquée par le contrôleur au changement d'état réel.
var probe: LatencyProbe = LatencyProbe.new()
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


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = UserSettings.clamp_sensitivity(value)


func _ready() -> void:
	# Par le setter, jamais en direct : la borne s'applique aussi à ce qui sort
	# du fichier (défense en profondeur, QA-D1R-02).
	set_mouse_sensitivity(UserSettings.load_mouse_sensitivity())
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
	_intent.focus_held = Input.is_action_pressed("resonance_focus")
	# Outillage de vol libre : lu ici comme tout le reste, jamais ailleurs.
	_intent.fly_up_held = Input.is_action_pressed("dev_fly_up")
	_intent.fly_down_held = Input.is_action_pressed("dev_fly_down")

	# Deux canaux, deux unités — JAMAIS mélangés (PT-D1-01) : le stick est un
	# axe (-1..1) que la caméra convertit en vitesse angulaire ; la souris est un
	# déplacement en pixels déjà converti en radians, appliqué tel quel.
	_intent.look_analog = Input.get_vector("look_left", "look_right", "look_down", "look_up")
	_intent.look_mouse = _mouse_delta
	_mouse_delta = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if not _capture_enabled:
		return
	# Fronts montants : détectés à l'événement pour ne jamais être perdus entre
	# deux ticks physiques (§10.6 — une action demandée dans une fenêtre valide
	# ne doit pas être avalée).
	#
	# LA VISÉE PASSE AVANT L'ATTAQUE. `attack_light` et `shoot` partagent le
	# clic GAUCHE (project.godot : button_index 1 pour les deux) et la cascade
	# ci-dessous est un `elif` : `attack_light` étant testé le premier, il
	# avalait le clic et `shoot` n'était JAMAIS atteint. Mesuré au playtest
	# humain du 2026-08-07 — le joueur a visé, cliqué, et son compteur est
	# resté bloqué sur « Flèches : 8 » pendant toute la partie ; sans arc, les
	# cristaux du boss (y = 3,90 m, hors de portée du corps à corps) rendaient
	# le boss invincible. Hors visée, rien ne change : le clic reste l'attaque.
	if Input.is_action_pressed("aim") \
			and event.is_action_pressed("shoot", false, true):
		_intent.shoot_pressed = true
		probe.mark_received(&"shoot")
	elif event.is_action_pressed("jump", false, true):
		_intent.jump_pressed = true
		probe.mark_received(&"jump")
	elif event.is_action_pressed("dodge", false, true):
		_intent.dodge_pressed = true
		probe.mark_received(&"dodge")
	elif event.is_action_pressed("interact", false, true):
		_intent.interact_pressed = true
		probe.mark_received(&"interact")
	elif event.is_action_pressed("attack_light", false, true):
		_intent.attack_pressed = true
		probe.mark_received(&"attack_light")
	elif event.is_action_pressed("lock_on", false, true):
		_intent.lock_pressed = true
	elif event.is_action_pressed("attack_heavy", false, true):
		_intent.heavy_pressed = true
		probe.mark_received(&"attack_heavy")
	elif event.is_action_pressed("shoot", false, true):
		_intent.shoot_pressed = true
		probe.mark_received(&"shoot")
	elif event.is_action_pressed("target_next", false, true):
		_intent.target_next_pressed = true
	elif event.is_action_pressed("target_prev", false, true):
		_intent.target_prev_pressed = true
	elif event.is_action_pressed("quick_meal", false, true):
		_intent.meal_pressed = true
	elif event.is_action_pressed("resonance_pulse", false, true):
		_intent.pulse_pressed = true
		probe.mark_received(&"resonance_pulse")
	elif event.is_action_pressed("resonance_ground", false, true):
		_intent.ground_pressed = true
		probe.mark_received(&"resonance_ground")
	elif event.is_action_pressed("dev_fly_toggle", false, true):
		_intent.fly_toggle_pressed = true
	elif event is InputEventMouseMotion:
		_mouse_delta += (event as InputEventMouseMotion).relative * mouse_sensitivity
