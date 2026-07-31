## Classe de base obligatoire de tous les cas de test.
##
## Historique des deux revues adverses du Gate 0 :
##   - D3 : chaque fichier recopiait son `_assert` et son `set_reporter` ; un
##     fichier qui oubliait ce câblage voyait toutes ses assertions avalées.
##   - N3 : la première correction passait par un *reporter injecté via méthode*.
##     Un cas de test pouvait redéfinir `set_reporter()` en no-op et
##     `get_check_count()` en constante, et faire passer des assertions fausses
##     pour 42 assertions réussies. Le contrat était contournable.
##
## Correction retenue : **aucune indirection par méthode**. Les échecs sont
## accumulés dans des membres de cette classe, que le runner lit directement via
## `get()`. GDScript interdit à une sous-classe de redéclarer un membre du parent
## (« already exists in parent class »), donc ces champs ne peuvent pas être
## masqués, et redéfinir une méthode ne change plus rien à la comptabilité.
class_name GateTestCase
extends RefCounted

## Lus par le runner via get(), jamais via un accesseur redéfinissable.
var _checks: int = 0
var _failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func check_equal(actual: Variant, expected: Variant, context: String) -> void:
	check(actual == expected, "%s : attendu %s, obtenu %s" % [context, expected, actual])


func check_approx(actual: float, expected: float, tolerance: float, context: String) -> void:
	check(absf(actual - expected) <= tolerance,
		"%s : attendu %.4f ± %.4f, obtenu %.4f" % [context, expected, tolerance, actual])


func check_not_null(value: Variant, context: String) -> void:
	check(value != null, "%s : valeur nulle" % context)
