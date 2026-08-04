## Points de vie (MASTER_SPEC §5.8, §10.1).
##
## Composant, pas classe de base : joueur, pillards, colosse et boss porteront le
## même. Il reçoit un montant **final** (formule de §10.3 déjà appliquée par la
## chaîne hitbox → hurtbox) : recalculer ici ouvrirait la porte à deux montants
## différents pour le même coup.
##
## La mort est **idempotente** (§16.2 l'exige du boss, autant l'exiger partout) :
## `died` est émis une fois, et plus rien n'entame un mort.
class_name HealthComponent
extends Node

signal damaged(event: DamageEvent)
signal healed(amount: float)
signal health_changed(current: float, maximum: float)
signal died(event: DamageEvent)

@export var max_health: float = 100.0

var _current: float = 0.0
var _dead: bool = false
## Les i-frames d'esquive (§10.2) basculeront ce drapeau — le composant n'a pas
## à savoir POURQUOI il est invulnérable.
var _invulnerable: bool = false
var _timed_invulnerable_until: int = 0


func _ready() -> void:
	_current = max_health


## Applique un événement de dégâts. Retourne `true` si des dégâts ont réellement
## été appliqués — le refus (mort, invulnérable) n'est pas une erreur, c'est une
## information dont la hitbox n'a d'ailleurs pas besoin.
func take_damage(event: DamageEvent) -> bool:
	# `is_invulnerable()`, jamais la variable brute : la fenêtre TEMPORISÉE
	# (mercy) compte autant que le drapeau des i-frames d'esquive. Tester le
	# drapeau seul est exactement le bug qui a fait rougir le premier essai —
	# invulnérable au sens de l'API, blessé quand même.
	if _dead or is_invulnerable():
		return false
	if event == null or event.amount <= 0.0:
		return false
	_current = maxf(0.0, _current - event.amount)
	damaged.emit(event)
	health_changed.emit(_current, max_health)
	if _current <= 0.0:
		_dead = true
		died.emit(event)
	return true


func heal(amount: float) -> void:
	# Soigner un mort est un respawn, pas un soin : cela passe par `revive()`,
	# jamais par un chiffre qui remonte tout seul.
	if _dead or amount <= 0.0:
		return
	var before: float = _current
	_current = minf(max_health, _current + amount)
	if not is_equal_approx(before, _current):
		healed.emit(_current - before)
		health_changed.emit(_current, max_health)


## Restauration explicite (checkpoint, respawn — §19.5).
func revive(health: float = -1.0) -> void:
	_dead = false
	_current = clampf(health if health > 0.0 else max_health, 0.0, max_health)
	health_changed.emit(_current, max_health)


func set_invulnerable(value: bool) -> void:
	_invulnerable = value


## Invulnérabilité TEMPORISÉE (mercy après un coup — 2.6 du plan de test),
## cumulée par OU avec le drapeau manuel des i-frames d'esquive : l'un et
## l'autre protègent, aucun n'éteint l'autre — c'est ce qui permet à l'esquive
## de retomber sans annuler une fenêtre de mercy en cours. Horloge moteur
## plutôt qu'un `_process` sur un nœud autrement dormant (règle GDScript).
func grant_invulnerability(duration: float) -> void:
	if duration <= 0.0:
		return
	_timed_invulnerable_until = maxi(_timed_invulnerable_until,
		Time.get_ticks_msec() + int(duration * 1000.0))


func is_invulnerable() -> bool:
	return _invulnerable or Time.get_ticks_msec() < _timed_invulnerable_until


func current() -> float:
	return _current


func maximum() -> float:
	return max_health


func ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return _current / max_health


func is_dead() -> bool:
	return _dead
