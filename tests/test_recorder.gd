## Enregistreur d'assertions, détenu par le runner — jamais par le cas de test.
##
## Raison d'être (revues adverses N3) : tant que les compteurs vivaient dans le
## cas de test, celui-ci pouvait les manipuler (`_failures.clear()`,
## `_checks += 42`) ou court-circuiter la méthode qui les alimentait. Ici, seul le
## runner détient l'instance et la lit ; aucune méthode d'effacement n'est
## exposée, et le cas de test n'y accède que pour ajouter un résultat.
class_name GateTestRecorder
extends RefCounted

var _checks: int = 0
var _failures: Array[String] = []


func record(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func checks() -> int:
	return _checks


func failures() -> Array[String]:
	return _failures.duplicate()


## Le runner repart d'une instance neuve pour chaque méthode de test : il n'existe
## donc aucune remise à zéro exploitable depuis un cas de test.
