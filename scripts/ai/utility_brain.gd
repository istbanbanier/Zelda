## Sélection utilitaire BORNÉE et EXPLICABLE (P2 §8.1) — un choix parmi des
## options scorées, avec trace des trois meilleurs scores, du choix et des
## raisons. « Pas de comportement opaque impossible à diagnostiquer. »
##
## Pur et sans état de jeu : le propriétaire construit ses options avec ses
## propres facteurs (distance, angle, cooldown, jetons, santé…) et garde la
## responsabilité d'agir. Le cerveau trie, choisit, se souvient.
class_name UtilityBrain
extends RefCounted

## Profondeur de la trace conservée (P2 §8.1 : « les trois meilleurs »).
const TRACE_DEPTH: int = 3

var _trace: Array[Dictionary] = []


## `options` : [{ "id": StringName, "score": float, "reason": String }].
## Retourne l'id du meilleur score (&"" si vide). Égalité : l'ordre de
## déclaration tranche — le propriétaire déclare ses options par priorité.
func choose(options: Array[Dictionary]) -> StringName:
	_trace = []
	if options.is_empty():
		return &""
	var sorted_options: Array[Dictionary] = options.duplicate()
	# Tri STABLE requis (l'ordre de déclaration départage les égalités) :
	# sort_custom n'est pas stable — on trie sur (score, rang inverse).
	for i: int in range(sorted_options.size()):
		sorted_options[i] = (sorted_options[i] as Dictionary).duplicate()
		(sorted_options[i] as Dictionary)["rank"] = i
	sorted_options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(float(a["score"]), float(b["score"])):
			return int(a["rank"]) < int(b["rank"])
		return float(a["score"]) > float(b["score"]))
	for i: int in range(mini(TRACE_DEPTH, sorted_options.size())):
		var entry: Dictionary = sorted_options[i] as Dictionary
		_trace.append({
			"id": entry["id"],
			"score": entry["score"],
			"reason": entry["reason"],
		})
	return (sorted_options[0] as Dictionary)["id"] as StringName


## Les trois meilleurs du DERNIER choix — [0] est l'élu.
func trace() -> Array[Dictionary]:
	return _trace


## Une ligne par option pour l'overlay de lab.
func trace_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	for i: int in range(_trace.size()):
		var entry: Dictionary = _trace[i]
		lines.append("%s%s %.2f — %s" % ["> " if i == 0 else "  ",
			entry["id"], float(entry["score"]), String(entry["reason"])])
	return "\n".join(lines)
