## Jauge de poise (MASTER_SPEC §10.3, §12.3).
##
## Les dégâts de poise voyagent dans `DamageEvent` depuis C.0 ; ce composant les
## consomme enfin. Quand la jauge casse, `poise_broken` est émis UNE fois et la
## jauge se recharge après l'étourdissement — le propriétaire (ennemi, boss)
## décide ce que « étourdi » veut dire, le composant ne connaît que la comptabilité.
##
## §10.5 : la jauge se régénère aussi hors combat, sinon des coups espacés de
## plusieurs secondes finiraient par étourdir — un stagger « à retardement »
## illisible.
class_name PoiseComponent
extends Node

signal poise_broken()
signal poise_changed(current: float, maximum: float)

@export var max_poise: float = 20.0
## Sans nouveau coup pendant ce délai, la jauge se vide de sa fatigue.
@export var reset_delay: float = 3.0

var _accumulated: float = 0.0
var _since_last_hit: float = 0.0
var _broken: bool = false


## Encaisse la poise d'un événement. Retourne `true` si la jauge vient de casser.
func take_poise_damage(event: DamageEvent) -> bool:
	if event == null or event.poise_damage <= 0.0 or _broken:
		return false
	_accumulated += event.poise_damage
	_since_last_hit = 0.0
	poise_changed.emit(maxf(0.0, max_poise - _accumulated), max_poise)
	if _accumulated >= max_poise:
		_broken = true
		poise_broken.emit()
		return true
	return false


## À appeler au rythme physique par le propriétaire (patron `StaminaComponent`).
func update(delta: float) -> void:
	if _broken:
		return
	_since_last_hit += delta
	if _since_last_hit >= reset_delay and _accumulated > 0.0:
		_accumulated = 0.0
		poise_changed.emit(max_poise, max_poise)


## Le propriétaire rétablit la jauge à la fin de son étourdissement.
func recover() -> void:
	_broken = false
	_accumulated = 0.0
	_since_last_hit = 0.0
	poise_changed.emit(max_poise, max_poise)


func is_broken() -> bool:
	return _broken
