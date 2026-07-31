## Classe de base obligatoire de tous les cas de test.
##
## Raison d'être (défaut D3 de la revue adverse du Gate 0) : quand chaque fichier
## de test recopiait son propre `_assert` et son propre `set_reporter`, un fichier
## qui oubliait ce câblage voyait **toutes** ses assertions avalées en silence et
## comptées comme réussies. Un test incapable d'échouer est pire qu'un test absent.
##
## Le runner refuse désormais tout script de test qui n'étend pas cette classe.
class_name GateTestCase
extends RefCounted

var _reporter: Object = null
var _checks: int = 0


## Injecté par le runner avant chaque méthode de test.
func set_reporter(reporter: Object) -> void:
	_reporter = reporter
	_checks = 0


## Nombre d'assertions réellement exécutées, lu par le runner : une méthode de test
## qui n'assertionne rien est signalée plutôt que comptée comme réussie.
func get_check_count() -> int:
	return _checks


func check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		return
	if _reporter == null:
		# Ne doit pas arriver : le runner injecte toujours le reporter. Si cela
		# survient, échouer bruyamment plutôt que d'avaler l'échec.
		printerr("ASSERTION ÉCHOUÉE SANS REPORTER: %s" % message)
		return
	_reporter.call("report_failure", message)


func check_equal(actual: Variant, expected: Variant, context: String) -> void:
	check(actual == expected, "%s : attendu %s, obtenu %s" % [context, expected, actual])


func check_approx(actual: float, expected: float, tolerance: float, context: String) -> void:
	check(absf(actual - expected) <= tolerance,
		"%s : attendu %.4f ± %.4f, obtenu %.4f" % [context, expected, tolerance, actual])


func check_not_null(value: Variant, context: String) -> void:
	check(value != null, "%s : valeur nulle" % context)
