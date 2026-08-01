## Autoload — flux de jeu et difficulté (MASTER_SPEC §5.6).
##
## Détient l'état *global* du jeu : où l'on est dans le flux, et à quelle
## difficulté. Rien d'autre.
##
## INTERDIT ICI (§5.6) : conserver une référence au joueur, aux ennemis ou à un
## nœud de scène. Un autoload survit aux changements de scène ; toute référence
## qu'il garde devient invalide sans prévenir et transforme un bug local en bug
## global. Les systèmes qui ont besoin du joueur le trouvent par groupe.
extends Node

## Étapes du flux (§6.1). `MAIN_MENU` et au-delà ne sont pas encore atteignables :
## les scènes correspondantes arrivent avec leurs phases.
enum Flow {
	BOOT,
	MAIN_MENU,
	VALLEY,
	DUNGEON,
	BOSS_ARENA,
	VICTORY,
}

## §17.5 : la difficulté ajuste dégâts et fenêtres, **jamais** la structure des
## énigmes sans choix explicite du joueur.
enum Difficulty {
	RELAXED,
	STANDARD,
	HARSH,
}

signal flow_changed(previous: Flow, current: Flow)
signal difficulty_changed(current: Difficulty)
signal paused_changed(is_paused: bool)

var _flow: Flow = Flow.BOOT
var _difficulty: Difficulty = Difficulty.STANDARD
var _paused: bool = false


func get_flow() -> Flow:
	return _flow


func set_flow(next: Flow) -> void:
	if next == _flow:
		return
	var previous: Flow = _flow
	_flow = next
	flow_changed.emit(previous, _flow)


func get_difficulty() -> Difficulty:
	return _difficulty


func set_difficulty(next: Difficulty) -> void:
	if next == _difficulty:
		return
	_difficulty = next
	difficulty_changed.emit(_difficulty)


func is_paused() -> bool:
	return _paused


## La pause est un état global : elle suspend l'arbre et, en Phase E, le minuteur
## de buff (§13.4). Idempotente pour que deux appels ne désynchronisent rien.
func set_paused(value: bool) -> void:
	if value == _paused:
		return
	_paused = value
	get_tree().paused = value
	paused_changed.emit(_paused)


func flow_name(value: Flow) -> String:
	return Flow.keys()[value]
