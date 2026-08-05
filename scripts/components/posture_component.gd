## Jauge de POSTURE — la ressource tactique des porteurs de garde (P2 §7.4,
## bible §7.2). Distincte de la poise (résistance instantanée d'une action)
## et de la santé : la rupture de posture ouvre une FENÊTRE, elle ne blesse
## pas.
##
## Le propriétaire décide ce que « rupture » veut dire (le Briseur entre en
## STAGGERED, le boss exposera son noyau — P2-5) ; le composant ne porte que
## la jauge, sa recharge après accalmie et l'idempotence du signal : brisée,
## elle ne ré-émet pas tant qu'elle n'est pas remontée au-dessus de zéro.
class_name PostureComponent
extends Node

signal posture_broken()
signal posture_changed(current: float, maximum: float)

@export var max_posture: float = 12.0
## Accalmie avant recharge (secondes sans coup encaissé).
@export var regen_delay: float = 5.0
@export var regen_rate: float = 4.0

var _posture: float = 0.0
var _regen_timer: float = 0.0
var _broken: bool = false


func _ready() -> void:
	_posture = max_posture
	# Recharge au tick physique — mais seulement quand il y a à recharger.
	set_physics_process(false)


func current() -> float:
	return _posture


func ratio() -> float:
	return _posture / max_posture if max_posture > 0.0 else 0.0


func is_broken() -> bool:
	return _broken


## Encaisse. Retourne vrai si CE coup provoque la rupture.
func take_posture_damage(amount: float) -> bool:
	if amount <= 0.0:
		return false
	_regen_timer = regen_delay
	set_physics_process(true)
	if _broken:
		return false
	_posture = maxf(0.0, _posture - amount)
	posture_changed.emit(_posture, max_posture)
	if _posture <= 0.0:
		_broken = true
		posture_broken.emit()
		return true
	return false


func reset() -> void:
	_posture = max_posture
	_broken = false
	_regen_timer = 0.0
	posture_changed.emit(_posture, max_posture)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_regen_timer = maxf(0.0, _regen_timer - delta)
	if _regen_timer > 0.0:
		return
	if _posture < max_posture:
		_posture = minf(max_posture, _posture + regen_rate * delta)
		if _broken and _posture > 0.0:
			_broken = false
		posture_changed.emit(_posture, max_posture)
	else:
		set_physics_process(false)
