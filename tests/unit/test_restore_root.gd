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


## LE CAS QUE LA COMPARAISON PAR NOM NE VOIT PAS.
##
## Un nœud nommé `Doublon` existe au moment de la photo. Le test le libère et en
## instancie un AUTRE, du même nom. Une photo de noms l'absout — « Doublon était
## là avant » — et l'intrus survit au nettoyage. Une photo d'identités le voit.
func test_a_same_name_replacement_does_not_survive_the_sweep() -> void:
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
	check(verdict, "le nettoyage conclut sans réserve (motif : « %s »)"
		% restore_root_reason())
	var survivors: Array[Node] = _tree().root.find_children(
		"Doublon", "", false, false)
	check(survivors.is_empty(),
		"…et AUCUN « Doublon » ne survit : la photo compare des identités, "
		+ "pas des noms (survivants : %d)" % survivors.size())


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
