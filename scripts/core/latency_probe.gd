## Sonde de latence entrée→logique — P2 §5.1/§7.2, exigence §23.1 :
## « entrée mouvement visible au tick physique suivant et latence d'action
## instrumentée ».
##
## La RÉCEPTION est marquée au front d'événement (`PlayerInputReader._input`),
## la CONSOMMATION au moment exact où le contrôleur change d'état (saut parti,
## attaque engagée, esquive lancée). L'écart est exprimé en **ticks physiques**
## (unité logique, insensible à la contention machine — R-017) et en
## millisecondes (indicatif ; jamais un critère de test sous llvmpipe).
##
## Une action bufferisée (saut demandé en l'air, esquive pendant une attaque)
## affiche un écart > 1 tick : c'est INTENTIONNEL, le buffer honore l'appui à la
## première fenêtre légale (§10.6). Le critère « ≤ 1 tick » ne vaut que pour une
## action immédiatement légale.
class_name LatencyProbe
extends RefCounted

## Mesures conservées par action. Anneau borné : aucune croissance par frame.
const RING_SIZE: int = 32

## action -> { "usec": int, "tick": int } — réceptions en attente de consommation.
var _pending: Dictionary = {}
## action -> Array[Dictionary] — mesures { "ticks": int, "ms": float }.
var _history: Dictionary = {}
## Dernier refus explicable (P2 §5.7 : « raison de refus » dans l'overlay).
var _last_refusal: Dictionary = {}


func mark_received(action: StringName) -> void:
	_pending[action] = {
		"usec": Time.get_ticks_usec(),
		"tick": Engine.get_physics_frames(),
	}


func mark_consumed(action: StringName) -> void:
	if not _pending.has(action):
		return
	var recv: Dictionary = _pending[action] as Dictionary
	_pending.erase(action)
	var entry: Dictionary = {
		"ticks": int(Engine.get_physics_frames()) - int(recv["tick"]),
		"ms": float(Time.get_ticks_usec() - int(recv["usec"])) / 1000.0,
	}
	var ring: Array[Dictionary] = []
	if _history.has(action):
		ring = _history[action] as Array[Dictionary]
	ring.append(entry)
	if ring.size() > RING_SIZE:
		ring.pop_front()
	_history[action] = ring


## Un refus n'est pas une consommation : l'appui est perdu ou re-bufferisé, et
## la raison reste lisible dans l'overlay au lieu d'un silence.
func mark_refused(action: StringName, reason: StringName) -> void:
	_pending.erase(action)
	_last_refusal = {
		"action": action,
		"reason": reason,
		"tick": Engine.get_physics_frames(),
	}


## Dernière mesure pour une action, ou {} si rien n'a encore été consommé.
func last(action: StringName) -> Dictionary:
	if not _history.has(action):
		return {}
	var ring: Array[Dictionary] = _history[action] as Array[Dictionary]
	return {} if ring.is_empty() else ring.back()


func last_refusal() -> Dictionary:
	return _last_refusal


## Une ligne par action mesurée — pour l'overlay de lab.
func summary() -> String:
	var lines: PackedStringArray = PackedStringArray()
	for action: StringName in _history:
		var entry: Dictionary = last(action)
		if entry.is_empty():
			continue
		lines.append("%s: %d tick(s), %.1f ms" % [action, int(entry["ticks"]), float(entry["ms"])])
	return "\n".join(lines)
