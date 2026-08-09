## `restore_root()` ÉPROUVÉ PAR L'ADVERSAIRE.
##
## Ce garde-fou protège toute la suite : s'il ment, une scène oubliée poisonne
## la géométrie des tests suivants et le vrai coupable devient invisible. Le
## 2026-08-08, `test_boot_smoke` a fait tomber dix-sept assertions du donjon
## trente fichiers plus loin ; le premier nettoyage écrit pour l'en empêcher
## comparait des NOMS et n'aurait pas vu un remplacement à nom identique.
##
## Ces trois cas font échouer une version affaiblie du nettoyage. C'est la seule
## chose qui distingue un garde-fou d'une décoration.
extends GateTestCase


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _spawn(named: String) -> Node:
	var node: Node = Node.new()
	node.name = named
	_tree().root.add_child(node)
	return node


## Un intrus ORDINAIRE — absent de la photo — doit partir, et le verdict être
## vrai. C'est le cas nominal ; sans lui, les deux suivants ne prouveraient rien
## (un nettoyage qui refuse toujours « attraperait » aussi les adversaires).
func test_an_ordinary_stray_is_removed_and_the_verdict_is_clean() -> void:
	remember_root()
	var stray: Node = _spawn("StrayNode")
	var verdict: bool = await restore_root(4.0)
	check(verdict, "un intrus ordinaire est retiré sans réserve (motif : « %s »)"
		% restore_root_reason())
	check(not is_instance_valid(stray) or stray.get_parent() == null,
		"…et le nœud est bien détaché de la racine")


## LE CAS QUE LA COMPARAISON PAR NOM NE VOIT PAS — DANS LES DEUX SENS.
##
## Un nœud nommé `Doublon` existe au moment de la photo. Le test le libère et en
## instancie un AUTRE, du même nom. Une photo de noms l'absout — « Doublon était
## là avant » — et l'intrus survit au nettoyage. Une photo d'identités le voit.
##
## Mais retirer l'imposteur ne suffit pas à rendre la racine intacte :
## l'ORIGINAL a disparu. Le nettoyage doit donc à la fois retirer l'intrus ET
## REFUSER de conclure, en nommant le disparu. C'est la seconde direction exigée
## par la deuxième passe d'audit : rien en trop, ET rien en moins.
func test_a_same_name_replacement_is_swept_and_the_missing_original_is_named() -> void:
	var original: Node = _spawn("Doublon")
	var original_id: int = original.get_instance_id()
	remember_root()

	_tree().root.remove_child(original)
	original.queue_free()
	await _tree().process_frame
	var impostor: Node = _spawn("Doublon")
	check(impostor.get_instance_id() != original_id,
		"l'imposteur porte le MÊME nom et une identité différente")

	var verdict: bool = await restore_root(4.0)
	var survivors: Array[Node] = _tree().root.find_children(
		"Doublon", "", false, false)
	check(survivors.is_empty(),
		"l'imposteur est retiré : la photo compare des identités, pas des noms "
		+ "(survivants : %d)" % survivors.size())
	check(not verdict,
		"…et le verdict REFUSE quand même, parce que l'original a disparu")
	check(restore_root_reason().contains("Doublon"),
		"…en nommant le disparu (obtenu : « %s »)" % restore_root_reason())


## UN NŒUD PHOTOGRAPHIÉ QUI DISPARAÎT, SANS AUCUN INTRUS.
##
## Le cas le plus discret : la racine est « propre » au sens du balayage — aucun
## enfant en trop — et pourtant le processus n'est plus celui d'avant. Un
## nettoyage qui ne regarde que les intrus rend vrai.
func test_a_vanished_original_alone_is_enough_to_refuse() -> void:
	var doomed: Node = _spawn("NoeudQuiDisparait")
	remember_root()
	_tree().root.remove_child(doomed)
	doomed.queue_free()
	await _tree().process_frame

	var verdict: bool = await restore_root(4.0)
	check(not verdict,
		"un nœud photographié disparu suffit à refuser, sans aucun intrus")
	check(restore_root_reason().contains("NoeudQuiDisparait"),
		"…et le motif le nomme (obtenu : « %s »)" % restore_root_reason())


## `current_scene` NON NULLE EST RENDUE.
##
## Elle ne se voit dans aucune liste d'enfants : la remettre à zéro à l'aveugle
## laissait le processus dans un état que rien ne signalait.
func test_a_photographed_current_scene_is_given_back() -> void:
	var loop: SceneTree = _tree()
	var previous: Node = loop.current_scene
	var stage: Node = _spawn("SceneSousTest")
	loop.current_scene = stage
	remember_root()
	var stray: Node = _spawn("IntrusDeScene")

	var verdict: bool = await restore_root(4.0)
	check(verdict, "l'intrus part et le verdict conclut (motif : « %s »)"
		% restore_root_reason())
	check(loop.current_scene == stage,
		"…et `current_scene` est RENDUE, pas mise à zéro (obtenu : %s)"
			% (loop.current_scene.name if loop.current_scene != null else "null"))
	check(not is_instance_valid(stray) or stray.get_parent() == null,
		"…tandis que l'intrus est bien détaché")

	# Ce cas a créé sa propre scène : il la reprend, sinon c'est LUI qui laisse
	# la racine différente de ce que le runner avait photographié.
	loop.current_scene = previous
	loop.root.remove_child(stage)
	stage.queue_free()
	await loop.process_frame


## `current_scene` PHOTOGRAPHIÉE PUIS DÉTRUITE.
func test_a_destroyed_current_scene_refuses() -> void:
	var loop: SceneTree = _tree()
	var previous: Node = loop.current_scene
	var stage: Node = _spawn("SceneCondamnee")
	loop.current_scene = stage
	remember_root()

	loop.current_scene = null
	loop.root.remove_child(stage)
	stage.queue_free()
	await loop.process_frame

	var verdict: bool = await restore_root(4.0)
	check(not verdict, "une `current_scene` photographiée puis détruite REFUSE")
	check(restore_root_reason().contains("current_scene"),
		"…et le motif dit que c'est `current_scene` (obtenu : « %s »)"
			% restore_root_reason())
	loop.current_scene = previous


## LA TRANSITION TARDIVE.
##
## Une scène qui se pose APRÈS le premier balayage propre est exactement le
## défaut du 2026-08-08. Le nettoyage doit la retirer ET refuser de conclure :
## la prochaine se posera peut-être après le garde-fou du runner, et c'est le
## test suivant qui paiera.
func test_a_late_arrival_is_swept_and_refused() -> void:
	remember_root()
	var timer: SceneTreeTimer = _tree().create_timer(0.2)
	timer.timeout.connect(func() -> void:
		var latecomer: Node = Node.new()
		latecomer.name = "ArriveeTardive"
		_tree().root.add_child(latecomer))

	var verdict: bool = await restore_root(4.0)
	check(not verdict,
		"une scène déposée après le nettoyage fait REFUSER le verdict")
	check(restore_root_reason().contains("ArriveeTardive"),
		"…et le motif NOMME la coupable (obtenu : « %s »)" % restore_root_reason())
	var survivors: Array[Node] = _tree().root.find_children(
		"ArriveeTardive", "", false, false)
	check(survivors.is_empty(), "…tout en la retirant quand même")
