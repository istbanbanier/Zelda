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


## ---------------------------------------------------------------------------
## ARBRE : un cas de test ne doit pas non plus laisser une SCÈNE derrière lui
## ---------------------------------------------------------------------------
##
## Le runner refuse déjà tout enfant de la racine apparu pendant un test
## (`_leaked_roots`), parce qu'une scène oubliée poisonne la géométrie de tous
## les suivants. Nettoyer par une LISTE DE NOMS ne suffit pas, et le
## 2026-08-08 l'a montré : `test_boot_smoke` et `test_golden_path` passaient
## seuls, et dans la suite complète laissaient `Boot, ValleyWorld` et un
## `@Node@…` anonyme — dix-sept assertions du donjon tombaient trente fichiers
## plus loin.
##
## La cause est une COURSE DE PHASE, la même famille qu'ISS-038 : la dernière
## action du test demande une transition, `SceneFlow.go_to()` est asynchrone, et
## en headless elle finit par `change_scene_to_file()`, différée en fin de
## frame. Le test retirait donc une scène pendant qu'une autre était en vol, et
## celle-ci se posait APRÈS le nettoyage. En isolation la transition avait le
## temps de finir ; dans la suite chargée, non.
##
## D'où les deux corrections : attendre la fin réelle de la transition, puis
## retirer le DELTA par rapport à la photo d'entrée plutôt qu'une liste de noms.
## Un nom qu'on n'a pas prévu reste invisible ; un delta, jamais.
##
## L'audit du 2026-08-09 a exigé deux durcissements successifs. Le premier
## portait sur l'identité : comparer des NOMS laisse passer le remplacement à
## nom identique. Un test qui
## libère `ValleyWorld` et en instancie un autre du même nom voyait sa photo
## d'entrée l'absoudre. On compare donc des IDENTITÉS (`get_instance_id()`), et
## `current_scene` est mémorisée puis rendue au lieu d'être mise à zéro à
## l'aveugle. Enfin, `restore_root()` REND UN VERDICT : un `SceneFlow` encore
## occupé après son budget, ou une scène qui se pose malgré le nettoyage, ne
## doivent plus être avalés en silence.

## `instance_id` -> nom, pour que le message de refus soit lisible.
var _root_snapshot: Dictionary = {}
var _scene_snapshot: int = 0
var _restore_reason: String = ""

## Grâce accordée APRÈS le premier balayage propre, en temps de jeu. Une
## transition différée qui se pose dans cet intervalle est encore attrapée ici ;
## au-delà, c'est le garde-fou du runner qui la verra, et le test suivant qui
## en souffrira.
const _LATE_ARRIVAL_GRACE_S: float = 0.75


## Photo des enfants de la racine AVANT que le test ne charge quoi que ce soit.
func remember_root() -> void:
	_root_snapshot.clear()
	_restore_reason = ""
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	if loop == null:
		return
	for child: Node in loop.root.get_children():
		_root_snapshot[child.get_instance_id()] = child.name
	_scene_snapshot = loop.current_scene.get_instance_id() \
		if loop.current_scene != null else 0


## Pourquoi le dernier `restore_root()` a refusé. Vide s'il a réussi.
func restore_root_reason() -> String:
	return _restore_reason


