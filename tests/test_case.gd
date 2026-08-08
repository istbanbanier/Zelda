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


## ---------------------------------------------------------------------------
## SAUVEGARDE : un cas de test ne doit rien laisser derrière lui
## ---------------------------------------------------------------------------
##
## Défaut mesuré le 2026-08-07. Charger `ValleyWorld` et y déplacer le héros
## suffit à déclencher un AUTOSAVE (`valley_world.gd` en pose un sur transition,
## ramassage, coffre, plat et buff). La position bidon d'un test se retrouvait
## donc dans `slot0`, et les cas de sauvegarde exécutés APRÈS échouaient sur des
## valeurs qu'ils n'avaient jamais écrites — douze échecs d'un coup, dont
## « « Continuer » replace le joueur où il était (écart 53,26 m) ».
##
## Mesuré des deux côtés : la même suite privée de ces tests-là sort
## 775 réussis / 4 échoués, et les quatre sont les échecs connus et antérieurs.
## Le couplage venait bien des tests, pas du système de sauvegarde — qui passe
## 3/3 en isolation.
##
## Tout cas qui monte un monde jouable encadre donc son travail par
## `remember_saves()` / `restore_saves()`.

const _GUARDED_SLOTS: Array[String] = ["slot0"]

var _save_snapshot: Dictionary = {}


## Mémorise l'état des sauvegardes AVANT que le test ne touche au monde.
func remember_saves() -> void:
	_save_snapshot.clear()
	var system: Node = _save_system()
	if system == null:
		return
	for slot: String in _GUARDED_SLOTS:
		# `null` = il n'y avait AUCUNE sauvegarde : à la fin il ne doit pas y
		# en avoir non plus, sinon le test suivant hérite d'une partie fantôme.
		_save_snapshot[slot] = system.call("load_slot", slot) \
			if bool(system.call("has_save", slot)) else null


## Remet les sauvegardes telles qu'elles étaient. À appeler même quand le test
## échoue : c'est le cas SUIVANT qu'on protège, pas celui-ci.
func restore_saves() -> void:
	var system: Node = _save_system()
	if system == null:
		return
	for slot: String in _GUARDED_SLOTS:
		var before: Variant = _save_snapshot.get(slot)
		if before == null:
			var path: String = String(system.call("slot_path", slot))
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
		else:
			system.call("save_slot", slot, before as Dictionary)
	_save_snapshot.clear()


func _save_system() -> Node:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	return null if loop == null else loop.root.get_node_or_null("/root/SaveSystem")
