## Autoload — bus d'événements réellement globaux (MASTER_SPEC §5.6).
##
## POLITIQUE STRICTE, et raison pour laquelle ce fichier est presque vide :
## un signal n'entre ici que s'il traverse des systèmes **sans lien** entre eux et
## n'a **aucun propriétaire naturel**. Un signal qui appartient à un système donné
## reste sur ce système :
##
##   - le flux de jeu et la pause      -> `GameState`
##   - les transitions de scène        -> `SceneFlow`
##   - la sauvegarde                   -> `SaveSystem`
##   - les dégâts, la mort, le butin   -> composants de l'entité concernée
##   - la propagation électrique       -> nœuds du graphe (§15.1)
##
## À la Phase A, aucun événement ne remplit ce critère : les systèmes qui les
## émettraient n'existent pas. Déclarer maintenant des signaux « au cas où »
## produirait une API spéculative que personne n'écoute, et le premier réflexe de
## la phase suivante serait de tout faire transiter par ici — exactement le
## couplage global que §5.6 cherche à éviter.
##
## Ajouter un signal ici exige donc, dans le même changement : un émetteur réel,
## au moins un récepteur réel, et une justification dans `docs/DECISIONS.md`.
extends Node

## PREMIER signal admis (D.1R.3, D-026) — il remplit le critère au complet :
## émetteurs réels sans lien entre eux (coffres, armes au sol, contrôleur
## joueur), récepteur réel (le HUD de `GameplayShell`), et aucun propriétaire
## naturel — une notification de gameplay traverse interactables, combat et
## interface. PT-D1-03 : « les armes sont versées silencieusement ».
signal gameplay_notification(text: String)


func notify(text: String) -> void:
	gameplay_notification.emit(text)


## Vrai tant qu'aucun événement global n'a été jugé nécessaire. Lu par les tests
## pour que le passage de « vide » à « non vide » soit un choix visible en revue,
## et non une dérive silencieuse.
func is_intentionally_empty() -> bool:
	return get_signal_list().size() == _builtin_signal_count()


## Nombre de signaux hérités de `Node` — ceux que nous n'avons pas déclarés.
func _builtin_signal_count() -> int:
	var script_signals: Array[Dictionary] = get_script().get_script_signal_list()
	return get_signal_list().size() - script_signals.size()