## Rend la racine telle qu'elle était, et DIT si elle l'est vraiment.
##
## `budget_s` est un temps de JEU, jamais un nombre de frames : un test ne doit
## jamais exiger que la machine soit RAPIDE, seulement qu'assez de temps de jeu
## se soit écoulé (ISS-038).
func restore_root(budget_s: float = 20.0) -> bool:
	_restore_reason = ""
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	if loop == null:
		_restore_reason = "aucune SceneTree"
		return false

	# 1. Laisser la transition en vol se poser. Nettoyer maintenant reviendrait à
	#    balayer devant un camion qui décharge encore.
	var flow: Node = loop.root.get_node_or_null("/root/SceneFlow")
	var elapsed: float = 0.0
	while flow != null and bool(flow.call("is_busy")) and elapsed <= budget_s:
		await loop.process_frame
		elapsed += loop.root.get_process_delta_time()
	if flow != null and bool(flow.call("is_busy")):
		# Échec EXPLICITE. Avant, on balayait quand même et la scène en vol se
		# posait juste après : le test passait, le suivant héritait du décor.
		_restore_reason = "SceneFlow toujours occupé après %.1f s de temps de jeu" \
			% budget_s
		await _sweep(loop)
		return false

	# 2. Balayer jusqu'à stabilité, par IDENTITÉ.
	var swept: Array[String] = await _sweep(loop)
	var late: Array[String] = []
	var grace: float = 0.0
	while grace <= _LATE_ARRIVAL_GRACE_S:
		var again: Array[String] = await _sweep(loop)
		for name: String in again:
			if not late.has(name):
				late.append(name)
		grace += loop.root.get_process_delta_time()

	# 3. LA SECONDE DIRECTION. Balayer les intrus ne dit rien de ce qui a
	#    DISPARU. Un test qui libère un autoload, ou qui remplace un nœud par un
	#    autre du même nom, laissait la racine « propre » et le verdict vrai —
	#    alors que le processus n'est plus celui d'avant. Exigé par la deuxième
	#    passe d'audit du 2026-08-09.
	var missing: Array[String] = []
	for id: int in _root_snapshot.keys():
		var was: String = String(_root_snapshot[id])
		if not is_instance_id_valid(id):
			missing.append("%s (libéré)" % was)
			continue
		var node: Node = instance_from_id(id) as Node
		if node == null:
			missing.append("%s (n'est plus un nœud)" % was)
		elif node.get_parent() != loop.root:
			missing.append("%s (détaché de la racine)" % was)

	# 4. Rendre `current_scene` telle qu'elle était, si elle vit encore.
	var scene_lost: String = ""
	if _scene_snapshot != 0:
		if is_instance_id_valid(_scene_snapshot):
			var remembered: Node = instance_from_id(_scene_snapshot) as Node
			if remembered != null and is_instance_valid(remembered):
				loop.current_scene = remembered
			else:
				scene_lost = "current_scene photographiée n'est plus un nœud"
		else:
			scene_lost = "current_scene photographiée a été LIBÉRÉE"
	elif loop.current_scene != null \
			and not _root_snapshot.has(loop.current_scene.get_instance_id()):
		# Il n'y en avait pas au départ : ne pas en laisser une.
		loop.current_scene = null

	_root_snapshot.clear()
	_scene_snapshot = 0
	# Motifs CUMULÉS : trois causes distinctes ne doivent pas s'effacer l'une
	# l'autre. Un verdict faux qui ne nomme qu'un tiers du problème envoie
	# chercher la panne au mauvais endroit.
	var reasons: Array[String] = []
	if not late.is_empty():
		# Le nettoyage a bien retiré l'intruse, mais une scène qui se pose APRÈS
		# le premier balayage propre signale un enchaînement non maîtrisé : la
		# prochaine arrivera peut-être après le garde-fou du runner.
		reasons.append("scène(s) déposée(s) APRÈS le nettoyage : %s" % ", ".join(late))
	if not missing.is_empty():
		reasons.append("nœud(s) de la photo DISPARU(S) : %s" % ", ".join(missing))
	if scene_lost != "":
		reasons.append(scene_lost)
	swept.clear()
	if reasons.is_empty():
		return true
	_restore_reason = " ; ".join(reasons)
	return false


## ---------------------------------------------------------------------------
## ATTENDRE UNE TRANSITION SANS EXIGER QUE LA MACHINE SOIT RAPIDE
## ---------------------------------------------------------------------------
##
## `B4` a échoué dans la suite complète après être passé seul quelques minutes
## plus tôt : la vallée n'était pas apparue en 25 s. Le défaut n'est pas dans le
## jeu, il est dans la borne. En headless, `SceneFlow._load_and_swap()` prend le
## chemin SYNCHRONE (`change_scene_to_file`) : la frame de chargement dure
## plusieurs secondes, et `get_process_delta_time()` les compte. Une borne fixe
## devient donc une exigence de VITESSE — exactement ce que `tests/CLAUDE.md`
## interdit : « un test ne doit jamais exiger que la machine soit rapide,
## seulement qu'assez de temps de jeu se soit écoulé ».
##
## On borne donc ce qui doit l'être et rien de plus :
##   - l'ORDRE doit partir : `SceneFlow` devient occupé, sinon rien n'a été
##     demandé et c'est un vrai défaut de câblage ;
##   - le CHARGEMENT lui-même n'est pas chronométré — il finit quand la machine
##     finit. Un garde d'anti-blocage très large reste, pour ne jamais pendre ;
##   - l'APPARITION après la transition est bornée court : une fois `SceneFlow`
##     au repos, la scène est là ou elle ne viendra pas.
##
## Un sabotage reste vu : avec une cible de transition fausse, `SceneFlow` finit
## et le nœud attendu n'apparaît jamais.
const _ORDER_BUDGET_S: float = 6.0
const _LOAD_ANTIHANG_S: float = 600.0
const _APPEAR_BUDGET_S: float = 15.0


