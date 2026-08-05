## Cible valide du Bracelet de Résonance (P2 §3.1). Posé en enfant d'un
## Node3D : l'objet devient détectable par Pulse et, plus tard, ciblable par
## les autres opérations (Link, Polarité, Arc Step selon `kind`).
##
## La révélation est un ÉTAT TEMPORAIRE (2-4 s, P2 §3.2) : la présentation
## (surbrillance, contour — passe visuelle ultérieure) écoute les signaux ;
## ce composant ne dessine rien. Décroissance au tick physique, coupée au
## repos (règle CLAUDE.md : pas de `_process` sur nœuds dormants).
class_name ResonanceTargetComponent
extends Node

signal revealed(duration: float)
signal reveal_ended()

## Nature de l'information révélée (P2 §3.2) : `material`, `electric_state`,
## `port`, `weak_point`, `trace`. Pilote ce que la présentation montrera.
@export var kind: StringName = &"material"

var _reveal_timer: float = 0.0


func _ready() -> void:
	add_to_group(&"resonance_targets")
	set_physics_process(false)


func is_revealed() -> bool:
	return _reveal_timer > 0.0


## Point spatial de la cible — le parent Node3D porte la position.
func anchor() -> Node3D:
	return get_parent() as Node3D


func reveal(duration: float) -> void:
	var was: bool = is_revealed()
	_reveal_timer = maxf(_reveal_timer, duration)
	if not was:
		revealed.emit(duration)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_reveal_timer -= delta
	if _reveal_timer <= 0.0:
		_reveal_timer = 0.0
		reveal_ended.emit()
		set_physics_process(false)
