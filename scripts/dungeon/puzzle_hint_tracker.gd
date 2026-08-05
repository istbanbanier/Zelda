## Hints gradués d'une salle d'énigme (P2 §9.8) — déclenchés par
## l'OBSERVATION d'échecs, jamais par un simple minuteur. Trois paliers :
## rappeler la LOI, attirer vers la CAUSE, montrer la RELATION — jamais la
## séquence complète au premier palier.
##
## Le composant ne devine rien : la salle lui SOUMET ses échecs réels
## (bouton reset pressé, objet essentiel hors limites, décharge subie) via
## `record_failure`. La résolution de la salle le FERME : une énigme
## comprise n'a plus besoin d'aide.
##
## Présentation minimale intégrée (palier atteint → ligne discrète en bas
## de l'écran) ; la passe UI du Cycle 3 la remplacera, et l'option §12.3
## (désactivés/contextuels/renforcés) arrivera avec l'écran d'options.
class_name PuzzleHintTracker
extends Node

signal hint_ready(level: int, text: String)

## Échecs observés avant chaque palier : 3 → loi, 6 → cause, 9 → relation.
const FAILURES_PER_LEVEL: int = 3
const MAX_LEVEL: int = 3

var _hints: Array[String] = ["", "", ""]
var _failures: int = 0
var _level: int = 0
var _closed: bool = false
var _counts: Dictionary[StringName, int] = {}
var _label: Label = null


## Les trois textes, du plus discret au plus direct.
func set_hints(law: String, cause: String, relation: String) -> void:
	_hints = [law, cause, relation]


## Un échec RÉEL observé par la salle. Le palier ne monte qu'aux seuils,
## et plus jamais une fois la salle résolue.
func record_failure(kind: StringName) -> void:
	if _closed:
		return
	_failures += 1
	_counts[kind] = int(_counts.get(kind, 0)) + 1
	var target: int = mini(_failures / FAILURES_PER_LEVEL, MAX_LEVEL)
	if target > _level:
		_level = target
		hint_ready.emit(_level, current_hint())
		_show(current_hint())


## La salle est résolue : les hints se taisent définitivement.
func close() -> void:
	_closed = true
	if _label != null and is_instance_valid(_label):
		_label.visible = false


func level() -> int:
	return _level


func failures() -> int:
	return _failures


func count(kind: StringName) -> int:
	return int(_counts.get(kind, 0))


func is_closed() -> bool:
	return _closed


func current_hint() -> String:
	if _level <= 0:
		return ""
	return _hints[_level - 1]


## Ligne discrète en bas à gauche — graybox assumé, remplacé au Cycle 3.
func _show(text: String) -> void:
	if text.is_empty():
		return
	if _label == null:
		var layer: CanvasLayer = CanvasLayer.new()
		layer.name = "HintLayer"
		add_child(layer)
		_label = Label.new()
		_label.name = "HintLabel"
		_label.anchor_top = 1.0
		_label.anchor_bottom = 1.0
		_label.offset_left = 24.0
		_label.offset_top = -64.0
		_label.offset_right = 900.0
		_label.offset_bottom = -24.0
		_label.add_theme_color_override("font_color",
			Color(0.85, 0.78, 0.55, 0.9))
		layer.add_child(_label)
	_label.text = text
	_label.visible = true