## Attend que `SceneFlow` soit RÉELLEMENT au repos avant d'agir sur un menu.
##
## Voici le mécanisme qui a fait rougir `B4` deux fois dans la suite complète,
## alors que le parcours passait seul : `SceneFlow.can_go_to()` rend FAUX tant
## que `_busy` est vrai, et `MainMenu._enter_world()` se contente alors
## d'écrire « Monde indisponible » dans un libellé — sans `push_warning`, sans
## `push_error`, sans transition. L'appui est avalé en silence.
##
## Or `_busy` ne retombe qu'à la toute fin de `go_to()`, après le fondu de
## sortie. Attendre que `MainMenu` EXISTE ne suffit donc pas : il existe pendant
## que le flux est encore occupé. Sous charge, l'appui du pilote tombait dans
## cette fenêtre.
##
## Un joueur ne vit pas ce problème — le voile noir couvre l'écran pendant ce
## laps. Le pilote doit donc l'imiter : attendre que le menu soit vraiment
## rendu, puis presser.
func await_flow_idle(budget_s: float = 30.0) -> bool:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	if loop == null:
		return false
	var flow: Node = loop.root.get_node_or_null("/root/SceneFlow")
	if flow == null:
		return true
	var waited: float = 0.0
	while bool(flow.call("is_busy")) and waited <= budget_s:
		await loop.process_frame
		waited += loop.root.get_process_delta_time()
	return not bool(flow.call("is_busy"))


## Attend qu'un nœud nommé `wanted` apparaisse sous la racine à la faveur d'une
## transition `SceneFlow`. Rend vrai s'il est là.
func await_scene(wanted: String) -> bool:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	if loop == null:
		return false
	var flow: Node = loop.root.get_node_or_null("/root/SceneFlow")
	# 1. L'ordre part-il ? Si la scène est déjà là, rien à attendre.
	var waited: float = 0.0
	while waited <= _ORDER_BUDGET_S:
		if _first_named(loop, wanted) != null:
			return true
		if flow != null and bool(flow.call("is_busy")):
			break
		await loop.process_frame
		waited += loop.root.get_process_delta_time()
	# 2. Le chargement va à son rythme. Le garde n'est pas un budget de vitesse :
	#    c'est un filet contre un blocage définitif.
	var guard: float = 0.0
	while flow != null and bool(flow.call("is_busy")) and guard <= _LOAD_ANTIHANG_S:
		await loop.process_frame
		guard += loop.root.get_process_delta_time()
	# 3. Une fois au repos, la scène est là ou elle ne viendra pas.
	var appear: float = 0.0
	while appear <= _APPEAR_BUDGET_S:
		if _first_named(loop, wanted) != null:
			return true
		await loop.process_frame
		appear += loop.root.get_process_delta_time()
	return false


func _first_named(loop: SceneTree, wanted: String) -> Node:
	var by_class: Array[Node] = loop.root.find_children("*", wanted, true, false)
	if not by_class.is_empty():
		return by_class[0]
	var by_name: Array[Node] = loop.root.find_children(wanted, "", true, false)
	return by_name[0] if not by_name.is_empty() else null


## Un balayage : retire tout enfant de la racine absent de la photo d'entrée.
## Rend les noms retirés.
func _sweep(loop: SceneTree) -> Array[String]:
	var removed: Array[String] = []
	for child: Node in loop.root.get_children():
		if _root_snapshot.has(child.get_instance_id()):
			continue
		removed.append(child.name)
		if child == loop.current_scene:
			loop.current_scene = null
		loop.root.remove_child(child)
		child.queue_free()
	await loop.process_frame
	await loop.physics_frame
	return removed
