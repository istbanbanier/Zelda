## Classe de base obligatoire de tous les cas de test.
##
## Historique — trois revues adverses successives du Gate 0 :
##   - D3 : chaque fichier recopiait son `_assert` ; un fichier qui oubliait ce
##     câblage voyait toutes ses assertions avalées.
##   - N3 : la comptabilité passait par un reporter injecté **par méthode** ; un
##     cas de test pouvait neutraliser `set_reporter()` et `get_check_count()`.
##   - N3 (2e passe) : la comptabilité vivait dans des **membres** de cette classe.
##     Redéclarer un membre est bien interdit par GDScript, mais rien n'empêchait
##     de redéfinir `check()` lui-même, ni d'appeler `_failures.clear()`, ni de
##     faire `_checks += 42`. Trois contournements, tous démontrés.
##
## Conception retenue : cette classe ne **détient** plus aucun résultat. Elle
## délègue à un enregistreur (`GateTestRecorder`) créé et conservé par le runner,
## qui lit ses propres compteurs et ne fait jamais confiance au cas de test. En
## complément, le runner **refuse** tout script de test qui redéfinit une méthode
## du contrat (voir `CONTRACT_METHODS`).
##
## LIMITE ASSUMÉE : ces défenses arrêtent la perte de signal accidentelle —
## câblage oublié, refactor, fichier renommé — et les vecteurs précisément
## démontrés par les revues. Elles n'arrêtent pas un auteur de test qui
## chercherait délibérément à mentir : il resterait possible de remplacer
## l'enregistreur depuis une méthode de test. Prétendre le contraire serait
## exactement le genre de sur-affirmation que ces revues ont sanctionné.
class_name GateTestCase
extends RefCounted

## Méthodes que le runner interdit de redéfinir dans un cas de test.
const CONTRACT_METHODS: Array[String] = [
	"check", "check_equal", "check_approx", "check_not_null",
]

## Injecté par le runner. Le cas de test n'a aucune raison d'y toucher.
var _recorder: Object = null


func check(condition: bool, message: String) -> void:
	if _recorder == null:
		printerr("CONTRAT DE TEST ROMPU: enregistreur absent — %s" % message)
		return
	_recorder.call("record", condition, message)


func check_equal(actual: Variant, expected: Variant, context: String) -> void:
	check(actual == expected, "%s : attendu %s, obtenu %s" % [context, expected, actual])


func check_approx(actual: float, expected: float, tolerance: float, context: String) -> void:
	check(absf(actual - expected) <= tolerance,
		"%s : attendu %.4f ± %.4f, obtenu %.4f" % [context, expected, tolerance, actual])


func check_not_null(value: Variant, context: String) -> void:
	check(value != null, "%s : valeur nulle" % context)
